# VFM 01 Foundations — Artifacts
*Vectors & Forces: From Direction to Dynamics · oscillation · 20 artifacts*

> The museum's front door: what a vector actually is.

The map, read through what it holds — its artifacts in the order you meet them:

## CoordinateSystem3M
![CoordinateSystem3M](/scene-catalog/CoordinateSystem3M.png)

FEEL orientation as embodied direction by standing inside the coordinate frame

`CoordinateSystem3M`

## Vector Subtraction
![Vector Subtraction](/scene-catalog/vector_subtraction_demo.png)

Interactive vector subtraction: A - B = C. Shows how subtraction finds the difference vector between two points.

`vector_subtraction_demo`

## Vector Addition (Walk-Inside)
![Vector Addition (Walk-Inside)](/scene-catalog/vector_addition_xl.png)

WALK between two force arrows and feel their sum reach across the room as the green diagonal of an invisible parallelogram

`vector_addition_xl`

## Vector Subtraction (a − b, two-pad console)
![Vector Subtraction (a − b, two-pad console)](/scene-catalog/vector_sub.png)

Vector subtraction made playable - the same two-pad ToyConsole as vector_add, flipped to a - b = a + (-b). Two 2D pads place the tips of a and b; the demo draws a, then the negated b head-to-tail, and the resultant a-b, with a faint ghost of the original +b so the flip reads as the whole idea. The monitor shows a, b, a-b, |a-b| and the angle. The control IS the vector tip; seed sets the starting a and b.

`vector_sub`

## Vector Addition (a + b, two-pad console)
![Vector Addition (a + b, two-pad console)](/scene-catalog/vector_add.png)

Vector addition made playable - the entry operation of the embodied vectors-forces arc, a ToyConsole with a TWO-PAD control surface (synthesised from three interaction-design passes). Two 2D pads on the front lip, one per vector: drag a pad and that vector's tip follows your hand (a grabbed handle in VR, a pointer-drag on desktop). The two arrows draw head-to-tail on the console top and the resultant a+b swings live; the monitor shows the full component breakdown (a, b, a+b, |a+b|, angle). The control IS the vector tip. seed sets the starting a and b.

`vector_add`

## VectorBasics
![VectorBasics](/scene-catalog/VectorBasics.png)

UNDERSTAND that a vector is not a number and not a point — it is a displacement carrying both how far and which way

`VectorBasics`

## Basis Vectors Rig
![Basis Vectors Rig](/scene-catalog/basis_vectors_rig.png)

Interactive basis vectors (î, ĵ, k̂) showing how any 3D point is a linear combination: P = xî + yĵ + zk̂.

`basis_vectors_rig`

## Vector Magnitude
![Vector Magnitude](/scene-catalog/vector_magnitude_demo.png)

Visualizes vector magnitude (length) using Pythagorean theorem. Shows |V| = √(x² + y² + z²).

`vector_magnitude_demo`

## Vector Normalization
![Vector Normalization](/scene-catalog/vector_normalize_demo.png)

Shows normalization: V̂ = V/|V|. Converts any vector to unit length while preserving direction.

`vector_normalize_demo`

## Vector Translation
![Vector Translation](/scene-catalog/vector_translation_demo.png)

Shows vectors as displacements in space. Position vectors and translation vectors.

`vector_translation_demo`

## Vector Multiplication VR
![Vector Multiplication VR](/scene-catalog/example_1_4_vector_multiplication_vr.png)

Vector multiplication demonstration

`example_1_4_vector_multiplication_vr`

## 2d_in_3d_vectors_vis
![2d_in_3d_vectors_vis](/scene-catalog/2d_in_3d_vectors_vis.png)

2d_in_3d_vectors_vis

`2d_in_3d_vectors_vis`

## Script Runner
![Script Runner](/scene-catalog/script_runner.png)

Live code display with real Expression evaluation! Shows code executing line-by-line with actual results. Scripts: #point, #vector_math, #array, #pattern, #loop. Example: script_runner#point:90:1

`script_runner`

## Coordinate System Switcher
![Coordinate System Switcher](/scene-catalog/coordinate_system_switcher.png)

Shows the same 3D point in Cartesian (x,y,z), Cylindrical (r,θ,z), and Spherical (ρ,θ,φ) coordinates simultaneously. ImmediateMesh axes and arcs with projection lines showing how each system maps. Color-coded: Cartesian=RGB, Cylindrical=yellow, Spherical=magenta.

`coordinate_system_switcher`

## The Adder's Drafting Board
![The Adder's Drafting Board](/scene-catalog/adder_board.png)

Dark slate pedestal with a brass rim and a black drafting slab tilted ~20deg toward the player, etched with an integer lattice and a glowing origin pin. Two grabbable GrabSphere tip-pucks set a (amber) and b (orange); emissive catapult-style arrows redraw the tip-to-tail chain + the cyan-violet resultant + dashed parallelogram ghosts every frame. Two precision sliders set |a|,|b| to clean integers; a push-button toggles chain-glow vs parallelogram-glow. Live two-column formula plate + billboarded readouts including the triangle-inequality |a+b| <= |a|+|b| with a brass equality needle. DNA: a_start, b_start, snap_to_grid, pedestal_height.

`adder_board`

## Length Lantern
![Length Lantern](/scene-catalog/length_lantern.png)

Dark slate pedestal + brass rim + etched integer ground lattice on a 0.6 m bench plate. One grabbable amber vector whose GrabSphere2 tip carries a glass lantern bead; pulling it redraws the faint x,y,z component legs, the explicit Pythagoras box, the floor diagonal sqrt(x^2+z^2), live numbers (components, squares, running sum, |v|), the lantern glow, and a vertical magnitude ruler. x/y/z precision sliders + a SNAP button trigger a 1.2 s eased two-stage resolve animation that makes sqrt-inside-sqrt temporally legible. DNA: reach, max_magnitude, degenerate_threshold, show_sliders, arrow_thickness.

`length_lantern`

## Stretch Bench
![Stretch Bench](/scene-catalog/stretch_bench.png)

Dark slate pedestal + brass rim + graduated rail (the number line for k). A grabbable brass crank slides along the rail to set k in [-3,+3]; the amber base vector v is grabbable (re-aim the reference line), the derived twin k*v snaps to it and is never grabbable — cyan-violet when k>=0, red when k<0, a glowing dot at k=0. Etched integer ground-lattice (-3v..3v), a bead + brass 'k' dial needle, live k*v and |k||v| readout, SNAP integer-lock button, and a slider_horizontal desktop fallback. DNA: default_k, min_k, max_k, base_vector.

`stretch_bench`

## Newton's Laws
![Newton's Laws](/scene-catalog/newtons_laws.png)

Interactive visualization of Newton's three laws of motion: inertia (an object at rest stays at rest), F=ma (force produces acceleration proportional to mass), and action-reaction (every force has an equal opposite). Objects of varying mass respond to applied forces, making the relationship between force, mass, and acceleration viscerally tangible.

`newtons_laws`

## Forces (2.1)
![Forces (2.1)](/scene-catalog/example_2_1_forces_vr.png)

Force application demo — applying a force vector to a body and watching F=ma unfold. Nature of Code chapter 2.1.

`example_2_1_forces_vr`

## Graphics Monitor
![Graphics Monitor](/scene-catalog/graphics_monitor.png)

3D monitor with frame displaying visualization graphics. Use #vectors, #forces, #arrays, #waves, #randomness, or #procedural

`graphics_monitor`
