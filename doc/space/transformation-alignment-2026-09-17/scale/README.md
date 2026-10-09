# Trans_Scale — align the cut and the route

The bottle makes a discrete fourfold scale change and then relocates the visitor onto the enlarged table. It does not animate continuous growth. The map now joins the small room entrance to the hall sides with a fixed wall, so its enlarged far door becomes part of forward passage. Retreat is still possible. A fixed witness doorway supplies the unchanged comparison, with the museum exit beyond it.

The 4 x 4 m room, 16 x 16 m enlarged footprint, one primary scale_me encounter and thirteen porcelain steps remain intact. The actor, museum, walking speed and gravity stay outside the scaling hierarchy. The standalone spawn token is corrected from sp (score point) to s, with 180-degree rotation in utility properties.

## Evidence

- `checks.json`: fresh actual-museum run, 40 checks and zero failures; source map and artifact script hashes recorded.
- `runtime.log`: complete final run. It includes the unrelated baseline UID/certificate warnings and one ambient crab bite during descent.
- `initial-failures.json` and `.log`: the first run found two failed bypass checks and foreign plinth collision after automatic museum repair moved the room. Root fixed the narrowly scoped whole-room seal; the map excludes automatic benches/dream sculptures.
- `entry-wall.png`, `before.png`, `on-the-plate.png`, `expanded.png`, `two-doorways.png`: actual Godot renders of the revised museum hall. `capture.gd`/`.tscn` reproduce them; capture uses the bottle consumption callback while the collision test exercises the real desktop pickup ray and carry gesture.
- `before/`: source snapshots before this alignment pass.

The collision probe uses the actual museum CharacterBody3D for all thirteen steps and walks from the descent through both doorways to the hall exit. It also checks the original doorway's body clearance and both exterior bypasses before and after scaling. The museum's coarse static walk graph does not prove the changing route.

Headset interaction, comfort and learner discovery remain untested. No claim of headset validation is made.
