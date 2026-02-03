# Master Implementation Plan
## The Missing Algorithms & Scenes

This document aggregates all the "Planned" and "Missing" items from the various curriculum plans. It serves as the primary To-Do list for completing the Ada Research algorithmic library.

---

### 🌿 L-Systems (Priority: High)
*Focus: Moving beyond trees to architecture and ecosystems.*

1.  **[ ] 3D Architecture Generator**
    *   **Goal:** Building cities or industrial structures.
    *   **Task:** Create an L-System rule set that generates road networks or pipe systems (Steampunk style).
    *   **Scene:** `algorithms/l_systems/Architecture/CityGenerator.tscn`
2.  **[ ] Space-Filling Curves (3D)**
    *   **Goal:** Efficiently filling volume.
    *   **Task:** Implement a 3D Hilbert Curve generator using L-System logic.
    *   **Scene:** `algorithms/l_systems/Architecture/Hilbert3D.tscn`
3.  **[ ] Animated Growth**
    *   **Goal:** Visualizing the process.
    *   **Task:** Create a system that "tweens" the growth of branches over time, rather than popping them into existence.
    *   **Scene:** `algorithms/l_systems/Growth/AnimatedTree.tscn`
4.  **[ ] Ecosystem Simulation**
    *   **Goal:** Interaction between systems.
    *   **Task:** Create a scene with multiple L-System plants competing for light/space.
    *   **Scene:** `algorithms/l_systems/Ecosystem/ForestCompetition.tscn`
5.  **[ ] Context-Sensitive Grammar**
    *   **Goal:** Environmentally aware growth.
    *   **Task:** Implement rules that query the environment (e.g., "Grow only if space is empty").
