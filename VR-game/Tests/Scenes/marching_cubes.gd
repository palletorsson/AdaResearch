extends Node3D

var metaball_meshes = []
var material: ShaderMaterial

func _ready():
	# Create shader material
	material = ShaderMaterial.new()
	material.shader = load("res://adaresearch/Tests/Scenes/meta_balls.gdshader")
	
	
	# Create metaballs
	create_metaball(Vector3(0, 0, 0), 0.5)
	create_metaball(Vector3(0.5, 0, 0), 0.4)
	create_metaball(Vector3(0, 0.5, 0), 0.3)
	
	# Setup camera
	var camera = Camera3D.new()
	camera.position = Vector3(0, 0, 3)
	camera.current = true
	add_child(camera)
	
	# Add light
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(light)

func create_metaball(position: Vector3, radius: float):
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = SphereMesh.new()
	mesh_instance.mesh.radius = radius
	mesh_instance.mesh.height = radius * 2.0
	mesh_instance.position = position
	mesh_instance.material_override = material
	add_child(mesh_instance)
	metaball_meshes.append({"instance": mesh_instance, "radius": radius})

func _process(delta):
	# Animate metaballs
	var time = Time.get_ticks_msec() * 0.001
	metaball_meshes[0].instance.position = Vector3(sin(time) * 0.7, cos(time * 1.3) * 0.5, 0)
	metaball_meshes[1].instance.position = Vector3(cos(time * 0.8) * 0.8, sin(time) * 0.6, sin(time * 0.5) * 0.3)
	metaball_meshes[2].instance.position = Vector3(sin(time * 1.2) * 0.5, sin(time * 0.7) * 0.7, cos(time) * 0.4)
	
	# Update shader parameters
	material.set_shader_parameter("metaball_pos_1", metaball_meshes[0].instance.position)
	material.set_shader_parameter("metaball_pos_2", metaball_meshes[1].instance.position)
	material.set_shader_parameter("metaball_pos_3", metaball_meshes[2].instance.position)
	material.set_shader_parameter("metaball_radius_1", metaball_meshes[0].radius)
	material.set_shader_parameter("metaball_radius_2", metaball_meshes[1].radius)
	material.set_shader_parameter("metaball_radius_3", metaball_meshes[2].radius)
