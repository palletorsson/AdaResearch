extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name AbjectToy

## @identity
## name: "The abject as force"
## tier: small
## lineage: A held abject blob — a soft membrane that troubles its own boundary. It bulges, it
##   strains, and it weeps a single droplet that falls and is reabsorbed. It never quite stays
##   inside its own line. The thing cast off that will not stay outside (Kristeva).
## truth: "THE BODY THAT WON'T STAY INSIDE ITS LINE — IT BULGES, IT WEEPS, IT CROSSES ITS OWN EDGE"
## applications: Kristeva's abject, the leaky cell, the wound, the Markov blanket that fails — every
##   boundary that is felt because it is breaking.

const RIM_PTS: int = 28

@export var blob_r: float = 0.11
@export var blob_col: Color = Color(0.72, 0.40, 0.62)
@export var rim_col: Color = Color(0.92, 0.55, 0.70)
@export var drip_col: Color = Color(0.88, 0.42, 0.55)
@export var label_col: Color = Color(0.95, 0.88, 0.90)

var _t: float = 0.0
var _blob: MeshInstance3D = null
var _rim_mm: MultiMesh = null
var _rim_dirs: Array = []
var _drip: MeshInstance3D = null
var _mid_y: float = 0.18
var _drip_phase: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("blob_r"):
		blob_r = clampf(float(config["blob_r"]), 0.07, 0.18)
	if config.has("blob_col"):
		blob_col = _parse_color(config["blob_col"], blob_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_blob = null
	_rim_mm = null
	_rim_dirs.clear()
	_drip = null
	_build()


func _build() -> void:
	# Held dish to catch what weeps — no table.
	add_child(_cylinder(Vector3(0.0, 0.02, 0.0), blob_r * 1.4, 0.025, _matte_mat(Color(0.16, 0.16, 0.2), 0.7)))

	# The abject body itself.
	_blob = _sphere(Vector3(0.0, _mid_y, 0.0), blob_r, _glow_mat(blob_col, 0.55))
	add_child(_blob)

	# A troubled rim — studs marking where the boundary should be, but they wander.
	_rim_mm = MultiMesh.new()
	_rim_mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 6
	sm.rings = 3
	_rim_mm.mesh = sm
	_rim_mm.instance_count = RIM_PTS
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = _rim_mm
	mi.material_override = _glow_mat(rim_col, 0.75)
	add_child(mi)
	var golden: float = PI * (3.0 - sqrt(5.0))
	for i in range(RIM_PTS):
		var y: float = 1.0 - 2.0 * (float(i) + 0.5) / float(RIM_PTS)
		var rad: float = sqrt(maxf(0.0, 1.0 - y * y))
		var th: float = golden * float(i)
		_rim_dirs.append(Vector3(cos(th) * rad, y, sin(th) * rad))
	_refresh_rim()

	# The weeping droplet — falls from the bottom, reabsorbs.
	_drip = _sphere(Vector3(0.0, _mid_y - blob_r, 0.0), blob_r * 0.28, _glow_mat(drip_col, 0.9))
	add_child(_drip)

	add_child(_billboard_label("THE BODY THAT WON'T STAY\nINSIDE ITS LINE", Vector3(0.0, _mid_y + blob_r + 0.16, 0.0), 13, label_col))


func _refresh_rim() -> void:
	if _rim_mm == null:
		return
	var stud: float = blob_r * 0.13
	for i in range(_rim_dirs.size()):
		var d: Vector3 = _rim_dirs[i]
		# Each rim stud bulges outward by a wandering amount — the boundary won't sit still.
		var bulge: float = 1.0 + 0.18 * sin(_t * 1.6 + float(i) * 0.9) + 0.12 * sin(_t * 0.7 + float(i) * 2.1)
		var p := Vector3(0.0, _mid_y, 0.0) + d * blob_r * bulge
		_rim_mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(stud, stud, stud)), p))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# The blob strains and bulges asymmetrically — never a clean sphere.
	if _blob != null:
		var sx: float = 1.0 + sin(_t * 1.3) * 0.14
		var sy: float = 1.0 + cos(_t * 0.9) * 0.18
		var sz: float = 1.0 + sin(_t * 1.1 + 1.7) * 0.12
		_blob.scale = Vector3(sx, sy, sz)
	_refresh_rim()
	# A droplet swells at the base, detaches, falls, and is drawn back — abjection's loop.
	if _drip != null:
		_drip_phase = fmod(_t * 0.5, 1.0)
		if _drip_phase < 0.6:
			# Swelling and falling.
			var fall: float = _drip_phase / 0.6
			_drip.position.y = _mid_y - blob_r - fall * (blob_r + 0.06)
			_drip.scale = Vector3.ONE * (0.6 + fall * 0.8)
		else:
			# Snap back / reabsorb.
			_drip.position.y = _mid_y - blob_r
			_drip.scale = Vector3.ONE * 0.3
		_drip.position.x = sin(_t * 2.3) * 0.01
