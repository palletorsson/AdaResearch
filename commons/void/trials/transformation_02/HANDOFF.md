# Transformation: Body and Moving Boundary

Batch 11 continues the museum transfer into separate Void trials. Codex transferred Trans_Body; Claude Opus supplied Trans_Pit's floor fragment and source analysis. Codex reviewed the fragment, integrated it, and owns the final evidence. All nineteen original placements have independent editor identities, including the two rotating slabs from the source utilities layer.

Read HANDOFF-floor-1.md and HANDOFF-floor-2.md for source behaviour and placement decisions. Source coverage and unchanged chapter/map hashes are recorded in evidence/source-checks.json. Native and editor acceptance are recorded separately in evidence/checks.json and evidence/editor-checks.json. A receipt with `passed: false` is not acceptance.

## Local integration

- The pusher adapter turns the original movement axis with its saved editor facing. A native quarter-turn probe verifies that the real moving collider follows the rotated route.
- The rotation adapter sends each original utility token through UtilityRegistry before the original scene's ready callback. This preserves the separate three- and four-second pauses, Y quarter-turn and -0.6 m offset. Original source scripts remain untouched.
- The retained carve supplies `room: Trans_Body` to its existing persistence interface. The wall, shrinking blocks, monitors, grower blocks, free-ball launchers and airlock use their original implementations.
- Desktop and VR load the same rooms.json. Web models are exported arrangement snapshots; native Godot runs the interactions and materials.

## Curation issues retained visibly

The old map's structure and captions have not been copied as new artifacts. Launchers retain the original two-metre ledge height, so their posts currently float; supporting architecture belongs to curation. Balls can roll towards the shafts, including the inner landing pad on shaft A. The native interaction probe observes from the side before deliberately entering the throw. The airlock was moved three metres inward to retain its exit runway, but can be bypassed along the open floor.

The rotating slabs retain their original partly buried setting: 0.5 m is visible above the deck, with lower geometry extending beneath it. These are existing low rotating boundaries, not new full-height doors. Native bounds record the conflict rather than shrinking the source geometry.

The launchers' original kill_y is absolute -12 m; moving them to a lower storey would need a relative-height adapter. At this floor a ball retiring below the slab works as authored. Their pool remains bounded and is paused with the floor.

Physical-headset play, final route, supporting architecture, lighting and text revisions remain pending. This is a transfer collection, not a finished encounter sequence.
