extends Node3D

## AXIOM 0: The origin (0, 0, 0) is the reference point
## from which all positions are measured.

# The origin - the center of our 3D universe
var origin = Vector3(0, 0, 0)

func _ready():
	print("The center of our 3D universe: ", origin)

	# Create a visual representation of the origin
	create_origin_marker()


func create_origin_marker():
	"""Create a small sphere to mark the origin point"""
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.05
	sphere_mesh.height = 0.1

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = sphere_mesh
	mesh_instance.position = origin  # At (0, 0, 0)

	# Make it a bright color so it stands out
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	material.emission_enabled = true
	material.emission = Color.YELLOW
	material.emission_energy = 2.0
	mesh_instance.set_surface_override_material(0, material)

	add_child(mesh_instance)

	# Add a label
	var label = Label3D.new()
	label.text = "ORIGIN (0,0,0)"
	label.position = Vector3(0, 0.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	label.modulate = Color.YELLOW
	add_child(label)
