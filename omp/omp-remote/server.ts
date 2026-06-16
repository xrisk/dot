import { mkdir, rename, stat } from "node:fs/promises";
const ROOM_PATH_RE = /^\/r\/([A-Za-z0-9_-]{10,64})$/;
const PORT = Number(Bun.env.PORT ?? "7466");
const TOKEN = Bun.env.OMP_REMOTE_TOKEN;
const DATA_DIR = Bun.env.OMP_REMOTE_DATA_DIR ?? defaultDataDir();
const SESSIONS_PATH = Bun.env.OMP_REMOTE_SESSIONS_PATH ?? `${DATA_DIR}/sessions.json`;
const SESSION_TTL_MS = 10 * 60 * 1000;
const ENVELOPE_HEADER_LENGTH = 4;
const PROJECT_ROOTS = parseProjectRoots(Bun.env.OMP_REMOTE_PROJECT_ROOTS ?? "");
const ALLOW_CUSTOM_ROOTS = Bun.env.OMP_REMOTE_ALLOW_CUSTOM_ROOTS !== "0";
const LAUNCH_MODE = Bun.env.OMP_REMOTE_LAUNCH_MODE ?? defaultLaunchMode();
const LAUNCH_COMMAND = Bun.env.OMP_REMOTE_LAUNCH_COMMAND ?? "omp";
const LAUNCH_APP = Bun.env.OMP_REMOTE_LAUNCH_APP ?? "Ghostty";
const LAUNCH_TMUX_PREFIX = Bun.env.OMP_REMOTE_LAUNCH_TMUX_PREFIX ?? "omp";

if (!TOKEN) {
	throw new Error("OMP_REMOTE_TOKEN is required");
}
if (!Number.isInteger(PORT) || PORT < 1 || PORT > 65_535) {
	throw new Error(`invalid PORT: ${Bun.env.PORT}`);
}

interface SocketData {
	roomId: string;
	role: "host" | "guest";
	peerId: number;
}

type RelaySocket = Bun.ServerWebSocket<SocketData>;

interface Room {
	host: RelaySocket;
	guests: Map<number, RelaySocket>;
	nextPeerId: number;
}

interface SessionRecord {
	id: string;
	title: string;
	cwd: string;
	terminal: string;
	pid: number;
	joinLink: string;
	webLink: string;
	summary: string;
	createdAt: string;
	updatedAt: string;
}

interface ProjectRoot {
	path: string;
	title: string;
}

const rooms = new Map<string, Room>();
let sessions = await loadSessions();

function unpackEnvelope(data: Uint8Array): { peerId: number; payload: Uint8Array } | null {
	if (data.byteLength < ENVELOPE_HEADER_LENGTH) return null;
	const peerId = new DataView(data.buffer, data.byteOffset, ENVELOPE_HEADER_LENGTH).getUint32(0, false);
	return { peerId, payload: data.subarray(ENVELOPE_HEADER_LENGTH) };
}

function rewriteEnvelopePeer(data: Uint8Array, peerId: number): void {
	new DataView(data.buffer, data.byteOffset, ENVELOPE_HEADER_LENGTH).setUint32(0, peerId, false);
}

function parseProjectRoots(value: string): ProjectRoot[] {
	const roots: ProjectRoot[] = [];
	for (const raw of value.split(",")) {
		const path = raw.trim();
		if (!path) continue;
		roots.push({ path, title: basename(path) });
	}
	return roots;
}

function defaultLaunchMode(): string {
	const processLike = (globalThis as unknown as { process?: { platform?: string } }).process;
	return processLike?.platform === "darwin" ? "macos" : "tmux";
}

function defaultDataDir(): string {
	const home = Bun.env.HOME ?? "/tmp";
	return `${home}/.local/share/omp-remote`;
}

function dirname(path: string): string {
	const slash = path.lastIndexOf("/");
	return slash > 0 ? path.slice(0, slash) : "/";
}

function basename(path: string): string {
	return path.split(/[\\/]/).filter(Boolean).at(-1) ?? path;
}

function launchSessionName(root: string, id: string): string {
	const safeRoot = basename(root).replace(/[^A-Za-z0-9_-]+/g, "-").replace(/^-+|-+$/g, "");
	return `${LAUNCH_TMUX_PREFIX}-${safeRoot || "chat"}-${id.slice(0, 8)}`;
}

function shellQuote(value: string): string {
	return `'${value.replaceAll("'", "'\"'\"'")}'`;
}

async function loadSessions(): Promise<Map<string, SessionRecord>> {
	try {
		const text = await Bun.file(SESSIONS_PATH).text();
		const parsed = JSON.parse(text) as unknown;
		if (!Array.isArray(parsed)) return new Map();
		const out = new Map<string, SessionRecord>();
		for (const item of parsed) {
			const record = normalizeSession(item);
			if (record) out.set(record.id, record);
		}
		return out;
	} catch (error) {
		if ((error as { code?: string }).code === "ENOENT") return new Map();
		console.error("failed to load sessions", error);
		return new Map();
	}
}

function normalizeSession(value: unknown): SessionRecord | null {
	if (!value || typeof value !== "object") return null;
	const candidate = value as Partial<SessionRecord>;
	if (
		typeof candidate.id !== "string" ||
		typeof candidate.title !== "string" ||
		typeof candidate.cwd !== "string" ||
		typeof candidate.terminal !== "string" ||
		typeof candidate.pid !== "number" ||
		typeof candidate.joinLink !== "string" ||
		typeof candidate.webLink !== "string" ||
		typeof candidate.createdAt !== "string" ||
		typeof candidate.updatedAt !== "string"
	) {
		return null;
	}
	return {
		id: candidate.id,
		title: candidate.title,
		cwd: candidate.cwd,
		terminal: candidate.terminal,
		pid: candidate.pid,
		joinLink: candidate.joinLink,
		webLink: candidate.webLink,
		summary: typeof candidate.summary === "string" ? candidate.summary : "",
		createdAt: candidate.createdAt,
		updatedAt: candidate.updatedAt,
	};
}

function currentSessions(): SessionRecord[] {
	const cutoff = Date.now() - SESSION_TTL_MS;
	for (const [id, record] of sessions) {
		const updatedAt = Date.parse(record.updatedAt);
		if (!Number.isFinite(updatedAt) || updatedAt < cutoff) sessions.delete(id);
	}
	return [...sessions.values()].sort((a, b) => Date.parse(b.updatedAt) - Date.parse(a.updatedAt));
}

async function saveSessions(): Promise<void> {
	await mkdir(dirname(SESSIONS_PATH), { recursive: true });
	await Bun.write(`${SESSIONS_PATH}.tmp`, JSON.stringify(currentSessions(), null, 2));
	await rename(`${SESSIONS_PATH}.tmp`, SESSIONS_PATH);
}

function json(data: unknown, init: ResponseInit = {}): Response {
	const headers = new Headers(init.headers);
	headers.set("content-type", "application/json; charset=utf-8");
	headers.set("cache-control", "no-store");
	return new Response(JSON.stringify(data), { ...init, headers });
}

function unauthorized(): Response {
	return json({ error: "unauthorized" }, { status: 401 });
}

function authorized(req: Request): boolean {
	return req.headers.get("authorization") === `Bearer ${TOKEN}`;
}

function sameOrigin(req: Request, url: URL): boolean {
	const origin = req.headers.get("origin");
	if (origin !== null && origin !== url.origin) return false;
	const site = req.headers.get("sec-fetch-site");
	return site === null || site === "same-origin" || site === "none";
}

function childEnv(root: string): Record<string, string> {
	const env: Record<string, string> = { OMP_REMOTE_PROJECT_ROOT: root };
	for (const key of [
		"HOME",
		"USER",
		"LOGNAME",
		"PATH",
		"SHELL",
		"TERM",
		"LANG",
		"LC_ALL",
		"XDG_CONFIG_HOME",
		"XDG_DATA_HOME",
		"XDG_STATE_HOME",
		"XDG_CACHE_HOME",
		"SSH_AUTH_SOCK",
		"OMP_AUTO_COLLAB_RELAY_URL",
		"OMP_AUTO_COLLAB_DASHBOARD_ORIGIN",
		"OMP_AUTO_COLLAB_TOKEN_NAME",
	]) {
		const value = Bun.env[key];
		if (value !== undefined) env[key] = value;
	}
	return env;
}


async function handleSessions(req: Request, url: URL): Promise<Response> {
	if (req.method === "GET" && url.pathname === "/api/sessions") {
		return json(currentSessions());
	}
	if (req.method === "POST" && url.pathname === "/api/sessions") {
		if (!authorized(req)) return unauthorized();
		let body: unknown;
		try {
			body = await req.json();
		} catch {
			return json({ error: "invalid json" }, { status: 400 });
		}
		const incoming = normalizeSession(body);
		if (!incoming) return json({ error: "invalid session" }, { status: 400 });
		const existing = sessions.get(incoming.id);
		const record = { ...incoming, webLink: `https://omp.rishav.io/client/#${incoming.joinLink}`, createdAt: existing?.createdAt ?? incoming.createdAt };
		sessions.set(record.id, record);
		await saveSessions();
		return json(record);
	}
	if (req.method === "DELETE" && url.pathname.startsWith("/api/sessions/")) {
		if (!authorized(req)) return unauthorized();
		const id = decodeURIComponent(url.pathname.slice("/api/sessions/".length));
		const existed = sessions.delete(id);
		if (existed) await saveSessions();
		return new Response(null, { status: existed ? 204 : 404 });
	}
	return json({ error: "not found" }, { status: 404 });
}

async function handleProjectRoots(req: Request, url: URL): Promise<Response> {
	if (req.method !== "GET" || url.pathname !== "/api/project-roots") {
		return json({ error: "not found" }, { status: 404 });
	}
	return json({ roots: PROJECT_ROOTS, allowCustom: ALLOW_CUSTOM_ROOTS, launchMode: LAUNCH_MODE });
}

async function validateProjectRoot(root: string): Promise<string> {
	const trimmed = root.trim();
	if (!trimmed.startsWith("/")) throw new Error("project root must be an absolute path");
	if (!ALLOW_CUSTOM_ROOTS && !PROJECT_ROOTS.some((candidate) => candidate.path === trimmed)) {
		throw new Error("project root is not allowed");
	}
	const info = await stat(trimmed);
	if (!info.isDirectory()) throw new Error("project root is not a directory");
	return trimmed;
}

async function launchProjectRoot(root: string): Promise<{ id: string; mode: string }> {
	const id = crypto.randomUUID();
	const env = childEnv(root);
	if (LAUNCH_MODE === "macos") {
		const proc = Bun.spawn([
			"open",
			"-na",
			LAUNCH_APP,
			"--args",
			`--working-directory=${root}`,
			"-e",
			LAUNCH_COMMAND,
		], { env, stdout: "ignore", stderr: "ignore" });
		const code = await proc.exited;
		if (code !== 0) throw new Error(`launcher exited with code ${code}`);
		return { id, mode: LAUNCH_MODE };
	}
	if (LAUNCH_MODE === "tmux") {
		const sessionName = launchSessionName(root, id);
		const command = `exec ${LAUNCH_COMMAND} --cwd ${shellQuote(root)}`;
		const proc = Bun.spawn(["tmux", "new-session", "-d", "-s", sessionName, "-c", root, command], { env, stdout: "ignore", stderr: "ignore" });
		const code = await proc.exited;
		if (code !== 0) throw new Error(`launcher exited with code ${code}`);
		return { id, mode: LAUNCH_MODE };
	}
	if (LAUNCH_MODE === "direct") {
		const command = `exec ${LAUNCH_COMMAND} --cwd "$OMP_REMOTE_PROJECT_ROOT"`;
		const proc = Bun.spawn(["sh", "-lc", command], { cwd: root, env, stdout: "ignore", stderr: "ignore" });
		void proc.exited.then((code) => {
			if (code !== 0) console.error(`launch ${id} failed with exit code ${code}`);
		});
		return { id, mode: LAUNCH_MODE };
	}
	throw new Error(`unsupported launch mode: ${LAUNCH_MODE}`);
}

async function handleLaunches(req: Request, url: URL): Promise<Response> {
	if (req.method !== "POST" || url.pathname !== "/api/launches") {
		return json({ error: "not found" }, { status: 404 });
	}
	if (!sameOrigin(req, url)) return unauthorized();
	let body: unknown;
	try {
		body = await req.json();
	} catch {
		return json({ error: "invalid json" }, { status: 400 });
	}
	if (!body || typeof body !== "object") return json({ error: "invalid launch request" }, { status: 400 });
	const request = body as { root?: unknown };
	if (typeof request.root !== "string") return json({ error: "invalid launch request" }, { status: 400 });
	let root: string;
	try {
		root = await validateProjectRoot(request.root);
	} catch (error) {
		return json({ error: error instanceof Error ? error.message : "invalid project root" }, { status: 400 });
	}
	try {
		const launch = await launchProjectRoot(root);
		return json({ ok: true, root, ...launch }, { status: 202 });
	} catch (error) {
		return json({ error: error instanceof Error ? error.message : "launch failed" }, { status: 500 });
	}
}

function clientRedirect(): Response {
	return new Response(`<!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>Opening OMP Collab…</title>
</head>
<body>
	<p>Opening OMP Collab…</p>
	<script>
		const target = "https://my.omp.sh/" + window.location.hash;
		window.location.replace(target);
	</script>
	<noscript>Enable JavaScript, then open https://my.omp.sh/ with the same URL fragment.</noscript>
</body>
</html>
`, { headers: { "cache-control": "no-store", "content-type": "text/html; charset=utf-8" } });
}

async function serveStatic(url: URL): Promise<Response | null> {
	if (url.pathname === "/client" || url.pathname === "/client/") return clientRedirect();
	const path = url.pathname === "/" ? "/index.html" : url.pathname;
	if (path !== "/index.html") return null;
	const file = Bun.file(`public${path}`);
	if (!(await file.exists())) return null;
	return new Response(file, { headers: { "cache-control": "no-store", "content-type": "text/html; charset=utf-8" } });
}

const server = Bun.serve<SocketData>({
	port: PORT,
	hostname: "0.0.0.0",
	async fetch(req, srv): Promise<Response | undefined> {
		const url = new URL(req.url);
		if (url.pathname.startsWith("/api/sessions")) return handleSessions(req, url);
		if (url.pathname === "/api/project-roots") return handleProjectRoots(req, url);
		if (url.pathname === "/api/launches") return handleLaunches(req, url);
		const match = ROOM_PATH_RE.exec(url.pathname);
		const role = url.searchParams.get("role");
		if (match && (role === "host" || role === "guest")) {
			const data: SocketData = { roomId: match[1]!, role, peerId: 0 };
			if (srv.upgrade(req, { data })) return undefined;
			return new Response("websocket upgrade required", { status: 426 });
		}
		const staticResponse = await serveStatic(url);
		if (staticResponse) return staticResponse;
		return new Response("not found", { status: 404 });
	},
	websocket: {
		open(ws): void {
			const { roomId, role } = ws.data;
			if (role === "host") {
				if (rooms.has(roomId)) {
					ws.close(4009, "a host is already connected for this room");
					return;
				}
				rooms.set(roomId, { host: ws, guests: new Map(), nextPeerId: 1 });
				return;
			}
			const room = rooms.get(roomId);
			if (!room) {
				ws.close(4004, "no such room");
				return;
			}
			const peerId = room.nextPeerId++;
			ws.data.peerId = peerId;
			room.guests.set(peerId, ws);
			room.host.send(JSON.stringify({ t: "peer-joined", peer: peerId }));
		},
		message(ws, message): void {
			if (typeof message === "string") return;
			const room = rooms.get(ws.data.roomId);
			if (!room) return;
			if (ws.data.role === "host") {
				const envelope = unpackEnvelope(message);
				if (!envelope) return;
				if (envelope.peerId === 0) {
					for (const guest of room.guests.values()) guest.send(message);
				} else {
					room.guests.get(envelope.peerId)?.send(message);
				}
				return;
			}
			if (message.byteLength < ENVELOPE_HEADER_LENGTH) return;
			rewriteEnvelopePeer(message, ws.data.peerId);
			room.host.send(message);
		},
		close(ws): void {
			const { roomId, role, peerId } = ws.data;
			const room = rooms.get(roomId);
			if (!room) return;
			if (role === "host") {
				if (room.host !== ws) return;
				rooms.delete(roomId);
				const closure = JSON.stringify({ t: "room-closed" });
				for (const guest of room.guests.values()) {
					guest.send(closure);
					guest.close(4001, "room closed");
				}
				room.guests.clear();
				return;
			}
			if (room.guests.delete(peerId)) {
				room.host.send(JSON.stringify({ t: "peer-left", peer: peerId }));
			}
		},
	},
});

console.log(`omp remote listening on http://0.0.0.0:${server.port}`);
