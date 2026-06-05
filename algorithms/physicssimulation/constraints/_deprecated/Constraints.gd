# @identity
# essence: an enum of joint types (hinge, slider, pendulum, spring) demonstrated as constrained rigid bodies — physics as restricted motion
# desire: show that "joints" are negative space — degrees of freedom REMOVED — and that each named joint is a different removal
# critical_parameter: current_constraint_type — picks which degree-of-freedom restriction is on stage
# triggers: _process() advances the simulation; type-switch button or input rotates through ConstraintType enum
# emerges: a single piece of rigid hardware that becomes a door (hinge), drawer (slider), bob (pendulum), or sproing (spring) by enum value
# needs: type selector [present]; reset button [missing]; per-type tuning sliders [missing]
# relationships: physicssim-bodies primitive that builds on collision_detection (touch) and spring_mass_system (continuous force); foundation for the joints sequence (FOUR named freedoms)
# truth: A joint is the act of forbidding. Each named joint is a different sentence of the form "you cannot move along axis X." The motion you see is what's left after the forbidding. [Note: this is the deprecated demo; the active interactive version lives at algorithms/physicssimulation/constraints/Constraints_Interactive.gd.]

extends Node3D

class_name Constraints

enum ConstraintType { HINGE, SLIDER, PENDULUM, SPRING }

var current_constraint_type = ConstraintType.HINGE
var paused = false
var gravity = Vector3(0, -9.8, 0)
var time = 0.0

# Hinge system variables
var hinge_angle = 0.0
var hinge_angular_velocity = 2.0

# Slider system variables
var slider_position = 0.0
var slider_velocity = 1.0
var slider_bounds = Vector2(-2, 2)

# Pendulum system variables
var pendulum_angle = PI / 4
var pendulum_angular_velocity = 0.0
var pendulum_length = 3.0
var pendulum_damping = 0.98

func _ready() -> void:
	# Scale for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	_connect_ui()
	_initialize_constraints()

func _initialize_constraints() -> void:
	# Initialize all constraint systems
	_update_constraint_visualization()

func _physics_process(delta: float) -> void:
	if paused:
		return
	
	time += delta
	
	# Update different constraint systems
	match current_constraint_type:
		ConstraintType.HINGE:
			_update_hinge_system(delta)
		ConstraintType.SLIDER:
			_update_slider_system(delta)
		ConstraintType.PENDULUM:
			_update_pendulum_system(delta)
	
	# Update constraint visualization
	_update_constraint_visualization()

func _update_hinge_system(delta) -> void:
	# Update hinge angle
	hinge_angle += hinge_angular_velocity * delta
	
	# Apply some oscillation
	hinge_angular_velocity += sin(time * 0.5) * 0.1
	
	# Keep angular velocity reasonable
	hinge_angular_velocity = clamp(hinge_angular_velocity, -3.0, 3.0)

func _update_slider_system(delta) -> void:
	# Update slider position
	slider_position += slider_velocity * delta
	
	# Bounce off bounds
	if slider_position > slider_bounds.y:
		slider_position = slider_bounds.y
		slider_velocity = -slider_velocity * 0.8
	elif slider_position < slider_bounds.x:
		slider_position = slider_bounds.x
		slider_velocity = -slider_velocity * 0.8
	
	# Add some oscillation
	slider_velocity += sin(time * 0.3) * 0.1

func _update_pendulum_system(delta) -> void:
	# Simple pendulum physics
	var g = gravity.y
	pendulum_angular_velocity += (g / pendulum_length) * sin(pendulum_angle) * delta
	pendulum_angle += pendulum_angular_velocity * delta
	
	# Apply damping
	pendulum_angular_velocity *= pendulum_damping

func _update_constraint_visualization() -> void:
	# Update hinge system
	var hinge_system = $ConstraintSystems/HingeSystem
	var arm1 = hinge_system.get_node("HingeJoint/Arm1")
	var arm2 = hinge_system.get_node("HingeJoint/Arm2")
	
	arm1.rotation.z = hinge_angle
	arm2.rotation.z = -hinge_angle * 0.5
	
	# Update slider system
	var slider_system = $ConstraintSystems/SliderSystem
	var slider_block = slider_system.get_node("SliderTrack/SliderBlock")
	
	slider_block.position.x = slider_position
	
	# Update pendulum system
	var pendulum_system = $ConstraintSystems/PendulumSystem
	var pendulum_bob = pendulum_system.get_node("PendulumString/PendulumBob")
	
	var bob_x = pendulum_length * sin(pendulum_angle)
	var bob_y = -pendulum_length * cos(pendulum_angle)
	pendulum_bob.position = Vector3(bob_x, bob_y, 0)

func _connect_ui() -> void:
	$UI/VBoxContainer/ResetButton.pressed.connect(_on_reset_pressed)
	$UI/VBoxContainer/PauseButton.pressed.connect(_on_pause_pressed)
	$UI/VBoxContainer/ConstraintTypeButton.pressed.connect(_on_constraint_type_pressed)

func _on_reset_pressed() -> void:
	# Reset all constraint systems
	hinge_angle = 0.0
	hinge_angular_velocity = 2.0
	slider_position = 0.0
	slider_velocity = 1.0
	pendulum_angle = PI / 4
	pendulum_angular_velocity = 0.0
	time = 0.0

func _on_pause_pressed() -> void:
	paused = !paused
	$UI/VBoxContainer/PauseButton.text = "Resume" if paused else "Pause"

func _on_constraint_type_pressed() -> void:
	current_constraint_type = (current_constraint_type + 1) % ConstraintType.size()
	
	# Update UI text
	var constraint_names = ["Hinge", "Slider", "Pendulum", "Spring"]
	$UI/VBoxContainer/ConstraintTypeButton.text = "Type: " + constraint_names[current_constraint_type]

func apply_grid_config(config: Dictionary) -> void:
	pass
