extends SoftBody3D

const EDGE := 0.3
const DIVISIONS := 4
var rest_points: PackedVector3Array
var anchor_index := -1

func _init() -> void:
	var box := BoxMesh.new()
	box.size = Vector3.ONE * EDGE
	box.subdivide_width = DIVISIONS
	box.subdivide_height = DIVISIONS
	box.subdivide_depth = DIVISIONS
	rest_points = box.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	mesh = box
	simulation_precision = 5
	total_mass = 1.0
	collision_layer = 1
	collision_mask = 1 | 4 | (1 << 17) | (1 << 18)
	reset_settings()
	anchor_index = crown_index(rest_points)
	set_point_pinned(anchor_index, true)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.2, 0.9, 0.5, 0.8)
	finish.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	finish.cull_mode = BaseMaterial3D.CULL_DISABLED
	finish.roughness = 0.2
	material_override = finish

func crown_index(points: PackedVector3Array) -> int:
	var selected := -1
	var nearest := INF
	for i in points.size():
		var p := points[i]
		if absf(p.y - EDGE * 0.5) > 0.001:
			continue
		var distance := Vector2(p.x, p.z).length_squared()
		if distance < nearest:
			nearest = distance
			selected = i
	assert(selected >= 0, "The mesh needs a top face.")
	return selected

func reset_settings() -> void:
	linear_stiffness = 0.5
	damping_coefficient = 0.01
	pressure_coefficient = 1.0
