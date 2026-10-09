extends "res://algorithms/cellularautomata/sierpinski_pyramid/SierpinskiPyramid.gd"
## Exercise the production recursion without allocating its cube scenes.
var recorded: Array[Vector3] = []
func _init() -> void:generate_on_ready=false
func _spawn_cube(at: Vector3) -> void:
	recorded.append(at)
	leaf_count+=1
