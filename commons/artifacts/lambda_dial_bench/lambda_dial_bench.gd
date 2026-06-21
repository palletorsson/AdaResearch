extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LambdaDialBench

## @identity
## name: Lambda Dial Bench
## concept: lambda (the order-chaos dial) — λ in QFE = F − λE(S) + φΔE(S,t)
## tier: medium
## truth: life sits at λ ≈ 0.3–0.5 — turn the dial too low and it freezes, too high and it dissolves.
##
## A floor-standing QFEP instrument with one big λ dial you watch sweep 0 → 1. A field of
## ~49 units reads the dial: at λ=0 they lock into a frozen crystal grid, at λ=1 they
## explode into pure noise, and in the gold band λ≈0.3–0.5 they organize into a living,
## breathing, complex pattern. The dial oscillates on its own; the field morphs to match.
## Readout: "λ = 0.40  LIFE".

@export var field_n: int = 7                  # field is n×n units
@export var field_pitch: float = 0.13
@export var field_center: Vector3 = Vector3(0.0, 1.05, 0.0)
@export var sweep_period: float = 12.0        # seconds for one full λ sweep cycle
@export var crystal_color: Color = Color(0.45, 0.75, 1.0)
@export var life_color: Color = Color(0.5, 1.0, 0.65)
@export var noise_color: Color = Color(0.95, 0.5, 0.85)

var _mm: MultiMesh
var _mm_inst: MultiMeshInstance3D
var _count: int = 0
var _grid: PackedVector3Array = PackedVector3Array()    # ordered crystal sites
var _seed_off: PackedVector3Array = PackedVector3Array() # per-unit random vector for noise
var _phase: PackedFloat32Array = PackedFloat32Array()
var _title: Label3D
var _readout: Label3D
var _needle: MeshInstance3D
var _needle_mat: StandardMaterial3D
var _gold_arc: MeshInstance3D
var _lambda: float = 0.0
var _t: float = 0.0
const GOLD_LO: float = 0.3
const GOLD_HI: float = 0.5


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_count = field_n * field_n

	# --- plinth + post ---
	add_child(_cylinder(Vector3(0.0, 0.04, 0.0), 0.46, 0.08, _steel_mat(Color(0.14, 0.18, 0.28))))
	add_child(_cylinder(Vector3(0.0, 0.11, 0.0), 0.40, 0.06, _matte_mat(Color(0.18, 0.24, 0.38), 0.6, 0.3)))
	add_child(_cylinder(Vector3(0.0, 0.42, 0.0), 0.05, 0.6, _steel_mat(Color(0.4, 0.5, 0.7))))

	# --- the big λ dial face (left side, tilted toward viewer) ---
	var dial_center: Vector3 = Vector3(-0.55, 1.05, 0.0)
	add_child(_cylinder(dial_center + Vector3(0.0, 0.0, -0.03), 0.26, 0.04, _matte_mat(Color(0.1, 0.13, 0.2))))
	add_child(_torus(dial_center, 0.26, 0.02, _steel_mat(Color(0.6, 0.66, 0.8))))
	# tick marks 0 → 1 across a 270° arc
	for ti in range(11):
		var frac: float = float(ti) / 10.0
		var a: float = lerp(2.356, -2.356, frac)   # 135° → -135°
		var tip: Vector3 = dial_center + Vector3(cos(a), sin(a), 0.0) * 0.24
		var inn: Vector3 = dial_center + Vector3(cos(a), sin(a), 0.0) * 0.20
		add_child(_cylinder_between(inn, tip, 0.006, _glow_mat(Color(0.7, 0.8, 1.0), 1.4)))
	# gold zone arc (λ 0.3–0.5) — a bright band on the dial
	_gold_arc = _make_arc(dial_center, 0.215, GOLD_LO, GOLD_HI, _glow_mat(Color(1.0, 0.85, 0.3), 2.6))
	add_child(_gold_arc)
	add_child(_billboard_label("0", dial_center + Vector3(-0.18, -0.2, 0.01), 13, Color(0.7, 0.78, 0.9)))
	add_child(_billboard_label("1", dial_center + Vector3(0.18, -0.2, 0.01), 13, Color(0.7, 0.78, 0.9)))
	add_child(_billboard_label("λ", dial_center + Vector3(0.0, 0.33, 0.01), 22, Color(0.9, 0.95, 1.0)))
	# the needle (rotates with λ)
	_needle_mat = _glow_mat(Color(1.0, 0.4, 0.4), 2.4)
	_needle = _cylinder(dial_center, 0.008, 0.22, _needle_mat)
	add_child(_needle)
	add_child(_sphere(dial_center, 0.03, _steel_mat(Color(0.8, 0.85, 0.95))))

	# --- title + readout ---
	_title = _billboard_label("λ  —  THE ORDER-CHAOS DIAL", Vector3(0.0, 1.5, 0.0), 22, Color(0.88, 0.95, 1.0))
	add_child(_title)
	add_child(_billboard_label("0 = crystal · 0.4 = LIFE · 1 = noise", Vector3(0.0, 1.36, 0.0), 14, Color(0.7, 0.78, 0.92)))
	_readout = _billboard_label("λ = 0.00", Vector3(0.42, 1.22, 0.0), 22, life_color)
	add_child(_readout)

	# --- the field that reads the dial ---
	_grid.resize(_count)
	_seed_off.resize(_count)
	_phase.resize(_count)
	var i: int = 0
	var off: float = float(field_n - 1) * 0.5
	for ix in range(field_n):
		for iz in range(field_n):
			_grid[i] = field_center + Vector3((float(ix) - off) * field_pitch, 0.0, (float(iz) - off) * field_pitch)
			_seed_off[i] = Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0))
			_phase[i] = _rng.randf() * TAU
			i += 1

	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.instance_count = _count
	var cube: BoxMesh = BoxMesh.new()
	cube.size = Vector3.ONE * (field_pitch * 0.46)
	_mm.mesh = cube
	_mm_inst = MultiMeshInstance3D.new()
	_mm_inst.name = "LambdaField"
	_mm_inst.multimesh = _mm
	_mm_inst.material_override = _glow_mat(Color(1, 1, 1), 1.8)
	add_child(_mm_inst)

	_apply_field()


func _life_strength(lam: float) -> float:
	# peaks at the center of the gold band, falls off either side.
	var mid: float = (GOLD_LO + GOLD_HI) * 0.5
	var d: float = absf(lam - mid) / 0.28
	return clampf(1.0 - d * d, 0.0, 1.0)


func _apply_field() -> void:
	var life: float = _life_strength(_lambda)
	# crystal weight high when λ low; noise weight high when λ high.
	var noise_w: float = clampf((_lambda - GOLD_HI) / (1.0 - GOLD_HI), 0.0, 1.0)
	var spread: float = field_pitch * (field_n) * 0.5
	for i in range(_count):
		var site: Vector3 = _grid[i]
		# noise displacement (grows with λ past the gold band)
		var noise: Vector3 = _seed_off[i] * spread * noise_w
		noise += Vector3(
			sin(_t * 3.0 + _phase[i]),
			cos(_t * 2.6 + _phase[i] * 1.4),
			sin(_t * 2.2 + _phase[i] * 0.7)) * (field_pitch * 1.6 * noise_w)
		# life displacement: a coherent travelling wave — only in the gold band
		var wave: float = sin((site.x + site.z) * 6.0 - _t * 3.0 + _phase[i] * 0.2)
		var living: Vector3 = Vector3(0.0, wave * field_pitch * 0.9 * life, 0.0)
		var pos: Vector3 = site + noise + living
		var b: Basis = Basis()
		var spin: float = noise_w * (_phase[i] + _t * 1.5)
		b = b.rotated(Vector3(0.4, 1.0, 0.2).normalized(), spin)
		_mm.set_instance_transform(i, Transform3D(b, pos))
		# color: crystal → life → noise
		var col: Color = crystal_color
		if _lambda <= GOLD_HI:
			col = crystal_color.lerp(life_color, life)
		else:
			col = life_color.lerp(noise_color, noise_w)
		_mm.set_instance_color(i, col)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# λ oscillates 0 → 1 → 0 slowly, lingering a touch in the gold band.
	var raw: float = 0.5 - 0.5 * cos(_t * TAU / sweep_period)
	_lambda = clampf(raw, 0.0, 1.0)
	_apply_field()

	# rotate the needle to match λ (135° → -135°)
	if _needle != null:
		var a: float = lerp(2.356, -2.356, _lambda)
		var dial_center: Vector3 = Vector3(-0.55, 1.05, 0.0)
		var dir: Vector3 = Vector3(cos(a), sin(a), 0.0)
		_needle.transform = Transform3D(_basis_y_to(dir), dial_center + dir * 0.11)
		# needle warms toward red as it leaves the gold band
		var life: float = _life_strength(_lambda)
		_needle_mat.emission = Color(1.0, 0.4, 0.4).lerp(Color(1.0, 0.85, 0.3), life)

	# readout text + a verdict word
	if _readout != null:
		var verdict: String = "NOISE"
		var col: Color = noise_color
		if _lambda < GOLD_LO:
			verdict = "FROZEN"
			col = crystal_color
		elif _lambda <= GOLD_HI:
			verdict = "LIFE"
			col = life_color
		_readout.text = "λ = %.2f  %s" % [_lambda, verdict]
		_readout.modulate = col


# --- a thin filled arc band on the dial face (immediate-mesh ring sector) ---
func _make_arc(center: Vector3, radius: float, frac_lo: float, frac_hi: float, mat: Material) -> MeshInstance3D:
	var im: ImmediateMesh = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)
	var inner: float = radius - 0.03
	var outer: float = radius + 0.03
	var segs: int = 16
	var a_lo: float = lerp(2.356, -2.356, frac_lo)
	var a_hi: float = lerp(2.356, -2.356, frac_hi)
	for s in range(segs):
		var t0: float = float(s) / float(segs)
		var t1: float = float(s + 1) / float(segs)
		var aa: float = lerp(a_lo, a_hi, t0)
		var ab: float = lerp(a_lo, a_hi, t1)
		var i0: Vector3 = Vector3(cos(aa) * inner, sin(aa) * inner, 0.0)
		var o0: Vector3 = Vector3(cos(aa) * outer, sin(aa) * outer, 0.0)
		var i1: Vector3 = Vector3(cos(ab) * inner, sin(ab) * inner, 0.0)
		var o1: Vector3 = Vector3(cos(ab) * outer, sin(ab) * outer, 0.0)
		im.surface_add_vertex(i0)
		im.surface_add_vertex(o0)
		im.surface_add_vertex(o1)
		im.surface_add_vertex(i0)
		im.surface_add_vertex(o1)
		im.surface_add_vertex(i1)
	im.surface_end()
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = im
	mi.position = center + Vector3(0.0, 0.0, 0.01)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
