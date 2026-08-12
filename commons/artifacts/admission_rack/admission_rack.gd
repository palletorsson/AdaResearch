extends Node3D
class_name AdmissionRack

## Admission Rack — a SYNTHESIS artifact. One object, four bays, four institutional
## statuses, and an axis that asks WHERE the status is actually kept.
##
## @identity
## essence: A 2.94 m rack with one bay per value of the family word `admission` —
##   none, bench, residue, exhibit — each bay holding the SAME vessel. All four
##   statuses stand at once, because they are parallel readings and not a ladder.
##   What turns is `carrier`: whether the four are told apart by marks on the
##   OBJECT, by the state of the HOUSING, by both at once, or by neither — in
##   which case the only thing that differs between the four bays is the code
##   plate screwed to the rail.
## desire: to be read across, bay to bay, and then read again at another value of
##   `carrier` — because the same four bays that were obviously different a moment
##   ago become four identical vessels on four identical shelves with four
##   different filing codes underneath them.
## critical_parameter: `carrier` — where institutional status is carried. The rack,
##   the bay order, the vessel and the four code plates never move.
## triggers: none. No _process, no timer, no random number, no physics, no light.
##   Everything is computed once in _plan() and drawn.
## emerges: bay 1 (`none`) is identical at every value of the axis and cannot be
##   otherwise — it is the null of both dimensions, nothing on the thing and
##   nothing in the housing. The bay for "not in the collection" is the one bay no
##   theory of status can touch.
## needs: one vessel profile evaluated once [has, _vessel_radius]; four bays built
##   from the OWNER's value list rather than a retyped one [has, Admission.ADMISSIONS];
##   marks gauged to the rack and not to the vessel [has, see the px table]; no
##   randf anywhere [has]
## relationships: builds on the fourteen artifacts that declare `admission` — the
##   GlassRack family, [[chemicalapparatus]] and [[samplevialrack]] — and takes its
##   dressing vocabulary and its exact mark colours out of [[GlassRack]]'s
##   controller rather than inventing a second palette for the same words.
## truth: whether a thing is stock, work, waste or evidence is not a fact you can
##   read off the thing. Four of these bays claim you can. One of them says the
##   claim is a card in a slot, and that bay is not obviously wrong.

# ═══════════════════════════════════════════════════════════════════════════
# SYNTHESIS DNA — `carrier`
# ═══════════════════════════════════════════════════════════════════════════
#
# BORN PROMOTED. This artifact did not exist before this pass and has zero
# placements, so the preservation rule that outranks everything in
# doc/DNA_PROMOTION_BRIEF.md has no work to do here. The default was chosen as
# the STRONGEST single reading, not the emptiest.
#
# ── LAW 2: NEST OR SIDE BY SIDE, and this one was decided by reading the
#    owner's code rather than by taste ──────────────────────────────────────
#
# `admission`'s four values sit SIDE BY SIDE. They are four parallel institutional
# statuses, mutually exclusive at any one moment and none of them containing the
# one before it: `none` is not a subset of `bench`, `residue` is not bench-plus,
# and `exhibit`'s seals REPLACE rather than accumulate on residue's crust.
#
# The evidence is in GlassRackController._dress_admission(), which is a `match`
# with three exclusive branches — _admission_bench, _admission_residue,
# _admission_exhibit — each building its own complete dressing set, and NOT ONE
# OF THEM CALLS ANOTHER. A nesting vocabulary would have `exhibit` run residue's
# crust first and then add its tags. It does not. That is a measured fact about
# the family's own implementation and it settles the question.
#
# So this rack does what retention_corridor does with its five parallel regimes:
# it holds ALL FOUR STANDING and varies something else. Showing all four at once
# is not "just the top value" here, because there is no top.
#
# ── THE AXIS ───────────────────────────────────────────────────────────────
#
#   carrier   WHERE THE STATUS IS CARRIED    housing · object · neither · both
#
#   housing   the four vessels are identical and pristine; the four BAYS differ.
#             Bay 2 is a working bench — pegboard, retort stand, two boss clamps,
#             hung tools, a scrawled note. Bay 3 has kept the record itself — a
#             stained shelf, a ring where the vessel stood, a tide band across the
#             back panel with runs down from it, an old label gone illegible.
#             Bay 4 is a vitrine — posts, glass on three sides, a cap, an
#             accession card with a barcode. Status is conferred by the setting.
#   object    the four BAYS are identical bare shelves; the four vessels differ.
#             Masking tape and a hand-drawn level and a stirring rod; crust, a
#             tide ring, an opaque etched band, runs down the outside; an orange
#             seal, an accession label, a wired tag. Status is intrinsic and
#             legible off the thing.
#   neither   four identical vessels on four identical shelves. The ONLY thing
#             that differs between the bays is the code plate on the rail. Status
#             is pure nomination.
#   both      the thing and its setting agree — the museum's own account of
#             itself: we accession what already shows what it is.
#
# The four are a 2x2 lattice (object-carries x housing-carries) and are therefore
# EXHAUSTIVE by construction rather than by taste. `neither` and `both` are its
# bottom and top and `object` and `housing` are incomparable, so the four cannot
# all be shown at once the way the four admissions can — which is exactly why
# this is the axis and admission is the exhibit.
#
# ── DEFAULT: housing (LAW 11) ──────────────────────────────────────────────
#
# It is the artifact's own claim — admission is a property of the housing — and
# it is the reading that makes the rack legible to somebody who never touches the
# knob: four identical vessels, four different bays, four different statuses.
# `neither` is the sharper frame and the worse default, because placed blind it
# is four identical vessels and no visible argument at all. `both` is the fullest
# picture and the weakest one, because when everything agrees nothing is being
# claimed.
#
# ── LAW 4: MARKS GAUGED TO THE RACK, NOT TO THE VESSEL ─────────────────────
#
# sorting_hall drew its gauge three pixels wide in a 760 px frame. At dna.framing
# 0.56 this rack is 219.5 px per metre (arithmetic in the registry), so:
#
#   code plate            0.300 x 0.110 m   ->  66 x 24 px   (x0.81 in yaw: 54 px)
#   code slot             0.055 x 0.050 m   ->  12 x 11 px
#   etched band (residue) 0.285 x 0.200 m   ->  63 x 44 px
#   masking tape (bench)  0.293 x 0.075 m   ->  64 x 16 px
#   hung tag  (exhibit)   0.170 x 0.120 m   ->  37 x 26 px
#   accession label       0.160 x 0.110 m   ->  35 x 24 px
#   drips, straps, bars   0.026 - 0.030 m   ->  5.7 - 6.6 px
#   retort rod / posts    0.028 - 0.032 m   ->  6.1 - 7.0 px
#
# Nothing that carries a claim is under 16 px and nothing at all is under 5.7 px.
# Every one of those numbers was raised from a first draft that failed this test.
#
# ── LAW 5: NO FRAME-RELATIVE NORMALISATION ─────────────────────────────────
#
# The one gauge here is the code plate, and its ceiling is FIXED at the family's
# whole vocabulary: n slots for n values, exactly one filled, every plate the same
# width and every plate the same quantity of ink. It is a CHECKBOX ROW and not a
# bar, deliberately, because a bar whose length grew with the bay index would draw
# these four parallel statuses as a ladder and quietly contradict LAW 2 above.
#
# ── LAW 8: DETERMINISM ─────────────────────────────────────────────────────
#
# No randf, no randi, no randomize, no _process, no _physics_process, no Timer, no
# Light3D, no collision body. Every position in this file is index arithmetic over
# constants. Two captures of one value are two photographs of one object.
#
# ── LAW 3: ONE COPY OF THE ARITHMETIC ──────────────────────────────────────
#
# _plan() runs once and fills _bays (x, sill, status, slot index) and _mat. The
# vessel's silhouette exists ONCE, as VESSEL plus _vessel_radius(); the clamp
# reach, the collar radii, the band radii and the strap offsets are all read out
# of that one function rather than recomputed per drawing routine.

# ─────────────────────────────────────────────────────────────────────────────
# THE FAMILY'S WORD, READ FROM THE FILE THAT OWNS IT
# ─────────────────────────────────────────────────────────────────────────────
## GlassRackController holds `const ADMISSIONS := ["none","bench","residue","exhibit"]`
## and fourteen registry entries declare that list. It is NOT retyped here. The bay
## count, the bay order and the bay statuses are all read from this preload, so the
## rack cannot drift from the family and would grow a fifth bay on its own if the
## family ever grew a fifth value. Preloaded rather than reached through class_name
## because class_name lookups have proved unreliable headless, and every frame of
## the evidence loop is rendered headless — the pattern nine `disclosure` artifacts
## already use on prng_crank_machine.
const Admission = preload("res://commons/glass_rack/GlassRackController.gd")
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

## THE STATUSES THIS RACK CAN ACTUALLY BUILD. This is NOT a second copy of the
## vocabulary — the vocabulary is Admission.ADMISSIONS and it is never retyped. This
## is the rack's own CAPABILITY list, and it exists to be checked against the owner's,
## which is the divergence LAW 1 asks for and which the first draft of this file did
## not perform. `_dress_bay` and `_mark_vessel` are both a `match` on three literal
## branch names plus a default; if the family ever adds `loan` or `deaccessioned` to
## ADMISSIONS, _plan() would lay out a fifth bay, _build_code_plate would give it a
## fifth slot and a filled code, and BOTH matches would fall through to `pass`. The
## rack would then exhibit a status with no dressing at any value of the axis: an
## empty niche presented as an institutional position, and — worse for the evidence
## loop — a bay that is identical at all four values, which would drag every focus
## number down while looking like a finding about `carrier`. `none` is in this list
## deliberately: it is dressed by building nothing, which is a real branch and the
## artifact's own argument about bay 1, not a gap.
const DRESSABLE: PackedStringArray = ["none", "bench", "residue", "exhibit"]

@export_group("DNA")
## AXIS — WHERE INSTITUTIONAL STATUS IS CARRIED. See the block above. Declared
## default-first, then in DESCENDING separation from the default, so a sweep
## truncated from the tail drops the weakest pair (`housing` against `both`,
## which differ by the object marks alone) rather than the strongest.
@export_enum("housing", "object", "neither", "both") var carrier: String = "housing"

## The export hint's four words, mirrored. GDScript requires the @export_enum hint
## to be string literals, so this copy is unavoidable; it is the axis's OWN
## vocabulary rather than a borrowed one, so there is no owner to check it against
## — but _pick_carrier tests membership against THIS list and _ready checks the
## borrowed list (ADMISSIONS) against its owner, which is where drift could happen.
const CARRIERS: PackedStringArray = ["housing", "object", "neither", "both"]

@export_group("Rack")
## Bay interior width. The rack's total width is derived, never set.
@export var bay_width: float = 0.66
## Bay interior height, sill to soffit.
@export var bay_height: float = 0.86

# ── Chassis constants ────────────────────────────────────────────────────────
const PIER: float = 0.06          # divider thickness, and the two end walls
const BAY_D: float = 0.44         # bay interior depth
const BACK_T: float = 0.06        # back panel thickness
const BASE_H: float = 0.34        # plinth under the bays; the code plates live on its face
const TOP_H: float = 0.10         # top rail
const PLATE_W: float = 0.30       # code plate
const PLATE_H: float = 0.11
const SLOT_GAP: float = 0.024

# ── The vessel, defined ONCE ─────────────────────────────────────────────────
## Bottom-up profile of the one object every bay holds: height, bottom radius, top
## radius. Total height 0.670 m, widest diameter 0.290 m. Every mark in this file
## that has to sit ON the vessel asks _vessel_radius() for the radius at its own
## height rather than assuming 0.140 — which is what stops a collar at shoulder
## height standing off the glass as a free-floating disc, the exact fault
## GlassRackController documents in _admission_radius.
const VESSEL: Array = [
	{"h": 0.014, "rb": 0.145, "rt": 0.145},   # foot flare   0.000 - 0.014
	{"h": 0.320, "rb": 0.140, "rt": 0.140},   # body         0.014 - 0.334
	{"h": 0.160, "rb": 0.140, "rt": 0.048},   # shoulder     0.334 - 0.494
	{"h": 0.160, "rb": 0.048, "rt": 0.048},   # neck         0.494 - 0.654
	{"h": 0.016, "rb": 0.058, "rt": 0.058},   # lip          0.654 - 0.670
]
const VESSEL_Z: float = 0.01      # where the vessel stands in the bay's depth

## Heights ON THE VESSEL, in its own coordinates, that marks and clamps attach to.
## Named once so the housing side and the object side cannot drift apart, because at
## carrier=both the bench bay is the ONE place where a housing mark and an object
## mark share a surface — the clamps grip the same glass the tape is wrapped round.
##
## THE FIRST DRAFT COLLIDED AND THE COMMENT HERE SAID IT DID NOT. Measured: the
## lower boss clamp's jaw occupies vessel-local y 0.1060..0.1340 and reaches in to
## x 0.1285 at z +-0.045; a tape collar at 0.105 spans y 0.0825..0.1275 with an
## outer surface at x 0.13942 there. That is 0.0215 m of vertical overlap and
## 0.01092 m of interpenetration — 2.4 px at this artifact's framing, which is
## exactly the size of thing a capture does not show you and a comment can go on
## denying forever. The lower tape moved to 0.070, clearing the jaw by 0.0135 m and
## the foot flare by 0.0335 m.
##
## IT COST NOTHING TO MOVE, and that is checkable rather than asserted: 0.070 and
## 0.105 both fall inside VESSEL's straight body segment (0.014..0.334, rb = rt =
## 0.140), so _vessel_radius returns 0.140 at both and the collar's front-projected
## silhouette is 0.013185 m2 either way — bit-identical. Every area in dna.still_note
## and every contrast in dna.predicted_degeneracy stands unchanged.
##
## The repair matters to the AXIS and not only to the picture: the two object-only
## pairs (neither<->object and housing<->both) are supposed to differ by the object
## marks and by nothing else, and a jaw eating a collar at `both` and not at
## `object` would have put a second, undeclared difference inside the pair the
## prediction is about.
const CLAMP_Y: PackedFloat32Array = [0.120, 0.400]
const TAPE_Y: PackedFloat32Array = [0.245, 0.070]
const TAPE_H: PackedFloat32Array = [0.075, 0.045]

# ── Colours, read out of GlassRackController's three dressing routines ───────
# Same words, same palette. A lab whose bench tape is one cream and whose rack's
# bench tape is another is two vocabularies wearing one word. Verified pair by
# pair against _admission_bench, _admission_residue and _admission_exhibit,
# roughness and metallic included: steel .35/.85, tape .85/0, ink .80/0, crust
# .97/0, tide .92/0, frost 1.0/0, card .85/0, wire .40/.80, seal .70/0.
#
# ONE DIVERGENCE, AND IT IS THE OWNER'S, NOT A TRANSCRIPTION SLIP. GlassRackController
# has TWO inks: _admission_bench writes Color(0.10, 0.10, 0.13) and _admission_exhibit
# writes Color(0.09, 0.09, 0.12). This rack carries one. The two differ by 0.01 in
# each channel — 2.55 grey levels of 255, invisible at any framing and on any
# display — so a second const here would be a difference nobody can see, declared
# as though it meant something. Said out loud instead of quietly averaged, because
# a shared vocabulary is only honest if the places it does NOT hold are on the
# record. If the owner ever means those two inks differently, this is the line
# that has to change.
const C_STEEL := Color(0.60, 0.62, 0.66)
const C_TAPE := Color(0.94, 0.92, 0.84)
const C_INK := Color(0.10, 0.10, 0.13)
const C_CRUST := Color(0.22, 0.17, 0.09)
const C_TIDE := Color(0.38, 0.30, 0.16)
const C_FROST := Color(0.80, 0.82, 0.79)
const C_CARD := Color(0.91, 0.89, 0.81)
const C_WIRE := Color(0.58, 0.58, 0.62)
const C_SEAL := Color(0.82, 0.30, 0.14)
const C_GLASS := Color(0.85, 0.92, 1.0, 0.25)

const ROOT_NAME := "Rack"

var _bays: Array = []
var _mat: Dictionary = {}
var _built: bool = false
var _total_w: float = 0.0
var _total_h: float = 0.0
var _front_z: float = 0.0


func _ready() -> void:
	_read_config_meta()
	_check_borrowed_vocabulary()
	_build()


## The grid stamps config_<key> metadata BEFORE add_child, so this is readable from
## _ready(). An unknown word keeps the default rather than blanking the axis.
func _read_config_meta() -> void:
	if has_meta("config_carrier"):
		carrier = _pick_carrier(str(get_meta("config_carrier")))


func _pick_carrier(raw: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	if CARRIERS.has(v):
		return v
	if v != "":
		push_warning("admission_rack: unknown carrier '%s' — keeping '%s'" % [v, carrier])
	return carrier


## The bay vocabulary is BORROWED, so it gets checked rather than trusted. If
## GlassRackController's ADMISSIONS ever changes shape this rack says so out loud at
## build time instead of silently exhibiting a vocabulary nobody uses.
##
## THE THIRD CHECK IS THE ONE THAT MATTERS and the first draft of this file was
## missing it. Size and emptiness are cheap; the failure that would actually ship is
## the family GAINING a value. The rack would build the extra bay's chassis and code
## plate from ADMISSIONS and then find no branch for it in either match — an empty
## niche, identical at all four values of `carrier`, quietly flattening every number
## the evidence loop produces. A push_error naming the exact word is the difference
## between a five-minute fix and a puzzling capture.
func _check_borrowed_vocabulary() -> void:
	var owner_list: PackedStringArray = Admission.ADMISSIONS
	if owner_list.size() < 2:
		push_error("admission_rack: GlassRackController.ADMISSIONS is %d long — "
			% owner_list.size() + "the rack has nothing to exhibit.")
	var undressable := PackedStringArray()
	for w in owner_list:
		var s: String = String(w).strip_edges()
		if s == "":
			push_error("admission_rack: GlassRackController.ADMISSIONS contains an empty value.")
		elif not DRESSABLE.has(s):
			undressable.append(s)
	if undressable.size() > 0:
		push_error("admission_rack: GlassRackController.ADMISSIONS has grown %s, which "
			% str(undressable) + "this rack has no dressing for. Those bays will be "
			+ "built empty at EVERY value of `carrier` and will read as a dead axis. "
			+ "Add a branch to _dress_bay and _mark_vessel, or the family and the "
			+ "synthesis have silently forked.")


func apply_grid_config(config: Dictionary) -> void:
	# Rebuild ONLY when a value this artifact owns actually CHANGED, and only after
	# _ready has built once. force_pad tore itself down on any call at all.
	var dirty: bool = false
	if config.has("carrier"):
		var next: String = _pick_carrier(str(config["carrier"]))
		if next != carrier:
			carrier = next
			dirty = true
	if config.has("bay_width"):
		var bw: float = float(config["bay_width"])
		if bw > 0.2 and not is_equal_approx(bw, bay_width):
			bay_width = bw
			dirty = true
	if config.has("bay_height"):
		var bh: float = float(config["bay_height"])
		if bh > 0.3 and not is_equal_approx(bh, bay_height):
			bay_height = bh
			dirty = true
	if dirty and _built:
		_build()


# ═══════════════════════════════════════════════════════════════════════════
# PLAN — the only place any of these numbers is computed
# ═══════════════════════════════════════════════════════════════════════════

func _plan() -> void:
	# THE DRESSING IS DRAWN IN METRES, so the bay it is drawn into has a range.
	# Every in-bay offset in this file was checked against the pier faces at the
	# shipped 0.66: the furthest is residue's corner crust at cx +- 0.305 against an
	# interior half-width of 0.330. Below 0.64 those offsets start punching through
	# the piers, which would be invisible in the editor and obvious in a capture.
	if bay_width < 0.64 or bay_width > 0.90:
		push_warning("admission_rack: bay_width %.3f is outside [0.64, 0.90] — clamped."
			% bay_width)
		bay_width = clampf(bay_width, 0.64, 0.90)
	if bay_height < 0.80 or bay_height > 1.20:
		push_warning("admission_rack: bay_height %.3f is outside [0.80, 1.20] — clamped."
			% bay_height)
		bay_height = clampf(bay_height, 0.80, 1.20)

	var statuses: PackedStringArray = Admission.ADMISSIONS
	var n: int = statuses.size()
	_total_w = float(n) * bay_width + float(n + 1) * PIER
	_total_h = BASE_H + bay_height + TOP_H
	_front_z = (BAY_D + BACK_T) * 0.5

	_bays.clear()
	for i in range(n):
		_bays.append({
			"status": String(statuses[i]),
			"index": i,
			"count": n,
			"x": -_total_w * 0.5 + PIER + bay_width * 0.5 + float(i) * (bay_width + PIER),
			"sill": BASE_H,
		})

	_mat = {
		"shell": HangarKit.painted_metal(HangarKit.BODY_LIGHT, 0.10, 0.30, 0.60),
		"trim": HangarKit.painted_metal(HangarKit.PANEL_TRIM, 0.12, 0.30, 0.64),
		# THE BAY INTERIOR IS DARKER THAN THE SHELL, and it is a legibility decision
		# rather than a style one. Every mark this artifact draws on the vessel is a
		# PALE mark — cream masking tape, the opaque etched band, the accession
		# label, the hung tag. Against a pale back panel the etched band measured
		# roughly 30 grey levels of contrast, and it is the family's own pivot mark:
		# the one dressing that destroys the transparency the whole vocabulary is
		# built on. At 0.34 grey behind it, that mark stands at about 100 levels and
		# is legible to a visitor as well as to the bench. Pale shell, dark niche is
		# also just what a display rack looks like.
		"niche": HangarKit.painted_metal(Color(0.34, 0.33, 0.32), 0.14, 0.25, 0.66),
		"dark": HangarKit.painted_metal(Color(0.16, 0.16, 0.18), 0.10, 0.35, 0.55),
		"accent": HangarKit.emissive(HangarKit.BRAUN_ACCENT, 1.4),
		"steel": _mk(C_STEEL, 0.35, 0.85),
		"tape": _mk(C_TAPE, 0.85, 0.0),
		"ink": _mk(C_INK, 0.80, 0.0),
		"crust": _mk(C_CRUST, 0.97, 0.0),
		"tide": _mk(C_TIDE, 0.92, 0.0),
		"frost": _mk(C_FROST, 1.00, 0.0),
		"card": _mk(C_CARD, 0.85, 0.0),
		"wire": _mk(C_WIRE, 0.40, 0.80),
		"seal": _mk(C_SEAL, 0.70, 0.0),
		"slot_off": _mk(Color(0.62, 0.61, 0.58), 0.80, 0.0),
		"glass": _mk_glass(C_GLASS),
		"pane": _mk_glass(Color(0.86, 0.90, 0.94, 0.18)),
	}


## The vessel's radius at a height above its own foot. ONE copy of the profile.
func _vessel_radius(local_y: float) -> float:
	var y0: float = 0.0
	for seg in VESSEL:
		var h: float = float(seg["h"])
		if local_y <= y0 + h:
			var t: float = clampf((local_y - y0) / maxf(h, 0.0001), 0.0, 1.0)
			return lerpf(float(seg["rb"]), float(seg["rt"]), t)
		y0 += h
	return float(VESSEL[VESSEL.size() - 1]["rt"])


# ═══════════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════════

func _build() -> void:
	var old: Node = get_node_or_null(ROOT_NAME)
	if old:
		remove_child(old)
		old.queue_free()

	_plan()

	var root := Node3D.new()
	root.name = ROOT_NAME
	add_child(root)

	# Where the status is allowed to show. The whole axis is these two booleans.
	var on_object: bool = carrier == "object" or carrier == "both"
	var on_housing: bool = carrier == "housing" or carrier == "both"

	_build_chassis(root)
	for b in _bays:
		var bay: Dictionary = b
		_build_code_plate(root, bay)               # ALWAYS — the institution always says the word
		if on_housing:
			_dress_bay(root, bay)
		_build_vessel(root, bay)
		if on_object:
			_mark_vessel(root, bay)

	_built = true


func _build_chassis(root: Node3D) -> void:
	var shell: Material = _mat["shell"]
	var dark: Material = _mat["dark"]
	var depth: float = BAY_D + BACK_T
	var bay_mid: float = BASE_H + bay_height * 0.5
	var bay_cz: float = _front_z - BAY_D * 0.5

	# Recessed foot reveal, then the plinth the code plates are screwed to.
	root.add_child(HangarKit.box(Vector3(0.0, 0.015, 0.0),
		Vector3(_total_w - 0.05, 0.03, depth - 0.04), dark))
	root.add_child(HangarKit.box(Vector3(0.0, 0.03 + (BASE_H - 0.03) * 0.5, 0.0),
		Vector3(_total_w, BASE_H - 0.03, depth), shell))
	# Back panel, top rail, and the piers between the bays.
	root.add_child(HangarKit.box(Vector3(0.0, bay_mid, -_front_z + BACK_T * 0.5),
		Vector3(_total_w, bay_height, BACK_T), _mat["niche"]))
	root.add_child(HangarKit.box(Vector3(0.0, BASE_H + bay_height + TOP_H * 0.5, 0.0),
		Vector3(_total_w, TOP_H, depth), shell))
	var n: int = _bays.size()
	for i in range(n + 1):
		var px: float = -_total_w * 0.5 + PIER * 0.5 + float(i) * (bay_width + PIER)
		root.add_child(HangarKit.box(Vector3(px, bay_mid, bay_cz),
			Vector3(PIER, bay_height, BAY_D), shell))
	# One lit accent line under the top rail — CONSTANT at every value of the axis,
	# so the brightest pixels in the frame never move with the knob.
	root.add_child(HangarKit.box(Vector3(0.0, BASE_H + bay_height - 0.012, _front_z + 0.004),
		Vector3(_total_w - 0.02, 0.014, 0.008), _mat["accent"]))
	# The soffit each bay looks up into, and the shelf each vessel stands on.
	root.add_child(HangarKit.box(Vector3(0.0, BASE_H - 0.008, bay_cz),
		Vector3(_total_w, 0.016, BAY_D), _mat["niche"]))
	root.add_child(HangarKit.box(Vector3(0.0, BASE_H + bay_height - 0.008, bay_cz),
		Vector3(_total_w, 0.016, BAY_D), _mat["niche"]))


## The code plate: n slots, one per value of the family vocabulary, exactly one
## filled. FIXED CEILING (LAW 5) and equal ink on every plate, because these four
## statuses are parallel and a plate whose ink grew with the index would draw them
## as a ladder. This is the ONLY thing that distinguishes the bays at carrier=neither.
func _build_code_plate(root: Node3D, bay: Dictionary) -> void:
	var cx: float = float(bay["x"])
	var idx: int = int(bay["index"])
	var n: int = int(bay["count"])
	var z: float = _front_z + 0.005
	root.add_child(HangarKit.box(Vector3(cx, 0.175, z), Vector3(PLATE_W, PLATE_H, 0.010),
		_mat["card"]))
	var avail: float = PLATE_W - 0.008
	var slot_w: float = (avail - float(n - 1) * SLOT_GAP) / float(n)
	var x0: float = cx - avail * 0.5 + slot_w * 0.5
	for j in range(n):
		var sx: float = x0 + float(j) * (slot_w + SLOT_GAP)
		var mat: Material = _mat["ink"] if j == idx else _mat["slot_off"]
		root.add_child(HangarKit.box(Vector3(sx, 0.170, z + 0.006),
			Vector3(slot_w, 0.050, 0.004), mat))


## The one object, identical in every bay and at every value of the axis. It never
## moves: no housing dressing is allowed under it, so the "object marks only" pairs
## differ by the marks and by nothing else.
func _build_vessel(root: Node3D, bay: Dictionary) -> void:
	var cx: float = float(bay["x"])
	var sill: float = float(bay["sill"])
	var y: float = 0.0
	for seg in VESSEL:
		var h: float = float(seg["h"])
		root.add_child(_cone(Vector3(cx, sill + y + h * 0.5, VESSEL_Z),
			float(seg["rb"]), float(seg["rt"]), h, _mat["glass"]))
		y += h


# ═══════════════════════════════════════════════════════════════════════════
# THE HOUSING SIDE — what the BAY says about the thing standing in it
# ═══════════════════════════════════════════════════════════════════════════

func _dress_bay(root: Node3D, bay: Dictionary) -> void:
	match String(bay["status"]):
		"bench":
			_bay_bench(root, bay)
		"residue":
			_bay_residue(root, bay)
		"exhibit":
			_bay_exhibit(root, bay)
		_:
			# `none` — the thing is not in the collection, so the housing confers
			# nothing and builds nothing. This is why bay 1 is identical at every
			# value of the axis: it is the null of both dimensions.
			pass


## BENCH — the bay is somebody's working position. Pegboard back, retort stand,
## two boss clamps reaching in at the radii the vessel actually has there, hung
## tools, a scrawled note and a marker left on the shelf.
func _bay_bench(root: Node3D, bay: Dictionary) -> void:
	var cx: float = float(bay["x"])
	var sill: float = float(bay["sill"])
	var back: float = -_front_z + BACK_T + 0.005
	var steel: Material = _mat["steel"]

	# Pegboard over the bay's back panel.
	root.add_child(HangarKit.box(Vector3(cx, sill + 0.44, back),
		Vector3(bay_width - 0.04, 0.66, 0.010), _mat["trim"]))
	for row in range(4):
		for col in range(6):
			root.add_child(HangarKit.box(
				Vector3(cx - 0.25 + 0.10 * float(col), sill + 0.20 + 0.16 * float(row), back + 0.006),
				Vector3(0.024, 0.024, 0.004), _mat["dark"]))
	# Three tools hung on it.
	for t in range(3):
		var tx: float = cx - 0.20 + 0.20 * float(t)
		var tl: float = 0.20 - 0.02 * float(t)
		root.add_child(HangarKit.box(Vector3(tx, sill + 0.70 - tl * 0.5, back + 0.014),
			Vector3(0.030, tl, 0.012), steel))
	# The scrawled note, taped on.
	root.add_child(HangarKit.box(Vector3(cx + 0.17, sill + 0.30, back + 0.010),
		Vector3(0.20, 0.15, 0.006), _mat["tape"]))
	for k in range(3):
		root.add_child(HangarKit.box(Vector3(cx + 0.17, sill + 0.34 - 0.045 * float(k), back + 0.015),
			Vector3(0.15, 0.020, 0.004), _mat["ink"]))

	# Retort stand at the bay's right, and two boss clamps gripping the vessel.
	var stand_x: float = cx + 0.255
	var stand_z: float = -0.10
	# 0.17 wide and not 0.19: at 0.19 centred here the plate's right edge lands at
	# cx + 0.330, which IS the pier's inner face at the shipped bay width — two
	# coplanar surfaces, and the z-fight would have been in every bench frame.
	root.add_child(HangarKit.box(Vector3(stand_x - 0.025, sill + 0.011, stand_z),
		Vector3(0.17, 0.022, 0.15), steel))
	root.add_child(_cone(Vector3(stand_x, sill + 0.40, stand_z), 0.014, 0.014, 0.80, steel))
	for c in range(2):
		var ly: float = CLAMP_Y[c]                           # heights ON THE VESSEL
		var r: float = _vessel_radius(ly)                    # asked, never assumed
		var cy: float = sill + ly
		root.add_child(HangarKit.box(Vector3(stand_x, cy, stand_z), Vector3(0.05, 0.05, 0.05), steel))
		var reach: float = cx + r
		var arm: float = stand_x - reach
		root.add_child(_cone_x(Vector3(stand_x - arm * 0.5, cy, stand_z), 0.012, 0.012, arm, steel))
		for j in range(2):
			root.add_child(HangarKit.box(Vector3(reach + 0.006, cy, VESSEL_Z + (-0.045 if j == 0 else 0.045)),
				Vector3(0.035, 0.028, 0.035), steel))
	# A marker left lying on the shelf.
	root.add_child(_cone_x(Vector3(cx - 0.20, sill + 0.012, 0.15), 0.011, 0.011, 0.13, _mat["ink"]))


## RESIDUE — the BAY has kept the record. A stained shelf, the ring where the
## vessel has been standing, a drip tray, a tide band across the back panel with
## runs down from it, and a label that has gone illegible where the ink was.
func _bay_residue(root: Node3D, bay: Dictionary) -> void:
	var cx: float = float(bay["x"])
	var sill: float = float(bay["sill"])
	var back: float = -_front_z + BACK_T + 0.005
	var bay_cz: float = _front_z - BAY_D * 0.5

	# THE STAIN FIELD, and it is the bay-scale form of the family's own claim.
	# GlassRackController's residue puts a tide ring on a vessel at the level the
	# liquid stood; a bay that has held leaking vessels for years is dark BELOW that
	# line and clean above it. This panel is 0.62 x 0.315 m and it is the single
	# largest element in this dressing, because without it the residue bay's housing
	# measured 0.114 m2 against the bench's 0.523 and the vitrine's 0.653 — a third
	# of the axis arguing at a fifth of the volume.
	root.add_child(HangarKit.box(Vector3(cx, sill + 0.158, back),
		Vector3(bay_width - 0.04, 0.315, 0.010), _mat["crust"]))
	root.add_child(HangarKit.box(Vector3(cx, sill + 0.003, bay_cz),
		Vector3(bay_width - 0.03, 0.006, BAY_D - 0.06), _mat["crust"]))
	root.add_child(_cone(Vector3(cx, sill + 0.010, VESSEL_Z), 0.185, 0.185, 0.008, _mat["tide"]))
	# Ghost rings where OTHER vessels stood and are no longer here. The housing
	# remembers things the collection does not hold.
	for k in range(3):
		root.add_child(_cone(Vector3(cx - 0.22 + 0.22 * float(k), sill + 0.015, 0.17),
			0.070, 0.070, 0.006, _mat["tide"]))
	# A drip tray off to one side, with a dried pool in it.
	root.add_child(HangarKit.box(Vector3(cx - 0.21, sill + 0.017, 0.11),
		Vector3(0.20, 0.022, 0.20), _mat["steel"]))
	root.add_child(HangarKit.box(Vector3(cx - 0.21, sill + 0.031, 0.11),
		Vector3(0.16, 0.006, 0.16), _mat["crust"]))
	# The tide band at the top of the stain, and six runs down from it.
	root.add_child(HangarKit.box(Vector3(cx, sill + 0.340, back + 0.006),
		Vector3(bay_width - 0.04, 0.05, 0.010), _mat["tide"]))
	for k in range(6):
		root.add_child(HangarKit.box(Vector3(cx - 0.25 + 0.10 * float(k), sill + 0.1625, back + 0.010),
			Vector3(0.030, 0.305, 0.006), _mat["tide"]))
	# Crust along the front lip of the shelf, where it has run off the edge.
	root.add_child(HangarKit.box(Vector3(cx, sill + 0.014, _front_z - 0.018),
		Vector3(bay_width - 0.05, 0.028, 0.022), _mat["crust"]))
	# The old label — cream card, and a smear exactly where the writing was.
	root.add_child(HangarKit.box(Vector3(cx + 0.17, sill + 0.58, back + 0.010),
		Vector3(0.18, 0.13, 0.006), _mat["card"]))
	root.add_child(HangarKit.box(Vector3(cx + 0.17, sill + 0.58, back + 0.015),
		Vector3(0.15, 0.055, 0.005), _mat["crust"]))
	# Crust settled into the two rear corners of the bay.
	for j in range(2):
		root.add_child(HangarKit.box(
			Vector3(cx + (-0.26 if j == 0 else 0.26), sill + 0.012, -0.13),
			Vector3(0.09, 0.020, 0.09), _mat["crust"]))


## EXHIBIT — the bay is a vitrine. Posts, glass on three sides, a cap, a base
## frame, an accession card with a barcode on the back panel, and a seal on the
## front join. Nobody is running this; it is being HELD.
func _bay_exhibit(root: Node3D, bay: Dictionary) -> void:
	var cx: float = float(bay["x"])
	var sill: float = float(bay["sill"])
	var back: float = -_front_z + BACK_T + 0.005
	var bay_cz: float = _front_z - BAY_D * 0.5
	var hw: float = bay_width * 0.5 - 0.04            # 0.29 at the default bay
	var hd: float = BAY_D * 0.5 - 0.03                # 0.19
	var steel: Material = _mat["steel"]

	for j in range(4):
		var px: float = cx + (hw if j % 2 == 0 else -hw)
		var pz: float = bay_cz + (hd if j < 2 else -hd)
		root.add_child(_cone(Vector3(px, sill + 0.40, pz), 0.016, 0.016, 0.80, steel))
	root.add_child(HangarKit.box(Vector3(cx, sill + 0.812, bay_cz),
		Vector3(hw * 2.0 + 0.03, 0.024, hd * 2.0 + 0.03), _mat["trim"]))
	# Base frame — four rails, so the case reads as a case and not as a box.
	root.add_child(HangarKit.box(Vector3(cx, sill + 0.018, bay_cz + hd),
		Vector3(hw * 2.0, 0.030, 0.030), steel))
	root.add_child(HangarKit.box(Vector3(cx, sill + 0.018, bay_cz - hd),
		Vector3(hw * 2.0, 0.030, 0.030), steel))
	for j in range(2):
		root.add_child(HangarKit.box(Vector3(cx + (hw if j == 0 else -hw), sill + 0.018, bay_cz),
			Vector3(0.030, 0.030, hd * 2.0), steel))
	# Glass, three sides. The back is the bay's own panel.
	root.add_child(HangarKit.box(Vector3(cx, sill + 0.41, bay_cz + hd - 0.004),
		Vector3(hw * 2.0 - 0.01, 0.76, 0.006), _mat["pane"]))
	for j in range(2):
		root.add_child(HangarKit.box(Vector3(cx + (hw - 0.007 if j == 0 else -hw + 0.007), sill + 0.41, bay_cz),
			Vector3(0.006, 0.76, hd * 2.0 - 0.01), _mat["pane"]))
	# The accession card on the back panel: two ruled lines and a four-bar code.
	root.add_child(HangarKit.box(Vector3(cx, sill + 0.62, back),
		Vector3(0.26, 0.17, 0.008), _mat["card"]))
	for k in range(2):
		root.add_child(HangarKit.box(Vector3(cx, sill + 0.665 - 0.038 * float(k), back + 0.006),
			Vector3(0.19, 0.020, 0.004), _mat["ink"]))
	for k in range(4):
		root.add_child(HangarKit.box(Vector3(cx - 0.096 + 0.064 * float(k), sill + 0.573, back + 0.006),
			Vector3(0.026, 0.036, 0.004), _mat["ink"]))
	# The seal over the front join.
	root.add_child(HangarKit.box(Vector3(cx - hw, sill + 0.42, bay_cz + hd + 0.004),
		Vector3(0.05, 0.035, 0.012), _mat["seal"]))


# ═══════════════════════════════════════════════════════════════════════════
# THE OBJECT SIDE — what the THING says about itself
# ═══════════════════════════════════════════════════════════════════════════

func _mark_vessel(root: Node3D, bay: Dictionary) -> void:
	match String(bay["status"]):
		"bench":
			_mark_bench(root, bay)
		"residue":
			_mark_residue(root, bay)
		"exhibit":
			_mark_exhibit(root, bay)
		_:
			# `none` — the discipline's own picture of itself: clean glass, nothing
			# recording that a hand was ever here. GlassRackController's word for
			# word, and it draws nothing there either.
			pass


## BENCH marks: masking tape where somebody drew the level, a hand line on it,
## a second collar lower down, and a stirring rod standing in the neck.
func _mark_bench(root: Node3D, bay: Dictionary) -> void:
	var cx: float = float(bay["x"])
	var sill: float = float(bay["sill"])
	for c in range(2):
		var ly: float = TAPE_Y[c]
		var th: float = TAPE_H[c]
		root.add_child(_cone(Vector3(cx, sill + ly, VESSEL_Z),
			_vessel_radius(ly) + 0.0065, _vessel_radius(ly) + 0.0065, th, _mat["tape"]))
	root.add_child(_cone(Vector3(cx, sill + 0.272, VESSEL_Z),
		_vessel_radius(0.272) + 0.0085, _vessel_radius(0.272) + 0.0085, 0.020, _mat["ink"]))
	# The rod: bottom in the neck at 0.50, 0.32 long, leaning 15 degrees.
	var lean: float = deg_to_rad(15.0)
	var rod: MeshInstance3D = _cone(
		Vector3(cx + sin(lean) * 0.16, sill + 0.50 + cos(lean) * 0.16, VESSEL_Z),
		0.013, 0.013, 0.32, _mat["tape"])
	rod.rotation = Vector3(0.0, 0.0, -lean)
	root.add_child(rod)


## RESIDUE marks: crust in the bottom, an OPAQUE etched band across the widest
## part, a tide ring at the old fill line, and runs down the outside from it.
## The etched band is the pivot — it is the only mark in this artifact that
## destroys the transparency the whole family is built on.
func _mark_residue(root: Node3D, bay: Dictionary) -> void:
	var cx: float = float(bay["x"])
	var sill: float = float(bay["sill"])
	root.add_child(_cone(Vector3(cx, sill + 0.033, VESSEL_Z), 0.118, 0.118, 0.038, _mat["crust"]))
	var rb: float = _vessel_radius(0.160) + 0.0025
	root.add_child(_cone(Vector3(cx, sill + 0.160, VESSEL_Z), rb, rb, 0.200, _mat["frost"]))
	var rt: float = _vessel_radius(0.295) + 0.0075
	root.add_child(_cone(Vector3(cx, sill + 0.295, VESSEL_Z), rt, rt, 0.018, _mat["tide"]))
	for d in range(2):
		var a: float = 0.55 + 1.90 * float(d)
		var rr: float = _vessel_radius(0.150) + 0.006
		root.add_child(HangarKit.box(
			Vector3(cx + cos(a) * rr, sill + 0.153, VESSEL_Z + sin(a) * rr),
			Vector3(0.030, 0.266, 0.030), _mat["tide"]))


## EXHIBIT marks: a seal over the mouth and another at the neck, an accession
## label flat on the body, and a numbered tag on a strap off the shoulder.
func _mark_exhibit(root: Node3D, bay: Dictionary) -> void:
	var cx: float = float(bay["x"])
	var sill: float = float(bay["sill"])
	root.add_child(_cone(Vector3(cx, sill + 0.679, VESSEL_Z), 0.066, 0.066, 0.032, _mat["seal"]))
	root.add_child(_cone(Vector3(cx, sill + 0.560, VESSEL_Z), 0.052, 0.052, 0.026, _mat["seal"]))
	# Accession label, flat against the front of the body.
	var lz: float = VESSEL_Z + _vessel_radius(0.200) + 0.006
	root.add_child(HangarKit.box(Vector3(cx, sill + 0.200, lz), Vector3(0.16, 0.11, 0.006), _mat["card"]))
	for k in range(2):
		root.add_child(HangarKit.box(Vector3(cx, sill + 0.230 - 0.030 * float(k), lz + 0.005),
			Vector3(0.12, 0.020, 0.004), _mat["ink"]))
	for k in range(4):
		root.add_child(HangarKit.box(Vector3(cx - 0.048 + 0.032 * float(k), sill + 0.172, lz + 0.005),
			Vector3(0.020, 0.028, 0.004), _mat["ink"]))
	# Tag on a flat strap off the shoulder — a strap and not a wire, because a
	# wire at this framing is 2.6 px and would be a claim nobody can read.
	var sr: float = _vessel_radius(0.500)
	root.add_child(HangarKit.box(Vector3(cx + (sr + 0.215) * 0.5, sill + 0.520, VESSEL_Z),
		Vector3(0.215 - sr, 0.024, 0.010), _mat["wire"]))
	root.add_child(HangarKit.box(Vector3(cx + 0.215, sill + 0.470, VESSEL_Z),
		Vector3(0.17, 0.12, 0.005), _mat["card"]))
	for k in range(2):
		root.add_child(HangarKit.box(Vector3(cx + 0.215, sill + 0.495 - 0.036 * float(k), VESSEL_Z + 0.005),
			Vector3(0.12, 0.020, 0.004), _mat["ink"]))


# ═══════════════════════════════════════════════════════════════════════════
# Geometry helpers
# ═══════════════════════════════════════════════════════════════════════════

func _mk(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _mk_glass(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.05
	m.roughness = 0.05
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.rim_enabled = true
	m.rim = 0.30
	m.rim_tint = 0.20
	return m


func _cone(center: Vector3, r_bottom: float, r_top: float, h: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = maxf(r_bottom, 0.0006)
	mesh.top_radius = maxf(r_top, 0.0006)
	mesh.height = maxf(h, 0.0008)
	mesh.radial_segments = 20
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _cone_x(center: Vector3, r_bottom: float, r_top: float, length: float, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = _cone(center, r_bottom, r_top, length, mat)
	mi.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	return mi
