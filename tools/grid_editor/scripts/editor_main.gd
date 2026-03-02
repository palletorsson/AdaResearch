extends Control
## Grid editor — simple XY plane. Camera looks from +Z.
## Grid X = right, Grid Y = up. No orientation abstraction.
## Glass generators build in YZ, get rotated 90° around Y to become XY.

@onready var subset_selector: OptionButton = %SubsetSelector
@onready var preset_selector: OptionButton = %PresetSelector
@onready var apply_preset_button: Button = %ApplyPresetButton
@onready var element_list: ItemList = %ElementList
@onready var status_label: Label = %StatusLabel
@onready var zoom_label: Label = %ZoomLabel
@onready var subset_loader: GridEditorSubsetLoader = %SubsetLoader
@onready var preview_root: Node3D = %PreviewRoot
@onready var preview_camera: Camera3D = %Camera3D
@onready var viewport_container: SubViewportContainer = $VBoxContainer/HSplitContainer/ViewportContainer
@onready var viewport: SubViewport = $VBoxContainer/HSplitContainer/ViewportContainer/SubViewport

var camera_pivot: Node3D
var camera_distance: float = 3.0
var camera_pan_offset: Vector3 = Vector3.ZERO
var is_orbiting := false
var is_panning := false

var grid_mesh: MeshInstance3D
var hover_mesh: MeshInstance3D
var selection_mesh: MeshInstance3D
var grid_dimensions := Vector2i(16, 12)

var placements: Array = []
var placement_nodes: Dictionary = {}
var selected_index: int = -1

var dragging_element: Dictionary = {}
var drag_rotation: int = 0
var is_moving := false
var move_source_index: int = -1

var undo_stack: Array = []
var redo_stack: Array = []

var current_layout_path := ""
var is_dirty := false
var save_dialog: FileDialog
var open_dialog: FileDialog

func _get_grid_size() -> float:
	return subset_loader.get_grid_size() if subset_loader else 0.1


# ── Coordinates: grid (gx,gy) → world XY plane at Z=0 ──

func _cell_to_world(gx: int, gy: int) -> Vector3:
	var gs = _get_grid_size()
	return Vector3(gx * gs, gy * gs, 0)

func _cell_to_world_f(gx: float, gy: float) -> Vector3:
	var gs = _get_grid_size()
	return Vector3(gx * gs, gy * gs, 0)

func _world_to_cell(w: Vector3) -> Vector2i:
	var gs = _get_grid_size()
	if gs <= 0: return Vector2i(-1, -1)
	return Vector2i(int(floor(w.x / gs)), int(floor(w.y / gs)))

func _screen_to_world(sp: Vector2):
	var from = preview_camera.project_ray_origin(sp)
	var dir = preview_camera.project_ray_normal(sp)
	return Plane(Vector3.FORWARD, 0).intersects_ray(from, dir)  # Z=0 plane

func _screen_to_cell(sp: Vector2) -> Vector2i:
	var hit = _screen_to_world(sp)
	return _world_to_cell(hit) if hit != null else Vector2i(-1, -1)

func _is_valid(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < grid_dimensions.x and c.y < grid_dimensions.y

func _safe_pos(p: Dictionary) -> Array:
	var pos = p.get("position", [0, 0])
	return pos if pos is Array and pos.size() >= 2 else [0, 0]

func _safe_size(e: Dictionary) -> Array:
	var sz = e.get("size", [1, 1])
	return sz if sz is Array and sz.size() >= 2 else [1, 1]


# ── Ready ──

func _ready() -> void:
	subset_loader.subsets_loaded.connect(_on_subsets_loaded)
	subset_selector.item_selected.connect(_on_subset_selected)
	apply_preset_button.pressed.connect(_on_apply_preset_pressed)
	element_list.item_selected.connect(_on_element_selected)
	preset_selector.clear(); preset_selector.disabled = true; apply_preset_button.disabled = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP
	viewport_container.gui_input.connect(_on_viewport_input)
	_setup_menus(); _setup_camera(); _setup_visuals(); _setup_file_dialogs()


# ── Menus ──

func _setup_menus() -> void:
	($VBoxContainer/MenuBar/File as PopupMenu).id_pressed.connect(_on_file_menu)
	($VBoxContainer/MenuBar/Edit as PopupMenu).id_pressed.connect(_on_edit_menu)

func _on_file_menu(id: int) -> void:
	match id:
		0: _do_new()
		1: _do_open()
		2: _do_save()
		4: get_tree().quit()

func _on_edit_menu(id: int) -> void:
	match id:
		0: undo()
		1: redo()
		2: _delete_selected()


# ── File Dialogs ──

func _setup_file_dialogs() -> void:
	save_dialog = FileDialog.new()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.add_filter("*.json", "Layout JSON")
	save_dialog.size = Vector2i(700, 500)
	save_dialog.file_selected.connect(func(p): save_layout(p))
	add_child(save_dialog)
	open_dialog = FileDialog.new()
	open_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	open_dialog.access = FileDialog.ACCESS_FILESYSTEM
	open_dialog.add_filter("*.json", "Layout JSON")
	open_dialog.size = Vector2i(700, 500)
	open_dialog.file_selected.connect(func(p): load_layout(p))
	add_child(open_dialog)

func _do_new() -> void:
	_push_undo(); placements.clear(); selected_index = -1
	current_layout_path = ""; is_dirty = false; _rebuild_all()
	status_label.text = "New layout"

func _do_open() -> void:
	open_dialog.popup_centered()

func _do_save() -> void:
	if current_layout_path.is_empty():
		save_dialog.popup_centered()
	else:
		save_layout(current_layout_path)


# ── Undo / Redo ──

func _snapshot() -> Dictionary:
	var sp: Array = []
	for p in placements: sp.append(p.duplicate(true))
	return {"placements": sp, "selected": selected_index, "grid": [grid_dimensions.x, grid_dimensions.y]}

func _restore(s: Dictionary) -> void:
	placements = s.get("placements", [])
	selected_index = s.get("selected", -1)
	var g = s.get("grid", [16, 12]); grid_dimensions = Vector2i(g[0], g[1])
	_rebuild_all()

func _push_undo() -> void:
	undo_stack.append(_snapshot())
	if undo_stack.size() > 50: undo_stack.pop_front()
	redo_stack.clear()

func undo() -> void:
	if undo_stack.is_empty(): status_label.text = "Nothing to undo"; return
	redo_stack.append(_snapshot()); _restore(undo_stack.pop_back()); is_dirty = true
	status_label.text = "Undo (%d left)" % undo_stack.size()

func redo() -> void:
	if redo_stack.is_empty(): status_label.text = "Nothing to redo"; return
	undo_stack.append(_snapshot()); _restore(redo_stack.pop_back()); is_dirty = true
	status_label.text = "Redo"


# ── Camera ──

func _setup_camera() -> void:
	camera_pivot = Node3D.new(); camera_pivot.name = "CameraPivot"
	viewport.add_child(camera_pivot)
	preview_camera.get_parent().remove_child(preview_camera)
	camera_pivot.add_child(preview_camera)
	_fit_camera()

func _fit_camera() -> void:
	var gs = _get_grid_size()
	var extent = max(grid_dimensions.x, grid_dimensions.y) * gs
	camera_distance = extent * 1.2 + 0.5
	_update_camera()

func _update_camera() -> void:
	if not camera_pivot: return
	var center = _cell_to_world(grid_dimensions.x / 2, grid_dimensions.y / 2) + camera_pan_offset
	camera_pivot.position = center
	# Camera sits on +Z looking toward -Z (straight at XY plane)
	preview_camera.position = Vector3(0, 0, camera_distance)
	preview_camera.look_at(camera_pivot.global_position)
	zoom_label.text = "Zoom: %d%%" % int(3.0 / camera_distance * 100)


# ── Grid + Hover + Selection visuals ──

func _setup_visuals() -> void:
	# Grid lines
	grid_mesh = MeshInstance3D.new(); grid_mesh.name = "Grid"
	var gm = StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.vertex_color_use_as_albedo = true
	grid_mesh.material_override = gm; grid_mesh.mesh = ImmediateMesh.new()
	viewport.add_child(grid_mesh)
	# Hover
	hover_mesh = MeshInstance3D.new(); hover_mesh.mesh = BoxMesh.new()
	var hm = StandardMaterial3D.new()
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.albedo_color = Color(0.3, 0.6, 1.0, 0.4)
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hover_mesh.material_override = hm; hover_mesh.visible = false
	viewport.add_child(hover_mesh)
	# Selection
	selection_mesh = MeshInstance3D.new(); selection_mesh.mesh = BoxMesh.new()
	var sm = StandardMaterial3D.new()
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_color = Color(1.0, 0.85, 0.2, 0.35)
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selection_mesh.material_override = sm; selection_mesh.visible = false
	viewport.add_child(selection_mesh)

func _rebuild_grid() -> void:
	var im = grid_mesh.mesh as ImmediateMesh; im.clear_surfaces()
	var gs = _get_grid_size()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	var c1 = Color(0.3, 0.35, 0.4, 0.6); var c2 = Color(0.4, 0.45, 0.5, 0.8)
	for y in range(grid_dimensions.y + 1):
		var c = c2 if y % 4 == 0 else c1
		im.surface_set_color(c); im.surface_add_vertex(_cell_to_world(0, y))
		im.surface_set_color(c); im.surface_add_vertex(_cell_to_world(grid_dimensions.x, y))
	for x in range(grid_dimensions.x + 1):
		var c = c2 if x % 4 == 0 else c1
		im.surface_set_color(c); im.surface_add_vertex(_cell_to_world(x, 0))
		im.surface_set_color(c); im.surface_add_vertex(_cell_to_world(x, grid_dimensions.y))
	im.surface_end()

func _show_box(mesh: MeshInstance3D, cell: Vector2i, w: float, h: float) -> void:
	var box = mesh.mesh as BoxMesh
	box.size = Vector3(w, h, 0.002)
	mesh.position = _cell_to_world(cell.x, cell.y) + Vector3(w / 2.0, h / 2.0, 0.001)

func _show_box_f(mesh: MeshInstance3D, pos: Array, w: float, h: float) -> void:
	var box = mesh.mesh as BoxMesh
	box.size = Vector3(w, h, 0.002)
	mesh.position = _cell_to_world_f(float(pos[0]), float(pos[1])) + Vector3(w / 2.0, h / 2.0, 0.001)

func _update_hover(cell: Vector2i, sz: Array = [1, 1]) -> void:
	if not _is_valid(cell): hover_mesh.visible = false; return
	hover_mesh.visible = true
	var gs = _get_grid_size()
	_show_box(hover_mesh, cell, sz[0] * gs, sz[1] * gs)
	var ok = _can_place_at(cell, sz)
	(hover_mesh.material_override as StandardMaterial3D).albedo_color = \
		Color(0.3, 0.8, 0.4, 0.4) if ok else Color(0.9, 0.2, 0.2, 0.4)

func _update_selection() -> void:
	if selected_index < 0 or selected_index >= placements.size():
		selection_mesh.visible = false; return
	selection_mesh.visible = true
	var p = placements[selected_index]; var pos = _safe_pos(p)
	var elem = subset_loader.get_element(str(p.get("element", "")))
	var sz = _rotated_size(elem, p.get("rotation", 0)); var gs = _get_grid_size()
	_show_box_f(selection_mesh, pos, sz[0] * gs, sz[1] * gs)


# ── Input ──

func _on_viewport_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_RIGHT: is_orbiting = mb.pressed; is_panning = false
			MOUSE_BUTTON_MIDDLE: is_panning = mb.pressed; is_orbiting = false
			MOUSE_BUTTON_WHEEL_UP: camera_distance = max(0.3, camera_distance * 0.9); _update_camera()
			MOUSE_BUTTON_WHEEL_DOWN: camera_distance = min(50.0, camera_distance * 1.1); _update_camera()
			MOUSE_BUTTON_LEFT:
				if mb.pressed: _on_click(mb.position)
	elif event is InputEventMouseMotion:
		var mm = event as InputEventMouseMotion
		if is_panning:
			var spd = camera_distance * 0.002
			camera_pan_offset.x -= mm.relative.x * spd
			camera_pan_offset.y += mm.relative.y * spd
			_update_camera()
		elif is_orbiting:
			pass  # Could add slight tilt, but keeping it 2D-like for now
		else:
			_on_mouse_move(mm.position)

func _input(event: InputEvent) -> void:
	if not viewport_container or not viewport_container.get_global_rect().has_point(get_global_mouse_position()):
		return
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed:
			match event.keycode:
				KEY_Z: redo() if event.shift_pressed else undo()
				KEY_Y: redo()
				KEY_S: _do_save()
		else:
			match event.keycode:
				KEY_R: _rotate_current()
				KEY_DELETE, KEY_BACKSPACE: _delete_selected()
				KEY_ESCAPE: _cancel()
				KEY_F: camera_pan_offset = Vector3.ZERO; _fit_camera()

func _on_mouse_move(sp: Vector2) -> void:
	var cell = _screen_to_cell(sp)
	if is_moving and move_source_index >= 0 and move_source_index < placements.size():
		var elem = subset_loader.get_element(str(placements[move_source_index].get("element", "")))
		_update_hover(cell, _rotated_size(elem, placements[move_source_index].get("rotation", 0)))
		status_label.text = "Move to %d,%d (click=confirm, Esc=cancel)" % [cell.x, cell.y]
	elif not dragging_element.is_empty():
		_update_hover(cell, _rotated_size(dragging_element, drag_rotation))
		status_label.text = "Place: %s at %d,%d (R=rotate, Esc=cancel)" % [dragging_element.get("name", "?"), cell.x, cell.y]
	elif _is_valid(cell):
		_update_hover(cell)
		var occ = _occupied(cell)
		if occ >= 0 and occ < placements.size():
			var elem = subset_loader.get_element(str(placements[occ].get("element", "")))
			status_label.text = "%s at %d,%d (click=select)" % [elem.get("name", "?"), cell.x, cell.y]
		else:
			status_label.text = "Cell: %d, %d" % [cell.x, cell.y]
	else:
		hover_mesh.visible = false; status_label.text = ""

func _on_click(sp: Vector2) -> void:
	var cell = _screen_to_cell(sp)
	if not _is_valid(cell): return
	if is_moving: _confirm_move(cell); return
	if not dragging_element.is_empty():
		var sz = _rotated_size(dragging_element, drag_rotation)
		if _can_place_at(cell, sz):
			_push_undo(); _place(dragging_element, cell, drag_rotation)
			dragging_element = {}; drag_rotation = 0; hover_mesh.visible = false; element_list.deselect_all()
		return
	var idx = _occupied(cell)
	if idx >= 0:
		if idx == selected_index: _start_move(idx)
		else: _select(idx)
	else: _deselect()


# ── Actions ──

func _rotate_current() -> void:
	if not dragging_element.is_empty():
		drag_rotation = (drag_rotation + 90) % 360
	elif selected_index >= 0:
		_push_undo(); placements[selected_index]["rotation"] = (placements[selected_index].get("rotation", 0) + 90) % 360
		_rebuild_all(); is_dirty = true; status_label.text = "Rotated"

func _delete_selected() -> void:
	if selected_index >= 0 and selected_index < placements.size():
		_push_undo(); placements.remove_at(selected_index); selected_index = -1
		_rebuild_all(); is_dirty = true; status_label.text = "Deleted"

func _cancel() -> void:
	if is_moving:
		is_moving = false; move_source_index = -1; _rebuild_all(); status_label.text = "Cancelled"
	elif not dragging_element.is_empty():
		dragging_element = {}; drag_rotation = 0; hover_mesh.visible = false; element_list.deselect_all()
	else: _deselect()

func _start_move(idx: int) -> void:
	is_moving = true; move_source_index = idx
	if placement_nodes.has(idx) and placement_nodes[idx]: placement_nodes[idx].visible = false
	status_label.text = "Click destination (Esc=cancel)"

func _confirm_move(cell: Vector2i) -> void:
	if move_source_index < 0 or move_source_index >= placements.size():
		is_moving = false; return
	var elem = subset_loader.get_element(str(placements[move_source_index].get("element", "")))
	var sz = _rotated_size(elem, placements[move_source_index].get("rotation", 0))
	var old = placements[move_source_index]["position"]
	placements[move_source_index]["position"] = [-999, -999]
	var ok = _can_place_at(cell, sz)
	placements[move_source_index]["position"] = old
	if ok:
		_push_undo(); placements[move_source_index]["position"] = [cell.x, cell.y]
		is_moving = false; move_source_index = -1; _rebuild_all(); is_dirty = true
		status_label.text = "Moved to %d,%d" % [cell.x, cell.y]
	else: status_label.text = "Can't place there"


# ── Placement logic ──

func _rotated_size(elem: Dictionary, rot: int) -> Array:
	var sz = _safe_size(elem); var w = int(sz[0]); var h = int(sz[1])
	return [h, w] if (rot % 180) == 90 else [w, h]

func _can_place_at(cell: Vector2i, sz: Array) -> bool:
	if sz.size() < 2: return false
	for dx in range(int(sz[0])):
		for dy in range(int(sz[1])):
			var c = Vector2i(cell.x + dx, cell.y + dy)
			if not _is_valid(c) or _occupied(c) >= 0: return false
	return true

func _occupied(cell: Vector2i) -> int:
	# Check if integer cell overlaps any element's bounding box (supports float positions)
	for i in range(placements.size()):
		var pos = _safe_pos(placements[i])
		if float(pos[0]) < 0: continue
		var elem = subset_loader.get_element(str(placements[i].get("element", "")))
		var sz = _rotated_size(elem, placements[i].get("rotation", 0))
		var px := float(pos[0]); var py := float(pos[1])
		var sw := float(sz[0]); var sh := float(sz[1])
		if float(cell.x) + 1.0 > px and float(cell.x) < px + sw and float(cell.y) + 1.0 > py and float(cell.y) < py + sh:
			return i
	return -1

func _place(elem: Dictionary, cell: Vector2i, rot: int) -> void:
	placements.append({"element": elem.get("id", ""), "position": [cell.x, cell.y], "rotation": rot})
	_instantiate(placements.size() - 1); is_dirty = true
	status_label.text = "Placed: %s at %d,%d" % [elem.get("name", "?"), cell.x, cell.y]

func _select(idx: int) -> void:
	selected_index = idx; _update_selection()
	var elem = subset_loader.get_element(str(placements[idx].get("element", "")))
	status_label.text = "Selected: %s (click=move, R=rotate, Del=delete)" % elem.get("name", "?")

func _deselect() -> void:
	selected_index = -1; _update_selection()


# ── Build 3D ──

func _rebuild_all() -> void:
	for c in preview_root.get_children(): c.queue_free()
	placement_nodes.clear()
	for i in range(placements.size()): _instantiate(i)
	_rebuild_grid(); _update_selection()

func _instantiate(index: int) -> void:
	if index < 0 or index >= placements.size(): return
	var p = placements[index]
	var element = subset_loader.get_element(str(p.get("element", "")))
	if element.is_empty(): return
	var gs = _get_grid_size(); var pos = _safe_pos(p); var rot = int(p.get("rotation", 0))

	var node = _create_element_3d(element, gs)
	if not node: return

	node.position = _cell_to_world_f(float(pos[0]), float(pos[1]))
	if rot != 0: node.rotate_z(deg_to_rad(rot))  # XY plane: rotate around Z

	# Debug label
	var lbl = Label3D.new()
	lbl.text = str(element.get("icon", "")) + " " + str(p.get("element", ""))
	lbl.font_size = 32; lbl.pixel_size = 0.001; lbl.modulate = Color.YELLOW
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lbl.no_depth_test = true
	var sz = _safe_size(element)
	lbl.position = Vector3(sz[0] * gs * 0.5, sz[1] * gs + 0.02, 0)
	node.add_child(lbl)

	# Port dots
	var ports = element.get("ports", [])
	for port in ports:
		if not port is Dictionary: continue
		var cell = port.get("cell", [0, 0])
		if not cell is Array or cell.size() < 2: continue
		# Port coords are in cell-units (grid X, grid Y). Parent node is rotated PI/2 around Y
		# so we place in YZ plane: X=offset for visibility, Y=cell_y, Z=cell_x
		var port_world = Vector3(-0.005, float(cell[1]) * gs, float(cell[0]) * gs)
		var dot = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = gs * 0.12; sphere.height = gs * 0.24
		dot.mesh = sphere
		var dot_mat = StandardMaterial3D.new()
		dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var aligned = _is_port_aligned(index, port, gs)
		dot_mat.albedo_color = Color(0.2, 0.9, 0.3, 0.8) if aligned else Color(0.9, 0.3, 0.2, 0.6)
		dot.material_override = dot_mat
		dot.position = port_world
		node.add_child(dot)

	preview_root.add_child(node)
	placement_nodes[index] = node


func _is_port_aligned(placement_index: int, port: Dictionary, gs: float) -> bool:
	"""Check if a port has a matching port on a nearby element within tolerance."""
	var p = placements[placement_index]
	var pos = _safe_pos(p)
	var cell = port.get("cell", [0, 0])
	var world_x = float(pos[0]) * gs + float(cell[0]) * gs
	var world_y = float(pos[1]) * gs + float(cell[1]) * gs
	var tolerance = gs * 0.6  # Allow slightly more than half-cell tolerance

	for i in range(placements.size()):
		if i == placement_index: continue
		var other_p = placements[i]
		var other_pos = _safe_pos(other_p)
		var other_elem = subset_loader.get_element(str(other_p.get("element", "")))
		var other_ports = other_elem.get("ports", [])
		for op in other_ports:
			if not op is Dictionary: continue
			var oc = op.get("cell", [0, 0])
			if not oc is Array or oc.size() < 2: continue
			var ox = float(other_pos[0]) * gs + float(oc[0]) * gs
			var oy = float(other_pos[1]) * gs + float(oc[1]) * gs
			var dist = sqrt((world_x - ox) ** 2 + (world_y - oy) ** 2)
			if dist < tolerance:
				return true
	return false


func _create_element_3d(element: Dictionary, grid_size: float) -> Node3D:
	var node: Node3D = null
	var segment_type = str(element.get("segment_type", ""))
	if not segment_type.is_empty() and subset_loader.current_subset_id == "glass_rack":
		node = _create_glass_segment(element, grid_size)
		if node:
			# Glass generators build in YZ plane. Rotate 90° around Y to convert to XY.
			# (0,y,z) → (z,y,0): Z becomes X, Y stays Y
			node.rotation.y = PI / 2.0
	if not node:
		var scene_path = str(element.get("scene", ""))
		if not scene_path.is_empty() and scene_path != "null" and ResourceLoader.exists(scene_path):
			var scene = load(scene_path)
			if scene:
				node = scene.instantiate(); node.name = element.get("id", "element")
	if not node:
		node = _create_placeholder_3d(element, grid_size)
	return node


# ── Subset / Preset / Element list ──

func _on_subsets_loaded() -> void:
	subset_selector.clear()
	var names = subset_loader.get_subset_names()
	for id in names:
		subset_selector.add_item(names[id])
		subset_selector.set_item_metadata(subset_selector.item_count - 1, id)
	if subset_selector.item_count > 0:
		subset_selector.select(0); _on_subset_selected(0)

func _on_subset_selected(index: int) -> void:
	subset_loader.set_current_subset(subset_selector.get_item_metadata(index))
	_populate_elements(); _populate_presets(); _rebuild_grid()
	camera_pan_offset = Vector3.ZERO; _fit_camera()
	status_label.text = "Subset: " + subset_loader.current_subset.get("name", "?")

func _populate_elements() -> void:
	element_list.clear()
	for cat in subset_loader.get_categories():
		var ci = element_list.add_item("── " + cat.get("name", "?") + " ──")
		element_list.set_item_disabled(ci, true); element_list.set_item_selectable(ci, false)
		for e in subset_loader.current_subset.get("elements", []):
			if e.get("category") == cat.get("id"):
				var sz = _safe_size(e)
				var idx = element_list.add_item("%s %s (%dx%d)" % [e.get("icon", "?"), e.get("name", e.get("id", "?")), sz[0], sz[1]])
				element_list.set_item_metadata(idx, e)

func _populate_presets() -> void:
	preset_selector.clear()
	var presets = subset_loader.get_presets()
	if presets.is_empty():
		preset_selector.add_item("No presets"); preset_selector.disabled = true; apply_preset_button.disabled = true; return
	preset_selector.disabled = false; apply_preset_button.disabled = false
	for pr in presets:
		preset_selector.add_item(pr.get("name", "Preset"))
		preset_selector.set_item_metadata(preset_selector.item_count - 1, pr)
	preset_selector.select(0)

func _on_apply_preset_pressed() -> void:
	if preset_selector.disabled: return
	var pr = preset_selector.get_item_metadata(preset_selector.selected)
	if pr is Dictionary: _apply_preset(pr)

func _apply_preset(preset: Dictionary) -> void:
	_push_undo(); placements.clear(); selected_index = -1
	var pg = preset.get("grid_size", [16, 12])
	if pg is Array and pg.size() >= 2: grid_dimensions = Vector2i(max(1, int(pg[0])), max(1, int(pg[1])))
	for entry in preset.get("placements", []):
		if not entry is Dictionary: continue
		var eid = str(entry.get("element", ""))
		if eid.is_empty() or subset_loader.get_element(eid).is_empty(): continue
		var pos = entry.get("position", [0, 0])
		if not pos is Array or pos.size() < 2: continue
		var rot = int(round(float(entry.get("rotation", 0)) / 90.0) * 90.0) % 360
		if rot < 0: rot += 360
		placements.append({"element": eid, "position": [float(pos[0]), float(pos[1])], "rotation": rot})
	_rebuild_all(); camera_pan_offset = Vector3.ZERO; _fit_camera(); is_dirty = true
	status_label.text = "Preset: %s (%d items)" % [preset.get("name", "?"), placements.size()]

func _on_element_selected(index: int) -> void:
	var e = element_list.get_item_metadata(index)
	if e is Dictionary and not e.is_empty():
		dragging_element = e; drag_rotation = 0
		status_label.text = "Place: %s (click grid, R=rotate, Esc=cancel)" % e.get("name", "?")


# ── File I/O ──

func save_layout(path: String = "") -> void:
	if path.is_empty(): path = current_layout_path
	if path.is_empty(): _do_save(); return
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"version": "1.0", "subset": subset_loader.current_subset_id,
			"name": path.get_file().get_basename(), "grid_size": [grid_dimensions.x, grid_dimensions.y],
			"placements": placements}, "  "))
		f.close(); current_layout_path = path; is_dirty = false
		status_label.text = "Saved: " + path.get_file()

func load_layout(path: String) -> void:
	var f = FileAccess.open(path, FileAccess.READ)
	if not f: status_label.text = "File not found"; return
	var json = JSON.new()
	if json.parse(f.get_as_text()) != OK: status_label.text = "Parse error"; return
	f.close(); _push_undo()
	var d = json.data; var sid = d.get("subset", "")
	if subset_loader.subsets.has(sid):
		subset_loader.set_current_subset(sid)
		for i in range(subset_selector.item_count):
			if subset_selector.get_item_metadata(i) == sid: subset_selector.select(i); break
		_populate_elements(); _populate_presets()
	var g = d.get("grid_size", [16, 12]); grid_dimensions = Vector2i(g[0], g[1])
	placements = d.get("placements", [])
	_rebuild_all(); camera_pan_offset = Vector3.ZERO; _fit_camera()
	current_layout_path = path; is_dirty = false
	status_label.text = "Loaded: " + path.get_file()


# ============================================================
# GLASS ELEMENT GENERATORS
# ============================================================
# These build geometry in YZ plane (Y=up, Z=horizontal).
# _create_element_3d rotates the result 90° around Y to convert to XY.
# Direction mapping (in YZ before rotation):
#   0: bottom→+Z   →  after 90°Y rotation: bottom→+X = bottom→right = ╭
#   90: bottom→-Z  →  bottom→-X = bottom→left = ╮
#   180: top→-Z    →  top→-X = top→left = ╯
#   270: top→+Z    →  top→+X = top→right = ╰

func _create_glass_segment(element: Dictionary, grid_size: float) -> Node3D:
	var segment_type = element.get("segment_type", "")
	var elem_size = element.get("size", [1, 1])
	var tube_radius = subset_loader.current_subset.get("defaults", {}).get("tube_radius", 0.015)
	var width = elem_size[0] * grid_size
	var height = elem_size[1] * grid_size

	var glass_mat = StandardMaterial3D.new()
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.albedo_color = Color(0.85, 0.92, 1.0, 0.4)
	glass_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var bend_mat = glass_mat

	var node: Node3D = null

	match segment_type:
		"straight":
			# Vertical tube: fits exactly in cell, centered at width/2
			node = Node3D.new()
			var mi = MeshInstance3D.new()
			mi.mesh = _generate_tube_mesh(height, tube_radius, 16, 2, width / 2.0, 0.0)
			mi.material_override = glass_mat
			node.add_child(mi)
		"straight_h":
			# Horizontal tube: fits exactly in cell, centered at height/2
			node = Node3D.new()
			var mi_h = MeshInstance3D.new()
			mi_h.mesh = _generate_tube_mesh_horizontal(width, tube_radius, 16, 2, height / 2.0, 0.0)
			mi_h.material_override = glass_mat
			node.add_child(mi_h)
		"corner", "corner_bl":
			node = _create_glass_elbow_directed(width, height, tube_radius, bend_mat, 180)
		"corner_br":
			node = _create_glass_elbow_directed(width, height, tube_radius, bend_mat, 270)
		"corner_tr":
			node = _create_glass_elbow_directed(width, height, tube_radius, bend_mat, 0)
		"corner_tl":
			node = _create_glass_elbow_directed(width, height, tube_radius, bend_mat, 90)
		"corner45":
			node = _create_glass_corner45_smooth(width, height, tube_radius, bend_mat)
		"wobbly":
			node = _create_glass_wobbly_smooth(width, height, tube_radius, glass_mat, -grid_size * 0.5)
		"reducer":
			node = _create_glass_reducer_smooth(width, height, tube_radius, glass_mat)
		"sbend":
			node = _create_glass_sbend_smooth(width, height, tube_radius, bend_mat)
		"ubend":
			node = _create_glass_ubend_smooth(width, height, tube_radius, glass_mat, -grid_size * 0.5)
		"ypipe":
			node = _create_glass_ypipe_smooth(width, height, tube_radius, glass_mat)
		"junction":
			node = _create_glass_tee_smooth(width, height, tube_radius, glass_mat)
		"cross":
			node = _create_glass_cross_smooth(width, height, tube_radius, glass_mat)
		"spiral":
			node = _create_glass_spiral_smooth(width, height, tube_radius, glass_mat)
		"condenser":
			node = _create_glass_condenser_smooth(width, height, tube_radius, glass_mat)
		"flask":
			node = _create_glass_flask_smooth(width, height, tube_radius, glass_mat)
		"beaker":
			node = _create_glass_beaker_smooth(width, height, glass_mat)
		"cap":
			node = _create_glass_cap_smooth(width, height, tube_radius, glass_mat)
		"drip":
			node = _create_glass_drip_smooth(width, height, tube_radius, glass_mat)
		_:
			node = _create_glass_tube_smooth(height, tube_radius, glass_mat)
			node.position.x = width / 2

	if node: node.name = element.get("id", "segment")
	return node

func _create_glass_tube_smooth(length: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var mi = MeshInstance3D.new()
	mi.mesh = _generate_tube_mesh(length, radius, 16, 2)
	mi.material_override = mat
	node.add_child(mi)
	return node

func _generate_tube_mesh(length: float, radius: float, segments: int, rings: int, center_z: float = 0.0, y_offset: float = 0.0) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(rings + 1):
		var y = y_offset + (float(r) / rings) * length
		for s in range(segments + 1):
			var angle = (float(s) / segments) * TAU
			st.set_normal(Vector3(cos(angle), 0, sin(angle)))
			st.set_uv(Vector2(float(s) / segments, float(r) / rings))
			st.add_vertex(Vector3(cos(angle) * radius, y, center_z + sin(angle) * radius))
	for r in range(rings):
		for s in range(segments):
			var curr = r * (segments + 1) + s
			var next = curr + segments + 1
			st.add_index(curr); st.add_index(next); st.add_index(curr + 1)
			st.add_index(curr + 1); st.add_index(next); st.add_index(next + 1)
	st.generate_tangents()
	return st.commit()

func _generate_tube_mesh_horizontal(length: float, radius: float, segments: int, rings: int, center_y: float = 0.0, z_offset: float = 0.0) -> ArrayMesh:
	# Tube along Z axis (horizontal in YZ plane)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(rings + 1):
		var z = z_offset + (float(r) / rings) * length
		for s in range(segments + 1):
			var angle = (float(s) / segments) * TAU
			st.set_normal(Vector3(cos(angle), sin(angle), 0))
			st.set_uv(Vector2(float(s) / segments, float(r) / rings))
			st.add_vertex(Vector3(cos(angle) * radius, center_y + sin(angle) * radius, z))
	for r in range(rings):
		for s in range(segments):
			var curr = r * (segments + 1) + s
			var next = curr + segments + 1
			st.add_index(curr); st.add_index(next); st.add_index(curr + 1)
			st.add_index(curr + 1); st.add_index(next); st.add_index(next + 1)
	st.generate_tangents()
	return st.commit()

func _generate_tube_mesh_along_x(length: float, radius: float, segments: int, rings: int, center_y: float = 0.0, x_offset: float = 0.0) -> ArrayMesh:
	# Tube along X axis directly (no rotation needed for horizontal)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(rings + 1):
		var x = x_offset + (float(r) / rings) * length
		for s in range(segments + 1):
			var angle = (float(s) / segments) * TAU
			st.set_normal(Vector3(0, cos(angle), sin(angle)))
			st.set_uv(Vector2(float(s) / segments, float(r) / rings))
			st.add_vertex(Vector3(x, center_y + cos(angle) * radius, sin(angle) * radius))
	for r in range(rings):
		for s in range(segments):
			var curr = r * (segments + 1) + s
			var next = curr + segments + 1
			st.add_index(curr); st.add_index(next); st.add_index(curr + 1)
			st.add_index(curr + 1); st.add_index(next); st.add_index(next + 1)
	st.generate_tangents()
	return st.commit()

func _create_glass_elbow_directed(width: float, height: float, radius: float, mat: Material, direction: int) -> Node3D:
	var node = Node3D.new()
	var mi = MeshInstance3D.new()
	var arc_r = min(width, height) / 2.0
	# Center at the cell corner where the two port directions intersect (outward-curving arcs)
	var cy: float; var cz: float
	match direction:
		0:   cy = 0.0;    cz = width   # corner_tr: bottom-right corner in YZ
		90:  cy = 0.0;    cz = 0.0     # corner_tl: bottom-left corner in YZ
		180: cy = height; cz = 0.0     # corner_bl: top-left corner in YZ
		_:   cy = height; cz = width   # corner_br: top-right corner in YZ
	mi.mesh = _generate_directed_elbow_yz(arc_r, radius, cy, cz, direction, 16, 16)
	mi.material_override = mat
	node.add_child(mi)
	return node

func _generate_directed_elbow_yz(arc_radius: float, tube_radius: float, center_y: float, center_z: float, direction: int, tube_segs: int, bend_segs: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var start_angle: float; var end_angle: float
	match direction:
		0:   start_angle = PI;  end_angle = PI / 2.0           # corner_tr: bottom→right
		90:  start_angle = 0.0; end_angle = PI / 2.0           # corner_tl: bottom→left
		180: start_angle = 0.0; end_angle = -PI / 2.0          # corner_bl: top→left
		_:   start_angle = PI;  end_angle = 3.0 * PI / 2.0    # corner_br: top→right
	var prev_normal := Vector3.ZERO
	for b in range(bend_segs + 1):
		var t = float(b) / bend_segs
		var angle = lerpf(start_angle, end_angle, t)
		var center = Vector3(0, center_y + arc_radius * sin(angle), center_z + arc_radius * cos(angle))
		var d_angle = end_angle - start_angle
		var tangent = Vector3(0, arc_radius * cos(angle) * d_angle, -arc_radius * sin(angle) * d_angle).normalized()
		var normal: Vector3; var binormal: Vector3
		if prev_normal == Vector3.ZERO:
			normal = tangent.cross(Vector3.RIGHT)
			if normal.length_squared() < 0.001: normal = tangent.cross(Vector3.UP)
			normal = normal.normalized()
		else:
			normal = prev_normal - tangent * tangent.dot(prev_normal)
			if normal.length_squared() < 0.001: normal = prev_normal
			else: normal = normal.normalized()
		binormal = tangent.cross(normal).normalized(); prev_normal = normal
		for s in range(tube_segs + 1):
			var ra = (float(s) / tube_segs) * TAU
			var offset = (normal * cos(ra) + binormal * sin(ra)) * tube_radius
			st.set_normal(offset.normalized()); st.set_uv(Vector2(float(s) / tube_segs, t))
			st.add_vertex(center + offset)
	for b in range(bend_segs):
		for s in range(tube_segs):
			var curr = b * (tube_segs + 1) + s; var next = curr + tube_segs + 1
			st.add_index(curr); st.add_index(next); st.add_index(curr + 1)
			st.add_index(curr + 1); st.add_index(next); st.add_index(next + 1)
	st.generate_tangents()
	return st.commit()

func _create_glass_sbend_smooth(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	mi.mesh = _generate_sbend_mesh_yz(h, w, r, 16, 24); mi.material_override = mat
	node.add_child(mi); return node

func _generate_sbend_mesh_yz(height: float, width: float, tr: float, ts: int, ls: int) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for l in range(ls + 1):
		var t = float(l) / ls; var y = t * height; var z = width * (0.5 - 0.5 * cos(PI * t))
		var dy = height / ls; var dz = width * 0.5 * PI * sin(PI * t) / ls
		var tang = Vector3(0, dy, dz).normalized(); var bn = Vector3(1, 0, 0); var n = bn.cross(tang).normalized()
		for s in range(ts + 1):
			var ra = (float(s) / ts) * TAU; var ro = (n * cos(ra) + bn * sin(ra)) * tr
			st.set_normal(ro.normalized()); st.set_uv(Vector2(float(s) / ts, t)); st.add_vertex(Vector3(0, y, z) + ro)
	for l in range(ls):
		for s in range(ts):
			var c = l * (ts + 1) + s; var nx = c + ts + 1
			st.add_index(c); st.add_index(nx); st.add_index(c + 1)
			st.add_index(c + 1); st.add_index(nx); st.add_index(nx + 1)
	st.generate_tangents(); return st.commit()

func _create_glass_ubend_smooth(w: float, h: float, r: float, mat: Material, y_offset: float = 0.0) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	mi.mesh = _generate_ubend_mesh_yz(w, h, r, 16, 20, y_offset); mi.material_override = mat
	node.add_child(mi); return node

func _generate_ubend_mesh_yz(width: float, height: float, tr: float, ts: int, bs: int, y_offset: float = 0.0) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cz = width / 2.0; var ar = cz - tr; var yt = height; var yb = tr; var ys = yt - yb
	for b in range(bs + 1):
		var t = float(b) / bs; var a = PI * t; var z = cz - ar * cos(a); var y = y_offset + yt - ys * sin(a)
		var tang = Vector3(0, -ys * cos(a), ar * sin(a)).normalized(); var bn = Vector3(1, 0, 0); var n = bn.cross(tang).normalized()
		for s in range(ts + 1):
			var ra = (float(s) / ts) * TAU; var off = (n * cos(ra) + bn * sin(ra)) * tr
			st.set_normal(off.normalized()); st.set_uv(Vector2(float(s) / ts, t)); st.add_vertex(Vector3(0, y, z) + off)
	for b in range(bs):
		for s in range(ts):
			var c = b * (ts + 1) + s; var nx = c + ts + 1
			st.add_index(c); st.add_index(nx); st.add_index(c + 1)
			st.add_index(c + 1); st.add_index(nx); st.add_index(nx + 1)
	st.generate_tangents(); return st.commit()

func _create_glass_tee_smooth(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var cz = w / 2; var cy = h / 2
	var vert = _create_glass_tube_smooth(h, r, mat); vert.position.z = cz; node.add_child(vert)
	var horiz = MeshInstance3D.new(); horiz.mesh = _generate_tube_mesh(w / 2, r, 16, 2)
	horiz.material_override = mat; horiz.rotation.x = PI / 2; horiz.position = Vector3(0, cy, cz); node.add_child(horiz)
	var sp = MeshInstance3D.new(); var sm = SphereMesh.new(); sm.radius = r * 1.5; sm.height = r * 3
	sp.mesh = sm; sp.material_override = mat; sp.position = Vector3(0, cy, cz); node.add_child(sp)
	return node

func _create_glass_ypipe_smooth(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var cz = w / 2; var jy = h * 0.35
	var stem = _create_glass_tube_smooth(jy, r, mat); stem.position.z = cz; node.add_child(stem)
	for side in [-1, 1]:
		var br = MeshInstance3D.new(); br.mesh = _generate_tube_mesh(h * 0.55, r, 16, 2)
		br.material_override = mat; br.position = Vector3(0, jy, cz); br.rotation.x = side * PI / 5; node.add_child(br)
	var sp = MeshInstance3D.new(); var sm = SphereMesh.new(); sm.radius = r * 2; sm.height = r * 4
	sp.mesh = sm; sp.material_override = mat; sp.position = Vector3(0, jy, cz); node.add_child(sp)
	return node

func _create_glass_cross_smooth(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var c = Vector3(0, h / 2, w / 2)
	var vert = _create_glass_tube_smooth(h, r, mat); vert.position.z = c.z; node.add_child(vert)
	var horiz = MeshInstance3D.new(); horiz.mesh = _generate_tube_mesh(w, r, 16, 2)
	horiz.material_override = mat; horiz.rotation.x = PI / 2; horiz.position = c; node.add_child(horiz)
	var sp = MeshInstance3D.new(); var sm = SphereMesh.new(); sm.radius = r * 1.8; sm.height = r * 3.6
	sp.mesh = sm; sp.material_override = mat; sp.position = c; node.add_child(sp)
	return node

func _create_glass_spiral_smooth(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	mi.mesh = _generate_spiral_mesh(h, w * 0.35, r, 4, 12, 48)
	mi.material_override = mat; mi.position.z = w / 2; node.add_child(mi); return node

func _generate_spiral_mesh(h: float, cr: float, tr: float, turns: int, ts: int, cs: int) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for c in range(cs + 1):
		var t = float(c) / cs; var ca = t * turns * TAU; var y = t * h
		var center = Vector3(cr * cos(ca), y, cr * sin(ca))
		var dx = -cr * sin(ca) * turns * TAU / cs; var dy = h / cs; var dz = cr * cos(ca) * turns * TAU / cs
		var tang = Vector3(dx, dy, dz).normalized()
		var bn = tang.cross(Vector3.UP).normalized(); var n = bn.cross(tang).normalized()
		for s in range(ts + 1):
			var ra = (float(s) / ts) * TAU; var off = (n * cos(ra) + bn * sin(ra)) * tr
			st.set_normal(off.normalized()); st.set_uv(Vector2(float(s) / ts, t)); st.add_vertex(center + off)
	for c2 in range(cs):
		for s in range(ts):
			var cu = c2 * (ts + 1) + s; var nx = cu + ts + 1
			st.add_index(cu); st.add_index(nx); st.add_index(cu + 1)
			st.add_index(cu + 1); st.add_index(nx); st.add_index(nx + 1)
	st.generate_tangents(); return st.commit()

func _create_glass_condenser_smooth(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var inner = _create_glass_tube_smooth(h, r, mat); inner.position.z = w / 2; node.add_child(inner)
	var jacket = _create_glass_tube_smooth(h * 0.7, r * 2.5, mat); jacket.position = Vector3(0, h * 0.15, w / 2); node.add_child(jacket)
	return node

func _create_glass_flask_smooth(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var bulb = MeshInstance3D.new(); var sm = SphereMesh.new(); sm.radius = w * 0.4; sm.height = w * 0.8
	bulb.mesh = sm; bulb.material_override = mat; bulb.position = Vector3(0, w * 0.4, w / 2); node.add_child(bulb)
	var neck = _create_glass_tube_smooth(h - w * 0.7, r, mat)
	neck.position = Vector3(0, w * 0.7, w / 2); node.add_child(neck); return node

func _create_glass_beaker_smooth(w: float, h: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new(); cyl.top_radius = w * 0.4; cyl.bottom_radius = w * 0.35; cyl.height = h * 0.9
	mi.mesh = cyl; mi.material_override = mat; mi.position = Vector3(0, h * 0.45, w / 2)
	node.add_child(mi); return node

func _create_glass_cap_smooth(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	var sp = SphereMesh.new(); sp.radius = min(w, h) * 0.4; sp.height = sp.radius * 2.0; sp.is_hemisphere = true
	mi.mesh = sp; mi.material_override = mat; mi.rotation.x = PI; mi.position = Vector3(0, h * 0.5, w / 2.0)
	node.add_child(mi); return node

func _create_glass_drip_smooth(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	var cone = CylinderMesh.new(); cone.top_radius = r; cone.bottom_radius = r * 0.3; cone.height = h * 0.8
	mi.mesh = cone; mi.material_override = mat; mi.position = Vector3(0, h * 0.5, w / 2.0)
	node.add_child(mi); return node

func _create_glass_corner45_smooth(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	var ar = min(w, h) / 2.0
	mi.mesh = _generate_corner45_mesh_yz(ar, r, h / 2.0, w / 2.0, 16, 12)
	mi.material_override = mat; node.add_child(mi); return node

func _generate_corner45_mesh_yz(ar: float, tr: float, cy: float, cz: float, ts: int, bs: int) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sa = -PI / 2.0; var ea = -PI / 4.0; var pn := Vector3.ZERO
	for b in range(bs + 1):
		var t = float(b) / bs; var a = lerpf(sa, ea, t)
		var center = Vector3(0, cy + ar * sin(a), cz + ar * cos(a))
		var da = ea - sa; var tang = Vector3(0, ar * cos(a) * da, -ar * sin(a) * da).normalized()
		var n: Vector3; var bn: Vector3
		if pn == Vector3.ZERO:
			n = tang.cross(Vector3.RIGHT); if n.length_squared() < 0.001: n = tang.cross(Vector3.UP)
			n = n.normalized()
		else: n = pn - tang * tang.dot(pn); n = pn if n.length_squared() < 0.001 else n.normalized()
		bn = tang.cross(n).normalized(); pn = n
		for s in range(ts + 1):
			var ra = (float(s) / ts) * TAU; var off = (n * cos(ra) + bn * sin(ra)) * tr
			st.set_normal(off.normalized()); st.set_uv(Vector2(float(s) / ts, t)); st.add_vertex(center + off)
	for b2 in range(bs):
		for s in range(ts):
			var c = b2 * (ts + 1) + s; var nx = c + ts + 1
			st.add_index(c); st.add_index(nx); st.add_index(c + 1)
			st.add_index(c + 1); st.add_index(nx); st.add_index(nx + 1)
	st.generate_tangents(); return st.commit()

func _create_glass_wobbly_smooth(w: float, h: float, r: float, mat: Material, y_offset: float = 0.0) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	var cz = w / 2.0; var amp = max(r * 1.5, w * 0.2); var wc = max(2.0, h / max(w * 0.4, 0.001))
	mi.mesh = _generate_wobbly_mesh_yz(h, cz, amp, wc, r, 16, 32, y_offset)
	mi.material_override = mat; node.add_child(mi); return node

func _generate_wobbly_mesh_yz(h: float, cz: float, amp: float, wc: float, tr: float, ts: int, ls: int, y_offset: float = 0.0) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for l in range(ls + 1):
		var t = float(l) / ls; var y = y_offset + t * h; var z = cz + sin(t * TAU * wc) * amp
		var dy = h / ls; var dz = cos(t * TAU * wc) * amp * TAU * wc / ls
		var tang = Vector3(0, dy, dz).normalized(); var bn = Vector3(1, 0, 0); var n = bn.cross(tang).normalized()
		for s in range(ts + 1):
			var ra = (float(s) / ts) * TAU; var ro = (n * cos(ra) + bn * sin(ra)) * tr
			st.set_normal(ro.normalized()); st.set_uv(Vector2(float(s) / ts, t)); st.add_vertex(Vector3(0, y, z) + ro)
	for l2 in range(ls):
		for s in range(ts):
			var c = l2 * (ts + 1) + s; var nx = c + ts + 1
			st.add_index(c); st.add_index(nx); st.add_index(c + 1)
			st.add_index(c + 1); st.add_index(nx); st.add_index(nx + 1)
	st.generate_tangents(); return st.commit()

func _create_glass_reducer_smooth(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	mi.mesh = _generate_reducer_mesh_yz(h, w / 2.0, r, r * 0.6, 16, 8)
	mi.material_override = mat; node.add_child(mi); return node

func _generate_reducer_mesh_yz(h: float, cz: float, br: float, tr: float, ts: int, rs: int) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(rs + 1):
		var t = float(r) / rs; var y = t * h; var cr = lerpf(br, tr, t)
		for s in range(ts + 1):
			var th = (float(s) / ts) * TAU
			st.set_normal(Vector3(cos(th), 0, sin(th))); st.set_uv(Vector2(float(s) / ts, t))
			st.add_vertex(Vector3(cr * cos(th), y, cz + cr * sin(th)))
	for r2 in range(rs):
		for s in range(ts):
			var c = r2 * (ts + 1) + s; var nx = c + ts + 1
			st.add_index(c); st.add_index(nx); st.add_index(c + 1)
			st.add_index(c + 1); st.add_index(nx); st.add_index(nx + 1)
	st.generate_tangents(); return st.commit()

func _create_placeholder_3d(element: Dictionary, grid_size: float) -> Node3D:
	var node = Node3D.new(); node.name = element.get("id", "element")
	var sz = _safe_size(element); var mi = MeshInstance3D.new()
	var mesh = BoxMesh.new(); mesh.size = Vector3(sz[0] * grid_size * 0.8, sz[1] * grid_size * 0.8, 0.01)
	mi.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.5, 0.6); mat.emission_enabled = true; mat.emission = Color(0.2, 0.3, 0.4)
	mi.material_override = mat; mi.position = Vector3(sz[0] * grid_size * 0.5, sz[1] * grid_size * 0.5, 0)
	node.add_child(mi)
	var label = Label3D.new(); label.text = element.get("icon", "?")
	label.position = Vector3(sz[0] * grid_size * 0.5, sz[1] * grid_size * 0.5, 0.01)
	label.pixel_size = 0.005; label.font_size = 32; label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.add_child(label)
	return node
