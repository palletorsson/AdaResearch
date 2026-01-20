# Bricolage_Chair - Summary

## Overview

The chair is vernacular bricolage frozen in time. This map demonstrates applied constraint satisfaction: a seat plane affords sitting, leg cylinders afford support, a back plane affords rest. When gravity, balance, and connectivity constraints are satisfied, "chair" emerges—not designed but discovered.

## Spatial Layout

An 11×13 assembly space, simpler than previous maps. The focus is application, not theory. Three key demonstration zones arranged vertically.

### Key Zones:
- **Entry Zone (rows 0-1)**: Transition from constraint theory
- **Comparison Zone (row 2)**: Parts inventory (left) vs assembled chair (right)
- **Central Focus (row 5)**: dark_sphere contemplation point
- **Builder Zone (row 7)**: Interactive chair_builder station
- **Exit Zone (rows 10-12)**: Transition to Sculpture

## Key Elements

### Interactables:
- **chair_parts_inventory** (row 2, left): Exploded view—seat plane, back plane, four leg cylinders laid out separately
- **chair_assembled** (row 2, right): Same parts assembled into functional chair
- **dark_sphere** (row 5, center): Transition point
- **chair_builder** (row 7, center): Interactive assembly station

### Utilities:
- **Spawn point** (top-left corner, height 4.5)
- **Teleporter** (bottom center): Proceeds to Bricolage_Sculpture

## Atmosphere

Returns to warm workshop lighting—back from constraint laboratory to making space. The simplicity (only three interactables) focuses attention on the assembly process rather than theory.

## Learning Sequence

1. Observe chair_parts_inventory: see parts as disassembled inventory
2. Observe chair_assembled: see same parts in functional configuration
3. Notice: the parts didn't change—only their arrangement
4. Pass through dark_sphere
5. Use chair_builder: interactively assemble chair from parts
6. Experience constraints: misplaced parts don't satisfy sit-ability
7. Discover: chair emerges when all constraints met
8. Exit to Sculpture—abstract assembly without function

## Design Intent

The inventory-to-assembly comparison makes the bricolage point viscerally: a chair isn't designed, it's discovered. The same inventory (planes, cylinders) could become table, bench, ladder. Chair emerges when sit-ability constraints are satisfied.

The interactive chair_builder is the map's pedagogical core: players don't watch assembly—they do it. Constraint violations are felt, not explained.

## Connection to Sequence

- **Position**: 5 of 7 in bricolage sequence
- **Precedes**: Bricolage_Sculpture
- **Follows**: Bricolage_Constraints
- **Theme**: First applied bricolage—functional structure from inventory
- **QFEP Layer**: Chair as local free energy minimum—stable configuration that satisfies constraints

## Theoretical Framework

### The Vernacular Chair
"Vernacular" architecture is building without architects—local knowledge, available materials, evolved forms. The chair is vernacular furniture: nobody invented it; cultures worldwide independently discovered it.

Chair-ness emerges from:
- **Inventory**: Horizontal plane (seat), vertical plane (back), vertical supports (legs)
- **Affordances**: Plane affords sitting, cylinders afford support
- **Constraints**: Gravity (legs must reach ground), balance (center of mass over legs), connectivity (parts must join)

### Joint Logic Over Form Logic
The map emphasizes joints—how parts connect—over form—what the chair looks like:
- **Seat-to-leg joints**: Must support weight, must be at corners
- **Seat-to-back joint**: Must maintain angle (90°-100°)
- **Leg-to-ground**: Must be level, must be stable

Get the joints right, and form follows. This is bricoleur thinking: work from parts outward, not from vision inward.

### From assemblies.json
The existing assemblies.json includes a Chair definition:
```json
"Chair": {
    "nodes": [...],  // Positioned instances
    "bonds": [...]   // Connections between parts
}
```
This map embodies that data structure in explorable form.
