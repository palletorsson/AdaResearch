# electronicscales.gd
# Laboratory electronic scales with damped sine settling
# Demonstrates damped harmonic oscillation
extends Node3D

class_name LabElectronicScales


# @identity
# essence: display(t) = target + amplitude * e^(-damping*t) * sin(omega*t) — damped oscillation to final reading
# desire: Place objects on a scale and watch the reading oscillate before settling to true weight
# critical_parameter: damping_factor — controls how fast oscillation decays to the final reading
# triggers: start_weighing() initiates the damped oscillation sequence; tare() resets the zero
# emerges: the drama of measurement — truth approached through diminishing oscillation
# needs: VR object placement [missing], weight detection [missing]
# relationships: depends on damped harmonic oscillator equation; contrasts with multimeter (mass vs voltage measurement); unlocks damped oscillation intuition
# truth: Every precise measurement is the residue of an oscillation that has almost died.

@export_group("Physics")
@export var damping_factor: float = 2.0  # How fast oscillation decays
@export var oscillation_frequency: float = 4.0  # Hz
@export var settling_time: float = 3.0  # Seconds to fully settle

@export_group("Display")
@export var display_color: Color = Color(0.2, 1.0, 0.5)
@export var target_weight: float = 125.7  # Grams

## Internal
var time: float = 0.0
var is_weighing: bool = false
var weigh_start_time: float = 0.0
var displayed_weight: float = 0.0
var platform_node: Node3D
var display_node: MeshInstance3D
var indicator_light: OmniLight3D

func _ready() -> void:
	_build_scales()
	# Start idle - occasional drift
	displayed_weight = 0.0

func _process(delta: float) -> void:
	time += delta
	
	if is_weighing:
		var elapsed = time - weigh_start_time
		
		# Damped sine oscillation: A * e^(-bt) * sin(wt)
		var decay = exp(-damping_factor * elapsed)
		var oscillation = sin(elapsed * oscillation_frequency * TAU)
		var deviation = decay * oscillation * target_weight * 0.1
		
		displayed_weight = target_weight + deviation
		
		# Check if settled
		if elapsed > settling_time:
			displayed_weight = target_weight
			is_weighing = false
	else:
		# Idle state - tiny random drift
		displayed_weight += (randf() - 0.5) * 0.01
		if abs(displayed_weight) < 0.1:
			displayed_weight = 0.0
	
	_update_display()

func _update_display() -> void:
	# Platform slight movement during weighing
	if platform_node and is_weighing:
		var elapsed = time - weigh_start_time
		var decay = exp(-damping_factor * elapsed)
		var bounce = decay * sin(elapsed * oscillation_frequency * TAU) * 0.002
		platform_node.position.y = 0.06 + bounce
	elif platform_node:
		platform_node.position.y = 0.06
	
	# Display brightness
	if display_node and display_node.material_override:
		var brightness = 0.8 + 0.2 * sin(time * 2.0)
		if is_weighing:
			brightness = 1.2  # Brighter during weighing
		display_node.material_override.emission_energy_multiplier = brightness
	
	# Indicator light
	if indicator_light:
		if is_weighing:
			indicator_light.light_color = Color.YELLOW
			indicator_light.light_energy = 0.5 + 0.5 * sin(time * 8.0)
		else:
			indicator_light.light_color = Color.GREEN
			indicator_light.light_energy = 0.3

func _build_scales() -> void:
	for child in get_children():
		child.queue_free()
	
	# Main body
	var body = MeshInstance3D.new()
	body.name = "Body"
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(0.18, 0.05, 0.22)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.025, 0)
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.85, 0.85, 0.88)
	body_mat.roughness = 0.6
	body.material_override = body_mat
	add_child(body)
	
	# Weighing platform
	platform_node = Node3D.new()
	platform_node.name = "PlatformPivot"
	platform_node.position = Vector3(0, 0.06, 0.02)
	add_child(platform_node)
	
	var platform = MeshInstance3D.new()
	platform.name = "Platform"
	var platform_mesh = CylinderMesh.new()
	platform_mesh.top_radius = 0.07
	platform_mesh.bottom_radius = 0.07
	platform_mesh.height = 0.008
	platform_mesh.radial_segments = 32
	platform.mesh = platform_mesh
	var platform_mat = StandardMaterial3D.new()
	platform_mat.albedo_color = Color(0.75, 0.78, 0.8)
	platform_mat.metallic = 0.9
	platform_mat.roughness = 0.1
	platform.material_override = platform_mat
	platform_node.add_child(platform)
	
	# Display panel
	var display_housing = MeshInstance3D.new()
	display_housing.name = "DisplayHousing"
	var housing_mesh = BoxMesh.new()
	housing_mesh.size = Vector3(0.12, 0.04, 0.02)
	display_housing.mesh = housing_mesh
	display_housing.position = Vector3(0, 0.07, -0.09)
	display_housing.rotation.x = -0.3
	var housing_mat = StandardMaterial3D.new()
	housing_mat.albedo_color = Color(0.2, 0.2, 0.22)
	display_housing.material_override = housing_mat
	add_child(display_housing)
	
	# LCD Display
	display_node = MeshInstance3D.new()
	display_node.name = "Display"
	var display_mesh = BoxMesh.new()
	display_mesh.size = Vector3(0.08, 0.025, 0.002)
	display_node.mesh = display_mesh
	display_node.position = Vector3(0, 0.005, 0.011)
	var display_mat = StandardMaterial3D.new()
	display_mat.albedo_color = Color(0.05, 0.08, 0.05)
	display_mat.emission_enabled = true
	display_mat.emission = display_color
	display_mat.emission_energy_multiplier = 0.8
	display_node.material_override = display_mat
	display_housing.add_child(display_node)
	
	# Status indicator
	indicator_light = OmniLight3D.new()
	indicator_light.name = "StatusLight"
	indicator_light.position = Vector3(0.05, 0.005, 0.011)
	indicator_light.light_color = Color.GREEN
	indicator_light.light_energy = 0.3
	indicator_light.omni_range = 0.1
	display_housing.add_child(indicator_light)
	
	var led = MeshInstance3D.new()
	var led_mesh = SphereMesh.new()
	led_mesh.radius = 0.003
	led_mesh.height = 0.006
	led.mesh = led_mesh
	var led_mat = StandardMaterial3D.new()
	led_mat.albedo_color = Color.GREEN
	led_mat.emission_enabled = true
	led_mat.emission = Color.GREEN
	led_mat.emission_energy_multiplier = 1.0
	led.material_override = led_mat
	indicator_light.add_child(led)
	
	# Buttons
	var button_positions = [
		Vector3(-0.04, 0.026, 0.08),
		Vector3(-0.02, 0.026, 0.08),
		Vector3(0.02, 0.026, 0.08),
	]
	var button_colors = [Color(0.2, 0.6, 0.2), Color(0.6, 0.6, 0.2), Color(0.6, 0.2, 0.2)]
	
	for i in range(button_positions.size()):
		var btn = MeshInstance3D.new()
		var btn_mesh = CylinderMesh.new()
		btn_mesh.top_radius = 0.008
		btn_mesh.bottom_radius = 0.008
		btn_mesh.height = 0.004
		btn.mesh = btn_mesh
		btn.position = button_positions[i]
		btn.rotation.x = PI / 2
		var btn_mat = StandardMaterial3D.new()
		btn_mat.albedo_color = button_colors[i]
		btn.material_override = btn_mat
		add_child(btn)

## Public API
func start_weighing(weight: float = -1.0) -> void:
	if weight > 0:
		target_weight = weight
	is_weighing = true
	weigh_start_time = time
	displayed_weight = 0.0

func tare() -> void:
	displayed_weight = 0.0
	target_weight = 0.0
	is_weighing = false

func get_weight() -> float:
	return displayed_weight

func set_damping(d: float) -> void:
	damping_factor = d

func set_frequency(f: float) -> void:
	oscillation_frequency = f
