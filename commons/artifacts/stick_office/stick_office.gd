extends Node3D
class_name StickOffice

## stick_office — an office is not a shape. It is a place a rod has been put, and the
## family this bench comes from photographs it by welding the place onto the rod.
##
## ─────────────────────────────────────────────────────────────────────────────────────
## THE FAMILY, AND IT IS ONE READING COUNTED TWICE.
##
## Two registry tokens declare `office` = reach | rule | lever | pointer | baton, with the
## same five values in the same order: `grab_long_stick` and `grab_rainbow_stick`
## (primitives.json). The brief asked whether the two members agree about what the word
## means. They cannot disagree. They are ONE SCRIPT:
##
##   grab_long_stick.tscn:3       ext_resource → res://commons/primitives/cubes/grab_rod.gd
##   grab_rainbow_stick.tscn:3    ext_resource → res://commons/primitives/cubes/grab_rod.gd
##   grab_long_stick.tscn:32      script = ExtResource("2_4w1i0")   ← attached to the root
##   grab_rainbow_stick.tscn:32   script = ExtResource("2_4w1i0")   ← the same file
##
## grab_rod.gd owns the whole axis: the export (:79), the allow-list (:80), the dispatch
## (:128-140) and all five builders (:149-221) are one implementation counted twice. The
## corpus's most common hidden family, found again — and this time there is a MEASUREMENT
## of it, which no previous finding of this shape had. Both tokens were swept, and the two
## bite reports rank all ten office pairs in the SAME ORDER and agree on every one of them:
##
##   pair            long     rainbow   Δ            (doc/reports/sweep_grab_long_stick_bite.json
##   reach·rule      0.370%   0.357%    3.5%          doc/reports/sweep_grab_rainbow_stick_bite.json)
##   reach·lever     0.401%   0.398%    0.7%
##   reach·pointer   0.361%   0.348%    3.6%
##   reach·baton     0.465%   0.464%    0.2%
##   rule·lever      0.626%   0.614%    1.9%
##   rule·pointer    0.505%   0.495%    2.0%
##   rule·baton      0.557%   0.557%    0.0%
##   lever·pointer   0.478%   0.462%    3.3%
##   lever·baton     0.663%   0.659%    0.6%
##   pointer·baton   0.504%   0.503%    0.2%
##
## That is what a shared vocabulary looks like when it is honest AND worthless as evidence:
## the two sheets are the same experiment, run twice, on the same code. The census is
## `office` · 2 tokens · 2 scenes · 1 script · ZERO independent readings.
##
## The two scenes differ only in dressing — grab_long_stick.tscn:24 magenta grip, :36 cloth
## trail, :26 shaft radii 0.010/0.011; grab_rainbow_stick.tscn:24 dark metallic grip, :36
## rainbow trail, :26 radii 0.012/0.014. The loudest difference between them, the trail, is
## a RATE and cannot be photographed at all: MesmerizingTrail needs two recorded points
## before it builds a mesh, which grab_rod.gd:76-78 already says. Two names, one argument.
##
## ─────────────────────────────────────────────────────────────────────────────────────
## THE BRIEF'S SECOND SUSPICION WAS HALF WRONG, AND THE WRONG HALF IS THE FINDING.
##
## The suspicion: `office` names a USE, not a property, so neither source will change any
## geometry across the five values, and the axis will be a label axis.
##
## DESTROYED on the first half. grab_rod.gd changes real geometry for four of the five
## values — a graduated bone blade (:154-165), a sleeved effort arm with bands, collar,
## counterweight and a wedge (:179-187), a full-length graphite taper with a finger stop
## (:199-202), an ivory sleeve with cork grip, five bindings and a brass pommel (:215-221).
## Nothing here is a label. `reach` builds nothing at all (:120-123), which is correct: it
## is the shipped default across 45 live placements and the legacy body byte for byte.
##
## CONFIRMED on the second half, in the one place it costs something. Every fitting is
## added as ONE child of the rod (:142  add_child(dress)), and the rod is an
## XRToolsPickable RigidBody3D. So the LEVER'S FULCRUM IS WELDED TO THE LEVER:
##
##     grab_rod.gd:186   dress.add_child(_wedge(Vector3(0.10, -0.052, 0.0), …))
##     grab_rod.gd:187   dress.add_child(_bar(Vector3(0.10, -0.112, 0.0), …))
##
## A fulcrum is, by definition, the part of a lever that does not move with the lever. This
## one is parented to the body that gets picked up, so it travels — and, hanging 0.112 m
## below the shaft axis of a rod held anywhere, it touches nothing. The author knew what
## the axis wanted and had only one node to put it on. The docstring says so plainly at
## :27-28: "what the rod is FOR … shows entirely in what is fitted at its ends." Fitted is
## the concession. An office is a relation, and a relation fitted to one of its two terms
## is a claim that the other term does not exist.
##
## ─────────────────────────────────────────────────────────────────────────────────────
## WHAT THIS BENCH DOES ABOUT IT.
##
## It keeps `office`, the family's word, with the family's five values in the family's
## order and the family's palette (grab_rod.gd:150-152, 173-177, 195-197, 210-213, copied
## as Colors and not retyped from prose). It crosses it with `reading`, which is one
## question: WHERE DOES THE OFFICE LIVE?
##
##   fitted      on the rod. The source's answer, rebuilt at this bench's scale. The
##               lever's wedge hangs from the shaft with a 0.130 m gap of air under it,
##               which is the source's arrangement drawn to scale and left visible.
##   apparatus   in the world. The rod is BARE and byte-identical in all five cells; what
##               changes is what stands around it — a shelf out of arm's length, a
##               graduated board to lay against, a fulcrum standing ON the bench and a load
##               to shift, a target to indicate, a fitted case to be kept in and handed on.
##   trace       in what was done. The rod is bare, the apparatus is gone, and what remains
##               is the state the act left the world in — the thing retrieved and the scuff
##               it dragged, the stock ruled and ticked, the load displaced and the bite
##               crushed where the fulcrum stood.
##
## THE SHEET'S ARGUMENT, IN ONE CELL: three of the fifteen frames are the same photograph.
## reach·fitted is a bare rod because the source fits nothing to a reach. pointer·trace is
## a bare rod because grab_rod.gd:70 says of the pointer "It indicates; it does not touch."
## baton·trace is a bare rod because :208-209 says "a baton is held and shown, and it
## touches nothing." One picture, three answers, and the source wrote two of the three
## reasons itself. That is what it means for a word to name a use rather than a shape — and
## it also shows `office` is TWO axes wearing one word: reach, rule and lever act on
## surfaces and leave evidence, pointer and baton act on people and leave none. The trace
## column is the only place in this programme where that split can be photographed.
##
## ─────────────────────────────────────────────────────────────────────────────────────
## INSTRUMENT DECISIONS, EACH COSTING SOMETHING.
##
## THE ASSEMBLY IS YAWED 0.62 rad. capture_config_sweep.gd:69 puts the camera at YAW 0.62
## and :443 builds its direction as Vector3(sin(yaw)cos(pitch), -sin(pitch), cos(yaw)cos(pitch)),
## whose horizontal bearing is 0.62 exactly. Rotating the bench by the same angle puts the
## rod's axis PERPENDICULAR to that bearing, so a 1.4 m rod is photographed at its full
## length instead of foreshortened by cos of whatever angle it happened to lie at. This is
## the one thing the sources most needed and never had.
##
## THERE IS A CONSTANT AABB ANCHOR. Anchor is a BoxMesh with layers = 0 — invisible, still
## counted, because capture_config_sweep.gd:1488 merges every MeshInstance3D regardless of
## layer or visibility. Without it the camera would retreat for the tall apparatus cells and
## close in for the flat trace cells, and every measured pair would carry a framing change
## it did not earn. With it the camera never moves across all fifteen cells.
##
## dna.framing IS 0.48 AND IT IS THE WHOLE REASON THIS BENCH EXISTS AT ALL. The sources fit
## by DIAGONAL: a 1.74 x 0.10 x 0.10 m rod has a 1.746 m diagonal and a 0.005 m² silhouette,
## so both sweeps photographed a subject occupying 2.255% and 2.273% of frame and both were
## reported "faint - under 2% of the frame moved". Inside the subject, lever against baton
## moved 0.663 / 2.255 = 29.4% of the rod. The verdict on the family's own axis was a fact
## about the camera, and neither registry entry carries a framing hint.
##
## DETERMINISTIC. No RandomNumberGenerator, no randf, no noise, no _process, no Timer, no
## tween, no shader. Every vertex is arithmetic on the constants below, so two builds are
## the same mesh and the two designed nulls are byte identities rather than near-misses.
##
## NO NUMERIC VALUE IN EITHER AXIS. Both are word enums typed String, so cabinet_sweep's
## coerce() has nothing to numericise and the tier_terrarium failure — Object.set() refusing
## a typed property in silence — cannot occur here. Checked, not assumed.


# ── DNA ───────────────────────────────────────────────────────────────────────────────
## WHAT THE ROD IS FOR. The family's word, the family's five values, the family's order,
## taken from grab_rod.gd:79-80. Default `reach`, which is the source's default across all
## 45 live placements (28 grab_long_stick, 17 grab_rainbow_stick) and builds nothing.
@export_enum("reach", "rule", "lever", "pointer", "baton") var office: String = "reach":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not OFFICES.has(picked):
			return                      ## an unreachable value keeps the standing bench
		office = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHERE THE OFFICE LIVES. Default `fitted`, because fitted is what the sources do: they
## put the office on the rod. The default cell of this bench is therefore the thing being
## argued with, photographed first.
@export_enum("fitted", "apparatus", "trace") var reading: String = "fitted":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()


const OFFICES: PackedStringArray = ["reach", "rule", "lever", "pointer", "baton"]
const READINGS: PackedStringArray = ["fitted", "apparatus", "trace"]


# ── The standing bench, identical in all fifteen cells ────────────────────────────────
const CAMERA_YAW: float = 0.62

const BENCH_SIZE := Vector3(1.600, 0.060, 0.440)
const BENCH_TOP: float = 0.060
const POST_SIZE := Vector3(0.060, 0.240, 0.090)
const POST_X: float = 0.560

const ROD_R: float = 0.016
const ROD_LEN: float = 1.400
const ROD_Y: float = 0.316                  ## POST top 0.300 + ROD_R
const ROD_X0: float = -0.700
const ROD_X1: float = 0.700
const GRIP_SIZE := Vector3(0.110, 0.048, 0.048)
const GRIP_X: float = -0.755
const BEAD_R: float = 0.030
const BEAD_X: float = 0.730

## The framing pin. Every cell measures 1.680 x 0.560 x 0.460 local, so the camera stands
## still. Sized to the union of the fifteen cells with nothing to spare on x: the grip ends
## at -0.810 and the reach shelf at +0.800.
const ANCHOR_SIZE := Vector3(1.680, 0.560, 0.460)
const ANCHOR_Y: float = 0.280

## Marks lie 0.5 mm proud of whatever they are on, so they take the key light rather than
## z-fighting with it.
const PROUD: float = 0.0005

const C_BENCH := Color(0.34, 0.31, 0.27)
const C_POST := Color(0.25, 0.24, 0.23)
const C_ROD := Color(0.56, 0.57, 0.59)
const C_GRIP := Color(0.13, 0.13, 0.14)
const C_BEAD := Color(0.93, 0.91, 0.85)

## THE SOURCE'S PALETTE, COPIED AS COLORS. grab_rod.gd:150-152 (rule), :173-177 (lever),
## :195-197 (pointer), :210-213 (baton). Taking the numbers rather than the words is the
## difference between rebuilding a family's argument and paraphrasing its docstring.
const C_BONE := Color(0.88, 0.86, 0.79)
const C_INK := Color(0.07, 0.07, 0.08)
const C_DATUM := Color(0.72, 0.15, 0.10)
const C_STEEL := Color(0.33, 0.34, 0.37)
const C_BAND := Color(0.10, 0.10, 0.11)
const C_BRIGHT := Color(0.62, 0.62, 0.60)
const C_BLOCK := Color(0.15, 0.16, 0.18)
const C_SHIM := Color(0.42, 0.43, 0.45)
const C_GRAPHITE := Color(0.20, 0.21, 0.24)
const C_ACCENT := Color(0.88, 0.36, 0.12)
const C_PALE := Color(0.85, 0.85, 0.82)
const C_IVORY := Color(0.94, 0.93, 0.89)
const C_CORK := Color(0.58, 0.40, 0.23)
const C_BINDING := Color(0.09, 0.09, 0.10)
const C_BRASS := Color(0.76, 0.64, 0.32)

## The world's own materials — apparatus and trace, which are not the rod's.
const C_STOCK := Color(0.80, 0.75, 0.63)
const C_SCUFF := Color(0.47, 0.43, 0.37)
const C_LOAD := Color(0.29, 0.27, 0.30)
const C_CARD := Color(0.90, 0.88, 0.83)
const C_FELT := Color(0.30, 0.13, 0.16)

var _bulk: bool = false
var _rig: Node3D = null


func _ready() -> void:
	_check_hints()
	_rebuild()


## Config from map_data.json tokens:  stick_office#office:lever#reading:apparatus
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("office"):
		office = str(config_data["office"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	_bulk = false
	if is_inside_tree():
		_rebuild()


# ── Build ─────────────────────────────────────────────────────────────────────────────
func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	_rig = Node3D.new()
	_rig.name = "Rig"
	_rig.rotation.y = CAMERA_YAW
	add_child(_rig)

	_anchor()
	_standing_bench()

	match reading:
		"fitted":
			_read_fitted()
		"apparatus":
			_read_apparatus()
		"trace":
			_read_trace()
		_:
			pass


## Invisible, counted, constant. See the header.
func _anchor() -> void:
	var mesh := BoxMesh.new()
	mesh.size = ANCHOR_SIZE
	var mi := MeshInstance3D.new()
	mi.name = "Anchor"
	mi.mesh = mesh
	mi.position = Vector3(0.0, ANCHOR_Y, 0.0)
	mi.layers = 0
	_rig.add_child(mi)


## The bench, the two posts and the rod. Byte-identical in every cell of the sheet, which
## is what makes the apparatus and trace columns readable as columns at all: five frames in
## which the rod does not move are five frames about something other than the rod.
func _standing_bench() -> void:
	_box("Bench", BENCH_SIZE, Vector3(0.0, BENCH_SIZE.y * 0.5, 0.0), C_BENCH)
	_box("PostL", POST_SIZE, Vector3(-POST_X, BENCH_TOP + POST_SIZE.y * 0.5, 0.0), C_POST)
	_box("PostR", POST_SIZE, Vector3(POST_X, BENCH_TOP + POST_SIZE.y * 0.5, 0.0), C_POST)
	_rod("Shaft", 0.0, ROD_LEN, ROD_R, ROD_R, C_ROD, 0.72, 0.34)
	_box("Grip", GRIP_SIZE, Vector3(GRIP_X, ROD_Y, 0.0), C_GRIP)
	_ball("Bead", BEAD_X, BEAD_R, C_BEAD)


# ── reading = fitted — the source's answer, rebuilt to scale ──────────────────────────
func _read_fitted() -> void:
	match office:
		"reach":
			pass                        ## grab_rod.gd:120-123 — nothing is fitted to a reach
		"rule":
			_fitted_rule()
		"lever":
			_fitted_lever()
		"pointer":
			_fitted_pointer()
		"baton":
			_fitted_baton()
		_:
			pass


## grab_rod.gd:149-165. A bone blade along the camera-facing side of the shaft, ticked
## every 0.09 m with a longer mark every fifth, a hairline second scale under them and a
## red datum at zero.
func _fitted_rule() -> void:
	_box("Blade", Vector3(ROD_LEN, 0.062, 0.010), Vector3(0.0, ROD_Y, 0.030), C_BONE)
	_box("Printed", Vector3(1.320, 0.007, 0.004), Vector3(0.0, ROD_Y - 0.024, 0.037), C_INK)
	for i in range(15):
		var tx: float = -0.600 + float(i) * 0.090
		if i % 5 == 0:
			_box("Tick%d" % i, Vector3(0.012, 0.060, 0.005), Vector3(tx, ROD_Y, 0.036), C_INK)
		else:
			_box("Tick%d" % i, Vector3(0.008, 0.030, 0.005), Vector3(tx, ROD_Y + 0.017, 0.036), C_INK)
	_box("Datum", Vector3(0.030, 0.062, 0.012), Vector3(-0.655, ROD_Y, 0.036), C_DATUM)


## grab_rod.gd:172-187, and the wedge is the finding. The effort arm thickens, gets three
## grip bands and a counterweight; a bearing collar marks the pivot; and the fulcrum is a
## child of the ROD, so it hangs 0.130 m clear of the bench it should be standing on. The
## gap is not a modelling error. It is grab_rod.gd:186 drawn at 1:1.
func _fitted_lever() -> void:
	_rod("Effort", -0.230, 0.620, 0.030, 0.030, C_STEEL, 0.42, 0.60)
	var bands: PackedFloat32Array = [-0.480, -0.380, -0.280]
	for gx in bands:
		_rod("Band", gx, 0.020, 0.036, 0.036, C_BAND, 0.85, 0.0)
	_rod("Counterweight", -0.520, 0.110, 0.052, 0.052, C_BLOCK, 0.75, 0.0)
	_rod("Collar", 0.090, 0.062, 0.040, 0.040, C_BRIGHT, 0.30, 0.55)
	## apex up, touching the shaft underside at y = 0.300; base at y = 0.190; bench at 0.060
	_wedge("WeldedFulcrum", Vector3(0.250, 0.110, 0.130), Vector3(0.090, 0.245, 0.0), C_BLOCK)
	_box("WeldedShim", Vector3(0.310, 0.017, 0.170), Vector3(0.090, 0.181, 0.0), C_SHIM)


## grab_rod.gd:194-202. The whole shaft becomes one taper: 0.038 m at the hand narrowing to
## a needle that dies short of the bead, so the body of the rod is itself an arrow.
func _fitted_pointer() -> void:
	_rod("Taper", 0.0, ROD_LEN, 0.002, 0.038, C_GRAPHITE, 0.42, 0.15)
	_rod("FingerStop", -0.420, 0.017, 0.046, 0.046, C_ACCENT, 0.45, 0.0)
	_rod("IndexRing", -0.300, 0.011, 0.030, 0.030, C_PALE, 0.50, 0.0)
	_rod("Needle", 0.690, 0.028, 0.0, 0.005, C_PALE, 0.50, 0.0)


## grab_rod.gd:209-221. An ivory sleeve makes the shaft one clean wand; a fat cork grip
## bound with five rings and a brass pommel make the hand end an object in its own right.
## Nothing is fitted at the far end at all.
func _fitted_baton() -> void:
	_rod("Sleeve", 0.0, ROD_LEN, 0.022, 0.022, C_IVORY, 0.35, 0.0)
	_rod("Cork", -0.440, 0.300, 0.052, 0.052, C_CORK, 0.85, 0.0)
	for i in range(5):
		var bx: float = -0.570 + float(i) * 0.070
		_rod("Binding%d" % i, bx, 0.013, 0.058, 0.058, C_BINDING, 0.70, 0.0)
	_rod("Ferrule", -0.280, 0.021, 0.040, 0.040, C_BRASS, 0.28, 0.85)
	_ball("Pommel", -0.630, 0.050, C_BRASS)


# ── reading = apparatus — the rod is bare; the world names the office ─────────────────
func _read_apparatus() -> void:
	match office:
		"reach":
			_app_reach()
		"rule":
			_app_rule()
		"lever":
			_app_lever()
		"pointer":
			_app_pointer()
		"baton":
			_app_baton()
		_:
			pass


## Out of arm's length. A post carrying a shelf above the far end of the rod, with the
## thing on it. Nothing about the rod says reach; the height of the shelf does.
func _app_reach() -> void:
	_box("ShelfPost", Vector3(0.050, 0.402, 0.050), Vector3(0.760, 0.261, -0.150), C_POST)
	_box("Shelf", Vector3(0.170, 0.016, 0.140), Vector3(0.715, 0.470, -0.150), C_BENCH)
	_box("OutOfReach", Vector3(0.070, 0.070, 0.070), Vector3(0.715, 0.513, -0.150), C_BRASS)


## A rule is a rod laid against a scale. The scale is on the board, and the board is not
## the rod — which is the entire disagreement with grab_rod.gd:154-165, where the
## graduations are engraved onto the stick and travel with it.
func _app_rule() -> void:
	_box("ScaleBoard", Vector3(1.300, 0.320, 0.012), Vector3(0.0, 0.280, -0.170), C_BONE)
	_box("ScaleFootL", Vector3(0.070, 0.060, 0.090), Vector3(-0.560, 0.090, -0.170), C_POST)
	_box("ScaleFootR", Vector3(0.070, 0.060, 0.090), Vector3(0.560, 0.090, -0.170), C_POST)
	for i in range(15):
		var tx: float = -0.600 + float(i) * 0.090
		if i % 5 == 0:
			_box("SBTick%d" % i, Vector3(0.012, 0.130, 0.004),
				Vector3(tx, 0.360, -0.164 + PROUD), C_INK)
		else:
			_box("SBTick%d" % i, Vector3(0.008, 0.070, 0.004),
				Vector3(tx, 0.390, -0.164 + PROUD), C_INK)
	_box("SBDatum", Vector3(0.030, 0.150, 0.006), Vector3(-0.600, 0.355, -0.164 + PROUD), C_DATUM)


## The fulcrum STANDS on the bench and takes the reaction into it, and the load is a
## separate body at the far end. Same wedge as the fitted cell in silhouette, 0.240 m tall
## instead of 0.110 because it reaches the ground. That difference — a fulcrum in contact
## with the world instead of hanging off the lever — is the pair this whole bench is for.
func _app_lever() -> void:
	_wedge("Fulcrum", Vector3(0.250, 0.240, 0.150), Vector3(-0.080, 0.180, 0.0), C_BLOCK)
	_box("Load", Vector3(0.200, 0.226, 0.180), Vector3(0.520, 0.173, 0.0), C_LOAD)
	## the bearing plate closes the last 0.014 m between the load and the shaft underside
	## at 0.300, so the load is in CONTACT with the rod rather than near it
	_box("Bearing", Vector3(0.230, 0.014, 0.200), Vector3(0.520, 0.293, 0.0), C_SHIM)


## A target, and the rod indicates it. The card stands beyond the bead, on the line of the
## shaft, so the pointing is a geometric fact about two objects rather than a taper.
func _app_pointer() -> void:
	_box("TargetPost", Vector3(0.040, 0.220, 0.040), Vector3(0.770, 0.170, -0.120), C_POST)
	_box("TargetCard", Vector3(0.240, 0.200, 0.010), Vector3(0.700, 0.380, -0.120), C_CARD)
	_box("TargetOuter", Vector3(0.150, 0.150, 0.004), Vector3(0.700, 0.380, -0.115 + PROUD), C_INK)
	_box("TargetInner", Vector3(0.078, 0.078, 0.005), Vector3(0.700, 0.380, -0.114 + PROUD), C_CARD)
	_box("TargetPip", Vector3(0.026, 0.026, 0.006), Vector3(0.700, 0.380, -0.113 + PROUD), C_DATUM)


## A fitted case, open. A baton is the kind of rod that is kept, presented and handed on:
## its apparatus is not a thing it acts upon but the furniture of its own custody.
func _app_baton() -> void:
	_box("CaseBody", Vector3(0.700, 0.090, 0.200), Vector3(-0.100, 0.105, 0.040), C_BLOCK)
	_box("CaseBed", Vector3(0.640, 0.024, 0.120), Vector3(-0.100, 0.138, 0.040), C_FELT)
	_box("CaseLid", Vector3(0.700, 0.240, 0.014), Vector3(-0.100, 0.270, -0.070), C_BLOCK)
	_box("CaseLining", Vector3(0.640, 0.190, 0.006), Vector3(-0.100, 0.270, -0.061 + PROUD), C_FELT)


# ── reading = trace — the rod is bare, the apparatus is gone, the world is left as it was
# left. Two of the five offices leave nothing, and the source says why for both.
func _read_trace() -> void:
	match office:
		"reach":
			_trace_reach()
		"rule":
			_trace_rule()
		"lever":
			_trace_lever()
		"pointer":
			pass                        ## grab_rod.gd:70 — "It indicates; it does not touch."
		"baton":
			pass                        ## grab_rod.gd:208-209 — "it touches nothing."
		_:
			pass


## The thing is down off the shelf and near the hand, and the bench carries the shallow arc
## the tip dragged getting it there. A reach is proved by displacement.
func _trace_reach() -> void:
	_box("Retrieved", Vector3(0.110, 0.110, 0.110), Vector3(-0.480, 0.115, 0.060), C_BRASS)
	for i in range(9):
		var t: float = float(i) / 8.0
		var sx: float = 0.660 - t * 1.020
		var sz: float = -0.130 + t * t * 0.190
		_box("Scuff%d" % i, Vector3(0.128, 0.002, 0.130),
			Vector3(sx, BENCH_TOP + PROUD, sz), C_SCUFF)


## The stock, ruled. A rule removes nothing and moves nothing; all it can leave is the mark
## it let something else make, which is why this is the smallest trace on the sheet and the
## predicted closest pair.
func _trace_rule() -> void:
	_box("Stock", Vector3(0.760, 0.006, 0.150), Vector3(0.030, 0.063, 0.060), C_STOCK)
	_box("Scribed", Vector3(0.700, 0.002, 0.007), Vector3(0.030, 0.066 + PROUD, 0.030), C_INK)
	for i in range(11):
		var tx: float = -0.320 + float(i) * 0.070
		_box("Ruled%d" % i, Vector3(0.008, 0.002, 0.048),
			Vector3(tx, 0.066 + PROUD, 0.086), C_INK)
	_box("StockDatum", Vector3(0.022, 0.002, 0.022), Vector3(-0.320, 0.066 + PROUD, 0.030), C_DATUM)


## The load is somewhere else than where it was, tipped where it came down; the bench
## carries the crushed bite the fulcrum stood in and the scar the load ploughed behind it.
func _trace_lever() -> void:
	_box("Moved", Vector3(0.150, 0.150, 0.150), Vector3(0.400, 0.145, 0.010), C_LOAD, 0.12)
	_box("Bite", Vector3(0.130, 0.002, 0.090), Vector3(-0.080, BENCH_TOP + PROUD, 0.0), C_SCUFF)
	_box("Scar", Vector3(0.420, 0.002, 0.120), Vector3(0.170, BENCH_TOP + PROUD, 0.010), C_SCUFF)


# ── Local helpers ─────────────────────────────────────────────────────────────────────
func _mat(col: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	return m


func _box(nm: String, size: Vector3, pos: Vector3, col: Color, roll: float = 0.0) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.position = pos
	if roll != 0.0:
		mi.rotation.z = roll
	mi.material_override = _mat(col, 0.82, 0.0)
	_rig.add_child(mi)


## A cylinder lying along the shaft's axis (local +X, at the shaft's height). r_tip is the
## radius at the +X end and r_butt at the -X end, so a taper is written the way the rod is
## read: from the hand outward. Same convention as grab_rod.gd:253-265.
func _rod(nm: String, cx: float, length: float, r_tip: float, r_butt: float,
		col: Color, rough: float, metal: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r_tip
	mesh.bottom_radius = r_butt
	mesh.height = length
	mesh.radial_segments = 24
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.position = Vector3(cx, ROD_Y, 0.0)
	## -90 about Z maps the mesh's local +Y (its top) onto local +X (the bead end).
	mi.rotation_degrees = Vector3(0.0, 0.0, -90.0)
	mi.material_override = _mat(col, rough, metal)
	_rig.add_child(mi)


func _ball(nm: String, cx: float, r: float, col: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.position = Vector3(cx, ROD_Y, 0.0)
	mi.material_override = _mat(col, 0.40, 0.10)
	_rig.add_child(mi)


## A triangular prism, apex up: the apex meets the shaft and the base is below it. Same
## primitive grab_rod.gd:281-289 uses, so the two fulcrums differ in their relation to the
## ground and in nothing else.
func _wedge(nm: String, size: Vector3, pos: Vector3, col: Color) -> void:
	var mesh := PrismMesh.new()
	mesh.size = size
	mesh.left_to_right = 0.5
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = _mat(col, 0.75, 0.0)
	_rig.add_child(mi)


## The declaration gate reads the @export_enum hint; the builders read the const. If they
## ever drift, every frame in a sweep is a fact about which of the two a given tool
## trusted — science_screen's whole failure, and it cost that pass sixteen identical frames
## and a confident INERT verdict about a typo.
func _check_hints() -> void:
	var pairs: Array = [["office", OFFICES], ["reading", READINGS]]
	for entry in pairs:
		var key: String = str(entry[0])
		var want: PackedStringArray = entry[1]
		for prop in get_property_list():
			if String(prop.get("name", "")) != key:
				continue
			var got: PackedStringArray = String(prop.get("hint_string", "")).split(",")
			if got != want:
				push_warning("stick_office: %s hint %s != const %s" % [key, got, want])
