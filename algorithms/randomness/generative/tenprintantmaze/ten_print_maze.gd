extends Node3D

# 3D Standing 10 PRINT Maze with Ant Pathfinder
# Based on the classic one-liner: 10 PRINT CHR$(205.5+RND(1)); : GOTO 10
#
# @identity
# essence: cell = RND(1) < 0.5 ? CHR$(205) : CHR$(206) — one random bit per cell of a
#   grid, drawn as one of two diagonals, and nothing else. Four bytes of entropy per cell,
#   repeated until the screen fills.
# desire: to see that a structure nobody designed can fall out of a coin flip repeated in
#   a grid — and to notice how quickly we start calling it a maze
# critical_parameter: impression — what the one random bit is drawn AS (stroke | character
#   | wall | tile), which is the whole question of whether 10 PRINT is a text program, an
#   architecture, or a textile; maze_seed pins which bits were drawn
# triggers: a timer rotates one random wall every wall_change_interval seconds, so the
#   pattern keeps re-rolling under the ant's feet; the ant re-plans every frame
# emerges: the diagonals meet at cell corners whether or not anyone intended it, and the
#   continuous contours that result are the only reason this reads as a maze at all
# needs: nothing — it is a one-liner; the ant, the path trace and the markers are all
#   later additions and the artifact is still itself without them
# relationships: the 1-bit sibling of [[perlin_noise_terrain]] and [[noisetorus]], which
#   sample a CONTINUOUS field; contrasts with [[coin_toss]], which draws the same bit once
#   and shows you the coin
# truth: the maze was never in the program. It is in the eye that refuses to see a grid of
#   unrelated marks.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-02).
#
# 10 PRINT CHR$(205.5+RND(1)); : GOTO 10 is the most famous four bytes of
# generative art, and its whole claim lives in ONE decision: what a single
# random bit is PRINTED AS. On a C64 it was a character — a glyph fetched from
# the character ROM and stamped into a cell of a 40×25 text screen. Everything
# people have since read into it (a maze, a labyrinth, a textile, a lattice) is
# a reading laid over a grid of unrelated marks.
#
# This 3D version had made that reading for you and then hidden the choice: it
# draws each stroke as a bare unlit LINE, with an ant pathfinder walking it and
# an orange trace behind the ant. Twelve exports, and not one of them could ask
# the artifact's own question.
#
#   impression   WHAT THE ONE RANDOM BIT LEAVES BEHIND
#
#     stroke     the bare diagonal, unshaded and emissive, hanging in space with
#                nothing around it. The glyph without its cell — a drawing.
#                THE LEGACY LINEAGE, byte for byte.
#     character  the same diagonal, given body, sitting inside a visible cell
#                frame. This is the C64: a CHARACTER stamped into one seat of a
#                text grid, and the grid is the reason the strokes line up at
#                all. The most legible the one-liner ever gets in 3D.
#     wall       the stroke extruded out of the plane into a slab you could not
#                walk through. The maze reading, made literal — and the point at
#                which the PRINT statement has completely disappeared into
#                architecture. (wall_thickness, an export that has done nothing
#                since this file was written, finally means something here.)
#     tile       the cell filled edge to edge and split along the diagonal into
#                two tones. No strokes, no walls, no gaps: a two-colour tiling.
#                The textile reading — pattern before it is ever a place.
#
# WHAT IS DELIBERATELY NOT THE AXIS. The obvious knob is the apparatus stacked
# on top of the one-liner — the ant, its path trace, the entrance/exit markers —
# and a ladder from "just the pattern" up to "a solved maze" is a tempting story.
# It fails R3: the ant is a 0.6 m sphere on a 10 × 10 m field, about 0.4% of the
# frame, and the two marker disks are smaller. An axis whose whole difference is
# under half a percent of the picture is decoration wearing a thesis. The four
# impressions repaint every one of the hundred cells instead.
#
# wall_change_interval is likewise NOT the axis: it is a rate, invisible to a
# still, and the thing it varies (how fast the pattern churns) is not what the
# one-liner argues.
#
# NOT TOUCHED: the bit itself. Every impression draws exactly the same maze
# array — the same randi() % 2 per cell, in the same order, from the same seed.
# This axis changes what the bit is WRITTEN AS, never which bits were drawn.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — what the one random bit leaves behind. `stroke` is the legacy default.
@export_enum("stroke", "character", "wall", "tile") var impression: String = "stroke"

## The allow-list, same spelling and same order as the @export_enum above. This is
## what _read_meta_overrides checks a map token against; an unreadable word keeps
## the legacy default rather than blanking a maze five rooms expect to see.
const IMPRESSIONS: PackedStringArray = ["stroke", "character", "wall", "tile"]

## SEED. This artifact is one random bit per cell and it took that bit from the
## global stream after a bare randomize(), so every boot drew a different maze and
## no two captures of it were ever of the same object. -1 keeps that behaviour
## EXACTLY (randomize(), as before); any value >= 0 pins the whole picture — the
## hundred cell bits, the entrance row, the exit row, the ant's tie-breaks and the
## wall the churn timer picks — because all of them draw from the one global stream
## this seeds. A sweep of `impression` MUST pin it, or four impressions of four
## different mazes get reported as a strong bite that is entirely noise.
@export var maze_seed: int = -1

## Untyped on purpose: sweep fixtures set this DIRECTLY pre-_ready with the string
## "false", and a typed bool silently rejects that assignment (the same trap
## catalyst_prompter_box.always_open documents).
##
## true (the default, and what every existing placement gets) = today exactly: the
## churn timer rotates a random wall every wall_change_interval seconds and the ant
## walks. false = the maze is drawn once and stands still, which is the only state
## in which a still frame of this artifact means anything: at the shipped interval
## of 0.08 s the walls re-roll about fourteen times inside the sweep's 1.1 s settle,
## so two captures of the SAME impression are two different pictures.
var animate = true

# Maze settings
@export var cell_size: float = 1.0
@export var wall_height: float = 2.0
@export var grid_width: int = 10
@export var grid_depth: int = 10
@export var wall_thickness: float = 0.1
@export var show_marker_disks: bool = false

# Ant settings
@export var ant_speed: float = 5.0
@export var ant_size: float = 0.3
@export var ant_color: Color = Color.RED
@export var path_color: Color = Color(1.0, 0.5, 0.0)
@export var wall_color: Color = Color(0.9, 0.95, 1.0, 1.0)
@export_range(0.02, 2.0, 0.01) var wall_change_interval: float = 0.2

# Maze representation
var maze: Array = []
var start_pos: Vector2i
var exit_pos: Vector2i

# Navigation grid
var nav_grid: Array = []
var nav_grid_scale: int = 2

# Ant properties
var ant_node: Node3D
var ant_nav_pos: Vector2i
var ant_path: Array = []
var ant_moving: bool = false
var found_exit: bool = false
var path_node: Node3D

# Path visualization
var path_mesh_instance: MeshInstance3D

# Pathfinding
var visited: Dictionary = {}

# Wall movement
var wall_timer: Timer
var wall_nodes: Array[Node3D] = []

## True once _ready has built once. apply_grid_config arriving before that is a value
## change with no geometry to answer it — _ready will use the new value.
var _built: bool = false

func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child and calls
	# apply_grid_config call_deferred, i.e. after this — so the meta read has to
	# happen here, before the seed is set and before a single bit is drawn.
	_read_meta_overrides()
	# maze_seed < 0 is the shipped behaviour, bare randomize(), one call in the same
	# place as before. No draw is inserted ahead of generate_maze(), so the legacy
	# stream is untouched.
	if maze_seed < 0:
		randomize()
	else:
		seed(maze_seed)
	generate_maze()
	build_navigation_grid()
	create_3d_maze()
	if _is_truthy(animate):
		setup_wall_movement_timer()
	# for later
	create_ant()
	create_path_visualization()
	place_ant()
	_built = true

func _process(delta: float) -> void:
	if ant_moving and not found_exit:
		move_ant(delta)
		update_path_visualization()

func generate_maze() -> void:
	# Initialize maze grid
	maze.clear()
	for z in range(grid_depth):
		var row = []
		for x in range(grid_width):
			# 50/50 chance of \ or /
			row.append(randi() % 2)
		maze.append(row)
	
	# Set entrance and exit
	start_pos = Vector2i(0, randi() % grid_depth)
	exit_pos = Vector2i(grid_width - 1, randi() % grid_depth)

func build_navigation_grid() -> void:
	# Create a finer grid for navigation where lines are walls
	nav_grid.clear()
	
	# Initialize with empty spaces
	for z in range(grid_depth * nav_grid_scale):
		var row = []
		for x in range(grid_width * nav_grid_scale):
			row.append(0)  # 0 = empty space
		nav_grid.append(row)
	
	# Add walls based on diagonal lines
	for z in range(grid_depth):
		for x in range(grid_width):
			var cell_type = maze[z][x]
			
			if cell_type == 0:  # / diagonal
				# Add wall for / line
				for i in range(nav_grid_scale):
					var nx = x * nav_grid_scale + i
					var nz = z * nav_grid_scale + (nav_grid_scale - 1 - i)
					if nx < grid_width * nav_grid_scale and nz < grid_depth * nav_grid_scale:
						nav_grid[nz][nx] = 1  # 1 = wall
			else:  # \ diagonal
				# Add wall for \ line
				for i in range(nav_grid_scale):
					var nx = x * nav_grid_scale + i
					var nz = z * nav_grid_scale + i
					if nx < grid_width * nav_grid_scale and nz < grid_depth * nav_grid_scale:
						nav_grid[nz][nx] = 1  # 1 = wall

func create_3d_maze() -> void:
	# Clear existing wall nodes
	wall_nodes.clear()

	# Create maze walls (in ZY plane)
	for z in range(grid_depth):
		for x in range(grid_width):
			var wall_position = Vector3(0, z * cell_size, x * cell_size)

			if maze[z][x] == 0:  # / diagonal
				create_diagonal_wall(wall_position, true)
			else:  # \ diagonal
				create_diagonal_wall(wall_position, false)

	# Optional entrance/exit markers (disabled by default).
	if show_marker_disks:
		create_marker(Vector3(ant_size, start_pos.y * cell_size + cell_size/2, 0), Color.GREEN)
		create_marker(Vector3(ant_size, exit_pos.y * cell_size + cell_size/2, grid_width * cell_size), Color.BLUE)

func create_diagonal_wall(position, is_forward_slash) -> void:
	var wall_node = Node3D.new()
	wall_node.position = position
	add_child(wall_node)

	# Store reference to wall node for movement
	wall_nodes.append(wall_node)

	# IMPRESSION dispatch. Each branch's FIRST child of wall_node is the diagonal
	# element and nothing else, because _on_wall_timer_timeout re-rolls a cell by
	# taking get_child(0) and rotating it 90° about X — which swaps / for \ in every
	# one of the four impressions, including `tile` (rotating a half-square about its
	# own centre lands it on the other half). Break that and the churn silently stops.
	match impression:
		"character":
			_impress_character(wall_node, is_forward_slash)
			return
		"wall":
			_impress_wall(wall_node, is_forward_slash)
			return
		"tile":
			_impress_tile(wall_node, is_forward_slash)
			return
		_:
			pass                    # stroke — the legacy lineage, below, byte for byte

	# Render each 10 PRINT stroke as a line (no square bars).
	var line_length := cell_size * sqrt(2.0)
	var wall_mesh := ImmediateMesh.new()
	var wall_material := StandardMaterial3D.new()
	wall_material.albedo_color = wall_color
	wall_material.emission_enabled = true
	wall_material.emission = wall_color
	wall_material.emission_energy_multiplier = 0.6
	wall_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wall_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var wall_instance = MeshInstance3D.new()
	wall_instance.mesh = wall_mesh
	wall_instance.material_override = wall_material
	wall_mesh.surface_begin(Mesh.PRIMITIVE_LINES, wall_material)
	wall_mesh.surface_add_vertex(Vector3(0, 0, -line_length * 0.5))
	wall_mesh.surface_add_vertex(Vector3(0, 0, line_length * 0.5))
	wall_mesh.surface_end()

	# Position at center of cell in ZY plane
	wall_instance.position = Vector3(0, cell_size/2, cell_size/2)

	# Rotate around X axis to create diagonals in ZY plane
	if is_forward_slash:  # / (bottom-left to top-right)
		wall_instance.rotation = Vector3(-PI/4, 0, 0)
	else:  # \ (top-left to bottom-right)
		wall_instance.rotation = Vector3(PI/4, 0, 0)

	wall_node.add_child(wall_instance)

func create_marker(position, color) -> void:
	var marker_mesh = CylinderMesh.new()
	marker_mesh.top_radius = cell_size * 0.3
	marker_mesh.bottom_radius = cell_size * 0.3
	marker_mesh.height = 0.1
	
	var marker_material = StandardMaterial3D.new()
	marker_material.albedo_color = color
	marker_material.emission_enabled = true
	marker_material.emission = color
	marker_material.emission_energy_multiplier = 0.5
	
	var marker_instance = MeshInstance3D.new()
	marker_instance.mesh = marker_mesh
	marker_instance.material_override = marker_material
	marker_instance.position = position
	
	add_child(marker_instance)



func create_ant() -> void:
	ant_node = Node3D.new()
	ant_node.name = "Ant"
	
	var ant_mesh = SphereMesh.new()
	ant_mesh.radius = ant_size
	ant_mesh.height = ant_size * 2
	
	var ant_material = StandardMaterial3D.new()
	ant_material.albedo_color = ant_color
	ant_material.emission_enabled = true
	ant_material.emission = ant_color
	ant_material.emission_energy_multiplier = 0.5
	
	var ant_mesh_instance = MeshInstance3D.new()
	ant_mesh_instance.mesh = ant_mesh
	ant_mesh_instance.material_override = ant_material
	
	ant_node.add_child(ant_mesh_instance)
	add_child(ant_node)

func create_path_visualization() -> void:
	path_node = Node3D.new()
	path_node.name = "Path"
	add_child(path_node)
	
	# We'll create the actual path mesh in update_path_visualization()

func place_ant() -> void:
	# Place ant at start (bottom side in ZY plane)
	var start_z = start_pos.y * nav_grid_scale + nav_grid_scale / 2
	ant_nav_pos = Vector2i(0, start_z)
	ant_path = [ant_nav_pos]

	# Set 3D position (now in ZY plane)
	var ant_3d_y = ant_nav_pos.y * cell_size / nav_grid_scale
	var ant_3d_z = ant_nav_pos.x * cell_size / nav_grid_scale
	ant_node.position = Vector3(ant_size, ant_3d_y, ant_3d_z)

	# Default (animate true) is `true`, exactly as shipped. A frozen ant stands at the
	# entrance and draws no trace, which is what makes a still of this artifact
	# reproducible — move_ant() draws randf() on every step it takes.
	ant_moving = _is_truthy(animate)
	visited = {ant_nav_pos: true}

func move_ant(_delta) -> void:
	if is_at_exit():
		found_exit = true
		return
	
	# Get available moves
	var moves = get_possible_moves()
	
	if moves.size() == 0:
		# If stuck, backtrack
		if ant_path.size() > 1:
			ant_path.pop_back()
			if ant_path.size() > 0:
				ant_nav_pos = ant_path[ant_path.size() - 1]
				update_ant_3d_position()
		return
	
	# Choose move with preference toward exit
	var next_pos = choose_best_move(moves)
	ant_nav_pos = next_pos
	ant_path.append(ant_nav_pos)
	visited[ant_nav_pos] = true
	update_ant_3d_position()

func update_ant_3d_position() -> void:
	# Update the 3D position of the ant based on its navigation grid position (ZY plane)
	var ant_3d_y = ant_nav_pos.y * cell_size / nav_grid_scale
	var ant_3d_z = ant_nav_pos.x * cell_size / nav_grid_scale
	ant_node.position = Vector3(ant_size, ant_3d_y, ant_3d_z)

func is_at_exit():
	# Check if ant has reached right edge of maze
	return ant_nav_pos.x >= (grid_width * nav_grid_scale - 1)

func get_possible_moves():
	var moves = []
	var directions = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
	
	for dir in directions:
		var new_pos = ant_nav_pos + dir
		
		# Check bounds
		if new_pos.x < 0 or new_pos.x >= grid_width * nav_grid_scale or \
		   new_pos.y < 0 or new_pos.y >= grid_depth * nav_grid_scale:
			continue
		
		# Check if we've been here before
		if visited.has(new_pos):
			continue
		
		# Check if this is a wall
		if new_pos.y < nav_grid.size() and new_pos.x < nav_grid[new_pos.y].size():
			if nav_grid[new_pos.y][new_pos.x] == 1:
				continue
		
		moves.append(new_pos)
	
	return moves

func choose_best_move(moves):
	# Use a simple heuristic: prefer moves that get us closer to the exit
	var best_score = -1
	var best_move = null
	
	# Target is the exit on the right side
	var target_x = grid_width * nav_grid_scale - 1
	
	for move in moves:
		# Score based on distance to exit
		var dx = target_x - move.x
		
		# We want to minimize dx (distance to right edge)
		var distance = dx * dx
		
		# Add some randomness to avoid straight paths
		var score = 1000.0 / (distance + 1) + randf() * 2.0
		
		if best_move == null or score > best_score:
			best_score = score
			best_move = move
	
	return best_move

func update_path_visualization() -> void:
	# Remove previous path
	if path_mesh_instance != null:
		path_mesh_instance.queue_free()

	if ant_path.size() <= 1:
		return

	# Create a new path using ImmediateMesh
	var path_immediate_mesh = ImmediateMesh.new()
	path_mesh_instance = MeshInstance3D.new()
	path_mesh_instance.mesh = path_immediate_mesh

	var path_material = StandardMaterial3D.new()
	path_material.albedo_color = path_color
	path_material.emission_enabled = true
	path_material.emission = path_color
	path_material.emission_energy_multiplier = 1.0
	path_mesh_instance.material_override = path_material

	# Draw the path (now in ZY plane)
	path_immediate_mesh.clear_surfaces()
	path_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, path_material)

	for point in ant_path:
		var y = point.y * cell_size / nav_grid_scale
		var z = point.x * cell_size / nav_grid_scale
		path_immediate_mesh.surface_add_vertex(Vector3(ant_size, y, z))

	path_immediate_mesh.surface_end()
	path_node.add_child(path_mesh_instance)

func setup_wall_movement_timer() -> void:
	"""Setup timer to move a random wall at the configured interval."""
	wall_timer = Timer.new()
	wall_timer.wait_time = maxf(wall_change_interval, 0.02)
	wall_timer.timeout.connect(_on_wall_timer_timeout)
	wall_timer.autostart = true
	add_child(wall_timer)

func _on_wall_timer_timeout() -> void:
	"""Rotate a random wall to change its diagonal direction"""
	if wall_nodes.is_empty():
		return

	# Pick a random wall
	var random_wall = wall_nodes[randi() % wall_nodes.size()]

	# Get the wall's mesh instance
	var wall_instance = random_wall.get_child(0) as MeshInstance3D
	if not wall_instance:
		return

	# Rotate the wall by 90 degrees around X axis (switching between / and \ in ZY plane)
	wall_instance.rotate_x(PI/2)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═════════════════════════════════════════════════════════════════════════════
# IMPRESSION — the three non-legacy ways one random bit can be written down.
# Built from bare primitives, in the same ZY plane and on the same cell centre the
# legacy stroke uses, so a cell occupies the same seat at every value and the four
# tiles of a sweep are the same maze in four hands.
# ═════════════════════════════════════════════════════════════════════════════

## Shared cell metrics. The legacy stroke spans the full cell diagonal from
## (0,0,-L/2) to (0,0,+L/2) and is then rotated ±45° about X — every impression
## below reuses that length and that rotation so the marks meet at cell corners
## exactly as they always have. Meeting at the corners is the entire reason this
## reads as continuous contour rather than as confetti.
func _stroke_basis() -> Dictionary:
	return {
		"length": cell_size * sqrt(2.0),
		"centre": Vector3(0, cell_size / 2.0, cell_size / 2.0),
	}


func _unshaded(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _slab(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	return mi


## CHARACTER — the C64 reading. The diagonal is given body (a bar rather than a
## hairline) and set inside its own cell frame, so what you see is a glyph stamped
## into one seat of a text grid. The frame is drawn at a third of the stroke's
## emission so the character stays the figure and the grid stays the ground.
func _impress_character(wall_node: Node3D, is_forward_slash: bool) -> void:
	var basis_data: Dictionary = _stroke_basis()
	var length: float = float(basis_data["length"])
	var centre: Vector3 = basis_data["centre"]
	var t: float = maxf(cell_size * 0.09, 0.02)

	# child 0 — the glyph stroke, a bar along local Z, rotated onto the diagonal.
	var glyph: MeshInstance3D = _slab(
		Vector3(t, t, length), Vector3.ZERO, _unshaded(wall_color, 0.6))
	glyph.position = centre
	glyph.rotation = Vector3((-PI / 4.0) if is_forward_slash else (PI / 4.0), 0, 0)
	wall_node.add_child(glyph)

	# the character cell — four thin rails on the cell boundary, dimmer than the glyph
	var rail: StandardMaterial3D = _unshaded(wall_color.darkened(0.45), 0.18)
	var r: float = maxf(cell_size * 0.035, 0.01)
	var h: float = cell_size * 0.5
	for sy in [-1.0, 1.0]:
		wall_node.add_child(_slab(Vector3(r, r, cell_size),
			centre + Vector3(0, sy * h, 0), rail))
	for sz in [-1.0, 1.0]:
		wall_node.add_child(_slab(Vector3(r, cell_size, r),
			centre + Vector3(0, 0, sz * h), rail))


## WALL — the maze reading made literal. The stroke leaves the plane: a slab with
## real depth in X (toward the viewer) and real width in the plane, lit rather than
## unshaded so it takes a highlight and reads as matter. This is the one impression
## in which the PRINT statement has vanished entirely into architecture.
func _impress_wall(wall_node: Node3D, is_forward_slash: bool) -> void:
	var basis_data: Dictionary = _stroke_basis()
	var length: float = float(basis_data["length"])
	var centre: Vector3 = basis_data["centre"]
	# wall_thickness has been an @export doing nothing since this file was written.
	# It is the in-plane width of the slab; the out-of-plane depth is a third of a
	# cell, enough for the field to read as built from the sweep's 3/4 view.
	var w: float = maxf(wall_thickness, 0.02)
	var depth: float = cell_size * 0.34

	var mat := StandardMaterial3D.new()
	mat.albedo_color = wall_color
	mat.metallic = 0.05
	mat.roughness = 0.62
	mat.emission_enabled = true
	mat.emission = wall_color
	mat.emission_energy_multiplier = 0.12

	# child 0 — rotation about X leaves the X extent alone, so the slab keeps its
	# depth and only its cross-section swings from / to \.
	var slab: MeshInstance3D = _slab(Vector3(depth, w, length), Vector3.ZERO, mat)
	slab.position = centre
	slab.rotation = Vector3((-PI / 4.0) if is_forward_slash else (PI / 4.0), 0, 0)
	wall_node.add_child(slab)


## TILE — the textile reading. No stroke at all: the cell is filled edge to edge and
## split along the diagonal into two tones, so the picture is a two-colour tiling and
## the "maze" is whatever your eye makes of the boundary between the tones. This is
## the pattern before it is ever a place.
##
## The bright half is a right triangle occupying half the cell. Rotating it 90° about
## X carries it onto the OTHER half (the rotation maps (y,z) → (−z,y), which is the
## reflection across the anti-diagonal), so the churn timer flips the tile exactly the
## way it flips a stroke.
func _impress_tile(wall_node: Node3D, is_forward_slash: bool) -> void:
	var centre: Vector3 = _stroke_basis()["centre"]
	var h: float = cell_size * 0.5

	var bright: StandardMaterial3D = _unshaded(wall_color, 0.30)
	var dark: StandardMaterial3D = _unshaded(wall_color.darkened(0.78), 0.05)

	# child 0 — the lit half, as a flat triangle standing 1 cm proud of the backing
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3(1, 0, 0))
	var corners: Array = [Vector3(0, -h, -h), Vector3(0, h, -h), Vector3(0, -h, h)]
	if not is_forward_slash:
		corners = [Vector3(0, h, h), Vector3(0, -h, h), Vector3(0, h, -h)]
	for c in corners:
		st.set_uv(Vector2(0, 0))
		st.add_vertex(c)
	var half := MeshInstance3D.new()
	half.mesh = st.commit()
	half.material_override = bright
	half.position = centre + Vector3(0.01, 0, 0)
	wall_node.add_child(half)

	# the backing plate — the unlit half, and the reason the field reads as filled
	var back := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(cell_size, cell_size)
	qm.orientation = PlaneMesh.FACE_X
	back.mesh = qm
	back.material_override = dark
	back.position = centre
	wall_node.add_child(back)


# ═════════════════════════════════════════════════════════════════════════════
# DNA plumbing
# ═════════════════════════════════════════════════════════════════════════════

## Accepts a real bool, an int, or the strings a map token and a sweep fixture carry.
func _is_truthy(v) -> bool:
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	return str(v).strip_edges().to_lower() in ["true", "1", "yes", "on"]


func _read_meta_overrides() -> void:
	if has_meta("config_impression"):
		var v: String = str(get_meta("config_impression")).strip_edges().to_lower()
		if IMPRESSIONS.has(v):
			impression = v
		elif v != "":
			push_warning("ten_print_maze: unknown impression '%s' — keeping '%s'"
				% [v, impression])
	if has_meta("config_maze_seed"):
		maze_seed = int(str(get_meta("config_maze_seed")))
	if has_meta("config_animate"):
		animate = _is_truthy(get_meta("config_animate"))


## LATENT BUG PAID (2026-08-02): this was `pass`. Every `#token: value` a map put on a
## ten_print_maze_3d placement was parsed, logged by GridInteractablesComponent and
## stashed as metadata, then silently dropped, because nothing here ever read it back.
##
## Guarded exactly like prng_crank_machine's: an unchanged impression touches nothing
## and says nothing, so curation_station's blanket apply_grid_config({"emissive": false})
## cannot trigger a rebuild that throws away framing it never re-applies.
func apply_grid_config(config: Dictionary) -> void:
	var before: String = impression
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()
	if not _built:
		return                      # nothing built yet; _ready will use these values
	if impression == before:
		return
	_reimpress()
	print("[TenPrintMaze] Config applied — impression=%s" % [impression])


## Redraw the SAME bits in a different hand. The maze array is not regenerated and no
## RNG is drawn: a late impression change must not silently deal a different maze, or
## a placement that also pins maze_seed would still move under the player.
func _reimpress() -> void:
	for w in wall_nodes:
		if is_instance_valid(w):
			remove_child(w)         # leaves the tree synchronously — no double-render
			w.queue_free()
	wall_nodes.clear()
	for z in range(grid_depth):
		for x in range(grid_width):
			var wall_position := Vector3(0, z * cell_size, x * cell_size)
			create_diagonal_wall(wall_position, maze[z][x] == 0)
