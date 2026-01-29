# Procedural Generation Reorganization

**Date Started:** 2026-01-29  
**Status:** In Progress

## Overview

The `proceduralgeneration` sequence was too large (50+ algorithm folders, 90+ scenes) and lacked clear pedagogical progression. We split it into focused sub-sequences aligned with the QFEP framework.

## New Sequence Structure

### Created Sub-Sequences (Layer: systems / λ)

| Sequence | Focus | Maps | Status |
|----------|-------|------|--------|
| `grammar_systems` | Markov, N-grams, L-system basics | 8 | ✅ Sequence JSON created |
| `spatial_partitioning` | Voronoi, Delaunay, BSP, Poisson | 8 | ✅ Sequence JSON created |
| `constraint_solvers` | WFC, Boolean patterns | 8 | ✅ Sequence JSON created |
| `isosurfaces` | Marching cubes/squares, metaballs | 10 | ✅ Sequence JSON created |
| `higher_dimensions` | Tesseract, 16-cell, Penteract | 8 | ✅ Sequence JSON created |

### Existing Related Sequences

| Sequence | Layer | Notes |
|----------|-------|-------|
| `morphogenesis` | emergence (E(S)) | Reaction-diffusion moved here |
| `lsystems` | systems (λ) | Advanced L-systems, separate from grammar_systems basics |
| `patterngeneration` | systems (λ) | DLA, Penrose, Wang tiles |
| `cellularautomata` | emergence (E(S)) | Prerequisite for constraint_solvers |

## Files Modified

### Sequence JSONs
- [x] `grammar_systems.json` — NEW
- [x] `spatial_partitioning.json` — NEW
- [x] `constraint_solvers.json` — NEW
- [x] `isosurfaces.json` — NEW
- [x] `higher_dimensions.json` — NEW
- [x] `proceduralgeneration.json` — Converted to hub
- [x] `morphogenesis.json` — Updated algorithm_paths for reaction-diffusion

### Infrastructure
- [x] `fractal_index.json` — Added new sequences to "systems" layer + cross-references
- [x] `algorithms.json` — Split "Procedural Generation" into 9 categories (70+ scenes registered)
- [x] `GridSystem.gd` — Added new sequences to known_sequences (2 locations)
- [x] `GridUtilitiesComponent.gd` — Added new sequences to _is_sequence_name()

## Still TODO

### Map Folders Need Creation
The new sequences reference maps that don't exist yet:

```
commons/maps/
├── SpatialPartitioning_Voronoi_Intro/
├── SpatialPartitioning_Voronoi_3D/
├── SpatialPartitioning_Delaunay/
├── ... (8 maps)
├── ConstraintSolvers_WFC_Intro/
├── ConstraintSolvers_WFC_Entropy/
├── ... (8 maps)
├── Isosurfaces_Intro/
├── Isosurfaces_Marching_Cubes_Basic/
├── ... (10 maps)
├── HigherDimensions_Tesseract_Net/
├── ... (8 maps)
├── GrammarSystems_Markov_Chains/
├── ... (8 maps)
```

### Priority Documentation
Generate docs for existing ProceduralGeneration_* maps (43 folders, 0 docs):

**Priority 1 (Core concepts):** ✅ DONE
- [x] ProceduralGeneration_Wave_Function_Collapse — 4 docs created
- [x] ProceduralGeneration_Marching_Cubes_Algorithm — 4 docs created
- [x] ProceduralGeneration_Voronoi_Diagrams — 4 docs created
- [x] ProceduralGeneration_Reaction_Diffusion_Systems — 4 docs created

**Priority 2 (VR experiences):**
- [ ] ProceduralGenerationMarchingCubesSculpture
- [ ] ProceduralGenerationTesseractErrorTunnel
- [ ] ProceduralGenerationWfcDungeonGenerator

### VR Interactivity Improvements
Based on VR research (Half-Life: Alyx, Boneworks, Bootstrap Island):

| Scene | Current | Enhancement Needed |
|-------|---------|-------------------|
| WFC | Auto-runs, visual only | Let player manually collapse cells |
| Voronoi | Display only | Hand-place points |
| Marching Cubes | Display only | Sculpt with hands |
| Reaction-Diffusion | Has VR presets ✓ | Good as-is |

## QFEP Connection

Procedural generation embodies QFEP:

| Sub-Sequence | QFEP Mapping |
|--------------|--------------|
| grammar_systems | F (rules) → E(S) (variety) |
| spatial_partitioning | λ (edge between continuous/discrete) |
| constraint_solvers | F (constraints) + E(S) (random selection) → emergence |
| isosurfaces | λ (threshold = edge of chaos made geometric) |
| higher_dimensions | Pure F (Platonic forms, projection) |
| morphogenesis | E(S) → F (entropy generates order) |

## Algorithm Registry Categories (algorithms.json)

New categories created:
1. Grammar Systems (4 scenes)
2. Spatial Partitioning (6 scenes)
3. Constraint Solvers (WFC) (12 scenes)
4. Isosurfaces (Marching) (14 scenes)
5. Higher Dimensions (4D/5D) (10 scenes)
6. Morphogenesis (Reaction-Diffusion) (5 scenes)
7. Growth Algorithms (5 scenes)
8. Caves & Mazes (6 scenes)
9. Procedural Misc (8 scenes)

## Session Notes

### 2026-01-29
- Fixed lambda_slider and phi_slider grabbability (XRTools handle hierarchy issue)
- Researched VR interaction design (HL:Alyx, Boneworks, Bootstrap Island)
- Split proceduralgeneration into 5 sub-sequences
- Moved reaction-diffusion references to morphogenesis
- Updated all registries and sequence lists
- Verified no broken links (algorithm files stay at original paths)

## Related Docs
- `doc/QFEP_GAMWELL_MAPPING.md` — Theory foundation
- `doc/VR_GAMEPLAY_DESIGN.md` — Capacity progression
- `doc/NEW_CAPACITY_ARTIFACTS.md` — 15 artifacts spec
