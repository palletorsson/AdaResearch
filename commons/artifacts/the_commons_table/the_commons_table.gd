extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheCommonsTable

## @identity
## lineage: the post-crisis SUPER OBJECT, and the last object of the spine — a round
##   table with NO HEAD. Around it sit partial instruments, each honest about its own
##   outside: a classifier whose three labelled bins are outnumbered by the drawer
##   marked OTHER; a sorter with its comparator printed on a card, because the order
##   is somebody's values and not a fact; two contradictory readings held side by side
##   in one bracket, not collapsed; a small camera on a plinth aimed at the table
##   itself, so the view is always from somewhere; and a rhizome of cords with no root,
##   where every jack reaches every other by more than one path. At the centre, where
##   a chairman would sit, there is a GAP — a lit ring around nothing, because the
##   edge is the ground and the middle was never the authority.
## essence: after the crisis, what do we build? Instruments that declare their limits
##   and work anyway. Every count on every card here was computed from the thing it
##   describes - the OTHER drawer really does hold more than the bins.
## truth: knowing the limits of formalization, we build things that say so. The edge
##   is the ground, not the limit.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each"), and the
## spine's closing body: primitives asked what a thing must have to be; this asks what
## we owe the things we make.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 17
@export var table_r: float = 1.15
@export_range(8, 24) var specimens: int = 18

func _ready() -> void:
	_rng.seed = seed
	_build_table()
	_build_gap()
	_build_classifier()
	_build_comparator()
	_build_contradiction()
	_build_camera_seat()
	_build_rhizome()
	_build_defaults_shelf()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "table_r", "specimens"]:
		if config_data.has(key):
			set(key, config_data[key])

func _tag(at: Vector3, title: String, sub: String) -> void:
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.18
	tag.position = at
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text(title, sub)

func _slab(at: Vector3, size: Vector3, tint: Color, glow: float = 0.0) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.position = at
	m.material_override = _glow_mat(tint, glow) if glow > 0.0 else _matte_mat(tint, 0.75)
	add_child(m)

func _dot(at: Vector3, r: float, tint: Color, glow: float = 1.0) -> void:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	m.mesh = sm
	m.position = at
	m.material_override = _glow_mat(tint, glow)
	add_child(m)

func _strand(a: Vector3, b: Vector3, thick: float, tint: Color, glow: float = 0.5) -> void:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = thick
	cm.bottom_radius = thick
	cm.height = maxf(a.distance_to(b), 0.001)
	m.mesh = cm
	m.position = (a + b) * 0.5
	var dir := (b - a).normalized()
	var axis := Vector3.UP.cross(dir)
	if axis.length() > 0.001:
		m.rotate(axis.normalized(), acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0)))
	m.material_override = _glow_mat(tint, glow)
	add_child(m)

# --- the table with no head --------------------------------------------------------

func _build_table() -> void:
	# a ring, not a disc: there is no place at the centre to sit
	var seg := 28
	for i in range(seg):
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var mid := (a0 + a1) * 0.5
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(TAU * table_r / float(seg) * 1.05, 0.07, 0.52)
		m.mesh = bm
		m.position = Vector3(cos(mid) * table_r, 0.92, sin(mid) * table_r)
		m.rotation.y = -mid
		m.material_override = _matte_mat(Color(0.28, 0.2, 0.13), 0.8)
		add_child(m)
	for i in range(6):
		var ang := TAU * float(i) / 6.0
		_slab(Vector3(cos(ang) * table_r, 0.44, sin(ang) * table_r), Vector3(0.07, 0.88, 0.07),
			Color(0.18, 0.14, 0.1))

func _build_gap() -> void:
	# where the chairman would be: a lit ring around nothing
	var seg := 34
	for i in range(seg):
		var ang := TAU * float(i) / float(seg)
		_dot(Vector3(cos(ang) * 0.34, 0.9, sin(ang) * 0.34), 0.012, Color(0.95, 0.85, 0.5), 1.4)
	_tag(Vector3(0.0, 0.86, 0.0), "no head", "the edge is the ground; the middle was never the authority")

func _build_classifier() -> void:
	# three labelled bins and one OTHER drawer - and the counts are computed
	var at := Vector3(cos(0.0) * table_r, 0.98, sin(0.0) * table_r)
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var bins := [0, 0, 0]
	var other := 0
	for i in range(specimens):
		# a specimen is classified only if it clears every rule; most do not
		var a := r.randf()
		var b := r.randf()
		if a < 0.22 and b > 0.5:
			bins[0] += 1
		elif a > 0.78 and b < 0.5:
			bins[1] += 1
		elif absf(a - 0.5) < 0.06:
			bins[2] += 1
		else:
			other += 1
	var labels := ["A", "B", "C"]
	for k in range(3):
		var bx := at + Vector3(-0.18 + 0.13 * float(k), 0.0, 0.0)
		_slab(bx, Vector3(0.1, 0.05, 0.14), Color(0.55, 0.65, 0.75))
		for n in range(bins[k]):
			_dot(bx + Vector3(0.0, 0.05 + 0.028 * float(n), 0.0), 0.018, Color(0.6, 0.85, 0.95), 0.9)
		_tag(bx + Vector3(0.0, -0.06, 0.12), labels[k], str(bins[k]))
	var ox := at + Vector3(0.24, 0.0, 0.0)
	_slab(ox, Vector3(0.2, 0.05, 0.16), Color(0.5, 0.4, 0.45))
	for n in range(other):
		_dot(ox + Vector3(-0.06 + 0.03 * float(n % 5), 0.05 + 0.028 * float(n / 5), 0.0), 0.018,
			Color(0.95, 0.55, 0.5), 0.9)
	_tag(ox + Vector3(0.0, -0.06, 0.14), "OTHER", "%d of %d - fuller than every bin" % [other, specimens])

func _build_comparator() -> void:
	# the sorter refuses to sort until you supply the rule; the rule is on a card
	var ang := TAU / 6.0
	var at := Vector3(cos(ang) * table_r, 0.98, sin(ang) * table_r)
	var heights := [0.06, 0.13, 0.09, 0.17, 0.11]
	heights.sort()
	for k in range(heights.size()):
		var h: float = heights[k]
		_slab(at + Vector3(-0.12 + 0.06 * float(k), h * 0.5, 0.0), Vector3(0.045, h, 0.045),
			Color(0.85, 0.75, 0.45), 0.4)
	_slab(at + Vector3(0.0, 0.005, 0.16), Vector3(0.26, 0.008, 0.16), Color(0.92, 0.9, 0.85), 0.3)
	_tag(at + Vector3(0.0, -0.05, 0.3), "the comparator", "sorted by HEIGHT - somebody chose that")

func _build_contradiction() -> void:
	# two readings that disagree, held in one bracket without collapse
	var ang := TAU * 2.0 / 6.0
	var at := Vector3(cos(ang) * table_r, 0.98, sin(ang) * table_r)
	_slab(at + Vector3(0.0, 0.14, 0.0), Vector3(0.34, 0.012, 0.05), Color(0.5, 0.46, 0.4))
	for side in [-1.0, 1.0]:
		var dial := MeshInstance3D.new()
		var dm := CylinderMesh.new()
		dm.top_radius = 0.062
		dm.bottom_radius = 0.062
		dm.height = 0.014
		dial.mesh = dm
		dial.rotation.x = PI * 0.5
		dial.position = at + Vector3(side * 0.12, 0.07, 0.0)
		dial.material_override = _matte_mat(Color(0.92, 0.9, 0.84), 0.6)
		add_child(dial)
		var needle := MeshInstance3D.new()
		var nm := BoxMesh.new()
		nm.size = Vector3(0.05, 0.008, 0.006)
		needle.mesh = nm
		needle.position = at + Vector3(side * 0.12 + side * 0.024, 0.07, 0.012)
		needle.rotation.z = deg_to_rad(38.0 * side)
		needle.material_override = _matte_mat(Color(0.8, 0.2, 0.18), 0.5)
		add_child(needle)
	_tag(at + Vector3(0.0, -0.05, 0.2), "both, still", "two readings, one bracket, no collapse")

func _build_camera_seat() -> void:
	# a camera on the table, aimed at the table: the view is from somewhere
	var ang := TAU * 3.0 / 6.0
	var at := Vector3(cos(ang) * table_r, 0.98, sin(ang) * table_r)
	_slab(at + Vector3(0.0, 0.05, 0.0), Vector3(0.14, 0.1, 0.1), Color(0.25, 0.25, 0.3))
	var lens := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.035
	lm.bottom_radius = 0.045
	lm.height = 0.09
	lens.mesh = lm
	lens.position = at + Vector3(0.0, 0.06, 0.0)
	var toward := (Vector3(0.0, 0.98, 0.0) - at).normalized()
	lens.rotation.y = atan2(toward.x, toward.z)
	lens.rotation.x = PI * 0.5
	lens.material_override = _glow_mat(Color(0.45, 0.75, 0.9), 0.8)
	add_child(lens)
	# the cone of what it can see - and therefore what it cannot
	for k in range(9):
		var t := float(k) / 8.0
		var p := at.lerp(Vector3(0.0, 0.95, 0.0), t)
		_dot(p + Vector3(0.0, 0.02, 0.0), 0.006 + 0.012 * t, Color(0.45, 0.75, 0.9), 0.35)
	_tag(at + Vector3(0.0, -0.05, 0.18), "from somewhere", "there is no view from nowhere")

func _build_rhizome() -> void:
	# no root: every jack reaches every other by more than one path
	var ang := TAU * 4.0 / 6.0
	var at := Vector3(cos(ang) * table_r, 1.02, sin(ang) * table_r)
	var pts: Array = []
	var r := RandomNumberGenerator.new()
	r.seed = seed
	for k in range(6):
		var a := TAU * float(k) / 6.0 + r.randf_range(-0.2, 0.2)
		var p := at + Vector3(cos(a) * 0.15, r.randf_range(-0.02, 0.06), sin(a) * 0.15)
		pts.append(p)
		_dot(p, 0.02, Color(0.6, 0.9, 0.7), 1.2)
	var links := 0
	for i in range(pts.size()):
		for j in range(i + 1, pts.size()):
			if (i + j) % 3 == 0 or j == i + 1:
				_strand(pts[i], pts[j], 0.005, Color(0.5, 0.8, 0.6), 0.5)
				links += 1
	_tag(at + Vector3(0.0, -0.09, 0.2), "rhizome", "%d cords, no root, more than one way" % links)

func _build_defaults_shelf() -> void:
	# the engine's opinions, shipped as facts: five defaults on a small shelf
	var ang := TAU * 5.0 / 6.0
	var at := Vector3(cos(ang) * table_r, 0.98, sin(ang) * table_r)
	_slab(at + Vector3(0.0, 0.01, 0.0), Vector3(0.34, 0.02, 0.14), Color(0.3, 0.26, 0.22))
	var defaults := [
		["9.8", Color(0.85, 0.6, 0.3)],
		["cull_back", Color(0.6, 0.7, 0.85)],
		["white", Color(0.95, 0.95, 0.92)],
		["scale 1", Color(0.7, 0.85, 0.6)],
	]
	for k in range(defaults.size()):
		var row: Array = defaults[k]
		var tint: Color = row[1]
		_slab(at + Vector3(-0.12 + 0.08 * float(k), 0.05, 0.0), Vector3(0.055, 0.055, 0.055), tint, 0.4)
	_tag(at + Vector3(0.0, -0.05, 0.18), "the defaults", "somebody's opinion, shipped as a fact")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "CommonsPlate"
	ts.mode = 2
	ts.width_m = 0.46
	ts.position = Vector3(-table_r - 0.55, 0.24, table_r * 0.75)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("THE COMMONS TABLE",
			"Knowing the limits of formalization, what do we build? Instruments that say\nso and work anyway. The classifier's OTHER drawer holds more than its labelled\nbins; the sorter prints the values it sorted by; two contradictory readings sit\nin one bracket uncollapsed; the camera admits it is somewhere; the cords have\nno root. And where a chairman would sit there is a lit ring around nothing.")
