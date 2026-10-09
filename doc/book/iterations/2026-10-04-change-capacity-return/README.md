# Change · what changes

Compact review dated 2026-10-04. [Open index.html](index.html) through `/book-review/doc/book/iterations/2026-10-04-change-capacity-return/index.html`.

Two cards show only the short before, after and reason strings in `changes.json`. Full storyboards and implementation detail stay out of the review. Each card links to the selected map's open, focused project-memory workspace; the reader reviews its finding there. This page has no approval action. Acceptance retains a teaching plan and does not implement code or full lessons.

## Publish

After `changes.json` and `summaries.diff` are final, run from the repository root:

```powershell
python -X utf8 doc/book/iterations/2026-10-04-change-capacity-return/publish.py
```

The publisher writes only `index.html` and this README. It validates two map IDs in the existing order, required short strings, image files and recorded collection dates. Links appear when `summaries.diff` and the local `CHANGE.md` teaching-guide copy exist; the publisher does not write either input. There are no scripts, remote fonts, external dependencies or approval requests.

## Text provenance

- Input: `changes.json`, SHA-256 `85326c58e45af191186aec274f41ad93e3f0d0808b92d58ef740b7c2938e6cca`.
- The source is the author's compact before/after account; it is not a verbatim display of complete storyboards.
- Map links use `/project-memory?scope=map%3A<id>&detail=1&view=focused`. They open the selected workspace; they do not target a finding ID or save an acceptance.

## Earlier museum images

All photographs are reused; none depict a visual change made by this summary update. The Flow image and both recorded collection dates come from `doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json`. Flow Field uses the second route image to show the installed arrows and trails. Change Intro uses its current final text’s slope-workbench image from the same source collection. Dates are explicitly labelled as collection dates; the 2026-09-25 source folder name is retained and no exact capture-day claim is made. The global route metadata is unchanged.

| Map | Image | Collection date |
| --- | --- | --- |
| `Change_Intro` | `../2026-09-25-change-review-comments/intro/two-readings-near.png` | 2026-09-28 |
| `Flow_Field` | `../2026-10-04-museum-tutorial-storyboards/images/Flow_Field-2.webp` | 2026-09-28 |

Evidence for the review-only override:

- `Change_Intro`: `doc/book/iterations/2026-09-25-change-review-comments/intro/source_manifest.json`.
