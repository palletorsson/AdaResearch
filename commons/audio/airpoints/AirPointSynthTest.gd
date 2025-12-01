# AirPointSynthTest.gd
# Path: res://commons/audio/airpoints/AirPointSynthTest.gd
# Agent: Agent-SynthesisEngineer (Agent B)
# Test scene controller for Teropa-style Air Point synthesizer
#
# Controls:
# - Arrow Keys: Move Air Point horizontally (X/Z)
# - Q/E: Move Air Point vertically (Y)
# - Space: Reset to starting position
# - V: Toggle voice mix (Sawtooth ↔ Sine)
# - H: Cycle harmonicity values
# - +/-: Adjust movement speed

extends Node3D

@onready var air_point: Node3D = $AirPoint
@onready var listener: SystemsMusicListener = $SystemsMusicListener
@onready var synth: SystemsMusicSynth = $SystemsMusicSynth
@onready var reference_point: Node3D = $ReferencePoint

## Movement speed (meters per second)
var movement_speed: float = 3.0

## Starting position
var start_position: Vector3 = Vector3(4, 0, 0)

## UI label for displaying info
var info_label: Label = null

## Voice mix toggle state
var voice_mix_index: int = 1  # 0=sawtooth, 1=mixed, 2=sine

## Harmonicity presets
var harmonicity_index: int = 0
var harmonicity_presets: Array[float] = [1.0, 1.5, 2.0, 0.5, 1.25]


func _ready() -> void:
	# Set starting position
	if air_point:
		air_point.global_position = start_position
	
	# Create UI overlay
	_create_ui()
	
	print("=== Air Point Synth Test (Teropa-Style) ===")
	print("Discreet Music Synthesis - All sounds synthesized")
	print("")
	print("Controls:")
	print("  Arrow Keys: Move Air Point (X/Z)")
	print("  Q/E: Move Air Point (Y)")
	print("  Space: Reset position")
	print("  V: Toggle voice mix")
	print("  H: Cycle harmonicity")
	print("  +/-: Adjust speed")
	print("==========================================")


func _process(delta: float) -> void:
	if not air_point:
		return
	
	# === MOVEMENT INPUT ===
	var movement = Vector3.ZERO
	
	# Horizontal movement (X/Z plane)
	if Input.is_key_pressed(KEY_LEFT):
		movement.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		movement.x += 1.0
	if Input.is_key_pressed(KEY_UP):
		movement.z -= 1.0
	if Input.is_key_pressed(KEY_DOWN):
		movement.z += 1.0
	
	# Vertical movement (Y)
	if Input.is_key_pressed(KEY_Q):
		movement.y += 1.0
	if Input.is_key_pressed(KEY_E):
		movement.y -= 1.0
	
	# Apply movement
	if movement.length() > 0:
		movement = movement.normalized() * movement_speed * delta
		air_point.global_position += movement
	
	# Update stereo panning based on X position
	if synth:
		synth.set_pan_from_position(air_point.global_position.x, 10.0)
	
	# Update UI
	_update_ui()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				# Reset position
				if air_point:
					air_point.global_position = start_position
					print("Air Point reset to starting position")
			
			KEY_V:
				# Toggle voice mix
				voice_mix_index = (voice_mix_index + 1) % 3
				if synth:
					match voice_mix_index:
						0:
							synth.voice_mix = 0.0  # All sawtooth
							print("Voice Mix: SAWTOOTH (harmonically rich)")
						1:
							synth.voice_mix = 0.5  # Mixed
							print("Voice Mix: MIXED (balanced)")
						2:
							synth.voice_mix = 1.0  # All sine
							print("Voice Mix: SINE (pure tone)")
			
			KEY_H:
				# Cycle harmonicity
				harmonicity_index = (harmonicity_index + 1) % harmonicity_presets.size()
				if synth:
					synth.harmonicity = harmonicity_presets[harmonicity_index]
					print("Harmonicity: %.2f" % synth.harmonicity)
			
			KEY_EQUAL, KEY_PLUS:
				# Increase speed
				movement_speed += 0.5
				movement_speed = clamp(movement_speed, 0.5, 10.0)
				print("Movement speed: %.1f m/s" % movement_speed)
			
			KEY_MINUS:
				# Decrease speed
				movement_speed -= 0.5
				movement_speed = clamp(movement_speed, 0.5, 10.0)
				print("Movement speed: %.1f m/s" % movement_speed)


func _create_ui() -> void:
	# Create a CanvasLayer for UI
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	# Create info label
	info_label = Label.new()
	info_label.position = Vector2(20, 20)
	info_label.add_theme_font_size_override("font_size", 14)
	canvas.add_child(info_label)


func _update_ui() -> void:
	if not info_label or not listener or not synth:
		return
	
	var params = listener.get_modulation_params()
	
	var voice_mix_name = ["SAWTOOTH", "MIXED", "SINE"][voice_mix_index]
	
	var text = ""
	text += "=== TEROPA-STYLE AIR POINT SYNTH ===\n"
	text += "Discreet Music Synthesis (1975)\n"
	text += "\n"
	text += "--- Spatial Parameters ---\n"
	text += "Distance: %.2f m\n" % params.distance
	text += "Proximity: %.2f\n" % params.proximity_factor
	text += "Speed: %.2f m/s\n" % params.speed
	text += "Position: (%.1f, %.1f, %.1f)\n" % [params.position.x, params.position.y, params.position.z]
	text += "\n"
	text += "--- Synthesis Parameters ---\n"
	text += "Frequency: %.1f Hz\n" % synth._current_frequency
	text += "Amplitude: %.2f\n" % synth._current_amplitude
	text += "Filter Cutoff: %.1f Hz\n" % synth._current_filter_cutoff
	text += "Vibrato Rate: %.2f Hz\n" % synth._current_vibrato_rate
	text += "Harmonicity: %.2f\n" % synth._current_harmonicity
	text += "Stereo Pan: %.2f\n" % synth.stereo_pan
	text += "\n"
	text += "--- Synth Settings ---\n"
	text += "Voice Mix: %s\n" % voice_mix_name
	text += "Envelope: A=%.1fs R=%.1fs\n" % [synth.attack_time, synth.release_time]
	text += "Filter: %.0f Hz (%.1f octaves)\n" % [synth.filter_base_frequency, synth.filter_octaves]
	text += "\n"
	text += "--- Controls ---\n"
	text += "Movement Speed: %.1f m/s\n" % movement_speed
	text += "Arrows: Move (X/Z) | Q/E: Move (Y)\n"
	text += "Space: Reset | V: Voice | H: Harmonicity\n"
	text += "+/-: Speed\n"
	
	info_label.text = text
