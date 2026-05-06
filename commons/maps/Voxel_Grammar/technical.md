# Voxel Grammar - Technical Tutorial

This chapter extends grammar concepts from sequence-based generation into 3D occupancy systems.

## The Concept as Data

Grammar in voxel systems can be represented as a local rule over neighborhood state:

```gdscript
func apply_voxel_rule(current: int, neighbors: int) -> int:
	# Example survival/birth grammar (CA-style)
	if current == 1 and neighbors >= 4 and neighbors <= 6:
		return 1
	if current == 0 and neighbors == 5:
		return 1
	return 0
```

A threshold grammar from a scalar field uses a comparator instead of explicit symbol rewriting:

```gdscript
func voxel_from_density(density: float, iso_level: float) -> int:
	return 1 if density >= iso_level else 0
```

## Shared Grammar Pattern

All artifacts in this map implement the same abstract loop:

1. Read local state.
2. Apply a finite rule set.
3. Write updated state.
4. Iterate.

This general form is independent of substrate:
- L-system: symbols and productions
- Cellular automata: cell states and neighborhood transitions
- Voxel noise: sampled field values and threshold rules

## Minimal Unified Interface

```gdscript
class_name VoxelGrammarStep

func step(grid: Array, rule_callable: Callable) -> Array:
	var next := []
	for z in grid.size():
		next.append([])
		for x in grid[z].size():
			var local_state = grid[z][x]
			var neighborhood = count_neighbors(grid, x, z)
			next[z].append(rule_callable.call(local_state, neighborhood))
	return next
```

A production-system grammar can use the same shape if `local_state` becomes a symbol token and `neighborhood` becomes context.

## VR Implementation Notes

- Keep voxel preview scales moderate (`0.1` to `0.5`) to preserve performance and legibility.
- Place grammar variants close enough for direct bodily comparison.
- Use annotation boards at transition points where rule interpretation shifts.

## Key Takeaway

Voxel grammar is a rule engine, not a specific algorithm. Once rule application is local and iterative, symbolic grammars and volumetric generation become different renderings of the same computational logic.
