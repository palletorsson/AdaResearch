# Bricolage_Constraints - Summary

## Overview

What pushes back. Structure emerges not from design but from constraint satisfaction—when gravity, balance, connectivity, and triangulation stop complaining, the assembly has found stable form. This map teaches "constraint literacy": the ability to read what physical reality demands.

## Spatial Layout

A 13×15 demonstration space with three pairs of constraint demonstrations (fail/pass). Each pair shows the same assembly configuration violating and satisfying a constraint. Height 3 maximum for demonstrations with vertical extent.

### Key Zones:
- **Entry Zone (rows 0-2)**: Clipboard introduction (constraint_catalog_axioms)
- **Gravity Zone (row 3)**: Gravity fail (left pedestal), gravity pass (right pedestal)
- **Central Focus (row 5)**: dark_sphere contemplation point
- **Balance Zone (row 7)**: Balance fail (left), balance pass (right)
- **Triangulation Zone (row 11)**: Triangulation fail (left), triangulation pass (right)
- **Exit Zone (rows 13-14)**: Transition to Chair Assembly

## Key Elements

### Interactables:
- **clipboard#constraint_catalog_axioms** (row 1, center): Full constraint catalog
- **gravity_fail_demo** (row 3, left): Unsupported parts that would fall
- **gravity_pass_demo** (row 3, right): Same parts, properly supported
- **dark_sphere** (row 5, center): Transition point
- **balance_fail_demo** (row 7, left): Assembly with center of mass outside base
- **balance_pass_demo** (row 7, right): Same parts, center of mass over base
- **triangulation_fail_demo** (row 11, left): Square frame that racks under load
- **triangulation_pass_demo** (row 11, right): Triangulated frame that holds rigid

### Utilities:
- **Spawn point** (top-left corner, height 4.5)
- **Teleporter** (bottom center): Proceeds to Bricolage_Chair

## Atmosphere

Slightly cooler lighting than previous maps—transitioning from warm workshop to laboratory. Directional light emphasizes the physicality of the demonstrations. The fail/pass pairing creates pedagogical contrast.

## Learning Sequence

1. Read constraint_catalog_axioms—understand what constraints exist
2. Examine gravity demonstrations: same parts, different support structures
3. Observe: unsupported = fail, supported = pass
4. Pass through dark_sphere
5. Examine balance demonstrations: same parts, different weight distribution
6. Observe: cantilevered without counterweight = fail, balanced = pass
7. Examine triangulation demonstrations: same rectangle, different bracing
8. Observe: unbraced = racking/collapse, triangulated = rigid
9. Recognize: constraints are teachers, not obstacles
10. Exit to Chair Assembly—apply constraint knowledge

## Design Intent

The fail/pass pairing makes constraints visceral. Players don't just read about gravity—they see the same parts in "wrong" and "right" configurations. The pedagogical message: constraints aren't arbitrary rules but physical realities that reward understanding.

## Connection to Sequence

- **Position**: 4 of 7 in bricolage sequence
- **Precedes**: Bricolage_Chair (first application)
- **Follows**: Bricolage_Arrays_as_Probes
- **Theme**: Reading what physical reality demands
- **QFEP Layer**: Constraints reduce E(S)—they collapse the possibility space to stable configurations

## Theoretical Framework

### Constraint Satisfaction as Structure Discovery
The engineer designs to satisfy known constraints. The bricoleur discovers constraints through assembly failure:
- Part falls → gravity constraint violated
- Assembly tips → balance constraint violated
- Frame racks → triangulation constraint violated

Each failure is information. The constraint "speaks" through failure.

### The Core Constraints
| Constraint | What It Demands | Failure Mode |
|-----------|----------------|--------------|
| Gravity | Path to ground | Floating, falling |
| Balance | Center of mass over base | Tipping, toppling |
| Connectivity | Parts must touch | Gaps, disconnection |
| Triangulation | Triangles for rigidity | Racking, collapse |

### Constraint Hierarchy
Not all constraints are equal:
1. **Gravity** - Absolute (cannot be negotiated)
2. **Connectivity** - Required (parts must touch to bond)
3. **Balance** - Conditional (can be stabilized by anchoring)
4. **Triangulation** - Situational (only matters under load)
