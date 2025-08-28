extends SoftBody3D
class_name SoftBodyVariation

# Soft body type-specific properties
@export var soft_body_type: String = "sphere"
@export var enable_interaction: bool = true
@export var enable_wind_effect: bool = true
@export var enable_force_field: bool = true

# Physics properties for different types
var type_properties = {
	"sphere": {
		"pressure": 0.2,
		"bounce": 0.3
	},
	"box": {
		"pressure": 0.1,
		"bounce": 0.2
	},
	"cylinder": {
		"pressure": 0.3,
		"bounce": 0.4
	},
	"capsule": {
		"pressure": 0.4,
		"bounce": 0.5
	}
}

# Animation states
enum BodyState {IDLE, ACTIVE, DEFORMED, RECOVERING}
var current_state = BodyState.IDLE
var state_timer = 0.0
var state_duration = 3.0

# Interactive forces
var wind_force = Vector3.ZERO
var force_field_strength = 0.0
var external_forces = Vector3.ZERO

# Color system (simplified, no material dependency)
var current_color: Color
var target_color: Color
var color_transition_speed = 2.0

func _ready():
	_detect_soft_body_type()
	_setup_soft_body()
	_setup_physics()
	_setup_colors()
	_setup_interactions()
	
	# Start with idle state
	_change_state(BodyState.IDLE)

func _detect_soft_body_type():
	# Automatically detect the soft body type from the node name
	var node_name = name.to_lower()
	if "sphere" in node_name:
		soft_body_type = "sphere"
	elif "box" in node_name:
		soft_body_type = "box"
	elif "cylinder" in node_name:
		soft_body_type = "cylinder"
	elif "capsule" in node_name:
		soft_body_type = "capsule"
	else:
		soft_body_type = "sphere"  # Default fallback
		print("SoftBody: Warning - Could not detect type from name '%s', using default 'sphere'" % name)
	
	print("SoftBody: Detected type '%s' from node name '%s'" % [soft_body_type, name])

func _setup_soft_body():
	if type_properties.has(soft_body_type):
		var props = type_properties[soft_body_type]
		
		# Apply type-specific properties
		pressure_coefficient = props.pressure
		
		# Set simulation precision based on complexity
		match soft_body_type:
			"sphere": simulation_precision = 8
			"box": simulation_precision = 6
			"cylinder": simulation_precision = 10
			"capsule": simulation_precision = 12
		
		print("SoftBody: Initialized %s with properties: %s" % [soft_body_type, props])
	else:
		print("SoftBody: Warning - Unknown type '%s', using defaults" % soft_body_type)

func _setup_physics():
	# Set up collision layers and masks
	collision_layer = 1
	collision_mask = 1
	
	# Set initial position above floor to prevent falling through
	if global_position.y < 1.0:
		global_position.y = 2.0
	
	print("SoftBody: %s physics configured at position %s" % [soft_body_type, global_position])

func _setup_colors():
	# Set up fallback colors for each type
	var fallback_colors = {
		"sphere": Color(0.2, 0.6, 1.0, 0.8),
		"box": Color(1.0, 0.4, 0.6, 0.8),
		"cylinder": Color(0.4, 1.0, 0.6, 0.8),
		"capsule": Color(1.0, 0.8, 0.2, 0.8)
	}
	
	current_color = fallback_colors.get(soft_body_type, Color.WHITE)
	target_color = current_color
	
	print("SoftBody: %s colors initialized" % soft_body_type)

func _setup_interactions():
	if enable_interaction:
		# Connect to wind zone
		var wind_zone = get_node_or_null("../../InteractiveElements/WindZone")
		if wind_zone:
			wind_zone.body_entered.connect(_on_wind_zone_entered)
			wind_zone.body_exited.connect(_on_wind_zone_exited)
		
		# Connect to force field
		var force_field = get_node_or_null("../../InteractiveElements/ForceField")
		if force_field:
			force_field.body_entered.connect(_on_force_field_entered)
			force_field.body_exited.connect(_on_force_field_exited)

func _process(delta):
	_update_state(delta)
	_update_forces(delta)
	_update_colors(delta)
	_apply_external_forces(delta)
	_validate_physics()

func _update_state(delta):
	state_timer += delta
	
	if state_timer >= state_duration:
		_cycle_to_next_state()

func _cycle_to_next_state():
	match current_state:
		BodyState.IDLE:
			_change_state(BodyState.ACTIVE)
		BodyState.ACTIVE:
			_change_state(BodyState.DEFORMED)
		BodyState.DEFORMED:
			_change_state(BodyState.RECOVERING)
		BodyState.RECOVERING:
			_change_state(BodyState.IDLE)

func _change_state(new_state: BodyState):
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		BodyState.IDLE:
			_apply_idle_behavior()
		BodyState.ACTIVE:
			_apply_active_behavior()
		BodyState.DEFORMED:
			_apply_deformed_behavior()
		BodyState.RECOVERING:
			_apply_recovering_behavior()
	
	print("SoftBody: %s changed to state: %s" % [soft_body_type, BodyState.keys()[new_state]])

func _apply_idle_behavior():
	# Gentle, subtle movement
	pressure_coefficient = lerp(pressure_coefficient, type_properties[soft_body_type].pressure, 0.1)
	
	# Subtle color variation
	var base_color = current_color
	target_color = base_color
	target_color.r += sin(Time.get_unix_time_from_system()) * 0.1
	target_color.g += cos(Time.get_unix_time_from_system() * 0.7) * 0.1

func _apply_active_behavior():
	# More dynamic movement
	pressure_coefficient = lerp(pressure_coefficient, type_properties[soft_body_type].pressure * 1.3, 0.2)
	
	# Brighter, more vibrant colors
	target_color = current_color
	target_color.r = min(target_color.r * 1.2, 1.0)
	target_color.g = min(target_color.g * 1.2, 1.0)
	target_color.b = min(target_color.b * 1.2, 1.0)

func _apply_deformed_behavior():
	# Maximum deformation
	pressure_coefficient = lerp(pressure_coefficient, type_properties[soft_body_type].pressure * 1.8, 0.3)
	
	# Intense, saturated colors
	target_color = current_color
	target_color.r = min(target_color.r * 1.5, 1.0)
	target_color.g = min(target_color.g * 1.5, 1.0)
	target_color.b = min(target_color.b * 1.5, 1.0)

func _apply_recovering_behavior():
	# Gradually return to normal
	pressure_coefficient = lerp(pressure_coefficient, type_properties[soft_body_type].pressure, 0.15)
	
	# Return to original color
	var fallback_colors = {
		"sphere": Color(0.2, 0.6, 1.0, 0.8),
		"box": Color(1.0, 0.4, 0.6, 0.8),
		"cylinder": Color(0.4, 1.0, 0.6, 0.8),
		"capsule": Color(1.0, 0.8, 0.2, 0.8)
	}
	target_color = fallback_colors.get(soft_body_type, Color.WHITE)

func _update_forces(delta):
	# Apply wind effect
	if enable_wind_effect and wind_force != Vector3.ZERO:
		_apply_force(wind_force)
	
	# Apply force field
	if enable_force_field and force_field_strength != 0.0:
		var to_center = global_position.direction_to(Vector3.ZERO)
		_apply_force(to_center * force_field_strength)

func _update_colors(delta):
	# Update colors smoothly
	if current_color != target_color:
		current_color = current_color.lerp(target_color, color_transition_speed * delta)

func _apply_external_forces(delta):
	if external_forces != Vector3.ZERO:
		_apply_force(external_forces)
		external_forces = external_forces.lerp(Vector3.ZERO, delta * 2.0)

func _apply_force(force: Vector3):
	"""Apply a force to the soft body using the correct Godot 4 API"""
	# In Godot 4, we need to apply forces to the physics body
	if has_method("apply_impulse"):
		# Apply as impulse if force method not available
		apply_impulse(force * 0.1)  # Scale down for impulse
	else:
		# Fallback: try to move the body directly
		global_position += force * 0.01

# Interactive event handlers
func _on_wind_zone_entered(body):
	if body == self:
		wind_force = Vector3(2.0, 0.0, 1.0)
		print("SoftBody: %s entered wind zone" % soft_body_type)

func _on_wind_zone_exited(body):
	if body == self:
		wind_force = Vector3.ZERO
		print("SoftBody: %s exited wind zone" % soft_body_type)

func _on_force_field_entered(body):
	if body == self:
		force_field_strength = 5.0
		print("SoftBody: %s entered force field" % soft_body_type)

func _on_force_field_exited(body):
	if body == self:
		force_field_strength = 0.0
		print("SoftBody: %s exited force field" % soft_body_type)

# Public API for external control
func apply_impulse(force: Vector3):
	"""Apply an external impulse to the soft body"""
	external_forces += force
	print("SoftBody: %s received impulse: %s" % [soft_body_type, force])

func set_physics_properties(pressure: float):
	"""Dynamically adjust physics properties"""
	pressure_coefficient = pressure
	print("SoftBody: %s physics updated - P:%.2f" % [soft_body_type, pressure])

func reset_to_defaults():
	"""Reset to type-specific default properties"""
	if type_properties.has(soft_body_type):
		var props = type_properties[soft_body_type]
		pressure_coefficient = props.pressure
		print("SoftBody: %s reset to defaults" % soft_body_type)

# Debug functions
func print_status():
	print("SoftBody: %s Status:" % soft_body_type)
	print("  State: %s" % BodyState.keys()[current_state])
	print("  Physics: P=%.2f" % [pressure_coefficient])
	print("  Forces: Wind=%s Field=%.2f External=%s" % [wind_force, force_field_strength, external_forces])

func _validate_physics():
	# Ensure the soft body doesn't fall below the floor
	if global_position.y < -0.5:
		global_position.y = 1.0
		print("SoftBody: %s repositioned above floor" % soft_body_type)
