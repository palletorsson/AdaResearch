# Promoting an artifact — what eleven batches learned

Read this before designing an axis. Everything here was paid for by a batch that
got it wrong first. It exists so an agent does not rediscover it, and so a brief
does not have to re-type it.

## The rule that outranks everything

**The default value of every axis must reproduce the artifact's exact
pre-promotion behaviour.** These artifacts are placed in live maps. A promotion
that changes what those maps look like is a regression, not research. Say plainly
in your report whether the default preserves, and how you checked.

Prefer **short-circuit over recomputation**. `fontana_puncture` returns the raw
shipped `sphere_radius` at its default rather than recomputing `0.68 * cube_size`
— bit-identical today, but a map overriding `cube_size` alone wants a 0.34 sphere
in a *bigger* cube, and the ratio path would silently rescale its void.

## The evidence is ONE STILL PNG per value

A rate, a duration, a decay, a sound, an animation and a player interaction are
all invisible to it. If the only honest axis is time-domain, **say so and
decline** rather than shipping a finished-looking experiment that answers
nothing. `info_board` was swept across five duration exports and produced six
identical tiles — every stage green, the verdict a fact about a typo.

Declines that were right: `SphericalHarmonics` refused an orbit-ratio axis (a
spherical Lissajous is traced over time). `SoundscapeRadioRack` refused
`station_width` (real, audible, invisible). `prebaked_loader` refused everything
— it is 78 lines of `load(scene_path)`, a pointer with 61 placements.

## Check the family before inventing a word

Grep the registry for siblings that already name the same question and **reuse
the word and its value list character for character** if it genuinely fits. A
shared vocabulary is only honest if the siblings measure alike.

Refusing a handed-down word is also correct, and three agents have done it well:

- `example_1_3` refused `evidence`: *"1.3 is not a motion demo asking what may be
  shown of an invisible law; it is an algebra bench asking which picture of a−b
  is the true one."*
- `folding_past` refused `fold`: there is no hinge and nothing closes into a
  solid, so two of its four values would name a mechanism this object lacks.
  **Taking a word without its answers is the dishonest half of a shared
  vocabulary.**
- `sierpinski_pyramid` refused `removal`: Cantor's removed middles are a disjoint
  complement you can ghost back in, but here the children's volumes interpenetrate
  — there is no complement to draw.
- `bouncing_ball` took `regime` and refused its value list: under/critical/over
  are the named cases of a second-order ODE and there is no critically-bouncing.

## Six ways a sweep comes back null, and only one is about the artifact

| symptom | cause | fix |
|---|---|---|
| all frames identical, ~0.7% | declared values are not the code's values | `check_dna_declarations.py` |
| NO RENDER, subject 0.00% | `_ready()` is gated and builds nothing standalone | registry `dna.fixture` |
| two values identical to the byte | geometry exists but is occluded or off-camera | change the fixture |
| subject under ~6% of frame | AABB inflated by one big or far-flung mesh | `dna.framing`, or a `layers = 0` anchor |
| confident bite on a generative artifact | unseeded `randf` — five variants are five objects | seed export + `dna.fixture` |
| axis real in world space, invisible in frame | fit-by-diagonal on a thin subject | `dna.framing` below 1.0 |

**The capture AABB counts `MeshInstance3D` and `MultiMeshInstance3D` only.** If
your axis hides the only `MeshInstance3D` bodies, the camera will fit whatever is
left and clip the rest — `dna_specimen`'s `escaped` hides the jar and would have
framed a 0.15 m base plate against a 0.60 m helix. Add a `layers = 0` anchor.

**The camera is fixed across a sweep** (union of every variant's box). Do not
assume a value that adds geometry gets photographed from further away; it does
not, any more.

## Traps that cost a batch each

- **`apply_grid_config` rebuilding unguarded.** Rebuild only when a value actually
  CHANGED and only after `_ready` has built once. `force_pad` tore down every
  child and `call_deferred("_ready")` on *any* call, including ones naming nothing
  it owns.
- **Export hints go on ONE line.** A parenthesised continuation inside
  `@export_enum(...)` is valid GDScript the gate's line parser cannot see; it
  reports NO EXPORT and the sweep refuses.
- **A typed bool rejects a fixture string `"true"`** before `_ready`. Leave
  fixture flags untyped or use String enums.
- **Godot visibility is hierarchical** — `visible = false` hides descendants. To
  hide one mesh and keep its children use `layers = 0`.
- **A `CSGCombiner3D` nested in another combiner is a SHAPE, not a container.** A
  ghost hung there gets unioned back into the solid it comments on.
- **Check the `.tscn` root carries the script.** Logic on a child makes the axis
  declared but unreachable from a map token (`line_interface`).
- **Check the `.tscn` path casing matches what git tracks.** Invisible on Windows,
  fatal on a case-sensitive export, and it strands the declaration.
- **One scene, many names is this corpus's most common hidden family.** Identical
  export counts across sibling tokens are the tell. The capture stamps
  `artifact_lookup_name` before `_ready` to tell them apart.
- **Registries are token-keyed dicts.** Edit the one entry surgically, never
  re-dump. A token may be *named* in three files while only one holds a real
  entry — check which before writing.

## Things worth doing that nobody asks for

- **Measure the ladder instead of assuming it.** `room_grammar` re-implemented its
  BSP in Python and ran it 400× per rung to prove depth 1–5 gives distinguishable
  plans and does not saturate.
- **Ask the geometry instead of being told.** `transform_composition` composes both
  orders and tests `is_equal_approx` rather than hard-coding which pairs commute.
- **Preload a sibling's table rather than copying it.** `slot_machine` reads its
  rank ladder out of `prng_crank_machine.gd`, so nine artifacts sharing
  `disclosure` cannot drift into nine vocabularies.
- **Say what you did NOT do.** A recorded decline with a reason stops the next
  agent reopening it. `gaussian_random` has been declined twice, on the record.

## An artifact that does not build is a finding, not an axis

Before declaring, confirm the thing renders. Three cases so far:

- `tile_meander_floor` — a 149-line stub, no `_ready`, seven maps, nothing drawn.
- `pattern_artifact` — ten bare tokens, `config_path` empty, nothing drawn.
- `dna_specimen` — an `@export_enum` and a doc block specifying four rungs, and no
  function implementing any of them. **The declaration gate cannot see this**: the
  export is real, the values are real, nothing implements them.

Report it. Do not paper over it with a genome.

## Verify before you report

`python tools/check_dna_declarations.py` must report your token `ok` and 0 broken.
Do not run Godot — captures are serialised centrally and a second instance dies
silently on the `user://` lock.
