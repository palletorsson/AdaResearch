extends RigidBody3D

## Resonating Bar
## A musical bar that resonates when hit with a stick
## Produces a sine wave tone that decays slowly

class_name ResonatingBar

signal hit(frequency: float, amplitude: float)
signal resonance_updated(current_amplitude: float)

# Sound properties
@export var frequency: float = 440.0  # Frequency in Hz (musical note)
@export var decay_time: float = 3.0  # How long the sound lasts in seconds
@export var max_amplitude: float = 0.5  # Maximum volume when hit hard

# Visual properties
@export var bar_color: Color = Color(0.8, 0.6, 1.0, 1.0)
@export var glow_intensity: float = 2.0

# Internal state
var is_resonating: bool = false
var current_amplitude: float = 0.0
var resonance_time: float = 0.0
var mesh_instance: MeshInstance3D
var material: StandardMaterial3D
var hit_velocity: float = 0.0

# Audio
var audio_player: AudioStreamPlayer3D
const SAMPLE_RATE = 44100
const SOUND_DURATION = 5.0  # Generate 5 seconds of sound

func _ready() -> void:
	_setup_visual()
	_setup_audio()

	# Connect to collision signal
	body_entered.connect(_on_body_hit)

	print("ResonatingBar: Ready at %.0f Hz" % frequency)

func _setup_visual() -> void:
	# Get or create mesh instance
	mesh_instance = get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		add_child(mesh_instance)

		# Create bar mesh
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(0.1, 0.05, 0.4)  # Thin bar shape
		mesh_instance.mesh = box_mesh

	# Create glowing material
	material = StandardMaterial3D.new()
	material.albedo_color = bar_color
	material.emission_enabled = true
	material.emission = bar_color * 0.0  # Start with no glow
	material.metallic = 0.8
	material.roughness = 0.2
	mesh_instance.material_override = material

func _setup_audio() -> void:
	# Create 3D audio player
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "AudioPlayer"
	audio_player.unit_size = 3.0
	audio_player.max_distance = 20.0
	audio_player.volume_db = -6.0
	add_child(audio_player)

	# Pre-generate the resonating sound
	_generate_resonance_sound()

func _generate_resonance_sound() -> void:
	"""Generate a long resonating sine wave with decay"""
	var sample_count = int(SAMPLE_RATE * SOUND_DURATION)
	var data = PackedByteArray()

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = t / SOUND_DURATION

		# Exponential decay envelope
		var decay_factor = decay_time / SOUND_DURATION
		var envelope = exp(-progress / decay_factor)

		# Pure sine wave at the resonant frequency
		var wave = sin(2.0 * PI * frequency * t)

		# Apply envelope
		var sample_value = wave * envelope * max_amplitude
		var sample_int = int(sample_value * 32767.0)

		# Append as 16-bit PCM
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)

	# Create AudioStreamWAV
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data

	audio_player.stream = stream

func _on_body_hit(body: Node) -> void:
	# Check if hit by the stick or player hand
	var is_stick = body.name.contains("Stick") or body.name.contains("stick") or body.is_in_group("stick")
	var is_hand = body.name.contains("Hand") or body.is_in_group("player_hand")

	if is_stick or is_hand:
		# Calculate hit strength from relative velocity
		var velocity_magnitude = linear_velocity.length()

		# Also check the hitting object's velocity
		if body is RigidBody3D:
			velocity_magnitude = max(velocity_magnitude, body.linear_velocity.length())
		elif body.has_method("get_linear_velocity"):
			velocity_magnitude = max(velocity_magnitude, body.get_linear_velocity().length())

		hit_velocity = clamp(velocity_magnitude * 2.0, 0.1, 1.0)

		_trigger_resonance(hit_velocity)

		print("ResonatingBar: Hit by %s (velocity=%.2f)" % [body.name, velocity_magnitude])

func _trigger_resonance(impact_strength: float) -> void:
	"""Trigger the resonance based on hit strength"""
	is_resonating = true
	resonance_time = 0.0
	current_amplitude = impact_strength * max_amplitude

	# Play sound at appropriate volume
	audio_player.volume_db = -6.0 + (impact_strength * 6.0)  # Louder for harder hits
	audio_player.play()

	# Emit signal
	hit.emit(frequency, current_amplitude)

	# Visual feedback - flash glow
	if material:
		material.emission = bar_color * glow_intensity

	print("ResonatingBar: Hit! freq=%.0f Hz, amplitude=%.2f" % [frequency, current_amplitude])

func _process(delta: float) -> void:
	if is_resonating:
		resonance_time += delta

		# Calculate current amplitude with exponential decay
		var decay_factor = decay_time
		current_amplitude = (hit_velocity * max_amplitude) * exp(-resonance_time / decay_factor)

		# Update glow intensity
		if material:
			var glow_amount = current_amplitude / max_amplitude
			material.emission = bar_color * glow_amount * glow_intensity

		# Emit update signal
		resonance_updated.emit(current_amplitude)

		# Stop resonating when amplitude is very low
		if current_amplitude < 0.001:
			is_resonating = false
			current_amplitude = 0.0
			if material:
				material.emission = Color.BLACK

func get_current_wave_contribution(time: float) -> float:
	"""Get the current wave value for visualization"""
	if not is_resonating:
		return 0.0

	# Sine wave at frequency with current amplitude
	return sin(2.0 * PI * frequency * time) * current_amplitude

# Public API
func force_stop() -> void:
	"""Stop resonating immediately"""
	is_resonating = false
	current_amplitude = 0.0
	audio_player.stop()
	if material:
		material.emission = Color.BLACK

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
