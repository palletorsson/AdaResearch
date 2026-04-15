extends Node3D
const ARTIFACT_SCENE_PRESENTER := preload("res://commons/artifacts/ArtifactScenePresenter.gd")

const MAT_WAVE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var num_waves: int = 3
@export var wave_speed: float = 0.03

var _sim_root: Node3D
var _wave_mesh: MeshInstance3D
var _waves: Array[Dictionary] = []
var _status_label: Label3D
var _control_panel: Node3D

func _ready() -> void:
	_setup_environment()
	_init_waves()
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


func _setup_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("ADDITIVE WAVES", [
		[
			{"type": "slider_h", "label": "WAVES", "default": float(num_waves - 1) / 7.0},
			{"type": "slider_h", "label": "SPEED", "default": (wave_speed - 0.01) / 0.09},
		],
	])
	_control_panel.position = Vector3(0.3, 0.15, 0.1)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	var waves_slider: Node = _control_panel.find_child("Param_0", true, false)
	var spd_slider: Node = _control_panel.find_child("Param_1", true, false)

	if waves_slider and waves_slider.has_signal("slider_moved"):
		waves_slider.slider_moved.connect(func(_n: String) -> void:
			var new_count: int = 1 + int(waves_slider.get_normalized_value() * 7.0)
			if new_count != num_waves:
				num_waves = new_count
				_init_waves()
		)
	if spd_slider and spd_slider.has_signal("slider_moved"):
		spd_slider.slider_moved.connect(func(_n: String) -> void:
			wave_speed = 0.01 + spd_slider.get_normalized_value() * 0.09
		)


func _init_waves() -> void:
	_waves.clear()
	for i in num_waves:
		_waves.append({
			"amplitude": randf_range(0.03, 0.08),
			"wavelength": randf_range(0.08, 0.2),
			"theta": randf() * TAU,
			"speed": randf_range(0.8, 1.2)
		})

func _spawn_wave() -> void:
	_wave_mesh = MeshInstance3D.new()
	_sim_root.add_child(_wave_mesh)

func _process(_delta: float) -> void:
	for wave in _waves:
		wave.theta += wave_speed * wave.speed

	_update_wave()
	_status_label.text = "Additive Wave | %d waves" % num_waves

func _update_wave() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var num_points := 80
	for i in num_points:
		var x := remap(i, 0, num_points - 1, -0.4, 0.4)
		var y := 0.0

		for wave in _waves:
			var angle: float = wave.theta + (x / wave.wavelength) * TAU
			y += sin(angle) * wave.amplitude

		var pos := Vector3(x, 0.5 + y, 0)
		mesh.surface_set_color(Color(1.0, 0.75, 0.95))
		mesh.surface_add_vertex(pos)

	mesh.surface_end()
	_wave_mesh.mesh = mesh
	_wave_mesh.material_override = MAT_WAVE

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


