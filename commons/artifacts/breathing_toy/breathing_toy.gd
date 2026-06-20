extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BreathingToy

## @identity
## name: "Breathing & the abject boundary"
## tier: small
## lineage: A held breathing sac — a soft sphere that swells and shrinks on a slow pulse, its
##   surface dimpling as it fills and empties. A boundary that does not hold by being rigid; it
##   holds by moving.
## truth: "A BOUNDARY THAT HOLDS BY MOVING — IT BREATHES, SO IT STAYS ITSELF"
## applications: lungs, swim bladders, pneumatic actuators, breathing soft robots — membranes
##   kept alive by their own rhythm.

const SHELL_PTS: int = 64

@export var sac_r: float = 0.13
@export var breath_amt: float = 0.32      # fractional swell
@export var breath_rate: float = 0.55     # Hz-ish
@export var sac_col: Color = Color(0.95, 0.55, 0.62)
@export var dimple_col: Color = Color(0.80, 0.40, 0.50)
@export var label_col: Color = Color(0.95, 0.90, 0.85)

var _t: float = 0.0
var _sac: MeshInstance3D = null
var _dimple_mm: MultiMesh = null
var _dirs: Array = []      # unit directions for dimple studs
var _base_y: float = 0.16


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("sac_r"):
		sac_r = clampf(float(config["sac_r"]), 0.08, 0.2)
	if config.has("breath_amt"):
		breath_amt = clampf(float(config["breath_amt"]), 0.1, 0.5)
	if config.has("sac_col"):
		sac_col = _parse_color(config["sac_col"], sac_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sac = null
	_dimple_mm = null
	_dirs.clear()
	_build()


func _build() -> void:
	# Held cradle so the sac has a resting place — no table.
	add_child(_cylinder(Vector3(0.0, 0.02, 0.0), sac_r * 1.1, 0.03, _matte_mat(Color(0.2, 0.2, 0.24), 0.6)))

	# The breathing sac itself.
	_sac = _sphere(Vector3(0.0, _base_y, 0.0), sac_r, _glow_mat(sac_col, 0.5))
	add_child(_sac)

	# Surface dimples on a fibonacci-ish sphere so the swell reads as a living surface.
	var n: int = SHELL_PTS
	_dimple_mm = MultiMesh.new()
	_dimple_mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 6
	sm.rings = 3
	_dimple_mm.mesh = sm
	_dimple_mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = _dimple_mm
	mi.material_override = _glow_mat(dimple_col, 0.6)
	add_child(mi)
	var golden: float = PI * (3.0 - sqrt(5.0))
	for i in range(n):
		var y: float = 1.0 - 2.0 * (float(i) + 0.5) / float(n)
		var rad: float = sqrt(maxf(0.0, 1.0 - y * y))
		var th: float = golden * float(i)
		_dirs.append(Vector3(cos(th) * rad, y, sin(th) * rad))
	_refresh(1.0)

	add_child(_billboard_label("A BOUNDARY THAT HOLDS BY MOVING", Vector3(0.0, _base_y + sac_r + 0.16, 0.0), 14, label_col))


func _refresh(scale: float) -> void:
	if _sac != null:
		_sac.scale = Vector3.ONE * scale
	if _dimple_mm == null:
		return
	var r: float = sac_r * scale * 1.02
	var dr: float = sac_r * 0.07
	for i in range(_dirs.size()):
		var d: Vector3 = _dirs[i]
		var t := Transform3D(Basis().scaled(Vector3(dr, dr, dr)), Vector3(0.0, _base_y, 0.0) + d * r)
		_dimple_mm.set_instance_transform(i, t)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var s: float = 1.0 + sin(_t * TAU * breath_rate) * breath_amt
	_refresh(s)
