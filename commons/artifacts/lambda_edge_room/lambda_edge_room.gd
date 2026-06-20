extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LambdaEdgeRoom

## @identity
## name: "Soft vs rigid (the alive middle)"
## tier: large
## lineage: A room split into three bands. A rigid crystalline wall locks the far side; a fluid
##   pool slumps and ripples on the near side; and through the middle band the soft alive forms
##   breathe. You walk in and stand on the lambda_edge — the only strip where matter is both held
##   and moving.
## truth: "THE LAMBDA_EDGE MADE FLESH — BETWEEN THE FROZEN WALL AND THE FORMLESS POOL, LIFE"
## applications: edge-of-chaos computation, the critical band of phase transitions, the habitable
##   zone, living tissue between bone and blood — order parameter tuned to its one alive value.

const POOL_PTS: int = 120
const CRYSTAL_COLS: int = 7

@export var room: float = 7.0
@export var n_blobs: int = 5
@export var crystal_col: Color = Color(0.55, 0.80, 0.99)
@export var soft_col: Color = Color(0.95, 0.55, 0.62)
@export var fluid_col: Color = Color(0.40, 0.68, 0.92)
@export var floor_col: Color = Color(0.10, 0.11, 0.14)
@export var label_col: Color = Color(0.96, 0.92, 0.86)
@export var breath_rate: float = 0.3

var _t: float = 0.0
var _blobs: Array = []       # each: { node:MeshInstance3D, phase:float, base:Vector3 }
var _pool_mm: MultiMesh = null
var _pool_p: Array = []      # each: Vector3 base
var _crystals: Array = []    # rigid columns (inert)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("n_blobs"):
		n_blobs = int(clampf(float(config["n_blobs"]), 3, 8))
	if config.has("soft_col"):
		soft_col = _parse_color(config["soft_col"], soft_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_blobs.clear()
	_pool_mm = null
	_pool_p.clear()
	_crystals.clear()
	_build()


func _build() -> void:
	var h: float = room * 0.5
	# Floor.
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room, 0.1, room), _matte_mat(floor_col, 0.9)))

	# FAR BAND (-Z) — RIGID: a crystalline wall of frozen prisms. One shape, dead.
	add_child(_box(Vector3(0.0, 1.6, -h + 0.2), Vector3(room, 3.2, 0.3), _glass_mat(crystal_col, 0.4)))
	for i in range(CRYSTAL_COLS):
		var cx: float = lerpf(-h * 0.85, h * 0.85, float(i) / float(CRYSTAL_COLS - 1))
		var crys := _box(Vector3(cx, 1.1, -h + 0.7), Vector3(0.5, 2.2, 0.5), _glass_mat(crystal_col, 0.55))
		crys.rotation.y = _rng.randf_range(-0.3, 0.3)
		add_child(crys)
		# Sharp cap to read as crystal.
		var cap := _box(Vector3(cx, 2.4, -h + 0.7), Vector3(0.5, 0.5, 0.5), _glow_mat(crystal_col, 0.6))
		cap.rotation = Vector3(0.6, _rng.randf_range(-0.4, 0.4), 0.6)
		add_child(cap)
		_crystals.append(crys)
	add_child(_billboard_label("RIGID — FROZEN, DEAD", Vector3(0.0, 3.0, -h + 0.9), 18, crystal_col))

	# NEAR BAND (+Z) — FLUID: a slumped pool of rippling studs. No form, dead.
	add_child(_box(Vector3(0.0, 0.0, h - 1.2), Vector3(room - 1.0, 0.06, 2.0), _glass_mat(fluid_col, 0.3)))
	_pool_mm = MultiMesh.new()
	_pool_mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 6
	sm.rings = 3
	_pool_mm.mesh = sm
	_pool_mm.instance_count = POOL_PTS
	var pmi := MultiMeshInstance3D.new()
	pmi.multimesh = _pool_mm
	pmi.material_override = _glow_mat(fluid_col, 0.6)
	add_child(pmi)
	for i in range(POOL_PTS):
		var px: float = _rng.randf_range(-(room - 1.2) * 0.5, (room - 1.2) * 0.5)
		var pz: float = h - 1.2 + _rng.randf_range(-0.9, 0.9)
		_pool_p.append(Vector3(px, 0.05, pz))
	_refresh_pool()
	add_child(_billboard_label("FLUID — FORMLESS, DEAD", Vector3(0.0, 1.0, h - 1.2), 18, fluid_col))

	# MIDDLE BAND (z ~ 0) — SOFT: the alive forms. Hold a shape AND breathe. You stand here.
	for i in range(n_blobs):
		var bx: float = lerpf(-room * 0.32, room * 0.32, float(i) / float(maxi(1, n_blobs - 1)))
		var base := Vector3(bx, 1.0, 0.0)
		var node := Node3D.new()
		node.position = base
		add_child(node)
		# Stacked soft spheres → a standing alive blob.
		for s in range(3):
			node.add_child(_sphere(Vector3(0.0, float(s) * 0.55, 0.0), 0.45 - float(s) * 0.06, _glow_mat(soft_col, 0.55)))
		_blobs.append({ "node": node, "phase": float(i) * 0.9, "base": base })

	# Lambda-edge strip on the floor marking where you stand.
	add_child(_box(Vector3(0.0, -0.04, 0.0), Vector3(room - 0.6, 0.02, 1.4), _glow_mat(soft_col, 0.35)))

	add_child(_billboard_label("THE LAMBDA_EDGE MADE FLESH", Vector3(0.0, 3.6, 0.0), 26, label_col))


func _refresh_pool() -> void:
	if _pool_mm == null:
		return
	var stud: float = 0.09
	for i in range(_pool_p.size()):
		var p: Vector3 = _pool_p[i]
		var ripple: float = 0.05 * sin(_t * 1.3 + p.x * 1.4 + p.z * 1.1)
		var pp := Vector3(p.x, 0.05 + ripple, p.z)
		_pool_mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(stud, stud * 0.4, stud)), pp))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Only the middle band lives. Crystals never move; the pool only ripples flat.
	for b in _blobs:
		var node: Node3D = b["node"]
		var ph: float = b["phase"]
		var breath: float = sin(_t * TAU * breath_rate + ph)
		var s: float = 1.0 + breath * 0.18
		node.scale = Vector3(s, 2.0 - s, s)
		node.position.y = b["base"].y + cos(_t * TAU * breath_rate + ph) * 0.08
	_refresh_pool()
