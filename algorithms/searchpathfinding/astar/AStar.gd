extends Node3D

@onready var pathfinding_visualizer = $PathfindingVisualizer
@onready var grid_size_slider = $UI/VBoxContainer/GridSizeSlider
@onready var heuristic_slider = $UI/VBoxContainer/HeuristicSlider
@onready var obstacle_density_slider = $UI/VBoxContainer/ObstacleDensitySlider
@onready var diagonal_movement_slider = $UI/VBoxContainer/DiagonalMovementSlider
@onready var grid_size_label = $UI/VBoxContainer/GridSizeLabel
@onready var heuristic_label = $UI/VBoxContainer/HeuristicLabel
@onready var obstacle_density_label = $UI/VBoxContainer/ObstacleDensityLabel
@onready var diagonal_movement_label = $UI/VBoxContainer/DiagonalMovementLabel
@onready var generate_grid_button = $UI/VBoxContainer/GenerateGridButton
@onready var find_path_button = $UI/VBoxContainer/FindPathButton
@onready var clear_path_button = $UI/VBoxContainer/ClearPathButton
@onready var step_by_step_button = $UI/VBoxContainer/StepByStepButton

var heuristics = ["Manhattan", "Euclidean", "Chebyshev", "Octile"]

func _ready():
	# Connect UI signals
	grid_size_slider.value_changed.connect(_on_grid_size_changed)
	heuristic_slider.value_changed.connect(_on_heuristic_changed)
	obstacle_density_slider.value_changed.connect(_on_obstacle_density_changed)
	diagonal_movement_slider.value_changed.connect(_on_diagonal_movement_changed)
	generate_grid_button.pressed.connect(_on_generate_grid_pressed)
	find_path_button.pressed.connect(_on_find_path_pressed)
	clear_path_button.pressed.connect(_on_clear_path_pressed)
	step_by_step_button.pressed.connect(_on_step_by_step_pressed)
	
	# Initialize the pathfinding visualizer
	_update_parameters()

func _on_grid_size_changed(value):
	grid_size_label.text = "Grid Size: " + str(int(value)) + "x" + str(int(value))
	_update_parameters()

func _on_heuristic_changed(value):
	var heuristic = heuristics[int(value)]
	heuristic_label.text = "Heuristic: " + heuristic
	_update_parameters()

func _on_obstacle_density_changed(value):
	var percentage = int(value * 100)
	obstacle_density_label.text = "Obstacle Density: " + str(percentage) + "%"
	_update_parameters()

func _on_diagonal_movement_changed(value):
	var enabled = "Enabled" if value > 0.5 else "Disabled"
	diagonal_movement_label.text = "Diagonal Movement: " + enabled
	_update_parameters()

func _on_generate_grid_pressed():
	pathfinding_visualizer.generate_grid()

func _on_find_path_pressed():
	pathfinding_visualizer.find_path()

func _on_clear_path_pressed():
	pathfinding_visualizer.clear_path()

func _on_step_by_step_pressed():
	pathfinding_visualizer.toggle_step_by_step()

func _update_parameters():
	if pathfinding_visualizer:
		pathfinding_visualizer.grid_size = int(grid_size_slider.value)
		pathfinding_visualizer.heuristic_type = int(heuristic_slider.value)
		pathfinding_visualizer.obstacle_density = obstacle_density_slider.value
		pathfinding_visualizer.allow_diagonal = diagonal_movement_slider.value > 0.5
		pathfinding_visualizer.update_parameters()

