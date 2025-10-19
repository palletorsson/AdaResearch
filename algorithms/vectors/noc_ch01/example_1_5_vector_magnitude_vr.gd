# ===========================================================================
# NOC Example 1.5: Vector Magnitude
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_VEC := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_GAUGE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var vector: Vector3 = Vector3(0.2, 0.15, 0)

var _sim_root: Node3D
var _arrow: MeshInstance3D
var _gauge_bar: MeshInstance3D
var _magnitude_label: Label3D
var _center: Vector3 = Vector3(0, 0.5, 0)
var _controller_root: Node3D

func _ready() -> void:
	_setup_environment()
	_spawn_arrow()
	_spawn_gauge()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


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

func _spawn_arrow() -> void:
	_arrow = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.01
	cylinder.bottom_radius = 0.01
	cylinder.height = 0.1
	_arrow.mesh = cylinder
	_arrow.material_override = MAT_VEC
	_sim_root.add_child(_arrow)

func _spawn_gauge() -> void:
	var gauge_root := Node3D.new()
	gauge_root.position = Vector3(-0.45, 0.5, 0)
	_sim_root.add_child(gauge_root)

	_gauge_bar = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.02, 0.1, 0.02)
	_gauge_bar.mesh = bar
	_gauge_bar.material_override = MAT_GAUGE
	gauge_root.add_child(_gauge_bar)

	_magnitude_label = Label3D.new()
	_magnitude_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_magnitude_label.font_size = 20
	_magnitude_label.modulate = Color(1.0, 0.85, 1.0)
	_magnitude_label.position = Vector3(0, -0.25, 0)
	gauge_root.add_child(_magnitude_label)

	var title := Label3D.new()
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.font_size = 18
	title.modulate = Color(1.0, 0.85, 1.0)
	title.position = Vector3(0, 0.28, 0)
	title.text = "Magnitude"
	gauge_root.add_child(title)

func _process(_delta: float) -> void:
	var magnitude := vector.length()

	_update_arrow(_arrow, _center, vector)

	var bar_height: float = clamp(magnitude * 2.0, 0.0, 0.8)
	_gauge_bar.scale.y = bar_height / 0.1
	_gauge_bar.position.y = -0.2 + bar_height * 0.5

	_magnitude_label.text = "%.3f" % magnitude

func _update_arrow(arrow: MeshInstance3D, origin: Vector3, vec: Vector3) -> void:
	var length := vec.length()
	if length < 0.01:
		arrow.visible = false
		return

	arrow.visible = true
	arrow.position = origin + vec * 0.5
	arrow.look_at_from_position(arrow.position, origin + vec, Vector3.UP)
	arrow.rotate_object_local(Vector3.RIGHT, PI / 2)
	arrow.scale = Vector3(1, length, 1)
