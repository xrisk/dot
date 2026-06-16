import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";

const RELAY_URL = Bun.env.OMP_AUTO_COLLAB_RELAY_URL ?? "wss://omp.rishav.io";
const DASHBOARD_ORIGIN = Bun.env.OMP_AUTO_COLLAB_DASHBOARD_ORIGIN ?? "https://omp.rishav.io";
const TOKEN_NAME = Bun.env.OMP_AUTO_COLLAB_TOKEN_NAME ?? "omp-collab-dashboard-token";
const COLLAB_PROTO = 1;
const ROOM_ID_BYTES = 16;
const ROOM_KEY_BYTES = 32;
const WRITE_TOKEN_BYTES = 16;
const IV_BYTES = 12;
const ENVELOPE_HEADER_BYTES = 4;
const CONNECT_TIMEOUT_MS = 15_000;
const DASHBOARD_REFRESH_MS = 60_000;
const STATE_DEBOUNCE_MS = 50;
const DASHBOARD_SUMMARY_MAX_CHARS = 320;
const DASHBOARD_SUMMARY_SNIPPET_MAX_CHARS = 140;
const DASHBOARD_SUMMARY_ENTRY_SCAN_LIMIT = 80;

const SAFE_ENTRY_TYPES = new Set([
	"message",
	"custom_message",
	"compaction",
	"branch_summary",
	"model_change",
	"thinking_level_change",
]);

const HOST_EVENTS = [
	"agent_start",
	"agent_end",
	"turn_start",
	"turn_end",
	"message_start",
	"message_update",
	"message_end",
	"tool_execution_start",
	"tool_execution_update",
	"tool_execution_end",
	"auto_compaction_start",
	"auto_compaction_end",
	"auto_retry_start",
	"auto_retry_end",
] as const;

const encoder = new TextEncoder();
const decoder = new TextDecoder();
const BufferCtor = (globalThis as unknown as { Buffer: { from(input: Uint8Array | ArrayBuffer | string, encoding?: string): { toString(encoding: string): string } } }).Buffer;

type AnyRecord = Record<string, unknown>;

type Logger = {
	warn?: (message: string, error?: unknown) => void;
	debug?: (message: string, data?: unknown) => void;
};

type AutoCollabAPI = ExtensionAPI & {
	logger?: Logger;
	on: (event: string, handler: (event: unknown, ctx: AutoCollabContext) => unknown) => void;
	sendUserMessage: (message: unknown, options?: unknown) => unknown;
};

type SessionManager = {
	getHeader?: () => unknown;
	getEntries?: () => unknown[] | Promise<unknown[]>;
	getSessionId?: () => string;
	getSessionName?: () => string | null | undefined;
};

type AutoCollabContext = ExtensionContext & {
	hasUI?: boolean;
	cwd: string;
	model?: unknown;
	sessionManager: SessionManager;
	isIdle: () => boolean;
	hasPendingMessages: () => boolean;
	abort: () => unknown;
	getContextUsage: () => unknown;
};

type GuestInfo = {
	peer: number;
	canWrite: boolean;
	name: string;
};

type DashboardRecord = {
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
};

type Links = {
	wsOrigin: string;
	wsUrl: string;
	joinLink: string;
	webLink: string;
};

let host: AutoCollabHost | undefined;

export default function autoCollab(pi: ExtensionAPI): void {
	pi.setLabel("Auto Collab");
	const api = pi as AutoCollabAPI;

	api.on("session_start", async (_event: unknown, ctx: AutoCollabContext) => {
		if (ctx.hasUI === false || host) return;
		const next = new AutoCollabHost(api, ctx);
		host = next;
		try {
			await next.start();
		} catch (error) {
			host = undefined;
			api.logger?.warn?.("auto-collab failed to start", error);
		}
	});

	api.on("session_shutdown", async () => {
		const current = host;
		host = undefined;
		await current?.stop("host stopped");
	});

	for (const eventName of HOST_EVENTS) {
		api.on(eventName, (event: unknown, ctx: AutoCollabContext) => {
			const current = host;
			if (!current) return;
			void current.broadcastEvent(eventName, event, ctx);
			current.scheduleState(ctx);
			if (eventName === "message_end") void current.broadcastState(ctx);
		});
	}
}

class AutoCollabHost {
	private readonly api: AutoCollabAPI;
	private readonly ctx: AutoCollabContext;
	private readonly roomId = base64url(randomBytes(ROOM_ID_BYTES));
	private readonly roomKey = randomBytes(ROOM_KEY_BYTES);
	private readonly writeToken = randomBytes(WRITE_TOKEN_BYTES);
	private readonly writeTokenText = base64url(this.writeToken);
	private readonly keyPromise = crypto.subtle.importKey("raw", arrayBufferFor(this.roomKey), "AES-GCM", false, ["encrypt", "decrypt"]);
	private readonly links: Links;
	private readonly guests = new Map<number, GuestInfo>();
	private socket: WebSocket | undefined;
	private sendChain = Promise.resolve();
	private stopped = false;
	private stopping = false;
	private stateTimer: number | undefined;
	private refreshTimer: number | undefined;
	private dashboardToken: string | undefined;
	private dashboardRecord: DashboardRecord | undefined;

	constructor(api: AutoCollabAPI, ctx: AutoCollabContext) {
		this.api = api;
		this.ctx = ctx;
		this.links = buildLinks(this.roomId, this.roomKey, this.writeToken);
	}

	async start(): Promise<void> {
		await this.openSocket();
		await this.refreshDashboard(this.ctx);
		this.refreshTimer = setInterval(() => {
			void this.refreshDashboard(this.ctx);
		}, DASHBOARD_REFRESH_MS) as unknown as number;
		void this.broadcastState(this.ctx);
	}

	async stop(reason: string): Promise<void> {
		if (this.stopped) return;
		this.stopped = true;
		this.stopping = true;
		this.clearTimers();
		if (this.isSocketOpen()) await this.enqueueFrame({ t: "bye", reason }, 0);
		this.socket?.close(1000, reason);
		await this.deleteDashboard();
		this.guests.clear();
	}

	async broadcastEvent(name: string, event: unknown, _ctx: AutoCollabContext): Promise<void> {
		await this.enqueueFrame({ t: "event", name, event }, 0);
	}

	scheduleState(ctx: AutoCollabContext): void {
		if (this.stopped || this.stateTimer !== undefined) return;
		this.stateTimer = setTimeout(() => {
			this.stateTimer = undefined;
			void this.broadcastState(ctx);
		}, STATE_DEBOUNCE_MS) as unknown as number;
	}

	async broadcastState(ctx: AutoCollabContext): Promise<void> {
		await this.enqueueFrame({ t: "state", state: this.buildState(ctx) }, 0);
	}

	private async openSocket(): Promise<void> {
		const { promise, resolve, reject } = Promise.withResolvers<void>();
		const ws = new WebSocket(`${this.links.wsUrl}?role=host`);
		this.socket = ws;
		ws.binaryType = "arraybuffer";
		let settled = false;
		const timer = setTimeout(() => {
			if (settled) return;
			settled = true;
			ws.close();
			reject(new Error("auto-collab relay connection timed out"));
		}, CONNECT_TIMEOUT_MS);
		ws.addEventListener("open", () => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			resolve();
		});
		ws.addEventListener("error", () => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			reject(new Error("auto-collab relay connection failed"));
		});
		ws.addEventListener("message", (event) => {
			void this.handleSocketMessage(event.data);
		});
		ws.addEventListener("close", () => {
			if (this.stopping) return;
			this.clearTimers();
			void this.deleteDashboard();
			this.api.logger?.warn?.("auto-collab relay socket closed");
		});
		await promise;
	}

	private async handleSocketMessage(data: unknown): Promise<void> {
		if (typeof data === "string") {
			this.handleControl(data);
			return;
		}
		let bytes: Uint8Array | undefined;
		if (data instanceof ArrayBuffer) bytes = new Uint8Array(data);
		else if (ArrayBuffer.isView(data)) bytes = new Uint8Array(data.buffer, data.byteOffset, data.byteLength);
		else if (data instanceof Blob) bytes = new Uint8Array(await data.arrayBuffer());
		if (!bytes) return;
		await this.handleGuestFrame(bytes);
	}

	private handleControl(text: string): void {
		let frame: AnyRecord;
		try {
			frame = JSON.parse(text) as AnyRecord;
		} catch {
			return;
		}
		const peer = typeof frame.peer === "number" ? frame.peer : undefined;
		if (frame.t === "peer-joined" && peer !== undefined) {
			this.guests.set(peer, { peer, canWrite: false, name: `guest ${peer}` });
			return;
		}
		if (frame.t === "peer-left" && peer !== undefined) {
			this.guests.delete(peer);
			void this.broadcastState(this.ctx);
		}
	}

	private async handleGuestFrame(envelope: Uint8Array): Promise<void> {
		if (envelope.byteLength < ENVELOPE_HEADER_BYTES + IV_BYTES) return;
		const peer = new DataView(envelope.buffer, envelope.byteOffset, ENVELOPE_HEADER_BYTES).getUint32(0, false);
		const payload = envelope.subarray(ENVELOPE_HEADER_BYTES);
		let frame: AnyRecord;
		try {
			frame = await this.decryptFrame(payload);
		} catch (error) {
			this.api.logger?.debug?.("auto-collab dropped undecryptable frame", error);
			return;
		}
		const t = frame.t;
		if (t === "hello") {
			await this.handleHello(peer, frame);
			return;
		}
		if (t === "prompt") {
			await this.handlePrompt(peer, frame);
			return;
		}
		if (t === "abort") {
			await this.handleAbort(peer);
			return;
		}
		if (t === "agent-cmd") {
			await this.enqueueFrame({ t: "error", message: "agent control is not available from auto-collab" }, peer);
			return;
		}
		if (t === "fetch-transcript") {
			const fromByte = typeof frame.fromByte === "number" ? frame.fromByte : 0;
			await this.enqueueFrame({ t: "transcript", reqId: frame.reqId, text: "", newSize: fromByte, error: "subagent transcript fetch is not available from auto-collab" }, peer);
		}
	}

	private async handleHello(peer: number, frame: AnyRecord): Promise<void> {
		if (frame.proto !== COLLAB_PROTO) {
			await this.enqueueFrame({ t: "error", message: "unsupported collab protocol" }, peer);
			return;
		}
		const receivedToken = typeof frame.writeToken === "string" ? frame.writeToken : "";
		const canWrite = timingSafeEqual(this.writeTokenText, receivedToken);
		this.guests.set(peer, { peer, canWrite, name: `guest ${peer}` });
		await this.enqueueFrame({
			t: "welcome",
			header: await this.getHeader(),
			entries: await this.getEntries(),
			state: this.buildState(this.ctx),
			agents: [],
			readOnly: !canWrite,
		}, peer);
		await this.broadcastState(this.ctx);
	}

	private async handlePrompt(peer: number, frame: AnyRecord): Promise<void> {
		const guest = this.guests.get(peer);
		if (!guest?.canWrite) {
			await this.enqueueFrame({ t: "error", message: "prompting is disabled on a read-only link" }, peer);
			return;
		}
		const message = frame.text ?? frame.message ?? frame.content;
		if (typeof message !== "string" && !Array.isArray(message)) {
			await this.enqueueFrame({ t: "error", message: "invalid prompt" }, peer);
			return;
		}
		const options = this.ctx.isIdle() ? undefined : { deliverAs: "steer" };
		await this.api.sendUserMessage(message, options);
	}

	private async handleAbort(peer: number): Promise<void> {
		const guest = this.guests.get(peer);
		if (!guest?.canWrite) {
			await this.enqueueFrame({ t: "error", message: "prompting is disabled on a read-only link" }, peer);
			return;
		}
		await this.ctx.abort();
	}

	private async getHeader(): Promise<unknown> {
		const header = this.ctx.sessionManager.getHeader?.();
		if (header) return header;
		const title = this.ctx.sessionManager.getSessionName?.() ?? basename(this.ctx.cwd);
		return {
			type: "session",
			id: this.ctx.sessionManager.getSessionId?.() ?? this.roomId,
			title,
			timestamp: new Date().toISOString(),
			cwd: this.ctx.cwd,
		};
	}

	private async getEntries(): Promise<unknown[]> {
		const entries = await this.ctx.sessionManager.getEntries?.();
		if (!Array.isArray(entries)) return [];
		return entries.filter((entry) => {
			if (!isRecord(entry)) return false;
			return typeof entry.type === "string" && SAFE_ENTRY_TYPES.has(entry.type);
		});
	}

	private buildState(ctx: AutoCollabContext): AnyRecord {
		return {
			isStreaming: !ctx.isIdle(),
			queuedMessageCount: ctx.hasPendingMessages() ? 1 : 0,
			sessionName: ctx.sessionManager.getSessionName?.(),
			cwd: ctx.cwd,
			model: ctx.model,
			thinkingLevel: undefined,
			contextUsage: ctx.getContextUsage(),
			participants: [
				{ name: Bun.env.USER ?? "anonymous", role: "host" },
				...Array.from(this.guests.values(), (guest) => ({ name: guest.name, role: "guest" })),
			],
		};
	}

	private async encryptFrame(frame: unknown, peer: number): Promise<Uint8Array> {
		const key = await this.keyPromise;
		const iv = randomBytes(IV_BYTES);
		const plaintext = encoder.encode(JSON.stringify(frame));
		const ciphertext = new Uint8Array(await crypto.subtle.encrypt({ name: "AES-GCM", iv: arrayBufferFor(iv) }, key, arrayBufferFor(plaintext)));
		const envelope = new Uint8Array(ENVELOPE_HEADER_BYTES + IV_BYTES + ciphertext.byteLength);
		new DataView(envelope.buffer, envelope.byteOffset, ENVELOPE_HEADER_BYTES).setUint32(0, peer, false);
		envelope.set(iv, ENVELOPE_HEADER_BYTES);
		envelope.set(ciphertext, ENVELOPE_HEADER_BYTES + IV_BYTES);
		return envelope;
	}

	private async decryptFrame(payload: Uint8Array): Promise<AnyRecord> {
		const key = await this.keyPromise;
		const iv = payload.subarray(0, IV_BYTES);
		const ciphertext = payload.subarray(IV_BYTES);
		const plaintext = await crypto.subtle.decrypt({ name: "AES-GCM", iv: arrayBufferFor(iv) }, key, arrayBufferFor(ciphertext));
		const frame = JSON.parse(decoder.decode(plaintext)) as unknown;
		if (!isRecord(frame)) throw new Error("invalid collab frame");
		return frame;
	}

	private enqueueFrame(frame: unknown, peer: number): Promise<void> {
		this.sendChain = this.sendChain.then(async () => {
			if (this.stopped || !this.isSocketOpen()) return;
			const envelope = await this.encryptFrame(frame, peer);
			this.socket?.send(arrayBufferFor(envelope));
		}).catch((error) => {
			this.api.logger?.warn?.("auto-collab failed to send frame", error);
		});
		return this.sendChain;
	}

	private isSocketOpen(): boolean {
		return this.socket?.readyState === 1;
	}

	private async refreshDashboard(ctx: AutoCollabContext): Promise<void> {
		try {
			const now = new Date().toISOString();
			const existing = this.dashboardRecord;
			const record = existing ?? await this.buildDashboardRecord(ctx, now);
			record.updatedAt = now;
			record.summary = await this.buildDashboardSummary(ctx);
			const token = await this.getDashboardToken();
			const response = await fetch(`${trimTrailingSlash(DASHBOARD_ORIGIN)}/api/sessions`, {
				method: "POST",
				headers: {
					Authorization: `Bearer ${token}`,
					"Content-Type": "application/json",
				},
				body: JSON.stringify(record),
			});
			if (!response.ok) throw new Error(`dashboard POST failed with HTTP ${response.status}`);
			this.dashboardRecord = record;
		} catch (error) {
			this.api.logger?.warn?.("auto-collab dashboard registration failed", error);
		}
	}

	private async buildDashboardRecord(ctx: AutoCollabContext, now: string): Promise<DashboardRecord> {
		const title = ctx.sessionManager.getSessionName?.() ?? basename(ctx.cwd);
		const terminal = Bun.env.TTY ? Bun.env.TTY.split(/[\\/]/).at(-1)! : "";
		const globalProcess = (globalThis as unknown as { process?: { pid?: number } }).process;
		const pid = typeof globalProcess?.pid === "number" ? globalProcess.pid : Number(Bun.env.OMP_PID ?? 0);
		return {
			id: await dashboardId(this.links.webLink),
			title,
			cwd: ctx.cwd,
			terminal,
			pid,
			joinLink: this.links.joinLink,
			webLink: this.links.webLink,
			summary: await this.buildDashboardSummary(ctx),
			createdAt: now,
			updatedAt: now,
		};
	}

	private async buildDashboardSummary(ctx: AutoCollabContext): Promise<string> {
		const entries = await ctx.sessionManager.getEntries?.();
		if (!Array.isArray(entries) || entries.length === 0) return "";
		const snippets: string[] = [];
		for (let index = entries.length - 1, seen = 0; index >= 0 && seen < DASHBOARD_SUMMARY_ENTRY_SCAN_LIMIT; index--, seen++) {
			const entry = entries[index];
			if (!isRecord(entry)) continue;
			const text = summarizeEntry(entry);
			if (text) snippets.push(text);
			if (snippets.length >= 2) break;
		}
		return truncateText(snippets.reverse().join(" · "), DASHBOARD_SUMMARY_MAX_CHARS);
	}

	private async getDashboardToken(): Promise<string> {
		if (this.dashboardToken !== undefined) return this.dashboardToken;
		const proc = Bun.spawn(["secret", "get", TOKEN_NAME], { stdout: "pipe", stderr: "ignore" });
		const text = await new Response(proc.stdout).text();
		const exitCode = await proc.exited;
		if (exitCode !== 0) throw new Error(`secret get ${TOKEN_NAME} failed`);
		this.dashboardToken = text.replace(/\r?\n$/, "");
		return this.dashboardToken;
	}

	private async deleteDashboard(): Promise<void> {
		const id = this.dashboardRecord?.id;
		if (!id) return;
		try {
			const token = await this.getDashboardToken();
			const response = await fetch(`${trimTrailingSlash(DASHBOARD_ORIGIN)}/api/sessions/${encodeURIComponent(id)}`, {
				method: "DELETE",
				headers: { Authorization: `Bearer ${token}` },
			});
			if (!response.ok && response.status !== 404) throw new Error(`dashboard DELETE failed with HTTP ${response.status}`);
			this.dashboardRecord = undefined;
		} catch (error) {
			this.api.logger?.warn?.("auto-collab dashboard cleanup failed", error);
		}
	}

	private clearTimers(): void {
		if (this.stateTimer !== undefined) {
			clearTimeout(this.stateTimer);
			this.stateTimer = undefined;
		}
		if (this.refreshTimer !== undefined) {
			clearInterval(this.refreshTimer);
			this.refreshTimer = undefined;
		}
	}
}

function buildLinks(roomId: string, roomKey: Uint8Array, writeToken: Uint8Array): Links {
	const wsOrigin = normalizeRelayOrigin(RELAY_URL);
	const wsUrl = `${wsOrigin}/r/${roomId}`;
	const url = new URL(wsOrigin);
	const secret = base64url(concatBytes(roomKey, writeToken));
	const joinLink = url.protocol === "ws:" ? `${wsUrl}.${secret}` : `${url.host}/r/${roomId}.${secret}`;
	const webLink = `${trimTrailingSlash(DASHBOARD_ORIGIN)}/client/#${joinLink}`;
	return { wsOrigin, wsUrl, joinLink, webLink };
}

function normalizeRelayOrigin(input: string): string {
	const url = new URL(input);
	const local = isLocalHost(url.hostname);
	if (url.protocol === "wss:" || url.protocol === "https:") {
		url.protocol = "wss:";
	} else if (url.protocol === "ws:") {
		if (!local) throw new Error("non-local ws auto-collab relay URLs are refused");
		url.protocol = "ws:";
	} else if (url.protocol === "http:") {
		url.protocol = local ? "ws:" : "wss:";
	} else {
		throw new Error(`unsupported auto-collab relay protocol: ${url.protocol}`);
	}
	url.pathname = url.pathname.replace(/\/$/, "");
	url.search = "";
	url.hash = "";
	return url.toString().replace(/\/$/, "");
}

function isLocalHost(hostname: string): boolean {
	return hostname === "localhost" || hostname === "127.0.0.1" || hostname === "::1" || hostname === "[::1]";
}

function randomBytes(length: number): Uint8Array {
	const bytes = new Uint8Array(length);
	crypto.getRandomValues(bytes);
	return bytes;
}

function concatBytes(...chunks: Uint8Array[]): Uint8Array {
	let total = 0;
	for (const chunk of chunks) total += chunk.byteLength;
	const out = new Uint8Array(total);
	let offset = 0;
	for (const chunk of chunks) {
		out.set(chunk, offset);
		offset += chunk.byteLength;
	}
	return out;
}

function arrayBufferFor(bytes: Uint8Array): ArrayBuffer {
	return (bytes.buffer as ArrayBuffer).slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
}

function base64url(bytes: Uint8Array): string {
	return BufferCtor.from(bytes).toString("base64").replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

function timingSafeEqual(expected: string, actual: string): boolean {
	let diff = expected.length ^ actual.length;
	const length = Math.max(expected.length, actual.length);
	for (let index = 0; index < length; index++) {
		diff |= expected.charCodeAt(index % expected.length) ^ actual.charCodeAt(index % Math.max(actual.length, 1));
	}
	return diff === 0;
}

function summarizeEntry(entry: AnyRecord): string {
	const type = typeof entry.type === "string" ? entry.type : "";
	if (!SAFE_ENTRY_TYPES.has(type)) return "";
	const text = truncateText(extractEntryText(entry), DASHBOARD_SUMMARY_SNIPPET_MAX_CHARS);
	if (!text) return "";
	return `${entryLabel(entry, type)}: ${text}`;
}

function entryLabel(entry: AnyRecord, type: string): string {
	if (type === "branch_summary" || type === "compaction") return "Summary";
	if (type === "custom_message") return "Note";
	const role = typeof entry.role === "string" ? entry.role : typeof entry.author === "string" ? entry.author : "";
	if (role.includes("user")) return "User";
	if (role.includes("assistant")) return "Assistant";
	if (role.includes("system")) return "System";
	return "Message";
}

function extractEntryText(value: unknown, depth = 0): string {
	if (depth > 4) return "";
	if (typeof value === "string") return normalizeText(value);
	if (Array.isArray(value)) {
		const parts: string[] = [];
		for (const item of value) {
			const text = extractEntryText(item, depth + 1);
			if (text) parts.push(text);
			if (parts.join(" ").length >= DASHBOARD_SUMMARY_SNIPPET_MAX_CHARS) break;
		}
		return normalizeText(parts.join(" "));
	}
	if (!isRecord(value)) return "";
	for (const key of ["summary", "text", "content", "message", "body", "markdown"]) {
		const text = extractEntryText(value[key], depth + 1);
		if (text) return text;
	}
	return "";
}

function truncateText(value: string, maxLength: number): string {
	const text = normalizeText(value);
	if (text.length <= maxLength) return text;
	return `${text.slice(0, Math.max(0, maxLength - 1)).trimEnd()}…`;
}

function normalizeText(value: string): string {
	return value.replace(/\s+/g, " ").trim();
}

async function dashboardId(webLink: string): Promise<string> {
	const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", encoder.encode(webLink)));
	let hex = "";
	for (let index = 0; index < 8; index++) hex += digest[index]!.toString(16).padStart(2, "0");
	return hex;
}

function basename(path: string): string {
	return path.split(/[\\/]/).filter(Boolean).at(-1) ?? path;
}

function trimTrailingSlash(value: string): string {
	return value.replace(/\/$/, "");
}

function isRecord(value: unknown): value is AnyRecord {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}
