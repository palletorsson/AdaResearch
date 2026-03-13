extends Node3D

@export_group("Grid Settings")
@export var grid_size: Vector2i = Vector2i(10, 30)
@export var spacing: float = 1.0
@export var cube_scene: PackedScene = preload("res://commons/primitives/cubes/cube_scene.tscn")

@export_group("Gradient Settings")
@export_enum("X-Axis", "Z-Axis") var gradient_axis: int = 1 # Default Z
@export var max_slope_angle: float = 45.0
@export var gradient_start_offset: float = 5.0
@export var gradient_length: float = 20.0
@export var reverse_gradient: bool = false

@export_group("Animation")
@export var animate_slope: bool = true
@export var animation_speed: float = 0.5
@export var min_animation_angle: float = 0.0

var _cubes: Array[Node3D] = []
var _time: float = 0.0
var _container: Node3D

func _ready() -> void:
	_container = Node3D.new()
	add_child(_container)
	_generate_grid()

func _generate_grid() -> void:
	# Clear existing
	for child in _container.get_children():
		child.queue_free()
	_cubes.clear()
	
	if not cube_scene:
		push_error("SlopeGradientCubes: No cube scene assigned!")
		return
		
	for x in range(grid_size.x):
		for z in range(grid_size.y):
			var cube = cube_scene.instantiate()
			_container.add_child(cube)
			
			# Center the grid slightly
			var pos_x = (x * spacing) - (grid_size.x * spacing * 0.5)
			var pos_z = (z * spacing) # Start at 0 and go forward
			
			cube.position = Vector3(pos_x, 0, pos_z)
			_cubes.append(cube)

func _process(delta: float) -> void:
	var current_max = max_slope_angle
	
	if animate_slope:
		_time += delta * animation_speed
		# Ping pong between min and max angle
		var t = (sin(_time) + 1.0) / 2.0 # 0 to 1
		current_max = lerp(min_animation_angle, max_slope_angle, t)
	
	_update_cubes(current_max)

func _update_cubes(max_angle: float) -> void:
	for cube in _cubes:
		var pos_val = cube.position.z if gradient_axis == 1 else cube.position.x
		
		# Calculate where we are in the gradient (0.0 to 1.0)
		var t = (pos_val - gradient_start_offset) / gradient_length
		t = clamp(t, 0.0, 1.0)
		
		if reverse_gradient:
			t = 1.0 - t
			
		# User requested "start not rotated and end not rotated" -> Sine wave curve (0 -> 1 -> 0)
		var curve_factor = sin(t * PI)
		var angle_degrees = curve_factor * max_angle
		var angle_rad = deg_to_rad(angle_degrees)
		
		# Apply rotation based on axis
		# If gradient is along Z (walking forward), we likely want to pitch up (X rotation)
		# If gradient is along X (walking side), we likely want to roll (Z rotation) or pitch (X)
		
		# User request: "just in x (0° → Max → 0°)"
		cube.rotation = Vector3.ZERO
		cube.rotation.x = -angle_rad

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

