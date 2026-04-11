@tool
extends Node3D

# @identity
# essence: next_cell = wolfram_rule(left, center, right) extruded as walkable bridge
# desire: To be crossed — a 1D automaton made physical, each row of cubes a generation you walk through
# critical_parameter: rule (0-255) — each Wolfram rule number produces a completely different bridge topology
# triggers: Rule 30 → chaotic, broken path; Rule 110 → structured walkway; random initial row → organic variation
# emerges: Walkable architecture from an 8-bit number — bridges, walls, gaps appear from three-neighbor logic
# needs: VR rule selector [missing], speed control [missing], collision [has]
# relationships: Feeds into CA_GameOfLife. Contrasts with ca_columns (1D→bridge vs 2D→towers). Precedes ca_rule_explorer.
# truth: A bridge built by a rule — you walk on computation.

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

@export_category("Bridge Settings")
@export var width: int = 21 # Width of the bridge (X axis)
@export var length: int = 100 # Length of the bridge (Z axis / Time)
@export var cell_size: float = 0.5 # Half size as requested (standard is 1.0)
@export var generation_speed: float = 0.1
@export var auto_generate: bool = true

@export_category("Rule Settings")
@export var rule: int = 30 # Wolfram 1D Rule (0-255)
@export var random_initial_row: bool = false
@export var initial_density: float = 0.5

var current_z: int = 0
var current_row: Array = []
var timer: float = 0.0
var is_generating: bool = false
var generated_cubes: Array = []

# Collision
var static_body: StaticBody3D
var box_shape: BoxShape3D

func _ready() -> void:
	_setup_collision()
	if auto_generate:
		start_generation()

func _process(delta: float) -> void:
	if is_generating:
		timer += delta
		if timer >= generation_speed:
			timer = 0.0
			step()

func _setup_collision() -> void:
	# Create a single StaticBody for the bridge to hold all shapes
	if not static_body:
		static_body = StaticBody3D.new()
		static_body.name = "BridgeCollision"
		add_child(static_body)
	
	# Shared shape resource
	if not box_shape:
		box_shape = BoxShape3D.new()
		# Match the visual scale (0.5)
		box_shape.size = Vector3(cell_size, cell_size, cell_size)

func start_generation() -> void:
	_clear_bridge()
	_initialize_row()
	current_z = 0
	is_generating = true

func stop_generation() -> void:
	is_generating = false

func _clear_bridge() -> void:
	for cube in generated_cubes:
		if is_instance_valid(cube):
			cube.queue_free()
	generated_cubes.clear()
	
	# Clear collision shapes
	if static_body:
		for child in static_body.get_children():
			child.queue_free()
			
	current_z = 0
	is_generating = false

func _initialize_row() -> void:
	current_row = []
	current_row.resize(width)
	
	if random_initial_row:
		for i in range(width):
			current_row[i] = 1 if randf() < initial_density else 0
	else:
		# Single point in center
		for i in range(width):
			current_row[i] = 0
		current_row[width / 2] = 1

func step() -> void:
	if current_z >= length:
		is_generating = false
		return

	_spawn_row(current_row, current_z)
	current_row = _calculate_next_row(current_row)
	current_z += 1

func _spawn_row(row: Array, z_index: int) -> void:
	var offset_x = (width * cell_size) / 2.0
	
	for i in range(width):
		if row[i] == 1:
			# Visual
			var cube = CUBE_SCENE.instantiate()
			add_child(cube)
			generated_cubes.append(cube)
			
			# Position
			var x_pos = (i * cell_size) - offset_x
			var z_pos = z_index * cell_size
			var pos = Vector3(x_pos, 0, z_pos)
			
			cube.position = pos
			# Scale (Half size) - Visual only
			cube.scale = Vector3(0.5, 0.5, 0.5)
			
			# Collision
			if static_body:
				var col_shape = CollisionShape3D.new()
				col_shape.shape = box_shape
				static_body.add_child(col_shape)
				col_shape.position = pos

func _calculate_next_row(row: Array) -> Array:
	var next_row = []
	next_row.resize(width)
	
	for i in range(width):
		var left = row[(i - 1 + width) % width]
		var center = row[i]
		var right = row[(i + 1) % width]
		next_row[i] = _apply_rule(left, center, right)
		
	return next_row

func _apply_rule(a, b, c) -> int:
	var index = (a << 2) | (b << 1) | c
	if (rule >> index) & 1:
		return 1
	else:
		return 0

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
