# ===========================================================================
# NOC Example 3.10: Swinging Pendulum
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D
const ARTIFACT_SCENE_PRESENTER := preload("res://commons/artifacts/ArtifactScenePresenter.gd")

const MAT_ROD := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")
const MAT_BOB := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var arm_length: float = 0.3
@export var gravity: float = 0.4

var _sim_root: Node3D
var _anchor: Node3D
var _rod: MeshInstance3D
var _bob: MeshInstance3D
var _status_label: Label3D
var _control_panel: Node3D
var _angle: float = PI / 4.0
var _initial_angle: float = PI / 4.0
var _angular_velocity: float = 0.0
var _angular_acceleration: float = 0.0

func _ready() -> void:
	_setup_environment()
	_spawn_pendulum()
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


func _spawn_pendulum() -> void:
	_anchor = Node3D.new()
	_anchor.position = Vector3(0, 0.9, 0)
	_sim_root.add_child(_anchor)

	_rod = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.005
	cylinder.bottom_radius = 0.005
	cylinder.height = arm_length
	_rod.mesh = cylinder
	_rod.material_override = MAT_ROD
	_anchor.add_child(_rod)

	_bob = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = sphere.radius * 2.0
	_bob.mesh = sphere
	_bob.material_override = MAT_BOB
	_anchor.add_child(_bob)

func _setup_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("PENDULUM", [
		[
			{"type": "slider_h", "label": "ARM", "default": arm_length / 0.6},
			{"type": "slider_h", "label": "GRAVITY", "default": gravity / 1.0},
		],
		[{"type": "button", "label": "RESET"}],
	])
	_control_panel.position = Vector3(0.3, 0.2, 0.1)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	var arm_slider: Node = _control_panel.find_child("Param_0", true, false)
	var grav_slider: Node = _control_panel.find_child("Param_1", true, false)

	if arm_slider and arm_slider.has_signal("slider_moved"):
		arm_slider.slider_moved.connect(func(_n: String) -> void:
			arm_length = 0.1 + arm_slider.get_normalized_value() * 0.5
			var cyl: CylinderMesh = _rod.mesh
			cyl.height = arm_length
		)
	if grav_slider and grav_slider.has_signal("slider_moved"):
		grav_slider.slider_moved.connect(func(_n: String) -> void:
			gravity = 0.1 + grav_slider.get_normalized_value() * 0.9
		)

	var reset_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if reset_btn:
		var area: Node = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b: bool) -> void:
				_angle = _initial_angle
				_angular_velocity = 0.0
			)


func _process(_delta: float) -> void:
	_angular_acceleration = (-gravity / arm_length) * sin(_angle)
	_angular_velocity += _angular_acceleration
	_angular_velocity *= 0.995
	_angle += _angular_velocity

	_anchor.rotation = Vector3(0, 0, _angle)
	_rod.position = Vector3(0, -arm_length / 2, 0)
	_bob.position = Vector3(0, -arm_length, 0)

	_status_label.text = "Pendulum | %.1f°" % rad_to_deg(_angle)

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


