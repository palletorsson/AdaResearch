# First reading proof — 30 September 2026

Built on 29 September from the current working tree. The edition date is the planned printing date.

The current print file is [AdaResearch_Reading_Proof_2026-09-30.pdf](../../../output/pdf/AdaResearch_Reading_Proof_2026-09-30.pdf). The older 25 September PDF in this directory is not this edition.

## Print

- A4 portrait, actual size / 100%.
- Double-sided, flip on the long edge: 580 pages / 290 sheets.
- Retain colour for the figures and colour studies. No bleed or crop marks are needed for this reading copy.
- Check a few sample pages on the intended printer before printing the whole copy.

## Contents and scope

25 sequences and all 204 active halls, assembled in current spine order from `final.md`, with the preface, Day Zero and QFEP afterword. Includes 101 figures and the 349 code blocks already in the manuscript. Separate tutorial and technical files are not appended.

The afterword's internal editorial checklist is excluded. Three stale references in the afterword were corrected: arrival points to Point Zero; the tolerance encounter points to Point Coordinates. No wider rewriting was undertaken for this export.

The PDF has numbered contents, chapter footnotes, 233 navigation bookmarks, 11 pt body type and 28 mm side margins. A small number of chapters use tighter paragraph spacing to avoid near-empty trailing pages; no prose was cut for pagination. Long code blocks can break across pages. Authoring annotations and internal measurement markers do not appear in the PDF.

## Verification

All 580 pages passed the automated page-area, missing-glyph and blank-page checks. All 4,784 compared text blocks from the assembled manuscript were found in their PDF chapters. All assembled internal links resolve; there are no duplicate document IDs. Pagination stabilized before the contents were finalized. Representative prose, code, image and footnote pages were inspected visually, along with contact sheets across the book. Physical printer output has not been tested.

The exact source hashes and section page numbers are in [the manifest](../../../output/pdf/reading-proof-2026-09-30-manifest.json). A [manuscript snapshot](../../../output/pdf/reading-proof-2026-09-30-manuscript.zip) preserves the text, sequence definitions, manifest and builder scripts. Original figure files are identified by hash in the manifest and embedded in the PDF; they are not included in the text snapshot.

## Rebuild

From the repository root:

```powershell
python tools/build_reading_proof.py --date 2026-09-30
python tools/check_reading_proof.py
```

The build uses local Chrome/Edge, Python Markdown, Beautiful Soup, Pillow, PyMuPDF, pypdf and reportlab. It fails on missing chapters or images, changed sources during rendering, or unstable contents pagination. QA renders and reports are under `tmp/pdfs/reading-proof-2026-09-30/qa/`.

Use a new edition date for a later proof so this printed reference remains stable. The older `build_book.py` here is the previous exporter; the current command is above.
