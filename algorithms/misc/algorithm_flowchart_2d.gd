extends Control
class_name AlgorithmFlowChart2D

# Node references
@onready var background: ColorRect
@onready var scroll_container: ScrollContainer
@onready var flow_container: Control

# Visual settings
const BOX_SIZE = Vector2(140, 60)
const BOX_MARGIN = Vector2(20, 15)
const CONNECTION_COLOR = Color(0.7, 0.7, 0.7, 0.8)
const CONNECTION_WIDTH = 2.0

# Category colors
const CATEGORY_COLORS = {
	"entry": Color(0.9, 0.9, 0.9),
	"foundation": Color(0.8, 0.9, 1.0),
	"audio": Color(1.0, 0.9, 0.8),
	"random": Color(0.9, 1.0, 0.8),
	"visual": Color(1.0, 0.8, 0.9),
	"physics": Color(0.8, 1.0, 1.0),
	"advanced": Color(1.0, 0.8, 1.0)
}

# Data structure for flowchart
var flowchart_data = {
	"max_x_outline_bott_plug": {"pos": Vector2(0, 0), "text": "Max_X\nOutline bott plug", "type": "entry", "connections": []},
	"pattern_generation": {"pos": Vector2(2, 0), "text": "Pattern Generation", "type": "foundation", "connections": []},
	"procedural_generation": {"pos": Vector2(6, 0), "text": "Procedural\nGeneration", "type": "advanced", "connections": []},
	
	# Row 1 - Main categories
	"arrays": {"pos": Vector2(0, 1), "text": "Arrays", "type": "foundation", "connections": ["tutorial_single"]},
	"meshes": {"pos": Vector2(1, 1), "text": "Meshes", "type": "visual", "connections": ["meshes_one"]},
	"wave_audio": {"pos": Vector2(2, 1), "text": "Wave Audio", "type": "audio", "connections": ["wave_one"]},
	"randomness": {"pos": Vector2(3, 1), "text": "Randomness", "type": "random", "connections": ["random_one"]},
	"noise": {"pos": Vector2(4, 1), "text": "Noise", "type": "random", "connections": ["noise_one"]},
	"physics_sim": {"pos": Vector2(5, 1), "text": "Physics Sim", "type": "physics", "connections": []},
	"soft_bodies": {"pos": Vector2(6, 1), "text": "Soft Bodies", "type": "physics", "connections": []},
	"recursive_emergence": {"pos": Vector2(7, 1), "text": "Recursive\nEmergence", "type": "advanced", "connections": []},
	"swarm_intelligence": {"pos": Vector2(8, 1), "text": "Swarm Intelligence", "type": "advanced", "connections": []},
	"machine_learning": {"pos": Vector2(9, 1), "text": "Machine Learning", "type": "advanced", "connections": []},
	
	# Arrays track
	"tutorial_single": {"pos": Vector2(0, 2), "text": "Tutorial_Single", "type": "foundation", "connections": ["tutorial_col"]},
	"tutorial_col": {"pos": Vector2(0, 3), "text": "Tutorial_Col", "type": "foundation", "connections": ["tutorial_row"]},
	"tutorial_row": {"pos": Vector2(0, 4), "text": "Tutorial_Row", "type": "foundation", "connections": ["tutorial_2d"]},
	"tutorial_2d": {"pos": Vector2(0, 5), "text": "Tutorial_2D", "type": "foundation", "connections": ["tutorial_3d", "tutorial_color"]},
	"tutorial_3d": {"pos": Vector2(-1, 6), "text": "Tutorial_3d7", "type": "foundation", "connections": []},
	"tutorial_color": {"pos": Vector2(0, 6), "text": "Tutorial_Color", "type": "foundation", "connections": ["more_datastructs", "tutorial_disco"]},
	"more_datastructs": {"pos": Vector2(-1, 7), "text": "More datastructs", "type": "foundation", "connections": []},
	"tutorial_disco": {"pos": Vector2(0, 7), "text": "Tutorial_Disco", "type": "foundation", "connections": []},
	
	# Meshes track
	"meshes_one": {"pos": Vector2(1, 2), "text": "Meshes_One\nFusion primitives", "type": "visual", "connections": ["meshes_two"]},
	"meshes_two": {"pos": Vector2(1, 3), "text": "Meshes_Two", "type": "visual", "connections": []},
	
	# Wave Audio track
	"wave_one": {"pos": Vector2(2, 2), "text": "Wave_One", "type": "audio", "connections": ["wave_two"]},
	"wave_two": {"pos": Vector2(2, 3), "text": "Wave_Two", "type": "audio", "connections": ["wave_three"]},
	"wave_three": {"pos": Vector2(2, 4), "text": "Wave_Three", "type": "audio", "connections": ["wave_four"]},
	"wave_four": {"pos": Vector2(2, 5), "text": "Wave_Four", "type": "audio", "connections": ["wave_walk"]},
	"wave_walk": {"pos": Vector2(2, 6), "text": "Wave_Walk", "type": "audio", "connections": ["wave_five"]},
	"wave_five": {"pos": Vector2(2, 7), "text": "Wave_Five", "type": "audio", "connections": ["wave_six"]},
	"wave_six": {"pos": Vector2(2, 8), "text": "Wave_Six", "type": "audio", "connections": []},
	
	# Randomness track
	"random_one": {"pos": Vector2(3, 2), "text": "Random_One\nrandom_rimose\nrandom_loses", "type": "random", "connections": ["random_two"]},
	"random_two": {"pos": Vector2(3, 3), "text": "Random_Two\nrandom_rimose\nrandom_loses", "type": "random", "connections": ["random_three"]},
	"random_three": {"pos": Vector2(3, 4), "text": "Random_Three\nrandom_rimose\nrandom_loses", "type": "random", "connections": ["random_four"]},
	"random_four": {"pos": Vector2(3, 5), "text": "Random_Four\nrandom_rimose\nrandom_loses", "type": "random", "connections": ["random_walk"]},
	"random_walk": {"pos": Vector2(3, 6), "text": "Random_Walk\nrandom_rimose\nrandom_loses", "type": "random", "connections": ["random_five"]},
	"random_five": {"pos": Vector2(3, 7), "text": "Random_Five\nrandom_rimose\nrandom_loses", "type": "random", "connections": ["random_six"]},
	"random_six": {"pos": Vector2(3, 8), "text": "Random_Six\nrandom_rimose\nrandom_loses", "type": "random", "connections": []},
	
	# Noise track
	"noise_one": {"pos": Vector2(4, 2), "text": "Noise_One\nwarking_cloud", "type": "random", "connections": ["noise_two"]},
	"noise_two": {"pos": Vector2(4, 3), "text": "Noise_Two\nbig_noise_torus", "type": "random", "connections": ["noise_four"]},
	"noise_four": {"pos": Vector2(4, 4), "text": "Noise_Four\ncolor_noise_tv", "type": "random", "connections": ["noise_five"]},
	"noise_five": {"pos": Vector2(4, 5), "text": "Noise_Five\ncolor_noise_tv", "type": "random", "connections": ["noise_six"]},
	"noise_six": {"pos": Vector2(4, 6), "text": "Noise_Six\ncolor_noise_tv", "type": "random", "connections": []}
}

var node_buttons = {}
var connections = []

func _ready():
	_setup_ui()
	_create_flowchart()

func _setup_ui():
	# Set up the main control
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Background
	background = ColorRect.new()
	background.color = Color(0.1, 0.1, 0.12)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	# Scroll container for the flowchart
	scroll_container = ScrollContainer.new()
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll_container)
	
	# Main container for the flowchart - use a custom control for drawing
	flow_container = FlowChartCanvas.new()
	flow_container.custom_minimum_size = Vector2(1400, 800)
	flow_container.parent_flowchart = self
	scroll_container.add_child(flow_container)

func _create_flowchart():
	# Create nodes
	for node_id in flowchart_data.keys():
		var node_data = flowchart_data[node_id]
		var button = _create_node_button(node_id, node_data)
		node_buttons[node_id] = button
		flow_container.add_child(button)
	
	# Store connections for drawing
	for node_id in flowchart_data.keys():
		var node_data = flowchart_data[node_id]
		for connection in node_data.connections:
			connections.append({"from": node_id, "to": connection})
	
	# Trigger redraw
	flow_container.queue_redraw()

func _create_node_button(node_id: String, node_data: Dictionary) -> Button:
	var button = Button.new()
	button.text = node_data.text
	button.size = BOX_SIZE
	
	# Position calculation
	var grid_pos = node_data.pos
	button.position = Vector2(
		grid_pos.x * (BOX_SIZE.x + BOX_MARGIN.x) + 50,
		grid_pos.y * (BOX_SIZE.y + BOX_MARGIN.y) + 50
	)
	
	# Styling
	var style_box = StyleBoxFlat.new()
	var color = CATEGORY_COLORS.get(node_data.type, Color.WHITE)
	style_box.bg_color = color
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.3, 0.3, 0.3)
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	
	button.add_theme_stylebox_override("normal", style_box)
	button.add_theme_stylebox_override("hover", _create_hover_style(color))
	button.add_theme_stylebox_override("pressed", _create_pressed_style(color))
	
	# Font styling
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	
	# Connect button press
	button.pressed.connect(_on_node_pressed.bind(node_id))
	
	return button

func _create_hover_style(base_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = base_color.lightened(0.1)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.5, 0.5)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _create_pressed_style(base_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = base_color.darkened(0.1)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.1, 0.1, 0.1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style



func _on_node_pressed(node_id: String):
	print("Pressed node: %s" % node_id)
	var node_data = flowchart_data.get(node_id, {})
	
	# Create info popup
	_show_node_info(node_id, node_data)

func _show_node_info(node_id: String, node_data: Dictionary):
	var popup = AcceptDialog.new()
	popup.title = "Algorithm Info"
	
	var label = RichTextLabel.new()
	label.custom_minimum_size = Vector2(300, 200)
	label.bbcode_enabled = true
	label.text = "[b]%s[/b]\n\n[color=gray]Type:[/color] %s\n\n[color=gray]Connections:[/color]\n%s" % [
		node_data.get("text", node_id),
		node_data.get("type", "unknown"),
		"\n".join(node_data.get("connections", []))
	]
	
	popup.add_child(label)
	get_tree().current_scene.add_child(popup)
	popup.popup_centered()
	
	# Auto-remove popup after showing
	popup.confirmed.connect(popup.queue_free)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				# Reset zoom and position
				scroll_container.scroll_horizontal = 0
				scroll_container.scroll_vertical = 0
			KEY_SPACE:
				# Center the view
				var center_x = (flow_container.custom_minimum_size.x - scroll_container.size.x) / 2
				var center_y = (flow_container.custom_minimum_size.y - scroll_container.size.y) / 2
				scroll_container.scroll_horizontal = center_x
				scroll_container.scroll_vertical = center_y

# Custom Control class for drawing connections
class FlowChartCanvas:
	extends Control
	
	var parent_flowchart: AlgorithmFlowChart2D
	
	func _draw():
		if not parent_flowchart:
			return
			
		# Draw connections between nodes
		for connection in parent_flowchart.connections:
			var from_node = parent_flowchart.node_buttons.get(connection.from)
			var to_node = parent_flowchart.node_buttons.get(connection.to)
			
			if from_node and to_node:
				var from_pos = from_node.position + from_node.size / 2
				var to_pos = to_node.position + to_node.size / 2
				
				# Draw arrow line
				draw_line(from_pos, to_pos, parent_flowchart.CONNECTION_COLOR, parent_flowchart.CONNECTION_WIDTH)
				
				# Draw arrow head
				var direction = (to_pos - from_pos).normalized()
				var arrow_size = 8
				var arrow_angle = PI / 6
				
				var arrow_point1 = to_pos - direction.rotated(arrow_angle) * arrow_size
				var arrow_point2 = to_pos - direction.rotated(-arrow_angle) * arrow_size
				
				draw_line(to_pos, arrow_point1, parent_flowchart.CONNECTION_COLOR, parent_flowchart.CONNECTION_WIDTH)
				draw_line(to_pos, arrow_point2, parent_flowchart.CONNECTION_COLOR, parent_flowchart.CONNECTION_WIDTH)
