# @identity
# essence: F -> F[+F]F[-F]F -- L-system grammar drives vine growth toward the player
# desire: a vine growing from axiom F through production rules, branching procedurally toward its target
# critical_parameter: _rules dictionary / _iteration_count -- grammar rules determine branching, iterations control depth
# triggers: iteration_timer drives growth; player position attracts branch direction; damage on contact
# emerges: biological growth pattern as hunting strategy -- the vine does not chase, it grows toward you
# needs: HazardCreatureBase [has]; L-system string rewriting [has]; procedural mesh generation [has]; player targeting [has]
# relationships: embodies L-systems sequence; contrasts with fractal_hydra (growth vs splitting)
# truth: the simplest grammar generates the branching complexity of all plant life.

extends HazardCreatureBase
class_name BranchingVine
## L-systems sequence — procedural vine that grows via L-system rules.
## Initial axiom "F", rule: "F" -> "F[+F][-F]F". Iterates every 3 seconds
## up to depth 4. Branches grow toward the player (angle bias).
## Branch tips (leaves) deal contact damage. Damage prunes branches.

@export_group("L-System")
@export var iteration_interval: float = 3.0
@export var max_iterations: int = 4
@export var segment_length: float = 0.15
@export var branch_angle: float = 25.0
@export var segment_radius: float = 0.015
@export var leaf_radius: float = 0.035
@export var player_bias: float = 0.3

@export_group("Combat")
@export var leaf_damage: float = 8.0

# ═══════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — evidence × habit
# ═══════════════════════════════════════════════════════════════════════
#
# Same two words, same two ladders, same meaning as lsystem_tree. That is
# deliberate and it is the point: strip the hazard chassis off this artifact
# and what is left is lsystem_tree's turtle — one production rewritten to a
# fixed depth, and a walker that only ever rotates about ONE axis, so the
# vine is a flat drawing. The two artifacts should measure ALIKE.
#
#   evidence  WHETHER THE DERIVATION IS ON SHOW OR ONLY ITS ANSWER.
#             This vine does show its own derivation — but temporally, one
#             generation every iteration_interval seconds. A still photograph
#             cannot see a sequence, so in every frame this artifact has ever
#             produced, the working is invisible. evidence makes the
#             derivation SPATIAL: trace nests the earlier generations inside
#             the finished vine at one root, longhand stands generation 1..N
#             side by side at one scale, axiom draws ONE application of
#             F -> F[+F][-F]F — the rule as a picture instead of its limit.
#             `result` is the shipped vine: whatever generation the growth
#             timer has reached, drawn alone at the root.
#
#   habit     HOW THE BRANCHING PLANE TURNS AS THE GRAMMAR DESCENDS.
#             The shipped turtle rotates only about turtle_right.cross(dir),
#             and turtle_right is never touched, so every branch of every
#             generation lands in one plane. `planar` is that flat vine, and
#             the roll is SKIPPED rather than applied as a zero rotation, so
#             the shipped instruction sequence runs untouched.
#
# NEITHER IS A TIME AXIS. Nothing declared here is a rate. iteration_interval
# and max_iterations were already exports and stay exactly what they were.
@export_group("DNA")
## DNA — how much of the derivation is on show. The shipped vine draws only the
## generation the growth timer has reached; "result" is that vine, byte for byte.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"
## DNA — how the branching plane turns as the grammar descends. The shipped turtle
## never rolls, so the vine is a flat drawing; "planar" is that drawing, byte for byte.
@export_enum("planar", "fanned", "whorled", "spiral") var habit: String = "planar"

const EVIDENCE_VALUES: PackedStringArray = ["result", "trace", "longhand", "axiom"]

## Degrees of roll applied to the branching plane at every push. planar = 0 is the
## shipped turtle; the roll is skipped entirely at that value.
const HABIT_ROLL: Dictionary = {
	"planar": 0.0,
	"fanned": 30.0,
	"whorled": 90.0,
	"spiral": 137.5,
}

## Horizontal pitch between longhand columns. Only `longhand` ever uses more than
## one column; at one column the offset is Vector3.ZERO and the arithmetic below
## is the shipped arithmetic.
const COLUMN_PITCH: float = 0.5

## Brightness of the superseded generations under `trace`.
const GHOST_SHADE: float = 0.35

# ── L-System State ─────────────────────────────────────────────────────
var _axiom: String = "F"
var _rules: Dictionary = {"F": "F[+F][-F]F"}
var _current_string: String = "F"
var _iteration_count: int = 0
var _iteration_timer: float = 0.0
## Every generation of the rewrite, index 0 = the axiom. Computed once, up front,
## from the same rule the timer uses — so `result` and `_current_string` still
## agree generation for generation, and the other three values do not have to
## wait twelve seconds for a picture that a capture never sees.
var _generations: Array[String] = []
var _built: bool = false

# ── Visual State ───────────────────────────────────────────────────────
var _segments: Array[Dictionary] = []  # {mesh, start, end, depth, is_leaf, children_indices}
var _trunk_mat: StandardMaterial3D = null
var _leaf_mat: StandardMaterial3D = null
var _label: Label3D = null
var _vine_root: Node3D = null
var _leg_roots: Array[Node3D] = []
var _walk_phase: float = 0.0


# This is a CharacterBody3D that starts in PATROL and walks its corners from the
# first physics frame. An unpinned creature drifts inside a fixed sweep camera and
# the diff then measures DISPLACEMENT instead of the axis. The two writes below are
# therefore guarded: they fire only while the property still holds
# HazardCreatureBase's own default, because an unguarded write here silently
# discards anything set before add_child — which is exactly how the sweep and the
# registry fixture supply values. Nothing in the repo supplies either today, so
# every existing placement takes the branch and gets the same numbers as before.
const BASE_PATROL_SPEED: float = 1.8
const OWN_PATROL_SPEED: float = 1.0
const BASE_DETECTION_RADIUS: float = 7.0
const OWN_DETECTION_RADIUS: float = 7.0


func _on_ready() -> void:
	max_health = 85.0
	_health = max_health
	chase_speed = 1.8
	if is_equal_approx(patrol_speed, BASE_PATROL_SPEED):
		patrol_speed = OWN_PATROL_SPEED
	contact_damage = 8.0
	if is_equal_approx(detection_radius, BASE_DETECTION_RADIUS):
		detection_radius = OWN_DETECTION_RADIUS

	_build_generations()
	_build_l_system()
	_built = true


## Rewrite the axiom max_iterations times and keep every step. Pure string work,
## bounded by max_iterations, and it RETURNS — no await, no unbounded loop.
func _build_generations() -> void:
	_generations.clear()
	var current: String = _axiom
	_generations.append(current)
	for _i in range(max_iterations):
		var out: String = ""
		for ch in current:
			var c: String = ch
			if _rules.has(c):
				out += String(_rules[c])
			else:
				out += c
		current = out
		_generations.append(current)


func _create_materials() -> void:
	_trunk_mat = _make_material(Color(0.35, 0.22, 0.1), Color(0.15, 0.1, 0.02))
	_leaf_mat = _make_material(Color(0.3, 0.9, 0.15), Color(0.2, 0.7, 0.1))


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	col.shape = shape
	col.position.y = 0.3
	add_child(col)


func _build_mesh() -> void:
	_mesh_root.position.y = 0.0

	_vine_root = Node3D.new()
	_vine_root.name = "VineRoot"
	_mesh_root.add_child(_vine_root)

	# 2 legs (root tendrils)
	for i in range(2):
		var root := Node3D.new()
		root.name = "Leg_%d" % i
		root.position = Vector3((i - 0.5) * 0.1, 0, 0)
		_mesh_root.add_child(root)
		_leg_roots.append(root)

		var cyl := CylinderMesh.new()
		cyl.height = 0.12
		cyl.top_radius = 0.02
		cyl.bottom_radius = 0.01
		var leg_mat := _make_material(Color(0.3, 0.18, 0.08), Color.BLACK)
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.set_surface_override_material(0, leg_mat)
		mi.position = Vector3(0, -0.06, 0)
		root.add_child(mi)

	# Label
	_label = Label3D.new()
	_label.text = ""
	_label.font_size = 36
	_label.pixel_size = 0.003
	_label.position = Vector3(0, 1.2, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1, 1, 1, 0.85)
	_mesh_root.add_child(_label)


func _build_l_system() -> void:
	# Clear existing segments
	for seg in _segments:
		if is_instance_valid(seg["mesh"]):
			seg["mesh"].queue_free()
	_segments.clear()

	for fig in _figures_for():
		var column: int = int(fig["column"])
		var offset: Vector3 = Vector3(float(column) * COLUMN_PITCH, 0.0, 0.0)
		_walk(String(fig["text"]), offset, float(fig["shade"]))


## Which strings get drawn, how bright, and in which column.
##
## `result` returns exactly one figure — the live _current_string, at the root,
## at full brightness — so the shipped vine takes the shipped path with a zero
## offset and a shade of 1.0, and nothing about its drawing changes.
##
## No value ever selects generation 0: a single bare segment carries no picture.
func _figures_for() -> Array:
	var figures: Array = []
	var last: int = _generations.size() - 1

	# Degenerate grammar (max_iterations 0, or an empty rewrite) — there is no
	# derivation to lay out, so every value falls back to the live string.
	if last < 1:
		figures.append({"text": _current_string, "shade": 1.0, "column": 0})
		return figures

	match evidence:
		"axiom":
			# ONE application of F -> F[+F][-F]F. The production, not its limit.
			figures.append({"text": _generations[1], "shade": 1.0, "column": 0})
		"trace":
			# The growth history nested inside the finished vine, at one root.
			for i in range(1, last):
				figures.append({"text": _generations[i], "shade": GHOST_SHADE, "column": 0})
			figures.append({"text": _generations[last], "shade": 1.0, "column": 0})
		"longhand":
			# Every rewrite stood side by side, all at one scale.
			for i in range(1, last + 1):
				figures.append({"text": _generations[i], "shade": 1.0, "column": i - 1})
		_:
			figures.append({"text": _current_string, "shade": 1.0, "column": 0})

	return figures


## The shipped turtle, unchanged. `origin` is Vector3.ZERO and `shade` is 1.0 for
## every figure except the extra ones the non-default evidence values add, so at
## evidence=result this runs the pre-promotion instruction sequence on the
## pre-promotion numbers.
func _walk(source: String, origin: Vector3, shade: float) -> void:
	# Interpret the L-system string using turtle graphics
	var turtle_pos: Vector3 = origin + Vector3(0, 0.05, 0)
	var turtle_dir := Vector3(0, 1, 0)  # Growing upward
	var turtle_right := Vector3(1, 0, 0)
	var stack: Array[Dictionary] = []
	var current_depth: int = 0

	# Player bias direction
	var bias_dir := Vector3.ZERO
	if is_instance_valid(_player_node):
		bias_dir = (_player_node.global_position - global_position).normalized()
		bias_dir.y = 0.0

	var angle_rad: float = deg_to_rad(branch_angle)
	# planar holds this at exactly 0.0, and the roll below is then never executed.
	var roll_rad: float = deg_to_rad(float(HABIT_ROLL.get(habit, 0.0)))

	for ch in source:
		var c: String = ch
		match c:
			"F":
				# Draw segment forward
				var biased_dir: Vector3 = turtle_dir
				if bias_dir.length() > 0.01:
					biased_dir = (turtle_dir + bias_dir * player_bias).normalized()

				var end_pos: Vector3 = turtle_pos + biased_dir * segment_length
				_create_segment(turtle_pos, end_pos, current_depth, false, shade)
				turtle_pos = end_pos
			"+":
				# Rotate right
				turtle_dir = turtle_dir.rotated(turtle_right.cross(turtle_dir).normalized(), angle_rad)
				if turtle_dir.length() < 0.01:
					turtle_dir = Vector3(0, 1, 0)
				turtle_dir = turtle_dir.normalized()
			"-":
				# Rotate left
				turtle_dir = turtle_dir.rotated(turtle_right.cross(turtle_dir).normalized(), -angle_rad)
				if turtle_dir.length() < 0.01:
					turtle_dir = Vector3(0, 1, 0)
				turtle_dir = turtle_dir.normalized()
			"[":
				# Push state
				stack.append({
					"pos": turtle_pos,
					"dir": turtle_dir,
					"right": turtle_right,
					"depth": current_depth,
				})
				current_depth += 1
				# Roll the branching plane. The saved `right` above is the
				# PRE-roll one, so popping restores the parent's plane. Skipped
				# entirely at habit == "planar", where roll_rad is exactly 0.0 —
				# not applied as a zero rotation, so no float is touched and the
				# shipped flat vine is reproduced instruction for instruction.
				if roll_rad != 0.0:
					turtle_right = turtle_right.rotated(turtle_dir, roll_rad).normalized()
			"]":
				# Pop state — add leaf at current tip before popping
				_create_segment(turtle_pos, turtle_pos, current_depth, true, shade)
				if not stack.is_empty():
					var saved: Dictionary = stack.pop_back()
					turtle_pos = saved["pos"]
					turtle_dir = saved["dir"]
					turtle_right = saved["right"]
					current_depth = saved["depth"]


## `shade` is 1.0 for every figure the shipped vine draws, and the colour
## expressions below multiply by it component-wise, so at 1.0 they evaluate to
## the same literals as before. Only `trace` ever passes anything else.
func _create_segment(start: Vector3, end: Vector3, depth: int, is_leaf: bool, shade: float = 1.0) -> void:
	if is_leaf:
		# Leaf sphere
		var sphere := SphereMesh.new()
		sphere.radius = leaf_radius
		sphere.height = leaf_radius * 2.0
		# Darken green with depth
		var green_val: float = max(0.3, 0.9 - depth * 0.15)
		var leaf_color := Color(0.2 * shade, green_val * shade, 0.1 * shade)
		var mat := _make_material(leaf_color, leaf_color * 0.8)
		var mi := MeshInstance3D.new()
		mi.mesh = sphere
		mi.set_surface_override_material(0, mat)
		mi.position = start
		_vine_root.add_child(mi)

		_segments.append({
			"mesh": mi,
			"start": start,
			"end": end,
			"depth": depth,
			"is_leaf": true,
		})
		return

	var diff: Vector3 = end - start
	var length: float = diff.length()
	if length < 0.001:
		return

	var mid: Vector3 = (start + end) * 0.5

	# Branch cylinder — thinner with depth
	var cyl := CylinderMesh.new()
	cyl.height = length
	var radius_factor: float = max(0.3, 1.0 - depth * 0.2)
	cyl.top_radius = segment_radius * radius_factor * 0.8
	cyl.bottom_radius = segment_radius * radius_factor

	# Darken trunk color with depth
	var brown_val: float = max(0.1, 0.35 - depth * 0.05)
	var green_tint: float = min(0.3, depth * 0.06)
	var branch_color := Color(brown_val * shade, (0.15 + green_tint) * shade, 0.08 * shade)
	var mat := _make_material(branch_color, Color.BLACK)

	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.set_surface_override_material(0, mat)
	mi.position = mid
	_vine_root.add_child(mi)

	# Orient cylinder along segment
	if diff.normalized().length() > 0.01:
		var up := Vector3.UP
		if abs(diff.normalized().dot(up)) > 0.95:
			up = Vector3.RIGHT
		mi.look_at_from_position(mid, mid + diff.normalized(), up)
		mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	_segments.append({
		"mesh": mi,
		"start": start,
		"end": end,
		"depth": depth,
		"is_leaf": false,
	})


func _iterate_l_system() -> void:
	if _iteration_count >= max_iterations:
		return

	var new_string: String = ""
	for ch in _current_string:
		var c: String = ch
		if _rules.has(c):
			new_string += _rules[c]
		else:
			new_string += c

	_current_string = new_string
	_iteration_count += 1
	_build_l_system()


func _process_visual(delta: float) -> void:
	# Iteration timer
	_iteration_timer += delta
	if _iteration_timer >= iteration_interval and _iteration_count < max_iterations:
		_iteration_timer = 0.0
		_iterate_l_system()

	# Walk animation
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 4.0
		for i in range(_leg_roots.size()):
			_leg_roots[i].rotation.x = sin(_walk_phase + float(i) * PI) * 0.2

	# Gentle sway of vine
	if is_instance_valid(_vine_root):
		_vine_root.rotation.z = sin(_walk_phase * 0.3) * 0.05

	# Leaf proximity damage during chase
	if _state == BaseState.CHASE and is_instance_valid(_player_node):
		for seg in _segments:
			if seg["is_leaf"] and is_instance_valid(seg["mesh"]):
				var leaf_world: Vector3 = seg["mesh"].global_position
				var dist: float = leaf_world.distance_to(_player_node.global_position)
				if dist < 0.25:
					var gm = get_node_or_null("/root/GameManager")
					if gm and gm.has_method("apply_health_damage"):
						gm.apply_health_damage(leaf_damage * delta)
					break  # Only one leaf damages per frame

	# Label — the shipped line, plus one line per axis only when that axis is
	# away from its default, so the 1 existing placement's label is untouched.
	if _label:
		var txt: String = "ITERATION: %d, BRANCHES: %d" % [_iteration_count, _segments.size()]
		if evidence != "result":
			txt += "\nEVIDENCE: %s" % evidence
		if habit != "planar":
			txt += "\nHABIT: %s" % habit
		_label.text = txt


func _on_damaged(_amount: float) -> void:
	# Prune a random branch segment (and its children at higher depth)
	if _segments.is_empty():
		_set_state(BaseState.STUNNED)
		return

	# Pick a random segment to prune
	var prune_idx: int = randi() % _segments.size()
	var prune_depth: int = _segments[prune_idx]["depth"]

	# Remove this segment and all segments at deeper depth after it
	var to_remove: Array[int] = [prune_idx]
	for i in range(prune_idx + 1, _segments.size()):
		if _segments[i]["depth"] > prune_depth:
			to_remove.append(i)
		else:
			break  # Stop when we reach same or shallower depth

	# Remove from back to front
	for idx in range(to_remove.size() - 1, -1, -1):
		var ri: int = to_remove[idx]
		if ri < _segments.size():
			if is_instance_valid(_segments[ri]["mesh"]):
				_segments[ri]["mesh"].queue_free()
			_segments.remove_at(ri)

	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.CHASE:
		_iteration_timer = iteration_interval * 0.5  # Iterate sooner when chasing


# ── Configuration ───────────────────────────────────────────────────────

## Called via call_deferred by GridInteractablesComponent, AFTER _ready().
##
## An UNKNOWN value is IGNORED rather than assigned: silently falling back to the
## default is how a sweep publishes N identical frames and calls the axis inert.
## The rebuild happens only when a value actually CHANGED and only once _ready
## has already built — the shipped placement is a bare token with no config, and
## the base's own keys (health, speed, damage) must not redraw the vine.
func apply_grid_config(config_data: Dictionary) -> void:
	super.apply_grid_config(config_data)

	var before_evidence: String = evidence
	var before_habit: String = habit

	if config_data.has("evidence"):
		var want_evidence: String = str(config_data["evidence"]).strip_edges().to_lower()
		if EVIDENCE_VALUES.has(want_evidence):
			evidence = want_evidence

	if config_data.has("habit"):
		var want_habit: String = str(config_data["habit"]).strip_edges().to_lower()
		if HABIT_ROLL.has(want_habit):
			habit = want_habit

	if not _built:
		return
	if evidence == before_evidence and habit == before_habit:
		return

	_build_l_system()
