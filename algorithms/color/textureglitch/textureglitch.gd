extends Node3D

# ═══════════════════════════════════════════════════════════════════
# LAYERED ANIMATED TEXTURE SYSTEM v2.0
# Complete rewrite with better architecture and error handling
# ═══════════════════════════════════════════════════════════════════

class_name LayeredTextureSystem

# ===================
# CONFIGURATION
# ===================

@export_group("Layer Settings")
@export var num_layers: int = 4
@export var texture_size: int = 128
@export var layer_depth_spacing: float = 0.03

@export_group("Animation")
@export var animation_speed: float = 1.0
@export var enable_layer_separation: bool = true
@export var separation_strength: float = 0.1

@export_group("Glitch Effects")
@export var glitch_intensity: float = 0.8
@export var update_frequency: float = 30.0  # Updates per second
@export var corruption_chance: float = 0.1

# ===================
# CORE CLASSES
# ===================

class LayeredObject:
	var container: Node3D
	var layers: Array[Node3D] = []
	var materials: Array[StandardMaterial3D] = []
	var textures: Array[ImageTexture] = []
	var glitch_type: String = ""
	var animation_data: Dictionary = {}
	var is_valid: bool = true
	
	func _init(parent: Node3D, name: String, position: Vector3, type: String):
		container = Node3D.new()
		container.name = name
		container.position = position
		glitch_type = type
		parent.add_child(container)
		
		# Initialize animation data
		animation_data = {
			"time_offset": randf() * PI * 2,
			"corruption_timer": 0.0,
			"separation_active": false,
			"layer_offsets": []
		}
	
	func is_container_valid() -> bool:
		return container != null and is_instance_valid(container)
	
	func cleanup():
		if is_container_valid():
			container.queue_free()
		layers.clear()
		materials.clear()  
		textures.clear()
		is_valid = false

class TextureLayer:
	var mesh_node: CSGBox3D
	var material: StandardMaterial3D
	var texture: ImageTexture
	var buffer: PackedByteArray
	var layer_index: int
	var blend_mode: BaseMaterial3D.BlendMode
	
	func _init(index: int, size: int):
		layer_index = index
		buffer = PackedByteArray()
		buffer.resize(size * size * 4)  # RGBA
		
		# Set blend mode based on layer
		match index:
			0: blend_mode = BaseMaterial3D.BLEND_MODE_MIX
			1: blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			2: blend_mode = BaseMaterial3D.BLEND_MODE_MIX
			_: blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	
	func create_mesh(depth: float) -> CSGBox3D:
		mesh_node = CSGBox3D.new()
		mesh_node.size = Vector3(3.0, 3.0, 0.1 + depth)
		mesh_node.name = "Layer_" + str(layer_index)
		return mesh_node
	
	func create_material() -> StandardMaterial3D:
		material = StandardMaterial3D.new()
		material.flags_transparent = true
		material.flags_unshaded = true
		material.blend_mode = blend_mode
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		
		# Layer-specific colors
		var colors = [
			Color(1.0, 0.2, 0.2, 0.8),  # Red
			Color(0.2, 1.0, 0.2, 0.6),  # Green  
			Color(0.2, 0.2, 1.0, 0.7),  # Blue
			Color(1.0, 1.0, 0.2, 0.5)   # Yellow
		]
		
		material.albedo_color = colors[layer_index % colors.size()]
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.3
		
		return material
	
	func create_texture(size: int):
		var image = Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, buffer)
		texture = ImageTexture.new()
		texture.set_image(image)
		
		if material:
			material.albedo_texture = texture
			material.emission_texture = texture
	
	func update_texture(size: int):
		if texture and buffer.size() > 0:
			var image = Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, buffer)
			texture.set_image(image)

# ===================
# MAIN SYSTEM
# ===================

var time: float = 0.0
var update_timer: float = 0.0
var objects: Array[LayeredObject] = []

# Glitch pattern generators
var noise_generator: FastNoiseLite
var wave_patterns: Array[Dictionary] = []

func _ready():
	initialize_system()
	create_demo_objects()
	setup_scene_environment()
	print("✨ Layered Texture System v2.0 Ready!")

# ===================
# SYSTEM INITIALIZATION
# ===================

func initialize_system():
	print("🔄 Initializing Layered Texture System...")
	
	# Setup noise generator
	noise_generator = FastNoiseLite.new()
	noise_generator.seed = randi()
	noise_generator.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Create wave patterns
	for i in range(8):
		wave_patterns.append({
			"frequency": 0.5 + randf() * 2.0,
			"amplitude": 0.5 + randf() * 0.5,
			"phase": randf() * PI * 2,
			"speed": 0.8 + randf() * 1.4
		})

func create_demo_objects():
	var object_configs = [
		{"name": "Datamosh Layers", "pos": Vector3(-9, 3, 0), "type": "datamosh"},
		{"name": "Chromatic Split", "pos": Vector3(-3, 3, 0), "type": "chromatic"},
		{"name": "Digital Decay", "pos": Vector3(3, 3, 0), "type": "decay"},
		{"name": "Buffer Cascade", "pos": Vector3(9, 3, 0), "type": "cascade"},
		{"name": "Pixel Sort", "pos": Vector3(-9, -3, 0), "type": "pixel_sort"},
		{"name": "Bit Crush", "pos": Vector3(-3, -3, 0), "type": "bit_crush"},
		{"name": "Memory Leak", "pos": Vector3(3, -3, 0), "type": "memory_leak"},
		{"name": "Quantum Glitch", "pos": Vector3(9, -3, 0), "type": "quantum"}
	]
	
	for config in object_configs:
		create_layered_object(config.name, config.pos, config.type)

func create_layered_object(name: String, pos: Vector3, glitch_type: String):
	var obj = LayeredObject.new(self, name, pos, glitch_type)
	
	# Create layers
	for layer_idx in range(num_layers):
		var layer = TextureLayer.new(layer_idx, texture_size)
		
		# Create mesh
		var mesh = layer.create_mesh(layer_idx * layer_depth_spacing)
		obj.container.add_child(mesh)
		
		# Create material
		var material = layer.create_material()
		mesh.material_override = material
		
		# Generate initial texture
		generate_layer_texture(layer, glitch_type, 0.0)
		layer.create_texture(texture_size)
		
		# Store references
		obj.layers.append(mesh)
		obj.materials.append(material)
		obj.textures.append(layer.texture)
		
		# Initialize layer offset
		obj.animation_data.layer_offsets.append(Vector3(
			randf_range(-0.05, 0.05),
			randf_range(-0.05, 0.05),
			layer_idx * layer_depth_spacing
		))
	
	# Add label
	var label = Label3D.new()
	label.text = name
	label.position = Vector3(0, -2.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.CYAN
	obj.container.add_child(label)
	
	objects.append(obj)

func setup_scene_environment():
	# Camera
	var camera = Camera3D.new()
	camera.position = Vector3(0, 4, 15)
	add_child(camera)
	camera.look_at_from_position(camera.position, Vector3.ZERO, Vector3.UP)
	
	# Camera animation
	animate_camera(camera)
	
	# Lighting
	setup_lighting()
	
	# Environment
	setup_world_environment()

func animate_camera(camera: Camera3D):
	var tween = create_tween()
	tween.set_loops()
	
	tween.tween_method(
		func(angle): 
			if is_instance_valid(camera):
				camera.position = Vector3(sin(angle) * 12, 4, cos(angle) * 12)
				camera.look_at_from_position(camera.position, Vector3.ZERO, Vector3.UP),
		0.0, PI * 2.0, 20.0
	)

func setup_lighting():
	# Main directional light
	var main_light = DirectionalLight3D.new()
	main_light.light_energy = 1.0
	main_light.rotation_degrees = Vector3(-45, 30, 0)
	main_light.shadow_enabled = true
	add_child(main_light)
	
	# Colored accent lights
	var colors = [Color.RED, Color.GREEN, Color.BLUE, Color.MAGENTA]
	
	for i in range(4):
		var light = SpotLight3D.new()
		light.light_color = colors[i]
		light.light_energy = 1.5
		light.spot_range = 20.0
		light.spot_angle = 45.0
		
		var angle = i * PI * 0.5
		light.position = Vector3(cos(angle) * 8, 6, sin(angle) * 8)
		add_child(light)
		light.look_at_from_position(light.position, Vector3.ZERO, Vector3.UP)

func setup_world_environment():
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.08)
	
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.15
	
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.1, 0.3)
	env.fog_density = 0.008
	
	world_env.environment = env
	add_child(world_env)

# ===================
# MAIN UPDATE LOOP
# ===================

func _process(delta):
	time += delta * animation_speed
	update_timer += delta
	
	# Update at specified frequency
	if update_timer >= (1.0 / update_frequency):
		update_all_objects()
		update_timer = 0.0
	
	# Update animations every frame
	update_animations(delta)

func update_all_objects():
	for obj in objects:
		if not obj.is_container_valid():
			continue
		
		update_object_textures(obj)

func update_object_textures(obj: LayeredObject):
	for layer_idx in range(obj.layers.size()):
		if layer_idx < obj.textures.size():
			# Create new layer data
			var layer = TextureLayer.new(layer_idx, texture_size)
			generate_layer_texture(layer, obj.glitch_type, time + obj.animation_data.time_offset)
			layer.update_texture(texture_size)
			
			# Update existing texture
			if obj.textures[layer_idx] and is_instance_valid(obj.textures[layer_idx]):
				var image = Image.create_from_data(texture_size, texture_size, false, Image.FORMAT_RGBA8, layer.buffer)
				obj.textures[layer_idx].set_image(image)

func update_animations(delta: float):
	for obj in objects:
		if not obj.is_container_valid():
			continue
		
		update_layer_positions(obj, delta)
		update_material_properties(obj, delta)

func update_layer_positions(obj: LayeredObject, delta: float):
	if not enable_layer_separation:
		return
	
	for i in range(obj.layers.size()):
		var layer = obj.layers[i]
		if not is_instance_valid(layer):
			continue
		
		var base_offset = obj.animation_data.layer_offsets[i]
		var time_val = time + obj.animation_data.time_offset
		
		# Animated separation
		var separation = Vector3(
			sin(time_val * 2.0 + i * 0.5) * separation_strength,
			cos(time_val * 1.5 + i * 0.7) * separation_strength,
			base_offset.z
		)
		
		# Apply glitch-specific movement
		separation += get_glitch_specific_movement(obj.glitch_type, i, time_val)
		
		layer.position = base_offset + separation
		
		# Rotation animation
		layer.rotation.z = time_val * (0.2 + i * 0.1)

func get_glitch_specific_movement(glitch_type: String, layer_idx: int, t: float) -> Vector3:
	match glitch_type:
		"datamosh":
			return Vector3(
				sin(t * 4.0 + layer_idx) * 0.02,
				cos(t * 3.0 + layer_idx) * 0.02,
				0
			)
		"chromatic":
			return Vector3((layer_idx - 1.5) * 0.03, 0, 0)
		"cascade":
			return Vector3(0, sin(t * 2.0 - layer_idx * 0.5) * 0.04, 0)
		"quantum":
			return Vector3(
				noise_generator.get_noise_2d(t * 2, layer_idx) * 0.02,
				noise_generator.get_noise_2d(t * 3, layer_idx + 10) * 0.02,
				0
			)
		_:
			return Vector3.ZERO

func update_material_properties(obj: LayeredObject, delta: float):
	for i in range(obj.materials.size()):
		var material = obj.materials[i]
		if not is_instance_valid(material):
			continue
		
		# Animate emission intensity
		var pulse = sin(time * 3.0 + i + obj.animation_data.time_offset) * 0.3 + 0.7
		material.emission_energy = pulse
		
		# Update transparency
		var current_color = material.albedo_color
		var alpha_pulse = sin(time * 1.5 + i) * 0.1 + 0.9
		material.albedo_color = Color(current_color.r, current_color.g, current_color.b, current_color.a * alpha_pulse)

# ===================
# TEXTURE GENERATION
# ===================

func generate_layer_texture(layer: TextureLayer, glitch_type: String, t: float):
	var size = texture_size
	
	for y in range(size):
		for x in range(size):
			var pixel_idx = (y * size + x) * 4
			var uv = Vector2(float(x) / size, float(y) / size)
			
			var color = get_pattern_color(uv, layer.layer_index, glitch_type, t)
			
			layer.buffer[pixel_idx] = int(color.r * 255)
			layer.buffer[pixel_idx + 1] = int(color.g * 255)
			layer.buffer[pixel_idx + 2] = int(color.b * 255)
			layer.buffer[pixel_idx + 3] = int(color.a * 255)

func get_pattern_color(uv: Vector2, layer_idx: int, glitch_type: String, t: float) -> Color:
	match glitch_type:
		"datamosh":
			return generate_datamosh_pattern(uv, layer_idx, t)
		"chromatic":
			return generate_chromatic_pattern(uv, layer_idx, t)
		"decay":
			return generate_decay_pattern(uv, layer_idx, t)
		"cascade":
			return generate_cascade_pattern(uv, layer_idx, t)
		"pixel_sort":
			return generate_pixel_sort_pattern(uv, layer_idx, t)
		"bit_crush":
			return generate_bit_crush_pattern(uv, layer_idx, t)
		"memory_leak":
			return generate_memory_leak_pattern(uv, layer_idx, t)
		"quantum":
			return generate_quantum_pattern(uv, layer_idx, t)
		_:
			return Color.WHITE

# ===================
# PATTERN GENERATORS
# ===================

func generate_datamosh_pattern(uv: Vector2, layer: int, t: float) -> Color:
	var motion = Vector2(sin(t * 3 + uv.x * 8), cos(t * 2 + uv.y * 6)) * 0.1
	var shifted_uv = uv + motion * (layer + 1) * 0.3
	
	var noise = noise_generator.get_noise_2d(shifted_uv.x * 10, shifted_uv.y * 10 + t * 2)
	var intensity = noise * 0.5 + 0.5
	
	var colors = [
		Color(intensity, 0.2, 0.2, 0.8),
		Color(0.2, intensity, 0.2, 0.6),
		Color(0.2, 0.2, intensity, 0.7),
		Color(intensity, intensity, 0.2, 0.5)
	]
	
	return colors[layer % colors.size()]

func generate_chromatic_pattern(uv: Vector2, layer: int, t: float) -> Color:
	var shift = (layer - 1.5) * 0.02
	var shifted_uv = uv + Vector2(shift, 0)
	
	var pattern = sin(shifted_uv.x * PI * 15 + t * 3) * 0.5 + 0.5
	
	match layer:
		0: return Color(pattern, 0.0, 0.0, 0.8)
		1: return Color(0.0, pattern, 0.0, 0.8)
		2: return Color(0.0, 0.0, pattern, 0.8)
		_: return Color(pattern * 0.5, pattern * 0.5, pattern, 0.6)

func generate_decay_pattern(uv: Vector2, layer: int, t: float) -> Color:
	var decay_noise = noise_generator.get_noise_3d(uv.x * 8, uv.y * 8, t * 0.5)
	var corruption = abs(decay_noise) * glitch_intensity
	
	var base_intensity = sin(t * 0.3 + layer) * 0.3 + 0.7
	var final_intensity = base_intensity * (1.0 - corruption * 0.5)
	
	return Color(
		final_intensity * (1.0 - corruption * 0.3),
		final_intensity * 0.6,
		final_intensity * 0.4,
		0.7
	)

func generate_cascade_pattern(uv: Vector2, layer: int, t: float) -> Color:
	var wave_pos = fmod((t * 1.5 - layer * 0.3), 1.0)
	var distance_to_wave = abs(uv.y - wave_pos)
	var cascade_intensity = exp(-distance_to_wave * 12.0)
	
	var corruption = sin(uv.x * PI * 20 + t * 5) * cascade_intensity
	
	return Color(
		cascade_intensity,
		0.3 + corruption * 0.4,
		0.3 + corruption * 0.4,
		cascade_intensity * 0.8 + 0.2
	)

func generate_pixel_sort_pattern(uv: Vector2, layer: int, t: float) -> Color:
	var sort_trigger = sin(t * 2 + int(uv.x * 12) * 0.5) > 0.3
	var brightness = uv.y
	
	if sort_trigger:
		brightness = smoothstep(0.0, 1.0, uv.y + layer * 0.2)
	
	var sorted_color = (brightness + layer * 0.3) % 1.0
	
	return Color(sorted_color, sorted_color * 0.8, sorted_color * 0.6, 0.7)

func generate_bit_crush_pattern(uv: Vector2, layer: int, t: float) -> Color:
	var bit_levels = pow(2, 6 - layer)  # Different bit depths
	
	var pattern = sin(uv.x * PI * 10) * cos(uv.y * PI * 8) + sin(t * 2)
	var crushed = floor(pattern * bit_levels) / bit_levels
	
	var intensity = crushed * 0.5 + 0.5
	
	return Color(intensity, intensity * 0.7, intensity * 0.9, 0.6)

func generate_memory_leak_pattern(uv: Vector2, layer: int, t: float) -> Color:
	# Create "leak" spots that grow over time
	var leak_centers = [
		Vector2(0.25, 0.25), Vector2(0.75, 0.25),
		Vector2(0.25, 0.75), Vector2(0.75, 0.75)
	]
	
	var total_leak = 0.0
	for i in range(leak_centers.size()):
		var distance = uv.distance_to(leak_centers[i])
		var leak_size = 0.1 + sin(t + i * PI * 0.5) * 0.05
		if distance < leak_size:
			total_leak += (leak_size - distance) / leak_size
	
	# Accumulate leaks over time
	total_leak *= (1.0 + sin(t * 0.2) * 0.5)
	
	return Color(
		total_leak,
		total_leak * 0.6,
		total_leak * 0.3,
		min(total_leak, 1.0) * 0.8
	)

func generate_quantum_pattern(uv: Vector2, layer: int, t: float) -> Color:
	# Quantum superposition simulation
	var quantum_noise = noise_generator.get_noise_3d(uv.x * 20, uv.y * 20, t * 2 + layer)
	var uncertainty = abs(quantum_noise)
	
	# Two quantum states
	var state_a = sin(uv.x * PI * 25 + t * 4) * 0.5 + 0.5
	var state_b = cos(uv.y * PI * 20 + t * 3) * 0.5 + 0.5
	
	# Collapse probability
	# Collapse probability
	var collapse = 1.0 if uncertainty >= 0.7 else 0.0
	var superposition = (state_a + state_b) / 2.0
	
	var final_state = lerp(superposition, quantum_noise * 0.5 + 0.5, collapse)

	
	return Color(
		final_state,
		final_state * 0.7,
		final_state * 0.9,
		0.6 + uncertainty * 0.4
	)

# ===================
# EFFECT TRIGGERS
# ===================

func trigger_layer_explosion(obj_index: int):
	if obj_index >= objects.size():
		return
		
	var obj = objects[obj_index]
	if not obj.is_container_valid():
		return
		
	print("💥 Layer explosion on: ", obj.container.name)
	
	for i in range(obj.layers.size()):
		var layer = obj.layers[i]
		if not is_instance_valid(layer):
			continue
		
		var explosion_dir = Vector3(
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5),
			randf_range(0.2, 1.0)
		)
		
		var tween = create_tween()
		tween.parallel().tween_property(layer, "position", explosion_dir, 1.5)
		tween.parallel().tween_property(layer, "rotation", Vector3(randf() * PI, randf() * PI, randf() * PI), 1.5)
		tween.parallel().tween_property(layer, "scale", Vector3.ONE * (1.5 + i * 0.3), 1.5)
		
		tween.tween_delay(1.0)
		tween.parallel().tween_property(layer, "position", Vector3.ZERO, 1.0)
		tween.parallel().tween_property(layer, "rotation", Vector3.ZERO, 1.0) 
		tween.parallel().tween_property(layer, "scale", Vector3.ONE, 1.0)

func trigger_chromatic_separation(obj_index: int):
	if obj_index >= objects.size():
		return
		
	var obj = objects[obj_index]
	if not obj.is_container_valid():
		return
	
	print("🌈 Chromatic separation on: ", obj.container.name)
	
	var offsets = [
		Vector3(-0.2, 0, 0),   # Red left
		Vector3(0, 0, 0),      # Green center
		Vector3(0.2, 0, 0),    # Blue right
		Vector3(0, 0.2, 0)     # Yellow up
	]
	
	for i in range(min(obj.layers.size(), offsets.size())):
		var layer = obj.layers[i]
		if not is_instance_valid(layer):
			continue
		
		var tween = create_tween()
		tween.tween_property(layer, "position", offsets[i], 1.0)
		tween.tween_delay(2.0)
		tween.tween_property(layer, "position", Vector3.ZERO, 1.0)

func trigger_system_wide_glitch():
	print("⚡ SYSTEM-WIDE GLITCH ACTIVATED!")
	
	for i in range(objects.size()):
		get_tree().create_timer(i * 0.4).timeout.connect(
			func(): trigger_layer_explosion(i)
		)

# ===================
# INPUT CONTROLS
# ===================

func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		KEY_SPACE:
			enable_layer_separation = !enable_layer_separation
			print("🔄 Layer separation: ", enable_layer_separation)
		
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
			var obj_idx = event.keycode - KEY_1
			trigger_layer_explosion(obj_idx)
		
		KEY_C:
			for i in range(min(4, objects.size())):
				trigger_chromatic_separation(i)
		
		KEY_X:
			trigger_system_wide_glitch()
		
		KEY_R:
			# Reset all objects
			for obj in objects:
				if obj.is_container_valid():
					for layer in obj.layers:
						if is_instance_valid(layer):
							layer.position = Vector3.ZERO
							layer.rotation = Vector3.ZERO
							layer.scale = Vector3.ONE
		
		KEY_PLUS, KEY_EQUAL:
			animation_speed = min(animation_speed * 1.2, 3.0)
			print("🎮 Animation speed: ", animation_speed)
		
		KEY_MINUS:
			animation_speed = max(animation_speed * 0.8, 0.1)
			print("🎮 Animation speed: ", animation_speed)
		
		KEY_H:
			print_help()

func print_help():
	print("\n🎮 LAYERED TEXTURE SYSTEM v2.0 CONTROLS")
	print("════════════════════════════════════════")
	print("  SPACE - Toggle layer separation")
	print("  1-8   - Layer explosion on objects 1-8")
	print("  C     - Chromatic separation (first 4 objects)")
	print("  X     - System-wide glitch")
	print("  R     - Reset all objects")
	print("  +/-   - Animation speed")
	print("  H     - Show help")
	print("\n✨ Features:")
	print("  • 8 objects with unique glitch types")
	print("  • 4 texture layers per object")
	print("  • Real-time procedural textures")
	print("  • Dynamic layer separation")
	print("  • Advanced blending modes")

func _notification(what):
	if what == NOTIFICATION_READY:
		print("\n🚀 LAYERED TEXTURE SYSTEM v2.0 INITIALIZED")
		print("📊 Objects: ", objects.size())
		print("🎨 Layers per object: ", num_layers)
		print("📱 Texture resolution: ", texture_size, "x", texture_size)
		print("⚡ Update frequency: ", update_frequency, " FPS")
		print("\nPress H for help!")

func _exit_tree():
	# Cleanup
	for obj in objects:
		obj.cleanup()
