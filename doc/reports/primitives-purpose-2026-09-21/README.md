# Primitives: paragraph, artifact and corpus

This local editorial pilot reads all ten halls in the current `primitives.json` map order. It compares every prose paragraph and footnote in the saved `final.md` snapshot with its proposed reader-facing purpose, artifact or spatial anchor, and surrounding map-local Markdown corpus. Code and headings remain visible as structural blocks.

These notes propose editorial functions. They do not establish the author's private motivation, prove a historical derivation, score quality, or require every paragraph to teach a new technical operation. Interpretive and poetic passages may deserve their place through hesitation, pleasure, selective attention and connections across halls.

The audit checks implementation files and configuration where claims require them. Source inspection is not a headset walk-through. Artifact descriptions, curriculum group lists and old placement records can drift; exact active configuration keys matter.

## Outputs

- `early.json`: Point One, Lines, Trace.
- `middle.json`: Grid, Triangle Context, Polyhedra, Animated Cube.
- `late.json`: Ignorance, Portals, Melencolia.
- `audit.json`: combined validated study with current source fingerprints and manuscript blocks.
- `../../research/possible-bodies/primitives-purpose.html`: interactive text/evidence view.

Each paragraph has a proposed purpose, artifact anchor, reader movement, reason for its place, what would disappear without it, and any improvement opportunity. Evidence is indexed per hall with exact path, line range and excerpt. A small list of revision candidates identifies whether the next step belongs to text, artifact, staging, corpus or a further review.

## Rebuild

```powershell
python tools/primitives_purpose_view.py
```

The builder fails on incomplete paragraph coverage, stale manuscript hashes, missing corpus inventory, invalid evidence paths, excerpt/line mismatches or broken evidence/action links. It writes no manuscript, artifact or map file and makes no API request. The resulting HTML must be copied to the corresponding Ada Encyclopedia `public/research/possible-bodies/` path to update the local website.

## Verification

Completed coverage: 10 halls, 313 prose/footnote readings, 231 evidence excerpts, 180 source-file fingerprints. Nineteen browser checks passed, including each hall’s full paragraph coverage, source dialogs, plain text, review filtering, action-to-passage navigation and a 430px viewport without horizontal overflow. Receipts and desktop/mobile screenshots are in `ada_run/book_registers/visual-check/purpose-*`.
