# PyramidStage.gd - Obelisk-style pyramid stage using scene files
extends Node3D

# Scene paths  
const PYRAMID_SCENE_PATH = "res://commons/primitives/pyramid/pyramid.tscn"
const CUBE_SCENE_PATH = "res://commons/primitives/cubes/cube_scene.tscn"

# -------- parameters you can tweak --------
@export var plinth_size := Vector3(20, 1, 14)  # Larger base platform (wider in x and z)
@export var obelisk_height := 4.0              # Taller central pyramid
@export var small_pyr_height := 2.5            # Taller corner pyramids
@export var cube_size := 0.9
@export var ring_radius_x := 6.0               # Wider spacing for corners
@export var ring_radius_z := 4.5               # Deeper spacing for corners

# Colors
var plinth_color = Color(0.55, 0.55, 0.55)  # Gray
var obelisk_color = Color(0.9, 0.47, 0.63, 0.86)  # Pink/rose with transparency
var small_pyramid_color = Color(0.59, 0.71, 0.86)  # Light blue
var cube_color = Color(0.8, 0.63, 0.27)  # Golden

func _ready():
	create_pyramid_stage()

func create_pyramid_stage():
	"""Create the pyramid stage composition"""
	create_base_plinth()
	create_central_pyramid()
	create_corner_pyramids()
	create_golden_cubes()
	add_camera_and_light()
	print("PyramidStage: Created obelisk-style pyramid stage")

func create_base_plinth():
	"""Create the base platform (scaled cube)"""
	var cube_scene = load(CUBE_SCENE_PATH)
	if not cube_scene:
		print("PyramidStage: Could not load cube scene")
		return
	
	var plinth = cube_scene.instantiate()
	if plinth:
		plinth.name = "Plinth"
		plinth.position = Vector3(0, plinth_size.y * 0.5, 0)
		plinth.scale = Vector3(plinth_size.x, plinth_size.y, plinth_size.z)
		
		# Set plinth color
		_apply_color_to_object(plinth, plinth_color)
		
		add_child(plinth)

func create_central_pyramid():
	"""Create the central tall pyramid (obelisk)"""
	var pyramid_scene = load(PYRAMID_SCENE_PATH)
	if not pyramid_scene:
		print("PyramidStage: Could not load pyramid scene")
		return
	
	var obelisk = pyramid_scene.instantiate()
	if obelisk:
		obelisk.name = "CentralObelisk"
		obelisk.position = Vector3(0, plinth_size.y, 0)
		obelisk.scale = Vector3(1.5, obelisk_height, 1.5)  # Scale base and height
		
		# Set obelisk color (pink with transparency)
		_apply_color_to_object(obelisk, obelisk_color)
		
		add_child(obelisk)

func create_corner_pyramids():
	"""Create four smaller pyramids at corners"""
	var pyramid_scene = load(PYRAMID_SCENE_PATH)
	if not pyramid_scene:
		return
	
	# Four corner positions
	var positions = [
		Vector3(-ring_radius_x, plinth_size.y, -ring_radius_z),
		Vector3( ring_radius_x, plinth_size.y, -ring_radius_z),
		Vector3(-ring_radius_x, plinth_size.y,  ring_radius_z),
		Vector3( ring_radius_x, plinth_size.y,  ring_radius_z)
	]
	
	for i in range(4):
		var pyramid = pyramid_scene.instantiate()
		if pyramid:
			pyramid.name = "CornerPyramid_%d" % i
			pyramid.position = positions[i]
			pyramid.scale = Vector3(0.8, small_pyr_height, 0.8)  # Smaller base and height
			
			# Set corner pyramid color (light blue)
			_apply_color_to_object(pyramid, small_pyramid_color)
			
			add_child(pyramid)

func create_golden_cubes():
	"""Create four golden cubes around the central obelisk"""
	var cube_scene = load(CUBE_SCENE_PATH)
	if not cube_scene:
		return
	
	# Position cubes around the obelisk base
	var c_off = 1.5  # Distance from center
	var cube_positions = [
		Vector3( c_off, plinth_size.y + cube_size * 0.5,  0),
		Vector3(-c_off, plinth_size.y + cube_size * 0.5,  0),
		Vector3( 0,     plinth_size.y + cube_size * 0.5,  c_off),
		Vector3( 0,     plinth_size.y + cube_size * 0.5, -c_off)
	]
	
	for i in range(4):
		var cube = cube_scene.instantiate()
		if cube:
			cube.name = "GoldenCube_%d" % i
			cube.position = cube_positions[i]
			cube.scale = Vector3.ONE * cube_size
			
			# Set golden cube color
			_apply_color_to_object(cube, cube_color)
			
			add_child(cube)

# Helper functions

func _apply_color_to_object(object: Node3D, color: Color):
	"""Apply color to an object using various methods"""
	# Try different color application methods
	if object.has_method("set_base_color"):
		object.set_base_color(color)
	elif object.has_method("set_material_color"):
		object.set_material_color(color)
	else:
		# Try to find and modify materials directly
		_apply_color_to_mesh_materials(object, color)

func _apply_color_to_mesh_materials(node: Node3D, color: Color):
	"""Recursively find MeshInstance3D nodes and apply color"""
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh_instance = child as MeshInstance3D
			if mesh_instance.material_override:
				if mesh_instance.material_override is StandardMaterial3D:
					var material = mesh_instance.material_override as StandardMaterial3D
					material.albedo_color = color
					if color.a < 1.0:  # Handle transparency
						material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		elif child is Node3D:
			_apply_color_to_mesh_materials(child, color)

func add_camera_and_light():
	"""Add camera and lighting to the scene"""
	# Directional light
	var sun = DirectionalLight3D.new()
	sun.light_energy = 2.0
	sun.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sun)

	# Camera
	var cam = Camera3D.new()
	cam.position = Vector3(14, 10, 16)
	cam.look_at(Vector3(0, plinth_size.y + 2, 0), Vector3.UP)
	add_child(cam)

	# Environment
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.3
	env.environment = e
	add_child(env)
