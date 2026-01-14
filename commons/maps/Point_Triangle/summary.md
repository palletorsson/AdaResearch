# Point Triangle - Map Summary

## Overview
Point Triangle introduces the first closed geometry - the triangle as fundamental enclosure. After experiencing points (position), lines (measured relation), grids (indexed space), this map reveals how three vertices produce something categorically new: **a boundary that defines inside and outside**.

## Spatial Layout
- **Dimensions**: 7×9 grid (compact workspace)
- **Architecture**: Varied height platform with elevated markers (1-2 levels)
- **Central void**: Single absent tile at (3,7) creating focal point
- **Entry**: Standard spawn

## Key Elements

### Primary Interactables
- **triangle** (3,3) - Editable triangle with grabbable vertices
  - Three snap points that can be moved in 3D space
  - Triangle surface updates in real-time as vertices move
  - Demonstrates how closure is maintained through vertex positions

- **triangle_line_puzzle** (3,2) - Triangle construction puzzle
  - Sunken to height 0 (fillhole group) creating focused interaction space
  - Challenges player to understand triangle constraints

### Supporting Elements
- **triangleprofiles** (3,7) height 0.5m - Gallery of triangle variations
  - Equilateral, isosceles, right, scalene examples
  - Shows how same primitive (three vertices) produces diverse forms

- **dark_sphere** (3,4) - Intimate lighting enclosure
- **cube_scene** (3,5) height 0.9m - Spatial marker in fillhole group
- **Label annotation** "triangle" at (3,3)

### Utilities
- **Teleporter** (3,7) - Exit to next map
- **Annotation** (6,2) rotated -90° - Navigation marker

## Atmosphere
- **Audio**: "fractal_exploration" preset at -10dB - contemplative algorithmic sound
- **Background**: Sky blue [0.2, 0.3, 0.7]
- **Lighting**: Warm directional (1.2 energy) creating defined shadows
- **Mood**: Workshop-like, focused on geometric manipulation
- **Visibility**: Hidden tiles except corners - progressive revelation

## Learning Sequence
1. Player spawns into workshop space
2. Encounters `triangle` interactable - three grabbable vertices
3. Grabs and moves vertices - observes triangle surface updating
4. Discovers constraints: vertices must remain non-collinear
5. Experiences triangle_line_puzzle - constructing triangles from scratch
6. Studies triangleprofiles - sees variety within triangular form
7. Recognizes triangle as first closure - space is now **inside** or **outside**
8. Exits having encountered geometry that contains

## Design Intent

The **editable triangle** is central - unlike previous fixed demonstrations, this triangle's vertices can be moved. This interactivity reveals that:
- Triangle is **three positions** + **three relations**
- Moving one vertex changes **all three edges**
- The surface persists as long as vertices are non-collinear
- Closure is **dynamic**, not static

The **triangleprofiles** gallery shows that "triangle" is a category containing infinite variations. All share the same structure (3 vertices, 3 edges, 1 face) but differ in proportions.

The map's architecture itself echoes triangulation - varied heights at (3,2), (0,3), (5,3), (2,4), (4,4) create non-uniform terrain requiring triangular faces to render.

## Key Concept: First Closure

**Point** - Singular position
**Line** - Two positions, open connection
**Triangle** - Three positions, **closed boundary**

The triangle is the first geometry that produces:
- **Inside vs. Outside** - Decisive binary distinction
- **Orientation** - Front and back faces
- **Area** - Quantified enclosure
- **Surface** - Visible boundary

All subsequent complex geometry (cubes, spheres, organic models) reduces to triangles.

## Connection to Sequence
- **Position in primitives sequence**: 7/13
- **Precedes**: Point_Triangle_Context (triangle variations and theorems)
- **Follows**: Point_Line_Grid (coordinate systems)
- **Establishes**: Closure, containment, inside/outside binary
- **Critical theme**: Boundaries as governance - who decides what's enclosed?
