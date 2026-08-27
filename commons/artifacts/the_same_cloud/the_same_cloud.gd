extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheSameCloud

## @identity
## lineage: the noise SUPER OBJECT — a weather bureau for one cloud. Every station
##   here reads THE SAME FastNoiseLite, seed 4, and disagrees only about how. A
##   scream-board of white noise hangs beside the promise-board of coherent noise,
##   the difference plain as static against weather. Three frequency plates show one
##   cloud at three zooms. An octave stair adds fbm layers left to right, each step
##   the sum of the ones before. Four kind-tiles sit in a row — Perlin, Simplex,
##   Cellular, Value — from one seed, four temperaments. A vane field leans by the
##   same samples read as angles. A relief bench extrudes them as height. A warp pair
##   shows the cloud plain, then read through itself. And the last plate thresholds
##   the same field into a coastline: the door to procedural generation.
## essence: FastNoiseLite is not a dice cup, it is a FUNCTION — ask x twice, get the
##   same answer forever, and ask nearby, get a neighbourly one. Everything in this
##   bureau is that one function under different questions.
## truth: noise is randomness that remembers its neighbours — and it is all one cloud.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const RES := 14                          # samples per board edge

@export var seed: int = 4
@export var base_frequency: float = 0.09

var _noise := FastNoiseLite.new()

func _ready() -> void:
	_rng.seed = seed
	_noise.seed = seed
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = base_frequency
	_build_bench()
	_build_scream_and_promise()
	_build_frequency_plates()
	_build_octave_stair()
	_build_kind_row()
	_build_vane_field()
	_build_relief()
	_build_warp_pair()
	_build_coastline()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "base_frequency"]:
		if config_data.has(key):
			set(key, config_data[key])

# --- helpers -------------------------------------------------------------------------

func _tag(at: Vector3, title: String, sub: String) -> void:
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.18
	tag.position = at
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text(title, sub)

## One board of RESxRES cells, each cell's grey from a sampler callable.
func _board(origin: Vector3, size: float, sampler: Callable, tint: Color = Color(1, 1, 1)) -> void:
	var cell := size / float(RES)
	for iy in range(RES):
		for ix in range(RES):
			var u := (float(ix) + 0.5) / float(RES)
			var v := (float(iy) + 0.5) / float(RES)
			var g: float = clampf(sampler.call(u, v), 0.0, 1.0)
			var q := MeshInstance3D.new()
			var qm := BoxMesh.new()
			qm.size = Vector3(cell * 0.94, 0.012, cell * 0.94)
			q.mesh = qm
			q.position = origin + Vector3((u - 0.5) * size, 0.0, (v - 0.5) * size)
			q.material_override = _matte_mat(Color(tint.r * g, tint.g * g, tint.b * g), 0.75)
			add_child(q)

func _n(x: float, y: float) -> float:
	return _noise.get_noise_2d(x, y) * 0.5 + 0.5

# --- stations -------------------------------------------------------------------------

func _build_bench() -> void:
	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(5.0, 0.1, 2.2)
	top.mesh = tm
	top.position = Vector3(0.0, 0.85, 0.0)
	top.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.85)
	add_child(top)
	for sx in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.12, 0.85, 1.6)
		leg.mesh = lm
		leg.position = Vector3(sx * 2.3, 0.42, 0.0)
		leg.material_override = _matte_mat(Color(0.1, 0.1, 0.12), 0.9)
		add_child(leg)

func _build_scream_and_promise() -> void:
	# the same seed, two questions: a fresh draw per cell, versus the function
	var r := RandomNumberGenerator.new()
	r.seed = seed
	_board(Vector3(-2.05, 0.91, -0.6), 0.62, func(_u, _v): return r.randf())
	_tag(Vector3(-2.05, 0.88, -0.15), "the scream", "white: every sample a stranger")
	_board(Vector3(-2.05, 0.91, 0.5), 0.62, func(u, v): return _n(u * 6.0, v * 6.0))
	_tag(Vector3(-2.05, 0.88, 0.95), "the promise", "same x, same answer - forever")

func _build_frequency_plates() -> void:
	# one cloud, three zooms: frequency is vocabulary
	for i in range(3):
		var mults := [0.5, 1.0, 2.5]
		var mult: float = mults[i]
		var x := -1.15 + 0.5 * float(i)
		_board(Vector3(x, 0.91, -0.45), 0.44, func(u, v): return _n(u * 6.0 * mult, v * 6.0 * mult))
	_tag(Vector3(-0.65, 0.88, -0.02), "frequency", "how fast the neighbourhood forgets")

func _build_octave_stair() -> void:
	# 1, 3, 5 octaves of fbm — each step the sum of the ones before
	for i in range(3):
		var octs := [1, 3, 5]
		var oct: int = octs[i]
		var x := -1.15 + 0.5 * float(i)
		_board(Vector3(x, 0.91 + 0.06 * float(i), 0.55), 0.44,
			func(u, v):
				var total := 0.0
				var amp := 1.0
				var f := 6.0
				var norm := 0.0
				for k in range(oct):
					total += amp * _n(u * f, v * f)
					norm += amp
					amp *= 0.5
					f *= 2.0
				return total / norm)
	_tag(Vector3(-0.65, 0.88, 1.0), "octaves", "big shapes plus their own gossip")

func _build_kind_row() -> void:
	# four temperaments from ONE seed
	var kinds := [
		["Perlin", FastNoiseLite.TYPE_PERLIN],
		["Simplex", FastNoiseLite.TYPE_SIMPLEX],
		["Cellular", FastNoiseLite.TYPE_CELLULAR],
		["Value", FastNoiseLite.TYPE_VALUE],
	]
	for i in range(4):
		var probe := FastNoiseLite.new()
		probe.seed = seed
		probe.frequency = base_frequency
		var kind_row: Array = kinds[i]
		probe.noise_type = kind_row[1]
		var x := 0.15 + 0.42 * float(i)
		_board(Vector3(x, 0.91, -0.5), 0.36,
			func(u, v): return probe.get_noise_2d(u * 6.0, v * 6.0) * 0.5 + 0.5)
		_tag(Vector3(x, 0.88, -0.17), str(kind_row[0]), "")

func _build_vane_field() -> void:
	# the same samples, read as ANGLES: space acquires a lean
	for iy in range(7):
		for ix in range(7):
			var u := (float(ix) + 0.5) / 7.0
			var v := (float(iy) + 0.5) / 7.0
			var ang := (_n(u * 6.0, v * 6.0) - 0.5) * TAU
			var vane := MeshInstance3D.new()
			var vm := PrismMesh.new()
			vm.size = Vector3(0.05, 0.012, 0.08)
			vane.mesh = vm
			vane.position = Vector3(0.15 + u * 0.6, 0.93, 0.35 + v * 0.6)
			vane.rotation.y = ang
			vane.material_override = _glow_mat(Color(0.45, 0.85, 0.8), 0.7)
			add_child(vane)
	_tag(Vector3(0.45, 0.88, 1.05), "the field", "samples read as wills")

func _build_relief() -> void:
	# noise as HEIGHT: the same cloud, extruded
	for iy in range(9):
		for ix in range(9):
			var u := (float(ix) + 0.5) / 9.0
			var v := (float(iy) + 0.5) / 9.0
			var h := 0.04 + 0.28 * _n(u * 6.0, v * 6.0)
			var col := MeshInstance3D.new()
			var cm := BoxMesh.new()
			cm.size = Vector3(0.062, h, 0.062)
			col.mesh = cm
			col.position = Vector3(1.05 + u * 0.62, 0.91 + h * 0.5, 0.35 + v * 0.62)
			col.material_override = _matte_mat(Color(0.55, 0.5, 0.42).lerp(Color(0.85, 0.86, 0.9), (h - 0.04) / 0.28), 0.7)
			add_child(col)
	_tag(Vector3(1.35, 0.88, 1.05), "displacement", "the surface that remembered a storm")

func _build_warp_pair() -> void:
	# plain, then read through itself: the engine ships domain warp, so use it
	var warped := FastNoiseLite.new()
	warped.seed = seed
	warped.frequency = base_frequency
	warped.noise_type = FastNoiseLite.TYPE_PERLIN
	warped.domain_warp_enabled = true
	warped.domain_warp_amplitude = 42.0
	_board(Vector3(1.95, 0.91, -0.5), 0.4, func(u, v): return _n(u * 6.0, v * 6.0))
	_board(Vector3(1.95, 0.91, 0.05), 0.4,
		func(u, v): return warped.get_noise_2d(u * 6.0, v * 6.0) * 0.5 + 0.5)
	_tag(Vector3(1.95, 0.88, 0.4), "noise of noise", "domain warp: where the cloud is READ")

func _build_coastline() -> void:
	# threshold the same field: land, water, and a world
	_board(Vector3(0.0, 0.91, 1.35), 0.7,
		func(u, v):
			var h := _n(u * 5.0, v * 5.0)
			return 1.0 if h > 0.52 else 0.25,
		Color(0.55, 0.85, 0.55))
	_tag(Vector3(0.0, 0.88, 1.78), "the world", "one threshold, and it is a coastline")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "CloudPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-2.55, 0.24, 1.1)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("THE SAME CLOUD",
			"A weather bureau for ONE FastNoiseLite, seed %d: every station reads it and\ndisagrees only about how - as static against weather, at three zooms, stacked\nin octaves, in four temperaments, as wills, as height, read through itself,\nand thresholded into a coastline. Noise is a function, not a dice cup." % seed)
