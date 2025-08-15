extends Node3D

@onready var hull_visualizer = $HullVisualizer
@onready var point_count_slider = $UI/VBoxContainer/PointCountSlider
@onready var distribution_slider = $UI/VBoxContainer/DistributionSlider
@onready var algorithm_slider = $UI/VBoxContainer/AlgorithmSlider
@onready var point_count_label = $UI/VBoxContainer/PointCountLabel
@onready var distribution_label = $UI/VBoxContainer/DistributionLabel
@onready var algorithm_label = $UI/VBoxContainer/AlgorithmLabel
@onready var generate_button = $UI/VBoxContainer/GenerateButton
@onready var compute_hull_button = $UI/VBoxContainer/ComputeHullButton
@onready var clear_button = $UI/VBoxContainer/ClearButton

var distributions = ["Uniform", "Normal", "Clustered"]
var algorithms = ["Graham Scan", "Jarvis March", "Quick Hull"]

func _ready():
	# Connect UI signals
	point_count_slider.value_changed.connect(_on_point_count_changed)
	distribution_slider.value_changed.connect(_on_distribution_changed)
	algorithm_slider.value_changed.connect(_on_algorithm_changed)
	generate_button.pressed.connect(_on_generate_pressed)
	compute_hull_button.pressed.connect(_on_compute_hull_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	
	# Initialize the visualizer
	_update_parameters()

func _on_point_count_changed(value):
	point_count_label.text = "Point Count: " + str(int(value))
	_update_parameters()

func _on_distribution_changed(value):
	var distribution = distributions[int(value)]
	distribution_label.text = "Distribution: " + distribution
	_update_parameters()

func _on_algorithm_changed(value):
	var algorithm = algorithms[int(value)]
	algorithm_label.text = "Algorithm: " + algorithm
	_update_parameters()

func _on_generate_pressed():
	hull_visualizer.generate_points()

func _on_compute_hull_pressed():
	hull_visualizer.compute_convex_hull()

func _on_clear_pressed():
	hull_visualizer.clear_all()

func _update_parameters():
	if hull_visualizer:
		hull_visualizer.point_count = int(point_count_slider.value)
		hull_visualizer.distribution_type = int(distribution_slider.value)
		hull_visualizer.algorithm_type = int(algorithm_slider.value)
