extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name OuroborosSignals

## @identity
## lineage: the graph taxonomy's rung 4 — three rotary telephones on plinths in a
##   triangle, cords arcing 1 → 2 → 3 → 1. A ring-pulse circles the loop forever:
##   each phone lights, trembles, and passes the call on. Above them hangs a small
##   rigid grey tree with one dashed red edge from a leaf back up to its ancestor —
##   the edge the engine REFUSES.
## essence: the scene tree is acyclic by refusal (reparent a node under its own
##   descendant and Godot errors), but signals lay a SECOND graph over the tree, and
##   connect() will happily close a ring. The call has no origin any more; it simply
##   circulates. This artifact's pulse is driven by three actual signal connections.
## truth: the tree refuses cycles; signals permit them. A call can outlive its caller.
##
## The 2026-08-27 graph taxonomy (doc/GRAPHTHEORY_TAXONOMY.md), rung 4 of 13.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

signal ring_a
signal ring_b
signal ring_c

@export var seed: int = 43
@export var period: float = 1.1         # seconds per hop

var _phones: Array = []                 # {node, mat}
var _hop_clock := 0.0
var _which := 0

func _ready() -> void:
	_rng.seed = seed
	_which = _rng.randi_range(0, 2)
	# the ring, as REAL signal edges: a fires b's phone, b fires c's, c fires a's
	ring_a.connect(func() -> void: _light(0))
	ring_b.connect(func() -> void: _light(1))
	ring_c.connect(func() -> void: _light(2))
	_build_phones()
	_build_refused_tree()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "period"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	_hop_clock += delta
	if _hop_clock >= period:
		_hop_clock = 0.0
		_which = (_which + 1) % 3
		[ring_a, ring_b, ring_c][_which].emit()
	# decay every lamp toward dark; _light() re-fires the current one
	for p in _phones:
		var m: StandardMaterial3D = p["mat"]
		m.emission_energy_multiplier = maxf(m.emission_energy_multiplier - delta * 2.2, 0.15)
		var ph: Node3D = p["node"]
		ph.rotation.z = lerp_angle(ph.rotation.z, 0.0, delta * 6.0)

func _light(i: int) -> void:
	var m: StandardMaterial3D = _phones[i]["mat"]
	m.emission_energy_multiplier = 2.6
	var ph: Node3D = _phones[i]["node"]
	ph.rotation.z = 0.12                # the handset's startled tremble

# --- three phones and their arcing cords --------------------------------------------

func _build_phones() -> void:
	var tints := [Color(0.85, 0.25, 0.2), Color(0.9, 0.75, 0.2), Color(0.25, 0.5, 0.9)]
	var centers: Array = []
	for i in range(3):
		var ang := TAU * float(i) / 3.0 + PI / 6.0
		var at := Vector3(cos(ang) * 1.05, 0.0, sin(ang) * 1.05)
		centers.append(at + Vector3(0.0, 0.98, 0.0))
		var plinth := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.22
		pm.bottom_radius = 0.26
		pm.height = 0.85
		plinth.mesh = pm
		plinth.position = at + Vector3(0.0, 0.425, 0.0)
		plinth.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.9)
		add_child(plinth)
		var phone := Node3D.new()
		phone.position = at + Vector3(0.0, 0.9, 0.0)
		add_child(phone)
		var mat := _glow_mat(tints[i], 0.15)
		var body := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.26, 0.14, 0.2)
		body.mesh = bm
		body.position = Vector3(0.0, 0.07, 0.0)
		body.material_override = mat
		phone.add_child(body)
		var handset := MeshInstance3D.new()
		var hm := CapsuleMesh.new()
		hm.radius = 0.035
		hm.height = 0.3
		handset.mesh = hm
		handset.rotation.z = PI * 0.5
		handset.position = Vector3(0.0, 0.18, 0.0)
		handset.material_override = mat
		phone.add_child(handset)
		var dial := MeshInstance3D.new()
		var dm := CylinderMesh.new()
		dm.top_radius = 0.055
		dm.bottom_radius = 0.055
		dm.height = 0.015
		dial.mesh = dm
		dial.rotation.x = PI * 0.5
		dial.position = Vector3(0.0, 0.08, 0.105)
		dial.material_override = _steel_mat(Color(0.75, 0.73, 0.7))
		phone.add_child(dial)
		_phones.append({"node": phone, "mat": mat})
	# directed cords: low sagging arcs drawn as chained segments, with an arrowhead
	for i in range(3):
		var a: Vector3 = centers[i]
		var b: Vector3 = centers[(i + 1) % 3]
		var segs := 9
		for k in range(segs):
			var t0 := float(k) / float(segs)
			var t1 := float(k + 1) / float(segs)
			var p0 := a.lerp(b, t0) + Vector3(0.0, -0.28 * sin(PI * t0), 0.0)
			var p1 := a.lerp(b, t1) + Vector3(0.0, -0.28 * sin(PI * t1), 0.0)
			var seg := MeshInstance3D.new()
			var sm := CylinderMesh.new()
			sm.top_radius = 0.012
			sm.bottom_radius = 0.012
			sm.height = p0.distance_to(p1)
			seg.mesh = sm
			seg.position = (p0 + p1) * 0.5
			var dir := (p1 - p0).normalized()
			var axis := Vector3.UP.cross(dir)
			if axis.length() > 0.001:
				seg.rotate(axis.normalized(), acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0)))
			seg.material_override = _glow_mat(Color(0.9, 0.8, 0.5), 0.45)
			add_child(seg)
		var head := MeshInstance3D.new()
		var am := CylinderMesh.new()
		am.top_radius = 0.0
		am.bottom_radius = 0.045
		am.height = 0.11
		head.mesh = am
		var tip := a.lerp(b, 0.93) + Vector3(0.0, -0.28 * sin(PI * 0.93), 0.0)
		head.position = tip
		var dir2 := (b - tip).normalized()
		var axis2 := Vector3.UP.cross(dir2)
		if axis2.length() > 0.001:
			head.rotate(axis2.normalized(), acos(clampf(Vector3.UP.dot(dir2), -1.0, 1.0)))
		head.material_override = _glow_mat(Color(0.9, 0.8, 0.5), 0.9)
		add_child(head)

# --- the refused edge ---------------------------------------------------------------

func _build_refused_tree() -> void:
	# a small rigid tree floating above the ring: root, two children, one grandchild —
	# and a dashed red edge from the grandchild BACK to the root, going nowhere
	var grey := _matte_mat(Color(0.45, 0.45, 0.5), 0.6)
	var pts := {
		"root": Vector3(0.0, 2.55, 0.0),
		"a": Vector3(-0.35, 2.2, 0.1),
		"b": Vector3(0.35, 2.2, -0.1),
		"ga": Vector3(-0.5, 1.85, 0.2),
	}
	for k in pts:
		var n := MeshInstance3D.new()
		var nm := SphereMesh.new()
		nm.radius = 0.05
		nm.height = 0.1
		n.mesh = nm
		n.position = pts[k]
		n.material_override = grey
		add_child(n)
	for pair in [["root", "a"], ["root", "b"], ["a", "ga"]]:
		var a: Vector3 = pts[pair[0]]
		var b: Vector3 = pts[pair[1]]
		var e := MeshInstance3D.new()
		var em := CylinderMesh.new()
		em.top_radius = 0.01
		em.bottom_radius = 0.01
		em.height = a.distance_to(b)
		e.mesh = em
		e.position = (a + b) * 0.5
		var dir := (b - a).normalized()
		var axis := Vector3.UP.cross(dir)
		if axis.length() > 0.001:
			e.rotate(axis.normalized(), acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0)))
		e.material_override = grey
		add_child(e)
	# the refusal: grandchild back to root, dashed (short segments), red
	var a2: Vector3 = pts["ga"]
	var b2: Vector3 = pts["root"]
	for k in range(5):
		var t0 := float(k) / 5.0 + 0.03
		var t1 := t0 + 0.11
		var p0 := a2.lerp(b2, t0)
		var p1 := a2.lerp(b2, t1)
		var dash := MeshInstance3D.new()
		var dm := CylinderMesh.new()
		dm.top_radius = 0.008
		dm.bottom_radius = 0.008
		dm.height = p0.distance_to(p1)
		dash.mesh = dm
		dash.position = (p0 + p1) * 0.5
		var dir := (p1 - p0).normalized()
		var axis := Vector3.UP.cross(dir)
		if axis.length() > 0.001:
			dash.rotate(axis.normalized(), acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0)))
		dash.material_override = _glow_mat(Color(0.9, 0.15, 0.1), 0.8)
		add_child(dash)

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "OuroborosPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-1.3, 0.24, 1.1)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("OUROBOROS SIGNALS",
			"The tree above refuses its red edge - reparent under your own descendant\nand the engine errors. The cords below are real connect() edges, and the\ncall circles them forever: signals permit the cycles the tree cannot.")
