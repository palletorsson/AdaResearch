# CrackPropagation.gd
# Attach to a Node3D. Generates, grows and draws 2D crack lines on XZ-plane.
class_name CrackPropagationCA
extends Node3D

# @identity
# essence: Cellular automaton on a 2D stress grid — cells crack when local stress exceeds threshold, propagating fracture to neighbors
# desire: To watch destruction emerge from accumulation: stress builds invisibly, then cracks bloom along paths of least resistance
# critical_parameter: CRACK_THRESHOLD — the breaking point; lower values create dense shatter, higher values yield sparse clean fractures
# triggers: High propagation rate produces explosive branching; direction bias produces river-like cracks; low threshold fragments everything
# emerges: Realistic fracture networks from three cell states and local stress transfer
# needs: Per-frame simulation [has], crack mesh visualization [has], seed control [has], VR interaction [missing]
# relationships: Growth system in biological_growth alongside slimemold, mushrooms, tree_gen. CA-based like cellular_automata_3d_tree.
# truth: A crack does not choose where to go — it reads the stress the material already carries.

# ---------- Simulation parameters ----------
@export var GRID_SIZE: int = 64        # cells per side
@export var CELL_SIZE: float = 0.08    # world meters per cell (~5m total)
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
@export var CRACK_COLOR: Color = Color(1.0, 0.4, 0.1, 1.0)  # warm orange, emissive
@export_range(0.001, 0.5, 0.001) var CRACK_WIDTH_BASE: float = 0.06  # meters — wider for visibility
@export_range(0.0, 1.0, 0.01) var CRACK_WIDTH_STRESS_SCALE: float = 0.25
@export var EMISSIVE: float = 1.8   # glow on crack lines

# ---------- Fracture model (2026-11-10) ----------
# "tips" (default): a crack is a TIP that runs - it advances along its heading until it meets another crack
# (a T-junction) or the edge, now and then splitting. A crack RELIEVES the stress around it, so the next one
# nucleates where the plate is still loaded, away from the old ones; the load keeps rising, so the network
# refines in generations - primary cracks first and widest, then the cracks between them: drying mud, glaze.
# "flood": the original rule. Every cracked cell pushed stress into all eight neighbours and every stressed cell
# cracked with at least 8 % a step, so nothing ever stopped a crack: within seconds every interior cell had
# cracked and the work stood as a solid orange plate (the floor-116 placement showed exactly that).
@export_enum("tips", "flood") var fracture_model: String = "tips"
@export_range(0.0, 0.05, 0.0005) var load_rate: float = 0.002      # far-field load added per step
@export_range(0.1, 1.0, 0.01) var load_max: float = 0.56            # the plate stops loading here
@export_range(2, 24) var relief_radius: int = 9                     # cells a crack relieves around itself
@export_range(0.0, 1.0, 0.01) var relief_strength: float = 0.75     # stress removed beside a crack
@export_range(0.0, 0.2, 0.005) var branch_chance: float = 0.025     # a running tip splits
@export_range(1.0, 60.0, 0.5) var steps_per_second: float = 24.0
@export var cycle: bool = true                                       # settle, hold, then a fresh plate
@export_range(0.0, 60.0, 0.5) var hold_seconds: float = 8.0

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
var _settled_frames := 0

# tips model state
var _weak: PackedFloat32Array        # smooth heterogeneity of the plate
var _relief: PackedFloat32Array      # stress removed by nearby cracks
var _birth: PackedInt32Array         # step a cell cracked (-1 = intact)
var _owner: PackedInt32Array         # which crack a cell belongs to
var _tips: Array = []                # {pos: Vector2i, dir: Vector2, id: int, grace: int}
var _segments: Array = []            # [Vector2i a, Vector2i b] in crack order
var _load := 0.0
var _step_n := 0
var _next_id := 0
var _accum := 0.0
var _hold := 0.0
var _mesh_age := 0.0
var _settled := false
var _kernel: Array = []              # [dx, dz, relief] - the relief disc, built once a plate
var _free_peak := 0.0                # upper bound of (weak - relief) over intact cells; only falls
var _frozen_v := PackedVector3Array()   # quads of cracks that have stopped changing
var _frozen_n := PackedVector3Array()
var _frozen_c := PackedColorArray()
var _frozen_i := PackedInt32Array()
var _frozen_count := 0

# 8-neighborhood offsets
const N8 := [
	Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1),
	Vector2i(-1, 0),                 Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
]

func _ready() -> void:
	if SEED == 0: 
		randomize() 
	else: 
		seed(SEED)
	if fracture_model == "tips":
		_make_crack_mesh()
		_make_ground_surface()
		_tips_reset()
		return

	_init_arrays()
	_seed_weakness()
	_make_crack_mesh()
	_make_ground_surface()
	_add_initial_stress_center()
	# Pre-run simulation steps so cracks are visible immediately
	for i in range(40):
		_step_sim()
	_update_crack_mesh()

func _process(_delta: float) -> void:
	if fracture_model == "tips":
		_tips_process(_delta)
		return
	var changed := _step_sim()
	if changed:
		_mesh_dirty = true
	if _mesh_dirty:
		_update_crack_mesh()
		_mesh_dirty = false
	# Once every interior cell has cracked at full stress, nothing drawn can change
	# again: the mesh reads only cracked cells and their stress, and a cracked cell's
	# neighbours push more stress than decay removes, so it stays clamped at 1.0. The
	# step still re-marked never-drawn border cells, which kept `changed` true and
	# rebuilt an identical mesh every frame (67 ms a frame on a desktop, measured
	# 2026-09-24). Stop there; add_stress_point and reset_simulation start it again.
	# Two settled frames in a row, not one: with non-default decay/propagation a cell
	# that cracked on the first could still thin; the step is monotone and border
	# stress never falls, so a second full-stress frame is a fixed point for any exports.
	if _interior_settled():
		_settled_frames += 1
		if _settled_frames >= 2:
			set_process(false)
	else:
		_settled_frames = 0

func _interior_settled() -> bool:
	for x in range(1, GRID_SIZE - 1):
		for z in range(1, GRID_SIZE - 1):
			if grid[x][z] != CellState.CRACKED or stress_grid[x][z] < 1.0:
				return false
	return true

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
	crack_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	crack_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	crack_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	crack_material.no_depth_test = false
	crack_material.albedo_color = CRACK_COLOR
	crack_material.metallic = 0.0
	crack_material.roughness = 1.0
	crack_material.emission_enabled = true
	crack_material.emission = CRACK_COLOR
	crack_material.emission_energy_multiplier = EMISSIVE

func _make_ground_surface() -> void:
	# Visible ground plane so cracks have context
	var extent: float = GRID_SIZE * CELL_SIZE * 0.5
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(extent * 2.0, extent * 2.0)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.16, 0.14)
	mat.roughness = 0.9
	mat.emission_enabled = true
	mat.emission = Color(0.08, 0.06, 0.05)
	mat.emission_energy_multiplier = 0.3
	ground.material_override = mat
	ground.position.y = -0.03  # slightly below cracks
	add_child(ground)

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

# ----------------- Tips model -----------------
func _ix(x: int, z: int) -> int:
	return x * GRID_SIZE + z

func _effective(x: int, z: int) -> float:
	var i := _ix(x, z)
	return _load + _weak[i] - _relief[i]

func _tips_reset() -> void:
	_init_arrays()
	var n := GRID_SIZE * GRID_SIZE
	_weak = PackedFloat32Array(); _weak.resize(n)
	_relief = PackedFloat32Array(); _relief.resize(n)
	_birth = PackedInt32Array(); _birth.resize(n); _birth.fill(-1)
	_owner = PackedInt32Array(); _owner.resize(n); _owner.fill(-1)
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.07
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			_weak[_ix(x, z)] = 0.12 * (noise.get_noise_2d(x, z) * 0.5 + 0.5) + randf() * 0.05
	_kernel.clear()
	var r := relief_radius
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			var d := sqrt(float(dx * dx + dz * dz))
			if d <= r:
				_kernel.append([dx, dz, relief_strength * (1.0 - d / float(r + 1))])
	_free_peak = 0.0
	for w in _weak:
		_free_peak = maxf(_free_peak, w)
	_tips.clear()
	_segments.clear()
	_frozen_v = PackedVector3Array(); _frozen_n = PackedVector3Array(); _frozen_c = PackedColorArray(); _frozen_i = PackedInt32Array()
	_frozen_count = 0
	_load = CRACK_THRESHOLD - 0.15
	_step_n = 0
	_next_id = 0
	_accum = 0.0
	_hold = 0.0
	_settled = false
	# A few steps up front, so the first crack is already running when the plate is met.
	for i in range(6):
		_tips_step()
	_update_tips_mesh()

func _tips_process(delta: float) -> void:
	if _settled:
		if not cycle:
			set_process(false)
			return
		_hold += delta
		if _hold >= hold_seconds:
			_tips_reset()
		return
	_accum += delta
	var stepped := false
	var guard := 0
	while _accum >= 1.0 / steps_per_second and guard < 4:
		_accum -= 1.0 / steps_per_second
		_tips_step()
		stepped = true
		guard += 1
	_accum = minf(_accum, 1.0 / steps_per_second)
	_mesh_age += delta
	if stepped and _mesh_age >= 0.2:
		_mesh_age = 0.0
		_update_tips_mesh()
	if _tips.is_empty() and _load >= load_max:
		_settled = true
		_update_tips_mesh()

func _crack_cell(c: Vector2i, id: int) -> void:
	var i := _ix(c.x, c.y)
	grid[c.x][c.y] = CellState.CRACKED
	_birth[i] = _step_n
	_owner[i] = id
	# The crack carries no stress across itself: relieve a disc around the new cell.
	for kv in _kernel:
		var nx: int = c.x + kv[0]
		var nz: int = c.y + kv[1]
		if nx < 0 or nz < 0 or nx >= GRID_SIZE or nz >= GRID_SIZE:
			continue
		var k := nx * GRID_SIZE + nz
		if _relief[k] < kv[2]:
			_relief[k] = kv[2]

func _tips_step() -> void:
	_step_n += 1
	_load = minf(load_max, _load + load_rate)
	# Nucleate: the most loaded intact cell breaks once it passes the threshold (at most one new crack a step).
	# The scan runs only when a crack CAN start: relief only grows and cells only crack, so the last scan's peak
	# of (weak - relief) is an upper bound until the next one.
	if _tips.size() < 6 and _load + _free_peak > CRACK_THRESHOLD:
		var best := Vector2i(-1, -1)
		var best_free := -INF
		for x in range(2, GRID_SIZE - 2):
			var row: Array = grid[x]
			for z in range(2, GRID_SIZE - 2):
				if row[z] == CellState.CRACKED:
					continue
				var k := x * GRID_SIZE + z
				var free := _weak[k] - _relief[k]
				if free > best_free:
					best_free = free
					best = Vector2i(x, z)
		_free_peak = best_free
		if best.x >= 0 and _load + best_free > CRACK_THRESHOLD:
			var id := _next_id
			_next_id += 1
			_crack_cell(best, id)
			var a := randf() * TAU
			var heading := Vector2(cos(a), sin(a))
			_tips.append({"pos": best, "dir": heading, "id": id, "grace": 0})
			_tips.append({"pos": best, "dir": -heading, "id": id, "grace": 0})
	# Advance every tip one cell.
	var survivors: Array = []
	var born: Array = []
	for tip in _tips:
		var pos: Vector2i = tip.pos
		var heading: Vector2 = tip.dir
		var target := Vector2i(-1, -1)
		var found := false
		var best_score := -INF
		for v in N8:
			var n: Vector2i = pos + v
			var step := Vector2(v.x, v.y).normalized()
			var align := heading.dot(step)
			if align < 0.35:
				continue
			var score := DIRECTION_BIAS * align + randf() * 0.35
			if _in_bounds(n.x, n.y):
				if grid[n.x][n.y] == CellState.CRACKED:
					if _owner[_ix(n.x, n.y)] == tip.id and tip.grace > 0:
						continue
					score += 0.6   # a running crack is drawn to the free surface of another
				else:
					score += (1.0 - DIRECTION_BIAS) * clampf(_effective(n.x, n.y), 0.0, 1.0)
			if score > best_score:
				best_score = score
				target = n
				found = true
		if not found:
			continue
		if not _in_bounds(target.x, target.y):
			continue   # ran off the plate
		_segments.append([pos, target])
		if grid[target.x][target.y] == CellState.CRACKED:
			continue   # met another crack: a T-junction, the tip stops
		_crack_cell(target, tip.id)
		var moved := Vector2(target - pos).normalized()
		tip.dir = (heading * 0.85 + moved * 0.15).normalized()
		tip.pos = target
		tip.grace = maxi(0, tip.grace - 1)
		survivors.append(tip)
		if randf() < branch_chance:
			var turn := deg_to_rad(randf_range(40.0, 65.0)) * (1.0 if randf() < 0.5 else -1.0)
			born.append({"pos": target, "dir": tip.dir.rotated(turn), "id": tip.id, "grace": 4})
	_tips = survivors + born

func _update_tips_mesh() -> void:
	# A crack's width and colour settle 90 steps after it opens; from then on its quad never changes, so it is
	# kept in the frozen arrays and only the young cracks are rebuilt.
	while _frozen_count < _segments.size() and _segment_age(_segments[_frozen_count]) >= 90.0:
		_emit_segment(_segments[_frozen_count], 90.0, _frozen_v, _frozen_n, _frozen_c, _frozen_i)
		_frozen_count += 1
	var vertices := _frozen_v.duplicate()
	var normals := _frozen_n.duplicate()
	var colors := _frozen_c.duplicate()
	var indices := _frozen_i.duplicate()
	for k in range(_frozen_count, _segments.size()):
		_emit_segment(_segments[k], _segment_age(_segments[k]), vertices, normals, colors, indices)
	if vertices.is_empty():
		crack_mesh.mesh = null
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	crack_mesh.mesh = mesh
	crack_material.vertex_color_use_as_albedo = true
	crack_material.vertex_color_is_srgb = true
	crack_material.albedo_color = Color.WHITE
	crack_material.emission_enabled = false
	crack_mesh.material_override = crack_material
	crack_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # a crack is IN the plate, not over it

func _segment_age(seg: Array) -> float:
	var a: Vector2i = seg[0]
	var b: Vector2i = seg[1]
	return float(_step_n - maxi(_birth[_ix(a.x, a.y)], _birth[_ix(b.x, b.y)]))

func _emit_segment(seg: Array, age: float, vertices: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, indices: PackedInt32Array) -> void:
	# Older cracks have opened wider and cooled: the generations read in the width and the colour.
	var t := clampf(age / 90.0, 0.0, 1.0)
	var width := CRACK_WIDTH_BASE * (0.3 + 0.7 * t)
	var col := Color(1.0, 0.93, 0.7).lerp(CRACK_COLOR, clampf(age / 24.0, 0.0, 1.0))
	var w1 := _grid_to_world(seg[0])
	var w2 := _grid_to_world(seg[1])
	var dir := (w2 - w1).normalized()
	var perp := Vector3(dir.z, 0.0, -dir.x) * width * 0.5
	# Run each quad half a width past its ends, so bends and junctions close.
	w1 -= dir * width * 0.5
	w2 += dir * width * 0.5
	var i0 := vertices.size()
	vertices.append_array([w1 + perp, w1 - perp, w2 - perp, w2 + perp])
	normals.append_array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	colors.append_array([col, col, col, col])
	indices.append_array([i0, i0 + 1, i0 + 2, i0, i0 + 2, i0 + 3])

# ----------------- Utilities -----------------
func _grid_to_world(p: Vector2i) -> Vector3:
	var offset := (GRID_SIZE * CELL_SIZE) * 0.5
	return Vector3(float(p.x) * CELL_SIZE - offset + CELL_SIZE * 0.5, 0.05, float(p.y) * CELL_SIZE - offset + CELL_SIZE * 0.5)

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
	if fracture_model == "tips":
		_tips_reset()
		set_process(true)
		return
	_init_arrays()
	_seed_weakness()
	_add_initial_stress_center()
	_mesh_dirty = true
	_settled_frames = 0
	set_process(true)

func add_stress_point(world_pos: Vector3, amount: float = 1.0) -> void:
	var gx := int(floor((world_pos.x / CELL_SIZE) + float(GRID_SIZE) * 0.5))
	var gz := int(floor((world_pos.z / CELL_SIZE) + float(GRID_SIZE) * 0.5))
	if fracture_model == "tips" and _in_bounds(gx, gz):
		# A blow weakens the plate there: the next crack starts at it.
		for dx in range(-2, 3):
			for dz in range(-2, 3):
				if _in_bounds(gx + dx, gz + dz):
					_weak[_ix(gx + dx, gz + dz)] += amount * 0.5 / (1.0 + dx * dx + dz * dz)
		_settled = false
		_hold = 0.0
		set_process(true)
		return
	if _in_bounds(gx, gz):
		stress_grid[gx][gz] = clamp(stress_grid[gx][gz] + amount, 0.0, 1.0)
		if stress_grid[gx][gz] > CRACK_THRESHOLD:
			grid[gx][gz] = CellState.STRESSED
		_mesh_dirty = true
		_settled_frames = 0
		set_process(true)

func get_stress_at(world_pos: Vector3) -> float:
	var gx := int(floor((world_pos.x / CELL_SIZE) + float(GRID_SIZE) * 0.5))
	var gz := int(floor((world_pos.z / CELL_SIZE) + float(GRID_SIZE) * 0.5))
	if _in_bounds(gx, gz):
		return stress_grid[gx][gz]
	return 0.0

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("fracture_model") and str(config.fracture_model) in ["tips", "flood"]:
		fracture_model = str(config.fracture_model)
	if config.has("seed"):
		SEED = int(config.seed)
	if config.has("cycle"):
		cycle = str(config.cycle).to_lower() in ["true", "1", "on"]
