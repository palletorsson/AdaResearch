# Bricolage_Inventory - Map Summary

## Overview
The opening map of the bricolage sequence introduces a fundamental shift in perspective: primitives are not just geometric shapes—they are **potential parts** in an inventory. The bricoleur does not ask "what shape is this?" but "what can I build with this?" This workshop space presents familiar primitives (from the primitives sequence) reframed as materials waiting to be recombined.

## Spatial Layout
- **Dimensions**: 11×13 grid
- **Architecture**: Walled workshop with pedestals (height 2) displaying primitive specimens
- **Height**: Perimeter walls at 2, floor at 1, pedestals at 2, exit at 0

## Key Elements

### Interactables
- **clipboard#bricolage_axioms** (5,1) rotated 180°, height 1.5m - Core theoretical introduction
- **Primitive specimens on pedestals** (row 2 and 4):
  - point_specimen, line_specimen, triangle_specimen, plane_specimen
  - cube_specimen, sphere_specimen, cylinder_specimen, torus_specimen
- **dark_sphere** (5,6) - Contemplation zone
- **clipboard#affordance_catalog_axioms** (1,8) rotated 90°, height 1.2m - Affordance reference
- **inventory_workbench** (9,8) - Interactive assembly surface

### Utilities
- **Spawn point** (0,0) height 4.5m - Elevated entry overlooking workshop
- **Teleporter** (5,11) - Exit to Bricolage_Affordances

## Atmosphere
- **Background**: Warm workshop brown [0.25, 0.22, 0.2]
- **Lighting**: Warm ambient [0.5, 0.45, 0.4] with soft directional
- **Mood**: Workshop, material, hands-on—a maker's space

## Learning Sequence
1. Player spawns elevated, sees workshop layout with specimens on pedestals
2. Descends to encounter bricolage_axioms clipboard—core concept introduction
3. Examines primitive specimens arranged on pedestals
4. Reads: "These are not shapes—they are potential parts"
5. Passes through dark_sphere for contemplation
6. Encounters affordance_catalog—what each primitive can do
7. Observes inventory_workbench—where assembly will happen
8. Exits to continue sequence

## Design Intent
The pedestal arrangement (height 2 blocks with specimens) creates a cabinet of curiosities effect—each primitive is elevated for examination like a museum specimen. But unlike a museum, this is a workshop: the workbench signals that these specimens are meant to be used, not just observed. The warm lighting reinforces the maker-space atmosphere.

## Connection to Sequence
- **Position in bricolage sequence**: 1/7
- **Precedes**: Bricolage_Affordances
- **Follows**: Completion of primitives and array_tutorial sequences
- **Theme**: The conceptual shift from "shapes" to "parts"

## Theoretical Framework

### Lévi-Strauss's Bricoleur
The bricoleur works with "whatever is at hand"—not ideal materials but available ones. This map presents the primitives as that inventory: the raw materials you already have from the primitives sequence.

### Inventory Thinking
The engineer asks: "What do I need?"
The bricoleur asks: "What do I have?"

This map establishes the inventory:
- Point (anchor, vertex, node)
- Line (edge, strut, path)
- Triangle (face, brace, stable unit)
- Plane (platform, wall, shelf)
- Cube (module, voxel, container)
- Sphere (joint, node, hub)
- Cylinder (column, beam, axle)
- Torus (ring, hoop, handle)

Each is not a shape but a **potential part**—defined by what it can become.

## QFEP Connection
The inventory represents the available microstates of the system—the E(S) term in material form. Before assembly, entropy is maximum: parts could combine in any configuration. Structure will emerge as constraints reduce this possibility space to stable configurations. The workshop is the space of potential; the subsequent maps are where potential becomes actual.

## Sources
- Lévi-Strauss, C. (1962). *The Savage Mind* (La Pensée Sauvage) - bricoleur concept
- Gibson, J.J. (1979). *The Ecological Approach to Visual Perception* - affordance theory
