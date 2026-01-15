# Transformation Intro - Map Summary

## Overview
Transformation_Intro serves as the gateway to the transformation sequence, presenting cubes in various states of spatial modification. The map establishes that position, rotation, and scale are not properties of objects but operations performed upon them. Players encounter transformation as a verb before understanding it as a concept.

## Spatial Layout
- **Dimensions**: 7×14 grid
- **Architecture**: L-shaped platform with elevated pedestals and a corridor leading south
- **Height**: Multi-level with pedestals at varying heights

## Key Elements

### Interactables
- **cube_scene** (2,3) - Static reference cube at 0.2 scale
- **transformation_cube** (3,3) - Interactive transformation workstation
- **rotating_cube** (4,3) - Continuously spinning demonstration
- **pick_up_cube** (5,3) - Grabbable cube for direct manipulation
- **combo_cube_visual** (6,3) - Combined transformation visualization
- **rotatescalecubes** (4,2) - Multi-cube rotation/scale array
- **pickup_cube_static/transforming/rotating** - Progressive pickup variants
- **pickup_gate** - Completion checkpoint requiring pickups

### Utilities
- **Waypoint** (5,4) - Navigation marker
- **3D Text** - "Space is what becomes perceptible through transformation"
- **Teleporter** - Exit to next map
- **Score point** - Completion marker

## Atmosphere
- **Lighting**: Cool ambient (0.4, 0.4, 0.5) with warm directional
- **Background**: Sky blue
- **Mood**: Exploratory, demonstrative

## Learning Sequence
1. Player enters and sees array of cube variants
2. Observes static, rotating, and transforming cubes side by side
3. Interacts with transformation_cube workstation
4. Picks up and manipulates grabbable cubes
5. Progresses through corridor collecting pickup variants
6. Reaches gate requiring collected pickups to proceed

## Design Intent
The map functions as a **taxonomy of transformation** - showing translation, rotation, and scale as distinct but composable operations. By placing different cube states adjacent to each other, players can compare and contrast what each transformation does to the same base geometry.

## Connection to Sequence
- **Position in transformation sequence**: 1/6
- **Precedes**: Trans_Translate_1 (focused translation)
- **Establishes**: The vocabulary of spatial transformation
