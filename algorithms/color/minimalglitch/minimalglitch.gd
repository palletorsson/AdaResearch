
extends Node3D

# All-in-one glitch demo - no external files needed!

var time := 0.0
var demo_cubes := []
var materials := []

func _ready():
	setup_basic_scene()
	create_glitch_cubes()
	print("🚀 All-in-One Glitch Demo Ready!")

func setup_basic_scene():
	# Camera
	var camera = Camera3D.new()
	camera.position = Vector3(0, 2, 8)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	add_child(camera)
	
	# Lighting
	var light = DirectionalLight3D.new()
	light.position = Vector3(5, 5, 5)
	light.look_at(Vector3.ZERO, Vector3.UP)
	light.light_energy = 1.0
	add_child(light)
	
	# Environment
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.2)
	env.glow_enabled = true
	env.glow_intensity = 0.5
	world_env.environment = env
	add_child(world_env)

func create_glitch_cubes():
	# Create a grid of cubes with different glitch effects
	for i in range(5):
		for j in range(3):
			var cube = CSGBox3D.new()
			cube.size = Vector3(1, 1, 1)
			cube.position = Vector3(i * 2.5 - 5, j * 2.5 - 2.5, 0)
			
			var material = StandardMaterial3D.new()
			material.flags_unshaded = true
			material.flags_transparent = true
			cube.material_override = material
			
			demo_cubes.append(cube)
			materials.append(material)
			add_child(cube)

func _process(delta):
	time += delta
	
	# Apply different glitch effects to each cube
	for i in range(demo_cubes.size()):
		var material = materials[i]
		
		match i % 6:
			0: # Bit crushing
				material.albedo_color = bit_crush_color(time + i)
			1: # XOR patterns
				material.albedo_color = xor_pattern_color(time, demo_cubes[i].position)
			2: # RGB shifting
				material.albedo_color = rgb_channel_shift(time + i * 0.5)
			3: # Digital corruption
				material.albedo_color = digital_corruption_color(time + i)
			4: # Binary noise
				material.albedo_color = binary_noise_color(time + i)
			5: # Chromatic glitch
				material.albedo_color = chromatic_glitch_color(time + i)

# Simplified glitch functions
func bit_crush_color(t: float) -> Color:
	var bits = 3 + int(sin(t) * 2)  # 3-5 bit depth
	var r = floor(sin(t) * bits) / bits
	var g = floor(cos(t * 1.3) * bits) / bits  
	var b = floor(sin(t * 0.7) * bits) / bits
	return Color(abs(r), abs(g), abs(b), 1.0)

func xor_pattern_color(t: float, pos: Vector3) -> Color:
	var x = int(pos.x * 10 + t * 10) % 256
	var y = int(pos.y * 10 + t * 8) % 256
	var r = float(x ^ y) / 255.0
	var g = float((x ^ y) >> 1) / 255.0
	var b = float((x ^ y) >> 2) / 255.0
	return Color(r, g, b, 1.0)

func rgb_channel_shift(t: float) -> Color:
	var base = int(sin(t) * 128 + 127)
	var r = float(base >> 1) / 255.0
	var g = float(base) / 255.0
	var b = float((base << 1) & 0xFF) / 255.0
	return Color(r, g, b, 1.0)

func digital_corruption_color(t: float) -> Color:
	var corruption = sin(t * 5.0) > 0.8
	if corruption:
		var corrupt_val = int(t * 255) % 256
		return Color(
			float(corrupt_val & 0xFF) / 255.0,
			float((corrupt_val >> 2) & 0xFF) / 255.0,
			float((corrupt_val >> 4) & 0xFF) / 255.0,
			1.0
		)
	return Color(0.3, 0.6, 0.9, 1.0)

func binary_noise_color(t: float) -> Color:
	var seed = int(t * 100) % 1000
	var r = float((seed * 1234567) % 256) / 255.0
	var g = float((seed * 9876543) % 256) / 255.0
	var b = float((seed * 5555555) % 256) / 255.0
	return Color(r, g, b, 1.0)

func chromatic_glitch_color(t: float) -> Color:
	var shift = sin(t * 3.0) * 0.5
	var r = clamp(0.8 + shift, 0.0, 1.0)
	var g = clamp(0.4, 0.0, 1.0)
	var b = clamp(0.8 - shift, 0.0, 1.0)
	return Color(r, g, b, 1.0)

# ===================
# STEP-BY-STEP INSTRUCTIONS
# ===================

# OPTION 1: Minimal Setup
# 1. Create new 3D Scene
# 2. Copy the "All-in-one script" above
# 3. Save as MinimalGlitch.gd  
# 4. Attach to root Node3D
# 5. Run scene - Done!

# OPTION 2: Full Setup
# 1. Create AdvancedGlitchSystem.gd (main system)
# 2. Create glitch_post_process.gdshader (shader)
# 3. Create new 3D Scene
# 4. Attach AdvancedGlitchSystem.gd to root
# 5. Run scene

# OPTION 3: Complete Setup with UI
# 1. Create all files from previous artifacts
# 2. Create new 3D Scene  
# 3. Attach GlitchDemo.gd (Complete Scene Setup)
# 4. Run scene

# ===================
# COMMON ISSUES & FIXES
# ===================

# Issue: "Nothing appears"
# Fix: Make sure you have a camera looking at the origin

# Issue: "Shader errors"  
# Fix: The post-processing shader is optional, system works without it

# Issue: "Script errors"
# Fix: Check that all function names match exactly

# Issue: "Poor performance"
# Fix: Reduce trail_length or number of demo objects

# ===================
# WHAT YOU'LL SEE
# ===================

# The system creates:
# - 15 cubes in a 5x3 grid
# - Each cube shows different glitch effects
# - Colors shift, corrupt, and glitch in real-time
# - Bit manipulation effects like crushing, XOR patterns
# - Digital corruption simulation
# - All running at 60+ FPS

# Controls (if using full setup):
# - SPACE: Toggle auto-animation
# - R: Reset system  
# - G: New random seed
# - 1-5: Toggle effect layers
# - ESC: Toggle UI
