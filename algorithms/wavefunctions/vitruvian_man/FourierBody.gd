extends Node3D

# Le Corbusier Palette
const COLOR_PALETTE = [
	Color(0.2, 0.2, 0.2), # Dark Grey / Black
	Color(0.8, 0.2, 0.2), # Red
	Color(0.2, 0.2, 0.8), # Blue
	Color(0.9, 0.9, 0.2), # Yellow
	Color(0.9, 0.9, 0.9)  # White/Concrete
]

var wheels = [] # Array of {freq, radius, phase}
var wheel_nodes = []
var connection_lines = []
var trace_points = []
var trace_line: Line3D
var time = 0.0
var trace_material: StandardMaterial3D
var show_rings: bool = false # Hidden by default as requested

func _ready() -> void:
	setup_trace()

func configure(descriptors: Array) -> void:
	# Clear existing
	for node in wheel_nodes:
		node.queue_free()
	for node in connection_lines:
		node.queue_free()
	wheel_nodes.clear()
	connection_lines.clear()
	wheels = descriptors
	setup_wheels()

func setup_wheels() -> void:
	# Materials
	var connection_material = StandardMaterial3D.new()
	connection_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	connection_material.albedo_color = COLOR_PALETTE[0] # Dark lines
	
	var center_pos = Vector3.ZERO

	for i in range(wheels.size()):
		var wheel_data = wheels[i]
		
		# Create wheel (optional, for debug or if user changes mind)
		var wheel_node = Node3D.new() # Dummy node if hidden
		if show_rings:
			var wheel_mesh = TorusMesh.new()
			wheel_mesh.inner_radius = wheel_data.radius * 0.98
			wheel_mesh.outer_radius = wheel_data.radius
			wheel_mesh.rings = 32
			wheel_mesh.ring_segments = 4
			
			var mesh_instance = MeshInstance3D.new()
			mesh_instance.mesh = wheel_mesh
			var mat = StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = COLOR_PALETTE[4]
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.2
			mesh_instance.material_override = mat
			wheel_node.add_child(mesh_instance)
			
		wheel_node.position = center_pos
		add_child(wheel_node)
		wheel_nodes.append(wheel_node)

		# Create connection line (Armature)
		var line_mesh = CylinderMesh.new()
		line_mesh.top_radius = 0.005 # Very thin, precise lines
		line_mesh.bottom_radius = 0.005
		line_mesh.height = 1.0
		
		var line_node = MeshInstance3D.new()
		line_node.mesh = line_mesh
		line_node.material_override = connection_material
		add_child(line_node)
		connection_lines.append(line_node)

var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D

func setup_trace() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.name = "FourierTrail"
	_trail_instance.mesh = _trail_mesh
	
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = COLOR_PALETTE[1]
	material.emission_enabled = true
	material.emission = COLOR_PALETTE[1]
	material.emission_energy_multiplier = 1.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	_trail_instance.material_override = material
	
	add_child(_trail_instance)

func update_trace() -> void:
	_trail_mesh.clear_surfaces()
	if trace_points.size() < 2:
		return
		
	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	var point_count = trace_points.size()
	for i in range(point_count):
		# Fade out older points
		# 0 is oldest, point_count-1 is newest
		var alpha = float(i) / float(point_count)
		# Make the fade curve a bit steeper
		alpha = pow(alpha, 2.0)
		
		var color = COLOR_PALETTE[1]
		color.a = alpha
		
		_trail_mesh.surface_set_color(color)
		_trail_mesh.surface_add_vertex(trace_points[i])
		
	_trail_mesh.surface_end()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
