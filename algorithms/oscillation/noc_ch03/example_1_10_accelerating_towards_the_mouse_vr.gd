# ===========================================================================
# NOC Example 1.10: Accelerating Towards the Mouse
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D
const ARTIFACT_SCENE_PRESENTER := preload("res://commons/artifacts/ArtifactScenePresenter.gd")

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_MOVER := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_TARGET := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var acceleration_gain: float = 0.08

var _sim_root: Node3D
var _mover: AccelMover
var _target: MeshInstance3D
var _status_label: Label3D
var _controller_root: Node3D

func _ready() -> void:
	_setup_environment()
	_spawn_scene()
	call_deferred("_apply_standard_presentation")
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

	var gain_controller := CONTROLLER_SCENE.instantiate()
	gain_controller.parameter_name = "Accel Gain"
	gain_controller.min_value = 0.02
	gain_controller.max_value = 0.2
	gain_controller.default_value = acceleration_gain
	gain_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(gain_controller)
	gain_controller.value_changed.connect(func(v: float) -> void:
		acceleration_gain = v
	)
	gain_controller.set_value(acceleration_gain)

func _spawn_scene() -> void:
	_mover = AccelMover.new()
	_mover.init(_sim_root, MAT_MOVER)
	_mover.position = Vector3(0, 0.5, 0)

	_target = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = sphere.radius * 2.0
	_target.mesh = sphere
	_target.material_override = MAT_TARGET
	_target.position = Vector3(0.2, 0.6, 0)
	_sim_root.add_child(_target)

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	_target.position = Vector3(
		0.3 * sin(t * 0.8),
		0.5 + 0.2 * cos(t * 0.6),
		0.15 * sin(t * 0.4)
	)

	var dir := (_target.position - _mover.position).normalized()
	var accel := dir * acceleration_gain
	_mover.apply_force(accel)
	_mover.update(delta)
	_mover.wrap_bounds()

	var dist := _mover.position.distance_to(_target.position)
	_status_label.text = "Accel to Target | Dist %.2f" % dist

class AccelMover:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var max_speed: float = 0.4

	var position: Vector3:
		get:
			if not is_instance_valid(root):
				return Vector3.ZERO
			return root.global_position
		set(value):
			if not is_instance_valid(root):
				return
			if root.get_parent() is Node3D:
				var det := (root.get_parent() as Node3D).global_transform.basis.determinant()
				if abs(det) < 0.0001:
					root.position = value
					return
			root.global_position = value

	func init(parent: Node3D, mat: Material) -> void:
		root = Node3D.new()
		root.name = "Mover"
		parent.add_child(root)

		body = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.04
		sphere.height = sphere.radius * 2.0
		body.mesh = sphere
		body.material_override = mat
		root.add_child(body)

	func apply_force(force: Vector3) -> void:
		acceleration += force

	func update(delta: float) -> void:
		velocity += acceleration
		velocity = velocity.limit_length(max_speed)
		position += velocity * delta * 60.0
		acceleration = Vector3.ZERO

	func wrap_bounds() -> void:
		var pos := position
		if pos.x < -0.45:
			pos.x = 0.45
		elif pos.x > 0.45:
			pos.x = -0.45
		if pos.y < 0.05:
			pos.y = 0.95
		elif pos.y > 0.95:
			pos.y = 0.05
		if pos.z < -0.45:
			pos.z = 0.45
		elif pos.z > 0.45:
			pos.z = -0.45
		position = pos

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()

func _apply_standard_presentation() -> void:
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	ARTIFACT_SCENE_PRESENTER.present(self, _sim_root)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
