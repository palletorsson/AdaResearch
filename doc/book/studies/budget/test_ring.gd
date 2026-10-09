extends SceneTree
## The ring's test. It needs no window. From the kit's folder:
##   godot --headless --path . --xr-mode off --script res://test_ring.gd

const Surfaces := preload("res://guests/budget/surfaces.gd")
const TOLERANCE := 0.01   # less than 1% of the radius short of the circle counts as round

func _initialize() -> void:
	var passed := checks()
	print("the ring's test passed" if passed else "the ring's test FAILED")
	quit(0 if passed else 1)

func checks() -> bool:
	for n in [3, 6, 12, 24, 48, 96]:
		print(n, " segments: ", Surfaces.gap_to_circle(n))
	assert(Surfaces.gap_to_circle(12) > TOLERANCE, "12 segments are not round yet")
	assert(Surfaces.gap_to_circle(24) < TOLERANCE, "24 segments are round enough")
	return true
