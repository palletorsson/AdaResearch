# Algorithms Folder Audit

Generated: 2026-01-30

## Summary

- **60 total folders**
- **41 with README** ✓
- **19 without README** (see below)

## READMEs Created This Session

| Folder | Files | Notes |
|--------|-------|-------|
| `cellularautomata` | 41 gd, 41 tscn | 21 subfolders, rich content |
| `color` | 31 gd, 38 tscn | 25 subfolders, perception + glitch |
| `forces` | 15 gd, 10 tscn | NoC Chapter 2 |
| `oscillation` | 18 gd, 18 tscn | NoC Chapter 3 |
| `steering` | 15 gd, 15 tscn | NoC Chapter 5 |
| `softbodies` | 9 gd, 13 tscn | Cloth, jelly physics |
| `particles` | 9 gd, 7 tscn | NoC Chapter 4 |
| `transformation` | 10 gd, 10 tscn | Geometric transforms |

## Action Required: Merge/Delete

### DELETE (empty)

| Folder | Reason |
|--------|--------|
| `tools` | Only .uid files, no actual code |

### MERGE (sparse → existing)

| Sparse Folder | Merge Into | Reason |
|---------------|-----------|--------|
| `audio` | `proceduralaudio` | Only 1 demo scene |
| `light` | `effects` | Only 2 flashlight scenes |
| `voronoi` | `computationalgeometry` | Only 1 algorithm |
| `geometry` | `computationalgeometry` | Only 1 floor pattern |
| `sortingalgorithms` | `datastructures` | Only 1 visualization |

### MERGE (duplicates)

| Folder A | Folder B | Recommendation |
|----------|----------|----------------|
| `array` | `arrays` | Merge into `arrays` (has more content) |
| `lsystems` | `l_systems` | Merge into `lsystems` (has README) |

## Still Need READMEs

### High Priority (has significant content)

| Folder | .gd | .tscn | Notes |
|--------|-----|-------|-------|
| `neuralnetworks` | 7 | 5 | Neural network visualizations |
| `neuroevolution` | 6 | 6 | Evolutionary neural networks |
| `pathfinding` | 4 | 2 | A*, Dijkstra |
| `physics` | 8 | 8 | Generic physics demos |
| `shaders` | 5 | 7 | Shader examples |
| `speech` | 7 | 6 | Speech/phoneme processing |
| `postprocessing` | 2 | 2 | Post-processing effects |
| `cryptography` | 1 | 1 | Crypto visualization |

### Low Priority (sparse, consider merge)

| Folder | .gd | .tscn | Recommendation |
|--------|-----|-------|----------------|
| `array` | 12 | 11 | Merge → `arrays` |
| `arrays` | 5 | 4 | Keep (merge target) |
| `effects` | 1 | 1 | Merge → `postprocessing`? |
| `l_systems` | 5 | 5 | Merge → `lsystems` |
| `visualization` | 2 | 2 | Merge → `datastructures`? |

## JSON Files Fixed

These sequence files had invalid JSON (trailing commas, typos):

- `array_tutorial.json` — trailing comma
- `fractals.json` — trailing commas, duplicate entry
- `higher_dimensions.json` — stray `],`
- `isosurfaces.json` — stray `],`
- `softbodies.json` — trailing comma
- `transformations.json` — key name mismatch (`transformation` vs `transformations`)

## Next Steps

1. Execute merges (see commands below)
2. Delete empty `tools` folder
3. Write remaining READMEs (8 high priority)
4. Update existing READMEs that are out of sync (e.g., `fractals/README.md` mentions cellular automata)

## Merge Commands

```powershell
# Backup first!
# Move voronoi → computationalgeometry
Move-Item algorithms/voronoi/* algorithms/computationalgeometry/ -Force
Remove-Item algorithms/voronoi -Recurse

# Move geometry → computationalgeometry  
Move-Item algorithms/geometry/* algorithms/computationalgeometry/ -Force
Remove-Item algorithms/geometry -Recurse

# Move sortingalgorithms → datastructures
Move-Item algorithms/sortingalgorithms/* algorithms/datastructures/ -Force
Remove-Item algorithms/sortingalgorithms -Recurse

# Move audio → proceduralaudio
Move-Item algorithms/audio/* algorithms/proceduralaudio/ -Force
Remove-Item algorithms/audio -Recurse

# Move light → effects (or delete if effects also sparse)
Move-Item algorithms/light/* algorithms/effects/ -Force
Remove-Item algorithms/light -Recurse

# Delete empty tools
Remove-Item algorithms/tools -Recurse

# Merge array → arrays
Move-Item algorithms/array/* algorithms/arrays/ -Force
Remove-Item algorithms/array -Recurse

# Merge l_systems → lsystems
Move-Item algorithms/l_systems/* algorithms/lsystems/ -Force
Remove-Item algorithms/l_systems -Recurse
```
