extends Node3D

# Optimized Layered Animated Texture System (Shader Based)
# Separates textures into multiple animated layers driven by shader algorithms

const GLITCH_SHADER = preload("res://algorithms/color/textureglitch/glitch.gdshader")

# ===================
# CONFIGURATION
# ===================

@export_group("Texture Layers")
@export var num_texture_layers: int = 4
@export var layer_resolution: int = 128 # Unused in shader mode but kept for compat
@export var layer_blend_modes: Array[String] = ["multiply", "add", "overlay", "screen"]
@export var enable_layer_separation: bool = true

@export_group("Animation Settings")
@export var animation_speed: float = 1.0
@export var rotation_speed: float = 0.5
@export var scale_animation: bool = true

@export_group("Glitch Parameters")
@export var separation_distance: float = 0.05
@export var chromatic_shift: float = 0.02 # Used in transform separation

# ===================
# CORE VARIABLES
# ===================

var time := 0.0
var demo_objects := []
var texture_layers := {}  # object -> layers array
var layer_materials := {}  # object -> materials array  
var layer_animations := {}  # object -> animation data
var glitch_controllers := {}  # object -> glitch control data

var GLITCH_TYPE_MAP = {
	"datamosh": 0,
	"chromatic": 1,
	"decay": 2,
	"cascade": 3,
	"pixel_sort": 4,
	"bit_crush": 5,
	"memory_leak": 6,
	"quantum": 7
}

func _ready():
	print("🚀 Starting Optimized Glitch System")
	initialize_layer_system()
	create_demo_objects()
	setup_glitch_controllers()

func initialize_layer_system():
	setup_scene_environment()

func setup_scene_environment():
	var camera = Camera3D.new()
	camera.position = Vector3(0, 3, 12)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	add_child(camera)
	
	var camera_tween = create_tween()
	camera_tween.set_loops()
	camera_tween.tween_method(func(pos): camera.position = pos, Vector3(8, 3, 8), Vector3(-8, 3, 8), 10.0)
	camera_tween.tween_method(func(pos): camera.look_at(Vector3.ZERO, Vector3.UP); camera.position = pos, Vector3(-8, 3, 8), Vector3(8, 3, 8), 10.0)
	
	setup_dynamic_lighting()

func setup_dynamic_lighting():
	var key_light = DirectionalLight3D.new()
	key_light.light_energy = 1.2
	key_light.rotation_degrees = Vector3(-45, 30, 0)
	add_child(key_light)

func create_demo_objects():
	var object_configs = [
		{"name": "Datamosh Layers", "pos": Vector3(-6, 2, 0), "type": "datamosh"},
		{"name": "Chromatic Split", "pos": Vector3(-2, 2, 0), "type": "chromatic"},
		{"name": "Digital Decay", "pos": Vector3(2, 2, 0), "type": "decay"},
		{"name": "Buffer Cascade", "pos": Vector3(6, 2, 0), "type": "cascade"},
		{"name": "Pixel Sort", "pos": Vector3(-6, -2, 0), "type": "pixel_sort"},
		{"name": "Bit Crush", "pos": Vector3(-2, -2, 0), "type": "bit_crush"},
		{"name": "Memory Leak", "pos": Vector3(2, -2, 0), "type": "memory_leak"},
		{"name": "Quantum Glitch", "pos": Vector3(6, -2, 0), "type": "quantum"}
	]
	
	for config in object_configs:
		create_layered_object(config.name, config.pos, config.type)

func create_layered_object(name: String, pos: Vector3, glitch_type: String):
	var container = Node3D.new()
	container.name = name
	container.position = pos
	add_child(container)
	
	var layers = []
	var materials = []
	
	for layer_index in range(num_texture_layers):
		var layer_obj = create_layer_object(layer_index, glitch_type)
		container.add_child(layer_obj)
		layers.append(layer_obj)
		materials.append(layer_obj.material_override)
	
	demo_objects.append(container)
	texture_layers[container] = layers
	layer_materials[container] = materials
	
	initialize_layer_animations(container, glitch_type)
	add_object_label(container, name)

func add_object_label(container: Node3D, text: String):
	var label = Label3D.new()
	label.text = text
	label.font_size = 48
	label.position = Vector3(0, 2.5, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	container.add_child(label)

func create_layer_object(layer_index: int, glitch_type: String) -> CSGBox3D:
	var layer = CSGBox3D.new()
	layer.size = Vector3(3.0, 3.0, 0.05 + layer_index * 0.02)
	layer.name = "Layer_" + str(layer_index)
	
	var material = create_layer_material(layer_index, glitch_type)
	layer.material_override = material
	
	return layer

func create_layer_material(layer_index: int, glitch_type: String) -> ShaderMaterial:
	var material = ShaderMaterial.new()
	material.shader = GLITCH_SHADER
	
	# Set simple properties
	material.set_shader_parameter("layer_index", layer_index)
	material.set_shader_parameter("glitch_type", GLITCH_TYPE_MAP.get(glitch_type, 0))
	material.set_shader_parameter("time", 0.0)
	
	# Layer Colors
	var col = Color.WHITE
	match layer_index:
		0: col = Color(1.0, 0.3, 0.3, 0.8)
		1: col = Color(0.3, 1.0, 0.3, 0.6)
		2: col = Color(0.3, 0.3, 1.0, 0.7)
		3: col = Color(1.0, 1.0, 0.3, 0.5)
	
	material.set_shader_parameter("layer_color", col)
	return material

func initialize_layer_animations(container: Node3D, glitch_type: String):
	var anim_data = {
		"type": glitch_type,
		"layer_offsets": [],
		"rotation_speeds": [],
		"scale_factors": []
	}
	for i in range(num_texture_layers):
		anim_data.layer_offsets.append(Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), i * 0.1))
		anim_data.rotation_speeds.append(randf_range(-1.0, 1.0) * rotation_speed)
		anim_data.scale_factors.append(1.0 + randf_range(-0.2, 0.2))
	
	layer_animations[container] = anim_data

func setup_glitch_controllers():
	for container in demo_objects:
		glitch_controllers[container] = { "separation_active": false, "animation_active": true }

func _process(delta):
	time += delta * animation_speed
	for container in demo_objects:
		update_layered_object(container, delta)

func update_layered_object(container: Node3D, delta: float):
	if not texture_layers.has(container): return
	
	var layers = texture_layers[container]
	var materials = layer_materials[container]
	var anim_data = layer_animations[container]
	var controller = glitch_controllers[container]
	
	if enable_layer_separation and controller.animation_active:
		update_layer_transforms(layers, anim_data)
	
	# Update Shader Uniforms
	for mat in materials:
		if mat is ShaderMaterial:
			mat.set_shader_parameter("time", time)

func update_layer_transforms(layers: Array, anim_data: Dictionary):
	for i in range(layers.size()):
		var layer = layers[i]
		var base_offset = anim_data.layer_offsets[i]
		var rot_speed = anim_data.rotation_speeds[i]
		var s_fact = anim_data.scale_factors[i]
		
		var sep = Vector3(
			sin(time * 2.0 + i) * separation_distance,
			cos(time * 1.5 + i) * separation_distance,
			base_offset.z
		)
		
		if anim_data.type == "datamosh":
			sep += Vector3(sin(time * 5.0 + i)*0.02, cos(time*7.0+i)*0.02, 0)
		elif anim_data.type == "chromatic":
			sep.x += (i - 1.5) * chromatic_shift * 2.0
		elif anim_data.type == "cascade":
			sep.y += sin(time * 3.0 - i * 0.5) * 0.05
			
		layer.position = base_offset + sep
		
		if scale_animation:
			layer.rotation.z = time * rot_speed
			layer.scale = Vector3.ONE * (s_fact + sin(time * 3.0 + i) * 0.1)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			enable_layer_separation = !enable_layer_separation
		elif event.keycode == KEY_PLUS or event.keycode == KEY_EQUAL:
			animation_speed = min(animation_speed * 1.2, 3.0)
		elif event.keycode == KEY_MINUS:
			animation_speed = max(animation_speed * 0.8, 0.1)
