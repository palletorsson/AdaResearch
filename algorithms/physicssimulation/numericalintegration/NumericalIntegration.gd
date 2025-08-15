extends Node3D

class_name NumericalIntegration

var particles = []
var paused = false
var time_step = 0.05
var time = 0.0
var trails_enabled = true

# Physics parameters
var gravity = Vector3(0, -9.8, 0)
var damping = 0.98

func _ready():
	_initialize_particles()
	_connect_ui()

func _initialize_particles():
	# Get all integration particles
	particles = $IntegrationParticles.get_children()
	
	# Initialize each particle
	for particle in particles:
		particle.initialize()

func _physics_process(delta):
	if paused:
		return
	
	time += time_step
	
	# Update each particle using their integration method
	for particle in particles:
		particle.update_physics(time_step, gravity, damping)
	
	# Update trails
	if trails_enabled:
		_update_trails()

func _update_trails():
	# Update trails for each particle
	for particle in particles:
		particle.update_trail()

func _connect_ui():
	$UI/VBoxContainer/ResetButton.pressed.connect(_on_reset_pressed)
	$UI/VBoxContainer/PauseButton.pressed.connect(_on_pause_pressed)
	$UI/VBoxContainer/TimeStepSlider.value_changed.connect(_on_time_step_changed)
	$UI/VBoxContainer/TrailToggle.pressed.connect(_on_trail_toggle_pressed)

func _on_reset_pressed():
	# Reset all particles to initial positions
	time = 0.0
	for particle in particles:
		particle.reset_to_initial()
	
	# Clear trails
	for child in $Trails.get_children():
		child.queue_free()

func _on_pause_pressed():
	paused = !paused
	$UI/VBoxContainer/PauseButton.text = "Resume" if paused else "Pause"

func _on_time_step_changed(value: float):
	time_step = value
	$UI/VBoxContainer/TimeStepLabel.text = "Time Step: " + str(value)

func _on_trail_toggle_pressed():
	trails_enabled = !trails_enabled
	$UI/VBoxContainer/TrailToggle.text = "Trails: " + ("ON" if trails_enabled else "OFF")
	
	if !trails_enabled:
		# Clear trails
		for child in $Trails.get_children():
			child.queue_free()
