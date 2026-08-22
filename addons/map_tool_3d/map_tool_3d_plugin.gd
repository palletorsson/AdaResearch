@tool
extends EditorPlugin
## Map Tool 3D — adds CLICK-TO-PLACE / PAINT to the 3D viewport for a MapToolEditor scene.
##
## The @tool MapToolEditor scene (commons/scenes/map_tool_editor.tscn) can only be edited via the
## gizmo. This plugin adds what a plain @tool node can't: it intercepts viewport clicks
## (_forward_3d_gui_input), raycasts to the grid plane, and calls the editor's place_at_cell() so a
## single click drops an artifact, paints a structure cube, or erases a cell. A small dock holds the
## token + mode. The MapToolEditor still owns load/save/build — this only adds the input + dock.
##
## Enable in Project Settings → Plugins → "Map Tool 3D", then open map_tool_editor.tscn and select
## the MapToolEditor node. (Complements the 2D top-down "Map Grid Editor" add-on.)

const EDITOR_SCENE := "res://commons/scenes/map_tool_editor.tscn"

var _dock: VBoxContainer
var _target: Node = null
var _token_field: LineEdit
var _mode: OptionButton
var _info: Label
var _open_btn: Button = null
var _rmb_pos := Vector2.ZERO
var _drag_marker: Node3D = null
var _drag_from := Vector2i(-99999, -99999)
var _drag_moved := false
var _ctx_menu: PopupMenu = null
var _menu_cell := Vector2i(-99999, -99999)


func _enter_tree() -> void:
	_dock = _build_dock()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, _dock)
	# Top-bar entry point: one click opens the MapToolEditor scene + selects its root,
	# so the inspector controls and this dock's click-to-place activate immediately.
	_open_btn = Button.new()
	_open_btn.text = "Map Tool"
	_open_btn.tooltip_text = "Open the Map Tool Editor (commons/scenes/map_tool_editor.tscn), select it, and load its map."
	_open_btn.pressed.connect(_open_editor_scene)
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, _open_btn)


func _exit_tree() -> void:
	if _ctx_menu:
		_ctx_menu.queue_free()
		_ctx_menu = null
	if _open_btn:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, _open_btn)
		_open_btn.queue_free()
		_open_btn = null
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
	_target = null


# ── Top-bar entry point ───────────────────────────────────────────────
# Opens the MapToolEditor scene, selects its root node (so the inspector shows its
# controls and _handles()/_edit() arms this add-on), and loads the current map so
# the editor lands ready to use rather than empty.
func _open_editor_scene() -> void:
	var ei := get_editor_interface()
	ei.open_scene_from_path(EDITOR_SCENE)
	# edited_scene_root is not ready on the frame the scene opens — let it settle.
	await get_tree().process_frame
	await get_tree().process_frame
	var root := ei.get_edited_scene_root()
	if root == null or not root.has_method("place_at_cell"):
		return
	var sel := ei.get_selection()
	sel.clear()
	sel.add_node(root)
	ei.edit_node(root)
	if root.has_method("_load"):
		root.call("_load")   # populate markers for the default/last map


# Activate for any node exposing place_at_cell (i.e. a MapToolEditor) — no class_name dependency.
func _handles(object) -> bool:
	return object != null and object is Node and (object as Node).has_method("place_at_cell")


func _edit(object) -> void:
	_target = object if (object is Node) else null
	_refresh_info()


func _make_visible(visible) -> void:
	if not visible:
		_target = null
		_refresh_info()


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if _target == null or not is_instance_valid(_target):
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	# X deletes the selected markers, Blender-style (undoable).
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo and k.keycode == KEY_X:
			_delete_selected_undoable()
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	# Mid-drag: the grabbed marker rides the cell under the cursor.
	if event is InputEventMouseMotion and _drag_marker != null:
		if not is_instance_valid(_drag_marker):
			_drag_marker = null
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		var mcell := _cell_at(viewport_camera, (event as InputEventMouseMotion).position)
		if mcell.x != -99999:
			_target.call("move_marker_to", _drag_marker, mcell.x, mcell.y)
			_drag_moved = true
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	if not (event is InputEventMouseButton):
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	var mb := event as InputEventMouseButton
	# Right-click WITHOUT a drag opens a context menu (Delete). A right-DRAG still orbits the camera.
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		if mb.pressed:
			_rmb_pos = mb.position
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		if mb.position.distance_to(_rmb_pos) < 6.0:
			_open_context_menu(viewport_camera, mb.position)
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	# Left RELEASE ends a drag: commit the move as one undo step; a press
	# that never moved is a plain click-select.
	if not mb.pressed:
		if _drag_marker == null:
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		var m := _drag_marker
		_drag_marker = null
		if not is_instance_valid(m):
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		if _drag_moved:
			var total := float(_target.get("_total"))
			if total <= 0.0:
				total = 1.0
			var to := Vector2i(int(round(m.position.x / total)), int(round(m.position.z / total)))
			var ur := get_undo_redo()
			ur.create_action("Map Tool: drag artifact")
			ur.add_do_method(_target, "move_marker_to", m, to.x, to.y)
			ur.add_undo_method(_target, "move_marker_to", m, _drag_from.x, _drag_from.y)
			ur.commit_action()
		_refresh_info()
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	# Plain left PRESS on a marker grabs it for a direct drag (and selects
	# it, so X / gizmo follow-ups have a target). Empty cells fall through
	# to the editor for native rubber-band select; structure cubes keep
	# their gizmo flow. Hold Ctrl to place / paint / erase instead.
	if not mb.ctrl_pressed:
		var pcell := _cell_at(viewport_camera, mb.position)
		if pcell.x == -99999:
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		var hit: Node3D = _target.call("marker_at_cell", pcell.x, pcell.y)
		if hit == null:
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		_drag_marker = hit
		_drag_from = Vector2i(pcell.x, pcell.y)
		_drag_moved = false
		var sel := get_editor_interface().get_selection()
		if not mb.shift_pressed:
			sel.clear()
		sel.add_node(hit)
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	var cell := _cell_at(viewport_camera, mb.position)
	if cell.x == -99999:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	var mode := _mode.get_selected_id() if _mode else 0
	var token := _token_field.text if _token_field else ""
	_apply_with_undo(cell.x, cell.y, token, mode)
	_refresh_info()
	return EditorPlugin.AFTER_GUI_INPUT_STOP   # consume the click so it doesn't also select


# Wrap a viewport place / paint / erase in the editor's UndoRedo so Ctrl+Z / Ctrl+Y work.
# The guards keep a no-op click (empty token, or paint without edit_grid) from leaving a
# destructive undo entry that would later delete a pre-existing marker/cube.
func _apply_with_undo(cx: int, cz: int, token: String, mode: int) -> void:
	var ur := get_undo_redo()
	match mode:
		1:
			if not bool(_target.get("edit_grid")):
				_target.call("place_at_cell", cx, cz, token, 1)   # warns; nothing added
				return
			ur.create_action("Map Tool: paint cube")
			ur.add_do_method(_target, "place_at_cell", cx, cz, token, 1)
			ur.add_undo_method(_target, "_undo_top_cube", cx, cz)
		2:
			var saved: Array = _target.call("cell_tokens", cx, cz)
			ur.create_action("Map Tool: erase cell")
			ur.add_do_method(_target, "place_at_cell", cx, cz, token, 2)
			ur.add_undo_method(_target, "_restore_tokens", cx, cz, saved)
		_:
			if token.strip_edges() == "":
				_target.call("place_at_cell", cx, cz, token, 0)   # warns; nothing added
				return
			ur.create_action("Map Tool: place artifact")
			ur.add_do_method(_target, "place_at_cell", cx, cz, token, 0)
			ur.add_undo_method(_target, "_undo_newest_marker", cx, cz)
	ur.commit_action()


# Raycast a viewport position to the target's grid plane → cell, or (-99999,-99999) on miss.
func _cell_at(cam: Camera3D, pos: Vector2) -> Vector2i:
	var total := float(_target.get("_total"))
	if total <= 0.0:
		total = 1.0
	var from := cam.project_ray_origin(pos)
	var dir := cam.project_ray_normal(pos)
	var inv := (_target as Node3D).global_transform.affine_inverse()
	var lo := inv * from
	var ld := inv.basis * dir
	if absf(ld.y) < 0.00001:
		return Vector2i(-99999, -99999)
	var t := -lo.y / ld.y
	if t <= 0.0:
		return Vector2i(-99999, -99999)
	var hit := lo + ld * t
	return Vector2i(int(round(hit.x / total)), int(round(hit.z / total)))


func _open_context_menu(cam: Camera3D, pos: Vector2) -> void:
	_menu_cell = _cell_at(cam, pos)
	if _ctx_menu == null:
		_ctx_menu = PopupMenu.new()
		_ctx_menu.add_item("Delete cell under cursor", 0)
		_ctx_menu.add_item("Delete selected", 1)
		_ctx_menu.id_pressed.connect(_on_ctx_menu)
		get_editor_interface().get_base_control().add_child(_ctx_menu)
	_ctx_menu.set_item_disabled(0, _menu_cell.x == -99999)
	_ctx_menu.reset_size()
	_ctx_menu.position = DisplayServer.mouse_get_position()
	_ctx_menu.popup()


func _on_ctx_menu(id: int) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	match id:
		0:   # erase the cell under the cursor (undoable)
			if _menu_cell.x != -99999:
				_apply_with_undo(_menu_cell.x, _menu_cell.y, "", 2)
				_refresh_info()
		1:   # erase every cell that holds a gizmo-selected marker (undoable)
			_delete_selected_undoable()


func _delete_selected_undoable() -> void:
	var total := float(_target.get("_total"))
	if total <= 0.0:
		total = 1.0
	var cells := {}
	for node in get_editor_interface().get_selection().get_selected_nodes():
		if node is Node3D and (node as Node).get_parent() == _target and (node as Node).has_meta("token"):
			var p: Vector3 = (node as Node3D).position
			cells[Vector2i(int(round(p.x / total)), int(round(p.z / total)))] = true
	for cell in cells.keys():
		_apply_with_undo(cell.x, cell.y, "", 2)
	_refresh_info()


func _build_dock() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = "Map Tool 3D"
	var title := Label.new()
	title.text = "Map Tool 3D"
	title.add_theme_font_size_override("font_size", 15)
	v.add_child(title)
	_info = Label.new()
	_info.text = "(select a MapToolEditor node)"
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_info)
	v.add_child(HSeparator.new())
	var tl := Label.new()
	tl.text = "Artifact token (Place mode)"
	v.add_child(tl)
	_token_field = LineEdit.new()
	_token_field.placeholder_text = "e.g. fibonacci_pagoda"
	v.add_child(_token_field)
	var ml := Label.new()
	ml.text = "Left-click does:"
	v.add_child(ml)
	_mode = OptionButton.new()
	_mode.add_item("Place artifact", 0)
	_mode.add_item("Paint structure cube", 1)
	_mode.add_item("Erase cell", 2)
	v.add_child(_mode)
	var hint := Label.new()
	hint.text = "Drag a marker to move it (click = select, shift-click adds, X deletes selected). Ctrl+click a cell = apply the action above, then Save map. (Paint needs the Structure layer / edit_grid on.)"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.66))
	v.add_child(hint)
	return v


func _refresh_info() -> void:
	if _info == null:
		return
	if _target == null or not is_instance_valid(_target):
		_info.text = "(select a MapToolEditor node)"
	else:
		_info.text = "Editing: %s" % str(_target.get("map_name"))
