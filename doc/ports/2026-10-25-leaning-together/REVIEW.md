# Leaning Together

Completed on floor 46 beside the three friction studies. All eight previous installations and all other saved floors were preserved. No chapter/final.md rewrites.

## The encounter

Two 1.25 m timber planks lean together between two loose wooden chocks. A 0.5 kg outlined ivory cube and a 180 g white ball wait on a 2.8 × 1.5 m board, 0.60 m above the slab. Two timber box plinths carry the board. Pink end marks and a compact reset strip distinguish the loose pieces and controls.

Every one of the six bodies can be picked up and moved. Desktop: right-click to hold/release, wheel to adjust reach, Q/E to roll, Z/X to tilt, Shift+Q/E to yaw. VR: native grip and wrist orientation. Reset releases actual held parts, restores authored member poses, then immediately returns every loose part to gravity. Runtime arrangements last while the scene is loaded; reusable starting arrangements are authored and saved in the lab editor.

## Physical and interaction evidence

- 8 native contact checks at a rotated negative-floor placement. The planks contact each other and both movable chocks. A held plank remains a support. Withdrawing it lets its neighbour fall; withdrawing a foot chock changes the arrangement. Reset preserves edited member poses.
- 124 actual main-floor player checks: approach and walking around all four sides; desktop mouse and synthetic XR grip pickup, movement and release for all six bodies; all three desktop rotation axes; reset of a held cube. Physical headset testing remains.
- 10 independently editable members and 32 meshes exported from the registered native scene. Move/rotate/copy pass production validation without saving test edits. Desktop/VR layout mirrors agree.
- Native inspection photographs show the standing arrangement, actual chock withdrawal and a released cube load. Those two interventions use an explicit fixture hand; they are not presented as captured user gestures. The separate player image comes from the actual desktop game.

## What the engine contributes

Jolt integrates gravity, rigid-body contact and friction. There are no joints, planar guides, snap connections, corrective torques, automatic balancing or timed collapses. The board's contact friction is calibrated to 0.22 so the foot chocks matter in the initial arrangement; each plank is 0.8 kg and each chock 1.6 kg. These are chosen toy construction values, not measured timber specimens.

The normal XRTools held-object layer is included in the loose parts' contact masks. A held member is kinematic, as in the native grab system: the hand imposes its pose and can support a posture that cannot persist freely. This does not simulate muscular compliance or haptic force, and large hand movements can pass through other geometry. Loose parts are fully dynamic after release.

The readout reports inclination and time without hands. It has no winning posture or failure flag. The question is relational: what changes when one body, foot or hand moves? Several arrangements are possible; collapse is a physical observation.

## Authoring and limits

Board, two plinths, six loose bodies and controls are independently editable. Arbitrary edits can remove the starting contacts; reset restores the authored layout rather than silently repairing it. Native editor export resets and freezes only its preview copy to capture the authored start; normal gameplay starts live. Existing solver-bias warnings remain; script/runtime errors were not accepted.

Editor: http://localhost:3003/lab-editor?mode=void&floor=46
Gallery: http://localhost:3003/book-review/doc/book/iterations/2026-10-25-leaning-together/index.html
