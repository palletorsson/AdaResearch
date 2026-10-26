extends Node3D
## Module: the trail engine — stigmergy, what the grammar calls trail(x). Agents walk a field that they
## themselves write: each senses the field ahead (left, centre, right), turns toward the strongest,
## wanders a little, moves one step and deposits; the field diffuses and evaporates; fixed anchors feed it.
## With channels 2 (an ant colony) searchers lay "home" and follow "food", carriers the reverse, and a
## deposit fades with the length of the journey. exclusive: one agent per cell (Jones's physarum: a
## blocked agent stays and turns at random). edge: reflect (the field has walls) or wrap (it does not).
## warm steps run at build time, so a still, a glb and a probe see a formed trail; the game keeps stepping.
## The film page (ada_encyclopedia spine-film) replays the same rule from the seed.
##
##   {"op": "engine", "kind": "trail", "cells": 40, "size": [sx, sz], "agents": 80, "seed": 1,
##    "follow": 1, "wander": 20, "sense": 3, "angle": 35, "turn": 30, "speed": 1, "deposit": 1,
##    "evaporate": 0.05, "diffuse": 0, "anchors": [[x, z], …], "anchor_deposit": 3,
##    "channels": 2, "nest": [x, z], "food": [[x, z], …], "fade": steps, "reach": cells,
##    "edge": "reflect"|"wrap", "exclusive": false, "warm": 300, "rate": 15, "saturate": 4, "of": …}

var p: Dictionary = {}
var n := 40
var chans := 1
var size := Vector2(1.2, 1.2)
var f0 := PackedFloat32Array()         # channel 0 (home, or the only one), n × n, row j = z
var f1 := PackedFloat32Array()         # channel 1 (food); members, not array items: a packed array in an Array copies on every write
var ax := PackedFloat32Array()         # agents, in cell units
var az := PackedFloat32Array()
var ah := PackedFloat32Array()         # heading, radians
var st := PackedInt32Array()           # 0 searching, 1 carrying (channels 2)
var age := PackedInt32Array()          # steps since the last change of state
var occ := PackedByteArray()
var anchors: Array = []
var nest := Vector2.ZERO
var foods: Array = []
var rng := RandomNumberGenerator.new()
var delivered := 0
var steps := 0
var _img: Image
var _tex: ImageTexture
var _mm: MultiMesh
var _acc := 0.0


static func make(expr: Dictionary) -> Node3D:
	var t: Node3D = (load("res://commons/modular/mod_trail.gd") as GDScript).new()
	t.name = "trail_field"
	t.setup(expr)
	return t


func setup(expr: Dictionary) -> void:
	p = expr
	n = clampi(int(p.get("cells", 40)), 8, 128)
	var sz: Array = p.get("size", [1.2, 1.2])
	size = Vector2(float(sz[0]), float(sz[1]))
	chans = 2 if int(p.get("channels", 1)) == 2 else 1
	rng.seed = int(p.get("seed", 1))
	f0.resize(n * n)
	f0.fill(0.0)
	if chans == 2:
		f1.resize(n * n)
		f1.fill(0.0)
	for a in p.get("anchors", []):
		anchors.append(_cell(a))
	nest = _cell(p.get("nest", [0, 0]))
	for f in p.get("food", []):
		foods.append(_cell(f))
	var na: int = clampi(int(p.get("agents", 80)), 1, 2000)
	ax.resize(na); az.resize(na); ah.resize(na); st.resize(na); age.resize(na)
	occ.resize(n * n)
	occ.fill(0)
	for i in na:
		if chans == 2:
			ax[i] = nest.x; az[i] = nest.y
		else:
			ax[i] = rng.randf() * n; az[i] = rng.randf() * n
		ah[i] = rng.randf() * TAU
		st[i] = 0; age[i] = 0
		if bool(p.get("exclusive", false)):
			occ[int(az[i]) * n + int(ax[i])] = 1
	_build()
	for k in int(p.get("warm", 300)):
		step()
	_draw()


func _cell(w: Variant) -> Vector2:
	var a: Array = w
	return Vector2((float(a[0]) / size.x + 0.5) * n, (float(a[1]) / size.y + 0.5) * n)


func _sample(c: int, x: float, z: float, a: float, d: float) -> float:
	var i := int(x + cos(a) * d)
	var j := int(z + sin(a) * d)
	if str(p.get("edge", "reflect")) == "wrap":
		i = posmod(i, n); j = posmod(j, n)
	elif i < 0 or j < 0 or i >= n or j >= n:
		return -1.0
	return f1[j * n + i] if c == 1 else f0[j * n + i]


func step() -> void:
	var sense: float = float(p.get("sense", 3.0))
	var ang: float = deg_to_rad(float(p.get("angle", 35.0)))
	var turn: float = deg_to_rad(float(p.get("turn", 30.0)))
	var speed: float = float(p.get("speed", 1.0))
	var dep: float = float(p.get("deposit", 1.0))
	var follow: float = float(p.get("follow", 1.0))
	var wander: float = deg_to_rad(float(p.get("wander", 20.0)))
	var fade: float = float(p.get("fade", 1e9))
	var reach: float = float(p.get("reach", 2.0))
	var wrap: bool = str(p.get("edge", "reflect")) == "wrap"
	var excl: bool = bool(p.get("exclusive", false))
	for i in ax.size():
		var x: float = ax[i]
		var z: float = az[i]
		var h: float = ah[i]
		var s: int = st[i]
		var fc: int = (1 - s) if chans == 2 else 0
		if follow > 0.0:
			var l := _sample(fc, x, z, h - ang, sense)
			var c := _sample(fc, x, z, h, sense)
			var r := _sample(fc, x, z, h + ang, sense)
			if c >= l and c >= r:
				pass
			elif l > r:
				h -= turn * minf(1.0, follow)
			else:
				h += turn * minf(1.0, follow)
		h += (rng.randf() - 0.5) * wander
		var nx: float = x + cos(h) * speed
		var nz: float = z + sin(h) * speed
		if wrap:
			nx = fposmod(nx, n); nz = fposmod(nz, n)
		else:
			if nx < 0.0 or nx >= n:
				h = PI - h; nx = clampf(nx, 0.0, n - 0.001)
			if nz < 0.0 or nz >= n:
				h = -h; nz = clampf(nz, 0.0, n - 0.001)
		if excl:
			var from_c: int = int(z) * n + int(x)
			var to_c: int = int(nz) * n + int(nx)
			if to_c != from_c and occ[to_c] == 1:
				ah[i] = rng.randf() * TAU   # blocked: stay, and turn at random
				continue
			occ[from_c] = 0; occ[to_c] = 1
		var amount: float = dep * maxf(0.0, 1.0 - age[i] / fade)   # to nothing: a lost ant stops marking, and a mill dies out
		if chans == 2 and s == 1:
			f1[int(nz) * n + int(nx)] += amount
		else:
			f0[int(nz) * n + int(nx)] += amount
		age[i] += 1
		if chans == 2:
			if s == 0:
				for fd in foods:
					if Vector2(nx, nz).distance_to(fd) < reach:
						s = 1; h += PI; age[i] = 0
						break
			elif Vector2(nx, nz).distance_to(nest) < reach:
				s = 0; h += PI; age[i] = 0; delivered += 1
		ax[i] = nx; az[i] = nz; ah[i] = h; st[i] = s
	var adep: float = float(p.get("anchor_deposit", 3.0))
	for a in anchors:
		f0[int(a.y) * n + int(a.x)] += adep
	f0 = _relax(f0)
	if chans == 2:
		f1 = _relax(f1)
	steps += 1


## diffuse (a separable 3 × 3 mean, mixed in by `diffuse`) and evaporate (lose `evaporate` of it)
func _relax(f: PackedFloat32Array) -> PackedFloat32Array:
	var diff: float = float(p.get("diffuse", 0.0))
	var keep: float = 1.0 - float(p.get("evaporate", 0.05))
	if diff > 0.0:
		var t := PackedFloat32Array()
		t.resize(n * n)
		for j in n:
			var row := j * n
			for i in n:
				t[row + i] = (f[row + maxi(i - 1, 0)] + f[row + i] + f[row + mini(i + 1, n - 1)]) / 3.0
		for j in n:
			var up := maxi(j - 1, 0) * n
			var row := j * n
			var dn := mini(j + 1, n - 1) * n
			for i in n:
				var b: float = (t[up + i] + t[row + i] + t[dn + i]) / 3.0
				f[row + i] = (f[row + i] + (b - f[row + i]) * diff) * keep
	else:
		for k in f.size():
			f[k] *= keep
	return f


func _build() -> void:
	_img = Image.create(n, n, false, Image.FORMAT_RGB8)
	_tex = ImageTexture.create_from_image(_img)
	var plane := MeshInstance3D.new()
	plane.name = "trail_plane"
	var pm := PlaneMesh.new()
	pm.size = size
	plane.mesh = pm
	plane.position.y = float(p.get("y", 0.01))
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _tex
	mat.roughness = 1.0
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	plane.material_override = mat
	add_child(plane)
	var dots := MultiMeshInstance3D.new()
	dots.name = "trail_agents"
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	var sm := SphereMesh.new()
	sm.radius = 0.011
	sm.height = 0.022
	sm.radial_segments = 6
	sm.rings = 3
	_mm.mesh = sm
	_mm.instance_count = ax.size()
	dots.multimesh = _mm
	var dm := StandardMaterial3D.new()
	dm.vertex_color_use_as_albedo = true
	dots.material_override = dm
	add_child(dots)


func _draw() -> void:
	var sat: float = maxf(1e-4, float(p.get("saturate", 4.0)))
	var g := Color(str(p.get("ground", "d9cfbc")))
	var c0 := Color(str(p.get("color", "7a4b8a")))
	var c1 := Color(str(p.get("color2", "b8862b")))
	var data := PackedByteArray()
	data.resize(n * n * 3)
	for k in n * n:
		var col: Color = g.lerp(c0, minf(1.0, f0[k] / sat))
		if chans == 2:
			col = col.lerp(c1, minf(1.0, f1[k] / sat))
		data[k * 3] = int(col.r * 255.0); data[k * 3 + 1] = int(col.g * 255.0); data[k * 3 + 2] = int(col.b * 255.0)
	_img.set_data(n, n, false, Image.FORMAT_RGB8, data)
	_tex.update(_img)
	var y: float = float(p.get("y", 0.01)) + 0.012
	var ink := Color("2b1d14")
	var gold := Color("b8862b")
	for i in ax.size():
		var w := Vector3((ax[i] / n - 0.5) * size.x, y, (az[i] / n - 0.5) * size.y)
		_mm.set_instance_transform(i, Transform3D(Basis(), w))
		_mm.set_instance_color(i, gold if st[i] == 1 else ink)


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_acc += delta
	var dt: float = 1.0 / maxf(1.0, float(p.get("rate", 15.0)))
	var done := 0
	while _acc >= dt and done < 2:
		step()
		_acc -= dt
		done += 1
	if done > 0:
		_draw()
	_acc = minf(_acc, dt)
