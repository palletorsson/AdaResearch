extends Node3D

# Advanced Glitch & Bit Manipulation System for Godot 4
# Comprehensive implementation of digital corruption techniques

# Core system variables
var time := 0.0
var glitch_intensity := 0.5
var corruption_seed := 12345

# Visual elements
var demo_objects := []
var materials := []
var shaders := {}

# Glitch parameters
var datamosh_vectors := []
var pixel_sort_data := []
var corruption_buffer := []

# UI Controls
@export var auto_animate: bool = true
@export var glitch_strength: float = 0.5 : set = set_glitch_strength
@export var corruption_rate: float = 0.1 : set = set_corruption_rate
@export var temporal_speed: float = 1.0 : set = set_temporal_speed

signal glitch_event_triggered(effect_name: String)

func _ready():
	setup_demo_scene()
	initialize_glitch_systems()
	create_ui_controls()
	print("🎨 Advanced Glitch System Initialized!")

func _process(delta):
	time += delta * temporal_speed
	if auto_animate:
		update_all_glitch_effects(delta)

# ===================
# SCENE SETUP
# ===================

func setup_demo_scene():
	# Create demo objects in a grid
	var positions = [
		Vector3(-4, 2, 0),   # Datamoshing
		Vector3(-2, 2, 0),   # Pixel sorting
		Vector3(0, 2, 0),    # Channel corruption
		Vector3(2, 2, 0),    # Memory corruption
		Vector3(4, 2, 0),    # Buffer overflow
		Vector3(-4, 0, 0),   # Bit crushing
		Vector3(-2, 0, 0),   # XOR patterns
		Vector3(0, 0, 0),    # Chromatic shift
		Vector3(2, 0, 0),    # Digital decay
		Vector3(4, 0, 0),    # Palette corruption
		Vector3(-4, -2, 0),  # Quantization
		Vector3(-2, -2, 0),  # Binary fade
		Vector3(0, -2, 0),   # Stream corruption
		Vector3(2, -2, 0),   # Overflow cascade
		Vector3(4, -2, 0)    # Meta-corruption
	]
	
	var effect_names = [
		"Datamoshing", "Pixel Sort", "Channel Corrupt", "Memory Leak", "Buffer Overflow",
		"Bit Crush", "XOR Pattern", "Chromatic Shift", "Digital Decay", "Palette Corrupt",
		"Quantization", "Binary Fade", "Stream Corrupt", "Overflow Cascade", "Meta-Corrupt"
	]
	
	for i in range(positions.size()):
		create_demo_object(positions[i], effect_names[i], i)

func create_demo_object(pos: Vector3, name: String, index: int):
	# Create base geometry
	var obj = CSGBox3D.new()
	obj.size = Vector3(1.5, 1.5, 0.2)
	obj.position = pos
	obj.name = name
	
	# Create material
	var material = StandardMaterial3D.new()
	material.flags_unshaded = true
	material.flags_transparent = true
	obj.material_override = material
	
	# Add label
	var label = Label3D.new()
	label.text = name
	label.position = Vector3(0, -1.0, 0.2)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.WHITE
	obj.add_child(label)
	
	demo_objects.append(obj)
	materials.append(material)
	add_child(obj)

# ===================
# GLITCH SYSTEM INITIALIZATION
# ===================

func initialize_glitch_systems():
	# Initialize datamosh vectors
	datamosh_vectors.clear()
	for i in range(100):
		datamosh_vectors.append({
			"pos": Vector2(randf(), randf()),
			"vel": Vector2(randf() - 0.5, randf() - 0.5) * 0.02,
			"age": 0.0,
			"intensity": randf()
		})
	
	# Initialize pixel sort data
	pixel_sort_data.clear()
	for i in range(64):
		pixel_sort_data.append({
			"value": randf(),
			"sorted": false,
			"corruption_time": 0.0
		})
	
	# Initialize corruption buffer
	corruption_buffer.clear()
	corruption_buffer.resize(256)
	for i in range(corruption_buffer.size()):
		corruption_buffer[i] = i

# ===================
# MAIN UPDATE LOOP
# ===================

func update_all_glitch_effects(delta):
	for i in range(demo_objects.size()):
		var material = materials[i]
		var obj = demo_objects[i]
		
		match i:
			0: # Datamoshing
				material.albedo_color = update_datamosh_effect(delta)
				apply_datamosh_transform(obj, delta)
			1: # Pixel sorting
				material.albedo_color = update_pixel_sort_effect(delta)
			2: # Channel corruption
				material.albedo_color = channel_corruption_effect(time)
			3: # Memory leak
				material.albedo_color = memory_leak_effect(time, delta)
			4: # Buffer overflow
				material.albedo_color = buffer_overflow_effect(time)
				apply_overflow_geometry(obj, time)
			5: # Bit crushing
				material.albedo_color = bit_crushing_effect(time)
			6: # XOR patterns
				material.albedo_color = xor_pattern_effect(time, obj.position)
			7: # Chromatic shift
				material.albedo_color = chromatic_shift_effect(time)
			8: # Digital decay
				material.albedo_color = digital_decay_effect(time, delta)
			9: # Palette corruption
				material.albedo_color = palette_corruption_effect(time)
			10: # Quantization
				material.albedo_color = quantization_effect(time)
			11: # Binary fade
				material.albedo_color = binary_fade_effect(time)
			12: # Stream corruption
				material.albedo_color = stream_corruption_effect(time)
			13: # Overflow cascade
				material.albedo_color = overflow_cascade_effect(time, i)
			14: # Meta-corruption
				material.albedo_color = meta_corruption_effect(time, delta)

# ===================
# ADVANCED GLITCH EFFECTS
# ===================

func update_datamosh_effect(delta) -> Color:
	# Update motion vectors
	for vector in datamosh_vectors:
		vector.pos += vector.vel
		vector.age += delta
		
		# Wrap around screen
		vector.pos.x = fmod(vector.pos.x + 1.0, 1.0)
		vector.pos.y = fmod(vector.pos.y + 1.0, 1.0)
		
		# Decay and regenerate
		if vector.age > 2.0:
			vector.age = 0.0
			vector.pos = Vector2(randf(), randf())
			vector.vel = Vector2(randf() - 0.5, randf() - 0.5) * 0.02
	
	# Calculate color from motion vectors
	var accumulated_color = Vector3.ZERO
	for vector in datamosh_vectors:
		var influence = exp(-vector.age) * vector.intensity
		accumulated_color.x += vector.pos.x * influence
		accumulated_color.y += vector.pos.y * influence  
		accumulated_color.z += vector.vel.length() * influence * 10.0
	
	accumulated_color /= datamosh_vectors.size()
	return Color(accumulated_color.x, accumulated_color.y, accumulated_color.z, 0.8)

func apply_datamosh_transform(obj: Node3D, delta):
	# Apply motion vector corruption to geometry
	var corruption_amount = sin(time * 3.0) * glitch_intensity
	if abs(corruption_amount) > 0.7:
		obj.scale = Vector3(1.0 + corruption_amount * 0.2, 1.0, 1.0)
		obj.rotation.z = corruption_amount * 0.1
	else:
		obj.scale = Vector3.ONE
		obj.rotation.z = 0.0

func update_pixel_sort_effect(delta) -> Color:
	# Update pixel sort simulation
	var sort_triggered = sin(time * 2.0) > 0.8
	
	if sort_triggered:
		# Sort a random segment
		var start_idx = randi() % (pixel_sort_data.size() - 8)
		var segment = pixel_sort_data.slice(start_idx, start_idx + 8)
		segment.sort_custom(func(a, b): return a.value < b.value)
		for i in range(segment.size()):
			pixel_sort_data[start_idx + i] = segment[i]
	
	# Generate color from sorted data
	var r = 0.0
	var g = 0.0
	var b = 0.0
	
	for i in range(min(16, pixel_sort_data.size())):
		var pixel = pixel_sort_data[i]
		r += pixel.value * (float(i) / 16.0)
		g += pixel.value * (1.0 - float(i) / 16.0)
		b += abs(sin(pixel.value * PI))
	
	return Color(r / 16.0, g / 16.0, b / 16.0, 1.0)

func channel_corruption_effect(t) -> Color:
	# Advanced RGB channel corruption
	var base_color = Color(0.6, 0.4, 0.8)
	var corruption_mask = int(t * 50) % 256
	
	# Apply bit corruption to each channel
	var r_bits = int(base_color.r * 255) ^ (corruption_mask & 0b11100000)
	var g_bits = int(base_color.g * 255) ^ ((corruption_mask << 2) & 0b11100000)
	var b_bits = int(base_color.b * 255) ^ ((corruption_mask << 4) & 0b11100000)
	
	# Bit shifting for channel separation
	var r_shifted = (r_bits >> 1) | (r_bits << 7) & 0xFF
	var g_shifted = (g_bits >> 2) | (g_bits << 6) & 0xFF  
	var b_shifted = (b_bits >> 3) | (b_bits << 5) & 0xFF
	
	return Color(r_shifted / 255.0, g_shifted / 255.0, b_shifted / 255.0, 1.0)

func memory_leak_effect(t, delta) -> Color:
	# Simulate memory leak accumulation
	var leaked_memory = 0.0
	var last_cleanup = 0.0
	
	leaked_memory += delta * corruption_rate * 10.0
	
	# Periodic "garbage collection"
	if t - last_cleanup > 3.0:
		leaked_memory *= 0.3
		last_cleanup = t
		emit_signal("glitch_event_triggered", "Memory Cleanup")
	
	# Visual representation of memory pressure
	var pressure = min(leaked_memory / 10.0, 1.0)
	var base_color = Color(0.2, 0.6, 0.3)
	var leak_color = Color(1.0, 0.2, 0.2)
	
	return base_color.lerp(leak_color, pressure)

func buffer_overflow_effect(t) -> Color:
	# Simulate buffer overflow conditions
	var buffer_size = 100.0
	var write_position = fmod(t * 30.0, buffer_size * 1.2)  # Write beyond buffer
	
	var overflow_amount = max(0, write_position - buffer_size) / (buffer_size * 0.2)
	overflow_amount = pow(overflow_amount, 2.0)  # Exponential overflow
	
	if overflow_amount > 0:
		# Overflow condition - chaotic colors
		var chaos_r = float(int(t * 1000) % 256) / 255.0
		var chaos_g = float(int(t * 1337) % 256) / 255.0  
		var chaos_b = float(int(t * 2047) % 256) / 255.0
		return Color(chaos_r, chaos_g, chaos_b, 1.0) * overflow_amount
	else:
		# Normal operation
		return Color(0.1, 0.8, 0.1, 1.0)

func apply_overflow_geometry(obj: Node3D, t):
	# Apply geometric corruption during overflow
	var overflow_detected = fmod(t * 30.0, 120.0) > 100.0
	if overflow_detected:
		obj.scale = Vector3(1.0 + sin(t * 20.0) * 0.3, 1.0 + cos(t * 25.0) * 0.2, 1.0)
		obj.rotation = Vector3(sin(t * 15.0) * 0.2, cos(t * 18.0) * 0.15, 0)
	else:
		obj.scale = Vector3.ONE
		obj.rotation = Vector3.ZERO

# ===================
# BIT MANIPULATION EFFECTS
# ===================

func bit_crushing_effect(t) -> Color:
	# Advanced bit crushing with temporal variation
	var crush_depth = int(2.0 + sin(t * 0.8) * 2.0)  # 2-4 bits
	var temporal_shift = int(t * 100) % 256
	
	# Multi-stage bit crushing
	var stage1 = bit_crush_value(sin(t) * 0.5 + 0.5, crush_depth)
	var stage2 = bit_crush_value(cos(t * 1.3) * 0.5 + 0.5, crush_depth)
	var stage3 = bit_crush_value(sin(t * 0.7) * 0.5 + 0.5, crush_depth)
	
	# Apply temporal corruption
	var r_final = float((int(stage1 * 255) ^ temporal_shift) & 0xFF) / 255.0
	var g_final = float((int(stage2 * 255) ^ (temporal_shift >> 1)) & 0xFF) / 255.0
	var b_final = float((int(stage3 * 255) ^ (temporal_shift >> 2)) & 0xFF) / 255.0
	
	return Color(r_final, g_final, b_final, 1.0)

func xor_pattern_effect(t, pos: Vector3) -> Color:
	# Advanced XOR patterns with position and time
	var x_coord = int((pos.x + 10.0) * 50.0) + int(t * 20.0)
	var y_coord = int((pos.y + 10.0) * 50.0) + int(t * 15.0)
	var z_coord = int((pos.z + 10.0) * 50.0) + int(t * 25.0)
	
	# Multiple XOR operations
	var pattern1 = x_coord ^ y_coord
	var pattern2 = (y_coord ^ z_coord) << 1
	var pattern3 = (x_coord ^ z_coord) << 2
	
	# Combine patterns with bit rotation
	var r_bits = rotate_bits_8(pattern1 & 0xFF, int(t) % 8)
	var g_bits = rotate_bits_8(pattern2 & 0xFF, int(t * 1.5) % 8)
	var b_bits = rotate_bits_8(pattern3 & 0xFF, int(t * 2.0) % 8)
	
	return Color(r_bits / 255.0, g_bits / 255.0, b_bits / 255.0, 1.0)

func chromatic_shift_effect(t) -> Color:
	# Advanced chromatic aberration with bit manipulation
	var base_intensity = sin(t) * 0.5 + 0.5
	var base_bits = int(base_intensity * 255)
	
	# Different bit shifts for each channel
	var r_shift = (base_bits << 2) & 0xFF  # Shift left 2
	var g_shift = base_bits                 # No shift
	var b_shift = (base_bits >> 2) | ((base_bits & 0b11) << 6)  # Rotate right 2
	
	# Add temporal chromatic separation
	var separation = sin(t * 3.0) * 0.2
	
	return Color(
		(r_shift / 255.0) + separation,
		g_shift / 255.0,
		(b_shift / 255.0) - separation,
		1.0
	)

# ===================
# SPECIALIZED EFFECTS  
# ===================

func digital_decay_effect(t, delta) -> Color:
	# Simulate digital decay over time
	var decay_accumulator = 0.0
	var pristine_color = Color(0.2, 0.8, 0.9)
	
	decay_accumulator += delta * corruption_rate
	
	# Apply decay corruption
	var decay_strength = min(decay_accumulator / 5.0, 0.8)
	var noise_factor = sin(t * 10.0 + decay_accumulator) * decay_strength
	
	var corrupted_r = pristine_color.r + noise_factor * 0.3
	var corrupted_g = pristine_color.g - decay_strength * 0.4  
	var corrupted_b = pristine_color.b + sin(decay_accumulator * 2.0) * 0.2
	
	return Color(corrupted_r, corrupted_g, corrupted_b, 1.0)

func palette_corruption_effect(t) -> Color:
	# Simulate palette memory corruption
	var original_palette = [
		Color(1.0, 0.0, 0.0),  # Red
		Color(0.0, 1.0, 0.0),  # Green  
		Color(0.0, 0.0, 1.0),  # Blue
		Color(1.0, 1.0, 0.0),  # Yellow
		Color(1.0, 0.0, 1.0),  # Magenta
		Color(0.0, 1.0, 1.0),  # Cyan
		Color(1.0, 1.0, 1.0),  # White
		Color(0.0, 0.0, 0.0)   # Black
	]
	
	var palette_index = int(t * 2.0) % original_palette.size()
	var corruption_chance = sin(t * 5.0 + palette_index) > 0.7
	
	if corruption_chance:
		# Corrupt palette entry with bit manipulation
		var color = original_palette[palette_index]
		var r_corrupt = int(color.r * 255) ^ (int(t * 100) % 64)
		var g_corrupt = int(color.g * 255) ^ (int(t * 150) % 64)  
		var b_corrupt = int(color.b * 255) ^ (int(t * 200) % 64)
		
		return Color(r_corrupt / 255.0, g_corrupt / 255.0, b_corrupt / 255.0, 1.0)
	
	return original_palette[palette_index]

func meta_corruption_effect(t, delta) -> Color:
	# Corruption that affects the corruption system itself
	var meta_corruption_level = 0.0
	meta_corruption_level += delta * 0.1
	
	# The corruption corrupts its own parameters
	var corrupted_time = t + sin(meta_corruption_level * 5.0) * meta_corruption_level
	var corrupted_intensity = glitch_intensity + cos(meta_corruption_level * 3.0) * 0.3
	
	# Self-referential color calculation
	var base_color = bit_crushing_effect(corrupted_time)
	var overlay_color = xor_pattern_effect(t, Vector3(meta_corruption_level, 0, 0))
	
	return base_color.lerp(overlay_color, sin(meta_corruption_level * 2.0) * 0.5 + 0.5)

# ===================
# UTILITY FUNCTIONS
# ===================

func bit_crush_value(value: float, bits: int) -> float:
	var levels = (1 << bits) - 1  # 2^bits - 1
	return floor(value * levels) / levels

func rotate_bits_8(value: int, positions: int) -> int:
	positions = positions % 8
	return ((value << positions) | (value >> (8 - positions))) & 0xFF

func quantization_effect(t) -> Color:
	# Advanced quantization with temporal dithering
	var dither_pattern = int(t * 100.0) % 4
	var quantize_levels = [2, 4, 8, 16][dither_pattern]
	
	var r = quantize_channel(sin(t) * 0.5 + 0.5, quantize_levels)
	var g = quantize_channel(cos(t * 1.2) * 0.5 + 0.5, quantize_levels)
	var b = quantize_channel(sin(t * 0.8) * 0.5 + 0.5, quantize_levels)
	
	return Color(r, g, b, 1.0)

func quantize_channel(value: float, levels: int) -> float:
	var step = 1.0 / float(levels - 1)
	return floor(value / step) * step

func binary_fade_effect(t) -> Color:
	# Binary fade with bit pattern morphing
	var fade_position = sin(t * 0.5) * 0.5 + 0.5
	var bit_pattern = int(fade_position * 255.0)
	
	# Create morphing bit patterns
	var pattern_a = bit_pattern
	var pattern_b = ~bit_pattern & 0xFF  # Inverted
	var pattern_c = bit_pattern ^ 0xAA   # XOR with alternating pattern
	
	var morph_factor = sin(t * 2.0) * 0.5 + 0.5
	var final_pattern = int(lerp(pattern_a, pattern_c, morph_factor))
	
	var intensity = float(final_pattern) / 255.0
	return Color(intensity, intensity * 0.7, intensity * 0.4, 1.0)

func stream_corruption_effect(t) -> Color:
	# Simulate data stream corruption
	var stream_pos = int(t * 1000.0) % 2048
	
	# Corrupt stream based on position
	var corruption_points = [256, 512, 1024, 1536]  # Specific corruption points
	var is_corrupted = false
	
	for point in corruption_points:
		if abs(stream_pos - point) < 50:
			is_corrupted = true
			break
	
	if is_corrupted:
		# Stream corruption colors
		return Color(
			float((stream_pos ^ 0xFF) & 0xFF) / 255.0,
			float((stream_pos >> 2) & 0xFF) / 255.0,
			float((stream_pos << 2) & 0xFF) / 255.0,
			1.0
		)
	else:
		# Clean stream
		return Color(0.1, 0.1, 0.8, 1.0)

func overflow_cascade_effect(t, index) -> Color:
	# Cascading overflow effect
	var cascade_delay = index * 0.2
	var cascade_time = t - cascade_delay
	
	if cascade_time > 0:
		var overflow_intensity = sin(cascade_time * 4.0) > 0.8
		if overflow_intensity:
			# Cascade overflow
			var cascade_color = buffer_overflow_effect(cascade_time)
			var upstream_influence = bit_crushing_effect(t + index)
			return cascade_color.lerp(upstream_influence, 0.3)
	
	return Color(0.2, 0.2, 0.2, 1.0)  # Inactive state

# ===================
# UI AND CONTROLS
# ===================

func create_ui_controls():
	# Create simple UI for real-time control
	var ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	var control_panel = VBoxContainer.new()
	control_panel.position = Vector2(20, 20)
	ui_layer.add_child(control_panel)
	
	# Intensity slider
	var intensity_label = Label.new()
	intensity_label.text = "Glitch Intensity"
	control_panel.add_child(intensity_label)
	
	var intensity_slider = HSlider.new()
	intensity_slider.min_value = 0.0
	intensity_slider.max_value = 2.0
	intensity_slider.value = glitch_intensity
	intensity_slider.custom_minimum_size = Vector2(200, 30)
	intensity_slider.value_changed.connect(_on_intensity_changed)
	control_panel.add_child(intensity_slider)

func set_glitch_strength(value: float):
	glitch_intensity = value

func set_corruption_rate(value: float):
	corruption_rate = value

func set_temporal_speed(value: float):  
	temporal_speed = value

func _on_intensity_changed(value: float):
	glitch_intensity = value

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				auto_animate = !auto_animate
				print("Auto-animation: ", auto_animate)
			KEY_R:
				initialize_glitch_systems()
				print("🔄 Glitch systems reset!")
			KEY_G:
				corruption_seed = randi()
				print("🎲 New corruption seed: ", corruption_seed)
