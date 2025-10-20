extends Node3D

# UI References
@onready var crystal: CrystalRandomWalk = $CrystalRandomWalk
@onready var steps_label: Label = $UI/Control/Panel/VBoxContainer/StepsLabel
@onready var steps_slider: HSlider = $UI/Control/Panel/VBoxContainer/StepsSlider
@onready var branch_label: Label = $UI/Control/Panel/VBoxContainer/BranchLabel
@onready var branch_slider: HSlider = $UI/Control/Panel/VBoxContainer/BranchSlider
@onready var taper_label: Label = $UI/Control/Panel/VBoxContainer/TaperLabel
@onready var taper_slider: HSlider = $UI/Control/Panel/VBoxContainer/TaperSlider
@onready var chaos_label: Label = $UI/Control/Panel/VBoxContainer/ChaosLabel
@onready var chaos_slider: HSlider = $UI/Control/Panel/VBoxContainer/ChaosSlider
@onready var regenerate_button: Button = $UI/Control/Panel/VBoxContainer/RegenerateButton
@onready var random_seed_button: Button = $UI/Control/Panel/VBoxContainer/RandomSeedButton
@onready var stats_label: Label = $UI/Control/Panel/VBoxContainer/StatsLabel

# Camera control
@onready var camera: Camera3D = $Camera3D
var camera_distance: float = 12.0
var camera_angle: float = 0.0
var camera_height: float = 8.0

func _ready():
	# Connect UI signals
	steps_slider.value_changed.connect(_on_steps_changed)
	branch_slider.value_changed.connect(_on_branch_changed)
	taper_slider.value_changed.connect(_on_taper_changed)
	chaos_slider.value_changed.connect(_on_chaos_changed)
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	random_seed_button.pressed.connect(_on_random_seed_pressed)
	
	# Initialize UI with crystal values
	steps_slider.value = crystal.steps
	branch_slider.value = crystal.branch_probability
	taper_slider.value = crystal.taper_amount
	chaos_slider.value = crystal.rotation_chaos
	
	# Update initial UI
	_update_ui()
	_update_stats()
	
	# Ensure crystal is visible
	_update_camera_position()

func _process(delta):
	# Rotate camera around the crystal
	camera_angle += delta * 0.3
	_update_camera_position()

func _update_camera_position():
	var x = cos(camera_angle) * camera_distance
	var z = sin(camera_angle) * camera_distance
	camera.position = Vector3(x, camera_height, z)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	
	# Debug: Print camera position to help with troubleshooting
	# print("Camera position: ", camera.position, " Distance: ", camera_distance)

func _on_steps_changed(value: float):
	crystal.steps = int(value)
	steps_label.text = "Steps: " + str(int(value))
	_update_stats()

func _on_branch_changed(value: float):
	crystal.branch_probability = value
	branch_label.text = "Branch Probability: " + "%.2f" % value
	_update_stats()

func _on_taper_changed(value: float):
	crystal.taper_amount = value
	taper_label.text = "Taper Amount: " + "%.2f" % value
	_update_stats()

func _on_chaos_changed(value: float):
	crystal.rotation_chaos = value
	chaos_label.text = "Rotation Chaos: " + "%.2f" % value
	_update_stats()

func _on_regenerate_pressed():
	crystal.regenerate()
	_update_stats()

func _on_random_seed_pressed():
	var new_seed = randi()
	crystal.set_seed(new_seed)
	_update_stats()

func _update_ui():
	"""Update UI to reflect current crystal settings"""
	steps_slider.value = crystal.steps
	branch_slider.value = crystal.branch_probability
	taper_slider.value = crystal.taper_amount
	chaos_slider.value = crystal.rotation_chaos

func _update_stats():
	"""Update statistics display"""
	var stats = crystal.get_crystal_stats() if crystal.has_method("get_crystal_stats") else {}
	var tetrahedra_count = crystal.transforms.size() if crystal.transforms else 0
	stats_label.text = "Tetrahedra: " + str(tetrahedra_count) + "\n"

	if stats.has("crystal_bounds"):
		var bounds = stats["crystal_bounds"]
		var size = bounds["max"] - bounds["min"]
		stats_label.text += "Size: " + "%.1f" % size.length() + " units\n"

	stats_label.text += "Branch Decay: " + "%.2f" % crystal.branch_decay + "\n"
	stats_label.text += "Tetrahedron Size: " + "%.2f" % crystal.tetrahedron_size

# Input handling for camera control
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(2.0, camera_distance - 0.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(20.0, camera_distance + 0.5)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Click to regenerate with random parameters
			_randomize_parameters()

func _randomize_parameters():
	"""Randomize crystal parameters for variety"""
	crystal.steps = randi_range(15, 50)
	crystal.branch_probability = randf_range(0.1, 0.5)
	crystal.taper_amount = randf_range(0.85, 0.98)
	crystal.rotation_chaos = randf_range(0.0, 0.3)
	crystal.branch_decay = randf_range(0.7, 0.9)
	crystal.tetrahedron_size = randf_range(0.8, 2.0)

	# Randomize colors
	var hue1 = randf()
	var hue2 = fmod(hue1 + randf_range(0.1, 0.4), 1.0)
	crystal.color_start = Color.from_hsv(hue1, 0.6, 0.9)
	crystal.color_end = Color.from_hsv(hue2, 0.8, 0.7)

	crystal.regenerate()
	_update_ui()
	_update_stats()
