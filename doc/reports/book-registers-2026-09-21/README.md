# Book registers: paragraph annotation

This workflow annotates the language of `commons/maps/*/final.md` in a separate snapshot. It never rewrites those files. The active spine is distinguished from final.md files outside it.

## Status

Prepared locally. No book paragraphs have been sent to TypeSafe. Automatic approval review blocked the proposed two-request calibration because sending the book text to that external destination requires explicit transfer approval. The earlier seed-artifact tests did not transfer book text.

The local review page is `/research/possible-bodies/book-registers.html`. Pending paragraphs are unclassified, not zero-scored. Displayed taxonomy colors describe the proposed categories and do not imply model results.

## Prepared scope

- 209 final.md files: 196 active spine halls and 13 files outside the spine.
- 3,525 prose and footnote paragraphs; 353 code blocks and 260 headings retained structurally.
- 441 proposed API requests, pinned to jev-1.13.0, with all requests within the conservative context check.
- Conservative input-cost estimate: $0.95 at the current documented rate. Actual usage could differ; the runner keeps usage receipts and has a $1 estimated-input budget.
- Zero book-tagging API calls and zero model labels so far. All final.md source fingerprints unchanged.

The annotator recovered a malformed code-fence boundary in Crisis_Synthesis (two closing backticks on line 43) in its parsing view only. It also retains footnotes that CommonMark would otherwise interpret as link definitions. The report marks recovered/ambiguous regions for review. This does not repair the source Markdown or the book renderer.

## Text visualization

The reader can display register colors next to the actual prose, with overlapping tags and a plain-text layer for comparison. An editorial demonstration covers all 30 prose/footnote blocks of Point_Trace and nine other sample passages. Those 39 readings are stored separately in `editorial-examples.json`, labelled as provisional assistant editorial judgments. They contain no probabilities and are not Jev output.

Examples only apply when both the source-file hash and paragraph hash match the displayed snapshot. The model annotation snapshot remains unchanged and pending. This local visualization does not authorize or perform external tagging.

```powershell
python tools/book_registers_view.py --data ada_run/book_registers/20260921-ready/annotations.json --editorial-examples doc/reports/book-registers-2026-09-21/editorial-examples.json --out doc/research/possible-bodies/book-registers.html
```

## Editorial use

Eight overlapping registers: technical; embodied/instructional; inquiry/discovery; critical; poetic; contextual/scholarly; connective; interpretive. A paragraph may perform several. These describe what writing does, not its quality or truth. No ratio is a writing target. An algorithm explaining its limits is not automatically critical; poetic vocabulary is not automatically poetry.

`calibration.json` contains twelve provisional assistant editorial readings for discussion. They are not independent human ground truth. In particular the boundary between inquiry, interpretation and critique needs review.

Jev's yes/no question type returns an independent probability of presence for each label. Values do not sum to one. The viewer's 0.65 selection and 0.35–0.65 review band are editorial conventions, not empirically calibrated thresholds for this book. Keep ambiguity and allow corrections.

Headings and code blocks remain visible as structural blocks. We do not infer poetic or technical register merely from a code fence; code is not included in the model-tagged paragraph totals.

## Implementation

- `tools/book_registers.py`: source-span parser, ordered corpus snapshot, bounded requests, exact-payload cache and validation.
- `tools/book_registers_taxonomy.json`: versioned definitions, independent of the manuscript.
- `tools/book_registers_view.py`: self-contained local report renderer.
- `ada_run/book_registers/20260921-ready/prepared/`: exact proposed requests, generated offline.
- `ada_run/book_registers/20260921-ready/annotations.json`: source snapshot, hashes, pending or validated tags and run summary.

The API state contains paragraph text, hall name, brief surrounding context and heading. Questions explicitly name the target paragraph, because API question keys themselves are not used in inference. No keys, artifact source code, private test diagnostics or other documents are sent. Each valid result records the pinned model and request hash. Changes to text, context, definitions or model invalidate the corresponding cached request; edited sources are detected again at the end of a run.

## Run locally

```powershell
python tools/book_registers.py --mode prepare
python -m unittest tools.test_book_registers -q
```

After explicit approval to send the book text and context to TypeSafe:

```powershell
python tools/book_registers.py --mode live --batch-size 8 --workers 3 --max-requests 450 --max-cost-usd 1
python tools/book_registers_view.py --data ada_run/book_registers/20260921-ready/annotations.json --out doc/research/possible-bodies/book-registers.html
```

The stored `TYPESAFE_API_KEY` is read only for live mode. No credentials enter source files, requests, reports or browser code. The live run uses up to three concurrent requests, validates every expected answer, rejects wrong model receipts, preserves failures, and does not retry automatically. A restart reuses valid exact-payload cache entries.

The dollar cap uses a conservative UTF-8-byte-plus-overhead input estimate at the documented rate, not an account billing guarantee. Actual usage is retained for calculating the estimate from consumed tokens. No purchase, subscription or credit top-up is performed.

## References checked 2026-09-21

- [TypeSafe API: Noul questions and strict response shape](https://docs.typesafe.ai/api)
- [Models: pinned model, context limits and input-token pricing](https://docs.typesafe.ai/models)
- [Confidence: interpreting model distributions](https://docs.typesafe.ai/confidence)

### Reading-view verification

The text-first preview was checked in isolated Chrome sessions at 1440px and 430px. All 30 Point Trace prose/footnote blocks and their editorial annotations appeared. Register filtering, plain text, pending Jev layer, analysis view and superscript footnotes passed browser checks; the mobile viewport had no horizontal overflow. The 23 parser tests also passed. All 209 manuscript hashes still match the snapshot.

Local browser receipts and screenshots are in `ada_run/book_registers/visual-check/` (`browser-checks.json`, `reading-desktop.png`, `reading-mobile.png`). No Jev requests were made for this visualization.
