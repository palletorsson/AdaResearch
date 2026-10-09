# Four-hall encounter reading · 15 September 2026

Palle approved revising Point One → Line → Trace → Grid as a continuous passage with several sustained encounters and lighter invitations to other relevant artifacts. The text should be explicitly poetic while grounding each new capability in the actual program. The four current final.md files now carry that pass.

Review: http://localhost:3003/research/possible-bodies/primitives-encounters.html

## What changed

- Four canonical final.md chapters and the compiled research reading.
- One encounter-reference.md per map, linked from its technical.md. Installed recording details and every earlier code excerpt absent from the new main reading remain available.
- Grid's old simulation_grid anchor now names the placed plan_vitrine, which wraps that grid. Its primary order now names the wrapper too.
- Two previously unruled Line service objects, sketch_monitor and health_cross, are explicitly secondary. They remain placed. All existing book encounters remain represented; the other role groups and their order are preserved.
- The original pilot links to the applied follow-up. The review provides expandable references and earlier chapters.

No map or artifact implementation changed in this pass. No commit or headset test was performed.

## Verification

`content-checks.json`: 72 checks of canonical/review equality, primary membership and order, placed book artifacts, preserved code excerpts, archived source hashes, unchanged maps and scoped role edits.

`http-checks.json`: all 12 published files returned HTTP 200 with exact source hashes; all four live Necklace API responses agree on book-artifact membership and order. This verifies content delivery, not visual layout or bodily reception. Browser automation could not initialise its local runtime, so no browser screenshot or visual review is claimed.

`revision.json`: chapter word counts and current artifact anchors. `before/` preserves all four earlier chapters, technical files, maps and the initial role file. Another ongoing task changed ISO_FlatTerrain role data during this pass. The mutation therefore used a fresh role file, preserved as `roles-immediately-before.json`, and changed only the scoped Line/Grid entries.

## Continue

Read the four chapters as one passage. Palle's useful annotations are where curiosity begins, where explanation arrives too soon, and what makes the next capability desirable. Revise from those reactions, retaining the working encounter briefs while continuing the whole spine. Do not automatically impose identical prose structure or an artifact quota on later halls.

The one-time revision script refuses replay against changed sources. `ada_run/build_primitives_reading.py` validates and renders the review against this dated pass; it is not a general book generator.
