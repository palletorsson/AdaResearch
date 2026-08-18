class_name ArtifactCatalogDesktop3D
extends Node3D

## Standalone 3D artifact catalog for desktop testing.
## Uses PerfectShotFramer for size-aware framing: measures the artifact,
## classifies its size, sets optimal orbit distance, adapts lighting.
## Number keys 1-4 jump to computed optimal angles.

@export var next_artifact_key: Key = KEY_N
@export var toggle_rotation_key: Key = KEY_R

## Orbit camera settings
@export_group("Camera Controls")
@export var orbit_sensitivity: float = 0.005
@export var pan_sensitivity: float = 0.01
@export var zoom_sensitivity: float = 0.3
@export var zoom_min: float = 0.5
@export var zoom_max: float = 50.0
@export var auto_rotate_speed: float = 0.3

@onready var _overlay: DesktopArtifactSwitcherOverlay = $DesktopArtifactSwitcherOverlay
@onready var _preview_container: Node3D = $PreviewContainer
@onready var _preview_camera: Camera3D = $PreviewContainer/PreviewCamera
@onready var _preview_light: DirectionalLight3D = $PreviewContainer/PreviewLight
@onready var _floor: MeshInstance3D = $PreviewContainer/Floor
@onready var _world_env: WorldEnvironment = $WorldEnvironment

var _current_preview_artifact: Node3D = null
var _current_lookup_name: String = ""
var _rotate_preview: bool = true

# Orbit camera state
var _orbit_yaw: float = 0.0
var _orbit_pitch: float = -0.35  # Slight downward angle (~20°)
var _orbit_distance: float = 5.0
var _orbit_focus: Vector3 = Vector3(0, 1.0, 0)
var _is_orbiting: bool = false
var _is_panning: bool = false

# PerfectShot integration
var _current_analysis: Dictionary = {}
var _computed_angles: Array[Dictionary] = []
var _current_angle_index: int = -1

# Manual capture mode
var _capture_count: int = 0
var _last_capture_path: String = ""

# HUD
var _hud_label: Label = null


func _ready():
	print("ArtifactCatalogDesktop3D: Initializing standalone catalog...")

	# Connect overlay sidebar signal
	if _overlay:
		_overlay.artifact_selected.connect(_on_artifact_selected)
		print("ArtifactCatalogDesktop3D: Connected to overlay artifact_selected signal")

	# Build HUD
	_build_hud()

	# Set initial camera from orbit state
	_update_camera_from_orbit()

	# Ensure artifacts are loaded (standalone mode)
	call_deferred("_refresh_catalog")


func _refresh_catalog():
	# Force load standalone registry
	var artifacts = ArtifactCatalogDataProvider.get_all_artifacts()
	print("ArtifactCatalogDesktop3D: Loaded %d artifacts" % artifacts.size())

	# Auto-load artifact from command line: --artifact=<lookup_name>
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for raw_arg in args:
		var arg: String = str(raw_arg).strip_edges()
		if arg.begins_with("--artifact="):
			var lookup: String = arg.substr(11).strip_edges()
			if not lookup.is_empty():
				print("ArtifactCatalogDesktop3D: Auto-loading from CLI: %s" % lookup)
				call_deferred("_load_preview_artifact", lookup)
				return


func _process(delta: float):
	# Auto-rotate orbit when not interacting
	if _rotate_preview and not _is_orbiting and not _is_panning:
		if _current_preview_artifact and is_instance_valid(_current_preview_artifact):
			_orbit_yaw += auto_rotate_speed * delta
			_update_camera_from_orbit()

	_update_hud()


func _on_artifact_selected(lookup_name: String):
	print("ArtifactCatalogDesktop3D: Artifact selected: %s" % lookup_name)
	_send_to_claude("artifact_selected", lookup_name)
	_load_preview_artifact(lookup_name)


func _load_preview_artifact(lookup_name: String):
	# Clear existing preview
	_clear_preview()
	_current_lookup_name = lookup_name

	# Get artifact info
	var artifact_info = ArtifactCatalogDataProvider.get_artifact_by_lookup_name(lookup_name)
	if artifact_info.is_empty():
		push_warning("ArtifactCatalogDesktop3D: Artifact not found: %s" % lookup_name)
		return

	var scene_path: String = str(artifact_info.get("scene", "")).strip_edges()
	if scene_path.is_empty():
		push_warning("ArtifactCatalogDesktop3D: No scene path for '%s', using placeholder" % lookup_name)
		scene_path = ArtifactCatalogDataProvider.PLACEHOLDER_ARTIFACT_SCENE_PATH

	if not ResourceLoader.exists(scene_path):
		push_warning("ArtifactCatalogDesktop3D: Scene not found: %s (using placeholder)" % scene_path)
		scene_path = ArtifactCatalogDataProvider.PLACEHOLDER_ARTIFACT_SCENE_PATH

	# Load and instantiate with placeholder fallback
	var scene = ResourceLoader.load(scene_path)
	if not scene and scene_path != ArtifactCatalogDataProvider.PLACEHOLDER_ARTIFACT_SCENE_PATH:
		scene_path = ArtifactCatalogDataProvider.PLACEHOLDER_ARTIFACT_SCENE_PATH
		scene = ResourceLoader.load(scene_path)
	if not scene:
		push_warning("ArtifactCatalogDesktop3D: Failed to load scene and placeholder for '%s'" % lookup_name)
		return

	var artifact = scene.instantiate()
	if not artifact:
		push_warning("ArtifactCatalogDesktop3D: Failed to instantiate scene for '%s'" % lookup_name)
		return
	if not (artifact is Node3D):
		push_warning("ArtifactCatalogDesktop3D: Preview scene root must be Node3D for '%s' (using placeholder)" % lookup_name)
		artifact.queue_free()
		var placeholder_scene = ResourceLoader.load(ArtifactCatalogDataProvider.PLACEHOLDER_ARTIFACT_SCENE_PATH)
		if not placeholder_scene:
			return
		artifact = placeholder_scene.instantiate()
		if not artifact or not (artifact is Node3D):
			return

	# Add to preview container
	_preview_container.add_child(artifact)
	_current_preview_artifact = artifact

	# Measure and frame with PerfectShotFramer
	_fit_artifact_to_preview(artifact)

	# Animate in
	_animate_preview_in(artifact)

	print("ArtifactCatalogDesktop3D: OK previewing: %s (%s, %.1f units)" % [
		lookup_name,
		_current_analysis.get("size_name", "?"),
		_current_analysis.get("max_dimension", 0.0),
	])


# ═══════════════════════════════════════════════════════════════
# SIZE-AWARE FRAMING (replaces old fixed 2.0 unit scaling)
# ═══════════════════════════════════════════════════════════════

func _fit_artifact_to_preview(artifact: Node3D):
	artifact.position = Vector3.ZERO

	# Measure and classify using PerfectShotFramer
	_current_analysis = PerfectShotFramer.analyze(artifact)
	var aabb: AABB = _current_analysis["aabb"]

	if aabb.size.length() < 0.001:
		# Fallback for empty AABB — use defaults
		_orbit_distance = 5.0
		_orbit_focus = Vector3(0, 1.0, 0)
		_computed_angles = PerfectShotFramer.ANGLES_STANDARD
		_update_camera_from_orbit()
		return

	# Center the artifact so AABB center is at origin, bottom at ground
	var center: Vector3 = aabb.get_center()
	artifact.position = -center
	artifact.position.y += -aabb.position.y  # Bottom of AABB sits at y=0

	# Set orbit from analysis
	_orbit_distance = _current_analysis["orbit_distance"]
	_orbit_focus = _current_analysis["orbit_focus"]
	_computed_angles = _current_analysis["angles"]
	_current_angle_index = -1

	# Adapt environment to size class
	_apply_size_environment()

	# Jump to hero angle
	if _computed_angles.size() > 0:
		_jump_to_angle(0)
	else:
		_orbit_yaw = 0.3
		_orbit_pitch = -0.35
		_update_camera_from_orbit()


func _apply_size_environment():
	var size_class: int = _current_analysis.get("size_class", PerfectShotFramer.SizeClass.MEDIUM)
	var aabb: AABB = _current_analysis.get("aabb", AABB())

	# Ground plane size
	if _floor and _floor.mesh is PlaneMesh:
		var ground_size: Vector2 = PerfectShotFramer.get_ground_size(aabb, size_class)
		(_floor.mesh as PlaneMesh).size = ground_size
		# Reposition floor to y=0 (artifacts sit on ground)
		_floor.position.y = 0.0

	# Environment lighting
	if _world_env and _world_env.environment:
		var env: Environment = _world_env.environment
		match size_class:
			PerfectShotFramer.SizeClass.TINY, PerfectShotFramer.SizeClass.SMALL:
				env.ambient_light_energy = 0.7
				env.ambient_light_color = Color(0.5, 0.52, 0.58)
			PerfectShotFramer.SizeClass.LARGE, PerfectShotFramer.SizeClass.HUGE:
				env.ambient_light_energy = 0.75
				env.ambient_light_color = Color(0.48, 0.5, 0.56)
			_:
				env.ambient_light_energy = 0.55
				env.ambient_light_color = Color(0.45, 0.5, 0.58)


# ═══════════════════════════════════════════════════════════════
# ANGLE PRESETS (number keys 1-4)
# ═══════════════════════════════════════════════════════════════

func _jump_to_angle(index: int) -> void:
	if index < 0 or index >= _computed_angles.size():
		return
	_current_angle_index = index
	var angle: Dictionary = _computed_angles[index]

	if PerfectShotFramer.is_environment_angle(angle):
		# Environment orbit for LARGE/HUGE
		var aabb: AABB = _current_analysis.get("aabb", AABB())
		var radius: float = PerfectShotFramer.get_environment_orbit_radius(aabb)
		var height: float = PerfectShotFramer.get_environment_orbit_height(aabb)
		_preview_camera.global_position = PerfectShotFramer.compute_environment_orbit_position(
			_orbit_focus, angle["yaw"], angle["pitch_factor"], radius, height
		)
		_preview_camera.look_at(_orbit_focus, Vector3.UP)
		# Sync orbit state
		_orbit_yaw = angle["yaw"]
		_orbit_distance = _preview_camera.global_position.distance_to(_orbit_focus)
	else:
		_orbit_yaw = angle["yaw"]
		_orbit_pitch = angle["pitch"]
		_update_camera_from_orbit()


# ═══════════════════════════════════════════════════════════════
# HUD
# ═══════════════════════════════════════════════════════════════

func _build_hud():
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	canvas.layer = 110  # Below sidebar (120) but above scene
	add_child(canvas)

	_hud_label = Label.new()
	_hud_label.name = "InfoLabel"
	_hud_label.position = Vector2(16, 16)
	_hud_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 0.9))
	_hud_label.add_theme_font_size_override("font_size", 13)
	_hud_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	_hud_label.add_theme_constant_override("shadow_offset_x", 1)
	_hud_label.add_theme_constant_override("shadow_offset_y", 1)
	canvas.add_child(_hud_label)


func _update_hud():
	if not _hud_label:
		return

	if _current_lookup_name.is_empty():
		_hud_label.text = "Select an artifact from the sidebar\nR=rotate  1-4=angles  Space=capture"
		return

	var size_name: String = _current_analysis.get("size_name", "?")
	var max_dim: float = _current_analysis.get("max_dimension", 0.0)
	var aabb: AABB = _current_analysis.get("aabb", AABB())

	var angle_name: String = "free"
	if _current_angle_index >= 0 and _current_angle_index < _computed_angles.size():
		angle_name = str(_computed_angles[_current_angle_index]["name"])

	var capture_info: String = ""
	if not _last_capture_path.is_empty():
		capture_info = "\nSaved: %s" % _last_capture_path.get_file()

	_hud_label.text = "%s\n%s | %.2f x %.2f x %.2f | dist: %.1f\nAngle: %s (%d/%d) | R=rotate 1-%d=angles Space=capture%s" % [
		_current_lookup_name,
		size_name, aabb.size.x, aabb.size.y, aabb.size.z,
		_orbit_distance,
		angle_name, _current_angle_index + 1, _computed_angles.size(),
		_computed_angles.size(),
		capture_info,
	]


# ═══════════════════════════════════════════════════════════════
# ANIMATION
# ═══════════════════════════════════════════════════════════════

func _animate_preview_in(artifact: Node3D):
	var original_scale = artifact.scale
	artifact.scale = Vector3.ZERO

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(artifact, "scale", original_scale, 0.6)


func _clear_preview():
	if _current_preview_artifact and is_instance_valid(_current_preview_artifact):
		_current_preview_artifact.queue_free()
		_current_preview_artifact = null
	_current_lookup_name = ""
	_current_analysis = {}
	_computed_angles = []
	_current_angle_index = -1


# ═══════════════════════════════════════════════════════════════
# INPUT — Orbit / Pan / Zoom + Angle Keys
# ═══════════════════════════════════════════════════════════════

func _input(event: InputEvent):
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and not _is_text_input_focused():
			# R = toggle rotation
			if key_event.keycode == toggle_rotation_key or key_event.physical_keycode == toggle_rotation_key:
				_rotate_preview = not _rotate_preview
				return

			# N = next artifact (placeholder for sidebar navigation)
			if key_event.keycode == next_artifact_key or key_event.physical_keycode == next_artifact_key:
				return

			# Space = capture current view
			if key_event.keycode == KEY_SPACE:
				_capture_current_view()
				return

			# Number keys 1-9: jump to computed angle
			var num: int = key_event.keycode - KEY_1
			if num >= 0 and num < _computed_angles.size():
				_jump_to_angle(num)
				_rotate_preview = false  # Stop rotation when jumping to angle
				return

	# Escape to clear preview
	if event.is_action_pressed("ui_cancel"):
		_clear_preview()

	# Skip mouse controls when over sidebar
	if _overlay and _overlay.is_mouse_over_panel():
		_is_orbiting = false
		_is_panning = false
		return

	# --- Mouse orbit / pan / zoom ---
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		# Left mouse: orbit
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_is_orbiting = mb.pressed
			if mb.pressed:
				_current_angle_index = -1  # Manual orbit = free angle
		# Right mouse: pan
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_is_panning = mb.pressed
		# Scroll: zoom
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_orbit_distance = max(zoom_min, _orbit_distance - zoom_sensitivity)
			_update_camera_from_orbit()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_orbit_distance = min(zoom_max, _orbit_distance + zoom_sensitivity)
			_update_camera_from_orbit()

	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _is_orbiting:
			_orbit_yaw -= motion.relative.x * orbit_sensitivity
			_orbit_pitch -= motion.relative.y * orbit_sensitivity
			_orbit_pitch = clamp(_orbit_pitch, -PI * 0.45, PI * 0.45)
			_update_camera_from_orbit()
		elif _is_panning:
			var right := _preview_camera.global_transform.basis.x
			var up := _preview_camera.global_transform.basis.y
			_orbit_focus -= right * motion.relative.x * pan_sensitivity
			_orbit_focus += up * motion.relative.y * pan_sensitivity
			_update_camera_from_orbit()


func _update_camera_from_orbit() -> void:
	if not _preview_camera:
		return
	var offset := Vector3(
		sin(_orbit_yaw) * cos(_orbit_pitch),
		sin(_orbit_pitch),
		cos(_orbit_yaw) * cos(_orbit_pitch)
	) * _orbit_distance
	_preview_camera.global_position = _orbit_focus + offset
	_preview_camera.look_at(_orbit_focus, Vector3.UP)


func _is_text_input_focused() -> bool:
	var viewport := get_viewport()
	if not viewport:
		return false
	var focused := viewport.gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit


## Claude Bridge — send selection events to local Claude Code session.
## No-op when --no-bridges is passed (capture flow) or when the 9876
## listener isn't reachable. Early-exits silently in capture mode; that's
## the point — a clean capture session should make zero HTTP noise.
func _send_to_claude(event_type: String, value: String) -> void:
	if "--no-bridges" in OS.get_cmdline_user_args() or "--no-bridges" in OS.get_cmdline_args():
		return

	var http := HTTPRequest.new()
	http.name = "ClaudeBridgeHTTP"
	add_child(http)
	http.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray):
		print("ClaudeBridge: response code=%d result=%d" % [code, result])
		http.queue_free()
	)
	var payload := JSON.stringify({
		"text": "Artifact catalog: %s — %s" % [event_type, value],
		"type": event_type,
		"lookup_name": value,
		"source": "ArtifactCatalogDesktop3D",
	})
	print("ClaudeBridge: sending %s -> %s" % [event_type, value])
	var err := http.request(
		"http://127.0.0.1:9876/message",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		payload
	)
	if err != OK:
		push_warning("ClaudeBridge: request failed with error %s" % error_string(err))
		http.queue_free()


# ═══════════════════════════════════════════════════════════════
# MANUAL CAPTURE (Space bar)
# ═══════════════════════════════════════════════════════════════

func _capture_current_view() -> void:
	if _current_lookup_name.is_empty():
		return

	# Hide HUD and sidebar for clean capture
	var hud_was_visible: bool = _hud_label != null and _hud_label.visible
	if _hud_label:
		_hud_label.get_parent().visible = false
	var overlay_was_visible: bool = false
	if _overlay:
		overlay_was_visible = _overlay.visible
		_overlay.visible = false

	# Wait one frame for UI to disappear
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame

	# Capture
	var image: Image = get_viewport().get_texture().get_image()
	if image:
		_capture_count += 1
		var dir_path: String = "user://catalog_captures/%s" % _current_lookup_name
		DirAccess.make_dir_recursive_absolute(dir_path)

		var filename: String = "%s_%02d.png" % [_current_lookup_name, _capture_count]
		var output_path: String = dir_path.path_join(filename)
		var abs_path: String = ProjectSettings.globalize_path(output_path)

		if image.save_png(abs_path) == OK:
			_last_capture_path = abs_path
			print("CAPTURED: %s" % abs_path)
		else:
			print("CAPTURE FAILED: %s" % abs_path)

	# Restore HUD and sidebar
	if _hud_label and hud_was_visible:
		_hud_label.get_parent().visible = true
	if _overlay and overlay_was_visible:
		_overlay.visible = true


## Public API
func set_rotation_enabled(enabled: bool):
	_rotate_preview = enabled

func get_current_artifact() -> Node3D:
	return _current_preview_artifact

func get_current_analysis() -> Dictionary:
	return _current_analysis
