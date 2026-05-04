# Five-artifact abstraction experiment — findings

**Date:** 2026-04-30
**Goal:** Write 5 Ada artifacts as engine-agnostic JSON specs and see what
the DSL would have to support.
**Conclusion:** It's tractable. About 25 primitives cover the five.

The five artifacts:

| id                       | QFEP        | dominant pattern                            |
|--------------------------|-------------|---------------------------------------------|
| `xyz_slider_plate`       | S           | input → state → 3D point                    |
| `vector_addition_walk`   | S           | grab handles → vectors → arrows + math      |
| `bulging_tunnel`         | λ_edge      | parametric CSG — order ↔ chaos              |
| `pompeii_mosaic_floor`   | F_order     | procedural mesh from grid rules             |
| `cellular_automata_1d`   | F_order     | algorithm tick → instanced cube grid        |

Specs are in `doc/abstraction_experiment/specs/`.

---

## What the DSL has to support

After writing all five specs, the primitives that came up:

### Geometry primitives (15)

The shape vocabulary the DSL has to know:

- **CSG ops**: `csg_combiner`, `csg_cylinder`, `csg_sphere`, `csg_box`,
  `csg_torus` with operations `base | union | subtraction | intersection`
  *(used by bulging_tunnel)*
- **Standard primitives**: `sphere`, `cylinder`, `box`, `plane`, `axis_triad`
  *(used by xyz_slider_plate, vector_addition_walk)*
- **Procedural mesh**: `procedural_mesh` (vertex/index arrays, multiple
  surfaces with materials), `immediate_mesh_lines`
  *(used by pompeii_mosaic_floor, vector_addition_walk)*
- **Instances**: `instances_per_cell` (instantiate a referenced primitive
  at every cell of a logical grid)
  *(used by cellular_automata_1d)*
- **UI**: `label_3d` (billboard text), `panel` (rams template, sliders/buttons),
  `text_display`
  *(used by xyz_slider_plate, vector_addition_walk)*
- **Composite**: `arrow` (cone + cylinder, parameterized by from/to/thickness),
  `grab_sphere` (sphere with pose binding)
  *(used by vector_addition_walk)*

### Materials (1 + variants)

One PBR material with overrides covers everything observed:

```
{ kind: "pbr_standard",
  albedo, metallic, roughness, emission, emission_energy,
  transparent, alpha, unshaded, vertex_color, cast_shadow }
```

### Behavior primitives (5)

- **on_ready**: build geometry once
- **on_parameter_change**: rebuild from current parameters
- **on_tick**: integrate over delta time, call sub-handlers on intervals
- **on_input_change**: react to interaction state changes
- **algorithm**: typed step function (e.g. `elementary_ca_1d`) with a `step`
  and a `init_state` — the algorithm itself is data, not code

### Interaction primitives (4)

- **slider_drag** (1D, scalar binding)
- **grab_3d** (3-axis pose binding with constraints)
- **button_press** (named action)
- **(none)** — passive artifact

### Parameter system

Every artifact uses a small set of parameter types:

`float | int | bool | vec2 | vec3 | color | string | enum | array<T>`

Parameters carry: `default`, `range`, `unit`, `doc`, optional
`constraint` (formula). Imports/refs handle external code (palettes,
border motifs) — explicitly noted but kept opaque to the DSL.

### Expression language

Specs need a tiny expression sublanguage for parameter formulas and
bindings. The syntax used in the five specs:

```
$param_name                  reference a parameter
length($v)                   builtins (length, sin, lerp, format, sum, min, max, abs, round)
$a + $b, $a / $b            arithmetic
$x ? a : b                   ternary
range($a, $b)                ranges and rng.range
"format('(%.2f, %.2f)', x)"  printf-style
"clamp($v inside box, ..)"   keyword-driven constraints
```

Roughly a calculator with named refs and a few special functions.

---

## What surprised us

### 1. CSG and procedural mesh are different beasts

Bulging tunnel is CSG ops composed at runtime — Godot can do this natively,
Three.js can't (or rather, only via `three-csg`). Pompeii floor is a
vertex-array mesh built procedurally — universally supported. CSG should
probably compile down to procedural mesh on engines that don't support it
runtime, which means **the DSL needs an offline "CSG bake"** pass for
those targets.

### 2. The interaction layer is small

Only **3 interaction kinds** across all 5 artifacts — slider, grab, button.
Most of Ada's other artifacts use the same set (cataloged in the
encyclopedia: slider_horizontal, push_button, grab_sphere are the holy
trinity). A clean abstraction here unlocks 80%+ of the corpus.

### 3. The algorithm is genuinely separable

`cellular_automata_1d.json` has an `algorithm` block:

```json
"algorithm": {
  "kind": "elementary_ca_1d",
  "step": "for i in 0..grid_width: ...",
  "neighbor_wrap": "circular",
  "init_state": "single 1 at grid_width/2"
}
```

This is the *truth* of the artifact. The geometry block is just how it's
visualized (cubes on walls). The same algorithm block could feed:
- Godot's instances_per_cell renderer (current)
- A 2D web canvas drawing pixels (for the encyclopedia)
- A book figure (printed snapshot of one generation)
- Sonification (cell state → MIDI note)

The algorithm is a separate, named, parameterized thing. The visual is one
attached renderer. That's the abstraction working as intended.

### 4. Most parameters are free-floating numbers

Looking across the 50+ parameters in five specs, very few have constraints
on each other. The DSL can treat them as a flat keyed bag with types and
ranges. Constraint expressions like `length <= max_vector_length` are the
exception, not the rule. This makes the parameter UI auto-generatable
(which the encyclopedia and editor already partially do).

### 5. The "spec" is shorter than the GDScript

Lines of code:

| artifact                | gd lines | spec lines | ratio |
|-------------------------|----------|------------|-------|
| bulging_tunnel          | 214      | 65         | 3.3×  |
| xyz_slider_plate        | 245      | 95         | 2.6×  |
| cellular_automata_1d    | 206      | 70         | 2.9×  |
| vector_addition_walk    | 436      | 92         | 4.7×  |
| pompeii_mosaic_floor    | 271      | 85         | 3.2×  |

The spec says **what** the artifact is. The GDScript says **what** plus
**how Godot specifically does each thing**. Compression ratio of 3-5×
is consistent with the gain. Most of the lost lines are setup
boilerplate that the renderer would generate.

---

## What the DSL doesn't yet handle

Honest gaps that didn't surface in these 5 but will in others:

- **Animation curves** — easing, bezier, spring physics. None of the
  five used animation curves explicitly; `cellular_automata_1d` has a
  pulse but it's just `1 + sin(t*5) * 0.15` inline.
- **Shader-driven artifacts** — Ada has 151 shaders. The DSL would need
  a shader-spec subsystem or a per-engine shader compile pass. Out of
  scope for now; mark them as "spec-incomplete" in the registry.
- **Sound** — none of the five make sound. Other artifacts do.
- **Physics** — none of the five use rigid bodies or collisions
  (other than CSG `use_collision = true` flags). Physics-driven
  artifacts (`spring_demo`, `flocking_demo`) need primitives we
  haven't written.
- **Sub-artifact references** — `vector_addition_walk` instantiates
  several `arrow` composites. The DSL handles this via primitive composition,
  but cross-artifact references (using one spec inside another) need a
  formal `import` semantics beyond the loose "preload these" we wrote.
- **Save state / persistence** — for tutorial sequences that need to
  remember progress. Not in any of these five.

---

## Recommendation

**The experiment succeeds.** Five very different artifacts compressed to
specs of comparable size, with overlapping primitive sets. The DSL surface
needed is small (≈25 primitives, 5 behaviors, 3 interactions, one
material, a 12-builtin expression sublanguage).

**Next steps if we commit to this:**

1. **Pick 5 more** that span the gaps above:
   - One shader-heavy (`anicka_yi_lab` or any substrate with custom shaders)
   - One physics-heavy (`spring_demo` or `flocking_demo`)
   - One sound-driven (any audio-rack module)
   - One animated (`marching_cubes_morph`, anything with timeline)
   - One composing other artifacts (`chamber_color` references many)

2. **Stop trying to write specs by hand.** Write a tool that scrapes
   `@export` annotations + `_ready()` patterns from a `.gd` file and
   emits a draft spec. Most of what we just hand-wrote can be derived.

3. **Decide on the expression language.** The mini-expressions in these
   five specs (`$param`, builtins, ternary) need a real grammar and an
   evaluator. Probably 200 lines of code; pick something off the shelf
   (jsonlogic, expr.js, or write a tiny one).

4. **Write a renderer**. Not Unity — start with Three.js, since the
   encyclopedia already uses it. Confirm round-trip: spec → Three.js
   render → side-by-side with Godot capture. If it matches for these
   five, the abstraction holds.

5. **Decide on `algorithm` blocks**. The cellular_automata_1d spec
   factored its algorithm out cleanly. Other artifacts (mosaic floor,
   bulging tunnel) have algorithms blended into geometry. Two paths:
   keep them separate (cleaner, more rewritable), or accept that some
   artifacts have geometry that *is* the algorithm. Either is defensible;
   we should pick one before writing the next 50.

The shape of the abstraction is becoming visible. It's smaller than I
expected. It might actually be doable.
