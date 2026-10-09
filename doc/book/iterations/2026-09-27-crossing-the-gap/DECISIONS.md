# A way across, then a return

## The encounter
The chapter already has a clear wish: reach the bank visible across missing floor. Keep its progression through a travelling cube, a growing cube and a turning plank. Let each crossing succeed before returning to move the far landing. The later complication has a particular cause: the plank repeats its movement, but the place it needs to reach has moved.

Read the private notes for this hall and its neighbours. Trans_Pre accumulates movements and ends with collection. This hall uses them for passage. Trans_Translation can then expand displacement into a journey. Keep the opening and closing handovers, the practical instructions to watch and wait, and the ending about the timers continuing while the visitor thinks.

## The sentences
Explain the variables at their first useful appearance: the transport destination, the displacement shared with its rider, the scale factor and the landing's target. Define the mesh and collision box where they make the growing surface understandable. Describe the orange plank's initial direction before its quarter-turn.

The five code excerpts remain unchanged. Exact crossing dimensions remain where they help a reader picture the plank; the landing's speed is available in the companion tutorial. The prose now gives the successful journey time before introducing a changed condition. Remove the general warning about a beautiful movement leaving someone behind and the quiz after scaling; keep the particular relation between a cube's unchanged proportions and an appearing route.

Preserve “The crossing has lost one of its agreements.” The bank images show the agreement being changed. Preserve the final observation about a simulation that keeps time without knowing how long understanding takes. These are distinct moments, not an instruction to attach a warning to every success.

## Source correction
The current map places the ferry at (5,6). Its scale token is `sc:3:0.5:1:0#seat:deck`; rotation is `rc:90:y:4:0#profile:bridge#seat:deck`. The bridge profile in `rotation_cube.gd` is 3.6 by 0.2 by 1 metre. Deck seating in `UtilityRegistry.gd` sets the upper supporting face, with no added lowering in these tokens.

Correct intent.md, which still placed the ferry at (5,5), described a three-metre-wide platform and repeated old lowering offsets. Historical field notes are retained as history. No geometry, timing, scene code, controls or placements changed in this pass.

Use the current tutorial for the crossing details. The older technical.md still discusses an earlier matrix-focused arrangement and needs a separate companion pass; it was not used as evidence for the live staging.

## Publication and limits
The revision is promoted to `commons/maps/Trans_Introduction/final.md`. This review keeps the pre-edit working copy, a readable comparison, the intent correction and a refreshed seven-hall Transformation capture. The two existing in-museum bank images are reused unchanged; they are not new screenshots from this pass.

Checks cover manuscript structure, unchanged source and images, the current authored tokens, capture freshness and served links. There is no new runtime or headset test. The source supports the described operations; the author's reading will determine whether the pacing feels right.
