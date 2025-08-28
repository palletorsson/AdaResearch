extends Node3D
class_name SoftBodySceneController

# Scene management
@export var auto_cycle_demonstrations: bool = true
@export var demonstration_duration: float = 8.0
@export var enable_user_interaction: bool = true

# Soft body references
var soft_bodies: Array[SoftBodyVariation] = []
var current_demonstration = 0
var demonstration_timer = 0.0

# Interactive elements
@onready var wind_zone: Area3D = $InteractiveElements/WindZone
@onready var force_field: Area3D = $InteractiveElements/ForceField

# UI elements
@onready var info_panel: Panel = $UI/InfoPanel
@onready var title_label: Label = $UI/InfoPanel/VBoxContainer/Title

# Demonstration modes
enum DemoMode {PHYSICS_VARIATIONS, INTERACTIVE_FORCES, STATE_CYCLING, COLLISION_DEMO}
var current_mode = DemoMode.PHYSICS_VARIATIONS

# Physics demonstration parameters
var physics_demo_params = {
	"low_pressure": {"pressure": 0.05},
	"high_pressure": {"pressure": 0.8},
	"medium_pressure": {"pressure": 0.3},
	"very_low_pressure": {"pressure": 0.02}
}

func _ready():
	_setup_scene()
	_start_demonstration_cycle()

func _setup_scene():
	# Collect all soft bodies
	for child in $SoftBodyVariations.get_children():
		if child is SoftBody3D:
			soft_bodies.append(child)
	
	print("SceneController: Found %d soft bodies" % soft_bodies.size())
	
	# Print details of each soft body for comparison
	for i in range(soft_bodies.size()):
		var body = soft_bodies[i]
		print("  %s: Precision=%d, Pressure=%.2f, Position=%s" % [
			body.name, 
			body.simulation_precision, 
			body.pressure_coefficient, 
			body.global_position
		])
	
	# Setup interactive zones
	_setup_interactive_zones()
	
	# Setup UI
	_setup_ui()

func _setup_interactive_zones():
	if wind_zone:
		wind_zone.body_entered.connect(_on_wind_zone_body_entered)
		wind_zone.body_exited.connect(_on_wind_zone_body_exited)
	
	if force_field:
		force_field.body_entered.connect(_on_force_field_body_entered)
		force_field.body_exited.connect(_on_force_field_body_exited)

func _setup_ui():
	if title_label:
		title_label.text = "Soft Body Physics Variations"
	
	# Add interactive buttons if needed
	_add_ui_controls()

func _add_ui_controls():
	# Create a control panel for user interaction
	var control_panel = Panel.new()
	control_panel.name = "ControlPanel"
	control_panel.anchors_preset = Control.PRESET_TOP_LEFT
	control_panel.position = Vector2(10, 10)
	control_panel.size = Vector2(250, 300)
	
	var vbox = VBoxContainer.new()
	control_panel.add_child(vbox)
	
	# Add demonstration mode buttons
	var mode_button = Button.new()
	mode_button.text = "Next Demo Mode"
	mode_button.pressed.connect(_cycle_demo_mode)
	vbox.add_child(mode_button)
	
	# Add physics variation buttons
	var physics_button = Button.new()
	physics_button.text = "Random Physics"
	physics_button.pressed.connect(_apply_random_physics)
	vbox.add_child(physics_button)
	
	# Add reset button
	var reset_button = Button.new()
	reset_button.text = "Reset All"
	reset_button.pressed.connect(_reset_all_bodies)
	vbox.add_child(reset_button)
	
	# Add impulse button
	var impulse_button = Button.new()
	impulse_button.text = "Apply Impulse"
	impulse_button.pressed.connect(_apply_random_impulse)
	vbox.add_child(impulse_button)
	
	$UI.add_child(control_panel)

func _start_demonstration_cycle():
	if auto_cycle_demonstrations:
		_change_demonstration_mode()

func _process(delta):
	if auto_cycle_demonstrations:
		demonstration_timer += delta
		if demonstration_timer >= demonstration_duration:
			demonstration_timer = 0.0
			_cycle_demonstration()

func _cycle_demonstration():
	current_demonstration += 1
	if current_demonstration >= 4:  # Number of demonstration types
		current_demonstration = 0
	
	_change_demonstration_mode()

func _change_demonstration_mode():
	match current_demonstration:
		0:
			_start_physics_variations_demo()
		1:
			_start_interactive_forces_demo()
		2:
			_start_state_cycling_demo()
		3:
			_start_collision_demo()

func _start_physics_variations_demo():
	print("SceneController: Starting Physics Variations Demo")
	title_label.text = "Physics Variations Demo"
	
	# Apply different physics properties to each body
	for i in range(soft_bodies.size()):
		var body = soft_bodies[i]
		var params = physics_demo_params.values()[i % physics_demo_params.size()]
		
		if params.has("pressure"):
			body.pressure_coefficient = params.pressure

func _start_interactive_forces_demo():
	print("SceneController: Starting Interactive Forces Demo")
	title_label.text = "Interactive Forces Demo"
	
	# Reset all bodies to defaults
	for body in soft_bodies:
		body.reset_to_defaults()
	
	# Activate wind and force field effects
	if wind_zone:
		wind_zone.monitoring = true
	if force_field:
		force_field.monitoring = true

func _start_state_cycling_demo():
	print("SceneController: Starting State Cycling Demo")
	title_label.text = "State Cycling Demo"
	
	# Each body cycles through states at different rates
	for i in range(soft_bodies.size()):
		var body = soft_bodies[i]
		body.state_duration = 2.0 + i * 1.0  # Different timing for each body

func _start_collision_demo():
	print("SceneController: Starting Collision Demo")
	title_label.text = "Collision Demo"
	
	# Apply impulses to create collisions
	for body in soft_bodies:
		var random_force = Vector3(
			randf_range(-3.0, 3.0),
			randf_range(2.0, 5.0),
			randf_range(-3.0, 3.0)
		)
		body.apply_impulse(random_force)

# Interactive zone handlers
func _on_wind_zone_body_entered(body):
	if body is SoftBodyVariation:
		print("SceneController: %s entered wind zone" % body.soft_body_type)

func _on_wind_zone_body_exited(body):
	if body is SoftBodyVariation:
		print("SceneController: %s exited wind zone" % body.soft_body_type)

func _on_force_field_body_entered(body):
	if body is SoftBodyVariation:
		print("SceneController: %s entered force field" % body.soft_body_type)

func _on_force_field_body_exited(body):
	if body is SoftBodyVariation:
		print("SceneController: %s exited force field" % body.soft_body_type)

# UI control handlers
func _cycle_demo_mode():
	current_mode = (current_mode + 1) % DemoMode.size()
	_change_demonstration_mode()

func _apply_random_physics():
	print("SceneController: Applying random physics to all bodies")
	for body in soft_bodies:
		var random_pressure = randf_range(0.1, 0.8)
		body.set_physics_properties(random_pressure)

func _reset_all_bodies():
	print("SceneController: Resetting all bodies to defaults")
	for body in soft_bodies:
		body.reset_to_defaults()

func _apply_random_impulse():
	print("SceneController: Applying random impulse to all bodies")
	for body in soft_bodies:
		var random_force = Vector3(
			randf_range(-5.0, 5.0),
			randf_range(3.0, 8.0),
			randf_range(-5.0, 5.0)
		)
		body.apply_impulse(random_force)

# Public API
func get_soft_body_count() -> int:
	return soft_bodies.size()

func get_soft_body_by_type(type: String) -> SoftBodyVariation:
	for body in soft_bodies:
		if body.soft_body_type == type:
			return body
	return null

func pause_demonstrations():
	auto_cycle_demonstrations = false
	print("SceneController: Demonstrations paused")

func resume_demonstrations():
	auto_cycle_demonstrations = true
	print("SceneController: Demonstrations resumed")

# Debug functions
func print_scene_status():
	print("SceneController: Scene Status:")
	print("  Soft Bodies: %d" % soft_bodies.size())
	print("  Current Mode: %s" % DemoMode.keys()[current_mode])
	print("  Auto Cycle: %s" % auto_cycle_demonstrations)
	print("  Demo Timer: %.2f" % demonstration_timer)
	
	for body in soft_bodies:
		body.print_status()
