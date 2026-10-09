# Stroke geometry

`stroke_geometry.gd` is an independent `RefCounted` utility loaded with `preload`. Its static API is:

- `clean_points(points)` removes non-finite samples and consecutive points less than one micrometre apart.
- `resample(points, spacing = 0.06)` samples a polyline by distance, keeps both endpoints, and permits a shorter final interval. Samples lying exactly at a sharp corner are not forced into the result; use the original polyline when every corner must be preserved.
- `frames(points)` returns one frame per cleaned point: `tangent`, `side`, `normal`, `arc_length`, and normalized distance `u`. The initial side is projected world right, with an alternate axis for nearly parallel paths. Subsequent sides are parallel transported.
- `build_mesh(points, options = {})` creates one indexed `ArrayMesh` surface. Its options are `shape` (`ribbon` or `tube`), `width` (full width or diameter in metres, default `0.25`), `taper` (0–1), `twist` (total radians), `sides` (3–64, default 8), and `caps` (default `true`). Fewer than two valid points produce an empty mesh.

The builder retains input cross sections; resample before building when input event density should not matter. Ribbon UV coordinates span 0–1 across the width and follow normalized arc length along the path. Tube UV coordinates wrap around the cross section, with duplicated seam vertices. Tube caps have their own flat normals. Taper never shrinks below 4% of the base width. Triangle winding follows Godot’s clockwise convention.

An exact reversal has no unique transport rotation. The kernel keeps the previous side and takes the outgoing tangent at that cusp. It removes degenerate triangles; it does not solve self-intersections or make a sharp reversal into a smooth bend. As with any sweep, widths exceeding a curve’s bend radius can overlap.

Run the native checks with `godot --headless --path . --script res://geometry_verify.gd -- geometry-verification.json`. The script verifies packed vertex/index/normal/UV arrays, transported frames, distance resampling, taper, twist, duplicate samples, reversals, radial tube normals, closed seams, cap orientation, and a spatial tube’s welded topology. It exits with code 0 on success and 1 on failed checks (2 if the JSON report cannot be written).
