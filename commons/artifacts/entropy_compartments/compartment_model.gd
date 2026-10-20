extends RefCounted
## Sixteen labelled sites, eight A (1) and eight B (0). No thermal dynamics.
var sites: Array[int] = [1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0]

func exchange(i: int, j: int) -> void:
	var held := sites[i]
	sites[i] = sites[j]
	sites[j] = held

func a_left() -> int:
	return sites.slice(0, 8).count(1)

func shannon_colour() -> float:
	var p := sites.count(1) / 16.0
	var h := 0.0
	for share in [p, 1.0 - p]:
		if share > 0.0: h -= share * log(share) / log(2.0)
	return h

func choose(n: int, k: int) -> int:
	var ways := 1
	for i in range(1, k + 1):
		ways = ways * (n - i + 1) / i
	return ways

func multiplicity() -> int:
	var k := a_left()
	return choose(8, k) * choose(8, 8 - k)

func boltzmann_over_kb() -> float:
	return log(float(multiplicity()))
