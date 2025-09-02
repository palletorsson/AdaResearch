extends Node3D

# Bit Shifting Color Magic & Glitch Techniques in Godot 4
# Demonstrates various bit manipulation tricks for colors

var time := 0.0
var materials := []
var cubes := []

func _ready():
	setup_color_cubes()
	create_bit_shift_examples()

func _process(delta):
	time += delta
	animate_bit_effects()

func setup_color_cubes():
	# Create a grid of cubes to demonstrate different bit effects
	for i in range(5):
		for j in range(3):
			var cube = CSGBox3D.new()
			cube.size = Vector3(0.8, 0.8, 0.8)
			cube.position = Vector3(i * 2.0 - 4.0, j * 2.0 - 2.0, 0)
			
			var material = StandardMaterial3D.new()
			material.flags_unshaded = true
			cube.material_override = material
			
			cubes.append(cube)
			materials.append(material)
			add_child(cube)

func create_bit_shift_examples():
	# Each cube demonstrates a different bit manipulation technique
	pass

func animate_bit_effects():
	for i in range(cubes.size()):
		var cube = cubes[i]
		var material = materials[i]
		
		match i:
			0: # RGB Channel Shifting
				material.albedo_color = rgb_channel_shift(time)
			1: # Bit Rotation
				material.albedo_color = bit_rotation_color(time)
			2: # Binary Noise
				material.albedo_color = binary_noise_color(time)
			3: # XOR Pattern
				material.albedo_color = xor_pattern_color(time, cube.position)
			4: # Bit Mask Magic
				material.albedo_color = bit_mask_color(time)
			5: # Digital Corruption
				material.albedo_color = digital_corruption(time)
			6: # Chromatic Shift
				material.albedo_color = chromatic_bit_shift(time)
			7: # Quantization Glitch
				material.albedo_color = quantization_glitch(time)
			8: # Binary Fade
				material.albedo_color = binary_fade(time)
			9: # Bit Crush RGB
				material.albedo_color = bit_crush_rgb(time)
			10: # Data Moshing Color
				material.albedo_color = data_mosh_color(time)
			11: # Overflow Aesthetics
				material.albedo_color = overflow_color(time)
			12: # Palette Corruption
				material.albedo_color = palette_corruption(time)
			13: # Memory Leak Visual
				material.albedo_color = memory_leak_visual(time)
			14: # Bit Stream Color
				material.albedo_color = bit_stream_color(time)

# ===================
# COLOR BIT TECHNIQUES
# ===================

func rgb_channel_shift(t: float) -> Color:
	# Shift RGB channels using bit operations
	var base_val = int(sin(t) * 128 + 127)
	
	# Bit shift each channel differently
	var r = float(base_val >> 1) / 255.0
	var g = float((base_val << 1) & 0xFF) / 255.0
	var b = float((base_val >> 2) | (base_val << 6)) / 255.0
	
	return Color(r, g, b, 1.0)

func bit_rotation_color(t: float) -> Color:
	# Rotate bits within color channels
	var val = int(t * 60) % 256
	
	# Rotate bits left and right
	var r_rot = rotate_bits_left(val, 2)
	var g_rot = rotate_bits_right(val, 3)
	var b_rot = rotate_bits_left(val ^ 0xAA, 4)
	
	return Color(r_rot / 255.0, g_rot / 255.0, b_rot / 255.0, 1.0)

func binary_noise_color(t: float) -> Color:
	# Generate color using binary noise patterns
	var seed_val = int(t * 100)
	
	var r = float(binary_noise(seed_val)) / 255.0
	var g = float(binary_noise(seed_val + 1000)) / 255.0
	var b = float(binary_noise(seed_val + 2000)) / 255.0
	
	return Color(r, g, b, 1.0)

func xor_pattern_color(t: float, pos: Vector3) -> Color:
	# Create XOR patterns based on position and time
	var x_int = int(pos.x * 100) + int(t * 50)
	var y_int = int(pos.y * 100) + int(t * 30)
	var z_int = int(pos.z * 100) + int(t * 70)
	
	var r = float((x_int ^ y_int) & 0xFF) / 255.0
	var g = float((y_int ^ z_int) & 0xFF) / 255.0
	var b = float((x_int ^ z_int) & 0xFF) / 255.0
	
	return Color(r, g, b, 1.0)

func bit_mask_color(t: float) -> Color:
	# Use bit masks to create color patterns
	var base = int(sin(t) * 128 + 127)
	
	var r = float(base & 0b11100000) / 255.0
	var g = float((base & 0b00011100) << 3) / 255.0
	var b = float((base & 0b00000011) << 6) / 255.0
	
	return Color(r, g, b, 1.0)

# ===================
# GLITCH TECHNIQUES
# ===================

func digital_corruption(t: float) -> Color:
	# Simulate digital corruption
	var corruption_rate = sin(t * 2.0) * 0.5 + 0.5
	var base_color = Color(0.3, 0.7, 0.9)
	
	if randf() < corruption_rate * 0.1:
		# Random bit flips
		var corrupt_r = corrupt_channel(base_color.r)
		var corrupt_g = corrupt_channel(base_color.g)
		var corrupt_b = corrupt_channel(base_color.b)
		return Color(corrupt_r, corrupt_g, corrupt_b, 1.0)
	
	return base_color

func chromatic_bit_shift(t: float) -> Color:
	# Chromatic aberration using bit shifts
	var base_val = int(cos(t * 1.5) * 100 + 155)
	
	# Shift channels by different amounts
	var r = float(base_val >> 1) / 255.0
	var g = float(base_val) / 255.0
	var b = float(base_val << 1 & 0xFF) / 255.0
	
	return Color(r, g, b, 1.0)

func quantization_glitch(t: float) -> Color:
	# Simulate color quantization errors
	var steps = int(4 + sin(t) * 2)  # Variable bit depth
	
	var r = quantize_channel(sin(t) * 0.5 + 0.5, steps)
	var g = quantize_channel(cos(t * 1.3) * 0.5 + 0.5, steps)
	var b = quantize_channel(sin(t * 0.7) * 0.5 + 0.5, steps)
	
	return Color(r, g, b, 1.0)

func binary_fade(t: float) -> Color:
	# Binary-style fade effect
	var fade_val = int((sin(t) * 0.5 + 0.5) * 8)
	var bit_pattern = create_bit_pattern(fade_val)
	
	var intensity = float(bit_pattern) / 255.0
	return Color(intensity, intensity * 0.3, intensity * 0.7, 1.0)

func bit_crush_rgb(t: float) -> Color:
	# Bit-crushing effect on RGB channels
	var crush_amount = int(2 + sin(t * 0.5) * 2)  # 2-4 bit depth
	
	var r = bit_crush_channel(sin(t) * 0.5 + 0.5, crush_amount)
	var g = bit_crush_channel(cos(t * 1.2) * 0.5 + 0.5, crush_amount)
	var b = bit_crush_channel(sin(t * 0.8) * 0.5 + 0.5, crush_amount)
	
	return Color(r, g, b, 1.0)

func data_mosh_color(t: float) -> Color:
	# Datamoshing-inspired color effect
	var frame_corruption = sin(t * 5.0) > 0.8
	
	if frame_corruption:
		# Corrupt the color data
		var corrupt_val = int(t * 255) % 256
		return Color(
			float(corrupt_val & 0xFF) / 255.0,
			float((corrupt_val >> 2) & 0xFF) / 255.0,
			float((corrupt_val >> 4) & 0xFF) / 255.0,
			1.0
		)
	else:
		return Color(0.4, 0.6, 0.8, 1.0)

func overflow_color(t: float) -> Color:
	# Buffer overflow visual representation
	var overflow_amount = max(0, sin(t * 3.0) - 0.7) * 10
	var base_intensity = 0.2
	
	# When "overflowing", add extra intensity
	var r = base_intensity + overflow_amount
	var g = base_intensity
	var b = base_intensity
	
	# Clamp to valid range (or not, for glitch effect!)
	if overflow_amount > 0:
		r = fmod(r, 2.0)  # Let it wrap around for glitch effect
	
	return Color(r, g, b, 1.0)

func palette_corruption(t: float) -> Color:
	# Simulate palette corruption
	var palette = [
		Color(1.0, 0.0, 0.0),
		Color(0.0, 1.0, 0.0),
		Color(0.0, 0.0, 1.0),
		Color(1.0, 1.0, 0.0)
	]
	
	var index = int(t * 2.0) % palette.size()
	var corruption_chance = sin(t * 7.0) > 0.9
	
	if corruption_chance:
		# Corrupt palette index with bit flip
		index = index ^ 0b10  # Flip a bit
		index = index % palette.size()
	
	return palette[index]

func memory_leak_visual(t: float) -> Color:
	# Visual representation of memory leaks
	var leak_accumulation = fmod(t * 0.1, 1.0)  # Slow accumulation
	var leak_intensity = leak_accumulation * leak_accumulation  # Quadratic growth
	
	# Memory leak causes gradual color shift and intensity increase
	var base_color = Color(0.2, 0.4, 0.6)
	return base_color + Color(leak_intensity, 0, leak_intensity, 0)

func bit_stream_color(t: float) -> Color:
	# Visualize bit streams as colors
	var stream_data = int(t * 1000) % 1024
	
	# Extract different bit ranges for RGB
	var r_bits = (stream_data & 0b1111000000) >> 6
	var g_bits = (stream_data & 0b0000111100) >> 2
	var b_bits = (stream_data & 0b0000000011) << 2
	
	return Color(
		float(r_bits) / 15.0,
		float(g_bits) / 15.0,
		float(b_bits) / 15.0,
		1.0
	)

# ===================
# UTILITY FUNCTIONS
# ===================

func rotate_bits_left(value: int, positions: int) -> int:
	# Rotate 8-bit value left
	positions = positions % 8
	return ((value << positions) | (value >> (8 - positions))) & 0xFF

func rotate_bits_right(value: int, positions: int) -> int:
	# Rotate 8-bit value right  
	positions = positions % 8
	return ((value >> positions) | (value << (8 - positions))) & 0xFF

func binary_noise(seed: int) -> int:
	# Simple pseudo-random binary noise
	var x = seed
	x = ((x >> 16) ^ x) * 0x45d9f3b
	x = ((x >> 16) ^ x) * 0x45d9f3b
	x = (x >> 16) ^ x
	return x & 0xFF

func corrupt_channel(channel: float) -> float:
	# Introduce bit corruption to a color channel
	var int_val = int(channel * 255)
	var corrupted = int_val ^ (1 << (randi() % 8))  # Flip random bit
	return float(corrupted & 0xFF) / 255.0

func quantize_channel(value: float, levels: int) -> float:
	# Quantize color channel to specific bit depth
	var step = 1.0 / float(levels - 1)
	return floor(value / step) * step

func create_bit_pattern(pattern_val: int) -> int:
	# Create 8-bit pattern from input value
	var pattern = 0
	for i in range(8):
		if (pattern_val >> i) & 1:
			pattern |= (1 << i)
	return pattern

func bit_crush_channel(value: float, bit_depth: int) -> float:
	# Bit-crush a color channel
	var levels = 1 << bit_depth  # 2^bit_depth levels
	var step = 1.0 / float(levels - 1)
	return floor(value / step) * step