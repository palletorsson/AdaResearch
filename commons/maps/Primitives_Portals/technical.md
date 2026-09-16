# Two finite approaches and a limit

Primitives_Ignorance compared mesh entries, visible surfaces and judgments of sufficient detail. This room arranges refinement along a spatial sequence, then compares it with a halving sequence. Its two primary artifacts are `combine_portals` and `achilles_tortoise`; the capsule remains a secondary topology comparison.

## The portal ladder

The default ladder has twenty instances. Each duplicates the base TorusMesh resource, so changing one member's subdivision does not alter its neighbours. Starting from 3 rings and 3 ring segments, member `i` uses:

```gdscript
return Vector2i(start_rings + i, start_segments + i * 2)
```

The final member has 22 rings and 41 ring segments. Godot describes `rings` as slices of the torus and `ring_segments` as edges around each ring. Its inner/outer radius parameters describe the torus's inner and outer radii; they should not be relabelled as the tube radius and centreline radius. [Godot 4.6 TorusMesh reference](https://docs.godotengine.org/en/4.6/classes/class_torusmesh.html).

The existing authored base mesh and its transform remain. Origins are separated by 4.5 local metres along +Z, so the first-to-last span is 85.5 metres before mesh extent is included. The museum's live stamp measured about 87.1 metres of depth. This is an extended exhibit, not a small object guaranteed to fit inside the map's nominal 35 rows. A full-corridor route remains to be checked.

## Select and reverse

`#discovery:1` adds a side instrument. PREVIOUS and NEXT RING select an index, bounded by the first and last members. The selected ring receives a gold material. Its rings, ring segments and triangle count are read from its current mesh.

REVERSE switches between the linear and inverted rules. Inverted uses `count - 1 - index` in place of `index`. The ring positions remain unchanged and the same subdivision pairs appear in reverse order. Resource instances are rebuilt; the family of resolutions is preserved. Removal detaches old nodes before queueing deletion, so rapid reversals do not create duplicate names or transient extra members.

Existing fixed, doubling and alternate layout modes remain configuration choices; the side panel exposes the linear/inverted comparison only. The refinement cap for the doubling option remains 96 subdivisions.

## A separately labelled planar calculation

The instrument also uses the selected member's ring count as the side count of a regular polygon inscribed in a unit circle:

```gdscript
var perimeter = 2.0 * n * sin(PI / n)
var gap = TAU - perimeter
```

This follows from the length `2 * sin(PI/n)` of each unit-circle chord. It compares a planar polygon with circumference `TAU`. It does not measure the portal's three-dimensional rim or combine its two subdivision counts into an estimate of pi.

At each finite side count in this display, the polygon perimeter is shorter than the circle's. Increasing `n` reduces the gap. A chosen tolerance can terminate an application without making the finite polygon identical to the circle.

## The halving instrument

The six-metre track uses stage targets:

```text
A_n = L * (1 - 2^(-n))
T_n = L * (1 - 2^(-(n+1)))
```

Achilles reaches the tortoise's previous target. Achilles-to-limit is `L * 2^(-n)`; Achilles-to-tortoise is half that distance. At stage ten these are 0.005859375 m and 0.0029296875 m respectively. The figures have visible extent, so visual overlap is not proof that their anchor positions coincide.

With discovery enabled, the instrument starts held at stage zero:

- NEXT STEP cancels any current interpolation and directly places the next stage targets. At the final stage it settles that stage without exceeding the configured count.
- PLAY schedules a stage every two seconds. The marker tweens last one second, using different easing curves for Achilles and the tortoise.
- PAUSE stops both automatic scheduling and the in-flight tween. The current and target gaps can therefore differ in a paused image.
- RESTART kills the current tween, restores initial marker positions and hides accumulated stage marks. The instrument remains held.

The final finite stage remains available for inspection. Outside discovery mode, the existing timed loop and four-second reset pause remain. No calculation beyond the ten stages is used here to find a floating-point saturation threshold.

## Representation and passage

Torus topology, a visible aperture and a physically usable route require different checks. These torus meshes do not implement teleportation. The controls' local button collision must also be distinguished from an obstruction filling the whole ladder footprint.

The instrument panels mark themselves `em_local_instrument`. The museum's footprint-level collider check skips those marked subtrees while retaining detection of ordinary artifact colliders. Local button physics stays intact. The footprint ledger now refreshes collision classification when it changes without the bounds growing, so a stale whole-ladder obstruction is not retained.

## Sources and validation

- `commons/primitives/combines/combine_portals.gd` and `.tscn`
- `commons/primitives/combines/achilles_tortoise.gd`
- `commons/ui/limit_experiment_panel.gd`
- `commons/scenes/endless_museum.gd`, `_has_collider` and `_ledger_note`
- `commons/testing/probe_portals_primary.gd`

The probe checks pointer controls, mesh-family reversal, stable child names, finite polygon gaps, stage positions, tween pause/restart, actual museum stamping and footprint classification. It does not establish the complete corridor's accessibility or headset comfort. Primitives_Melencolia next asks what purpose these exact constructions should serve.
