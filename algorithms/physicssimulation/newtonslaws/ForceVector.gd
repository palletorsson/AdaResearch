extends Node3D
class_name ForceVector

@export var force_color: Color = Color.RED
@export var force_strength: float = 1.0
var arrow_mesh: MeshInstance3D
var force_direction: Vector3 = Vector3.UP

func _ready():
	create_force_arrow()

func create_force_arrow():
	# Create a box mesh for the arrow head (pyramid-like shape)
	var arrow_head_mesh = BoxMesh.new()
	arrow_head_mesh.size = Vector3(0.2, 0.3, 0.2)
	
	# Create a cylinder for the arrow shaft
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	
	cylinder.height = 1.0
	cylinder.radial_segments = 8
	
	# Create materials
	var cone_material = StandardMaterial3D.new()
	cone_material.albedo_color = force_color
	cone_material.emission_enabled = true
	cone_material.emission = force_color * 0.3
	
	var cylinder_material = StandardMaterial3D.new()
	cylinder_material.albedo_color = force_color
	cylinder_material.emission_enabled = true
	cylinder_material.emission = force_color * 0.2
	
	# Create arrow head
	var arrow_head = MeshInstance3D.new()
	arrow_head.mesh = arrow_head_mesh
	arrow_head.material_override = cone_material
	arrow_head.position = Vector3(0, 0.65, 0)
	arrow_head.scale = Vector3(1, 1, 1)
	add_child(arrow_head)
	
	# Create arrow shaft
	var arrow_shaft = MeshInstance3D.new()
	arrow_shaft.mesh = cylinder
	arrow_shaft.material_override = cylinder_material
	arrow_shaft.position = Vector3(0, 0.15, 0)
	add_child(arrow_shaft)
	
	# Store reference to the arrow
	arrow_mesh = arrow_head

func set_force_direction(direction: Vector3):
	force_direction = direction.normalized()
	look_at(global_position + force_direction, Vector3.UP)

func set_force_strength(strength: float):
	force_strength = strength
	scale = Vector3.ONE * (strength / 10.0)  # Scale based on force strength
