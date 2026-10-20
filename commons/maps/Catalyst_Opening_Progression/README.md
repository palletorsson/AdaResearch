# Catalyst: the opening progression

Open `commons/testing/catalyst_opening_progression.tscn` in Godot and press **F6** with OpenXR available. This is a compressed rehearsal inside the real Endless Museum, from the first point to the end of the first Transformation encounters. The rest of the spine is not implemented here.

1. Take the black point from the entrance plinth. Place it inside the hollow field on the other plinth.
2. Release it. Bring your empty hands together: a sphere appears between them. Separate them: it disappears, while the small hand glows remain.
3. In the next room, take the rod from the wall. Put its tip inside the light, draw, then release. This keeps your actual recorded positions.
4. Find your line on the next plinth, beside the head waiting in the Dürer arrangement.
5. The same point waits ahead if you released it; a held point stays in your hand. Hold it at the next station. Rings and segments decrease to Godot's valid minimum: **1 ring / 4 segments**, not zero.
6. Aim at the quiet ring target and use the trigger. Its surface lights when the emitted form hits it. This unlocks BEGIN.
7. Press BEGIN. The same waiting head flies into the arena. Its line warns before it moves. Sidestep or interrupt it with an emitted form.
8. One interruption ends a round. Press BEGIN for the next operation: translation, then added rotation, then added scale. The third interruption opens the passage. Walk through.

REST / RESUME pauses the active round. RESET WALK / RESET TRIAL returns the local progression to the first sphere. Released tools return to their mounts; reset never pulls a held object from the hand.

The prototype does not write its abilities to CatalystCapabilityManager's save or its trace to the museum TraceData store. It temporarily suspends the persistent hand visual and restores it on exit. These are local session abilities. To test combat freely, the separate `catalyst_test_arena.tscn` remains available.

## Run the checks

```powershell
python -X utf8 tools/build_catalyst_test_plan.py --progression
python -X utf8 tools/test_catalyst_first_abilities.py --progression --render
```

The probe runs the actual F6 museum scene, XRTools pickup, the existing recorder and real projectile collisions. Hands are supplied poses. A human headset playtest is still needed for grip, reach, readability, timing, aim and enjoyment.

## Connection to the spine

| Existing subjects | Playable ability in this rehearsal |
| --- | --- |
| Point / Coordinates | Carry the same point; place it in a volume; acquire a hand ability. |
| Trace / Grid | Charge the pen; sample and retain movement; see your own record again. |
| Godot Primitives / Ignorance | The same point changes resolution; send a copy of its current form. |
| Melencolia | Meet the same head at rest, before it threatens anything. |
| Transformation | Read a line of motion; interrupt; meet added rotation and scale. |
| Arrays | The next proposed extension: one form distributes an effect. Not implemented here. |

This compresses selected encounters into four rooms. It does not replace the intervening Lines, Triangle, Polyhedra or other lessons, alter the canonical order, or publish enemies into the main teaching halls.
