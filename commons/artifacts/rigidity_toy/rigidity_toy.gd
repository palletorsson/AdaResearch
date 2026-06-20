extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RigidityToy

## @identity
## name: "Soft vs rigid (the alive middle)"
## tier: small
## lineage: A held triptych of states — a crystal cube frozen on the left, a soft blob breathing
##   in the middle, a puddle slumped on the right. Only the middle one moves. The two ends are
##   each a kind of death; the alive thing sits between them.
## truth: "RIGID IS DEAD, FLUID IS DEAD — SOFT IS THE ONLY STATE THAT HOLDS A FORM AND STILL FLOWS"
## applications: glass-transition, the lambda_edge of edge-of-chaos systems, living tissue, soft
##   robotics — matter that is structured enough to keep a shape, loose enough to keep changing.

const PUDDLE_PTS: int = 24

@export var spacing: float = 0.16
@export var crystal_col: Color = Color(0.55, 0.78, 0.98)
@export var soft_col: Color = Color(0.95, 0.55, 0.62)
@export var fluid_col: Color = Color(0.45, 0.70, 0.92)
@export var label_col: Color = Color(0.95, 0.92, 0.85)
@export var breath_rate: float = 0.55

var _t: float = 0.0
var _blob: MeshInstance3D = null
var _puddle_mm: MultiMesh = null
var _puddle_dirs: Array = []
var _mid_y: float = 0.18


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("spacing"):
		spacing = clampf(float(config["spacing"]), 0.1, 0.26)
	if config.has("soft_col"):
		soft_col = _parse_color(config["soft_col"], soft_col)
	if config.has("breath_rate"):
		breath_rate = clampf(float(config["breath_rate"]), 0.2, 1.0)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_blob = null
	_puddle_mm = null
	_puddle_dirs.clear()
	_build()


func _build() -> void:
	# Held cradle so the triptych has a base — no table.
	add_child(_box(Vector3(0.0, 0.02, 0.0), Vector3(spacing * 4.0, 0.025, 0.16), _matte_mat(Color(0.18, 0.18, 0.22), 0.7)))

	var lx: float = -spacing * 1.6
	var mx: float = 0.0
	var rx: float = spacing * 1.6

	# LEFT — rigid: a faceted crystal cube. One shape, locked, never moves. Dead.
	var crystal := _box(Vector3(lx, _mid_y, 0.0), Vector3(0.11, 0.11, 0.11), _glass_mat(crystal_col, 0.55))
	crystal.rotation = Vector3(0.4, 0.8, 0.2)
	add_child(crystal)
	# Spike studs to read it as hard/crystalline.
	for i in range(4):
		var ang: float = TAU * float(i) / 4.0
		add_child(_box(Vector3(lx + cos(ang) * 0.07, _mid_y, sin(ang) * 0.07), Vector3(0.02, 0.02, 0.02), _glow_mat(crystal_col, 0.8)))

	# MIDDLE — soft: an alive blob. Holds a roundish form AND breathes. The living one.
	_blob = _sphere(Vector3(mx, _mid_y, 0.0), 0.075, _glow_mat(soft_col, 0.6))
	add_child(_blob)

	# RIGHT — fluid: a slumped puddle, no form left to hold. Spread flat. Dead.
	_puddle_mm = MultiMesh.new()
	_puddle_mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 6
	sm.rings = 3
	_puddle_mm.mesh = sm
	_puddle_mm.instance_count = PUDDLE_PTS
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = _puddle_mm
	mi.material_override = _glow_mat(fluid_col, 0.5)
	add_child(mi)
	for i in range(PUDDLE_PTS):
		var a: float = _rng.randf() * TAU
		var rr: float = sqrt(_rng.randf())
		_puddle_dirs.append(Vector3(cos(a) * rr, 0.0, sin(a) * rr))
	_refresh_puddle()

	# Tiny state labels under each.
	add_child(_billboard_label("RIGID", Vector3(lx, _mid_y - 0.11, 0.0), 9, crystal_col))
	add_child(_billboard_label("SOFT", Vector3(mx, _mid_y - 0.11, 0.0), 10, soft_col))
	add_child(_billboard_label("FLUID", Vector3(rx, _mid_y - 0.07, 0.0), 9, fluid_col))

	add_child(_billboard_label("RIGID IS DEAD, FLUID IS DEAD —\nSOFT HOLDS A FORM AND STILL FLOWS", Vector3(0.0, _mid_y + 0.18, 0.0), 13, label_col))


func _refresh_puddle() -> void:
	if _puddle_mm == null:
		return
	var rx: float = spacing * 1.6
	var spread: float = 0.085
	var stud: float = 0.013
	for i in range(_puddle_dirs.size()):
		var d: Vector3 = _puddle_dirs[i]
		var ripple: float = 0.006 * sin(_t * 1.4 + float(i) * 0.7)
		var p := Vector3(rx + d.x * spread, _mid_y - 0.045 + ripple, d.z * spread)
		_puddle_mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(stud, stud * 0.5, stud)), p))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Only the middle breathes — the alive one. The crystal and puddle are inert.
	if _blob != null:
		var s: float = 1.0 + sin(_t * TAU * breath_rate) * 0.22
		var wobble: float = 1.0 + cos(_t * TAU * breath_rate * 1.3) * 0.07
		_blob.scale = Vector3(s * wobble, s / wobble, s)
	# The puddle only shivers faintly — surface tension, no real life.
	_refresh_puddle()
