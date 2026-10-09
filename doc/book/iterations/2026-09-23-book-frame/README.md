# Book framing drafts · 23 September 2026

A reading edition of the short preface and substantial QFEP afterword, with the active museum spine between them. Both are working drafts for revision.

Read locally: <http://localhost:3003/book-review/doc/book/iterations/2026-09-23-book-frame/index.html>.

## Canonical manuscripts

- [Before the first point](../../preface.md)
- [QFEP afterword](../../afterword-qfep.md)
- [Editorial structure and development plan](../../BOOK_FRAME.md)

Edit these canonical files, then rebuild from the repository root:

```powershell
python doc/book/iterations/2026-09-23-book-frame/build.py
```

The builder requires Python `markdown` and `beautifulsoup4`. It creates the reading page, linked source snapshots and manifest. The snapshots under `sources/` are generated reading copies. The manifest records the manuscript and curriculum source fingerprints.

## Publication order

Preface → the complete active spine → QFEP afterword. At this edition the spine contains 24 sequences and 196 halls, from Point_One through PostCrisis_Synthesis. The afterword therefore follows the Post-Foundations Crisis halls as well as the QFEP Laboratory. These framing texts are book matter, not additional museum maps.

The preview lists the active sequences and links to the current first and last hall texts; it does not duplicate the whole manuscript. The book editor has separate links to the preface and afterword. These open in another tab to preserve unsaved edits. The older book index and manuscript exporter need a separate alignment pass before publication; this edition does not claim to update those exports.

## Verification

`verification.json` records 29 passed checks: local source URLs, publication order, eight developed essay sections, nine rendered footnotes, the full spine endpoint, desktop and mobile overflow, navigation, editorial notes, and the two live book-editor links. Desktop and mobile screenshots were visually reviewed. All 42 manifest fingerprints matched the sources at completion.

The essay's source notes distinguish project documents, current chapter evidence and the primary Free Energy Principle reference. Ethical proposals and exploratory formulae are not presented as experimentally established conclusions. No hall text, map, runtime behaviour or sequence order was changed by this framing task. Headset testing does not apply to these manuscript changes and was not performed.

## Next writing pass

Develop a sustained case from the middle of the spine and a case where two bodies have conflicting needs. Then revise the essay against those cases, reader/play evidence, and a fuller primary-source review. The editorial notes also reserve space for access, credits and the role of AI collaboration. These are development tasks, not completed findings.

The exact book-editor insertion is documented by `integration/receipt.json`; `integration/book-page-before.tsx` preserves its previous contents.
