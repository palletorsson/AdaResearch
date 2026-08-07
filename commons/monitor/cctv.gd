extends Node3D
class_name CCTVMonitor

## CCTV Monitor — the oversight of watching, staged one piece at a time.
##
## @identity
## essence: a wall-tier security monitor whose feed is a private SubViewport copy of a
##   scene — the picture is always a model of the room, never the room. The screen rig
##   (Sprite3D, SubViewport, camera) is authored in cctv.tscn; this script finishes that
##   chassis as a mass-produced object — moulded shell, bezel, faceplate glass, vents —
##   and then stages WHICH PIECE of the watching oversight stands with it.
## desire: to make the room ask who it is for. A monitor alone shows you the watching;
##   a camera body gives the gaze an address; a drawn sightline points it at you; a
##   tally shows what the watching keeps; a dome refuses to say where it looks.
## critical_parameter: oversight — which face of the surveillance instrument fronts the
##   installation. The feed never changes; the institution around it does.
## triggers: _ready() finishes the chassis once, then stages the chosen oversight;
##   apply_grid_config restages on an #oversight: token and ignores everything else
##   (including the legacy scene-path fragments the test_cctv tokens still carry).
## emerges: with four placements at four values, one room becomes a small history of
##   CCTV — shopfront deterrence, bracket camera, aimed beam, smoked dome.
## needs: cctv.tscn's authored screen rig [present]; commons/render/pbr_kit.gd and
##   commons/render/mesh_kit.gd for surfaces and bevels [present]; nothing external.
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
##   monitor    the installation alone — chassis, bezel, faceplate and feed, with
##              no watcher staged above it. Watching shown as its output: the
##              shopfront deterrence monitor.
##   housing    the gaze acquires a body — a bracket-mounted camera housing on a
##              mast above the monitor, hooded, lens down the same axis the
##              screen faces, a red REC point burning on the hood.
##   sightline  the gaze acquires an address — the housing aims at its spot and a
##              thin red beam runs from the lens to a floor reticle in front of
##              the screen: the watched place, marked where you stand.
##   tally      the gaze acquires a memory — a ledger fin bolted to the right
##              flank, rows of counted marks and a SEEN total: not what it
##              watches, what it has KEPT.
##   dome       the gaze refuses an address — a smoked half-sphere on a stem
##              above the monitor. No lens, no direction, no way to know where
##              it looks: the unverifiable watcher that never blinks.
##
## THE CHASSIS IS NOT PART OF THE AXIS. Every value stands on the same authored
## monitor, so its surfaces are finished ONCE in _finish_chassis() and never torn
## down. Only _stage_oversight() builds and frees; the five values differ by
## exactly what they always differed by.
@export_enum("monitor", "housing", "sightline", "tally", "dome") var oversight: String = "monitor"
const OVERSIGHTS: PackedStringArray = ["monitor", "housing", "sightline", "tally", "dome"]

const PK = preload("res://commons/render/pbr_kit.gd")
const MK = preload("res://commons/render/mesh_kit.gd")

# Everything the axis builds, tracked for teardown so an #oversight: token
# arriving after _ready() can restage without touching the authored monitor.
var _staged: Array[Node] = []
# The chassis finish is idempotent — apply_grid_config can land before _ready().
var _chassis_done: bool = false

# Authored-scene facts (from cctv.tscn): the shell is a 1.296 m slab, 72 mm deep,
# centred at (0, 1.2, 0.48); the screen sprite sits at z 0.4337 facing -Z, so -Z
# is the room the monitor watches and +Z is its back.
const FRAME_TOP := 1.848
const FRAME_HALF_W := 0.648
const FRAME_Z := 0.48
const FRAME_MID_Y := 1.2
const FRAME_FRONT := 0.444    # the -Z face: the side that faces the room
const FRAME_BACK := 0.516
const SCREEN_Z := 0.4337      # the Sprite3D plane — do not move it, the feed hangs there

# The moulding that turns a slab into a monitor: an 73 mm frame standing 16 mm
# proud of the shell face, its aperture cropping the outer band of the picture.
const BEZEL_W := 0.073
const BEZEL_LIP := 0.428

# Where the camera head hangs, and where its lens sits inside it.
const HEAD_POS := Vector3(0.0, 2.06, 0.44)
const LENS_LOCAL := Vector3(0.0, -0.010, -0.2105)
# The watched place: front-right of the screen, where a door (or a viewer) stands.
const MARK_POS := Vector3(0.60, 0.0022, -0.80)


func _ready() -> void:
	_finish_chassis()
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
			_finish_chassis()
			_stage_oversight()


func _stage_oversight() -> void:
	for n in _staged:
		if is_instance_valid(n):
			n.queue_free()
	_staged.clear()
	match oversight:
		"housing":
			# dead ahead and 17 degrees down — the shipped pose
			_stage_housing(Vector3(0.0, sin(-0.30), -cos(-0.30)))
		"sightline":
			_stage_sightline()
		"tally":
			_stage_tally()
		"dome":
			_stage_dome()
		_:
			pass  # "monitor" — the legacy lineage: the authored scene, nothing staged


# ── the chassis every value stands on ────────────────────────────────────────

## Finish the authored monitor as a manufactured object. Outer extents are
## untouched — the shell keeps its 1.296 x 1.296 x 0.072 volume and the Sprite3D
## keeps its transform and its ViewportTexture. What changes is the surface: a
## chamfered shell in moulded ABS, a separate bezel moulding standing proud of
## it, a recessed faceplate, a power lamp, vent ribs and a mount plate.
func _finish_chassis() -> void:
	if _chassis_done:
		return
	_chassis_done = true

	var shell: StandardMaterial3D = _mat_case()
	var frame: MeshInstance3D = get_node_or_null("MonitorFrame") as MeshInstance3D
	if frame != null:
		# Same local extents as the authored BoxMesh (the node carries the 1.2
		# scale), now with a 7 mm chamfer so every edge catches a highlight line.
		frame.mesh = MK.bevel_box(Vector3(1.08, 1.08, 0.06), 0.007, 1, true, 1.0)
		frame.material_override = shell

	var bez: StandardMaterial3D = _mat_bezel()
	var ap: float = FRAME_HALF_W - BEZEL_W          # aperture half-width, 0.575
	var mid: float = (FRAME_HALF_W + ap) * 0.5      # centre of the moulding run
	var bz: float = (FRAME_FRONT + BEZEL_LIP) * 0.5
	var bd: float = FRAME_FRONT - BEZEL_LIP
	add_child(PK.box(Vector3(0.0, FRAME_MID_Y + mid, bz),
		Vector3(FRAME_HALF_W * 2.0, BEZEL_W, bd), bez, 0.0026, 0.14))
	add_child(PK.box(Vector3(0.0, FRAME_MID_Y - mid, bz),
		Vector3(FRAME_HALF_W * 2.0, BEZEL_W, bd), bez, 0.0026, 0.14))
	add_child(PK.box(Vector3(-mid, FRAME_MID_Y, bz),
		Vector3(BEZEL_W, ap * 2.0, bd), bez, 0.0026, 0.14))
	add_child(PK.box(Vector3(mid, FRAME_MID_Y, bz),
		Vector3(BEZEL_W, ap * 2.0, bd), bez, 0.0026, 0.14))

	# The faceplate. ONE transparent layer, recessed 1.5 mm behind the bezel lip
	# and 1.2 mm in front of the sprite plane, so the feed is seen THROUGH glass
	# instead of being a lit rectangle. render_priority puts it after the
	# Sprite3D, which is transparent too and would otherwise sort by accident.
	var pane: StandardMaterial3D = PK.glass(Color(0.70, 0.77, 0.82), 0.045, 0.11)
	pane.render_priority = 1
	var face: MeshInstance3D = _mesh_node(
		MK.rounded_panel(Vector3(1.154, 1.154, 0.003), 0.012, 2, 0.0014, 1, 1.0),
		pane, "Faceplate")
	face.position = Vector3(0.0, FRAME_MID_Y, SCREEN_Z - 0.0027)
	add_child(face)

	# Power lamp, seated in a machined ring on the bottom moulding. The only
	# light the chassis allows itself.
	var trim: StandardMaterial3D = _mat_trim(40.0)
	var lamp_y: float = FRAME_MID_Y - mid
	var ring: MeshInstance3D = _mesh_node(MK.tube(0.0115, 0.0062, 0.006, 20, 0.0012),
		trim, "LampRing")
	ring.rotation.x = PI / 2.0
	ring.position = Vector3(0.545, lamp_y, 0.4288)
	add_child(ring)
	# 0.0058, not the ring's 0.0062 inner radius — two cylinders of exactly equal
	# radius give you a z-fighting seam, not a lamp in a ring.
	var lamp: MeshInstance3D = _cyl(Vector3(0.545, lamp_y, 0.4292), 0.0058, 0.006,
		PK.led(Color(0.34, 0.94, 0.44), 2.8), 16)
	lamp.rotation.x = PI / 2.0
	add_child(lamp)

	# Vent ribs moulded into the top shell, two banks clear of the mast footprint.
	# One MultiMesh, one draw call — twelve separate boxes would be twelve.
	var vent_mat: StandardMaterial3D = PK.hard_plastic(Color(0.082, 0.087, 0.098), 0.20, 0.26)
	PK.scale_detail(vent_mat, 9.0)
	var vent_mm := MultiMesh.new()
	vent_mm.transform_format = MultiMesh.TRANSFORM_3D
	vent_mm.mesh = MK.bevel_box(Vector3(0.30, 0.006, 0.007), 0.0015)
	vent_mm.instance_count = 12
	var vi: int = 0
	for bank in range(2):
		var bx: float = -0.28
		if bank == 1:
			bx = 0.28
		for i in range(6):
			var rz: float = FRAME_Z - 0.022 + float(i) * 0.011
			vent_mm.set_instance_transform(vi,
				Transform3D(Basis(), Vector3(bx, FRAME_TOP + 0.003, rz)))
			vi += 1
	var vents := MultiMeshInstance3D.new()
	vents.name = "TopVents"
	vents.multimesh = vent_mm
	vents.material_override = vent_mat
	add_child(vents)

	# Mount plate on the back. The monitor hangs off something out of frame; the
	# plate and its four bolts are what it hangs by.
	var alu: StandardMaterial3D = _mat_alu()
	add_child(PK.box(Vector3(0.0, FRAME_MID_Y, FRAME_BACK + 0.007),
		Vector3(0.17, 0.17, 0.014), alu, 0.003, 0.24))
	add_child(_bolts([
		Vector3(0.058, FRAME_MID_Y + 0.058, FRAME_BACK + 0.0125),
		Vector3(-0.058, FRAME_MID_Y + 0.058, FRAME_BACK + 0.0125),
		Vector3(0.058, FRAME_MID_Y - 0.058, FRAME_BACK + 0.0125),
		Vector3(-0.058, FRAME_MID_Y - 0.058, FRAME_BACK + 0.0125),
	], 0.0085, 0.007, Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN), trim, "MountBolts"))


# ── the values ───────────────────────────────────────────────────────────────

## HOUSING — the camera in its body, mast-mounted above the monitor. `aim` is the
## world direction the lens looks along; the head's -Z is turned onto it, so
## sightline can hand it a target instead of a hand-tuned pair of angles.
func _stage_housing(aim: Vector3) -> void:
	var alu: StandardMaterial3D = _mat_alu()
	var steel: StandardMaterial3D = _mat_steel()
	var powder: StandardMaterial3D = _mat_powder()
	var trim: StandardMaterial3D = _mat_trim(16.0)
	var bolt: StandardMaterial3D = _mat_trim(45.0)

	# Mounting flange on the shell top, bolted down, then the mast. The flange is
	# 68 mm deep, not 140 — a plate wider than the shell it is bolted to has two
	# overhanging ends supported by nothing, which is the grounding tell.
	_stage(PK.box(Vector3(0.0, FRAME_TOP + 0.009, FRAME_Z), Vector3(0.14, 0.018, 0.068),
		alu, 0.0035, 0.25))
	_stage(_bolts([
		Vector3(0.05, FRAME_TOP + 0.0165, FRAME_Z + 0.024),
		Vector3(-0.05, FRAME_TOP + 0.0165, FRAME_Z + 0.024),
		Vector3(0.05, FRAME_TOP + 0.0165, FRAME_Z - 0.024),
		Vector3(-0.05, FRAME_TOP + 0.0165, FRAME_Z - 0.024),
	], 0.0085, 0.007, Basis(), bolt, "FlangeBolts"))
	# Post runs from inside the flange up into the head — no gap at either end.
	_stage(_cyl(Vector3(0.0, 1.957, FRAME_Z), 0.02, 0.186, steel, 20))

	# The housing itself, grouped so the whole assembly turns as one body.
	var head := Node3D.new()
	head.name = "CameraHousing"
	head.transform = Transform3D(_aim_basis(aim), HEAD_POS)
	_stage(head)

	# Extruded case: a rounded rectangular section run along the lens axis, which
	# is what a die makes and a box does not.
	var body: MeshInstance3D = _mesh_node(
		MK.rounded_panel(Vector3(0.16, 0.15, 0.34), 0.018, 3, 0.004, 1, 1.0),
		powder, "Case")
	head.add_child(body)

	# Sunshield over the lens end, overhanging the nose, with a drip lip.
	var hood: MeshInstance3D = _mesh_node(
		MK.rounded_panel(Vector3(0.176, 0.37, 0.014), 0.008, 2, 0.003, 1, 1.0),
		_mat_hood(), "Sunshield")
	hood.rotation.x = -PI / 2.0
	hood.position = Vector3(0.0, 0.083, -0.02)
	head.add_child(hood)
	var lip: MeshInstance3D = PK.box(Vector3(0.0, 0.070, -0.202),
		Vector3(0.176, 0.030, 0.010), _mat_hood(), 0.002, 0.2)
	lip.rotation.x = -0.35
	head.add_child(lip)

	# Tilt knuckle where the mast meets the case — the joint that explains the pose.
	var knuckle: MeshInstance3D = _cyl(Vector3(0.0, -0.052, 0.045), 0.026, 0.17, trim, 16)
	knuckle.rotation.z = PI / 2.0
	head.add_child(knuckle)

	# Lens stack on the nose: machined barrel, retaining ring, dark optic, glass cap.
	var barrel: MeshInstance3D = _cyl(Vector3(0.0, -0.010, -0.185), 0.046, 0.052, alu, 24)
	barrel.rotation.x = PI / 2.0
	head.add_child(barrel)
	var retain: MeshInstance3D = _mesh_node(MK.tube(0.048, 0.034, 0.008, 24, 0.002),
		trim, "RetainingRing")
	retain.rotation.x = PI / 2.0
	retain.position = Vector3(0.0, -0.010, -0.2085)
	head.add_child(retain)
	var optic: MeshInstance3D = _cyl(Vector3(0.0, -0.010, -0.2075), 0.033, 0.005,
		_mat_lens(), 24)
	optic.rotation.x = PI / 2.0
	head.add_child(optic)
	# The glass sits its rim INSIDE the optic disc, so the open edge of the cap is
	# never on screen and no two surfaces are coplanar.
	var cap: MeshInstance3D = _mesh_node(_dome_mesh(0.0315, 0.009, 24, 6),
		PK.glass(Color(0.62, 0.70, 0.78), 0.03, 0.14), "LensGlass")
	cap.rotation.x = -PI / 2.0
	cap.position = Vector3(0.0, -0.010, -0.2085)
	head.add_child(cap)

	# The REC point — the one light surveillance always allows itself — seated in
	# its own ring on the sunshield rather than floating above it.
	var rec_ring: MeshInstance3D = _mesh_node(MK.tube(0.0115, 0.008, 0.008, 16, 0.0012),
		trim, "RecRing")
	rec_ring.position = Vector3(0.06, 0.094, -0.10)
	head.add_child(rec_ring)
	head.add_child(_cyl(Vector3(0.06, 0.0955, -0.10), 0.0076, 0.007,
		PK.led(Color(0.96, 0.20, 0.15), 3.0), 16))


## SIGHTLINE — the housing plus its gaze, drawn. The body is AIMED at the spot it
## holds (the shipped pose only leaned toward it), the beam leaves the actual lens
## along the actual lens axis, and the reticle lies on the floor rather than a
## centimetre above it.
func _stage_sightline() -> void:
	_stage_housing(MARK_POS - HEAD_POS)
	var beam_c := Color(0.95, 0.30, 0.25)
	var lens_world: Vector3 = HEAD_POS + _aim_basis(MARK_POS - HEAD_POS) * LENS_LOCAL
	var beam_mat: StandardMaterial3D = PK.emissive(beam_c, 2.4)
	PK.edge_light(beam_mat, 0.6, 0.15)
	_stage(PK.pipe(lens_world, MARK_POS, 0.005, beam_mat, 12))

	# The floor reticle: an open square frame plus a centre tick, bedded on y = 0.
	var rmat: StandardMaterial3D = PK.emissive(beam_c, 1.5)
	var r := 0.22
	var cx: float = MARK_POS.x
	var cz: float = MARK_POS.z
	var ry: float = MARK_POS.y
	var rt := 0.0044
	_stage(PK.box(Vector3(cx, ry, cz - r), Vector3(r * 2.0, rt, 0.030), rmat, 0.0012))
	_stage(PK.box(Vector3(cx, ry, cz + r), Vector3(r * 2.0, rt, 0.030), rmat, 0.0012))
	_stage(PK.box(Vector3(cx - r, ry, cz), Vector3(0.030, rt, r * 2.0), rmat, 0.0012))
	_stage(PK.box(Vector3(cx + r, ry, cz), Vector3(0.030, rt, r * 2.0), rmat, 0.0012))
	_stage(PK.box(Vector3(cx, ry, cz), Vector3(0.060, rt, 0.060), rmat, 0.0012))


## TALLY — what the watching keeps. A ledger fin bolted to the right flank:
## rows of counted marks, the last row still filling, and the running total.
func _stage_tally() -> void:
	var fin: StandardMaterial3D = _mat_fin()
	var steel: StandardMaterial3D = _mat_steel()
	var bolt: StandardMaterial3D = _mat_trim(45.0)

	# The fin, thin in X, faces +X; two bracket arms pin it to the shell edge.
	_stage(PK.box(Vector3(0.85, FRAME_MID_Y, FRAME_Z), Vector3(0.03, 1.0, 0.30),
		fin, 0.0032, 0.22))
	_stage(PK.box(Vector3(0.741, 1.55, FRAME_Z), Vector3(0.19, 0.03, 0.03),
		steel, 0.0025, 0.3))
	_stage(PK.box(Vector3(0.741, 0.85, FRAME_Z), Vector3(0.19, 0.03, 0.03),
		steel, 0.0025, 0.3))
	# Four bolt heads at the fin's corners, clear of the mark field and the plate.
	# The basis turns the head's axis onto +X and stays RIGHT-handed — a mirrored
	# basis on a MultiMesh flips every instance's winding and shows its inside.
	_stage(_bolts([
		Vector3(0.867, 1.688, FRAME_Z - 0.135), Vector3(0.867, 1.688, FRAME_Z + 0.135),
		Vector3(0.867, 0.715, FRAME_Z - 0.135), Vector3(0.867, 0.715, FRAME_Z + 0.135),
	], 0.0095, 0.008, Basis(Vector3.BACK, Vector3.RIGHT, Vector3.UP), bolt, "FinBolts"))

	# Counted marks on the +X face: 9 full rows of 4, one row of 2 — counting on.
	# One MultiMesh: 38 marks used to be 38 draw calls.
	var rows := 10
	var offsets: Array[Vector3] = []
	var row_i := 0
	while row_i < rows:
		var cols: int = 4
		if row_i == rows - 1:
			cols = 2
		var col_i := 0
		while col_i < cols:
			var mz: float = FRAME_Z - 0.105 + float(col_i) * 0.07
			var my: float = 1.56 - float(row_i) * 0.082
			offsets.append(Vector3(0.868, my, mz))
			col_i += 1
		row_i += 1
	var mark_mm := MultiMesh.new()
	mark_mm.transform_format = MultiMesh.TRANSFORM_3D
	mark_mm.mesh = MK.bevel_box(Vector3(0.008, 0.009, 0.034), 0.0012)
	mark_mm.instance_count = offsets.size()
	for i in range(offsets.size()):
		var p: Vector3 = offsets[i]
		mark_mm.set_instance_transform(i, Transform3D(Basis(), p))
	var marks := MultiMeshInstance3D.new()
	marks.name = "TallyMarks"
	marks.multimesh = mark_mm
	marks.material_override = PK.emissive(Color(0.52, 0.92, 0.58), 1.5)
	_stage(marks)

	# The running total, printed on its own screen-printed plate at the head of the
	# ledger. pixel_size 0.0013, not 0.0016: at the old size "SEEN 0447" measured
	# about 0.32 m and the fin it is printed on is only 0.30 m deep.
	_stage(PK.box(Vector3(0.8668, 1.641, FRAME_Z), Vector3(0.006, 0.070, 0.262),
		_mat_plate(), 0.0018, 0.18))
	var total := Label3D.new()
	total.text = "SEEN 0447"
	total.font_size = 40
	total.pixel_size = 0.0013
	total.outline_size = 6
	total.outline_modulate = Color(0.03, 0.06, 0.04, 0.85)
	total.modulate = Color(0.55, 0.90, 0.60)
	total.double_sided = true
	total.position = Vector3(0.872, 1.641, FRAME_Z)
	total.rotation.y = -PI / 2.0
	_stage(total)


## DOME — the unverifiable gaze. A smoked half-sphere on a stem above the
## monitor: no lens, no direction, no way to know where it looks. What is inside
## is a baffle turned on the same axis as the bubble, so it carries no direction
## BY CONSTRUCTION — you can see there is something in there, and that is all.
func _stage_dome() -> void:
	var steel: StandardMaterial3D = _mat_steel()
	var alu: StandardMaterial3D = _mat_alu()
	var trim: StandardMaterial3D = _mat_trim(7.0)

	# Foot flange on the shell top — the stem used to start 12 mm above it.
	_stage(PK.box(Vector3(0.0, FRAME_TOP + 0.007, FRAME_Z), Vector3(0.11, 0.014, 0.068),
		alu, 0.003, 0.25))
	_stage(_cyl(Vector3(0.0, 1.979, FRAME_Z), 0.018, 0.262, steel, 20))
	_stage(PK.box(Vector3(0.0, 2.115, FRAME_Z), Vector3(0.26, 0.016, 0.26),
		_mat_powder(), 0.003, 0.2))

	# Mounting collar over the rim seam — and the reason the open rim of the
	# bubble is never on screen.
	var collar: MeshInstance3D = _mesh_node(MK.tube(0.155, 0.136, 0.016, 32, 0.002),
		trim, "DomeCollar")
	collar.position = Vector3(0.0, 2.103, FRAME_Z)
	_stage(collar)

	# The baffle: an axis-symmetric mass, unresolvable through the smoke. Turned on
	# the same axis as the bubble, so it carries no direction BY CONSTRUCTION.
	var dark: StandardMaterial3D = PK.rubber(Color(0.045, 0.046, 0.052), 0.15)
	var baffle: MeshInstance3D = _mesh_node(_dome_mesh(0.095, 0.050, 24, 5), dark, "Baffle")
	baffle.rotation.x = PI
	baffle.position = Vector3(0.0, 2.100, FRAME_Z)
	_stage(baffle)
	# ...and its lid, so the open rim of the cap is never seen through the smoke.
	_stage(_cyl(Vector3(0.0, 2.0985, FRAME_Z), 0.096, 0.005, dark, 24))

	# Smoked polycarbonate. Same 0.30 m bubble, lathed rather than a sphere
	# primitive, so its rim takes a chamfer and its Fresnel edge reads.
	var smoked: StandardMaterial3D = PK.glass(Color(0.10, 0.105, 0.130), 0.06, 0.78)
	PK.edge_light(smoked, 0.85, 0.05)
	var bulb: MeshInstance3D = _mesh_node(_dome_mesh(0.15, 0.075, 32, 8), smoked, "Dome")
	bulb.rotation.x = PI  # bulge downward, off the plate
	bulb.position = Vector3(0.0, 2.107, FRAME_Z)
	_stage(bulb)


# ── surfaces ─────────────────────────────────────────────────────────────────
# One vocabulary, five values. Every material carries a roughness texture, so no
# surface here is a single uniform highlight; metals are metallic 1.0 with a
# measured albedo, everything painted or moulded is metallic 0 with a clear coat.

## The moulded ABS shell — the largest surface in every frame this artifact is in.
func _mat_case() -> StandardMaterial3D:
	var m: StandardMaterial3D = PK.hard_plastic(Color(0.148, 0.152, 0.172), 0.32, 0.16)
	PK.crevice_ao(m, 0.45)
	PK.weather(m, 0.20)
	return PK.scale_detail(m, 2.6)


## The bezel is a second moulding, a shade darker and flatter than the shell —
## two plastics that were not made in the same die.
func _mat_bezel() -> StandardMaterial3D:
	var m: StandardMaterial3D = PK.hard_plastic(Color(0.104, 0.108, 0.124), 0.22, 0.20)
	PK.crevice_ao(m, 0.55)
	return PK.scale_detail(m, 5.0)


## Brushed steel, grain running along the part — masts, stems, bracket arms.
func _mat_steel() -> StandardMaterial3D:
	var m: StandardMaterial3D = PK.brushed_metal(Color(0.470, 0.478, 0.492), 0.30, 0.18, "y")
	return PK.scale_detail(m, 5.5)


## Machined aluminium — flanges and lens barrels, off a lathe rather than a line.
func _mat_alu() -> StandardMaterial3D:
	var m: StandardMaterial3D = PK.machined_metal(Color(0.560, 0.568, 0.575), 0.24, 0.14)
	return PK.scale_detail(m, 6.0)


## Powder-coated case metal — the camera housing and the dome plate.
func _mat_powder() -> StandardMaterial3D:
	var m: StandardMaterial3D = PK.painted_metal(Color(0.236, 0.246, 0.276), 0.22, 0.30, 0.46)
	PK.crevice_ao(m, 0.40)
	return PK.scale_detail(m, 5.0)


## The sunshield took the weather the case did not.
func _mat_hood() -> StandardMaterial3D:
	var m: StandardMaterial3D = PK.painted_metal(Color(0.252, 0.260, 0.288), 0.38, 0.35, 0.52)
	return PK.scale_detail(m, 5.0)


## Anodised instrument plate — the ledger fin.
func _mat_fin() -> StandardMaterial3D:
	var m: StandardMaterial3D = PK.anodized(Color(0.152, 0.162, 0.188), 0.34, 0.18)
	PK.crevice_ao(m, 0.5)
	return PK.scale_detail(m, 1.6)


## A dark screen-printed plate, for the panel the total is printed on.
func _mat_plate() -> StandardMaterial3D:
	var m: StandardMaterial3D = PK.hard_plastic(Color(0.062, 0.070, 0.066), 0.30, 0.10)
	return PK.scale_detail(m, 8.0)


## Dark worn metal — lens rings, collars, bolt heads, the tilt knuckle.
##
## `detail` is the small-part correction, and it is not optional: these materials
## are triplanar at a few tiles per LOCAL metre, so on a 19 mm bolt head the noise
## never repeats once and the whole point of it — breaking the highlight up —
## is lost. Rule of thumb, PbrKit's: factor ~= 1 / longest dimension in metres.
func _mat_trim(detail: float = 20.0) -> StandardMaterial3D:
	var m: StandardMaterial3D = PK.worn_metal(Color(0.150, 0.155, 0.170), 0.45)
	return PK.scale_detail(m, detail)


## The optic. Near-black but never 0,0,0 — a dielectric with a hard gloss, so it
## answers the light with a specular point instead of a hole.
func _mat_lens() -> StandardMaterial3D:
	var m: StandardMaterial3D = PK.hard_plastic(Color(0.032, 0.040, 0.055), 0.96, 0.0)
	m.metallic_specular = 0.85
	PK.edge_light(m, 0.5, 0.2)
	return PK.scale_detail(m, 14.0)


# ── helpers ──────────────────────────────────────────────────────────────────

func _stage(n: Node) -> Node:
	add_child(n)
	_staged.append(n)
	return n


func _mesh_node(mesh: ArrayMesh, mat: Material, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = mat
	return mi


## Chamfered cylinder, positioned — the drop-in for the old CylinderMesh helper.
## PbrKit's lathe returns the node unpositioned, so the position is set here.
func _cyl(center: Vector3, radius: float, height: float, mat: Material,
		segments: int = 20) -> MeshInstance3D:
	var mi: MeshInstance3D = PK.chamfer_cylinder(radius, height, -1.0, mat, segments, 0.0)
	mi.position = center
	return mi


## A cluster of identical bolt heads as ONE MultiMesh. `orient` turns the head's
## +Y (its axis) onto whatever face it is screwed into.
func _bolts(offsets: Array, head_r: float, head_h: float, orient: Basis,
		mat: Material, nm: String) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = MK.cylinder(head_r, head_h, 12, head_r * 0.30, 1, true, 1.0)
	mm.instance_count = offsets.size()
	for i in range(offsets.size()):
		var p: Vector3 = offsets[i]
		mm.set_instance_transform(i, Transform3D(orient, p))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	mmi.multimesh = mm
	mmi.material_override = mat
	return mmi


## An elliptical cap turned around +Y: radius at y = 0, apex at y = rise. Normals
## are the analytic ellipsoid normals, so there is no faceting on the curve.
## Used at both scales — the 33 mm lens glass and the 300 mm smoked bubble.
func _dome_mesh(radius: float, rise: float, segments: int, rings: int) -> ArrayMesh:
	var prof: Array = []
	var n: int = maxi(rings, 2)
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		var a: float = t * PI * 0.5
		var ca: float = cos(a)
		var sa: float = sin(a)
		prof.append(Vector4(radius * ca, rise * sa,
			ca / maxf(radius, 0.0001), sa / maxf(rise, 0.0001)))
	return MK.lathe(prof, segments, 1.0)


## A basis whose -Z points along `dir`, kept upright. This is what turns a target
## point into a camera pose, so the beam and the body cannot disagree.
func _aim_basis(dir: Vector3) -> Basis:
	if dir.length_squared() < 0.000001:
		return Basis()
	var zv: Vector3 = -dir.normalized()
	var up: Vector3 = Vector3.UP
	if absf(zv.dot(up)) > 0.999:
		up = Vector3.BACK
	var xv: Vector3 = up.cross(zv).normalized()
	var yv: Vector3 = zv.cross(xv).normalized()
	return Basis(xv, yv, zv)
