@tool
extends Node3D

# Living Architecture - Decaying Bridge
# A bridge that decays when stepped on and regrows over time.

@export_category("Bridge Settings")
@export var length: int = 20
@export var width: int = 4
@export var cell_size: float = 1.0
@export var decay_speed: float = 0.1
@export var regrow_speed: float = 2.0
@export var decay_radius: float = 2.0

@export_category("Visuals")
@export var color_healthy: Color = Color(0.2, 0.8, 0.2)
@export var color_decayed: Color = Color(0.2, 0.2, 0.2)
@export var color_dead: Color = Color(0.0, 0.0, 0.0, 0.0)

var grid: Dictionary = {} # Vector2i -> float (health 0.0 to 1.0)
var mesh_instances: Dictionary = {} # Vector2i -> MeshInstance3D
var colliders: Dictionary = {} # Vector2i -> CollisionShape3D
var player_position: Vector3 = Vector3.ZERO
var time_accumulator: float = 0.0

var static_body: StaticBody3D

func _ready():
	# Try to get existing StaticBody3D node, or create one
	if has_node("StaticBody3D"):
		static_body = get_node("StaticBody3D")
	else:
		static_body = StaticBody3D.new()
		static_body.name = "StaticBody3D"
		add_child(static_body)

	_initialize_bridge()

func _process(delta):
	if Engine.is_editor_hint():
		return
		
	# Simulate player detection (replace with actual player tracking)
	# For now, we assume an external script updates `player_position`
	# or we find a node named "Player"
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_position = player.global_position
	
	time_accumulator += delta
	if time_accumulator >= 0.1:
		time_accumulator = 0.0
		_update_simulation(0.1)

func _initialize_bridge():
	# Clear old
	for child in static_body.get_children():
		child.queue_free()
	for k in mesh_instances:
		mesh_instances[k].queue_free()
	grid.clear()
	mesh_instances.clear()
	colliders.clear()
	
	# Build
	var offset_x = (width * cell_size) / 2.0
	
	for z in range(length):
		for x in range(width):
			var coord = Vector2i(x, z)
			grid[coord] = 1.0 # Full health
			
			# Visual
			var mesh_inst = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(cell_size, 0.2, cell_size) * 0.95
			mesh_inst.mesh = box
			add_child(mesh_inst)
			
			var pos = Vector3((x * cell_size) - offset_x, 0, z * cell_size)
			mesh_inst.position = pos
			mesh_instances[coord] = mesh_inst
			
			# Collider
			var col = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			shape.size = Vector3(cell_size, 0.2, cell_size)
			col.shape = shape
			static_body.add_child(col)
			col.position = pos
			colliders[coord] = col
			
	_update_visuals()

func _update_simulation(dt):
	var changed = false
	
	# 1. Decay from player
	# Convert player pos to grid coords
	var offset_x = (width * cell_size) / 2.0
	var local_player_pos = to_local(player_position)
	
	# Simple radius check
	for coord in grid.keys():
		var pos = mesh_instances[coord].position
		var dist = pos.distance_to(local_player_pos)
		
		if dist < decay_radius:
			# Decay!
			grid[coord] = max(0.0, grid[coord] - decay_speed * dt * 5.0)
			changed = true
		else:
			# Regrow (Game of Life-ish or just simple regen?)
			# Let's do simple regen for now, but neighbor-dependent regen is cooler
			# If neighbors are healthy, I heal faster
			var neighbors = _count_healthy_neighbors(coord)
			if neighbors > 0:
				grid[coord] = min(1.0, grid[coord] + regrow_speed * dt * 0.1 * neighbors)
				changed = true
	
	if changed:
		_update_visuals()

func _count_healthy_neighbors(coord: Vector2i) -> int:
	var count = 0
	var dirs = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
	for d in dirs:
		var n = coord + d
		if grid.has(n) and grid[n] > 0.5:
			count += 1
	return count

func _update_visuals():
	for coord in grid.keys():
		var health = grid[coord]
		var mesh = mesh_instances[coord]
		var col = colliders[coord]
		
		# Color
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_dead.lerp(color_healthy, health)
		if health < 0.1:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = health * 10.0
		mesh.material_override = mat
		
		# Collision
		if health < 0.2:
			col.disabled = true
		else:
			col.disabled = false
