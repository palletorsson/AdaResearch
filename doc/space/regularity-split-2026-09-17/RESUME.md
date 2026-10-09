# Resume the regularity split

Paused expansion at the user's request to conserve the final 4% of inference and prepare an online text review (2026-09-18). This is a work record, not a completed visual acceptance.

Implemented source route: Array → Tutorial_3D → Tutorial_Tiling_Floor → Tutorial_Tiling_Walls → Tutorial_Disco; after Color, Pattern_Disco → Pattern_Foundry → existing tiling sequence. Source sequences, map_authored, active/shipped museum plans, book pearls, primary roles and core encounter records were updated. Existing configurations are archived in before/.

New artifact scripts: commons/artifacts/regularity/{array_flight_lab,tiling_principles,disco_controls,pattern_architecture,room_tools}.gd and four scene/registry entries. Existing flight box gained opt-in monochrome/title properties; existing disco floor gained opt-in monochrome conversion. Defaults preserved.

New/updated final.md: Array, Tutorial_3D, Tutorial_Tiling_Floor, Tutorial_Tiling_Walls, Tutorial_Disco, Pattern_Disco, Pattern_Foundry; Chamber_Color exit now bridges to the returning disco. Intent and supporting chapter metadata updated. No commits or pushes made.

Probe: commons/testing/probe_regularity_split.gd, run via Godot --script with -- --map=NAME [--capture]. Logs and per-map checks are in this folder. Probe uses actual endless-museum scenes with isolated control/override/hand paths. Captures are actual Godot renders.

Remaining:

1. Fix the new halls' appearance: grid defaults produce prominent pink wireframes despite show_grid=false, competing with the black/white lesson. Set a verified neutral grid finish locally, using an existing colour_overrides example; do not globally change grid defaults.
2. Floor study images show striped interference against the floor in the render. Inspect actual floor/plane world heights, duplicates and shader movement; resolve the overlap, then recapture.
3. Foundry machine C uses _carpet_material rather than _carpet_mat. The receiver was corrected; verify the updated test result and a full-room render. Array's gridagent uses agent_tier metadata rather than artifact_lookup_name; the probe was corrected to recognise that special dispatch.
4. Check architecture skins align with real walls/floors, source controls propagate, and hold/target behaviour is clear. Current HOLD freezes both skins; unselected live receivers can continue following their previously bound image. Native small studies remain separate.
5. Review button reach and the two-tier casing in VR later. The lower panel was moved to z=-0.38 to face the approaching visitor. Headset comfort remains untested.
6. Final evidence page/index.html has not been made. Prior proposal links to it, so create it before presenting that review link. Keep the current manuscript handover as the review entry meanwhile.
7. Ensure generated bake/layout caches and shipped records agree with the expanded route without regenerating unrelated work. Scoped map-plan derivation was completed; a full global bake was not run.
8. tools/regularity_split_content.py is a one-off content updater, not a canonical regeneration command: rerunning it can overwrite later refinements (including spawn syntax and editorial role ordering). Prefer targeted edits.

Disk filled during work. The interrupted archive copy ada_run/em_plan.json was zero bytes and was subsequently replaced successfully. Source map JSON was revalidated. Free space later recovered to approximately 123 GiB; no cache deletion was performed. The async cache-cleanup question no longer blocks the work.

Review brief: doc/book/review-packets/whole-spine-handover-2026-09-18.md. Frozen current text corpus sits beside it. Online repository may lag: https://github.com/palletorsson/AdaResearch.
