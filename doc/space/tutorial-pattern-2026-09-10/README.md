# Tutorial_Pattern: fixed source comparison — 2026-09-10

User asked to continue to the next map and deferred headset/gesture work. Active route confirms Tutorial_Pattern follows Pattern_Foundry. Existing primary/book anchor remains pattern_maker_station.

Implemented an opt-in lesson:fixed_motif adapter on that station, moved from (6,12) to (22,9), rotation 180 and floor offset zero. Added a level east bay and three-cell opening through x17, z10-12. Existing artifact instances and original grid structure otherwise preserved. Original map/text/code snapshots are under before/ with .gdignore.

The new console has 16 pointer source cells, eight paints, P1/PM floor selection, source reflection/rotation, undo and reset. Two independent 1.6m panels read the same source with fixed P1/PM rules. Both panels and 4m floor use 40cm tile spans. Source sampling is nearest via an instance-local shader copy. Legacy editor collision and polling are disabled only for the opt-in instance. Unconfigured station checked unchanged.

41 checks pass in the actual desktop museum, using pointer press/release. Source bytes stay fixed through rule selection; source edits update both panels; double reflection and four rotations return the cells. Route, standing clearance, reach heights and physical tile spacing checked. Palette comparison accounts for RGBA8 quantisation. Captures inspected after correcting palette feedback and making source cells legible.

Updated final, technical, tutorial, critical, summary, blurb, intent and catalogue primary description. The older four-station expression-parser story is retained in before/ but removed from current prose because it did not describe the implemented lesson. Published guide evidence and a dedicated tutorial-pattern page. No role promotion or artifact deletion. No commits.

Headset comfort, real tracked hands and performance remain deferred. Godot reports a shutdown ObjectDB/resource-in-use warning in the museum probe; no lesson script errors or failed assertions remain. Do not describe this as a warning-free engine run.

Next: Array_Patterns, repetition as an environment; inspect actual surfaces, corners and passage before writing. Foundry gestures and wardrobe transfer remain open for later.
