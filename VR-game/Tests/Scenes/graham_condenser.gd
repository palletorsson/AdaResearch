extends Node3D

# Script to generate Graham condensers (laboratory glassware) in Godot 4
# This creates the spiral tube condenser with side arms shown in the images

class_name GrahamCondenser

# Parameters for condenser customization
@export var condenser_height: float = 1.0
@export var condenser_radius: float = 0.05
@export var tube_radius: float = 0.008
@export var spiral_loops: int = 12
@export var spiral_radius: float = 0.03
@export var spiral_pitch: float = 0.06
@export var has_bulges: bool = false  # Image 1 has straight tube, Image 2 has bulges
@export var side_arm_angle: float = 110.0  # Degrees
@export var joint_type: String = "standard"  # "standard" or "custom"

# Material properties
@export var glass_transparency: float = 0.9
@export var glass_roughness: float = 0.05
@export var glass_ior: float = 1.45  # Index of refraction

# Internal variables
var _glass_material: ShaderMaterial
var _main_mesh_instance: MeshInstance3D
var _spiral_mesh_instance: MeshInstance3D
var _side_arms: Array[MeshInstance3D] = []
var _joints: Array[MeshInstance3D] = []

func _ready():
	create_materials()
	create_condenser()

# In your GrahamCondenser or AdvancedGrahamCondenser class
func create_materials():
	# Instead of creating a StandardMaterial3D
	_glass_material = ShaderMaterial.new()

	# Load and assign the shader
	var shader = load( "res://adaresearch/Tests/Scenes/glass2.gdshader")
	_glass_material.shader = shader

	# Set the shader parameters
	_glass_material.set_shader_parameter("glass_color", Color(1.0, 1.0, 1.0, 0.1))
	_glass_material.set_shader_parameter("glass_roughness", 0.05)
	_glass_material.set_shader_parameter("refraction_scale", 0.1)
	_glass_material.set_shader_parameter("ior", 1.45)
	_glass_material.set_shader_parameter("fresnel_power", 2.0)
	_glass_material.set_shader_parameter("edge_tint", 0.2)
	_glass_material.set_shader_parameter("thickness", 0.1)
	
func create_condenser():
	# Create the main tube (outer glass)
	create_main_tube()
	
	# Create the spiral inner tube
	create_spiral_tube()
	
	# Create side arms
	create_side_arms()
	
	# Create the ground glass joints at top and bottom
	create_joints()

func create_main_tube():
	# The main cylindrical tube with optional bulges as in image 2
	var main_mesh: CylinderMesh
	
	if has_bulges:
		# For Image 2 style with bulges
		main_mesh = create_bulged_cylinder_mesh()
	else:
		# For Image 1 style (straight cylinder)
		main_mesh = CylinderMesh.new()
		main_mesh.top_radius = condenser_radius
		main_mesh.bottom_radius = condenser_radius
		main_mesh.height = condenser_height
		main_mesh.radial_segments = 24
		main_mesh.rings = 1
	
	_main_mesh_instance = MeshInstance3D.new()
	_main_mesh_instance.mesh = main_mesh
	_main_mesh_instance.material_override = _glass_material
	_main_mesh_instance.name = "CondenserOuter"
	add_child(_main_mesh_instance)

func create_bulged_cylinder_mesh() -> CylinderMesh:
	# For now we'll use a simple cylinder - in a real implementation
	# you'd create a custom mesh with bulges using SurfaceTool
	# This is a placeholder for demonstration
	var mesh = CylinderMesh.new()
	mesh.top_radius = condenser_radius
	mesh.bottom_radius = condenser_radius
	mesh.height = condenser_height
	mesh.radial_segments = 24
	mesh.rings = 8  # More rings for potential deformation
	
	# Note: To properly create bulges, you would need to use SurfaceTool
	# to generate a custom mesh with vertex displacement
	
	return mesh

func create_spiral_tube():
	# Create the inner spiral tube
	var spiral_points = generate_spiral_points()
	var spiral_mesh = create_tube_from_points(spiral_points, tube_radius)
	
	_spiral_mesh_instance = MeshInstance3D.new()
	_spiral_mesh_instance.mesh = spiral_mesh
	_spiral_mesh_instance.material_override = _glass_material
	_spiral_mesh_instance.name = "CondenserSpiral"
	add_child(_spiral_mesh_instance)

func generate_spiral_points() -> PackedVector3Array:
	var points = PackedVector3Array()
	var segments_per_loop = 16
	var total_points = spiral_loops * segments_per_loop
	
	# Start at the top
	var start_y = condenser_height / 2 - 0.1
	var end_y = -condenser_height / 2 + 0.1
	
	for i in range(total_points + 1):
		var fraction = float(i) / float(total_points)
		var angle = fraction * spiral_loops * 2.0 * PI
		var y = start_y - fraction * (start_y - end_y)
		
		var x = spiral_radius * cos(angle)
		var z = spiral_radius * sin(angle)
		
		points.append(Vector3(x, y, z))
	
	return points

func create_tube_from_points(points: PackedVector3Array, tube_radius: float) -> Mesh:
	# This is a placeholder for demonstration
	# In a real implementation, you would use SurfaceTool to create
	# a tube mesh along the path defined by points
	
	# For now, we'll create a simple path visualizer with spheres
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var prev_point = points[0]
	for i in range(1, points.size()):
		var point = points[i]
		add_tube_segment(st, prev_point, point, tube_radius)
		prev_point = point
	
	st.index()
	return st.commit()

func add_tube_segment(st: SurfaceTool, start: Vector3, end: Vector3, radius: float):
	# Direction vector
	var direction = end - start
	var length = direction.length()
	direction = direction.normalized()
	
	# Find perpendicular vectors
	var perpendicular: Vector3
	if abs(direction.x) < 0.5:
		perpendicular = Vector3(1, 0, 0).cross(direction).normalized()
	else:
		perpendicular = Vector3(0, 1, 0).cross(direction).normalized()
	
	var perpendicular2 = direction.cross(perpendicular).normalized()
	
	# Number of sides for the tube
	var sides = 8
	
	# Create vertices around both ends
	var start_verts = []
	var end_verts = []
	
	for i in range(sides):
		var angle = 2.0 * PI * i / sides
		var offset = perpendicular * cos(angle) * radius + perpendicular2 * sin(angle) * radius
		
		start_verts.append(start + offset)
		end_verts.append(end + offset)
	
	# Create triangles
	for i in range(sides):
		var i_next = (i + 1) % sides
		
		# First triangle of quad
		st.add_vertex(start_verts[i])
		st.add_vertex(end_verts[i])
		st.add_vertex(start_verts[i_next])
		
		# Second triangle of quad
		st.add_vertex(start_verts[i_next])
		st.add_vertex(end_verts[i])
		st.add_vertex(end_verts[i_next])

func create_side_arms():
	# Create two side arms (inlet/outlet tubes)
	var side_arm_positions = [
		Vector3(0, condenser_height * 0.35, 0),
		Vector3(0, -condenser_height * 0.35, 0)
	]
	
	var side_arm_length = condenser_radius * 3
	
	for pos in side_arm_positions:
		var arm = create_side_arm(pos, side_arm_length)
		_side_arms.append(arm)
		add_child(arm)

func create_side_arm(position: Vector3, length: float) -> MeshInstance3D:
	# Create a side arm (bent tube) for water inlet/outlet
	var arm_mesh = CylinderMesh.new()
	arm_mesh.top_radius = tube_radius * 1.5
	arm_mesh.bottom_radius = tube_radius * 1.5
	arm_mesh.height = length
	
	var arm_instance = MeshInstance3D.new()
	arm_instance.mesh = arm_mesh
	arm_instance.material_override = _glass_material
	
	# Position and rotate the arm
	arm_instance.position = position
	arm_instance.rotation_degrees = Vector3(0, 0, side_arm_angle - 90) # Angle from vertical
	arm_instance.position += arm_instance.transform.basis.x * condenser_radius
	
	return arm_instance

func create_joints():
	# Create ground glass joints at top and bottom
	var joint_positions = [
		Vector3(0, condenser_height / 2, 0),
		Vector3(0, -condenser_height / 2, 0)
	]
	
	for pos in joint_positions:
		var joint = create_ground_glass_joint(pos)
		_joints.append(joint)
		add_child(joint)

func create_ground_glass_joint(position: Vector3) -> MeshInstance3D:
	# Create a standard ground glass joint
	var joint_length = condenser_radius * 2
	var joint_taper = 0.2  # How much the radius reduces
	
	var joint_mesh = CylinderMesh.new()
	
	if position.y > 0:
		# Top joint
		joint_mesh.top_radius = condenser_radius * (1 - joint_taper)
		joint_mesh.bottom_radius = condenser_radius
		joint_mesh.height = joint_length
		
		var joint_instance = MeshInstance3D.new()
		joint_instance.mesh = joint_mesh
		joint_instance.material_override = _glass_material
		joint_instance.position = position + Vector3(0, joint_length / 2, 0)
		
		return joint_instance
	else:
		# Bottom joint
		joint_mesh.top_radius = condenser_radius
		joint_mesh.bottom_radius = condenser_radius * (1 - joint_taper)
		joint_mesh.height = joint_length
		
		var joint_instance = MeshInstance3D.new()
		joint_instance.mesh = joint_mesh
		joint_instance.material_override = _glass_material
		joint_instance.position = position - Vector3(0, joint_length / 2, 0)
		
		return joint_instance
