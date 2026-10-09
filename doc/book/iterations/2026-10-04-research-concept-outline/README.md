# Research concept outline

User request: see only the bearing algorithmic and programming concepts, as a list in columns on one page.

Open [the outline](http://localhost:3003/research-outline). The default view follows the current 25-sequence museum route, down each column. Search finds a concept's returns; optional hall references locate its encounters. A compact [Markdown version](outline.md) supports reading the whole selection into context.

The index is an authored selection from the current route and its source material. It is not an exhaustive code inventory, a prerequisite graph or a certificate of taught mastery. Reflective halls can contribute a formal concept without becoming required programming lessons. Repeated concepts can perform new work; retain those returns where they matter.

The first four sequences now include the proposed foundation progression: 16 Primitives, 10 Transformation, 7 Arrays and 10 Colour entries. The whole index contains 215 entries in 25 sequences. Twenty entries carry a **proposed** label: they describe teaching additions, not installed or verified lessons. A concept without that label is still not proof of a finished tutorial or learner mastery.

Open **Foundations before Randomness** above the columns for the 12 capabilities: first encounter, practice, independent use, and a visual comparison. The four sequence exits link to all 35 hall picture cards; the panel also describes consolidation through Waves and the practical Randomness checkpoint. This panel reads the original `foundations-before-randomness/plan.json` and `foundations-visible/visual-plan.json` at page load. It does not maintain a separate copy of the curriculum. Search now includes hall IDs and titles as well as concepts and sequences. The default and printed outline keep the compact column view.

## Maintain the outline

Edit `concepts-early.json` and `concepts-late.json`, keeping concise labels and supported hall references. Use `"status": "proposed"` for planned additions. Update the original foundation or visual plan when a teaching placement changes, then rebuild their respective review pages. Run:

```powershell
python -X utf8 doc/book/iterations/2026-10-04-research-concept-outline/build.py
```

This creates `concepts.json`, `outline.md` and source hashes in `manifest.json`. The web page reads the JSON through the existing configured repository path. Rebuilding validates sequence order and referenced halls but does not prove the editorial selection is complete or correct. Revisit the selection when the research changes; it does not constrain future sequence order.

No museum logic, placements, tutorial summaries, full chapters or acceptance decisions are changed by this index.
