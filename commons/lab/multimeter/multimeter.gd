# multimeter.gd
# Digital multimeter with analog-style oscillating needle
# Demonstrates AC waveforms and frequency measurement
extends Node3D

class_name LabMultimeter

@export_group("Measurement")
@export var ac_frequency: float = 1.0  # Hz
@export var ac_amplitude: float = 5.0  # Volts peak
@export var dc_offset: float = 0.0
@export var noise_level: float = 0.1
@export_enum("AC_VOLTAGE", "DC_VOLTAGE", "RESISTANCE", "FREQUENCY") var mode: int = 0

@export_group("Display")
@export var lcd_color: Color = Color(0.2, 1.0, 0.4)
@export var needle_color: Color = Color(1.0, 0.3, 0.1)

## Internal
var time: float = 0.0
var current_reading: float = 0.0
var needle_node: Node3D
var lcd_node: MeshInstance3D
var needle_mesh: MeshInstance3D
var status_led: OmniLight3D

func _ready() -> void:
	_build_multimeter()

func _process(delta: float) -> void:
	time += delta
	
	match mode:
		0:  # AC Voltage - sine wave
			current_reading = ac_amplitude * sin(time * ac_frequency * TAU) + dc_offset
			current_reading += (randf() - 0.5) * noise_level
		1:  # DC Voltage - steady with noise
			current_reading = dc_offset + (randf() - 0.5) * noise_level * 0.5
		2:  # Resistance - slow drift
			current_reading = 1000.0 + 50.0 * sin(time * 0.3) + randf() * 10.0
		3:  # Frequency - displays the frequency
			current_reading = ac_frequency + (randf() - 0.5) * 0.01
	
	_update_display()

func _update_display() -> void:
	# Needle deflection based on reading
	if needle_node:
		var deflection: float
		match mode:
			0, 1:  # Voltage modes
				deflection = clamp(current_reading / 10.0, -1.0, 1.0) * 45.0
			2:  # Resistance
				deflection = clamp(log(current_reading) / 10.0, 0.0, 1.0) * 90.0 - 45.0
			3:  # Frequency
				deflection = clamp(current_reading / 5.0, 0.0, 1.0) * 90.0 - 45.0
		needle_node.rotation_degrees.z = deflection
	
	# LCD brightness pulses with measurement
	if lcd_node and lcd_node.material_override:
		var brightness = 0.8 + 0.4 * abs(sin(time * 2.0))
		lcd_node.material_override.emission_energy_multiplier = brightness
	
	# Status LED blinks at measurement rate
	if status_led:
		var blink = 0.5 + 0.5 * sin(time * ac_frequency * TAU * 2.0)
		status_led.light_energy = blink

func _build_multimeter() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()
	
	# Main body
	var body = MeshInstance3D.new()
	body.name = "Body"
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(0.12, 0.18, 0.035)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.09, 0)
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.15, 0.15, 0.18)
	body_mat.roughness = 0.7
	body.material_override = body_mat
	add_child(body)
	
	# LCD Display
	lcd_node = MeshInstance3D.new()
	lcd_node.name = "LCD"
	var lcd_mesh = BoxMesh.new()
	lcd_mesh.size = Vector3(0.08, 0.035, 0.003)
	lcd_node.mesh = lcd_mesh
	lcd_node.position = Vector3(0, 0.14, 0.019)
	var lcd_mat = StandardMaterial3D.new()
	lcd_mat.albedo_color = Color(0.05, 0.1, 0.05)
	lcd_mat.emission_enabled = true
	lcd_mat.emission = lcd_color
	lcd_mat.emission_energy_multiplier = 1.0
	lcd_node.material_override = lcd_mat
	add_child(lcd_node)
	
	# Analog needle gauge
	var gauge_bg = MeshInstance3D.new()
	gauge_bg.name = "GaugeBackground"
	var gauge_mesh = CylinderMesh.new()
	gauge_mesh.top_radius = 0.035
	gauge_mesh.bottom_radius = 0.035
	gauge_mesh.height = 0.003
	gauge_mesh.radial_segments = 32
	gauge_bg.mesh = gauge_mesh
	gauge_bg.rotation.x = PI / 2
	gauge_bg.position = Vector3(0, 0.095, 0.019)
	var gauge_mat = StandardMaterial3D.new()
	gauge_mat.albedo_color = Color(0.95, 0.95, 0.9)
	gauge_bg.material_override = gauge_mat
	add_child(gauge_bg)
	
	# Needle pivot
	needle_node = Node3D.new()
	needle_node.name = "NeedlePivot"
	needle_node.position = Vector3(0, 0.095, 0.021)
	add_child(needle_node)
	
	# Needle
	needle_mesh = MeshInstance3D.new()
	needle_mesh.name = "Needle"
	var n_mesh = BoxMesh.new()
	n_mesh.size = Vector3(0.002, 0.03, 0.001)
	needle_mesh.mesh = n_mesh
	needle_mesh.position = Vector3(0, 0.015, 0)
	var needle_mat = StandardMaterial3D.new()
	needle_mat.albedo_color = needle_color
	needle_mat.emission_enabled = true
	needle_mat.emission = needle_color
	needle_mat.emission_energy_multiplier = 0.5
	needle_mesh.material_override = needle_mat
	needle_node.add_child(needle_mesh)
	
	# Rotary dial
	var dial = MeshInstance3D.new()
	dial.name = "Dial"
	var dial_mesh = CylinderMesh.new()
	dial_mesh.top_radius = 0.02
	dial_mesh.bottom_radius = 0.02
	dial_mesh.height = 0.008
	dial.mesh = dial_mesh
	dial.rotation.x = PI / 2
	dial.position = Vector3(0, 0.045, 0.019)
	var dial_mat = StandardMaterial3D.new()
	dial_mat.albedo_color = Color(0.3, 0.3, 0.35)
	dial_mat.metallic = 0.8
	dial_mat.roughness = 0.2
	dial.material_override = dial_mat
	add_child(dial)
	
	# Status LED
	status_led = OmniLight3D.new()
	status_led.name = "StatusLED"
	status_led.position = Vector3(0.04, 0.16, 0.019)
	status_led.light_color = Color.GREEN
	status_led.light_energy = 0.5
	status_led.omni_range = 0.1
	add_child(status_led)
	
	var led_mesh = MeshInstance3D.new()
	var led_sphere = SphereMesh.new()
	led_sphere.radius = 0.004
	led_sphere.height = 0.008
	led_mesh.mesh = led_sphere
	var led_mat = StandardMaterial3D.new()
	led_mat.albedo_color = Color.GREEN
	led_mat.emission_enabled = true
	led_mat.emission = Color.GREEN
	led_mat.emission_energy_multiplier = 2.0
	led_mesh.material_override = led_mat
	status_led.add_child(led_mesh)
	
	# Probe ports (red and black)
	_add_probe_port(Vector3(-0.03, 0.01, 0.0), Color.RED)
	_add_probe_port(Vector3(0.03, 0.01, 0.0), Color.BLACK)

func _add_probe_port(pos: Vector3, color: Color) -> void:
	var port = MeshInstance3D.new()
	var port_mesh = CylinderMesh.new()
	port_mesh.top_radius = 0.006
	port_mesh.bottom_radius = 0.006
	port_mesh.height = 0.01
	port.mesh = port_mesh
	port.position = pos
	var port_mat = StandardMaterial3D.new()
	port_mat.albedo_color = color
	port_mat.metallic = 0.7
	port.material_override = port_mat
	add_child(port)

## Public API
func set_frequency(freq: float) -> void:
	ac_frequency = freq

func set_amplitude(amp: float) -> void:
	ac_amplitude = amp

func get_reading() -> float:
	return current_reading
