# Riemann Surface Torus - VR Topology Demonstration

An interactive VR scene that visualizes how a **fundamental parallelogram** with opposite edges identified forms a **genus-1 Riemann surface** (torus). Demonstrates the relationship between lattice vectors in the complex plane and the modular parameter τ.

## Concept

### Complex Tori and Lattice Vectors

A **complex torus** (genus-1 Riemann surface) can be constructed from the complex plane ℂ by identifying points that differ by elements of a lattice:

```
T = ℂ / Λ    where Λ = { m·ω₁ + n·ω₂ | m, n ∈ ℤ }
```

The two lattice vectors **ω₁** and **ω₂** span a fundamental parallelogram. By identifying opposite edges (gluing them together), we obtain a torus.

### The Modular Parameter τ

The **shape** of the torus is encoded by the complex number:

```
τ = ω₂ / ω₁
```

This is the **modular parameter**. Different values of τ give geometrically distinct tori. The scene displays τ in real-time as you move the lattice vectors.

### Double Periodicity

The torus has **two independent cycles**:
- One around the "donut hole" (corresponding to ω₁)
- One around the "tube" (corresponding to ω₂)

The shader on the torus displays animated stripes in both directions to visualize this **double periodicity**.

## Usage

### In VR

1. **Open the scene**: `res://algorithms/spacetopology/riemann_torus/torus_vr.tscn`

2. **Grab and move the spheres**:
   - **Origin** (at 0,0,0): The base point of your lattice
   - **Ω₁** (omega 1): First lattice vector (initially at 1.2, 0, 0)
   - **Ω₂** (omega 2): Second lattice vector (initially at 0.2, 0, 1.2)

3. **Observe**:
   - The **fundamental parallelogram** updates in real-time (4 glowing edges)
   - The **lattice tiling** shows how the parallelogram tiles the plane
   - The **τ label** displays the modular parameter (complex ratio ω₂/ω₁)
   - The **torus** (floating at eye level) shows animated stripes representing the two periodic directions

### Parameters (Inspector)

#### Visualization
- `show_plane`: Display the floor grid
- `show_tiles`: Show the lattice tiling
- `tile_radius`: How many tiles to show around origin (1 = 3×3 grid)
- `plane_cell`: Grid spacing for floor (0.1 = 10cm)

#### Torus Appearance
- `torus_outer`: Outer radius of the torus (1.0m default)
- `torus_inner`: Inner radius of the torus hole (0.35m default)
- `stripe_density_u`: Number of stripes in first direction
- `stripe_density_v`: Number of stripes in second direction
- `animate_stripes`: Enable/disable stripe animation
- `stripe_speed`: Speed of stripe animation

#### 3-Torus Wrap (Experimental)
- `enable_3torus_wrap`: Enable 3-dimensional toroidal wrapping
- `wrap_box_half_extent`: Size of wrap region (1.5m = 3m cube)

When `enable_3torus_wrap` is enabled, add a `PlayerRig` child node to experience **3-torus topology**: moving past any boundary instantly wraps you to the opposite side, creating a closed 3-dimensional space.

## Mathematical Background

### Why Identify Edges?

When you "glue" opposite edges of the parallelogram:
1. **Horizontal edges** (along ω₁) → Creates a cylinder
2. **Vertical edges** (along ω₂) → Closes the cylinder into a torus

This is **topological identification**: points on opposite edges are considered the same point.

### Elliptic Functions

Functions that respect this lattice structure (i.e., f(z + ω₁) = f(z) and f(z + ω₂) = f(z)) are called **elliptic functions**. They naturally "live" on the torus.

### Complex Structure

The modular parameter τ determines the **complex structure** of the torus:
- Re(τ): "Skew" of the parallelogram
- Im(τ): "Aspect ratio"

Different τ values give conformally distinct tori. The **moduli space** of tori is closely related to the upper half-plane of τ.

## Extensions

### Try These Experiments

1. **Make τ purely imaginary**: Move ω₂ so it's directly "above" ω₁ (aligned vertically in XZ)
   - Result: A rectangular fundamental domain (no skew)

2. **Make τ ≈ i**: Make the parallelogram nearly square
   - Result: The most symmetric torus

3. **Make τ have large real part**: Move ω₂ far along ω₁ direction
   - Result: A highly skewed parallelogram

4. **Add a third direction**: Enable `enable_3torus_wrap` to feel what a 3-torus is like
   - Note: You can't have 3 independent complex periods in 2D, but this simulates the wrap-around feeling

### Potential Additions

- **Geodesic visualization**: Draw the shortest path between two points on the torus
- **Eisenstein series**: Show a heatmap of E₄ or E₆ on the fundamental domain
- **Modular forms**: Visualize how functions transform under SL(2,ℤ) actions on τ
- **Weierstrass ℘ function**: Plot the doubly-periodic meromorphic function
- **Theta functions**: Show the relationship between τ and theta function values

## Files

- `torus_vr.tscn`: Main scene with grabbable lattice vectors
- `torus_vr.gd`: Script handling lattice math, visualization, and torus shader
- `README.md`: This file

## Dependencies

- `res://commons/primitives/point/grab_sphere_point.tscn`: Grabbable sphere points (VR compatible)

## Related Topics

- Complex analysis
- Riemann surfaces
- Elliptic curves
- Modular forms
- Algebraic geometry
- Topological spaces
- Fundamental groups

---

*"The torus is the simplest example of a compact Riemann surface that isn't the Riemann sphere. It's where complex analysis truly becomes interesting."*
