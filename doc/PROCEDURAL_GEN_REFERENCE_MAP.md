# Procedural Generation Reference Map
**Generated**: 2026-01-29
**Purpose**: Track all references to procedural generation algorithms before reorganization

## Summary
- **Total algorithms**: 49
- **Referenced in sequences**: 21 (HIGH RISK - move carefully)
- **Not referenced**: 28 (LOW RISK - safe to move first)
- **L-systems duplicate**: 1 algorithm exists in 2 locations

## Referenced Algorithms (HIGH RISK)

### constraint_solvers.json
- `wave_function_collapse/` → Line 38
- `wfc3D/` → Line 39
- `wfcRooms/` → Line 40
- `randomboolean/` → Line 41

### grammar_systems.json
- `markov_chains/` → Line 39
- `markov_chains_tree/` → Line 40
- Note: Also references `algorithms/l_systems/` (top-level, not in proceduralgeneration)

### higher_dimensions.json
- `tesseractnetspace/` → Line 39
- `tesseracttunnel/` → Line 40
- `sixteencellnetspace/` → Line 41
- `penteractdoubleprojection/` → Line 42
- `tessellatingportal/` → Line 43

### morphogenesis.json
- `reactiondiffusion/` → Lines 60-63 (multiple scene paths)

### isosurfaces.json
- `marchingcave/` → Line 40
- `marchingsquares/` → Line 41
- `metaballs/` → Line 42
- `implicitsurfacemodeling/` → Line 43

### spatial_partitioning.json
- `voronoi_diagrams/` → Line 38
- `voronoi_diagram_3d/` → Line 39
- `delaunay_triangulation_3d_cell/` → Line 40
- `binary_space_partitioning/` → Line 41
- `poisson_disk_sampling_3d/` → Line 42

### Other References
- **lsystems.json**: References `algorithms/l_systems/` (top-level folder)
- **cellular_automata.json** (artifact registry): References procedural generation

## Unreferenced Algorithms (LOW RISK - 28 algorithms)

Safe to move first as they're not in active sequences:

1. `berninicolumns/`
2. `branchinggrowthalgorithm/`
3. `branchinggrowthalgorithmcontinued/`
4. `cave_generator/`
5. `caverandomwalk/`
6. `crackpropagation_ca/`
7. `cubemound/`
8. `dewcoveredfoliage/`
9. `genetic_programming/`
10. `infinite_voxel_floor/`
11. `layeredmembrane/`
12. **`lsystem/` (DUPLICATE - to be removed)**
13. `mazegeneration/`
14. `metaballgenerator/` (NOTE: different from `metaballs/` which IS referenced)
15. `mirroredcellularautomata/`
16. `modernistchairs/`
17. `mushrooms/`
18. `particlebasedsimulation/`
19. `percolationnetwork_ca/`
20. `proceduralstrategies/`
21. `slimemold/`
22. `space_colonization_algorithm/`
23. `spherenetwork/`
24. `tilepatterns/`
25. `treegen/`
26. `WFC3DGenerator/` (NOTE: different from `wfc3D/` which IS referenced)
27. `WFCSculptureGenerator/`
28. `wireframe/`

## L-Systems Duplicate Issue

**Problem**: L-Systems exists in two locations

### Top-Level (KEEP THIS ONE - per user decision)
- **Path**: `algorithms/l_systems/`
- **Contents**: 5 folders: Architecture, ContextSensitive, Ecosystem, Growth, Hilbert3D
- **Referenced by**:
  - `commons/maps/sequences/grammar_systems.json` line 41
  - `commons/maps/sequences/lsystems.json` (entire sequence)
  - `commons/maps/sequences/fractals.json` (likely)
  - `commons/maps/sequences/swarmintelligence.json` (likely)

### Nested (REMOVE THIS ONE)
- **Path**: `algorithms/proceduralgeneration/lsystem/`
- **Status**: NOT currently referenced in any sequence
- **Action**: DELETE after confirming no references

### L-Systems Audit Commands
```bash
# Search for references to both locations
grep -r "algorithms/l_systems" commons/maps/sequences/
grep -r "algorithms/proceduralgeneration/lsystem" commons/maps/sequences/

# Search in artifact registries
grep -r "l_systems" commons/artifacts/registry/
grep -r "lsystem" commons/artifacts/registry/
```

## Proposed Grouping Structure

Based on generative paradigm (per user decision):

### space_filling/ (4 algorithms)
- `wave_function_collapse/` ⚠️ HIGH RISK
- `wfc3D/` ⚠️ HIGH RISK
- `wfcRooms/` ⚠️ HIGH RISK
- `WFC3DGenerator/` ✅ LOW RISK
- `WFCSculptureGenerator/` ✅ LOW RISK

### growth_systems/ (12 algorithms)
- `branchinggrowthalgorithm/` ✅ LOW RISK
- `branchinggrowthalgorithmcontinued/` ✅ LOW RISK
- `cave_generator/` ✅ LOW RISK
- `caverandomwalk/` ✅ LOW RISK
- `genetic_programming/` ✅ LOW RISK
- `mushrooms/` ✅ LOW RISK
- `slimemold/` ✅ LOW RISK
- `space_colonization_algorithm/` ✅ LOW RISK
- `treegen/` ✅ LOW RISK
- `reactiondiffusion/` ⚠️ HIGH RISK
- `crackpropagation_ca/` ✅ LOW RISK
- `percolationnetwork_ca/` ✅ LOW RISK

### noise_terrain/ (1 algorithm)
- (No pure noise algorithms found - they may be in primitives)

### graph_based/ (5 algorithms)
- `voronoi_diagrams/` ⚠️ HIGH RISK
- `voronoi_diagram_3d/` ⚠️ HIGH RISK
- `delaunay_triangulation_3d_cell/` ⚠️ HIGH RISK
- `binary_space_partitioning/` ⚠️ HIGH RISK
- `poisson_disk_sampling_3d/` ⚠️ HIGH RISK

### hybrid_complex/ (13 algorithms)
- `berninicolumns/` ✅ LOW RISK
- `cubemound/` ✅ LOW RISK
- `dewcoveredfoliage/` ✅ LOW RISK
- `infinite_voxel_floor/` ✅ LOW RISK
- `layeredmembrane/` ✅ LOW RISK
- `marchingcave/` ⚠️ HIGH RISK
- `marchingsquares/` ⚠️ HIGH RISK
- `metaballs/` ⚠️ HIGH RISK
- `metaballgenerator/` ✅ LOW RISK
- `implicitsurfacemodeling/` ⚠️ HIGH RISK
- `modernistchairs/` ✅ LOW RISK
- `spherenetwork/` ✅ LOW RISK
- `wireframe/` ✅ LOW RISK

### procedural_logic/ (8 algorithms)
- `markov_chains/` ⚠️ HIGH RISK
- `markov_chains_tree/` ⚠️ HIGH RISK
- `randomboolean/` ⚠️ HIGH RISK
- `mazegeneration/` ✅ LOW RISK
- `mirroredcellularautomata/` ✅ LOW RISK
- `particlebasedsimulation/` ✅ LOW RISK
- `proceduralstrategies/` ✅ LOW RISK
- `tilepatterns/` ✅ LOW RISK

### higher_dimensional/ (5 algorithms)
- `tesseractnetspace/` ⚠️ HIGH RISK
- `tesseracttunnel/` ⚠️ HIGH RISK
- `sixteencellnetspace/` ⚠️ HIGH RISK
- `penteractdoubleprojection/` ⚠️ HIGH RISK
- `tessellatingportal/` ⚠️ HIGH RISK

## Update Checklist Template

For EACH moved algorithm, verify:

- [ ] Searched for old path in sequences: `grep -r "old_name" commons/maps/sequences/`
- [ ] Searched for old path in registries: `grep -r "old_name" commons/artifacts/registry/`
- [ ] Updated `algorithm_paths` in relevant sequence JSON files
- [ ] Moved folder: `git mv algorithms/proceduralgeneration/old_name algorithms/proceduralgeneration/group/old_name`
- [ ] Tested sequence loads (if high-risk)
- [ ] Verified no "No map data found" errors
- [ ] Committed change: `git commit -m "Move old_name to group/"`

## Recommended Move Order

### Phase 1: Duplicate Resolution (FIRST)
1. Audit `algorithms/proceduralgeneration/lsystem/` references
2. Confirm it's not referenced
3. Delete `algorithms/proceduralgeneration/lsystem/` folder
4. Commit: "Remove duplicate lsystem folder, canonical location is algorithms/l_systems/"

### Phase 2: Test Move (ONE low-risk algorithm)
1. Pick: `wireframe/` (simple, unreferenced, easy to verify)
2. Create group folder: `algorithms/proceduralgeneration/hybrid_complex/`
3. Move: `git mv algorithms/proceduralgeneration/wireframe algorithms/proceduralgeneration/hybrid_complex/wireframe`
4. Test game launch
5. Commit: "Test move: wireframe to hybrid_complex/"

### Phase 3: Low-Risk Batch (5-10 algorithms)
Pick from unreferenced list:
1. `berninicolumns/` → hybrid_complex/
2. `cubemound/` → hybrid_complex/
3. `modernistchairs/` → hybrid_complex/
4. `spherenetwork/` → hybrid_complex/
5. `mushrooms/` → growth_systems/
6. `treegen/` → growth_systems/
7. `mazegeneration/` → procedural_logic/
8. `tilepatterns/` → procedural_logic/

### Phase 4: High-Risk Moves (AFTER low-risk proven)
- Update sequence JSON `algorithm_paths` first
- Move folders
- Test EACH sequence individually
- Commit after each successful sequence test

## Notes

- **No hardcoded paths in .gd files** - all paths come from sequence JSON files
- **algorithm_paths field is critical** - this is where paths are defined
- **Legacy maps** in proceduralgeneration.json use map names, not direct paths
- **proceduralgeneration.json is ACTIVE** - extra care needed for referenced algorithms
- **Git branch recommended**: Create `procedural-gen-reorganization` branch before starting
