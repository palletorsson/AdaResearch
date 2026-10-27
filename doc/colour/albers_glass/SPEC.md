# Albers in glass: `medium` axis on `albers_wall_gallery`

*2026-10-27. Palle: "The Bauhaus color Josef Albers boxes the albers_wall_gallery can we make them in 3d transparent instead." Derived from the colour workflow's judged spec (quest-safe design, judges 92 / 91 / 75) and revised after its critic: the judged spec built thin relief slabs on the wall, which is not "3D boxes"; this spec builds nested glass cubes as the main answer and keeps the relief as the comparison.*

*Revised the same day after three reviews (code, evidence, look). What changed is listed in §7; the numbers quoted here are from the runs listed in §5.*

## 1. The axis

`@export_enum("paint", "relief", "cubes") var medium: String = "paint"` on `algorithms/primitives/homagetothesquare/albers_wall_gallery.gd`.

| value | what stands | what it argues |
|---|---|---|
| `paint` (default) | today's wall, pixel-identical: 589 meshes, 4 shadowed spots, the z-fight and the pastel stay | Albers' practice: opaque tube colour, nothing mixes |
| `relief` | each homage's five squares become five thin filter slabs stepped 3 cm apart in front of a white light table | subtracting glass, seen face-on |
| `cubes` | each homage becomes five **nested glass cubes**, 85% of the painted square, the inner ones smaller and set lower (the painting's `vertical_bias` becomes gravity), the outer cube's edges drawn as thicker glass, standing on pale shelves that belong to the light table | subtracting glass as a body: walking past, the cubes' depths overlap and their colours multiply into each other |

**What the glass reproduces, said exactly.** Glass can only darken. Head-on, a square shows its palette colour exactly (within 1/255) on every channel where the palette is darker than what the outer glass already lets through, and on the other channels it keeps that light. This palette makes inner squares *lighter* (`val_inner >= 0.7`), so that is most squares: **381 of 490 squares (78%) have at least one clamped channel, 677 of 1,470 channels (46%)**. The clamped channels land a median 34/255 sRGB from the palette (p75 73, max 192); per clamped square the CIE76 dE is median 31.6, max 115. Only about a fifth of the homages are reproduced whole. The rest read as a darkening tunnel: the in-or-out ambiguity of the paintings is replaced by literal depth. That is what the medium argues, and the hall text must say so ("glass cannot give back light").

**The comparison is not like for like.** The paint wall does not show the palette either: its material reads the palette bytes as linear, so it shows a pastel of it (median dE76 27.5 against the palette, every square). Glass decodes sRGB and shows the saturated palette where it is not clamped. Paint's pastel is the sacred default and stays.

**Defaults are sacred.** The seven grid placements, the museum plan and the Void's floor 35 carry no `medium`, so they build exactly as today. Nothing under `commons/void/`, no `map_data.json` and no grid code is touched. The Void record switch is Palle's call after he sees the pictures.

## 2. The physics: filter (multiply), never alpha

Real coloured glass subtracts: transmitted light = light behind × transmittance, per channel. `blend_mul` multiplies the framebuffer by the fragment colour, and **multiplication commutes**, so no sorting is needed and nothing flickers. Coplanar glass faces (an edge bar flush with its cube) cannot z-fight for the same reason.

Solve, per canvas, from the painting's palette `C_0..C_4` over the light table `B` (the table's stored byte):

- `A_{-1} = B`; `T_k = clamp(C_k / A_{k-1}, 0, 1)`; `A_k = T_k · A_{k-1}`, each layer solved against the product the already-quantised outer layers really give.
- A channel where the clamp fired counts as *clamped*. Clamp totals are stored as metadata. They are sensitive to 8-bit quantisation (relief 677/381, cubes 673/380: four borderline channels flip between `T` and `sqrt(T)`), so quote them as about 46% of channels and 78% of squares.
- **The space of the solve is the framebuffer's.** Forward+ and Mobile multiply linear light: the solve runs in linear light and the faces are stored sRGB-encoded and decoded by the shader. Compatibility multiplies sRGB values (`OUTPUT_IS_SRGB`; the shader then skips its decode, as BaseMaterial3D does): the solve runs in sRGB space. Measured: Compatibility matched the sRGB-space product within 0.6–0.9/255 and missed the linear one by 4.1–4.5/255 before the change.

**relief**: each slab is drawn front face + sides, cull back, so a ray crosses each slab once: face colour = `T_k`.

**cubes**: each cube is a closed shell drawn cull disabled, so a ray crosses it twice: face colour = `sqrt(T_k)`. Head-on, the centre of a nest is seen through all five shells and reproduces `A_4`; the outer band only through the outer shell and reproduces `A_0`. The 12 edge bars of the outer cube lie inside its shell in its own face colour; a ray through a bar crosses it twice too, so an edge reads `T0^3` against the band's `T0` (a frame head-on, two offset outlines in perspective).

**The material** is a ShaderMaterial (one compiled Shader per cull mode, shared by every wall and rebuild): `render_mode unshaded, blend_mul, cull_*, depth_draw_opaque, shadows_disabled, fog_disabled`, `ALBEDO = decoded COLOR × gain`, `ALPHA = 1`, render priority -1. It is a shader rather than the StandardMaterial3D the first draft named because Mobile halves the multiply operand (below).

**The gain is the 3D buffer's luminance multiplier**, a property of the buffer, not of the renderer's name. Measured on an RTX 3070, 2026-10-27:

| path | gain | evidence |
|---|---|---|
| Mobile, SubViewport or root window, `use_hdr_2d` off | 2.0 | gain 1 halves every layer: outer band 57/255 off, centre 154/255 off |
| Mobile, `use_hdr_2d` on (float buffer) | 1.0 | gain 2 doubles every layer: 67/255 at the band; the diagnostic run before the fix read 32x the expected linear light at the five-layer centre (2^5) |
| Forward+, either | 1.0 | |
| Compatibility | 1.0, sRGB-space solve | |

The artifact reads the viewport it renders into at build time. **Not measured: the Quest itself** (the XR swapchain). So the rule is a default and the project setting `ada/albers_glass/mul_gain` wins when set above 0: a headset-measured value lands as `ada/albers_glass/mul_gain.android=<g>` in `project.godot` (Godot's feature-tag override) with no code change.

**The light table.** The wall becomes a merged unshaded backing mesh (`GlassBacking`, cull back, vertex colours, no shadows, **no fog**): the wall plate in `canvas_color`, frames dropped. Fog is off because the solve assumes B is the stored byte: the Void's depth fog starts at 6 m and would tint the table while the glass, fog disabled, would not. Unshaded means the solve does not depend on the Void's evening light.

**The shelves** (cubes only) belong to the light table: their top face is the table's own byte, so a ray through a cube's bottom onto the shelf still sees B and the solve holds there; front x0.72, underside x0.80, ends x0.86 in sRGB, so the ledge reads as a line. They run from the plate (attached, no float) to 2 cm past the cube fronts.

## 3. Construction

All geometry is cut from `BoxMesh.new().get_mesh_arrays()` (Godot's own winding), transformed and merged; never hand-wound quads.

- `relief`: slab `k` of canvas `c` is a box `(s_k, s_k, 0.006)`, `s_0 = canvas_size · (1 − 2 · border_ratio) = 0.342 m`, `s_k = s_0 · inset_ratio^k`, its back at `wall_front + canvas_depth + 0.02 + k · 0.03`; drop the two back-facing triangles. 20 vertices / 30 indices per slab.
- `cubes`: outer cube `s_0 = 0.342 · CUBE_SCALE 0.85 = 0.291 m`, `s_k = s_0 · inset_ratio^k`, `vertical_bias` scaled by the same 0.85. The gap to the neighbour is 0.169 m against 0.291 m of depth, a clear cone of about 30° (19° at full size). Outer cube's back face 0.05 m in front of the light table. 12 edge bars of 6 mm on the outer cube (the 4 along x full length, the 8 along y and z stopping at them). A shelf per row: 12 mm thick, from the plate to 2 cm past the cube fronts, spanning the canvas columns, its top 0.5 mm under the outer cubes.
- **Containment.** Every square is held at least 2 mm inside the square it nests in (`NEST_MARGIN`), in both glass media: a part outside would be seen through square k but not k-1, and the solve assumes every outer layer. At the defaults nothing is held (tightest margin 12.15 mm relief, 10.33 mm cubes); a `vertical_bias` that would break it is held inside with a warning and counted in the `glass_bias_held` meta.
- One `GlassHomages` MeshInstance3D holds every slab or cube of the wall in one surface; in cubes the 1,176 edge bars follow the 490 nests, so box `c·5+k` is still canvas c's layer k (39,984 vertices, 59,976 indices). One `GlassBacking` holds the plate and shelves. **Measured: 2 draws** for the wall in either glass medium, against 589 for paint (viewport render info on Mobile reads 3 and 590: the picture fixture adds a floor). Shadow casters: 0.
- `Canvas_00..Canvas_97` stay as empty Node3D markers at the canvas positions (the Void's color_04 probe counts them), each with meta `palette`, `layers` (solved, sRGB), `clamped`. Root meta: `glass_medium`, `glass_clamped`, `glass_clamped_squares`, `glass_mul_gain`, `glass_mul_gain_source`, `glass_blend_space`, `glass_bias_held`.

## 4. Config and lifecycle

- `apply_grid_config(config)` reads `medium` (a word; unknown words warn and fall back to `paint`) and rebuilds **once**, only if the value changed. It is a no-op for `{}`, `{"museum_yaw":0}`, `{"emissive":false}` and a repeated call with the same dict (the Void calls it after add).
- `_ready` reads `config_medium` metas first (the Void stamps metas before `add_child`), so a glass record builds glass the first time.
- The setter rebuilds after `_ready`. `_exit_tree` keeps today's behaviour and then asks for a new `_ready`, so a re-entered node rebuilds. **This is a behaviour change on the default path**: the HEAD script left a removed-and-re-added paint wall standing empty; it now rebuilds the baseline exactly (tested). Museum or Void streaming that re-adds a wall will see a wall where it saw none.
- Grid token: `albers_wall_gallery:180:0.5#medium:cubes`. Void record: `"config": {"medium": "cubes"}`.
- Edge case, named, not fixed (the Void is out of scope): the Void stamps `config_*` metas before `add_child` only when a museum import, trial or transformation applies. Floor 35 resolves trial `color_04`, so it is safe. A glass record on a floor without such a source would build paint first (589 meshes) and rebuild glass when `apply_grid_config` arrives, and an unknown word would warn twice.

## 5. Verification (all re-run 2026-10-27 after the review)

1. **Baseline** before editing: `ada_run/albers_paint_signature.json` (07:51, unedited script; 692 rows: child paths, classes, mesh sizes and hashes, material flags, lights, shadows, AABB).
2. **Compile**: `check_compile.gd` on the artifact and both probes, 3 checked, 0 failed.
3. **Structural probe** `probe_albers_glass.gd --mode=check` (headless): **56 passed, 0 failed** (`ada_run/probe_albers_glass.json`). Default and no-op configs equal the baseline byte for byte; paint remove + re-add (same frame, after 3 frames) equals the baseline; relief and cubes build once from the meta with the node, vertex and index counts derived from BoxMesh; bars in the outer face colour inside the outer cube; shelves attached with the table's colour on top; containment; the bias negative (−0.5 would push square 1 out by 40 mm against 32 mm of room, and is held inside with a warning); round trip cubes → relief → paint equals the baseline with orphan nodes back to start and the cubes build's meshes and materials freed (weakrefs; `OBJECT_RESOURCE_COUNT` was measured blind); unknown words fall back with a warning; the project-setting gain reaches the shader. The material check is structural only (shader text and the gain against the root meta); the behaviour is the pixel oracle's. The winding negative is a non-vacuity check (reversing every triangle flips every cross product); the winding *evidence* is the cull-back relief rendering its slab colours and the table at exactly 250,250,247.
4. **Solve oracle** from the read-back vertex colours (relief `A_k = Π T`, cubes `A_k = Π face²`) against a palette regenerated in the probe: every unclamped channel within 2/255 (max 0.49/255 relief, 0.92/255 cubes). Clamp counts equal the metadata. The clamped squares' error against the palette is measured (§1) and recorded, not gated.
5. **Rendered pixel oracle** `probe_albers_glass_render.gd --mode=oracle` (windowed, orthographic, linear tonemap, head-on): two expectations, both computed in the probe: the read-back mesh product, and an independent clamp-aware palette solve with no quantisation. The Canvas meta `layers` is the artifact's own output and is reported only as "meta agrees with mesh". `ada_run/albers_glass_oracle.json`, 19 runs, all machine-written by the current probe, **verdict PASS**:
   - pass (within 3/255 of both): Mobile and Forward+ × relief and cubes × canvases 45 and 44 (8 runs, worst 0.78/255 vs mesh, 0.87/255 vs palette); Mobile `use_hdr_2d`, Forward+ `use_hdr_2d`, Mobile root window, Compatibility relief and cubes (worst 0.91/255). Canvas 44 is the one where the centre sample shows the innermost square is reached (A_3 87,198,91 against A_4 83,187,91).
   - negatives that must fail and do: cubes with cull back (one crossing per shell) on both renderers and both canvases, 59–67/255; Mobile with gain 1, 57/255 at the band; Mobile `use_hdr_2d` with gain 2, 67/255 at the band.
6. **Pictures for Palle** (`--mode=pictures`, Mobile, filmic tonemap, MSAA/SSAA/TAA forced off by the fixture, so the edges step and these colours are not the oracle's linear ones): paint, relief, cubes × front, 35° oblique, close-up, eye (1.65 m eye in Void terms: 1.15 m above the wall base, 1.9 m out, 70° FOV); cubes also grazing.
7. **Gates.** The default is **pixel-identical** to HEAD: `--mode=identity` builds the HEAD script and the working-tree script in one fixture (4 views, 1600×1000, Mobile, the wall's own shadowed spots) in the order head, tree, tree, head. The second paint build of a session differs from the first and third by 1, 2 and 8 pixels in three views whatever the script (the paint z-fight), so builds are compared at equal parity: head_1 = tree_3 and tree_2 = head_4 in every view, 0 differing pixels, while head_1 vs head_4 shows the same 1/2/8 px as tree_2 vs tree_3 (`ada_run/albers_glass_default_identity.json`, `ada_run/albers_glass_default_identity_pixels.json`). This replaces the first draft's gate against `before_front.png`, whose harness, camera and renderer are not recorded anywhere (1800×1200, oblique, green background, a HUD overlay), so it cannot be reproduced. `python tools/check_dna_declarations.py`: `albers_wall_gallery.medium` ok.
8. **Registry**: `python tools/apply_dna_block.py --token=albers_wall_gallery --axes=medium` derived `paint, relief, cubes` from the code; `dna.default` "paint" and a written `dna.predicted_degeneracy` before any sweep: relief vs cubes, head-on, focus **26.7%** as a lower bound (`tools/predict_albers_glass_degeneracy.py`, the critic's own crop and metric over the read-back boxes; paint vs relief 54.6%, paint vs cubes 54.5%).

Reproduce everything rendered: `python tools/run_albers_glass_evidence.py all` (one Godot at a time, each under the watchdog).

## 6. Open, for Palle

- **The clamp is the medium's argument or its flaw.** Levers, each a design change: (a) keep it, and the hall text says glass shows what subtraction can reach; (b) relief only: build each slab as a square ring whose hole is the next square, zero clamps and an exact homage head-on, multiplication only in the parallax overlaps; (c) solve glass against the colour the paint wall *displays* (its pastel): the fronts then match paint minus the clamps and neighbour overlaps roughly double in brightness, but the glass no longer shows the palette; (d) reorder or recolour each canvas so every channel darkens inward, which changes the homages.
- **The Quest.** One headset check before the Void record is switched: a frame of one canvas head-on through the VR link, its centre and outer band against that marker's `layers` meta, within a few /255. If it is off by a constant, set `ada/albers_glass/mul_gain.android` and nothing else. Also time a grazing stance close to the cubes wall: blended overdraw (10 multiply fragments per pixel at a nest's centre, more at grazing) is the new GPU cost, not measured.
- **From the side** the cubes still go dark beyond the nearest columns: 42.5% of the grazing frame is below luma 40 (50.5% before the cubes shrank and the shelves went pale), 15.3% of the oblique frame. A golden-angle palette puts near-complementary filters side by side; that is physics, and it is the walk-past picture.
- **MSAA for XR** is a project decision, not this artifact's; the pale shelves removed the worst crawling edge (black on white).
- The Void record's 0.5 m float puts 6 of 7 rows above a 1.65 m eye; height 0 would put the row centres at 0.89–3.65 m. The registry's `compact` footprint for a 7.76 m wall: flagged, not fixed.

## 7. Deferred, named

- `veil` (alpha averaging, needs a static draw order) and `stain` (unsolved chip-as-glass) from the judged spec.
- Twins: three pairs whose cores carry the same light at the eye and differ only by surround, with shape glyphs so colour vision is never required. Albers' central lesson; it needs the projection step of the judged spec.
- The hall text (`commons/maps/Color_Paint/final.md` lines 53-63 and its bridge sentence, which promises Color_Walls as the first place colour can be looked through) follows the map only after the Void record is switched.

## 8. What the review changed

- Pale shelves attached to the table, top in the table's colour (was near-black, floating 3 cm off the plate, the dominant thing in every cube view).
- Cubes at 85% with the bias scaled, and 12 edge bars on each outer cube (were flat squares near the axis and clipped hexagons off it).
- Containment held and tested for any `vertical_bias`.
- The gain follows the buffer (`use_hdr_2d`) with a project-setting override; the decode is guarded by `OUTPUT_IS_SRGB`; Compatibility is solved in sRGB space; the Shader is compiled once per cull mode; the backing ignores fog.
- Evidence: an independent palette oracle, canvas 44 and both renderers' negatives required, machine-written gain negatives, the hdr/root/Compatibility paths, the clamped squares' error measured, paint re-add tested, resources tracked by weakref, draw calls recorded, the default compared pixel for pixel against HEAD in one fixture, an eye-level picture.
