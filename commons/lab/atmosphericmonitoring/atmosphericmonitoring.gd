# atmosphericmonitoring.gd
# Atmospheric monitoring station with oscillating gauges
# Demonstrates multiple sine waves at different frequencies
extends Node3D

class_name LabAtmosphericMonitoring


# @identity
# essence: reading(t) = base + variation * sin(frequency * t * TAU) + noise
# desire: Watch laboratory instruments slowly drift through atmospheric measurements
# critical_parameter: pressure_frequency — controls the speed of atmospheric drift cycles
# triggers: time drives sinusoidal variation in pressure, temperature, humidity needles
# emerges: the feeling of a living laboratory where instruments never fully settle
# needs: VR needle observation [has], alert threshold adjustment [missing]
# relationships: depends on sine-driven gauge animation; contrasts with multimeter (AC measurement vs environmental monitoring); unlocks lab atmosphere
# truth: The atmosphere is a superposition of slow oscillations that instruments make legible.

@export_group("Pressure")
@export var pressure_base: float = 1013.25  # hPa (standard atm)
@export var pressure_variation: float = 5.0  # hPa
@export var pressure_frequency: float = 0.05  # Hz (slow drift)

@export_group("Temperature")
@export var temp_base: float = 22.0  # Celsius
@export var temp_variation: float = 0.5
@export var temp_frequency: float = 0.02

@export_group("Humidity")
@export var humidity_base: float = 45.0  # Percent
@export var humidity_variation: float = 5.0
@export var humidity_frequency: float = 0.03

## Internal
var time: float = 0.0
var pressure_needle: Node3D
var temp_needle: Node3D
var humidity_needle: Node3D
var status_lights: Array[OmniLight3D] = []
var display_panel: MeshInstance3D

func _ready() -> void:
	_build_station()

func _process(delta: float) -> void:
	time += delta
	
	# Pressure gauge - slow sine wave
	var pressure = pressure_base + pressure_variation * sin(time * pressure_frequency * TAU)
	if pressure_needle:
		var pressure_angle = (pressure - 980.0) / 70.0 * 180.0 - 90.0  # Map 980-1050 to -90 to 90
		pressure_needle.rotation_degrees.z = clamp(pressure_angle, -90.0, 90.0)
	
	# Temperature gauge - different frequency
	var temp = temp_base + temp_variation * sin(time * temp_frequency * TAU)
	if temp_needle:
		var temp_angle = (temp - 15.0) / 20.0 * 180.0 - 90.0  # Map 15-35 to -90 to 90
		temp_needle.rotation_degrees.z = clamp(temp_angle, -90.0, 90.0)
	
	# Humidity gauge - third frequency
	var humidity = humidity_base + humidity_variation * sin(time * humidity_frequency * TAU)
	if humidity_needle:
		var humidity_angle = humidity / 100.0 * 180.0 - 90.0  # Map 0-100 to -90 to 90
		humidity_needle.rotation_degrees.z = clamp(humidity_angle, -90.0, 90.0)
	
	# Status lights - green when in normal range
	_update_status_lights(pressure, temp, humidity)
	
	# Display panel pulse
	if display_panel and display_panel.material_override:
		var pulse = 0.6 + 0.2 * sin(time * 1.0)
		display_panel.material_override.emission_energy_multiplier = pulse

func _update_status_lights(pressure: float, temp: float, humidity: float) -> void:
	if status_lights.size() < 3:
		return
	
	# Pressure status
	if abs(pressure - 1013.25) < 10.0:
		status_lights[0].light_color = Color.GREEN
	else:
		status_lights[0].light_color = Color.YELLOW
	
	# Temperature status
	if temp >= 18.0 and temp <= 26.0:
		status_lights[1].light_color = Color.GREEN
	else:
		status_lights[1].light_color = Color.YELLOW
	
	# Humidity status
	if humidity >= 30.0 and humidity <= 60.0:
		status_lights[2].light_color = Color.GREEN
	else:
		status_lights[2].light_color = Color.YELLOW
	
	# Pulse all lights
	for light in status_lights:
		light.light_energy = 0.3 + 0.2 * sin(time * 2.0)

func _build_station() -> void:
	for child in get_children():
		child.queue_free()
	status_lights.clear()
	
	# Main housing
	var housing = MeshInstance3D.new()
	housing.name = "Housing"
	var housing_mesh = BoxMesh.new()
	housing_mesh.size = Vector3(0.35, 0.25, 0.08)
	housing.mesh = housing_mesh
	housing.position = Vector3(0, 0.125, 0)
	var housing_mat = StandardMaterial3D.new()
	housing_mat.albedo_color = Color(0.2, 0.22, 0.25)
	housing_mat.metallic = 0.3
	housing_mat.roughness = 0.6
	housing.material_override = housing_mat
	add_child(housing)
	
	# Create three circular gauges
	var gauge_data = [
		{"name": "Pressure", "pos": Vector3(-0.1, 0.16, 0.041), "color": Color(0.2, 0.6, 1.0)},
		{"name": "Temperature", "pos": Vector3(0.0, 0.16, 0.041), "color": Color(1.0, 0.4, 0.2)},
		{"name": "Humidity", "pos": Vector3(0.1, 0.16, 0.041), "color": Color(0.2, 0.8, 0.4)},
	]
	
	var needles: Array[Node3D] = []
	
	for data in gauge_data:
		var gauge = _create_gauge(data.pos, data.color, data.name)
		needles.append(gauge)
	
	pressure_needle = needles[0]
	temp_needle = needles[1]
	humidity_needle = needles[2]
	
	# Digital display panel
	display_panel = MeshInstance3D.new()
	display_panel.name = "DisplayPanel"
	var display_mesh = BoxMesh.new()
	display_mesh.size = Vector3(0.28, 0.05, 0.003)
	display_panel.mesh = display_mesh
	display_panel.position = Vector3(0, 0.06, 0.041)
	var display_mat = StandardMaterial3D.new()
	display_mat.albedo_color = Color(0.05, 0.1, 0.05)
	display_mat.emission_enabled = true
	display_mat.emission = Color(0.1, 0.8, 0.3)
	display_mat.emission_energy_multiplier = 0.6
	display_panel.material_override = display_mat
	add_child(display_panel)
	
	# Status indicator lights
	var light_positions = [
		Vector3(-0.1, 0.095, 0.041),
		Vector3(0.0, 0.095, 0.041),
		Vector3(0.1, 0.095, 0.041),
	]
	
	for pos in light_positions:
		var light = OmniLight3D.new()
		light.position = pos
		light.light_color = Color.GREEN
		light.light_energy = 0.3
		light.omni_range = 0.05
		add_child(light)
		status_lights.append(light)
		
		var led = MeshInstance3D.new()
		var led_mesh = SphereMesh.new()
		led_mesh.radius = 0.006
		led_mesh.height = 0.012
		led.mesh = led_mesh
		var led_mat = StandardMaterial3D.new()
		led_mat.albedo_color = Color.GREEN
		led_mat.emission_enabled = true
		led_mat.emission = Color.GREEN
		led_mat.emission_energy_multiplier = 1.0
		led.material_override = led_mat
		light.add_child(led)
	
	# Ventilation grille
	var grille = MeshInstance3D.new()
	grille.name = "Grille"
	var grille_mesh = BoxMesh.new()
	grille_mesh.size = Vector3(0.08, 0.03, 0.005)
	grille.mesh = grille_mesh
	grille.position = Vector3(0.12, 0.025, 0.041)
	var grille_mat = StandardMaterial3D.new()
	grille_mat.albedo_color = Color(0.15, 0.15, 0.18)
	grille.material_override = grille_mat
	add_child(grille)

func _create_gauge(pos: Vector3, accent_color: Color, gauge_name: String) -> Node3D:
	var gauge_radius = 0.035
	
	# Gauge face
	var face = MeshInstance3D.new()
	face.name = gauge_name + "Face"
	var face_mesh = CylinderMesh.new()
	face_mesh.top_radius = gauge_radius
	face_mesh.bottom_radius = gauge_radius
	face_mesh.height = 0.005
	face_mesh.radial_segments = 32
	face.mesh = face_mesh
	face.position = pos
	face.rotation.x = PI / 2
	var face_mat = StandardMaterial3D.new()
	face_mat.albedo_color = Color(0.95, 0.95, 0.9)
	face.material_override = face_mat
	add_child(face)
	
	# Gauge rim
	var rim = MeshInstance3D.new()
	var rim_mesh = TorusMesh.new()
	rim_mesh.inner_radius = gauge_radius - 0.003
	rim_mesh.outer_radius = gauge_radius
	rim.mesh = rim_mesh
	rim.position = pos + Vector3(0, 0, 0.003)
	rim.rotation.x = PI / 2
	var rim_mat = StandardMaterial3D.new()
	rim_mat.albedo_color = accent_color
	rim_mat.metallic = 0.7
	rim.material_override = rim_mat
	add_child(rim)
	
	# Needle pivot
	var needle_pivot = Node3D.new()
	needle_pivot.name = gauge_name + "NeedlePivot"
	needle_pivot.position = pos + Vector3(0, 0, 0.004)
	add_child(needle_pivot)
	
	# Needle
	var needle = MeshInstance3D.new()
	needle.name = gauge_name + "Needle"
	var needle_mesh = BoxMesh.new()
	needle_mesh.size = Vector3(0.003, 0.028, 0.001)
	needle.mesh = needle_mesh
	needle.position = Vector3(0, 0.012, 0)
	var needle_mat = StandardMaterial3D.new()
	needle_mat.albedo_color = Color(0.8, 0.1, 0.1)
	needle.material_override = needle_mat
	needle_pivot.add_child(needle)
	
	# Center cap
	var cap = MeshInstance3D.new()
	var cap_mesh = SphereMesh.new()
	cap_mesh.radius = 0.004
	cap_mesh.height = 0.008
	cap.mesh = cap_mesh
	cap.position = pos + Vector3(0, 0, 0.005)
	var cap_mat = StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.2, 0.2, 0.22)
	cap_mat.metallic = 0.8
	cap.material_override = cap_mat
	add_child(cap)
	
	return needle_pivot

## Public API
func get_pressure() -> float:
	return pressure_base + pressure_variation * sin(time * pressure_frequency * TAU)

func get_temperature() -> float:
	return temp_base + temp_variation * sin(time * temp_frequency * TAU)

func get_humidity() -> float:
	return humidity_base + humidity_variation * sin(time * humidity_frequency * TAU)

func set_alert_conditions(pressure_alert: float, temp_alert: float, humidity_alert: float) -> void:
	pressure_variation = pressure_alert
	temp_variation = temp_alert
	humidity_variation = humidity_alert
