extends Node3D

@export var iterations: int = 4  # Number of L-System iterations
@export var angle: float = 25.0  # Base angle for branching
@export var angle_variation: float = 10.0  # Random angular variation
@export var branch_length: float = 0.2  # Length of each branch segment
@export var thickness: float = 0.4  # Initial branch thickness
@export var thickness_reduction: float = 0.9  # Reduction factor for branch thickness
@export var sphere_scene: PackedScene  # PackedScene for sphere (branch nodes)
@export var flower_scene: PackedScene  # PackedScene for the flower at the top
@export var structure_radius: float = 1.0  # Overall structure size

var terminal_nodes = []  # Stores the end points for flower placement
var axiom = "A"
var rules = {
	"A": "F[+A][-A]{&A}",  # A expands into three branches (upwards & angled)
	"F": "FF"  # Each F grows further
}

var current_position: Vector3
var current_rotation: Basis
var stack = []
var lsystem_string = ""

func _ready():
	randomize()  # Ensure randomness each run
	generate_lsystem()
	generate_plant()

func generate_lsystem():
	""" Expands the axiom using defined rules for a given number of iterations. """
	lsystem_string = axiom
	for i in range(iterations):
		var new_string = ""
		for c in lsystem_string:
			new_string += rules.get(c, c)
		lsystem_string = new_string

func generate_plant():
	""" Constructs the L-system using cylinders (branches) and spheres (nodes). """
	current_position = Vector3.ZERO
	current_rotation = Basis.IDENTITY
	var current_thickness = thickness

	for c in lsystem_string:
		match c:
			"F":  # Draw forward
				var end_position = current_position + current_rotation * Vector3.UP * branch_length
				create_branch(current_position, end_position, current_thickness)
				
								# If it's a terminal branch, store its position
				if !lsystem_string.contains("F[") and !lsystem_string.contains("]"):
					terminal_nodes.append(end_position)
					
				current_position = end_position
				current_thickness *= thickness_reduction
			"+":  # Rotate positively with variation
				current_rotation = current_rotation.rotated(
					Vector3.FORWARD, 
					deg_to_rad(angle + randf_range(-angle_variation, angle_variation))
				)
			"-":  # Rotate negatively with variation
				current_rotation = current_rotation.rotated(
					Vector3.FORWARD, 
					deg_to_rad(-angle + randf_range(-angle_variation, angle_variation))
				)
			"{":  # Extra upwards branch (custom syntax)
				stack.push_back({
					"position": current_position,
					"rotation": current_rotation.rotated(
						Vector3.RIGHT, 
						deg_to_rad(30 + randf_range(-angle_variation, angle_variation))
					),
					"thickness": current_thickness * thickness_reduction
				})
			"&":  # Restore for upwards branch
				if stack.size() > 0:
					var state = stack.pop_back()
					current_position = state.position
					current_rotation = state.rotation
					current_thickness = state.thickness
			"[":  # Save state (for branching)
				stack.push_back({
					"position": current_position,
					"rotation": current_rotation,
					"thickness": current_thickness
				})
			"]":  # Restore state
				if stack.size() > 0:
					var state = stack.pop_back()
					current_position = state.position
					current_rotation = state.rotation
					current_thickness = state.thickness
			
func create_branch(start: Vector3, end: Vector3, branch_thickness: float):
	""" Creates a cylinder between two points representing a branch. """
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = branch_thickness * 0.7
	cylinder_mesh.bottom_radius = branch_thickness
	cylinder_mesh.height = start.distance_to(end)
	
	# Create cylinder node
	var cylinder = MeshInstance3D.new()
	cylinder.mesh = cylinder_mesh
	
	# Create material for the cylinder
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.44, 0.27, 0.13)  # Brownish color for branches
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.2
	cylinder.material_override = material

	# Position and rotate the cylinder correctly
	var mid_point = (start + end) * 0.5
	cylinder.position = mid_point
	
	var direction = (end - start).normalized()
	var rotation = Quaternion(Vector3(0, 1, 0), direction)
	cylinder.rotation = rotation.get_euler()
	
	add_child(cylinder)

	# Add sphere at each branching node
	if sphere_scene:
		var sphere = sphere_scene.instantiate() as Node3D
		sphere.global_transform.origin = end
		sphere.scale = Vector3(branch_thickness, branch_thickness, branch_thickness)
		add_child(sphere)

# 🌸 **Function to Place Flowers at Terminal Nodes**
func place_flowers():
	""" Places flowers at terminal branches. """
	if not flower_scene:
		print("⚠️ No flower scene assigned!")
		return
	
	for pos in terminal_nodes:
		var flower = flower_scene.instantiate() as Node3D
		flower.global_transform.origin = pos
		flower.scale *= randf_range(0.8, 1.2)  # Slight random scaling for variation
		flower.rotation_degrees = Vector3(randf_range(-10, 10), randf_range(-180, 180), randf_range(-10, 10))  # Random tilt
		
		add_child(flower)
		print("🌸 Placed flower at ", pos)
