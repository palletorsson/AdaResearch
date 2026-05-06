# Kitbashing

A procedural **kitbashing** generator that creates complex 3D environments by randomly combining, placing, and connecting modular building blocks. Inspired by the film and game industry technique of assembling new designs from pre-existing parts, this artifact generates surrealist, mechanical, or organic assemblages from procedurally created modules.

This artifact teaches **compositional randomness** -- how complex, visually rich structures emerge from randomly combining simple parts. Kitbashing demonstrates that randomness applied at the compositional level (which parts, where, at what scale, in what orientation) produces far more variety than randomness at the geometric level. The same small set of modules, randomly assembled, yields an effectively infinite space of possible designs.

## How It Works

1. **Module Generation**: If no external `.tscn` module files are found, the system generates 10 procedural modules in one of three styles:
   - **Surrealist**: Stacked primitives, floating parts, nonsensical machines, abstract CSG sculptures, composite creatures (exquisite corpse-inspired mismatched body parts)
   - **Mechanical**: Joints with arms and bolts, control panels with buttons/dials/switches, pipe systems with valves and wheels, electronic circuit boards with chips, capacitors, and LEDs
   - **Organic**: Plant structures with stems and branches, transparent fluid-containing vessels with connecting tubes, recursive coral-like branching, egg sac clusters with connecting tendrils

2. **Space Population**: `module_count` modules are randomly selected, duplicated, positioned within the `space_size` bounding volume, given random rotation, and scaled by a random factor between 0.5x and 2.0x.

3. **Module Connection**: Placed modules are connected based on distance:
   - **Close (< 5 units)**: Mechanical connections -- pipe paths with joints or solid bars
   - **Medium (< 15 units)**: Energy beams with emissive materials and particle spheres
   - **Far (> 15 units)**: Floating object chains interpolated along the path

4. **Color Theming**: One of three color themes is randomly selected at startup:
   - Blue/yellow with red accent (inspired by Ben Nicholas)
   - Industrial dark gray with red accent (inspired by Vitaly Bulgarov)
   - Vibrant pink/teal with yellow accent (inspired by Katie Torn)

5. **Lighting and Atmosphere**: Dynamic lighting includes a directional light, colored spotlights pointing toward the center, fog, bloom, and filmic tone mapping. Atmospheric dust particles (100 small semi-transparent spheres) fill the space.

6. **CSG Sculpting**: Abstract sculptures use `CSGCombiner3D` with `CSGSphere3D` primaries and `OPERATION_SUBTRACTION` cutters (boxes or spheres) to create complex boolean-carved forms.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `module_count` | int | 30 | Number of modules placed in the scene |
| `space_size` | Vector3 | (30, 15, 30) | Bounding volume for module placement |
| `modules_path` | String | "res://modules/" | Directory to load external module scenes |
| `generation_rules` | String | "surrealist" | Style: "surrealist", "mechanical", "organic", or other (mixed) |
| `color_themes` | Array | 3 themes | Array of color theme dictionaries (primary, secondary, accent, metal) |

## Features

- Three generation styles: surrealist, mechanical, organic (plus mixed)
- Procedural module library with 10+ distinct module archetypes
- Distance-based connection system: pipes, beams, floating chains
- Three color themes randomly selected at startup
- CSG boolean sculpting for abstract forms
- Recursive coral branching with configurable depth
- Transparent fluid vessels with connecting tubes
- Electronic circuit boards with chips, capacitors, LEDs, and circuit traces
- Pipe systems with valves, wheels, and segment joints
- Exquisite corpse-inspired composite creatures
- Dynamic lighting: directional, colored spotlights, bloom, fog
- Atmospheric dust particles for spatial depth
- Filmic tone mapping and volumetric fog

## Files

| File | Description |
|------|-------------|
| `kitbashing.gd` | Main script -- module generation, placement, connection, lighting, atmosphere |
| `kitbashing.tscn` | Scene file |
