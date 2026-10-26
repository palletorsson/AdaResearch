extends Node3D
## Module: the cells engine — a lattice of local state updates, what the grammar calls cells(x), drawn as one
## texture on the floor. Every cell reads the previous lattice (eight neighbours, wrapped edges).
##   mode "generations": states 0 empty, 1 active, 2 … n-1 fading. Only active cells are counted: an empty cell
##     with a count in `birth` becomes active, an active one with a count in `survive` stays, any other active
##     cell starts to fade and a fading cell fades on until it is gone (a cell with a past: present, not counted).
##   mode "difference": two coupled logistic lattices, x' = (1 - eps) f(x) + eps · mean f(four neighbours),
##     f(x) = r x (1 - x), identical but for one cell; the red is how far they differ.
## warm steps run at build time; the game keeps stepping. The film page replays the same rule.
##
##   {"op": "engine", "kind": "cells", "mode": "generations", "birth": [2], "survive": [3, 4, 5], "states": 4,
##    "density": 0.3, "cells": 48, "size": [1.2, 1.2], "seed": 2, "warm": 60, "rate": 8, "of": …}
##   {"op": "engine", "kind": "cells", "mode": "difference", "r": 3.9, "eps": 0.3, "delta": 0.1, …}

var p: Dictionary = {}
var n := 48
var size := Vector2(1.2, 1.2)
var a := PackedFloat32Array()      # generations: the state; difference: run A
var b := PackedFloat32Array()      # difference: run B
var steps := 0
var rng := RandomNumberGenerator.new()
var _img: Image
var _tex: ImageTexture
var _acc := 0.0


static func make(expr: Dictionary) -> Node3D:
	var t: Node3D = (load("res://commons/modular/mod_cells.gd") as GDScript).new()
	t.name = "cells_field"
	t.setup(expr)
	return t


func setup(expr: Dictionary) -> void:
	p = expr
	n = clampi(int(p.get("cells", 48)), 8, 128)
	var sz: Array = p.get("size", [1.2, 1.2])
	size = Vector2(float(sz[0]), float(sz[1]))
	rng.seed = int(p.get("seed", 1))
	a.resize(n * n)
	if _mode() == "difference":
		for k in n * n:
			a[k] = rng.randf()
		b = a.duplicate()
		var c := (n / 2) * n + n / 2
		b[c] = fposmod(b[c] + float(p.get("delta", 0.1)), 1.0)
	else:
		var dens: float = float(p.get("density", 0.3))
		for k in n * n:
			a[k] = 1.0 if rng.randf() < dens else 0.0
	_build()
	for k in int(p.get("warm", 60)):
		step()
	_draw()


func _mode() -> String:
	return str(p.get("mode", "generations"))


func step() -> void:
	if _mode() == "difference":
		a = _logistic(a)
		b = _logistic(b)
	else:
		a = _generation(a)
	steps += 1


func _generation(s: PackedFloat32Array) -> PackedFloat32Array:
	var birth: Array = p.get("birth", [2])
	var survive: Array = p.get("survive", [3, 4, 5])
	var states: int = maxi(2, int(p.get("states", 4)))
	var out := PackedFloat32Array()
	out.resize(n * n)
	for j in n:
		for i in n:
			var cnt := 0
			for dj in [-1, 0, 1]:
				for di in [-1, 0, 1]:
					if di == 0 and dj == 0:
						continue
					if int(s[posmod(j + dj, n) * n + posmod(i + di, n)]) == 1:
						cnt += 1
			var v := int(s[j * n + i])
			var nv := 0
			if v == 0:
				nv = 1 if birth.has(cnt) or birth.has(float(cnt)) else 0
			elif v == 1:
				nv = 1 if survive.has(cnt) or survive.has(float(cnt)) else (2 if states > 2 else 0)
			else:
				nv = v + 1 if v + 1 < states else 0
			out[j * n + i] = nv
	return out


func _logistic(x: PackedFloat32Array) -> PackedFloat32Array:
	var r: float = float(p.get("r", 3.9))
	var eps: float = float(p.get("eps", 0.3))
	var f := PackedFloat32Array()
	f.resize(n * n)
	for k in n * n:
		f[k] = r * x[k] * (1.0 - x[k])
	var out := PackedFloat32Array()
	out.resize(n * n)
	for j in n:
		for i in n:
			var nb: float = f[posmod(j - 1, n) * n + i] + f[posmod(j + 1, n) * n + i] + f[j * n + posmod(i - 1, n)] + f[j * n + posmod(i + 1, n)]
			out[j * n + i] = (1.0 - eps) * f[j * n + i] + eps * nb / 4.0
	return out


func _build() -> void:
	_img = Image.create(n, n, false, Image.FORMAT_RGB8)
	_tex = ImageTexture.create_from_image(_img)
	var plane := MeshInstance3D.new()
	plane.name = "cells_plane"
	var pm := PlaneMesh.new()
	pm.size = size
	plane.mesh = pm
	plane.position.y = float(p.get("y", 0.01))
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _tex
	mat.roughness = 1.0
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST   # a lattice: every cell keeps its edge
	plane.material_override = mat
	add_child(plane)


func _draw() -> void:
	var ground := Color("ece5d4")
	var active := Color("e8508a")
	var fading := Color("3d9a5a")
	var red := Color("e63946")
	var states: int = maxi(2, int(p.get("states", 4)))
	var data := PackedByteArray()
	data.resize(n * n * 3)
	for k in n * n:
		var col: Color
		if _mode() == "difference":
			col = ground.lerp(Color("8a7a5a"), a[k] * 0.5).lerp(red, minf(1.0, absf(a[k] - b[k]) * 4.0))
		else:
			var v := int(a[k])
			col = ground if v == 0 else (active if v == 1 else fading.lerp(ground, float(v - 2) / maxf(1.0, states - 2)))
		data[k * 3] = int(col.r * 255.0); data[k * 3 + 1] = int(col.g * 255.0); data[k * 3 + 2] = int(col.b * 255.0)
	_img.set_data(n, n, false, Image.FORMAT_RGB8, data)
	_tex.update(_img)


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_acc += delta
	var dt: float = 1.0 / maxf(0.5, float(p.get("rate", 8.0)))
	if _acc < dt:
		return
	_acc = 0.0
	step()
	_draw()
