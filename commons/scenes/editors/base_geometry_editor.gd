# base_geometry_editor.gd — Reusable parameter editor with 3D preview
#
# Provides: split view, orbit camera, slider system from PARAMETER_GROUPS,
# rebuild throttle, preset save/load. Subclass defines parameters + rebuild.
#
# Usage:
#   1. Extend this class
#   2. Override _get_parameter_groups() → return Array[Dictionary]
#   3. Override _get_editor_name() → return String
#   4. Override _rebuild() → regenerate geometry from _params
#   5. Optionally override _create_initial_geometry()
#
# Each parameter group: {"name": "GroupName", "params": [
#     {"id": "param_id", "label": "Label", "min": 0.0, "max": 1.0, "step": 0.05},
# ]}

class_name BaseGeometryEditor
extends HSplitContainer

# ── Core UI refs ──────────────────────────────────────────────
var controls: VBoxContainer = null
var viewport_container: SubViewportContainer = null
var viewport: SubViewport = null
var cam: Camera3D = null
var content_root: Node3D = null
var _world_env: WorldEnvironment = null
var info_label: Label = null

# ── Sliders & Dropdowns ───────────────────────────────────────
var _sliders: Dictionary = {}    # param_id → HSlider
var _dropdowns: Dictionary = {}  # param_id → OptionButton
var _params: Dictionary = {}     # param_id → float (current values)

# ── Post-process modifier stack ───────────────────────────────
var _mod_sliders: Dictionary = {}  # mod_param_id → HSlider
var _mod_dropdowns: Dictionary = {}
var _mod_params: Dictionary = {}   # mod_param_id → float

# ── Rebuild throttle ──────────────────────────────────────────
const REBUILD_THROTTLE: float = 0.15
var _rebuild_timer: float = 0.0
var _needs_rebuild: bool = false

# ── Orbit camera ──────────────────────────────────────────────
var orbit_yaw: float = 0.3
var orbit_pitch: float = 0.4
var orbit_dist: float = 3.0
var orbiting: bool = false
var _auto_rotate: bool = true

# ── Presets ────────────────────────────────────────────────────
var _presets: Array[Dictionary] = []
var _preset_list: ItemList = null
var _preset_name_edit: LineEdit = null


# ═══════════════════════════════════════════════════════════════
# VIRTUAL — Subclass must override
# ═══════════════════════════════════════════════════════════════

## Return parameter group definitions.
func _get_parameter_groups() -> Array:
	return []

## Return the editor name (used for preset folder + title).
func _get_editor_name() -> String:
	return "GeometryEditor"

## Rebuild the 3D geometry from current _params.
## Clear content_root children and create new geometry.
func _rebuild() -> void:
	pass

## Create the initial geometry when editor opens.
func _create_initial_geometry() -> void:
	_set_defaults()
	_rebuild()


# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	_setup_split_view()
	_setup_viewport()
	_build_header()
	_build_parameter_sliders()
	_build_modifier_stack()
	_build_preset_panel()
	_build_info_bar()
	_load_presets()
	viewport_container.gui_input.connect(_on_viewport_input)
	_create_initial_geometry()
	_update_cam()


func _process(delta: float) -> void:
	if _needs_rebuild:
		_rebuild_timer += delta
		if _rebuild_timer > REBUILD_THROTTLE:
			_rebuild_timer = 0.0
			_needs_rebuild = false
			_rebuild()
			_apply_modifier_stack()

	# Auto-rotate when idle
	if _auto_rotate and not orbiting and content_root:
		content_root.rotation.y += delta * 0.2


# ═══════════════════════════════════════════════════════════════
# SETUP
# ═══════════════════════════════════════════════════════════════

func _setup_split_view() -> void:
	var left_scroll := ScrollContainer.new()
	left_scroll.custom_minimum_size = Vector2(300, 0)
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(left_scroll)

	controls = VBoxContainer.new()
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(controls)

	viewport_container = SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(viewport_container)

	viewport = SubViewport.new()
	viewport.size = Vector2i(800, 600)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)


func _setup_viewport() -> void:
	cam = Camera3D.new()
	cam.name = "EditorCamera"
	cam.fov = 50
	cam.current = true
	viewport.add_child(cam)

	var light := DirectionalLight3D.new()
	light.light_energy = 1.0
	light.rotation_degrees = Vector3(-40, -30, 0)
	viewport.add_child(light)

	# Second fill light from opposite side
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.3
	fill.rotation_degrees = Vector3(-20, 150, 0)
	viewport.add_child(fill)

	_world_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.12, 0.15)
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.6
	_world_env.environment = env
	viewport.add_child(_world_env)

	content_root = Node3D.new()
	content_root.name = "ContentRoot"
	viewport.add_child(content_root)


# ═══════════════════════════════════════════════════════════════
# UI CONSTRUCTION
# ═══════════════════════════════════════════════════════════════

func _build_header() -> void:
	var header := Label.new()
	header.text = _get_editor_name()
	header.add_theme_font_size_override("font_size", 16)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_child(header)

	var sep := HSeparator.new()
	controls.add_child(sep)


func _build_parameter_sliders() -> void:
	var groups: Array = _get_parameter_groups()
	if groups.is_empty():
		return

	for group: Dictionary in groups:
		var group_label := Label.new()
		group_label.text = "— %s —" % [group.get("name", "???") as String]
		group_label.add_theme_font_size_override("font_size", 12)
		group_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		controls.add_child(group_label)

		var params: Array = group.get("params", []) as Array
		for param: Dictionary in params:
			var param_id: String = param.get("id", "") as String
			if param_id.is_empty():
				continue

			var hbox := HBoxContainer.new()

			var lbl := Label.new()
			lbl.text = param.get("label", param_id) as String
			lbl.custom_minimum_size = Vector2(100, 0)
			lbl.add_theme_font_size_override("font_size", 11)
			hbox.add_child(lbl)

			# Check if this param has dropdown options
			var options: Variant = param.get("options")
			if options is Array and (options as Array).size() > 0:
				# ── Dropdown (OptionButton) ──────────────────
				var dropdown := OptionButton.new()
				dropdown.custom_minimum_size = Vector2(140, 24)
				dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				for opt_idx: int in (options as Array).size():
					dropdown.add_item((options as Array)[opt_idx] as String, opt_idx)
				var default_idx: int = int(param.get("default", 0.0) as float)
				dropdown.select(clampi(default_idx, 0, (options as Array).size() - 1))
				dropdown.item_selected.connect(_on_dropdown_changed.bind(param_id))
				hbox.add_child(dropdown)
				_dropdowns[param_id] = dropdown
				_params[param_id] = float(default_idx)
			else:
				# ── Slider (HSlider) ─────────────────────────
				var slider := HSlider.new()
				slider.min_value = param.get("min", 0.0) as float
				slider.max_value = param.get("max", 1.0) as float
				slider.step = param.get("step", 0.05) as float
				slider.value = param.get("default", (slider.min_value + slider.max_value) * 0.5) as float
				slider.custom_minimum_size = Vector2(120, 20)
				slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				slider.value_changed.connect(_on_param_changed.bind(param_id))
				hbox.add_child(slider)

				var val_label := Label.new()
				val_label.name = "Val"
				val_label.text = "%.2f" % slider.value
				val_label.custom_minimum_size = Vector2(45, 0)
				val_label.add_theme_font_size_override("font_size", 10)
				hbox.add_child(val_label)

				_sliders[param_id] = slider
				_params[param_id] = slider.value

			controls.add_child(hbox)


func _build_preset_panel() -> void:
	var sep := HSeparator.new()
	controls.add_child(sep)

	var header := Label.new()
	header.text = "Presets"
	header.add_theme_font_size_override("font_size", 14)
	controls.add_child(header)

	var save_row := HBoxContainer.new()
	_preset_name_edit = LineEdit.new()
	_preset_name_edit.placeholder_text = "Name..."
	_preset_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_row.add_child(_preset_name_edit)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_save_preset)
	save_row.add_child(save_btn)

	var del_btn := Button.new()
	del_btn.text = "Del"
	del_btn.pressed.connect(_delete_preset)
	save_row.add_child(del_btn)

	controls.add_child(save_row)

	_preset_list = ItemList.new()
	_preset_list.custom_minimum_size = Vector2(0, 100)
	_preset_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preset_list.item_selected.connect(_on_preset_selected)
	controls.add_child(_preset_list)


func _build_modifier_stack() -> void:
	var sep := HSeparator.new()
	controls.add_child(sep)

	var header := Label.new()
	header.text = "— Post-Process Modifiers —"
	header.add_theme_font_size_override("font_size", 12)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color(0.6, 0.85, 0.95))
	controls.add_child(header)

	var mod_defs: Array[Dictionary] = [
		{"id": "mod_smooth", "label": "Smooth", "min": 0.0, "max": 5.0, "step": 1.0, "default": 0.0},
		{"id": "mod_smooth_factor", "label": "  Factor", "min": 0.1, "max": 1.0, "step": 0.05, "default": 0.5},
		{"id": "mod_subdivide", "label": "Subdivide", "min": 0.0, "max": 2.0, "step": 1.0, "default": 0.0},
		{"id": "mod_mirror", "label": "Mirror", "options": ["Off", "X", "Y", "Z"]},
		{"id": "mod_solidify", "label": "Solidify", "min": 0.0, "max": 0.15, "step": 0.005, "default": 0.0},
		{"id": "mod_array_count", "label": "Array Count", "min": 1.0, "max": 8.0, "step": 1.0, "default": 1.0},
		{"id": "mod_array_spacing", "label": "  Spacing", "min": 0.3, "max": 3.0, "step": 0.1, "default": 1.2},
		{"id": "mod_screw", "label": "Screw Steps", "min": 0.0, "max": 24.0, "step": 1.0, "default": 0.0},
		{"id": "mod_screw_height", "label": "  Height", "min": 0.0, "max": 3.0, "step": 0.1, "default": 0.0},
	]

	for mdef: Dictionary in mod_defs:
		var mid: String = mdef.get("id", "") as String
		var hbox := HBoxContainer.new()

		var lbl := Label.new()
		lbl.text = mdef.get("label", mid) as String
		lbl.custom_minimum_size = Vector2(100, 0)
		lbl.add_theme_font_size_override("font_size", 11)
		hbox.add_child(lbl)

		var options: Variant = mdef.get("options")
		if options is Array and (options as Array).size() > 0:
			var dropdown := OptionButton.new()
			dropdown.custom_minimum_size = Vector2(140, 24)
			dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			for oi: int in (options as Array).size():
				dropdown.add_item((options as Array)[oi] as String, oi)
			dropdown.select(0)
			dropdown.item_selected.connect(_on_mod_dropdown_changed.bind(mid))
			hbox.add_child(dropdown)
			_mod_dropdowns[mid] = dropdown
			_mod_params[mid] = 0.0
		else:
			var slider := HSlider.new()
			slider.min_value = mdef.get("min", 0.0) as float
			slider.max_value = mdef.get("max", 1.0) as float
			slider.step = mdef.get("step", 0.05) as float
			slider.value = mdef.get("default", 0.0) as float
			slider.custom_minimum_size = Vector2(120, 20)
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.value_changed.connect(_on_mod_changed.bind(mid))
			hbox.add_child(slider)

			var val_label := Label.new()
			val_label.name = "Val"
			val_label.text = "%.2f" % slider.value
			val_label.custom_minimum_size = Vector2(45, 0)
			val_label.add_theme_font_size_override("font_size", 10)
			hbox.add_child(val_label)

			_mod_sliders[mid] = slider
			_mod_params[mid] = slider.value

		controls.add_child(hbox)


func _on_mod_changed(value: float, mod_id: String) -> void:
	_mod_params[mod_id] = value
	var slider: HSlider = _mod_sliders.get(mod_id) as HSlider
	if slider:
		var val_label: Label = slider.get_parent().get_node_or_null("Val") as Label
		if val_label:
			val_label.text = "%.2f" % value
	_needs_rebuild = true
	_rebuild_timer = 0.0


func _on_mod_dropdown_changed(index: int, mod_id: String) -> void:
	_mod_params[mod_id] = float(index)
	_needs_rebuild = true
	_rebuild_timer = 0.0


func _mp(mod_id: String, default: float = 0.0) -> float:
	return _mod_params.get(mod_id, default) as float


## Apply the modifier stack to all MeshInstance3D children of content_root.
func _apply_modifier_stack() -> void:
	# Check if any modifier is active
	var has_active: bool = false
	if int(_mp("mod_smooth")) > 0: has_active = true
	if int(_mp("mod_subdivide")) > 0: has_active = true
	if int(_mp("mod_mirror")) > 0: has_active = true
	if _mp("mod_solidify") > 0.001: has_active = true
	if int(_mp("mod_array_count", 1)) > 1: has_active = true
	if int(_mp("mod_screw")) > 0: has_active = true
	if not has_active:
		return

	# Process each MeshInstance3D in content_root
	for child: Node in content_root.get_children():
		if not child is MeshInstance3D:
			continue
		var mi: MeshInstance3D = child as MeshInstance3D
		var mesh: Mesh = mi.mesh
		if not mesh:
			continue

		# Apply modifiers in Blender-like order

		# 1. Subdivide (topology)
		if int(_mp("mod_subdivide")) > 0:
			var iters: int = int(_mp("mod_subdivide"))
			for _i in iters:
				# Simple subdivision: use SurfaceTool to increase resolution
				mesh = MorphoModifier.smooth(mesh, 0, 0.0)  # 0 iterations = just convert format
				# Actually subdivide by inflating slightly then smoothing
			mesh = MorphoModifier.smooth(mesh, iters, 0.5)

		# 2. Smooth
		if int(_mp("mod_smooth")) > 0:
			mesh = MorphoModifier.smooth(mesh, int(_mp("mod_smooth")),
				_mp("mod_smooth_factor", 0.5))

		# 3. Mirror
		var mirror_axis: int = int(_mp("mod_mirror"))
		if mirror_axis > 0:
			mesh = MorphoModifier.mirror(mesh, mirror_axis - 1)

		# 4. Solidify
		if _mp("mod_solidify") > 0.001:
			mesh = MorphoModifier.solidify(mesh, _mp("mod_solidify"))

		# 5. Array
		if int(_mp("mod_array_count", 1)) > 1:
			mesh = MorphoModifier.array_modifier(mesh,
				int(_mp("mod_array_count")),
				Vector3(_mp("mod_array_spacing", 1.2), 0, 0))

		# 6. Screw
		if int(_mp("mod_screw")) > 0:
			mesh = MorphoModifier.screw(mesh, Vector3.UP,
				int(_mp("mod_screw")), 360.0, _mp("mod_screw_height"))

		if mesh:
			mi.mesh = mesh


func _build_info_bar() -> void:
	info_label = Label.new()
	info_label.text = "Drag: orbit | Scroll: zoom"
	info_label.add_theme_font_size_override("font_size", 10)
	controls.add_child(info_label)


# ═══════════════════════════════════════════════════════════════
# PARAMETER HANDLING
# ═══════════════════════════════════════════════════════════════

func _on_param_changed(value: float, param_id: String) -> void:
	_params[param_id] = value
	var slider: HSlider = _sliders.get(param_id) as HSlider
	if slider:
		var val_label: Label = slider.get_parent().get_node_or_null("Val") as Label
		if val_label:
			val_label.text = "%.2f" % value
	_needs_rebuild = true
	_rebuild_timer = 0.0


func _on_dropdown_changed(index: int, param_id: String) -> void:
	_params[param_id] = float(index)
	_needs_rebuild = true
	_rebuild_timer = 0.0


func _set_defaults() -> void:
	for group: Dictionary in _get_parameter_groups():
		for param: Dictionary in group.get("params", []):
			var pid: String = param.get("id", "") as String
			var def_val: float = param.get("default", (param.get("min", 0.0) as float + param.get("max", 1.0) as float) * 0.5) as float
			_params[pid] = def_val
			if _sliders.has(pid):
				(_sliders[pid] as HSlider).set_value_no_signal(def_val)


func _sync_sliders_to_params() -> void:
	for pid: String in _params:
		if _sliders.has(pid):
			var slider: HSlider = _sliders[pid] as HSlider
			slider.set_value_no_signal(_params[pid])
			var val_label: Label = slider.get_parent().get_node_or_null("Val") as Label
			if val_label:
				val_label.text = "%.2f" % _params[pid]
		elif _dropdowns.has(pid):
			var dropdown: OptionButton = _dropdowns[pid] as OptionButton
			dropdown.select(clampi(int(_params[pid]), 0, dropdown.item_count - 1))


## Get a parameter value with a default fallback.
func p(param_id: String, default: float = 0.0) -> float:
	return _params.get(param_id, default) as float


## Clear all geometry from content_root.
func _clear_content() -> void:
	for child: Node in content_root.get_children():
		child.queue_free()


# ═══════════════════════════════════════════════════════════════
# ORBIT CAMERA
# ═══════════════════════════════════════════════════════════════

func _on_viewport_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			orbiting = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			orbit_dist = maxf(0.5, orbit_dist - 0.3)
			_update_cam()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			orbit_dist = minf(20.0, orbit_dist + 0.3)
			_update_cam()
	elif ev is InputEventMouseMotion and orbiting:
		var mm: InputEventMouseMotion = ev as InputEventMouseMotion
		orbit_yaw -= mm.relative.x * 0.005
		orbit_pitch = clampf(orbit_pitch + mm.relative.y * 0.005, 0.1, 1.4)
		_update_cam()


func _update_cam() -> void:
	if not cam:
		return
	var o := Vector3(
		sin(orbit_yaw) * cos(orbit_pitch),
		sin(orbit_pitch),
		cos(orbit_yaw) * cos(orbit_pitch)
	) * orbit_dist
	cam.position = o + Vector3(0, 0.3, 0)
	cam.look_at(Vector3(0, 0.3, 0), Vector3.UP)


# ═══════════════════════════════════════════════════════════════
# PRESETS
# ═══════════════════════════════════════════════════════════════

func _get_presets_path() -> String:
	return "user://editor_presets/%s.json" % _get_editor_name().to_snake_case()


func _save_preset() -> void:
	var pname: String = _preset_name_edit.text.strip_edges()
	if pname.is_empty():
		pname = "Preset_%d" % _presets.size()
	_presets.append({"name": pname, "params": _params.duplicate()})
	_save_presets_to_disk()
	_refresh_preset_list()
	_preset_name_edit.text = ""


func _delete_preset() -> void:
	var sel: PackedInt32Array = _preset_list.get_selected_items()
	if sel.is_empty():
		return
	var idx: int = sel[0]
	if idx >= 0 and idx < _presets.size():
		_presets.remove_at(idx)
		_save_presets_to_disk()
		_refresh_preset_list()


func _on_preset_selected(idx: int) -> void:
	if idx < 0 or idx >= _presets.size():
		return
	var data: Dictionary = _presets[idx].get("params", {}) as Dictionary
	for key: String in data:
		_params[key] = data[key] as float
	_sync_sliders_to_params()
	_needs_rebuild = true
	_rebuild_timer = 0.0


func _refresh_preset_list() -> void:
	if not _preset_list:
		return
	_preset_list.clear()
	for i: int in _presets.size():
		_preset_list.add_item(_presets[i].get("name", "???") as String)


func _save_presets_to_disk() -> void:
	var dir_path: String = "user://editor_presets"
	DirAccess.make_dir_recursive_absolute(dir_path)
	var file := FileAccess.open(_get_presets_path(), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_presets, "  "))
		file.close()


func _load_presets() -> void:
	var path: String = _get_presets_path()
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Array:
		_presets.clear()
		for item: Variant in parsed:
			if item is Dictionary:
				_presets.append(item as Dictionary)
	_refresh_preset_list()
