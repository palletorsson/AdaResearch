extends Node3D

# UI References
@onready var lattice: TessellationLatticeWalk = $TessellationLatticeWalk
@onready var type_label: Label = $UI/Control/Panel/VBoxContainer/TypeLabel
@onready var cube_button: Button = $UI/Control/Panel/VBoxContainer/CubeButton
@onready var octahedron_button: Button = $UI/Control/Panel/VBoxContainer/OctahedronButton
@onready var rhombic_button: Button = $UI/Control/Panel/VBoxContainer/RhombicButton
@onready var truncated_button: Button = $UI/Control/Panel/VBoxContainer/TruncatedButton
@onready var speed_label: Label = $UI/Control/Panel/VBoxContainer/SpeedLabel
@onready var speed_slider: HSlider = $UI/Control/Panel/VBoxContainer/SpeedSlider
@onready var pause_button: Button = $UI/Control/Panel/VBoxContainer/PauseButton
@onready var reset_button: Button = $UI/Control/Panel/VBoxContainer/ResetButton
@onready var reveal_all_button: Button = $UI/Control/Panel/VBoxContainer/RevealAllButton
@onready var stats_label: Label = $UI/Control/Panel/VBoxContainer/StatsLabel

# Camera control
@onready var camera: Camera3D = $Camera3D
var camera_distance: float = 25.0
var camera_angle: float = 0.0
var camera_height: float = 15.0
var is_paused: bool = false

func _ready():
	# Connect UI signals
	cube_button.pressed.connect(_on_cube_pressed)
	octahedron_button.pressed.connect(_on_octahedron_pressed)
	rhombic_button.pressed.connect(_on_rhombic_pressed)
	truncated_button.pressed.connect(_on_truncated_pressed)
	speed_slider.value_changed.connect(_on_speed_changed)
	pause_button.pressed.connect(_on_pause_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	reveal_all_button.pressed.connect(_on_reveal_all_pressed)

	# Initialize UI
	speed_slider.value = lattice.walk_speed
	_update_ui()
	_update_camera_position()

func _process(delta):
	# Rotate camera around the lattice
	camera_angle += delta * 0.2
	_update_camera_position()

	# Update stats periodically
	if Engine.get_frames_drawn() % 30 == 0:
		_update_stats()

func _update_camera_position():
	var x = cos(camera_angle) * camera_distance
	var z = sin(camera_angle) * camera_distance
	camera.position = Vector3(x, camera_height, z)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _on_cube_pressed():
	lattice.set_tessellation_type(TessellationLatticeWalk.TessellationType.CUBE)
	_update_ui()
	_update_stats()

func _on_octahedron_pressed():
	lattice.set_tessellation_type(TessellationLatticeWalk.TessellationType.OCTAHEDRON)
	_update_ui()
	_update_stats()

func _on_rhombic_pressed():
	lattice.set_tessellation_type(TessellationLatticeWalk.TessellationType.RHOMBIC_DODECAHEDRON)
	_update_ui()
	_update_stats()

func _on_truncated_pressed():
	lattice.set_tessellation_type(TessellationLatticeWalk.TessellationType.TRUNCATED_OCTAHEDRON)
	_update_ui()
	_update_stats()

func _on_speed_changed(value: float):
	lattice.walk_speed = value
	speed_label.text = "Speed: %.1f cells/sec" % value

func _on_pause_pressed():
	is_paused = !is_paused
	if is_paused:
		lattice.pause_walk()
		pause_button.text = "Resume"
	else:
		lattice.resume_walk()
		pause_button.text = "Pause"

func _on_reset_pressed():
	lattice.reset_walk()
	is_paused = false
	pause_button.text = "Pause"
	lattice.auto_walk = true
	_update_stats()

func _on_reveal_all_pressed():
	lattice.reveal_all()
	_update_stats()

func _update_ui():
	"""Update UI to reflect current settings"""
	var type_name = TessellationLatticeWalk.TessellationType.keys()[lattice.tessellation_type]
	type_label.text = "Type: " + type_name.replace("_", " ").capitalize()
	speed_label.text = "Speed: %.1f cells/sec" % lattice.walk_speed

func _update_stats():
	"""Update statistics display"""
	var stats = lattice.get_stats()
	stats_label.text = ""
	stats_label.text += "Type: " + str(stats.get("tessellation_type", "N/A")) + "\n"
	stats_label.text += "Grid: " + str(stats.get("grid_size", Vector3i.ZERO)) + "\n"
	stats_label.text += "Total Cells: " + str(stats.get("total_cells", 0)) + "\n"
	stats_label.text += "Revealed: " + str(stats.get("revealed_cells", 0)) + "\n"

	var progress = stats.get("walk_progress", 0.0) * 100.0
	stats_label.text += "Progress: %.1f%%" % progress

# Input handling for camera control
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(10.0, camera_distance - 2.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(50.0, camera_distance + 2.0)
