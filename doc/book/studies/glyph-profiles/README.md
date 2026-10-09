# A letter becomes a body

4 October 2026. A small Godot 4.6 geometry experiment accompanying Ada's investigation of alternative forms. This is a desktop orbit study, not a new museum placement or a rewritten tutorial.

Open `project.godot` and run. Drag with the left mouse button to orbit; use the wheel to move nearer or farther. Five specimens share one font:

1. B as an ordinary extruded letter.
2. B widened and sheared in its two-dimensional face before extrusion.
3. O as a deep passage, with its hole retained.
4. An asterisk extruded upward as a column.
5. An ampersand extruded through 24 progressively rotated sections.

`study.gd` creates the objects directly. `glyph_solid.gd` uses a flat TextMesh to obtain a triangulated face, welds matching positions, identifies the boundary edges, changes the planar positions, then constructs front, back and side faces. The font file is unchanged. The twist varies the cross-section's rotation along depth; it requires extra sections, not just a rotation of the whole object.

This shortcut borrows Godot's existing triangulation. Its scope is the tested glyphs and modest deformations that do not fold the face. Arbitrary editing, merging holes, self-intersection or morphing between different glyph topologies requires a more general contour and triangulation system. The scene adds no player, grabbability or automatic collision for the sculptures. A separate native check creates a temporary collision shape to verify the O opening and rim.

## Font evidence

The visible study uses Ada's JetBrains Mono Medium. Its separate OFL notice is included. The unchanged Roboto Regular file and its own OFL notice are retained as a diagnostic sample: that font's ampersand failed the tested TextMesh triangulation, while JetBrains Mono succeeded. A lower-resolution Roboto test also produced unsuitable geometry. These observations are specific to these files and settings.

The native verifier additionally loaded the locally installed Segoe UI Symbol and successfully extruded U+2605 BLACK STAR. That font is not in the download; the separate symbol screenshot records the test. The installed Wingdings file reported an empty supported-character list through Godot, so its replacement rectangle was rejected as evidence. This is not a claim that every Wingdings version or every dingbat font fails.

## Where to intervene

- `TextMesh`: choose the font/glyph, sampling and extrusion depth.
- Flat generated face: change existing vertices, preserving its triangulation when valid. This is the route demonstrated here.
- Raw glyph contours: use TextServer's `font_get_glyph_contours` to obtain line and Bézier data, then supply curve sampling, hole-aware triangulation and extrusion yourself.
- Finished mesh: deform the resulting surface; rebuild normals and collision when needed. A vertex shader changes appearance without automatically moving physics collision.

The raw contour API stores the control-point type in the third component of each Vector3. That component is a tag, not spatial depth. The engine also distinguishes characters from glyphs; words and complex scripts require shaping, not a naive one-character/one-glyph assumption.

Godot's `TubeTrailMesh` has a different input: a radius curve along its length. It does not accept the same compound two-dimensional outlines as a font. Both systems generate bodies from profiles, but their inputs are not interchangeable.

## References and validation

- [Godot 4.6 TextMesh](https://docs.godotengine.org/en/4.6/classes/class_textmesh.html)
- [TextServer contour API](https://docs.godotengine.org/en/4.6/classes/class_textserver.html#class-textserver-method-font-get-glyph-contours)
- [TextMesh implementation](https://github.com/godotengine/godot/blob/4.6/scene/resources/3d/primitive_meshes.cpp)
- [TubeTrailMesh](https://docs.godotengine.org/en/4.6/classes/class_tubetrailmesh.html)

The review folder `../../iterations/2026-10-04-glyphs-as-profiles/` contains the verifier, native screenshots and results. Checks cover closed edge topology, finite normals, preserved B triangulation, O contours and through-hole collision, and a real symbol glyph. These checks do not certify arbitrary deformations, all fonts, physical headset use or VR performance.
