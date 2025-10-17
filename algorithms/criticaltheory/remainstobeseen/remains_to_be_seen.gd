extends Node3D

# Implementation of a 3D representation inspired by Mona Hatoum's "Remains to be Seen"
# This script creates a 3D installation with suspended furniture frames made of metal wire

var wire_material: StandardMaterial3D
var grid_size = 5
var grid_spacing = 1.5
var rotation_speed = 0.2
var subtle_movement_amplitude = 0.1
var swing_speed = 0.8

func _ready():
	# Create a dark environment with appropriate lighting
	setup_environment()
	
	# Create the wire material - metallic dark grey
	wire_material = StandardMaterial3D.new()
	wire_material.albedo_color = Color(0.2, 0.2, 0.2)
	wire_material.metallic = 0.8
	wire_material.roughness = 0.3
	
	# Create the suspended furniture frames arranged in a grid pattern
	create_suspended_frames()
	


func setup_environment():
	# Create environment
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	
	# Set up ambient light
	env.ambient_light_color = Color(0.05, 0.05, 0.07)
	env.ambient_light_energy = 0.3
	
	# Add fog for atmosphere
	env.fog_enabled = true
	#env.fog_color = Color(0.05, 0.05, 0.05)
	env.fog_density = 0.02
	
	# Set environment
	environment.environment = env
	add_child(environment)
	
	# Add directional light from above
	var dir_light = DirectionalLight3D.new()
	dir_light.position = Vector3(0, 8, 0)
	dir_light.rotation_degrees = Vector3(-90, 0, 0)
	dir_light.light_color = Color(0.9, 0.9, 1.0)
	dir_light.light_energy = 1.0
	dir_light.shadow_enabled = true
	add_child(dir_light)
	
	# Add subtle accent light
	var spot_light = SpotLight3D.new()
	spot_light.position = Vector3(5, 3, 5)
	spot_light.light_color = Color(0.8, 0.7, 0.6)
	spot_light.light_energy = 3.0
	spot_light.spot_range = 15
	spot_light.spot_angle = 30
	add_child(spot_light)

func create_suspended_frames():
	# Parent node for all frames
	var frames = Node3D.new()
	frames.name = "SuspendedFrames"
	add_child(frames)
	
	# Create grid of suspended furniture frames
	for x in range(-grid_size, grid_size + 1):
		for z in range(-grid_size, grid_size + 1):
			# Skip some positions randomly to create irregular pattern
			if randf() < 0.3:
				continue
				
			var frame = create_random_frame()
			
			# Position in grid with slight random offset
			var pos_x = x * grid_spacing + randf_range(-0.3, 0.3)
			var pos_y = randf_range(0.5, 3.5)
			var pos_z = z * grid_spacing + randf_range(-0.3, 0.3)
			frame.position = Vector3(pos_x, pos_y, pos_z)
			
			# Random initial rotation
			frame.rotation = Vector3(
				randf_range(-PI/8, PI/8),
				randf_range(0, 2*PI),
				randf_range(-PI/8, PI/8)
			)
			
			# Add subtle animation
			var animation_player = AnimationPlayer.new()
			frame.add_child(animation_player)
			
			# Create swinging animation
			create_swing_animation(animation_player, frame)
			
			frames.add_child(frame)
			
	# Add thin wire suspensions from ceiling
	add_suspension_wires(frames)

func create_random_frame():
	var frame_types = ["bed", "chair", "table", "crib"]
	var type = frame_types[randi() % frame_types.size()]
	
	var frame = Node3D.new()
	frame.name = type.capitalize() + "Frame"
	
	match type:
		"bed":
			create_bed_frame(frame)
		"chair":
			create_chair_frame(frame)
		"table":
			create_table_frame(frame)
		"crib":
			create_crib_frame(frame)
			
	return frame

func create_bed_frame(parent):
	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	
	# Create bed frame dimensions
	mesh.size = Vector3(1.8, 0.1, 0.9)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = wire_material
	
	# Convert solid mesh to wireframe
	convert_to_wireframe(mesh_instance)
	
	parent.add_child(mesh_instance)
	
	# Add bed posts (legs)
	for x in [-0.85, 0.85]:
		for z in [-0.4, 0.4]:
			var post = MeshInstance3D.new()
			var post_mesh = CylinderMesh.new()
			post_mesh.height = 0.5
			post_mesh.top_radius = 0.05
			post.mesh = post_mesh
			post.material_override = wire_material
			post.position = Vector3(x, -0.25, z)
			convert_to_wireframe(post)
			parent.add_child(post)

func create_chair_frame(parent):
	# Chair seat
	var seat = MeshInstance3D.new()
	var seat_mesh = BoxMesh.new()
	seat_mesh.size = Vector3(0.5, 0.05, 0.5)
	seat.mesh = seat_mesh
	seat.material_override = wire_material
	parent.add_child(seat)
	convert_to_wireframe(seat)
	
	# Chair back
	var back = MeshInstance3D.new()
	var back_mesh = BoxMesh.new()
	back_mesh.size = Vector3(0.5, 0.6, 0.05)
	back.mesh = back_mesh
	back.material_override = wire_material
	back.position = Vector3(0, 0.3, -0.25)
	parent.add_child(back)
	convert_to_wireframe(back)
	
	# Chair legs
	for x in [-0.2, 0.2]:
		for z in [-0.2, 0.2]:
			var leg = MeshInstance3D.new()
			var leg_mesh = CylinderMesh.new()
			leg_mesh.height = 0.4
			leg_mesh.top_radius = 0.02
			leg.mesh = leg_mesh
			leg.material_override = wire_material
			leg.position = Vector3(x, -0.2, z)
			convert_to_wireframe(leg)
			parent.add_child(leg)

func create_table_frame(parent):
	# Table top
	var top = MeshInstance3D.new()
	var top_mesh = BoxMesh.new()
	top_mesh.size = Vector3(1.2, 0.05, 0.8)
	top.mesh = top_mesh
	top.material_override = wire_material
	parent.add_child(top)
	convert_to_wireframe(top)
	
	# Table legs
	for x in [-0.5, 0.5]:
		for z in [-0.3, 0.3]:
			var leg = MeshInstance3D.new()
			var leg_mesh = CylinderMesh.new()
			leg_mesh.height = 0.7
			leg_mesh.top_radius = 0.03
			leg.mesh = leg_mesh
			leg.material_override = wire_material
			leg.position = Vector3(x, -0.35, z)
			convert_to_wireframe(leg)
			parent.add_child(leg)

func create_crib_frame(parent):
	# Crib base
	var base = MeshInstance3D.new()
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(1.0, 0.05, 0.6)
	base.mesh = base_mesh
	base.material_override = wire_material
	parent.add_child(base)
	convert_to_wireframe(base)
	
	# Crib sides
	for side_pos in [Vector3(0, 0.3, 0.3), Vector3(0, 0.3, -0.3), 
					 Vector3(0.5, 0.3, 0), Vector3(-0.5, 0.3, 0)]:
		var side = MeshInstance3D.new()
		var side_mesh = BoxMesh.new()
		
		# Adjust mesh based on position (sides vs ends)
		if abs(side_pos.z) > 0.1:  # It's a side (longer)
			side_mesh.size = Vector3(0.95, 0.6, 0.02)
		else:  # It's an end (shorter)
			side_mesh.size = Vector3(0.02, 0.6, 0.56)
			
		side.mesh = side_mesh
		side.material_override = wire_material
		side.position = side_pos
		convert_to_wireframe(side)
		parent.add_child(side)
	
	# Crib legs
	for x in [-0.45, 0.45]:
		for z in [-0.25, 0.25]:
			var leg = MeshInstance3D.new()
			var leg_mesh = CylinderMesh.new()
			leg_mesh.height = 0.5
			leg_mesh.top_radius = 0.02
			leg.mesh = leg_mesh
			leg.material_override = wire_material
			leg.position = Vector3(x, -0.2, z)
			convert_to_wireframe(leg)
			parent.add_child(leg)

func convert_to_wireframe(mesh_instance):
	# This is a simplified approach to create a wireframe effect
	# For a true wireframe, you would typically use a shader
	var material = mesh_instance.material_override.duplicate()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.6
	material.no_depth_test = false
	
	# Wireframe parameter removed - not available in Godot 4
	# For wireframe effect, consider using a different approach or shader
	
	mesh_instance.material_override = material

func add_suspension_wires(frames_parent):
	# Add thin suspension wires that go up to ceiling
	var ceiling_height = 6.0
	
	for i in range(frames_parent.get_child_count()):
		var frame = frames_parent.get_child(i)
		
		# Create 1-4 suspension wires per frame
		var wire_count = randi() % 4 + 1
		
		for j in range(wire_count):
			var wire = MeshInstance3D.new()
			var wire_mesh = CylinderMesh.new()
			
			# Random attachment point on the frame
			var attach_local = Vector3(
				randf_range(-0.3, 0.3),
				0.05,
				randf_range(-0.3, 0.3)
			)
			
			# Calculate wire properties
			var wire_bottom = frame.position + attach_local
			var wire_top = Vector3(wire_bottom.x, ceiling_height, wire_bottom.z)
			var wire_center = (wire_bottom + wire_top) / 2
			var wire_height = ceiling_height - wire_bottom.y
			
			# Set wire mesh properties
			wire_mesh.height = wire_height
			wire_mesh.top_radius = 0.005
			wire.mesh = wire_mesh
			
			# Calculate rotation to point upward
			wire.look_at_from_position(wire_center, wire_top, Vector3.FORWARD)
			
			# Set material
			var wire_mat = wire_material.duplicate()
			wire_mat.albedo_color = Color(0.1, 0.1, 0.1, 0.7)
			wire.material_override = wire_mat
			
			# Add to scene
			add_child(wire)

func create_swing_animation(animation_player, frame):
	# Create animation for subtle swinging motion
	var animation = Animation.new()
	
	# Create tracks for rotation
	var rotation_track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(rotation_track_idx, ":rotation")
	
	# Create keys for the animation
	var duration = 4.0 + randf() * 2.0  # Random duration for varied movement
	
	# Initial rotation
	var initial_rotation = frame.rotation
	
	# Set keyframes
	animation.track_insert_key(rotation_track_idx, 0.0, initial_rotation)
	animation.track_insert_key(rotation_track_idx, duration * 0.25, 
		initial_rotation + Vector3(subtle_movement_amplitude, 0, subtle_movement_amplitude/2))
	animation.track_insert_key(rotation_track_idx, duration * 0.5, 
		initial_rotation + Vector3(0, 0, -subtle_movement_amplitude))
	animation.track_insert_key(rotation_track_idx, duration * 0.75, 
		initial_rotation + Vector3(-subtle_movement_amplitude/2, 0, 0))
	animation.track_insert_key(rotation_track_idx, duration, initial_rotation)
	
	# Set animation properties
	animation.loop_mode = Animation.LOOP_LINEAR
	


func _process(delta):
	# Add any global animations or interactions here
	pass
