@tool
extends Node3D

# Big Pipe System
# Generates a sequence of pipe segments based on a turtle-graphics code.
# Usage:
# var pipes = BigPipeSystem.new()
# pipes.generate_pipes("f,f,s,u,f,c,l,f")
# add_child(pipes)

class_name BigPipeSystem

# Segment Scenes
const SEGMENT_STRAIGHT = preload("res://algorithms/wavefunctions/big_pipe_system/segments/pipe_straight.tscn")
const SEGMENT_CORNER = preload("res://algorithms/wavefunctions/big_pipe_system/segments/pipe_corner.tscn")
const SEGMENT_SBEND = preload("res://algorithms/wavefunctions/big_pipe_system/segments/pipe_s_bend.tscn")

@export var pipe_radius: float = 0.8
@export var segment_length: float = 2.0

var current_pos: Vector3 = Vector3.ZERO
var current_basis: Basis = Basis.IDENTITY

func generate_pipes(code: String) -> void:
	# Code format: "bp:f,s,l,d..." or just "f,s,l,d..."
	if code.begins_with("bp:"):
		code = code.substr(3)
	
	var commands = code.split(",")
	
	for cmd in commands:
		cmd = cmd.strip_edges().to_lower()
		match cmd:
			"f": # Forward
				_add_straight()
			"s": # S-Bend (Offset)
				_add_s_bend()
			"u": # Up (Corner Up)
				_add_corner(Vector3.RIGHT, 90) # Pitch Up
			"d", "c": # Down (Corner Down) - "counter"
				_add_corner(Vector3.RIGHT, -90) # Pitch Down
			"l": # Left
				_add_corner(Vector3.UP, 90) # Yaw Left
			"r": # Right
				_add_corner(Vector3.UP, -90) # Yaw Right
			_:
				push_warning("BigPipeSystem: Unknown command '%s'" % cmd)

func _add_straight() -> void:
	var instance = SEGMENT_STRAIGHT.instantiate()
	add_child(instance)
	
	# Position at current cursor
	instance.transform.origin = current_pos
	instance.transform.basis = current_basis
	
	# Move cursor forward
	# Local forward is -Z (standard Godot)
	var forward = -current_basis.z
	current_pos += forward * segment_length

func _add_s_bend() -> void:
	var instance = SEGMENT_SBEND.instantiate()
	add_child(instance)
	
	# Position at current cursor
	instance.transform.origin = current_pos
	instance.transform.basis = current_basis
	
	# Move cursor with offset
	# S-Bend moves Forward 2m and Right 1m (Local X)
	# Wait, my S-Bend visual goes (1, 0, -2).
	# So we move (1 * Right) + (-2 * Forward aka 2 * Backward?? No -Z is Forward).
	# Vector (1, 0, -2) is 1 Right, 2 Forward.
	var forward = -current_basis.z
	var right = current_basis.x
	
	current_pos += (forward * 2.0) + (right * 1.0)

func _add_corner(axis: Vector3, angle_deg: float) -> void:
	var instance = SEGMENT_CORNER.instantiate()
	add_child(instance)
	
	instance.transform.origin = current_pos
	
	# Visual Rotation Logic:
	# The Corner visual starts at (0,0,0) -Z and curves UP (+Y) by default (Quarter loop).
	# If we want Length 2, Radius 2.
	# End point (0, 2, -2).
	# If we transform `axis` relative to current basis...
	# If command is "Up" (Pitch 90 deg). Axis is Local Right.
	# We rotate the visual so its "Curve Plane" matches.
	# Default Corner curves Up (+Y).
	
	# If we want a Turn Left (Yaw 90).
	# We want it to curve Left (-X).
	# Default curves Up (+Y).
	# Rotate Visual on Z axis -90? Y -> -X.
	
	# General Logic:
	# We align the Visual's Entrance to current Basis.
	# And we rotate Visual so its Exit matches desired Turn.
	
	var turn_basis = current_basis
	
	# Apply Visual Rotation
	if axis == Vector3.RIGHT:
		if angle_deg > 0: # Up
			# Default visual is Up. No extra rot.
			pass
		else: # Down
			# Rotate Visual 180 Z? Up -> Down.
			turn_basis = turn_basis.rotated(current_basis.z, PI)
			
	elif axis == Vector3.UP:
		if angle_deg > 0: # Left
			# Default Up (+Y). Want Left (-X).
			# Rotate Z 90? +Y -> -X.
			turn_basis = turn_basis.rotated(current_basis.z, PI/2)
		else: # Right
			# Default Up (+Y). Want Right (+X).
			# Rotate Z -90? +Y -> +X.
			turn_basis = turn_basis.rotated(current_basis.z, -PI/2)
	
	instance.transform.basis = turn_basis
	
	# Update Cursor
	# Move 2m Forward, 2m in Turn Direction.
	# Pivot is at corner start.
	# We essentially rotate the entire turtle Basis around the turn axis by 90 deg,
	# AND move the position.
	# Center of turn is 2m along (TurnAxis x Forward)?
	# No, Center is 2m "Up" from enter velocity?
	# Let's just step the position manually based on type.
	
	var forward = -current_basis.z
	var up = current_basis.y
	var right = current_basis.x
	
	if axis == Vector3.RIGHT:
		if angle_deg > 0: # Up
			current_pos += (forward * 2.0) + (up * 2.0)
			current_basis = current_basis.rotated(current_basis.x, deg_to_rad(90))
		else: # Down
			current_pos += (forward * 2.0) - (up * 2.0)
			current_basis = current_basis.rotated(current_basis.x, deg_to_rad(-90))
			
	elif axis == Vector3.UP:
		if angle_deg > 0: # Left
			current_pos += (forward * 2.0) - (right * 2.0)
			current_basis = current_basis.rotated(current_basis.y, deg_to_rad(90))
		else: # Right
			current_pos += (forward * 2.0) + (right * 2.0)
			current_basis = current_basis.rotated(current_basis.y, deg_to_rad(-90))
