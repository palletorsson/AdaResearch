# @identity
# essence: procedural plant meshes for MultiMesh instancing — recognizable shapes, VR-cheap
# desire: grass that sways, flowers with petals, mushrooms with caps, trees with crowns
# critical_parameter: triangle count per plant — must stay under 20 tris for VR instancing
# truth: three crossed planes make grass. five triangles make a flower. geometry is cheap, recognition is priceless.

class_name SyntheticFoliage
extends RefCounted
## Static factory for low-poly plant meshes.
## Each mesh is <20 triangles, designed for MultiMesh instancing (hundreds of copies).
## All built with SurfaceTool. No textures — color and shape only.


static func make_grass() -> ArrayMesh:
	## Three crossed vertical planes — classic billboard grass.
	## 12 triangles total. Sways in wind via vertex shader.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h: float = 1.0
	var w: float = 0.3
	# Three planes at 60° intervals
	for i in 3:
		var angle: float = float(i) * PI / 3.0
		var dx: float = cos(angle) * w
		var dz: float = sin(angle) * w
		var bl := Vector3(-dx, 0, -dz)
		var br := Vector3(dx, 0, dz)
		var tl := Vector3(-dx * 0.6, h, -dz * 0.6)  # Tapers inward at top
		var tr := Vector3(dx * 0.6, h, dz * 0.6)
		_quad(st, bl, br, tr, tl, Color(0.25, 0.55, 0.15))
	return st.commit()


static func make_flower() -> ArrayMesh:
	## Stem + 5 petals radiating from center. ~12 triangles.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem_h: float = 0.6
	var petal_r: float = 0.25
	var petal_h: float = 0.15
	# Stem: thin vertical quad
	_quad(st, Vector3(-0.02, 0, 0), Vector3(0.02, 0, 0),
		Vector3(0.02, stem_h, 0), Vector3(-0.02, stem_h, 0),
		Color(0.2, 0.45, 0.12))
	# Petals: 5 triangles radiating from stem top
	for i in 5:
		var angle: float = float(i) * TAU / 5.0
		var tip := Vector3(cos(angle) * petal_r, stem_h + petal_h, sin(angle) * petal_r)
		var left_a: float = angle - 0.3
		var right_a: float = angle + 0.3
		var base_l := Vector3(cos(left_a) * 0.04, stem_h, sin(left_a) * 0.04)
		var base_r := Vector3(cos(right_a) * 0.04, stem_h, sin(right_a) * 0.04)
		_tri(st, base_l, tip, base_r, Color(0.9, 0.4, 0.55))
	# Center dot
	_tri(st, Vector3(-0.03, stem_h + 0.01, -0.03),
		Vector3(0.03, stem_h + 0.01, -0.03),
		Vector3(0, stem_h + 0.01, 0.03), Color(0.9, 0.8, 0.2))
	return st.commit()


static func make_fern() -> ArrayMesh:
	## Frond: central stem with alternating leaflets. ~16 triangles.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var frond_h: float = 0.8
	var leaf_w: float = 0.2
	var leaves: int = 6
	# Central stem
	_quad(st, Vector3(-0.01, 0, 0), Vector3(0.01, 0, 0),
		Vector3(0.005, frond_h, 0), Vector3(-0.005, frond_h, 0),
		Color(0.15, 0.4, 0.1))
	# Alternating leaflets
	for i in leaves:
		var t: float = float(i + 1) / float(leaves + 1)
		var y: float = t * frond_h
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var w_scale: float = 1.0 - t * 0.5  # Smaller toward top
		var base := Vector3(0, y, 0)
		var tip := Vector3(side * leaf_w * w_scale, y + 0.06, 0.05 * side)
		var base2 := Vector3(0, y + 0.08, 0)
		_tri(st, base, tip, base2, Color(0.18, 0.5, 0.12))
	return st.commit()


static func make_mushroom() -> ArrayMesh:
	## Stem + dome cap. ~14 triangles.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem_h: float = 0.3
	var cap_r: float = 0.2
	var cap_h: float = 0.12
	var segs: int = 6
	# Stem: hexagonal prism
	for i in segs:
		var a0: float = float(i) * TAU / float(segs)
		var a1: float = float(i + 1) * TAU / float(segs)
		var r: float = 0.04
		var bl := Vector3(cos(a0) * r, 0, sin(a0) * r)
		var br := Vector3(cos(a1) * r, 0, sin(a1) * r)
		var tl := Vector3(cos(a0) * r, stem_h, sin(a0) * r)
		var tr := Vector3(cos(a1) * r, stem_h, sin(a1) * r)
		_quad(st, bl, br, tr, tl, Color(0.8, 0.75, 0.65))
	# Cap: cone from rim to peak
	var peak := Vector3(0, stem_h + cap_h, 0)
	for i in segs:
		var a0: float = float(i) * TAU / float(segs)
		var a1: float = float(i + 1) * TAU / float(segs)
		var rim0 := Vector3(cos(a0) * cap_r, stem_h, sin(a0) * cap_r)
		var rim1 := Vector3(cos(a1) * cap_r, stem_h, sin(a1) * cap_r)
		_tri(st, rim0, peak, rim1, Color(0.7, 0.3, 0.25))
	return st.commit()


static func make_reed() -> ArrayMesh:
	## Tall thin stem with slight curve + tuft at top. ~8 triangles.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h: float = 1.2
	var r: float = 0.015
	var curve: float = 0.08
	# Two crossed quads with slight lean
	for i in 2:
		var angle: float = float(i) * PI / 2.0
		var dx: float = cos(angle) * r
		var dz: float = sin(angle) * r
		var bl := Vector3(-dx, 0, -dz)
		var br := Vector3(dx, 0, dz)
		var tl := Vector3(-dx + curve, h, -dz)
		var tr := Vector3(dx + curve, h, dz)
		_quad(st, bl, br, tr, tl, Color(0.5, 0.6, 0.3))
	# Tuft at top: small triangle burst
	for i in 3:
		var a: float = float(i) * TAU / 3.0
		var tip := Vector3(curve + cos(a) * 0.06, h + 0.1, sin(a) * 0.06)
		_tri(st, Vector3(curve - 0.02, h, -0.02),
			tip, Vector3(curve + 0.02, h, 0.02),
			Color(0.55, 0.5, 0.3))
	return st.commit()


static func make_tree() -> ArrayMesh:
	## Trunk (tapered box) + crown (icosahedron-ish sphere). ~18 triangles.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk_h: float = 0.6
	var trunk_r: float = 0.06
	var crown_r: float = 0.35
	var crown_y: float = trunk_h + crown_r * 0.6
	# Trunk: 4 quads
	for i in 4:
		var a0: float = float(i) * TAU / 4.0
		var a1: float = float(i + 1) * TAU / 4.0
		var bl := Vector3(cos(a0) * trunk_r, 0, sin(a0) * trunk_r)
		var br := Vector3(cos(a1) * trunk_r, 0, sin(a1) * trunk_r)
		var tl := Vector3(cos(a0) * trunk_r * 0.6, trunk_h, sin(a0) * trunk_r * 0.6)
		var tr := Vector3(cos(a1) * trunk_r * 0.6, trunk_h, sin(a1) * trunk_r * 0.6)
		_quad(st, bl, br, tr, tl, Color(0.4, 0.28, 0.15))
	# Crown: 6 triangles forming rough sphere
	var top := Vector3(0, crown_y + crown_r * 0.7, 0)
	var bot := Vector3(0, crown_y - crown_r * 0.3, 0)
	for i in 6:
		var a0: float = float(i) * TAU / 6.0
		var a1: float = float(i + 1) * TAU / 6.0
		var mid0 := Vector3(cos(a0) * crown_r, crown_y, sin(a0) * crown_r)
		var mid1 := Vector3(cos(a1) * crown_r, crown_y, sin(a1) * crown_r)
		var green: Color = Color(0.15 + randf() * 0.1, 0.4 + randf() * 0.15, 0.1)
		_tri(st, mid0, top, mid1, green)
		_tri(st, mid1, bot, mid0, green.darkened(0.15))
	return st.commit()


static func make_bush() -> ArrayMesh:
	## Flattened sphere — 8 triangles forming a dome.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r: float = 0.35
	var h: float = 0.25
	var segs: int = 6
	var top := Vector3(0, h, 0)
	for i in segs:
		var a0: float = float(i) * TAU / float(segs)
		var a1: float = float(i + 1) * TAU / float(segs)
		var rim0 := Vector3(cos(a0) * r, 0, sin(a0) * r)
		var rim1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
		_tri(st, rim0, top, rim1, Color(0.2, 0.5, 0.15))
		# Bottom face
		_tri(st, rim1, Vector3(0, -0.02, 0), rim0, Color(0.15, 0.35, 0.1))
	return st.commit()


static func make_vine() -> ArrayMesh:
	## Vertical zigzag strip — climbing vine. ~8 triangles.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h: float = 1.0
	var w: float = 0.04
	var segments: int = 4
	for i in segments:
		var t0: float = float(i) / float(segments)
		var t1: float = float(i + 1) / float(segments)
		var y0: float = t0 * h
		var y1: float = t1 * h
		var x_off: float = (0.08 if i % 2 == 0 else -0.08)
		_quad(st,
			Vector3(x_off - w, y0, 0), Vector3(x_off + w, y0, 0),
			Vector3(-x_off + w, y1, 0), Vector3(-x_off - w, y1, 0),
			Color(0.25, 0.5, 0.2))
	return st.commit()


# ── Helpers ──────────────────────────────────────────────────────────────

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var n: Vector3 = (b - a).cross(c - a).normalized()
	if n.length() < 0.001: n = Vector3.UP
	st.set_color(color); st.set_normal(n); st.add_vertex(a)
	st.set_color(color); st.set_normal(n); st.add_vertex(b)
	st.set_color(color); st.set_normal(n); st.add_vertex(c)
	# Back face
	st.set_color(color); st.set_normal(-n); st.add_vertex(a)
	st.set_color(color); st.set_normal(-n); st.add_vertex(c)
	st.set_color(color); st.set_normal(-n); st.add_vertex(b)


static func _quad(st: SurfaceTool, bl: Vector3, br: Vector3, tr: Vector3, tl: Vector3, color: Color) -> void:
	_tri(st, bl, br, tr, color)
	_tri(st, bl, tr, tl, color)
