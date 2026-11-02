# 2 November 2026: the biome court's first glass bays

Task: SW04/SW05 continuation (inhabitants and broader transfer), steps 1 and 2 of the plan's
"Glass bays, biome strata and workers across the spine". Status: technically verified on desktop
and with a synthetic XR rig. It has not been reviewed by a person in the headset.

Previous report: [principal places](../2026-10-30-principal-places/). Source revision: HEAD
`7e74fc897` with these dirty files (`git hash-object`):

| File | Hash |
|---|---|
| `flight_bay.gd` | `5bd0e7a23d` |
| `activities.json` | `b7e368fd08` |
| `biome_object.gd` | `0116f3c74c` |
| `flight_bay_court.gd` | `414ad8e126` |

## Encounter and question

Palle asked for the flight bay first, then the next step, and chose the `biome_object` ladder over
the glass cage's composition: "yes the biome-ladder".

The court (m1) is a 10 × 10 m mint bath. Its floor is at y 3 and its rim at y 4, with a descent ramp
through a 2.2 m opening on +z and 16 m of clearance above. The question was whether the court can be:

- a place to walk, as before;
- the air above it, where one flies to inspect;
- one stratum of a biome whose later states are the same world.

**What would count against it:** the bay closing the walk, flight leaking onto the rim or the ramp,
or a later stage losing what an earlier one showed.

## Retained baseline and one change

**Baseline:** the court held `random_space` (gaussian) and a 100-ball `pocket_test` from the hall
sidecar `commons/void/trials/principal_places/activities.json`. Both entries are in git, with a
copy in `ada_run/flight-bay/court_samples_removed_2026-11-02.json`. `recipe.json` is unchanged.

**The change**, in the same sidecar:

- **`biome-plastic-bath_flight`:** `flight_bay` with its origin at the rim (0, 4, 0).
  - It is 9.9 × 9.9 × 8 m with no floor.
  - Its doors are east, west and south. The south door stands over the descent ramp.
  - The glass starts 7 cm up (`sill` 0.07), clear of the rim's joint crowns.
- **`biome-plastic-bath_stratum`:** `biome_object` at stage `primitives`, seed 7, moisture 0.5,
  relief 0.5, wildness 0.6, size 12. This is the `/biome-ladder` gallery's world.
  - `fit` scales it to 7.6 m, centred at (0, 3.27, −0.4).
  - Its surface is 27 cm over the court floor, carried by a `walk` top.
- **`biome_object.gd`**, two additive changes. It reads `config_*` metas in `_ready`, and
  `apply_grid_config` rebuilds only on a changed value. Without them a host builds the full world
  first and then the configured one. At `full` nothing changes.

## Result and evidence

`python tools/test_flight_bay.py`. The actual tower is opened at floor 210, by the desktop walker
and by a synthetic XR rig. The probe is `tools/probes/flight_bay_court.gd`. Reports and captures
are in `ada_run/flight-bay/<mode>/` and are not committed, because images stay out of git.

Desktop passed 56/56 and XR 54/54. The probe checked:

- **Walking stays walking.** The rim walk passes all three doors, goes down the ramp, round the
  plinth's ring and back up. It never flew: 0 frames.
- **Flight is the air above the court:**
  - Flight begins at the door step (x 4.92, feet 4.05).
  - Released, the body hovers (0.000 m drift in 2 s).
  - The roof stops the rise (feet at 10.12, the roof collision above the head).
  - The north glass and the east lintel hold.
  - Sinking below the rim lands the body on the court floor, unhurt.
  - A jump from the court floor is caught in the air at 3.99.
  - Flying out of the east door lands the body on the rim.
- **The control:** `mode still` keeps colliding glass and leaves the flight group, so stepping off
  the rim drops the body into the court.
- **The court's walking surface stays under the air:** at most 3.275 against 3.97.
- **No glass pane stands in a body of the hall.** The overlap query was itself shown able to see a
  rim joint.
- **The ladder, seed 7, side by side:**

  | Stage | Layers standing | Organisms | Kingdoms present |
  |---|---|---|---|
  | Point_One | 2 | 3 | — |
  | primitives | 9 | 13 | — |
  | transformation | 12 | 26 | — |
  | color | 15 (lattice retired) | 40 | — |
  | full | 20 | 60 | water, mineral, fungus, flora, fauna |

  - The earlier layers are kept through transformation.
  - The court's object equals a standalone primitives object.
  - The full world took 1378 ms to build on this PC.

A three-reader review (no Godot) found a blocking bug before the tower run: the south pane closed
the descent ramp. That bug is fixed and is now tested by the ramp walk. The review also found
several weak checks in the probe, which were tightened.

| Verification | Evidence / result / unresolved limit |
|---|---|
| Artifact behavior and technical claims | Verified in the tower, desktop and synthetic XR |
| Compare → keep → replay → independently reconstruct → revise | One seed and five stages in one run; no replay record kept |
| Cross-host transfer and saved state | Not tested; the bay's mode change is not saved |
| Loading, stability and performance | PC only; Quest frame cost unmeasured |
| Actual VR interaction, scale and comfort | Not done: flying at 2.4 m/s over a 1 m drop needs a person in the headset |

## Bench and world parity

| Capability / source | Bench | Glass | Tower | Editor | Quest |
|---|---|---|---|---|---|
| `flight_bay` in a host | unsupported | proposed | verified | proposed (`export_void_floors.py 210` not run) | unsupported (see below) |
| `biome_object` stratum in m1 | unsupported | proposed | verified | proposed | unsupported |

**Quest:** `addons/quest_game_export/runtime-trial-files.json` does not list `activities.json`, and
`exporter.gd` skips trial files that are not on that list. On the headset, floor 210 therefore has
no sidecar activities at all, and has had none since the samples arrived on 31 Oct. This is
reported on the forum (thread 261102-mjk7e) and not changed here, because it is another agent's
uncommitted export file.

## Inference and revision

**The court can hold three relations at once without them interfering.** It is walked (ramp,
ring), looked at (rim, through glass) and flown over (the bay).

**The bay changes locomotion and nothing else.** The `still` control shows that it is the bay that
holds the body.

**One case is decided here, but is not Palle's ruling.** A jump from the court floor reaching the
air is accepted as a second way in. It follows from the walker's 4.6 m/s jump against a 1 m deep
court.

**Revised:**

- **The plan's step 2.** The source is the `biome_object` ladder, not the vitrine.
- **Two existing gates had gone stale against content from 31 Oct, independent of this change.**
  The disco plate's noise surface stands 0.2–0.3 m over the inspection route's y 0, so
  `tools/probes/principal_places.gd` fails its first waypoints. The synthetic XR body also spawns
  0.30 m under that surface and is held there. Both are reported on the forum, not fixed.
- **`probe_hall_activities.gd` no longer expects the court's gaussian surface.**

## Next bounded action

1. **The later stage on another floor.** Place `biome_object` with seed 7 at a spine floor's own
   stage, for example a Random floor at stage `hall`, or `randomness`. Inside a flight bay it can be
   compared against the court from the air. The floor is Palle's choice.
2. **Step 3 of the plan:** the worker record, with the sculpture and simple-machine stages beside the
   stratum.
3. **The Quest sidecar gap.** Fixing it needs the export owner's agreement.
4. **Headset review.** Fly the bay and judge comfort.

## Addendum, same day: the worker being and the court's troupe

For Astra, who keeps the places, the workstation and the Void tower. This adds step 3 of the plan's
"Glass bays, biome strata and workers across the spine" to the court. Nothing here edits your
untracked `commons/void/` code: the workers stand in the court from the same hall sidecar as the bay
and the stratum, and are built by `place_activity.gd`. Blog with pictures:
[/blog/2026-11-02-a-court-for-the-workers](http://localhost:3003/blog/2026-11-02-a-court-for-the-workers).

Source at the time of writing (`git hash-object`, all uncommitted):

| File | Hash |
|---|---|
| `worker_being.gd` | `39cd7b84d7` |
| `activities.json` | `b4a75a77f8` |
| `flight_bay_court.gd` | `0b5001b4d3` |
| `probe_worker_ladder.gd` | `52fd3a10f0` |

### Encounter and question

Palle: "the biome should evolve with the sequences ... they also should start to work as the habitat
for the agentic workers of the void"; "I want the worker to be a humanoid"; "one humanoid body wearing
each stage's sculpture and ... add joints so they can dance"; "or move". Then, in order: "stand it in
the court and let it dance", "let it dance the full dance, not just the sway", "make more workers dance
in the court".

The question was whether one being can carry the ladder's rule (a part stands only when the stage's
words allow it, the seed fixes the body) while still dancing on real ground in the tower.

**What would count against it:** a later stage losing a part with no word to retire it, two seeds
looking alike, a foot sinking into or floating off the plate, or a body built twice in a host.

### The change

- **`commons/artifacts/worker_being/`** (new; `.gd`, `.tscn`, `registry/worker_being.json`).
  - **Skeleton:** one jointed humanoid skeleton in Modulor proportions.
  - **What it wears:** the stage's closure (`BiomeGrammar.closure`) chooses what each bone wears.
    It wears the endless museum's dream bodies through their own static helpers:
    - `stijl_robot._limb`;
    - `ceramic_puppet._chain`;
    - `asawa_wire._ring`;
    - `masked_dancer._tex_diamond`.
  - **Config:** `stage`, `seed`, `motion` (dance | walk | still), `tempo`, and `moves`. `moves`
    names the stage its moves come from; it defaults to the body's own stage.
  - **IK:** feet are planted by two-bone IK, with the hip frame built from the knee's hinge axis.
  - **Reads:** `get_state()` names its parts, moves and plan.
- **The bench:** `commons/testing/probe_worker_ladder.tscn` stands seed 7 at ten stages, with 11
  checks. `python tools/worker_ladder_gallery.py` publishes
  [/worker-ladder](http://localhost:3003/worker-ladder) (the gallery page is new in the
  encyclopedia).
- **The court, in `activities.json`:**
  - `biome-plastic-bath_worker`: primitives, seed 7, `moves: full`.
  - Five more: `_lines` (Point_Lines, seed 11), `_cord` (Point_Line_Grid, 23), `_plates`
    (Point_Triangle_Context, 5), `_slabs` (Primitives_Polythedra, 19) and `_round_head`
    (Primitives_Ignorance, 31).
  - All six dance at tempo 104 at y 3.275 (the stratum's walk top), in a ring of 1.9 m round the
    stratum's seed point (0, −0.4), each turned to face it.
  - The ring holds every body the Primitives stratum allows.

### Result and evidence

- **Bench: 11/11.** It checks that:
  - Point_One is the heart alone and still;
  - parts and moves only grow along the walk, except what a later word retires (lines, plates
    and cord → slabs; the flower → coral; painted skin → tesserae → made finish);
  - one seed gives one plan at every stage;
  - a dancing body's joints turn and a still one's do not;
  - one foot always stands on the floor and none sinks;
  - walking, the feet alternate.
- **Tower: `python tools/test_flight_bay.py --desktop` passes 60/60.** It confirms that:
  - the first worker dances with turn, wave and bounce (its shoulder turned 19° in 0.5 s);
  - its lowest ankle is at 3.319 against the top at 3.275, the ankle joint standing 4.5 cm above the
    sole;
  - all six of the ring are present and dancing, each with a foot on the top, and no two wear the
    same body.

  The run was headless, beside Palle's open play windows (so the native slot was bypassed for it).
  The photo is `ada_run/flight-bay/desktop/troupe_in_court.png`.
- **XR: `python tools/test_flight_bay.py --xr` passes 58/58 with the six workers** (run after the play windows
  closed, through the native slot). The first worker's lowest ankle is at 3.320, and the ring check passes.

### Lessons on the way

- **An IK foot missed by 15 mm.** The cause was a constant, not the solver: the being's `ANKLE_Y`
  (0.03) disagreed with the check's 0.045.
- **A shortest-arc quaternion twisted the knee out of the leg's plane.** Build the hip basis from the
  hinge axis instead.
- **A walk check sampled a whole gait cycle and so saw the feet back where they started.** One beat
  is half a cycle.
- **`biome_object` built the full world first, then the configured one, in a host.** It now reads
  `config_*` metas in `_ready`; `worker_being` does the same.

### Open

- **Quest:** the sidecar gap (above) means none of the bay, the stratum or the workers reach the
  headset.
- **Garments still approximated in the being's own code:** tesserae, springs, crystals, coral,
  fibre and fused skin. The dream bodies have the real ones (`mosaic_body`, `brass_stamen`,
  `crystal_suit`, `coral_polyp`, `hicks_fiber`, `fetish_idol`).
- **No task yet.** The plan's next worker stage is the simple machine: one legible task on an
  interval. The record `{id, seed, stages: [{from_stage, body_scene, task}]}` is not written yet.
- **The six may stand on the stratum's stones.** Nothing collides with them: the stratum has no
  collision and the workers have none either.
- **Headset review** of the dance at this scale, from the rim and from the bay.
