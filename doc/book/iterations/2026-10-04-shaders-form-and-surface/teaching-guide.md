# Shaders: a form acquires a surface

Teaching reference, 4 October 2026. This is a proposed summary-level progression within the existing six halls. It authorizes no new room, lesson implementation or runtime claim. Read alongside `opening.json`, `early.json` and the `shaders` record in `growth.json`.

## Deepen the existing walk

Point and Coordinates gave a place an address; Lines made distance and direction available; Triangle distinguished a boundary from a filled face. Primitives built forms from positions, profiles and supplied geometry. Transformation changed placement, orientation and scale. Array separated an address from its occupant. Colour separated a value from its appearance. Tiling carried a motif through different lookups and receivers. Noise supplied fields with relationships between nearby samples.

Shaders gives these ideas another implementation. It should not reset the learner to an isolated collection of tricks. A drawn mask differs from Triangle’s mesh face, but both ask where an interior begins. Transforming the coordinates used to read a shape differs from transforming its mesh. Repetition can preserve addresses without creating another node at every site.

Ribbon_Patterns_03 already contains a fabric sampler: `commons/artifacts/fabric_shader_studio/fabric.gdshader` repeats and offsets UV coordinates, reads a texture, and offers cut-out and bounded vertex displacement. Its recipe builder is `fabric_recipe.gd`. That encounter exists; a complete learner-written sampler lesson remains proposed. Reuse its ideas without claiming every earlier construction has already been mastered.

## Six hall briefs

### 1. Shader_01_Shaping — one boundary we can change

**Prior:** coordinates, distance, filled faces, profiles and colour mappings. **New:** one circle mask evaluated on a supplied panel, with a named centre, radius and edge width. Compare a hard boundary with a gradual transition while retaining the same underlying distance. Use the graphs to explain that change. **Carry:** one small form function and its chosen parameters.

Keep this first lesson to one main mask. An annular band/ring or a box is an optional variation, not three additional obligations. Sources already include `shapes_circle.gdshader` and `shapes_rect.gdshader` beside the shaping shaders in `algorithms/shaders/book_of_shaders/`; their teaching-panel connection is proposed. Ask: when does a gradual difference become an inside and an outside? A softer visible edge does not automatically grant a body passage.

### 2. Shader_05_Patterns — a form at many addresses

**Prior:** the retained mask, pivoted transforms, Array and the reflected motif. **New:** translate, turn or scale the sampling coordinates around an explicit centre; then separate integer tile address from fractional local position. The first can select an exception; the second draws the form. A marked or asymmetric variation reveals a turn that a circle conceals. **Carry:** a transformable motif and a repeat rule.

`patterns_tile.gdshader` and `patterns_truchet.gdshader` provide existing comparisons. The garden’s `commons/artifacts/reference_studies/pattern.gdshader` instead blends three world-coordinate projections. Replacing its local motif while retaining that supplied projection is a proposed adapter, not direct UV transfer. Ask: what must remain shared, and where can one appearance refuse the repeat?

### 3. Shader_11_QueerRubber — the shape participates

**Prior:** familiar solids, Flashlight’s faceted sphere, flat/curved receivers and dot products. **New:** compare one material across a sphere and cube, then make a rim response from supplied normal and view vectors. Hold material settings while changing the body or viewpoint. **Carry:** a material whose dependence on orientation can be explained.

The existing host displays bodies using `algorithms/shaders/queer_materials/pop_plastic.gdshader` and other materials; a learner comparison material connection remains proposed. Ask what makes a surface read as leather, latex, softness or display. Preserve those associations and pleasures without treating their names as proof of simulated fibres. An apparently stationary surface can conceal a turning sphere.

### 4. Shader_09_FBM — disturb a boundary deliberately

**Prior:** Noise’s sampled fields, weighted sums and the retained mask. **New:** a finite octave loop with separate amplitude and frequency updates. Bound its contribution and use it to perturb the mask’s threshold or coordinate lookup. Compare zero contribution with the chosen disturbance before adding time. **Carry:** a repeatable irregular form with an identifiable rule and range.

`fbm_basic.gdshader` supplies the existing layered field; connecting it to the retained mask is proposed. Keep the basin’s displacement, normals and glass support supplied. Ask which irregularities are welcome, who chose their range, and what the surface can actually support. The water and the glass keep that last question physical.

### 5. Shader_12_PinkExtravaganza — choose a composition

**Prior:** known forms, transformed assemblies, masks, patterned materials and view-dependent colour. **New:** deliberate composition rather than another mandatory mechanism. Choose what to retain from colour, rim and emission beside a supplied deformation; distinguish appearance, moved vertices and whole-object transformation. **Carry:** a material recipe and a reason to keep it.

The host and `commons/artifacts/reference_studies/plural_body.gd` provide existing bodies. A material-composition station is proposed; current controls do not constitute one. Ask who gets to call these defaults excessive. Six limbs, three heads and an unresolved pose extend the question beyond pinkness. A larger menu of parts cannot itself promise a freer life.

### 6. Shader_10_ReactionDiffusion — what must the image retain?

**Prior:** stored arrays, Paint’s preceding image and old/new simulation states. **New:** identify the input a changing image must receive from its previous update, and keep the next output separate. **Carry:** an explicit state-update contract into Cellular Automata.

The host does not bind the `prev_texture` requested by `commons/resourses/shaders/reaction_diffusion.gdshader`. The apparent frost also does not retain growth. Preserve this honest threshold rather than promising evolving chemistry. Ask what history a grown-looking form permits us to infer. A diagram or manual update can establish the missing relation without silently repairing the exhibit.

## Adapter and continuity rules

For Godot 4.6, use a supplied spatial material host: `fragment()` sets `ALBEDO`; mesh `UV` is not screen-space `gl_FragCoord`. State the coordinate source and aspect convention. Normal and view vectors must share a frame before comparison. `EMISSION` does not automatically make a surface illuminate its neighbours. See the official [spatial shader reference](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html).

Retaining a paper recipe, copying a function or manually applying parameters is legitimate continuity. Persistent museum transport is a separate implementation; do not imply it exists. Introduce deferred Shapes and Matrices as bounded returns within Shaping and Patterns. Their full catalogues do not require new halls.

## Focused future prose review

Review, without rewriting finals in this pass: earlier tilings already used image/shader sampling; `patterns_tile.gdshader` explicitly draws a faint border; one sphere mesh does not guarantee seam-free UV mapping. Keep these distinctions separate from a geometric edge. Also align Shaping’s displayed formula with its actual amplitude and phase-speed inputs.

## Compact AI brief and references

Carry one form forward. Name prior, new and carried capability. Supply infrastructure explicitly. Keep comparisons concrete and critical questions local to the encounter. Mark adapters as proposed. Preserve strong poetic passages; do not turn every artwork into an exercise or every limitation into the chapter’s subject.

Patricio Gonzalez Vivo and Jen Lowe’s *The Book of Shaders* is inspiration, not copied lesson text: [03 Uniforms](https://thebookofshaders.com/03/), [05 Shaping](https://thebookofshaders.com/05/), [07 Shapes](https://thebookofshaders.com/07/), [08 Matrices](https://thebookofshaders.com/08/), [09 Patterns](https://thebookofshaders.com/09/), [11 Noise](https://thebookofshaders.com/11/), [13 FBM](https://thebookofshaders.com/13/). Adapt those ideas to the museum’s existing forms and Godot’s material interface.
