# Colour · what changes

Compact review dated 2026-10-04. [Open index.html](index.html) through `/book-review/doc/book/iterations/2026-10-04-colour-capacity-return/index.html`.

Eight cards show only the short before, after and reason strings in `changes.json`. Full storyboards and implementation detail stay out of the review. Each card links to the selected map's open, focused project-memory workspace; the reader reviews its finding there. This page has no approval action. Acceptance retains a teaching plan and does not implement code or full lessons.

## Publish

After `changes.json` and `summaries.diff` are final, run from the repository root:

```powershell
python -X utf8 doc/book/iterations/2026-10-04-colour-capacity-return/publish.py
```

The publisher writes only `index.html` and this README. It validates eight map IDs in the existing order, required short strings, image files and original capture dates. The exact-diff link appears when `summaries.diff` exists. There are no scripts, remote fonts, external dependencies or approval requests.

## Text provenance

- Input: `changes.json`, SHA-256 `a38b32dea1e3ec02ca4f108ddb48558bc81572c07a1dadf7134b0bdd1faa10e7`.
- The source is the author's compact before/after account; it is not a verbatim display of complete storyboards.
- Map links use `/project-memory?scope=map%3A<id>&detail=1&view=focused`. They open the selected workspace; they do not target a finding ID or save an acceptance.

## Earlier museum images

All photographs are reused; none depict a visual change made by this summary update. Default images and dates come from `doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json`. Grid and Paint use the second route image to show the museum view rather than a composite or isolated texture. Three local review overrides follow photographs embedded in the current final texts and preserve their earlier publication dates. The global route metadata is unchanged.

| Map | Image | Original date |
| --- | --- | --- |
| `Color_Context_Placed` | `../2026-10-04-museum-tutorial-storyboards/images/Color_Context_Placed-1.webp` | 2026-09-28 |
| `Color_Flashlight` | `../2026-10-02-light-an-opening/figures/pink-threshold.png` | 2026-10-02 |
| `Color_Nails` | `../2026-10-04-museum-tutorial-storyboards/images/Color_Nails-1.webp` | 2026-09-28 |
| `Color_Rainbow` | `../2026-10-04-museum-tutorial-storyboards/images/Color_Rainbow-1.webp` | 2026-09-28 |
| `Color_Pillar` | `../2026-09-28-pillar-colour-ceiling/ceiling-and-column.png` | 2026-09-28 |
| `Color_Grid_Pallet` | `../2026-10-04-museum-tutorial-storyboards/images/Color_Grid_Pallet-2.webp` | 2026-09-28 |
| `Color_Paint` | `../2026-10-04-museum-tutorial-storyboards/images/Color_Paint-2.webp` | 2026-09-28 |
| `Color_Walls` | `../2026-10-01-office-open-colour/layers-glass.png` | 2026-10-01 |

Evidence for the three review-only overrides:

- `Color_Flashlight`: `doc/book/iterations/2026-10-02-light-an-opening/VALIDATION.json`.
- `Color_Pillar`: `doc/book/iterations/2026-09-28-pillar-colour-ceiling/source_manifest.json`.
- `Color_Walls`: `doc/book/iterations/2026-10-01-office-open-colour/source_manifest.json`.
