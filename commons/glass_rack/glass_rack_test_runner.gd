@tool
extends Node3D

## Glass Rack Test Runner
## Displays all segment types with port visualizations for alignment verification
## Run in editor by toggling 'run_tests' or just play the scene

@export var run_tests: bool = false:
	set(value):
		if value:
			_run_all_tests()
		run_tests = false

@export var show_port_visualization: bool = true
@export var segment_spacing: float = 0.6
@export var row_spacing: float = 0.8

var _test_root: Node3D
var _rack: GlassRackController

func _ready():
	_run_all_tests()

func _run_all_tests():
	# Clear previous tests
	if _test_root:
		_test_root.queue_free()
		await get_tree().process_frame
	
	_test_root = Node3D.new()
	_test_root.name = "TestResults"
	add_child(_test_root)
	
	# Create rack for segment generation
	_rack = GlassRackController.new()
	_rack.auto_build = false
	_rack.show_liquid = true
	_test_root.add_child(_rack)
	
	# Test segments organized by category
	var segment_rows = [
		# Row 1: Basic segments
		[
			{"type": "straight", "params": {"length": 0.3}, "label": "Straight"},
			{"type": "wobbly", "params": {"length": 0.4}, "label": "Wobbly"},
			{"type": "spiral", "params": {"height": 0.4}, "label": "Spiral"},
			{"type": "corner", "params": {"corner_radius": 0.15}, "label": "Corner 90°"},
			{"type": "corner45", "params": {"corner_radius": 0.1}, "label": "Corner 45°"},
		],
		# Row 2: Bends and transitions
		[
			{"type": "sbend", "params": {"length": 0.3, "offset": 0.1}, "label": "S-Bend"},
			{"type": "ubend", "params": {"bend_radius": 0.08}, "label": "U-Bend"},
			{"type": "reducer", "params": {"length": 0.1, "radius_in": 0.02, "radius_out": 0.012}, "label": "Reducer"},
			{"type": "condenser", "params": {"length": 0.3}, "label": "Condenser"},
		],
		# Row 3: Junctions
		[
			{"type": "junction", "params": {}, "label": "T-Junction"},
			{"type": "ypipe", "params": {"length": 0.2}, "label": "Y-Pipe"},
			{"type": "cross", "params": {"arm_length": 0.1}, "label": "Cross"},
		],
		# Row 4: Vessels and terminals
		[
			{"type": "flask", "params": {"radius": 0.05}, "label": "Flask"},
			{"type": "beaker", "params": {"radius": 0.035}, "label": "Beaker"},
			{"type": "cap", "params": {}, "label": "Cap"},
			{"type": "drip", "params": {}, "label": "Drip"},
		],
	]
	
	var total_segments = 0
	var valid_segments = 0
	
	for row_idx in range(segment_rows.size()):
		var row = segment_rows[row_idx]
		var z_pos = -row_idx * row_spacing
		
		for col_idx in range(row.size()):
			var seg_data = row[col_idx]
			var x_pos = col_idx * segment_spacing
			
			var segment = _rack._create_segment(seg_data.type, seg_data.params)
			if segment:
				segment.position = Vector3(x_pos, 0, z_pos)
				segment.name = seg_data.label.replace(" ", "_")
				_test_root.add_child(segment)
				
				# Add port visualization
				if show_port_visualization:
					_add_port_visualization(segment)
				
				# Add label
				var label = _create_label(seg_data.label)
				label.position = Vector3(x_pos, -0.12, z_pos)
				_test_root.add_child(label)
				
				# Validate and count
				total_segments += 1
				if _validate_segment_ports(segment, seg_data.label):
					valid_segments += 1
	
	print("═══════════════════════════════════════════")
	print("Glass Rack Test Complete: %d/%d segments valid" % [valid_segments, total_segments])
	print("═══════════════════════════════════════════")

func _add_port_visualization(segment: Node3D):
	var ports = GlassSegmentPorts.get_ports(segment)
	if ports.is_empty():
		return
	
	var viz_root = Node3D.new()
	viz_root.name = "PortViz"
	
	for port_name in ports.keys():
		var port = ports[port_name]
		var is_input = port_name == "in"
		
		# Sphere at port position
		var sphere = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = port.radius * 1.2
		sphere_mesh.height = port.radius * 2.4
		sphere.mesh = sphere_mesh
		
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(1, 0.2, 0.2, 0.6) if is_input else Color(0.2, 1, 0.2, 0.6)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 0.3
		sphere.material_override = mat
		
		sphere.position = port.position
		sphere.name = "Port_" + port_name
		viz_root.add_child(sphere)
		
		# Direction arrow
		var arrow = _create_arrow(port.direction, port.radius * 3, mat.albedo_color)
		arrow.position = port.position
		viz_root.add_child(arrow)
	
	segment.add_child(viz_root)

func _create_arrow(direction: Vector3, length: float, color: Color) -> MeshInstance3D:
	var arrow = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.002
	cylinder.bottom_radius = 0.004
	cylinder.height = length
	arrow.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	arrow.material_override = mat
	
	# Orient arrow along direction
	if direction.length() > 0.001:
		var up = Vector3.UP
		if abs(direction.dot(up)) > 0.99:
			up = Vector3.RIGHT
		arrow.look_at(arrow.global_position + direction, up)
		arrow.rotate_object_local(Vector3.RIGHT, PI / 2)
	
	arrow.position += direction * (length / 2)
	
	return arrow

func _validate_segment_ports(segment: Node3D, label: String) -> bool:
	var ports = GlassSegmentPorts.get_ports(segment)
	var valid = true
	
	if ports.is_empty():
		push_warning("⚠️ %s: No ports defined!" % label)
		return false
	
	# Check for required 'in' port
	if not ports.has("in"):
		push_warning("⚠️ %s: Missing 'in' port!" % label)
		valid = false
	
	# Check port structure
	for port_name in ports.keys():
		var port = ports[port_name]
		var issues = []
		
		if not port.has("position"):
			issues.append("missing position")
		if not port.has("direction"):
			issues.append("missing direction")
		if not port.has("radius"):
			issues.append("missing radius")
		elif port.radius <= 0:
			issues.append("invalid radius: %f" % port.radius)
		
		if not issues.is_empty():
			push_warning("⚠️ %s.%s: %s" % [label, port_name, ", ".join(issues)])
			valid = false
	
	# Check terminal consistency
	var is_terminal = GlassSegmentPorts.is_terminal(segment)
	var out_ports = GlassSegmentPorts.get_out_port_names(segment)
	
	if is_terminal and not out_ports.is_empty():
		push_warning("⚠️ %s: Marked terminal but has output ports: %s" % [label, out_ports])
		valid = false
	if not is_terminal and out_ports.is_empty():
		push_warning("⚠️ %s: Not terminal but has no output ports!" % label)
		valid = false
	
	if valid:
		print("✓ %s: %d ports OK" % [label, ports.size()])
	
	return valid

func _create_label(text: String) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = 0.001
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1, 1, 1, 0.9)
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.outline_size = 4
	return label
