# The tutorial manuscript

[Open the continuous reading copy](http://localhost:3003/book-review/doc/book/iterations/2026-10-04-tutorial-book/index.html).

4 October 2026. Read-only compilation of current `commons/maps/<hall>/tutorial.md` files, in the actual curriculum spine and sequence-map order. The saved storyboard route must match that order before the build succeeds. Existing source chapters remain unchanged; missing files remain visible in place. `final.md`, preparation documents and proposed foundation summaries are not substituted for tutorial text.

- `index.html`: continuous reading view, sequence navigation, visible gaps and editorial reading.
- `tutorial-book.md`: all current tutorial texts, with source/map separators, for reading or sharing.
- `sources/`: byte-for-byte snapshots of the 197 present tutorial files.
- `manifest.json`: source hashes, counts, missing files and linked-reference provenance.
- `ASSESSMENT.md`: synthesis of three parallel readers who read all 197 present files in full. Linked supplementary lessons were not comprehensively reviewed; no code execution or learner validation is claimed.

Rebuild from the main repository:

```powershell
python -X utf8 doc/book/iterations/2026-10-04-tutorial-book/build.py
```

The renderer retains chapter wording and code, adjusts heading levels for the combined structure, namespaces anchors, resolves local links and suppresses executable embedded content. Original Markdown snapshots remain available beside each chapter. Some linked text/code is copied as a reference snapshot; those references are supporting material, not extra chapters. Browser Find searches all chapters. Print CSS is included, but print pagination has not been rendered or proofed.

Counts are documentary, not a completion score: 25 sequences, 207 hall positions, 197 existing files, 10 missing files, 76,588 whitespace-separated prose words excluding fenced code, 712 code blocks. The three explicit Primitives teaching intents are labelled as such. Other files vary from encounter notes to full lessons; no automatic rule treats file presence as instructional completeness.
