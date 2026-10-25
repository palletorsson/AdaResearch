# A hundred artifacts the ontology does not have yet

*Palle, 25 Oct 2026: "list 100 new possible relevant artifacts if there are holes or empty space in the
ontology." The holes are measured, not guessed: the 236 of 420 spine principles the grammar has no
words for (`MODULAR_COVERAGE.md`: compare 104, measure 67, procedure 47, retain 45, body 40, frame 22),
the census of what the spine is built of (`SPINE_DISASSEMBLY.md`: arrays 642, engines 752, fields 130,
documents 84), and the kernel pieces the 88 terms never touch (`by`, `measure`, `replicate` as recurse
or rewrite, `field`, most `step` rules, `light`, `label` as a construction). Each entry is written in
the grammar's notation and says which hole it fills and what it needs:*

- **now** — buildable with the kernel as it is (compose, associate, transform, times, array, assemblage,
  engine physics/trace/hand/sine/noise/random/logic, sort, connect, prefab);
- **by / step / field / replicate / measure** — waits for that kernel piece (the plan's waves);
- **walk** — belongs to the walk model (the visitor's body), not the builder, and needs the game.

## A. Instruments — a value read off a thing, retained, compared (the largest hole: 216 principles)

| # | artifact | expression | hole it fills | needs |
|---|---|---|---|---|
| 1 | `ruler` | measure(line, length) drawn as ticks along it | length as a reading, not a size | measure |
| 2 | `protractor` | measure(two lines, angle) as an arc with the number | angle (triangle, rotation, forces) | measure |
| 3 | `counter` | measure(array(x), count) as a label that follows the array | the count the reader makes | measure |
| 4 | `scale_pan` | two plates on a rod over a pivot + step(physics): the heavier side drops | compare by weight — a comparison with a physical verdict | now |
| 5 | `plumb_line` | point + sphere_collider on a rope + step(physics) — vertical, read off the wall | the frame: what "down" is here | now |
| 6 | `spirit_level` | plank + a sphere in a shallow channel + step(physics): the ball tells the tilt | measure(tilt) by a body, not a number | now |
| 7 | `odometer` | measure(trace, path length) retained as a growing number | retain: how far, not where | measure |
| 8 | `stopwatch` | measure(step, ticks) as a readout that a hand starts and stops | time as a reading; procedure | measure |
| 9 | `height_gauge` | a post with marks; measure(any thing placed, height) | compare heights without lifting | measure |
| 10 | `histogram_rack` | array(box) by(height = count of samples in each bin) | the record's shape (Random_Gaussian) | by + measure |
| 11 | `entropy_meter` (plan) | measure(scatter, shannon entropy); compare order, shares, entropy | the three entropies without equating them | measure |
| 12 | `balance_scale_logic` | scale_pan whose dropped side closes a gate | compare → a decision | now |
| 13 | `tally_board` | array(peg) + step(hand: a peg moved per event) | retain by hand; a record nobody computes | now |
| 14 | `speed_trap` | two gates on a track + measure(ball, time between) | rate as a difference of readings | measure |
| 15 | `slope_reader` | a ramp whose angle is set by a slider; measure(ball, distance travelled) | the derivative as an experiment (change) | measure |
| 16 | `comparator_tray` | two things side by side + a label that says which is longer / heavier / darker | compare under a named rule | measure |
| 17 | `residual_bin` | sort(parts) + a box for what the rule did not accept | the leak made furniture | now |
| 18 | `memory_shelf` | array(slot) + step(hand: what was carried is set down and stays) | retain across a room | now |
| 19 | `frame_marker` | three coloured lines at the thing's own origin + a label "measured from here" | the frame every measure carries | now |
| 20 | `clock_face` | line + by(rotate, t) over a disc with twelve marks | the clock as a construction, not a UI | by |

## B. Physical logic — the beginning of logic with a ball (Palle's own hole)

| # | artifact | expression | hole it fills | needs |
|---|---|---|---|---|
| 21 | `branch_gate` | ramp + a wedge at the fork: the ball goes left or right by where it entered | if / else in matter | now |
| 22 | `and_gate` | two balls must both press a plank before the latch lifts | AND | now |
| 23 | `or_gate` | either ramp feeds the same channel | OR | now |
| 24 | `not_gate` | a seesaw: a ball on one side lifts the other side's ball out | NOT | now |
| 25 | `latch` | a plank held by a peg; a ball knocks the peg; the plank drops once | a state that lingers | now |
| 26 | `reservoir` | a bucket that tips when the third ball lands — counts to three | a counter without a number | now |
| 27 | `marble_run_loop` | ramps that return the ball to the top by a lift (hand engine) | while | now |
| 28 | `flip_flop` | a seesaw channel that alternates the exit each time | state, memory of one bit | now |
| 29 | `domino_line` | array(plank on edge) + step(physics): one push, a wave of falls | sequence, propagation, delay | now |
| 30 | `cam_follower` | a cylinder with a bump + by(rotate) + a plank resting on it: the plank lifts once a turn | a periodic signal from a shape | by |
| 31 | `pulley_pair` | two sphere_colliders on one rope over a cylinder: one down, one up | transfer, conservation | now |
| 32 | `pendulum_row` | array(pendulum, 5) with ropes of growing length | a wave of phases (Newton's cradle's cousin) | now |
| 33 | `trapdoor` | a plank hinged (rod) at one edge + latch | passage that changes | now |
| 34 | `ratchet` | a wheel with teeth + a pawl: turns one way only | irreversibility | now |
| 35 | `half_adder_table` | and_gate + xor built from two branch_gates, on one table, with labels | the AND and XOR the logic room names | now |

## C. Nets, ropes, soft — connect × step (just opened)

| # | artifact | expression | hole it fills | needs |
|---|---|---|---|---|
| 36 | `hammock` | net hung from two posts by its ends; a cube dropped in | a net that holds a load | now |
| 37 | `rope_bridge` | two ropes + planks tied across + step(physics) | passage on ropes (the walk) | now |
| 38 | `tent` | net over a frame of three sticks; its margins pinned by points | the outline followed, from inside | now |
| 39 | `cargo_net` | net wrapped around a pallet and tied at the corners | connect as containment | now |
| 40 | `chain_curtain` | array(bead_chain, 9) hung from a plank | a doorway you pass through | now |
| 41 | `spring_mattress` | array(spring_pair, 5 × 5) under a plank; a dropped ball bounces | spring as a surface | step |
| 42 | `tensegrity` | three rods and six ropes: the rods never touch | tension holds compression | now |
| 43 | `clothes_line` | a rope between two posts; planks hung by two ties each | hanging things with two ropes | now |
| 44 | `cloth_sheet` | 10 × 10 net with a surface stretched over it | association on a net | now |
| 45 | `trampoline` | a ring of points, a net tied to them, a ball from above | the membrane's rim held | now |

## D. Fields — a surface from a function of space (130 artifacts are fields; the grammar has none)

| # | artifact | expression | hole it fills | needs |
|---|---|---|---|---|
| 46 | `height_field` | grid by(noise, height) — a terrain of cubes | noise as relief | by |
| 47 | `iso_blob` | two points + field(iso): a metaball you can walk around | the isosurface sequence's first term | field |
| 48 | `cut_block` | field(cube − sphere) | boolean difference | field |
| 49 | `carved_tunnel` | field(block − a line of spheres) walkable | passage by subtraction | field |
| 50 | `threshold_wall` | grid by(noise) with cells shown only above a threshold | the line that decides | by |
| 51 | `gradient_floor` | quad + association(shader: gradient) under the feet | a shader as ground | now |
| 52 | `contour_stack` | array(quad outline) by(height = level of a field) | contours as slices | by + field |
| 53 | `voronoi_fence` | points + field(voronoi) as thin walls | a boundary as membrane | field |
| 54 | `sand_pile` | step(array(sphere_collider, 200), physics) poured from a funnel | a field made of bodies | now |
| 55 | `fog_box` | light + association(volumetric) in a frame | a field you cannot touch | now |

## E. Replication and grammar — recurse, rewrite, tiling (the spine is 642 arrays)

| # | artifact | expression | hole it fills | needs |
|---|---|---|---|---|
| 56 | `koch_fence` | replicate(line, 4 scaled copies, depth 4) stood up as a fence | recurse, first term | replicate |
| 57 | `branch_tree` | replicate(stick, two rotated copies, depth 5) | the tree without blueprints | replicate |
| 58 | `menger_stair` | replicate(cube, 20 of 27, depth 2) that a body can climb | a walkable fractal | replicate |
| 59 | `turtle_wall` | rewrite(F → F+F−F, 3 generations) on a wall as tape | the sentence become a shape | replicate |
| 60 | `truchet_floor` | array(tile with a quarter arc) by(random rotation) | tiling by chance | by |
| 61 | `brick_wall` | array(box) by(offset every second row) | the tiling rule that stands up | by |
| 62 | `wallpaper_p4m` | replicate(motif, mirror, rotate 4) | one of the seventeen | replicate |
| 63 | `stack_stair` | times(plank, 8, stack with a step) | the stair as a stack | now |
| 64 | `spiral_ramp` | times(wedge, 12, ring) rising | ring layout with height | by |
| 65 | `ply_board` (have) | times(ply, 7, stack) | the deck as plies — already built | now |

## F. The body — reach, passage, hand (40 principles; the walk model's hole)

| # | artifact | expression | hole it fills | needs |
|---|---|---|---|---|
| 66 | `reach_post` | a post with a mark at the hand's height; measure(hand, highest touched) | reach as a reading | walk + measure |
| 67 | `squeeze_gap` | two walls a shoulder apart; a wider pair beside | passage a particular body can traverse | walk |
| 68 | `step_set` | times(box, 5, stack) with risers 0.1 … 0.5 | which step a body can take | walk |
| 69 | `duck_bar` | a plank at head height across a corridor | passage by bending | walk |
| 70 | `carry_test` | three cubes of three sizes on a shelf, a mark where they must go | what a hand can carry | walk |
| 71 | `footprint_tiles` | array(quad) by(random colour) that mark where a foot stood | trace of the body | walk + step |
| 72 | `hand_scale` | a tray that reads the weight of what is put on it | the hand's own instrument | measure |
| 73 | `mirror_frame` | a quad that shows the body's trace behind it | the body as apparatus | walk |
| 74 | `doorway_family` | times(doorway, 4) by(width 0.4 … 1.0) | the aperture axis | by |
| 75 | `throw_range` | marks on the floor at 1, 2, 3 m; a ball to throw | the hand's reach extended | walk |

## G. Documents built, not placed — labels, screens, readouts as constructions (84 are documents)

| # | artifact | expression | hole it fills | needs |
|---|---|---|---|---|
| 76 | `caption_post` | post + label that names the thing beside it | the label as a term | now |
| 77 | `readout_box` | box + label whose text is measure(any) | the readout the kernel can build | measure |
| 78 | `plaque` | quad + association(paper) + label | the plaques of the crisis rooms | now |
| 79 | `scoreboard_refused` | a board that shows what was dropped and never a total | the leak bus's rule made visible | now |
| 80 | `recipe_card` | label with the thing's own expression beside it | expand, in the hall | now |
| 81 | `before_after_pair` | the same thing twice, one changed, labels | compare as a pair | now |
| 82 | `lineage_tag` | a tag on a deconstructed part naming what it came from | the kept lineage, visible | now |
| 83 | `error_plaque` | label with the builder's refusal text | the undecided plaque, made | now |

## H. Light, colour, sound — primitives the terms barely use

| # | artifact | expression | hole it fills | needs |
|---|---|---|---|---|
| 84 | `lamp_post` | post + light(warm) at its top | the light primitive's first term | now |
| 85 | `colour_lamp_row` | array(lamp_post, 5) by(colour list) | light meets surface (colour) | by |
| 86 | `shadow_sundial` | post + light that by(rotate, t) around it | time read off a shadow | by |
| 87 | `swatch_wall` (plan) | array(quad) by(colour) | the census room's wall | by |
| 88 | `rgb_mixer` | three lights, three sliders, one white quad | mixing by light, not paint | now |
| 89 | `bell` | cube + a hanging ball on a rope + audio(on contact) | a sound as a construction | now |
| 90 | `wind_chime` | array(bead_chain, 5) + audio(on contact) | sound from physics | now |
| 91 | `dark_room` | walls + no light + one lamp the hand can carry | the light as the only instrument | now |

## I. Sequence-specific gaps — relation, learning, swarm, synthesis

| # | artifact | expression | hole it fills | needs |
|---|---|---|---|---|
| 92 | `node_edge_toy` | array(node) + connect(rod) you can rearrange by hand | a graph with no coordinate | now |
| 93 | `shortest_path_floor` | tiles that light along the path between two chosen nodes | pathfinding as a floor | by |
| 94 | `flock_tank` | array(sphere_collider, 30) + step(boids) in a glass box | the first swarm term | step |
| 95 | `ant_trail` | step(agents leave marks; marks decay) on a floor of quads | pheromone, memory in the field | step |
| 96 | `loss_bowl` | a bowl (field) + a ball that rolls to the bottom | descent as a landscape | field |
| 97 | `perceptron_rack` | array(node) + connect(weights as rods of varying thickness) | what a weight keeps | by |
| 98 | `self_member_cabinet` | the term that contains itself, refused, with the refusal framed | Russell, built | now |
| 99 | `axis_sweep_row` (plan) | array(term) by(its own dna axis) | the lab reads its families | by |
| 100 | `open_term_bench` | a bench where a visitor's edits save a term | the studio in the hall | walk |

## Where the empty space is, in one paragraph

Of the hundred, counted from the needs column: 50 build today, 16 wait for `by`, 14 for `measure`,
6 for `field`, 5 for `replicate`, 4 for a `step` rule, and 9 belong to the walk model (four of those
also need a piece). The empty space is not in things — the spine has 1331 of them — but in
**instruments** (A: nothing in the grammar reads a value), **decisions** (B: nothing makes a verdict
out of matter), **fields** (D: 130 artifacts of the spine are fields and no term is), and the
**body** (F: no term knows what a visitor can reach, squeeze through, or carry). Section B needs no new
kernel at all, which makes it the cheapest hole to fill and the one Palle named first.
