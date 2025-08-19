extends Node3D

# Portal-Style Joint Panels
# This script creates interactive floor panels that can open like in Portal

# Panel grid settings
@export var grid_size_x: int = 3
@export var grid_size_z: int = 3
@export var panel_size: float = 1.0
@export var gap_size: float = 0.02

# Animation settings
@export var open_speed: float = 2.0
@export var max_open_angle: float = 85.0

# Materials
@export var panel_material: Material
@export var frame_material: Material
@export var pit_material: Material

# Internal variables
var panels = []
var is_opening = false
var current_angle = 0.0
var panel_root

# Called when the node enters the scene tree for the first time
func _ready():
	create_pit()
	create_frame()
	create_panels()

func _process(delta):
	if is_opening and current_angle < max_open_angle:
		current_angle += open_speed * delta * 50
		current_angle = min(current_angle, max_open_angle)
		update_panel_rotation()
	elif not is_opening and current_angle > 0:
		current_angle -= open_speed * delta * 50
		current_angle = max(current_angle, 0)
		update_panel_rotation()

func update_panel_rotation():
	for i in range(grid_size_x):
		for j in range(grid_size_z):
			var panel = panels[i][j]
			
			# Calculate opening direction based on position in grid
			# Panels open outward from the center
			var center_x = (grid_size_x - 1) / 2.0
			var center_z = (grid_size_z - 1) / 2.0
			
			var dir_x = 1 if i > center_x else -1
			var dir_z = 1 if j > center_z else -1
			
			# If exactly at center, choose a default direction
			if i == center_x:
				dir_x = 0
			if j == center_z:
				dir_z = 0
				
			# Determine which axis to rotate around based on position
			var rotation_axis = Vector3.ZERO
			var hinge_offset = Vector3.ZERO
			
			if abs(i - center_x) > abs(j - center_z):
				# Rotate around Z axis
				rotation_axis = Vector3(0, 0, dir_z)
				hinge_offset = Vector3(0, 0, dir_z * panel_size/2)
			else:
				# Rotate around X axis
				rotation_axis = Vector3(dir_x, 0, 0)
				hinge_offset = Vector3(dir_x * panel_size/2, 0, 0)
			
			# Reset rotation and position
			panel.rotation = Vector3.ZERO
			panel.position = Vector3(
				i * (panel_size + gap_size) - (grid_size_x * (panel_size + gap_size))/2 + panel_size/2,
				0,
				j * (panel_size + gap_size) - (grid_size_z * (panel_size + gap_size))/2 + panel_size/2
			)
			
			# Move to hinge position, rotate, then move back
			panel.translate(-hinge_offset)
			
			if rotation_axis.x != 0:
				panel.rotate_x(deg_to_rad(current_angle * rotation_axis.x))
			elif rotation_axis.z != 0:
				panel.rotate_z(deg_to_rad(current_angle * rotation_axis.z))
			
			panel.translate(hinge_offset)

func create_pit():
	# Create the pit below the panels
	var pit = CSGBox3D.new()
	pit.name = "Pit"
	pit.size = Vector3(
		grid_size_x * (panel_size + gap_size) + panel_size,
		panel_size * 2,
		grid_size_z * (panel_size + gap_size) + panel_size
	)
	pit.position = Vector3(0, -panel_size, 0)
	
	if pit_material:
		pit.material = pit_material
	else:
		var default_mat = StandardMaterial3D.new()
		default_mat.albedo_color = Color(0.1, 0.1, 0.1)
		pit.material = default_mat
	
	add_child(pit)

func create_frame():
	# Create the frame around the panels
	var frame_width = grid_size_x * (panel_size + gap_size) + gap_size
	var frame_depth = grid_size_z * (panel_size + gap_size) + gap_size
	
	var frame = CSGBox3D.new()
	frame.name = "Frame"
	frame.size = Vector3(frame_width, panel_size/10, frame_depth)
	frame.position = Vector3(0, -panel_size/20, 0)
	
	# Create hole in the middle
	var hole = CSGBox3D.new()
	hole.name = "Hole"
	hole.size = Vector3(
		grid_size_x * (panel_size + gap_size) - gap_size,
		panel_size,
		grid_size_z * (panel_size + gap_size) - gap_size
	)
	hole.operation = CSGShape3D.OPERATION_SUBTRACTION
	
	if frame_material:
		frame.material = frame_material
	else:
		var default_mat = StandardMaterial3D.new()
		default_mat.albedo_color = Color(0.3, 0.3, 0.3)
		frame.material = default_mat
	
	frame.add_child(hole)
	add_child(frame)

func create_panels():
	# Create panel root to organize the scene
	panel_root = Node3D.new()
	panel_root.name = "Panels"
	add_child(panel_root)
	
	# Create 2D array for panels
	panels = []
	for i in range(grid_size_x):
		panels.append([])
		for j in range(grid_size_z):
			# Create a panel
			var panel = CSGBox3D.new()
			panel.name = "Panel_" + str(i) + "_" + str(j)
			panel.size = Vector3(panel_size, panel_size/10, panel_size)
			
			# Position the panel
			panel.position = Vector3(
				i * (panel_size + gap_size) - (grid_size_x * (panel_size + gap_size))/2 + panel_size/2,
				0,
				j * (panel_size + gap_size) - (grid_size_z * (panel_size + gap_size))/2 + panel_size/2
			)
			
			# Apply material
			if panel_material:
				panel.material = panel_material
			else:
				var default_mat = StandardMaterial3D.new()
				default_mat.albedo_color = Color(0.8, 0.8, 0.8)
				panel.material = default_mat
			
			panel_root.add_child(panel)
			panels[i].append(panel)

func toggle_panels():
	is_opening = !is_opening

# Set up input handling
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			toggle_panels()

# Usage instructions:
# 1. Create a new 3D scene in Godot 4
# 2. Add a Node3D as the root node
# 3. Attach this script to the root node
# 4. Optionally create materials and assign them in the Inspector
# 5. Run the scene and press Space to toggle the panels
