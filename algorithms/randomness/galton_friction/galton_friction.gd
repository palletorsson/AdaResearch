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

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const BakedTextGF = preload("res://commons/utils/baked_text_albedo.gd")

## Housing (cabinet grammar). Two bays, because the artifact IS a comparison:
## the harvest on the left, the crank on the right, one body holding both.
@export var finish: String = "rams"
@export var wear: float = 0.10
@export var unit_code: String = "GF-08"
@export var plinth_height: float = 0.95

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
	_build_twin_bay()
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
	# The harvest is a REAL galton_board — the artifact's whole argument is
	# that the left bay holds the actual apparatus. It now carries its own
	# cabinet and pedestal, so: suppress the inner plinth (the twin-bay
	# supplies one; two stacked pedestals is a mistake, not a machine) and
	# size it to sit inside its bay. Properties are set BEFORE add_child so
	# _ready sees them.
	board.set("plinth_height", 0.0)
	board.set("show_cabinet", false)   # bare board — the twin-bay IS the housing
	board.position = Vector3(-0.40, 0.02, 0.0)
	board.scale = Vector3(0.42, 0.42, 0.42)
	add_child(board)
	_plate("THE HARVEST",
		"physics — chance from a falling body\napparatus · slow · biased · never repeats",
		Vector3(-0.42, 0.56, 0.0), color_bell)


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
		Vector3(0.42, 0.56, 0.0), color_bar)  # match THE HARVEST plate height (twin symmetry)
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


## THE TWIN-BAY COMPARISON — the body says what the artifact says.
## This piece is an argument between two methods: real physics on the left,
## the formula on the right. So it gets TWO BAYS of one slab with a mullion
## between them — the comparison is structural, not a caption.
func _build_twin_bay() -> void:
	var half_w: float = 0.80
	var bot: float = -0.20
	var top: float = 0.74
	var cap_h: float = 0.10
	var z_back: float = -0.06

	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	add_child(cab)

	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_panel: Color = pal["panel"]
	var col_accent: Color = pal["accent"]
	var ew: float = float(pal["wear"]) if finish.to_lower() == "terminal" else wear
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, ew)
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), ew, 0.4, 0.5)
	var maroon: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.11, 0.09), ew)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_panel)
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	# back slab + the mullion that makes it a comparison
	cab.add_child(HangarKit.box(Vector3(0, (bot + top) * 0.5, z_back),
		Vector3(half_w * 2.0, top - bot, 0.05), shell))
	cab.add_child(HangarKit.box(Vector3(0, (bot + top) * 0.5, z_back + 0.035),
		Vector3(0.045, top - bot, 0.06), dark))
	for sx in [-1.0, 1.0]:
		cab.add_child(HangarKit.box(Vector3(sx * (half_w - 0.025), (bot + top) * 0.5, z_back + 0.02),
			Vector3(0.05, top - bot, 0.09), maroon))
		cab.add_child(HangarKit.bolts(
			Vector3(sx * (half_w - 0.025), bot + 0.08, z_back + 0.068),
			Vector3(sx * (half_w - 0.025), top - 0.08, z_back + 0.068), 6, 0.008, steel))

	# the readout leaves the air and takes a screen on the left bay's sill
	var scr_w: float = 0.34
	var scr_h: float = 0.13
	var scr_c := Vector3(-0.42, bot + 0.10, z_back + 0.036)
	cab.add_child(HangarKit.box(scr_c - Vector3(0, 0, 0.004),
		Vector3(scr_w + 0.03, scr_h + 0.025, 0.014), dark))
	cab.add_child(HangarKit.box(scr_c, Vector3(scr_w, scr_h, 0.006),
		HangarKit.emissive(Color(0.12, 0.12, 0.135), 0.45)))
	cab.add_child(HangarKit.box(scr_c + Vector3(0, scr_h * 0.5 + 0.005, 0.004),
		Vector3(scr_w + 0.03, 0.005, 0.005), accent))
	if _readout != null and is_instance_valid(_readout):
		_readout.pixel_size = 0.00042
		_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_readout.position = scr_c + Vector3(0, 0.0, 0.010)

	# sill under both bays + vents on the right bay
	cab.add_child(HangarKit.box(Vector3(0, bot + 0.015, z_back + 0.05),
		Vector3(half_w * 2.0, 0.03, 0.13), dark))
	for gi in range(5):
		cab.add_child(HangarKit.box(
			Vector3(0.42, bot + 0.055 + float(gi) * 0.022, z_back + 0.036),
			Vector3(0.26, 0.010, 0.012), dark))

	# sign cap over the ember line
	cab.add_child(HangarKit.box(Vector3(0, top + cap_h * 0.5, z_back + 0.01),
		Vector3(half_w * 2.0 + 0.06, cap_h, 0.14), shell))
	cab.add_child(HangarKit.box(Vector3(0, top + 0.005, z_back + 0.075),
		Vector3(half_w * 2.0 + 0.06, 0.006, 0.004), accent))
	cab.add_child(HangarKit.box(Vector3(0, top + cap_h * 0.5, z_back + 0.072),
		Vector3(half_w * 2.0 - 0.06, 0.072, 0.012), dark))
	var st: Node3D = BakedTextGF.make_tag("GALTON — FRICTION vs FORMULA",
		Color(0.93, 0.94, 0.97), 0.030, Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if st:
		st.position = Vector3(0, top + cap_h * 0.5 + 0.012, z_back + 0.080)
		cab.add_child(st)
	var ss: Node3D = BakedTextGF.make_tag("ONE BELL, TWO ROADS TO IT",
		Color(0.55, 0.58, 0.66), 0.014, Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if ss:
		ss.position = Vector3(0, top + cap_h * 0.5 - 0.019, z_back + 0.080)
		cab.add_child(ss)

	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.11, 0.028),
		col_accent.lightened(0.25))
	if code:
		code.position = Vector3(-half_w + 0.13, bot + 0.055, z_back + 0.070)
		cab.add_child(code)
	var gb: MeshInstance3D = HangarKit.grime_band(half_w * 1.7, 0.05, z_back + 0.070, col_body)
	if gb:
		gb.position.y = bot
		cab.add_child(gb)

	# pedestal — the whole piece is authored around y=0, i.e. on the floor
	var ped: Node3D = HangarKit.plinth(half_w * 2.0, 0.24, plinth_height, finish, ew,
		col_accent, unit_code)
	if ped:
		ped.position = Vector3(0, bot, z_back + 0.05)
		cab.add_child(ped)
