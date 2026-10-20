# Museum memory

Open [the atlas](http://localhost:3003/museum-memory). This adds a visual retrieval layer to the existing [Project memory](http://localhost:3003/project-memory), without changing the museum or its book.

Choose whole museum → sequence → hall, or follow a cross-domain thread. The current live spine gives addresses to 206 halls in 25 sequences (11 October snapshot). Museum photographs are dated cues. Six opening capsules describe the continuing object, change, retained distinctions, onward relation, reflective question and prohibited inference. Other rooms display learning labels extracted from their current tutorials; they are not automatically summarised or certified.

## Sequence summaries and cross-domain threads

**Sequence summaries** provides a short reading, carry onward and open question for every sequence. The first draft covers all 25. Choose **Edit summary** to revise it, or the hall count to open its museum rooms.

**Cross-domain threads** follows eight editable inquiries: body, trace, frames, rules, boundaries, selection, time and authorship. The first draft contains 48 connections. The matrix shows which sequences each thread touches; a dot is a connection, not a score for coverage or quality. Select a thread, filter its connections or open either endpoint. **New thread**, **Add connection** and **Edit connection** let the author change this reading of the work.

Each connection records its reason, source and target, relationship, status and optional source references. Arrows run source → target: **reuses**, **enables**, **revisits**, **resembles**, **complicates**. The stored `depends-on` relation is displayed as **enables** because its target depends on its source. **Documented** requires linked sources; **interpretation** identifies an editorial reading; **proposed** identifies work or a connection to consider. None certifies runtime behaviour or successful teaching. Relationships may cross or run back through the route; they do not reorder it.

The editable source is [connections.json](connections.json). UI saves use an expected revision, a shared writer lock and atomic replacement. Every edit keeps the previous full state in `doc/book/memory/history/museum-*.json`, with before/after values in the visible recent-edits journal. A conflicting save preserves the draft and loads the current revision. Existing fingerprints remain unchanged when wording is edited. A changed or missing source remains marked for review; an endpoint removed from the live spine remains identifiable as unavailable.

**Existing structures** links six systems already in the project: the live spine, tutorial execution plan, working memory, authored red thread, artifact relationship graph and teaching-focus lineage. They retain their separate jobs. In particular, co-placed artifacts do not establish a tutorial dependency. `doc/threads.json` describes development tasks, so it is not used as the conceptual-thread store.

The old project-memory catalog also keeps authored halls outside the current route. Museum Memory now gets membership directly from the spine and sequence JSON files, without removing those older records.

**Make AI packet** fetches current source fingerprints, shared rules, editable working brief, relevant notes and scoped findings. Copy or download it. **Read full tutorial/final** opens exact current text. **Refresh sources** recomputes freshness without replacing any old receipts. A changed fingerprint means reinspection is needed, not that the earlier statement was false.

## Edit without losing the original

Use **Working notes** or **Edit this hall's working note** for the existing revisioned notes editor, with reasons, open questions and history. Sequence and connection edits happen directly in Museum Memory. Both appear in newly generated packets. They do not silently rewrite inspected capsules or canonical texts.

The editable capsule source is [capsules.json](capsules.json). It is intentionally a small authored pilot. When a correction is agreed, inspect the affected current source, revise the relevant fields and record its new SHA-256 with a review explanation. Do not merely refresh hashes to clear warnings. Keep the schema, source receipts and separate reflective question. The image builder never updates these receipts.

## AI entry

From the AdaResearch_46 repository root:

```powershell
python -X utf8 tools/museum_memory.py --root . packet --scope project
python -X utf8 tools/museum_memory.py --root . packet --scope sequence:primitives
python -X utf8 tools/museum_memory.py --root . packet --scope map:Point_Trace
python -X utf8 tools/museum_memory.py --root . packet --scope thread:trace
```

The JSON response contains `text`, whitespace word counts and source receipts. The project packet carries all sequence summaries and connections, with statuses, freshness and a pointer to the receipt store. Scoped packets unfold the relevant summaries, links and receipts. Read the project address, then the local packet. Open exact source whenever code, a disputed fact, an unresolved note or a changed dependency matters. Return the finding outward: hall consequence → neighbour consequence → sequence implication → remaining uncertainty. Preserve permission boundaries.

This is external retrievable context. It does not modify an AI's weights, make a session remember automatically, or guarantee that another model interprets a capsule correctly. Full source is essential because retrieval and summaries remain selective.

## Optical experiment

[Experiment and proposed comparison](../../iterations/2026-10-11-museum-memory/REPORT.md). Two different outputs are deliberate: a semantic atlas with selected claims and a complete Point Zero source leaf rendered into pixels. Only the latter avoids a summarisation step. Neither has been decoded with DeepSeek-OCR in this pass. Model-specific vision-token accounting, OCR errors and downstream reasoning still need measurement.

## Implementation and checks

- Backend: `tools/museum_memory.py` indexes the live route and current sources; `tools/museum_connections.py` edits only its dedicated memory store, reusing the existing safe source reader and writer lock.
- Web: sibling `ada_encyclopedia/src/app/museum-memory/` and `src/app/api/museum-memory/route.ts`.
- Regression: `python -X utf8 -m unittest discover -s tests -p test_museum*.py -v`.
- Optical exports: `python -X utf8 doc/book/iterations/2026-10-11-museum-memory/build_plates.py` (Pillow; Windows system fonts).
- Frontend: `node node_modules/typescript/bin/tsc --project tests/museum-memory/tsconfig.json --pretty false` in the sibling web repository.

No GPU model, new dependency, cloud upload, manuscript change, Godot change or sequence reorder is required.
