extends RefCounted
## Four occupied sites. A way is a colour pattern, not an identity permutation.
const PARTITIONS := [[0,0,0,0], [0,0,1,1], [0,0,1,2], [0,1,2,3]]
var stage := 0
var occupants := [0,1,2,3]
const COLOURS := [1,0,1,0] # A deliberately kept, balanced batch.

func colours() -> Array:
	return occupants.map(func(id): return COLOURS[id])

func counts(pattern: Array) -> Array:
	var result := [0,0,0,0]
	for site in 4: result[PARTITIONS[stage][site]] += pattern[site]
	return result

func arrangements() -> Array:
	var result := []
	var target := counts(colours())
	for mask in 16:
		var pattern := []
		for site in 4: pattern.append((mask >> site) & 1)
		if pattern.count(1) == 2 and counts(pattern) == target: result.append(pattern)
	return result

func exchange(from: int, to: int) -> void:
	var held: int = occupants[from]
	occupants[from] = occupants[to]
	occupants[to] = held
