# Primitives encounter cards

Review draft requested by Palle: **cards for the whole sequence first**, before further mechanics are built.

- [One hall at a time](index.html)
- [Whole route](overview.html)
- [Print view](print.html)
- [Compact context and cards](cards.json)

Fifteen halls follow the current Primitives spine. Fourteen Void floors: Grid remains on Trace's floor. The cards preserve the distinction between the museum's wider field, selected tutorial operations, and reflective writing.

Each card names what the learner brings, changes, holds fixed, notices, checks and carries onward. A short alternative supports future AI context. The shared instructions at the top of `cards.json` are part of that context; do not read one short card as a complete specification.

The four largest room/tutorial gaps are the octahedron generator comparison, held-sphere resolution study, profile/path comparison control, and bounded-error stopping-rule instrument. These are proposals. Existing artifacts remain the surrounding material. Point Zero's counter pause is also a proposal, not an installed control.

No runtime code, shared layouts, `tutorial.md` or `final.md` were changed by this deck. Images reuse earlier native Godot captures; they do not preview proposed controls or guarantee the latest manual editor placement. Cube's controlled trial was already implemented before this card pass; its recorded native checks are linked and explicitly distinguished from proposed acceptance criteria.

## Editing

Edit `cards.json`, then run from the repository root:

```text
python doc/book/iterations/2026-10-19-primitives-encounter-cards/build.py
```

`template.html` supplies presentation; `build.py` generates static pages. Static navigation works both through the existing read-only book-review route and as local files, without altering the web server's script policy.

The build checks spine order, map-to-floor assignment, required fields and 80 local image/source references. Browser review verified rendered cards, Next navigation, the whole-route links and expansion of the compressed summary. These are document checks, not new game tests or student learning evidence.

## Continue from here

Review one card at a time. Keep an accepted encounter's teaching focus when expanding it. Resolve actual dependencies from the linked tutorial and repository source paths. Only then implement the missing interaction, write the focused code change and run an appropriate native assertion. Preserve the source trace and name what actually carries between lessons; do not imply all halls share one persistent runtime object.

Source review also found older museum context in Point One's reflective text (sun/white final sphere) and Portals (twenty rings rather than seven). Those texts remain untouched. Preserve their reflection and adjust concrete staging when that hall is reviewed.
