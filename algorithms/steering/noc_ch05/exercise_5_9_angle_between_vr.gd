extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_VEC_A := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_VEC_B := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var angle_a: float = 0.0
@export var angle_b: float = PI / 3.0

var _sim_root: Node3D
var _vector_a: MeshInstance3D
var _vector_b: MeshInstance3D
var _arc_mesh: MeshInstance3D
var _status_label: Label3D
var _controller_root: Node3D

func _ready() -> void:
	_setup_environment()
	_spawn_scene()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 22
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	_controller_root = Node3D.new()
	_controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(_controller_root)

	var angle_a_controller := CONTROLLER_SCENE.instantiate()
	angle_a_controller.parameter_name = "Angle A"
	angle_a_controller.min_value = 0.0
	angle_a_controller.max_value = TAU
	angle_a_controller.default_value = angle_a
	angle_a_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(angle_a_controller)
	angle_a_controller.value_changed.connect(func(v: float) -> void:
		angle_a = v
		_update_vectors()
	)
	angle_a_controller.set_value(angle_a)

	var angle_b_controller := CONTROLLER_SCENE.instantiate()
	angle_b_controller.parameter_name = "Angle B"
	angle_b_controller.min_value = 0.0
	angle_b_controller.max_value = TAU
	angle_b_controller.default_value = angle_b
	angle_b_controller.position = Vector3(0, -0.18, 0)
	angle_b_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(angle_b_controller)
	angle_b_controller.value_changed.connect(func(v: float) -> void:
		angle_b = v
		_update_vectors()
	)
	angle_b_controller.set_value(angle_b)

func _spawn_scene() -> void:
	_vector_a = _create_arrow(MAT_VEC_A)
	_sim_root.add_child(_vector_a)

	_vector_b = _create_arrow(MAT_VEC_B)
	_sim_root.add_child(_vector_b)

	_arc_mesh = MeshInstance3D.new()
	_sim_root.add_child(_arc_mesh)

	_update_vectors()

func _create_arrow(mat: Material) -> MeshInstance3D:
	var arrow := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.01
	mesh.bottom_radius = 0.01
	mesh.height = 0.25
	arrow.mesh = mesh
	arrow.material_override = mat
	return arrow

func _update_vectors() -> void:
	if not _vector_a or not _vector_b:
		return
		
	var vec_a := Vector3(cos(angle_a), sin(angle_a), 0) * 0.25
	var vec_b := Vector3(cos(angle_b), sin(angle_b), 0) * 0.25
	var center := Vector3(0, 0.5, 0)

	_vector_a.position = center + vec_a * 0.5
	_vector_a.rotation = Vector3(0, 0, angle_a - PI / 2)

	_vector_b.position = center + vec_b * 0.5
	_vector_b.rotation = Vector3(0, 0, angle_b - PI / 2)

	var between = abs(angle_b - angle_a)
	if between > PI:
		between = TAU - between

	_update_arc(center, 0.12, angle_a, angle_b)

	_status_label.text = "Angle Between | %.1f°" % rad_to_deg(between)

func _update_arc(center: Vector3, radius: float, start_angle: float, end_angle: float) -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var segments := 20
	var angle_range := end_angle - start_angle
	if abs(angle_range) > PI:
		if angle_range > 0:
			angle_range -= TAU
		else:
			angle_range += TAU

	for i in range(segments + 1):
		var t := float(i) / segments
		var angle := start_angle + angle_range * t
		var pos := center + Vector3(cos(angle), sin(angle), 0) * radius
		mesh.surface_set_color(Color(1.0, 0.8, 0.95, 0.6))
		mesh.surface_add_vertex(pos)

	mesh.surface_end()
	_arc_mesh.mesh = mesh

func _process(_delta: float) -> void:
	pass
