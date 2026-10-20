# Catalyst test arena

Game entry: **main menu → Head Arena** now opens the biome version, `commons/hazards/catalyst_counterpart/biome_arena.tscn`. Point at the menu button until its dwell indicator completes. In the arena, **MAIN MENU** beside the sphere returns you without restarting the XR session. Restart the running game to load these changes; an installed Quest copy needs an updated export. This map remains the earlier museum-shell test.

Open `res://commons/testing/catalyst_test_arena.tscn` in Godot and press F6. With OpenXR available it uses the existing museum XR rig. This is a direct-entry arena: no trace, drawing or unlock prerequisite. The earlier three-room route remains in `catalyst_first_abilities.tscn`.

Take the black sphere from the left plinth. Select MOVE, TURN or SCALE on the right console, then START. Aim with the holding hand and use its trigger. Holding the point still reduces its rings and segments. Interrupt the head three times to complete a round; the head survives. Sidestep its announced line to avoid a touch. REST cancels an attack immediately. RESET clears the trial and returns the released sphere to its plinth; it never pulls a held sphere away. Selecting another operation resets the round.

The actual museum shell surrounds a clear dark floor inlay. Both control areas sit outside the head's travel bounds. Head contact counts a touch without health damage or forced movement. There is one head with selectable motion, not autonomous learning or the full proposed spine progression.

The map data describes the shell. Both the F6 launcher and the menu destination `commons/hazards/catalyst_counterpart/head_arena.tscn` mount `test_arena.gd` after generation; loading map_data alone is not the complete playtest. The menu destination uses the exportable `museum_plan.json` here and writes practice reports under `user://head-arena/`. The main spine and existing lessons are untouched.

Build plan: `python -X utf8 tools/build_catalyst_test_plan.py --arena`.

Test: `python -X utf8 tools/test_catalyst_first_abilities.py --arena --render`.

Evidence: `ada_run/encounter_pilot/Catalyst_Test_Arena/`. Supplied hand poses exercise the real XRTools grip and real catalyst projectile collision. Headset reach, comfort, aiming and enjoyment still require playtesting.
