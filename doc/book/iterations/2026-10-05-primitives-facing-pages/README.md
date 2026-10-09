# Primitives — facing pages

User request: show the first chapter with tutorial.md on the left and final.md on the right.

Open `index.html` through the Encyclopedia's `/book-review/` route. Fifteen hall spreads follow the current `commons/maps/sequences/primitives.json` order. Each side scrolls independently. Previous, next and chapter contents are ordinary links, compatible with the review server's existing script restrictions.

This is a reading snapshot dated 5 October 2026, not a manuscript rewrite. Canonical text is preserved in full, including code, images and footnotes. Godot, Columns and Profiles are labelled “Teaching intent” because their tutorial sources remain plans. The two tracks are paired by hall, not by paragraph.

Run `python doc/book/iterations/2026-10-05-primitives-facing-pages/build.py` from the museum root to refresh this view from the canonical sources. It also refreshes the source snapshots and SHA-256 manifest. Markdown, code fences and footnotes are rendered; relative references are resolved or copied into the review artifact. No museum code or manuscript files are edited.

Validation: 15 pairs, 30 complete source texts, no duplicate fragment IDs, all internal footnote targets resolved, 70 local HTTP references returned 200, and canonical hashes remained unchanged. Browser checks cover chapter navigation, complete Lines code, independent scrolling, footnotes, the teaching-intent label and desktop layout. See `view-check.json` and `preview.jpg`.

This is a screen reading view, not a typeset print edition.
