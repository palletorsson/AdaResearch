extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BspFloorplanTool

## @identity
## name: "Boolean & space partition"
## tier: applied
## truth: "EVERY FEW SECONDS, A NEW BUILDING FROM THE SAME RULE" — the partition rule
##   is fixed; only the random cuts change, and each run is a different plausible plan.
## essence: A ~1m device. It regenerates a BSP floor plan every ~3 seconds — a fresh
##   split tree carved into rooms on a lit plate — and shows the resulting room count
##   on a readout. The machine is a level designer that never tires.

@export var plan: float = 0.78
@export var min_leaf: float = 0.09
@export var max_depth: int = 4
@export var regen_period: float = 3.0
@export var body_col: Color = Color(0.18, 0.19, 0.23)
@export var plate_col: Color = Color(0.08, 0.09, 0.11)
@export var floor_col: Color = Color(0.30, 0.45, 0.60)
@export var wall_col: Color = Color(0.70, 0.66, 0.60)
@export var label_col: Color = Color(0.84, 0.90, 0.98)

const PAL := [
	Color(0.30, 0.65, 0.95),
	Color(0.95, 0.55, 0.25),
	Color(0.45, 0.85, 0.55),
	Color(0.90, 0.40, 0.65),
	Color(0.95, 0.85, 0.30),
]

var _t: float = 0.0
var _container: Node3D = null
var _readout: Label3D = null
var _room_count: int = 0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("max_depth"):
		max_depth = clampi(int(config["max_depth"]), 2, 6)
	if config.has("regen_period"):
		regen_period = clampf(float(config["regen_period"]), 1.0, 10.0)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_container = null
	_readout = null
	_t = 0.0
	_build()


func _split(x: float, z: float, w: float, d: float, depth: int, horizontal: bool) -> void:
	var too_small: bool = (w < min_leaf * 2.0) or (d < min_leaf * 2.0)
	if depth >= max_depth or too_small or (depth >= 2 and _rng.randf() < 0.20):
		_emit_room(x, z, w, d, depth)
		return
	var ratio: float = _rng.randf_range(0.38, 0.62)
	if horizontal:
		var dw: float = w * ratio
		_split(x, z, dw, d, depth + 1, false)
		_split(x + dw, z, w - dw, d, depth + 1, false)
	else:
		var dd: float = d * ratio
		_split(x, z, w, dd, depth + 1, true)
		_split(x, z + dd, w, d - dd, depth + 1, true)


func _emit_room(x: float, z: float, w: float, d: float, depth: int) -> void:
	_room_count += 1
	var pad: float = 0.010
	var iw: float = maxf(w - pad * 2.0, 0.02)
	var id: float = maxf(d - pad * 2.0, 0.02)
	var cx: float = x + w * 0.5 - plan * 0.5
	var cz: float = z + d * 0.5 - plan * 0.5
	var col: Color = PAL[depth % PAL.size()]
	_container.add_child(_box(Vector3(cx, 0.002, cz), Vector3(iw, 0.006, id), _glow_mat(col, 1.0)))
	var t: float = 0.010
	var wh: float = 0.04
	_container.add_child(_box(Vector3(cx, wh * 0.5, cz - id * 0.5), Vector3(iw, wh, t), _matte_mat(wall_col, 0.8)))
	_container.add_child(_box(Vector3(cx, wh * 0.5, cz + id * 0.5), Vector3(iw, wh, t), _matte_mat(wall_col, 0.8)))
	_container.add_child(_box(Vector3(cx - iw * 0.5, wh * 0.5, cz), Vector3(t, wh, id), _matte_mat(wall_col, 0.8)))
	_container.add_child(_box(Vector3(cx + iw * 0.5, wh * 0.5, cz), Vector3(t, wh, id), _matte_mat(wall_col, 0.8)))


func _regenerate() -> void:
	for c in _container.get_children():
		_container.remove_child(c)
		c.queue_free()
	_room_count = 0
	_split(0.0, 0.0, plan, plan, 0, _rng.randf() < 0.5)
	if _readout != null:
		_readout.text = "ROOMS: %d" % _room_count


func _build() -> void:
	# ~1m device: body + lit plate on top, plan drawn on the plate
	add_child(_box(Vector3(0.0, 0.30, 0.0), Vector3(0.96, 0.6, 0.96), _matte_mat(body_col, 0.6, 0.2)))
	add_child(_box(Vector3(0.0, 0.62, 0.0), Vector3(plan + 0.06, 0.02, plan + 0.06), _matte_mat(plate_col, 0.4)))

	# container for the regenerated plan, sitting on the plate surface (y ~ 0.63)
	var cont := Node3D.new()
	cont.name = "PlanContainer"
	cont.position = Vector3(0.0, 0.632, 0.0)
	add_child(cont)
	_container = cont

	# readout panel
	add_child(_box(Vector3(0.0, 0.80, -0.40), Vector3(0.5, 0.24, 0.02), _matte_mat(Color(0.07, 0.08, 0.10), 0.5)))
	_readout = _billboard_label("ROOMS: 0", Vector3(0.0, 0.82, -0.38), 18, Color(0.55, 0.90, 0.70))
	add_child(_readout)

	add_child(_billboard_label("BSP FLOORPLAN GENERATOR", Vector3(0.0, 1.18, 0.0), 20, label_col))

	_regenerate()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _t >= regen_period:
		_t = 0.0
		_regenerate()
