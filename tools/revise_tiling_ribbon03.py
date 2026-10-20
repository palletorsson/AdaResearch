"""Write the reduced shader lesson within the supplied museum studio."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/Ribbon_Patterns_03'
O=R/'doc/book/iterations/2026-10-09-tiling-revision/Ribbon_Patterns_03';S=R/'doc/book/studies/tiling-lineage'
def block(n,lang):return f'<!-- student-code:{n} -->\n```{lang}\n{(S/n).read_text(encoding="utf8").rstrip()}\n```\n'
t='''# Ribbon Patterns 03 — a source reaches a skirt

## Learning elements

- Reading a texture with the surface's UV coordinates.
- Separating repeat count from address offset.
- Supplying a shader with a texture and named parameters.
- Distinguishing a saved recipe from the program that interprets it.

## Begin at the studio

Find the source editor beside the wall and preview dress. Choose a paint colour and touch one source cell. The mark changes on both receivers. UNDO restores it. Try OFFSET, then REPEAT. The first shifts the reading; the second changes how many copies fit.

Earlier we changed how the source was read by cubes. Here the reading happens for each drawn fragment of a surface. The studio supplies a four-by-four source and its cream, red, blue and gold palette. This is its existing bent mark, not an automatic import of our earlier two-by-three source. We carry the address operation into this larger supplied example.

Keep the wall, dress, source editor and pointer controls. They already exist inside the museum. Our task is one small shader. Cut-outs, finishes and vertex movement remain experiments in the full studio; they are not requirements for this first shader.

## The supplied host

Work in your lesson copy of the museum. Open `commons/artifacts/fabric_shader_studio/fabric_shader_studio.tscn`. Its root, **FabricShaderStudio**, already has the script that creates the wall, preview, sixteen source buttons and controls. Add a plain Node child named **Lesson** and attach **09_studio_lesson.gd** below. Keep **09_fabric_sample.gdshader** beside that script. Run the same museum hall. Remove the Lesson child and reload to return to the full studio.

For reconstruction, **09_studio_lesson.tscn** below contains that complete root-and-child arrangement. Our test uses it in place of the one studio instance inside an isolated copy of the actual hall. The museum still supplies the player, camera, wardrobe and runway. No replacement world or player is constructed.

The existing `fabric_recipe.gd` converts sixteen palette indices into a four-by-four texture. Its `material()` function assigns that texture to `motif`, the chosen repeat count to `repeats`, and the offset to `phase`. The studio's `refresh()` gives materials made from that recipe to the wall and the preview's named **Skirt** mesh. These are supplied services. They do not hide any part of our address calculation.

### 09_fabric_sample.gdshader

'''+block('09_fabric_sample.gdshader','glsl')+'''
`UV` is a two-component address supplied by the mesh, conventionally spanning zero to one across a mapped region. `UV.x` and `UV.y` are surface coordinates, not world x and y. The wall and skirt each provide their own layout.

`vec2(repeats, 2.0)` multiplies the horizontal address by the chosen count and the vertical address by two. Adding `vec2(phase, 0.0)` offsets only the horizontal reading. `repeat_enable` wraps the texture address; `filter_nearest` selects source texels without blending neighbours. `source_color` identifies the sampled texture as colour data. The returned RGB goes to `ALBEDO`.

This reduced shader is unshaded so we can follow the sampling without the full studio's lighting response. It has no cut-out or displacement. The sampler still runs for many fragments; the source remains sixteen texels. A texel, a fragment and a mesh vertex are different things.

### 09_studio_lesson.gd

The small supplied adapter below replaces the shader on the two preview materials. It waits for the parent studio to create them. Every edit makes fresh materials, so it also reconnects our shader after an edit. The named `Skirt` is the actual receiver in the existing preview, not an unexplained scene dependency. Other parts of the outfit keep their materials.

'''+block('09_studio_lesson.gd','gdscript')+'''
### 09_studio_lesson.tscn

This is the supplied studio root with the Lesson child added. Keep the three lesson files together if using this ready-made scene. The existing studio script path is the explicit dependency on the museum project.

'''+block('09_studio_lesson.tscn','ini')+'''
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

At `UV = (0.15, 0.20)`, four repeats and phase zero now read texture address `(0.60, 0.60)`: source column 2, row 2, value 3, gold. Check a region away from a texel boundary. The full program is printed; this is your independent edit of its operation.

Now SAVE and WEAR SAVED. The preview can show your three vertical repeats, but the worn skirt is built by the original wardrobe shader, whose vertical count is still two. SAVE stores the supported recipe: source cells, horizontal repeats 4 or 8, offset 0 or 0.125, and the existing display flags. It does **not** store our shader text, its vertical multiplier, the palette, meshes or the current LOOK choice.

This difference is useful evidence. Saving data does not save every program capable of interpreting it. To make vertical count travel, the recipe schema, validation and receiving shader would all need to accept it. That extension is a later decision, not an invisible service this tutorial assumes.

## What travels

Restore the vertical multiplier and return to the original studio. Save a source, choose a preview silhouette with LOOK, then WEAR SAVED. The current preview look is chosen separately when wearing; it was not stored by SAVE. The saved fabric goes to the named Skirt. The bodice, crown and sleeves retain the look's materials.

Edit the preview after saving. The worn skirt keeps the saved version. RUNWAY SAVED gives that version to four performer skirts. UNDO can restore a prior application, but does not rewind the saved file. Use the mirror and procession as comparisons of the same record on different bodies.

Tiling has followed a value into a source, a repeated reading, a surface, a volume and a garment. Keep those distinctions when the picture changes. In Change Intro, we return to comparing readings at different positions, this time to ask how much a value changes between them.
'''
(M/'tutorial.md').write_text(t,encoding='utf8')
f=(O/'before/final.md').read_text(encoding='utf8')
import re
f=re.sub(r'```glsl\n.*?\n```\n\n','',f,flags=re.S)
f=f.replace('`UV` supplies an address from the mesh; multiplication repeats it, addition shifts it, and the texture wraps.','The mesh supplies a surface address; multiplication repeats it, addition shifts it, and the texture wraps.')
f=f.replace('Here `discard` stops drawing a fragment.','Here the shader stops drawing selected fragments.')
f=f.replace('The shader moves rendered vertices along their normals, by at most 0.04 local units.','The shader moves rendered vertices along their normals, by at most 0.04 local units.')
(M/'final.md').write_text(f,encoding='utf8')
# The old technical placement paragraph predates the compact map; only correct those coordinates.
tech=(O/'before/technical.md').read_text(encoding='utf8')
tech=tech.replace('`fabric_shader_studio` (22,26), `super_drag_mirror` (31,27), `drag_catwalk` (58,24).','`fabric_shader_studio` (6,5), `super_drag_mirror` (12,7), `drag_catwalk` (23,3), in the current compact map.')
tech=tech.replace('RotatingLaser moves from (58,39) to (58,50),','RotatingLaser is at (23,24),')
(M/'technical.md').write_text(tech,encoding='utf8')
(O/'spec-student.json').write_text(json.dumps({'lesson':'res://'+O.relative_to(R).as_posix()+'/learner/printed/09_studio_lesson.tscn'},indent=2))
print('Ribbon03 shader lesson written in supplied studio host.')
