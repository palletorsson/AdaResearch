@tool
extends EditorNode3DGizmoPlugin
## Gizmo plugin that draws the grid overlay and cable connections for ElementLayoutNode.

var plugin  # Reference to ElementEditorPlugin

# Cable colors for different parameter types
const CABLE_COLORS = {
	"frequency": Color(0.2, 0.8, 1.0, 0.8),    # Cyan
	"amplitude": Color(0.2, 1.0, 0.4, 0.8),    # Green
	"duration": Color(1.0, 0.8, 0.2, 0.8),     # Yellow
	"cutoff": Color(1.0, 0.4, 0.2, 0.8),       # Orange
	"resonance": Color(1.0, 0.2, 0.6, 0.8),    # Pink
	"attack": Color(0.6, 0.2, 1.0, 0.8),       # Purple
	"release": Color(0.4, 0.4, 1.0, 0.8),      # Blue
	"default": Color(0.7, 0.7, 0.7, 0.6),      # Gray
}

# Port offsets (relative to element center)
const OUTPUT_PORT_OFFSET = Vector3(0.02, 0, 0.02)   # Right side
const INPUT_PORT_OFFSET = Vector3(-0.02, 0, 0.02)   # Left side


func _init():
	create_material("grid", Color(0.4, 0.6, 1.0, 0.3))
	create_material("grid_lines", Color(0.4, 0.6, 1.0, 0.5))
	create_material("axis_x", Color(1, 0.2, 0.2, 0.8))
	create_material("axis_y", Color(0.2, 1, 0.2, 0.8))
	
	# Create cable materials
	for param in CABLE_COLORS:
		var color = CABLE_COLORS[param]
		create_material("cable_" + param, color)
	
	# Port materials
	create_material("port_output", Color(0.2, 0.9, 0.4, 0.9))  # Green dot
	create_material("port_input", Color(0.9, 0.4, 0.2, 0.9))   # Orange dot


func _get_gizmo_name() -> String:
	return "ElementLayoutGizmo"


func _has_gizmo(node: Node3D) -> bool:
	return node is ElementLayoutNode


func _redraw(gizmo: EditorNode3DGizmo):
	gizmo.clear()
	
	var node = gizmo.get_node_3d() as ElementLayoutNode
	if not node:
		return
	
	# Ensure subset data is loaded (needed for cable drawing)
	if node._subset_data == null:
		node._subset_data = ElementSubsetData.new()
		node._subset_data.load_all()
	
	# Draw grid if enabled
	if node.show_grid:
		_draw_grid(gizmo, node)
	
	# Draw cables between connected elements (check show_cables property)
	var show_cables = node.get("show_cables") if node.get("show_cables") != null else true
	if show_cables:
		_draw_cables(gizmo, node)
		_draw_ports(gizmo, node)


func _draw_grid(gizmo: EditorNode3DGizmo, node: ElementLayoutNode):
	var grid_size = node.grid_size
	var width = node.grid_width
	var height = node.grid_height
	var plane = node.orientation_plane
	
	# Draw grid lines
	var lines = PackedVector3Array()
	
	match plane:
		"XY":
			# Vertical lines
			for x in range(width + 1):
				var px = x * grid_size
				lines.append(Vector3(px, 0, 0))
				lines.append(Vector3(px, height * grid_size, 0))
			# Horizontal lines
			for y in range(height + 1):
				var py = y * grid_size
				lines.append(Vector3(0, py, 0))
				lines.append(Vector3(width * grid_size, py, 0))
		
		"YZ":
			# Vertical lines (Y axis)
			for z in range(width + 1):
				var pz = z * grid_size
				lines.append(Vector3(0, 0, pz))
				lines.append(Vector3(0, height * grid_size, pz))
			# Horizontal lines (Z axis)
			for y in range(height + 1):
				var py = y * grid_size
				lines.append(Vector3(0, py, 0))
				lines.append(Vector3(0, py, width * grid_size))
		
		"XZ":
			# Lines along X
			for z in range(height + 1):
				var pz = z * grid_size
				lines.append(Vector3(0, 0, pz))
				lines.append(Vector3(width * grid_size, 0, pz))
			# Lines along Z
			for x in range(width + 1):
				var px = x * grid_size
				lines.append(Vector3(px, 0, 0))
				lines.append(Vector3(px, 0, height * grid_size))
	
	if lines.size() > 0:
		gizmo.add_lines(lines, get_material("grid_lines", gizmo), false)
	
	# Draw origin axes
	var axis_lines = PackedVector3Array()
	var axis_length = grid_size * 2
	
	match plane:
		"XY":
			axis_lines.append(Vector3.ZERO)
			axis_lines.append(Vector3(axis_length, 0, 0))
		"YZ":
			axis_lines.append(Vector3.ZERO)
			axis_lines.append(Vector3(0, 0, axis_length))
		"XZ":
			axis_lines.append(Vector3.ZERO)
			axis_lines.append(Vector3(axis_length, 0, 0))
	
	gizmo.add_lines(axis_lines, get_material("axis_x", gizmo), false)
	
	# Y axis (green) - always up
	var y_axis = PackedVector3Array()
	match plane:
		"XY", "YZ":
			y_axis.append(Vector3.ZERO)
			y_axis.append(Vector3(0, axis_length, 0))
		"XZ":
			y_axis.append(Vector3.ZERO)
			y_axis.append(Vector3(0, 0, axis_length))
	
	gizmo.add_lines(y_axis, get_material("axis_y", gizmo), false)


func _draw_cables(gizmo: EditorNode3DGizmo, node: ElementLayoutNode):
	"""Draw cables between elements that share parameters."""
	if not node._subset_data:
		return
	
	var subset_id = node.subset_id
	if subset_id.is_empty():
		return
	
	# Build parameter connection map
	# { param_name: { "outputs": [positions], "inputs": [positions] } }
	var param_connections = {}
	
	for placement in node.placements:
		var elem_id = placement.get("id", "")
		var grid_pos = placement.get("grid_pos", Vector3i.ZERO)
		var rotation = placement.get("rotation", 0)
		
		var element = node._subset_data.get_element(subset_id, elem_id)
		if element.is_empty():
			continue
		
		var elem_size = element.get("size", [1, 1])
		var effective_rotation = rotation
		if node.has_method("get_effective_grid_rotation"):
			effective_rotation = node.get_effective_grid_rotation(element, rotation)
		var world_pos = node.grid_to_world(grid_pos, elem_size, effective_rotation)
		
		# Check for control (output)
		if element.has("control"):
			var param = element["control"].get("parameter", "")
			if param != "":
				if not param_connections.has(param):
					param_connections[param] = { "outputs": [], "inputs": [] }
				param_connections[param]["outputs"].append(world_pos)
		
		# Check for display (input)
		if element.has("display"):
			var display = element["display"]
			for binding_key in ["freq_param", "amp_param"]:
				var param = display.get(binding_key, "")
				if param != "":
					if not param_connections.has(param):
						param_connections[param] = { "outputs": [], "inputs": [] }
					param_connections[param]["inputs"].append(world_pos)
	
	# Draw cables for each parameter
	for param in param_connections:
		var connections = param_connections[param]
		var outputs = connections["outputs"]
		var inputs = connections["inputs"]
		
		if outputs.is_empty() or inputs.is_empty():
			continue
		
		# Get material for this parameter
		var mat_name = "cable_" + param if CABLE_COLORS.has(param) else "cable_default"
		var material = get_material(mat_name, gizmo)
		
		# Draw cables from each output to each input
		for out_pos in outputs:
			for in_pos in inputs:
				var cable_lines = _generate_cable_curve(out_pos, in_pos, node.orientation_plane)
				gizmo.add_lines(cable_lines, material, false)


func _generate_cable_curve(from: Vector3, to: Vector3, plane: String) -> PackedVector3Array:
	"""Generate a curved cable between two points (bezier-style)."""
	var lines = PackedVector3Array()
	var segments = 12
	
	# Calculate control points for a nice droop
	var mid = (from + to) / 2.0
	var distance = from.distance_to(to)
	var droop = distance * 0.3  # Cable sag
	
	# Droop direction based on plane
	var droop_dir = Vector3.ZERO
	match plane:
		"XY":
			droop_dir = Vector3(0, -1, 0.1)  # Droop down and forward
		"YZ":
			droop_dir = Vector3(0.1, -1, 0)
		"XZ":
			droop_dir = Vector3(0, 0.1, 0)  # Slight lift for top-down
	
	var control = mid + droop_dir * droop
	
	# Generate bezier curve points
	var prev_point = from
	for i in range(1, segments + 1):
		var t = float(i) / float(segments)
		var point = _bezier_point(from, control, to, t)
		lines.append(prev_point)
		lines.append(point)
		prev_point = point
	
	return lines


func _bezier_point(p0: Vector3, p1: Vector3, p2: Vector3, t: float) -> Vector3:
	"""Quadratic bezier curve point."""
	var u = 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2


func _draw_ports(gizmo: EditorNode3DGizmo, node: ElementLayoutNode):
	"""Draw connection port indicators on elements."""
	if not node._subset_data:
		return
	
	var subset_id = node.subset_id
	if subset_id.is_empty():
		return
	
	var output_positions = PackedVector3Array()
	var input_positions = PackedVector3Array()
	
	for placement in node.placements:
		var elem_id = placement.get("id", "")
		var grid_pos = placement.get("grid_pos", Vector3i.ZERO)
		var rotation = placement.get("rotation", 0)
		
		var element = node._subset_data.get_element(subset_id, elem_id)
		if element.is_empty():
			continue
		
		var elem_size = element.get("size", [1, 1])
		var effective_rotation = rotation
		if node.has_method("get_effective_grid_rotation"):
			effective_rotation = node.get_effective_grid_rotation(element, rotation)
		var world_pos = node.grid_to_world(grid_pos, elem_size, effective_rotation)
		
		# Add output port for controls
		if element.has("control") and element["control"].get("parameter", "") != "":
			var port_pos = world_pos + _get_port_offset("output", node.orientation_plane, elem_size, node.grid_size)
			output_positions.append(port_pos)
		
		# Add input ports for displays
		if element.has("display"):
			var display = element["display"]
			var has_binding = display.has("freq_param") or display.has("amp_param")
			if has_binding:
				var port_pos = world_pos + _get_port_offset("input", node.orientation_plane, elem_size, node.grid_size)
				input_positions.append(port_pos)
	
	# Draw port dots as small crosses (gizmos don't support spheres well)
	if output_positions.size() > 0:
		var out_lines = _positions_to_crosses(output_positions, 0.015, node.orientation_plane)
		gizmo.add_lines(out_lines, get_material("port_output", gizmo), false)
	
	if input_positions.size() > 0:
		var in_lines = _positions_to_crosses(input_positions, 0.015, node.orientation_plane)
		gizmo.add_lines(in_lines, get_material("port_input", gizmo), false)


func _get_port_offset(port_type: String, plane: String, elem_size: Array, grid_size: float) -> Vector3:
	"""Get port position offset based on element size and plane."""
	var half_w = elem_size[0] * grid_size / 2.0 if elem_size.size() > 0 else grid_size / 2.0
	var half_h = elem_size[1] * grid_size / 2.0 if elem_size.size() > 1 else grid_size / 2.0
	
	var sign = 1.0 if port_type == "output" else -1.0
	
	match plane:
		"XY":
			return Vector3(sign * half_w, 0, 0.02)
		"YZ":
			return Vector3(0.02, 0, sign * half_w)
		"XZ":
			return Vector3(sign * half_w, 0.02, 0)
	
	return Vector3.ZERO


func _positions_to_crosses(positions: PackedVector3Array, size: float, plane: String) -> PackedVector3Array:
	"""Convert positions to cross markers for visibility."""
	var lines = PackedVector3Array()
	
	for pos in positions:
		match plane:
			"XY":
				lines.append(pos + Vector3(-size, 0, 0))
				lines.append(pos + Vector3(size, 0, 0))
				lines.append(pos + Vector3(0, -size, 0))
				lines.append(pos + Vector3(0, size, 0))
			"YZ":
				lines.append(pos + Vector3(0, -size, 0))
				lines.append(pos + Vector3(0, size, 0))
				lines.append(pos + Vector3(0, 0, -size))
				lines.append(pos + Vector3(0, 0, size))
			"XZ":
				lines.append(pos + Vector3(-size, 0, 0))
				lines.append(pos + Vector3(size, 0, 0))
				lines.append(pos + Vector3(0, 0, -size))
				lines.append(pos + Vector3(0, 0, size))
	
	return lines


func _get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> String:
	return "Grid"


func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> Variant:
	return null


func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2):
	pass


func _commit_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, restore: Variant, cancel: bool):
	pass
