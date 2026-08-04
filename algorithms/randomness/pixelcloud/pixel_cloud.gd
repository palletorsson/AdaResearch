# @identity
# essence: SAW(n) — self-avoiding walk with upward bias on a 3D integer lattice
# desire: see a vertical sculpture made of cubes, each placed by a walk that refuses to retrace its steps
# critical_parameter: upward_bias — weight multiplier for +Y steps; higher values produce taller, thinner clouds
# triggers: self_avoiding_walk() with weighted_random_choice(); ui_accept regenerates the structure
# emerges: the walker frequently traps itself — the sculpture is a record of how far freedom reached before constraint won
# needs: cube_scene template [has]; keyboard regeneration [has]; VR controls [missing]
# relationships: feeds Random_Walk map; contrasts with random_walk_terrarium (unbounded vs self-avoiding)
# truth: Self-avoidance is memory — and memory is the first constraint that gives randomness shape.

extends Node3D

# ─── STAGE-2 DNA ──────────────────────────────────────────────────────────────
# Two axes, both lifted out of numbers that were already in this file and already
# doing the arguing, neither of them reachable from a map token.
#
# WHY THESE TWO. The @identity block above names upward_bias as the critical
# parameter and then leaves it a bare float nobody can turn — the classic
# unreachable-critical_parameter. And the truth statement claims self-avoidance is
# what gives randomness shape, while the shipped sculpture shows only the surviving
# path: the refusals that did the shaping are thrown away at build time. So one axis
# turns the pull and the other decides how much of the working the object admits to.
#
# NEITHER AXIS TOUCHES THE WALK'S DICE. `bias` changes the weights the walk is
# offered; `evidence` changes only what is built afterwards from a walk that has
# already happened. bias=rise, evidence=result is the shipped build exactly — the
# same weight of 3.0 on +Y, the same 1.0 everywhere else, the same one randf() per
# step in the same order, the same cubes and nothing beside them.
#
# SEE walk_seed. It defaults to -1, which draws from the global stream exactly as
# before; without a seed set, four evidence values would be four different walks and
# the sweep would measure the dice instead of the drawing.
#
# Usage in map_data.json:
#   "pixel_cloud#bias:sprawl"
#   "pixel_cloud#bias:spire#evidence:longhand"

@export var grid_size: int = 16
@export var num_cubes: int = 23
@export var cube_spacing: float = 1.0
@export var upward_bias: float = 3.0  # Higher = more upward movement

## What pulls the walk. A self-avoiding walk on an isotropic lattice has no opinion
## about which way is up; this one always did, and the opinion was a hard-coded 3.0.
##
##   rise    the shipped weighting, unchanged: +Y carries `upward_bias`, the other
##           five directions carry 1.0. A cloud that climbs while it wanders.
##   none    every direction weighted 1.0 — the textbook SAW, with the preference
##           taken away. The sculpture stops being a column and becomes a knot that
##           settles near the floor it started on.
##   spire   +Y at four times `upward_bias`. The walk barely turns aside; the cloud
##           is nearly a stack, and the wandering shows only as a stagger.
##   sprawl  the four horizontal directions carry `upward_bias` and the vertical
##           pair carry 1.0 — the same magnitude of preference aimed flat. A floor
##           plan instead of an elevation.
@export_enum("rise", "none", "spire", "sprawl") var bias: String = "rise"
const BIASES: PackedStringArray = ["rise", "none", "spire", "sprawl"]

## What the sculpture offers as proof of its own working. Word and value list taken
## character for character from the twenty-one siblings that already ask this —
## fibonacci_sequences, koch_curve, gradient_descent_visualization and the NOC forces
## family — because it is the same question, not a near neighbour of it.
##
##   result    the shipped build: the surviving path, every cube identical, the
##             order of arrival and the refusals both discarded.
##   trace     the same cubes, ramped in colour from first step to last. The object
##             stops being a SET of occupied cells and becomes a SEQUENCE again —
##             which end is the start is a fact the shipped sculpture withholds.
##   longhand  the working instead of the answer. Every step's valid-but-unchosen
##             neighbours are stamped as small dim cubes: the road not taken, at
##             every fork, in the same lattice. The cloud wears its own alternatives.
##   axiom     the instance gives way to the rule. The walk is not built at all;
##             one cube stands at the start cell surrounded by its six candidate
##             neighbours, each drawn with a VOLUME proportional to its weight. The
##             local rule the whole sculpture is one sample of — and it restates
##             itself under each value of `bias`.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]

## Seed for the step generator. -1 (the default) draws from the global stream with
## the same calls in the same order as before, so shipped placements keep rolling a
## fresh sculpture on every launch. Set it non-negative and every launch and every
## DNA variant replays the SAME walk, which is the precondition for either axis
## measuring the drawing rather than the dice. Convention shared with
## random_walk_terrarium and the random_walk_* family.
@export var walk_seed: int = -1

var cube_scene = preload("res://commons/primitives/cubes/cube_scene.tscn")
var occupied_cells: Dictionary = {}
var walker_path: Array[Vector3i] = []
## Valid neighbours that were offered and passed over, in step order. Recorded on
## every build regardless of `evidence` — it costs an append and nothing else — so
## that switching the axis after _ready does not require re-walking.
var forgone_cells: Array[Vector3i] = []

var _rng: RandomNumberGenerator = null
var _generated: Array[Node] = []
var _built: bool = false

# Directions: up, right, forward, left, back, down (3D space)
var directions: Array[Vector3i] = [
	Vector3i(0, 1, 0),   # up
	Vector3i(1, 0, 0),   # right
	Vector3i(0, 0, 1),   # forward
	Vector3i(-1, 0, 0),  # left
	Vector3i(0, 0, -1),  # back
	Vector3i(0, -1, 0)   # down
]

func _ready() -> void:
	generate_pixel_cloud()
	_built = true

func generate_pixel_cloud() -> void:
	# Start at bottom center of grid
	var start_pos = Vector3i(grid_size / 2, 0, grid_size / 2)
	walker_path.clear()
	occupied_cells.clear()
	forgone_cells.clear()
	_prepare_rng()

	# Perform self-avoiding walk
	self_avoiding_walk(start_pos, num_cubes)

	# Place cubes along the path
	place_cubes()

## walk_seed < 0 leaves _rng null and every draw goes through the global randf(),
## which is what shipped. Only a non-negative seed installs a private stream.
func _prepare_rng() -> void:
	if walk_seed < 0:
		_rng = null
		return
	_rng = RandomNumberGenerator.new()
	_rng.seed = walk_seed

func _roll() -> float:
	if _rng != null:
		return _rng.randf()
	return randf()

func self_avoiding_walk(start: Vector3i, steps: int) -> void:
	var current = start
	walker_path.append(current)
	occupied_cells[current] = true

	for i in range(steps - 1):
		var valid_moves: Array[Vector3i] = []
		var move_weights: Array[float] = []

		# Find all valid adjacent cells with bias weights
		for dir in directions:
			var next = current + dir

			# Check bounds and if cell is unoccupied
			if is_valid_position(next) and not occupied_cells.has(next):
				valid_moves.append(next)
				move_weights.append(_direction_weight(dir))

		# If no valid moves, stop (walker is trapped)
		if valid_moves.is_empty():
			print("Walker trapped after ", walker_path.size(), " steps")
			break

		# Choose weighted random move
		var next_pos = weighted_random_choice(valid_moves, move_weights)
		for candidate in valid_moves:
			if candidate != next_pos:
				forgone_cells.append(candidate)
		current = next_pos
		walker_path.append(current)
		occupied_cells[current] = true

	print("Generated path with ", walker_path.size(), " cubes")

## The one place `bias` reaches. "rise" returns exactly what the inline weight
## computation returned before this axis existed.
func _direction_weight(dir: Vector3i) -> float:
	if bias == "none":
		return 1.0
	if bias == "spire":
		if dir.y > 0:
			return upward_bias * 4.0
		return 1.0
	if bias == "sprawl":
		if dir.y == 0:
			return upward_bias
		return 1.0
	# "rise" — the shipped weighting.
	if dir.y > 0:
		return upward_bias
	return 1.0

func weighted_random_choice(choices: Array[Vector3i], weights: Array[float]) -> Vector3i:
	var total_weight = 0.0
	for w in weights:
		total_weight += w

	var rand_val = _roll() * total_weight
	var cumulative = 0.0

	for i in range(choices.size()):
		cumulative += weights[i]
		if rand_val <= cumulative:
			return choices[i]

	return choices[-1]

func is_valid_position(pos: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < grid_size and \
		   pos.y >= 0 and pos.y < grid_size and \
		   pos.z >= 0 and pos.z < grid_size

## Convert grid position to local position, centering the grid around the origin.
## Lifted verbatim out of place_cubes() so the added builds land on the same lattice.
func _grid_to_local(grid_pos: Vector3i) -> Vector3:
	var x = (grid_pos.x - grid_size / 2.0) * cube_spacing
	var y = grid_pos.y * cube_spacing
	var z = (grid_pos.z - grid_size / 2.0) * cube_spacing
	return Vector3(x, y, z)

func place_cubes() -> void:
	if evidence == "axiom":
		_build_axiom()
		return

	var last: int = maxi(1, walker_path.size() - 1)
	for i in range(walker_path.size()):
		var grid_pos: Vector3i = walker_path[i]
		var cube = cube_scene.instantiate()
		add_child(cube)
		_generated.append(cube)
		cube.position = _grid_to_local(grid_pos)
		if evidence == "trace":
			_tint_cube(cube, float(i) / float(last))

	if evidence == "longhand":
		_build_forgone()

## The alternatives, once. A cell offered at step 3 and taken at step 9 is not a road
## not taken, so anything the path eventually occupied is dropped — otherwise the
## ghosts would sit inside the cubes and read as z-fighting rather than as a choice.
func _build_forgone() -> void:
	var drawn: Dictionary = {}
	for cell in forgone_cells:
		if occupied_cells.has(cell) or drawn.has(cell):
			continue
		drawn[cell] = true
		var ghost: MeshInstance3D = MeshInstance3D.new()
		ghost.name = "Forgone"
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(0.34, 0.34, 0.34) * cube_spacing
		ghost.mesh = box
		ghost.material_override = _ghost_material(Color(0.25, 0.85, 1.0), 0.45)
		ghost.position = _grid_to_local(cell)
		add_child(ghost)
		_generated.append(ghost)

## The rule rather than a sample of it: the start cell and its six candidates, each
## candidate's VOLUME set to its weight so `bias` is read off the geometry.
func _build_axiom() -> void:
	var start: Vector3i = Vector3i(grid_size / 2, 0, grid_size / 2)
	var origin: Vector3 = _grid_to_local(start)

	var cube = cube_scene.instantiate()
	add_child(cube)
	_generated.append(cube)
	cube.position = origin

	for dir in directions:
		var w: float = _direction_weight(dir)
		var edge: float = 0.42 * pow(w, 1.0 / 3.0) * cube_spacing
		var slot: MeshInstance3D = MeshInstance3D.new()
		slot.name = "Candidate"
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(edge, edge, edge)
		slot.mesh = box
		slot.material_override = _ghost_material(Color(1.0, 0.55, 0.15), 0.8)
		slot.position = origin + Vector3(dir.x, dir.y, dir.z) * cube_spacing
		add_child(slot)
		_generated.append(slot)

## DUPLICATE FIRST. cube_scene's ShaderMaterial is a sub-resource of the packed
## scene and is therefore SHARED by every instance in the game; setting a parameter
## on it directly would repaint every cube in every map.
func _tint_cube(cube: Node, t: float) -> void:
	var mesh_node: MeshInstance3D = cube.get_node_or_null("CubeBaseStaticBody3D/CubeBaseMesh") as MeshInstance3D
	if mesh_node == null:
		return
	var shader_mat: ShaderMaterial = mesh_node.material_override as ShaderMaterial
	if shader_mat == null:
		return
	var own_mat: ShaderMaterial = shader_mat.duplicate() as ShaderMaterial
	if own_mat == null:
		return
	var col: Color = Color(0.15, 0.9, 1.0).lerp(Color(1.0, 0.2, 0.7), t)
	own_mat.set_shader_parameter("wireframeColor", col)
	own_mat.set_shader_parameter("emissionColor", col)
	mesh_node.material_override = own_mat

func _ghost_material(color: Color, alpha: float) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	return mat

## Free only what this script built. The previous version freed EVERY child, which
## took the scene's Camera3D and DirectionalLight3D with it on the first regenerate.
func _clear_generated() -> void:
	for node in _generated:
		if is_instance_valid(node):
			node.queue_free()
	_generated.clear()

func _input(event: InputEvent) -> void:
	# Press R to regenerate
	if event.is_action_pressed("ui_accept"):
		_clear_generated()
		generate_pixel_cloud()

## Only restages when a value BOTH validates AND differs from what is standing, and
## never before _ready has built once. The eight shipped placements pass none of
## these keys, so nothing in them re-runs.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

	var changed: bool = false

	if config_data.has("bias"):
		var want_bias: String = str(config_data["bias"]).strip_edges().to_lower()
		if BIASES.has(want_bias) and want_bias != bias:
			bias = want_bias
			changed = true

	if config_data.has("evidence"):
		var want_evidence: String = str(config_data["evidence"]).strip_edges().to_lower()
		if EVIDENCES.has(want_evidence) and want_evidence != evidence:
			evidence = want_evidence
			changed = true

	if config_data.has("walk_seed"):
		var want_seed: int = int(str(config_data["walk_seed"]))
		if want_seed != walk_seed:
			walk_seed = want_seed
			changed = true

	if changed and _built and is_inside_tree():
		_clear_generated()
		generate_pixel_cloud()
