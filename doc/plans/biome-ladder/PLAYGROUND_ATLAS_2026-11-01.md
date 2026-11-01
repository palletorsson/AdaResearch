# Playground atlas, second set — 18 precedents read against the vocabulary

1 November 2026. Palle pasted a second atlas of indoor-playground precedents (sources linked in the paste; image
links expire, so only the readings are kept here). Each row: the precedent, the principle the atlas extracted,
the experiment it proposed, and what it is in the words we have — `place` (a plate or pool in a scaffold frame),
`slot` (a surface fitted to a place: footprint, rim, floor or wall), `board` (a framed display plate, repeated),
`kit` (points, rods, panels, wedges on the workstation), `pocket test` (balls read a surface), or a word we do
not have yet.

## 1. Primitives, transformations, assembly

| # | precedent | principle | proposed experiment | in our words |
|---|---|---|---|---|
| 1 | Ocean Eastville (Playmondo) | cubes, wedges, cylinders, Boolean holes; form not colour | snap foam primitives, change scale and orientation | the kit and the inventory's boxes and wedges on the metre grid; Boolean holes are missing from the kit |
| 2 | Rubik climbing tower (tiNiWorld) | stacked, rotated coloured cubes | rotate a layer to change connectivity | the modular cubes on a rotating part (the kit has `motion`); the connectivity change is the workstation's support graph re-evaluated after a turn — a new word, `layer` |
| 3 | NUBO (Sydney) | tubes swept along curves climb, bend, descend | edit a spline in VR, extrude a tube, release a ball | **not a word yet**: `tube` — the rod kit swept along a spline; the ball is the pocket test |
| 4 | MIJU (Buenos Aires) | tube slide, stepped platforms, modular seating; pixel walls, rotating labyrinths, ball circuits, sequencers | translation and rotation as a room-sized level editor | the stack and the ramp are places; the pixel wall is a rack of 1 × 1 boards with state; the ball circuit is the marble track below |

## 2. Colour, tiling, waves, repetition

| # | precedent | principle | proposed experiment | in our words |
|---|---|---|---|---|
| 5 | The Playground (Snarkitecture 2026) | layered plywood contours make playable topography | heightfield → contour slices; sine, noise or functions make hills, stairs, caves | **nearly a word**: a slot surface rendered as contour steps (`contours: 0.25`) — walkable stairs from any walkgrid; cheap and striking |
| 6 | Wirthshof hexagonal cells | hexagonal tessellation, some cells open, some solid | cellular automaton grows a cave, redistributes openings | the cellular-automata surface in a slot, stood as walls; hex cells are a new tiling for the board (`shape: hex`) |
| 7 | Neobio (X+Living) | chevron floors, repeating arches, scale jumps | a shape grammar turns an interior surreal by scale and repetition | the array and the corridor with a tiling content; the scale jump is a board `scale` the vocabulary lacks on purpose (whole metres) |
| 8 | MELAND CLUB | checkered tiles, circular ornaments, spiral tubes, colour zones | colour as force: red attracts, blue repels, stripes redirect | the pocket test with a coloured surface whose colour sets friction and bounce per cell — a `colour_rule` on a display plate's content |

## 3. Forces, networks, soft bodies

| # | precedent | principle | proposed experiment | in our words |
|---|---|---|---|---|
| 9 | An Atlas of Superpower (waa) | tubular branches, mesh platforms, dune floors of trapezoidal blocks | L-system branches, a force solver, a noise terrain | the L-system surface and the noise surface in slots; the branches are `tube` again |
| 10 | Ed.Square Play (Tilt) | suspended pods, rope bridges, perforated skins | pods as graph nodes, tunnels as edges, springs and gravity | the workstation's point–rod graph made big: pods are points, tunnels rods — a `graph` place |
| 11 | Net Blow-up (Numen/For Use) | an inflatable tensioning an interior net; people deform it | a soft-body labyrinth where weight changes geometry | the SoftBody traps are recorded (sphere colliders give no soft contacts; own verlet shell); a `net` is a real new word and a known cost |
| 12 | Woods of Net (Horiuchi MacAdam) | knitted mesh, elastic tension, hanging spheres, colour regions | a spring lattice that is floor, hammock, trampoline or tunnel by tension | the same `net`; the hanging spheres are the stacked six-balls hung |
| 13 | Balloon Monster (PLAY! PARK) | thousands of balloons as soft branching shapes, changing with use | a procedural inflatable organism from repeated cells | the ball pit's balls bound into a body — `net` plus the pocket test's balls |

## 4. Logic, feedback, programmable environments

| # | precedent | principle | proposed experiment | in our words |
|---|---|---|---|---|
| 14 | Kinderreich (Deutsches Museum) | a mechanical marble track: gravity, loops, wheels, branches, capture, release | a physically playable if / else / while; a ball carries state | **nearly a word**: `track` — rails of the kit's rods with gates; the pocket test's balls and readout already count arrivals |
| 15 | Loop (COS × Snarkitecture) | suspended tracks carrying glass marbles; precision, not accident | marble flow with gates, counters, sensors, junctions | the same `track`, with the logic halls' gates as junctions |
| 16 | LEGO House | a tiny vocabulary, unlimited assemblies | a rule-based prefab language | the modular grammar (terms.json) and the kit; already the project's premise |
| 17 | Graffiti Nature (teamLab) | drawn forms enter a projected ecosystem | agents, cellular processes, visual feedback; draw, introduce creatures, change rules | the hand canvas feeding the biome: a drawing becomes a critter — a bridge between two existing systems |
| 18 | Wavy Walls (Snarkitecture) | thin vertical ribs along curved paths make rooms without enclosing them | a maze from a pathfinding graph, walls distorted by noise or growth | the corridor principle with the walls as rib boards along a path; the distortion is a slot surface stood up |

## The atlas's own table, annotated

| hall or method | playable primitive | status |
|---|---|---|
| Primitives | blocks, rings, arches, tubes, holes | blocks and wedges yes; rings, arches, tubes, holes no |
| Transformations | rotate a structure to open a route; scale into terrain | the kit's motion exists; the route change needs `layer` |
| Colour | colour as force, material, signal, state | the pocket test can carry it as a `colour_rule` |
| Tiling | hex, square, irregular modules with connection rules | square boards yes; hex and connection rules no |
| Wave functions | slides, undulating floors, contour walls, kinetic tracks | the slot surfaces; contours and tracks are the two nearest words |
| Randomness | seeded scattering of blocks, chambers | the random surface; a scattering of boards is a `repeat` with jitter |
| Noise | continuous displacement of terrain and pathways | the noise surfaces, in slots, floor and wall |
| Cellular automata | rooms and cells that grow and disappear | the CA surface; cells as boards with state is the pixel wall |
| L-systems | branching tunnels, nets, climbing architecture | the L-system surface; branching tubes need `tube` |
| Procedural | assembly rules for variable connected spaces | the place builder and the board vocabulary |
| Soft bodies | nets, inflatables, cushions, pressure | `net`, with the traps already known |
| Forces | gravity, attraction, tension, springs, rolling | the pocket test, the kit's support graph |
| Swarms / particles | ball pits, marble flows, moving populations | the ball pit place type (unbuilt), `track` |
| Machine learning | learn from play to propose configurations | nothing yet; the ledgers exist |
| Feedback / emergence | play changes the environment | the live-update chain; the pocket test's readout |

## What to build from this, in order

1. **Contours** — a rendering mode of the slot surfaces: the heightfield as walkable steps of a set rise. One
   function in the base class; every walkgrid gets stairs, caves and plateaus; the Snarkitecture precedent.
2. **Track** — rails of rods with gates and a counter, the pocket test's balls as the marbles; the logic halls'
   if / else as junctions. The Kinderreich and Loop precedents.
3. **Tube** — the rod kit swept along a spline, a ball released through it. NUBO and waa.
4. **The ball pit** — a place type, still owed from the first atlas.
5. **Net** — only with the soft-body lessons in hand; the costliest word.

The atlas's closing idea is the right one: combine two playground functions in one prefab. The pocket test is
already that — a ball pit that is a measurement.


## The two deep-research reports (1 Nov), what transfers

Palle attached two ChatGPT deep-research PDFs: *Indoor Playgrounds as Generative-Design Systems* (14 pp.) and its
backing conversation, *Indoor Playgrounds as Computational Landscapes* (a 33-image catalogue: Luckey Climbers,
Play9, Architensions, Moureaux, COBE, HAO, plus Perlin, Bourke's L-systems, AADRL automata, WFC, Vellum,
Kangaroo, IAAC differential growth). Their numbers are "exploratory ranges, not specifications". What is worth
keeping, against the vocabulary we have:

**Rules that transfer directly**

- *The layered stack*: topology → primitive geometry → repetition → deformation → material/physics → colour →
  label. This is the order our spec already follows (place → board → repeat → surface → content → title) and the
  order a prompt or a recipe should be written in. Specify topology and geometry before style.
- *Four compositional modes*: frame systems (columns, beams, decks, tubes), landscape systems (mounds, ramps,
  contoured floors), village systems (repeated room modules), object-field systems (many small objects on an
  open floor). Ours: the scaffold and the boards are the frame; the slot surfaces are the landscape; the places
  are the village; the array and the ball pit are the object field. A hall should declare which mode it is.
- *Algorithmic clarity*: one algorithm controls the macro-form and one secondary method supplies variation.
  "The Voronoi playground", "the wave playground", never all at once. The example structures obey this; the hall
  on floor 210 does not yet — three structures and three samples share one slab.
- *Legibility at three scales*: room (an understandable circulation), equipment (each object says climb, crawl,
  slide, balance, hide), detail (pattern and material carry the algorithm). The display plate carries the third;
  the second is what the pocket test and the kit do; the first is the place recipe's job.
- *Structured repetition plus controlled perturbation*, and *stratified randomness*: global (the layout family),
  module (widths, heights, rotations, colours), surface (texture, curvature), micro (balls, seams, grain), each on
  its own seed. Most parameters vary ±5–15 %, a few ±20–35 %, one hero 40–70 %. For us: a `jitter` on a board's
  repeat (module randomness), the surfaces' own seeds (surface), the pocket test's radius jitter (micro).
  Palle's "the playground nodes more and more random" is this ladder walked upward.
- *Shape-producing vs motion-producing physics*: a still frame needs the first (sag, compression, indentation);
  the second is for play. The slot surfaces are shape; the pocket test is motion.
- *Palette roles*, not RGB clusters: background-neutral, material-base, primary zone, secondary zone, accent,
  safety. Ratios 50–70 / 15–30 / 5–15 / 2–8 %. Our plates and frames have no palette rule yet; the kit's blue
  and yellow are the material base by accident.

**Parameter ranges, against our parameter files**

| method | the report's range | ours now |
|---|---|---|
| Perlin/simplex noise | octaves 2–6, persistence .35–.65, displacement 2–20 % of feature size | noise_space: octaves 1–4, height_scale .1–3 — the displacement rule (relief as a share of the footprint) is the better knob |
| fBm | Hurst .35–.75, lacunarity 1.7–2.5, 3–7 levels | the fractal surface has no file yet |
| L-systems | 2–5 iterations, branch angle 15–45°, contraction .55–.85, branching .3–.8 | the L-system surface has no file yet |
| cellular automata | grid 32²–256², fill .35–.55, 3–12 iterations | the CA surface has no file yet |
| Voronoi | 10–150 seeds, Lloyd 0–5, jitter 0–40 % | the Voronoi surface has no file yet; Voronoi as a *place layout* (pads, zones) is a missing word |
| particles / ball pit | 2k–50k, size jitter ±5–15 %, restitution .2–.65, friction .2–.8 | pocket test: 100, jitter ±12 %, bounce .1, friction .5 — the pit is 20× more balls and livelier |
| soft body / mass-spring | stiffness 20–300, damping .05–.5, 10–60 subdivisions/axis | the recorded SoftBody traps; `net` not built |
| wave fields | 1–4 base waves, amplitude .02–.15 of width, 2–3 superposed frequencies halving per octave | sine_space_floor: one frequency; the wave-interference surface is the superposition and has no file yet |

**New words the catalogue names that we do not have**: the spiral / helix climber (Luckey's stacked platforms
rising round an atrium — our stack with a turn per level is the first step: `repeat.turn` on floor boards with a
vertical step already compiles), the tube and the net (as before), Voronoi partition as a place layout, Wave
Function Collapse for modular tiles with connection rules, differential growth for folded walls.

**One sentence to keep**: "turn play behaviour into the input of generative systems". The pocket test, the
live-update chain and the hand canvas are three inputs that exist; a structure that changes because it was
walked is the piece none of them is yet.
