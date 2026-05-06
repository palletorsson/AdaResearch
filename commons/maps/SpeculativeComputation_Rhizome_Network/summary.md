# Rhizome Network - Summary

## Overview
The second Post-Foundations Crisis map offers the constructive alternative to hierarchical classification: a rhizomatic cave system with four interconnected chambers and no center. A 10x10 grid uses height-5 walls and height-0 voids to create a topology where multiple paths connect every chamber, no chamber is privileged, and the center is empty. The rhizome_cave_demo generates a miniature cave via density fields and marching cubes.

## Spatial Layout
- **Dimensions**: 10x10 grid, max height 5
- **Architecture**: Four chambers in the corners (NW, NE, SW, SE) connected by one-tile-wide corridors along rows 2, 7 and columns 2, 7; central void (rows 4-5, columns 4-5) prevents hub-and-spoke routing
- **Topology**: Ring with cross-connections; multiple paths between any two chambers; no bottleneck, no root

## Key Elements

### Interactables
- **rhizome_cave_demo** (2,5) — Procedural cave generator using three-stage pipeline: growth nodes with probabilistic branching from four seeds, density field accumulation with falloff-based merging, marching cubes surface extraction producing continuous non-hierarchical topology

### Utilities
- **Spawn** at (0,0), **announcement board** at (1,0), **teleporter** at (1,8), **secondary spawn** at (1,9)

## Learning Sequence
1. Spawn in the NW chamber — one of four equivalent starting points
2. Navigate through corridors to other chambers — discover multiple paths, feel the absence of a canonical route
3. Encounter the central void — the map has no center, only periphery
4. Interact with rhizome_cave_demo — watch density-field merging produce connections between independently grown branches
5. Recognize: while the generation is hierarchical (nodes spawn children), the result is topologically continuous (marching cubes erases parentage)
6. Exit toward AdvancedLaboratory_Lab_Equipment_Simulation

## Design Intent
The rhizome responds to the bias map's diagnosis. Where tree-structured classification creates inequality through binary division, the rhizome offers connection without hierarchy. Deleuze and Guattari's six principles — connection, heterogeneity, multiplicity, asignifying rupture, cartography, decalcomania — are embedded in both the map layout and the procedural generation. The central void is the key architectural statement: because there is no hub, every path is equally valid.

## Connection to Sequence
- **Position**: 2/3 in postfoundationscrisis
- **Follows**: CriticalAlgorithms_Algorithmic_Bias_Visualization (bias as structural incompleteness)
- **Leads to**: AdvancedLaboratory_Lab_Equipment_Simulation (formal systems rebuilt with humility)
