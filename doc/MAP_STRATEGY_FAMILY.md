# The Map Strategy Family

> Palle: "all these questions are with the goal to create a principal that can
> make good maps with all relevant layers."

**The principal** lives in `tools/map_principal.py`: a strategy only invents
the FLOOR IDEA; `finish()` guarantees every relevant layer (dimensions,
labwall + register palettes, proximity_lod, spawn `"s"`/exit, wall runs, wall
props, mission metadata). Strategies are standalone `tools/gen_*.py` files
that import `mission_graph` helpers (mission, resolve_cast, integration,
staffing) and end in `map_principal.finish`.

**Acceptance bar (every strategy):** pathfinder 0 issues / 100% reachable;
deterministic (seeded — byte-identical per seed); honest sizes (rooms from
em-square footprints); tight around artifacts; verdicts on `/hall-verdicts`
(the shot + walk + rule loop).

## Implemented — THE BOX IS FULL (13 strategies, 2026-07-11)

All: pathfinder 0 issues / 100%, seeded byte-identical, tight, all layers via
the finisher, knobs via `pearl_factory.py --set`, shots + sliders on
`/hall-verdicts`. Floor-cell counts on the randomness/lsystems pair.

| strategy | file | floor idea | cells |
|---|---|---|---|
| act-halls | `mission_graph.py --mode=halls` | three register halls, features fill, chapels the only rooms | — |
| sized rooms | `mission_graph.py --mode=rooms` | per-beat rooms by footprint, serpentine bands with turns | — |
| breathing wang-hall | `gen_wanghall.py` | ONE hall, widths pulse, voltage = width-8 pinches | — |
| ants | `gen_ants.py` | footprint plates; 30 ants find the floor; pheromone ≥ 2 stays | 2051 |
| ant-rooms | `gen_antrooms.py` | perfect close rooms; A*-over-noise opens the between; reuse merges trunks (2.8×) | 771/902 |
| dérive bricolage | `gen_derive.py` | the wanderer with the backpack; forward places, the return improves | **385/471** |
| flocking rooms | `gen_flocking.py` | rooms as boids; separation = honest spacing; sequence-cohesion clusters | 721/884 |
| physarum trunks | `gen_physarum.py` | slime finds circulation; width follows flow (trunk 4 / twig 2) | 1158/1236 |
| reaction-diffusion | `gen_rd.py` | Gray-Scott floor; spots/stripes/sparse by register; A* repairs | 1610/1698 |
| erosion valleys | `gen_erosion.py` | valleys = least-cost water routes between plateau rooms; berm banks | 1495/1645 |
| voronoi territories | `gen_voronoi.py` | sites tessellate; walls at every meeting edge; doors where beat-neighbours touch | 1937/2007 |
| WFC blocks | `gen_wfc.py` | wang blocks wave-collapsed; register weights; spanning-tree unseal (seed-swept 10/10) | ~1268/1012 |
| DLA dendrites | `gen_dla.py` | rooms as aggregation seeds; walkers stick into dendrites; tips pruned | 1662/1764 |
| L-system trunk | `gen_lsystem.py` | the grammar grows the map; rooms at branch tips in derivation order | — |

## Specced — next candidates

### dérive bricolage (the wanderer with the backpack) — Palle 2026-07-10, IN BUILD
ONE wanderer carries the beats in a backpack in teaching order. FORWARD PASS
(the dérive): she drifts — heading momentum + seeded turn noise + a soft pull
toward the centroid so the walk circles compactly — carving 3-wide floor, and
every (6 + footprint) steps places the next artifact on a TIGHT plate beside
her path (footprint + 1 aisle); voltage goes in 1-deep side alcoves. RETURN
PASS (the bricolage — "then goes back again to improve"): she retraces,
pruning floor bulges to a fixpoint (never breaking connectivity), carving up
to 2 shortcut loops where her path nearly self-touches, and staffing benches
at the plates on the second look. Placement and curation are the SAME WALK in
two directions — no other strategy has the return. Tightness target < 1600
floor cells. KNOBS: turn probability, centroid pull, spacing, prune
aggressiveness, shortcut count. `tools/gen_derive.py`.

### flocking rooms (separation as layout) — Palle 2026-07-10
Rooms are BOIDS. Each beat's room (sized footprint+aisle) is an agent with:
- **separation** — the "perfect but close" force: rooms repel inside radius
  r_sep = (w_a + w_b)/2 + aisle, so spacing is exactly the honest gap;
- **cohesion toward sequence neighbours** — room i is attracted to i−1/i+1
  (the walk order becomes physical adjacency; chapters cluster);
- **alignment** (weak) — rooms drift along the spine direction so the flock
  elongates instead of balling up.
Run N seeded steps from a random scatter, freeze, snap to grid. Corridors:
straight gates where sequence neighbours touch; A*-ants (the gen_antrooms
carver) where they don't. Registers by flock order thirds. KNOBS: weights of
the three forces, steps, aisle. The separation/cohesion tension IS the map:
too much separation → archipelago; too much cohesion → one clump — the
readable middle is the design space.

### trunks (slime-mould / Physarum circulation)
The stronger network-finder for "trunks": agents with trail-following
(sense-ahead, turn toward pheromone, deposit) released between room sites —
converges to efficient trunk networks WITH loops (the Tokyo-rail experiment).
Rooms first (perfect close, as ant-rooms); Physarum finds circulation; prune
below flow threshold; corridors width ∝ flow (trunks 4-wide, twigs 2-wide —
width hierarchy = wayfinding). Deterministic via seeded agents + fixed steps.
KNOBS: agent count, sense angle/distance, deposit/decay, flow threshold.
Teaches itself: this is the stigmergy chapter's own algorithm at map scale.

### L-system trunk (the grammar grows the map)
Grow a bracketed L-system 3–4 iterations (seeded angle jitter); the turtle
path IS the corridor skeleton — trunk = main walk, branches = side pools,
beat rooms attach at branch TIPS in derivation order (derivation order =
walk order = teaching order). Room size from footprint; chapels on short
side-twigs. The lsystems chapter literally grows its own habitat. KNOBS:
axiom/rules, angle, iteration count, segment length. Risk: overlap — resolve
by shortening colliding branches (grammar-legal pruning).

### reaction-diffusion plate (Gray-Scott labyrinth)
Seed activator at room sites on a ~96² field, run seeded Gray-Scott to
steady-ish state, threshold U → floor. Feed/kill per REGISTER: spot regime =
arrival (chambers), stripe/labyrinth regime = work (corridors), sparse = depth.
Rooms stamped over the pattern (perfect close); connectivity repaired by one
ant-carve pass for any beat pair the pattern failed to join. The map is a
chemistry — the softbody/morphogenesis chapters' own image. KNOBS: F/k per
register, threshold, steps.

### DLA dendrites (aggregation corridors)
Rooms as aggregation seeds; seeded random walkers stick on contact → dendritic
corridors radiating and joining between rooms. Naturally tight (dendrites are
1-wide; dilate to 3), naturally treelike (loops must be added: 2 extra ant
connections). Fractal register: the fractals chapter's map. KNOBS: walker
count, stickiness, dilation.

### voronoi territories
Scatter beat sites (max-min-distance), Voronoi cells = territories; each
room = footprint+aisle rect at its site; walls on territory boundaries;
doors carved on beat-order shared edges; non-room territory floor optionally
eroded to void by distance from site (tightness knob). Clean partition logic —
the computational-geometry chapter's map. KNOBS: erosion radius, extra doors.

### WFC over wall-kit blocks
The original 8×8 wang blocks, wave-function-collapsed with enclosure weights
per register; beat cells PINNED before collapse (the mission constrains the
wave). Guaranteed edge contract by construction; spanning-tree unseal after.
KNOBS: enclosure weights per register, pin layout.

### erosion valleys
Heightfield (seeded noise) + rain-erosion passes; rooms = plateaus stamped
flat at beat sites; corridors = valley floors below a walkability slope;
bridges/ramps where the walk order must cross a ridge (r utility). The
terrain/noise chapters' map. KNOBS: rain iterations, slope threshold.

### the gardener loop (meta-strategy)
Any strategy above + fitness = walk_evaluator score + gaze_ride clearance +
Palle's `/hall-verdicts` rulings (keep/drop as selection pressure). Evolve
the strategy's knobs per sequence (the auto-research pattern: propose →
generate → walk → rule → breed). Closes the whole system.

## The pattern underneath

Three families by what is FOUND vs DECLARED:
- **rooms-first** (rooms declared, circulation found): ant-rooms, flocking,
  Physarum trunks, voronoi doors — *the space between is the search.*
- **floor-first** (floor found, rooms emerge): ants-plates, reaction-diffusion,
  DLA, erosion — *the figure is the search.*
- **grammar-first** (structure generated, both derived): wang-hall, WFC,
  L-system trunk — *the rule is the author.*

Every chapter can be walked inside its own algorithm. That is the long game:
the curriculum generating its own architecture, one strategy per way of
thinking.
