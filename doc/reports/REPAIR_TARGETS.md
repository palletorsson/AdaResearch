# Repair targets — faults found and deliberately not fixed

Measured across waves 20–23. Every one of these is a defect in a **shipped** artifact with live
map placements, which is why none was repaired in place: in this programme defaults are sacred,
and changing one silently rewrites every room the artifact already stands in.

So they have been accumulating in commit messages, which is not a place work gets done.

**A repair MUTATION is the way out.** Build a child artifact with the fault corrected, leave the
parent untouched, and score the pair with `tools/score_mutation.py`. The paired measurement says
exactly what the fault costs — same standpoint, same framing, same metric, so the rig cancels and
the difference is the defect. Nothing shipped changes. The repair becomes evidence rather than a
risk, and Palle can decide afterwards whether to promote it into the parent.

Ordered by how much the fault costs the viewer.

---

## 1. `schrodinger_box` — the default hides the subject

`commons/artifacts/schrodinger_box/schrodinger_box.gd`

- `_create_box()` (`:180-191`) builds an **opaque** BoxMesh at `box_size` 0.4 × 0.3 × 0.3,
  albedo `Color(0.3, 0.25, 0.2)`, no transparency.
- `_create_superposition_effect()` (`:238-253`) builds a 0.12 m glow sphere at `Vector3(0,0,0)`
  — the same origin. Interior half-extents 0.20 / 0.15 / 0.15 against 0.12, so the sphere is
  **entirely enclosed**.
- `core` is the shipped default on both members of the family.

So the artifact's whole subject is invisible in the value every placement uses, and `_process()`
(`:299-303`) animates alpha and emission on a mesh no camera can reach.

**Repair:** make the box transparent, or open, or cut away, at `core`.
**Paired question it answers:** what does the default cost, in measured drift, at every rung?

## 2. `schrodinger_box` — the Born rule is a coin flip

Same file. `@identity` at `:10` declares the essence as
`|ψ⟩ = α|alive⟩ + β|dead⟩ → observation collapses to |alive⟩ or |dead⟩ with P = |α|²`.
`observe()` at `:314` is `var is_alive = randf() > 0.5`. **α is never read.**

The artifact states the rule it exists to teach and implements the one thing that rule rules out.

**Repair:** collapse with `randf() < alpha*alpha`.
**Note:** this one is not photographable at a single instant — it is a distribution. A repair
mutation here must draw the distribution (a tally, a stack of outcomes), not the collapse.

## 3. `SierpinskiPyramid` — six children under a comment saying five

`algorithms/cellularautomata/sierpinski_pyramid/SierpinskiPyramid.gd`

`_recursive_build` (`:99`) has `# 5 sub-pyramids` at `:106`, then makes **six** calls:

| line | call | note |
|---|---|---|
| `:109` | top at `+half_size` | orphaned scaffolding, left behind while the author worked out offsets in ~60 lines of comments |
| `:174` | top at `+offset` | the real top |
| `:177-180` | four base corners | |

Consequences: 6⁴ = 1296 leaves at the shipped depth rather than 625; two tops at different
heights; Hausdorff dimension **log6/log2 = 2.585**, not Sierpiński's 2.322. It is not a
Sierpiński pyramid.

**The proof has been in the repo since 2026-04-29**: the registry records
`measurements.aabb_size = [8.5, 12.25, 8.5]` with `aabb_center = [0.0, 1.88, 0.0]`. A correct
pyramid on an 8.5 base is neither 12.25 tall nor offset upward in Y.

Second, separate fault: `:96` uses `size * pow(2, depth - 1)`, putting leaf pitch at `size/4`, so
edge-length-`size` cubes overlap **4:1**. A comment at `:198` names the fix
(`size * pow(2, depth)`) and it was never applied.

**Repair:** delete the `:109` call; apply the `:198` pitch fix.
**Paired question:** does the corrected figure read as more or less like a Sierpiński pyramid to
the sweep than the doubled one? (Live task chip: `task_869d655e`.)

## 4. `grab_rod` — the fulcrum is welded to the lever

`commons/primitives/cubes/grab_rod.gd` (attached to both `grab_long_stick` and
`grab_rainbow_stick`, which are one script under two registry tokens)

Everything the `office` axis fits is added as a child of the rod (`:142  add_child(dress)`), and
the rod is an `XRToolsPickable` RigidBody3D. So at `lever` the fulcrum (`:186`, shim `:187`) is
parented to the body you pick up — hanging 0.112 m under a shaft you can hold anywhere, touching
nothing, travelling with the thing it is meant to pivot. A fulcrum is by definition the part that
does **not** move with the lever.

The docstring concedes the shape of it at `:27-28`: office "shows entirely in what is fitted at
its ends."

**Repair:** parent the fulcrum to the world, not the rod.
**Related, already filed:** both scenes fit the camera by diagonal, putting the subject at 2.26%
of frame while `lever` vs `baton` moves 29.4% inside it, and neither entry carries `dna.framing`
(task chip `task_e104f6bc`).

## 5. `microstate_counter` — the entropy table is not a function of its own geometry

`commons/artifacts/microstate_counter/microstate_counter.gd`

`CELLS_BASE` (`:47-52`) = `{uniform 24.0, corner 3.35, layered 6.8, spilled 24.0}` over 40
particles, so the plate prints 10⁵⁵ / 10²¹ / 10³³ / 10⁵⁵. The chamber it *draws* has a 0.5208 m
interior (`:439` × `:77`), a 0.20 m octant (`:63`) and two 0.12 × 0.57 × 0.57 slabs (`:64-66`).
Taking cells ∝ volume:

| value | plate prints | geometry gives | error |
|---|---|---|---|
| `corner` | 10²¹ | 10⁵·³ | **15.7 decades too generous** |
| `layered` | 10³³ | 10⁴⁴·⁹ | **11.6 decades too stingy** |

Wrong in **opposite directions**, in the artifact named for the count. The table gives itself
away in its own comment, which states entries by their output (`24.0 -> 10^55`) rather than
deriving them. Side-effect: `SLAB_SPAN = 0.57` exceeds the 0.5208 m interior, so the sorted slabs
pass through the chamber walls.

**Repair:** derive `CELLS_BASE` from the drawn volumes.

## 6. `harmonic_distance_table` — the default reads a different array

`commons/artifacts/harmonic_distance_table/harmonic_distance_table.gd`

`_shared_for()` short-circuits at `:326`:

```gdscript
func _shared_for(interval_class: int) -> int:
    if consonance_theory == "western":
        return int(SHARED_OVERTONES.get(interval_class, 0))   # this file's own dict
    var table: Array = _consonance_table(consonance_theory)   # the shared tables
```

`_consonance_table()` **has** a correct western path — its `_:` fallback returns the sibling's
`CONSONANCE`, preloaded at `:50` — and that branch is unreachable for the one value the family
ships as its default. The two arrays are not close: pushed through the file's own inversion rule
the perfect fourth scores **14** in one and **3** in the other, and the `shared < 2` gate at
`:464-465` would draw all 66 pairs instead of 36.

**Repair:** delete the short-circuit and let `western` fall through to the shared table.

## 7. `queer_morphology_specimen` — a shader that has never compiled

`queer_morphology_specimen.gd:176-189` — the fluid shader's `noise3d` has two compile errors
(`vec3()` given four components, `fmod()` given one argument). The file's own comment states the
consequence: three of the four `becoming` values are defined against the fluid volume that noise
drives, so all three have only ever rendered through the error material.

**Repair:** fix the two signatures.
**Paired question:** this is the cleanest rescue case in the list — three rungs that are
currently flat should start moving, and `score_mutation.py`'s `rescue` reading is built for it.

## 8. `entropy_jar` — unseeded, and its one sweep has no control

`algorithms/randomness/entropy_jar/entropy_jar.gd:82` ships `particle_seed: int = 0`, and at 0
the code falls through to the **global unseeded** `randf()` (`:110-111`, `:116-117`). Its registry
`dna` block holds `axes` and nothing else — no `fixture`.

`doc/reports/sweep_entropy_jar_bite.json` exists and records 15 pairs at 1.70%–7.42% — but it
swept `jar_radius` and `jar_height`, two size exports, and never touched the declared
`found_state` axis. And because the jar re-randomises 80 bodies on every build, the file contains
**no same-parameter control pair**, so nothing in it separates signal from re-draw.

**Repair:** add `dna.fixture` pinning `particle_seed`, re-sweep on the declared axis.

## 9. `fire_extinguisher` — two exports dead at one value

Under `statute:joinery` the livery table sets `ink_amt = 1.0`, which makes `_ink()` —
`c.lerp(ink, 1.0)` at `:611-616` — a **constant function**. So `label_color` and `accent_color`
silently discard whatever a map passes and always return `Color(0.44, 0.46, 0.42)`.

Alongside it, a smaller asymmetry of the same shape: `support` is normalised and allow-listed on
every config read, with a comment about the space a human types after a colon, while `statute` is
matched **raw** in two places. Same file, same author, one axis defended and the other not.

---

## Not a repair, but standing

- **46 axes across 44 artifacts cannot be hung from a map at all** — numeric values whose key is
  outside `CONFIG_PARAM_NAMES`, so `#axis:value` is read as positional shorthand and sets the
  axis to `true` with the number as a rotation. `ca_bridge.rule` (30·90·110·250) is one.
- **7 sceneless registry tokens declare `dna.axes`**, all in `living.json` — axes nothing can
  ever photograph.
- **`neural_network_visualization` declares `@export_enum("analysis", "museum") var presentation`**
  — a two-value axis that five maps already configure and that `dna.axes` has never seen, so it
  is invisible to the sweep, the gate and the critic.
