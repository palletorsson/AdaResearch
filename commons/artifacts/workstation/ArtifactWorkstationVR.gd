class_name ArtifactWorkstationVR
extends Node3D

## VR Artifact Workstation — browse and test any artifact from inside VR.
## Uses a 2D UI panel on a kiosk stand (viewport_2d_in_3d pattern).
## Place in any map as an artifact.

const VIEWPORT_2D_3D = preload("res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn")
const UI_SCENE = preload("res://commons/artifacts/workstation/workstation_ui.tscn")
const HAND_POSE_AREA = preload("res://addons/godot-xr-tools/objects/hand_pose_area.tscn")

var _presentation_area: Node3D
var _current_artifact: Node = null
var _ui_instance: Control = null

func _ready() -> void:
	_build_kiosk()
	_build_presentation_area()

func _build_kiosk() -> void:
	# Kiosk positioned in front of the artifact (player stands behind kiosk, facing artifact)
	var kiosk_z := 2.5  # In front of center

	# Panel stand (cylinder post)
	var stand := CSGCylinder3D.new()
	stand.radius = 0.04
	stand.height = 1.6
	stand.position = Vector3(0, 0.8, kiosk_z)
	var stand_mat := StandardMaterial3D.new()
	stand_mat.albedo_color = Color(0.15, 0.15, 0.18)
	stand_mat.metallic = 0.5
	stand_mat.roughness = 0.3
	stand.material = stand_mat
	add_child(stand)

	# Screen backing
	var screen := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.65, 0.55, 0.02)
	screen.mesh = box
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.08, 0.08, 0.12)
	screen.material_override = screen_mat
	# Tilt screen toward player (angled back)
	screen.transform = Transform3D(
		Basis(Vector3.RIGHT, deg_to_rad(-25)),
		Vector3(0, 1.45, kiosk_z)
	)
	add_child(screen)

	# Viewport2Din3D — renders the 2D UI onto the screen
	var viewport := VIEWPORT_2D_3D.instantiate()
	viewport.transform = Transform3D(
		Basis(Vector3.RIGHT, deg_to_rad(-25)),
		Vector3(0, 1.45, kiosk_z + 0.015)
	)
	viewport.screen_size = Vector2(0.6, 0.5)
	viewport.scene = UI_SCENE
	viewport.viewport_size = Vector2(500, 420)
	add_child(viewport)

	# Hand pose area for VR pointing
	if ResourceLoader.exists("res://addons/godot-xr-tools/objects/hand_pose_area.tscn"):
		var hand_area := HAND_POSE_AREA.instantiate()
		hand_area.transform = Transform3D(
			Basis(Vector3.RIGHT, deg_to_rad(-25)),
			Vector3(0, 1.45, kiosk_z)
		)
		if ResourceLoader.exists("res://addons/godot-xr-tools/hands/poses/pose_point_left.tres"):
			hand_area.left_pose = load("res://addons/godot-xr-tools/hands/poses/pose_point_left.tres")
		if ResourceLoader.exists("res://addons/godot-xr-tools/hands/poses/pose_point_right.tres"):
			hand_area.right_pose = load("res://addons/godot-xr-tools/hands/poses/pose_point_right.tres")
		add_child(hand_area)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.6, 0.2, 0.5)
		collision.shape = shape
		hand_area.add_child(collision)

	# Connect to UI after viewport loads
	call_deferred("_connect_ui", viewport)

func _connect_ui(viewport: Node) -> void:
	# Wait for viewport to create the scene instance
	for i in range(10):
		await get_tree().process_frame
		_ui_instance = viewport.get_scene_instance() if viewport.has_method("get_scene_instance") else null
		if _ui_instance:
			break

	if _ui_instance and _ui_instance.has_signal("artifact_changed"):
		_ui_instance.artifact_changed.connect(_on_artifact_changed)
		print("ArtifactWorkstation: UI connected")
		# Load the first artifact (signal was emitted before we connected)
		if _ui_instance.has_method("_get_current_lookup"):
			_load_artifact(_ui_instance._get_current_lookup())
		elif _ui_instance.get("_current_list") and _ui_instance._current_list.size() > 0:
			var first: String = str(_ui_instance._current_list[0].get("lookup_name", ""))
			if first != "":
				_load_artifact(first)
	else:
		print("ArtifactWorkstation: Could not connect to UI scene")

func _build_presentation_area() -> void:
	_presentation_area = Node3D.new()
	_presentation_area.name = "PresentationArea"
	_presentation_area.position = Vector3(0, 0, 0)
	add_child(_presentation_area)

	# Title label above presentation
	var title := Label3D.new()
	title.text = "Artifact Workstation"
	title.font_size = 24
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color(1, 1, 1, 0.6)
	title.position = Vector3(0, 4.0, 0)
	add_child(title)

func _on_artifact_changed(lookup_name: String) -> void:
	_load_artifact(lookup_name)

func _load_artifact(lookup_name: String) -> void:
	# Clear current
	if _current_artifact:
		_current_artifact.queue_free()
		_current_artifact = null
	for child in _presentation_area.get_children():
		child.queue_free()

	# Get scene path from registry
	var art: Dictionary = ArtifactCatalogDataProvider.get_artifact_by_lookup_name(lookup_name)
	var scene_path: String = str(art.get("scene", ""))

	if scene_path == "" or not ResourceLoader.exists(scene_path):
		print("ArtifactWorkstation: Scene not found: %s" % scene_path)
		return

	print("ArtifactWorkstation: Loading '%s'" % lookup_name)

	# Some scenes have broken scripts — catch load failures
	var packed: Resource = null
	if ResourceLoader.exists(scene_path):
		packed = ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REUSE)

	if not packed or not packed is PackedScene:
		print("ArtifactWorkstation: Skip '%s' (load failed)" % lookup_name)
		return

	var instance: Node = (packed as PackedScene).instantiate()
	if not instance:
		print("ArtifactWorkstation: Skip '%s' (instantiate failed)" % lookup_name)
		return

	_presentation_area.add_child(instance)
	_current_artifact = instance
	_disable_cameras_recursive(instance)

	# Auto-fit after a frame
	call_deferred("_fit_artifact")
	print("ArtifactWorkstation: Showing '%s'" % lookup_name)

func _fit_artifact() -> void:
	if not _current_artifact or not _current_artifact is Node3D:
		return

	var node3d := _current_artifact as Node3D
	var aabb := _get_aabb(node3d)
	if aabb.size.length() < 0.01:
		return

	# Center
	node3d.position -= aabb.get_center()
	node3d.position.y += aabb.size.y * 0.5

	# Scale to fit 3m
	var max_dim := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if max_dim > 3.0:
		node3d.scale = Vector3.ONE * (3.0 / max_dim)

func _disable_cameras_recursive(node: Node) -> void:
	if node is Camera3D:
		(node as Camera3D).current = false
	for child in node.get_children():
		_disable_cameras_recursive(child)

func _get_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.get_children():
		if child is VisualInstance3D:
			var vi := child as VisualInstance3D
			var a: AABB = vi.get_aabb()
			var t: Transform3D = vi.transform
			var p1: Vector3 = t * a.position
			var p2: Vector3 = t * (a.position + a.size)
			var expanded := AABB(
				Vector3(minf(p1.x, p2.x), minf(p1.y, p2.y), minf(p1.z, p2.z)),
				Vector3(absf(p2.x - p1.x), absf(p2.y - p1.y), absf(p2.z - p1.z))
			)
			if first:
				result = expanded
				first = false
			else:
				result = result.merge(expanded)
		if child is Node3D:
			var sub := _get_aabb(child as Node3D)
			if sub.size.length() > 0:
				if first:
					result = sub
					first = false
				else:
					result = result.merge(sub)
	return result

# Keyboard fallback for desktop testing
func _unhandled_input(event: InputEvent) -> void:
	if not _ui_instance:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_RIGHT:
				if _ui_instance.has_method("_on_next"):
					_ui_instance._on_next()
			KEY_LEFT:
				if _ui_instance.has_method("_on_prev"):
					_ui_instance._on_prev()
			KEY_TAB:
				if _ui_instance.has_method("_on_mode"):
					_ui_instance._on_mode()
			KEY_UP:
				if _ui_instance.has_method("_on_group_next"):
					_ui_instance._on_group_next()
			KEY_DOWN:
				if _ui_instance.has_method("_on_group_prev"):
					_ui_instance._on_group_prev()

func apply_grid_config(config: Dictionary) -> void:
	pass
