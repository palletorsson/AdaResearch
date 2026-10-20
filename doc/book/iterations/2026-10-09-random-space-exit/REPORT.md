# Random Space — a supported way onward

The remaining exit problem from the Randomness ghost-student report is repaired. The native round trip **Random Space → Random Game → Random Space** passes **49 desktop checks and 50 checks with the XR player body**.

## The change

The terrain intersected the old floor-level doorway. I joined the rear blocks into a three-metre-wide, one-metre-high landing, added three adjacent ramp wedges, and moved the exit one cell inward to clear the rear boundary wall. The doorway faces the approaching visitor.

This is a change to `commons/maps/Random_Space/map_data.json`: seven structure cells, three ramp utilities, the exit's cell and its approach setting. The hall derives its geometry from that file on load. All five authored exhibits, their positions and parameters are retained. No artifact algorithm, portal runtime, lesson, reflection or sequence order was changed in this repair.

## What ran

- Both runs load the actual museum and settle the real player body under gravity at three arrivals.
- The body walks a supported route from each entrance. The test supplies the existing scanner's access action and horizontal velocity; movement meets the live colliders.
- A swept doorway crossing loads Random Game. A return request restores Random Space. Only one hall remains resident, and arrival does not immediately send the player back.
- On return, the body walks down the ramp onto the terrain and climbs back to the landing without jumping or teleporting along the route.
- The XR run uses the actual XR Tools player body, a simulated room-scale camera offset and the bounds checker. It is not a physical headset session.

## What the failures taught us

The first raised doorway was still too close to the museum's rear boundary wall. The first round trip succeeded but the clearance check exposed that edge; moving the exit inward fixed it. The old flat-floor checker also asked for a straight, level line from entrances where the safe route turns or follows terrain. A floor ray landing exactly on a shared block edge returned a side normal. I retained that failed receipt and used actual body walks to test the passage instead. The new checker initially had a GDScript type-inference error; its failed launch is retained too.

The final tests have no script errors. Existing missing-UID and shutdown-leak warnings remain in the logs. The coarse inventory walk graph still calls this hall severed because it reserves the terrain's footprint; the native player checks demonstrate the tested paths through its actual collision surface. That graph is not repaired here.

## Reading status

The previous **420 baseline and 60 changed-program checks** still stand as the teaching evidence; this map-only repair does not require a tutorial rewrite. Randomness keeps its fourteen-hall order, with the closing Biome Ladder deferred. This pass closes the reported exit issue. It does not certify a continuous walk through the whole sequence or headset comfort.

## Reproduce

From the repository root:

```powershell
python -X utf8 tools/run_encounter_probe.py Random_Space --sequence randomness --render --output-tag exit-desktop-review --probe tools/probes/random_space_passage.gd --spec doc/book/iterations/2026-10-09-random-space-exit/desktop-spec.json
python -X utf8 tools/run_encounter_probe.py Random_Space --sequence randomness --render --output-tag exit-xr-review --probe tools/probes/random_space_passage.gd --spec doc/book/iterations/2026-10-09-random-space-exit/xr-spec.json
```

[Desktop receipt](desktop/report.json) · [XR receipt](xr/report.json) · [Source hashes](validation.json) · [Previous ghost-student report](../2026-10-09-randomness-ghost-student/index.html)
