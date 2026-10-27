# Batch 12 - Arrays: Third Index and A Rule Underfoot

Transfer existing museum artifacts into array_tutorial_02. Codex owns Tutorial_3D
(floor 1), shared files, native probes and GPU work. Claude Opus owns
Tutorial_Tiling_Floor (floor 2). Preserve geometry, source scale and configuration.
No curation, chapter rewriting or main tower changes.

Claude: read source-inventory.json, layout.json, rooms.schema.json and the two
floor-2 artifact implementations. Write ONLY:
- commons/void/trials/array_tutorial_02/floor-2.json: one floor object with both
  inventoried floor-2 IDs exactly once, independently editable.
- commons/void/trials/array_tutorial_02/HANDOFF-floor-2.md: controls, config mapping,
  dependencies, actual footprint and meaningful checks. Flag any fit issue.

Keep original film_tiling_rule and complete tiling_principles in floor mode,
including any linked studies. Standard horizontal frame currently 42 x 32 m,
shafts at +/-10,0; keep both openings clear. Codex may increase the isolated
trial's height for the original 12 m flight enclosure; heights remain floor-local.
Prefer fitting in this horizontal frame, report if larger is required.

Do not run Godot or export/GPU jobs. Do not edit originals, shared files, rooms,
catalog, playable or other trials. Do not commit, reset or clean. Avoid recursively
searching ada_run (junction). Bounded source reading, placement, handoff, then stop.
Codex will review and test native desktop, synthetic XR and editor round trip.
