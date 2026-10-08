# Triangle construction plate

A static native Godot schematic: the same positions become a boundary, then a filled face. Reference for `Point_Triangle_Context`, supporting the hands-on puzzle and drawing tool.

The scene contains real meshes and labels. `show_mount` hides only the feet/posts when rendering the book. The canonical vertex positions match the triangle-line puzzle; they are uniformly enlarged for legibility. The scene and materials are shared between the book capture and museum instance.

Run `python tools/capture_triangle_plate.py` to regenerate `doc/book/iterations/2026-09-23-triangle-illustration/figures/triangle-construction.png`, the spatial reference, geometry checks and source provenance. The capture uses an isolated temporary project with exact source copies, avoiding project autoloads. The book's `final.md` links the resulting image through `/book-review/`.

Museum placement: cell (9,5), facing +Z, panel centre 1.7 m above the floor. Overall frame approximately 4.245 m wide; fonts do not billboard. Static reference, no controls or collision blocks. Geometry and image checks pass; headset reading remains to test.
