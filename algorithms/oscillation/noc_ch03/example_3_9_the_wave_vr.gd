# ===========================================================================
# NOC Example 3.9: The Wave
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D
const ARTIFACT_SCENE_PRESENTER := preload("res://commons/artifacts/ArtifactScenePresenter.gd")

const MAT_WAVE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var wavelength: float = 0.15
@export var amplitude: float = 0.12
@export var wave_speed: float = 0.05

var _sim_root: Node3D
var _wave_mesh: MeshInstance3D
var _status_label: Label3D
var _control_panel: Node3D
var _theta: float = 0.0

func _ready() -> void:
	_setup_environment()
	_spawn_wave()
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


func _spawn_wave() -> void:
	_wave_mesh = MeshInstance3D.new()
	_sim_root.add_child(_wave_mesh)

func _setup_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("THE WAVE", [
		[
			{"type": "slider_h", "label": "WAVE \u03bb", "default": (wavelength - 0.05) / 0.35},
			{"type": "slider_h", "label": "AMP", "default": (amplitude - 0.02) / 0.28},
		],
		[
			{"type": "slider_h", "label": "SPEED", "default": (wave_speed - 0.01) / 0.14},
		],
	])
	_control_panel.position = Vector3(0.4, 0.15, 0.2)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	var wl_slider: Node = _control_panel.find_child("Param_0", true, false)
	var amp_slider: Node = _control_panel.find_child("Param_1", true, false)
	var spd_slider: Node = _control_panel.find_child("Param_2", true, false)

	if wl_slider and wl_slider.has_signal("slider_moved"):
		wl_slider.slider_moved.connect(func(_n: String) -> void:
			wavelength = 0.05 + wl_slider.get_normalized_value() * 0.35
		)
	if amp_slider and amp_slider.has_signal("slider_moved"):
		amp_slider.slider_moved.connect(func(_n: String) -> void:
			amplitude = 0.02 + amp_slider.get_normalized_value() * 0.28
		)
	if spd_slider and spd_slider.has_signal("slider_moved"):
		spd_slider.slider_moved.connect(func(_n: String) -> void:
			wave_speed = 0.01 + spd_slider.get_normalized_value() * 0.14
		)


func _process(_delta: float) -> void:
	_theta += wave_speed
	_update_wave()
	_status_label.text = "Animated Wave"

func _update_wave() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var num_points := 80
	var angle := _theta
	for i in num_points:
		var x := remap(i, 0, num_points - 1, -0.4, 0.4)
		var y := sin(angle) * amplitude
		var pos := Vector3(x, 0.5 + y, 0)
		mesh.surface_set_color(Color(1.0, 0.75, 0.95))
		mesh.surface_add_vertex(pos)
		angle += (TAU / wavelength) * (0.8 / num_points)

	mesh.surface_end()
	_wave_mesh.mesh = mesh
	_wave_mesh.material_override = MAT_WAVE

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


