# The playground stack: one model of a thing, in the hand and in the editor

Palle, 2026-11-06. This follows his notes from Blender and the conversation on the factory and the playground.
Primitives are primitives. Array and boolean are modifiers. Colour is a material property. Randomness is a modifier,
force is physics, and soft bodies bring deform and physics together. The inventory (the hand) and the playground editor
(the map) should follow the same principle. The editor starts with only vertices, edges and faces. Each sequence then
adds one add-on, in a fixed order: arrays, then randomness, then deform, and so on. **The editor stays consistent:**
an add-on adds entries, never a new layout.

## The one shape

Every thing the hand makes or the editor holds is one record:

```
{ primitive,            # the mesh: vertices, edges, faces (the kit's balls, rods, faces)
  state: frozen | physics,
  transform,
  stack: [ modifier, ... ],   # ordered: array-then-random is not random-then-array
  material }
```

Today the parts of this record live in separate places:

| Part | Lives in |
|---|---|
| The hand | `commons/data/inventory/items.json` |
| The kit catalogue | `commons/void/primitive-prefabs.json` |
| Frozen or physics | the gravity rule and the pin tool (items.json `_rules`) |
| Where things are kept | `user://inventory/placed.json` |
| The add-ons unlocked by floor | `commons/data/inventory/workbench.json` (it was snap only; the Triangle stage is the first add-on) |

## Blender's columns along the spine

| Blender | In the hand and the editor | Arrives with (spine order) |
|---|---|---|
| Object / Edit mode: vertices, edges, faces | the primitive; frozen or physics | primitives (1) |
| Transform | move, turn, scale | transformation (2) |
| Constraints / drivers | "if this, then that" between things | logic (3) |
| Generate: Array, Mirror | repeat, then pattern | array_tutorial (4), tiling (6) |
| Material | colour, then shader | color (5), shaders (13) |
| Physics: Rigid Body, force fields | gravity, push, spring | forces (8), formfinding (9) |
| Deform: Wave, Displace | wave, noise | wavefunctions (10), noise (12) |
| Modify: randomize | random offset and draw | randomness (11) |
| Geometry Nodes | rules that grow | cellular automata, fractals, L-systems, procedural (14-17) |
| Deform + Physics: Soft Body | where the columns meet | softbodies (18) |
| Remesh / Boolean | field to surface, cut and join | isosurfaces (19), boolean_surfaces (20) |
| Particles / boids | many agents | swarmintelligence (21) |

## What the sieve says

**What this rules out.** Blender's categories are a production tool's, so they bring the factory's frame with them.
The playground version must let the stack be **seen and re-ordered**. Which order a learner applies modifiers in is
something they can grasp by hand.

**The dark spot.** Soft bodies sit in two columns at once. Logic's AND (floor 7, Matter AND) arrives long before the
Boolean modifier. Keep these crossings visible; do not tidy them away.

## Step 1, built: Edit mode's face, and the triangle that holds (2026-11-06)

The kit already had the vertex (the six-socket ball) and the edge (the rod). Step 1 adds the face, and the first proof
the playground can make by hand: three free rods make a rigid triangle, which none of them is alone. Organisation from
outside becomes a capacity of the thing itself.

**Palle's choice:** a new bench stage, from the Triangle floor (5). He chose it over "faces only, joints rigid" and over
"an editor separate from the kit". `workbench.json`'s `triangle` stage carries two keys, and a stage without them
changes nothing.

- **`diagonals: true`.** Each ball gets twelve face-diagonal sockets beside its six axis ones. The hand's new item
  `brace` is a rod √2 units long (1.24 m mouth to mouth on the metre grid). A brace goes only into diagonal sockets,
  and a rod only into axis ones.
- **`rigidity: bars`.** What the scaffold holds is also read as a framework (`kit_rigidity.gd`): each ball a point,
  each rod a bar that keeps a distance but no angle, and each floor ball an anchor. The rigidity matrix's null space
  gives the **free motions**. Maxwell's count: 3 × free points − independent bars.
- **What the player sees** (`playground_faces.gd`):
  - Faces fill every triangle of rods and every flat square with no rod across it. They are pink while the piece can
    still move and ivory once it can't.
  - A flexible ball rocks gently along its free motion, and its rods and faces follow.
  - A label over each piece reads, for example, "4 points (2 on the floor) / 5 rods / 2 free motions".
- **The bodies never move for the lesson.** The scaffold still holds every ball on its grid point, so building is never
  undone. The motion is drawn, not performed.

**Measured** (Godot `commons/testing/probe_kit_triangle.tscn` 7/7; web twin `ada_encyclopedia/tools/test-kit-graph.ts`
19/19; the existing kit probe still 9/9):

| Structure | Free motions |
|---|---|
| A square standing on two floor balls | 3 (the shear, and each top ball sideways) |
| The same square with a brace across it | 2: it tips about its floor edge |
| The square with a brace from each top ball to a floor ball behind | 0 |
| A point on one rod / two rods / three rods | 2 / 1 / 0 |
| A ball without the stage | no faces node; six sockets |

**What 3D teaches that a flat drawing hides.** A braced square is rigid only in its own plane. Standing up, it still
falls over sideways. A wall needs buttresses, and a point in space needs three rods. That leads straight to floor 6,
Polyhedra, and the tetrahedron.

## Three playground grids, one record (2026-11-06, asked on the forum: 261106-godli)

Three playground grids exist today. They share no record, no rules and no look:

| | Inventory kit (the hand, in the Void) | Web editor `/catalyst-inventory` | Playground workstation (floor 20 / 210, `/playground-workbench`) |
|---|---|---|---|
| Record | balls and rods at world metres, 1 m grid | the kit's rules in TypeScript (`kit-graph.ts`) | integer addresses × a step: 0.2 m hand model, 2 m world, quarter-scale glass copy |
| Pieces | 6/18-socket ball, rod, brace, faces | ball, rod | point, 1-8 m rods, triangle halves, quads, wedges, panels |

The proposal:
- **One record:** integer addresses × a step, the workstation's form.
- **One rule set per language,** twin-tested.
- **The look chosen by state:** detailed while held or edited, *built* once settled, points or lines far away.

Palle decides the record. The workstation side has been asked.

### The built-look pilot (kit only, measured)

`commons/artifacts/playground_kit/kit_structure.gd`. A kit ball with `fold` on that the support graph holds on its
point, and every rod whose ends are all in such balls, fold into one scene node: one MultiMesh of low spheres and one of
thin tubes. Their own meshes hide, a built rod freezes and stops its per-frame script, and the bodies stay. The hand, the
support graph, the sockets and the Triangle stage's counts therefore work as before. A flexible ball keeps its detailed
look, so the wobble still shows. Picked up, a piece unfolds; set down, it folds back. **Off by default:** the hand passes
a stage's `fold` key, and no stage sets it yet.

`commons/testing/probe_kit_built.tscn` 5/5, a 10 × 10 × 4 field (400 balls, 1,020 rods) on the mobile renderer:

| | Draw calls | Triangles | Frame (desktop, vsync off) | Physics per tick |
|---|---|---|---|---|
| detailed | 4,842 | 1,172,708 | 6.35 ms | 2.85 ms |
| **built** | **5** | **56,726** | **0.83 ms** | 1.49 ms |

The draw calls and triangles are the gate: the hand's budget is 120 draws and 60k triangles a hall. Frame and physics
times are desktop numbers, reported but not gated, and they vary between runs (physics read 3.2 / 0.93 ms on the run
before). The rods were already asleep before folding (0 active bodies both times), so the physics saving is the scripts
that stopped, not the solver. The built look drops the steel sockets: up close the detailed piece shows them, and from
a distance the built one doesn't need them.

## Next steps (not built)

0. **Turn the built look on** for the bench stages (`"fold": true` in `workbench.json`), after a try in the game.

1. **The load test.** The verb that lets the scaffold go: flexible balls become bodies on hinged joints and fall the way
   their free motion says. It could be the pin tool's release, applied to a whole piece.
2. **The web page.** `/catalyst-inventory` should pass the stage's `diagonals` / `rigidity` to `placeBall`, offer the
   brace, and draw `kit.pieces` (faces, the wobble, the count). The rules are already in `kit-graph.ts`.
3. **The prism's four faces as Blender's tabs:** Object / Modifiers / Material / Physics. This changes the hand
   interface; ask Palle first.
4. **The first modifier add-on: Array** (array_tutorial, spine 4), as an entry in the stack, not a new tool.
5. **The Unit's robots on the same record.** A factory regime and a playground regime, measured by what newly
   becomes reachable or buildable (ΔW).
