# Shader and pattern maps: what is worth carrying forward

10 October 2026 · source survey and teaching proposal

There is useful material here. The strongest gain is a clearer return from stored motifs to coordinate rules, then from surface appearance to visible geometry. Tiling already has a coherent nine-hall route; most additions should be selected encounters inside its current halls or inside the six shader halls.

The separate `patterngeneration` route contains 25 maps. Six are already in `shaders`. The seven older `Pattern_Generation_*` maps overlap it at Five, giving **31 unique maps** in this review. A broader discovery index is included separately; those extra names have not all received a code-level audit.

This report does not change map order, artifacts, tutorial.md or final.md. Findings come from map JSON, registry resolution, scene references and selected implementation code. The two images are existing isolated engine previews, not fresh captures of the current museum placement. Source links open dated snapshots. No runtime, ghost-student or headset pass was performed for this survey.

## What I would borrow

### UV made visible — Borrow first

**Pattern_Generation_One → Shader_01_Shaping**

Keep the learner's panel and motif. Show its UV colours, repeat the coordinates, turn a cell, then use those coordinates to evaluate a shape. The five stages already exist in TilesExplained.gd.

Proposed learner check: Predict which four positions will sample the same local coordinate; change the repeat count and check them.

Source: [algorithms/shaders/tilesexplained/TilesExplained.gd, line 3](sources/algorithms/shaders/tilesexplained/TilesExplained.gd).

### One tile, several turns — Small Tiling addition

**Pattern_Generation_Three → Tutorial_Pattern**

Keep one asymmetric diagonal tile. Compare a 4×4 field with all cells facing one way against a fixed orientation rule. Let the global pattern change while the source stays the same. This extends the current reflection lesson rather than replacing it.

Proposed learner check: Change only one orientation entry and identify exactly which cell changes; then alter the repeated rule and follow every affected copy.

Source: [algorithms/patterngeneration/truchettiles/quarterarcs.gdshader, line 31](sources/algorithms/patterngeneration/truchettiles/quarterarcs.gdshader.txt).

### The familiar form becomes a test — Borrow first

**Shader_03_Shapes + Shader_04_Matrices → Shaping / Patterns**

A radius produces a boundary; translated or rotated sampling coordinates change where it appears. Bring back the point, line and transformed cube through one surface rule.

Proposed learner check: Separate a transformed Node3D from a transformed UV: predict what moves on the surface and what stays fixed in the room.

Source: [algorithms/shaders/book_of_shaders/shader_03_shapes.gd, line 23](sources/algorithms/shaders/book_of_shaders/shader_03_shapes.gd).

### A bump, or a changed body? — Borrow first

**Pattern_Generation_Four → QueerRubber / FBM**

Put a field on the same sphere. Compare colour only, normal response, then vertex displacement. The normalstone shader has an explicit vertex-displacement switch. This is a strong return to primitive resolution.

Proposed learner check: Predict which mode changes the silhouette. Check collision separately; a displaced visible mesh does not establish a changed physical collider.

Source: [algorithms/patterngeneration/fabrics/normalstone.gdshader, line 87](sources/algorithms/patterngeneration/fabrics/normalstone.gdshader.txt).

### A skin made from known decisions — Optional composition

**Pattern_Generation_Seven → PinkExtravaganza**

Compose one stripe or spot mask with a palette and material response. A personal skin can carry earlier colour, noise and form work without making all animal modes compulsory.

Proposed learner check: Hold the mask fixed and change the palette; hold the palette fixed and change mask scale. Explain the two results separately.

Source: [algorithms/patterngeneration/animalpatterns/neontigerstripes.gdshader, line 189](sources/algorithms/patterngeneration/animalpatterns/neontigerstripes.gdshader.txt).

### A surface that keeps an encounter — Later, after repair

**Pattern_Generation_One → Shader_10_ReactionDiffusion**

The unused degradation manager sketches a CPU image that accumulates imprints and is uploaded as a texture. This could contrast a retained record with a pattern recalculated from TIME.

Proposed learner check: Leave a mark, stop input and verify the stored record persists; reset it deliberately. First connect the manager, material and actual museum hands and validate the code.

Source: [algorithms/shaders/degrading_shader/DegradingShaderManager.gd, line 64](sources/algorithms/shaders/degrading_shader/DegradingShaderManager.gd).

## Keep the teaching line clear

**Tiling:** a small stored motif → a copying rule → a receiving surface → a worn recipe. Add one controlled orientation comparison if it helps; keep the real loom and the distinction between making thread and depicting cloth.

**Shaders:** the same receiver → coordinates → a form mask → transformed/repeated sampling → material response → layered fields → composition → the need for retained state. Return to the student's familiar sphere or cube. The new operation belongs in a small script or shader; the museum supplies the host.

The shader sequence's form-based plan exists, but four of its six maps currently lack tutorial.md, and Shader_05_Patterns calls its own learning focus proposed. This is not another finished, tested teaching sequence waiting to be concatenated. Its existing reflections and working exhibits are the starting material for a proper pass.

## Full map list

| Map | Fit | What is actually placed / implemented | Proposed use and limit |
|---|---|---|---|
| [Shader_01_Shaping](sources/commons/maps/Shader_01_Shaping/map_data.json) | Already in Shaders | Five function/graph panels, including step and smoothstep. | Bring the spare Shapes hall's circle mask here: the point and distance return as a surface boundary. The current full tutorial is absent; the sequence JSON describes a proposed focus, not a verified learner chain. |
| [Shader_02_Colors](sources/commons/maps/Shader_02_Colors/map_data.json) | Reference | Gradient, HSB, mix and rainbow panels with parameter controls. | A small reference beside Shaping can recall colour interpolation. Colour already has its own sequence. A second compulsory colour hall would repeat that work. |
| [Shader_03_Shapes](sources/commons/maps/Shader_03_Shapes/map_data.json) | Borrow for Shaders | Circle, rectangle, boolean-combination and polygon masks; radius, softness and sides controls. | Use one circle-to-boundary comparison in Shader_01_Shaping. Keep the existing sphere or cube as receiver. These are surface masks, not new collision bodies. Boolean composition can stay optional. |
| [Shader_04_Matrices](sources/commons/maps/Shader_04_Matrices/map_data.json) | Borrow for Shaders | Separate translation, rotation, scale and combined-coordinate panels. | Use one transformed sampling coordinate in Shader_05_Patterns. Reconnect to Transformation without rebuilding a cube. Moving a sampling coordinate and moving a Node3D are different operations. The full four-panel gallery need not become another lesson. |
| [Shader_05_Patterns](sources/commons/maps/Shader_05_Patterns/map_data.json) | Already in Shaders | Classic tile/Truchet/offset/brick modes plus Wang-labelled, Voronoi and noise modes; the map also contains a garden and camera study. | Carry one motif through address, local coordinate and orientation. Other modes can remain museum encounters. Already dense. Its tutorial explicitly says its proposed focus still needs alignment. The Wang-labelled shader blends neighbouring edge colours; it is not a constraint solver or an aperiodicity proof. |
| [Shader_06_Random](sources/commons/maps/Shader_06_Random/map_data.json) | Reference | Coordinate hash, random-grid and animated-static panels. | Recall the difference between a fixed result at an address and a clock-changing input when randomising tile orientation. Keep Randomness as the place where sampling is learned. Do not imply bit-exact GPU replay across all devices. |
| [Shader_07_Noise](sources/commons/maps/Shader_07_Noise/map_data.json) | Reference | Value, gradient, simplex and domain-warp panels. | A comparison source for Shader_09_FBM; revisit a known noise input at a new surface. Noise already has a sequence. Choose one return, not another survey of every noise algorithm. |
| [Shader_08_CellularNoise](sources/commons/maps/Shader_08_CellularNoise/map_data.json) | Borrow for Shaders | Nearest-point, Worley F1 and F2-F1/crackle display definitions. | Use one nearest-point comparison if it makes the transition from a regular grid to irregular cells clearer. Optional after the established coordinate lesson; compare with Voronoi already in Shader_05_Patterns before adding another artifact. |
| [Shader_09_FBM](sources/commons/maps/Shader_09_FBM/map_data.json) | Already in Shaders | Layered-noise displays and a separate water basin under glass. | Borrow a controlled normal/displacement comparison from Fabrics. Connect the familiar wave and field to surface appearance. The supporting glass and collision are separate from the visible wave. Current final.md already makes that distinction. |
| [Shader_10_ReactionDiffusion](sources/commons/maps/Shader_10_ReactionDiffusion/map_data.json) | Already in Shaders | A reaction-diffusion material whose previous texture is not connected; a separate analytic frost image labelled DLA. | Keep the question of retained state explicit before Cellular Automata. Do not present the panels as working growth simulations. The current reflection already identifies the missing input. |
| [Shader_11_QueerRubber](sources/commons/maps/Shader_11_QueerRubber/map_data.json) | Already in Shaders | Material studies on staged primitive bodies; view-dependent rims, surface response and lighting. | A strong place for the returning sphere: compare colour, normal response and actual silhouette change. Use a controlled comparison; a library of spectacular materials alone does not establish what changed. |
| [Shader_12_PinkExtravaganza](sources/commons/maps/Shader_12_PinkExtravaganza/map_data.json) | Already in Shaders | Pink material compositions and a plural-body study. | Borrow one animal-pattern skin as a composition of known masks, noise, palette and material response. These shaders make designed resemblances, not biological explanations. Keep the composition lesson bounded. |
| [Pattern_Generation_Five](sources/commons/maps/Pattern_Generation_Five/map_data.json) | Optional Shaders | Shader_Gallery materials and a waves scene containing water shaders. | A reserve for material and water comparisons in the existing body/basin halls. Both already have strong examples. Four-wave water with depth, normals and refraction is too much as the first printed shader. |
| [PatternGeneration_Diffusion_Limited_Aggregation_DLA](sources/commons/maps/PatternGeneration_Diffusion_Limited_Aggregation_DLA/map_data.json) | Repair before teaching | The map places self_organizing_patterns, not the separately named DLA artifact. | Keep as a candidate for a later growth/state sequence after checking the actual simulation. The map title alone cannot establish diffusion-limited aggregation. Do not import its stated lesson unchanged. |
| [PatternGeneration_Narrative_Generation](sources/commons/maps/PatternGeneration_Narrative_Generation/map_data.json) | Keep for later | The map places markov_chains. | A later probability/language comparison may be useful. It does not strengthen the present tiling-to-surface-rule progression. |
| [PatternGeneration_Penrose_Tilings](sources/commons/maps/PatternGeneration_Penrose_Tilings/map_data.json) | Repair before teaching | The placed artifact is koch_curve. A separate PenroseTilings.gd implementation exists elsewhere. | Order without simple repetition is an interesting future encounter. Neither the map name nor a finite illustrated patch proves the property. The separate implementation needs a geometric audit before teaching from it. |
| [PatternGeneration_Typography_Generation](sources/commons/maps/PatternGeneration_Typography_Generation/map_data.json) | Repair before teaching | The map places env_one, a random environment generator. | Letter/motif relationships could be useful, but this room is not evidence for an implemented typography lesson. A relevant artifact would need to be selected and verified first. |
| [PatternGeneration_Wang_Tiles](sources/commons/maps/PatternGeneration_Wang_Tiles/map_data.json) | Repair before teaching | The map places env_one, not a Wang tile solver. | Edge compatibility could become a later constraint lesson; compare the real wfc_tile_mosaic instead. The similarly named shader in Shader_05_Patterns averages edge colours rather than selecting tiles from a constrained tile set. |
| [Pattern_Maker_Workshop](sources/commons/maps/Pattern_Maker_Workshop/map_data.json) | Already represented | One pattern_maker_station with an editable source and carpet receiver. | Useful as a quieter test room for the same station already used in Foundry and Tutorial_Pattern. It is not a new learning operation merely because it has another map. |
| [Cove_Display_Gallery](sources/commons/maps/Cove_Display_Gallery/map_data.json) | Optional Tiling | wall_pattern_gallery overlays wallpaper materials on grid architecture. | Borrow a single wall-to-ceiling return or a controlled crop/seam comparison for Array_Patterns or Pattern_Temple. The same gallery artifact is already in Symmetry_Seventeen. Its grid-system assumptions need checking in a different museum shell. |
| [Wallpaper_Groups_Gallery](sources/commons/maps/Wallpaper_Groups_Gallery/map_data.json) | Reference | A floor-plan-driven collection of named group bays and decorative floor presets. | A spatial catalogue to consult when choosing a contrast for Symmetry_Seventeen. Names and floor presets do not prove the assigned groups. The floor plan does not even enumerate all 17 group names; do not import its census claim. |
| [Shader_Arch_Gallery](sources/commons/maps/Shader_Arch_Gallery/map_data.json) | Optional Tiling | A tunnel of cube receivers with independently generated domain textures, palettes, scales and wallpaper-group settings. | An optional exuberant destination: one rule can dress an enclosure. Changing many parameters at once obscures causality. Pattern_Temple already supplies the controlled architectural lesson. |
| [Tile_Shapes_Gallery](sources/commons/maps/Tile_Shapes_Gallery/map_data.json) | Reference | Fifteen floor-plan rooms including entrance; square/diagonal/hexagonal/radial and other named floor patterns. | Take one contrast between carrier/lattice arrangements for an optional tile study. A catalogue of presets is not yet a lesson explaining their construction. Tiling need not teach every tile family. |
| [Pattern_Maker_Showcase](sources/commons/maps/Pattern_Maker_Showcase/map_data.json) | Reference | Tile puzzle, 4×4/8×8/mirror/brick/herringbone/cube variants, carpet, editor and WFC mosaic. | A useful artifact-selection shelf. Compare one carrier or one copying rule at a time. Most of the family is already represented in Tiling. WFC adds neighbour constraints and should be a separate later step. |
| [Pixel_Art_Gallery](sources/commons/maps/Pixel_Art_Gallery/map_data.json) | Optional Tiling | An eight-room floor plan with pixel-invader, neon, glitch and Memphis areas plus corridors. | A visual return to the small stored source and nearest sampling, if we need an optional walk. It adds atmosphere more readily than a new core operation; the complete gallery need not enter the spine. |
| [Pattern_Generation_One](sources/commons/maps/Pattern_Generation_One/map_data.json) | Borrow for Shaders | tiles_explained, gridscheckers and degrading_shader_demo. | The five-stage UV → tiling → rotation → tile orientation → final pattern display is the strongest opening bridge from Tiling to Shaders. tiles_explained is marked map_ready=false. The degrading scene does not attach its manager; touch memory is not ready as placed. |
| [Pattern_Generation_Two](sources/commons/maps/Pattern_Generation_Two/map_data.json) | Optional Shaders | A glass-divider shader scene and WFCSculptureGenerator. | Use the divider to compare object UV with sampling the scene behind a surface. Screen/depth sampling needs renderer and headset checks. Keep the WFC sculpture outside the minimal shader lesson. |
| [Pattern_Generation_Three](sources/commons/maps/Pattern_Generation_Three/map_data.json) | Borrow for Tiling | A Truchet-family surface scene plus WFC3DGenerator. | In Tutorial_Pattern, show a small deterministic 4×4 orientation comparison: one diagonal source, several turns, a different global reading. Borrow the motif/orientation idea. Random flips and WFC belong later. The file quarterarcs.gdshader actually draws a diagonal threshold, despite its name. |
| [Pattern_Generation_Four](sources/commons/maps/Pattern_Generation_Four/map_data.json) | Borrow for Shaders | The fabrics scene binds wallpaper, normal, terrain, displacement and tartan shaders. | Use one known sphere to separate an image, a perturbed normal and vertex displacement in Shader_11_QueerRubber or Shader_09_FBM. This is not a woven-thread simulation. Preserve the distinction between the physical handloom, a depicted textile and shader geometry. |
| [Pattern_Generation_Six](sources/commons/maps/Pattern_Generation_Six/map_data.json) | Keep for later | A TileMate scene generating and mirroring coloured line paths, with a timed pattern update. | Potential return to Trace and symmetry, or a later lesson on changing a stored pattern. It uses line geometry rather than just a fragment shader. Random path generation and timed changes add a different teaching problem. |
| [Pattern_Generation_Seven](sources/commons/maps/Pattern_Generation_Seven/map_data.json) | Borrow for Shaders | Animal-pattern materials: spots, stripes, scales, eyes and moiré; a mode-driven shader combines noise and masks. | One selected skin in Pink Extravaganza could let the student compose earlier operations on their own sphere. Do not assign the entire material library. File names can mislead: popleopard.gdshader is a hex/stitch appearance, while the multi-animal modes live in neontigerstripes.gdshader. |

## Nearby collections

**Symmetry_Motif · Symmetry_Translation · Symmetry_Mirror_Rotor · Symmetry_Glide · Symmetry_Group · Chamber_Symmetry**

A separate symmetry proposal still exists. Its tile, loom/mill, mirror and group operations overlap the present Tiling sequence. Keep it as a source catalogue; Chamber_Symmetry is a catalyst/synthesis room, not another pattern algorithm.

**Pattern_Loom_Gallery · Pattern_Tunnel · Pattern_Walls_Pearl**

Six loom variants; a pattern tunnel; mosaic floors and a WFC mosaic. Useful form and display alternatives. Check what each 'loom' actually makes: the recent thread_loom is the explicit warp/weft artifact.

**Grand_Pattern_Museum · Mega_Pattern_Museum · Immersive_Pattern_Rooms · Pattern_Showcase · Pattern_Walls_Gallery**

These contain substantial floor-plan JSON, not just empty floor_plan_space tokens. They supply room arrangements, borders, architectural skins and preset comparisons. Select an encounter rather than importing another large gallery.

**Gallery_Shaders**

A broad sixteen-artifact shelf including a pattern compositor, cubemap, transmission, carpet and material galleries. The compositor assigns different patterns to field, border and medallion zones: useful if Pattern_Temple needs clearer compositional parts. Several placements are aliases or alternate versions; count functions rather than names.

**Mosaic_Pattern_Maker · PG_Mirrored_Patterns · ProceduralGenerationBooleanPatterns**

Adjacent work connects painted motifs to tessellation, procedural mirroring and constraints. These belong to other routes; useful references, not automatically missing Tiling chapters.

**Pattern_pt01_p1_bauhaus … Pattern_pt10_p3m1_alhambra**

Ten preview maps use gallery_marker_pattern. Treat them as visual variants and locate their configuration before calling them ten new lessons.

## Specific cautions before teaching from this material

- The Penrose, Wang and Typography map names currently point to different artifacts. A title is not implementation evidence.
- `patterns_wang.gdshader` blends independently assigned edge colours. At full blending adjacent sides share an average, but this does not implement tile-set constraint solving or prove aperiodicity.
- `quarterarcs.gdshader` in the old Truchet scene uses `step(st.x, st.y)`: its source mark is diagonal. The Book of Shaders `patterns_truchet.gdshader` is the separate actual arc implementation.
- The degradation manager is not attached by its demo scene and uses fixed hand paths plus Image lock/unlock calls that need a Godot 4.6 compatibility check. It is a promising repair candidate, not a verified touch-memory artifact.
- The named wallpaper-group floor bays use decorative floor presets. The current floor-plan list omits PMG and PGG; it cannot stand in for a complete or verified classification.
- Procedural textile appearance, interlaced yarn geometry, cloth motion and skin pattern formation are different subjects. An attractive resemblance can support reflection without being a simulation of the referenced process.

## Next concrete pass

Start with the shader opening. Use the five-stage coordinate display and one circle mask on a familiar receiver. Write one complete minimal example, reconstruct it from the printed text, and test a predicted change. Then choose whether the small 4×4 tile-orientation study adds enough to Tiling to earn its place. No new hall is required by these recommendations.
