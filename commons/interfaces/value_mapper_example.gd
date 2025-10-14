extends Node3D

# Example demonstrating all three value mappers
# Shows how to map values to various parameters

@onready var mapper_1d = $ValueMapper1D
@onready var mapper_2d = $ValueMapper2D
@onready var mapper_3d = $ValueMapper3D
@onready var demo_sphere = $DemoSphere
@onready var audio_player = $AudioStreamPlayer3D

var time_accumulator: float = 0.0

func _ready() -> void:
	# Connect signals from mappers
	if mapper_1d:
		mapper_1d.value_changed.connect(_on_1d_value_changed)
	if mapper_2d:
		mapper_2d.values_changed.connect(_on_2d_values_changed)
	if mapper_3d:
		mapper_3d.values_changed.connect(_on_3d_values_changed)

	print("Value Mapper Example Scene Loaded")
	print("1D Mapper: Controls sphere size")
	print("2D Mapper: Controls XY position of sphere")
	print("3D Mapper: Controls RGB color of sphere")

func _process(delta: float) -> void:
	time_accumulator += delta

func _on_1d_value_changed(value: float) -> void:
	# Map 1D value to sphere scale
	if demo_sphere:
		var scale_factor = 0.5 + value * 1.5  # Range: 0.5 to 2.0
		demo_sphere.scale = Vector3.ONE * scale_factor
		print("1D: Sphere scale = %.2f" % scale_factor)

func _on_2d_values_changed(x_value: float, y_value: float) -> void:
	# Map 2D values to sphere position (XY only, keep Z constant)
	if demo_sphere:
		var new_pos = demo_sphere.position
		new_pos.x = (x_value - 0.5) * 2.0  # Center around origin
		new_pos.y = (y_value - 0.5) * 2.0 + 1.0  # Offset up
		demo_sphere.position = new_pos
		print("2D: Sphere position X=%.2f, Y=%.2f" % [new_pos.x, new_pos.y])

func _on_3d_values_changed(x_value: float, y_value: float, z_value: float) -> void:
	# Map 3D values to RGB color
	if demo_sphere:
		var color = Color(x_value, y_value, z_value, 1.0)
		var material = demo_sphere.get_surface_override_material(0)
		if not material:
			material = StandardMaterial3D.new()
			demo_sphere.set_surface_override_material(0, material)
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * 0.5
		print("3D: Sphere color RGB=(%.2f, %.2f, %.2f)" % [x_value, y_value, z_value])

# Alternative examples for different use cases:

# Example: Map to audio parameters
func map_to_audio(frequency: float, amplitude: float) -> void:
	if audio_player:
		# frequency could control pitch
		# amplitude could control volume
		audio_player.volume_db = linear_to_db(amplitude)
		print("Audio: Volume = %.2f dB" % audio_player.volume_db)

# Example: Map to VR hand nail colors
func map_to_hand_nails(r: float, g: float, b: float) -> void:
	var nail_color = Color(r, g, b, 1.0)
	# This would connect to your VR hand material
	# For example: vr_hand.get_node("Nails").material.albedo_color = nail_color
	print("Hand nails: RGB=(%.2f, %.2f, %.2f)" % [r, g, b])

# Example: Map to sine wave parameters
func map_to_sine_wave(amplitude: float, frequency: float, phase: float) -> void:
	var t = time_accumulator
	var wave_value = amplitude * sin(frequency * t + phase)
	print("Sine wave: amp=%.2f, freq=%.2f, phase=%.2f, value=%.2f" %
		[amplitude, frequency, phase, wave_value])
