extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EuclidParallelBench

## @identity
## name: Euclid & the Parallel Postulate
## lineage: the fifth of Euclid's axioms — the one nobody could derive from the
##   other four, and whose denial opened non-Euclidean geometry two thousand
##   years later.
## essence: two perfectly parallel chalk rails run toward a vanishing point. A
##   transversal crosses both; the equal corresponding angles glow. Beside a
##   marked point floats the postulate: through a point not on a line, exactly
##   ONE parallel can be drawn.
## truth: the one axiom nobody could prove from the others — assumed, never
##   demonstrated, and in the end simply one choice among many possible worlds.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent_gold: Color = Color(0.98, 0.80, 0.32)
@export var rail_length: float = 1.4
@export var rail_gap: float = 0.46

var _angle_a: Node3D
var _angle_b: Node3D
var _point_dot: MeshInstance3D
var _parallel_ghost: Node3D
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	var white_mat := _glow_mat(cool_white, 0.7)
	var purple_mat := _glow_mat(wire_purple, 0.8)
	var gold_mat := _glow_mat(accent_gold, 1.3)

	# floor chalk disc the whole diagram sits on
	add_child(_torus(Vector3(0.0, 0.02, 0.0), 0.72, 0.01, purple_mat))

	# --- two parallel rails converging to a vanishing point ---
	# near ends are rail_gap apart; far ends nearly meet (perspective vanishing)
	var y: float = 0.42
	var near_z: float = rail_length * 0.5
	var far_z: float = -rail_length * 0.5
	var near_off: float = rail_gap * 0.5
	var far_off: float = rail_gap * 0.06  # converge toward a point
	var rail_l_near := Vector3(-near_off, y, near_z)
	var rail_l_far := Vector3(-far_off, y, far_z)
	var rail_r_near := Vector3(near_off, y, near_z)
	var rail_r_far := Vector3(far_off, y, far_z)
	add_child(_cylinder_between(rail_l_near, rail_l_far, 0.012, white_mat))
	add_child(_cylinder_between(rail_r_near, rail_r_far, 0.012, white_mat))

	# vanishing point marker where they would meet
	var vp := Vector3(0.0, y, far_z - 0.08)
	add_child(_sphere(vp, 0.02, gold_mat))
	add_child(_billboard_label("vanishing point", vp + Vector3(0.0, 0.14, 0.0), 13, accent_gold))

	# --- transversal crossing both rails ---
	var cross_near := Vector3(-near_off - 0.10, y, 0.10)
	var cross_far := Vector3(near_off + 0.10, y, 0.34)
	add_child(_cylinder_between(cross_near, cross_far, 0.01, purple_mat))

	# equal corresponding angles where the transversal meets each rail (glowing arcs)
	var hit_l := Vector3(-lerpf(near_off, far_off, 0.18), y, lerpf(near_z, far_z, 0.18))
	var hit_r := Vector3(lerpf(near_off, far_off, 0.30), y, lerpf(near_z, far_z, 0.30))
	_angle_a = _make_angle_arc(hit_l, gold_mat)
	_angle_b = _make_angle_arc(hit_r, gold_mat)
	add_child(_angle_a)
	add_child(_angle_b)
	add_child(_billboard_label("=", (hit_l + hit_r) * 0.5 + Vector3(0.0, 0.12, 0.0), 22, accent_gold))

	# --- the marked point not on the line, with its single parallel ---
	var pt := Vector3(0.40, y, 0.05)
	_point_dot = _sphere(pt, 0.024, gold_mat)
	add_child(_point_dot)
	add_child(_billboard_label("P", pt + Vector3(0.0, 0.10, 0.0), 18, cool_white))
	# the one parallel drawn through P (a ghost rail, animated to "draw")
	_parallel_ghost = Node3D.new()
	add_child(_parallel_ghost)

	# --- the postulate, stated ---
	add_child(_billboard_label("EUCLID — THE PARALLEL POSTULATE", Vector3(0.0, 1.62, 0.0), 30, cool_white))
	add_child(_billboard_label("through a point not on a line, exactly ONE parallel", Vector3(0.0, 1.48, 0.0), 15, wire_purple))
	add_child(_billboard_label("the one axiom nobody could prove from the others", Vector3(0.0, 1.36, 0.0), 13, accent_gold))


func _make_angle_arc(at: Vector3, mat: Material) -> Node3D:
	# a small glowing wedge of cylinders marking an angle, sitting flat-ish
	var root := Node3D.new()
	root.position = at
	var r: float = 0.09
	var steps: int = 5
	for i in range(steps):
		var f0: float = float(i) / float(steps)
		var f1: float = float(i + 1) / float(steps)
		var a0: float = lerpf(0.2, 1.1, f0)
		var a1: float = lerpf(0.2, 1.1, f1)
		var p0 := Vector3(cos(a0) * r, 0.0, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0.0, sin(a1) * r)
		root.add_child(_cylinder_between(p0, p1, 0.006, mat))
	return root


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# the equal angles pulse together — they are congruent
	var pulse: float = 0.5 + 0.5 * sin(_t * 2.0)
	if is_instance_valid(_angle_a):
		_angle_a.scale = Vector3.ONE * (1.0 + pulse * 0.12)
	if is_instance_valid(_angle_b):
		_angle_b.scale = Vector3.ONE * (1.0 + pulse * 0.12)

	# the point P breathes gold
	if is_instance_valid(_point_dot):
		var m: StandardMaterial3D = _point_dot.material_override as StandardMaterial3D
		if m != null:
			m.emission_energy_multiplier = (1.0 if emissive else 0.3) * (1.0 + pulse * 0.8)

	# the single parallel "draws" itself through P, sweeping out and back
	if is_instance_valid(_parallel_ghost):
		for c in _parallel_ghost.get_children():
			_parallel_ghost.remove_child(c)
			c.queue_free()
		var grow: float = 0.5 + 0.5 * sin(_t * 0.9)
		var y: float = 0.42
		var pt := Vector3(0.40, y, 0.05)
		var half: float = lerpf(0.08, rail_length * 0.5, grow)
		var a := pt + Vector3(0.0, 0.0, half)
		var b := pt + Vector3(0.0, 0.0, -half)
		var ghost_mat := _glow_mat(accent_gold, 1.0)
		var seg: MeshInstance3D = _cylinder_between(a, b, 0.009, ghost_mat)
		_parallel_ghost.add_child(seg)
