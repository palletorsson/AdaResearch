# The Soft Bodies Curriculum
## A Comprehensive Ground-Up Presentation Plan

This document outlines a structured progression for presenting material related to **Soft Bodies and Physics Simulation** found in `algorithms/physicssimulation`. It organizes the examples into a coherent 5-Map journey, from rigid constraints to squishy volumes.

---

### 🔗 Map 1: The Link (Constraints & Springs)
**Theme:** The bonds that hold matter together.
**Environment:** Physics Lab / Suspension Bridge.

1.  **The Spring (Hooke's Law)**
    *   `springsystem` / `springmass`: Basic oscillating springs.
    *   `massspringdamper`: Damped harmonic motion.
    *   `constraints`: Distance constraints (the basis of Verlet physics).
2.  **The Chain (1D)**
    *   (Gap): A simple rope/chain demo using linked particles.

---

### 👕 Map 2: The Surface (Cloth & Sheets)
**Theme:** 2D manifolds bending in 3D space.
**Environment:** Laundry Room / Sailboat.

1.  **The Cloth**
    *   `clothsimulation`: Grid of particles connected by springs.
    *   `verletintegration`: The math behind stable cloth.

---

### 🍮 Map 3: The Volume (Soft Bodies)
**Theme:** Squishy, deformable 3D objects.
**Environment:** Jelly Factory / Bouncy Castle.

1.  **The Jelly**
    *   `softbodies` / `softbody3d`: 3D meshes behaving like jelly.
    *   `fem`: Finite Element Method (more accurate deformation).
2.  **The Pressure**
    *   (Gap): A "Pressure" demo where you inflate/deflate a soft body.

---

### 💧 Map 4: The Fluid (Particles & Fields)
**Theme:** Matter that flows.
**Environment:** Water Tank / Wind Tunnel.

1.  **The Particle**
    *   `particlesystems`: Emitters and forces.
    *   `fluidsimulation` / `water_one` / `waterflowers`: SPH (Smoothed Particle Hydrodynamics) or grid-based fluids.
2.  **The Field**
    *   `forcefields` / `vectorfields`: Invisible forces pushing matter.

---

### 🧩 Map 5: The Interaction (Rigid vs Soft)
**Theme:** How soft bodies interact with the hard world.
**Environment:** Obstacle Course.

1.  **The Collision**
    *   `collisiondetection`: Algorithms for detecting overlaps.
    *   `rigidbody`: Comparison with non-deformable objects.
2.  **The Playground**
    *   `playground_of_joy`: A sandbox combining these elements.
    *   `surrealkineticsculpture`: Artistic application of physics.

---

### 📝 Implementation Strategy
*   **Hub World:** A "Physics Playground" where everything is interactive.
*   **Interaction:** Grab, pull, poke, and slice objects.
