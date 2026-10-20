# Capacity tree: make evidence inspectable

User intent: see what we can build and understand across the spine, from individual artifacts to sequences, without confusing a proposed lineage with implemented or tested capability. Museum, tutorial and reflection overlap; some artifacts belong only to the wider field.

Start by re-reading current files: another Claude session has already worked on this page. Preserve its changes. The quoted assessment is an earlier snapshot, not a current specification. Work in `C:/Users/palle/Documents/GitHub/ada_encyclopedia`; read the sibling `AdaResearch_46` repository as evidence. Do not change Godot, room layouts, authored capacity JSON, curriculum order, or texts. Do not commit either dirty repository as part of this task.

First patch: correct and expose evidence behind capacity status.

1. Separate location (museum, configured tower floors, configured trials), editorial role (carried/proposed), and verification (source, native test, physical VR review). An object can occupy several locations. A teaching relation is not code inheritance or a test pass.
2. Give each placement claim a source file and record/part identifier. Resolve room artifact entries and real assembly members, respecting the loader's copy/removal configuration. Never infer placement solely from hall membership, a filename, a note containing `Void`, a carry flag, or `Trans_Pre` membership. Unknown is acceptable. A missing direct token is not proof of absence.
3. Preserve assembly evidence: `trace_area.gd` instantiates `draw_dot`; `primitive_hall.gd` instantiates the cube net and adapts column/profile factories; `polyhedra_area.gd` instantiates the alignment instruments. Use explicit source-backed mappings or existing export metadata where available, not a speculative general-purpose GDScript parser.
4. Keep recorded review state and its caveats visible. Transformation is recorded as ready for VR, explicitly not headset-reviewed. Show the evidence link and date; if freshness cannot be checked, say so. Do not silently promote an old review to current verification.
5. Show definitions beside counts. Authored ownership, authored objects encountered in a sequence, distinct placed tokens, configured instances, and reusable capabilities are different measures. Authoring coverage is not completion. Missing photos are missing documentation, not broken artifacts.

Tests must include negative cases: unchanged hall label after deleting a placement; source file existing without placement; a note mentioning Void; proposed/carried annotations without placement; artifact present in both tower and trial; known assembly child; removed child and independent copy using actual loader semantics; absent/malformed optional evidence; recorded ready-for-VR without headset evidence. Run the existing artifact checker and focused checks. Report precisely what passed and what was not tested.

Then review the current UI before adding anything: sequence clusters, a progress strip and capacity cards already exist. Preserve useful work. A later gaps view should identify unresolved teaching handoffs and missing evidence, while treating frequent infrastructure objects and intentionally terminal branches separately from defects. Do not invent edges to improve scores. Prioritize learning/building value, with frequency as supporting information.

Deliver a small reviewable patch, before/after status examples with provenance, test results and a concise account of remaining uncertainty. Keep runtime evidence, configured state and editorial judgment distinct.
