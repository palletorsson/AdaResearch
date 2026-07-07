# Sieve pass — catalyst arsenal mapping

_Recorded 2026-05-13T09:45:00_

**Target:** the mapping between *what the curriculum teaches* and *what the bracelet can fire*. Companion to the math-density sieve. The question driving this pass is *does the catalyst's mode-arsenal hold at the right resolution to express what the curriculum claims has been taught?*

**Background:** Palle's framing from yesterday — "many main artifacts become part of the catalyst arsenal: the point becomes the orb, the line a wand, the triangle a spell, the cube the first agent." That sentence is a load-bearing design rule: *what the player learns becomes what the bracelet can fire*. This pass tests whether the data encodes that rule at the right resolution.

---

## 1. The claim

The bracelet's mode-arsenal is a *distillation of the spine*, not an arbitrary inventory. Stated as a rule:

> **What the player learns becomes what the bracelet can fire.**

Three consequences if the rule is load-bearing:

1. Every spine sequence should produce at least one catalyst affordance.
2. The total arsenal at the end of sequence N should be the union of affordances harvested through sequences 1…N.
3. The arsenal's resolution should match the curriculum's resolution — *not coarser*. If a sequence teaches four primitive atoms (as `primitives` does), the arsenal at end of seq 1 should contain four affordances, not one.

## 2. The trace

### Current data (top level)

`soft_stages.json` declares one catalyst mode per sequence:

| seq | catalyst_mode | activation verb (from prior sieve) |
|---|---|---|
| 1 primitives | `primitives` | bounce-and-tint |
| 2 transformation | `transformation` | shrink |
| 3 array_tutorial | *(empty)* | — |
| 4 color | `chromatic` | paint |
| 5 forces | `forces` | gather |
| 6 wavefunctions | `waveform` | oscillate |
| 7 randomness | `chaos` | arc |
| 8 noise | — | — |
| 9 cellularautomata | `cellular` | evolve |
| 10 fractals | `fractal` | split |
| 11 lsystems | `branching` | grow |
| 12 proceduralgeneration | — | — |
| 13 softbodies | — | — |
| 14 swarmintelligence | `swarm` | flock |

Ten declared modes mapped to ten of the 19 spine sequences. Nine sequences inherit (or pass through) without a declared mode.

### The design hypothesis (Palle, yesterday)

Within `primitives` alone, **four sub-affordances**:

- point → **orb** (projectile primitive — "fire one shot")
- line → **wand** / orb-stick (drawing primitive — "draw a line in space")
- triangle → **spell** (area-effect — "triangles-in-series at target")
- cube → **first agent** (cube-foe — "produce a small agent that does X")

If this is right at seq 1, the same finer-grained unpacking applies everywhere. The published "10 modes" are **categories** of affordance; each category contains *atoms* corresponding to *what the sequence actually taught at artifact level*.

## 3. Per-sequence reading — what affordances does each F_order sequence imply?

### seq 1 · primitives — four atoms

The 67 artifacts cluster cleanly by primitive type:

| Atom | Representative artifacts | Implied affordance |
|---|---|---|
| **point** | `origin`, `static_point`, `interactive_point_origin`, `dark_sphere`, `sphere`, `draw_dot`, `grab_sphere_point_snap`, `frame_counter_display` | **orb** — fire one projectile primitive (current `primitives` mode) |
| **line** | `line`, `line_builder_3d`, `line_demo`, `lightrod`, `laser_measure`, `scale_lines`, `grid_lines`, `perspective_lines`, `parallel_line_puzzle`, `plus`, `quad`, `plus_line_puzzle`, `quad_line_puzzle`, `triangle_line_puzzle` | **wand / orb-stick** — draw a line in space; trace a path; measure a distance |
| **triangle** | `triangle`, `righttriangle`, `interactivetriangle`, `triangleprofiles`, `pythagorean_triangle_angles`, `draw_triangle_faces`, `grab_trihedron`, `snap_tetrahedron_puzzle` | **spell** — project a triangle (or chain of triangles) at a target; area effect through closure |
| **cube / polyhedron** | `cube_scene`, `animatedcubebuilder`, `polyhedron_nets_cube`, `platonic_grabbables`, `pyramid`, `pyramid_edit`, `prism_block`, `lshape`, `bigframe`, `truncatedtetrahedron`, `grab_octahedron`, `snap_octahedron_puzzle`, `snap_pyramid_puzzle` | **agent** — produce a small self-acting body (a cube-foe, a wedge-walker, a polyhedral helper) |

**Verdict**: the current `primitives` catalyst-mode flattens four affordances into one. The arsenal at end of seq 1 should have *orb + wand + spell + agent*, not just "primitives mode".

### seq 2 · transformation — three atoms

The 20 artifacts cluster by operation:

| Atom | Representative artifacts | Implied affordance |
|---|---|---|
| **translation** | `x_translation_cube`, `y_translation_cube`, `z_translation_cube`, `translation_cube_demo`, `pickup_gate`, `clipboard` | **shift** — catalyst pushes/pulls the target along an axis (call it `forces.push` later? — see cross-sequence note) |
| **rotation** | `rotate_grid_cubes`, `spin`, `carousel_cake`, `chair_assembly_puzzle` | **rotate** — catalyst spins the target around an axis |
| **scale** | `scale_me`, `boolean_tunnel`, `pick_up_cube` (size variants) | **shrink/grow** — catalyst changes the target's size (current `transformation` verb = shrink) |

**Verdict**: current `transformation` mode = shrink only. The two other affordances (shift, rotate) are implied by the curriculum but **collapsed into the single mode** in the data. Worse, the *shift* affordance overlaps with what `forces` does on contact (push/pull) — see cross-sequence note below.

### seq 3 · array_tutorial — empty mode, but implied atoms

The 19 artifacts cluster by addressing pattern:

| Atom | Representative artifacts | Implied affordance |
|---|---|---|
| **grid-spread** | `grid_2d_4x4`, `grid_3d_4x4x4`, `column_3_z`, `xyz_coordinates`, `tiling_demo`, `gridagent` | **stamp / spread** — catalyst stamps a grid-tile pattern (this is currently the `cellular` verb, declared 6 sequences later) |
| **pattern-tile** | `pattern_tile_4x4`, `pattern_tile_brick`, `pattern_tile_herringbone`, `pattern_tile_mirror`, `pattern_tile_puzzle` | **pattern** — catalyst emits a wallpaper-group pattern on impact |

**Verdict**: `array_tutorial` has *no declared catalyst_mode* — but the curriculum at this point has taught grid-addressing, which is exactly what `cellular` does at seq 9. The data is silent at the moment the affordance becomes available. Two possible fixes:
- Move the `cellular` mode unlock to seq 3 (it's been available since arrays were taught).
- Or: introduce a new mode `grid-stamp` at seq 3, and reserve `cellular` (seq 9) for the *evolving* grid variant (where the stamp keeps changing per rule 30 / game-of-life).

### seq 4 · color — chromatic plus two

The 23 artifacts cluster by color operation:

| Atom | Representative artifacts | Implied affordance |
|---|---|---|
| **paint** | `gridcolorizer`, `brick_wall_factory`, `ball_painting_demo`, `colorballs`, `pillarcolorcollection`, `mario_cube` | **paint** (current `chromatic` mode) — catalyst permanently recolors what it hits |
| **gradient / rainbow-arc** | `rainbow`, `rainbow_hallway`, `spectrum_forest`, `SpectrumVisualizer`, `grab_rainbow_stick`, `grab_stick_scanner`, `dark_side_prism` | **rainbow-arc** — catalyst's projection draws a color-graded trail; or it leaves a spectrum behind |
| **contextual / Albers** | `albers_wall_gallery`, `color_constellation_office`, `visual_color_mixing` | **context-tint** — catalyst changes how *neighboring* colors are perceived (one cell affects three neighbors) |

**Verdict**: current `chromatic` mode = paint only. Two other affordances are implied by curriculum but the bracelet doesn't carry them.

## 4. Cross-sequence transitions

Three places where the lookup-to-affordance mapping has tension across sequences:

**A. shift ⇄ forces.push (seq 2 ↔ seq 5)**

The translation atom at seq 2 implies a *shift* affordance. The current `forces` mode at seq 5 was originally "push back" (in the activation-verbs sieve we revised it to "gather" — pull *in*). If shift exists at seq 2 (taught operationally) AND push/pull is one of the verbs forces could carry, there's a clean distinction:

- **shift** (seq 2): translates a target along a *specified axis*. Reversible. Operator-driven.
- **gather** (seq 5): pulls toward the catalyst as a *field*. Continuous. Force-as-care.

These are different verbs at different layers. The current data collapses both into one mode (`transformation` does shrink only; `forces` does gather only) — translation as catalyst verb just isn't represented.

**B. grid-stamp ⇄ cellular (seq 3 ↔ seq 9)**

The grid-spread atom at seq 3 (`array_tutorial`) is *structurally identical* to the `cellular` mode at seq 9. If we honour the "what's taught becomes what's fired" rule, the *static* grid-stamp affordance is born at seq 3, and the *evolving* grid-stamp (CA rules) is what seq 9 adds.

**C. wand ⇄ branching/lsystems (seq 1 ↔ seq 11)**

The wand at seq 1 draws a line. At seq 11 (lsystems), the `branching` mode grows trees from lines. The wand → branching arc is the same curve as primitives → fractals — *what's taught at seq 1 as a primitive becomes a generative system later*. Worth naming: the bracelet's *grow* affordance at seq 11 is *the wand-line, but recursive*.

## 5. The three-question sieve at the arsenal level

### Does refining the resolution thicken the cognitive water?

Yes — three handles:

- **Pedagogical legibility.** A player who unlocks the *orb* at seq 1 and then unlocks the *wand* halfway through that same sequence sees the bracelet growing in proportion to what they've learned. The current "10 modes" feels granted in chunks; the finer atoms would feel earned per-artifact.
- **Diagnostic affordance for designers.** The artifact → affordance table is testable. If an artifact at primitives doesn't map cleanly to one of point/line/triangle/cube, that's evidence the artifact may not belong to primitives. The mapping becomes a tool for curriculum hygiene.
- **The bracelet starts to read as a sentence.** orb · wand · spell · agent · shift · rotate · shrink · grid-stamp · paint · rainbow-arc · context-tint · … → cellular · gather · oscillate · chaos · split · grow · flock. That sequence reads as a *vocabulary the player accumulates*, not a list of weapons.

### What does refining foreclose?

- **Inventory bloat.** Currently 10 modes; at full resolution that's ~25–30 affordances. The bracelet's UI (mode-gem-rotation) and the player's mental model both have to scale.
- **Decision overhead in gameplay.** With 4 affordances from primitives alone, the player at seq 5 may have 15+ verbs to choose from. The current 10-mode arsenal is already at the edge of what one rotation-hinge can show.
- **The categorical readings.** "Primitives mode" reads as a single thing the player owns. Splitting it into four affordances loses the *primitives-as-a-bag* feel. Some players will read that as fragmentation.

These are real. The mitigation is *progressive disclosure*: the bracelet shows the current top-level category; the active atom within it is selected by a secondary gesture (squeeze? a second gem-rotation? the held-matter shape itself tells you?). The 10 categories stay legible at the bracelet's surface; the atoms live one click deeper.

### What lives in the dark spot?

What the table can't reach:

- *Which affordance the player chooses, in the moment.* Strategy, taste, attunement to context — these stay felt, not encoded.
- *The chord effect across the arsenal.* Some affordances pair (paint + gather = held color-field). The combinatorics of the bracelet aren't visible in the table.
- *The affordance's body in the world.* What does the spell *look like* mid-flight? What's the sound? Those live in the held-matter and gesture-DNA captures, not in the affordance name.
- *The reverse direction — what the world's resistance to the affordance is.* What does a friend-foe-state-X creature do when struck by spell vs orb vs wand? Different things, presumably. The mapping doesn't yet encode this.

**Generative — fragile.** The dark spot stays habitat if the bracelet's surface stays at the 10-category resolution while the affordance system handles the atoms underneath. The fragility is at the seam: if every atom needs its own UI slot, the bracelet becomes a hotbar and the felt simplicity is gone.

## 6. Recommendations

### 6a. The end-of-F_order arsenal (target)

By the end of sequence 4, the bracelet should carry these affordances, in unlock order:

1. **orb** (seq 1, point) — single projectile, the current default
2. **wand** (seq 1, line) — line-drawing / measuring projection
3. **spell** (seq 1, triangle) — triangle / chain-of-triangles area effect
4. **agent** (seq 1, cube) — produce a self-acting cube/wedge body
5. **shift** (seq 2, translation) — translate target along axis
6. **rotate** (seq 2, rotation) — spin target around axis
7. **shrink** (seq 2, scale) — current `transformation` verb
8. **grid-stamp** (seq 3, arrays) — stamp a pattern tile or grid
9. **pattern** (seq 3, wallpaper) — emit a wallpaper-group pattern on impact
10. **paint** (seq 4, color) — current `chromatic` verb
11. **rainbow-arc** (seq 4, gradient) — color-graded trail
12. **context-tint** (seq 4, Albers) — change perception of neighbors

Twelve affordances by end of F_order. The bracelet doesn't have to *display* twelve gems — those map to the 4 categories `primitives / transformation / arrays / color`. The atoms live inside the category and are selected by a sub-gesture.

### 6b. Encode the affordance layer in soft_stages

Add a new field `capability.catalyst_affordances` per stage (alongside `catalyst_mode`):

```jsonc
"primitives": {
  "capability": {
    "catalyst_mode": "primitives",          // existing — the category
    "catalyst_affordances": ["orb", "wand", "spell", "agent"]  // NEW — the atoms
  }
}
```

The runtime can choose how to surface this (sub-modes inside the category, separate gem slots, etc.). The data carries the resolution the design implies.

### 6c. Resolve the three cross-sequence tensions

- **shift / gather**: name them differently. `shift` at seq 2 = operator-driven, axis-aligned, reversible. `gather` at seq 5 = field-driven, continuous. Both stay; they don't conflict.
- **grid-stamp / cellular**: static stamp at seq 3, evolving stamp at seq 9. Cellular keeps its current `evolve` verb but explicitly *inherits from* grid-stamp.
- **wand / branching**: wand at seq 1 is the primitive; branching at seq 11 is the recursive variant of the wand. Worth one bullet in seq 11's pedagogical text: *"the line you drew at primitives, but each line spawns lines."*

### 6d. Fill the empty modes

Sequences without a declared catalyst_mode (array_tutorial, noise, proceduralgeneration, softbodies, machinelearning, foundationscrisis, qfeplaboratory, postfoundationscrisis, graphtheory) — each should be examined:

- Does this sequence have an affordance that should join the bracelet? (Yes: array_tutorial → grid-stamp; noise → field-noise modulation; softbodies → deform; ML → predict; graph theory → trace-network.)
- Or is this a sequence where the bracelet is *contemplative* (post-foundations-crisis: the bracelet learns to *not fire*)?

The empties aren't all gaps; some may be by design. But each should be sieved.

## 7. Load-bearing rules out of this pass

1. **Atoms below categories.** The bracelet has 10 (or so) categories at its surface; the data has 25-30 affordances underneath. Resolution lives at the data layer; legibility lives at the UI layer.

2. **Every artifact in a sequence maps to one affordance or is non-catalyst.** "Non-catalyst" is an allowed answer — `code_display`, `clipboard`, `script_runner` exist to teach without becoming projection. Mark them explicitly so the catalyst layer doesn't claim them.

3. **End-of-F_order arsenal = 12 affordances.** Stated as a load-bearing target so any future curriculum rewrites can be checked against it.

4. **Cross-sequence tension is named, not collapsed.** `shift` and `gather` are different verbs at different layers; `grid-stamp` and `cellular.evolve` likewise. The mapping preserves the distinctions the curriculum already makes implicit.

## 8. Pass result

The arsenal passes the sieve **under significant expansion**. The current data encodes the bracelet at one-tenth the resolution the curriculum implies. The fix is structural (a new `catalyst_affordances` field per stage) and content-light (each affordance already corresponds to artifacts that exist). The bracelet's UI doesn't have to change at the surface — the new resolution lives below it.

The arsenal-mapping pass also depends on the math-density sieve's recommendations: *naming the math atoms a sequence teaches makes the affordance derivation cleaner*. If `array_tutorial` opens with "binary indexing + floor division + modular", the grid-stamp affordance reads as "the catalyst fires what you just learned."

Both sieves converge on the same conclusion at different scales:

> **Make the curriculum's claim visible at the resolution the design implies.** Math atoms named in sequences; catalyst affordances named in the arsenal. The bracelet *is* the math the player has learned, but only if the math is visibly enough taught and visibly enough carried.

---

*Companion sieve:* `2026-05-13T09-15-00_math-density.md` (first; produces the named-atom vocabulary this pass depends on).
*Earlier sieve passes:* `2026-05-11T10-54-27_orb-gesture-detector.md`, `2026-05-11T19-25-26_activation-verbs.md`.
*Source data:* `commons/maps/sequences/{primitives,transformation,array_tutorial,color}.json`, `commons/maps/soft_stages.json`.
