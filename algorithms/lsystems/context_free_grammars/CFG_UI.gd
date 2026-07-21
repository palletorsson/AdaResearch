extends Node3D

## VR UI panel for ContextFreeGrammars
## Provides sliders and buttons to control grammar type, speed, and derivation stepping.
##
## SUPERSEDED 2026-07-21 — DO NOT RE-WIRE THIS SCRIPT.
## context_free_grammars.tscn loads ContextFreeGrammars.gd alone; nothing in the
## repo instantiates this node, so the pad and its two Label3Ds have never
## existed in game. Under the cabinet grammar an artifact's interface is part of
## its BODY, so the panel now lives in ContextFreeGrammars._mount_controls(),
## seated on the wedge shoulder of the chart case's service band, and the two
## floating Label3Ds became lines of the STATE readout inset in that band.
## Attaching this script again would put a second, competing pad in the scene —
## exactly the floating interface the ruling retired. Kept only so the path in
## doc/startpacks/text-systems.json still resolves.

var cfg_node: Node = null
var _control_panel: Node3D
var speed_slider: Node = null
var status_label: Label3D = null
var grammar_label: Label3D = null
var auto_enabled := true

func _ready() -> void:
	cfg_node = get_parent()
	if not cfg_node or not cfg_node.has_method("next_step"):
		cfg_node = get_node_or_null("../ContextFreeGrammars")
	_build_ui()


func _build_ui() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("CFG GRAMMAR", [
		[
			{"type": "slider_h", "label": "SPEED", "default": 0.2},
		],
		[
			{"type": "button", "label": "AUTO"},
			{"type": "button", "label": "STEP"},
		],
		[
			{"type": "button", "label": "GRAMMAR"},
			{"type": "button", "label": "RESET"},
		],
	])
	_control_panel.position = Vector3(0, 0.0, 0)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	speed_slider = _control_panel.find_child("Param_0", true, false)
	if speed_slider:
		speed_slider.slider_moved.connect(_on_speed_changed)

	# Status label above panel
	status_label = Label3D.new()
	status_label.text = "Step: 0"
	status_label.font_size = 32
	status_label.outline_size = 3
	status_label.modulate = Color(0.75, 0.85, 0.95)
	status_label.position = Vector3(0, 0.22, 0)
	add_child(status_label)

	# Grammar type label
	grammar_label = Label3D.new()
	grammar_label.text = ""
	grammar_label.font_size = 24
	grammar_label.outline_size = 3
	grammar_label.modulate = Color(0.6, 0.8, 1.0)
	grammar_label.position = Vector3(0, 0.17, 0)
	add_child(grammar_label)

	var auto_btn = _control_panel.find_child("Btn_0", true, false)
	if auto_btn:
		var area = auto_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_auto_toggled())

	var step_btn = _control_panel.find_child("Btn_1", true, false)
	if step_btn:
		var area = step_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_step_pressed())

	var grammar_btn = _control_panel.find_child("Btn_2", true, false)
	if grammar_btn:
		var area = grammar_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_grammar_cycle())

	var reset_btn = _control_panel.find_child("Btn_3", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_reset_pressed())


func _process(_delta: float) -> void:
	if cfg_node and status_label:
		status_label.text = "Step: %d | Length: %d" % [
			cfg_node.derivation_step,
			cfg_node.current_string.length()
		]
	if cfg_node and grammar_label:
		var idx: int = cfg_node.grammar_index
		if idx < cfg_node.grammar_names.size():
			grammar_label.text = cfg_node.grammar_names[idx]


func _on_auto_toggled() -> void:
	auto_enabled = not auto_enabled
	if cfg_node:
		cfg_node.auto_play = auto_enabled


func _on_speed_changed(_value: float) -> void:
	if cfg_node and speed_slider:
		cfg_node.speed = speed_slider.get_normalized_value() * 10.0


func _on_step_pressed() -> void:
	if cfg_node:
		cfg_node.next_step()


func _on_grammar_cycle() -> void:
	if cfg_node:
		var next_idx: int = (cfg_node.grammar_index + 1) % cfg_node.grammars.size()
		cfg_node.set_grammar(next_idx)


func _on_reset_pressed() -> void:
	if cfg_node:
		cfg_node.reset_derivation()


func apply_grid_config(config: Dictionary) -> void:
	pass


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
