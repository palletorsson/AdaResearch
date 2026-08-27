# The Concept Atlas — every principle, its algorithm, its bodies

> 2026-08-27, Palle: *"Can you make a list of the force, algorithm and principle in forces
> and the different artifact that represent these forces? And then also plan to do this for
> all artifacts and all principal and algorithms?"*

Part A is the forces list, derived from live data (the 25-concept canon of
`doc/vector_forces_concept_map.json` crossed with today's placement census and the prop
gallery). Part B is the corpus plan — which mostly means waking machinery that already
exists: 29 concept-map JSONs, their builders, and the `/concept-maps` atlas, all asleep
since one generation event on June 17–20.

## A · Forces: principle → algorithm → bodies

Sequence truth: *"Direction + magnitude = vector. F = ma. Acceleration is the only thing
you feel."* Five rungs at two scales (bench VFM / building Acts), closing as a loop —
rung 5 is rung 1 with the walker inside the arrow.

**Algorithm scenes** (7, from `algorithm_paths`; the XL bench exhibits delegate to these):
`VectorBasics`, `VectorAddition`, `VectorMotion`, `VectorFieldFlow`, `VectorForces`,
`Forces_1`, `Forces_Destruct`.

Legend: **gallery** = the surreal prop object (2026-08-27); *starred* = standing artifact
adopted by the gallery unchanged; standing = placed survivors after the retire;
(–N) = diagram tokens that retire with the swap.

| principle | the surreal object | standing bodies | retiring |
|---|---|---|---|
| Coordinate system | — rung 0: recalled from primitives, a threshold, not a room | — | –3 |
| Vector basics | force_cube* (your shove draws itself) | — | –1 |
| Magnitude / length | length_lantern* (light reaches exactly \|v\|) | — | –2 |
| Unit / normalize | length_lantern* (same lamp, radius 1) | 4 | –1 |
| Addition | tug_of_war (cargo axis: real freight) | — | –6 |
| Subtraction | tug_of_war (the rope that closes the sum) | — | –4 |
| Scaling | **GAP** — see below | — | –2 |
| Dot product | revolving_door (keeps only \|F\|·cos θ) | 2 | –4 |
| Projection / reflection | projection_shadow* | 2 | –1 |
| Cross product / torque | prop_mobile + calder_mobile | torque_crank | –3 |
| Vector field / flow | umbrella_field (wind axis: whisper→gale) | weather_vector_field +2 | –4 |
| Motion / velocity | paused_fountain (time_slice axis) | 3 | –3 |
| Work F·d | — | work_meter family | 0 |
| Friction / drag | brake_skid (sled axis) + drag_corridor (swimmer axis) | friction_ramp +3 | –1 |
| Projectile / launch | paused_fountain's live throw + catapult | launch_arc +8 | –1 |
| Centripetal | — | centrifuge_ring +1 | 0 |
| Gravity / orbit | three_gravities + parlour_orbits | 6 | –5 |
| Spring / Hooke | spring_tower (bob axis) | 6 | –1 |
| Pendulum | pendulum_hall* | 4 | 0 |
| Momentum / collision | momentum_cradle (bobs axis, ballasted & confessed) | collision_carts +3 | 0 |
| Restitution / bounce | bounce_well* | 2 | –1 |
| Lever / balance | prop_mobile + calder_mobile | lever family | 0 |
| Wind / weather | umbrella_field + wind_room* | 1 | 0 |
| Force field (zone) | — | force_field_zone +2 | –1 |
| General force / F = ma | prop_spigot (one gravity, every fate) + force_pad* | 4 | –4 |

**The two honest gaps.** *Coordinate system* is declared closed (rung 0, recalled).
*Scaling* is real: both its representatives retire and nothing surreal replaces them —
the natural object is one prop at ×½ / ×1 / ×2 on one pedestal row (a matryoshka of
the same extinguisher). One future artifact closes the census.

**The page (2026-08-27, same day):** localhost:3003/forces-concepts - one tile per
artifact, its principle underneath, 219 tiles across the 25 concepts. The chips are MAP
MEMBERSHIP (retire / corpus only / in maps / hero); selections persist to
public/forces-concepts/evals.json and tools/read_concept_selections.py reads them back,
so the retire swap runs from clicks, not guesses. Built by
tools/build_concept_gallery.py forces + doc/forces_concept_additions.json (the hand
layer naming the seven new objects' concepts).

## B · The plan: this list, for all 22 sequences

**What already exists (audit 2026-08-27).** 21 of 22 spine sequences have a
`doc/<seq>_concept_map.json` in exactly this shape (concepts / concept_meta with truth +
small·medium·large tiers / scored groups); `formfinding` is the only hole. Builders:
`tools/build_concept_map.py <domain>` (generic, keyword-scored) plus bespoke ones
(vector_forces, ca, foundations, fractal, lsystem…). The `/concept-maps` atlas and
per-sequence pages render them. **Everything is dated 06-17..20** — one generation, no
gate, so the family missed the folds (color 08-24, forces 08-25) and today's twelve
gallery objects.

The plan is five steps, smallest honest version:

1. **Refresh** — re-run every builder post-fold (audit first: which builder owns which
   JSON — the generic one takes the domain as its argv). Acceptance per sequence: every
   token currently PLACED in its maps appears in ≥1 concept.
2. **Gate** — `tools/check_concept_maps.py`, exit = fault count, wired into the release
   gates: per spine sequence — the JSON exists · its `_generated` stamp is newer than
   the sequence json and its maps · no ORPHANS (placed token in no concept) · no
   STARVING concepts (zero map_ready bodies). The forces worked example above is the
   gate's spec run by hand.
3. **formfinding** — build the missing 22nd map.
4. **Ingestion rule** — a new artifact isn't landed until the gate passes, which forces
   the concept map to regenerate in the same commit. (Today's failure mode: the prop
   gallery is invisible to a June file. The gate makes that loud instead of silent.)
5. **The algorithm column** — the builders currently map principle→artifacts; add
   principle→algorithm-scene from each sequence's `algorithm_paths` + the taxonomy's
   delegation notes (forces: 7 scenes), completing Palle's triad
   **principle · algorithm · bodies** per row.

**Judgment stays at the source.** The builders score registry tags and descriptions;
when an artifact lands in the wrong concept, fix its registry entry (tags are truth),
never the generated JSON — a hand-edited output dies at the next regeneration, the
snapshot-vs-ops scar. Where tags genuinely cannot express an assignment, the builder
takes a small per-sequence overrides file, the pattern the necklace ops proved.

**Order and cost.** forces (done above, by hand) → the folded three (color,
transformation, change) → the remaining 17 by staleness → formfinding. Tooling + gate ≈
one session; judgment ≈ 15–30 min per sequence; the atlas page then shows 22/22 with
GAP/STARVING badges from the gate report.
