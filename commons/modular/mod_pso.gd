extends Node3D
## Module: the pso engine — particle swarm optimisation, what the grammar calls pso(x). Particles fly over a
## landscape of gaussian peaks (drawn as a surface, the objective as height). Each remembers the best place it
## has been (its personal best: a gold disc where it was found, at the height of its score); all share the
## best of those (the global best: a red pin). Each step a particle's velocity keeps some of itself (inertia)
## and is pulled toward both memories by random amounts: v = w v + c1 r1 (pb - x) + c2 r2 (gb - x).
## personal 0 or social 0 removes one memory. warm steps run at build time; the game keeps searching and,
## after `cycle` steps, starts a new search from a new scatter. The film page replays the same rule.
##
##   {"op": "engine", "kind": "pso", "size": 1.2, "height": 0.35, "peaks": [[x, z, h, width], …],
##    "particles": 16, "inertia": 0.7, "personal": 1.4, "social": 1.4, "vmax": 0.06, "seed": 1,
##    "warm": 20, "cycle": 90, "rate": 6, "of": …}

var p: Dictionary = {}
var peaks: Array = []
var half := 0.6
var lift := 0.35
var xs := PackedVector2Array()        # positions
var vs := PackedVector2Array()        # velocities
var pb := PackedVector2Array()        # personal bests
var ps := PackedFloat32Array()        # their scores
var gb := Vector2.ZERO                # the global best
var gs := -INF
var rng := RandomNumberGenerator.new()
var steps := 0
var round_n := 0
var _dots: MultiMesh
var _discs: MultiMesh
var _pin: Node3D
var _acc := 0.0


static func make(expr: Dictionary) -> Node3D:
	var t: Node3D = (load("res://commons/modular/mod_pso.gd") as GDScript).new()
	t.name = "pso_field"
	t.setup(expr)
	return t


func setup(expr: Dictionary) -> void:
	p = expr
	half = float(p.get("size", 1.2)) / 2.0
	lift = float(p.get("height", 0.35))
	peaks = p.get("peaks", [[0, 0, 1, 0.2]])
	_build()
	reset()
	for k in int(p.get("warm", 20)):
		step()
	_draw()


func score(x: float, z: float) -> float:
	var s := 0.0
	for q in peaks:
		var w: float = float(q[3])
		s += float(q[2]) * exp(-(pow(x - float(q[0]), 2) + pow(z - float(q[1]), 2)) / (2.0 * w * w))
	return s


func slope(x: float, z: float) -> Vector2:
	var g := Vector2.ZERO
	for q in peaks:
		var w: float = float(q[3])
		var e: float = float(q[2]) * exp(-(pow(x - float(q[0]), 2) + pow(z - float(q[1]), 2)) / (2.0 * w * w)) / (w * w)
		g += Vector2(-(x - float(q[0])) * e, -(z - float(q[1])) * e)
	return g


func reset() -> void:
	rng.seed = int(p.get("seed", 1)) + round_n * 7919
	var n: int = clampi(int(p.get("particles", 16)), 1, 400)
	var vmax: float = float(p.get("vmax", 0.06))
	xs.resize(n); vs.resize(n); pb.resize(n); ps.resize(n)
	gs = -INF
	for i in n:
		xs[i] = Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
		vs[i] = Vector2(rng.randf_range(-vmax, vmax), rng.randf_range(-vmax, vmax))
		pb[i] = xs[i]
		ps[i] = score(xs[i].x, xs[i].y)
		if ps[i] > gs:
			gs = ps[i]; gb = pb[i]
	steps = 0


func step() -> void:
	var w: float = float(p.get("inertia", 0.7))
	var c1: float = float(p.get("personal", 1.4))
	var c2: float = float(p.get("social", 1.4))
	var vmax: float = float(p.get("vmax", 0.06))
	for i in xs.size():
		var v: Vector2 = vs[i]
		var x: Vector2 = xs[i]
		for a in 2:
			v[a] = clampf(w * v[a] + c1 * rng.randf() * (pb[i][a] - x[a]) + c2 * rng.randf() * (gb[a] - x[a]), -vmax, vmax)
			x[a] = clampf(x[a] + v[a], -half, half)
		vs[i] = v; xs[i] = x
		var s := score(x.x, x.y)
		if s > ps[i]:
			ps[i] = s; pb[i] = x
			if s > gs:
				gs = s; gb = x
	steps += 1


func _build() -> void:
	var g := 40
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lo := Color("ece5d4")
	var hi := Color("6b5a40")
	var top := 0.0
	for q in peaks:
		top = maxf(top, float(q[2]))
	for j in g:
		for i in g:
			var quad := [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]
			for c in [0, 1, 2, 3, 4, 5]:   # the top is the front face (culling off flips a back face's normal)
				var gi: Vector2i = quad[c]
				var x: float = -half + 2.0 * half * gi.x / g
				var z: float = -half + 2.0 * half * gi.y / g
				var s := score(x, z)
				var gr := slope(x, z) * lift
				st.set_normal(Vector3(-gr.x, 1.0, -gr.y).normalized())   # from the gradient: up whatever the winding
				st.set_color(lo.lerp(hi, sqrt(clampf(s / maxf(top, 1e-4), 0.0, 1.0))))   # sqrt: the slopes read, not only the summits
				st.add_vertex(Vector3(x, s * lift, z))
	var land := MeshInstance3D.new()
	land.name = "pso_landscape"
	land.mesh = st.commit()
	var lm := StandardMaterial3D.new()
	lm.vertex_color_use_as_albedo = true
	lm.roughness = 1.0
	lm.cull_mode = BaseMaterial3D.CULL_DISABLED
	land.material_override = lm
	add_child(land)
	_dots = _multi("pso_particles", _sphere(0.022), Color("2b1d14"))
	var disc := CylinderMesh.new()
	disc.top_radius = 0.014
	disc.bottom_radius = 0.014
	disc.height = 0.006
	disc.radial_segments = 10
	_discs = _multi("pso_personal_bests", disc, Color("b8862b"))
	_pin = Node3D.new()
	_pin.name = "pso_global_best"
	var red := StandardMaterial3D.new()
	red.albedo_color = Color("e63946")
	var stick := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.005
	sm.bottom_radius = 0.005
	sm.height = 0.25
	stick.mesh = sm
	stick.position.y = 0.125
	stick.material_override = red
	var head := MeshInstance3D.new()
	head.mesh = _sphere(0.02)
	head.position.y = 0.25
	head.material_override = red
	_pin.add_child(stick)
	_pin.add_child(head)
	add_child(_pin)


func _sphere(r: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = 2.0 * r
	m.radial_segments = 10
	m.rings = 5
	return m


func _multi(nm: String, mesh: Mesh, color: Color) -> MultiMesh:
	var inst := MultiMeshInstance3D.new()
	inst.name = nm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = clampi(int(p.get("particles", 16)), 1, 400)
	inst.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	inst.material_override = mat
	add_child(inst)
	return mm


func _draw() -> void:
	for i in xs.size():
		var x: Vector2 = xs[i]
		_dots.set_instance_transform(i, Transform3D(Basis(), Vector3(x.x, score(x.x, x.y) * lift + 0.024, x.y)))
		_discs.set_instance_transform(i, Transform3D(Basis(), Vector3(pb[i].x, ps[i] * lift + 0.004, pb[i].y)))
	_pin.position = Vector3(gb.x, gs * lift, gb.y)


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_acc += delta
	var dt: float = 1.0 / maxf(0.5, float(p.get("rate", 6.0)))
	if _acc < dt:
		return
	_acc = 0.0
	if steps >= int(p.get("cycle", 90)):
		round_n += 1   # a new search from a new scatter: the memory is the search's, not the landscape's
		reset()
	step()
	_draw()
