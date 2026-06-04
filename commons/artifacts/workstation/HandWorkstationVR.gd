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
const PICKABLE = preload("res://addons/godot-xr-tools/objects/pickable.tscn")

const PANEL_W := 0.14
const PANEL_H := 0.115
const PREVIEW_FIT := 0.10  # max size of the floating preview, metres
const TILT_DEG := -42.0     # face up-and-back toward the eyes when wrist is raised

var _tilt: Node3D
var _preview_area: Node3D
var _current_artifact: Node = null
var _ui_instance: Control = null
var _current_lookup: String = ""

# grid placement preview ("where will this land")
var _grid_structure: GridStructureComponent = null
var _grid_search_cooldown: float = 0.0
var _place_ghost: MeshInstance3D = null
var _ghost_pulse: float = 0.0

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
	_update_place_ghost(delta)

func _connect_ui(viewport: Node) -> void:
	for i in range(12):
		await get_tree().process_frame
		_ui_instance = viewport.get_scene_instance() if viewport.has_method("get_scene_instance") else null
		if _ui_instance:
			break
	if _ui_instance and _ui_instance.has_signal("artifact_changed"):
		_ui_instance.artifact_changed.connect(_on_artifact_changed)
		if _ui_instance.has_signal("place_requested"):
			_ui_instance.place_requested.connect(_spawn_into_world)
		if _ui_instance.has_method("_get_current_lookup"):
			_load_artifact(_ui_instance._get_current_lookup())
		print("[HandWorkstation] UI connected")
	else:
		print("[HandWorkstation] Could not connect UI")

func _on_artifact_changed(lookup_name: String) -> void:
	_current_lookup = lookup_name
	_load_artifact(lookup_name)

## PLACE — spawn the current artifact onto the grid: snapped to the cell you're
## aiming at, sitting on TOP of the structure column there (find_highest_y_at) —
## the same spot the map loader uses, so what you place is what reloads. It's a
## grid object: grabbable and re-snapping on release, and it saves into the map's
## interactables layer when you press B. Falls back to a floor drop if no grid.
func _spawn_into_world(lookup_name: String) -> void:
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
	_disable_cameras_recursive(inst)
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	# Wrap the artifact in an XRTools pickable (RigidBody3D, grab layer 4) so
	# either hand can grab and move it — close, or ranged up to 5 m. Frozen
	# until its collider is sized; then released to gravity + grabbing.
	var pickable := PICKABLE.instantiate() as RigidBody3D
	if pickable == null:
		scene_root.add_child(inst)  # fallback: place raw
		return
	pickable.freeze = true
	pickable.add_child(inst)
	scene_root.add_child(pickable)

	# Grid placement: snap onto the cell you're aiming at, on TOP of the
	# structure column there — exactly where the map loader would put it
	# (find_highest_y_at). The placed artifact counts with the grid and saves
	# with B. Falls back to a floor drop if there's no grid in this scene.
	var structure := _find_grid_structure()
	if structure != null:
		var total_size: float = structure.cube_size + structure.gutter
		var grid_origin := _grid_origin(structure)
		var cell := _target_cell(structure, total_size, grid_origin)
		var y_pos: int = structure.find_highest_y_at(cell.x, cell.y)
		pickable.global_position = grid_origin + Vector3(cell.x, y_pos, cell.y) * total_size
		# Mark it a grid object: freeze on release so it stays snapped (never
		# falls). Re-snapped to the nearest column-top each time it's dropped.
		pickable.set_meta("vr_grid_object", true)
		# pickable is typed RigidBody3D here; release_mode / dropped are
		# XRToolsPickable members, so reach them by string to avoid a static
		# type error. 1 = XRToolsPickable.ReleaseMode.FROZEN (freeze on release).
		pickable.set("release_mode", 1)
		pickable.add_to_group("vr_placed_artifact")
		pickable.add_to_group("vr_editable_artifact")  # catalyst Edit-mode laser can grab it too
		pickable.set_meta("artifact_lookup_name", lookup_name)
		pickable.set_meta("grid_cell", cell)
		pickable.set_meta("grid_rotation_y", 0.0)
		if pickable.has_signal("dropped") and not pickable.is_connected("dropped", _on_placed_artifact_dropped):
			pickable.connect("dropped", _on_placed_artifact_dropped)
		print("[HandWorkstation] placed '%s' on grid cell (%d,%d) y=%d" % [lookup_name, cell.x, cell.y, y_pos])
	else:
		# Fallback (no grid): ~1.6 m in front at floor level, rests by gravity.
		var cam := _find_xr_camera()
		var origin := _find_xr_origin()
		var fwd := Vector3(0, 0, -1)
		var base_pos := global_position
		if cam:
			fwd = -cam.global_transform.basis.z
			fwd.y = 0.0
			if fwd.length() > 0.01:
				fwd = fwd.normalized()
			base_pos = cam.global_position
		var floor_y: float = origin.global_position.y if origin else base_pos.y
		pickable.global_position = Vector3(base_pos.x, floor_y + 0.05, base_pos.z) + fwd * 1.6
		print("[HandWorkstation] placed '%s' (grabbable, no grid) in the world" % lookup_name)

	# size the grab collider once the artifact has built its geometry
	call_deferred("_finalize_pickable", pickable, inst)

func _finalize_pickable(pickable: Node, inst: Node) -> void:
	if not is_instance_valid(pickable) or not is_instance_valid(inst) or not inst is Node3D:
		return
	var aabb := _get_aabb(inst as Node3D)
	var cs := pickable.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs:
		var box := BoxShape3D.new()
		var s: Vector3 = aabb.size
		if s.length() < 0.05:
			s = Vector3(0.3, 0.3, 0.3)
		box.size = s
		cs.shape = box
		cs.position = aabb.get_center()
	# Hover indicator: a glow box that lights up whenever a hand's grab/laser
	# targets this artifact (XRTools fires highlight_updated on close OR ranged
	# focus). This is the "you're pointing at a grabbable thing" cue.
	_attach_highlight_box(pickable, aabb)
	if pickable.has_signal("highlight_updated") and not pickable.is_connected("highlight_updated", _on_pickable_highlight):
		pickable.connect("highlight_updated", _on_pickable_highlight)
	# Let the player pass through it: a placed artifact must stay on the
	# "Pickable Objects" layer (the only layer ranged-grab scans), but the
	# player body also scans that layer, so walking into a frozen artifact
	# launches you. Collision exceptions stop the physical push without
	# touching grab (grab is Area-based and ignores body exceptions).
	_exclude_player_collision(pickable)
	if pickable is RigidBody3D:
		if pickable.has_meta("vr_grid_object") and bool(pickable.get_meta("vr_grid_object")):
			(pickable as RigidBody3D).freeze = true   # grid object: stays snapped
		else:
			(pickable as RigidBody3D).freeze = false  # free object: rests by gravity

## Build a hidden glow box around the artifact; shown on hover/aim highlight.
func _attach_highlight_box(pickable: Node, aabb: AABB) -> void:
	if pickable.get_node_or_null("VrHighlightBox") != null:
		return
	var box := MeshInstance3D.new()
	box.name = "VrHighlightBox"
	var bm := BoxMesh.new()
	var s: Vector3 = aabb.size
	if s.length() < 0.05:
		s = Vector3(0.3, 0.3, 0.3)
	bm.size = s * 1.08
	box.mesh = bm
	box.position = aabb.get_center()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.85, 1.0, 0.16)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.85, 1.0)
	mat.emission_energy_multiplier = 0.8
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	box.material_override = mat
	box.visible = false
	pickable.add_child(box)

## XRTools highlight callback — toggle the glow box when this artifact is the
## hand's grab/laser target (close or ranged up to 5 m).
func _on_pickable_highlight(pickable, enable: bool) -> void:
	if not is_instance_valid(pickable):
		return
	var box = pickable.get_node_or_null("VrHighlightBox")
	if box:
		box.visible = enable

## Add collision exceptions so the placed artifact never physically pushes the
## player rig (body + collision hands). Grab still works — it's Area-based.
func _exclude_player_collision(pickable: Node) -> void:
	var co := pickable as CollisionObject3D
	if co == null:
		return
	var origin := _find_xr_origin()
	if origin == null:
		return
	for body in origin.find_children("*", "PhysicsBody3D", true, false):
		var pb := body as PhysicsBody3D
		if pb:
			co.add_collision_exception_with(pb)

func _find_xr_origin() -> XROrigin3D:
	var n: Node = get_parent()
	while n:
		if n is XROrigin3D:
			return n as XROrigin3D
		n = n.get_parent()
	return null

func _find_xr_camera() -> XRCamera3D:
	var o := _find_xr_origin()
	if o:
		for c in o.get_children():
			if c is XRCamera3D:
				return c as XRCamera3D
	return null

# ── grid placement ─────────────────────────────────────────────────────────

## Find the live grid structure component (same discovery the catalyst uses).
## Cached — it only re-walks the tree when the reference goes stale (map change).
func _find_grid_structure() -> GridStructureComponent:
	if is_instance_valid(_grid_structure):
		return _grid_structure
	var n := _find_node_by_name(get_tree().root, "GridStructureComponent")
	if n is GridStructureComponent:
		_grid_structure = n as GridStructureComponent
		return _grid_structure
	return null

## Live preview of where the next PLACE will land: a translucent green cell that
## sits on top of the structure column you're aiming at — the same cell the
## artifact will occupy. Matches the voxel editor's green add-ghost.
func _update_place_ghost(delta: float) -> void:
	if not is_instance_valid(_grid_structure):
		_grid_search_cooldown -= delta
		if _grid_search_cooldown <= 0.0:
			_grid_search_cooldown = 0.5
			_grid_structure = _find_grid_structure()
	var have_target := is_instance_valid(_grid_structure) and is_instance_valid(_current_artifact)
	if not have_target:
		if _place_ghost:
			_place_ghost.visible = false
		return
	var total_size: float = _grid_structure.cube_size + _grid_structure.gutter
	var grid_origin := _grid_origin(_grid_structure)
	var cell := _target_cell(_grid_structure, total_size, grid_origin)
	var y_pos: int = _grid_structure.find_highest_y_at(cell.x, cell.y)
	if _place_ghost == null:
		_build_place_ghost(total_size)
	_place_ghost.visible = true
	_place_ghost.global_position = grid_origin + Vector3(cell.x, y_pos, cell.y) * total_size
	# gentle pulse so it reads as a live target
	_ghost_pulse += delta * 3.0
	var mat := _place_ghost.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color.a = 0.16 + 0.10 * (0.5 + 0.5 * sin(_ghost_pulse))
		mat.emission_energy_multiplier = 0.35 + 0.25 * (0.5 + 0.5 * sin(_ghost_pulse))

func _build_place_ghost(cell_size: float) -> void:
	_place_ghost = MeshInstance3D.new()
	_place_ghost.name = "PlaceGhost"
	_place_ghost.top_level = true  # world space — ignore the moving wrist transform
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * cell_size * 0.92
	_place_ghost.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 1.0, 0.45, 0.18)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.3, 1.0, 0.45)
	mat.emission_energy_multiplier = 0.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	_place_ghost.material_override = mat
	_place_ghost.visible = false
	add_child(_place_ghost)

## World position of grid cell (0,0,0). The structure component is a plain Node;
## its parent (GridSystem) is the Node3D that carries the world transform.
func _grid_origin(structure: GridStructureComponent) -> Vector3:
	var p := structure.get_parent()
	return (p as Node3D).global_position if p is Node3D else Vector3.ZERO

## The grid cell (x,z) the player is aiming at: project the camera's flattened
## forward a few cells ahead, convert to grid space, and clamp to the grid.
func _target_cell(structure: GridStructureComponent, total_size: float, grid_origin: Vector3) -> Vector2i:
	var dims := structure.get_grid_dimensions()
	var aim := global_position
	var cam := _find_xr_camera()
	if cam:
		var fwd := -cam.global_transform.basis.z
		fwd.y = 0.0
		if fwd.length() > 0.01:
			fwd = fwd.normalized()
		aim = cam.global_position + fwd * (total_size * 2.5)
	var local := (aim - grid_origin) / total_size
	var x := clampi(int(round(local.x)), 0, maxi(dims.x - 1, 0))
	var z := clampi(int(round(local.z)), 0, maxi(dims.z - 1, 0))
	return Vector2i(x, z)

## When a placed artifact is dropped after a move, re-snap it to the nearest
## column-top so it stays a clean grid object (and saves to the right cell).
func _on_placed_artifact_dropped(pickable) -> void:
	if not is_instance_valid(pickable):
		return
	var structure := _find_grid_structure()
	if structure == null:
		return
	var total_size: float = structure.cube_size + structure.gutter
	var grid_origin := _grid_origin(structure)
	var dims := structure.get_grid_dimensions()
	var local := ((pickable as Node3D).global_position - grid_origin) / total_size
	var x := clampi(int(round(local.x)), 0, maxi(dims.x - 1, 0))
	var z := clampi(int(round(local.z)), 0, maxi(dims.z - 1, 0))
	# Respect the height you dropped it at: snap Y to the nearest integer level,
	# so artifacts can float (0,1,2,…). Dropped low it lands on the surface.
	var y_level: int = clampi(int(round(local.y)), 0, maxi(dims.y - 1, 6))
	# snap rotation too: stand it upright and yaw to the nearest 90°, so it
	# aligns to the grid like a cube (and saves as lookup:yaw).
	var yaw_deg: float = rad_to_deg((pickable as Node3D).global_rotation.y)
	var snapped_yaw: float = round(yaw_deg / 90.0) * 90.0
	(pickable as Node3D).global_rotation = Vector3(0.0, deg_to_rad(snapped_yaw), 0.0)
	(pickable as Node3D).global_position = grid_origin + Vector3(x, y_level, z) * total_size
	pickable.set_meta("grid_cell", Vector2i(x, z))
	pickable.set_meta("grid_y_level", y_level)
	pickable.set_meta("grid_rotation_y", fposmod(snapped_yaw, 360.0))
	if pickable is RigidBody3D:
		(pickable as RigidBody3D).linear_velocity = Vector3.ZERO
		(pickable as RigidBody3D).angular_velocity = Vector3.ZERO
		(pickable as RigidBody3D).freeze = true
	print("[HandWorkstation] re-snapped artifact to cell (%d,%d) y=%d yaw=%d" % [x, z, y_level, int(snapped_yaw)])

## Depth-first search for a node by exact name (rare calls: place / drop).
func _find_node_by_name(root: Node, target_name: String) -> Node:
	if root.name == target_name:
		return root
	for child in root.get_children():
		var found := _find_node_by_name(child, target_name)
		if found:
			return found
	return null


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
