# ===========================================================================
# ForestCompetition - L-System Forest Ecosystem with Nutrient Diffusion
# Implementation: AI-assisted GDScript, 2025
#
# Multiple L-System trees competing for nutrients in a shared soil grid.
# Features: nutrient diffusion, allometric scaling, seasonal growth cycles.
# License: CC BY-NC-SA 3.0
# ===========================================================================
#
# @identity
# essence: tree.dbh += nutrients * season * strategy * health; nutrients diffuse and deplete — competitive growth on shared soil
# desire: To grow a forest where trees compete — watch aggressive species starve neighbors, conservative ones endure winters
# critical_parameter: nutrient_supply vs competition_radius — together they determine whether the forest is cooperative or cutthroat
# triggers: Spring → growth burst; Winter → dormancy; aggressive strategy → fast growth but resource depletion; crown overlap → health decline
# emerges: Ecosystem dynamics from individual L-system trees sharing a diffusing nutrient grid — ecology from grammar
# needs: VR diffusion/nutrients/speed/trees controllers [has], Label3D [has], health graph [has]
# relationships: Central to LSystems_Competition. Extends lsystem_tree (single tree → competing forest). Uses allometric power laws.
# truth: Competition emerges when grammars share resources — ecology is grammar plus scarcity.

extends Node3D

## Forest Competition Ecosystem
## L-System organisms competing for soil nutrients with realistic scaling
## Chapter: L-Systems (Ecosystem & Interaction)

@export var num_trees: int = 5
@export var tree_generations: int = 5
@export var forest_radius: float = 2.5
@export var growth_delay: float = 1.5
@export var diffusion_rate: float = 0.15
@export var nutrient_supply: float = 0.6
@export var season_speed: float = 0.3
@export var competition_radius: float = 1.2

# --- Constants ---
const GRID_RES := 20          # nutrient grid cells per axis
const GRID_EXTENT := 3.5      # world-space half-size of nutrient grid
const CELL_SIZE := (GRID_EXTENT * 2.0) / GRID_RES

# Season enum
enum Season { SPRING, SUMMER, AUTUMN, WINTER }

# Tree strategy enum
enum Strategy { TALL_SPARSE, WIDE_DENSE, BALANCED, AGGRESSIVE, CONSERVATIVE }

# --- Tree inner class ---
class EcoTree:
	var position: Vector3
	var strategy: int
	var color: Color
	var generation: int = 0
	var health: float = 1.0
	var dbh: float = 0.02         # diameter at breast height (meters)
	var trunk_height: float = 0.0
	var crown_radius: float = 0.0
	var biomass: float = 0.0
	var growth_rate_mult: float = 1.0
	var segments: Array = []      # [start, end, depth, thickness, perp]
	var max_depth: int = 0
	var lsystem = null
	var nutrient_uptake: float = 0.0  # how much it took this step

# --- State ---
var _trees: Array = []
var _nutrient_grid: Array = []   # GRID_RES x GRID_RES floats
var _season_time: float = 0.0
var _current_season: int = Season.SPRING
var _step_timer: float = 0.0
var _current_grow_idx: int = 0
var _growing: bool = false
var _year: int = 1

# --- Rendering ---
var _tree_im: ImmediateMesh
var _tree_mi: MeshInstance3D
var _tree_mat: StandardMaterial3D

var _soil_im: ImmediateMesh
var _soil_mi: MeshInstance3D
var _soil_mat: StandardMaterial3D

var _graph_im: ImmediateMesh
var _graph_mi: MeshInstance3D
var _graph_mat: StandardMaterial3D

# --- Labels ---
var _title_label: Label3D
var _stats_label: Label3D
var _season_label: Label3D

# --- VR Sliders ---
const CTRL_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
var _diffusion_ctrl: Node3D
var _supply_ctrl: Node3D
var _speed_ctrl: Node3D
var _trees_ctrl: Node3D

# --- History for graph ---
var _health_history: Array = []  # per-tree arrays of health over time
const MAX_HISTORY := 60

# --- Season palette ---
const SEASON_NAMES := ["Spring", "Summer", "Autumn", "Winter"]
const SEASON_COLORS: Array = [
	Color(0.5, 0.9, 0.5),   # spring - bright green
	Color(0.2, 0.7, 0.3),   # summer - deep green
	Color(0.9, 0.6, 0.2),   # autumn - orange
	Color(0.6, 0.65, 0.75), # winter - blue-grey
]

# ===== READY =====
func _ready() -> void:
	_init_nutrient_grid()
	_init_rendering()
	_init_labels()
	_init_controllers()
	_setup_forest()
	_growing = true
	_rebuild_soil()
	_rebuild_trees()
	_update_labels()

# ===== NUTRIENT GRID =====
func _init_nutrient_grid() -> void:
	_nutrient_grid.resize(GRID_RES)
	for y in GRID_RES:
		var row := []
		row.resize(GRID_RES)
		for x in GRID_RES:
			row[x] = nutrient_supply
		_nutrient_grid[y] = row

func _diffuse_nutrients(delta: float) -> void:
	# Simple discrete diffusion: each cell averages with neighbors
	var rate := diffusion_rate * delta * 4.0
	var tmp := []
	tmp.resize(GRID_RES)
	for y in GRID_RES:
		var row := []
		row.resize(GRID_RES)
		for x in GRID_RES:
			var val: float = _nutrient_grid[y][x]
			var avg := 0.0
			var n := 0
			if x > 0:
				avg += _nutrient_grid[y][x - 1]; n += 1
			if x < GRID_RES - 1:
				avg += _nutrient_grid[y][x + 1]; n += 1
			if y > 0:
				avg += _nutrient_grid[y - 1][x]; n += 1
			if y < GRID_RES - 1:
				avg += _nutrient_grid[y + 1][x]; n += 1
			if n > 0:
				avg /= float(n)
			row[x] = lerpf(val, avg, clampf(rate, 0.0, 0.5))
		tmp[y] = row
	_nutrient_grid = tmp

func _replenish_nutrients(delta: float) -> void:
	# Slow replenishment toward nutrient_supply, faster in spring/summer
	var season_mult := 1.0
	match _current_season:
		Season.SPRING: season_mult = 1.5
		Season.SUMMER: season_mult = 1.0
		Season.AUTUMN: season_mult = 0.5
		Season.WINTER: season_mult = 0.2
	var rate := 0.1 * season_mult * delta
	for y in GRID_RES:
		for x in GRID_RES:
			_nutrient_grid[y][x] = lerpf(_nutrient_grid[y][x], nutrient_supply, rate)

func _world_to_grid(world_pos: Vector3) -> Vector2i:
	var gx := int(clampf((world_pos.x + GRID_EXTENT) / CELL_SIZE, 0, GRID_RES - 1))
	var gy := int(clampf((world_pos.z + GRID_EXTENT) / CELL_SIZE, 0, GRID_RES - 1))
	return Vector2i(gx, gy)

func _consume_nutrients(tree: EcoTree) -> float:
	var gc := _world_to_grid(tree.position)
	var uptake := 0.0
	# Consume from a small radius around tree
	var radius_cells := int(ceil(tree.crown_radius / CELL_SIZE)) + 1
	radius_cells = clampi(radius_cells, 1, 4)
	var count := 0
	for dy in range(-radius_cells, radius_cells + 1):
		for dx in range(-radius_cells, radius_cells + 1):
			var cx := gc.x + dx
			var cy := gc.y + dy
			if cx >= 0 and cx < GRID_RES and cy >= 0 and cy < GRID_RES:
				var take := minf(_nutrient_grid[cy][cx] * 0.15 * tree.growth_rate_mult, _nutrient_grid[cy][cx])
				_nutrient_grid[cy][cx] -= take
				uptake += take
				count += 1
	tree.nutrient_uptake = uptake
	return uptake

# ===== ALLOMETRIC SCALING =====
func _update_allometry(tree: EcoTree) -> void:
	# Power-law scaling: height ~ dbh^0.67, crown ~ dbh^0.5
	tree.trunk_height = 0.3 + pow(tree.dbh, 0.67) * 8.0
	tree.crown_radius = 0.1 + pow(tree.dbh, 0.5) * 1.5
	tree.biomass = PI * (tree.dbh * 0.5) * (tree.dbh * 0.5) * tree.trunk_height * 0.5

func _grow_dbh(tree: EcoTree, nutrient_available: float) -> void:
	# Growth rate depends on nutrients, season, strategy
	var season_mult := 0.0
	match _current_season:
		Season.SPRING: season_mult = 1.2
		Season.SUMMER: season_mult = 1.0
		Season.AUTUMN: season_mult = 0.3
		Season.WINTER: season_mult = 0.0
	if season_mult <= 0.0:
		return
	var growth := 0.005 * nutrient_available * season_mult * tree.growth_rate_mult * tree.health
	tree.dbh += growth
	_update_allometry(tree)

# ===== SEASONAL CYCLE =====
func _advance_season(delta: float) -> void:
	_season_time += delta * season_speed
	var old_season := _current_season
	_current_season = int(fmod(_season_time, 4.0))
	if _current_season < old_season:
		_year += 1

# ===== FOREST SETUP =====
func _setup_forest() -> void:
	for child in get_children():
		if child is Turtle3D:
			child.queue_free()
	_trees.clear()
	_health_history.clear()

	var LSystemClass = load("res://utils/lsystem.gd")

	for i in num_trees:
		var tree := EcoTree.new()
		var angle := (TAU / num_trees) * i + randf() * 0.3
		var dist := randf_range(0.8, forest_radius)
		tree.position = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		tree.strategy = i % 5
		tree.color = _strategy_color(tree.strategy)

		# Allometric init
		tree.dbh = randf_range(0.015, 0.03)
		_update_allometry(tree)

		# Growth rate by strategy
		match tree.strategy:
			Strategy.AGGRESSIVE: tree.growth_rate_mult = 1.5
			Strategy.CONSERVATIVE: tree.growth_rate_mult = 0.7
			Strategy.TALL_SPARSE: tree.growth_rate_mult = 1.1
			Strategy.WIDE_DENSE: tree.growth_rate_mult = 0.9
			_: tree.growth_rate_mult = 1.0

		# L-system
		tree.lsystem = _create_lsystem(tree.strategy, LSystemClass)

		_trees.append(tree)
		_health_history.append([])

func _strategy_color(strategy: int) -> Color:
	match strategy:
		Strategy.TALL_SPARSE: return Color(0.15, 0.55, 0.25)
		Strategy.WIDE_DENSE: return Color(0.3, 0.75, 0.4)
		Strategy.BALANCED: return Color(0.25, 0.65, 0.35)
		Strategy.AGGRESSIVE: return Color(0.75, 0.35, 0.25)
		Strategy.CONSERVATIVE: return Color(0.4, 0.55, 0.65)
		_: return Color(0.3, 0.6, 0.3)

func _create_lsystem(strategy: int, cls) -> RefCounted:
	var lsys: RefCounted
	match strategy:
		Strategy.TALL_SPARSE:
			lsys = cls.new("X")
			lsys.add_rule("X", "F[+X]F[-X]+X")
			lsys.add_rule("F", "FF")
		Strategy.WIDE_DENSE:
			lsys = cls.new("F")
			lsys.add_rule("F", "F[+F]F[-F][F]")
		Strategy.BALANCED:
			lsys = cls.create_fractal_plant()
		Strategy.AGGRESSIVE:
			lsys = cls.create_bush()
		Strategy.CONSERVATIVE:
			lsys = cls.create_tree()
		_:
			lsys = cls.create_plant()
	return lsys

# ===== INTERPRET L-SYSTEM INTO SEGMENTS =====
func _interpret_tree(tree: EcoTree) -> void:
	tree.segments.clear()
	tree.max_depth = 0
	var sentence: String = tree.lsystem.get_sentence()
	if sentence.is_empty():
		return

	var base_len: float = 0.08 * (tree.trunk_height / 2.0)
	var base_thick: float = tree.dbh * 0.5
	var turn_angle: float = 25.0

	# Allometric: taller trees have wider angles
	match tree.strategy:
		Strategy.WIDE_DENSE: turn_angle = 35.0
		Strategy.TALL_SPARSE: turn_angle = 18.0
		Strategy.AGGRESSIVE: turn_angle = 30.0
		Strategy.CONSERVATIVE: turn_angle = 22.0

	var pos := tree.position + Vector3(0, 0.01, 0)
	var dir := Vector3.UP
	var right := Vector3.RIGHT
	var depth := 0
	var cur_len := base_len
	var cur_thick := base_thick
	var stack := []

	for ch in sentence:
		match ch:
			"F", "G":
				var end_pos := pos + dir * cur_len
				var perp := dir.cross(right)
				if perp.length_squared() < 0.001:
					perp = dir.cross(Vector3.FORWARD)
				perp = perp.normalized()
				tree.segments.append([pos, end_pos, depth, cur_thick, perp])
				pos = end_pos
			"f":
				pos += dir * cur_len
			"+":
				var axis := dir.cross(right).normalized()
				if axis.length_squared() < 0.001:
					axis = Vector3.FORWARD
				dir = dir.rotated(axis, deg_to_rad(turn_angle))
				right = right.rotated(axis, deg_to_rad(turn_angle))
			"-":
				var axis := dir.cross(right).normalized()
				if axis.length_squared() < 0.001:
					axis = Vector3.FORWARD
				dir = dir.rotated(axis, deg_to_rad(-turn_angle))
				right = right.rotated(axis, deg_to_rad(-turn_angle))
			"[":
				stack.append([pos, dir, right, depth, cur_len, cur_thick])
				depth += 1
				cur_len *= 0.75
				cur_thick *= 0.6
				if depth > tree.max_depth:
					tree.max_depth = depth
			"]":
				if stack.size() > 0:
					var s = stack.pop_back()
					pos = s[0]; dir = s[1]; right = s[2]
					depth = s[3]; cur_len = s[4]; cur_thick = s[5]

# ===== COMPETITION =====
func _apply_competition() -> void:
	for i in _trees.size():
		var tree := _trees[i] as EcoTree
		var crowding := 0.0
		for j in _trees.size():
			if i == j:
				continue
			var other := _trees[j] as EcoTree
			var dist := tree.position.distance_to(other.position)
			if dist < competition_radius:
				# Crown overlap competition
				var overlap := maxf(0.0, (tree.crown_radius + other.crown_radius) - dist)
				crowding += overlap * other.biomass * 0.3
		tree.health = clampf(tree.health - crowding * 0.02 + 0.005, 0.05, 1.0)

# ===== GROWTH STEP =====
func _grow_step() -> void:
	if _current_grow_idx >= _trees.size():
		_current_grow_idx = 0

	var tree := _trees[_current_grow_idx] as EcoTree
	if tree.generation < tree_generations and tree.health > 0.1:
		# Consume nutrients
		var nutrients := _consume_nutrients(tree)
		_grow_dbh(tree, nutrients)

		# Only produce new L-system generation if enough nutrients and right season
		if nutrients > 0.05 and _current_season != Season.WINTER:
			tree.lsystem.generate()
			tree.generation += 1

		_apply_competition()
		_interpret_tree(tree)

	# Record health
	if _current_grow_idx < _health_history.size():
		var hist: Array = _health_history[_current_grow_idx]
		hist.append(tree.health)
		if hist.size() > MAX_HISTORY:
			hist.pop_front()

	_current_grow_idx += 1

	# Check if all done
	var any_can_grow := false
	for t in _trees:
		if t.generation < tree_generations and t.health > 0.1:
			any_can_grow = true
			break
	if not any_can_grow:
		_growing = false

# ===== PROCESS =====
func _process(delta: float) -> void:
	_advance_season(delta)
	_diffuse_nutrients(delta)
	_replenish_nutrients(delta)

	if _growing:
		_step_timer += delta
		if _step_timer >= growth_delay:
			_step_timer = 0.0
			_grow_step()
			_rebuild_trees()
			_update_labels()

	_rebuild_soil()
	_rebuild_graph()

# ===== RENDERING: INIT =====
func _init_rendering() -> void:
	# Tree mesh
	_tree_im = ImmediateMesh.new()
	_tree_mi = MeshInstance3D.new()
	_tree_mi.mesh = _tree_im
	_tree_mat = StandardMaterial3D.new()
	_tree_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tree_mat.vertex_color_use_as_albedo = true
	_tree_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_tree_mi.material_override = _tree_mat
	add_child(_tree_mi)

	# Soil mesh (nutrient grid)
	_soil_im = ImmediateMesh.new()
	_soil_mi = MeshInstance3D.new()
	_soil_mi.mesh = _soil_im
	_soil_mat = StandardMaterial3D.new()
	_soil_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_soil_mat.vertex_color_use_as_albedo = true
	_soil_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_soil_mi.material_override = _soil_mat
	add_child(_soil_mi)

	# Graph mesh (health history)
	_graph_im = ImmediateMesh.new()
	_graph_mi = MeshInstance3D.new()
	_graph_mi.mesh = _graph_im
	_graph_mat = StandardMaterial3D.new()
	_graph_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_graph_mat.vertex_color_use_as_albedo = true
	_graph_mi.material_override = _graph_mat
	add_child(_graph_mi)

# ===== RENDERING: SOIL =====
func _rebuild_soil() -> void:
	_soil_im.clear_surfaces()
	_soil_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var y_off := -0.01
	for gy in GRID_RES:
		for gx in GRID_RES:
			var val: float = clampf(_nutrient_grid[gy][gx], 0.0, 1.0)
			# Color: dark brown (depleted) → rich green (nutrient-rich)
			var col := Color(0.25 + 0.15 * (1.0 - val), 0.15 + 0.5 * val, 0.1 + 0.1 * val, 0.6)
			var x0 := -GRID_EXTENT + gx * CELL_SIZE
			var z0 := -GRID_EXTENT + gy * CELL_SIZE
			var x1 := x0 + CELL_SIZE
			var z1 := z0 + CELL_SIZE
			# Two triangles per cell
			_soil_im.surface_set_color(col)
			_soil_im.surface_add_vertex(Vector3(x0, y_off, z0))
			_soil_im.surface_set_color(col)
			_soil_im.surface_add_vertex(Vector3(x1, y_off, z0))
			_soil_im.surface_set_color(col)
			_soil_im.surface_add_vertex(Vector3(x1, y_off, z1))
			_soil_im.surface_set_color(col)
			_soil_im.surface_add_vertex(Vector3(x0, y_off, z0))
			_soil_im.surface_set_color(col)
			_soil_im.surface_add_vertex(Vector3(x1, y_off, z1))
			_soil_im.surface_set_color(col)
			_soil_im.surface_add_vertex(Vector3(x0, y_off, z1))
	_soil_im.surface_end()

# ===== RENDERING: TREES =====
func _rebuild_trees() -> void:
	_tree_im.clear_surfaces()
	_tree_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for tree in _trees:
		var t: EcoTree = tree as EcoTree
		if t.segments.is_empty():
			continue
		var season_hue := _season_leaf_color(t)
		for seg in t.segments:
			var start: Vector3 = seg[0]
			var end_pos: Vector3 = seg[1]
			var depth: int = seg[2]
			var thick: float = seg[3]
			var perp: Vector3 = seg[4]
			# Color: trunk at depth 0, blending to leaf color at max depth
			var frac := 0.0
			if t.max_depth > 0:
				frac = float(depth) / float(t.max_depth)
			var trunk_col := Color(0.45, 0.3, 0.2).lerp(t.color, 0.3)
			var col := trunk_col.lerp(season_hue, frac * 0.8)
			# Health tint
			col = col.lerp(Color(0.35, 0.25, 0.15), 1.0 - t.health)
			# Cross-quad rendering (two perpendicular quads)
			_add_branch_quad(start, end_pos, perp, thick, col)
			var perp2 := perp.cross((end_pos - start).normalized()).normalized()
			if perp2.length_squared() > 0.001:
				_add_branch_quad(start, end_pos, perp2, thick, col)
	_tree_im.surface_end()

func _season_leaf_color(tree: EcoTree) -> Color:
	var base := tree.color
	match _current_season:
		Season.SPRING:
			return base.lerp(Color(0.5, 0.9, 0.4), 0.4)
		Season.SUMMER:
			return base
		Season.AUTUMN:
			return base.lerp(Color(0.9, 0.5, 0.15), 0.6)
		Season.WINTER:
			return base.lerp(Color(0.5, 0.45, 0.4), 0.7)
		_:
			return base

func _add_branch_quad(start: Vector3, end_pos: Vector3, perp: Vector3, thick: float, col: Color) -> void:
	var half := perp * thick
	var a := start - half
	var b := start + half
	var c := end_pos + half * 0.7  # taper
	var d := end_pos - half * 0.7
	_tree_im.surface_set_color(col)
	_tree_im.surface_add_vertex(a)
	_tree_im.surface_set_color(col)
	_tree_im.surface_add_vertex(b)
	_tree_im.surface_set_color(col)
	_tree_im.surface_add_vertex(c)
	_tree_im.surface_set_color(col)
	_tree_im.surface_add_vertex(a)
	_tree_im.surface_set_color(col)
	_tree_im.surface_add_vertex(c)
	_tree_im.surface_set_color(col)
	_tree_im.surface_add_vertex(d)

# ===== RENDERING: HEALTH GRAPH =====
func _rebuild_graph() -> void:
	_graph_im.clear_surfaces()
	if _health_history.is_empty():
		return
	_graph_im.surface_begin(Mesh.PRIMITIVE_LINES)
	var graph_origin := Vector3(-3.5, 0.5, -3.5)
	var graph_w := 2.0
	var graph_h := 1.0
	# Axes
	_graph_im.surface_set_color(Color(0.5, 0.5, 0.5))
	_graph_im.surface_add_vertex(graph_origin)
	_graph_im.surface_set_color(Color(0.5, 0.5, 0.5))
	_graph_im.surface_add_vertex(graph_origin + Vector3(graph_w, 0, 0))
	_graph_im.surface_set_color(Color(0.5, 0.5, 0.5))
	_graph_im.surface_add_vertex(graph_origin)
	_graph_im.surface_set_color(Color(0.5, 0.5, 0.5))
	_graph_im.surface_add_vertex(graph_origin + Vector3(0, graph_h, 0))
	# Per-tree health lines
	for ti in _health_history.size():
		var hist: Array = _health_history[ti]
		if hist.size() < 2:
			continue
		var col: Color = _trees[ti].color if ti < _trees.size() else Color.WHITE
		for hi in range(1, hist.size()):
			var x0 := graph_origin.x + (float(hi - 1) / MAX_HISTORY) * graph_w
			var x1 := graph_origin.x + (float(hi) / MAX_HISTORY) * graph_w
			var y0 := graph_origin.y + float(hist[hi - 1]) * graph_h
			var y1 := graph_origin.y + float(hist[hi]) * graph_h
			_graph_im.surface_set_color(col)
			_graph_im.surface_add_vertex(Vector3(x0, y0, graph_origin.z))
			_graph_im.surface_set_color(col)
			_graph_im.surface_add_vertex(Vector3(x1, y1, graph_origin.z))
	_graph_im.surface_end()

# ===== LABELS =====
func _init_labels() -> void:
	_title_label = Label3D.new()
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.font_size = 28
	_title_label.outline_size = 4
	_title_label.modulate = Color(0.3, 0.9, 0.4)
	_title_label.position = Vector3(0, 3.5, 0)
	add_child(_title_label)

	_stats_label = Label3D.new()
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stats_label.font_size = 20
	_stats_label.outline_size = 3
	_stats_label.modulate = Color(0.7, 0.85, 0.6)
	_stats_label.position = Vector3(0, 3.0, 0)
	_stats_label.width = 900.0
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_stats_label)

	_season_label = Label3D.new()
	_season_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_season_label.font_size = 24
	_season_label.outline_size = 4
	_season_label.position = Vector3(0, 2.6, 0)
	add_child(_season_label)

func _update_labels() -> void:
	if _title_label:
		var total_seg := 0
		for t in _trees:
			total_seg += t.segments.size()
		_title_label.text = "Forest Ecosystem\nTrees: %d | Segments: %d" % [_trees.size(), total_seg]

	if _stats_label:
		var avg_h := _avg_health()
		var avg_dbh := 0.0
		for t in _trees:
			avg_dbh += t.dbh
		if _trees.size() > 0:
			avg_dbh /= _trees.size()
		var status := "Growing..." if _growing else "Stable"
		_stats_label.text = "Status: %s | Avg Health: %.0f%% | Avg DBH: %.1f cm" % [
			status, avg_h * 100.0, avg_dbh * 100.0
		]

	if _season_label:
		var s_name: String = SEASON_NAMES[_current_season] if _current_season < 4 else "?"
		_season_label.modulate = SEASON_COLORS[_current_season] if _current_season < 4 else Color.WHITE
		_season_label.text = "%s — Year %d" % [s_name, _year]

func _avg_health() -> float:
	var total := 0.0
	for t in _trees:
		total += t.health
	return total / maxf(1.0, _trees.size())

# ===== VR CONTROLLERS =====
func _init_controllers() -> void:
	var cx := 3.8
	var cz := -1.0
	var cy := 0.8

	_diffusion_ctrl = CTRL_SCENE.instantiate()
	_diffusion_ctrl.parameter_name = "Diffusion"
	_diffusion_ctrl.min_value = 0.0
	_diffusion_ctrl.max_value = 0.5
	_diffusion_ctrl.default_value = diffusion_rate
	_diffusion_ctrl.step_size = 0.01
	_diffusion_ctrl.position = Vector3(cx, cy, cz)
	_diffusion_ctrl.value_changed.connect(func(v: float) -> void: diffusion_rate = v)
	add_child(_diffusion_ctrl)

	_supply_ctrl = CTRL_SCENE.instantiate()
	_supply_ctrl.parameter_name = "Nutrients"
	_supply_ctrl.min_value = 0.1
	_supply_ctrl.max_value = 1.0
	_supply_ctrl.default_value = nutrient_supply
	_supply_ctrl.step_size = 0.05
	_supply_ctrl.position = Vector3(cx, cy + 0.25, cz)
	_supply_ctrl.value_changed.connect(func(v: float) -> void: nutrient_supply = v)
	add_child(_supply_ctrl)

	_speed_ctrl = CTRL_SCENE.instantiate()
	_speed_ctrl.parameter_name = "Season Speed"
	_speed_ctrl.min_value = 0.05
	_speed_ctrl.max_value = 1.0
	_speed_ctrl.default_value = season_speed
	_speed_ctrl.step_size = 0.05
	_speed_ctrl.position = Vector3(cx, cy + 0.5, cz)
	_speed_ctrl.value_changed.connect(func(v: float) -> void: season_speed = v)
	add_child(_speed_ctrl)

	_trees_ctrl = CTRL_SCENE.instantiate()
	_trees_ctrl.parameter_name = "Trees"
	_trees_ctrl.min_value = 2.0
	_trees_ctrl.max_value = 10.0
	_trees_ctrl.default_value = float(num_trees)
	_trees_ctrl.step_size = 1.0
	_trees_ctrl.position = Vector3(cx, cy + 0.75, cz)
	_trees_ctrl.value_changed.connect(_on_trees_changed)
	add_child(_trees_ctrl)

func _on_trees_changed(v: float) -> void:
	var new_count := int(v)
	if new_count != num_trees:
		num_trees = new_count
		_restart()

# ===== RESTART =====
func _restart() -> void:
	_init_nutrient_grid()
	_setup_forest()
	_growing = true
	_step_timer = 0.0
	_current_grow_idx = 0
	_season_time = 0.0
	_current_season = Season.SPRING
	_year = 1
	_rebuild_soil()
	_rebuild_trees()
	_update_labels()

# ===== STRATEGY NAME =====
func _strategy_name(strategy: int) -> String:
	match strategy:
		Strategy.TALL_SPARSE: return "Tall"
		Strategy.WIDE_DENSE: return "Wide"
		Strategy.BALANCED: return "Balanced"
		Strategy.AGGRESSIVE: return "Aggressive"
		Strategy.CONSERVATIVE: return "Conservative"
		_: return "?"

# ===== GRID CONFIG =====
func apply_grid_config(config: Dictionary) -> void:
	if config.has("num_trees"):
		num_trees = clampi(int(config["num_trees"]), 2, 10)
	if config.has("tree_generations"):
		tree_generations = clampi(int(config["tree_generations"]), 2, 7)
	if config.has("diffusion_rate"):
		diffusion_rate = clampf(float(config["diffusion_rate"]), 0.0, 0.5)
	if config.has("nutrient_supply"):
		nutrient_supply = clampf(float(config["nutrient_supply"]), 0.1, 1.0)
	if config.has("season_speed"):
		season_speed = clampf(float(config["season_speed"]), 0.05, 1.0)
	if config.has("growth_delay"):
		growth_delay = clampf(float(config["growth_delay"]), 0.3, 5.0)
	if config.has("competition_radius"):
		competition_radius = clampf(float(config["competition_radius"]), 0.5, 3.0)
	# Sync controllers
	if _diffusion_ctrl:
		_diffusion_ctrl.set_value(diffusion_rate)
	if _supply_ctrl:
		_supply_ctrl.set_value(nutrient_supply)
	if _speed_ctrl:
		_speed_ctrl.set_value(season_speed)
	if _trees_ctrl:
		_trees_ctrl.set_value(float(num_trees))
	_restart()

# ===== CLEANUP =====
func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
