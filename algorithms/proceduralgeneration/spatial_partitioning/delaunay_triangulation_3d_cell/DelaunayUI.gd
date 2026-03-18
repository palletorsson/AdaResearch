extends Node3D

const SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")

var delaunay_node: Node = null
var gen_slider: Node = null
var points_slider: Node = null
var randomness_slider: Node = null
var subdiv_slider: Node = null
var status_label: Label3D = null

var rotating := true
var rotation_speed := 0.5

func _ready() -> void:
	delaunay_node = get_node_or_null("../../DelaunayTriangulation3DCell")

	# Status label
	status_label = Label3D.new()
	status_label.position = Vector3(0, 0.5, 0)
	status_label.font_size = 32
	status_label.text = "Delaunay 3D Cell"
	add_child(status_label)

	# Generations slider
	gen_slider = SliderScene.instantiate()
	gen_slider.position = Vector3(0, 0.3, 0)
	add_child(gen_slider)
	gen_slider.set_param_name("Generations")
	gen_slider.set_normalized_value(0.5)
	gen_slider.slider_moved.connect(_on_gen_slider_moved)

	# Points slider
	points_slider = SliderScene.instantiate()
	points_slider.position = Vector3(0, 0.18, 0)
	add_child(points_slider)
	points_slider.set_param_name("Initial Points")
	points_slider.set_normalized_value(0.5)
	points_slider.slider_moved.connect(_on_points_slider_moved)

	# Randomness slider
	randomness_slider = SliderScene.instantiate()
	randomness_slider.position = Vector3(0, 0.06, 0)
	add_child(randomness_slider)
	randomness_slider.set_param_name("Randomness")
	randomness_slider.set_normalized_value(0.5)
	randomness_slider.slider_moved.connect(_on_randomness_slider_moved)

	# Subdivision slider
	subdiv_slider = SliderScene.instantiate()
	subdiv_slider.position = Vector3(0, -0.06, 0)
	add_child(subdiv_slider)
	subdiv_slider.set_param_name("Subdivision")
	subdiv_slider.set_normalized_value(0.5)
	subdiv_slider.slider_moved.connect(_on_subdiv_slider_moved)

	# Rotate toggle button
	var rotate_btn = ButtonScene.instantiate()
	rotate_btn.position = Vector3(-0.15, -0.18, 0)
	add_child(rotate_btn)
	var rotate_area = rotate_btn.get_node_or_null("InteractableAreaButton")
	if rotate_area:
		rotate_area.button_pressed.connect(_on_rotate_pressed)
	var rotate_lbl = Label3D.new()
	rotate_lbl.position = Vector3(-0.15, -0.24, 0)
	rotate_lbl.font_size = 20
	rotate_lbl.text = "Rotate"
	add_child(rotate_lbl)

	# Regenerate button
	var regen_btn = ButtonScene.instantiate()
	regen_btn.position = Vector3(0.15, -0.18, 0)
	add_child(regen_btn)
	var regen_area = regen_btn.get_node_or_null("InteractableAreaButton")
	if regen_area:
		regen_area.button_pressed.connect(_on_regenerate_pressed)
	var regen_lbl = Label3D.new()
	regen_lbl.position = Vector3(0.15, -0.24, 0)
	regen_lbl.font_size = 20
	regen_lbl.text = "Regenerate"
	add_child(regen_lbl)

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
