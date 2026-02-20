class_name ArtifactCatalogDesktop3D
extends Node3D

## Standalone 3D artifact catalog for desktop testing
## Includes preview viewport for viewing artifacts without needing GridSystem

@export var next_artifact_key: Key = KEY_N
@export var toggle_rotation_key: Key = KEY_R

## Orbit camera settings
@export_group("Camera Controls")
@export var orbit_sensitivity: float = 0.005
@export var pan_sensitivity: float = 0.01
@export var zoom_sensitivity: float = 0.3
@export var zoom_min: float = 1.0
@export var zoom_max: float = 20.0
@export var auto_rotate_speed: float = 0.3

@onready var _catalog_ui: CanvasLayer = $CatalogUI
@onready var _preview_container: Node3D = $PreviewContainer
@onready var _preview_camera: Camera3D = $PreviewContainer/PreviewCamera
@onready var _preview_light: DirectionalLight3D = $PreviewContainer/PreviewLight

var _current_preview_artifact: Node3D = null
var _rotate_preview: bool = true

# Orbit camera state
var _orbit_yaw: float = 0.0
var _orbit_pitch: float = -0.35  # Slight downward angle (~20°)
var _orbit_distance: float = 5.0
var _orbit_focus: Vector3 = Vector3(0, 1.0, 0)
var _is_orbiting: bool = false
var _is_panning: bool = false
var _mouse_captured: bool = false

func _ready():
	print("ArtifactCatalogDesktop3D: Initializing standalone catalog...")
	
	# Connect catalog UI signals
	if _catalog_ui:
		var catalog = _catalog_ui.get_node_or_null("ArtifactCatalogUI")
		if catalog and catalog.has_signal("spawn_requested"):
			catalog.spawn_requested.connect(_on_artifact_selected)
			print("ArtifactCatalogDesktop3D: Connected to spawn_requested signal")
	
	# Set initial camera from orbit state
	_update_camera_from_orbit()
	
	# Ensure artifacts are loaded (standalone mode)
	call_deferred("_refresh_catalog")

func _refresh_catalog():
	# Force load standalone registry
	var artifacts = ArtifactCatalogDataProvider.get_all_artifacts()
	print("ArtifactCatalogDesktop3D: Loaded %d artifacts" % artifacts.size())
	
	# Refresh UI if available
	if _catalog_ui:
		var catalog = _catalog_ui.get_node_or_null("ArtifactCatalogUI")
		if catalog and catalog.has_method("refresh"):
			catalog.refresh()

func _process(delta: float):
	# Auto-rotate orbit when not interacting
	if _rotate_preview and not _is_orbiting and not _is_panning:
		if _current_preview_artifact and is_instance_valid(_current_preview_artifact):
			_orbit_yaw += auto_rotate_speed * delta
			_update_camera_from_orbit()

func _on_artifact_selected(lookup_name: String):
	print("ArtifactCatalogDesktop3D: Artifact selected: %s" % lookup_name)
	_load_preview_artifact(lookup_name)

func _load_preview_artifact(lookup_name: String):
	# Clear existing preview and reset camera
	_clear_preview()
	_reset_orbit()
	
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
	
	# Center and scale artifact to fit preview
	_fit_artifact_to_preview(artifact)
	
	# Animate in
	_animate_preview_in(artifact)
	
	print("ArtifactCatalogDesktop3D: OK previewing: %s" % lookup_name)

func _fit_artifact_to_preview(artifact: Node3D):
	"""Scale and position artifact to fit nicely in preview area"""
	# Reset position to center
	artifact.position = Vector3.ZERO
	
	# Try to get bounding box
	var aabb = _get_combined_aabb(artifact)
	if aabb.size.length() > 0:
		# Scale to fit within 2 unit cube
		var max_dim = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		if max_dim > 0:
			var target_size = 2.0
			var scale_factor = target_size / max_dim
			artifact.scale *= scale_factor
		
		# Center based on AABB
		var center = aabb.get_center() * artifact.scale
		artifact.position = -center
		artifact.position.y += 0.5  # Lift slightly

func _get_combined_aabb(node: Node3D) -> AABB:
	"""Get combined AABB of node and all children"""
	var result = AABB()
	var first = true
	
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh = child.mesh
			if mesh:
				var child_aabb = mesh.get_aabb()
				# Transform to node space
				child_aabb = child.transform * child_aabb
				if first:
					result = child_aabb
					first = false
				else:
					result = result.merge(child_aabb)
		
		# Recurse into children
		if child is Node3D:
			var child_aabb = _get_combined_aabb(child)
			if child_aabb.size.length() > 0:
				if first:
					result = child_aabb
					first = false
				else:
					result = result.merge(child_aabb)
	
	return result

func _animate_preview_in(artifact: Node3D):
	"""Animate artifact appearing"""
	var original_scale = artifact.scale
	artifact.scale = Vector3.ZERO
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(artifact, "scale", original_scale, 0.6)

func _clear_preview():
	"""Remove current preview artifact"""
	if _current_preview_artifact and is_instance_valid(_current_preview_artifact):
		_current_preview_artifact.queue_free()
		_current_preview_artifact = null

func _input(event: InputEvent):
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and not _is_text_input_focused():
			if key_event.keycode == toggle_rotation_key or key_event.physical_keycode == toggle_rotation_key:
				_rotate_preview = not _rotate_preview
				return
			if key_event.keycode == next_artifact_key or key_event.physical_keycode == next_artifact_key:
				_select_next_artifact()
				return

	# Escape to clear preview
	if event.is_action_pressed("ui_cancel"):
		_clear_preview()

	# --- Mouse orbit / pan / zoom ---
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		# Left mouse: orbit
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_is_orbiting = mb.pressed
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
	"""Position the camera on a sphere around _orbit_focus using yaw/pitch/distance."""
	if not _preview_camera:
		return
	var offset := Vector3(
		sin(_orbit_yaw) * cos(_orbit_pitch),
		sin(_orbit_pitch),
		cos(_orbit_yaw) * cos(_orbit_pitch)
	) * _orbit_distance
	_preview_camera.global_position = _orbit_focus + offset
	_preview_camera.look_at(_orbit_focus, Vector3.UP)

func _reset_orbit() -> void:
	"""Reset orbit to default view."""
	_orbit_yaw = 0.0
	_orbit_pitch = -0.35
	_orbit_distance = 5.0
	_orbit_focus = Vector3(0, 1.0, 0)
	_update_camera_from_orbit()


func _select_next_artifact() -> void:
	if not _catalog_ui:
		return

	var catalog = _catalog_ui.get_node_or_null("ArtifactCatalogUI")
	if not catalog:
		return

	if catalog.has_method("select_next_artifact"):
		var lookup_name := str(catalog.select_next_artifact())
		if not lookup_name.is_empty():
			_load_preview_artifact(lookup_name)


func _is_text_input_focused() -> bool:
	var viewport := get_viewport()
	if not viewport:
		return false
	var focused := viewport.gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit

## Public API
func set_rotation_enabled(enabled: bool):
	_rotate_preview = enabled

func get_current_artifact() -> Node3D:
	return _current_preview_artifact
