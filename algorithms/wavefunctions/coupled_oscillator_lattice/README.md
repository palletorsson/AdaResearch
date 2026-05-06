# Coupled Oscillator Lattice

A grid of spherical oscillators where each node is connected to its neighbors by virtual springs. Excitation at the center ripples outward as a wave, and each sphere's vertical displacement is color-coded from blue to cyan. The artifact teaches **coupled oscillation, wave propagation, and collective dynamics** -- how local interactions between simple identical elements produce global wave behavior.

## Concept Taught

**Coupled oscillators** are a foundational model in physics. Each oscillator obeys Hooke's law (a restoring force proportional to displacement) and is coupled to its neighbors by a force proportional to the displacement difference. When one oscillator is disturbed, the coupling transfers energy to adjacent oscillators, and a wave propagates through the lattice. This is the microscopic mechanism behind sound waves, heat conduction, crystal phonons, and many other phenomena. The lattice makes these dynamics visible: a sine-wave excitation at the center creates concentric wave fronts; a pulse excitation creates a single expanding ring; random excitation produces turbulent noise.

## How It Works

1. The script runs in `@tool` mode (lattice is visible in the editor but only animates at runtime).
2. A `lattice_size.x * lattice_size.y` grid of oscillators is created. Each oscillator is a dictionary storing grid position, displacement, velocity, acceleration, and phase.
3. A `MeshInstance3D` sphere with an emissive material is created for each oscillator.
4. Each frame:
   - **Excitation** is applied to the center oscillator according to `excitation_mode` (continuous sine, one-shot pulse, or random bursts).
   - **Force calculation**: for each oscillator, the restoring force (`-omega^2 * displacement`), coupling forces from all neighbors (`coupling_strength * (neighbor.displacement - self.displacement)`), and damping (`-damping * velocity`) are summed.
   - **Integration**: Euler integration updates velocity and displacement from the net force.
5. **Visualization**: each sphere's Y-position is set to `equilibrium + displacement`. If `color_by_displacement` is enabled, the sphere's color shifts from blue (resting) toward cyan (displaced) based on normalized absolute displacement, and emission energy scales accordingly.
6. Public API functions allow external code to query displacement at any grid position, manually set displacement, and read total system energy (kinetic + potential).

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `lattice_size` | Vector2i | `(12, 12)` | Grid dimensions (columns x rows) |
| `oscillator_spacing` | float | `0.4` | Distance between adjacent oscillators |
| `base_height` | float | `1.0` | Resting Y-position of all oscillators |
| `natural_frequency` | float | `2.0` | Natural angular frequency (omega-0) |
| `mass` | float | `1.0` | Mass of each oscillator |
| `damping_coefficient` | float | `0.02` | Velocity damping factor |
| `coupling_strength` | float | `1.5` | Spring constant between neighbors |
| `coupling_range` | int | `1` | Neighbor radius (1 = nearest only) |
| `excite_center` | bool | `true` | Whether the center oscillator is driven |
| `excitation_amplitude` | float | `0.5` | Strength of the excitation signal |
| `excitation_frequency` | float | `2.0` | Frequency of sine-mode excitation |
| `excitation_mode` | String | `"Sine"` | Excitation type: `Sine`, `Pulse`, or `Random` |
| `oscillator_radius` | float | `0.06` | Visual radius of each sphere |
| `color_by_displacement` | bool | `true` | Map displacement to color |
| `show_connections` | bool | `false` | (Reserved) Show coupling lines |
| `max_displacement_color` | float | `0.8` | Displacement that maps to full color shift |

## Features

- `@tool` script: lattice structure visible in the editor; physics runs only at runtime.
- Three excitation modes: continuous sine wave, one-shot pulse, and stochastic random bursts.
- Configurable coupling range: nearest neighbors or extended neighborhoods.
- Per-oscillator displacement-to-color mapping with emissive glow.
- Euler integration of coupled spring-mass equations with damping.
- Public API: `get_displacement_at()`, `apply_displacement()`, `get_total_energy()`.
- Energy conservation tracking (kinetic + potential).

## Files

- `coupled_oscillator_lattice.gd` -- Main script: lattice construction, coupled oscillator physics, excitation modes, visualization.
- `coupled_oscillator_lattice.tscn` -- Scene file.
