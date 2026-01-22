# Trans_Composition - Furniture Assembly

## Overview

This map presents transformation as **composition**—the combination of scale, rotation, and translation to create complex forms from simple primitives.

## Layout

- **9×9 platform** with raised edges
- **Central assembly area** where the chair takes shape
- **Workbench** with 6 scalable cubes (pieces)
- **Ghost guides** showing target positions for each piece

## Key Elements

| Element | Purpose |
|---------|---------|
| `chair_assembly_puzzle` | The main puzzle controller |
| Scalable wood cubes | 6 pieces (seat, 4 legs, back) |
| Ghost guides | Semi-transparent targets |
| `dark_sphere` | Ambient lighting |

## Interaction

1. **Grab** a cube from the workbench
2. **Scale** using two-handed grip (VR) or scroll wheel (desktop)
3. **Rotate** by twisting while held
4. **Position** to match the ghost guide
5. When all pieces match → chair assembles and grows to real size

## Learning Objectives

- Transform composition (T × R × S)
- Scale as form-giving operation
- Spatial reasoning in 3D
- The grammar of making: primitives → modulators → combinations

## Design Philosophy

Inspired by Donald Judd's furniture: minimal forms, honest materials, systematic variation. The puzzle demonstrates that complex objects are just simple shapes with the right transforms applied.
