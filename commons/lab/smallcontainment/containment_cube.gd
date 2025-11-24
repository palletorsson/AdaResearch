extends Node3D

@onready var containment_walls = [$CubeStructure/BackWall, $CubeStructure/LeftWall, $CubeStructure/RightWall, $CubeStructure/TopWall, $CubeStructure/BottomWall]
@onready var contained_specimen = $CubeStructure/ContainedSpecimen
@onready var energy_field = $CubeStructure/EnergyField
@onready var status_indicators = [$CubeStructure/StatusIndicator1, $CubeStructure/StatusIndicator2, $CubeStructure/StatusIndicator3]
@onready var field_projectors = [$CubeStructure/FieldProjector1, $CubeStructure/FieldProjector2, $CubeStructure/FieldProjector3, $CubeStructure/FieldProjector4]

var containment_active = true
var specimen_type = 'anomalous_sample'
var field_strength = 100.0
var containment_breach_risk = 0.0
var cube_size = 0.2  # 20cm desktop cube

signal containment_stabilized
signal breach_warning
signal specimen_contained
signal field_fluctuation

func _ready():
	setup_containment_cube()
	initialize_containment_field()

func setup_containment_cube():
	add_to_group('desk_equipment')
	add_to_group('containment_devices')
	add_to_group('specimen_storage')

func initialize_containment_field():
	# Start field projector animations
	animate_field_projectors()
	
	# Specimen floating animation
	animate_contained_specimen()
	
	# Status monitoring
	start_containment_monitoring()

func animate_field_projectors():
	for i in range(field_projectors.size()):
		var projector = field_projectors[i]
		var phase_offset = i * (PI / 2.0)  # 90 degree phase separation
		
		var projector_tween = create_tween()
		projector_tween.set_loops()
		projector_tween.tween_method(pulse_field_projector.bind(projector, phase_offset), 0.0, TAU, 3.0)

func pulse_field_projector(projector: Node3D, phase_offset: float, time: float):
	var intensity = sin(time + phase_offset) * 0.3 + 0.7
	projector.light_energy = intensity * (field_strength / 100.0)

func animate_contained_specimen():
	# Specimen floating inside the cube
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(contained_specimen, 'position:y', 0.02, 3.0)
	float_tween.tween_property(contained_specimen, 'position:y', -0.02, 3.0)
	
	# Gentle rotation
	var rotate_tween = create_tween()
	rotate_tween.set_loops()
	rotate_tween.tween_property(contained_specimen, 'rotation_degrees:y', 360.0, 12.0)

func start_containment_monitoring():
	var monitor_timer = Timer.new()
	monitor_timer.wait_time = 2.0
	monitor_timer.timeout.connect(monitor_containment_integrity)
	monitor_timer.autostart = true
	add_child(monitor_timer)

func monitor_containment_integrity():
	# Simulate field fluctuations
	field_strength += randf_range(-5.0, 2.0)
	field_strength = clamp(field_strength, 60.0, 100.0)
	
	# Calculate breach risk
	containment_breach_risk = (100.0 - field_strength) / 100.0
	
	# Update energy field visibility
	update_energy_field_visuals()
	
	# Check for critical conditions
	if field_strength < 75.0:
		trigger_breach_warning()
	elif field_strength < 85.0:
		emit_signal('field_fluctuation', field_strength)

func update_energy_field_visuals():
	# Field opacity based on strength
	var field_alpha = (field_strength / 100.0) * 0.4
	energy_field.material_override.albedo_color.a = field_alpha
	
	# Color shifts based on stability
	if field_strength > 90.0:
		energy_field.material_override.emission = Color.CYAN
	elif field_strength > 75.0:
		energy_field.material_override.emission = Color.YELLOW
	else:
		energy_field.material_override.emission = Color.RED
	
	# Pulsing intensity for unstable fields - FIXED: use emission_energy_multiplier
	if field_strength < 80.0:
		var pulse_tween = create_tween()
		pulse_tween.tween_property(energy_field, 'material_override:emission_energy_multiplier', 2.0, 0.5)
		pulse_tween.tween_property(energy_field, 'material_override:emission_energy_multiplier', 1.0, 0.5)

func trigger_breach_warning():
	emit_signal('breach_warning', containment_breach_risk)
	
	# Flash status indicators
	for indicator in status_indicators:
		var warning_tween = create_tween()
		warning_tween.set_loops(3)
		warning_tween.tween_property(indicator, 'light_color', Color.RED, 0.2)
		warning_tween.tween_property(indicator, 'light_color', Color.BLUE, 0.2)

func _on_area_3d_body_entered(body):
	if body.is_in_group('player'):
		analyze_contained_specimen()

func analyze_contained_specimen():
	print('🔍 CONTAINMENT CUBE: Analyzing specimen properties...')
	print('  Specimen Type: %s' % specimen_type)
	print('  Field Strength: %.1f%%' % field_strength)
	print('  Breach Risk: %.1f%%' % (containment_breach_risk * 100))
	print('  Containment Status: %s' % ('STABLE' if field_strength > 85.0 else 'UNSTABLE'))

func reinforce_containment_field():
	field_strength = 100.0
	containment_breach_risk = 0.0
	
	# Visual reinforcement effect - FIXED: use emission_energy_multiplier
	var reinforce_tween = create_tween()
	reinforce_tween.tween_property(energy_field, 'material_override:emission_energy_multiplier', 3.0, 1.0)
	reinforce_tween.tween_property(energy_field, 'material_override:emission_energy_multiplier', 1.5, 1.0)
	
	emit_signal('containment_stabilized')

func emergency_containment_protocol():
	# Maximum field strength
	field_strength = 100.0
	
	# Lock down specimen
	var lockdown_tween = create_tween()
	lockdown_tween.tween_property(contained_specimen, 'scale', Vector3(0.8, 0.8, 0.8), 0.5)
	
	# Intensify all field projectors
	for projector in field_projectors:
		projector.light_energy = 2.0
		projector.light_color = Color.WHITE

func specimen_interaction_detected():
	# Specimen becomes more active - FIXED: use emission_energy_multiplier
	var reaction_tween = create_tween()
	reaction_tween.tween_property(contained_specimen, 'material_override:emission_energy_multiplier', 2.5, 1.0)
	reaction_tween.tween_property(contained_specimen, 'material_override:emission_energy_multiplier', 1.0, 2.0)
	
	# Slight field fluctuation in response
	field_strength -= 10.0

func change_specimen(new_specimen_type: String, specimen_color: Color):
	specimen_type = new_specimen_type
	contained_specimen.material_override.emission = specimen_color
	contained_specimen.material_override.albedo_color = specimen_color
	
	emit_signal('specimen_contained', specimen_type)

func toggle_containment_access():
	# The front wall is missing for access, but we can simulate opening/closing
	if containment_active:
		field_strength *= 0.7
	else:
		field_strength = 100.0
	
	containment_active = not containment_active
