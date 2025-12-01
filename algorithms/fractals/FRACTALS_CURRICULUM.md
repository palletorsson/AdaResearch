# The Fractals Curriculum
## A Comprehensive Ground-Up Presentation Plan

This document outlines a structured progression for presenting **ALL** material in `algorithms/fractals`. It organizes the examples into a coherent 5-Map journey, from simple recursion to complex organic and mathematical forms.

---

### 🪞 Map 1: The Mirror (Recursion Basics)
**Theme:** Self-similarity. A shape that contains itself.
**Environment:** Hall of Mirrors / Infinite Void.

1.  **The Loop (Basics)**
    *   `example_8_1_recursion_vr.tscn`: Visualizing the call stack.
    *   `example_8_2_recursion_vr.tscn`: Recursive rotation.
    *   `example_8_3_recursion_circles_vr.tscn`: Circles inside circles.
2.  **The Set (Cantor)**
    *   `cantorset`: The simplest fractal (removing the middle third).
    *   `example_8_4_cantor_set_vr.tscn`: 3D visualization of Cantor dust.
3.  **The Triangle (Sierpinski)**
    *   `sierpinskitriangle` / `sierpinski_pyramid`: 2D and 3D variations.

---

### ❄️ Map 2: The Snowflake (L-Systems & Grammar)
**Theme:** Rewriting rules to create complexity. (See also: `algorithms/l_systems`)
**Environment:** Frozen Tundra / Drafting Room.

1.  **The Grammar (String Rewriting)**
    *   `example_8_8_lsystem_string_only_vr.tscn`: Visualizing the text generation ("A" -> "ABA").
2.  **The Curve (Koch)**
    *   `koch_curve` / `koshcurve` / `koch_curve_1`: The classic infinite coastline.
    *   `example_8_5_koch_curve_vr.tscn`: 3D interpretation.
3.  **The Tree (Branching)**
    *   `recursive_tree` / `recursivetree`: Simple Y-branching.
    *   `example_8_6_recursive_tree_vr.tscn`: 3D Fractal Tree.
    *   `example_8_9_lsystem_tree_vr.tscn`: L-System generated tree.
4.  **The Variation (Stochastic)**
    *   `example_8_7_stochastic_tree_vr.tscn`: Adding randomness to the rules.

---

### 🧽 Map 3: The Sponge (Volume & Space)
**Theme:** Fractals that fill (or empty) 3D space.
**Environment:** Alien Ruins / Swiss Cheese Planet.

1.  **The Box (Subdivision)**
    *   `cubesubdivision`: Splitting cubes into smaller cubes.
2.  **The Sponge (Menger)**
    *   `mengersponge`: The 3D equivalent of the Sierpinski carpet. Infinite surface area, zero volume.
3.  **The Mesh (Geometry)**
    *   `meshfractal`: Applying fractal noise/displacement to meshes.

---

### 🌀 Map 4: The Spiral (Nature & Fibonacci)
**Theme:** The Golden Ratio and organic growth.
**Environment:** Garden / Nautilus Shell.

1.  **The Sequence (Fibonacci)**
    *   `fibonacci_sequences`: Visualizing the 1, 1, 2, 3, 5... pattern.
2.  **The Vegetable (Romanesco)**
    *   `romanesco`: The famous fractal broccoli. Self-similar cones.

---

### 🌌 Map 5: The Set (Complex Numbers)
**Theme:** The edge of chaos. Iterating functions on the complex plane.
**Environment:** Psychedelic Void / Mathscape.

1.  **The Mandelbrot (The Map)**
    *   `mandelbrot_set`: The set of all connected Julia sets.
2.  **The Julia (The Island)**
    *   `julia_set`: Variations based on the seed point.

---

### 📝 Implementation Strategy
*   **Consolidation:** We have L-System examples here (`example_8_8`, `example_8_9`) and a new empty folder `algorithms/l_systems`. We should decide whether to move them to the new folder or keep them here as "Fractal Applications".
    *   *Recommendation:* Keep specific fractal curves (Koch, Sierpinski) here. Move generic L-System engines and biological trees to `algorithms/l_systems`.
*   **Hub World:** A "Museum of Infinity" connecting these 5 Maps.
