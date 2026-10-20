extends SoftBody3D

const WIDTH := 1.2
const HEIGHT := 1.4
const COLUMNS := 10
var rest_points: PackedVector3Array
var pins: Array[int] = []
var mode := 0

func _init() -> void:
	var surface := PlaneMesh.new()
	surface.orientation = PlaneMesh.FACE_Z
	surface.size = Vector2(WIDTH, HEIGHT)
	surface.subdivide_width = COLUMNS
	surface.subdivide_depth = 12
	rest_points = surface.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
	mesh = surface
	simulation_precision = 5
	total_mass = 1.0
	linear_stiffness = 0.34
	damping_coefficient = 0.05
	pressure_coefficient = 0.0
	collision_layer = 1
	collision_mask = 1 | 4 | (1 << 17) | (1 << 18)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("e7dbce")
	finish.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = finish
	set_pins(0)

func set_pins(next_mode: int) -> void:
	assert(next_mode in [0, 1, 2])
	mode = next_mode
	pins.clear()
	for i in rest_points.size():
		var p := rest_points[i]
		var top := absf(p.y - HEIGHT * 0.5) < 0.001
		var corner := absf(absf(p.x) - WIDTH * 0.5) < 0.001
		var keep := top and (mode == 0 or (mode == 1 and corner))
		set_point_pinned(i, keep)
		if keep:
			pins.append(i)
