extends Node3D
class_name GeneticProgrammingInterface

## Interactive Evolution Interface

@export var evolution_engine: NodePath

var engine: Node3D
var selected_genome_index: int = -1
var status_label: Label3D
var _control_panel: Node3D

func _ready() -> void:
	if evolution_engine:
		engine = get_node(evolution_engine)

	setup_ui()

func setup_ui() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("GENETIC PROG", [
		[
			{"type": "label", "label": "Click forms to select"},
		],
		[
			{"type": "button", "label": "EVOLVE"},
			{"type": "button", "label": "RANDOM"},
		],
	])
	_control_panel.position = Vector3(0, 0.3, 0.3)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	# Connect button signals
	var evolve_btn = _control_panel.find_child("Btn_0", true, false)
	if evolve_btn:
		var evolve_area = evolve_btn.get_node_or_null("InteractableAreaButton")
		if evolve_area:
			evolve_area.button_pressed.connect(func(_b): _on_evolve_selected())

	var random_btn = _control_panel.find_child("Btn_1", true, false)
	if random_btn:
		var random_area = random_btn.get_node_or_null("InteractableAreaButton")
		if random_area:
			random_area.button_pressed.connect(func(_b): _on_random_evolution())

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
