# The whole spine, with connections that can change

[Open Museum Memory](http://localhost:3003/museum-memory) · [Follow trace and memory](http://localhost:3003/museum-memory?scope=thread%3Atrace&view=threads) · [Existing structures](http://localhost:3003/museum-memory?view=structures)

All 25 sequences now have a short editorial summary, a carry onward and an open question. Eight named threads connect constructions, programming concepts, reflective questions and museum encounters. Their 48 initial connections can be revised individually. These are starting readings, not a claim that every lesson or hall has been audited.

The matrix lets the author see which sequences a thread touches, then open a sequence or the exact endpoints of a connection. Each connection has a reason and a relation: reuse, dependency, return, resemblance or complication. Documented connections, interpretations and proposals remain distinguishable. Sources open beside the memory interface; changes to those sources are flagged.

## Structures already present

| Structure | Its existing job | Use here |
| --- | --- | --- |
| Spine and sequence JSON | Live route and hall membership | Authoritative addresses; never reordered by a memory edit |
| Tutorial execution plan | Lesson summaries, prerequisites, reusable objects and topic returns | Linked for the teaching decisions beneath a short summary |
| Project memory | Working brief, notes, findings and their history | Reused in packets and linked for editing |
| Red-thread rulings | Authored arguments for selected rooms | Kept distinct from lesson objectives |
| Museum relational graph | Named, co-placed and other artifact relations | Linked as spatial evidence, not inferred teaching dependencies |
| Teaching-focus lineage | Learning labels and carries across the spine | Linked as a separate editorial register |

The existing development `threads.json` contains work tasks, so it was not repurposed. The older project-memory catalog keeps two Forces halls outside the current live route. This atlas now reads membership directly from the spine: 206 halls, 25 sequences. Those older records remain intact.

## What an edit changes

Summaries, thread names, connection endpoints, relationship types, reasons and statuses can be changed directly in the page. Saved edits go to `doc/book/memory/museum/connections.json`. They immediately affect a new AI packet. The full previous state is preserved in the memory history folder; the page shows recent before/after records. Concurrent saves require matching revisions, so a stale window cannot silently overwrite a newer edit.

The whole-spine packet is about 3,200 whitespace words at this snapshot. It carries 25 short readings, the eight threads and their links. Hall and thread packets unfold relevant details and source receipts. Compression selects a route back into the work; it does not replace reading the actual tutorial, reflective text or implementation.

Three records were flagged when linked Foundations Crisis sources changed during this pass. Their original receipts were kept. A warning means reread the source before relying on that interpretation; it does not automatically invalidate the reading.

## Validation

- 22 Python regression checks passed, including stale-save rejection, concurrent writers, history, source freshness, invalid paths and addresses, removed-hall detection, current-route membership and packet contents.
- Focused TypeScript check passed for the page, its connection editor and API.
- Browser save of the Primitives carry survived reload; a new proposed Trace → Reaction Diffusion connection was saved and appeared in the thread packet. Status filtering and source opening were checked in the interface.
- The HTTP endpoint rejected a stale revision (409), invalid JSON (400) and a cross-origin write (403). Browser console checks returned no errors. Sequence → halls navigation was checked after the navigation fix.

This pass changes the memory interface and its editorial data. It does not alter museum behaviour, sequence order, `tutorial.md` or `final.md`. Human review of the summaries and connections remains the next editorial step.

![Cross-domain threads across the spine](threads.png)

![Editable sequence summaries](summaries.png)
