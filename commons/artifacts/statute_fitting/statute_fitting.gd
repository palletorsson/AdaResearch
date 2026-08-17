extends Node3D
class_name StatuteFitting

## statute_fitting — a fire point, and the two different questions its family asks with
## one word.
##
## ═════════════════════════════════════════════════════════════════════════════════════
## THE FAMILY. Two tokens declare an axis called `statute` with identical values
## (issue | notice | joinery | lapse): `fire_extinguisher` and `fire_hose_box`. Unlike
## most two-member families in this corpus they are NOT one script — there are two files,
## 904 and 981 lines — but they are one AUTHOR working from one note, and the note says
## so: fire_extinguisher.gd:28-29 instructs "If you add a value to one file, add it to the
## other in the same commit or the family forks."
##
## Read side by side, the agreement is near-total and mechanical:
##
##   SUPPORTS           fire_extinguisher.gd:182-183   fire_hose_box.gd:183-184   identical
##   DEGRADE            :189-195                       :190-196                   identical
##   SIGN_RED/BOARD_    :199-200                       :201-202                   identical
##   STATUTES table     :206-218                       :208-220                   identical to
##                                                                                the last digit
##   _lv/_lv_rough/     :586-616                       :659-689                   identical
##     _lv_metal/_ink                                                             bodies
##   _keep_clear        :817-827                       :891-901                   same six slabs
##   the expired tag    :882  make_panel_mesh("2019")  :959  same literal          same string
##
## So the family agrees. The question this bench was built to answer is whether they agree
## about ONE THING, and they do not — they agree about two.
##
## ═════════════════════════════════════════════════════════════════════════════════════
## THE BRIEF'S SUSPICION, AND WHY IT IS WRONG IN ITS LETTER AND RIGHT IN ITS SPIRIT.
##
## The suspicion put to this bench was that `issue`, `notice` and `lapse` are a regulatory
## lifecycle and `joinery` is a construction detail — how the thing is put together, which
## does not change when a certificate expires.
##
## `joinery` is NOT a construction detail. It is not the FITTING's joinery, it is the
## BUILDING's. fire_extinguisher.gd:44-45 and fire_hose_box.gd:85-87 both gloss it as
## "absorption: the architect won, the red is retinted into the building's own cabinetwork
## and the shouting is reduced to one small engraved plate", and _statute_joinery()
## (:833-846 / :908-924) builds exactly that — a flush matte panel, a shadow-gap reveal,
## one brushed plate — while _lv() drags the alarm red 88% of the way to a dark taupe. The
## word names a stance toward the law, like the other three.
##
## But the SEAM IS REAL and it falls one value to the left of where the brief put it:
##
##   issue     the building added nothing            A DECISION, TAKEN AT INSTALL
##   notice    the building amplified                A DECISION, TAKEN AT INSTALL
##   joinery   the building absorbed and silenced    A DECISION, TAKEN AT INSTALL
##   lapse     nobody came back                      NOT A DECISION. TIME.
##
## Three of these are things a building DID. The fourth is a thing that HAPPENED to it.
## Putting them in one enum makes neglect into a fourth kind of intention — which is what
## a building is allowed to claim in court and precisely what it is not. And because the
## code dispatches on one `match` (fire_extinguisher.gd:763-772, fire_hose_box.gd:830-839),
## the two questions are mutually exclusive: the family cannot photograph a serviced
## extinguisher on a rotted wall, nor an absorbed one that has quietly gone out of date —
## and the second of those is the commonest failure in the built world, because a thing is
## absorbed into the joinery exactly so that it can be forgotten.
##
## THE EVIDENCE THAT `lapse` IS CARRYING BOTH HALVES: _statute_lapse() does rust, chalked
## paint and a grime collar — all fabric — AND THEN hangs a service tag reading "2019"
## (fire_extinguisher.gd:882, fire_hose_box.gd:959). The date is welded to the rust. There
## is no way to ask for one without the other, and there is no way to ask for a VALID tag
## at all: the only certificate anywhere in the family is an expired one.
##
## ═════════════════════════════════════════════════════════════════════════════════════
## WHAT THIS BENCH DOES ABOUT IT.
##
## It keeps `statute` — the family's word, the family's four values, the family's exact
## colour arithmetic, copied and not retyped (LIVERY below is STATUTES from either file,
## digit for digit) — and it removes the date from `lapse`, handing it to a second axis.
##
##   currency   IS THE PROMISE STILL IN FORCE, AND HOW WOULD YOU KNOW?
##
## and it is answered in GEOMETRY, never in text, because the evidence this programme
## accepts is one 760x760 still and a printed date is worth nothing in it. Four
## instruments, each answering a different question, exactly as an inspector reads them:
##
##   the gauge needle      is it charged?          in the green sector / down in the red
##   the tamper seal       has it been fired?      an intact loop / two cut stubs / gone
##   the record band       is it in date?          the cycle colour on the wall card
##   the bracket           is it there at all?     occupied / empty, with the wall ghost
##
##   certified    needle in the green, seal intact, current cycle colour, body present
##   overdue      the same object, to the millimetre. ONLY the record's cycle band has
##                changed colour. This is the state the brief warned could not be drawn,
##                and the answer is that it CAN be drawn but it costs 0.60% of frame
##                against 5.7% for a missing extinguisher — the most consequential fact
##                about the object is the faintest mark on the sheet, and that number is
##                the finding, not an accident of framing.
##   discharged   needle swung out of the green, seal cut. Nothing about the paperwork
##                has changed: being used is not being expired, which is the second
##                thing `lapse` cannot say.
##   absent       the bracket stands empty, the strap hangs open, and the wall carries the
##                unfaded ghost of the cylinder. The record card is STILL THERE and still
##                says in-date, because the record is the building's and the object is not.
##
## ═════════════════════════════════════════════════════════════════════════════════════
## INSTRUMENT DECISIONS, EACH ONE COSTING SOMETHING.
##
## THE WALL IS THE AABB, IN ALL SIXTEEN CELLS. Every part of the fitting — cylinder,
## accent band, gauge, seal, strap, hose, ghost, card — is inside the board's own world
## box after the yaw (checked part by part, see dna.note). So `currency: absent`, which
## deletes the entire cylinder assembly, does not move the camera one millimetre. A
## sheet whose framing changed down one column would have measured its own framing.
##
## THE BOARD IS YAWED 0.62 rad. capture_config_sweep.gd:69 puts the camera at YAW 0.62
## and builds its direction as Vector3(sin(yaw)cos(pitch), -sin(pitch), cos(yaw)cos(pitch))
## (:443), whose horizontal bearing is 0.62 exactly. The wall turns to meet it, so the
## record card and the gauge are photographed square and cost only the 15 deg pitch.
##
## THE FLAT MARKS ARE UNSHADED. Everything painted ON the wall — the wall face, the
## statutory panel, the keep-clear hatch, the rust, the grime, the ghost, the record card
## and its cycle band — is SHADING_MODE_UNSHADED, so its pixel is filmic(srgb_to_linear
## (albedo)) and nothing else. That is what makes the prediction below two-sided rather
## than a floor: there is no shadow, no AO and no antialiasing inside a flat coplanar
## patch for a paper rasteriser to be blind to. The cylinder, bracket, gauge bezel and
## feet stay lit, so the object still has a body.
##
## NO RANDOMNESS ANYWHERE. No RandomNumberGenerator, no randf, no noise, no _process, no
## Timer, no tween. Every vertex and every colour is arithmetic on constants, so two
## builds are the same bytes and no dna.fixture is needed to pin a seed.
##
## NO TEXT ANYWHERE. Not one Label3D, not one baked-text panel. The sources put their
## whole `notice` sign and their whole `lapse` date into rendered glyphs; at 760x760 in a
## frame 0.94 m wide those are 4-6 px tall and contribute nothing a critic can measure.
## Where the sources write a word this bench draws a pictogram, a colour or a needle.


# ── AXES ──────────────────────────────────────────────────────────────────────────────

## AXIS 1 — WHAT THE BUILDING DID WITH THE LAW THAT SPECIFIES THIS OBJECT'S APPEARANCE.
## The family's word and the family's four values, verbatim from fire_extinguisher.gd:152
## and fire_hose_box.gd:156. issue (as delivered, nothing added — the sources' default and
## this bench's) | notice (full submission: statutory panel, red border, mandatory sign,
## keep-clear zone) | joinery (absorption: the architect's cabinetwork, the alarm red
## retinted, one engraved plate) | lapse (the fabric left to rot: chalked wall, rust from
## the fixings, grime at the foot — and NOTHING about a date, which is the change).
@export_enum("issue", "notice", "joinery", "lapse") var statute: String = "issue":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not STATUTES.has(picked):
			return                          ## an unreachable value keeps the standing wall
		statute = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## AXIS 2 — IS THE PROMISE STILL IN FORCE, AND HOW WOULD YOU KNOW? The half of `lapse`
## the sources could not separate. Answered by four instruments and no text at all:
## certified (needle in the green, seal intact, current cycle band) | overdue (the same
## object to the millimetre; only the cycle band has changed colour) | discharged (needle
## out of the green, seal cut; the paperwork untouched) | absent (empty bracket, open
## strap, the wall's unfaded ghost — and the record card still certifying nothing).
@export_enum("certified", "overdue", "discharged", "absent") var currency: String = "certified":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not CURRENCIES.has(picked):
			return
		currency = picked
		if is_inside_tree() and not _bulk:
			_rebuild()


const STATUTES: PackedStringArray = ["issue", "notice", "joinery", "lapse"]
const CURRENCIES: PackedStringArray = ["certified", "overdue", "discharged", "absent"]


# ── THE SOURCES' OWN ARITHMETIC ───────────────────────────────────────────────────────

## COPIED FROM fire_extinguisher.gd:206-218 AND fire_hose_box.gd:208-220, which hold the
## same table to the last digit. If these ever drift, this bench stops being about that
## family and starts being about a palette someone liked.
##
## `issue` and `notice` carry NO keys, so _lv() and _ink() are identity returns for both —
## not a lookup that happens to match. That is why the two rows of this sheet measure the
## SAME cycle-band delta to the byte, and it is the sources' decision, not this bench's.
const LIVERY: Dictionary = {
	"issue": {},
	"notice": {},
	"joinery": {"tint": Color(0.27, 0.29, 0.26), "amt": 0.88, "rough": 0.90,
			"metal": 0.06, "ink": Color(0.44, 0.46, 0.42), "ink_amt": 1.0},
	"lapse": {"tint": Color(0.60, 0.45, 0.42), "amt": 0.58, "rough": 0.95,
			"metal": 0.03, "ink": Color(0.56, 0.53, 0.48), "ink_amt": 0.85},
}

## The law's own colours. fire_extinguisher.gd:199-200 / fire_hose_box.gd:201-202. NOT
## routed through `statute`, and that carve-out is kept verbatim: a sign is the law
## speaking, and the law is not the building's decorator. Under `joinery` it leaves one
## red mark the building could not repaint.
const SIGN_RED: Color = Color(0.70, 0.09, 0.10)
const BOARD_WHITE: Color = Color(0.93, 0.93, 0.91)

## fire_extinguisher.gd:114 — the alarm red, and the thing `joinery` takes away.
const BODY_RED: Color = Color(0.78, 0.08, 0.08)
## fire_extinguisher.gd:115 — the white accent band, the one inked mark on the body.
const ACCENT_WHITE: Color = Color(0.96, 0.96, 0.96)
## fire_extinguisher.gd:838 / fire_hose_box.gd:916 — the architect's cabinetwork.
const CABINETWORK: Color = Color(0.35, 0.36, 0.33)
## fire_extinguisher.gd:840 / fire_hose_box.gd:918 — the shadow-gap reveal.
const REVEAL: Color = Color(0.09, 0.09, 0.09)
## fire_extinguisher.gd:854 / fire_hose_box.gd:932 — rust.
const RUST: Color = Color(0.33, 0.17, 0.08)
## fire_extinguisher.gd:870 / fire_hose_box.gd:933 — the grime that climbs off the floor.
const GRIME: Color = Color(0.20, 0.17, 0.14)
## fire_extinguisher.gd:818 / fire_hose_box.gd:892 — keep-clear paint.
const HAZARD: Color = Color(0.84, 0.70, 0.09)
## fire_extinguisher.gd:842 / fire_hose_box.gd:920 — the engraved plate, both colours.
const PLATE_METAL: Color = Color(0.60, 0.61, 0.62)
const PLATE_INK: Color = Color(0.19, 0.20, 0.19)
## fire_extinguisher.gd:333 — the steel bracket.
const STEEL: Color = Color(0.32, 0.32, 0.34)
## fire_extinguisher.gd:447 — the hose.
const HOSE_BLACK: Color = Color(0.07, 0.07, 0.08)
## fire_extinguisher.gd:408 — the pinch handle.
const DARK_STEEL: Color = Color(0.18, 0.18, 0.20)
## fire_extinguisher.gd:793 — the bright bracket steel of the notice apparatus.
const BRIGHT_STEEL: Color = Color(0.55, 0.56, 0.58)

## THE WALL, and the four things a building's own paintwork does under this axis. The
## sources have no wall of their own — they mount into whatever the map put behind them —
## so this is the one table here that is NOT copied. It is chosen so that `issue` is a
## plain builder's render and every other value is a departure from it.
const FACE_COLOR: Dictionary = {
	"issue": Color(0.62, 0.62, 0.60),
	"notice": Color(0.70, 0.09, 0.10),      ## SIGN_RED — the statutory panel's border
	"joinery": Color(0.35, 0.36, 0.33),     ## CABINETWORK
	"lapse": Color(0.50, 0.47, 0.42),       ## the same render, twenty years of corridor
}

## THE INSPECTION CYCLE COLOUR. Real service records and real tamper ties are colour-coded
## by cycle and read at a distance for exactly that reason; a printed date is not readable
## at this resolution and a colour is. `discharged` and `absent` keep the CURRENT colour on
## purpose — being fired is not being out of date, and neither is being stolen.
const CYCLE_GREEN: Color = Color(0.16, 0.52, 0.24)
const CYCLE_AMBER: Color = Color(0.86, 0.62, 0.10)
const CARD_STOCK: Color = Color(0.94, 0.93, 0.89)
const CARD_FRAME: Color = Color(0.16, 0.16, 0.15)
const CARD_PUNCH: Color = Color(0.28, 0.27, 0.25)

const DIAL_FACE: Color = Color(0.90, 0.90, 0.88)
const DIAL_GREEN: Color = Color(0.18, 0.50, 0.22)
const DIAL_RED: Color = Color(0.66, 0.13, 0.11)
const NEEDLE: Color = Color(0.10, 0.10, 0.11)
const SEAL_TIE: Color = Color(0.85, 0.78, 0.20)


# ── GEOMETRY ──────────────────────────────────────────────────────────────────────────

## capture_config_sweep.gd:69. The wall turns to meet the standpoint.
const CAMERA_YAW: float = 0.62

const BOARD_SIZE: Vector3 = Vector3(0.600, 0.760, 0.024)
const BOARD_Y: float = 0.435
const FOOT_SIZE: Vector3 = Vector3(0.075, 0.055, 0.120)
const FOOT_X: float = 0.185
const FACE_SIZE: Vector2 = Vector2(0.580, 0.740)

## Depth stack on the wall face (board front face is at z = 0.012). Gaps of 0.6 mm: far
## enough that nothing z-fights, near enough that the parallax at the sweep's 1.53 m is
## sub-pixel.
const Z_FACE: float = 0.0126
const Z_PANEL: float = 0.0134
const Z_GHOST: float = 0.0140
const Z_MARK: float = 0.0148
const Z_MARK2: float = 0.0154
const Z_CARD: float = 0.0160
const Z_CARDF: float = 0.0166
const Z_CYCLE: float = 0.0172

## The fitting's column on the wall. Everything about it lives at x > 0; the record card
## lives at x < 0, so the cylinder can never stand in front of the thing being read.
const FIT_X: float = 0.130
const CYL_R: float = 0.062
const CYL_H: float = 0.330
const CYL_Y: float = 0.330
const CYL_Z: float = 0.090

const CARD_X: float = -0.150
const CARD_Y: float = 0.310
const CARD_SIZE: Vector2 = Vector2(0.210, 0.290)
const BAND_SIZE: Vector2 = Vector2(0.210, 0.100)
const BAND_Y: float = 0.405

const GAUGE_Y: float = 0.462
const GAUGE_Z: float = 0.153
const GAUGE_R: float = 0.040

var _bulk: bool = false
var _wall: Node3D = null


func _ready() -> void:
	_check_hints()
	_rebuild()


# ── The sources' livery functions, body for body ──────────────────────────────────────

## fire_extinguisher.gd:586-591 / fire_hose_box.gd:659-664. `issue` and `notice` carry no
## "tint", so this hands `c` straight back. Never mutates BODY_RED.
func _lv(c: Color) -> Color:
	var e: Dictionary = LIVERY.get(statute, {})
	if not e.has("tint"):
		return c
	var tint: Color = e["tint"]
	return c.lerp(tint, float(e.get("amt", 0.5)))


func _lv_rough(base: float) -> float:
	var e: Dictionary = LIVERY.get(statute, {})
	if not e.has("rough"):
		return base
	return float(e["rough"])


func _lv_metal(base: float) -> float:
	var e: Dictionary = LIVERY.get(statute, {})
	if not e.has("metal"):
		return base
	return float(e["metal"])


## fire_extinguisher.gd:611-616 / fire_hose_box.gd:684-689, verbatim — AND IT IS THE
## HINGE OF THIS BENCH. Under `joinery` the table's ink_amt is 1.0, so Color.lerp(ink, 1.0)
## returns `ink` EXACTLY, whatever went in: _ink() is a CONSTANT FUNCTION there. In the
## sources that quietly kills the `label_color` and `accent_color` exports — pass any
## colour you like with statute:joinery and you get Color(0.44,0.46,0.42). Here it does
## something worse and more interesting: the green cycle band and the amber one become the
## same greige, and the difference between an extinguisher that is in date and one that is
## not stops existing. That is this bench's registered null, and the arithmetic producing
## it is not mine.
func _ink(c: Color) -> Color:
	var e: Dictionary = LIVERY.get(statute, {})
	if not e.has("ink"):
		return c
	var ink: Color = e["ink"]
	return c.lerp(ink, float(e.get("ink_amt", 1.0)))


func _cycle_color() -> Color:
	if currency == "overdue":
		return CYCLE_AMBER
	return CYCLE_GREEN


# ── Build ─────────────────────────────────────────────────────────────────────────────

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_wall = Node3D.new()
	_wall.name = "Wall"
	_wall.rotation.y = CAMERA_YAW
	add_child(_wall)

	_build_stand()
	_build_face()
	_build_statute()
	if currency == "absent":
		_build_ghost()
	_build_bracket()
	if currency != "absent":
		_build_body()
		_build_gauge()
		_build_seal()
	_build_record()


## The wall slab and its two feet. These four meshes are the whole world box: every other
## part of every cell sits inside their union after the yaw.
func _build_stand() -> void:
	_box("Board", BOARD_SIZE, Vector3(0.0, BOARD_Y, 0.0), Color(0.44, 0.44, 0.43), false, _wall)
	_box("FootL", FOOT_SIZE, Vector3(-FOOT_X, FOOT_SIZE.y * 0.5, 0.0),
			Color(0.30, 0.30, 0.29), false, _wall)
	_box("FootR", FOOT_SIZE, Vector3(FOOT_X, FOOT_SIZE.y * 0.5, 0.0),
			Color(0.30, 0.30, 0.29), false, _wall)


## The painted face. One flat quad, one colour per statute, and it is the base every other
## mark on the wall is drawn over.
func _build_face() -> void:
	var col: Color = FACE_COLOR.get(statute, FACE_COLOR["issue"])
	_quad("Face", FACE_SIZE, Vector3(0.0, BOARD_Y, Z_FACE), col, _wall)


# ── Axis 1: statute ───────────────────────────────────────────────────────────────────

func _build_statute() -> void:
	match statute:
		"notice":
			_statute_notice()
		"joinery":
			_statute_joinery()
		"lapse":
			_statute_lapse()
		_:
			pass                            ## "issue" — the building added nothing


## FULL SUBMISSION. The white statutory panel inside its red border, the mandatory sign
## across the head carrying the equipment pictogram, and the keep-clear zone hatched on
## the floor at the wall's foot. The border is the FACE quad showing through, which is why
## FACE_COLOR["notice"] is SIGN_RED.
func _statute_notice() -> void:
	_quad("Panel", Vector2(FACE_SIZE.x - 0.060, FACE_SIZE.y - 0.060),
			Vector3(0.0, BOARD_Y, Z_PANEL), BOARD_WHITE, _wall)
	_quad("SignBand", Vector2(0.380, 0.104), Vector3(0.0, 0.740, Z_MARK), SIGN_RED, _wall)
	## The pictogram, because the sources put a WORD here and a word is 5 px tall in this
	## frame. A cylinder body, a valve neck and a swung hose, in three white boxes.
	_quad("PictoBody", Vector2(0.034, 0.058), Vector3(-0.020, 0.736, Z_MARK2),
			BOARD_WHITE, _wall)
	_quad("PictoNeck", Vector2(0.014, 0.018), Vector3(-0.020, 0.774, Z_MARK2),
			BOARD_WHITE, _wall)
	_quad("PictoHose", Vector2(0.052, 0.010), Vector3(0.014, 0.766, Z_MARK2),
			BOARD_WHITE, _wall)
	_keep_clear()


## fire_extinguisher.gd:817-827 / fire_hose_box.gd:891-901 paint a rectangle on the floor
## you are not allowed to fill. This wall has no floor in shot, so the same instruction is
## carried as the hatched band at the wall's foot that a corridor actually gets.
func _keep_clear() -> void:
	for i in range(7):
		var fi: float = float(i)
		var pivot: Node3D = Node3D.new()
		pivot.name = "Hatch%d" % i
		pivot.position = Vector3(-0.240 + fi * 0.080, 0.118, Z_MARK)
		pivot.rotation.z = -0.61
		_wall.add_child(pivot)
		_quad("Bar", Vector2(0.026, 0.104), Vector3.ZERO, HAZARD, pivot)


## ABSORPTION. The face is already the architect's cabinetwork (FACE_COLOR); this adds the
## shadow-gap reveal at its head and the one small brushed plate where the shout was.
func _statute_joinery() -> void:
	_quad("Reveal", Vector2(FACE_SIZE.x, 0.014), Vector3(0.0, 0.762, Z_MARK), REVEAL, _wall)
	_quad("Plate", Vector2(0.118, 0.040), Vector3(FIT_X, 0.176, Z_MARK), PLATE_METAL, _wall)
	_quad("PlateInk", Vector2(0.094, 0.020), Vector3(FIT_X, 0.176, Z_MARK2), PLATE_INK, _wall)


## THE FABRIC LEFT TO ROT — and nothing else. The sources' _statute_lapse() also hangs a
## service tag reading "2019"; that half has moved to `currency`, which is the whole point
## of this bench. What is left here is chalked paint (FACE_COLOR), rust weeping from the
## two bracket fixings, and the grime that has climbed off the floor.
func _statute_lapse() -> void:
	var runs: Array = [[-0.058, 0.150], [-0.030, 0.096], [0.026, 0.132], [0.062, 0.078],
			[0.096, 0.114]]
	for i in range(runs.size()):
		var run: Array = runs[i]
		var dx: float = float(run[0])
		var h: float = float(run[1])
		_quad("Rust%d" % i, Vector2(0.011, h), Vector3(FIT_X + dx, 0.240 - h * 0.5, Z_MARK),
				RUST, _wall)
	_quad("Grime", Vector2(FACE_SIZE.x, 0.072), Vector3(0.0, 0.101, Z_MARK), GRIME, _wall)


# ── Axis 2: currency ──────────────────────────────────────────────────────────────────

## THE GHOST. The rectangle of wall the cylinder stood in front of for twenty years,
## painted in the wall's ORIGINAL colour — FACE_COLOR["issue"], not the current one. Under
## `statute: issue` that is the colour the wall still is, so the ghost contributes exactly
## zero pixels; under `lapse` it is the loudest mark on the sheet. An absence is only
## visible against a surface that has changed, which is why nobody notices a missing
## extinguisher in a building that is looked after.
func _build_ghost() -> void:
	_quad("Ghost", Vector2(0.230, 0.430), Vector3(FIT_X, CYL_Y, Z_GHOST),
			FACE_COLOR["issue"], _wall)


## The wall fixing, present in every cell — it is what makes `absent` read as absent
## rather than as a bare wall. The strap across it is closed when there is something to
## hold and hangs open when there is not.
func _build_bracket() -> void:
	_box("Bracket", Vector3(0.200, 0.100, 0.016), Vector3(FIT_X, 0.290, 0.020),
			STEEL, false, _wall)
	var pivot: Node3D = Node3D.new()
	pivot.name = "Strap"
	pivot.position = Vector3(FIT_X - 0.063, 0.250, 0.150)
	if currency == "absent":
		pivot.rotation.z = -1.35
	_wall.add_child(pivot)
	_box("StrapBar", Vector3(0.126, 0.020, 0.014), Vector3(0.063, 0.0, 0.0),
			BRIGHT_STEEL, false, pivot)


## The cylinder and its furniture. Only the body and the accent band answer to `statute` —
## the bracket, hose, neck, valve and handle are steel and black in the sources and stay
## that way here.
func _build_body() -> void:
	_cyl("Body", CYL_R, CYL_H, Vector3(FIT_X, CYL_Y, CYL_Z),
			_lv(BODY_RED), _lv_rough(0.35), _lv_metal(0.30))
	_cyl("Accent", CYL_R * 1.04, 0.020, Vector3(FIT_X, 0.375, CYL_Z),
			_ink(ACCENT_WHITE), 0.45, 0.15)
	_cyl("Neck", 0.026, 0.048, Vector3(FIT_X, 0.519, CYL_Z), STEEL, 0.45, 0.60)
	_cyl("Valve", 0.034, 0.026, Vector3(FIT_X, 0.556, CYL_Z), STEEL, 0.45, 0.60)
	_box("Handle", Vector3(0.088, 0.016, 0.024), Vector3(FIT_X, 0.577, CYL_Z),
			DARK_STEEL, false, _wall)
	## The hose: three fixed segments swinging off the valve, away from the record card.
	var segs: Array = [[0.086, 0.520, 1.05], [0.044, 0.462, 0.52], [0.024, 0.392, 0.14]]
	for i in range(segs.size()):
		var seg: Array = segs[i]
		var pivot: Node3D = Node3D.new()
		pivot.name = "HoseSeg%d" % i
		pivot.position = Vector3(float(seg[0]), float(seg[1]), CYL_Z)
		pivot.rotation.z = float(seg[2])
		_wall.add_child(pivot)
		_cyl("Tube", 0.010, 0.080, Vector3.ZERO, HOSE_BLACK, 0.60, 0.0, pivot)
	_cyl("Nozzle", 0.013, 0.032, Vector3(0.020, 0.348, CYL_Z), DARK_STEEL, 0.40, 0.70)


## THE GAUGE — is it charged? A lit steel bezel and an unshaded dial: the green sector
## across the top, the red one down at the left, and a needle whose angle is the whole
## reading. The dial is an INSTRUMENT and is deliberately NOT routed through _ink(): the
## building's decorator does not get to repaint a pressure gauge, and if it did, the
## `discharged` reading would go with it and this axis would have one fewer question.
func _build_gauge() -> void:
	_cyl("Bezel", GAUGE_R, 0.006, Vector3(FIT_X, GAUGE_Y, GAUGE_Z), BRIGHT_STEEL, 0.35, 0.80,
			_wall, true)
	var face: Node3D = Node3D.new()
	face.name = "Dial"
	face.position = Vector3(FIT_X, GAUGE_Y, GAUGE_Z + 0.004)
	_wall.add_child(face)
	_disc("DialFace", 0.033, Vector3.ZERO, DIAL_FACE, face)
	for i in range(9):
		var fi: float = float(i)
		_tick(face, -0.70 + fi * 0.175, 0.026, DIAL_GREEN, "G%d" % i)
	for i in range(6):
		var fj: float = float(i)
		_tick(face, 1.75 + fj * 0.14, 0.026, DIAL_RED, "R%d" % i)
	var needle: Node3D = Node3D.new()
	needle.name = "Needle"
	needle.position = Vector3(0.0, 0.0, 0.0012)
	if currency == "discharged":
		needle.rotation.z = 2.10
	face.add_child(needle)
	_quad("NeedleBar", Vector2(0.005, 0.050), Vector3(0.0, 0.021, 0.0), NEEDLE, needle)
	_disc("Hub", 0.008, Vector3(0.0, 0.0, 0.0018), NEEDLE, face)


## THE TAMPER SEAL — has it been fired? An intact plastic tie through the handle, or the
## two stubs left when somebody pulled the pin. Not routed through _ink() for the same
## reason as the gauge: it is physical evidence, not signage.
func _build_seal() -> void:
	if currency == "discharged":
		for i in range(2):
			var fi: float = float(i)
			var pivot: Node3D = Node3D.new()
			pivot.name = "SealStub%d" % i
			pivot.position = Vector3(FIT_X - 0.016 + fi * 0.032, 0.566, 0.128)
			pivot.rotation.z = -0.55 + fi * 1.10
			_wall.add_child(pivot)
			_box("Stub", Vector3(0.006, 0.024, 0.006), Vector3.ZERO, SEAL_TIE, false, pivot)
		return
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.name = "Seal"
	var tm: TorusMesh = TorusMesh.new()
	tm.inner_radius = 0.014
	tm.outer_radius = 0.022
	tm.rings = 24
	tm.ring_segments = 10
	ring.mesh = tm
	ring.rotation.x = PI * 0.5
	ring.position = Vector3(FIT_X, 0.566, 0.128)
	ring.material_override = _mat(SEAL_TIE, false, 0.5, 0.05)
	_wall.add_child(ring)


## THE RECORD — is it in date? A framed service card on the wall beside the fitting, its
## head band carrying the inspection cycle's colour. It is the building's paperwork, not
## the device's, so it survives `absent` and goes on certifying an empty bracket. And it
## IS routed through _ink(), unlike the gauge and the seal: a decorator who reframes a
## corridor takes the record card with it, and under `joinery` that is exactly what
## happens — ink_amt 1.0 flattens green and amber onto the same greige.
func _build_record() -> void:
	_quad("CardFrame", Vector2(CARD_SIZE.x + 0.016, CARD_SIZE.y + 0.016),
			Vector3(CARD_X, CARD_Y, Z_CARD), CARD_FRAME, _wall)
	_quad("CardFace", CARD_SIZE, Vector3(CARD_X, CARD_Y, Z_CARDF),
			_ink(CARD_STOCK), _wall)
	_quad("CycleBand", BAND_SIZE, Vector3(CARD_X, BAND_Y, Z_CYCLE),
			_ink(_cycle_color()), _wall)
	for i in range(8):
		var fi: float = float(i)
		_quad("Punch%d" % i, Vector2(0.017, 0.017),
				Vector3(CARD_X + (fi - 3.5) * 0.024, 0.205, Z_CYCLE), _ink(CARD_PUNCH), _wall)


# ── Primitives ────────────────────────────────────────────────────────────────────────

func _tick(parent: Node3D, angle: float, radius: float, col: Color, nm: String) -> void:
	var pivot: Node3D = Node3D.new()
	pivot.name = nm
	pivot.rotation.z = angle
	pivot.position = Vector3(0.0, 0.0, 0.0008)
	parent.add_child(pivot)
	_quad("T", Vector2(0.006, 0.011), Vector3(0.0, radius, 0.0), col, pivot)


func _box(nm: String, size: Vector3, pos: Vector3, col: Color, flat: bool,
		parent: Node3D) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = nm
	var m: BoxMesh = BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.position = pos
	mi.material_override = _mat(col, flat, 0.85, 0.0)
	parent.add_child(mi)


## Every mark painted ON the wall is one of these: an unshaded quad facing +Z.
func _quad(nm: String, size: Vector2, pos: Vector3, col: Color, parent: Node3D) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = nm
	var m: QuadMesh = QuadMesh.new()
	m.size = size
	mi.mesh = m
	mi.position = pos
	mi.material_override = _mat(col, true, 0.85, 0.0)
	parent.add_child(mi)


func _disc(nm: String, radius: float, pos: Vector3, col: Color, parent: Node3D) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = nm
	var m: CylinderMesh = CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = 0.0008
	m.radial_segments = 64
	m.rings = 0
	mi.mesh = m
	mi.position = pos
	mi.rotation.x = PI * 0.5
	mi.material_override = _mat(col, true, 0.85, 0.0)
	parent.add_child(mi)


func _cyl(nm: String, radius: float, height: float, pos: Vector3, col: Color,
		rough: float, metal: float, parent: Node3D = null, lie_flat: bool = false) -> void:
	var host: Node3D = parent
	if host == null:
		host = _wall
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = nm
	var m: CylinderMesh = CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = 32
	mi.mesh = m
	mi.position = pos
	if lie_flat:
		mi.rotation.x = PI * 0.5
	mi.material_override = _mat(col, false, rough, metal)
	host.add_child(mi)


func _mat(col: Color, flat: bool, rough: float, metal: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = col
	if flat:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	else:
		m.roughness = rough
		m.metallic = metal
	return m


# ── Map config ────────────────────────────────────────────────────────────────────────

## Config from map_data.json tokens:  statute_fitting#statute:lapse#currency:overdue
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("statute"):
		statute = str(config_data["statute"])
	if config_data.has("currency"):
		currency = str(config_data["currency"])
	_bulk = false
	if is_inside_tree():
		_rebuild()


## The declaration gate reads the @export_enum hint; the builder reads the const. If they
## ever drift, every frame in a sweep is a fact about which of the two a given tool
## trusted — science_screen's whole failure, sixteen identical frames and a confident
## INERT verdict about a typo.
func _check_hints() -> void:
	var pairs: Array = [["statute", STATUTES], ["currency", CURRENCIES]]
	for entry in pairs:
		var key: String = str(entry[0])
		var want: PackedStringArray = entry[1]
		for prop in get_property_list():
			if String(prop.get("name", "")) != key:
				continue
			var got: PackedStringArray = String(prop.get("hint_string", "")).split(",")
			if got != want:
				push_warning("statute_fitting: %s hint %s != const %s" % [key, got, want])
