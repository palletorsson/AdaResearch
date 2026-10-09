# maze_generator_vr.gd
# VR-optimized Maze Generation - Human-scale walkable maze
extends Node3D

# Maze Configuration - VR optimized defaults
@export_category("Maze Configuration")
@export var maze_width: int = 15  # Odd number for proper maze generation
@export var maze_height: int = 15
@export var cell_size: float = 2.0  # 2 meter wide corridors
@export var wall_height: float = 2.8  # Above head height for immersion
@export var wall_thickness: float = 0.3  # Thin walls for more space
@export var generation_speed: float = 0.05  # Fast generation

@export_category("Visual Settings")
@export var wall_color: Color = Color(0.25, 0.25, 0.35)
@export var floor_color: Color = Color(0.15, 0.15, 0.2)
@export var current_color: Color = Color(0.9, 0.3, 0.3)
@export var visited_color: Color = Color(0.2, 0.5, 0.3)
@export var entrance_color: Color = Color(0.3, 0.8, 0.3)
@export var exit_color: Color = Color(0.8, 0.3, 0.3)
@export var show_generation: bool = true

@export_category("Lighting")
@export var add_ambient_light: bool = true
@export var light_intensity: float = 0.4

# ─────────────────────────────────────────────────────────────────────────────
# DNA PROMOTION (2026-08-02).
#
# A maze is the one procedural object that everybody calls "random" and nobody
# looks at twice. But a maze is not random — it is the FINGERPRINT of whatever
# carved it. Depth-first backtracking makes long serpentine corridors and very
# few dead ends, because it commits to a direction and only gives up when it is
# cornered. Randomised Prim's grows outward from one seed and leaves a short,
# bushy, dead-end-heavy warren, because every frontier wall is equally likely.
# Binary tree carves north-or-east from every cell and therefore MUST leave one
# complete corridor along the top row and one down the right-hand column, plus a
# diagonal grain no other method has. Sidewinder closes horizontal runs and rises
# once per run, so the top corridor is there but the right column is not, and the
# grain is horizontal. And a labyrinth is not a maze at all: one path, no
# branches, no choices — the shape a maker cuts when the point is the walking and
# not the puzzle.
#
#   hand   whose hand cut these corridors
#
#     backtracker | prim | binary_tree | sidewinder | labyrinth
#
# All five leave exactly the same number of standing wall blocks on a 15x15 grid
# (49 cells, 48 walls removed for a spanning tree; the labyrinth's snake removes
# 48 too). Nothing about the amount of maze changes. What changes is the TEXTURE,
# which is the whole claim: "procedurally generated" is not a description of a
# thing, it is a refusal to name the hand.
#
# WHAT IS DELIBERATELY NOT THE AXIS. generation_speed is the obvious knob and it
# is invisible to a still — a rate cannot be photographed. maze_width/height are
# a dial, not a claim. The colours are colours.
#
# STRICTLY ADDITIVE. `backtracker` never enters any code added below: _ready's
# branch tests `hand != "backtracker"` first and falls through to the original
# start_generation()/_generate_instant() pair untouched, and the default rolls
# randi() at exactly the same call sites in exactly the same order as before.
# ─────────────────────────────────────────────────────────────────────────────
@export_category("DNA")

## THE AXIS — which maze-maker's hand cut these corridors. `backtracker` is the
## legacy lineage and the only value that runs the original carving code.
@export_enum("backtracker", "prim", "binary_tree", "sidewinder", "labyrinth") var hand: String = "backtracker"

## The allow-list a map token is checked against — the same five words the
## @export_enum above declares, in the same spelling and order. An unreadable
## word keeps the default rather than leaving a room walled solid.
const HANDS: PackedStringArray = ["backtracker", "prim", "binary_tree", "sidewinder", "labyrinth"]

## Determinism. Every hand here draws from the global RNG, which Godot randomises
## at startup — so before this existed, two boots of the same map produced two
## different mazes and any before/after comparison was measuring the dice.
## -1 keeps that behaviour EXACTLY (no seed call is made at all, so the stream is
## byte-for-byte what it was); any value >= 0 pins the whole carve. The capture
## harness sets this through the registry's dna.fixture so one axis is varied at
## a time and the maze underneath holds still.
@export var maze_seed: int = -1

# Maze data
var maze: Array = []
var visited: Array = []
var generation_stack: Array = []
var current_cell: Vector2i
var generating: bool = false
var generation_timer: float = 0.0
var generation_complete: bool = false

# Visual elements
var cell_meshes: Array = []
var wall_colliders: Array = []
var floor_mesh: MeshInstance3D
var ceiling_mesh: MeshInstance3D

# Directions for maze generation (step by 2 for wall carving)
var directions = [
	Vector2i(0, -2),  # North
	Vector2i(2, 0),   # East
	Vector2i(0, 2),   # South
	Vector2i(-2, 0)   # West
]

# Materials (reused for performance)
var wall_material: StandardMaterial3D
var floor_material: StandardMaterial3D
var path_material: StandardMaterial3D

func _ready() -> void:
	# DNA first: a map token or a sweep fixture must be in hand before anything
	# draws or builds. Both reads are no-ops when nothing was passed.
	_read_dna_meta()
	if maze_seed >= 0:
		seed(maze_seed)

	_create_materials()
	_initialize_maze()
	_create_floor_and_ceiling()
	_create_maze_visuals()

	if add_ambient_light:
		_setup_lighting()

	if hand != "backtracker":
		# A non-default hand carves the whole maze at once: the still that this
		# artifact is measured in cannot hold a process, only what the process
		# left, and the alternative hands are claims about the finished corridor
		# texture. The legacy pair below is not touched.
		_carve_by_hand()
	elif show_generation:
		start_generation()
	else:
		_generate_instant()

func _process(delta: float) -> void:
	if generating:
		generation_timer += delta
		if generation_timer >= generation_speed:
			_generation_step()
			generation_timer = 0.0

func _create_materials() -> void:
	# Wall material
	wall_material = StandardMaterial3D.new()
	wall_material.albedo_color = wall_color
	wall_material.roughness = 0.9

	# Floor material
	floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = floor_color
	floor_material.roughness = 0.95

	# Path material (for generation visualization)
	path_material = StandardMaterial3D.new()
	path_material.albedo_color = visited_color
	path_material.roughness = 0.9

func _initialize_maze() -> void:
	maze.clear()
	visited.clear()

	for y in range(maze_height):
		var row = []
		var visited_row = []
		for x in range(maze_width):
			row.append(true)  # Start with all walls
			visited_row.append(false)
		maze.append(row)
		visited.append(visited_row)

	# Create path cells at odd coordinates
	for y in range(1, maze_height, 2):
		for x in range(1, maze_width, 2):
			maze[y][x] = false

func _create_floor_and_ceiling() -> void:
	var total_width = maze_width * cell_size
	var total_depth = maze_height * cell_size

	# Create floor
	floor_mesh = MeshInstance3D.new()
	floor_mesh.name = "Floor"
	var floor_box = BoxMesh.new()
	floor_box.size = Vector3(total_width, 0.2, total_depth)
	floor_mesh.mesh = floor_box
	floor_mesh.position = Vector3(total_width / 2 - cell_size / 2, -0.1, total_depth / 2 - cell_size / 2)
	floor_mesh.material_override = floor_material
	add_child(floor_mesh)

	# Floor collision
	var floor_body = StaticBody3D.new()
	floor_body.name = "FloorCollision"
	var floor_shape = CollisionShape3D.new()
	var floor_box_shape = BoxShape3D.new()
	floor_box_shape.size = Vector3(total_width + 4, 0.2, total_depth + 4)
	floor_shape.shape = floor_box_shape
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(total_width / 2 - cell_size / 2, -0.1, total_depth / 2 - cell_size / 2)
	add_child(floor_body)

func _setup_lighting() -> void:
	# Add subtle ambient lighting throughout the maze
	var light = DirectionalLight3D.new()
	light.name = "MazeLight"
	light.light_color = Color(0.9, 0.9, 1.0)
	light.light_energy = light_intensity
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.shadow_enabled = false  # Better VR performance
	add_child(light)

func _create_maze_visuals() -> void:
	# Clear existing
	for child in get_children():
		if child.name.begins_with("Wall_"):
			child.queue_free()

	cell_meshes.clear()
	wall_colliders.clear()

	for y in range(maze_height):
		var row = []
		var collider_row = []
		for x in range(maze_width):
			if maze[y][x]:  # Wall
				var wall = _create_wall(x, y)
				row.append(wall)
				add_child(wall)

				var collider = _create_wall_collider(x, y)
				collider_row.append(collider)
				add_child(collider)
			else:
				row.append(null)
				collider_row.append(null)
		cell_meshes.append(row)
		wall_colliders.append(collider_row)

func _create_wall(x: int, y: int) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Wall_" + str(x) + "_" + str(y)

	var box = BoxMesh.new()
	box.size = Vector3(cell_size - wall_thickness, wall_height, cell_size - wall_thickness)
	mesh_instance.mesh = box
	mesh_instance.position = Vector3(x * cell_size, wall_height / 2, y * cell_size)
	mesh_instance.material_override = wall_material

	return mesh_instance

func _create_wall_collider(x: int, y: int) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = "WallCollider_" + str(x) + "_" + str(y)

	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(cell_size, wall_height, cell_size)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(x * cell_size, wall_height / 2, y * cell_size)

	return body

func start_generation() -> void:
	current_cell = Vector2i(1, 1)
	visited[1][1] = true
	generation_stack.clear()
	generating = true
	generation_complete = false

	_highlight_cell(current_cell, current_color)

func _generation_step() -> void:
	var neighbors = _get_unvisited_neighbors(current_cell)

	if neighbors.size() > 0:
		var next_cell = neighbors[randi() % neighbors.size()]
		visited[next_cell.y][next_cell.x] = true

		# Remove wall between cells
		var wall_x = current_cell.x + (next_cell.x - current_cell.x) / 2
		var wall_y = current_cell.y + (next_cell.y - current_cell.y) / 2
		_remove_wall(wall_x, wall_y)

		_highlight_cell(current_cell, visited_color)
		generation_stack.push_back(current_cell)
		current_cell = next_cell
		_highlight_cell(current_cell, current_color)

	elif generation_stack.size() > 0:
		_highlight_cell(current_cell, visited_color)
		current_cell = generation_stack.pop_back()
		_highlight_cell(current_cell, current_color)

	else:
		generating = false
		generation_complete = true
		_highlight_cell(current_cell, visited_color)
		_create_entrance_exit()
		_finalize_visuals()

func _get_unvisited_neighbors(cell: Vector2i) -> Array:
	var neighbors = []
	for direction in directions:
		var next = cell + direction
		if next.x >= 1 and next.x < maze_width - 1 and next.y >= 1 and next.y < maze_height - 1:
			if not visited[next.y][next.x]:
				neighbors.append(next)
	return neighbors

func _remove_wall(x: int, y: int) -> void:
	maze[y][x] = false

	# Remove visual
	if cell_meshes[y][x]:
		cell_meshes[y][x].queue_free()
		cell_meshes[y][x] = null

	# Remove collider
	if wall_colliders[y][x]:
		wall_colliders[y][x].queue_free()
		wall_colliders[y][x] = null

func _highlight_cell(_cell: Vector2i, color: Color) -> void:
	# During generation, we highlight path cells by creating temporary markers
	pass  # Skip for VR performance

func _create_entrance_exit() -> void:
	# Entrance at top
	maze[0][1] = false
	_remove_wall(1, 0)
	_add_marker(1, 0, entrance_color, "Entrance")

	# Exit at bottom
	maze[maze_height - 1][maze_width - 2] = false
	_remove_wall(maze_width - 2, maze_height - 1)
	_add_marker(maze_width - 2, maze_height - 1, exit_color, "Exit")

func _add_marker(x: int, y: int, color: Color, marker_name: String) -> void:
	# Add a glowing marker at entrance/exit
	var marker = MeshInstance3D.new()
	marker.name = marker_name + "Marker"

	var cylinder = CylinderMesh.new()
	cylinder.top_radius = cell_size * 0.3
	cylinder.bottom_radius = cell_size * 0.3
	cylinder.height = 0.1
	marker.mesh = cylinder

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	marker.material_override = mat

	marker.position = Vector3(x * cell_size, 0.05, y * cell_size)
	add_child(marker)

func _finalize_visuals() -> void:
	# Remove all remaining wall highlights, use final colors
	for y in range(maze_height):
		for x in range(maze_width):
			if cell_meshes[y][x]:
				cell_meshes[y][x].material_override = wall_material

func _generate_instant() -> void:
	# Generate maze without animation
	current_cell = Vector2i(1, 1)
	visited[1][1] = true
	generation_stack.clear()

	while true:
		var neighbors = _get_unvisited_neighbors(current_cell)

		if neighbors.size() > 0:
			var next_cell = neighbors[randi() % neighbors.size()]
			visited[next_cell.y][next_cell.x] = true

			var wall_x = current_cell.x + (next_cell.x - current_cell.x) / 2
			var wall_y = current_cell.y + (next_cell.y - current_cell.y) / 2
			_remove_wall(wall_x, wall_y)

			generation_stack.push_back(current_cell)
			current_cell = next_cell

		elif generation_stack.size() > 0:
			current_cell = generation_stack.pop_back()
		else:
			break

	generation_complete = true
	_create_entrance_exit()
	_finalize_visuals()

func regenerate() -> void:
	# Clear and regenerate
	for child in get_children():
		if child.name.begins_with("Wall_") or child.name.begins_with("WallCollider_"):
			child.queue_free()
		if child.name.ends_with("Marker"):
			child.queue_free()

	await get_tree().process_frame

	_initialize_maze()
	_create_maze_visuals()

	if show_generation:
		start_generation()
	else:
		_generate_instant()

func get_entrance_position() -> Vector3:
	return Vector3(1 * cell_size, 0, -cell_size)

func get_exit_position() -> Vector3:
	return Vector3((maze_width - 2) * cell_size, 0, maze_height * cell_size)

func get_maze_center() -> Vector3:
	return Vector3(
		(maze_width * cell_size) / 2 - cell_size / 2,
		wall_height / 2,
		(maze_height * cell_size) / 2 - cell_size / 2
	)

func get_total_size() -> Vector3:
	return Vector3(maze_width * cell_size, wall_height, maze_height * cell_size)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				regenerate()
			KEY_G:
				if not generating:
					show_generation = true
					regenerate()
			KEY_I:
				if not generating:
					show_generation = false
					regenerate()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass


# ── DNA: THE FIVE HANDS ──────────────────────────────────────────────────────
# Everything below this line is reached only when `hand` is not "backtracker".
# Each carver writes into the SAME maze array and calls the SAME _remove_wall the
# legacy generator uses, so the walls, colliders, entrance, exit and finalisation
# are all shared — only the choice of which 48 walls to take differs.

## Read a map token / grid config value if the placer left one. Unknown words keep
## the default: a typo must not seal a room the map expects to be walkable.
func _read_dna_meta() -> void:
	if has_meta("config_hand"):
		var raw: String = str(get_meta("config_hand")).strip_edges().to_lower()
		if HANDS.has(raw):
			hand = raw
		else:
			push_warning("maze_generator_vr: unknown hand '%s' — keeping '%s'" % [raw, hand])
	if has_meta("config_maze_seed"):
		maze_seed = int(str(get_meta("config_maze_seed")))


func _carve_by_hand() -> void:
	match hand:
		"prim":
			_carve_prim()
		"binary_tree":
			_carve_binary_tree()
		"sidewinder":
			_carve_sidewinder()
		"labyrinth":
			_carve_labyrinth()
		_:
			# Set to something unreadable by code rather than by a map token.
			# Fall back to the legacy carve, which finishes the room itself.
			_generate_instant()
			return

	generation_complete = true
	_create_entrance_exit()
	_finalize_visuals()


## Every cell of the lattice, in row-major order. Cells live at ODD coordinates
## between 1 and maze_width - 2 — the same lattice _get_unvisited_neighbors walks.
func _cells() -> Array:
	var out: Array = []
	var y: int = 1
	while y < maze_height - 1:
		var x: int = 1
		while x < maze_width - 1:
			out.append(Vector2i(x, y))
			x += 2
		y += 2
	return out


## Open the single wall standing between two cells two steps apart.
func _carve_between(a: Vector2i, b: Vector2i) -> void:
	_remove_wall(a.x + (b.x - a.x) / 2, a.y + (b.y - a.y) / 2)


func _in_lattice(c: Vector2i) -> bool:
	return c.x >= 1 and c.x < maze_width - 1 and c.y >= 1 and c.y < maze_height - 1


## PRIM — grow outward from one seed, and at every step open the frontier wall
## the dice picked out of ALL of them. No commitment, no momentum: the maze comes
## out short-limbed and bushy, thick with dead ends.
func _carve_prim() -> void:
	var reached: Dictionary = {}
	var frontier: Array = []
	var start: Vector2i = Vector2i(1, 1)
	reached[start] = true
	_push_frontier(start, reached, frontier)

	while frontier.size() > 0:
		var i: int = randi() % frontier.size()
		var edge: Array = frontier[i]
		frontier.remove_at(i)
		var to: Vector2i = edge[1]
		if reached.has(to):
			continue
		reached[to] = true
		_carve_between(edge[0], to)
		_push_frontier(to, reached, frontier)


func _push_frontier(c: Vector2i, reached: Dictionary, frontier: Array) -> void:
	for d in directions:
		var step: Vector2i = d
		var n: Vector2i = c + step
		if _in_lattice(n) and not reached.has(n):
			frontier.append([c, n])


## BINARY TREE — the most brutally simple maze there is: at every cell, toss for
## north or east and open that one wall. It cannot help itself. The cells on the
## top row have no north, so they ALL go east and leave one unbroken corridor
## across the top; the cells on the right column have no east, so they all go
## north and leave one down the right-hand side. Everything else falls on a
## diagonal grain. A maze that admits which way its maker was facing.
func _carve_binary_tree() -> void:
	for c in _cells():
		var cell: Vector2i = c
		var options: Array = []
		if cell.y - 2 >= 1:
			options.append(Vector2i(cell.x, cell.y - 2))
		if cell.x + 2 < maze_width - 1:
			options.append(Vector2i(cell.x + 2, cell.y))
		if options.is_empty():
			continue
		var pick: Vector2i = options[randi() % options.size()]
		_carve_between(cell, pick)


## SIDEWINDER — run east while the coin says so, then close the run and rise ONCE
## from a cell chosen anywhere along it. Long horizontal reaches with a single
## riser each: the grain lies down flat. Like binary tree it leaves the top row
## open end to end (nothing up there can rise), and unlike binary tree it leaves
## the right column closed.
func _carve_sidewinder() -> void:
	var y: int = 1
	while y < maze_height - 1:
		var run: Array = []
		var x: int = 1
		while x < maze_width - 1:
			var cell: Vector2i = Vector2i(x, y)
			run.append(cell)
			var at_east_edge: bool = x + 2 >= maze_width - 1
			var at_top: bool = y - 2 < 1
			if at_top:
				if not at_east_edge:
					_carve_between(cell, Vector2i(x + 2, y))
			elif at_east_edge or (randi() % 2) == 0:
				var pick: Vector2i = run[randi() % run.size()]
				_carve_between(pick, Vector2i(pick.x, pick.y - 2))
				run.clear()
			else:
				_carve_between(cell, Vector2i(x + 2, y))
			x += 2
		y += 2


## LABYRINTH — the unicursal one, and the value that argues with the other four.
## A single switchback path snakes every row end to end and drops to the next: no
## junctions, no dead ends, nothing to solve. It takes 48 walls like the others
## and rolls no dice at all. The classical labyrinth was never a puzzle — it is a
## route you are meant to walk to the end of, and it looks nothing like the thing
## the word "maze" now means.
func _carve_labyrinth() -> void:
	var path: Array = []
	var y: int = 1
	var flip: bool = false
	while y < maze_height - 1:
		var row: Array = []
		var x: int = 1
		while x < maze_width - 1:
			row.append(Vector2i(x, y))
			x += 2
		if flip:
			row.reverse()
		path.append_array(row)
		flip = not flip
		y += 2

	for i in range(path.size() - 1):
		var a: Vector2i = path[i]
		var b: Vector2i = path[i + 1]
		_carve_between(a, b)
