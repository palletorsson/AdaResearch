extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PhiBecomingRoom

## @identity
## name: Phi Becoming Room
## concept: phi (rate & becoming) — φ·ΔE(S,t) in QFE = F − λE(S) + φΔE(S,t)
## tier: large
## truth: form held alive by its own rate of change — a room of becoming where stillness would mean collapse.
##
## A room-scale staging of φ: forms that exist only because they keep changing. A 7×7 floor
## holds a river of transformation down the middle (flowing emissive ribbon of units), flanked
## by tall morphing columns that perpetually twist, swell, and re-form, and standing-wave
## sculptures that breathe. Nothing here is static; the whole room is its own motion. Stop it
## and it would slump. Overhead: "BECOMING — FORM HELD ALIVE BY ITS OWN RATE OF CHANGE".

@export var river_units: int = 120
@export var column_units: int = 70
@export var column_count: int = 4
@export var river_color: Color = Color(0.4, 0.9, 1.0)
@export var column_color: Color = Color(0.6, 0.7, 1.0)
@export var crest_color: Color = Color(0.75, 1.0, 0.85)
@export var floor_color: Color = Color(0.07, 0.1, 0.18)
@export var flow_speed: float = 1.2

var _river_mm: MultiMesh
var _river_inst: MultiMeshInstance3D
var _river_t: PackedFloat32Array = PackedFloat32Array()   # per-unit parameter along the river

var _col_mm: MultiMesh
var _col_inst: MultiMeshInstance3D
var _col_base_h: PackedFloat32Array = PackedFloat32Array()
var _col_ang: PackedFloat32Array = PackedFloat32Array()
var _col_which: PackedInt32Array = PackedInt32Array()
var _col_phase: PackedFloat32Array = PackedFloat32Array()
var _col_origins: Array = []                              # Vector3 base of each column

var _t: float = 0.0


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
	# --- 7×7 floor (large-tier, y = -0.05) ---
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), _matte_mat(floor_color, 0.85, 0.1)))
	# the riverbed channel down the middle (a darker recessed strip)
	add_child(_box(Vector3(0.0, 0.0, 0.0), Vector3(1.2, 0.02, 6.6), _glow_mat(river_color * 0.3, 0.5)))

	# --- column origins flanking the river (2 per side) ---
	_col_origins = [
		Vector3(-2.1, 0.0, -1.6), Vector3(-2.1, 0.0, 1.6),
		Vector3(2.1, 0.0, -1.6), Vector3(2.1, 0.0, 1.6)]
	column_count = _col_origins.size()
	# faint base plinths under each column
	for o in _col_origins:
		add_child(_box((o as Vector3) + Vector3(0.0, 0.05, 0.0), Vector3(0.7, 0.1, 0.7), _steel_mat(column_color * 0.4)))

	# --- overhead title (large-tier y ~ 3.6) ---
	add_child(_billboard_label("BECOMING — FORM HELD ALIVE BY ITS OWN RATE OF CHANGE", Vector3(0.0, 3.6, 0.0), 26, Color(0.86, 0.96, 1.0)))
	add_child(_billboard_label("stop, and it would collapse", Vector3(0.0, 3.32, 0.0), 18, Color(0.62, 0.74, 0.92)))
	add_child(_billboard_label("φ · ΔE(S, t)", Vector3(0.0, 3.07, 0.0), 22, crest_color))

	_build_river()
	_build_columns()


func _build_river() -> void:
	_river_mm = MultiMesh.new()
	_river_mm.transform_format = MultiMesh.TRANSFORM_3D
	_river_mm.use_colors = true
	_river_mm.instance_count = river_units
	var sph: SphereMesh = SphereMesh.new()
	sph.radius = 0.07
	sph.height = 0.14
	sph.radial_segments = 7
	sph.rings = 4
	_river_mm.mesh = sph
	_river_inst = MultiMeshInstance3D.new()
	_river_inst.name = "RiverOfBecoming"
	_river_inst.multimesh = _river_mm
	_river_inst.material_override = _glow_mat(river_color, 2.4)
	add_child(_river_inst)

	_river_t.resize(river_units)
	for i in range(river_units):
		_river_t[i] = float(i) / float(river_units)
	_apply_river()


func _build_columns() -> void:
	var total: int = column_units * column_count
	_col_mm = MultiMesh.new()
	_col_mm.transform_format = MultiMesh.TRANSFORM_3D
	_col_mm.use_colors = true
	_col_mm.instance_count = total
	var cube: BoxMesh = BoxMesh.new()
	cube.size = Vector3.ONE * 0.13
	_col_mm.mesh = cube
	_col_inst = MultiMeshInstance3D.new()
	_col_inst.name = "MorphingColumns"
	_col_inst.multimesh = _col_mm
	_col_inst.material_override = _glow_mat(column_color, 2.0)
	add_child(_col_inst)

	_col_base_h.resize(total)
	_col_ang.resize(total)
	_col_which.resize(total)
	_col_phase.resize(total)
	for i in range(total):
		var which: int = i / column_units
		var local: int = i % column_units
		_col_which[i] = which
		_col_base_h[i] = float(local) / float(column_units)
		_col_ang[i] = _col_base_h[i] * TAU * 2.5 + _rng.randf() * 0.4
		_col_phase[i] = _rng.randf() * TAU
	_apply_columns()


func _apply_river() -> void:
	# units stream from -Z to +Z, weaving side to side and bobbing — a flowing ribbon.
	for i in range(river_units):
		var p: float = fmod(_river_t[i] + _t * 0.06 * flow_speed, 1.0)
		var z: float = lerp(-3.2, 3.2, p)
		var weave: float = sin(p * TAU * 2.0 + _t * flow_speed) * 0.42
		var bob: float = 0.35 + 0.12 * sin(p * TAU * 4.0 - _t * 2.0 * flow_speed)
		var pos: Vector3 = Vector3(weave, bob, z)
		var s: float = 0.7 + 0.5 * sin(p * TAU * 3.0 + _t)
		var b: Basis = Basis().scaled(Vector3.ONE * clampf(s, 0.4, 1.4))
		_river_mm.set_instance_transform(i, Transform3D(b, pos))
		# crest brighter where the flow rises
		var col: Color = river_color.lerp(crest_color, clampf((bob - 0.3) / 0.2, 0.0, 1.0))
		_river_mm.set_instance_color(i, col)


func _apply_columns() -> void:
	var col_height: float = 2.6
	for i in range(_col_mm.instance_count):
		var which: int = _col_which[i]
		var origin: Vector3 = _col_origins[which]
		var h01: float = _col_base_h[i]
		# morphing radius: swells and pinches over time, different per column
		var swell: float = 0.32 + 0.22 * sin(_t * 1.4 + h01 * 6.0 + float(which) * 1.7)
		var ang: float = _col_ang[i] + _t * (1.0 + 0.3 * float(which)) + sin(_t * 0.7 + h01 * 3.0)
		var y: float = h01 * col_height + sin(_t * 2.0 + _col_phase[i]) * 0.05
		var pos: Vector3 = origin + Vector3(cos(ang) * swell, y + 0.1, sin(ang) * swell)
		var spin: float = _t * 1.5 + _col_phase[i]
		var b: Basis = Basis().rotated(Vector3(0.3, 1.0, 0.2).normalized(), spin)
		_col_mm.set_instance_transform(i, Transform3D(b, pos))
		var col: Color = column_color.lerp(crest_color, 0.5 + 0.5 * sin(_t * 1.2 + h01 * 5.0))
		_col_mm.set_instance_color(i, col)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# The whole room is sustained by its motion — never still.
	_apply_river()
	_apply_columns()
