extends Node3D

# VR Hand Color Trails System for Godot 4
# Attach this to your Base node or create a new Node3D in your scene

# Trail configuration
@export var trail_length: int = 100
@export var trail_lifetime: float = 2.0
@export var trail_width: float = 0.2
@export var update_distance: float = 0.001  # Minimum distance to add new trail point
@export var left_hand_color: Color = Color(0.2, 0.8, 1.0, 0.8)  # Cyan
@export var right_hand_color: Color = Color(1.0, 0.2, 0.8, 0.8)  # Magenta

# Trail data structures
var left_trail_points: Array[Dictionary] = []
var right_trail_points: Array[Dictionary] = []

# Trail meshes
var left_trail_mesh: MeshInstance3D
var right_trail_mesh: MeshInstance3D
var left_trail_material: StandardMaterial3D
var right_trail_material: StandardMaterial3D

# Hand references (will be found automatically)
var left_hand: Node3D
var right_hand: Node3D

func _ready():
	find_hand_controllers()
	setup_trail_meshes()
	print("🎨 VR Hand Trails initialized!")

func _process(delta):
	# Debug: Always try to draw trails for testing
	if left_hand:
		update_trail(left_hand, left_trail_points, delta)
		update_trail_mesh(left_trail_mesh, left_trail_points, left_hand_color)
	
	if right_hand:
		update_trail(right_hand, right_trail_points, delta)
		update_trail_mesh(right_trail_mesh, right_trail_points, right_hand_color)
	
	# Always decay existing trails
	decay_trails(left_trail_points, delta)
	decay_trails(right_trail_points, delta)
	
	# Update meshes even when not drawing (for decay)
	if left_trail_points.size() > 0:
		update_trail_mesh(left_trail_mesh, left_trail_points, left_hand_color)
	if right_trail_points.size() > 0:
		update_trail_mesh(right_trail_mesh, right_trail_points, right_hand_color)

func find_hand_controllers():
	# Find hand controllers - search through the scene tree
	var xr_origin = null
	
	# Try multiple common paths
	var possible_paths = [
		"/root/Base/XROrigin3D",
		"/root/VRStaging/Scene/Base/XROrigin3D", 
		"/root/Lab/XROrigin3D",
		"/root/Scene/Base/XROrigin3D"
	]
	
	for path in possible_paths:
		if has_node(path):
			xr_origin = get_node(path)
			print("✅ Found XROrigin3D at: ", path)
			break
	
	# If direct paths don't work, search recursively
	if not xr_origin:
		xr_origin = find_node_recursive(get_tree().root, "XROrigin3D")
		if xr_origin:
			print("✅ Found XROrigin3D via search at: ", xr_origin.get_path())
	
	if xr_origin:
		if xr_origin.has_node("LeftHand"):
			left_hand = xr_origin.get_node("LeftHand")
			print("✅ Handtrails: left hand controller found at: ", left_hand.get_path())
		else:
			print("❌ Handtrails: left hand controller not found")
		
		if xr_origin.has_node("RightHand"):
			right_hand = xr_origin.get_node("RightHand")
			print("✅ Handtrails: right hand controller found at: ", right_hand.get_path())
		else:
			print("❌ Handtrails: right hand controller not found")
	else:
		print("❌ Handtrails: XROrigin3D not found anywhere")

func find_node_recursive(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	
	for child in node.get_children():
		var result = find_node_recursive(child, node_name)
		if result:
			return result
	
	return null

func is_trigger_pressed(hand: Node3D) -> bool:
	# First check if it's an XRController3D
	if hand is XRController3D:
		var pressed = hand.is_button_pressed("trigger_click")
		if pressed:
			print("🎮 XRController3D trigger detected")
		return pressed
	
	# Check for XRController3D in children (XR Tools structure)
	for child in hand.get_children():
		if child is XRController3D:
			var pressed = child.is_button_pressed("trigger_click")
			if pressed:
				print("🎮 Child XRController3D trigger detected")
			return pressed
	
	# Check input actions
	var is_left = hand == left_hand
	var actions = ["trigger_click", "grip_click", "primary_click"]
	
	for action in actions:
		if Input.is_action_pressed(action):
			print("🎮 Input action detected: ", action)
			return true
	
	# Keyboard/mouse fallback for testing
	var fallback = Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if fallback and randf() < 0.01:  # Print occasionally to avoid spam
		print("🖱️ Fallback input detected (Space/Mouse)")
	return fallback 

func setup_trail_meshes():
	# Left hand trail
	left_trail_mesh = MeshInstance3D.new()
	left_trail_mesh.name = "LeftTrailMesh"
	add_child(left_trail_mesh)
	
	left_trail_material = StandardMaterial3D.new()
	left_trail_material.flags_transparent = true
	left_trail_material.flags_unshaded = true
	left_trail_material.no_depth_test = false
	left_trail_material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	left_trail_material.albedo_color = left_hand_color
	left_trail_mesh.material_override = left_trail_material
	
	# Right hand trail
	right_trail_mesh = MeshInstance3D.new()
	right_trail_mesh.name = "RightTrailMesh"
	add_child(right_trail_mesh)
	
	right_trail_material = StandardMaterial3D.new()
	right_trail_material.flags_transparent = true
	right_trail_material.flags_unshaded = true
	right_trail_material.no_depth_test = false
	right_trail_material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	right_trail_material.albedo_color = right_hand_color
	right_trail_mesh.material_override = right_trail_material

func update_trail(hand: Node3D, trail_points: Array[Dictionary], delta: float):
	var hand_pos = hand.global_transform.origin
	
	# Check if we should add a new point
	var should_add = false
	if trail_points.is_empty():
		should_add = true
		print("📍 First trail point for ", hand.name, " at: ", hand_pos)
	else:
		var last_pos = trail_points[-1].position
		var distance = hand_pos.distance_to(last_pos)
		if distance > update_distance:
			should_add = true
			print("📍 New trail point (distance: ", "%.3f" % distance, ") at: ", hand_pos)
	
	if should_add:
		var trail_point = {
			"position": hand_pos,
			"age": 0.0,
			"velocity": Vector3.ZERO
		}
		
		# Calculate velocity if we have previous points
		if trail_points.size() > 0:
			var prev_point = trail_points[-1]
			trail_point.velocity = (hand_pos - prev_point.position) / delta
		
		trail_points.append(trail_point)
		print("✨ Trail now has ", trail_points.size(), " points")
		
		# Limit trail length
		if trail_points.size() > trail_length:
			trail_points.pop_front()

func decay_trails(trail_points: Array[Dictionary], delta: float):
	# Age all points and remove old ones
	for i in range(trail_points.size() - 1, -1, -1):
		trail_points[i].age += delta
		if trail_points[i].age > trail_lifetime:
			trail_points.remove_at(i)

func update_trail_mesh(mesh_instance: MeshInstance3D, trail_points: Array[Dictionary], base_color: Color):
	if trail_points.size() < 2:
		mesh_instance.mesh = null
		return
	
	print("🎨 Creating mesh with ", trail_points.size(), " trail points")
	
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	var colors = PackedColorArray()
	
	# Generate trail geometry
	for i in range(trail_points.size()):
		var point = trail_points[i]
		var pos = point.position
		var age_factor = 1.0 - (point.age / trail_lifetime)
		var width = trail_width * age_factor
		
		# Calculate direction for ribbon orientation
		var forward = Vector3.FORWARD
		if i < trail_points.size() - 1:
			forward = (trail_points[i + 1].position - pos).normalized()
		elif i > 0:
			forward = (pos - trail_points[i - 1].position).normalized()
		
		# Create perpendicular vector for width
		var camera = get_viewport().get_camera_3d()
		var to_camera = Vector3.UP
		if camera:
			to_camera = (camera.global_transform.origin - pos).normalized()
		
		var right = forward.cross(to_camera).normalized()
		
		# Create quad vertices
		var left_pos = pos - right * width * 0.5
		var right_pos = pos + right * width * 0.5
		
		vertices.append(left_pos)
		vertices.append(right_pos)
		
		# Normals
		normals.append(to_camera)
		normals.append(to_camera)
		
		# UVs
		var u = float(i) / float(trail_points.size() - 1)
		uvs.append(Vector2(u, 0.0))
		uvs.append(Vector2(u, 1.0))
		
		# Colors with alpha fade
		var alpha = age_factor * base_color.a
		var point_color = Color(base_color.r, base_color.g, base_color.b, alpha)
		colors.append(point_color)
		colors.append(point_color)
		
		# Indices for triangles (except last point)
		if i < trail_points.size() - 1:
			var base_idx = i * 2
			
			# First triangle
			indices.append(base_idx)
			indices.append(base_idx + 1)
			indices.append(base_idx + 2)
			
			# Second triangle
			indices.append(base_idx + 1)
			indices.append(base_idx + 3)
			indices.append(base_idx + 2)
	
	# Create the mesh
	if vertices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = indices
		
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh_instance.mesh = array_mesh

# Alternative: Particle-based trails (more performance-friendly for long trails)
func create_particle_trail(hand: Node3D, color: Color) -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	add_child(particles)
	
	# Configure particle system
	particles.emitting = false
	particles.amount = 1000
	particles.lifetime = trail_lifetime
	particles.process_material = create_trail_particle_material(color)
	
	# Create custom mesh for particles
	var particle_mesh = SphereMesh.new()
	particle_mesh.radius = 0.01
	particle_mesh.height = 0.02
	particles.draw_pass_1 = particle_mesh
	
	return particles

func create_trail_particle_material(color: Color) -> ParticleProcessMaterial:
	var material = ParticleProcessMaterial.new()
	
	# Basic particle settings
	material.direction = Vector3(0, 0, 0)
	material.initial_velocity_min = 0.0
	material.initial_velocity_max = 0.1
	material.angular_velocity_min = 0.0
	material.angular_velocity_max = 0.0
	material.gravity = Vector3.ZERO
	
	# Size and color
	material.scale_min = 0.5
	material.scale_max = 1.0
	material.color = color
	
	# Fade out over time
	var fade_curve = Curve.new()
	fade_curve.add_point(Vector2(0.0, 1.0))
	fade_curve.add_point(Vector2(1.0, 0.0))
	material.alpha_curve = fade_curve
	
	return material

# Advanced trail effects
func create_glitch_trail_effect():
	# Add bit manipulation effects to trails
	var glitch_material = StandardMaterial3D.new()
	glitch_material.flags_transparent = true
	glitch_material.flags_unshaded = true
	
	# Create shader for glitch effects
	var shader = Shader.new()
	shader.code = '''
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, depth_test_disabled, diffuse_burley, specular_schlick_ggx;

varying float age;
varying vec3 world_pos;

uniform float time : hint_range(0.0, 100.0);
uniform vec4 base_color : source_color = vec4(1.0);
uniform float glitch_intensity : hint_range(0.0, 2.0) = 0.5;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	age = COLOR.a;
	world_pos = VERTEX;
}

void fragment() {
	vec2 glitch_uv = world_pos.xz + time * 0.1;
	float noise = random(floor(glitch_uv * 20.0) / 20.0);
	
	vec3 color = base_color.rgb;
	
	// Bit-shift color channels
	if (noise > 0.8 && glitch_intensity > 0.5) {
		color.r = fract(color.r * 4.0);
		color.g = fract(color.g * 2.0);  
		color.b = fract(color.b * 8.0);
	}
	
	// Digital corruption
	if (random(glitch_uv + time) > 0.9) {
		color = vec3(1.0, 0.0, 1.0); // Hot pink corruption
	}
	
	ALBEDO = color;
	ALPHA = base_color.a * age;
}
'''
	
	glitch_material.shader = shader
	return glitch_material

# Input handling for trail controls
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				left_hand_color = Color(randf(), randf(), randf(), 0.8)
				left_trail_material.albedo_color = left_hand_color
			KEY_2:
				right_hand_color = Color(randf(), randf(), randf(), 0.8)
				right_trail_material.albedo_color = right_hand_color
			KEY_C:
				clear_all_trails()
			KEY_PLUS, KEY_EQUAL:
				trail_width = min(trail_width * 1.2, 0.5)
			KEY_MINUS:
				trail_width = max(trail_width * 0.8, 0.005)

func clear_all_trails():
	left_trail_points.clear()
	right_trail_points.clear()
	left_trail_mesh.mesh = null
	right_trail_mesh.mesh = null

# VR-specific enhancements
func get_hand_velocity(hand: Node3D) -> Vector3:
	# Get hand velocity from XR system if available
	if hand.has_method("get_velocity"):
		return hand.get_velocity()
	return Vector3.ZERO

func add_haptic_feedback(hand: Node3D, intensity: float = 0.3):
	# Add haptic feedback when drawing
	if hand.has_method("trigger_haptic_pulse"):
		hand.trigger_haptic_pulse("haptic", 0, intensity, 0.1, 0.0)

# Performance optimization for long trails
func optimize_trail_points(trail_points: Array[Dictionary]):
	# Remove redundant points that are too close together
	if trail_points.size() < 3:
		return
		
	for i in range(trail_points.size() - 2, 0, -1):
		var curr = trail_points[i]
		var prev = trail_points[i - 1]
		var next = trail_points[i + 1]
		
		# Check if current point is nearly collinear
		var to_prev = (prev.position - curr.position).normalized()
		var to_next = (next.position - curr.position).normalized()
		
		if to_prev.dot(to_next) > 0.98:  # Nearly collinear
			trail_points.remove_at(i)
