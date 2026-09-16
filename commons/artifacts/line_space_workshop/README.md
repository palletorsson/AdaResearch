# Line Space Workshop

Four live filmed studies in Point_Lines. Only the framed monitors, count labels and floor marking appear in the hall. Source geometry is calculated and animated in a private World3D; the visitor cannot see or grab it directly. The encounter asks what a flat image can establish about a spatial arrangement.

1. Two: parallel, plus, X, skew, rails, drawing. Two fixed 0.8 m segments.
2. Three: triangle, opened join, displaced edge. Three fixed 0.6 m segments.
3. Four: square, nonplanar folded loop, grid. Four fixed 0.6 m segments.
4. More: six-line grid, lifted grid, tetrahedron, twelve-edge cube. Fixed 0.6 m segments; count changes at the cube.

Each arrangement holds for six seconds, then moves for five seconds. Rigid transforms preserve lengths; folding around the square diagonal preserves all four joins. Extra cube edges fade in at full length. No buttons, grab targets or invisible colliders remain in the source geometry.

## Filming and display

`line_space_workshop.gd` owns the geometry and automatic cycles. It creates a disabled-render SubViewport with its own World3D and puts the source rods under its FilmSet. `workshop_rod.gd` is a visual Node3D with no physics body. Four camera viewports share only this private world. Their images are textured onto monitors in the museum world. This avoids changing player camera masks, source shadows in the museum, or cross-talk between copies of the exhibit.

`camera_study.gd` builds 0.80 × 0.60 m monitors, centered at 1.25 m and tilted upward by 18 degrees, with counts above the casings. The first camera is frontal and orthographic; three and more have fixed oblique perspective views. Four has a slow ±35 degree orbit over 36 seconds. A visitor moving beside the monitor sees the monitor obliquely, without changing the filming camera's viewpoint.

`study_filter.gdshader` implements monochrome, ink threshold, image contours and tinted scan lines. These image treatments do not change geometry or measure depth, normals or topology. Layers 17–20 isolate the line sets within the private world. Each feed is 384 × 288, with at most twelve updates/second while its monitor is visible.

The hall placement remains (16,16), facing 180 degrees. The 3.8 × 2.3 m floor marking is visual. The book anchor is `<!-- @line_space_workshop -->` in Point_Lines/final.md; the saved encounter is `combine`. Other grabbable lines elsewhere in the hall remain available as a different encounter.

## Verification

`ada_run/line_workshop_check.tscn`: automatic sequence, length preservation, continuous closed fold and fading additions; no invisible physics targets.

`ada_run/line_camera_check.tscn`: real rendered feeds in the private source world, source absence from the museum even with all camera layers enabled, camera isolation, live animation-driven image changes, orbit, and off-screen render suppression.

`ada_run/line_workshop_museum_check.tscn`: actual endless museum capture. Headset comfort and device performance remain unverified.

`python -X utf8 ada_run/research_line_counts.py`: 29 bounded geometric cases exported from production code. Measures endpoint joins and affine dimension, not collision clearance, solid interiors or aesthetic quality. Historical evidence for the earlier grabbable version is retained in the iteration snapshots.
