extends Node3D

@export var deformation_strength: float = 0.5
@export var grid_resolution: int = 8
@export var animation_speed: float = 2.0

var beam_mesh: CSGBox3D
var membrane_mesh: CSGBox3D
var sphere_mesh: CSGSphere3D

var beam_nodes: Array[Vector3] = []
var membrane_nodes: Array[Vector3] = []
var sphere_nodes: Array[Vector3] = []

var time: float = 0.0
var force_oscillation: float = 0.0

func _ready():
	beam_mesh = $DeformableObjects/Beam/BeamMesh
	membrane_mesh = $DeformableObjects/Membrane/MembraneMesh
	sphere_mesh = $DeformableObjects/Sphere/SphereMesh
	
	create_fem_grids()
	create_grid_visualization()

func create_fem_grids():
	# Create beam nodes (vertical grid)
	for i in range(grid_resolution + 1):
		var y = (i - grid_resolution / 2.0) * 2.0 / grid_resolution
		beam_nodes.append(Vector3(0, y, 0))
	
	# Create membrane nodes (2D grid)
	for i in range(grid_resolution + 1):
		for j in range(grid_resolution + 1):
			var x = (i - grid_resolution / 2.0) * 2.0 / grid_resolution
			var z = (j - grid_resolution / 2.0) * 2.0 / grid_resolution
			membrane_nodes.append(Vector3(x, 0, z))
	
	# Create sphere nodes (spherical grid)
	for i in range(grid_resolution + 1):
		for j in range(grid_resolution + 1):
			var phi = i * PI / grid_resolution
			var theta = j * 2 * PI / grid_resolution
			var r = 0.8
			var x = r * sin(phi) * cos(theta)
			var y = r * cos(phi)
			var z = r * sin(phi) * sin(theta)
			sphere_nodes.append(Vector3(x, y, z))

func create_grid_visualization():
	# Create beam grid lines
	for i in range(beam_nodes.size() - 1):
		var line = create_grid_line(Color.YELLOW, 0.02)
		line.position = (beam_nodes[i] + beam_nodes[i + 1]) / 2
		line.look_at(beam_nodes[i + 1])
		line.rotation.z += PI / 2
		$GridLines/BeamGrid.add_child(line)
	
	# Create membrane grid lines
	for i in range(grid_resolution):
		for j in range(grid_resolution):
			var idx1 = i * (grid_resolution + 1) + j
			var idx2 = (i + 1) * (grid_resolution + 1) + j
			var idx3 = i * (grid_resolution + 1) + j + 1
			
			# Horizontal line
			var h_line = create_grid_line(Color.CYAN, 0.01)
			h_line.position = (membrane_nodes[idx1] + membrane_nodes[idx3]) / 2
			h_line.look_at(membrane_nodes[idx3])
			h_line.rotation.z += PI / 2
			$GridLines/MembraneGrid.add_child(h_line)
			
			# Vertical line
			var v_line = create_grid_line(Color.CYAN, 0.01)
			v_line.position = (membrane_nodes[idx1] + membrane_nodes[idx2]) / 2
			v_line.look_at(membrane_nodes[idx2])
			v_line.rotation.z += PI / 2
			$GridLines/MembraneGrid.add_child(v_line)
	
	# Create sphere grid lines (simplified)
	for i in range(0, sphere_nodes.size, grid_resolution + 1):
		if i + grid_resolution < sphere_nodes.size:
			var line = create_grid_line(Color.MAGENTA, 0.01)
			line.position = (sphere_nodes[i] + sphere_nodes[i + grid_resolution]) / 2
			line.look_at(sphere_nodes[i + grid_resolution])
			line.rotation.z += PI / 2
			$GridLines/SphereGrid.add_child(line)

func create_grid_line(color: Color, thickness: float) -> CSGCylinder3D:
	var line = CSGCylinder3D.new()
	line.radius = thickness
	line.height = 0.1
	line.material = StandardMaterial3D.new()
	line.material.albedo_color = color
	line.material.emission_enabled = true
	line.material.emission = color
	line.material.emission_energy_multiplier = 0.3
	return line

func _process(delta):
	time += delta * animation_speed
	force_oscillation = sin(time) * 0.5 + 0.5
	
	# Apply FEM deformation to beam
	deform_beam()
	
	# Apply FEM deformation to membrane
	deform_membrane()
	
	# Apply FEM deformation to sphere
	deform_sphere()
	
	# Animate force points
	animate_force_points()

func deform_beam():
	var deformed_nodes = beam_nodes.duplicate()
	
	# Apply bending deformation (simple beam theory)
	for i in range(deformed_nodes.size()):
		var y = deformed_nodes[i].y
		var normalized_y = y / 1.0  # Normalize to -1 to 1
		
		# Simple quadratic deformation
		var deflection = force_oscillation * deformation_strength * (1.0 - normalized_y * normalized_y)
		deformed_nodes[i].x = deflection
	
	# Update beam mesh (simplified - just scale and rotate)
	var max_deflection = deformation_strength * force_oscillation
	beam_mesh.rotation.z = max_deflection * 0.5
	beam_mesh.scale.x = 1.0 + max_deflection * 0.2

func deform_membrane():
	var deformed_nodes = membrane_nodes.duplicate()
	
	# Apply membrane deformation (wave equation)
	for i in range(deformed_nodes.size()):
		var x = deformed_nodes[i].x
		var z = deformed_nodes[i].z
		var distance = sqrt(x * x + z * z)
		
		# Wave-like deformation
		var wave = sin(distance * 3.0 - time * 2.0) * force_oscillation * deformation_strength
		deformed_nodes[i].y = wave
	
	# Update membrane mesh (simplified)
	var wave_height = deformation_strength * force_oscillation
	membrane_mesh.scale.y = 1.0 + wave_height * 0.5

func deform_sphere():
	var deformed_nodes = sphere_nodes.duplicate()
	
	# Apply spherical deformation (radial waves)
	for i in range(deformed_nodes.size()):
		var original_pos = sphere_nodes[i]
		var radius = original_pos.length()
		
		# Radial wave deformation
		var radial_wave = sin(radius * 4.0 - time * 1.5) * force_oscillation * deformation_strength
		var new_radius = radius + radial_wave
		
		deformed_nodes[i] = original_pos.normalized() * new_radius
	
	# Update sphere mesh (simplified)
	var radial_deformation = deformation_strength * force_oscillation
	sphere_mesh.scale = Vector3.ONE * (1.0 + radial_deformation * 0.3)

func animate_force_points():
	# Animate force point positions
	var beam_force = $ForcePoints/BeamForce
	var membrane_force = $ForcePoints/MembraneForce
	var sphere_force = $ForcePoints/SphereForce
	
	# Oscillate force points
	beam_force.position.y = 1.5 + sin(time * 3.0) * 0.2
	membrane_force.position.y = 0.5 + cos(time * 2.0) * 0.1
	sphere_force.position.y = 0.8 + sin(time * 2.5) * 0.15
	
	# Scale force points based on force strength
	var force_scale = 0.1 + force_oscillation * 0.2
	beam_force.scale = Vector3.ONE * force_scale
	membrane_force.scale = Vector3.ONE * force_scale
	sphere_force.scale = Vector3.ONE * force_scale
