# ===========================================================================
# NOC Example 3.11: A Spring Connection
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D
const ARTIFACT_SCENE_PRESENTER := preload("res://commons/artifacts/ArtifactScenePresenter.gd")

const MAT_SPRING := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")
const MAT_BOB := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var spring_constant: float = 0.1
@export var damping: float = 0.98
@export var rest_length: float = 0.2

var _sim_root: Node3D
var _anchor_pos: Vector3 = Vector3(0, 0.85, 0)
var _bob: Bob
var _spring_mesh: MeshInstance3D
var _status_label: Label3D
var _control_panel: Node3D
var _initial_bob_pos: Vector3 = Vector3(0, 0.5, 0)

func _ready() -> void:
	_setup_environment()
	_spawn_scene()
	_setup_controls()
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


func _spawn_scene() -> void:
	_bob = Bob.new()
	_bob.init(_sim_root, MAT_BOB)
	_bob.position = Vector3(0, 0.5, 0)

	_spring_mesh = MeshInstance3D.new()
	_sim_root.add_child(_spring_mesh)

func _setup_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("SPRING", [
		[
			{"type": "slider_h", "label": "K", "default": (spring_constant - 0.01) / 0.49},
			{"type": "slider_h", "label": "DAMP", "default": (damping - 0.9) / 0.1},
		],
		[
			{"type": "slider_h", "label": "REST", "default": (rest_length - 0.05) / 0.45},
		],
		[{"type": "button", "label": "RESET"}],
	])
	_control_panel.position = Vector3(0.3, 0.15, 0.1)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	var k_slider: Node = _control_panel.find_child("Param_0", true, false)
	var damp_slider: Node = _control_panel.find_child("Param_1", true, false)
	var rest_slider: Node = _control_panel.find_child("Param_2", true, false)

	if k_slider and k_slider.has_signal("slider_moved"):
		k_slider.slider_moved.connect(func(_n: String) -> void:
			spring_constant = 0.01 + k_slider.get_normalized_value() * 0.49
		)
	if damp_slider and damp_slider.has_signal("slider_moved"):
		damp_slider.slider_moved.connect(func(_n: String) -> void:
			damping = 0.9 + damp_slider.get_normalized_value() * 0.1
		)
	if rest_slider and rest_slider.has_signal("slider_moved"):
		rest_slider.slider_moved.connect(func(_n: String) -> void:
			rest_length = 0.05 + rest_slider.get_normalized_value() * 0.45
		)

	var reset_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if reset_btn:
		var area: Node = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b: bool) -> void:
				_bob.position = _initial_bob_pos
				_bob.velocity = Vector3.ZERO
			)


func _process(delta: float) -> void:
	var spring_dir := _anchor_pos - _bob.position
	var current_length := spring_dir.length()
	var extension := current_length - rest_length
	spring_dir = spring_dir.normalized()
	var spring_force := spring_dir * spring_constant * extension

	_bob.apply_force(spring_force)
	_bob.apply_force(Vector3(0, -0.1, 0))
	_bob.velocity *= damping
	_bob.update(delta)

	_update_spring()

	_status_label.text = "Spring | Ext %.2f" % extension

func _update_spring() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var num_coils := 12
	var coil_radius := 0.02
	var direction := (_bob.position - _anchor_pos).normalized()
	var length := _anchor_pos.distance_to(_bob.position)

	for i in range(num_coils * 4):
		var t := float(i) / (num_coils * 4)
		var pos_along := _anchor_pos + direction * (length * t)
		var angle := t * num_coils * TAU
		var offset := Vector3(cos(angle), 0, sin(angle)) * coil_radius
		mesh.surface_set_color(Color(1.0, 0.7, 0.95, 0.8))
		mesh.surface_add_vertex(pos_along + offset)

	mesh.surface_end()
	_spring_mesh.mesh = mesh

class Bob:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO

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
		root.name = "Bob"
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
		position += velocity * delta * 60.0
		acceleration = Vector3.ZERO

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()

func _apply_standard_presentation() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	ARTIFACT_SCENE_PRESENTER.present(self, _sim_root)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
