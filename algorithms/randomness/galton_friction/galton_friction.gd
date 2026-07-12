# galton_friction.gd — TWO SOLUTIONS TO ONE PROBLEM, side by side.
#
# The Galton bell needs many FAIR, INDEPENDENT coin-flips. Godot's physics
# does not hand you fair coins: a ball landing dead-centre on a peg is an
# unstable equilibrium the solver breaks the same way every time, and a ball's
# bounces are linked through its own momentum. So the same bell has two roads,
# and this artifact runs both at once:
#
#   LEFT  — THE HARVEST: a real rigid-body cascade (the existing galton_board).
#           Chance drawn from a falling body. An apparatus, slow, lumpy,
#           biased, never the same twice. Real randomness, and expensive.
#   RIGHT — THE CRANK: each ball's bin is sum(randf() < 0.5). Chance computed
#           from a formula. Instant, a few lines, a perfect bell, and the same
#           bell every time you set the seed. Fake randomness, and cheap.
#
# The crank is smaller because it is cheaper. That asymmetry is the whole
# point: what the system can hold is the crank; real randomness is too
# expensive or too specific to keep everywhere. The bell you trust is almost
# always manufactured.
extends Node3D
class_name GaltonFriction

const PHYS_BOARD := preload("res://algorithms/randomness/galton_board/galton_board.tscn")

@export var rows: int = 8
@export var rng_seed: int = 1955
@export var balls_per_second: float = 12.0
@export var bin_width: float = 0.035
@export var bin_gap: float = 0.006
@export var max_bar: float = 0.26
@export var color_bar: Color = Color(0.3, 0.7, 1.0)
@export var color_bell: Color = Color(1.0, 0.62, 0.18)

var _rng := RandomNumberGenerator.new()
var _bins: Array[int] = []
var _total: int = 0
var _bars: Array[MeshInstance3D] = []
var _drop_t: float = 0.0
var _readout: Label3D
var _crank_x0: float = 0.0


func _ready() -> void:
	_rng.seed = rng_seed
	_bins.clear()
	for _i in range(rows + 1):
		_bins.append(0)
	_build_harvest()
	_build_crank()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_rng_seed"):
		rng_seed = int(str(get_meta("config_rng_seed")))
	if has_meta("config_rows"):
		rows = int(str(get_meta("config_rows")))


# ── LEFT: the harvest (real physics, the expensive apparatus) ────────────────
func _build_harvest() -> void:
	var board: Node3D = PHYS_BOARD.instantiate()
	board.name = "Harvest"
	board.position = Vector3(-0.62, 0.0, 0.0)
	board.scale = Vector3(0.62, 0.62, 0.62)
	add_child(board)
	_plate("THE HARVEST",
		"physics — chance from a falling body\napparatus · slow · biased · never repeats",
		Vector3(-0.62, 0.46, 0.0), color_bell)


# ── RIGHT: the crank (pseudo, the cheap formula) ─────────────────────────────
func _build_crank() -> void:
	var n: int = rows + 1
	var total_w: float = float(n) * (bin_width + bin_gap)
	_crank_x0 = 0.42 - total_w * 0.5
	# floor line
	var floor_mesh := MeshInstance3D.new()
	var fbm := BoxMesh.new()
	fbm.size = Vector3(total_w + 0.02, 0.004, bin_width + 0.02)
	floor_mesh.mesh = fbm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.12, 0.12, 0.16)
	floor_mesh.material_override = fmat
	floor_mesh.position = Vector3(0.42, -0.002, 0.0)
	add_child(floor_mesh)
	for i in range(n):
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(bin_width, 0.002, bin_width)
		bar.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_bar
		mat.emission_enabled = true
		mat.emission = color_bar * 0.4
		mat.emission_energy_multiplier = 0.3
		bar.material_override = mat
		bar.position = Vector3(_crank_x0 + float(i) * (bin_width + bin_gap), 0.001, 0.0)
		add_child(bar)
		_bars.append(bar)
	_bell_overlay(n)
	_plate("THE CRANK",
		"pseudo — bin = sum(randf() < 0.5)\nformula · instant · perfect · same seed same bell",
		Vector3(0.42, 0.46, 0.0), color_bar)
	_readout = Label3D.new()
	_readout.text = "0 balls"
	_readout.font_size = 44
	_readout.pixel_size = 0.0005
	_readout.modulate = Color(0.82, 0.86, 0.95)
	_readout.position = Vector3(0.42, -0.05, 0.0)
	add_child(_readout)


func _bell_overlay(n: int) -> void:
	# the ideal Binomial(rows, 0.5) the crank converges to, as amber dots
	var pmf: Array[float] = []
	var peak: float = 0.0
	for k in range(n):
		var c: float = _binom(rows, k)
		pmf.append(c)
		if c > peak:
			peak = c
	for k in range(n):
		var dot := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.007
		sm.height = 0.014
		dot.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_bell
		mat.emission_enabled = true
		mat.emission = color_bell
		dot.material_override = mat
		var h: float = pmf[k] / peak * max_bar
		dot.position = Vector3(_crank_x0 + float(k) * (bin_width + bin_gap), h, 0.028)
		add_child(dot)


func _process(delta: float) -> void:
	_drop_t += delta
	var interval: float = 1.0 / maxf(balls_per_second, 0.1)
	while _drop_t >= interval and _total < 20000:
		_drop_t -= interval
		_drop_one()


func _drop_one() -> void:
	var bin: int = 0
	for _r in range(rows):
		if _rng.randf() < 0.5:
			bin += 1
	_bins[bin] += 1
	_total += 1
	_refresh_bars()
	if _readout != null:
		_readout.text = "%d balls · seed %d\ninstant · exact · repeatable" % [_total, rng_seed]


func _refresh_bars() -> void:
	var peak: int = 1
	for v in _bins:
		if v > peak:
			peak = v
	for i in range(_bars.size()):
		var h: float = maxf(0.002, float(_bins[i]) / float(peak) * max_bar)
		var bm: BoxMesh = _bars[i].mesh
		bm.size = Vector3(bin_width, h, bin_width)
		_bars[i].position.y = h * 0.5


# ── the thesis plate (2D-in-3D, no floating label) ───────────────────────────
func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.46, 0.17, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	add_child(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.46, 0.012, 0.012)
	strip.mesh = sbm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent
	smat.emission_enabled = true
	smat.emission = accent
	strip.material_override = smat
	strip.position = pos + Vector3(0.0, 0.09, 0.006)
	add_child(strip)
	var t := Label3D.new()
	t.text = title + "\n\n" + body
	t.font_size = 38
	t.pixel_size = 0.00042
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	add_child(t)


func _binom(n: int, k: int) -> float:
	var r: float = 1.0
	for i in range(k):
		r = r * float(n - i) / float(i + 1)
	return r
