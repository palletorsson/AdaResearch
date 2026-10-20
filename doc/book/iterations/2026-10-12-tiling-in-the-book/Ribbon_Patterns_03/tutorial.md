# Ribbon Patterns 03 — a source reaches a skirt

## Learning elements

- UV repeat and offset in a fragment shader.
- Texture sampling onto differently mapped surfaces.
- A saved recipe versus its shader interpreter.

The address calculation returns in a new place: the fragment shader. Keep the studio as the supplied host. A garment and procession make the result available to wear and compare; saved settings and the program interpreting them remain separate.

## Begin at the studio

Find the source editor beside the wall and preview dress. Choose a paint colour and touch one source cell. The mark changes on both receivers. UNDO restores it. Try OFFSET, then REPEAT. The first shifts the reading; the second changes how many copies fit.

Earlier we changed how the source was read by cubes. Here the reading happens for each drawn fragment of a surface. The studio supplies a four-by-four source and its cream, red, blue and gold palette. This is its existing bent mark, not an automatic import of our earlier two-by-three source. We carry the address operation into this larger supplied example.

Keep the wall, dress, source editor and pointer controls. They already exist inside the museum. Our task is one small shader. Cut-outs, finishes and vertex movement remain experiments in the full studio; they are not requirements for this first shader.

## Your part in this lesson

- **Write and change:** the small shader below. Follow a surface address through repeat, offset and texture sampling; then change the vertical repeat from two to three.
- **Use as supplied:** the studio, mesh UV layouts, material adapter, save system and wardrobe. Their connections are declared below; building them is not this lesson's task.
- **Check your understanding:** predict a sampled colour and the spacing on the wall before running. Explain why saving the source does not transfer your changed shader to the worn skirt.

## The supplied host

Work in your lesson copy of the museum. Open `commons/artifacts/fabric_shader_studio/fabric_shader_studio.tscn`. Its root, **FabricShaderStudio**, already has the script that creates the wall, preview, sixteen source buttons and controls. Add a plain Node child named **Lesson** and attach **09_studio_lesson.gd** below. Keep **09_fabric_sample.gdshader** beside that script. Run the same museum hall. Remove the Lesson child and reload to return to the full studio.

For reconstruction, **09_studio_lesson.tscn** below contains that complete root-and-child arrangement. Our test uses it in place of the one studio instance inside an isolated copy of the actual hall. The museum still supplies the player, camera, wardrobe and runway. No replacement world or player is constructed.

The existing `fabric_recipe.gd` converts sixteen palette indices into a four-by-four texture. Its `material()` function assigns that texture to `motif`, the chosen repeat count to `repeats`, and the offset to `phase`. The studio's `refresh()` gives materials made from that recipe to the wall and the preview's named **Skirt** mesh. These are supplied services. They do not hide any part of our address calculation.

### 09_fabric_sample.gdshader

<!-- student-code:09_fabric_sample.gdshader -->
```glsl
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D motif : source_color, filter_nearest, repeat_enable;
uniform float repeats = 4.0;
uniform float phase = 0.0;

void fragment() {
    vec2 address = UV * vec2(repeats, 2.0) + vec2(phase, 0.0);
    ALBEDO = texture(motif, address).rgb;
}
```

`UV` is a two-component address supplied by the mesh, conventionally spanning zero to one across a mapped region. `UV.x` and `UV.y` are surface coordinates, not world x and y. The wall and skirt each provide their own layout.

`vec2(repeats, 2.0)` multiplies the horizontal address by the chosen count and the vertical address by two. Adding `vec2(phase, 0.0)` offsets only the horizontal reading. `repeat_enable` wraps the texture address; `filter_nearest` selects source texels without blending neighbours. `source_color` identifies the sampled texture as colour data. The returned RGB goes to `ALBEDO`.

This reduced shader is unshaded so we can follow the sampling without the full studio's lighting response. It has no cut-out or displacement. The sampler still runs for many fragments; the source remains sixteen texels. A texel, a fragment and a mesh vertex are different things.

### 09_studio_lesson.gd

The small supplied adapter below replaces the shader on the two preview materials. It waits for the parent studio to create them. Every edit makes fresh materials, so it also reconnects our shader after an edit. The named `Skirt` is the actual receiver in the existing preview, not an unexplained scene dependency. Other parts of the outfit keep their materials.

<!-- student-code:09_studio_lesson.gd -->
```gdscript
extends Node

const SAMPLE = preload("09_fabric_sample.gdshader")

func _process(_delta: float) -> void:
    var studio = get_parent() # The supplied FabricShaderStudio root.
    if not is_instance_valid(studio.wall) or not is_instance_valid(studio.preview):
        return
    var skirt: MeshInstance3D = studio.preview.outfit.get_node("Skirt")
    for surface in [studio.wall, skirt]:
        var material: ShaderMaterial = surface.material_override
        if material.shader != SAMPLE:
            material.shader = SAMPLE
    studio.code.text = "STUDY: UV -> repeat + offset -> sample\nUse PAINT / OFFSET / REPEAT\nFull shader features wait in the original studio"
```

### 09_studio_lesson.tscn

This is the supplied studio root with the Lesson child added. Keep the three lesson files together if using this ready-made scene. The existing studio script path is the explicit dependency on the museum project.

<!-- student-code:09_studio_lesson.tscn -->
```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://commons/artifacts/fabric_shader_studio/fabric_shader_studio.gd" id="1"]
[ext_resource type="Script" path="09_studio_lesson.gd" id="2"]

[node name="FabricShaderStudio" type="Node3D"]
script = ExtResource("1")

[node name="Lesson" type="Node" parent="."]
script = ExtResource("2")
```

During the reduced study, use the paint cells, OFFSET, REPEAT and UNDO. UV / FABRIC, CUT OUT, FINISH and VERTICES belong to the full shader and will not alter this reduced preview. Return to the original studio to investigate them. SAVE and WEAR still use the existing recipe system; they do not install our new shader on the wearer.

## Read one address

Before painting, consider `UV = (0.15, 0.20)` on the initial mark. At four horizontal repeats and phase zero, the texture address is `(0.60, 0.40)`. In the four-by-four source this reads column 2, row 1: value 0, cream.

Press OFFSET. Its phase is 0.125, so the address becomes `(0.725, 0.40)`. This still reads column 2, row 1. Not every offset changes every sampled colour. At `UV = (0.22, 0.20)`, however, the horizontal address goes from 0.88 to 1.005. Wrapping gives 0.005: column 0 instead of column 3. On row 1 that changes cream to red.

Press OFFSET again to return to zero, then REPEAT. Eight repeats give `(1.20, 0.40)` at the first UV; wrapping reads column 0, row 1, red. Repeat and offset can both change a sample, but they do different work.

An offset of 0.125 is one eighth of the texture's width, not one eighth of the wall. At four repeats it moves the pattern by one thirty-second of the wall's UV width. At eight repeats the same phase moves it by one sixty-fourth. Positive phase moves the visible motif towards decreasing U because each fixed surface position reads farther into the source.

## Count along a surface

The wall is three metres wide. Four horizontal copies span 0.75 metres each; eight span 0.375 metres. On its two-metre height, two copies span one metre each. These distances apply to this wall's mapping.

The skirt receives the same repeat counts on its own UV domain. Its circumference, height and cap mapping differ. Equal UV counts do not promise equal physical spacing. The last hall let us compare equal surface widths; here we deliberately meet different ones.

## Make a change the saved recipe cannot contain

Change only the vertical multiplier from `2.0` to `3.0` in the shader. Predict: the wall now has three copies over two metres, each two thirds of a metre high. Its horizontal count and phase controls should work as before. Neither the source texture nor the mesh changes.

At `UV = (0.15, 0.20)`, four repeats and phase zero now read texture address `(0.60, 0.60)`: source column 2, row 2, value 3, gold. Check a region away from a texel boundary. This guided change checks the address calculation. Then choose another positive vertical repeat count yourself. Predict the spacing on the wall and the colour at a UV address away from a texel boundary before running. Explain which values changed and which stayed fixed.

Now SAVE and WEAR SAVED. The preview can show your three vertical repeats, but the worn skirt is built by the original wardrobe shader, whose vertical count is still two. SAVE stores the supported recipe: source cells, horizontal repeats 4 or 8, offset 0 or 0.125, and the existing display flags. It does **not** store our shader text, its vertical multiplier, the palette, meshes or the current LOOK choice.

This difference is useful evidence. Saving data does not save every program capable of interpreting it. To make vertical count travel, the recipe schema, validation and receiving shader would all need to accept it. That extension is a later decision, not an invisible service this tutorial assumes.

## Optional: cut the cloth you kept

Beside the studio, **LOAD LOOM** reads the sample you saved with SAVE CLOTH in Symmetry Seventeen. Without a saved sample, the cutting table supplies tartan. **CLOTH** cycles supplied tartan, houndstooth and optical checks. Choose **SUIT**, **A-LINE**, **GOWN** or **PLEATED** on the front row. The figure previews the shape immediately; the cloth stays the same. Inspect the ten labelled pieces: four bodice panels, two sleeves and four skirt panels for a dress, or jacket, sleeves and trousers for the suit. Changing cloth or shape starts a fresh layout.

Press **CUT**. The arm follows each outline, then removes the surrounding cloth from the display. Press **ASSEMBLE** to watch the pieces travel onto the fitting figure. Their surface addresses stay attached while the panels curve. **PAUSE** stops either operation; **RESET** returns the same cloth and shape to the layout. Once fitted, **WEAR** applies the garment to your museum avatar. Look down or use the mirror. **TAKE OFF** restores the outfit you wore before using the table, including its cloth and shape.

Predict what survives a later edit: change the table's cloth or shape after wearing. Your worn garment keeps both choices. Its appearance is saved with the wardrobe and returns when you reopen the museum. Loading another loom sample changes the table, not the garment already worn.

This supplied station extends the material encounter; the shader program above remains the coding lesson. The model curves ten panels into a prescribed silhouette and maps the recorded weave onto them. It does not solve seams, fabric tension or fit for different body measurements. Sleeves follow the hands; torso and legs use the museum's inferred body. The earlier shader studio's SAVE/WEAR SAVED controls still target its separate skirt recipe.

## What travels

Restore the vertical multiplier and return to the original studio. Save a source, choose a preview silhouette with LOOK, then WEAR SAVED. The current preview look is chosen separately when wearing; it was not stored by SAVE. The saved fabric goes to the named Skirt. The bodice, crown and sleeves retain the look's materials.

Edit the preview after saving. The worn skirt keeps the saved version. RUNWAY SAVED gives that version to four performer skirts. UNDO can restore a prior application, but does not rewind the saved file. Use the mirror and procession as comparisons of the same record on different bodies.

Across Tiling we have reused classes and reading operations, with declared sources for each study. We have not automatically saved one edited motif through every hall. The volume was a branch; the garment returns to surface sampling. Keep those distinctions when the picture changes. In Change Intro, we return to comparing readings at different positions, this time to ask how much a value changes between them.
