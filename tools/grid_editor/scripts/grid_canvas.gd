@tool
extends Control
class_name GridCanvas
## 2D Grid canvas for placing elements
## Handles drawing, interaction, zoom/pan

signal cell_hovered(cell: Vector2i)
signal cell_clicked(cell: Vector2i, button: int)
signal element_placed(placement: Dictionary)
signal element_selected(placement: Dictionary)
signal element_rotated(placement: Dictionary)
signal element_moved(placement: Dictionary)
signal selection_cleared

# Grid settings
@export var grid_dimensions: Vector2i = Vector2i(16, 12):
	set(value):
		grid_dimensions = value
		queue_redraw()

@export var cell_size: float = 40.0:
	set(value):
		cell_size = value
		queue_redraw()

# View settings
var zoom: float = 1.0
var pan_offset: Vector2 = Vector2.ZERO
var is_panning: bool = false
var pan_start: Vector2 = Vector2.ZERO

# Interaction
var hovered_cell: Vector2i = Vector2i(-1, -1)
var selected_placements: Array = []
var dragging_element: Dictionary = {}
var drag_preview_cell: Vector2i = Vector2i(-1, -1)
var drag_rotation: int = 0  # 0, 90, 180, 270

# Moving existing elements
var moving_placement: Dictionary = {}
var move_offset: Vector2i = Vector2i.ZERO

# Data
var placements: Array = []  # Array of placement dictionaries
var subset_loader: GridEditorSubsetLoader  # Set by parent

# Modern dark theme colors
var color_grid_line: Color = Color(0.2, 0.22, 0.26)
var color_grid_major: Color = Color(0.28, 0.3, 0.35)
var color_background: Color = Color(0.1, 0.1, 0.12)
var color_hover: Color = Color(0.35, 0.55, 0.85, 0.25)
var color_selected: Color = Color(0.95, 0.65, 0.2, 0.35)
var color_preview: Color = Color(0.4, 0.85, 0.5, 0.4)
var color_invalid: Color = Color(0.9, 0.25, 0.25, 0.4)
var color_element_bg: Color = Color(0.18, 0.22, 0.28, 0.9)
var color_element_border: Color = Color(0.5, 0.55, 0.65)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true

func _draw() -> void:
	var canvas_size = size
	
	# Background
	draw_rect(Rect2(Vector2.ZERO, canvas_size), color_background)
	
	# Calculate visible grid area
	var grid_origin = _get_grid_origin()
	var scaled_cell = cell_size * zoom
	
	# Draw grid
	for x in range(grid_dimensions.x + 1):
		var from = grid_origin + Vector2(x * scaled_cell, 0)
		var to = grid_origin + Vector2(x * scaled_cell, grid_dimensions.y * scaled_cell)
		var color = color_grid_major if x % 4 == 0 else color_grid_line
		draw_line(from, to, color, 1.0 if x % 4 == 0 else 0.5)
	
	for y in range(grid_dimensions.y + 1):
		var from = grid_origin + Vector2(0, y * scaled_cell)
		var to = grid_origin + Vector2(grid_dimensions.x * scaled_cell, y * scaled_cell)
		var color = color_grid_major if y % 4 == 0 else color_grid_line
		draw_line(from, to, color, 1.0 if y % 4 == 0 else 0.5)
	
	# Draw placed elements (skip the one being moved)
	for placement in placements:
		if placement == moving_placement:
			continue
		_draw_element(placement, selected_placements.has(placement))
	
	# Draw hover highlight
	if _is_valid_cell(hovered_cell) and dragging_element.is_empty():
		var rect = _get_cell_rect(hovered_cell)
		draw_rect(rect, color_hover)
	
	# Draw drag preview (new element)
	if not dragging_element.is_empty() and _is_valid_cell(drag_preview_cell):
		var element = dragging_element
		var elem_size = _get_rotated_size(element, drag_rotation)
		var can_place = _can_place_at(drag_preview_cell, elem_size)
		var preview_color = color_preview if can_place else color_invalid
		
		for dx in range(elem_size.x):
			for dy in range(elem_size.y):
				var cell = drag_preview_cell + Vector2i(dx, dy)
				if _is_valid_cell(cell):
					var rect = _get_cell_rect(cell)
					draw_rect(rect, preview_color)
		
		# Draw element preview
		_draw_element_preview(element, drag_preview_cell, drag_rotation)
	
	# Draw move preview (existing element)
	if not moving_placement.is_empty() and _is_valid_cell(drag_preview_cell):
		var element = subset_loader.get_element(moving_placement.get("element", "")) if subset_loader else {}
		var rotation = moving_placement.get("rotation", 0)
		var elem_size = _get_rotated_size(element, rotation)
		var can_place = _can_place_at_for_move(drag_preview_cell, elem_size, moving_placement)
		var preview_color = color_preview if can_place else color_invalid
		
		for dx in range(elem_size.x):
			for dy in range(elem_size.y):
				var cell = drag_preview_cell + Vector2i(dx, dy)
				if _is_valid_cell(cell):
					var rect = _get_cell_rect(cell)
					draw_rect(rect, preview_color)
		
		_draw_element_preview(element, drag_preview_cell, rotation)

func _draw_element(placement: Dictionary, is_selected: bool) -> void:
	if not subset_loader:
		return
	var element = subset_loader.get_element(placement.get("element", ""))
	if element.is_empty():
		return
	
	var cell = Vector2i(placement.get("position", [0, 0])[0], placement.get("position", [0, 0])[1])
	var rotation = placement.get("rotation", 0)
	var elem_size = _get_rotated_size(element, rotation)
	
	# Draw element background with modern styling
	var full_rect = _get_element_rect(cell, elem_size)
	var bg_color = color_element_bg
	if is_selected:
		bg_color = Color(0.3, 0.4, 0.55, 0.9)
	draw_rect(full_rect, bg_color)
	var border_color = color_selected if is_selected else color_element_border
	draw_rect(full_rect, border_color, false, 2.0 if is_selected else 1.0)
	
	# Draw icon/ASCII with rotation
	var icon = element.get("icon", "?")
	var font = ThemeDB.fallback_font
	var font_size = int(cell_size * zoom * 0.6)
	var center = full_rect.get_center()
	
	draw_set_transform(center, deg_to_rad(rotation), Vector2.ONE)
	draw_string(font, Vector2(-font_size * 0.3, font_size * 0.3), icon, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	
	# Draw rotation indicator for non-zero rotation
	if rotation != 0:
		var indicator_pos = full_rect.position + Vector2(4, 4)
		draw_string(font, indicator_pos, "%dÂ°" % rotation, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7, 0.8))
	
	# Ports hidden for free placement

func _draw_element_preview(element: Dictionary, cell: Vector2i, rotation: int = 0) -> void:
	var elem_size = _get_rotated_size(element, rotation)
	var full_rect = _get_element_rect(cell, elem_size)
	
	var icon = element.get("icon", "?")
	var font = ThemeDB.fallback_font
	var font_size = int(cell_size * zoom * 0.6)
	var center = full_rect.get_center()
	
	# Draw rotated icon
	draw_set_transform(center, deg_to_rad(rotation), Vector2.ONE)
	draw_string(font, Vector2(-font_size * 0.3, font_size * 0.3), icon, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1, 1, 1, 0.7))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		
		# Zoom
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(mb.position, 1.1)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(mb.position, 0.9)
			accept_event()
		
		# Pan
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = mb.pressed
			pan_start = mb.position
			accept_event()
		
		# Click
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			var cell = _canvas_to_cell(mb.position)
			if mb.pressed:
				if not dragging_element.is_empty():
					_try_place_element(cell)
				elif mb.double_click:
					_handle_double_click(cell)
				else:
					_start_move_or_select(cell)
				accept_event()
			else:
				# Mouse released
				if not moving_placement.is_empty():
					_finish_move(cell)
					accept_event()
		
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			dragging_element = {}
			moving_placement = {}
			drag_preview_cell = Vector2i(-1, -1)
			drag_rotation = 0
			queue_redraw()
			accept_event()
	
	elif event is InputEventKey:
		var ke = event as InputEventKey
		if ke.pressed and ke.keycode == KEY_R:
			if not dragging_element.is_empty():
				# Rotate while dragging
				drag_rotation = (drag_rotation + 90) % 360
				queue_redraw()
				accept_event()
			elif not selected_placements.is_empty():
				# Rotate selected element
				_rotate_selected()
				accept_event()
	
	elif event is InputEventMouseMotion:
		var mm = event as InputEventMouseMotion
		
		if is_panning:
			pan_offset += mm.relative
			queue_redraw()
		else:
			var cell = _canvas_to_cell(mm.position)
			if cell != hovered_cell:
				hovered_cell = cell
				cell_hovered.emit(cell)
				queue_redraw()
			
			if not dragging_element.is_empty():
				drag_preview_cell = cell
				queue_redraw()
			elif not moving_placement.is_empty():
				drag_preview_cell = cell - move_offset
				queue_redraw()

func _zoom_at(pos: Vector2, factor: float) -> void:
	var old_zoom = zoom
	zoom = clamp(zoom * factor, 0.25, 4.0)
	
	# Adjust pan to zoom at cursor position
	var zoom_change = zoom / old_zoom
	pan_offset = pos - (pos - pan_offset) * zoom_change
	
	queue_redraw()

func _get_grid_origin() -> Vector2:
	return pan_offset + size / 2 - Vector2(grid_dimensions) * cell_size * zoom / 2

func _cell_to_canvas(cell: Vector2i) -> Vector2:
	return _get_grid_origin() + Vector2(cell) * cell_size * zoom

func _canvas_to_cell(pos: Vector2) -> Vector2i:
	var grid_pos = (pos - _get_grid_origin()) / (cell_size * zoom)
	return Vector2i(floor(grid_pos.x), floor(grid_pos.y))

func _get_cell_rect(cell: Vector2i) -> Rect2:
	var origin = _cell_to_canvas(cell)
	return Rect2(origin, Vector2.ONE * cell_size * zoom)

func _get_element_rect(cell: Vector2i, elem_size: Vector2i) -> Rect2:
	var origin = _cell_to_canvas(cell)
	return Rect2(origin, Vector2(elem_size) * cell_size * zoom)

func _is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_dimensions.x and cell.y < grid_dimensions.y

func _can_place_at(cell: Vector2i, elem_size: Vector2i) -> bool:
	# Check bounds
	if cell.x < 0 or cell.y < 0:
		return false
	if cell.x + elem_size.x > grid_dimensions.x:
		return false
	if cell.y + elem_size.y > grid_dimensions.y:
		return false
	
	# Check overlap
	for placement in placements:
		if _placements_overlap(cell, elem_size, placement):
			return false
	
	return true

func _placements_overlap(cell: Vector2i, elem_size: Vector2i, placement: Dictionary) -> bool:
	var p_cell = Vector2i(placement.get("position", [0, 0])[0], placement.get("position", [0, 0])[1])
	var p_size = Vector2i(1, 1)
	if subset_loader:
		var p_element = subset_loader.get_element(placement.get("element", ""))
		var p_rotation = placement.get("rotation", 0)
		p_size = _get_rotated_size(p_element, p_rotation)
	
	var r1 = Rect2i(cell, elem_size)
	var r2 = Rect2i(p_cell, p_size)
	return r1.intersects(r2)

func _handle_double_click(cell: Vector2i) -> void:
	# Find element at cell and rotate it
	for placement in placements:
		var p_cell = Vector2i(placement.get("position", [0, 0])[0], placement.get("position", [0, 0])[1])
		var p_size = Vector2i(1, 1)
		if subset_loader:
			var p_element = subset_loader.get_element(placement.get("element", ""))
			var p_rotation = placement.get("rotation", 0)
			p_size = _get_rotated_size(p_element, p_rotation)
		
		if cell.x >= p_cell.x and cell.x < p_cell.x + p_size.x:
			if cell.y >= p_cell.y and cell.y < p_cell.y + p_size.y:
				# Select and rotate
				selected_placements = [placement]
				placement["rotation"] = (placement.get("rotation", 0) + 90) % 360
				element_rotated.emit(placement)
				queue_redraw()
				return

func _start_move_or_select(cell: Vector2i) -> void:
	# Check if clicking on existing element
	for placement in placements:
		var p_cell = Vector2i(placement.get("position", [0, 0])[0], placement.get("position", [0, 0])[1])
		var p_size = Vector2i(1, 1)
		if subset_loader:
			var p_element = subset_loader.get_element(placement.get("element", ""))
			var p_rotation = placement.get("rotation", 0)
			p_size = _get_rotated_size(p_element, p_rotation)
		
		if cell.x >= p_cell.x and cell.x < p_cell.x + p_size.x:
			if cell.y >= p_cell.y and cell.y < p_cell.y + p_size.y:
				# Start moving this element
				moving_placement = placement
				move_offset = cell - p_cell
				drag_preview_cell = p_cell
				selected_placements = [placement]
				element_selected.emit(placement)
				queue_redraw()
				return
	
	# Clear selection
	selected_placements.clear()
	moving_placement = {}
	selection_cleared.emit()
	queue_redraw()

func _finish_move(cell: Vector2i) -> void:
	if moving_placement.is_empty():
		return
	
	var target_cell = cell - move_offset
	var element = subset_loader.get_element(moving_placement.get("element", "")) if subset_loader else {}
	var rotation = moving_placement.get("rotation", 0)
	var elem_size = _get_rotated_size(element, rotation)
	
	if _can_place_at_for_move(target_cell, elem_size, moving_placement):
		moving_placement["position"] = [target_cell.x, target_cell.y]
		element_moved.emit(moving_placement)
	
	moving_placement = {}
	drag_preview_cell = Vector2i(-1, -1)
	queue_redraw()

func _can_place_at_for_move(cell: Vector2i, elem_size: Vector2i, exclude_placement: Dictionary) -> bool:
	# Check bounds
	if cell.x < 0 or cell.y < 0:
		return false
	if cell.x + elem_size.x > grid_dimensions.x:
		return false
	if cell.y + elem_size.y > grid_dimensions.y:
		return false
	
	# Check overlap (excluding the element being moved)
	for placement in placements:
		if placement == exclude_placement:
			continue
		if _placements_overlap(cell, elem_size, placement):
			return false
	
	return true

func _handle_click(_cell: Vector2i) -> void:
	# Legacy - now handled by _start_move_or_select
	pass

func _try_place_element(cell: Vector2i) -> void:
	if dragging_element.is_empty():
		return
	
	var elem_size = _get_rotated_size(dragging_element, drag_rotation)
	if not _can_place_at(cell, elem_size):
		return
	
	var placement = {
		"id": "elem_%d" % (placements.size() + 1),
		"element": dragging_element.get("id", ""),
		"position": [cell.x, cell.y],
		"rotation": drag_rotation,
		"params": {}
	}
	
	placements.append(placement)
	element_placed.emit(placement)
	
	# Clear drag state (or keep for multi-place)
	dragging_element = {}
	drag_preview_cell = Vector2i(-1, -1)
	drag_rotation = 0
	queue_redraw()

func _rotate_selected() -> void:
	for placement in selected_placements:
		placement["rotation"] = (placement.get("rotation", 0) + 90) % 360
		element_rotated.emit(placement)
	queue_redraw()

func _get_rotated_size(element: Dictionary, rotation: int) -> Vector2i:
	var size = Vector2i(element.get("size", [1, 1])[0], element.get("size", [1, 1])[1])
	if rotation == 90 or rotation == 270:
		return Vector2i(size.y, size.x)  # Swap width/height
	return size

# Public API
func start_drag(element: Dictionary) -> void:
	dragging_element = element
	drag_preview_cell = hovered_cell
	queue_redraw()

func clear_placements() -> void:
	placements.clear()
	selected_placements.clear()
	queue_redraw()

func delete_selected() -> void:
	for placement in selected_placements:
		placements.erase(placement)
	selected_placements.clear()
	selection_cleared.emit()
	queue_redraw()

func get_layout_data() -> Dictionary:
	return {
		"grid_size": [grid_dimensions.x, grid_dimensions.y],
		"placements": placements.duplicate(true)
	}

func load_layout_data(data: Dictionary) -> void:
	grid_dimensions = Vector2i(data.get("grid_size", [16, 12])[0], data.get("grid_size", [16, 12])[1])
	placements = data.get("placements", []).duplicate(true)
	selected_placements.clear()
	queue_redraw()
