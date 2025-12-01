# AirPointAudioTest.gd
# Path: res://commons/audio/airpoints/AirPointAudioTest.gd
# Agent: Agent-SynthesisEngineer (Agent B)
# Test scene controller for Air Point audio system (FM Piano Version)
#
# Controls:
# - Arrow Keys: Move Air Point horizontally (X/Z)
# - Q/E: Move Air Point vertically (Y)
# - Space: Reset to starting position
# - +/-: Adjust movement speed

extends Node3D

@onready var air_point: Node3D = $AirPoint
@onready var listener: AirPointListener = $ReferencePoint/AirPointListener
@onready var synth: FMPianoSynth = $FMPianoSynth
@onready var trigger: Node = $AirPointTrigger
@onready var reference_point: Node3D = $ReferencePoint

## Movement speed (meters per second)
var movement_speed: float = 3.0

## Starting position
var start_position: Vector3 = Vector3(3, 0, 0)

## UI label for displaying info
var info_label: Label = null


func _ready() -> void:
	# Set starting position
	if air_point:
		air_point.global_position = start_position
	
	# Create UI overlay
	_create_ui()
	
	print("=== Air Point Audio Test (FM Piano) ===")
	print("Controls:")
	print("  Arrow Keys: Move Air Point (X/Z)")
	print("  Q/E: Move Air Point (Y)")
	print("  Space: Reset position")
	print("  +/-: Adjust speed")
	print("============================")


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
	info_label.add_theme_font_size_override("font_size", 16)
	canvas.add_child(info_label)


func _update_ui() -> void:
	if not info_label or not listener:
		return
	
	var text = ""
	text += "=== AIR POINT AUDIO TEST (FM PIANO) ===\n"
	text += "\n"
	text += "Distance: %.2f m\n" % listener.distance
	text += "Proximity: %.2f\n" % listener.proximity
	text += "Speed: %.2f m/s\n" % listener.speed
	text += "Acceleration: %.2f m/s²\n" % listener.acceleration.length()
	text += "\n"
	text += "Trigger Status: %s\n" % ("Active" if trigger else "N/A")
	text += "\n"
	text += "Movement Speed: %.1f m/s\n" % movement_speed
	text += "\n"
	text += "Controls:\n"
	text += "  Arrows: Move (X/Z)\n"
	text += "  Q/E: Move (Y)\n"
	text += "  Space: Reset\n"
	text += "  +/-: Speed\n"
	
	info_label.text = text
