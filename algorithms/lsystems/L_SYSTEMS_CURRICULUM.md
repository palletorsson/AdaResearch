# The L-Systems Curriculum
## A Comprehensive Ground-Up Presentation Plan

This document outlines the roadmap for the `algorithms/l_systems` module, integrating existing theoretical maps with planned visual demonstrations.

---

### 📜 Map 1: The Grammar (Theory & Logic)
**Theme:** The language of structure. Understanding how text defines form.
**Environment:** Library / Archive.

1.  **The Syntax (Basics)**
	*   `LSystems_Backus_Naur_Form_BNF`: Introduction to notation.
	*   `LSystems_Context_Free_Grammars_CFG`: Rules that don't depend on neighbors.
    *   `LSystems_Different_Grammar_Types`: Exploring the Chomsky hierarchy.
2.  **The Rewrite (String Generation)**
    *   *Planned:* `AxiomVisualizer`: A console-like display showing the string growing iteration by iteration.

---

### 🐢 Map 2: The Interpreter (Turtle Graphics)
**Theme:** Translating text into motion.
**Environment:** Drafting Table / 2D Plotter.

1.  **The String (Visualization)**
    *   `algorithms/fractals/example_8_8_lsystem_string_only_vr.tscn`: Visualizing the text generation ("A" -> "ABA").
2.  **The Shape**
    *   `LSystems_Shape_Grammars`: Generating geometric forms.
    *   `algorithms/fractals/koch_curve`: The classic infinite coastline (often L-System based).
    *   `algorithms/fractals/sierpinskitriangle`: Recursive triangle generation.

---

### 🌳 Map 3: The Branch (Organic Growth)
**Theme:** Creating natural forms in 3D.
**Environment:** Greenhouse / Arboretum.

1.  **The Tree**
    *   `LSystems_Tree_L_Systems`: The classic fractal tree.
    *   `algorithms/fractals/example_8_9_lsystem_tree_vr.tscn`: 3D L-System Tree implementation.
2.  **The Variation**
    *   `LSystems_Stochastic_L_Systems`: Adding probability for natural variety.
    *   `algorithms/fractals/example_8_7_stochastic_tree_vr.tscn`: Stochastic tree example.

---

### 🏙️ Map 4: The Structure (Architecture)
**Theme:** Building synthetic worlds.
**Environment:** City Planner / Industrial Zone.

1.  **The Space Filler**
    *   *Planned:* `HilbertCurve3D`: Efficiently filling volume (pipes/wiring).
2.  **The City**
    *   *Planned:* `CityLayoutGenerator`: Using L-systems for road networks.

---

### 🍂 Map 5: The Ecosystem (Time & Interaction)
**Theme:** Living, breathing systems.
**Environment:** Forest / Time-Lapse.

1.  **The Growth**
    *   *Planned:* `AnimatedGrowth`: Visualizing the process over time (tweening).
2.  **The Forest**
    *   *Planned:* `LSystemForest`: Multiple systems competing for space.

---

### 📝 Implementation Status
*   **Existing:** Theoretical maps (BNF, CFG) and basic Trees/Stochastic systems are in the sequence.
*   **Missing:** 3D Architecture, Space Filling Curves, and Animated Growth.
