extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CrisisSynthesisBench

## @identity
## name: Crisis Synthesis Bench — Every Formal System Has an Outside
## concept: The crisis & the edge
## tier: medium
## lineage: the foundations crisis gathered into one statement. The parallel postulate's
##   independence, the set-theoretic paradoxes, Gödel's incompleteness, the impossible
##   figures — read not as a catalogue of failures but as one discovery: formal systems
##   are bounded, and the boundary is generative.
## essence: a bench with one truth at its centre and four small emblems orbiting it — a pair
##   of parallel lines (geometry's many worlds), a paradox loop (self-reference), a Gödel
##   gap (the unprovable truth), an impossible triangle (local-yet-impossible). They circle
##   the same core: EVERY FORMAL SYSTEM HAS AN OUTSIDE.
## truth: not a list of failures — one discovery. The limits of formalisation are a single
##   shape, and that shape has an edge you can stand on.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent: Color = Color(0.45, 0.92, 0.78)
@export var orbit_period: float = 14.0

var _t: float = 0.0
var _emblems: Array = []        # each: { "node": Node3D, "angle0": float, "radius": float, "bob": float }
var _core_mat: StandardMaterial3D
var _core: MeshInstance3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("orbit_period"):
		orbit_period = float(config["orbit_period"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_emblems = []

	var base_mat: StandardMaterial3D = _matte_mat(Color(0.10, 0.11, 0.16), 0.85)
	var purple_mat: StandardMaterial3D = _glow_mat(wire_purple, 0.6)
	var top_y: float = 0.62

	# --- bench: a low pedestal table (~1 m), floor-standing ---
	add_child(_cylinder(Vector3(0.0, top_y, 0.0), 0.5, 0.05, base_mat))
	add_child(_torus(Vector3(0.0, top_y + 0.03, 0.0), 0.48, 0.018, purple_mat))
	# leg
	add_child(_cylinder(Vector3(0.0, top_y * 0.5, 0.0), 0.08, top_y, _steel_mat(Color(0.3, 0.32, 0.4))))
	add_child(_cylinder(Vector3(0.0, 0.03, 0.0), 0.3, 0.06, base_mat))

	# --- the core truth at the centre ---
	_core_mat = _glow_mat(accent, 1.6)
	_core = _sphere(Vector3(0.0, top_y + 0.32, 0.0), 0.1, _core_mat)
	add_child(_core)
	add_child(_torus(Vector3(0.0, top_y + 0.32, 0.0), 0.15, 0.01, _glow_mat(cool_white, 1.0)))

	# --- four orbiting emblems ---
	var orbit_y: float = top_y + 0.32
	var radius: float = 0.34
	_add_emblem(_make_parallels(), 0.0, radius, orbit_y)
	_add_emblem(_make_paradox_loop(), PI * 0.5, radius, orbit_y)
	_add_emblem(_make_godel_gap(), PI, radius, orbit_y)
	_add_emblem(_make_impossible_triangle(), PI * 1.5, radius, orbit_y)

	# --- billboard title (medium: label y ~1.5) ---
	add_child(_billboard_label("EVERY FORMAL SYSTEM", Vector3(0.0, 1.62, 0.0), 22, cool_white))
	add_child(_billboard_label("HAS AN OUTSIDE", Vector3(0.0, 1.46, 0.0), 22, accent))
	add_child(_billboard_label("the crisis — one discovery, not a list", Vector3(0.0, 1.30, 0.0), 12, wire_purple))


func _add_emblem(node: Node3D, angle0: float, radius: float, orbit_y: float) -> void:
	add_child(node)
	node.position = Vector3(cos(angle0) * radius, orbit_y, sin(angle0) * radius)
	_emblems.append({ "node": node, "angle0": angle0, "radius": radius, "y": orbit_y, "bob": _rng.randf() * TAU })


func _make_parallels() -> Node3D:
	# two parallel lines that never meet (geometry's many worlds)
	var n := Node3D.new()
	var mat: StandardMaterial3D = _glow_mat(cool_white, 1.0)
	n.add_child(_cylinder_between(Vector3(-0.09, 0.025, 0.0), Vector3(0.09, 0.025, 0.0), 0.008, mat))
	n.add_child(_cylinder_between(Vector3(-0.09, -0.025, 0.0), Vector3(0.09, -0.025, 0.0), 0.008, mat))
	n.add_child(_billboard_label("∥", Vector3(0.0, 0.10, 0.0), 14, wire_purple))
	return n


func _make_paradox_loop() -> Node3D:
	# a self-referential loop (the liar / Russell knot) — a torus biting its own tail
	var n := Node3D.new()
	var mat: StandardMaterial3D = _glow_mat(accent, 1.2)
	n.add_child(_torus(Vector3.ZERO, 0.07, 0.018, mat))
	# the arrow that points back into itself
	n.add_child(_sphere(Vector3(0.07, 0.0, 0.0), 0.022, _glow_mat(cool_white, 1.2)))
	n.add_child(_billboard_label("↻", Vector3(0.0, 0.11, 0.0), 14, wire_purple))
	return n


func _make_godel_gap() -> Node3D:
	# a tidy little lattice with one glowing empty socket — the unprovable truth
	var n := Node3D.new()
	var cell_mat: StandardMaterial3D = _glow_mat(cool_white, 0.7)
	var gap_mat: StandardMaterial3D = _glow_mat(Color(0.98, 0.80, 0.32), 1.5)
	var idx: int = 0
	var r: int = 0
	while r < 3:
		var c: int = 0
		while c < 3:
			var p: Vector3 = Vector3(-0.06 + float(c) * 0.06, -0.06 + float(r) * 0.06, 0.0)
			if idx == 4:
				# the central GAP — an empty glowing socket
				n.add_child(_box(p, Vector3(0.045, 0.045, 0.012), _glass_mat(Color(0.98, 0.80, 0.32), 0.2)))
				n.add_child(_box(p + Vector3(0.0, 0.022, 0.006), Vector3(0.045, 0.008, 0.014), gap_mat))
				n.add_child(_box(p + Vector3(0.0, -0.022, 0.006), Vector3(0.045, 0.008, 0.014), gap_mat))
			else:
				n.add_child(_box(p, Vector3(0.045, 0.045, 0.02), cell_mat))
			idx += 1
			c += 1
		r += 1
	n.add_child(_billboard_label("⌷", Vector3(0.0, 0.12, 0.0), 14, wire_purple))
	return n


func _make_impossible_triangle() -> Node3D:
	# a Penrose triangle — locally fine, globally impossible
	var n := Node3D.new()
	var mat: StandardMaterial3D = _glow_mat(accent, 1.2)
	var s: float = 0.11
	var h: float = s * 0.866
	var v_bl: Vector3 = Vector3(-s * 0.5, -h / 3.0, 0.0)
	var v_br: Vector3 = Vector3(s * 0.5, -h / 3.0, 0.0)
	var v_top: Vector3 = Vector3(0.0, h * 2.0 / 3.0, 0.0)
	var z_gap: float = s * 0.3
	var v_top_back: Vector3 = v_top + Vector3(0.0, 0.0, -z_gap)
	n.add_child(_bar_box(v_bl, v_br, 0.022, mat))
	n.add_child(_bar_box(v_br, v_top_back, 0.022, mat))
	n.add_child(_bar_box(v_top, v_bl, 0.022, mat))
	n.add_child(_billboard_label("△", Vector3(0.0, 0.12, 0.0), 14, wire_purple))
	return n


func _bar_box(a: Vector3, b: Vector3, thick: float, mat: Material) -> MeshInstance3D:
	var d: Vector3 = b - a
	var length: float = d.length()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(thick, thick, maxf(length, 0.001))
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = (a + b) * 0.5
	if length > 0.001:
		mi.look_at_from_position(mi.position, b, Vector3.UP)
	return mi


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# core truth pulses at the centre
	if _core_mat != null:
		_core_mat.emission_energy_multiplier = (1.6 if emissive else 0.5) * (0.8 + 0.3 * sin(_t * 2.0))

	# emblems orbit the truth, each bobbing and turning to face out
	var w: float = TAU / orbit_period
	var i: int = 0
	while i < _emblems.size():
		var e: Dictionary = _emblems[i]
		var node: Node3D = e["node"]
		if is_instance_valid(node):
			var ang: float = float(e["angle0"]) + _t * w
			var rad: float = float(e["radius"])
			var oy: float = float(e["y"])
			var bob: float = sin(_t * 1.3 + float(e["bob"])) * 0.03
			node.position = Vector3(cos(ang) * rad, oy + bob, sin(ang) * rad)
			node.rotation.y = _t * 0.5 + ang
		i += 1
