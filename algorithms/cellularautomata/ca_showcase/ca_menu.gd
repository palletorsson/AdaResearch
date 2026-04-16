# CAMenu.gd
# Main menu for selecting different CA simulations — VR Node3D version
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
var _buttons: Array[Node] = []

func _ready() -> void:
	_build_menu()

func _build_menu() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")

	# Build button rows — one button per CA type, plus a Back button
	var ca_names := ca_scenes.keys()
	var rows: Array = []
	for ca_name in ca_names:
		rows.append([{"type": "button", "label": ca_name}])
	rows.append([{"type": "spacer"}])
	rows.append([{"type": "button", "label": "BACK"}])

	var panel: Node3D = RackTpl.create_panel("CA MENU", rows)
	panel.position = Vector3(0, 0, 0)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	# Connect CA buttons
	for i in ca_names.size():
		var btn_node: Node = panel.find_child("Btn_%d" % i, true, false)
		if btn_node:
			_buttons.append(btn_node)
			var area = btn_node.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(_on_ca_selected.bind(ca_names[i]))

	# Connect Back button (last button)
	var back_btn: Node = panel.find_child("Btn_%d" % ca_names.size(), true, false)
	if back_btn:
		_buttons.append(back_btn)
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
