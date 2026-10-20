# B19 — a standing array

13 October 2026. Built from Palle's edited scaffold. Five playable stages remain; this upgrades Arrays and carries the behaviour into Colour and Tiling.

## What changed

- Nine skulls occupy a standing 3 × 3 grid. Labels are `[row, column]`, starting at zero. The wire frame shows each place without adding a wall.
- One catalyst hit drops the skull. Its address remains and reads EMPTY; neighbours keep their original addresses. RESET restores the nine occupants.
- START fires rows 0, 1, 2, then columns 0, 1, 2. One group is scheduled every 4.8 seconds; each head warns for 1.2 seconds. Empty places do not fire. REST stops warnings and clears shots.
- Each shot stores a list of positions. The warning draws that list; the projectile traverses the same list at 1.8 metres per second, sweeping each edge for collision. After the last point it continues along the final direction. The target is sampled when the warning begins; these are not homing shots.
- Transformation's small head motion, turning and bounded projectile growth remain. Heads hold still during the warning so the muzzle matches the announced path.
- Entrance refuge boxes move outward, becoming 3 metres high and 2 metres wide/deep. All nine heads are visible from the arrival view; test shots from all nine addresses stop at the left refuge.
- Tile shrinking and rotation remain. Colour adds colour; Tiling still repeats the catalyst impact across 18 matching tiles. Skull impacts paint only the actual receiving tile.

## Play

Game menu → Biome Ladder → **3 / ARRAY**. START or T begins volleys. Left click shoots; arrow keys move; R resets. In VR use the supplied hand form and trigger. The standalone scene is `res://commons/hazards/biome_ladder/ladder_world.tscn`.

Try removing the middle skull. Read the empty address while the next row passes through it. Then compare Colour and Tiling: the same array and paths remain while the floor acquires later operations.

## Evidence

| Check | Passed | Raw result |
|---|---|---|
| Array, addresses, volleys, paths and cover | 140/140 | [arrays-checks.json](arrays-checks.json) |
| Five-stage behaviour | 67/67 | [arrays-stage-checks.json](arrays-stage-checks.json) |
| Desktop input and projectile physics | 54/54 | [arrays-desktop-checks.json](arrays-desktop-checks.json) |
| Tiling and floor collision | 33/33 | [arrays-tiling-checks.json](arrays-tiling-checks.json) |
| Controlled XR input, skull hit and fall | 106/106 | [arrays-xr-checks.json](arrays-xr-checks.json) |

All runs exited 0. The array probe includes normal scheduled volleys, actual projectile collisions, a falling vacancy, reset, corner traversal, inherited floor operations and refuge shots from all nine addresses. Desktop and controlled XR input use the actual catalyst projectile. Tiling's old hard-coded cover target was replaced with the actual box position; its floor-paint test now verifies the receiving collider explicitly.

The pictures are rendered by Godot in controlled probe scenes. Overview/volley shots temporarily hold head motion to make comparison readable; the game retains motion. They are not a manual headset playthrough. Physical headset comfort, difficulty and performance remain to be assessed. Existing ObjectDB cleanup warnings remain at shutdown. Claude's earlier Tiling console-reach finding is still open; this pass does not certify the complete route.

## Handoff

`array_path.gd` supplies the position list and line drawing; `ladder_ball.gd` follows it; `ladder_skull.gd` manages warnings; `ladder_encounter.gd` owns addresses and volley order. Source hashes are in [arrays-evidence.json](arrays-evidence.json). Claude-owned probes and review remain untouched. Tutorial/final.md and sequence order are unchanged. Preserve user edits in SCAFFOLD.json.
