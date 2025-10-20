# CrackPropagation.gd
# Attach to a Node3D. Generates, grows and draws 2D crack lines on XZ-plane.
extends Node3D

# ---------- Simulation parameters ----------
@export var GRID_SIZE: int = 64        # cells per side
@export var CELL_SIZE: float = 0.25    # world meters per cell
@export var SEED: int = 0              # 0 = randomize()

@export_range(0.0, 1.0, 0.001) var CRACK_THRESHOLD: float = 0.30
@export_range(0.0, 1.0, 0.01) var PROPAGATION_RATE: float = 0.06     # stress from cracked neighbors to intact
@export_range(0.0, 1.0, 0.01) var STRESS_DIFFUSE: float = 0.04       # mild stress diffusion (all neighbors)
@export_range(0.0, 1.0, 0.01) var STRESS_DECAY: float = 0.02         # stress relax per tick
@export_range(0.0, 1.0, 0.01) var CRACK_PROPAGATION_CHANCE: float = 0.55   # chance a cracked cell seeds a new arm each step
@export var MAX_BRANCHES_PER_STEP: int = 400                         # safety / performance cap

# Bias new arms to follow existing directionality (prevents zig-zag)
@export_range(0.0, 1.0, 0.05) var DIRECTION_BIAS: float = 0.6

# ---------- Visual parameters ----------
@export var CRACK_COLOR: Color = Color(0.08, 0.05, 0.04, 1.0)
@export_range(0.001, 0.5, 0.001) var CRACK_WIDTH_BASE: float = 0.02  # meters
@export_range(0.0, 1.0, 0.01) var CRACK_WIDTH_STRESS_SCALE: float = 0.15
@export var EMISSIVE: float = 0.0   # set >0 for faint glow

# ---------- Grids ----------
var grid: Array = []         # int states
var stress_grid: Array = []  # float stress 0..1
var dir_grid: Array = []     # Vector2 direction memory for each cracked cell (for nicer continuity)

# Cellular automata states
enum CellState { INTACT = 0, STRESSED = 1, CRACKED = 2 }

# ---------- Mesh ----------
var crack_mesh: MeshInstance3D
var crack_material: StandardMaterial3D
var _mesh_dirty := true

# 8-neighborhood offsets
const N8 := [
	Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1),
	Vector2i(-1, 0),                 Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
]

func _ready():
	if SEED == 0: 
		randomize() 
	else: 
		seed(SEED)

	_init_arrays()
	_seed_weakness()
	_make_crack_mesh()
	_add_initial_stress_center()
	_mesh_dirty = true

func _process(_delta: float) -> void:
	var changed := _step_sim()
	if changed:
		_mesh_dirty = true
	if _mesh_dirty:
		_update_crack_mesh()
		_mesh_dirty = false

# ----------------- Setup -----------------
func _init_arrays() -> void:
	grid.resize(GRID_SIZE)
	stress_grid.resize(GRID_SIZE)
	dir_grid.resize(GRID_SIZE)
	for x in range(GRID_SIZE):
		grid[x] = []
		stress_grid[x] = []
		dir_grid[x] = []
		grid[x].resize(GRID_SIZE)
		stress_grid[x].resize(GRID_SIZE)
		dir_grid[x].resize(GRID_SIZE)
		for z in range(GRID_SIZE):
			grid[x][z] = CellState.INTACT
			stress_grid[x][z] = 0.0
			dir_grid[x][z] = Vector2.ZERO

func _seed_weakness() -> void:
	# 5% weak spots with small initial stress
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			if randf() < 0.05:
				stress_grid[x][z] = randf_range(0.1, 0.25)

func _make_crack_mesh() -> void:
	crack_mesh = MeshInstance3D.new()
	add_child(crack_mesh)

	crack_material = StandardMaterial3D.new()
	crack_material.flags_unshaded = true
	crack_material.flags_transparent = false
	crack_material.no_depth_test = false
	crack_material.albedo_color = CRACK_COLOR
	crack_material.metallic = 0.0
	crack_material.roughness = 1.0
	if EMISSIVE > 0.0:
		crack_material.emission_enabled = true
		crack_material.emission = CRACK_COLOR
		crack_material.emission_energy_multiplier = EMISSIVE

func _add_initial_stress_center() -> void:
	var cx: int = int(float(GRID_SIZE) / 2.0)
	var cz: int = int(float(GRID_SIZE) / 2.0)
	stress_grid[cx][cz] = 1.0
	grid[cx][cz] = CellState.STRESSED
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			var nx := cx + dx
			var nz := cz + dz
			if _in_bounds(nx, nz):
				var dist := sqrt(float(dx * dx + dz * dz))
				if dist > 0.0:
					stress_grid[nx][nz] = clamp(stress_grid[nx][nz] + 0.6 / dist, 0.0, 1.0)
					if stress_grid[nx][nz] > CRACK_THRESHOLD:
						grid[nx][nz] = CellState.STRESSED

# ----------------- Simulation -----------------
func _step_sim() -> bool:
	var changed := false
	var new_grid := _dup_grid()
	var new_stress := _dup_stress()

	# 1) diffuse and decay stress
	for x in range(1, GRID_SIZE - 1):
		for z in range(1, GRID_SIZE - 1):
			var s = stress_grid[x][z]
			# decay
			s = max(0.0, s - STRESS_DECAY)
			# mild diffusion (average of neighbors)
			var neigh_sum := 0.0
			for v in N8:
				neigh_sum += stress_grid[x + v.x][z + v.y]
			var neigh_avg := neigh_sum / 8.0
			s = clamp(lerp(s, neigh_avg, STRESS_DIFFUSE), 0.0, 1.0)
			new_stress[x][z] = s

	# 2) intact & stressed → update, cracked propagates stress
	for x in range(1, GRID_SIZE - 1):
		for z in range(1, GRID_SIZE - 1):
			var state = grid[x][z]
			match state:
				CellState.INTACT:
					var add := _stress_from_cracked_neighbors(x, z)
					new_stress[x][z] = clamp(new_stress[x][z] + add, 0.0, 1.0)
					if new_stress[x][z] > CRACK_THRESHOLD:
						new_grid[x][z] = CellState.STRESSED
						changed = true

				CellState.STRESSED:
					var p := _crack_probability(x, z)
					if randf() < p:
						new_grid[x][z] = CellState.CRACKED
						new_stress[x][z] = 1.0
						# set an initial direction guess using stress gradient
						dir_grid[x][z] = _dominant_neighbor_direction(x, z)
						changed = true

				CellState.CRACKED:
					# Cracked continues to push stress outward
					for v in N8:
						var nx = x + v.x
						var nz = z + v.y
						if _in_bounds(nx, nz):
							new_stress[nx][nz] = clamp(new_stress[nx][nz] + PROPAGATION_RATE * stress_grid[x][z], 0.0, 1.0)

	# 3) branching from cracked cells (limited per step)
	var branches := 0
	for x in range(1, GRID_SIZE - 1):
		for z in range(1, GRID_SIZE - 1):
			if branches >= MAX_BRANCHES_PER_STEP:
				break
			if grid[x][z] == CellState.CRACKED and randf() < CRACK_PROPAGATION_CHANCE:
				var ok := _branch_from_cell(new_grid, new_stress, x, z)
				if ok:
					branches += 1
					changed = true

	grid = new_grid
	stress_grid = new_stress
	return changed

func _stress_from_cracked_neighbors(x: int, z: int) -> float:
	var s := 0.0
	for v in N8:
		var nx = x + v.x
		var nz = z + v.y
		if grid[nx][nz] == CellState.CRACKED:
			s += stress_grid[nx][nz] * PROPAGATION_RATE
	return s

func _crack_probability(x: int, z: int) -> float:
	var base := 0.08
	var cracked_n := 0
	for v in N8:
		var nx = x + v.x
		var nz = z + v.y
		if grid[nx][nz] == CellState.CRACKED:
			cracked_n += 1
	var p = base + stress_grid[x][z] * 0.55 + float(cracked_n) * 0.12
	return clamp(p, 0.0, 1.0)

func _dominant_neighbor_direction(x: int, z: int) -> Vector2:
	var best_dir := Vector2.ZERO
	var best_val := -1.0
	for v in N8:
		var nx = x + v.x
		var nz = z + v.y
		var s = stress_grid[nx][nz]
		if s > best_val:
			best_val = s
			best_dir = Vector2(v.x, v.y).normalized()
	return best_dir

func _branch_from_cell(new_grid: Array, new_stress: Array, x: int, z: int) -> bool:
	# Prefer continuing along previous direction
	var prefer = dir_grid[x][z]
	var candidates: Array = []
	for v in N8:
		var nx = x + v.x
		var nz = z + v.y
		if not _in_bounds(nx, nz):
			continue
		if new_grid[nx][nz] != CellState.CRACKED:
			# score by alignment with preferred direction and local stress
			var align := 0.0
			if prefer != Vector2.ZERO:
				align = max(0.0, prefer.dot(Vector2(v.x, v.y).normalized()))
			var score = DIRECTION_BIAS * align + (1.0 - DIRECTION_BIAS) * stress_grid[nx][nz]
			candidates.append({"pos": Vector2i(nx, nz), "score": score})
	if candidates.is_empty():
		return false
	candidates.sort_custom(func(a, b): return a["score"] > b["score"])
	var target: Vector2i = candidates[0]["pos"]
	new_grid[target.x][target.y] = CellState.STRESSED
	new_stress[target.x][target.y] = max(new_stress[target.x][target.y], 0.85)
	# update direction memory for the new target
	dir_grid[target.x][target.y] = (Vector2(target.x - x, target.y - z)).normalized()
	return true

# ----------------- Mesh build -----------------
func _update_crack_mesh() -> void:
	var mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var vi := 0

	# visited to avoid retreading
	var visited := {}
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			var key := Vector2i(x, z)
			if grid[x][z] == CellState.CRACKED and not visited.has(key):
				var path: Array = []
				path.append(key)
				visited[key] = true

				# greedy walk following cracked neighbors, prefer straight direction
				var prev := key
				var curr := key
				while true:
					var res := _next_crack_step(curr, prev, visited)
					if not res["found"]:
						break
					var nxt: Vector2i = res["pos"]
					path.append(nxt)
					visited[nxt] = true
					prev = curr
					curr = nxt

				if path.size() > 1:
					for i in range(path.size() - 1):
						var a: Vector2i = path[i]
						var b: Vector2i = path[i + 1]
						vi = _emit_quad_segment(vertices, normals, indices, vi, a, b)

	if vertices.size() > 0:
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		crack_mesh.mesh = mesh
		crack_mesh.material_override = crack_material
	else:
		crack_mesh.mesh = null

# Prefer continuing forward from (prev->curr)
func _next_crack_step(curr: Vector2i, prev: Vector2i, visited: Dictionary) -> Dictionary:
	var best_found := false
	var best_pos := Vector2i.ZERO
	var best_score := -1.0
	var forward := Vector2(curr.x - prev.x, curr.y - prev.y).normalized()

	for v in N8:
		var nx = curr.x + v.x
		var nz = curr.y + v.y
		var p := Vector2i(nx, nz)
		if not _in_bounds(nx, nz):
			continue
		if visited.has(p):
			continue
		if grid[nx][nz] != CellState.CRACKED:
			continue
		var dir := Vector2(v.x, v.y).normalized()
		var align := 0.0
		if forward != Vector2.ZERO:
			align = max(0.0, forward.dot(dir))
		# weight by local stress too (smoother thickness transitions)
		var s = stress_grid[nx][nz]
		var score = 0.7 * align + 0.3 * s
		if score > best_score:
			best_score = score
			best_pos = p
			best_found = true

	return {"found": best_found, "pos": best_pos}

func _emit_quad_segment(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array, start_index: int, p1: Vector2i, p2: Vector2i) -> int:
	var wpos1 := _grid_to_world(p1)
	var wpos2 := _grid_to_world(p2)
	var dir := (wpos2 - wpos1).normalized()
	var perp := Vector3(dir.z, 0.0, -dir.x)

	# width from stress (average)
	var s1 = stress_grid[p1.x][p1.y]
	var s2 = stress_grid[p2.x][p2.y]
	var s_avg = (s1 + s2) * 0.5
	var width = CRACK_WIDTH_BASE + s_avg * CRACK_WIDTH_STRESS_SCALE

	var v0 = wpos1 + perp * width * 0.5
	var v1 = wpos1 - perp * width * 0.5
	var v2 = wpos2 - perp * width * 0.5
	var v3 = wpos2 + perp * width * 0.5

	vertices.push_back(v0)
	vertices.push_back(v1)
	vertices.push_back(v2)
	vertices.push_back(v3)

	normals.push_back(Vector3.UP)
	normals.push_back(Vector3.UP)
	normals.push_back(Vector3.UP)
	normals.push_back(Vector3.UP)

	indices.push_back(start_index + 0)
	indices.push_back(start_index + 1)
	indices.push_back(start_index + 2)
	indices.push_back(start_index + 0)
	indices.push_back(start_index + 2)
	indices.push_back(start_index + 3)

	return start_index + 4

# ----------------- Utilities -----------------
func _grid_to_world(p: Vector2i) -> Vector3:
	var offset := (GRID_SIZE * CELL_SIZE) * 0.5
	return Vector3(float(p.x) * CELL_SIZE - offset + CELL_SIZE * 0.5, -0.02, float(p.y) * CELL_SIZE - offset + CELL_SIZE * 0.5)

func _in_bounds(x: int, z: int) -> bool:
	return x >= 0 and x < GRID_SIZE and z >= 0 and z < GRID_SIZE

func _dup_grid() -> Array:
	var out := []
	out.resize(GRID_SIZE)
	for x in range(GRID_SIZE):
		out[x] = grid[x].duplicate()
	return out

func _dup_stress() -> Array:
	var out := []
	out.resize(GRID_SIZE)
	for x in range(GRID_SIZE):
		out[x] = stress_grid[x].duplicate()
	return out

# ----------------- Public API -----------------
func reset_simulation() -> void:
	_init_arrays()
	_seed_weakness()
	_add_initial_stress_center()
	_mesh_dirty = true

func add_stress_point(world_pos: Vector3, amount: float = 1.0) -> void:
	var gx := int(floor((world_pos.x / CELL_SIZE) + float(GRID_SIZE) * 0.5))
	var gz := int(floor((world_pos.z / CELL_SIZE) + float(GRID_SIZE) * 0.5))
	if _in_bounds(gx, gz):
		stress_grid[gx][gz] = clamp(stress_grid[gx][gz] + amount, 0.0, 1.0)
		if stress_grid[gx][gz] > CRACK_THRESHOLD:
			grid[gx][gz] = CellState.STRESSED
		_mesh_dirty = true

func get_stress_at(world_pos: Vector3) -> float:
	var gx := int(floor((world_pos.x / CELL_SIZE) + float(GRID_SIZE) * 0.5))
	var gz := int(floor((world_pos.z / CELL_SIZE) + float(GRID_SIZE) * 0.5))
	if _in_bounds(gx, gz):
		return stress_grid[gx][gz]
	return 0.0
