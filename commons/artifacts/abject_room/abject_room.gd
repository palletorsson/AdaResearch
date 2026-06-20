extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name AbjectRoom

## @identity
## name: "The abject as force"
## tier: large
## lineage: A room of the abject. Membranes hang from the ceiling and leak; soft forms on the floor
##   bulge and reach past their drawn edges; columns of flesh strain and weep. The boundaries are
##   everywhere troubled. You stand inside an affect that refuses to keep inside and outside apart.
## truth: "THE EDGE THAT TROUBLES THE LINE BETWEEN INSIDE AND OUT — EVERY BOUNDARY HERE IS LEAKING"
## applications: Kristeva's abject, affect-laden space, horror's wet architecture, the failing
##   Markov blanket — a built environment that makes the porous boundary felt.

const N_DRIPS: int = 90

@export var room: float = 7.0
@export var n_columns: int = 5
@export var membrane_col: Color = Color(0.70, 0.40, 0.58)
@export var floor_blob_col: Color = Color(0.78, 0.42, 0.60)
@export var drip_col: Color = Color(0.85, 0.45, 0.55)
@export var floor_col: Color = Color(0.11, 0.08, 0.10)
@export var label_col: Color = Color(0.95, 0.88, 0.90)
@export var pulse_rate: float = 0.28

var _t: float = 0.0
var _membranes: Array = []    # each: { node:MeshInstance3D, phase:float, base:Vector3 }
var _blobs: Array = []        # each: { node:MeshInstance3D, phase:float, base:Vector3 }
var _columns: Array = []      # each: { node:Node3D, phase:float }
var _drip_mm: MultiMesh = null
var _drips: Array = []        # each: { x:float, z:float, phase:float }


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("n_columns"):
		n_columns = int(clampf(float(config["n_columns"]), 3, 8))
	if config.has("membrane_col"):
		membrane_col = _parse_color(config["membrane_col"], membrane_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_membranes.clear()
	_blobs.clear()
	_columns.clear()
	_drip_mm = null
	_drips.clear()
	_build()


func _build() -> void:
	var h: float = room * 0.5
	# Floor.
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room, 0.1, room), _matte_mat(floor_col, 0.9)))

	# Hanging membranes — translucent sheets that sag and leak.
	for i in range(4):
		var mx: float = lerpf(-h * 0.6, h * 0.6, float(i) / 3.0)
		var base := Vector3(mx, 3.0, -h * 0.4 + float(i % 2) * h * 0.6)
		var node := _box(base, Vector3(1.4, 0.04, 1.4), _glass_mat(membrane_col, 0.35))
		add_child(node)
		_membranes.append({ "node": node, "phase": float(i) * 1.1, "base": base })

	# Floor blobs that bulge past their drawn boundary rings.
	for i in range(6):
		var ang: float = TAU * float(i) / 6.0
		var rad: float = room * 0.30
		var base2 := Vector3(cos(ang) * rad, 0.5, sin(ang) * rad)
		# Boundary ring on the floor the blob overflows.
		add_child(_torus(Vector3(base2.x, 0.02, base2.z), 0.55, 0.01, _glow_mat(Color(0.95, 0.80, 0.40), 0.5)))
		var blob := _sphere(base2, 0.42, _glow_mat(floor_blob_col, 0.5))
		add_child(blob)
		_blobs.append({ "node": blob, "phase": float(i) * 0.8, "base": base2 })

	# Columns of strained flesh that weep.
	for p in range(n_columns):
		var ca: float = TAU * float(p) / float(n_columns) + 0.4
		var crad: float = room * 0.40
		var cbase := Vector3(cos(ca) * crad, 0.0, sin(ca) * crad)
		var cnode := Node3D.new()
		cnode.position = cbase
		add_child(cnode)
		for s in range(4):
			cnode.add_child(_sphere(Vector3(0.0, 0.5 + float(s) * 0.6, 0.0), 0.3, _glow_mat(membrane_col, 0.45)))
		_columns.append({ "node": cnode, "phase": float(p) * 1.3 })

	# A rain of drips from the membranes — the room itself weeping.
	_drip_mm = MultiMesh.new()
	_drip_mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	sm.radial_segments = 6
	sm.rings = 3
	_drip_mm.mesh = sm
	_drip_mm.instance_count = N_DRIPS
	var dmi := MultiMeshInstance3D.new()
	dmi.multimesh = _drip_mm
	dmi.material_override = _glow_mat(drip_col, 0.8)
	add_child(dmi)
	for i in range(N_DRIPS):
		_drips.append({
			"x": _rng.randf_range(-h * 0.8, h * 0.8),
			"z": _rng.randf_range(-h * 0.8, h * 0.8),
			"phase": _rng.randf(),
		})
	_refresh_drips()

	add_child(_billboard_label("THE EDGE THAT TROUBLES THE LINE\nBETWEEN INSIDE AND OUT", Vector3(0.0, 3.6, 0.0), 24, label_col))


func _refresh_drips() -> void:
	if _drip_mm == null:
		return
	for i in range(_drips.size()):
		var d: Dictionary = _drips[i]
		var phase: float = fmod(_t * 0.35 + float(d["phase"]), 1.0)
		var y: float = 3.0 - phase * 3.0
		var stretch: float = 1.0 + phase * 1.5
		var t := Transform3D(Basis().scaled(Vector3(1.0, stretch, 1.0)), Vector3(float(d["x"]), maxf(y, 0.04), float(d["z"])))
		_drip_mm.set_instance_transform(i, t)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Membranes sag and ripple.
	for m in _membranes:
		var node: MeshInstance3D = m["node"]
		var ph: float = m["phase"]
		var sag: float = sin(_t * TAU * pulse_rate + ph) * 0.12
		node.position.y = m["base"].y + sag
		var s: float = 1.0 + sin(_t * 0.9 + ph) * 0.08
		node.scale = Vector3(s, 1.0, s)
	# Floor blobs strain and overflow their rings.
	for b in _blobs:
		var bnode: MeshInstance3D = b["node"]
		var bph: float = b["phase"]
		var sx: float = 1.0 + sin(_t * 0.9 + bph) * 0.16
		var sy: float = 1.0 + cos(_t * 0.7 + bph) * 0.12
		bnode.scale = Vector3(sx, sy, sx)
		bnode.position.y = b["base"].y + sin(_t * 0.6 + bph) * 0.05
	# Columns strain.
	for col in _columns:
		var cnode: Node3D = col["node"]
		var cph: float = col["phase"]
		var cs: float = 1.0 + sin(_t * TAU * pulse_rate * 1.2 + cph) * 0.14
		cnode.scale = Vector3(cs, 2.0 - cs, cs)
	_refresh_drips()
