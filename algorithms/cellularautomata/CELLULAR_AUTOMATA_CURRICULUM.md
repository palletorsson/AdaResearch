# The Cellular Automata Curriculum
## A Comprehensive Ground-Up Presentation Plan

This document outlines a structured progression for presenting **ALL** material in `algorithms/cellularautomata`. It organizes the examples into a coherent 5-Map journey, from simple 1D patterns to complex 3D simulations.

---

### ➖ Map 1: The Line (1D Automata)
**Theme:** Complexity from simplicity. The foundation of Wolfram's physics.
**Environment:** Data Tape / Turing Machine.

1.  **The Rule (Basics)**
    *   `cellular_automata_1d`: Basic implementation of elementary CA.
    *   `rule_30_110`: Exploring specific famous rules (Chaos vs Computation).
    *   `noc_ch07`: Nature of Code examples (Wolfram's classification).

---

### ▦ Map 2: The Grid (2D Automata)
**Theme:** Emergent life and logic.
**Environment:** Pixel Screen / Circuit Board.

1.  **The Life (Conway)**
    *   `cellular_automata_2d`: The Game of Life implementation.
    *   `crossway_ca`: Traffic or flow simulations.
2.  **The Pattern (Reaction-Diffusion)**
    *   (Gap): We should add a reaction-diffusion example here if not present in `noc_ch07`.

---

### 🧊 Map 3: The Volume (3D Automata)
**Theme:** Architecture and growth in space.
**Environment:** Voxel Lab / Hologram.

1.  **The Stack (Time as Dimension)**
    *   `cellular_automata_3d_stacked`: Visualizing 2D CA history as a 3D object.
2.  **The Cube (True 3D)**
    *   `cellular_automata_3d`: 3D Game of Life (Survival/Birth rules in 3D).
    *   `CA_sphere`: CA applied to a spherical surface/volume.

---

### 🌳 Map 4: The Growth (Structure)
**Theme:** Procedural generation of objects.
**Environment:** Digital Garden / Furniture Factory.

1.  **The Tree**
    *   `cellular_automata_3d_tree`: Growing organic structures using voxel rules.
2.  **The Object**
    *   `CAchairtests`: Generating furniture/objects using CA rules.
    *   `ca_showcase`: A gallery of generated forms.

---

### 🌊 Map 5: The Fluid (Physics)
**Theme:** Simulating nature with discrete logic.
**Environment:** Wind Tunnel / Pipe Network.

1.  **The Gas (Lattice Boltzmann)**
    *   `lattice_gas_automata`: Simulating fluid flow using particles on a grid.

---

### 📝 Implementation Strategy
*   **Hub World:** A "Grid World" where the floor itself is a CA.
*   **Interaction:** Allow users to "paint" cells and watch them evolve.
