# ===========================================================================
# NOC Example 3.7: Oscillator Objects
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_OSC := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var num_oscillators: int = 10
@export var global_speed: float = 1.0

var _sim_root: Node3D
var _oscillators: Array[Oscillator] = []
var _status_label: Label3D
var _controller_root: Node3D

func _ready() -> void:
	_setup_environment()
	_spawn_oscillators()
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

	var speed_controller := CONTROLLER_SCENE.instantiate()
	speed_controller.parameter_name = "Global Speed"
	speed_controller.min_value = 0.2
	speed_controller.max_value = 3.0
	speed_controller.default_value = global_speed
	speed_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(speed_controller)
	speed_controller.value_changed.connect(func(v: float) -> void:
		global_speed = v
	)
	speed_controller.set_value(global_speed)

func _spawn_oscillators() -> void:
	for i in num_oscillators:
		var osc := Oscillator.new()
		osc.init(_sim_root, MAT_OSC)
		var x := remap(i, 0, num_oscillators - 1, -0.35, 0.35)
		osc.anchor = Vector3(x, 0.5, 0)
		osc.amplitude = Vector2(randf_range(0.05, 0.15), randf_range(0.05, 0.15))
		osc.period = Vector2(randf_range(60, 180), randf_range(60, 180))
		osc.phase = Vector2(randf() * TAU, randf() * TAU)
		_oscillators.append(osc)

func _process(delta: float) -> void:
	for osc in _oscillators:
		osc.oscillate(delta * global_speed)

	_status_label.text = "Oscillator Objects | %d rods" % _oscillators.size()

func _exit_tree() -> void:
	for osc in _oscillators:
		osc.queue_free()

class Oscillator:
	var root: Node3D
	var rod: MeshInstance3D
	var anchor: Vector3 = Vector3.ZERO
	var amplitude: Vector2 = Vector2(0.1, 0.1)
	var period: Vector2 = Vector2(120, 120)
	var phase: Vector2 = Vector2.ZERO
	var angle: Vector2 = Vector2.ZERO

	func init(parent: Node3D, mat: Material) -> void:
		root = Node3D.new()
		root.name = "Oscillator"
		parent.add_child(root)

		rod = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.015, 0.2, 0.015)
		rod.mesh = box
		rod.material_override = mat
		root.add_child(rod)

	func oscillate(delta: float) -> void:
		angle.x += (TAU / period.x) * delta * 60.0
		angle.y += (TAU / period.y) * delta * 60.0

		var x := sin(angle.x + phase.x) * amplitude.x
		var y := sin(angle.y + phase.y) * amplitude.y

		root.position = anchor + Vector3(x, y, 0)

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()
