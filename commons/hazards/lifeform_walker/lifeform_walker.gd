# @identity
# essence: cell(t+1) = GoL(neighbors(t)) -- walking creature with 6x6 Game of Life grid as armor
# desire: Conway's automaton tiling a walker's torso, alive cells as armor, dead cells as vulnerability
# critical_parameter: _grid state / _generation -- GoL rules determine which body cells are armored
# triggers: _ca_timer advances generations; alive cells block damage; dead cells expose creature
# emerges: emergent armor patterns -- gliders, oscillators, still lifes have tactical meaning as coverage
# needs: HazardCreatureBase [has]; 6x6 GoL grid [has]; cell mesh [has]; armor logic [has]; VR interaction [missing]
# relationships: embodies cellularautomata sequence; GoL rules create unpredictable defense patterns
# truth: armor that evolves by its own rules -- the creature does not choose defenses, emergence does.

extends HazardCreatureBase
class_name LifeformWalker
## Cellular Automata hazard — a walking creature with a 6×6 Game of Life grid
## on its torso. Living cells provide armor; dead cells expose weakness.
## CA rules run each tick, teaching local rules → global patterns.
##
## --- DNA (stage 2, promoted 2026-08-03) -------------------------------------
## Axis:
##   rule   which automaton governs the armour
##
## rule=life is exactly what shipped. `life` is [[3], [2, 3]] — B3/S23, which is
## the `neighbors == 2 or neighbors == 3` that _step_ca() used to write out by
## hand, so the default path is byte-for-byte the old one.
##
## WHY THE LAW AND NOT THE SOUP. The @identity names the critical parameter as
## "_grid state / _generation", and the shipped _init_grid seeds at density 0.5.
## Density is the wrong knob and complexity_pattern already refused it for the
## same reason: under Life every starting density converges to the same sparse
## litter of still lifes, so five densities photograph as five indistinguishable
## torsos. What the still actually shows is HOW MUCH OF THE BODY IS ARMOURED,
## and that fraction is a property of the rule table, not of the soup — life and
## highlife decay to a few blocks, maze and coral freeze into standing structure
## covering most of the plate, seeds sprays and empties, replicator fills to a
## periodic parity texture. The creature stops asserting "Conway" and starts
## showing what a different law would have armoured it with.
##
## THE WORD IS BORROWED ON PURPOSE. `rule` with exactly these six values is
## complexity_pattern's axis, character for character, including the RULES table
## below. That artifact is the same automaton as a flat field; this one wears it.
## Same question, same vocabulary, and the two should measure ALIKE — which is
## itself the check on whether the sharing was honest.
##
## ca_seed and warmup are NOT axes. They are fixture knobs, both defaulting to
## the shipped behaviour (0 = fresh unseeded randomness at spawn, no generations
## run before the first frame). Without a seed, six rule variants are six
## different random torsos and the sweep measures the RNG; without a warmup
## every variant photographs the same undifferentiated 50% soup, because at
## generation 0 no rule has spoken yet.
##
## Map token:  "lifeform_walker#rule:maze"
## ---------------------------------------------------------------------------

@export_group("Cellular Automata")
## DNA axis: which automaton governs the armour. "life" is B3/S23, the rule the
## shipped code wrote out by hand.
@export_enum("life", "highlife", "seeds", "replicator", "maze", "coral") var rule: String = "life"
@export var ca_rows: int = 6
@export var ca_cols: int = 6
@export var ca_tick_rate: float = 0.5
@export var ca_tick_rate_chase: float = 0.2
@export var cell_size: float = 0.05

## Fixture knob, not an axis. 0 = the shipped unseeded soup, so every existing
## placement keeps its own fresh randomness on every spawn.
@export var ca_seed: int = 0

## Fixture knob, not an axis. Generations run at build time before the first
## frame. 0 = shipped (the player meets the soup and watches it organise).
@export var warmup: int = 0

## birth neighbour counts, survival neighbour counts.
const RULES = {
	"life": [[3], [2, 3]],
	"highlife": [[3, 6], [2, 3]],
	"seeds": [[2], []],
	"replicator": [[1, 3, 5, 7], [1, 3, 5, 7]],
	"maze": [[3], [1, 2, 3, 4, 5]],
	"coral": [[3], [4, 5, 6, 7, 8]],
}

@export_group("Appearance")
@export var alive_color: Color = Color(0.2, 1.0, 0.3)
@export var dead_color: Color = Color(0.1, 0.1, 0.12)
@export var body_color: Color = Color(0.25, 0.3, 0.28)
@export var emission_alive: Color = Color(0.1, 0.8, 0.2)

# CA state
var _grid: Array = []  # 2D array of bools
var _ca_timer: float = 0.0
var _generation: int = 0
var _alive_count: int = 0

# Visual
var _cell_meshes: Array[MeshInstance3D] = []
var _cell_mats: Array[StandardMaterial3D] = []
var _body_mi: MeshInstance3D = null
var _head_mi: MeshInstance3D = null
var _leg_l: MeshInstance3D = null
var _leg_r: MeshInstance3D = null
var _label: Label3D = null
var _walk_phase: float = 0.0
var _body_mat: StandardMaterial3D
var _alive_mat: StandardMaterial3D
var _dead_mat: StandardMaterial3D

## Null unless ca_seed is set, in which case every draw comes from it.
## Null is the shipped path: the global randf(), exactly as before.
var _rng: RandomNumberGenerator = null
## True once _on_ready has seeded the grid. Guards the config hook from
## regrowing a body that does not exist yet.
var _built: bool = false


func _on_ready() -> void:
	add_to_group("ca_enemy")
	_seed_rng()
	_init_grid()
	for _i in range(maxi(warmup, 0)):
		_step_ca()
	# Only reachable with warmup > 0, which no existing placement sets. The
	# shipped creature leaves all 36 cells on the alive material until the first
	# tick lands half a second later, and that is preserved.
	if warmup > 0:
		_update_cell_visuals()
	_built = true


func _seed_rng() -> void:
	if ca_seed == 0:
		_rng = null
		return
	_rng = RandomNumberGenerator.new()
	_rng.seed = ca_seed


## The shipped call when unseeded, so nothing about the default path changes.
func _roll() -> float:
	if _rng != null:
		return _rng.randf()
	return randf()


func _init_grid() -> void:
	_grid.clear()
	for r in range(ca_rows):
		var row: Array = []
		for c in range(ca_cols):
			row.append(_roll() > 0.5)
		_grid.append(row)
	_count_alive()


func _create_materials() -> void:
	_body_mat = _make_material(body_color)
	_alive_mat = _make_material(alive_color, emission_alive)
	_dead_mat = _make_material(dead_color)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.45, 0.55, 0.2)
	col.shape = shape
	col.position.y = 0.45
	add_child(col)


func _build_mesh() -> void:
	# Torso
	var torso := BoxMesh.new()
	var grid_w: float = ca_cols * (cell_size + 0.01) + 0.04
	var grid_h: float = ca_rows * (cell_size + 0.01) + 0.04
	torso.size = Vector3(grid_w, grid_h, 0.06)
	_body_mi = _add_mesh(torso, _body_mat, Vector3(0.0, 0.5, 0.0))

	# CA cells on torso
	var start_x: float = -(ca_cols - 1) * (cell_size + 0.01) * 0.5
	var start_y: float = (ca_rows - 1) * (cell_size + 0.01) * 0.5
	for r in range(ca_rows):
		for c in range(ca_cols):
			var cm := BoxMesh.new()
			cm.size = Vector3(cell_size, cell_size, cell_size)
			var mat: StandardMaterial3D = _alive_mat.duplicate()
			var pos := Vector3(
				start_x + c * (cell_size + 0.01),
				start_y - r * (cell_size + 0.01),
				0.035
			)
			var mi := MeshInstance3D.new()
			mi.mesh = cm
			mi.set_surface_override_material(0, mat)
			mi.position = pos
			_body_mi.add_child(mi)
			_cell_meshes.append(mi)
			_cell_mats.append(mat)

	# Head
	var head := SphereMesh.new()
	head.radius = 0.08
	head.height = 0.16
	_head_mi = _add_mesh(head, _body_mat, Vector3(0.0, 0.82, 0.0))

	# Legs
	var leg := CylinderMesh.new()
	leg.top_radius = 0.025
	leg.bottom_radius = 0.03
	leg.height = 0.3
	_leg_l = _add_mesh(leg, _body_mat, Vector3(-0.1, 0.15, 0.0))
	_leg_r = _add_mesh(leg, _body_mat, Vector3(0.1, 0.15, 0.0))

	# Label
	_label = Label3D.new()
	_label.text = "Gen: 0 | Alive: 0"
	_label.font_size = 24
	_label.pixel_size = 0.002
	_label.modulate = alive_color
	_label.position = Vector3(0.0, 0.95, 0.06)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mesh_root.add_child(_label)


func _process_visual(delta: float) -> void:
	# Walk animation
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		var spd: float = patrol_speed if _state == BaseState.PATROL else chase_speed
		_walk_phase += delta * spd * 4.0
		if _leg_l and _leg_r:
			_leg_l.position.y = 0.15 + sin(_walk_phase) * 0.06
			_leg_r.position.y = 0.15 - sin(_walk_phase) * 0.06

	# CA tick
	var tick: float = ca_tick_rate_chase if _state == BaseState.CHASE else ca_tick_rate
	_ca_timer += delta
	if _ca_timer >= tick:
		_ca_timer = 0.0
		_step_ca()
		_update_cell_visuals()


func _step_ca() -> void:
	# The transition rule. "life" is [[3], [2, 3]] — B3/S23, which is the
	# `neighbors == 2 or neighbors == 3` this function used to write out by hand,
	# so the default path is the shipped one exactly.
	var law: Array = RULES.get(rule, RULES["life"])
	var birth: Array = law[0]
	var survive: Array = law[1]
	var new_grid: Array = []
	for r in range(ca_rows):
		var row: Array = []
		for c in range(ca_cols):
			var neighbors: int = _count_neighbors(r, c)
			var alive: bool = _grid[r][c]
			if alive:
				row.append(survive.has(neighbors))
			else:
				row.append(birth.has(neighbors))
		new_grid.append(row)
	_grid = new_grid
	_generation += 1
	_count_alive()

	# If CA dies completely, reinitialize
	if _alive_count == 0:
		_init_grid()


func _count_neighbors(row: int, col: int) -> int:
	var count: int = 0
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			if dr == 0 and dc == 0:
				continue
			var nr: int = row + dr
			var nc: int = col + dc
			if nr >= 0 and nr < ca_rows and nc >= 0 and nc < ca_cols:
				if _grid[nr][nc]:
					count += 1
	return count


func _count_alive() -> void:
	_alive_count = 0
	for r in range(ca_rows):
		for c in range(ca_cols):
			if _grid[r][c]:
				_alive_count += 1


func _update_cell_visuals() -> void:
	for r in range(ca_rows):
		for c in range(ca_cols):
			var idx: int = r * ca_cols + c
			if idx >= _cell_mats.size():
				continue
			var alive: bool = _grid[r][c]
			if alive:
				_cell_mats[idx].albedo_color = alive_color
				_cell_mats[idx].emission_enabled = true
				_cell_mats[idx].emission = emission_alive
				_cell_mats[idx].emission_energy_multiplier = 1.5
			else:
				_cell_mats[idx].albedo_color = dead_color
				_cell_mats[idx].emission_enabled = false

	if _label:
		_label.text = "Gen: %d | Alive: %d" % [_generation, _alive_count]


## Re-seed the automaton under the current axis value and repaint the torso.
## Only called from apply_grid_config, and only when a value actually changed.
## The 36 cell meshes are NOT rebuilt — the plate's geometry does not depend on
## the rule, only on ca_rows/ca_cols, which this hook does not touch.
func _regrow() -> void:
	_generation = 0
	_ca_timer = 0.0
	_seed_rng()
	_init_grid()
	for _i in range(maxi(warmup, 0)):
		_step_ca()
	_update_cell_visuals()


## Guarded on both counts: the automaton is re-seeded only when a key's value
## actually CHANGED, and only after _on_ready has grown it once. A placement
## that passes none of these keys — which today is the single existing one —
## gets exactly the behaviour it had before the axis existed. Values arrive as
## strings from a map token, so each is parsed and validated before it is let
## through. Unrecognised keys fall to the base configure(), unchanged.
func apply_grid_config(config_data: Dictionary) -> void:
	var re_grow: bool = false
	for key in config_data:
		var k: String = str(key)
		if k == "rule":
			var r: String = str(config_data[key]).to_lower()
			if RULES.has(r) and r != rule:
				rule = r
				re_grow = true
			continue
		if k == "ca_seed":
			var s: int = int(config_data[key])
			if s != ca_seed:
				ca_seed = s
				re_grow = true
			continue
		if k == "warmup":
			var w: int = maxi(int(config_data[key]), 0)
			if w != warmup:
				warmup = w
				re_grow = true
			continue
	super.apply_grid_config(config_data)
	if re_grow and _built:
		_regrow()


## Armor effect — alive cells reduce damage taken.
func _on_damaged(amount: float) -> void:
	var armor: float = float(_alive_count) / float(ca_rows * ca_cols)
	var reduced: float = amount * (1.0 - armor * 0.7)
	# Base class already subtracted full amount; add back the difference
	_health += amount - reduced
	if _health > 0.0:
		_set_state(BaseState.STUNNED)
