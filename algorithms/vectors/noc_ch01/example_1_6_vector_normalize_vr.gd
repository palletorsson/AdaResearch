# ===========================================================================
# NOC Example 1.6: Vector Normalize
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_VEC := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_NORMALIZED := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var vector: Vector3 = Vector3(0.25, 0.2, 0)

var _sim_root: Node3D
var _arrow_vec: MeshInstance3D
var _arrow_norm: MeshInstance3D
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

	var x_controller := CONTROLLER_SCENE.instantiate()
	x_controller.parameter_name = "Vec.x"
	x_controller.min_value = -0.3
	x_controller.max_value = 0.3
	x_controller.default_value = vector.x
	x_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(x_controller)
	x_controller.value_changed.connect(func(v: float) -> void:
		vector.x = v
	)
	x_controller.set_value(vector.x)

	var y_controller := CONTROLLER_SCENE.instantiate()
	y_controller.parameter_name = "Vec.y"
	y_controller.min_value = -0.3
	y_controller.max_value = 0.3
	y_controller.default_value = vector.y
	y_controller.position = Vector3(0, -0.18, 0)
	y_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(y_controller)
	y_controller.value_changed.connect(func(v: float) -> void:
		vector.y = v
	)
	y_controller.set_value(vector.y)

func _spawn_arrows() -> void:
	_arrow_vec = _create_arrow(MAT_VEC)
	_sim_root.add_child(_arrow_vec)

	_arrow_norm = _create_arrow(MAT_NORMALIZED)
	_sim_root.add_child(_arrow_norm)

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
	var magnitude := vector.length()
	var normalized := vector.normalized() if magnitude > 0.01 else Vector3.ZERO

	_update_arrow(_arrow_vec, _center, vector)
	_update_arrow(_arrow_norm, _center, normalized * 0.15)

	_status_label.text = "Normalize | mag: %.3f → 1.000" % magnitude

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
