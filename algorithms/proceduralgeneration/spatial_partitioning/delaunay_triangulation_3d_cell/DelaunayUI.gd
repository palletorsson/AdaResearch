extends Control

@onready var delaunay_node = $"../../DelaunayTriangulation3DCell"
@onready var gen_slider = $Panel/VBoxContainer/GenerationsSlider
@onready var points_slider = $Panel/VBoxContainer/PointsSlider
@onready var randomness_slider = $Panel/VBoxContainer/RandomnessSlider
@onready var subdiv_slider = $Panel/VBoxContainer/SubdivisionSlider
@onready var regenerate_btn = $Panel/VBoxContainer/RegenerateButton
@onready var rotate_check = $Panel/VBoxContainer/RotateCheck

var rotating = true
var rotation_speed = 0.5

func _ready() -> void:
	_update_ui()

func _process(delta: float) -> void:
	if rotating and delaunay_node:
		delaunay_node.rotation.y += delta * rotation_speed

func _update_ui() -> void:
	if not delaunay_node: return
	gen_slider.value = delaunay_node.generations
	points_slider.value = delaunay_node.initial_points
	randomness_slider.value = delaunay_node.randomness
	subdiv_slider.value = delaunay_node.subdivision_factor

func _on_regenerate_pressed() -> void:
	delaunay_node.generate_cell_body()

func _on_generations_changed(value) -> void:
	delaunay_node.generations = int(value)
	$Panel/VBoxContainer/GenerationsLabel.text = "Generations: %d" % int(value)

func _on_points_changed(value) -> void:
	delaunay_node.initial_points = int(value)
	$Panel/VBoxContainer/PointsLabel.text = "Initial Points: %d" % int(value)

func _on_randomness_changed(value) -> void:
	delaunay_node.randomness = value
	$Panel/VBoxContainer/RandomnessLabel.text = "Randomness: %.2f" % value

func _on_subdivision_changed(value) -> void:
	delaunay_node.subdivision_factor = value
	$Panel/VBoxContainer/SubdivisionLabel.text = "Subdivision: %.2f" % value

func _on_rotate_toggled(button_pressed) -> void:
	rotating = button_pressed

func _on_generations_drag_ended(value_changed) -> void:
	if value_changed:
		delaunay_node.generate_cell_body()

func _on_points_drag_ended(value_changed) -> void:
	if value_changed:
		delaunay_node.generate_cell_body()
