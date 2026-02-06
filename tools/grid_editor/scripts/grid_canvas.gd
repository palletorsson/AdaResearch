@tool
extends Control
class_name GridCanvas
## 2D Grid canvas for placing elements
## Handles drawing, interaction, zoom/pan

signal cell_hovered(cell: Vector2i)
signal cell_clicked(cell: Vector2i, button: int)
signal element_placed(placement: Dictionary)
signal element_selected(placement: Dictionary)
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

# Data
var placements: Array = []  # Array of placement dictionaries
var subset_loader: GridEditorSubsetLoader  # Set by parent

# Colors
var color_grid_line: Color = Color(0.3, 0.3, 0.35)
var color_grid_major: Color = Color(0.4, 0.4, 0.45)
var color_background: Color = Color(0.15, 0.15, 0.18)
var color_hover: Color = Color(0.4, 0.6, 0.9, 0.3)
var color_selected: Color = Color(0.9, 0.6, 0.2, 0.4)
var color_preview: Color = Color(0.5, 0.9, 0.5, 0.5)
var color_invalid: Color = Color(0.9, 0.3, 0.3, 0.5)

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
	
	# Draw placed elements
	for placement in placements:
		_draw_element(placement, selected_placements.has(placement))
	
	# Draw hover highlight
	if _is_valid_cell(hovered_cell) and dragging_element.is_empty():
		var rect = _get_cell_rect(hovered_cell)
		draw_rect(rect, color_hover)
	
	# Draw drag preview
	if not dragging_element.is_empty() and _is_valid_cell(drag_preview_cell):
		var element = dragging_element
		var elem_size = Vector2i(element.get("size", [1, 1])[0], element.get("size", [1, 1])[1])
		var can_place = _can_place_at(drag_preview_cell, elem_size)
		var preview_color = color_preview if can_place else color_invalid
		
		for dx in range(elem_size.x):
			for dy in range(elem_size.y):
				var cell = drag_preview_cell + Vector2i(dx, dy)
				if _is_valid_cell(cell):
					var rect = _get_cell_rect(cell)
					draw_rect(rect, preview_color)
		
		# Draw element preview
		_draw_element_preview(element, drag_preview_cell)

func _draw_element(placement: Dictionary, is_selected: bool) -> void:
	if not subset_loader:
		return
	var element = subset_loader.get_element(placement.get("element", ""))
	if element.is_empty():
		return
	
	var cell = Vector2i(placement.get("position", [0, 0])[0], placement.get("position", [0, 0])[1])
	var elem_size = Vector2i(element.get("size", [1, 1])[0], element.get("size", [1, 1])[1])
	var rotation = placement.get("rotation", 0)
	
	# Draw element background
	var full_rect = _get_element_rect(cell, elem_size)
	var bg_color = Color(0.25, 0.35, 0.45, 0.8)
	if is_selected:
		bg_color = color_selected
	draw_rect(full_rect, bg_color)
	draw_rect(full_rect, Color.WHITE, false, 2.0)
	
	# Draw icon/ASCII
	var icon = element.get("icon", "?")
	var font = ThemeDB.fallback_font
	var font_size = int(cell_size * zoom * 0.6)
	var text_pos = full_rect.get_center() - Vector2(font_size * 0.3, -font_size * 0.3)
	draw_string(font, text_pos, icon, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	
	# Draw ports
	var ports = element.get("ports", {})
	for port_name in ports:
		var port = ports[port_name]
		var port_cell = Vector2i(port.get("cell", [0, 0])[0], port.get("cell", [0, 0])[1])
		var port_pos = _cell_to_canvas(cell + port_cell) + Vector2(cell_size * zoom / 2, cell_size * zoom / 2)
		var port_color = Color.RED if port_name == "in" else Color.GREEN
		draw_circle(port_pos, 4.0 * zoom, port_color)

func _draw_element_preview(element: Dictionary, cell: Vector2i) -> void:
	var elem_size = Vector2i(element.get("size", [1, 1])[0], element.get("size", [1, 1])[1])
	var full_rect = _get_element_rect(cell, elem_size)
	
	var icon = element.get("icon", "?")
	var font = ThemeDB.fallback_font
	var font_size = int(cell_size * zoom * 0.6)
	var text_pos = full_rect.get_center() - Vector2(font_size * 0.3, -font_size * 0.3)
	draw_string(font, text_pos, icon, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1, 1, 1, 0.7))

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
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var cell = _canvas_to_cell(mb.position)
			if not dragging_element.is_empty():
				_try_place_element(cell)
			else:
				_handle_click(cell)
			accept_event()
		
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			dragging_element = {}
			drag_preview_cell = Vector2i(-1, -1)
			queue_redraw()
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
		p_size = Vector2i(p_element.get("size", [1, 1])[0], p_element.get("size", [1, 1])[1])
	
	var r1 = Rect2i(cell, elem_size)
	var r2 = Rect2i(p_cell, p_size)
	return r1.intersects(r2)

func _handle_click(cell: Vector2i) -> void:
	# Check if clicking on existing element
	for placement in placements:
		var p_cell = Vector2i(placement.get("position", [0, 0])[0], placement.get("position", [0, 0])[1])
		var p_size = Vector2i(1, 1)
		if subset_loader:
			var p_element = subset_loader.get_element(placement.get("element", ""))
			p_size = Vector2i(p_element.get("size", [1, 1])[0], p_element.get("size", [1, 1])[1])
		
		if cell.x >= p_cell.x and cell.x < p_cell.x + p_size.x:
			if cell.y >= p_cell.y and cell.y < p_cell.y + p_size.y:
				selected_placements = [placement]
				element_selected.emit(placement)
				queue_redraw()
				return
	
	# Clear selection
	selected_placements.clear()
	selection_cleared.emit()
	queue_redraw()

func _try_place_element(cell: Vector2i) -> void:
	if dragging_element.is_empty():
		return
	
	var elem_size = Vector2i(dragging_element.get("size", [1, 1])[0], dragging_element.get("size", [1, 1])[1])
	if not _can_place_at(cell, elem_size):
		return
	
	var placement = {
		"id": "elem_%d" % (placements.size() + 1),
		"element": dragging_element.get("id", ""),
		"position": [cell.x, cell.y],
		"rotation": 0,
		"params": {}
	}
	
	placements.append(placement)
	element_placed.emit(placement)
	
	# Clear drag state (or keep for multi-place)
	dragging_element = {}
	drag_preview_cell = Vector2i(-1, -1)
	queue_redraw()

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
