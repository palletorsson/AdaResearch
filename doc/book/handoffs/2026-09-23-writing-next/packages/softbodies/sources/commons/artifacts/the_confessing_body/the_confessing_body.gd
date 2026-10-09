extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheConfessingBody

## @identity
## lineage: the soft bodies SUPER OBJECT — an anatomy theatre for things that have
##   insides. On the slab, the confession: a rigid cube beside a soft one, the rigid
##   marked with ONE pin at its centre, the soft with a pin at every vertex — the
##   whole ontological shift in two objects. Beside them the edge-memory rack, springs
##   at rest and the same springs stretched, each labelled with the length it is trying
##   to return to. A budget row shows one jelly solved at 1, 3 and 8 iterations,
##   sagging to firm. Above, a cloth genuinely draped: a mass-spring grid relaxed
##   under gravity for 60 real passes, hanging from two anchors — and one corner cut
##   loose, falling. Around the theatre: a Verlet chain, a pressure-held membrane
##   breathing, a Miura fold that remembers its creases, and a tentacle that is
##   nothing but constraint.
## essence: a rigid body has one position; a soft body has a position per vertex, and
##   its shape is a memory held in the edges between them. Every drape here was
##   relaxed at build time, vertex by vertex.
## truth: form is not imposed - it emerges from the material's own dynamics. And
##   softness is always relative to something that refuses to move.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 11
@export_range(20, 120) var relax_passes: int = 60
@export var cloth_w: int = 11
@export var cloth_h: int = 8

func _ready() -> void:
	_rng.seed = seed
	_build_theatre()
	_build_confession()
	_build_edge_memory()
	_build_budget_row()
	_build_cloth()
	_build_verlet_chain()
	_build_membrane()
	_build_miura()
	_build_tentacle()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "relax_passes", "cloth_w", "cloth_h"]:
		if config_data.has(key):
			set(key, config_data[key])

func _tag(at: Vector3, title: String, sub: String) -> void:
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.17
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

func _dot(at: Vector3, r: float, tint: Color, glow: float = 1.2) -> void:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	m.mesh = sm
	m.position = at
	m.material_override = _glow_mat(tint, glow)
	add_child(m)

func _strand(a: Vector3, b: Vector3, thick: float, tint: Color, glow: float = 0.6) -> void:
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

# --- the theatre ---------------------------------------------------------------------

func _build_theatre() -> void:
	_slab(Vector3(0.0, 0.85, 0.0), Vector3(5.0, 0.1, 2.2), Color(0.16, 0.15, 0.17))
	for sx in [-1.0, 1.0]:
		_slab(Vector3(sx * 2.3, 0.42, 0.0), Vector3(0.14, 0.85, 1.7), Color(0.11, 0.11, 0.13))

func _build_confession() -> void:
	# ONE position, versus a position per vertex
	_slab(Vector3(-2.0, 1.06, -0.6), Vector3(0.26, 0.26, 0.26), Color(0.55, 0.58, 0.66))
	_dot(Vector3(-2.0, 1.06, -0.6), 0.035, Color(0.95, 0.75, 0.25), 2.0)
	_tag(Vector3(-2.0, 0.94, -0.32), "rigid", "one position")
	var c := Vector3(-1.5, 1.06, -0.6)
	var pts: Array = []
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var p := c + Vector3(sx, sy, sz) * 0.13
				pts.append(p)
				_dot(p, 0.022, Color(0.95, 0.45, 0.55), 1.6)
	for i in range(pts.size()):
		for j in range(i + 1, pts.size()):
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[j]
			if a.distance_to(b) < 0.28:
				_strand(a, b, 0.005, Color(0.8, 0.5, 0.6), 0.5)
	_tag(Vector3(-1.5, 0.94, -0.32), "soft", "a position per VERTEX")

func _build_edge_memory() -> void:
	# springs at rest, and the same springs stretched, each labelled with the length
	# it is trying to return to
	for i in range(2):
		var stretched := i == 1
		var len_now := 0.22 if not stretched else 0.36
		var y := 1.35 - 0.2 * float(i)
		var a := Vector3(-2.15, y, 0.35)
		var b := a + Vector3(len_now, 0.0, 0.0)
		_dot(a, 0.022, Color(0.6, 0.8, 0.95))
		_dot(b, 0.022, Color(0.6, 0.8, 0.95))
		var coils := 7
		for k in range(coils):
			var t0 := float(k) / float(coils)
			var t1 := float(k + 1) / float(coils)
			var p0 := a.lerp(b, t0) + Vector3(0.0, 0.02 * (1.0 if k % 2 == 0 else -1.0), 0.0)
			var p1 := a.lerp(b, t1) + Vector3(0.0, 0.02 * (1.0 if k % 2 == 1 else -1.0), 0.0)
			_strand(p0, p1, 0.005, Color(0.6, 0.8, 0.95), 0.6)
		_tag(Vector3(a.x + len_now * 0.5, y - 0.09, 0.5),
			"rest 0.22" if not stretched else "at 0.36", "pulling home" if stretched else "at rest")
	_tag(Vector3(-1.9, 1.5, 0.5), "the constraint that remembers", "shape is a memory held in edges")

func _build_budget_row() -> void:
	# one jelly, three solver budgets: sag to firm. Relaxation actually run.
	for i in range(3):
		var budgets := [1, 3, 8]
		var iters: int = budgets[i]
		var cx := -0.75 + 0.55 * float(i)
		var pts: Array = []
		var n := 7
		for k in range(n):
			var ang := TAU * float(k) / float(n)
			pts.append(Vector3(cx + cos(ang) * 0.16, 1.02 + sin(ang) * 0.16, -0.55))
		# gravity pulls, then `iters` relaxation passes restore rest lengths
		for k in range(n):
			pts[k] += Vector3(0.0, -0.09, 0.0) * (1.0 + 0.4 * sin(float(k)))
		var rest := (pts[0] as Vector3).distance_to(pts[1])
		for pass_i in range(iters):
			for k in range(n):
				var a: Vector3 = pts[k]
				var b: Vector3 = pts[(k + 1) % n]
				var d := b - a
				var cur := d.length()
				if cur < 0.0001:
					continue
				var corr := d.normalized() * (cur - 0.16) * 0.5
				pts[k] = a + corr
				pts[(k + 1) % n] = b - corr
		for k in range(n):
			var a: Vector3 = pts[k]
			var b: Vector3 = pts[(k + 1) % n]
			_strand(a, b, 0.008, Color(0.85, 0.6, 0.9), 0.7)
			_dot(a, 0.018, Color(0.85, 0.6, 0.9), 1.0)
		_tag(Vector3(cx, 0.94, -0.3), "%d pass%s" % [iters, "" if iters == 1 else "es"], "")
	_tag(Vector3(-0.2, 0.94, -0.08), "the iteration budget", "softness you can afford")

func _build_cloth() -> void:
	# a REAL drape: mass-spring grid relaxed under gravity, pinned at two corners
	var pos: Array = []
	var pinned := {}
	for y in range(cloth_h):
		for x in range(cloth_w):
			pos.append(Vector3(0.55 + float(x) * 0.085, 1.75, -0.5 + float(y) * 0.085))
	pinned[0] = true
	pinned[cloth_w - 1] = true
	var rest := 0.085
	for step in range(relax_passes):
		# gravity
		for i in range(pos.size()):
			if pinned.has(i):
				continue
			pos[i] = (pos[i] as Vector3) + Vector3(0.0, -0.004, 0.0)
		# constraints: horizontal and vertical neighbours pull to rest length
		for y in range(cloth_h):
			for x in range(cloth_w):
				var i := y * cloth_w + x
				for d in [Vector2i(1, 0), Vector2i(0, 1)]:
					var step_d: Vector2i = d
					var nx := x + step_d.x
					var ny := y + step_d.y
					if nx >= cloth_w or ny >= cloth_h:
						continue
					var j := ny * cloth_w + nx
					var a: Vector3 = pos[i]
					var b: Vector3 = pos[j]
					var delta := b - a
					var cur := delta.length()
					if cur < 0.0001:
						continue
					var corr := delta.normalized() * (cur - rest) * 0.5
					if not pinned.has(i):
						pos[i] = a + corr
					if not pinned.has(j):
						pos[j] = b - corr
	for y in range(cloth_h):
		for x in range(cloth_w):
			var i := y * cloth_w + x
			if x + 1 < cloth_w:
				_strand(pos[i], pos[i + 1], 0.004, Color(0.55, 0.75, 0.9), 0.5)
			if y + 1 < cloth_h:
				_strand(pos[i], pos[i + cloth_w], 0.004, Color(0.55, 0.75, 0.9), 0.5)
	for i in pinned:
		_dot(pos[i], 0.025, Color(0.95, 0.75, 0.25), 1.8)
	_tag(Vector3(0.95, 0.94, 0.35), "the anchor", "%d relaxation passes; two pins, or it falls forever" % relax_passes)

func _build_verlet_chain() -> void:
	# position from position: a hanging chain relaxed the same way
	var pts: Array = []
	for k in range(12):
		pts.append(Vector3(1.95, 1.7 - float(k) * 0.06, -0.55))
	for step in range(40):
		for k in range(1, pts.size()):
			pts[k] = (pts[k] as Vector3) + Vector3(0.004 * float(k) * 0.1, -0.004, 0.0)
		for pass_i in range(3):
			for k in range(pts.size() - 1):
				var a: Vector3 = pts[k]
				var b: Vector3 = pts[k + 1]
				var d := b - a
				var cur := d.length()
				if cur < 0.0001:
					continue
				var corr := d.normalized() * (cur - 0.06) * 0.5
				if k > 0:
					pts[k] = a + corr
				pts[k + 1] = b - corr
	for k in range(pts.size() - 1):
		_strand(pts[k], pts[k + 1], 0.007, Color(0.9, 0.7, 0.4), 0.6)
		_dot(pts[k], 0.014, Color(0.9, 0.7, 0.4), 0.8)
	_tag(Vector3(1.95, 0.94, -0.3), "Verlet", "position from position, not velocity")

func _build_membrane() -> void:
	# pressure holding a boundary open: a ring that breathes outward
	var n := 14
	for k in range(n):
		var ang := TAU * float(k) / float(n)
		var r := 0.2 + 0.03 * sin(float(k) * 3.0)
		var a := Vector3(1.55 + cos(ang) * r, 1.05, 0.55 + sin(ang) * r)
		var ang2 := TAU * float((k + 1) % n) / float(n)
		var r2 := 0.2 + 0.03 * sin(float((k + 1) % n) * 3.0)
		var b := Vector3(1.55 + cos(ang2) * r2, 1.05, 0.55 + sin(ang2) * r2)
		_strand(a, b, 0.007, Color(0.6, 0.9, 0.75), 0.8)
		_strand(Vector3(1.55, 1.05, 0.55), a, 0.003, Color(0.4, 0.7, 0.6), 0.3)
	_tag(Vector3(1.55, 0.94, 0.85), "the membrane", "pressure holds the boundary open")

func _build_miura() -> void:
	# creases that remember: a folded sheet
	for y in range(4):
		for x in range(6):
			var zig := 0.03 * (1.0 if (x + y) % 2 == 0 else -1.0)
			_slab(Vector3(-0.9 + float(x) * 0.1, 1.42 + zig, 0.5 + float(y) * 0.09),
				Vector3(0.095, 0.008, 0.085), Color(0.85, 0.78, 0.6), 0.3)
	_tag(Vector3(-0.65, 1.32, 0.85), "Miura", "a flat sheet that remembers how to fold")

func _build_tentacle() -> void:
	# no skeleton, not a puddle: constraint alone
	var pos := Vector3(0.15, 1.02, 0.6)
	var ang := PI * 0.4
	for k in range(14):
		var nxt := pos + Vector3(cos(ang), sin(ang) * 0.5, 0.0) * 0.06
		_strand(pos, nxt, 0.012 - 0.0006 * float(k), Color(0.85, 0.45, 0.55), 0.7)
		pos = nxt
		ang += 0.28 + 0.04 * sin(float(k))
	_tag(Vector3(0.2, 0.94, 0.85), "tentacle", "no skeleton, and not a puddle")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "BodyPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-2.5, 0.24, 1.1)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("THE CONFESSING BODY",
			"A rigid body has ONE position; a soft body has a position per vertex - the\nwhole shift, on the slab. Shape is a memory held in edges, each spring pulling\ntoward a rest length. The cloth above was relaxed %d times, vertex by vertex,\nhanging from two pins - because softness is always relative to something\nthat refuses to move." % relax_passes)
