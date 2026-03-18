# CAMenu.gd
# Main menu for selecting different CA simulations — VR Node3D version
extends Node3D

const PushButton = preload("res://commons/interactables/push_button.tscn")

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
var _buttons: Array[Node] = []

func _ready() -> void:
	_build_menu()

func _build_menu() -> void:
	var y_offset := 0.0

	# Title
	var title := Label3D.new()
	title.text = "Cellular Automata Showcase"
	title.font_size = 48
	title.position = Vector3(0, y_offset, 0)
	add_child(title)
	y_offset -= 0.1

	# Create a VR push button for each CA type
	for ca_name in ca_scenes.keys():
		var btn := PushButton.instantiate()
		btn.position = Vector3(0, y_offset, 0)
		add_child(btn)
		_buttons.append(btn)

		var label_node = btn.get_node_or_null("Frame/LabelName")
		if label_node:
			label_node.text = ca_name

		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_ca_selected.bind(ca_name))

		y_offset -= 0.08

	# Spacer
	y_offset -= 0.04

	# Back button
	var back_btn := PushButton.instantiate()
	back_btn.position = Vector3(0, y_offset, 0)
	add_child(back_btn)
	_buttons.append(back_btn)

	var back_label = back_btn.get_node_or_null("Frame/LabelName")
	if back_label:
		back_label.text = "Back"

	var back_area = back_btn.get_node_or_null("InteractableAreaButton")
	if back_area:
		back_area.button_pressed.connect(_on_back_pressed)

func _on_ca_selected(ca_name: String) -> void:
	var scene_path = ca_scenes.get(ca_name, "")
	if scene_path != "":
		load_ca_scene(scene_path)

func load_ca_scene(scene_path: String) -> void:
	# Remove current scene if exists
	if current_scene:
		current_scene.queue_free()
		current_scene = null

	# Load and instantiate new scene
	var scene = load(scene_path)
	if scene:
		current_scene = scene.instantiate()
		add_child(current_scene)
		# Offset loaded scene so it doesn't overlap the menu
		current_scene.position = Vector3(0.5, 0, 0)
		print("Loaded CA scene: ", scene_path)

func _on_back_pressed() -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	get_tree().change_scene_to_file("res://MainSceneLoader.tscn")

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
