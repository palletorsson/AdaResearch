# MeltingDemoScene.gd
# Demo scene showing how to use the level set melting system
extends Node3D

var melting_geometry: Node3D
var heat_source_marker: MeshInstance3D

func _ready():
	setup_scene()
	setup_melting_geometry()
	setup_heat_source_marker()
	setup_camera()
	setup_lighting()

func setup_scene():
	# Set up basic scene
	pass

func setup_melting_geometry():
	# Create the melting geometry node
	melting_geometry = preload("res://algorithms/physicssimulation/softbodies/melting/meltinggeometry.gd").new()
	add_child(melting_geometry)
	
	# Configure melting parameters
	melting_geometry.resolution = 32  # Lower resolution for better performance
	melting_geometry.melt_speed = 1.0
	melting_geometry.melt_threshold = 0.8
	melting_geometry.ambient_temperature = 0.0
	
	# Add initial heat source
	melting_geometry.add_heat_source(Vector3(1, 0, 0))

func setup_heat_source_marker():
	# Create a visual marker for heat sources
	heat_source_marker = MeshInstance3D.new()
	add_child(heat_source_marker)
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	sphere_mesh.height = 0.2
	heat_source_marker.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.emission_enabled = true
	material.emission = Color.RED
	heat_source_marker.material_override = material
	
	heat_source_marker.position = Vector3(1, 0, 0)

func setup_camera():
	var camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(5, 3, 5)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func setup_lighting():
	var light = DirectionalLight3D.new()
	add_child(light)
	light.position = Vector3(2, 4, 2)
	light.rotation_degrees = Vector3(-45, 45, 0)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Add heat source at clicked position
			var camera = get_viewport().get_camera_3d()
			var from = camera.project_ray_origin(event.position)
			var to = from + camera.project_ray_normal(event.position) * 100
			
			# Simplified ray casting to find world position
			var world_pos = from + (to - from) * 0.5  # Middle point
			melting_geometry.add_heat_source(world_pos)
			
			# Move marker to new position
			heat_source_marker.position = world_pos
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				melting_geometry.set_melt_speed(0.5)
			KEY_2:
				melting_geometry.set_melt_speed(1.0)
			KEY_3:
				melting_geometry.set_melt_speed(2.0)
			KEY_R:
				# Reset the geometry
				melting_geometry.queue_free()
				setup_melting_geometry()
