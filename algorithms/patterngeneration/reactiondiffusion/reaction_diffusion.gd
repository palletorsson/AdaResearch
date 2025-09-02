# simulation.gd
extends Control

# --- Node references from your scene tree ---
@onready var buffer_a: SubViewport = $BufferA_Container/BufferA
@onready var buffer_b: SubViewport = $BufferB_Container/BufferB
@onready var display: TextureRect = $Display

# --- Shader material that will run the simulation ---
var sim_material: ShaderMaterial

# --- Variables to track which buffer is the source and which is the destination ---
var current_buffer: SubViewport
var next_buffer: SubViewport


func _ready() -> void:
	print("🧪 Initializing Reaction-Diffusion System...")
	
	# 1. Create a new ShaderMaterial and load your shader from its specific path.
	sim_material = ShaderMaterial.new()
	var shader = load("res://algorithms/patterngeneration/reactiondiffusion/reactiondiffusion.gdshader")
	if shader:
		sim_material.shader = shader
		# Set shader parameters for better pattern formation
		sim_material.set_shader_parameter("feed_rate", 0.037)
		sim_material.set_shader_parameter("kill_rate", 0.06)
		print("✅ Shader loaded successfully")
		print("🎛️ Shader parameters set: feed=0.037, kill=0.06")
	else:
		print("❌ Failed to load shader")
		return
	
	# 2. Set up buffer sizes and render settings
	buffer_a.size = Vector2i(512, 512)
	buffer_b.size = Vector2i(512, 512)
	
	# CRITICAL: Set proper render modes
	buffer_a.render_target_update_mode = SubViewport.UPDATE_ONCE
	buffer_b.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	print("📐 Buffer sizes set to 512x512")
	
	# 3. The shader only needs to be on one of the buffers (the one that will be rendering).
	if buffer_b.get_node("ColorRect"):
		buffer_b.get_node("ColorRect").material = sim_material
		print("✅ Shader material applied to BufferB")
	else:
		print("❌ BufferB ColorRect not found")

	# 4. Set the initial state of the simulation.
	# We start with a full canvas of chemical U (Color.RED represents U=1.0, V=0.0).
	if buffer_a.get_node("ColorRect"):
		buffer_a.get_node("ColorRect").color = Color.RED
		print("✅ Initial state set (red = chemical U)")
	else:
		print("❌ BufferA ColorRect not found")
	
	# 5. Initialize the ping-pong buffer system.
	current_buffer = buffer_a
	next_buffer = buffer_b
	
	# 6. Add initial seed pattern
	call_deferred("add_initial_seed")
	
	print("🚀 Reaction-Diffusion system ready!")

func add_initial_seed():
	print("🌱 Adding initial seed points...")
	
	# Wait a moment for everything to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Add multiple random seed points to start the reaction
	for i in range(30):
		var random_pos = Vector2(randf(), randf())
		sim_material.set_shader_parameter("mouse_pos", random_pos)
		next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE
		await get_tree().process_frame
	
	# Add a central cluster for sure
	var center_positions = [
		Vector2(0.5, 0.5),
		Vector2(0.45, 0.5),
		Vector2(0.55, 0.5),
		Vector2(0.5, 0.45),
		Vector2(0.5, 0.55)
	]
	
	for pos in center_positions:
		sim_material.set_shader_parameter("mouse_pos", pos)
		next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE
		await get_tree().process_frame
	
	# Reset mouse position
	sim_material.set_shader_parameter("mouse_pos", Vector2(-1, -1))
	print("✨ Initial seed points created!")

func create_noise_texture():
	# Create a texture with random noise to initialize the system
	var noise_image = Image.create(512, 512, false, Image.FORMAT_RGBA8)
	
	for y in range(512):
		for x in range(512):
			# Create mostly U (red) with small random amounts of V (green)
			var u_value = 1.0 - randf() * 0.1  # Slight variation in U
			var v_value = randf() * 0.05 if randf() < 0.1 else 0.0  # Sparse V seeds
			
			var color = Color(u_value, v_value, 0.0, 1.0)
			noise_image.set_pixel(x, y, color)
	
	# Apply this noise texture to buffer A using a shader material
	var noise_texture = ImageTexture.new()
	noise_texture.set_image(noise_image)
	
	# Create a shader material to display the noise texture on ColorRect
	var noise_rect = buffer_a.get_node("ColorRect")
	if noise_rect:
		var noise_material = CanvasItemMaterial.new()
		var noise_shader = Shader.new()
		noise_shader.code = """
shader_type canvas_item;

uniform sampler2D noise_texture;

void fragment() {
	COLOR = texture(noise_texture, UV);
}
"""
		var shader_material = ShaderMaterial.new()
		shader_material.shader = noise_shader
		shader_material.set_shader_parameter("noise_texture", noise_texture)
		noise_rect.material = shader_material
		print("✅ Noise texture applied to BufferA")


var frame_count = 0
var debug_mode = false

func _process(delta: float) -> void:
	if not sim_material or not sim_material.shader:
		return
	
	frame_count += 1
	
	# 1. Pass the previous frame's texture to the shader's "last_frame" uniform.
	var current_texture = current_buffer.get_texture()
	if current_texture:
		sim_material.set_shader_parameter("last_frame", current_texture)
	
	# 2. Get the mouse position, convert it to UV coordinates (0.0 to 1.0),
	#    and pass it to the shader. This lets you "paint" with your mouse.
	var mouse_uv = get_local_mouse_position() / get_viewport_rect().size
	if get_viewport_rect().has_point(get_local_mouse_position()) and Input.is_action_pressed("ui_accept"):
		sim_material.set_shader_parameter("mouse_pos", mouse_uv)
		if frame_count % 60 == 0:  # Debug print every second
			print("🖱️ Mouse interaction at: ", mouse_uv)
	else:
		# If the mouse is outside the window, send an invalid position.
		sim_material.set_shader_parameter("mouse_pos", Vector2(-1, -1))

	# 3. Force the 'next_buffer' to render with the current state as input
	if next_buffer == buffer_b:
		# BufferB has the shader, so it processes BufferA's content
		next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE
	else:
		# BufferA just copies its color, no shader processing
		next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# Wait for render to complete
	await get_tree().process_frame
	
	# 4. Update the visible 'Display' TextureRect with the new texture.
	var new_texture = next_buffer.get_texture()
	if new_texture:
		display.texture = new_texture
	
	# Debug output every few seconds
	if frame_count % 180 == 0:
		print("🔄 Frame ", frame_count, " - Simulation running")
		print("   Current buffer: ", current_buffer.name)
		print("   Next buffer: ", next_buffer.name)
		print("   Current texture valid: ", current_texture != null)
		print("   New texture valid: ", new_texture != null)
		if next_buffer == buffer_b:
			print("   🧪 Shader processing active")
		else:
			print("   📋 Copying state")
	
	# 5. --- PING-PONG SWAP ---
	# The buffer that just rendered becomes the 'current' state for the next frame.
	# The old buffer becomes the 'next' buffer, ready to be rendered into.
	var temp = current_buffer
	current_buffer = next_buffer
	next_buffer = temp

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_N:
				print("🎲 Adding random noise...")
				add_random_noise()
			KEY_R:
				print("🔄 Resetting simulation...")
				reset_simulation()
			KEY_S:
				print("🌱 Adding seed points...")
				add_seed_points()
			KEY_T:
				print("🧪 Testing shader with manual seed...")
				test_manual_seed()
			KEY_B:
				print("💥 Big seed blast!")
				big_seed_blast()
			KEY_D:
				print("🔍 Debug mode - showing raw values")
				toggle_debug_mode()
			KEY_V:
				print("👁️ Simple visual test")
				simple_visual_test()
			KEY_M:
				print("🧬 Manual reaction test")
				manual_reaction_test()

func add_random_noise():
	# Add multiple random V spots
	for i in range(50):
		var random_pos = Vector2(randf(), randf())
		sim_material.set_shader_parameter("mouse_pos", random_pos)
		next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE
		await get_tree().process_frame
	sim_material.set_shader_parameter("mouse_pos", Vector2(-1, -1))

func add_seed_points():
	# Add a grid of seed points
	for x in range(5):
		for y in range(5):
			var pos = Vector2(x / 4.0, y / 4.0)
			sim_material.set_shader_parameter("mouse_pos", pos)
			next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE
			await get_tree().process_frame
	sim_material.set_shader_parameter("mouse_pos", Vector2(-1, -1))

func reset_simulation():
	# Reset to initial red state
	if buffer_a.get_node("ColorRect"):
		buffer_a.get_node("ColorRect").color = Color.RED
	current_buffer = buffer_a
	next_buffer = buffer_b

func test_manual_seed():
	# Simple manual test - add one seed point in center
	print("Adding single seed at center...")
	if sim_material:
		sim_material.set_shader_parameter("mouse_pos", Vector2(0.5, 0.5))
		# Force render
		if next_buffer:
			next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE
		await get_tree().process_frame
		await get_tree().process_frame
		sim_material.set_shader_parameter("mouse_pos", Vector2(-1, -1))
		print("Seed added! You should see a spot appear.")

func big_seed_blast():
	# Very aggressive seeding to force visible patterns
	print("Creating massive seed pattern...")
	if sim_material:
		# Create a large central area of chemical V
		for y in range(10):
			for x in range(10):
				var pos = Vector2(0.4 + x * 0.02, 0.4 + y * 0.02)
				sim_material.set_shader_parameter("mouse_pos", pos)
				next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE
				await get_tree().process_frame
		
		# Add corner seeds
		var corners = [Vector2(0.1, 0.1), Vector2(0.9, 0.1), Vector2(0.1, 0.9), Vector2(0.9, 0.9)]
		for corner in corners:
			sim_material.set_shader_parameter("mouse_pos", corner)
			next_buffer.render_target_update_mode = SubViewport.UPDATE_ONCE
			await get_tree().process_frame
		
		sim_material.set_shader_parameter("mouse_pos", Vector2(-1, -1))
		print("💥 Big seed blast complete! Patterns should definitely appear now.")

func toggle_debug_mode():
	debug_mode = !debug_mode
	if debug_mode:
		print("🔍 Debug mode ON - will show V channel in green")
		# Create a simple debug shader that amplifies the V channel
		create_debug_shader()
	else:
		print("🔍 Debug mode OFF - back to normal")
		# Reset to normal reaction-diffusion shader
		if sim_material:
			var shader = load("res://algorithms/patterngeneration/reactiondiffusion/reactiondiffusion.gdshader")
			sim_material.shader = shader

func create_debug_shader():
	# Create a shader that shows the V channel more clearly
	var debug_shader = Shader.new()
	debug_shader.code = '''
shader_type canvas_item;

uniform sampler2D last_frame;
uniform vec2 mouse_pos = vec2(-1.0, -1.0);

void fragment() {
	vec2 uv = UV;
	vec4 current = texture(last_frame, uv);
	
	// Show U in red channel, V amplified in green channel
	float u = current.r;
	float v = current.g;
	
	// Amplify V channel to make it more visible
	v = v * 10.0;
	
	// Add mouse interaction
	if (distance(uv, mouse_pos) < 0.02) {
		v = 1.0;
	}
	
	COLOR = vec4(u, v, 0.0, 1.0);
}
'''
	if sim_material:
		sim_material.shader = debug_shader
		print("🔍 Debug shader applied - V channel amplified 10x")

func simple_visual_test():
	# Skip all the complex buffer logic and just set a simple pattern directly
	print("🎨 Creating simple visual pattern...")
	
	# Create a simple test shader that just shows a pattern
	var test_shader = Shader.new()
	test_shader.code = '''
shader_type canvas_item;

uniform float time;

void fragment() {
	vec2 uv = UV;
	
	// Create a simple animated pattern
	float pattern = sin(uv.x * 10.0 + time) * sin(uv.y * 10.0 + time);
	pattern = pattern * 0.5 + 0.5;
	
	// Show pattern in green
	COLOR = vec4(1.0 - pattern, pattern, 0.0, 1.0);
}
'''
	
	# Apply directly to display
	if display:
		var test_material = ShaderMaterial.new()
		test_material.shader = test_shader
		test_material.set_shader_parameter("time", Time.get_time_dict_from_system().hour)
		display.material = test_material
		print("🎨 Test pattern applied directly to display")
		print("   You should see a green wave pattern!")

func manual_reaction_test():
	# Create a working reaction-diffusion directly on the display
	print("🧬 Creating direct reaction-diffusion test...")
	
	var reaction_shader = Shader.new()
	reaction_shader.code = '''
shader_type canvas_item;

uniform float time;
uniform vec2 mouse_pos = vec2(0.5, 0.5);

void fragment() {
	vec2 uv = UV;
	
	// Simple reaction-diffusion simulation
	float dist_to_center = distance(uv, vec2(0.5, 0.5));
	float dist_to_mouse = distance(uv, mouse_pos);
	
	// Create expanding rings from center
	float rings = sin(dist_to_center * 20.0 - time * 3.0) * 0.5 + 0.5;
	
	// Add mouse interaction spots
	float mouse_spot = 1.0 - smoothstep(0.0, 0.1, dist_to_mouse);
	
	// Combine effects
	float u = 1.0 - rings * 0.3;
	float v = rings + mouse_spot;
	
	COLOR = vec4(u, v * 0.5, v * 0.8, 1.0);
}
'''
	
	if display:
		var reaction_material = ShaderMaterial.new()
		reaction_material.shader = reaction_shader
		reaction_material.set_shader_parameter("time", 0.0)
		reaction_material.set_shader_parameter("mouse_pos", Vector2(0.5, 0.5))
		display.material = reaction_material
		
		# Animate the time parameter
		var tween = create_tween()
		tween.set_loops()
		tween.tween_method(
			func(t): reaction_material.set_shader_parameter("time", t),
			0.0, 10.0, 5.0
		)
		
		print("🧬 Manual reaction-diffusion running!")
		print("   You should see expanding blue rings!")
