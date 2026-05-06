# Sphere Network

A procedural level generator that creates networks of large spheres connected by cylindrical pipes, with walkable tunnels carved through both using CSG (Constructive Solid Geometry) boolean operations. The result is an interconnected series of hollow chambers linked by passages -- a VR-navigable architectural structure built entirely from code.

## Concept Taught

**Constructive Solid Geometry and procedural architecture.** This artifact teaches how complex, navigable 3D spaces can be created by combining and subtracting simple geometric primitives. CSG union builds up solid volumes; CSG subtraction carves out interior walkways. Students see how a small number of rules -- place spheres, connect with pipes, carve tunnels -- produces a walkable environment that feels designed but is generated procedurally. The concept extends to game level design, architectural modeling, and any domain where boolean operations on geometry create useful structure.

## How It Works

1. Sphere positions are distributed along a horizontal line with small random vertical and depth offsets.
2. For each sphere, a CSGCombiner3D is created containing the main sphere mesh and subtracted walkway carve-outs (inner spheres at connection points).
3. Adjacent spheres are linked by CSGMesh3D pipes. The outer pipe is a cylinder at `pipe_radius`; a smaller cylinder at `walkway_radius` is subtracted to create a hollow tunnel.
4. Pipes are oriented to align with the direction between sphere centers using cross-product rotation calculations.
5. All CSG shapes have collision enabled for VR walkability.
6. An alternative ArrayMesh method generates sphere vertices with carved regions by testing each vertex against walkway and connection directions.
7. The simple example script demonstrates a minimal 3-sphere network using CSGSphere3D and CSGCylinder3D primitives with boolean subtraction.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `sphere_count` | int | 5 | Number of spheres in the network |
| `sphere_radius` | float | 10.0 | Radius of each sphere chamber |
| `pipe_radius` | float | 6.0 | Outer radius of connecting pipes |
| `network_width` | float | 50.0 | Total horizontal span of the network |
| `walkway_radius` | float | 5.0 | Radius of carved walkway tunnels |
| `material` | StandardMaterial3D | null | Material applied to all CSG shapes |
| `generate_network` | bool | false | Editor button to trigger generation |

## Features

- Tool script: runs in the Godot editor for preview and iteration
- CSG boolean subtraction carves walkable tunnels through spheres and pipes
- Automatic collision generation via `use_collision = true`
- Pipe orientation handles arbitrary directions including edge cases (vertical pipes)
- Simple example demonstrates a minimal 3-sphere network with horizontal and vertical tunnels
- Alternative ArrayMesh path for finer-grained control over carved geometry
- Editor integration: generated nodes have proper ownership for scene saving

## Files

| File | Purpose |
|------|---------|
| `spherenetwork.gd` | Configurable sphere network generator with CSG boolean carving and ArrayMesh alternative |
| `simpleexample.gd` | Minimal 3-sphere demo using CSGSphere3D and CSGCylinder3D primitives |
