# Footnotes: another way through the book

Working convention, 16 September 2026. The main text follows an encounter through action, observation, code and a question it can carry onward. Footnotes give readers a route into the intellectual and technical work accompanying that encounter.

## When a note earns its place

Attach the reference to the sentence where the connection becomes specific. At WALK THIS LINE, Ahmed belongs with the possibility that an unenforced instruction still changes movement. A general note on every mention of “line” would make that connection harder to find.

A first substantial note names the work, gives publication details and explains its relevance. Later notes return briefly to the particular argument being used. An early acknowledgement may precede the main note: Point One introduces Ahmed through orientation and reach; Line develops the relation between following paths and making them.

The connection is an invitation to inquiry. Distinguish an author's argument, a technical operation, our interpretation and evidence from an encounter. A coordinate frame does not demonstrate Haraway's epistemology. A stored coordinate list is not Derrida's philosophical trace. A sampling theorem has assumptions that a hand recorder may not satisfy. Keep these distinctions inside the note where they help the reader.

Use primary texts and official technical documentation where possible. Give a page only after checking that edition; otherwise identify the chapter or section. Prefer a short paraphrase to an ornamental quotation. Source links should lead to the work, a publisher or a reliable holding institution. Record access limitations in the iteration's source notes.

Notes can introduce philosophy, mathematics, artistic practice, technical history or an implementation reference. They need not all be theoretical. Add barycentric coordinates, rasterisation or Euler characteristic when a passage actually uses that question, rather than inserting a survey before the encounter needs it.

## Preserve the path and the works beside it

Footnotes do not require another primary artifact. If the relevant encounter is now a return visit, attach its note there. Panofsky accompanies the Line workshop reference; Le Corbusier accompanies Grid's Modulor return visit. Neither is brought back into the required walk merely to create a citation anchor.

The main text remains readable with note markers removed. Keep substantive argument in the main text when the reader needs it to perform or understand the operation. Optional context belongs below it; an instruction required to make an experiment work does not.

## File convention

Use standard GFM footnotes in the source document:

```markdown
The instruction may still have changed how you moved.[^point-lines-ahmed-paths]

[^point-lines-ahmed-paths]: Author, linked work, edition or year, checked section. Explain the relation to this encounter.
```

Use descriptive identifiers prefixed by the room, including for short returns. They remain distinct when chapters are assembled. Retain existing valid identifiers unless migration is necessary. The renderer supplies display numbers in reading order.

Keep definitions at the end of the file, outside code fences. They are research notes, not new artifact tags. Every marker must have one definition, and every definition a marker. Check links and backlinks in the actual Markdown renderer, individually and across the assembled reading. The encyclopedia's book view uses ReactMarkdown with remark-gfm.

Authored research notes in `final.md` are separate from historical `field_notes.md`. The legacy manuscript exporter also appends field-note sections automatically; do not confuse those development records with newly selected scholarly notes. This pass leaves that exporter unchanged and verifies the live book text and standard rendering instead of rebuilding the whole export.

The first application and source record are in [the opening-footnotes iteration](iterations/2026-09-16-opening-footnotes/README.md).
