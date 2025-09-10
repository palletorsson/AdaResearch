# CAMenu.gd
# Main menu for selecting different CA simulations
extends Control

var ca_scenes = {
	"Recrystallization": "res://algorithms/proceduralgeneration/ca_showcase/recrystallization_ca.tscn",
	"Dendrite Growth": "res://algorithms/proceduralgeneration/ca_showcase/dendrite_growth_ca.tscn",
	"Percolation": "res://algorithms/proceduralgeneration/ca_showcase/percolation_ca.tscn",
	"Crack Propagation": "res://algorithms/proceduralgeneration/ca_showcase/crack_propagation_ca.tscn",
	"Avalanche Model": "res://algorithms/proceduralgeneration/ca_showcase/avalanche_ca.tscn",
	"Ecosystem": "res://algorithms/proceduralgeneration/ca_showcase/ecosystem_ca.tscn",
	"Disease Spread": "res://algorithms/proceduralgeneration/ca_showcase/disease_spread_ca.tscn",
	"Self-Organization": "res://algorithms/proceduralgeneration/ca_showcase/self_organization_ca.tscn"
}

var current_scene: Node = null

func _ready():
	create_menu_buttons()

func create_menu_buttons():
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Cellular Automata Showcase"
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)
	
	# Add spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	
	# Create buttons for each CA
	for ca_name in ca_scenes.keys():
		var button = Button.new()
		button.text = ca_name
		button.custom_minimum_size = Vector2(300, 50)
		button.pressed.connect(_on_ca_selected.bind(ca_name))
		vbox.add_child(button)
	
	# Add spacing
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)
	
	# Back button
	var back_button = Button.new()
	back_button.text = "Back to Main Menu"
	back_button.custom_minimum_size = Vector2(200, 40)
	back_button.pressed.connect(_on_back_pressed)
	vbox.add_child(back_button)

func _on_ca_selected(ca_name: String):
	var scene_path = ca_scenes[ca_name]
	if scene_path:
		load_ca_scene(scene_path)

func load_ca_scene(scene_path: String):
	# Remove current scene if exists
	if current_scene:
		current_scene.queue_free()
	
	# Load and instantiate new scene
	var scene = load(scene_path)
	if scene:
		current_scene = scene.instantiate()
		add_child(current_scene)
		print("Loaded CA scene: ", scene_path)

func _on_back_pressed():
	# Return to main menu or previous scene
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	get_tree().change_scene_to_file("res://MainSceneLoader.tscn")
