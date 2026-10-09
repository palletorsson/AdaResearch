# Project memory v1 implementation contract

Authoritative memory is `doc/book/memory/state.json` in AdaResearch_46. Existing authored storyboards remain authoritative for proposed teaching; the system reads them live. Notes are a separate working layer. No Godot, hall order, tutorial.md or final.md writes.

## Python backend

`tools/project_memory.py --root <repo> <command>`; commands `model`, `packet`, `source`, `mutate`. Read one JSON object from stdin for all commands (empty means {}). Output JSON. On expected errors output `{error, code}` and exit nonzero; use code 409 for conflicts, 400 for invalid input, 404 for missing records.

Functions should accept an explicit root for isolated tests. Model must work from existing storyboard sources, preparation and generated route metadata. State seeded by coordinator; no writes on GET. Storage writes only under doc/book/memory. Atomic state replacement, exclusive writer lock and expected revision required. Save previous state in history/ before replacement; keep a concise journal in state. No silent overwrite.

### Model response

`{revision, updated_at, core, scopes, notes, findings, signals, history, stats}`.

`core: {text, reason, open_question}`. `notes: {[scope]: {summary, reason, open_question, updated_at}}`.

`scopes: [{id, level, title, parent, order, summary, full, source, children, brings, learns, supplied, carries, artifact_refs, documents, image, review_note}]`.

- IDs: `project`, `sequence:primitives`, `map:Point_Zero`, `preparation:day-zero`.
- level: project | sequence | map | preparation. parent null only project; children are IDs.
- summary/full: live compact/full storyboard or sequence arc. source: repo-relative canonical source file.
- documents: `[{label,path}]`, repo-relative paths. image: null or `{path,label,date}` pointing to generated route image under doc/book/iterations. No file:// URLs needed.
- optional arrays default empty; text defaults empty. Route images are earlier museum captures, not live observations.

`findings: [{id,scope,kind,text,reason,sequence_effect,project_effect,related_scopes,sources,status,method,created_by,created_at,review_note,reviewed_at,freshness}]`.

- kind: source | decision | proposal | question. status: proposed | accepted | dismissed.
- sources: `[{path,sha256,current_sha256,status}]`; stored records contain only path and observed sha256. Derived status current | changed | missing. sha256 may be null for uninspected reference.
- freshness: current | changed | missing | unlinked. Empty or all uninspected references => unlinked. Changed/missing takes precedence.
- status is editorial acceptance; it does not certify a technical claim. Display method and source freshness separately.

`signals: [{id,scope,kind,text,related_scopes}]`: derive stale/missing sources, missing selected artifact refs, open review notes, snapshot route/spine disagreement. These are coverage/review signals, never automatic judgments of artistic quality. `history`: last 40 journal entries `{at,action,scope,summary}`. `stats`: sequences, maps, findings, needs_recheck, open_questions.

### Mutations

Every request `{action,expected_revision,...}`. Return fresh model on success.

- `core`: core object; save editable working brief.
- `note`: scope plus note `{summary,reason,open_question}`; preserve other fields. Cannot change existing storyboard text.
- `finding`: finding object with scope, kind, text, reason, sequence_effect, project_effect, related_scopes[], source_paths[], method, created_by. Assign ID/time, status proposed; fingerprint existing source paths at submission. Text can include earlier audit evidence; never autoaccept a new finding.
- `review`: id, status accepted|dismissed|proposed, review_note (nonempty for accepted/dismissed). Preserve original evidence hashes so accepting a stale finding does not make it fresh.
- `recheck`: id, review_note (required), current_sources `[{path,sha256}]` for every stored source. Reject if hashes do not match current files. Update evidence hashes and review note; journal previous state. This records a new human/source review, not an automatic truth test. Missing sources cannot be restamped.

Limits: known scope IDs, legal kinds/statuses, text max 12000 chars, max 20 sources and related scopes. Reject absolute/traversal/symlink escape paths. Source files must be safe repo-relative text: .md, .json, .gd, .gdshader, .tscn, .txt under commons/, algorithms/, doc/book/, or exact project.godot. Exclude memory/history and private/system files. Cap source response at 512 KiB; cap input at 128 KiB.

### Source and packet

`source` input `{path}` → `{path,text,sha256}` using same safe source resolver. No arbitrary file access or write.

`packet` input `{scope}` → `{text,word_count}`. Include working brief, current scope, ancestor arc, scope note/reason/open choice, selected compact summaries, related nondismissed findings with evidence freshness, source paths, and return to sequence/project effects. Whole project includes sequence arcs, sequence includes its compact hall summaries, map includes current map + adjacent halls as orientation. Never silently omit unresolved choices or portray supplied objects as learned. Explicitly warn this is context, not implementation permission or proof. Keep deterministic and reasonably compact.

## Web integration

Sibling ada_encyclopedia: `/project-memory`, API `/api/project-memory`.

- GET default → model; `?packet=<scope>` → packet; `?source=<path>` → source.
- POST JSON → mutate.
- Bridge executes the fixed Python script and streams JSON through stdin; no shell interpolation. Reject cross-origin mutations; require loopback service origin. Use getRepoPath().
- UI error/conflict state must preserve unsaved text. Saved edits survive reload. No browser localStorage as authoritative memory.
- Display source files via API text panel; generated museum images through existing `/book-review/<path>`.
- Core and notes edits, add finding, accept/dismiss with note, explicit source recheck, copy/download handoff, source freshness refresh, history and gaps view.
- Plain language; few primary actions. Clear project → sequence → hall navigation and way back. Museum image and current full/short storyboard are read-only context alongside editable memory.

CLI is also the AI interface; parallel agents submit separate proposed findings against a revision and one synthesis pass integrates them. Do not launch background AI jobs from this v1 UI.
