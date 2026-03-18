extends Node3D
class_name GeneticProgrammingInterface

## Interactive Evolution Interface

@export var evolution_engine: NodePath

const VRButton = preload("res://commons/interactables/push_button.tscn")

var engine: Node3D
var selected_genome_index: int = -1
var status_label: Label3D

func _ready() -> void:
	if evolution_engine:
		engine = get_node(evolution_engine)

	setup_ui()

func setup_ui() -> void:
	# Title label
	var title = Label3D.new()
	title.position = Vector3(0, 0.5, 0)
	title.text = "Interactive Evolution"
	title.font_size = 48
	title.modulate = Color.WHITE
	add_child(title)

	# Info label
	var info = Label3D.new()
	info.position = Vector3(0, 0.38, 0)
	info.text = "Click on forms to select favorites"
	info.font_size = 32
	info.modulate = Color.LIGHT_GRAY
	add_child(info)

	# Evolve Selected button
	var evolve_btn = VRButton.instantiate()
	evolve_btn.position = Vector3(-0.1, 0.2, 0)
	add_child(evolve_btn)
	var evolve_area = evolve_btn.get_node_or_null("InteractableAreaButton")
	if evolve_area:
		evolve_area.button_pressed.connect(_on_evolve_selected)

	# Random Evolution button
	var random_btn = VRButton.instantiate()
	random_btn.position = Vector3(0.1, 0.2, 0)
	add_child(random_btn)
	var random_area = random_btn.get_node_or_null("InteractableAreaButton")
	if random_area:
		random_area.button_pressed.connect(_on_random_evolution)

	# Stats label
	status_label = Label3D.new()
	status_label.name = "Stats"
	status_label.position = Vector3(0, 0.06, 0)
	status_label.text = ""
	status_label.font_size = 32
	status_label.modulate = Color.WHITE
	add_child(status_label)

func _on_evolve_selected() -> void:
	if engine and selected_genome_index >= 0:
		print("Evolving from selected genome")

func _on_random_evolution() -> void:
	if engine:
		engine.evolve_one_generation = true

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
