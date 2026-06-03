class_name HandWorkstationVR
extends Node3D

## Wrist-mounted artifact browser — the "spawn machine" on the left hand.
## A small 2D-in-3D panel browsing every registered artifact, with a tiny live
## preview spinning above it. Point the right hand's laser at the panel and
## click to navigate (next / prev / mode). A shrunk relative of
## ArtifactWorkstationVR, oriented to be read on the back of the wrist.
##
## Mount as a child of XROrigin3D/LeftHand in base.tscn. The exact wrist
## position/angle is set by the parent node's transform there and is meant to
## be fine-tuned in-headset.

const VIEWPORT_2D_3D = preload("res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn")
const UI_SCENE = preload("res://commons/artifacts/workstation/workstation_ui.tscn")

const PANEL_W := 0.14
const PANEL_H := 0.115
const PREVIEW_FIT := 0.10  # max size of the floating preview, metres
const TILT_DEG := -42.0     # face up-and-back toward the eyes when wrist is raised

var _tilt: Node3D
var _preview_area: Node3D
var _current_artifact: Node = null
var _ui_instance: Control = null

func _ready() -> void:
	# Everything lives under a tilted pivot so the panel reads on the wrist;
	# the parent (LeftHand) transform only has to position it.
	_tilt = Node3D.new()
	_tilt.name = "Tilt"
	_tilt.rotation_degrees = Vector3(TILT_DEG, 0, 0)
	add_child(_tilt)
	_build_panel()
	_build_preview_area()

func _build_panel() -> void:
	# screen backing
	var screen := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(PANEL_W + 0.012, PANEL_H + 0.012, 0.005)
	screen.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.09)
	mat.emission_enabled = true
	mat.emission = Color(0.03, 0.04, 0.08)
	mat.emission_energy_multiplier = 0.4
	screen.material_override = mat
	_tilt.add_child(screen)

	# Viewport2Din3D — renders the browser UI onto the panel
	var viewport := VIEWPORT_2D_3D.instantiate()
	viewport.position = Vector3(0, 0, 0.004)
	viewport.screen_size = Vector2(PANEL_W, PANEL_H)
	viewport.scene = UI_SCENE
	viewport.viewport_size = Vector2(500, 420)
	_tilt.add_child(viewport)

	var title := Label3D.new()
	title.text = "ARTIFACTS"
	title.font_size = 40
	title.pixel_size = 0.0006
	title.modulate = Color(0.6, 0.85, 1.0, 0.95)
	title.outline_size = 6
	title.outline_modulate = Color(0, 0, 0, 0.7)
	title.position = Vector3(0, PANEL_H * 0.5 + 0.02, 0.006)
	_tilt.add_child(title)

	call_deferred("_connect_ui", viewport)

func _build_preview_area() -> void:
	_preview_area = Node3D.new()
	_preview_area.name = "PreviewArea"
	# floats just above the panel, on the tilted plane
	_preview_area.position = Vector3(0, PANEL_H * 0.5 + PREVIEW_FIT * 0.75, 0.04)
	_tilt.add_child(_preview_area)

func _process(delta: float) -> void:
	if is_instance_valid(_current_artifact) and _current_artifact is Node3D:
		(_current_artifact as Node3D).rotate_y(delta * 0.8)

func _connect_ui(viewport: Node) -> void:
	for i in range(12):
		await get_tree().process_frame
		_ui_instance = viewport.get_scene_instance() if viewport.has_method("get_scene_instance") else null
		if _ui_instance:
			break
	if _ui_instance and _ui_instance.has_signal("artifact_changed"):
		_ui_instance.artifact_changed.connect(_on_artifact_changed)
		if _ui_instance.has_method("_get_current_lookup"):
			_load_artifact(_ui_instance._get_current_lookup())
		print("[HandWorkstation] UI connected")
	else:
		print("[HandWorkstation] Could not connect UI")

func _on_artifact_changed(lookup_name: String) -> void:
	_load_artifact(lookup_name)

func _load_artifact(lookup_name: String) -> void:
	if is_instance_valid(_current_artifact):
		_current_artifact.queue_free()
	_current_artifact = null
	for c in _preview_area.get_children():
		c.queue_free()

	var art: Dictionary = ArtifactCatalogDataProvider.get_artifact_by_lookup_name(lookup_name)
	var scene_path: String = str(art.get("scene", ""))
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return
	var packed: PackedScene = _safe_load(scene_path)
	if not packed:
		return
	var inst: Node = _safe_instantiate(packed)
	if not inst:
		return
	_preview_area.add_child(inst)
	if not is_instance_valid(inst):
		_current_artifact = null
		return
	_current_artifact = inst
	_disable_cameras_recursive(inst)
	call_deferred("_fit_preview")

func _fit_preview() -> void:
	if not is_instance_valid(_current_artifact) or not _current_artifact is Node3D:
		return
	var n := _current_artifact as Node3D
	var aabb := _get_aabb(n)
	if aabb.size.length() < 0.001:
		return
	n.position -= aabb.get_center()
	var md := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if md > 0.0001:
		n.scale = Vector3.ONE * (PREVIEW_FIT / md)

# ── safe load / instantiate (from ArtifactWorkstationVR) ───────────────────
func _safe_load(path: String) -> PackedScene:
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_REUSE)
	return res as PackedScene if res is PackedScene else null

func _safe_instantiate(packed: PackedScene) -> Node:
	var state: SceneState = packed.get_state()
	if state.get_node_count() == 0:
		return null
	return packed.instantiate()

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
				Vector3(absf(p2.x - p1.x), absf(p2.y - p1.y), absf(p2.z - p1.z)))
			if first:
				result = expanded; first = false
			else:
				result = result.merge(expanded)
		if child is Node3D:
			var sub := _get_aabb(child as Node3D)
			if sub.size.length() > 0:
				if first:
					result = sub; first = false
				else:
					result = result.merge(sub)
	return result

func apply_grid_config(_config: Dictionary) -> void:
	pass
