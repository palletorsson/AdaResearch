extends SoftBody3D

const SIZE := Vector3(0.16, 1.2, 1.8)
var rest_points: PackedVector3Array
var pins: Array[int] = []

func _init() -> void:
	var surface := BoxMesh.new()
	surface.size = SIZE
	surface.subdivide_height = 6
	surface.subdivide_depth = 8
	rest_points = surface.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
	mesh = surface
	total_mass = 1.0
	linear_stiffness = 0.5
	damping_coefficient = 0.1
	pressure_coefficient = 0.0
	simulation_precision = 5
	collision_layer = 1
	collision_mask = 1 | 4 | (1 << 17) | (1 << 18)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("c98288")
	material_override = finish
	for i in rest_points.size():
		var p := rest_points[i]
		var edge := absf(absf(p.y) - SIZE.y * 0.5) < 0.001 or absf(absf(p.z) - SIZE.z * 0.5) < 0.001
		if edge:
			set_point_pinned(i, true)
			pins.append(i)
