# ===========================================================================
# NOC Example 1.3: Vector Subtraction
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_VEC_A := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_VEC_B := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")
const MAT_RESULT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var vector_a: Vector3 = Vector3(0.2, 0.15, 0)
@export var vector_b: Vector3 = Vector3(-0.1, 0.25, 0)

var _sim_root: Node3D
var _arrow_a: MeshInstance3D
var _arrow_b: MeshInstance3D
var _arrow_result: MeshInstance3D
var _center: Vector3 = Vector3(0, 0.5, 0)
var _status_label: Label3D
var _controller_root: Node3D

func _ready() -> void:
	_setup_environment()
	_spawn_arrows()
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
	_controller_root.position = Vector3(0.75, 0.5, 0)
	add_child(_controller_root)

	var ax_controller := CONTROLLER_SCENE.instantiate()
	ax_controller.parameter_name = "A.x"
	ax_controller.min_value = -0.3
	ax_controller.max_value = 0.3
	ax_controller.default_value = vector_a.x
	ax_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(ax_controller)
	ax_controller.value_changed.connect(func(v: float) -> void:
		vector_a.x = v
	)
	ax_controller.set_value(vector_a.x)

	var ay_controller := CONTROLLER_SCENE.instantiate()
	ay_controller.parameter_name = "A.y"
	ay_controller.min_value = -0.3
	ay_controller.max_value = 0.3
	ay_controller.default_value = vector_a.y
	ay_controller.position = Vector3(0, -0.18, 0)
	ay_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(ay_controller)
	ay_controller.value_changed.connect(func(v: float) -> void:
		vector_a.y = v
	)
	ay_controller.set_value(vector_a.y)

	var bx_controller := CONTROLLER_SCENE.instantiate()
	bx_controller.parameter_name = "B.x"
	bx_controller.min_value = -0.3
	bx_controller.max_value = 0.3
	bx_controller.default_value = vector_b.x
	bx_controller.position = Vector3(0, -0.36, 0)
	bx_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(bx_controller)
	bx_controller.value_changed.connect(func(v: float) -> void:
		vector_b.x = v
	)
	bx_controller.set_value(vector_b.x)

func _spawn_arrows() -> void:
	_arrow_a = _create_arrow(MAT_VEC_A)
	_sim_root.add_child(_arrow_a)

	_arrow_b = _create_arrow(MAT_VEC_B)
	_sim_root.add_child(_arrow_b)

	_arrow_result = _create_arrow(MAT_RESULT)
	_sim_root.add_child(_arrow_result)

func _create_arrow(mat: Material) -> MeshInstance3D:
	var arrow := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.01
	cylinder.bottom_radius = 0.01
	cylinder.height = 0.1
	arrow.mesh = cylinder
	arrow.material_override = mat
	return arrow

func _process(_delta: float) -> void:
	var result := vector_a - vector_b

	_update_arrow(_arrow_a, _center, vector_a)
	_update_arrow(_arrow_b, _center, vector_b)
	_update_arrow(_arrow_result, _center, result)

	_status_label.text = "Vector Subtraction | Result (%.2f, %.2f)" % [result.x, result.y]

func _update_arrow(arrow: MeshInstance3D, origin: Vector3, vec: Vector3) -> void:
	var length := vec.length()
	if length < 0.01:
		arrow.visible = false
		return

	arrow.visible = true
	arrow.position = origin + vec * 0.5
	arrow.look_at(origin + vec, Vector3.UP)
	arrow.rotate_object_local(Vector3.RIGHT, PI / 2)
	arrow.scale = Vector3(1, length, 1)
