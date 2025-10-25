# tesseract_net_space_grid_vr.gd
# Display all tesseract net space variations in a grid for VR viewing
extends Node3D

@export var grid_rows: int = 4
@export var grid_cols: int = 4
@export var spacing_between: float = 15.0

const TesseractNetSpace = preload("res://algorithms/proceduralgeneration/tesseractnetspace/tesseract_net_space.gd")

# Net types
const NET_TYPES = [
	"DALI_CROSS",
	"LINEAR_CHAIN",
	"FOLDED_CHAIN",
	"DOUBLE_CROSS"
]

# Configuration variations
var configurations = []
var net_instances: Array = []

func _ready():
	setup_configurations()
	generate_grid()

func setup_configurations():
	"""Create a list of different configuration combinations"""
	configurations.clear()
	
	# For each net type, create variations
	for net_type_idx in range(NET_TYPES.size()):
		# Variation 1: Small space, no hollow
		configurations.append({
			"net_type": net_type_idx,
			"space_size": Vector3i(3, 2, 3),
			"cube_size": 0.8,
			"spacing": 0.05,
			"hollow": false,
			"rotation_variety": true,
			"offset_pattern": false,
			"color": Color.from_hsv(float(net_type_idx) / 4.0, 0.7, 0.8),
			"name": NET_TYPES[net_type_idx] + " Small"
		})
		
		# Variation 2: Medium space, hollow center
		configurations.append({
			"net_type": net_type_idx,
			"space_size": Vector3i(4, 2, 4),
			"cube_size": 0.6,
			"spacing": 0.1,
			"hollow": true,
			"rotation_variety": true,
			"offset_pattern": false,
			"color": Color.from_hsv(float(net_type_idx) / 4.0, 0.8, 0.9),
			"name": NET_TYPES[net_type_idx] + " Hollow"
		})
		
		# Variation 3: With offset pattern
		configurations.append({
			"net_type": net_type_idx,
			"space_size": Vector3i(3, 3, 3),
			"cube_size": 0.7,
			"spacing": 0.08,
			"hollow": false,
			"rotation_variety": true,
			"offset_pattern": true,
			"color": Color.from_hsv(float(net_type_idx) / 4.0, 0.9, 1.0),
			"name": NET_TYPES[net_type_idx] + " Offset"
		})
		
		# Variation 4: Large and complex
		configurations.append({
			"net_type": net_type_idx,
			"space_size": Vector3i(5, 2, 5),
			"cube_size": 0.5,
			"spacing": 0.12,
			"hollow": true,
			"rotation_variety": false,
			"offset_pattern": true,
			"color": Color.from_hsv(float(net_type_idx) / 4.0, 0.6, 0.95),
			"name": NET_TYPES[net_type_idx] + " Complex"
		})

func generate_grid():
	print("Generating tesseract net space grid...")
	
	# Clear existing
	for net in net_instances:
		if is_instance_valid(net):
			net.queue_free()
	net_instances.clear()
	
	# Calculate grid offset to center
	var grid_offset = Vector3(
		-(grid_cols - 1) * spacing_between / 2.0,
		0,
		-(grid_rows - 1) * spacing_between / 2.0
	)
	
	var config_index = 0
	
	# Create grid
	for row in range(grid_rows):
		for col in range(grid_cols):
			if config_index >= configurations.size():
				break
			
			var config = configurations[config_index]
			var position = grid_offset + Vector3(col * spacing_between, 0, row * spacing_between)
			
			# Create net space instance
			var net = create_net_space(config, position)
			if net:
				add_child(net)
				net_instances.append(net)
			
			config_index += 1
	
	print("Generated %d tesseract net space instances" % net_instances.size())

func create_net_space(config: Dictionary, position: Vector3) -> Node3D:
	"""Create a single tesseract net space instance"""
	var net_node = Node3D.new()
	net_node.set_script(TesseractNetSpace)
	net_node.position = position
	
	# Apply configuration
	net_node.net_type = config.net_type
	net_node.space_size = config.space_size
	net_node.cube_size = config.cube_size
	net_node.spacing = config.spacing
	net_node.create_hollow_center = config.hollow
	net_node.rotation_variety = config.rotation_variety
	net_node.offset_pattern = config.offset_pattern
	net_node.base_color = config.color
	net_node.color_variation = true
	net_node.emission_strength = 0.3
	net_node.show_wireframe = true
	
	# Add label
	var label = Label3D.new()
	label.text = config.name
	label.position = Vector3(0, -3, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 20
	label.modulate = config.color
	net_node.add_child(label)
	
	# Add type label above
	var type_label = Label3D.new()
	type_label.text = NET_TYPES[config.net_type]
	type_label.position = Vector3(0, 4, 0)
	type_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	type_label.font_size = 24
	type_label.modulate = Color(1, 1, 1, 1)
	net_node.add_child(type_label)
	
	return net_node

func _input(event):
	"""Handle input"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			print("Regenerating grid...")
			generate_grid()
		elif event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			spacing_between += 2.0
			print("Spacing: %.1f" % spacing_between)
			generate_grid()
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			spacing_between = max(8.0, spacing_between - 2.0)
			print("Spacing: %.1f" % spacing_between)
			generate_grid()






