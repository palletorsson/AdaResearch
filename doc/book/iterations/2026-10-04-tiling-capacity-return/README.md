# Tiling · what changes

Compact review dated 2026-10-04. [Open index.html](index.html) through `/book-review/doc/book/iterations/2026-10-04-tiling-capacity-return/index.html`.

Eight cards show only the short before, after and reason strings in `changes.json`. Full storyboards and implementation detail stay out of the review. Each card links to the selected map's open, focused project-memory workspace; the reader reviews its finding there. This page has no approval action. Acceptance retains a teaching plan and does not implement code or full lessons.

## Publish

After `changes.json` and `summaries.diff` are final, run from the repository root:

```powershell
python -X utf8 doc/book/iterations/2026-10-04-tiling-capacity-return/publish.py
```

The publisher writes only `index.html` and this README. It validates eight map IDs in the existing order, required short strings, image files and original capture dates. The exact-diff link appears when `summaries.diff` exists. There are no scripts, remote fonts, external dependencies or approval requests.

## Text provenance

- Input: `changes.json`, SHA-256 `558a8c8165582e018eb0832c7077433a88e3a3489d036dfe2d4bd10c16d5c7d3`.
- The source is the author's compact before/after account; it is not a verbatim display of complete storyboards.
- Map links use `/project-memory?scope=map%3A<id>&detail=1&view=focused`. They open the selected workspace; they do not target a finding ID or save an acceptance.

## Earlier museum images

All photographs are reused; none depict a visual change made by this summary update. Default images and dates come from `doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json`. Pattern Disco and Symmetry use the second route image for the held checker and installed comparison panel. Tutorial Pattern uses the museum photograph embedded in its current final text, retaining its earlier capture date. Array Patterns uses the wider entry view rather than a close view of its checker surface. The global route metadata is unchanged.

| Map | Image | Original date |
| --- | --- | --- |
| `Pattern_Disco` | `../2026-10-04-museum-tutorial-storyboards/images/Pattern_Disco-2.webp` | 2026-09-28 |
| `Pattern_Foundry` | `../2026-10-04-museum-tutorial-storyboards/images/Pattern_Foundry-1.webp` | 2026-09-28 |
| `Tutorial_Pattern` | `../2026-09-28-pattern-a-facing-return/source-pair.png` | 2026-09-28 |
| `Array_Patterns` | `../2026-10-04-museum-tutorial-storyboards/images/Array_Patterns-1.webp` | 2026-10-03 |
| `Symmetry_Seventeen` | `../2026-10-04-museum-tutorial-storyboards/images/Symmetry_Seventeen-2.webp` | 2026-09-28 |
| `Ribbon_Patterns_01` | `../2026-10-04-museum-tutorial-storyboards/images/Ribbon_Patterns_01-1.webp` | 2026-10-03 |
| `Ribbon_Patterns_02` | `../2026-10-04-museum-tutorial-storyboards/images/Ribbon_Patterns_02-1.webp` | 2026-09-28 |
| `Ribbon_Patterns_03` | `../2026-10-04-museum-tutorial-storyboards/images/Ribbon_Patterns_03-1.webp` | 2026-09-28 |

Evidence for the review-only override:

- `Tutorial_Pattern`: `doc/book/iterations/2026-09-28-pattern-a-facing-return/source_manifest.json`.
