# Voxel Grammar - Map Summary

## Overview
Voxel_Grammar teaches that "grammar" means local rewrite constraints, not just linguistic syntax. The map stages three generative families side by side: L-system branching, cellular automata growth, and thresholded voxel fields.

## Spatial Layout
- Dimensions: 9x11 grid
- Architecture: A simple gallery with raised pedestals at the corners and center
- Flow: Enter, compare symbolic grammars first, then move into voxel occupancy systems

## Key Elements

### Interactables
- CityGenerator at (2,2) introduces explicit symbolic production rules.
- ContextSensitiveTree at (6,2) demonstrates grammar conditioned by local context.
- cellular_automata_3d_tree at (4,5) shows neighborhood-state grammar in voxel form.
- voxelnoise at (2,8) demonstrates threshold grammar from scalar fields.
- VoxelNoiseROIs at (6,8) extends threshold grammar to region-specific rule sets.

### Utilities
- Spawn at (0,0) gives immediate line-of-sight to the first two grammar artifacts.
- Annotation boards at (4,2) and (4,8) support before-and-after comparisons.
- Teleporter at (4,10) advances to the next map in sequence.

## Learning Sequence
1. Start with symbolic grammar systems (CityGenerator, ContextSensitiveTree).
2. Move to cellular automata where grammar is encoded as neighborhood transitions.
3. Compare to voxel noise systems where occupancy is rule-based thresholding.
4. Recognize the shared pattern: local rule application, global morphological emergence.
5. Exit with the teleporter after connecting symbolic and volumetric grammar.

## Design Intent
The map uses minimal architecture to foreground structural comparison rather than spectacle. All major artifacts are arranged as a single argument: grammar can be symbolic, topological, or scalar, but each produces form through constrained local decisions.

## Connection to Sequence
- Sequence: grammar_systems
- Follows: Markov and N-gram maps focused on symbolic sequence generation
- Extends toward: spatial grammar applications in L-systems and volumetric generation
