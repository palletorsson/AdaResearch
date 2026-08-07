extends Node3D
class_name CCTVMonitor

## CCTV Monitor — the oversight of watching, staged one piece at a time.
##
## @identity
## essence: a wall-tier security monitor whose feed is a private SubViewport copy of a
##   scene — the picture is always a model of the room, never the room. The scene itself
##   (frame, screen, viewport rig) is authored in cctv.tscn; this script stages WHICH
##   PIECE of the watching oversight stands with it.
## desire: to make the room ask who it is for. A monitor alone shows you the watching;
##   a camera body gives the gaze an address; a drawn sightline points it at you; a
##   tally shows what the watching keeps; a dome refuses to say where it looks.
## critical_parameter: oversight — which face of the surveillance instrument fronts the
##   installation. The feed never changes; the institution around it does.
## triggers: _ready() stages the chosen oversight; apply_grid_config restages on an
##   #oversight: token and ignores everything else (including the legacy scene-path
##   fragments the test_cctv tokens still carry).
## emerges: with four placements at four values, one room becomes a small history of
##   CCTV — shopfront deterrence, bracket camera, aimed beam, smoked dome.
## needs: cctv.tscn's authored monitor [present]; nothing external.
## relationships: kin to operational_eye (images that were never for you — Farocki's
##   operational images); adopts durer_scene's `oversight` word: both stage which piece
##   of a seeing-machine stands before you. The dome is Foucault's move — a gaze made
##   unverifiable is a gaze made permanent.
## truth: the monitor never watches the world — it films its own private model. What the
##   room learns from a camera is not what it sees, but who it is for.
##
## ── DNA ─────────────────────────────────────────────────────────────────────
## AXIS — WHICH PIECE OF THE WATCHING INSTRUMENT STANDS IN THE ROOM. The word is
## [[durer_scene]]'s `oversight` (same registry), adopted because the question is
## the same one Dürer's machines answer: which part of the seeing-instrument is
## staged between the eye and the subject. The VALUES are this artifact's own —
## a CCTV rig is not a drawing frame — following the kresling_spire/eggling
## precedent: shared word, shared question, body-specific vocabulary.
## Rejected words, each for a reason worth keeping: `channel` (operational_eye)
## picks WHICH of six feeds is up, and this monitor owns exactly one feed;
## `disclosure` (bias_visualizer) is a monotone ladder of how much mechanism is
## shown, and these are not quantities of one revelation but different faces of
## the same watching; `notice` (pickup_gate) is how a rule announces itself,
## which fits only the placard sense of surveillance and none of its bodies.
##
##   monitor    the shipped installation, byte for byte — frame and feed alone.
##              Watching shown as its output: the shopfront deterrence monitor.
##   housing    the gaze acquires a body — a bracket-mounted camera housing on a
##              mast above the monitor, hooded, lens down the same axis the
##              screen faces, a red REC point burning on the hood.
##   sightline  the gaze acquires an address — the housing yaws toward its spot
##              and a thin red beam runs from the lens to a floor reticle in
##              front of the screen: the watched place, marked where you stand.
##   tally      the gaze acquires a memory — a ledger fin bolted to the right
##              flank, rows of counted marks and a SEEN total: not what it
##              watches, what it has KEPT.
##   dome       the gaze refuses an address — a smoked half-sphere on a stem
##              above the monitor. No lens, no direction, no way to know where
##              it looks: the unverifiable watcher that never blinks.
@export_enum("monitor", "housing", "sightline", "tally", "dome") var oversight: String = "monitor"
const OVERSIGHTS: PackedStringArray = ["monitor", "housing", "sightline", "tally", "dome"]

# Everything the axis builds, tracked for teardown so an #oversight: token
# arriving after _ready() can restage without touching the authored monitor.
var _staged: Array[Node] = []

# Authored-scene facts (from cctv.tscn): the frame is a 1.296 m slab centred at
# (0, 1.2, 0.48); the screen sprite sits at z 0.434 facing -Z, so -Z is the
# room the monitor watches and +Z is its back.
const FRAME_TOP := 1.848
const FRAME_HALF_W := 0.648
const FRAME_Z := 0.48


func _ready() -> void:
	_stage_oversight()


## Grid entry point. `oversight` is normalised against OVERSIGHTS so a typo in a
## map token keeps the shipped monitor. Every other key is ignored on purpose —
## the four test_cctv placements still carry pre-config-grammar tokens
## (cctv#res://...tscn:rot:y:scale) whose fragment parses to a junk "res" key,
## and this artifact has never answered it.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("oversight"):
		var a: String = str(config_data["oversight"]).strip_edges().to_lower()
		if OVERSIGHTS.has(a) and a != oversight:
			oversight = a
			_stage_oversight()


func _stage_oversight() -> void:
	for n in _staged:
		if is_instance_valid(n):
			n.queue_free()
	_staged.clear()
	match oversight:
		"housing":
			_stage_housing(0.0)
		"sightline":
			_stage_sightline()
		"tally":
			_stage_tally()
		"dome":
			_stage_dome()
		_:
			pass  # "monitor" — the legacy lineage: the authored scene, untouched


# ── the values ───────────────────────────────────────────────────────────────

## HOUSING — the camera in its body, mast-mounted above the monitor, pitched
## down the axis the screen faces. yaw_to lets sightline aim the same body at
## its marked spot; plain housing watches dead ahead.
func _stage_housing(yaw_to: float) -> void:
	var steel: StandardMaterial3D = _flat(Color(0.22, 0.23, 0.26), 0.55, 0.6)
	var dark: StandardMaterial3D = _flat(Color(0.10, 0.11, 0.13), 0.8, 0.2)
	# mast: base plate on the frame top, post rising off it
	_stage(_box(Vector3(0.0, FRAME_TOP + 0.01, FRAME_Z), Vector3(0.14, 0.02, 0.14), steel))
	_stage(_cyl(Vector3(0.0, 1.935, FRAME_Z), 0.02, 0.135, steel))
	# the housing itself, grouped so it can pitch (and, for sightline, yaw)
	var head := Node3D.new()
	head.name = "CameraHousing"
	head.position = Vector3(0.0, 2.06, 0.44)
	head.rotation = Vector3(-0.30, yaw_to, 0.0)
	_stage(head)
	head.add_child(_box(Vector3.ZERO, Vector3(0.16, 0.15, 0.34), steel))
	# hood lip over the lens end (-Z is the nose)
	head.add_child(_box(Vector3(0.0, 0.083, -0.02), Vector3(0.17, 0.012, 0.36), dark))
	# lens ring + glass on the nose face
	var ring: MeshInstance3D = _cyl(Vector3(0.0, -0.01, -0.185), 0.045, 0.02, dark)
	ring.rotation.x = PI / 2.0
	head.add_child(ring)
	var glass: MeshInstance3D = _cyl(Vector3(0.0, -0.01, -0.198), 0.032, 0.006, _flat(Color(0.04, 0.05, 0.07), 0.1, 0.7))
	glass.rotation.x = PI / 2.0
	head.add_child(glass)
	# the REC point — the one light surveillance always allows itself
	head.add_child(_box(Vector3(0.06, 0.10, -0.10), Vector3(0.018, 0.018, 0.018), _emi(Color(0.95, 0.18, 0.14), 2.2)))


## SIGHTLINE — the housing plus its gaze, drawn. The body yaws toward the spot
## it holds, a thin beam runs lens-to-floor, and a reticle marks the watched
## place — front-right of the screen, where a door (or a viewer) would stand.
func _stage_sightline() -> void:
	_stage_housing(-0.515)
	var beam_c := Color(0.95, 0.30, 0.25)
	# lens position with the head pitched -0.30 and yawed -0.515 (see _stage_housing)
	_stage(_cyl_between(Vector3(0.09, 1.99, 0.28), Vector3(0.60, 0.012, -0.80), 0.006, _emi(beam_c, 1.3)))
	# the floor reticle: an open square frame plus a centre tick
	var rmat: StandardMaterial3D = _emi(beam_c, 1.0)
	var r := 0.22
	var cx := 0.60
	var cz := -0.80
	_stage(_box(Vector3(cx, 0.012, cz - r), Vector3(r * 2.0, 0.004, 0.03), rmat))
	_stage(_box(Vector3(cx, 0.012, cz + r), Vector3(r * 2.0, 0.004, 0.03), rmat))
	_stage(_box(Vector3(cx - r, 0.012, cz), Vector3(0.03, 0.004, r * 2.0), rmat))
	_stage(_box(Vector3(cx + r, 0.012, cz), Vector3(0.03, 0.004, r * 2.0), rmat))
	_stage(_box(Vector3(cx, 0.012, cz), Vector3(0.06, 0.004, 0.06), rmat))


## TALLY — what the watching keeps. A ledger fin bolted to the right flank:
## rows of counted marks, the last row still filling, and the running total.
func _stage_tally() -> void:
	var plate: StandardMaterial3D = _flat(Color(0.09, 0.10, 0.12), 0.85, 0.15)
	var steel: StandardMaterial3D = _flat(Color(0.22, 0.23, 0.26), 0.55, 0.6)
	var mark: StandardMaterial3D = _emi(Color(0.55, 0.90, 0.60), 1.0)
	# the fin, thin in X, faces +X; two bracket arms pin it to the frame edge
	_stage(_box(Vector3(0.85, 1.2, FRAME_Z), Vector3(0.03, 1.0, 0.30), plate))
	_stage(_box(Vector3(0.741, 1.55, FRAME_Z), Vector3(0.19, 0.03, 0.03), steel))
	_stage(_box(Vector3(0.741, 0.85, FRAME_Z), Vector3(0.19, 0.03, 0.03), steel))
	# counted marks on the +X face: 9 full rows of 4, one row of 2 — counting on
	var rows := 10
	var row_i := 0
	while row_i < rows:
		var cols: int = 4 if row_i < rows - 1 else 2
		var col_i := 0
		while col_i < cols:
			var mz: float = FRAME_Z - 0.105 + float(col_i) * 0.07
			var my: float = 1.56 - float(row_i) * 0.082
			_stage(_box(Vector3(0.868, my, mz), Vector3(0.008, 0.009, 0.034), mark))
			col_i += 1
		row_i += 1
	# the running total, printed at the head of the ledger
	var total := Label3D.new()
	total.text = "SEEN 0447"
	total.font_size = 40
	total.pixel_size = 0.0016
	total.outline_size = 6
	total.modulate = Color(0.55, 0.90, 0.60)
	total.double_sided = true
	total.position = Vector3(0.872, 1.64, FRAME_Z)
	total.rotation.y = -PI / 2.0
	_stage(total)


## DOME — the unverifiable gaze. A smoked half-sphere on a stem above the
## monitor: no lens, no direction, no way to know where it looks.
func _stage_dome() -> void:
	var steel: StandardMaterial3D = _flat(Color(0.22, 0.23, 0.26), 0.55, 0.6)
	_stage(_cyl(Vector3(0.0, 1.985, FRAME_Z), 0.018, 0.25, steel))
	_stage(_box(Vector3(0.0, 2.12, FRAME_Z), Vector3(0.26, 0.018, 0.26), steel))
	var smoked := StandardMaterial3D.new()
	smoked.albedo_color = Color(0.06, 0.06, 0.08, 0.88)
	smoked.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoked.roughness = 0.12
	smoked.metallic = 0.4
	var bulb := SphereMesh.new()
	bulb.radius = 0.15
	bulb.height = 0.15
	bulb.is_hemisphere = true
	var mi := MeshInstance3D.new()
	mi.name = "Dome"
	mi.mesh = bulb
	mi.material_override = smoked
	mi.position = Vector3(0.0, 2.11, FRAME_Z)
	mi.rotation.x = PI  # bulge downward, off the plate
	_stage(mi)


# ── helpers ──────────────────────────────────────────────────────────────────

func _stage(n: Node) -> Node:
	add_child(n)
	_staged.append(n)
	return n


func _flat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _emi(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _cyl(center: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _basis_y_to(dir: Vector3) -> Basis:
	var y: Vector3 = dir.normalized()
	if y.length() < 0.0001:
		return Basis()
	var ref: Vector3 = Vector3.UP if absf(y.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


func _cyl_between(a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = maxf(a.distance_to(b), 0.001)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(_basis_y_to(b - a), (a + b) * 0.5)
	return mi
