# TorusCylinder.gd
extends Node3D

@onready var torus_mesh_instance: MeshInstance3D = $TorusMesh
@onready var cylinder_mesh_instance: MeshInstance3D = $CylinderMesh
@onready var world_environment: WorldEnvironment = $WorldEnvironment

var time_elapsed: float = 0.0

func _ready():
	# Setup the scene components
	setup_torus()
	setup_cylinder()
 

func setup_torus():
	# Create torus mesh
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = 1.5
	torus_mesh.outer_radius = 3.0
	torus_mesh.rings = 32
	torus_mesh.ring_segments = 16
	torus_mesh_instance.mesh = torus_mesh
	
	# Create black shiny material
	var torus_material = StandardMaterial3D.new()
	torus_material.albedo_color = Color.BLACK
	torus_material.metallic = 0.9
	torus_material.roughness = 0.1
	torus_mesh_instance.material_override = torus_material

func setup_cylinder():
	# Create bigger cylinder mesh
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.7  # Increased from 0.3
	cylinder_mesh.bottom_radius = 0.7   # Increased from 0.3
	cylinder_mesh.height = 5.0
	cylinder_mesh.rings = 4
	cylinder_mesh_instance.mesh = cylinder_mesh
	
	# Create black shiny material
	var cylinder_material = StandardMaterial3D.new()
	cylinder_material.albedo_color = Color.BLACK
	cylinder_material.metallic = 0.9
	cylinder_material.roughness = 0.1
	cylinder_mesh_instance.material_override = cylinder_material
 

func _process(delta):
	time_elapsed += delta
	
	# Rotate the torus around Y axis
	torus_mesh_instance.rotation.y += delta * 0.5
	
	# Animate cylinder moving up and down
	var cylinder_speed = 1.5
	var cylinder_range = 3.0
	cylinder_mesh_instance.position.y = sin(time_elapsed * cylinder_speed) * cylinder_range
