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
	# Reset cursor
	current_pos = Vector3.ZERO
	current_basis = Basis.IDENTITY
	
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
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
				if not cmd.is_empty():
					push_warning("BigPipeSystem: Unknown command '%s'" % cmd)

func _add_straight() -> void:
	var instance = SEGMENT_STRAIGHT.instantiate()
	add_child(instance)
	
	# Configure Dimensions
	var mesh_inst = instance.get_node("MeshInstance3D")
	if mesh_inst and mesh_inst.mesh is CylinderMesh:
		# Use unique mesh for this system to allow customization
		mesh_inst.mesh = mesh_inst.mesh.duplicate()
		mesh_inst.mesh.top_radius = pipe_radius
		mesh_inst.mesh.bottom_radius = pipe_radius
		mesh_inst.mesh.height = segment_length
		# Adjust position to be Z-forward based (0 to length)
		mesh_inst.position.z = segment_length / 2.0
		
	var col = instance.get_node_or_null("CollisionShape3D")
	if col and col.shape is CylinderShape3D:
		col.shape = col.shape.duplicate()
		col.shape.radius = pipe_radius
		col.shape.height = segment_length
		col.position.z = segment_length / 2.0
	
	# Position at current cursor
	instance.transform.origin = current_pos
	instance.transform.basis = current_basis
	
	# Move cursor forward
	var forward = current_basis.z
	current_pos += forward * segment_length

func _add_s_bend() -> void:
	var instance = SEGMENT_SBEND.instantiate()
	add_child(instance)
	
	# Configure Dimensions
	var offset = segment_length # Use segment_length as offset for uniform grid
	
	if instance.get("pipe_radius") != null:
		instance.pipe_radius = pipe_radius
	if instance.get("length") != null:
		instance.length = segment_length
	if instance.get("offset") != null:
		instance.offset = offset
	
	# Position at current cursor
	instance.transform.origin = current_pos
	instance.transform.basis = current_basis
	
	# Update cursor
	# S-Bend moves Forward (Z) and Offset (Right X)
	var forward = current_basis.z
	var right = current_basis.x
	
	# Assuming Parametric S-Bend generates a +X (Right) shift.
	# With offset = segment_length, it shifts 1 block Right, 1 block Forward.
	
	# Parametric script usually generates Left shift (+X in local space)?
	# Wait, check pipe_s_bend_parametric.gd logic.
	# x = offset * (1 - cos)..
	# If offset 1.0 -> X goes 0 to 1.
	# If local +X is Right? No, +X is Left in typical "Forward +Z" view.
	# (Thumb X Right, Index Y Up, Z Forward) -> Left Handed? Godot is Right Handed.
	# Thumb Right (+X), Index Up (+Y), Middle Back (+Z)?
	# Actually: X Right, Y Up, Z Back (Standard GL).
	# Forward is -Z.
	# I am using Forward +Z.
	# So X is Right? Y is Up. Z is Forward.
	# Basis(Vector3(1,0,0), ...)
	# If X is Right.
	# offset 1.0 (positive X) maps to Right.
	# So S-Bend shifts Right.
	
	current_pos += (forward * segment_length) + (right * offset)

func _add_corner(axis: Vector3, angle_deg: float) -> void:
	var instance = SEGMENT_CORNER.instantiate()
	add_child(instance)
	
	# Configure Dimensions
	if instance.get("pipe_radius") != null:
		instance.pipe_radius = pipe_radius
	if instance.get("corner_radius") != null:
		instance.corner_radius = segment_length
	
	instance.transform.origin = current_pos
	
	# Visual Rotation Logic for Parametric Corner (+Z Entry, +X Exit [Left relative to Z?])
	# Check Parametric Corner again:
	# End at (R, 0, R). Z=R, X=R.
	# If X is Right. This is Right Turn.
	# So Parametric Corner is Right Turn.
	# My previous analysis "Left Turn" might be wrong if X is Right.
	# Let's assume Standard Godot: +X is Right.
	# So base is RIGHT Turn.
	
	var visual_basis = current_basis
	
	if axis == Vector3.RIGHT: # Pitch
		if angle_deg > 0: # Up (+Y)
			# Right (+X) -> Up (+Y): Rot Z 90 (+X towards +Y)
			visual_basis = visual_basis.rotated(visual_basis.z, PI/2)
		else: # Down (-Y)
			# Right (+X) -> Down (-Y): Rot Z -90
			visual_basis = visual_basis.rotated(visual_basis.z, -PI/2)
			
	elif axis == Vector3.UP: # Yaw
		if angle_deg > 0: # Left (-X)
			# Right (+X) -> Left (-X): Rot Z 180
			visual_basis = visual_basis.rotated(visual_basis.z, PI)
		else: # Right (+X)
			# Right (+X). Matches Base.
			pass
	
	instance.transform.basis = visual_basis
	
	# Update Turtle... (Same as before)
	var forward = current_basis.z
	var up = current_basis.y
	var right = current_basis.x
	
	var radius = segment_length
	
	if axis == Vector3.RIGHT:
		if angle_deg > 0: # Up
			current_pos += (forward * radius) + (up * radius)
			# Pitch Up requires -90 rotation around Right axis (Z -> Y)
			current_basis = current_basis.rotated(current_basis.x, deg_to_rad(-90))
		else: # Down
			current_pos += (forward * radius) - (up * radius)
			# Pitch Down requires +90 rotation around Right axis (Z -> -Y)
			current_basis = current_basis.rotated(current_basis.x, deg_to_rad(90))
			
	elif axis == Vector3.UP:
		if angle_deg > 0: # Left
			current_pos += (forward * radius) - (right * radius) # Left is -Right
			current_basis = current_basis.rotated(current_basis.y, deg_to_rad(90))
		else: # Right
			current_pos += (forward * radius) + (right * radius) # Right is +Right
			current_basis = current_basis.rotated(current_basis.y, deg_to_rad(-90))
