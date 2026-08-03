# PercolationNetwork3D.gd

# @identity
# essence: P(occupied) = threshold -> CA flow propagation from top to bottom — does the random lattice percolate?
# desire: to stand inside a 3D lattice and watch pink flow seep through white cubes, hoping it reaches the bottom before paths run out
# critical_parameter: PERCOLATION_THRESHOLD (0.4) — the probability that defines whether the system connects or fragments; near p_c the outcome is uncertain
# triggers: _process ticks the CA every frame; flow propagates through 6-connected neighbors; collision removed from flowing cubes so player can walk through the network
# emerges: at the critical threshold, the percolating cluster forms a fractal — neither filling the space nor vanishing, but threading through it
# needs: per-cube collision [has]; flow visualization [has]; real-time CA [has]; VR threshold slider [missing]; Label3D [missing]
# relationships: bridges cellularautomata sequence to proceduralgeneration; contrasts with caverandomwalk (random walk vs random lattice); teaches phase transitions
# truth: connectivity is not gradual — below the threshold nothing connects, above it everything does, and at the threshold the system decides

# Attach this script to a Node3D in your scene
extends Node3D

const GRID_SIZE = 18
const CUBE_SIZE = 0.5
const PERCOLATION_THRESHOLD = 0.4  # Lower threshold to create more pathways
const FLOW_RATE = 0.15
const MAX_ITERATIONS = 500

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA PROMOTION (2026-08-03) — `occupation` and `inlet`
# ═══════════════════════════════════════════════════════════════════════════
#
# This artifact's own @identity block names PERCOLATION_THRESHOLD as its critical
# parameter and then lists a threshold control under `needs` as MISSING. The number was
# a const, so the one quantity the piece exists to argue about could not be argued with:
# every placement, in every map, got p = 0.4 — comfortably above the 3D site-percolation
# critical point p_c ~= 0.3116, which is to say every player who ever met this lattice met
# a lattice that was always going to connect. The claim "below the threshold nothing
# connects, above it everything does, and at the threshold the system decides" was
# demonstrated only on its winning side.
#
#   occupation  HOW MUCH LATTICE THERE IS — p, the probability a site is open.
#     sparse      0.20  well under p_c: isolated pockets, the flow dies near the top face
#     critical    0.31  at p_c: the incipient cluster, fractal, the outcome genuinely open
#     conductive  0.40  THE SHIPPED VALUE. above p_c; a network with room to walk in
#     dense       0.60  everything connects and the paths stop being paths
#     solid       0.80  a wall. percolation is trivial and the network is no longer one
#
#   inlet  WHERE THE FLOW ENTERS — which sites are seeded as SOURCE. This is a boundary
#          condition, not a decoration: it is the difference between classical percolation
#          (a front descending from a plane) and invasion from a single site.
#     face   every open site on the +z face      THE SHIPPED VALUE. a rain front
#     point  the open site nearest that face's centre. one injection, one dendrite
#     seam   one row across the face. a line source, and a sheet of flow instead of a volume
#     shell  every open site on ALL SIX faces. the flow arrives from outside, inward
#
# occupation=conductive, inlet=face is the pre-promotion behaviour EXACTLY — same 0.4,
# same top-face seeding, same materials, same collision rule — and it is the default, so
# every existing placement is unchanged.
#
# A WARNING THAT BELONGS IN THE CODE, not only in the registry: occupied (white) cubes
# CARRY COLLISION and the player walks inside this lattice. `dense` and `solid` are honest
# arguments and bad rooms; they are bench values. Nothing above `conductive` should be
# placed in a walked map without checking the map still has a path through it.
#
# Usage in map_data.json:
#   "percolationnetwork_ca#occupation:critical"
#   "percolationnetwork_ca#occupation:sparse#inlet:point#lattice_seed:7"

## How much lattice there is — the probability that a site is open. See the note above.
@export_enum("sparse", "critical", "conductive", "dense", "solid") var occupation: String = "conductive"
## Where the flow enters the lattice. See the note above.
@export_enum("face", "point", "seam", "shell") var inlet: String = "face"
## SEED for the lattice and for the flow jitter, both of which have always come from the
## global unseeded randf(). -1 keeps that exactly: a new lattice every launch. Any other
## value fixes it, which is what a sweep needs if it is to measure the axis and not the
## dice — five variants of an unseeded lattice are five different objects.
@export var lattice_seed: int = -1

## Site-open probability per value of `occupation`. p_c(3D site) ~= 0.3116.
const OCCUPATIONS := {
	"sparse": 0.20,
	"critical": 0.31,
	"conductive": 0.40,
	"dense": 0.60,
	"solid": 0.80,
}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _built: bool = false

var grid: Array = []
var flow_grid: Array = []
var cube_nodes: Array = []  # Store individual cube nodes for collision
var material_occupied: StandardMaterial3D
var material_flowing: StandardMaterial3D
var material_blocked: StandardMaterial3D

var iteration_count = 0
var percolation_complete = false

# Cellular automata states for percolation
enum CellState {
	EMPTY = 0,        # Empty space (blocked)
	OCCUPIED = 1,     # Occupied site (can conduct)
	FLOWING = 2,      # Currently has flow
	CONNECTED = 3,    # Connected to percolating cluster
	SOURCE = 4        # Source points (top face)
}

func _ready() -> void:
	_read_grid_config_meta()
	_seed_rng()
	setup_percolation_system()
	initialize_lattice()
	create_cube_collision_boxes()
	start_percolation()
	_built = true

func setup_percolation_system() -> void:
	# Initialize 3D arrays
	grid.resize(GRID_SIZE)
	flow_grid.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		grid[x] = []
		flow_grid[x] = []
		grid[x].resize(GRID_SIZE)
		flow_grid[x].resize(GRID_SIZE)
		
		for y in range(GRID_SIZE):
			grid[x][y] = []
			flow_grid[x][y] = []
			grid[x][y].resize(GRID_SIZE)
			flow_grid[x][y].resize(GRID_SIZE)
			
			for z in range(GRID_SIZE):
				grid[x][y][z] = CellState.EMPTY
				flow_grid[x][y][z] = 0.0

func initialize_lattice() -> void:
	# Create random occupied sites based on percolation threshold
	var p: float = _site_probability()
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if _rng.randf() < p:  # Use threshold directly for pathways
					grid[x][y][z] = CellState.OCCUPIED

	# Set source points — the top face (z = GRID_SIZE - 1) unless `inlet` says otherwise
	_seed_inlet()

func create_cube_collision_boxes() -> void:
	# Initialize cube nodes array
	cube_nodes.resize(GRID_SIZE)
	for x in range(GRID_SIZE):
		cube_nodes[x] = []
		cube_nodes[x].resize(GRID_SIZE)
		for y in range(GRID_SIZE):
			cube_nodes[x][y] = []
			cube_nodes[x][y].resize(GRID_SIZE)
	
	# Create materials for different states - white cubes with collision, pink very transparent no collision
	material_occupied = StandardMaterial3D.new()
	material_occupied.albedo_color = Color.WHITE
	material_occupied.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	
	material_flowing = StandardMaterial3D.new()
	material_flowing.albedo_color = Color(1.0, 0.75, 0.8)  # Pink color
	material_flowing.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_flowing.albedo_color.a = 0.2  # Very transparent (20% opacity) - NO COLLISION
	
	material_blocked = StandardMaterial3D.new()
	material_blocked.albedo_color = Color(1.0, 0.75, 0.8)  # Pink color
	material_blocked.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_blocked.albedo_color.a = 0.2  # Very transparent (20% opacity) - NO COLLISION
	
	# Create individual collision boxes for each occupied cell
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] != CellState.EMPTY:
					create_single_cube_collision(x, y, z, grid[x][y][z])

func start_percolation() -> void:
	print("Starting percolation simulation...")
	print("Grid size: ", GRID_SIZE, "³")
	print("Occupied sites: ", count_occupied_sites())

func _process(_delta):
	if not percolation_complete and iteration_count < MAX_ITERATIONS:
		update_percolation_automata()
		update_cube_visualization()
		iteration_count += 1
		
		if iteration_count % 10 == 0:
			check_percolation_status()

func update_percolation_automata() -> void:
	var new_grid = duplicate_grid()
	var new_flow = duplicate_flow_grid()
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var current_state = grid[x][y][z]
				var current_flow = flow_grid[x][y][z]
				
				match current_state:
					CellState.OCCUPIED:
						# Check if flow reaches this occupied site
						var neighbor_flow = calculate_neighbor_flow(x, y, z)
						if neighbor_flow > 0:
							new_grid[x][y][z] = CellState.FLOWING
							new_flow[x][y][z] = min(1.0, neighbor_flow * FLOW_RATE)
					
					CellState.FLOWING:
						# Flowing sites maintain flow and spread to neighbors
						new_flow[x][y][z] = max(0.1, current_flow * 0.9)
						propagate_flow_to_neighbors(new_flow, x, y, z, current_flow)
						
						# Check if this site should become permanently connected
						if current_flow > 0.8:
							new_grid[x][y][z] = CellState.CONNECTED
					
					CellState.CONNECTED:
						# Connected sites maintain permanent flow
						new_flow[x][y][z] = 1.0
						propagate_flow_to_neighbors(new_flow, x, y, z, 1.0)
					
					CellState.SOURCE:
						# Source sites always have maximum flow
						new_flow[x][y][z] = 1.0
						propagate_flow_to_neighbors(new_flow, x, y, z, 1.0)
	
	grid = new_grid
	flow_grid = new_flow

func calculate_neighbor_flow(x: int, y: int, z: int) -> float:
	var max_flow = 0.0
	
	# Check 6-connected neighbors (face neighbors only)
	var neighbors = [
		Vector3i(x+1, y, z), Vector3i(x-1, y, z),
		Vector3i(x, y+1, z), Vector3i(x, y-1, z),
		Vector3i(x, y, z+1), Vector3i(x, y, z-1)
	]
	
	for neighbor in neighbors:
		if is_valid_position(neighbor.x, neighbor.y, neighbor.z):
			var neighbor_state = grid[neighbor.x][neighbor.y][neighbor.z]
			if neighbor_state == CellState.FLOWING or neighbor_state == CellState.CONNECTED or neighbor_state == CellState.SOURCE:
				max_flow = max(max_flow, flow_grid[neighbor.x][neighbor.y][neighbor.z])
	
	return max_flow

func propagate_flow_to_neighbors(new_flow: Array, x: int, y: int, z: int, current_flow: float) -> void:
	var flow_amount = current_flow * FLOW_RATE
	
	# 6-connected neighborhood
	var neighbors = [
		Vector3i(x+1, y, z), Vector3i(x-1, y, z),
		Vector3i(x, y+1, z), Vector3i(x, y-1, z),
		Vector3i(x, y, z+1), Vector3i(x, y, z-1)
	]
	
	for neighbor in neighbors:
		if is_valid_position(neighbor.x, neighbor.y, neighbor.z):
			var neighbor_state = grid[neighbor.x][neighbor.y][neighbor.z]
			if neighbor_state == CellState.OCCUPIED:
				new_flow[neighbor.x][neighbor.y][neighbor.z] = max(
					new_flow[neighbor.x][neighbor.y][neighbor.z],
					flow_amount * _rng.randf_range(0.7, 1.0)
				)

func is_valid_position(x: int, y: int, z: int) -> bool:
	return x >= 0 and x < GRID_SIZE and y >= 0 and y < GRID_SIZE and z >= 0 and z < GRID_SIZE

func duplicate_grid() -> Array:
	var new_grid = []
	new_grid.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		new_grid[x] = []
		new_grid[x].resize(GRID_SIZE)
		for y in range(GRID_SIZE):
			new_grid[x][y] = grid[x][y].duplicate()
	
	return new_grid

func duplicate_flow_grid() -> Array:
	var new_flow = []
	new_flow.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		new_flow[x] = []
		new_flow[x].resize(GRID_SIZE)
		for y in range(GRID_SIZE):
			new_flow[x][y] = flow_grid[x][y].duplicate()
	
	return new_flow

func create_single_cube_collision(x: int, y: int, z: int, state: CellState) -> void:
	# Create parent node
	var cube_node = Node3D.new()
	cube_node.name = "Cube_" + str(x) + "_" + str(y) + "_" + str(z)
	
	# Set position (no gutter - cubes touch)
	var world_pos = Vector3(
		(x - GRID_SIZE/2) * CUBE_SIZE,
		(y - GRID_SIZE/2) * CUBE_SIZE,
		(z - GRID_SIZE/2) * CUBE_SIZE
	)
	cube_node.position = world_pos
	
	# Only add collision for white cubes (occupied state)
	# Pink cubes (FLOWING, CONNECTED, SOURCE) have NO collision
	if state == CellState.OCCUPIED:
		var static_body = StaticBody3D.new()
		static_body.name = "CollisionBody"
		
		# Create CollisionShape3D
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
		collision_shape.shape = box_shape
		static_body.add_child(collision_shape)
		
		cube_node.add_child(static_body)
	
	# Create MeshInstance3D for visualization (all cubes)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
	mesh_instance.mesh = box_mesh
	cube_node.add_child(mesh_instance)
	
	# Set material based on state
	var material = get_material_for_state(state)
	mesh_instance.material_override = material
	
	# Store reference
	cube_nodes[x][y][z] = cube_node
	add_child(cube_node)

func get_material_for_state(state: CellState) -> StandardMaterial3D:
	match state:
		CellState.OCCUPIED:
			return material_occupied
		CellState.FLOWING, CellState.CONNECTED, CellState.SOURCE:
			return material_flowing
		_:
			return material_blocked

func update_cube_visualization() -> void:
	# Update existing cubes and create new ones as needed
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var current_state = grid[x][y][z]
				var cube_node = cube_nodes[x][y][z]
				
				if current_state != CellState.EMPTY:
					if cube_node:
						# Update existing cube
						var mesh_instance = cube_node.get_node("MeshInstance3D")
						var material = get_material_for_state(current_state)
						mesh_instance.material_override = material
						
						# Update collision based on state
						update_cube_collision(cube_node, current_state)
					else:
						# Create new cube for newly occupied cell
						create_single_cube_collision(x, y, z, current_state)
				else:
					# Remove cube if cell becomes empty
					if cube_node:
						cube_node.queue_free()
						cube_nodes[x][y][z] = null

func update_cube_collision(cube_node: Node3D, state: CellState) -> void:
	# Remove existing collision body if it exists
	var existing_collision = cube_node.get_node_or_null("CollisionBody")
	if existing_collision:
		existing_collision.queue_free()
		# Remove from parent immediately to ensure no collision interference
		cube_node.remove_child(existing_collision)
	
	# Add collision only for white cubes (occupied state)
	# Pink cubes (FLOWING, CONNECTED, SOURCE) have NO collision
	if state == CellState.OCCUPIED:
		var static_body = StaticBody3D.new()
		static_body.name = "CollisionBody"
		
		# Create CollisionShape3D
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
		collision_shape.shape = box_shape
		static_body.add_child(collision_shape)
		
		cube_node.add_child(static_body)

# Helper function to get cube world position
func get_cube_world_position(x: int, y: int, z: int) -> Vector3:
	return Vector3(
		(x - GRID_SIZE/2) * CUBE_SIZE,
		(y - GRID_SIZE/2) * CUBE_SIZE,
		(z - GRID_SIZE/2) * CUBE_SIZE
	)

func check_percolation_status() -> void:
	var bottom_connected = false
	
	# Check if flow has reached the bottom face (z = 0)
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y][0] == CellState.FLOWING or grid[x][y][0] == CellState.CONNECTED:
				bottom_connected = true
				break
		if bottom_connected:
			break
	
	if bottom_connected and not percolation_complete:
		percolation_complete = true
		print("PERCOLATION ACHIEVED! Flow connected from top to bottom.")
		print("Iterations required: ", iteration_count)
		print("Connected sites: ", count_connected_sites())
	elif iteration_count >= MAX_ITERATIONS and not percolation_complete:
		print("Simulation complete. No percolation detected.")
		print("This may be below the percolation threshold.")

func count_occupied_sites() -> int:
	var count = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] != CellState.EMPTY:
					count += 1
	return count

func count_connected_sites() -> int:
	var count = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] == CellState.CONNECTED or grid[x][y][z] == CellState.FLOWING:
					count += 1
	return count

# Debug method to get percolation statistics
func get_percolation_stats() -> Dictionary:
	return {
		"iteration": iteration_count,
		"occupied_sites": count_occupied_sites(),
		"connected_sites": count_connected_sites(),
		"percolation_achieved": percolation_complete,
		"occupation_probability": float(count_occupied_sites()) / (GRID_SIZE * GRID_SIZE * GRID_SIZE),
		"total_cubes": count_total_cubes(),
		"colliding_cubes": count_colliding_cubes(),
		"pink_cubes": count_total_cubes() - count_colliding_cubes()
	}

func count_total_cubes() -> int:
	var count = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if cube_nodes[x][y][z] != null:
					count += 1
	return count

func count_colliding_cubes() -> int:
	var count = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] == CellState.OCCUPIED:
					count += 1
	return count

# Method to get collision information for a specific position
func get_cube_at_position(world_pos: Vector3) -> Node3D:
	var grid_pos = world_to_grid_position(world_pos)
	if is_valid_position(grid_pos.x, grid_pos.y, grid_pos.z):
		return cube_nodes[grid_pos.x][grid_pos.y][grid_pos.z]
	return null

# Method to get collision body for a specific position (only for white cubes)
func get_collision_body_at_position(world_pos: Vector3) -> StaticBody3D:
	var cube_node = get_cube_at_position(world_pos)
	if cube_node:
		return cube_node.get_node_or_null("CollisionBody")
	return null

func world_to_grid_position(world_pos: Vector3) -> Vector3i:
	var x = int(round(world_pos.x / CUBE_SIZE + GRID_SIZE/2))
	var y = int(round(world_pos.y / CUBE_SIZE + GRID_SIZE/2))
	var z = int(round(world_pos.z / CUBE_SIZE + GRID_SIZE/2))
	return Vector3i(x, y, z)

# Debug function to check collision status at a position
func debug_collision_at_position(world_pos: Vector3) -> Dictionary:
	var grid_pos = world_to_grid_position(world_pos)
	var cube_node = get_cube_at_position(world_pos)
	var collision_body = get_collision_body_at_position(world_pos)
	
	return {
		"grid_position": grid_pos,
		"cube_exists": cube_node != null,
		"has_collision": collision_body != null,
		"state": grid[grid_pos.x][grid_pos.y][grid_pos.z] if is_valid_position(grid_pos.x, grid_pos.y, grid_pos.z) else -1
	}

# Force remove all collision from pink cubes (call this if needed)
func force_remove_pink_cube_collisions() -> void:
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var state = grid[x][y][z]
				if state == CellState.FLOWING or state == CellState.CONNECTED or state == CellState.SOURCE:
					var cube_node = cube_nodes[x][y][z]
					if cube_node:
						var collision_body = cube_node.get_node_or_null("CollisionBody")
						if collision_body:
							cube_node.remove_child(collision_body)
							collision_body.queue_free()
							print("Removed collision from pink cube at ", x, ",", y, ",", z)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `occupation` and `inlet`
# EVERYTHING BELOW THIS LINE IS APPENDED. Above it, four lines moved: the two
# calls at the head of _ready(), the probability and the seeding in
# initialize_lattice(), and randf_range -> _rng.randf_range in the propagator.
# ═══════════════════════════════════════════════════════════════════════════

## Read the #key:value tokens the grid writes onto the artifact as `config_<key>`
## metadata before the scene enters the tree. This scene's ROOT carries the script, so
## apply_grid_config() below is reached directly too — this exists for the ordering case:
## the metadata is in place before _ready(), so a token builds the right lattice ONCE
## instead of building the default and then tearing it down.
##
## Costs nothing when no token is present. The exports keep their defaults and not a
## single existing placement changes.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_occupation"):
			occupation = str(node.get_meta("config_occupation"))
		if node.has_meta("config_inlet"):
			inlet = str(node.get_meta("config_inlet"))
		if node.has_meta("config_lattice_seed"):
			lattice_seed = int(str(node.get_meta("config_lattice_seed")))
		node = node.get_parent()


## Config from map_data.json tokens: #occupation:critical · #inlet:point#lattice_seed:7
##
## GUARDED ON CHANGE, deliberately. The grid reaches an artifact with whatever other keys
## the token carries, and can reach it after _ready has already built. Rebuilding 5,832
## cells and their collision bodies because a placement passed an unrelated key would be a
## visible stutter for nothing, so nothing happens unless a value of ours actually moved.
func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = false

	if config.has("occupation"):
		var want_occupation: String = str(config["occupation"])
		if want_occupation != occupation:
			occupation = want_occupation
			changed = true
	if config.has("inlet"):
		var want_inlet: String = str(config["inlet"])
		if want_inlet != inlet:
			inlet = want_inlet
			changed = true
	if config.has("lattice_seed"):
		var want_seed: int = int(str(config["lattice_seed"]))
		if want_seed != lattice_seed:
			lattice_seed = want_seed
			changed = true

	if not changed:
		return
	# Before _ready() there is no lattice yet and _ready() will build it with these values.
	if not _built:
		return
	_rebuild_lattice()


func _seed_rng() -> void:
	if lattice_seed < 0:
		_rng.randomize()                 # the shipped behaviour: a new lattice every launch
	else:
		_rng.seed = lattice_seed


## The site-open probability p this placement runs at. An unknown word keeps the shipped
## 0.4 rather than stranding a placement with an empty or solid room.
func _site_probability() -> float:
	var want: String = String(occupation).strip_edges().to_lower()
	if not OCCUPATIONS.has(want):
		want = "conductive"
	occupation = want
	return float(OCCUPATIONS[want])


## Mark the SOURCE sites — the boundary the flow is injected across.
func _seed_inlet() -> void:
	match inlet:
		"point":
			_seed_point()
		"seam":
			_seed_seam()
		"shell":
			_seed_shell()
		_:
			_seed_face()                 # the shipped behaviour: the whole +z face


## An open site becomes a source. A closed one is left closed — the boundary cannot open
## a site the lattice never gave it, which is what makes p and the inlet independent.
func _mark_source(x: int, y: int, z: int) -> void:
	if not is_valid_position(x, y, z):
		return
	if grid[x][y][z] == CellState.OCCUPIED:
		grid[x][y][z] = CellState.SOURCE
		flow_grid[x][y][z] = 1.0


## THE SHIPPED INLET, unchanged: every open site on the top face.
func _seed_face() -> void:
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			_mark_source(x, y, GRID_SIZE - 1)


## One site. Invasion from a point rather than a front — what grows is a dendrite, and
## whether it reaches the far face is a question about ONE cluster instead of all of them.
func _seed_point() -> void:
	var mid: int = int(GRID_SIZE / 2)
	var best_x: int = -1
	var best_y: int = -1
	var best_d: float = 1.0e9
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y][GRID_SIZE - 1] != CellState.OCCUPIED:
				continue
			var d: float = Vector2(float(x - mid), float(y - mid)).length()
			if d < best_d:
				best_d = d
				best_x = x
				best_y = y
	if best_x >= 0:
		_mark_source(best_x, best_y, GRID_SIZE - 1)


## A line across the face. The front is one-dimensional, so the flow spreads as a sheet
## and the lattice's anisotropy — which it should not have — becomes checkable by eye.
func _seed_seam() -> void:
	var mid: int = int(GRID_SIZE / 2)
	for x in range(GRID_SIZE):
		_mark_source(x, mid, GRID_SIZE - 1)


## All six faces. The flow arrives from outside and works inward, so what is being asked
## is not whether the lattice spans but whether anything in it stays dry.
func _seed_shell() -> void:
	for a in range(GRID_SIZE):
		for b in range(GRID_SIZE):
			_mark_source(a, b, 0)
			_mark_source(a, b, GRID_SIZE - 1)
			_mark_source(a, 0, b)
			_mark_source(a, GRID_SIZE - 1, b)
			_mark_source(0, a, b)
			_mark_source(GRID_SIZE - 1, a, b)


## Tear the lattice down and cast a new one. Only ever called from apply_grid_config, and
## only when a value actually changed.
func _rebuild_lattice() -> void:
	if cube_nodes.size() == GRID_SIZE:
		for x in range(GRID_SIZE):
			for y in range(GRID_SIZE):
				for z in range(GRID_SIZE):
					var node: Node = cube_nodes[x][y][z]
					if node != null and is_instance_valid(node):
						node.queue_free()
					cube_nodes[x][y][z] = null

	iteration_count = 0
	percolation_complete = false
	_seed_rng()
	setup_percolation_system()
	initialize_lattice()
	create_cube_collision_boxes()
	start_percolation()
