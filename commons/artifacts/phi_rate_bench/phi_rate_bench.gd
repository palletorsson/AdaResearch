extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PhiRateBench

## @identity
## name: Phi Rate Bench
## concept: phi (rate & becoming) — φ·ΔE(S,t) in QFE = F − λE(S) + φΔE(S,t)
## tier: medium
## truth: some forms are preserved only by being kept in motion — freeze the rate and they die.
##
## A floor-standing QFEP instrument staging φ as sensitivity to the RATE of change (ΔE/Δt).
## A pattern — a standing wave column / a flame of ~60 units — exists ONLY while it moves.
## The instrument periodically "freezes" the rate to zero: the form instantly slumps, greys,
## and collapses to a dead pile. Let the rate return and it springs back to life. A readout
## tracks "ΔE/Δt" rising and falling with the motion.

@export var unit_count: int = 60
@export var column_radius: float = 0.16
@export var column_height: float = 0.9
@export var column_center: Vector3 = Vector3(0.0, 1.05, 0.0)
@export var freeze_period: float = 8.0        # seconds between freeze events
@export var alive_color: Color = Color(0.4, 0.95, 1.0)
@export var hot_color: Color = Color(0.7, 0.95, 1.0)
@export var dead_color: Color = Color(0.32, 0.34, 0.4)

var _mm: MultiMesh
var _mm_inst: MultiMeshInstance3D
var _count: int = 0
var _base_ang: PackedFloat32Array = PackedFloat32Array()
var _base_h: PackedFloat32Array = PackedFloat32Array()
var _phase: PackedFloat32Array = PackedFloat32Array()
var _title: Label3D
var _readout: Label3D
var _rate_bar: MeshInstance3D
var _rate_bar_mat: StandardMaterial3D
var _t: float = 0.0
var _rate: float = 1.0      # 0 = frozen (dead), 1 = full motion (alive)


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
	_count = unit_count

	# --- plinth + post ---
	add_child(_cylinder(Vector3(0.0, 0.04, 0.0), 0.44, 0.08, _steel_mat(Color(0.14, 0.18, 0.28))))
	add_child(_cylinder(Vector3(0.0, 0.11, 0.0), 0.38, 0.06, _matte_mat(Color(0.18, 0.24, 0.38), 0.6, 0.3)))
	add_child(_cylinder(Vector3(0.0, 0.4, 0.0), 0.05, 0.5, _steel_mat(Color(0.4, 0.5, 0.7))))
	# emitter ring at the base of the flame/wave
	add_child(_torus(column_center + Vector3(0.0, -column_height * 0.5 - 0.02, 0.0), column_radius + 0.04, 0.02, _glow_mat(alive_color, 2.2)))

	# --- title + readout ---
	_title = _billboard_label("φ  —  RATE & BECOMING", Vector3(0.0, 1.72, 0.0), 22, Color(0.88, 0.95, 1.0))
	add_child(_title)
	add_child(_billboard_label("φ·ΔE/Δt  —  alive only while moving", Vector3(0.0, 1.58, 0.0), 14, Color(0.7, 0.78, 0.92)))
	_readout = _billboard_label("ΔE/Δt", Vector3(0.46, 1.34, 0.0), 22, alive_color)
	add_child(_readout)

	# --- ΔE/Δt meter rail + fill ---
	add_child(_box(Vector3(-0.46, 1.05, 0.0), Vector3(0.04, 0.55, 0.04), _matte_mat(Color(0.1, 0.13, 0.2))))
	_rate_bar_mat = _glow_mat(alive_color, 2.2)
	_rate_bar = _box(Vector3(-0.46, 1.05, 0.0), Vector3(0.05, 0.55, 0.05), _rate_bar_mat)
	add_child(_rate_bar)
	add_child(_billboard_label("ΔE/Δt", Vector3(-0.46, 1.4, 0.0), 14, Color(0.85, 0.9, 1.0)))

	# --- the form: a column of units arranged as a helix/flame ---
	_base_ang.resize(_count)
	_base_h.resize(_count)
	_phase.resize(_count)
	for i in range(_count):
		_base_h[i] = float(i) / float(_count)                       # 0..1 up the column
		_base_ang[i] = _base_h[i] * TAU * 3.0 + _rng.randf() * 0.3   # helical twist
		_phase[i] = _rng.randf() * TAU
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.instance_count = _count
	var sph: SphereMesh = SphereMesh.new()
	sph.radius = 0.03
	sph.height = 0.06
	sph.radial_segments = 7
	sph.rings = 4
	_mm.mesh = sph
	_mm_inst = MultiMeshInstance3D.new()
	_mm_inst.name = "StandingWave"
	_mm_inst.multimesh = _mm
	_mm_inst.material_override = _glow_mat(Color(1, 1, 1), 2.2)
	add_child(_mm_inst)

	_apply_form()


func _apply_form() -> void:
	# rate 1 → a coherent living standing wave / flame; rate 0 → collapsed dead pile.
	var bottom: float = column_center.y - column_height * 0.5
	for i in range(_count):
		var h01: float = _base_h[i]
		# alive height taper (flame narrows toward the top)
		var taper: float = 1.0 - h01 * 0.6
		var rad: float = column_radius * taper
		# the wave: angle + radial breathing driven by time × rate
		var ang: float = _base_ang[i] + _t * 2.5 * _rate
		var breath: float = 1.0 + 0.35 * sin(_t * 4.0 * _rate + _phase[i])
		var alive_pos: Vector3 = Vector3(
			cos(ang) * rad * breath,
			bottom + h01 * column_height + sin(_t * 5.0 * _rate + _phase[i]) * 0.04 * _rate,
			sin(ang) * rad * breath)
		# dead pose: everything slumps to a low disordered pile at the base
		var dead_pos: Vector3 = Vector3(
			cos(_phase[i]) * column_radius * 1.3 * h01 * 0.4,
			bottom + h01 * 0.12,
			sin(_phase[i]) * column_radius * 1.3 * h01 * 0.4)
		var pos: Vector3 = column_center + dead_pos.lerp(alive_pos, _rate)
		_mm.set_instance_transform(i, Transform3D(Basis(), pos))
		var col: Color = dead_color.lerp(alive_color.lerp(hot_color, h01), _rate)
		_mm.set_instance_color(i, col)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Most of the time fully alive (rate≈1). Periodically the rate is frozen to ~0,
	# the form collapses, then the rate returns and it springs back.
	var phase: float = fmod(_t, freeze_period) / freeze_period
	if phase > 0.72 and phase < 0.86:
		# brief freeze window: rate dives to ~0 (form dies)
		var f: float = (phase - 0.72) / 0.14         # 0..1 across the window
		_rate = 1.0 - sin(f * PI) * 0.96             # dip to ~0.04 and back
	else:
		_rate = 1.0
	_apply_form()

	# meter + readout follow the rate
	if _rate_bar != null:
		var hh: float = clampf(_rate, 0.02, 1.0) * 0.55
		var bm: BoxMesh = _rate_bar.mesh as BoxMesh
		bm.size = Vector3(0.05, hh, 0.05)
		_rate_bar.position = Vector3(-0.46, (1.05 - 0.275) + hh * 0.5, 0.0)
		_rate_bar_mat.emission = dead_color.lerp(alive_color, _rate)
	if _readout != null:
		if _rate < 0.2:
			_readout.text = "ΔE/Δt → 0\nFROZEN = DEAD"
			_readout.modulate = dead_color
		else:
			_readout.text = "ΔE/Δt = %.2f\nMOVING = ALIVE" % _rate
			_readout.modulate = alive_color.lerp(hot_color, _rate)
