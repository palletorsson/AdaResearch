# Shaders in places

10 October 2026 · spatial and tutorial proposal for Endless Museum

The shader sequence needs scenes with a reason to be there. A furnished room, basin, passage or abstract stage gives the material something to change. The existing six-hall route remains a useful provisional structure; its order and density can still change after one staged hall is tested.

This pass records a direction and a source inventory. The settings below are not built yet. Museum maps, runtime code and tutorial/final manuscripts are unchanged. Images are reused Godot specimens from the earlier survey, not renders of these proposed rooms.

## What the references contribute

- [Intro till Queer 3D world 2024](https://docs.google.com/document/d/1ndU2dkp55eR-qC2qC121hLkFXIML41-Nu3PFVo1AxYg/edit): prefabs and digital archives as artistic material; skins, impossible rooms and the relation between technical literacy and aesthetic choices. Carry a recognizable thing through a change so the operation has consequences.
- [edgeartist](https://docs.google.com/document/d/1p0hG1Og96_CwDl-OA1eZMUG0GPdLy41Am2Adstc07Qo/edit): a collection of spatial desires—folding, softness, scale, accumulation, inside/outside and unstable material identity. It explicitly places Claudia Hart near shaders. Use these as research prompts, not verified histories or recipes for copying an artist's style.
- [VR_VR_PT_2023 research application](/book-review/doc/VR_VR_PT_2023.md): the project proposes an increasingly complex landscape of algorithms, strange realities, exploratory spaces and a relation between abstraction and surrealism. The application is a statement of aims; its historical examples need independent checking before reuse in the book.

My reading: the technical operation must stay exact, while the encounter can become extravagant. The same rule should be inspectable on a simple receiver and meaningful when situated in a larger world. A strange colour does not by itself establish a queer relation; ask what the setting permits a body to do, expect or become.

## Two simultaneous progressions

Teaching: coordinates → mask → repeated/transformed domain → material response → displaced field → composition → retained state.

Experience: image → patterned place → familiar object made strange → water at architectural scale → abstract/surreal assemblage → a room that keeps an encounter.

For each hall, use one primary reconstruction object and at most a few nearby comparisons. Retain the student's sphere/cube and shader functions where they still clarify the work. A furnished prop is a second receiver, not a reason to explain modelling from scratch. The museum can contain more than the tutorial teaches.

## Six proposed settings

### 1. A mark becomes a surface — Shader_01_Shaping

**Setting:** Graphic wall / small workbench. Begin at the museum wall, with one large circle mask beside the existing graphs. A small cube provides the same rule on another receiver. Leave enough blank wall for the boundary to read.

**Tutorial:** UV coordinates, a distance mask, one uniform controlling its boundary. Keep step versus smoothstep as a visible comparison. Move the boundary with one nearby control, then change its radius in the complete printed shader. Predict which sampled positions change.

**Carried forward:** The same mask and its parameters travel forward as code. No new geometry is needed to draw the circle.

**Reflective question:** An image of an opening is not yet an opening you can pass through.

**Supporting encounters:** Use the existing five graphs as reference exhibits; only one mask carries the reconstruction lesson.

### 2. The image leaves its frame — Shader_05_Patterns

**Setting:** Patterned passage / domestic fragments. Let the wall pattern continue onto a floor, a column and a familiar chair. Keep a neutral strip along the route. Reuse actual project props rather than inventing another sample rack.

**Tutorial:** Transform and repeat the sampling coordinates. Distinguish the address of a tile from the position inside it. Keep the chair still and slide the pattern; then move the chair. Compare attached UVs with a supplied world-coordinate material.

**Carried forward:** The learner retains the original mask and adds a coordinate function. The woven cloth is a reference for continuity, not a prerequisite clothing system.

**Reflective question:** A repeated mark can suggest that several unrelated objects belong to one place.

**Supporting encounters:** Tartan, optical checks and one animal mask can be nearby applications without becoming three extra coding lessons.

### 3. A familiar object acquires another skin — Shader_11_QueerRubber

**Setting:** Uncanny furnished room / material stage. Use the project sofa, chair and vase alongside the carried sphere. Give the same objects velvet, leather, oil sheen or pearl. Keep the silhouette recognizable so the material change can be felt.

**Tutorial:** Material response: surface normal, roughness and view-dependent rim. Begin on the same sphere under fixed light. Walk around it; then change one response while holding mesh and lighting constant. Transfer that material to one furnished object.

**Carried forward:** The same receiver and mask now control material channels. Normal-based detail is compared with actual silhouette change only after it is understood.

**Reflective question:** A surface suggests softness, expense, bodily contact or discomfort; those suggestions do not establish its physical behaviour.

**Supporting encounters:** Oil-Slick Latex, Crushed Pearl and Sad Metal are existing material candidates. Their names are invitations, not verified physical models.

### 4. Water becomes a place — Shader_09_FBM

**Setting:** Sunken basin / impossible bathhouse. Give water a substantial place in the hall: a low basin, a visible edge and a route around it, with a chair or column reflected in the composition. Begin with the existing basin rather than installing an unrelated ocean.

**Tutorial:** Reuse waves and noise as a height field; apply it to a sufficiently subdivided mesh and account for the visible normal. Layered noise is a return to prior work. Hold the field fixed; compare colour only, normal response and vertex displacement. Look at the edge to identify which mode changes the silhouette.

**Carried forward:** The familiar surface rule now affects vertices. Mesh density returns from Primitives; the floor/support remains an explicitly separate construction.

**Reflective question:** What looks deep, wet or yielding may still be supported by a flat invisible collider. The room makes that distinction available to experience.

**Supporting encounters:** Show one water application at scale. Refraction, foam and underwater viewing stay supporting studies until validated; do not pack them all into the first water lesson.

### 5. The room can be otherwise — Shader_12_PinkExtravaganza

**Setting:** Abstract and surreal assemblage / open stage. Recombine recognizable furniture, the learner sphere, cloth, columns and water-like surfaces at deliberate scales. A reflective sofa, hovering drape or apparently liquid ceiling should change a spatial expectation, not just add decoration.

**Tutorial:** Compose known masks, domains and material channels. No compulsory new mathematical technique. Choose one prefab; make two distinct readings by changing only its material rule, then change its setting while keeping the material fixed.

**Carried forward:** A material recipe and the declared receiver. Wearing the result can be an optional return to Tiling once the actual player material adapter is checked.

**Reflective question:** Which qualities did the asset library assume, and which did the student alter? Surreal space comes from relationships as well as unusual colour.

**Supporting encounters:** Candidates include candy deformation, patterned skin, foil and dream water. Select a few that make a composition, not all available shaders.

### 6. An encounter leaves a trace — Shader_10_ReactionDiffusion

**Setting:** Quiet return / wall that remembers. Return to a restrained room after the stage. Put an animated material beside a surface that genuinely retains a mark, once its state path is implemented.

**Tutorial:** Time-driven evaluation versus a stored previous state. Actual reaction–diffusion is a further operation, not a synonym for a retained mark. Leave a mark, stop input and test that the stored record remains; reset it deliberately. Compare with a pattern that only changes with TIME.

**Carried forward:** A declared state owner and update rule, providing a concrete bridge toward cellular automata.

**Reflective question:** A surface can appear to carry history without keeping any. Locate what the world actually retains.

**Supporting encounters:** The current reaction–diffusion panel has a missing previous-state input. The degradation manager needs integration. Memory Skin is moving noise, not contact history.

## Give water enough room without making it every subject

Water is already partly in the route through basin_water, while the larger collection remains outside it. Use the basin as the next environmental proof: one controlled height field, a simple object beside it, a visible edge and a clearly supported path. Do not present refraction, foam, buoyancy, displacement, noise and fluid simulation as one tiny lesson. If the water encounter needs a separate teaching step after testing, split it explicitly; six is a working structure, not a quota.

The existing water2 shader is a concrete repair candidate: its screen and depth samplers have no capture hints, and the scene feeds noise into its screen slot. Godot's [screen-reading documentation](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html) specifies those hints and explains that the 3D screen copy excludes transparent geometry. A good desktop still cannot establish working refraction in a headset. Validate the chosen renderer, both eyes and the actual scene inputs.

## Existing sources to choose from

The inventory counts shader source files, not distinct working artifacts. Only the selected candidates below received this inspection. The old visual survey contains 76 specimens across shaders, patterns, machines and spaces; it is not a complete shader inventory.

| Existing source | Proposed role / current limit |
|---|---|
| [Water basin](/book-review/commons/artifacts/basin_water/basin_water.tscn) | **Existing Shaders / FBM anchor.** Directional sines, value noise, displaced surface and a separate supporting construction. Strong starting point for the room-scale application. |
| [Water comparison](/book-review/algorithms/patterngeneration/waves/waves.tscn) | **Pattern_Generation_Five source.** Several older water materials on simple receivers. Re-stage a selected one; do not import the whole floor arrangement unexamined. |
| [Noise-displaced water](/book-review/algorithms/patterngeneration/waves/water2.gdshader) | **Repair candidate.** Plain SCREEN_TEXTURE/DEPTH_TEXTURE sampler uniforms lack screen/depth hints; the scene assigns noise as SCREEN_TEXTURE. Do not describe this as verified scene refraction. |
| [Waterfloor](/book-review/commons/resourses/shaders/waterfloor.gdshader) | **Water study.** Normal textures, displacement and hinted screen/depth sampling. Source found; renderer/depth and stereo behaviour still require testing. |
| [View under water](/book-review/commons/resourses/shaders/see_under_water.gdshader) | **Optional optical study.** Samples a screen texture with distortion. A viewing effect, not a complete underwater physical environment. |
| [Dream water](/book-review/algorithms/shaders/book_of_shaders/queer_water.gdshader) | **Pink composition candidate.** Sine displacement, animated noise, view-dependent colour and emission. No fluid solver. |
| [Flag-coloured water](/book-review/commons/resourses/shaders/bitwisewater.gdshader) | **Optional material.** Palette presets, waves and shimmer. Queer inquiry must also examine body, relation and constraints; a flag palette alone is not the argument. |
| [Frosted divider](/book-review/algorithms/patterngeneration/glassdivider/glassdivider.tscn) | **Window / passage candidate.** An existing divider scene with screen/depth-dependent material. Test what is visible through it in each eye. |
| [Material transmission](/book-review/algorithms/shaders/materialtransmission/materialstransmission.tscn) | **Optional optical comparison.** Existing code-driven gallery with transmission material. Keep camera-dependent effects out of the minimal first shader. |
| [Normal / displaced stone](/book-review/algorithms/patterngeneration/fabrics/normalstone.gdshader) | **Controlled comparison.** An explicit vertex-displacement toggle makes normal-only detail versus silhouette change teachable. |
| [Leather / velvet / plastic gallery](/book-review/algorithms/shaders/Shader_Gallery.tscn) | **Material room sources.** Useful on the same known form, then on a recognizable prefab. These are visual responses, not simulated leather or cloth. |
| [Oil, pearl, skin, metal, candy collection](/book-review/algorithms/shaders/queer_collection_2/Collection_Gallery_A.tscn) | **Additional collection outside six-hall teaching list.** Five material spheres with their own lights, environment and camera. Extract selected materials; do not import a second global environment blindly. |
| [Memory Skin](/book-review/algorithms/shaders/queer_collection_2/memory_skin.gdshader) | **Counterexample in final hall.** Its marks are sampled from moving noise using TIME. No contact record is retained by this shader. |
| [Melted Candy](/book-review/algorithms/shaders/queer_collection_2/melted_candy.gdshader) | **Surreal composition.** Sine-based vertex deformation and glossy colour. Does not accumulate a melting process. |
| [Foil](/book-review/commons/resourses/shaders/foil_paper.gdshader) | **Drape / stage candidate.** Perturbs NORMAL and roughness; no vertex function. A crumpled appearance does not make a folded mesh. |
| [Coffee swirl](/book-review/commons/resourses/shaders/coffeeswirl.gdshader) | **Small domestic counterpoint.** Polar-coordinate and sine warps; useful at cup/table scale. Its entropy parameter is an artistic control, not a measured physical entropy. |
| [Animal patterns](/book-review/algorithms/patterngeneration/animalpatterns/animalpatterns.tscn) | **Pattern passage / composition.** Stripes, spots and patterned receivers. Compare mask and palette separately; do not claim biological growth. |
| [Spatial material collection](/book-review/commons/artifacts/shader_arch_gallery/shader_arch_gallery.tscn) | **Abstract staging source.** A spatial composition of pattern/domain choices, useful after one controlled receiver. |
| [Degrading surface](/book-review/algorithms/shaders/degrading_shader/DegradingShaderManager.gd) | **Stateful candidate needing wiring.** A candidate owner for retained marks. Existing demo does not establish that the manager is connected to museum interaction. |
| [Pixelated view](/book-review/commons/resourses/shaders/pp_pixelate_spatial.gdshader) | **Optional backstage viewing booth.** Treat changing the camera image as a different operation from changing an object material. Not a compulsory extra hall. |
| [Sofa prefab](/book-review/commons/primitives/sofa/sofa.tscn) | **Existing furnished receiver.** Inspect UVs, material slots and collider before replacing materials. |
| [Chair prefab](/book-review/commons/primitives/chair/chair_modern.tscn) | **Existing furnished receiver.** A recognizable object supports comparisons between appearance and expected use. |
| [Vase prefab](/book-review/commons/primitives/design_classics/aalto_vase.tscn) | **Existing furnished receiver.** A familiar profile makes changes in surface response legible. |

## Next implementation pass

1. Start Shaping with one complete printed mask and a declared receiver. Preserve useful existing graphs as supporting exhibits.
2. Reconstruct the printed code in a fresh learner fixture. Assert parameter binding and expected samples; verify real rendered output as well as shader compilation.
3. Stage the same rule in its proposed setting. Check entry view, close interaction and side view; provide a nearby control and reset.
4. For the water and material halls, compare fixed geometry, normal response and displacement independently. Test collider/support separately.
5. Capture the real museum; label desktop versus headset evidence accurately. Then revise tutorial.md and final.md around what that encounter actually does.

Only after the water proof and the first lessons should we decide whether optical effects need their own hall. Keep screen effects, elaborate transmission and the wider material catalogue available as optional encounters.

## Compact AI brief

WORLD: existing Endless Museum. DIRECTION: situate shaders in prefab/domestic, abstract, surreal settings; water at room scale. TEACH: one operation + one carried receiver per hall. SECOND RECEIVER: recognizable prop. SHOW: rule → appearance → spatial consequence. SEPARATE: pixel colour / normal / vertex / collider / retained state. KEEP: six-hall order provisional; archive wider than tutorial. SOURCES: Queer 3D 2024, edgeartist, VR_VR_PT_2023 application. VERIFY: actual source, printed-code reconstruction, render, museum path, headset when available. DO NOT: treat shader names as behaviour, pink as a complete queer argument, animated marks as memory, or specimen images as newly built rooms.
