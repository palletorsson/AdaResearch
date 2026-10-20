# A museum that helps us remember

11 October 2026 · [Open the atlas](http://localhost:3003/museum-memory)

The museum can become an external memory with an address for each idea. Its most useful compression is already present in the work: one point returns with another capacity. We do not need to explain a new unrelated object at every doorway. Position, permission, relation, record and representation can be recovered through the same developing thing.

The danger is losing a distinction while shortening the description. “Keep the drawing” does not say whether it survives restart, contains time, retains every hand sample, or preserves the original when another representation is made. A useful memory must help us reopen those questions.

## What exists now

The new atlas reads all 25 current spine sequences and 208 halls. It uses the existing museum's images and the existing project-memory notes, not a new fictional architecture. The route is schematic; the physical halls need not share this layout.

Six opening halls have authored capsules checked against selected current tutorial passages and the openings of their reflective texts. The remaining halls expose explicitly labelled Learning elements from current `tutorial.md`. An absent capsule stays visibly absent. We have not reviewed every lesson or claimed that every subject list is pedagogically correct.

Each capsule preserves:

- the familiar object and the capacity brought into the room;
- the operation introduced and the distinctions to retain;
- what travels onward;
- a separate reflective question;
- what the compressed text does not establish;
- the source versions against which it was written.

Working notes remain editable in the revisioned Project memory interface. Current packets include those notes and the shared working brief. Older findings retain their acceptance status, method and source fingerprints. Acceptance, unchanged bytes and successful behaviour are different things.

## What we can borrow from DeepSeek-OCR

DeepSeek-OCR studies optical context compression: document text is presented as an image, encoded into vision tokens and decoded. The authors report about 97% OCR precision when text tokens are within ten times the vision-token count; at 20× compression their reported accuracy is about 60%. Those are their OCR experiments, not evidence that reasoning, code correctness or an author's intention survives at the same rate. [Primary paper](https://arxiv.org/abs/2510.18234).

This suggests preserving a rendered source page instead of immediately replacing it with a paraphrase. The encoder remains lossy; a missing negation or indentation can matter much more than its share of the character count. DeepSeek's token counts belong to its model and encoder; they do not describe the cost of showing an image to this assistant. [Official implementation](https://github.com/deepseek-ai/DeepSeek-OCR).

We should therefore distinguish three operations:

| Operation | Prototype | What can be lost |
| --- | --- | --- |
| Selection and semantic compression | [Six-room atlas](plate.png), AI packets | Explanations, exceptions, cultural context and unselected concerns |
| Optical encoding without summarisation | [Complete Point Zero source leaf](source-leaf.png), [exact source snapshot](source-leaf.md) | Legibility and details during later image encoding/OCR |
| Retrieval | Whole museum → sequence → hall → current source | Relevant material outside the chosen route or query |

The semantic atlas is a visual index, not a claim that putting text on a wall makes it more intelligible. The sources, short briefs and images can be used together. A future model may find the optical leaf economical, but that requires a model-specific test.

## A useful friction in the evidence

An October 4 finding inspected an in-memory production TraceData path and did not establish survival through restart. The later tutorial has an explicit `TraceArchive` file handoff into Grid. Both statements need their source and scope. Collapsing them into one timeless “Trace saves” statement would erase a meaningful change—and confuse a production artifact with a learner study.

The new Trace packet retains local metres, no timestamps, intentional release, later-save replacement and the same-project requirement. The Grid packet preserves original positions, independent copied resources and the fact that rounding cannot recover an arbitrary original. It also keeps their reflective questions. These are the small details we want compression to carry.

## Verification and limits

Ten read-only/backend tests cover every live hall address, required Trace/Grid distinctions, current versus changed versus missing sources, changed shared rules, old-finding provenance, editable-note carry, undeclared subject inference and invalid addresses. The deliberate source mutation occurs in a temporary fixture; the real manuscript is not edited. This is a structural memory regression, not an independent AI comprehension test.

The new UI and API pass a focused TypeScript check. Browser checks exercise room navigation, exact-source opening and packet generation. The optical outputs were visually inspected for readable text and clipping. No new Godot, headset, OCR or learner trial is claimed.

The [manifest](manifest.json) records source hashes and whitespace word counts. The small packet and the full manuscripts contain different information; their size ratio is not a lossless compression ratio. This pass did not run DeepSeek-OCR, download model weights or measure vision tokens. It did not change `tutorial.md`, `final.md`, museum geometry or the spine order.

## The next experiment

Give separate fresh readers the same tasks, with four inputs: original text; short text packet; source page image; and the museum atlas with permission to retrieve sources. Keep a withheld answer rubric and identical retrieval allowances where comparisons require them. Test exact constraints, reasoning and refusal to guess separately from ordinary OCR similarity.

Include known traps: missing label creation; frames mistaken for seconds; distance taught in Coordinates; no timestamp interpreted as timed replay; an old session-only finding treated as the later archive; and rounding treated as reversible. Change one dependent source and test whether the reader asks to reopen it. Record corrections and extra retrieval, not just a final answer score.

The method succeeds if it makes the next action better grounded with less context-reading work. It need not fit everything into one image. Keeping a reliable route back to what was omitted is part of the design.

[Edit working notes](http://localhost:3003/project-memory) · [Frozen project packet](project.md) · [Trace packet](map-Point_Trace.md) · [Grid packet](map-Point_Line_Grid.md)

The repository's `doc/book/memory/museum/README.md` contains the editing contract and CLI instructions. These report packets are frozen examples; use **Make AI packet** for current evidence.
