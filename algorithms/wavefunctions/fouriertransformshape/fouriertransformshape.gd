# Main scene script - attach to a Node3D
extends Node3D

# Wheel configuration - frequency, radius, phase
var wheels = [
	{"freq": 1.0, "radius": 2.0, "phase": 0.0},
	{"freq": 3.0, "radius": 0.8, "phase": 0.0},
	{"freq": 5.0, "radius": 0.4, "phase": PI/2},
	{"freq": 7.0, "radius": 0.2, "phase": PI/4}
]

var wheel_nodes = []
var connection_lines = []
var trace_points = []
var trace_mesh_instance: MeshInstance3D
var time = 0.0
var trace_material: StandardMaterial3D

func _ready():
	setup_camera()
	setup_wheels()
	setup_trace()
	
func setup_camera():
	var camera = Camera3D.new()
	camera.position = Vector3(0, 3, 8)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	add_child(camera)

func setup_wheels():
	# Create materials
	var wheel_material = StandardMaterial3D.new()
	wheel_material.albedo_color = Color.CYAN
	wheel_material.emission_enabled = true
	wheel_material.emission = Color.CYAN * 0.2
	
	var connection_material = StandardMaterial3D.new()
	connection_material.albedo_color = Color.WHITE
	connection_material.emission_enabled = true
	connection_material.emission = Color.WHITE * 0.3
	
	var center_pos = Vector3.ZERO
	
	for i in range(wheels.size()):
		var wheel_data = wheels[i]
		
		# Create wheel (torus)
		var wheel_mesh = TorusMesh.new()
		wheel_mesh.inner_radius = wheel_data.radius * 0.8
		wheel_mesh.outer_radius = wheel_data.radius
		wheel_mesh.rings = 16
		wheel_mesh.ring_segments = 32
		
		var wheel_node = MeshInstance3D.new()
		wheel_node.mesh = wheel_mesh
		wheel_node.material_override = wheel_material
		wheel_node.position = center_pos
		add_child(wheel_node)
		wheel_nodes.append(wheel_node)
		
		# Create connection line to next wheel (or trace point for last wheel)
		var line_mesh = CylinderMesh.new()
		line_mesh.top_radius = 0.02
		line_mesh.bottom_radius = 0.02
		line_mesh.height = 1.0
		
		var line_node = MeshInstance3D.new()
		line_node.mesh = line_mesh
		line_node.material_override = connection_material
		add_child(line_node)
		connection_lines.append(line_node)

func setup_trace():
	trace_material = StandardMaterial3D.new()
	trace_material.albedo_color = Color.YELLOW
	trace_material.emission_enabled = true
	trace_material.emission = Color.YELLOW * 0.5
	trace_material.vertex_color_use_as_albedo = true
	
	trace_mesh_instance = MeshInstance3D.new()
	trace_mesh_instance.material_override = trace_material
	add_child(trace_mesh_instance)

func _process(delta):
	time += delta * 0.5  # Control animation speed
	
	update_wheels()
	update_trace()

func update_wheels():
	var current_pos = Vector3.ZERO
	
	for i in range(wheels.size()):
		var wheel_data = wheels[i]
		var wheel_node = wheel_nodes[i]
		var line_node = connection_lines[i]
		
		# Calculate wheel rotation
		var angle = time * wheel_data.freq + wheel_data.phase
		wheel_node.rotation.z = angle
		
		# Position wheel at current position
		wheel_node.position = current_pos
		
		# Calculate next position (end of this wheel's arm)
		var arm_end = current_pos + Vector3(
			cos(angle) * wheel_data.radius,
			sin(angle) * wheel_data.radius,
			0
		)
		
		# Update connection line
		var line_center = (current_pos + arm_end) / 2
		var line_direction = (arm_end - current_pos).normalized()
		var line_length = current_pos.distance_to(arm_end)
		
		line_node.position = line_center
		line_node.scale.y = line_length
		
		# Rotate line to point in correct direction
		if line_direction.length() > 0:
			var up = Vector3.UP
			if abs(line_direction.dot(up)) > 0.99:
				up = Vector3.RIGHT
			var right = line_direction.cross(up).normalized()
			up = right.cross(line_direction).normalized()
			line_node.basis = Basis(right, line_direction, up)
		
		current_pos = arm_end
	
	# Add current end position to trace
	if trace_points.size() < 1000:  # Limit trace length
		trace_points.append(current_pos)
	else:
		trace_points.pop_front()
		trace_points.append(current_pos)

func update_trace():
	if trace_points.size() < 2:
		return
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var colors = PackedColorArray()
	
	# Create trace line
	for i in range(trace_points.size()):
		vertices.append(trace_points[i])
		
		# Fade color based on age
		var alpha = float(i) / float(trace_points.size())
		var color = Color.YELLOW
		color.a = alpha * alpha  # Quadratic fade for better visual
		colors.append(color)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arrays)
	trace_mesh_instance.mesh = mesh

# Scene tree structure for reference:
# Main (Node3D) - attach this script
# ├── Camera3D
# ├── MeshInstance3D (Wheel 1)
# ├── MeshInstance3D (Connection Line 1)
# ├── MeshInstance3D (Wheel 2)
# ├── MeshInstance3D (Connection Line 2)
# ├── MeshInstance3D (Wheel 3)
# ├── MeshInstance3D (Connection Line 3)
# ├── MeshInstance3D (Wheel 4)
# ├── MeshInstance3D (Connection Line 4)
# └── MeshInstance3D (Trace)
