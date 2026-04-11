# PerfectShotPreview.gd — Interactive desktop viewer with smart framing
#
# Wraps PerfectShotFramer + PerfectShotScaffold with orbit camera controls.
# When a scene loads, it auto-measures and auto-frames to the optimal angle.
# Number keys 1-4 jump to computed optimal angles. C captures current view.
#
# Load modes:
#   - Artifact by lookup_name
#   - Scene by .tscn path
#   - Critter by DNA JSON path
#
# Usage:
#   Open PerfectShotPreview.tscn in Godot editor or:
#   godot_console --path . --xr-mode off --script res://commons/testing/perfect_shot_preview.gd

class_name PerfectShotPreview
extends Node3D

# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────

@export_group("Camera Controls")
@export var orbit_sensitivity: float = 0.005
@export var pan_sensitivity: float = 0.01
@export var zoom_sensitivity: float = 0.3
@export var auto_rotate_speed: float = 0.2

@export_group("Capture")
@export var capture_output_dir: String = "user://perfect_shots/preview"


# ─────────────────────────────────────────────────────────────
#  Signals
# ─────────────────────────────────────────────────────────────

signal scene_loaded(name: String, analysis: Dictionary)
signal angle_changed(angle_name: String)
signal screenshot_saved(path: String)


# ─────────────────────────────────────────────────────────────
#  State
# ─────────────────────────────────────────────────────────────

var _camera: Camera3D = null
var _world_env: WorldEnvironment = null
var _ground: MeshInstance3D = null
var _instance_container: Node3D = null
var _current_instance: Node3D = null
var _current_name: String = ""

# Orbit state
var _orbit_yaw: float = 0.3
var _orbit_pitch: float = 0.4
var _orbit_distance: float = 5.0
var _orbit_focus: Vector3 = Vector3(0, 0.5, 0)
var _is_orbiting: bool = false
var _is_panning: bool = false
var _auto_rotate: bool = false

# Framing state
var _analysis: Dictionary = {}
var _computed_angles: Array[Dictionary] = []
var _current_angle_index: int = 0

# HUD
var _hud_label: Label = null


# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	_build_environment()
	_build_hud()
	_update_camera()


func _process(delta: float) -> void:
	if _auto_rotate and not _is_orbiting and not _is_panning:
		_orbit_yaw += auto_rotate_speed * delta
		_update_camera()

	_update_hud()


# ═══════════════════════════════════════════════════════════════
# PUBLIC API — Loading
# ═══════════════════════════════════════════════════════════════

## Load an artifact by lookup_name from the registry.
func load_artifact(lookup_name: String) -> void:
	var artifact_info: Dictionary = ArtifactCatalogDataProvider.get_artifact_by_lookup_name(lookup_name)
	if artifact_info.is_empty():
		push_warning("[PerfectShotPreview] Artifact not found: %s" % lookup_name)
		return

	var scene_path: String = str(artifact_info.get("scene", "")).strip_edges()
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("[PerfectShotPreview] Scene not found: %s" % scene_path)
		return

	var scene = ResourceLoader.load(scene_path)
	if not scene:
		return

	var instance = scene.instantiate()
	if not instance or not (instance is Node3D):
		if instance:
			instance.queue_free()
		return

	_set_instance(instance as Node3D, lookup_name)


## Load a scene by .tscn path.
func load_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_warning("[PerfectShotPreview] Scene not found: %s" % scene_path)
		return

	var scene = ResourceLoader.load(scene_path)
	if not scene:
		return

	var instance = scene.instantiate()
	if not instance or not (instance is Node3D):
		if instance:
			instance.queue_free()
		return

	_set_instance(instance as Node3D, scene_path.get_file().get_basename())


## Load a critter from DNA JSON path.
func load_critter_dna(dna_path: String) -> void:
	if not FileAccess.file_exists(dna_path):
		push_warning("[PerfectShotPreview] DNA file not found: %s" % dna_path)
		return

	var file := FileAccess.open(dna_path, FileAccess.READ)
	var json_str: String = file.get_as_text()
	file.close()

	var dna: CritterDNA = CritterDNA.from_json(json_str)
	if not dna:
		push_warning("[PerfectShotPreview] Failed to parse DNA")
		return

	load_critter_from_dna(dna, dna_path.get_file().get_basename())


## Load a critter directly from a CritterDNA resource.
func load_critter_from_dna(dna: CritterDNA, display_name: String = "") -> void:
	var trait_mapper := CritterTraitMapper.new()
	var mesh_root := Node3D.new()
	mesh_root.name = "Critter_%s" % dna.get_kingdom_name()
	MorphologyRouter.build(dna, mesh_root, trait_mapper, 0)

	var name_str: String = display_name if not display_name.is_empty() else "critter_%s_gen%d" % [dna.get_kingdom_name(), dna.generation]
	_set_instance(mesh_root, name_str)


## Clear the current scene.
func clear() -> void:
	if _current_instance and is_instance_valid(_current_instance):
		_current_instance.queue_free()
	_current_instance = null
	_current_name = ""
	_analysis = {}
	_computed_angles = []


# ═══════════════════════════════════════════════════════════════
# PUBLIC API — Controls
# ═══════════════════════════════════════════════════════════════

## Jump to a specific computed angle by index (1-based for keyboard).
func jump_to_angle(index: int) -> void:
	if index < 0 or index >= _computed_angles.size():
		return
	_current_angle_index = index
	var angle: Dictionary = _computed_angles[index]

	if PerfectShotFramer.is_environment_angle(angle):
		var aabb: AABB = _analysis.get("aabb", AABB())
		var radius: float = PerfectShotFramer.get_environment_orbit_radius(aabb)
		var height: float = PerfectShotFramer.get_environment_orbit_height(aabb)
		var cam_pos: Vector3 = PerfectShotFramer.compute_environment_orbit_position(
			_orbit_focus, angle["yaw"], angle["pitch_factor"], radius, height
		)
		_camera.global_position = cam_pos
		_camera.look_at(_orbit_focus, Vector3.UP)
		# Update orbit state to match
		_orbit_yaw = angle["yaw"]
		_orbit_distance = _camera.global_position.distance_to(_orbit_focus)
	else:
		_orbit_yaw = angle["yaw"]
		_orbit_pitch = angle["pitch"]
		_orbit_distance = _analysis.get("orbit_distance", 5.0)
		_update_camera()

	angle_changed.emit(str(angle["name"]))


## Capture the current view to disk.
func capture_current_view() -> String:
	var output_dir: String = capture_output_dir + "/" + _current_name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))

	var angle_name: String = "custom"
	if _current_angle_index >= 0 and _current_angle_index < _computed_angles.size():
		angle_name = str(_computed_angles[_current_angle_index]["name"])

	var path: String = output_dir + "/" + angle_name + ".png"
	var abs_path: String = ProjectSettings.globalize_path(path)

	var image: Image = get_viewport().get_texture().get_image()
	if image and image.save_png(abs_path) == OK:
		print("[PerfectShotPreview] Saved: %s" % abs_path)
		screenshot_saved.emit(abs_path)
		return abs_path

	push_warning("[PerfectShotPreview] Failed to save screenshot")
	return ""


# ═══════════════════════════════════════════════════════════════
# INTERNAL — Scene setup
# ═══════════════════════════════════════════════════════════════

func _set_instance(instance: Node3D, display_name: String) -> void:
	clear()

	_current_instance = instance
	_current_name = display_name
	_instance_container.add_child(instance)

	# Center the instance
	var aabb: AABB = PerfectShotFramer.get_combined_aabb(instance)
	if aabb.size.length() > 0.001:
		var center: Vector3 = aabb.get_center()
		instance.position = -center
		instance.position.y += -aabb.position.y

	# Analyze
	_analysis = PerfectShotFramer.analyze(instance)
	_computed_angles = _analysis.get("angles", [])

	# Apply size-aware environment
	var size_class: int = _analysis.get("size_class", PerfectShotFramer.SizeClass.MEDIUM)
	_apply_size_preset(size_class, _analysis.get("aabb", AABB()))

	# Auto-frame to hero angle
	_orbit_focus = _analysis.get("orbit_focus", Vector3(0, 0.5, 0))
	_orbit_distance = _analysis.get("orbit_distance", 5.0)

	if _computed_angles.size() > 0:
		jump_to_angle(0)
	else:
		_orbit_yaw = 0.3
		_orbit_pitch = 0.4
		_update_camera()

	# Animate in
	var original_scale: Vector3 = instance.scale
	instance.scale = Vector3.ZERO
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(instance, "scale", original_scale, 0.5)

	scene_loaded.emit(display_name, _analysis)
	print("[PerfectShotPreview] Loaded '%s' — %s (%.1f units)" % [
		display_name, _analysis.get("size_name", "?"), _analysis.get("max_dimension", 0.0)
	])


func _apply_size_preset(size_class: int, aabb: AABB) -> void:
	var env: Environment = _world_env.environment if _world_env else null
	if not env:
		return

	var ground_size: Vector2 = PerfectShotFramer.get_ground_size(aabb, size_class)
	if _ground.mesh is PlaneMesh:
		(_ground.mesh as PlaneMesh).size = ground_size

	var ground_mat: StandardMaterial3D = _ground.material_override as StandardMaterial3D

	match size_class:
		PerfectShotFramer.SizeClass.TINY, PerfectShotFramer.SizeClass.SMALL:
			env.ambient_light_energy = 0.7
			env.background_color = Color(0.10, 0.10, 0.14)
			ground_mat.albedo_color = Color(0.13, 0.12, 0.16)
		PerfectShotFramer.SizeClass.LARGE, PerfectShotFramer.SizeClass.HUGE:
			env.ambient_light_energy = 0.8
			env.background_color = Color(0.14, 0.14, 0.18)
			ground_mat.albedo_color = Color(0.15, 0.15, 0.18)
		_:
			env.ambient_light_energy = 0.6
			env.background_color = Color(0.12, 0.12, 0.16)
			ground_mat.albedo_color = Color(0.15, 0.15, 0.18)


# ═══════════════════════════════════════════════════════════════
# INTERNAL — Environment building
# ═══════════════════════════════════════════════════════════════

func _build_environment() -> void:
	# World environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.12, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	_world_env = WorldEnvironment.new()
	_world_env.environment = env
	add_child(_world_env)

	# Camera
	_camera = Camera3D.new()
	_camera.name = "PreviewCamera"
	_camera.current = true
	_camera.fov = 50.0
	add_child(_camera)

	# Key light
	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.rotation_degrees = Vector3(-45, -30, 0)
	key.light_energy = 1.2
	key.shadow_enabled = true
	add_child(key)

	# Fill light
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_energy = 0.4
	fill.shadow_enabled = false
	add_child(fill)

	# Ground
	_ground = MeshInstance3D.new()
	_ground.name = "Ground"
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(20, 20)
	_ground.mesh = ground_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.18)
	_ground.material_override = mat
	add_child(_ground)

	# Instance container
	_instance_container = Node3D.new()
	_instance_container.name = "InstanceContainer"
	add_child(_instance_container)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)

	_hud_label = Label.new()
	_hud_label.name = "InfoLabel"
	_hud_label.position = Vector2(16, 16)
	_hud_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	_hud_label.add_theme_font_size_override("font_size", 14)
	canvas.add_child(_hud_label)


func _update_hud() -> void:
	if not _hud_label:
		return

	if _current_name.is_empty():
		_hud_label.text = "Perfect Shot Preview\nLoad: artifact / scene / critter\nKeys: 1-4 angles, C capture, R rotate"
		return

	var size_name: String = _analysis.get("size_name", "?")
	var max_dim: float = _analysis.get("max_dimension", 0.0)
	var angle_name: String = "custom"
	if _current_angle_index >= 0 and _current_angle_index < _computed_angles.size():
		angle_name = str(_computed_angles[_current_angle_index]["name"])

	_hud_label.text = "%s\nSize: %s (%.2f units)\nAngle: %s (%d/%d)\nKeys: 1-%d angles, C capture, R rotate" % [
		_current_name, size_name, max_dim, angle_name,
		_current_angle_index + 1, _computed_angles.size(),
		_computed_angles.size()
	]


# ═══════════════════════════════════════════════════════════════
# CAMERA ORBIT CONTROLS (from ArtifactCatalogDesktop3D)
# ═══════════════════════════════════════════════════════════════

func _update_camera() -> void:
	if not _camera:
		return
	_camera.global_position = PerfectShotFramer.compute_orbit_position(
		_orbit_focus, _orbit_yaw, _orbit_pitch, _orbit_distance
	)
	_camera.look_at(_orbit_focus, Vector3.UP)


func _input(event: InputEvent) -> void:
	# Keyboard shortcuts
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			# Number keys 1-4: jump to angle
			var num: int = key.keycode - KEY_1
			if num >= 0 and num < _computed_angles.size():
				jump_to_angle(num)
				return

			# C: capture
			if key.keycode == KEY_C:
				capture_current_view()
				return

			# R: toggle auto-rotate
			if key.keycode == KEY_R:
				_auto_rotate = not _auto_rotate
				return

	# Mouse orbit/pan/zoom
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_is_orbiting = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_is_panning = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_orbit_distance = maxf(0.5, _orbit_distance - zoom_sensitivity)
			_update_camera()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_orbit_distance = minf(50.0, _orbit_distance + zoom_sensitivity)
			_update_camera()

	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _is_orbiting:
			_orbit_yaw -= motion.relative.x * orbit_sensitivity
			_orbit_pitch -= motion.relative.y * orbit_sensitivity
			_orbit_pitch = clampf(_orbit_pitch, -PI * 0.45, PI * 0.45)
			_update_camera()
		elif _is_panning:
			var right: Vector3 = _camera.global_transform.basis.x
			var up: Vector3 = _camera.global_transform.basis.y
			_orbit_focus -= right * motion.relative.x * pan_sensitivity
			_orbit_focus += up * motion.relative.y * pan_sensitivity
			_update_camera()
