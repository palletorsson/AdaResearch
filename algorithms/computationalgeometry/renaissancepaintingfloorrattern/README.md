# Renaissance Painting Floor Pattern

A procedural floor tile generator that recreates the geometric patterns found in Renaissance paintings. The artifact builds a multi-layered floor surface with a checkerboard base, diamond overlays, decorative borders, and perspective guide lines -- all using physically-based materials.

## Concept Taught

**Computational geometry applied to art history.** Renaissance painters used precise geometric constructions to create convincing perspective illusions in their floor patterns. These patterns served both decorative and spatial purposes -- the converging lines of tiled floors helped establish depth and vanishing points. This artifact demonstrates how layered geometric constructions (checkerboard grids, rotated diamond tessellations, border framing) combine to produce complex visual patterns from simple algorithmic rules.

## How It Works

1. A **base checkerboard** is laid out as a grid of `BoxMesh` tiles with alternating dark and light brown materials, each tile including a `StaticBody3D` collision shape.
2. **Diamond pattern groups** are placed at regular intervals (every 4 tiles), each consisting of a central 45-degree-rotated box and four small corner accent diamonds in red terracotta.
3. **Decorative border strips** frame the entire floor on all four sides with ornate golden-brown material featuring clearcoat for a polished sheen.
4. **Perspective guide lines** are placed along horizontal and vertical axes at 2-tile intervals as thin raised strips, enhancing the spatial depth illusion.
5. Materials use rim lighting, clearcoat effects, and subtle emission to simulate the warm stone surfaces characteristic of Renaissance interiors.

## Parameters

The floor is configured through local variables in `create_renaissance_floor()`:

- Floor dimensions: 24 x 16 tiles
- Base tile size: 1.0 unit
- Tile thickness: 0.08 units
- Diamond spacing: every 4 tiles
- Diamond sizes: 60% of tile size (center), 20% (corners)

## Features

- Four-layer construction: checkerboard base, diamond overlay, borders, perspective lines
- Six distinct PBR materials: dark brown, light brown, cream stone, red terracotta, ornate border, perspective line
- Rim lighting on stone materials for edge definition
- Clearcoat on border material for polished appearance
- Per-tile collision shapes for VR walkability
- Optional Renaissance-style lighting setup with warm directional, cool fill, and omni accent lights
- Diamond tiles created via 45-degree rotated boxes

## Files

- `renaissancepaintingfloorrattern.gd` -- Procedural floor pattern generator with material system and optional lighting
- `renaissancepaintingfloorrattern.tscn` -- Scene file
