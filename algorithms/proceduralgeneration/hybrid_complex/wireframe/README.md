# Fat Wireframe

A collection of procedurally generated 3D geometric shapes rendered as thick, glowing wireframes against a dark cyberpunk backdrop. The artifact creates a dozen objects -- from basic primitives (sphere, box, torus) through mathematical surfaces (Klein bottle, Mobius strip) to Platonic solids (icosahedron, tetrahedron, dodecahedron) -- each displayed with animated, pulsing wireframe edges using custom GPU shaders.

## Concept Taught

**Wireframe rendering, parametric surfaces, and shader-based visualization.** This artifact teaches several interconnected ideas. First, how barycentric coordinates and screen-space derivatives can detect triangle edges in a fragment shader, discarding interior pixels to reveal only the wireframe skeleton. Second, how parametric equations define mathematical surfaces: the Klein bottle, the Mobius strip, the icosahedron built from the golden ratio. Third, how procedural mesh generation works in practice -- building vertex arrays, index arrays, and submitting them as ArrayMesh surfaces. Students experience the geometry that underlies 3D graphics: vertices, edges, faces, and the shaders that decide what to draw.

## How It Works

1. A dark environment with volumetric fog is set up for glow enhancement.
2. Twelve base geometries are created: standard Godot primitives (SphereMesh, BoxMesh, CylinderMesh, TorusMesh) are converted to ArrayMesh, and custom meshes are generated procedurally:
   - **Icosphere**: low-poly sphere with reduced segment counts
   - **Geodesic**: icosahedron from 12 vertices positioned using the golden ratio, with 20 triangular faces
   - **Klein bottle**: parametric surface using the immersion equations, sampled over a 24x16 grid
   - **Mobius strip**: parametric half-twist surface sampled over 40x8 grid
   - **Pyramid**, **Prism** (hexagonal), **Dodecahedron**, **Tetrahedron**: hand-crafted vertex and index arrays
3. Objects are positioned in four arrangement patterns: circular, vertical stack, spiral, and random cloud.
4. Two custom shaders alternate between objects:
   - **Barycentric wireframe shader**: uses `VERTEX_ID % 3` to assign barycentric coordinates, calculates edge proximity via `fwidth()` and `smoothstep()`, discards interior fragments, and adds pulsing glow with configurable thickness animation.
   - **Edge-based wireframe shader**: uses `fmod()` on local position derivatives to detect grid-like edges with screen-space line width.
5. Each object gets a unique hue, glow color, pulse speed, and thickness variation.
6. Tween-based animations rotate objects with tumble, dual-axis, and oscillating patterns.
7. Glow intensity and line thickness are animated over time for living, breathing wireframes.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `object_count` | int | 12 | Number of wireframe objects to create |
| `wireframe_thickness` | float | 0.08 | Base thickness of wireframe lines |
| `animation_speed` | float | 1.0 | Speed multiplier for rotation animations |
| `glow_intensity` | float | 2.0 | Base emission intensity for wireframe glow |
| `auto_rotate` | bool | true | Enable automatic rotation animations |

## Features

- Two custom GLSL wireframe shaders: barycentric-based and edge-based
- Procedural generation of 12 distinct geometric shapes including mathematical surfaces
- Klein bottle and Mobius strip from parametric equations
- Icosahedron and geodesic from golden ratio vertex placement
- Animated glow, pulsing thickness, and per-object color variation
- Dark cyberpunk environment with volumetric fog for enhanced glow
- Multiple spatial arrangements: circle, stack, spiral, random cloud
- All meshes converted to ArrayMesh for consistent shader compatibility

## Files

| File | Purpose |
|------|---------|
| `fatwireframe.gd` | Scene setup, procedural mesh generation for all 12 shapes, shader creation, animation, and arrangement |
