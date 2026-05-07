Read the prose file at the path given in $ARGUMENTS and augment it with TODO blocks.

## How to parse $ARGUMENTS

- The **first whitespace-delimited token** is the file path to read.
- Everything after that is the user's editorial guidance: things to expand, add, or cite.

Example invocations:
- `/augment-prose ~/writing/ch5.md Add sensory detail to the opening scene. Reference: Smith 2020 ch3`
- `/augment-prose notes/draft.md Strengthen the argument in paragraph 2.`

## Steps

1. Read the file at the path extracted from $ARGUMENTS.
2. Parse the remaining arguments as editorial guidance.
3. Walk through the prose section by section (use paragraph breaks or headings as natural boundaries).
4. After each section where the editorial guidance is relevant — or wherever additional development, citation, or expansion would strengthen the writing — insert a TODO block.
5. Output the complete augmented text: original prose unchanged, with TODO blocks interspersed.

## Rules

- **Do not alter, paraphrase, or rewrite any of the existing prose.** Copy it verbatim.
- Place TODO blocks at paragraph or section boundaries, never mid-sentence.
- Each TODO block must contain specific, actionable bullet points drawn from the user's guidance. Be concrete: name the reference, describe the detail to add, identify the claim that needs support.
- If the guidance applies to multiple places, add a TODO block at each relevant location.
- If a section needs no attention, include it without a TODO block.

## TODO block format

Use LaTeX line comments. Each TODO block looks like this:

```
% TODO:
% - specific action to take
% - another bullet if needed
```

Place the block on its own line(s), between paragraphs or sections.

## Output

Return the full augmented prose as plain text (suitable for a `.tex` file). Do not add any commentary outside the augmented prose itself.
