extends "res://commons/primitives/point/draw_dot.gd"

## A spatial sample remains in world space, or takes the plan's X/Z address.
## Height stays continuous: the comparison concerns the numbered floor, not
## another metre lattice suspended above it. Both pens keep draw_dot's sampling,
## capacity and world-space trails, without nearby whiteboard projection.
var grid_frame: Node3D
var snap_to_plan: bool = true

func _shape_sample(p: Vector3) -> Vector3:
	if not snap_to_plan or not is_instance_valid(grid_frame):
		return p
	var on_plan := grid_frame.to_local(p)
	on_plan.x = roundf(on_plan.x)
	on_plan.z = roundf(on_plan.z)
	return grid_frame.to_global(on_plan)
