class_name ArtifactWorkstationVR
extends Node3D

## VR Artifact Workstation — browse and test any artifact from inside VR.
## Navigate by sequence, type, or all. See it running. Rate it. Move on.

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

# --- State ---
var _all_artifacts: Array = []
var _current_list: Array = []  # filtered/sorted view
var _current_index: int = 0
var _current_artifact: Node = null
var _sort_mode: int = 0  # 0=all, 1=by_sequence, 2=by_type
var _current_group: String = ""  # current sequence/type name
var _groups: Array[String] = []
var _group_index: int = 0

# --- UI Nodes ---
var _presentation_area: Node3D
var _name_label: Label3D
var _position_label: Label3D
var _group_label: Label3D
var _info_label: Label3D
var _mode_label: Label3D
var _description_label: Label3D

const SORT_NAMES := ["ALL", "SEQUENCE", "TYPE"]

func _ready() -> void:
	_build_environment()
	_build_presentation_area()
	_build_control_panel()
	_build_info_panel()
	_load_data()
	if _current_list.size() > 0:
		_show_artifact(_current_index)

# === ENVIRONMENT ===

func _build_environment() -> void:
	# Dark room
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.06, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.4, 0.45)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Key light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.3
	light.shadow_enabled = true
	add_child(light)

	# Fill light
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_energy = 0.4
	add_child(fill)

	# Floor circle (subtle reference)
	var floor_mesh := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 3.0
	disc.bottom_radius = 3.0
	disc.height = 0.02
	disc.radial_segments = 32
	floor_mesh.mesh = disc
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.1, 0.1, 0.12)
	floor_mat.roughness = 0.95
	floor_mesh.material_override = floor_mat
	floor_mesh.position.y = -0.01
	add_child(floor_mesh)

# === PRESENTATION AREA ===

func _build_presentation_area() -> void:
	_presentation_area = Node3D.new()
	_presentation_area.name = "PresentationArea"
	_presentation_area.position = Vector3(0, 0, 0)
	add_child(_presentation_area)

# === CONTROL PANEL (left side) ===

func _build_control_panel() -> void:
	var panel := Node3D.new()
	panel.name = "ControlPanel"
	panel.position = Vector3(-3.5, 0, 0)
	add_child(panel)

	# PREV button
	var btn_prev := PUSH_BUTTON.instantiate()
	btn_prev.position = Vector3(0, 1.0, 0.3)
	btn_prev.scale = Vector3(2.0, 2.0, 2.0)
	panel.add_child(btn_prev)
	_connect_button(btn_prev, _on_prev)
	_add_button_label(btn_prev, "PREV")

	# NEXT button
	var btn_next := PUSH_BUTTON.instantiate()
	btn_next.position = Vector3(0, 1.0, -0.3)
	btn_next.scale = Vector3(2.0, 2.0, 2.0)
	panel.add_child(btn_next)
	_connect_button(btn_next, _on_next)
	_add_button_label(btn_next, "NEXT")

	# MODE button (cycles ALL → SEQUENCE → TYPE)
	var btn_mode := PUSH_BUTTON.instantiate()
	btn_mode.position = Vector3(0, 1.4, 0)
	btn_mode.scale = Vector3(2.0, 2.0, 2.0)
	panel.add_child(btn_mode)
	_connect_button(btn_mode, _on_mode_cycle)
	_mode_label = _add_button_label(btn_mode, "MODE: ALL")

	# GROUP PREV/NEXT (switch between sequences or types)
	var btn_gprev := PUSH_BUTTON.instantiate()
	btn_gprev.position = Vector3(0, 1.8, 0.3)
	btn_gprev.scale = Vector3(1.5, 1.5, 1.5)
	panel.add_child(btn_gprev)
	_connect_button(btn_gprev, _on_group_prev)
	_add_button_label(btn_gprev, "GRP<")

	var btn_gnext := PUSH_BUTTON.instantiate()
	btn_gnext.position = Vector3(0, 1.8, -0.3)
	btn_gnext.scale = Vector3(1.5, 1.5, 1.5)
	panel.add_child(btn_gnext)
	_connect_button(btn_gnext, _on_group_next)
	_add_button_label(btn_gnext, "GRP>")

	# Position labels
	_name_label = _make_label("", Vector3(0, 2.4, 0), 28, Color(1, 1, 1, 0.95))
	panel.add_child(_name_label)

	_position_label = _make_label("", Vector3(0, 2.2, 0), 18, Color(0.6, 0.6, 0.6, 0.7))
	panel.add_child(_position_label)

	_group_label = _make_label("", Vector3(0, 2.0, 0), 20, Color(1.0, 0.7, 0.2, 0.8))
	panel.add_child(_group_label)

# === INFO PANEL (right side) ===

func _build_info_panel() -> void:
	var panel := Node3D.new()
	panel.name = "InfoPanel"
	panel.position = Vector3(3.5, 0, 0)
	add_child(panel)

	_info_label = _make_label("", Vector3(0, 2.0, 0), 16, Color(0.7, 0.7, 0.7, 0.7))
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel.add_child(_info_label)

	_description_label = _make_label("", Vector3(0, 1.2, 0), 14, Color(0.5, 0.5, 0.5, 0.6))
	_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_description_label.width = 400
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(_description_label)

# === DATA LOADING ===

func _load_data() -> void:
	_all_artifacts = ArtifactCatalogDataProvider.get_all_artifacts()
	# Sort alphabetically by default
	_all_artifacts.sort_custom(func(a, b): return str(a.get("lookup_name", "")) < str(b.get("lookup_name", "")))
	print("ArtifactWorkstation: Loaded %d artifacts" % _all_artifacts.size())
	_apply_sort()

func _apply_sort() -> void:
	match _sort_mode:
		0:  # ALL
			_current_list = _all_artifacts.duplicate()
			_groups = ["all"]
			_current_group = "all"
		1:  # BY SEQUENCE
			_build_groups_by_field("map_sequences")
		2:  # BY TYPE
			_build_groups_by_field("artifact_type")

	_current_index = 0
	if _current_list.size() > 0:
		_show_artifact(0)
	_update_labels()

func _build_groups_by_field(field: String) -> void:
	var group_map: Dictionary = {}
	for art in _all_artifacts:
		var val = art.get(field, "")
		var group_names: Array = []
		if val is Array:
			group_names = val
		elif val is String and val != "":
			group_names = [val]
		else:
			group_names = ["ungrouped"]
		for g in group_names:
			if g not in group_map:
				group_map[g] = []
			group_map[g].append(art)

	_groups = []
	for g in group_map.keys():
		_groups.append(g)
	_groups.sort()

	if _group_index >= _groups.size():
		_group_index = 0
	_current_group = _groups[_group_index] if _groups.size() > 0 else ""
	_current_list = group_map.get(_current_group, [])
	_current_index = 0

# === ARTIFACT LOADING ===

func _show_artifact(index: int) -> void:
	if index < 0 or index >= _current_list.size():
		return

	_current_index = index
	var art: Dictionary = _current_list[index]
	var lookup: String = str(art.get("lookup_name", ""))
	var scene_path: String = str(art.get("scene", ""))

	# Free current artifact
	if _current_artifact:
		_current_artifact.queue_free()
		_current_artifact = null

	# Clear presentation area
	for child in _presentation_area.get_children():
		child.queue_free()

	# Load new artifact
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		print("ArtifactWorkstation: Scene not found for '%s': %s" % [lookup, scene_path])
		_update_labels()
		return

	var packed: PackedScene = ResourceLoader.load(scene_path)
	if not packed:
		print("ArtifactWorkstation: Failed to load '%s'" % scene_path)
		_update_labels()
		return

	var instance: Node = packed.instantiate()
	if not instance:
		_update_labels()
		return

	_presentation_area.add_child(instance)
	_current_artifact = instance

	# Disable artifact cameras (from capture-debug flow)
	_disable_cameras_recursive(instance)

	# Auto-fit after a frame
	call_deferred("_fit_artifact")

	_update_labels()
	print("ArtifactWorkstation: Loaded '%s' (%d/%d)" % [lookup, index + 1, _current_list.size()])

func _fit_artifact() -> void:
	if not _current_artifact or not _current_artifact is Node3D:
		return

	var aabb := _get_combined_aabb(_current_artifact as Node3D)
	if aabb.size.length() < 0.01:
		return

	# Center on AABB
	var center := aabb.get_center()
	(_current_artifact as Node3D).position -= center
	(_current_artifact as Node3D).position.y += aabb.size.y * 0.5

	# Scale to fit within ~3m presentation area
	var max_dim := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if max_dim > 3.0:
		var scale_factor := 3.0 / max_dim
		(_current_artifact as Node3D).scale = Vector3.ONE * scale_factor

func _disable_cameras_recursive(node: Node) -> void:
	if node is Camera3D:
		(node as Camera3D).current = false
	for child in node.get_children():
		_disable_cameras_recursive(child)

func _get_combined_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.get_children():
		if child is VisualInstance3D:
			var vi := child as VisualInstance3D
			var local_aabb: AABB = vi.get_aabb()
			# Transform AABB corners to parent space
			var t: Transform3D = vi.transform
			var p1: Vector3 = t * local_aabb.position
			var p2: Vector3 = t * (local_aabb.position + local_aabb.size)
			var child_aabb := AABB(Vector3(minf(p1.x, p2.x), minf(p1.y, p2.y), minf(p1.z, p2.z)), Vector3.ZERO)
			child_aabb = child_aabb.expand(p1)
			child_aabb = child_aabb.expand(p2)
			if first:
				result = child_aabb
				first = false
			else:
				result = result.merge(child_aabb)
		if child is Node3D:
			var sub := _get_combined_aabb(child as Node3D)
			if sub.size.length() > 0:
				if first:
					result = sub
					first = false
				else:
					result = result.merge(sub)
	return result

# === NAVIGATION ===

func _on_next() -> void:
	if _current_list.size() == 0:
		return
	_show_artifact((_current_index + 1) % _current_list.size())

func _on_prev() -> void:
	if _current_list.size() == 0:
		return
	_show_artifact((_current_index - 1 + _current_list.size()) % _current_list.size())

func _on_mode_cycle() -> void:
	_sort_mode = (_sort_mode + 1) % 3
	_group_index = 0
	_apply_sort()

func _on_group_next() -> void:
	if _groups.size() <= 1:
		return
	_group_index = (_group_index + 1) % _groups.size()
	_current_group = _groups[_group_index]
	_apply_sort_within_group()

func _on_group_prev() -> void:
	if _groups.size() <= 1:
		return
	_group_index = (_group_index - 1 + _groups.size()) % _groups.size()
	_current_group = _groups[_group_index]
	_apply_sort_within_group()

func _apply_sort_within_group() -> void:
	if _sort_mode == 0:
		_current_list = _all_artifacts.duplicate()
	else:
		var field := "map_sequences" if _sort_mode == 1 else "artifact_type"
		_current_list = _all_artifacts.filter(func(art):
			var val = art.get(field, "")
			if val is Array:
				return _current_group in val
			return str(val) == _current_group
		)
	_current_index = 0
	if _current_list.size() > 0:
		_show_artifact(0)
	_update_labels()

# === KEYBOARD FALLBACK (desktop testing) ===

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_RIGHT:
				_on_next()
			KEY_LEFT:
				_on_prev()
			KEY_UP:
				_on_group_next()
			KEY_DOWN:
				_on_group_prev()
			KEY_TAB:
				_on_mode_cycle()

# === LABEL UPDATES ===

func _update_labels() -> void:
	if _current_list.size() == 0:
		_name_label.text = "No artifacts"
		_position_label.text = ""
		_group_label.text = ""
		_info_label.text = ""
		_description_label.text = ""
		return

	var art: Dictionary = _current_list[_current_index] if _current_index < _current_list.size() else {}
	var lookup: String = str(art.get("lookup_name", "?"))
	var name: String = str(art.get("name", lookup))

	_name_label.text = name
	_position_label.text = "%d / %d" % [_current_index + 1, _current_list.size()]

	var mode_name: String = SORT_NAMES[_sort_mode]
	if _mode_label:
		_mode_label.text = "MODE: %s" % mode_name

	if _sort_mode == 0:
		_group_label.text = "all artifacts"
	else:
		_group_label.text = "%s (%d/%d)" % [_current_group, _group_index + 1, _groups.size()]

	# Info panel
	var seqs = art.get("map_sequences", [])
	var seq_str: String = ", ".join(seqs) if seqs is Array else str(seqs)
	var art_type: String = str(art.get("artifact_type", "?"))
	var complexity: String = str(art.get("complexity", "?"))

	_info_label.text = "Type: %s\nSequence: %s\nComplexity: %s\nLookup: %s" % [
		art_type, seq_str, complexity, lookup
	]

	var desc: String = str(art.get("description", ""))
	if desc.length() > 200:
		desc = desc.substr(0, 197) + "..."
	_description_label.text = desc

# === HELPERS ===

func _connect_button(btn: Node, callback: Callable) -> void:
	var area = btn.get_node_or_null("InteractableAreaButton")
	if area and area.has_signal("button_pressed"):
		area.button_pressed.connect(callback)

func _add_button_label(btn: Node, text: String) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = 20
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = Color(1, 1, 1, 0.9)
	lbl.position = Vector3(0, 0.12, 0)
	btn.add_child(lbl)
	return lbl

func _make_label(text: String, pos: Vector3, size: int, color: Color) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = size
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = color
	lbl.position = pos
	return lbl

func apply_grid_config(config: Dictionary) -> void:
	pass
