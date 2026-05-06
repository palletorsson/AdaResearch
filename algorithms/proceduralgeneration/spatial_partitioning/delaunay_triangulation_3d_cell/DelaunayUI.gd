extends Node3D

var delaunay_node: Node = null
var _control_panel: Node3D
var gen_slider: Node = null
var points_slider: Node = null
var randomness_slider: Node = null
var subdiv_slider: Node = null
var status_label: Label3D = null

var rotating := true
var rotation_speed := 0.5

func _ready() -> void:
	delaunay_node = get_node_or_null("../../DelaunayTriangulation3DCell")

	# Status label above panel
	status_label = Label3D.new()
	status_label.position = Vector3(0, 0.5, 0)
	status_label.font_size = 32
	status_label.text = "Delaunay 3D Cell"
	add_child(status_label)

	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("DELAUNAY", [
		[
			{"type": "slider_h", "label": "GENS", "default": 0.5},
			{"type": "slider_h", "label": "POINTS", "default": 0.5},
		],
		[
			{"type": "slider_h", "label": "RANDOM", "default": 0.5},
			{"type": "slider_h", "label": "SUBDIV", "default": 0.5},
		],
		[
			{"type": "button", "label": "ROTATE"},
			{"type": "button", "label": "REGEN"},
		],
	])
	_control_panel.position = Vector3(0, 0.25, 0)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	gen_slider = _control_panel.find_child("Param_0", true, false)
	points_slider = _control_panel.find_child("Param_1", true, false)
	randomness_slider = _control_panel.find_child("Param_2", true, false)
	subdiv_slider = _control_panel.find_child("Param_3", true, false)

	if gen_slider:
		gen_slider.slider_moved.connect(_on_gen_slider_moved)
	if points_slider:
		points_slider.slider_moved.connect(_on_points_slider_moved)
	if randomness_slider:
		randomness_slider.slider_moved.connect(_on_randomness_slider_moved)
	if subdiv_slider:
		subdiv_slider.slider_moved.connect(_on_subdiv_slider_moved)

	var rotate_btn = _control_panel.find_child("Btn_0", true, false)
	if rotate_btn:
		var area = rotate_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_rotate_pressed())

	var regen_btn = _control_panel.find_child("Btn_1", true, false)
	if regen_btn:
		var area = regen_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_regenerate_pressed())

func _process(delta: float) -> void:
	if rotating and delaunay_node:
		delaunay_node.rotation.y += delta * rotation_speed

func _on_gen_slider_moved(_name: String, value: float) -> void:
	if not delaunay_node: return
	delaunay_node.generations = int(lerp(1.0, 10.0, value))

func _on_points_slider_moved(_name: String, value: float) -> void:
	if not delaunay_node: return
	delaunay_node.initial_points = int(lerp(4.0, 50.0, value))

func _on_randomness_slider_moved(_name: String, value: float) -> void:
	if not delaunay_node: return
	delaunay_node.randomness = lerp(0.0, 1.0, value)

func _on_subdiv_slider_moved(_name: String, value: float) -> void:
	if not delaunay_node: return
	delaunay_node.subdivision_factor = lerp(0.0, 2.0, value)

func _on_rotate_pressed() -> void:
	rotating = !rotating

func _on_regenerate_pressed() -> void:
	if delaunay_node:
		delaunay_node.generate_cell_body()

func _exit_tree() -> void:
	delaunay_node = null

func apply_grid_config(config: Dictionary) -> void:
	pass
