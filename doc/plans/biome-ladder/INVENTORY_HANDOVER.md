# Inventory, prefabs and the hand — continuation handover

Updated 31 October 2026. Companion to [PLAYGROUND_HANDOVER.md](PLAYGROUND_HANDOVER.md): that document
is the structure (the principal places, the bench, floor 210); this one is the hand — what the player
carries, places, binds, paints and takes back, and how it grows down the tower. The same evidence rule: a
thing is **built** only when a probe shows it, **proposed** when only said. Forum: questions to the playground
side are thread `261030-9gz0s`; the day's heads-ups are `261029-x0yw4` (exports), `261029-dtdlu` (left X),
`261030-dr7cn` (terms.json).

Palle's frame, 29–31 October: *"the primitives fill the inventory so we can add things to the levels, we can
play with the surroundings like in Garry's Mod. The Playground will host and integrate some of the spatial
artifacts … Not all levels are playgrounds but they will be able to connect the other levels in a cohesive
fuzziness."* And: *"we have all the principles we need so now the question is how do we integrate all these in
a once fuzzy cohesive world."*

## What is built (each line has a probe)

| capacity | where | probe | commit |
|---|---|---|---|
| The palette: a four-faced Open Brush drum on the left wand (HAND · KNOBS · TAPE · PLACED), left X or palm up, ◀ ▶ roll it, the pointed face lifts | `commons/player/inventory_prism.gd`, `inventory_face.gd`, on `museum_rig.tscn` (museum and Void) | `probe_inventory_prism` 23/23, `probe_void_x_prism` 7/7 | `05b8f4743`, `b9abdeda3` |
| The prefab list: 22 items in Palle's order, paged two columns, placed where the wand points on the metre grid, turned by a knob; the clock only on walls | `commons/data/inventory/items.json` (truth), `inventory_hand.gd` | prism probe H, K, O | `79d031bee`, `21cf8fab9`, `ee376540c` |
| The ghost and the aim line; grip takes back the pointed thing | `inventory_prism.gd`, `inventory_hand.placement_at` | prism probe P | `263197720` |
| The base rule: bodies fall onto what is under them and stack; fixtures (clock, health, nozzle, wedge, pyramid) stand frozen; the sand-block rule (a grid thing at rest square takes its point and freezes); free hanging when pointing at nothing | `inventory_carrier.gd`, `inventory_hand.gd`, `items.json gravity/snap` | prism probe R, S, W, U, V | `5298a7e8d`, `466f0cc0f` |
| The lattice: the six-socket ball on the metre grid, the rod snapping to sockets or lying on the grid, the support graph, tape binding | `commons/artifacts/playground_kit/`, `tape_roll/` | `probe_playground_kit` 9/9, `probe_tape_binds_kit` 4/4, `probe_inventory_vr_hand` 5/5 | `eb3dbdfa9`…`af04a4404` |
| The tape worn on the hand, the 30 cm leg rule, the printed roll, designs | `tape_roll/roll.gd`, `items.json` tape | `probe_tape_worn` 7/7 | `201d785d2` |
| The rubber (take one back) and the pin (freeze / release) | `commons/artifacts/inventory_rubber/`, `inventory_pin/` | prism probe M, V | `b1306902d`, `466f0cc0f` |
| The budget (draws 120 · lights 2 · viewports 16 · tris 60k, refused not evicted), costs measured per item, copies as one multimesh, the crate as one mesh | `costs.json`, `inventory_instancer.gd`, `mesh_merge.gd` | `probe_inventory_cost`, prism probe L, N | `af7fdd2be`, `b1306902d` |
| The hand canvas: a 4 × 2.5 m glass the fingertips paint, the stroke by how many touch | `commons/artifacts/hand_canvas/` | `probe_hand_canvas` 6/6 | `7e2b4d247` |
| Distance grab made explicit (line + ring to the would-be target) | `commons/player/grab_hint.gd` | prism probe Q | `263197720` |
| The web twin: `/catalyst-inventory` (the palette's faces), `/prefab-timeline` (every prefab as a model, floor by floor, the floor edited there and written to items.json) | ada_encyclopedia | tsc; browser | `985029222`… |
| The input tree by context | `commons/player/EVENT_TREE.md` | — | `263197720` |

Headset: version 8 / 2026.10.30 was reinstalled from this tree several times on 30 Oct; the last install
(`5298a7e8d` + diagnostics) writes one `[inventory] placed …` line per placement to `user://logs` (hand,
hit, point, where the thing is a moment later, the origin's position and scale). **Open fault:** Palle saw
the counter and the nozzle land near (0,0,0) in VR; the desktop Void probe places correctly with the origin at
(−5, 0, 1). Read the log lines after the next headset session before guessing further.

## The spine plan — what each sequence hands the inventory

Palle's list (30 Oct): *"the point, line, triangle, quad, a tetrahedron corner, the full cube, other primitives
as decoration or strange add-ons, transformation (moving bridges), then colours (a selector, colours for the
elements), tiling (the first pattern on the side of the structure), forces (jump pads, a cube on a spring to
avoid), wave functions (4 × 4 sine space, synced bridges), randomness (a node moved randomly, a random-walk
construction, a 4 × 4 random surface), cellular automata (neighbour thinking), L-systems (a 6 × 6 inner yard
for plants), the rest walking inside strange worlds through the grid structure."*

| sequence (floor) | the inventory gains | state |
|---|---|---|
| point | the six-socket ball on the metre grid; the clock as the first fixture | built |
| line | the 1 m and 2 m rods (sockets, the stick, the grid), the tape (bind, print, designs) | built; the 2 m rod is `plank2`'s cousin, a `units: 2` rod exists as a knob |
| triangle | the wooden triangle ruler (a modular term); the half-fill / fill of a square by triangle faces | ruler built; faces proposed (TriangleTable / folded edge) |
| transformation (floors 13–20) | moving bridges, the pivot, the gantry; the workbench's parts | playground side |
| colour | a palette knob on every element (today the kit's `colour` only); paint station; gradient over a structure | proposed; `items.json` knobs are the hook |
| tiling | the first pattern on a panel; the aged tiling | proposed (`/pattern-studio` exists) |
| forces | jump pads, a cube on a spring | proposed |
| wave functions | 4 × 4 sine space, synced bridges | proposed |
| randomness | a dice that changes the crossing; random-walk construction; a 4 × 4 random surface in the steel basin | playground side (PC walk, PP04) |
| cellular automata | neighbour rules on the lattice | proposed |
| L-systems | the 6 × 6 inner yard, critters | playground side (SW04) |

Each row's "gains" is a line in `items.json` (`floor`, `unlock`) plus an artifact that exists; the row is done
when the item places from the palette on a floor and a probe shows the rule it adds. Curate the floors at
`/prefab-timeline`.

## Where to start — bang for inference

1. **Read the headset log** for the (0,0,0) fault. One hour, and it decides whether placement on the Quest
   can be trusted at all.
2. **The playground's parts as inventory items** (forum question 2): if the answer is one grammar, the ball
   and rod take the approved finish and the contract's legality, and every later sequence builds on parts
   that are also the floor-210 frame. If two grammars, keep the kit as the tutorial's and move on.
3. **Colour as the first per-element knob** — the smallest change that touches every item and the first
   sequence Palle named after the primitives. The `knobs` block already carries it for the kit.
4. **One hosted activity through the palette** (PP04/PP05 from the playground side): the disco plate placed
   from the hand on floor 210 with its parameters as knobs. If that works, the palette *is* the place-authoring
   UI the handover leaves open.

## The report loop, for the hand

The playground's [ITERATION_REPORT_TEMPLATE.md](ITERATION_REPORT_TEMPLATE.md) applies unchanged. For the
inventory, the per-iteration record is smaller and lives in three places that already exist:

- `commons/data/inventory/items.json` — the truth of what can be held, with `floor`/`unlock`; a change here is
  the curation.
- the probes — `probe_inventory_prism` grows a lettered check per capacity (A…W today); a capacity without a
  letter is not built. `probe_inventory_cost` re-measures after any artifact change.
- `commons/player/INVENTORY.md` — one paragraph per rule with Palle's words, the probe and the trap met.
  `EVENT_TREE.md` for input.

**Parity**, per the playground's rule: each item's status in bench / glass / tower / editor / Quest. Not
recorded yet (forum question 3); until decided, assume tower + Quest only.

## Still open from the day's discussion (the hand's side)

- The counter and nozzle at (0,0,0) on the headset — log first.
- Grab as a select tool at the bench; a dice that changes a crossing; the working wheel above the model; the
  1:4 glass box with an entry point and a VR set on the table — the playground/workbench side (Codex).
- The palette's per-context default (workbench up, glass hall on X) — the number has no home
  (`EVENT_TREE.md`).
- The 2 m rod as its own item; the triangle *faces* (half / full fill of a square).
- A clear gesture for the hand canvas; its strokes are not yet an artifact that can be saved or carried.
- An endless walker through the text; the renaissance-stages image app; the sticky-map altar — other threads.
