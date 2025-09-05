# DiamondTorusCollection.gd - Thin cylinders with diamonds hanging from a torus
@tool
extends Node3D

# Torus and diamond parameters
@export var torus_radius: float = 2.0        # 2 meters from center to torus
@export var cylinder_length: float = 1.0     # 1 meter long cylinders
@export var cylinder_radius: float = 0.01    # Thin cylinders
@export var diamond_count: int = 7           # Number of diamonds around the torus
@export var diamond_scale: float = 0.5       # Scale factor for diamonds
@export var show_torus_wireframe: bool = true # Show the torus wireframe for reference

# Diamond scene path
const DIAMOND_SCENE_PATH = "res://commons/primitives/octahedron/octahedron.tscn"

# Collections
var cylinders: Array[MeshInstance3D] = []
var diamonds: Array[Node3D] = []
var torus_mesh: MeshInstance3D

# Colors
var cylinder_color = Color(0.7, 0.7, 0.7)  # Gray cylinders
var diamond_colors = [
	Color(0.9, 0.0, 0.0),    # Red
	Color(1.0, 0.5, 0.0),    # Orange
	Color(1.0, 1.0, 0.0),    # Yellow
	Color(0.0, 0.8, 0.0),    # Green
	Color(0.0, 0.4, 1.0),    # Blue
	Color(0.6, 0.0, 0.8),    # Purple
	Color(1.0, 0.0, 1.0)     # Magenta
]

func _ready():
	create_torus_reference()
	create_hanging_arrangement()

func create_torus_reference():
	"""Create a wireframe torus for reference"""
	if not show_torus_wireframe:
		return
		
	torus_mesh = MeshInstance3D.new()
	torus_mesh.name = "TorusReference"
	
	# Create torus mesh
	var torus = TorusMesh.new()
	torus.inner_radius = torus_radius - 0.1
	torus.outer_radius = torus_radius + 0.1
	torus.rings = diamond_count * 2
	torus.ring_segments = 8
	
	torus_mesh.mesh = torus
	
	# Create wireframe material
	var material = StandardMaterial3D.new()
	material.flags_wireframe = true
	material.albedo_color = Color(0.4, 0.4, 0.4, 0.6)
	material.flags_transparent = true
	torus_mesh.material_override = material
	
	add_child(torus_mesh)

func create_hanging_arrangement():
	"""Create cylinders pointing downward from torus with diamonds hanging below"""
	
	# Load diamond scene
	var diamond_scene = load(DIAMOND_SCENE_PATH)
	if not diamond_scene:
		print("DiamondTorusCollection: Could not load diamond scene at: ", DIAMOND_SCENE_PATH)
		return
	
	for i in range(diamond_count):
		# Calculate angle around the torus
		var angle = (i / float(diamond_count)) * 2.0 * PI
		
		# Position on the torus (at specified radius from center)
		var torus_position = Vector3(
			cos(angle) * torus_radius,
			0,  # Torus at Y = 0
			sin(angle) * torus_radius
		)
		
		# Create cylinder hanging downward from torus
		var cylinder = create_hanging_cylinder(torus_position)
		cylinders.append(cylinder)
		add_child(cylinder)
		
		# Calculate diamond position (hanging below the torus)
		var diamond_position = Vector3(
			cos(angle) * torus_radius,
			-cylinder_length,  # Hanging down by cylinder length
			sin(angle) * torus_radius
		)
		
		# Create diamond at the bottom of cylinder
		var diamond = diamond_scene.instantiate()
		if diamond:
			diamond.position = diamond_position
			
			# Orient diamond pointing upward toward the cylinder
			diamond.look_at(torus_position, Vector3.UP)
			
			# Apply scale
			diamond.scale = Vector3.ONE * diamond_scale
			
			
			diamond.name = "Diamond_%d" % i
			diamonds.append(diamond)
			add_child(diamond)
	
	print("DiamondTorusCollection: Created %d cylinders and diamonds" % diamond_count)

func create_hanging_cylinder(torus_position: Vector3) -> MeshInstance3D:
	"""Create a thin cylinder hanging downward from the torus"""
	
	var cylinder = MeshInstance3D.new()
	cylinder.name = "Cylinder_%d" % cylinders.size()
	
	# Create cylinder mesh
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = cylinder_length
	cylinder_mesh.top_radius = cylinder_radius
	cylinder_mesh.bottom_radius = cylinder_radius
	cylinder_mesh.radial_segments = 8
	
	cylinder.mesh = cylinder_mesh
	
	# Position cylinder at center point between torus and diamond (hanging down)
	var center_position = Vector3(
		torus_position.x,
		-cylinder_length * 0.5,  # Halfway down from torus
		torus_position.z
	)
	cylinder.position = center_position
	
	# Cylinder already points up-down by default, so no rotation needed

	
	return cylinder

# Public methods for external control

func set_diamond_count(count: int):
	"""Change the number of diamonds and recreate arrangement"""
	diamond_count = count
	clear_arrangement()
	create_hanging_arrangement()

func set_torus_radius(radius: float):
	"""Change torus radius and recreate arrangement"""
	torus_radius = radius
	clear_arrangement()
	create_hanging_arrangement()
	
	# Update torus reference if it exists
	if torus_mesh:
		var torus = torus_mesh.mesh as TorusMesh
		if torus:
			torus.inner_radius = torus_radius - 0.1
			torus.outer_radius = torus_radius + 0.1

func set_cylinder_length(length: float):
	"""Change cylinder length and recreate arrangement"""
	cylinder_length = length
	clear_arrangement()
	create_hanging_arrangement()

func clear_arrangement():
	"""Remove all cylinders and diamonds from scene"""
	for cylinder in cylinders:
		if is_instance_valid(cylinder):
			cylinder.queue_free()
	for diamond in diamonds:
		if is_instance_valid(diamond):
			diamond.queue_free()
	
	cylinders.clear()
	diamonds.clear()

func toggle_torus_wireframe():
	"""Show/hide the reference torus wireframe"""
	show_torus_wireframe = !show_torus_wireframe
	if torus_mesh:
		torus_mesh.visible = show_torus_wireframe

func set_diamond_colors_custom(colors: Array[Color]):
	"""Apply custom colors to diamonds"""
	for i in range(diamonds.size()):
		var diamond = diamonds[i]
		if diamond and diamond.has_method("set_base_color") and i < colors.size():
			diamond.set_base_color(colors[i])

func set_cylinder_color(color: Color):
	"""Change the color of all cylinders"""
	cylinder_color = color
	for cylinder in cylinders:
		if is_instance_valid(cylinder) and cylinder.material_override:
			var material = cylinder.material_override as StandardMaterial3D
			material.albedo_color = color

# Debug information
func get_arrangement_info() -> Dictionary:
	return {
		"diamond_count": diamonds.size(),
		"cylinder_count": cylinders.size(),
		"torus_radius": torus_radius,
		"cylinder_length": cylinder_length,
		"diamonds_height": -cylinder_length
	}
