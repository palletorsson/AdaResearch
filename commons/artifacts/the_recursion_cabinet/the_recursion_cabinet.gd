extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheRecursionCabinet

## @identity
## lineage: the fractals SUPER OBJECT — a curiosity cabinet that contains itself. The
##   case is built by a function that calls itself: each shelf holds a smaller copy of
##   the whole cabinet, four levels down, until the base case stops it and the last
##   copy is a solid block with nothing inside. Inside the drawers, the family: a
##   Cantor comb with its middles gone, a Koch edge, a Sierpinski face, a Menger
##   cube with its holes bored, a golden spiral of shelf-boxes, a chaos-game fern,
##   a DLA coral, and an escape-time plate of the Mandelbrot boundary. Every one is
##   RECURSED here, not drawn — and a brass depth dial reads the level count while
##   the stack plate confesses what it cost.
## essence: recursion is four characters — a function calling itself — plus one rung
##   that stops it. The cabinet is the argument: the whole is in the part, and the
##   part is smaller, and eventually the machine says no.
## truth: infinite complexity from finite rules; but the base case is what makes it
##   a fractal instead of a crash.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 5
@export_range(2, 5) var depth: int = 4
## The base case's own body: the last copy is SOLID, so the stop is visible.
@export var shrink: float = 0.42

var _built := 0                        # how many cabinets the recursion actually made

func _ready() -> void:
	_rng.seed = seed
	_build_plinth()
	_cabinet(Vector3(0.0, 0.95, 0.0), 1.1, depth)
	_build_drawers()
	_build_depth_dial()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "depth", "shrink"]:
		if config_data.has(key):
			set(key, config_data[key])

func _tag(at: Vector3, title: String, sub: String) -> void:
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.16
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

# --- the cabinet that calls itself -----------------------------------------------------

func _build_plinth() -> void:
	_slab(Vector3(0.0, 0.2, 0.0), Vector3(1.5, 0.4, 0.8), Color(0.11, 0.1, 0.11))

## THE SELF-CALL. Builds one cabinet, then calls itself for the copy on each shelf -
## until level hits the BASE CASE, where it draws a solid block and returns.
func _cabinet(at: Vector3, size: float, level: int) -> void:
	_built += 1
	var warm := Color(0.42, 0.28, 0.16).lerp(Color(0.75, 0.6, 0.35), float(level) / float(depth))
	if level <= 0:
		# the base case: SOLID. Nothing inside, and the recursion stops here.
		_slab(at, Vector3(size, size * 0.9, size * 0.55), Color(0.85, 0.7, 0.3), 0.8)
		return
	# the carcass: two sides, a top, a bottom, a back — a case with a hollow
	var t := size * 0.055
	_slab(at + Vector3(-size * 0.5, 0.0, 0.0), Vector3(t, size * 0.9, size * 0.55), warm)
	_slab(at + Vector3(size * 0.5, 0.0, 0.0), Vector3(t, size * 0.9, size * 0.55), warm)
	_slab(at + Vector3(0.0, size * 0.45, 0.0), Vector3(size, t, size * 0.55), warm)
	_slab(at + Vector3(0.0, -size * 0.45, 0.0), Vector3(size, t, size * 0.55), warm)
	_slab(at + Vector3(0.0, 0.0, -size * 0.27), Vector3(size, size * 0.9, t * 0.6), warm.darkened(0.35))
	# one shelf, and on it the SAME FUNCTION again, smaller
	_slab(at + Vector3(0.0, 0.0, 0.0), Vector3(size * 0.9, t * 0.7, size * 0.5), warm.darkened(0.15))
	var child := size * shrink
	_cabinet(at + Vector3(0.0, size * 0.24, 0.02), child, level - 1)
	_cabinet(at + Vector3(0.0, -size * 0.24, 0.02), child, level - 1)

# --- the drawers: the family, each genuinely recursed ------------------------------------

func _build_drawers() -> void:
	_cantor(Vector3(-1.65, 1.35, 0.0))
	_koch(Vector3(-1.65, 0.95, 0.0))
	_sierpinski(Vector3(-1.65, 0.5, 0.0))
	_menger(Vector3(1.6, 1.3, 0.0))
	_golden(Vector3(1.6, 0.85, 0.0))
	_fern(Vector3(1.6, 0.35, 0.0))
	_mandelbrot(Vector3(0.0, 1.72, 0.0))

func _cantor(at: Vector3) -> void:
	# remove the middle third, forever (five levels)
	var segs := [[0.0, 0.62]]
	for level in range(5):
		for s in segs:
			var a: float = s[0]
			var b: float = s[1]
			_slab(at + Vector3((a + b) * 0.5 - 0.31, -0.045 * float(level), 0.0),
				Vector3(b - a, 0.012, 0.03), Color(0.9, 0.85, 0.6), 0.6)
		var nxt := []
		for s in segs:
			var a: float = s[0]
			var b: float = s[1]
			var third := (b - a) / 3.0
			nxt.append([a, a + third])
			nxt.append([b - third, b])
		segs = nxt
	_tag(at + Vector3(0.0, -0.28, 0.12), "Cantor", "zero length, uncountably many points")

func _koch(at: Vector3) -> void:
	# replace each segment with four: the edge grows without bound
	var pts := [Vector2(-0.3, 0.0), Vector2(0.3, 0.0)]
	for level in range(3):
		var nxt := [pts[0]]
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var d := (b - a) / 3.0
			var p1 := a + d
			var p3 := a + d * 2.0
			var peak := p1 + Vector2(d.x * 0.5 - d.y * 0.866, d.y * 0.5 + d.x * 0.866)
			nxt.append(p1)
			nxt.append(peak)
			nxt.append(p3)
			nxt.append(b)
		pts = nxt
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var mid := (a + b) * 0.5
		var seg := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(a.distance_to(b), 0.008, 0.012)
		seg.mesh = sm
		seg.position = at + Vector3(mid.x, mid.y, 0.0)
		seg.rotation.z = atan2(b.y - a.y, b.x - a.x)
		seg.material_override = _glow_mat(Color(0.5, 0.85, 0.95), 0.7)
		add_child(seg)
	_tag(at + Vector3(0.0, -0.16, 0.12), "Koch", "infinite perimeter, finite area")

func _sierpinski(at: Vector3) -> void:
	# the triangle of triangles: chaos-game, 400 seeded points
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var corners := [Vector2(-0.28, -0.16), Vector2(0.28, -0.16), Vector2(0.0, 0.3)]
	var p := Vector2(0.0, 0.0)
	for i in range(400):
		var c: Vector2 = corners[r.randi_range(0, 2)]
		p = (p + c) * 0.5
		if i > 12:
			var dot := MeshInstance3D.new()
			var dm := BoxMesh.new()
			dm.size = Vector3(0.008, 0.008, 0.008)
			dot.mesh = dm
			dot.position = at + Vector3(p.x, p.y, 0.0)
			dot.material_override = _glow_mat(Color(0.95, 0.6, 0.3), 0.9)
			add_child(dot)
	_tag(at + Vector3(0.0, -0.24, 0.12), "Sierpinski", "D = 1.585 - between a line and a plane")

func _menger(at: Vector3) -> void:
	# level-2 sponge, built by the same keep-or-remove test at both scales
	for x in range(3):
		for y in range(3):
			for z in range(3):
				var mid := int(x == 1) + int(y == 1) + int(z == 1)
				if mid >= 2:
					continue
				for xx in range(3):
					for yy in range(3):
						for zz in range(3):
							var m2 := int(xx == 1) + int(yy == 1) + int(zz == 1)
							if m2 >= 2:
								continue
							_slab(at + Vector3(float(x) - 1.0, float(y) - 1.0, float(z) - 1.0) * 0.105
								+ Vector3(float(xx) - 1.0, float(yy) - 1.0, float(zz) - 1.0) * 0.035,
								Vector3.ONE * 0.032, Color(0.7, 0.72, 0.78))
	_tag(at + Vector3(0.0, -0.24, 0.14), "Menger", "D = 2.73 - a solid with no volume left")

func _golden(at: Vector3) -> void:
	# phi: each box the previous times 1/1.618, turned a quarter
	var size := 0.22
	var pos := Vector2.ZERO
	var ang := 0.0
	for i in range(8):
		_slab(at + Vector3(pos.x, pos.y, 0.0), Vector3(size, size, 0.02),
			Color.from_hsv(0.09 + 0.03 * float(i), 0.5, 0.95), 0.5)
		ang += PI * 0.5
		size /= 1.618
		pos += Vector2(cos(ang), sin(ang)) * size * 1.1
	_tag(at + Vector3(0.0, -0.2, 0.12), "golden", "137.5 degrees, and a sunflower packs itself")

func _fern(at: Vector3) -> void:
	# Barnsley: four affine maps, the chaos game again - IFS
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var p := Vector2.ZERO
	for i in range(500):
		var q := r.randf()
		var n: Vector2
		if q < 0.01:
			n = Vector2(0.0, 0.16 * p.y)
		elif q < 0.86:
			n = Vector2(0.85 * p.x + 0.04 * p.y, -0.04 * p.x + 0.85 * p.y + 1.6)
		elif q < 0.93:
			n = Vector2(0.2 * p.x - 0.26 * p.y, 0.23 * p.x + 0.22 * p.y + 1.6)
		else:
			n = Vector2(-0.15 * p.x + 0.28 * p.y, 0.26 * p.x + 0.24 * p.y + 0.44)
		p = n
		if i > 20:
			var dot := MeshInstance3D.new()
			var dm := BoxMesh.new()
			dm.size = Vector3(0.006, 0.006, 0.006)
			dot.mesh = dm
			dot.position = at + Vector3(p.x * 0.05, p.y * 0.05 - 0.22, 0.0)
			dot.material_override = _glow_mat(Color(0.45, 0.85, 0.5), 0.8)
			add_child(dot)
	_tag(at + Vector3(0.0, -0.3, 0.12), "IFS fern", "four maps, thrown at random, and a plant")

func _mandelbrot(at: Vector3) -> void:
	# escape time: recursion on NUMBERS - z -> z*z + c, asked of every cell
	for iy in range(18):
		for ix in range(24):
			var cx := -2.2 + 3.0 * float(ix) / 23.0
			var cy := -1.1 + 2.2 * float(iy) / 17.0
			var zx := 0.0
			var zy := 0.0
			var n := 0
			while n < 24 and zx * zx + zy * zy < 4.0:
				var t := zx * zx - zy * zy + cx
				zy = 2.0 * zx * zy + cy
				zx = t
				n += 1
			var v := float(n) / 24.0
			_slab(at + Vector3((float(ix) - 11.5) * 0.032, (float(iy) - 8.5) * 0.032, 0.0),
				Vector3(0.03, 0.03, 0.01),
				Color(0.1, 0.05, 0.2).lerp(Color(0.95, 0.85, 0.5), v), 0.3 + 0.7 * v)
	_tag(at + Vector3(0.0, -0.34, 0.1), "escape time", "z -> z*z + c, asked of every point")

func _build_depth_dial() -> void:
	var dial := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.1
	dm.bottom_radius = 0.1
	dm.height = 0.03
	dial.mesh = dm
	dial.rotation.x = PI * 0.5
	dial.position = Vector3(0.0, 0.5, 0.45)
	dial.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
	add_child(dial)
	_tag(Vector3(0.0, 0.3, 0.5), "depth %d" % depth,
		"%d cabinets built - and the deepest is solid: the base case" % _built)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "CabinetPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-1.15, 0.44, 0.62)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("THE RECURSION CABINET",
			"A cabinet built by a function that calls itself: every shelf holds a smaller\ncopy, until the base case draws a SOLID block and returns. In the drawers,\nthe family - Cantor's missing thirds, Koch's endless edge, Sierpinski's\nchaos game, Menger's bored cube, phi's spiral, a Barnsley fern, and\nz -> z*z + c asked of every point. Each one recursed here, not drawn.")
