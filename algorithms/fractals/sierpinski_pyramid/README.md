# Sierpinski Pyramid -- Fractal Tetrahedron with Physics

A recursive fractal generator that constructs a **Sierpinski tetrahedron** (3D Sierpinski triangle) from `RigidBody3D` cubes arranged in a tetrahedral pattern. After a delay, the rigid bodies are unfrozen and the fractal collapses under gravity, demonstrating both fractal geometry and physics simulation.

## Concept Taught

**Fractal self-similarity and recursive subdivision.** The Sierpinski tetrahedron is the 3D extension of the Sierpinski triangle -- one of the most fundamental fractals in mathematics. It is constructed by recursively replacing a tetrahedron with four smaller copies placed at its vertices, leaving the center void. This artifact teaches recursive thinking: the same `generate_sierpinski` function calls itself with reduced size and offset positions until the base case is reached. The physics collapse adds an interactive element -- showing how a perfect mathematical structure behaves when physical forces are applied.

## How It Works

1. The `generate_sierpinski` function is called with an initial position, recursion level, and size.
2. At the base case (`level == 0`), a `RigidBody3D` is created with a `BoxMesh` and `BoxShape3D` collision, initially frozen in place. A custom shader material is applied.
3. At higher levels, the function computes four vertex positions of a tetrahedron: `(1,1,1)`, `(1,-1,-1)`, `(-1,1,-1)`, `(-1,-1,1)`, each scaled by `new_size = current_size / 2`.
4. The function recurses into four sub-tetrahedra, each at half the size and offset to a vertex position.
5. After a 2-second timer, all rigid bodies are unfrozen (`freeze = false`), allowing the fractal to collapse under Godot's physics engine.

## Parameters

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `max_level` | int | 3 | Recursion depth (produces 4^level cubes) |
| `size` | float | 5.0 | Initial tetrahedron size |

## Features

- Recursive fractal generation with configurable depth
- Custom shader material applied via `pyramid_shader.gdshader`
- RigidBody3D physics on every fractal element
- Timed physics activation -- fractal holds shape then collapses
- Tetrahedral vertex arrangement for true 3D Sierpinski structure
- Collision shapes on all elements for physical interaction
- At max_level=3: 64 cubes (4^3); at max_level=4: 256 cubes

## Files

- `SierpinskiPyramid.gd` -- Recursive fractal generator with physics
- `SierpinskiPyramid.tscn` -- Main scene file
- `sierpinski_pyramid.tscn` -- Alternate scene file
- `pyramid_shader.gdshader` -- Custom shader material for the fractal cubes
