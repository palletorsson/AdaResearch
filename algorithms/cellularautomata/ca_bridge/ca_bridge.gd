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

## STAGE-2 DNA PROMOTION (2026-08-05). Everything this artifact argues is in one 8-bit
## number, and that number was unreachable: `rule` is an @export, but apply_grid_config was
## a literal `pass`, so no map token could name it and all four placements walked the same
## rule 30. The runner refused it as NO TURNABLE KNOBS on that ground — the knob existed,
## nothing was connected to it.
##
##   rule   which three-cell law builds the bridge   30 · 90 · 110 · 250
##
## The word `rule` is taken from complexity_pattern, lifeform_walker, mold_network and
## structure_growth, which all use it for the same question: which local update law is in
## force. Its VALUES are refused. life · highlife · seeds · replicator · maze · coral are
## 2D Moore-neighbourhood birth/survival rulestrings, and there is no "life" in a 1D
## three-cell automaton to name — taking those answers would be naming a mechanism this
## object does not have. For an elementary CA the rules ARE their numbers; the @identity
## already says so ("critical_parameter: rule (0-255)").
##
## The four were MEASURED, not picked from a textbook: the exact update above was
## re-implemented in Python at this scene's own geometry (width 31, periodic wrap, single
## centre seed, 120 rows) and every candidate 0-254 scored for fill and pairwise
## difference. Rules 184 and 22 were dropped for filling 3% of the deck — a thread, not a
## bridge, and far too small a subject to photograph. What ships spans Wolfram's classes
## and is separated by at least 42% of cells between any two:
##
##   30   48.0% full  class 3, chaotic — a broken deck you would not trust
##   90   23.5% full  class 2, the Sierpinski gasket — nested holes, self-similar gaps
##   110  49.7% full  class 4, the universal one — structure, and gliders crossing it
##   250  87.5% full  class 1/2, near-solid — the control, a ramp that computes nothing
##
## `seeding` (one cell vs a random row) is DECLINED as a second axis, for the reason
## complexity_pattern recorded when it declined density: the initial row here is drawn with
## an unseeded randf(), so four random-start frames would be four different bridges and any
## bite number would be measuring the RNG rather than the rule.

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

@export_category("Bridge Settings")
@export var width: int = 21 # Width of the bridge (X axis)
@export var length: int = 100 # Length of the bridge (Z axis / Time)
@export var cell_size: float = 0.5 # Half size as requested (standard is 1.0)
@export var generation_speed: float = 0.1
@export var auto_generate: bool = true

@export_category("Rule Settings")
## DNA axis: the Wolfram number. 0-255; the declared ladder is 30, 90, 110, 250.
@export var rule: int = 30 # Wolfram 1D Rule (0-255)
@export var random_initial_row: bool = false
@export var initial_density: float = 0.5

## Not an axis — a PIN, and a MANDATORY one for the sweep. This bridge grows one row per
## `generation_speed` seconds out of `length` rows: at the scene's own 0.05 s × 120 that is
## six full seconds of wall clock. A still photographed at the bench's settle time catches
## a stump, and worse, a different stump per value, because a rule that spawns more cubes
## renders slower — four frames that differ by how far each one got, which is the
## generative-artifact trap in the time domain rather than the RNG. 0 is the shipped
## behaviour (grow over time, exactly as before) and is what all four placements get; a
## positive number builds that many rows synchronously inside _ready and then stops, so the
## capture bench photographs the finished deck. Set through dna.fixture, never in a map.
@export var build_rows: int = 0

var current_z: int = 0
var current_row: Array = []
var timer: float = 0.0
var is_generating: bool = false
var generated_cubes: Array = []

# Collision
var static_body: StaticBody3D
var box_shape: BoxShape3D

## True once _ready has built the bridge. apply_grid_config must not regenerate before it.
var _built: bool = false

func _ready() -> void:
	_setup_collision()
	if auto_generate:
		start_generation()
	_built = true

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
	if build_rows > 0:
		_build_immediately(build_rows)

## Spend the whole growth in one frame. Only reachable when build_rows is non-zero, which
## no placement sets — the shipped path still ticks through _process one row at a time.
func _build_immediately(rows: int) -> void:
	var budget: int = mini(rows, length)
	for k in range(budget):
		if current_z >= length:
			break
		step()
	is_generating = false

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


## GUARDED. Config can arrive before _ready (the grid stamps it on the node it is about to
## add) or after. Before the first build, assignment is enough — _ready reads the new values
## on its way through. After it, only a value that actually MOVED may tear down and respawn
## up to 3,720 cubes and their collision shapes. All four placements pass rotation and
## y_offset only, never a key this function reads, so none of them rebuilds anything.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	var field_changed: bool = false

	if config.has("rule"):
		var r: int = clampi(int(config["rule"]), 0, 255)
		if r != rule:
			rule = r
			field_changed = true
	if config.has("build_rows"):
		var b: int = maxi(int(config["build_rows"]), 0)
		if b != build_rows:
			build_rows = b
			field_changed = true

	if not _built:
		return
	if field_changed and auto_generate:
		start_generation()
