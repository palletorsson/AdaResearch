# Biome AAA pass — scout briefing (salvaged)

The 2026-07-27 fan-out hit a session limit after the scout phase; 24 of 25
agents never ran. This is the one agent that completed — a map of the visual
levers, kept so the work is not repeated.

## BIOME VISUAL-QUALITY SCOUT — current state + levers

### Reach (measured, so you know what work is worth)
37 map_data.json files ship `layers.biome`. Only **1** sets `budget_instances`/`visibility_range`/`chunk_lod`/`living_ground`/`presence`; 4 set `stage_order`. So **defaults govern 36 of 37 maps** — every default is load-bearing.

Token census across shipped maps (`kingdom:algo:role`):
```
165 flora:scatter:field    106 flora:scatter:halo     40 fungus:ca:halo
 24 fungus:ca:seed          17 water:fog:halo         15 flora:lsystem:seed
 13 fauna:dna:seed          12 fungus:{softbody,mycelium,ca}:field/seed
  8 fungus:dna:seed          7 fungus:sdf:seed         7 flora:sdf:seed
  4 water:pool / mineral:vein / meta:glyph seeds
```
Two consequences almost everyone gets wrong:
1. **`field` cells render NOTHING at rest** (`GridBiomeComponent.gd:239` — only `seed|halo|edge` start active). The 165 `flora:scatter:field` cells are dormant until a `claim` reaction. So the *visible* biome is dominated by **halo cover (~230 cells × 10–50 batched instances)**, not by seeds. Halo/edge quality is the highest-leverage surface in the whole system.
2. Seeds are few (≈90 total across all maps). Expensive per-organism work there is affordable; work on halo cover must stay in the MultiMesh.

---

## 1. CANOPY — `tree_morphology.gd`, `flora_sdf_morphology.gd`

**Current state.** Biome L-system trees get `lod = clampi(intensity-2,0,3)` (`biome_paint_dispatcher.gd:554`) → most are lod 0–1. At lod ≤2 every leaf is the *same* `SphereMesh(radius 0.6, height 1.1, 6×4)` (`tree_morphology.gd:597-605`), instanced with a **uniform** basis (`:560 basis.scaled(Vector3.ONE * leaf_size)`). One MultiMesh, `use_colors` already on, per-leaf drift only ±0.04 (`:519-521, :567-572`).

**Zero-cost levers**
- `tree_morphology.gd:559-561` — replace the uniform scale with a **non-uniform, per-instance basis** (flatten Y, widen XZ, random tilt). Same instance count, same draw call, breaks the "bag of identical balls" read. This is the single best canopy win.
- `tree_morphology.gd:567-572` — the per-leaf tint drift is ±0.04 on a shader that does `base_color *= v_instance_color.rgb` (`critter_dna.gdshader:479`). Widen it, and **bias it by the leaf's height within the canopy** (darker low, lighter at the crown). Free fake-AO + free "light comes from above". Data is already in `placements[i]["position"].y`.
- `tree_morphology.gd:504-508` — leaf offsets are uniform inside a **cube** of ±`leaf_size`. Make the cloud ellipsoidal with an upward bias; costs one normalize.
- **BARK IS GREEN.** `biome_paint_dispatcher.gd:549` sets `dna.secondary_color` to a green, and `tree_morphology.gd:467` uses `dna.secondary_color.darkened()` as the branch material's `primary_color`. So biome L-system trees have dark-green trunks. `FloraSdfMorphology` had to hardcode a brown around this (`flora_sdf_morphology.gd:96`). Fix belongs in the dispatcher (see ownership note) — give the branch material its own bark colour. `secondary_color` is *only* consumed by branches here (leaves override both channels at `tree_morphology.gd:583-584`), so the change is contained.
- `flora_sdf_morphology.gd:112-117` — the whole canopy is ONE `StandardMaterial3D` flat `dna.secondary_color`, roughness 0.85. No gradient, no variation. Needs vertex colours from the mesher (see §3).

**Traps**
- `LOD_LEAF_SKIP = [4,2,1,1]` (`:35`) and `LOD_MAX_BRANCHES = [30,80,200,500]` (`:34`) are the tree's cost governors. Raising them at lod 0–1 hits every biome tree.
- `flora_sdf_morphology.gd:24 MAX_CAPSULES = 48` — the SDF field iterates **all** capsules per sample; cost is `res³ × capsules`. This is why `flora_sdf_tree` measures 746 ms. Do not raise it.
- `flora_sdf_morphology.gd:60-63` — the `crown_floor = top_y * 0.45` filter that keeps the trunk visible is a deliberate fix; dropping it re-buries the trunk.
- **Determinism bug worth knowing before any before/after capture:** `tree_morphology.gd:244` uses `root.get_instance_id()` as the RNG base, and `flora_sdf_morphology.gd:40` uses `hash(dna)` — which hashes the *object reference*, not the genes. **Trees are not reproducible across runs.** Two captures of an unchanged map show different trees. Do not attribute that difference to your edit.

---

## 2. GROUND CONTACT — `GridBiomeComponent.gd`

**Current state.** Every dispatched seed organism is placed at `Vector3(col*step, _surface_y(col,row) + 0.02, row*step)` (`:698-699`) — **dead centre of its cell, floating 2 cm, zero jitter**. `_spawn_specimen` is the same (`:1032`). `_surface_y` (`:1418`) is correct (centre-origin cubes; the `h*cube` bug is fixed). Halo/edge cover already jitters in XZ and seats its base exactly on the ground via the recipe's `y_off * sc` (`:908`, `:832`).

**Zero-cost levers**
- `GridBiomeComponent.gd:698-699` — add a **deterministic per-cell XZ jitter** (hash of `col,row`) and a small Y-rotation. Organisms currently form a perfect lattice; this is the biggest "groups that compose" win available and costs one hash.
- Same line — replace the flat `+0.02` float with a small **negative sink** proportional to the organism's own base radius so it sits *in* the ground, not on it. Halo cover already gets this right; seeds do not.
- `_spawn_halo_band:905` (`sc = randf_range(0.7,1.4)`) and `_spawn_edge:830` (`0.55–1.0`) — scale is **uniform**. Non-uniform (squat vs. lanky) per instance costs nothing and multiplies apparent species variety.
- `_spawn_halo_band:882` — the ground strip is one flat plane at `surf_y + 0.005` with `albedo = Color(0.16,0.15,0.13).lerp(kcolor, 0.15)` and no variation. A per-band tonal jitter, or a second darker strip at the outer rim, is one extra transform in an existing batch.
- The presence stain (`_refresh_presence:1191`, shader `biome_presence.gdshader`) is grid-native and already cheap. `PRESENCE_RADIUS = 2.4` cells (`:156`) is very soft; a tighter, darker per-seed contribution would read as contact shadow. Costs nothing at runtime — the texture is `cols × rows` and rebuilt only on reactions.

**Traps**
- `_surface_y` / `_cell_height` (`:1418-1432`) are the fix for the "presence quads poked through the floor" bug. Every Y computation must go through `_surface_y`.
- `_cell_height` returns **1.0** for out-of-range cells (`:1432`), which is what lets halo bands extend past the grid. Do not "fix" it to 0.
- Halo cover has **no collider by design** — the void stays walkable-unchanged. Never add one.
- `_batch_add` key is `"cover:<kingdom>:<recipe>"` (`:909`) / `"edge:..."` (`:833`) / `"strip:<kingdom>"` (`:884`). **Node count is O(kingdoms×recipes) only because the key excludes per-instance data.** Putting a colour, size or jitter value into the key fragments ~12 nodes into hundreds. This is the single most destructive naive change in the file.

---

## 3. MATERIAL RESPONSE — `critter_dna.gdshader`, `critter_trait_mapper.gd`, `sdf_mesher.gd`

Two findings here are, I think, the largest single quality wins in the whole survey.

**(a) Every DNA-shaded organism in the project has SPECULAR = 0.**
`critter_dna.gdshader:491` writes `SPECULAR = specular_tint`; the uniform defaults to `0.0` (`:34`). Grep `critter_trait_mapper.gd:217-233` — `_apply_surface` sets roughness/metallic/iridescence/transparency/cracking and **never sets `specular_tint`**. Godot's default SPECULAR is 0.5. So every tree branch, leaf, mushroom cap, gill, spore and SDF grub renders with the specular lobe fully suppressed — nothing answers a light source. Fix is one line (uniform default, or set it in `_apply_surface`). Cost: zero.
*Honest caveat:* this changes the look of every DNA organism project-wide, including Pokemon Studio and the fungus galleries — it is a default change, not an additive one. Flag it, don't slip it in.

**(b) SDF bodies have no UVs, so the DNA shader runs at UV = (0,0) everywhere.**
`sdf_mesher.gd` never calls `set_uv` or `set_color` — `_tri:273-279` emits bare `add_vertex`. `CreatureSdfMorphology._skin` (`creature_sdf_morphology.gd:110-115`) returns the `critter_dna` ShaderMaterial. That shader derives *everything* from `UV`: `generate_base_pattern`, `apply_surface_effect`, iridescence, cracking. At a constant UV, all 20 patterns collapse to a constant, the SCALES effect degenerates to a flat `color * 0.88`, and `normal_perturbation` becomes a **constant non-zero tilt** written into `NORMAL_MAP` (`:494-496`) — a uniform lighting skew across the whole body. All 13 `fauna:dna:seed` grubs are flat-tinted and patternless.
Fix: write a UV in `sdf_mesher.gd` (planar/spherical from the vertex's normalised position within the sampled AABB) during `_tri`. Cost: one `set_uv` per emitted vertex against a marching loop that already does `res³` field evaluations — well under 2% of build time, **zero runtime cost**. This unlocks the entire pattern/surface library on SDF bodies.
While there: `st.set_color()` in the same place gives height-graded vertex colours to *all three* SDF bodies, which is what §1 (flora canopy) and §5 (fungus cap/stem) both need. `FloraSdf`/`FungusSdf` use `StandardMaterial3D` and would need `vertex_color_use_as_albedo = true` to consume it — additive, no change until opted in.

**(c) Halo/edge MultiMeshes have no per-instance colour at all.**
`_flush_batches` (`GridBiomeComponent.gd:1370-1396`) never sets `mm.use_colors`, and the `StandardMaterial3D` never sets `vertex_color_use_as_albedo`. Enabling both gives **colour variation within a species across ~230 halo cells at zero extra draw calls** — cost is 16 bytes/instance of buffer (~64 KB at the 4000 budget).
*Trap:* `_flush_batches:1377-1381` decimates by **even stride** when the budget clamps. If you store colours in a parallel array you must apply the identical stride, or colours desync from transforms. Safer: store `{xf, color}` together in `_batch_add`.

**Other levers / traps**
- `critter_trait_mapper.gd:151-171 apply_variation` gives ±0.06 colour drift and a pattern rotation. It's called on tree branches and fungus stems/caps but **not** on the SDF skins. Cheap variation, already written.
- `_apply_surface_effect` (`shader:315-378`) *overrides* DNA roughness per surface: bark `max(r,0.7)`, petal `min(r,0.35)`, membrane `min(r,0.25)`. Tuning `dna.roughness` on a bark part does nothing — know this before you "tune roughness".
- `shader:487` writes `ALPHA` unconditionally with `blend_mix, depth_prepass_alpha`. I suspect this puts every DNA organism on the transparent pipeline even at `transparency = 0`, which would cost sorting correctness and SSAO. **I could not verify this without a render** — flag it for the capture agent rather than changing the render_mode blind.
- `fungus_morphology.gd:385` and `:451` hardcode `surface_type = 2.0` (PETAL). This is a documented fix — MEMBRANE's thin-film term (`shader:354-362`) produced the cyan rainbow banding on cap edges and gills that `biome_research.json` records as fixed twice. **Do not "restore DNA-driven surface" there.**

---

## 4. INDIVIDUAL VARIATION — `biome_paint_dispatcher.gd`, `spawn_service.gd`

**Current state.** Every per-cell seed is a **linear** combination of grid coordinates:
```
_spawn_tree:528           seed = (x*31 + z*17) & 0xFFFF
_spawn_creature:584       seed = (x*41 + z*23) & 0xFFFF
_spawn_sdf_organism:433   seed = (x*53 + z*29) & 0xFFFF
_spawn_fungus_preset:478  seed = (x*53 + z*29) & 0xFFFF
_spawn_flower:237         seed = x*31 + z          ← worst: adjacent z = adjacent seed
```
These are then consumed with small moduli — `seed % 7`, `(seed>>3) % 5`, `seed % 11`, `(seed>>6) % 5` (`:438-443`). A linear seed through a small modulus **cycles with a short period along a row**: `_spawn_sdf_organism`'s hue uses `seed % 11` with a per-column step of 53 (≡ 9 mod 11), so the hue repeats every 11 cells — visible banding in any wide field.

**Zero-cost levers**
- Replace all five with `hash("<substrate>:%d,%d" % [x,z])` — the pattern `GridBiomeComponent` already uses for halo/edge/specimen (`:813`, `:866`, `:1036`). Kills the banding outright.
- `spawn_service.gd:44` — `tree_dna_from_seed` varies bark red by `0.05 * float(seed & 3) * 0.1`, i.e. a **maximum spread of 0.015**. Effectively one bark colour across every tree in the project. Widen it (and see §1: the dispatcher overwrites it anyway for biome trees).
- `_spawn_creature:598-604` and `_spawn_sdf_organism:438-444` set `part_length/part_width/part_curve/part_taper` from 5-step quantised buckets. More steps costs nothing.
- **`fungus:sdf` never glows:** `_spawn_sdf_organism` builds its DNA without touching `iridescence` (default 0.0), and `FungusSdfMorphology:56` only enables emission above 0.4. Seven placements that can never bioluminesce. One line.
- **Algo is parsed then ignored for three kingdoms.** `_spawn_specimen` (`GridBiomeComponent.gd:1041-1047`) branches on *kingdom only*, so `mineral:vein`, `mineral:tint` and `mineral:scree` all render the identical crystal cluster; same for `water:pool`/`water:reed`/`water:fog` and `meta:rune`/`meta:glyph`/`meta:glow`. The authoring vocabulary already distinguishes them. (File is §2's; coordinate.)

**Traps**
- `_spawn_fungus_preset:493` — `dna.scale *= (2.2 + 0.6*intensity)`; `_spawn_sdf_organism:438` — `(1.7 + 0.6*intensity)`. These were tuned *against each other* so `fungus:sdf` and `fungus:dna` read at matching apparent size (`biome_research.json` "SIZE FIX"). Change one, change both.
- `spawn_service.gd` has **three** callers (`lsystem_trees`, `BiomeRingComponent`, this dispatcher). Changes there leave the biome layer entirely.
- `_spawn_creature:599-602` explicitly seizes four geometry genes to stop the raw seed DNA producing a ~15 m thread. Don't hand them back to the recipe.

---

## 5. FUNGUS FORM — `fungus_morphology.gd`, `fungus_sdf_morphology.gd`

**Current state.** `fungus:dna`/`fungus:softbody` route to `FungusMorphology` (cap SurfaceTool + stem cylinder + gill MultiMesh + spore MultiMesh). `fungus:sdf` routes to `FungusSdfMorphology` — **two primitives total** (`fungus_sdf_morphology.gd:40-44`: one tapered capsule + one ellipsoid), one shared `StandardMaterial3D` (`:52-59`).

**Zero-cost (or negative-cost) levers**
- **The cap apex emits degenerate geometry.** `_build_cap` builds ring 0 at `rt = 0` → `ring_radius = 0`, so all `segments` vertices of that ring are coincident at the apex. The `ri=0→1` band (`:271-322`) therefore emits `segments` degenerate triangles, and the "centre fan" (`:324-347`) fans `center_vert` to `first_ring` — which *is* the apex — so **every fan triangle is fully degenerate**. `st.generate_normals()` (`:349`) then averages zero-area normals into the apex vertex. This is consistent with the standing notes "Cap slightly lumpy", "Minor specks at the cap-stem junction". Fix: start the rings at `rt = 1/(rings-1)` with a single real apex vertex and delete the redundant fan. **Removes triangles** — negative cost.
  *Honest:* I derived this from the code; it needs one capture to confirm the visual, which I am not permitted to take.
- `:260-261` — `st.set_uv` / `st.set_normal` inside the ring-*building* loop are dead calls (no `add_vertex` follows). Harmless, but they mislead.
- `:294, :298` etc. — cap UVs use `float(ri)/rings` rather than `/(rings-1)`, compressing the radial axis. Since the cap's pattern reads as concentric rings, this directly controls the cap's surface texture scale. Free tuning knob.
- `:244-248` — cap-edge waviness fires only when `rt > 0.7 && edge_type > 0.3`, amplitude `cap_height * 0.1 * edge_type`. Tiny. The wavy-rim silhouette is the cheapest way to make a cap read as organic rather than turned-on-a-lathe; the vertices already exist.
- `_create_canonical_gill_mesh:466-469` — gills are **deeper at the stem** (`-depth`) and shallower at the rim (`-depth*0.5`). Real gills read the other way. Two constants.
- `FungusSdfMorphology`: cap and stem share ONE material, so there is zero cap/stem differentiation. Best fix is §3(b)'s mesher vertex colours (height gradient: pale stem → coloured cap → dark under-cap), still one draw call. Adding a second MeshInstance instead costs +1 draw call per mushroom × 7 placements — acceptable but inferior.
- `FungusSdfMorphology` has **no gills, no ring, no spores**. A third primitive (a flattened ellipsoid under the cap for a gill-shadow mass) costs one more term in the smin field — `res³ × prims`, so ~+50% on a 48 ms body. Say so explicitly if you take it.

**Traps**
- `LOD_GILL_COUNT = [0,4,8,16]` (`:33`): `_spawn_fungus_preset:498` gives `lod = clampi(intensity-1,0,3)`, so **intensity-1 cells get no gills at all**. That's a legitimate LOD behaviour, not a bug.
- `apply_softbody_deform` (`:67-99`) matches child nodes **by name** — `"Stem"`, `"Cap"`, `"Gills"`, `"Spores"`, `"StemRing"`. Renaming any node silently breaks all five softbody poses (12 `fungus:softbody` placements). Its comment at `:96-98` — "never squash Y or gills vanish" — is a scar; keep the Y=1.0.
- The 60 curated `fd_*.json` / `sf_*.json` presets in `morphology/fungus_presets*/` drive these genes. A change to how a gene is interpreted retunes 60 hand-curated organisms at once.

---

## Cross-cutting hard limits (do not touch)
| Guard | Where | Why |
|---|---|---|
| `RES_CAP = 34` | `sdf_mesher.gd:85` | marching tets cost `res³`; four separate perf commits landed here |
| `MIN_CELLS = 1.6` | `sdf_mesher.gd:86` | the "partly-invisible body" bug — thinner than the grid = never meshed |
| `BIOME_SDF_MAX_LOD = 1` | `biome_paint_dispatcher.gd:385` | lod 1 = 57 ms vs lod 3 = 283 ms per body, captured-indistinguishable |
| batch key excludes instance data | `GridBiomeComponent.gd:1346` | node count is O(kingdoms), not O(cells) |
| `DEFAULT_BUDGET_INSTANCES 4000` / `VISIBILITY_RANGE 60` | `:107-108` | 36 of 37 maps rely on these defaults |
| even-stride decimation | `:1377-1381` | deterministic + spatially uniform thinning |
| `_presence_mmi.cast_shadow = OFF` | `:1309` | alpha geometry renders opaque into the shadow map — the "dark rectangle" bug |
| `MAX_CAPSULES = 48` | `flora_sdf_morphology.gd:24` | field iterates all capsules per sample |

## Suggested ownership (split by file, not by area — two areas collide otherwise)
| Agent | Owns | Notes |
|---|---|---|
| A — canopy | `tree_morphology.gd`, `flora_sdf_morphology.gd` | needs the bark-colour fix, which lives in the dispatcher → hand it to D |
| B — ground contact | `GridBiomeComponent.gd` (whole file) | also owns §3(c) batch colours and §4's specimen-algo gap, because they're in this file |
| C — material response | `critter_dna.gdshader`, `critter_trait_mapper.gd`, `sdf_mesher.gd` | owns the UV + vertex-colour emission that A and E consume |
| D — individual variation | `biome_paint_dispatcher.gd`, `spawn_service.gd` | includes A's bark-colour line (`:549`) |
| E — fungus form | `fungus_morphology.gd`, `fungus_sdf_morphology.gd` | |

`creature_sdf_morphology.gd` is unassigned; give it to C (its only real issue is the UV-starved skin) or to D. Sequencing note: C's `sdf_mesher.gd` UV/colour work should land **first** — A's flora canopy gradient and E's fungus cap/stem gradient both depend on it, and all three would otherwise want to edit that file.