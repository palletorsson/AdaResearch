extends Node3D
class_name RackRoom

# @identity
# essence: one equipment rack at walk-up scale — 1.12 m wide, 1.60 m tall, sixteen bay positions on a real 19-inch / 4U grid — and five conditions of what it admits exists behind its own controls. The synth family's `machinery` axis taken off a 0.08 m bench grid and given a body you stand in front of.
# desire: to photograph the one value the bench cannot photograph. At 0.08 m per cell a blanking cover is a small plate; at 0.483 x 0.178 m an uncovered bay is a hole you can see 0.47 m into, and `vacancy` stops being "a closed position" and becomes the empty bay where a module would be.
# critical_parameter: machinery — none | plate | vacancy | frame | works. Appearance only, behind the control plane. No control moves, no control is added or hidden, at any value.
# triggers: _ready() solves the rack once into _g, checks every mark against the frame's own px/m, builds the room, then appends the machinery body LAST; apply_grid_config swaps only that body, and only when the word actually changed.
# emerges: the covered positions are the most finished-looking thing in the rack. The modules are bare controls on a dark panel; the blanks are clean sheet metal with screws in it. What the rack has done best is the part of itself that does nothing.
# relationships: the word and its five values are read out of [[MarioSoundController]]'s and the seven synth racks' own script, addons/element_editor/element_layout_node.gd, not retyped — the same file [[Rack303Acid]], [[Rack808Drums]], [[RackAmbientDrone]], [[RackDX7Piano]], [[RackMario]], [[RackMoogBass]] and [[RackSineBasic]] all run. [[timbre_sculptor]] is the ninth member.
# truth: sound is invisible to a still, so nothing here is about sound. This is a room about the RACK. The axis is a claim about where a machine is allowed to end, and every one of its five answers is photographable.

## RACK ROOM — a synthesis. One rack, five conditions, no audio anywhere in it.
##
## NOT AN INSTRUMENT. There is no AudioStreamPlayer, no AudioStreamGenerator, no
## sound_type, no bus, no synthesis and no interaction. It is built entirely from
## MeshInstance3D + BoxMesh. The controls are geometry: they do not turn, slide or play.
##
## THE ROOM, identical at every value of the axis:
##   a 1.30 x 0.74 m floor tile 0.030 m thick — the room's floor, not the rack's body, so
##   the object has ground contact and a scale at every value including `none`;
##   sixteen bay positions on a real rack grid: 2 columns of 19-inch panel width
##   (0.4826 m) either side of a 0.052 m post, 8 rows of 4U (4 x 0.04445 = 0.1778 m);
##   five of those positions carry CONTROLS, and nothing else — a master knob pair with
##   two buttons, a screen with two knobs, an 18-way patch field, a four-fader bank with
##   an eight-segment meter, a six-knob row. Bare. No module faceplates: a faceplate is a
##   plate, and giving each module one would smuggle `plate` into `none`.
##
## ── AXIS — MACHINERY ────────────────────────────────────────────────────────────────────
## How much machine the rack admits around its controls — which is a claim about whether
## sound here is a set of numbers, a product, a format, an installation, or a circuit.
##
##   none     nothing behind the hand. Five clusters of controls standing in their rack
##            positions over an empty floor tile. The claim: there is no machine. A
##            synthesiser IS its parameters and everything else is furniture.
##   plate    one dark panel across both columns, a lip standing past its edge, a lit strip
##            along the foot. The machine is admitted as a SURFACE: there is a front, and
##            therefore a back you are not shown.
##   vacancy  the plate, plus a blanking cover over every bay position no control occupies —
##            adjacent free positions in a row merged into one cover, exactly as the family
##            merges free cells — screwed down in lighter metal standing 10 mm proud. AND
##            ONE BAY LEFT OPEN: a 0.4426 x 0.1538 m hole in the panel, 0.47 m of cavity
##            behind it, punched rails down each side, a connector on the back wall and four
##            empty screw holes in the jamb where the cover for it went. The machine is
##            admitted as a FORMAT with positions, most of them closed and one of them
##            missing its contents.
##   frame    no panel at all. Four corner uprights, eight cross members, four punched rack
##            strips, and the room visible straight through the middle. The machine is
##            admitted as INSTALLED EQUIPMENT: one unit among many, rackable, replaceable.
##   works    no panel either. A board on standoffs behind each control cluster, component
##            blocks on their faces, a wiring spine down the centre with a branch to every
##            board, a transformer and a finned heatsink at the floor. The machine is
##            admitted as CIRCUITRY, and the knobs are revealed as the near ends of parts.
##
## THE FAMILY'S CASE IS MIXED, and this is derived from the family's code, not its prose.
## element_layout_node.gd's `match machinery` (line 1428) reads:
##     "vacancy": _machinery_plate(...) THEN _machinery_vacancy(...)
##     "frame":   _machinery_frame(...) only
##     "works":   _machinery_works(...) only
## So `plate` is NESTED inside `vacancy` — vacancy is literally plate plus covers — while
## plate, frame and works sit SIDE BY SIDE: neither of the last two builds a panel, and
## neither contains the other. One nested pair inside a set of parallel readings, which is
## operations_gallery's third case. There is therefore no "top value" that an all-at-once
## frame would collapse to, and no reason to hold the values simultaneously and vary
## something else. The word varies. See dna.declines for the move that was refused.
##
## THE NESTING IS ALSO THE PREDICTION. plate and vacancy differ by exactly the covers, the
## screws and the one opening; every other pair differs by a whole body. So the closest pair
## is known before any capture, and dna.predicted_degeneracy carries the number.
##
## APPEARANCE ONLY, AND STRICTLY BEHIND THE CONTROL PLANE. Every control sits at z >= 0.280
## and every panel, cover, rail and board at z <= 0.280, except the covers (0.280-0.290) and
## their screws (0.290-0.296), which stand only over positions that hold no control. Nothing
## the axis draws is ever in front of a mark, and nothing it draws is ever hidden by one.
## The z intervals are written out in _build_machinery's header.
##
## DETERMINISTIC. No randf, no randi, no randomize, no _process, no _physics_process, no
## timer, no tween, no physics, no audio, no lookup outside this artifact's own children.
## Two captures of one value are two photographs of one object.

## THE FAMILY'S VOCABULARY, READ OUT OF THE FAMILY, NOT RETYPED.
##
## element_layout_node.gd is the owner on every count that matters: it AUTHORED the axis
## (its 40-line doc block is where the five words are defined), it serves SEVEN of the
## family's nine registry tokens from one script (Rack303Acid, Rack808Drums,
## RackAmbientDrone, RackDX7Piano, RackMario, RackMoogBass, RackSineBasic are seven .tscn
## files with one `script = ExtResource` line between them), and it preloads nothing, so
## pulling it in costs no dependency chain — its five load() calls are all runtime. The
## other two members (MarioSoundController, timbre_sculptor) carry transcribed copies and
## say so in their own comments; a transcription is not the source.
const MACHINERY_SOURCE := preload("res://addons/element_editor/element_layout_node.gd")

## GDScript will not build an @export_enum hint out of a constant, so the list is duplicated
## here exactly once and _assert_vocabulary() checks BOTH the hint copy and the standing
## value against MACHINERY_SOURCE.MACHINERIES at _ready. That is the whole defence against
## the science_screen fault, where a declaration named values the code could not reach and
## sixteen identical frames were published as a verdict about a typo.
const HINT_VALUES: PackedStringArray = ["none", "plate", "vacancy", "frame", "works"]
const DEFAULT_MACHINERY: String = "vacancy"
@export_enum("none", "plate", "vacancy", "frame", "works") var machinery: String = "vacancy"

# ── THE RACK ────────────────────────────────────────────────────────────────────────────
# Primitive dimensions only. Everything derived is computed once in _solve() and read out
# of _g; if a number appears twice in this file, one of them is a lookup.
const RU: float = 0.04445            # one rack unit, the actual standard
const BAY_U: int = 4                 # a bay is 4U, so a bay is 0.1778 m
const COLS: int = 2
const ROWS: int = 8
const PANEL_W: float = 0.4826        # 19 inches, the actual standard
const POST_W: float = 0.052          # centre post, side rails, uprights, cross members
const FRONT: float = 0.280           # the panel face plane; controls live in front of it
const TILE_W: float = 1.30
const TILE_T: float = 0.030
const TILE_D: float = 0.74
const FOOT: float = 0.075            # rack skirt below the lowest bay, and head above the top
const OPEN_IX: float = 0.020         # the bay opening is inset from the panel edge, so a
const OPEN_IY: float = 0.012         # hole in the panel always has a jamb on all four sides

# The family's own body constants, used unchanged: a 16 mm panel, an 8 mm lip 4 mm behind
# it, a 10 mm blanking cover standing proud. All three are real rack dimensions, which is
# why they survive the jump from a 0.08 m bench grid to a 0.483 m panel without scaling.
const PLATE_T: float = 0.016         # MACH_PLATE
const LIP_T: float = 0.008
const COVER_T: float = 0.010         # MACH_COVER
const COVER_GAP: float = 0.006
const SCREW: float = 0.020           # a rack screw with its cup washer
const CAV_D: float = 0.470           # how far you can see into the open bay

## Which positions hold controls: column, row, kind. Fixed table, not a draw from a stream.
const MODULES: Array = [
	[0, 0, "master"],
	[1, 2, "screen"],
	[1, 4, "patch"],
	[0, 6, "faders"],
	[1, 6, "knobs"],
]
## The one position left open at `vacancy`. It is in the LEFT column deliberately: the sweep
## camera stands at +X, and from there the fascia occludes the cavity's outside faces only
## for column 0. In column 1 the same cavity photographs as a box protruding past the panel's
## right edge — measured in the Python model, not guessed.
const OPEN_COL: int = 0
const OPEN_ROW: int = 4

const FADER_LEVEL: Array = [0.045, -0.020, 0.030, -0.048]
## dx, dy, width, height of the component blocks on each board at `works`.
const COMP_TABLE: Array = [
	[-0.150, 0.040, 0.086, 0.030],
	[-0.040, 0.036, 0.062, 0.038],
	[0.062, 0.042, 0.074, 0.026],
	[0.150, 0.030, 0.048, 0.048],
	[-0.096, -0.040, 0.110, 0.024],
	[0.052, -0.044, 0.096, 0.028],
]

# ── PALETTE ─────────────────────────────────────────────────────────────────────────────
# The machinery colours are the FAMILY'S, transcribed from element_layout_node.gd lines
# 1446-1447, 1454, 1464-1465, 1496-1497 and 1519-1522. They could not be preloaded the way
# warning_yard preloads path_block's WARN_* constants, because the family writes them as
# inline Color() literals inside the four builders rather than as named constants — so this
# is a transcription, said out loud, with the lines it came from. Only the VOCABULARY is
# preloaded, and the vocabulary is the only thing that can silently break a sweep.
const C_SHELL: Color = Color(0.125, 0.130, 0.150)
const C_LIP: Color = Color(0.075, 0.078, 0.092)
const C_LIT: Color = Color(0.20, 0.85, 1.0)
const C_COVER: Color = Color(0.215, 0.225, 0.250)
const C_SCREW: Color = Color(0.42, 0.43, 0.46)
const C_RAIL: Color = Color(0.300, 0.310, 0.340)
const C_HOLE: Color = Color(0.045, 0.045, 0.055)
const C_BOARD: Color = Color(0.085, 0.230, 0.155)
const C_STAND: Color = Color(0.380, 0.390, 0.420)
const C_PART: Color = Color(0.100, 0.100, 0.120)
const C_WIRE: Color = Color(0.620, 0.360, 0.160)
# This artifact's own: the room's floor, the cavity, and the controls the family gets from
# separate interactable scenes it instantiates rather than draws.
const C_TILE: Color = Color(0.150, 0.150, 0.158)
const C_CAV: Color = Color(0.020, 0.020, 0.026)
const C_KNOB: Color = Color(0.085, 0.085, 0.095)
const C_MARK: Color = Color(0.62, 0.62, 0.64)
const C_JACK: Color = Color(0.46, 0.44, 0.36)
const C_CAP: Color = Color(0.70, 0.70, 0.72)
const C_SCREEN: Color = Color(0.16, 0.62, 0.55)
const C_SEG_ON: Color = Color(0.35, 0.95, 0.55)
const C_SEG_OFF: Color = Color(0.09, 0.11, 0.10)

# ── THE GAUGE ───────────────────────────────────────────────────────────────────────────
# foresight_range shipped 0.028 m arrows onto an 18 m lane; sorting_hall drew the gauge
# carrying its whole axis three pixels wide. So every mark the AXIS is measured on is
# checked against the frame's own scale at build time, by code, from _g["px_per_m"] — the
# one copy of that arithmetic — rather than in a comment that cannot fail out loud.
#
# A mark is foreshortened by WHICH WAY ITS READ DIMENSION RUNS, not by where it lies. At the
# sweep's yaw 0.62 and pitch -0.26 (14.90 degrees of elevation):
#   "s"  standing up          -> cos(14.90) = 0.9664
#   "w"  across the panel     -> the yaw alone, and the worse of the two horizontal runs,
#                               sin(0.62) = 0.5810 (no mark is credited with the diagonal
#                               widening a square post actually gets)
#   "d"  into the view along the ground -> sin(14.90) = 0.2571
const ELEV_COS: float = 0.9664
const YAW_MIN: float = 0.5810
const ELEV_SIN: float = 0.2571
const GAUGE_FLOOR_PX: float = 5.0

const MACH_HOST: String = "RackMachinery"

# The sweep's own rig, so the gauge below is computed rather than quoted.
const CAP_RES: float = 760.0
const CAP_PAD: float = 1.9            # capture_config_sweep.gd PAD
const DNA_FRAMING: float = 0.58       # must equal the registry's dna.framing

var _g: Dictionary = {}
var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_assert_vocabulary()
	_solve()
	_census_check()
	_gauge_check()
	_build_room()
	# DNA, LAST — the family's own construction. The machinery body is appended after every
	# control exists, so no control changes parent, index or position on any path, and
	# "none" appends nothing at all.
	_build_machinery()
	_built = true


## The grid hands config in as a dictionary AND as config_<key> metadata; the DNA sweep sets
## the @export directly before add_child. All three land here on the same word.
##
## REBUILD ONLY WHAT CHANGED, and only after _ready has built once. force_pad tore down every
## child and re-ran _ready on any call, including calls naming nothing it owned — and this
## artifact will be handed dictionaries naming nothing it owns, because composers pass them
## round wholesale (curation_station calls apply_grid_config({"emissive": false}) on
## everything it mounts, which is how all seven promoted racks are placed today).
func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	var before: String = machinery
	_read_metadata_overrides()
	if not _built:
		return
	if machinery == before:
		return
	_build_machinery()


func _read_metadata_overrides() -> void:
	var raw: String = machinery
	if has_meta("config_machinery"):
		raw = str(get_meta("config_machinery"))
	var want: String = raw.strip_edges().to_lower()
	if MACHINERY_SOURCE.MACHINERIES.has(want):
		machinery = want
		return
	# An unrecognised word KEEPS the standing value; a typo must never blank the rack.
	if MACHINERY_SOURCE.MACHINERIES.has(machinery):
		push_warning("rack_room: '%s' is not a `machinery` value; keeping '%s'." % [raw, machinery])
		return
	# Nothing legal is standing, which means an illegal word reached the @export before
	# _ready — the sweep sets properties directly, so this is the science_screen path. Fall
	# back LOUDLY: silence here costs five identical frames and a verdict about a typo.
	push_error("rack_room: '%s' is not a `machinery` value and nothing legal was standing; falling back to '%s'. The family's list is %s." % [raw, DEFAULT_MACHINERY, Array(MACHINERY_SOURCE.MACHINERIES)])
	machinery = DEFAULT_MACHINERY


## The two lists that must not drift: the literal the export hint forces, and the family's
## own constant. Loud on divergence, because the failure it guards against is silent.
func _assert_vocabulary() -> void:
	var owned: Array = Array(MACHINERY_SOURCE.MACHINERIES)
	var mine: Array = Array(HINT_VALUES)
	if mine != owned:
		push_error("rack_room: the @export_enum hint on `machinery` reads %s and element_layout_node.gd's MACHINERIES reads %s. They have drifted, so this artifact now carries a private vocabulary and the sweep will set values it cannot reach." % [mine, owned])
	if not owned.has(machinery):
		push_error("rack_room: `machinery` = '%s' is not in the family's list %s." % [machinery, owned])


# ── ONE COPY OF THE ARITHMETIC ──────────────────────────────────────────────────────────
func _solve() -> void:
	var bay_h: float = RU * float(BAY_U)                      # 0.17780
	var face_h: float = bay_h * float(ROWS)                   # 1.42240
	var face_y0: float = TILE_T + FOOT                        # 0.10500
	var face_y1: float = face_y0 + face_h                     # 1.52740
	var rack_y1: float = face_y1 + FOOT                       # 1.60240
	var panel_span: float = float(COLS) * PANEL_W + POST_W    # 1.01720
	var ext_w: float = panel_span + 2.0 * POST_W              # 1.12120
	# The union AABB across all five values is TILE_W x rack_y1 x TILE_D = 1.30 x 1.6024 x
	# 0.74, and its X and Z are set by the FLOOR TILE, which is CONSTANT — so no value of the
	# axis can move the camera. The three inequalities that make that true: EXT_W 1.1212 <
	# TILE_W 1.30; the frontmost control face 0.330 < TILE_D * 0.5 = 0.37; the rearmost body
	# -0.280 > -0.37. The tallest thing at any value is the rack head at rack_y1, and the
	# tallest control is in row 6 at about 1.34.
	#
	# The sweep frames by the bounding SPHERE: radius = |size| / 2 = 1.09605, and the visible
	# frame is 2 * PAD * radius * framing metres wide. Computed, not quoted, so that changing
	# the tile or the rack height moves the gauge with it.
	var radius: float = sqrt(TILE_W * TILE_W + rack_y1 * rack_y1 + TILE_D * TILE_D) * 0.5
	var frame_w: float = 2.0 * CAP_PAD * radius * DNA_FRAMING
	var occ: Dictionary = {}
	for m in MODULES:
		var spec: Array = m
		occ["%d_%d" % [int(spec[0]), int(spec[1])]] = str(spec[2])
	_g = {
		"bay_h": bay_h,
		"face_h": face_h,
		"face_y0": face_y0,
		"face_y1": face_y1,
		"face_mid": (face_y0 + face_y1) * 0.5,
		"rack_y0": TILE_T,
		"rack_y1": rack_y1,
		"rack_h": rack_y1 - TILE_T,                            # 1.57240
		"rack_mid": (TILE_T + rack_y1) * 0.5,
		"panel_span": panel_span,
		"ext_w": ext_w,
		"col_dx": (PANEL_W + POST_W) * 0.5,                    # 0.26730
		"opening_w": PANEL_W - 2.0 * OPEN_IX,                  # 0.44260
		"opening_h": bay_h - 2.0 * OPEN_IY,                    # 0.15380
		"plate_z": FRONT - PLATE_T * 0.5,
		"lip_z": FRONT - PLATE_T - 0.004 - LIP_T * 0.5,
		"board_z": FRONT - 0.078,
		"occ": occ,
	}
	_g["px_per_m"] = CAP_RES / frame_w                         # 314.61
	_g["frame_w"] = frame_w                                    # 2.41569
	_g["radius"] = radius                                      # 1.09605


func _bay_x(c: int) -> float:
	return (float(c) - 0.5) * 2.0 * float(_g["col_dx"])


func _bay_y(r: int) -> float:
	return float(_g["face_y0"]) + (float(r) + 0.5) * float(_g["bay_h"])


## COUNT THE THING YOU CLAIM TO COUNT. The registry's argument rests on four numbers —
## sixteen positions, five used, ten covered, one open — and `vacancy` is defended as "the
## only value that says a NUMBER". So the numbers are counted from the tables that actually
## draw the geometry, at build time, instead of being typed into a note. sorting_hall
## counted cells whose value changed as a proxy for work and thereby stated that merge sort
## is free on sorted input; a claim in a wall text that nothing recomputes is the same fault
## with a longer fuse.
func _census_check() -> void:
	var positions: int = COLS * ROWS
	var used: int = MODULES.size()
	var covered: int = 0
	for run in _cover_runs():
		var spec: Array = run
		covered += int(spec[1]) - int(spec[0]) + 1
	var opened: int = 1
	var occ: Dictionary = _g["occ"]
	if occ.has("%d_%d" % [OPEN_COL, OPEN_ROW]):
		opened = 0
		push_error("rack_room: the open bay (%d, %d) is also a module position, so `vacancy` draws a cavity behind a control. The two tables have gone out of step." % [OPEN_COL, OPEN_ROW])
	if used + covered + opened != positions:
		push_error("rack_room: the census does not close. %d positions = %d used + %d covered + %d open is false, so the registry's count of the rack is wrong and so is the argument built on it." % [positions, used, covered, opened])


## Every mark the axis is measured on, against the frame it will be photographed in. Silent
## when the rack is in gauge, which it is: the thinnest MARK is the works side post at
## 5.49 px, then the cover screw at 6.08 and the works spine at 6.58.
##
## Four elements sit deliberately UNDER the floor and are not listed, because no part of the
## axis is measured on them: the cover's 10 mm proud step (3.04 px), the punched holes in
## the rack strips (4.26 px), the works standoffs (4.26 px) and the heatsink fins (2.19 px).
## Each is texture on a mark that is itself 35-52 px, and each is a real dimension that
## field_room's ruling says to leave alone rather than fatten for pixels.
func _gauge_check() -> void:
	var ppm: float = float(_g["px_per_m"])
	var marks: Array = [
		["lip side rail", POST_W, "w"],
		["lip head rail", FOOT, "s"],
		["cover run height", float(_g["bay_h"]) - COVER_GAP, "s"],
		["cover screw", SCREW, "s"],
		["open bay height", float(_g["opening_h"]), "s"],
		["open bay width", float(_g["opening_w"]), "w"],
		["lit foot strip", 0.030, "s"],
		["rack strip width", 0.042, "w"],
		["corner upright", POST_W, "w"],
		["cross member", POST_W, "s"],
		["works board height", float(_g["bay_h"]) - 0.010, "s"],
		["works component", 0.026, "s"],
		["works loom", 0.026, "s"],
		["works spine", 0.036, "w"],
		["works side post", 0.030, "w"],
		["works transformer", 0.170, "s"],
		["works heatsink block", 0.192, "w"],
	]
	for m in marks:
		var spec: Array = m
		var metres: float = float(spec[1])
		var run: String = str(spec[2])
		var factor: float = ELEV_COS
		if run == "w":
			factor = YAW_MIN
		elif run == "d":
			factor = ELEV_SIN
		var px: float = metres * factor * ppm
		if px < GAUGE_FLOOR_PX:
			push_warning("rack_room: the mark '%s' is %.4f m = %.2f px at dna.framing 0.58, under the %.1f px floor. Widen it, or the axis is being measured on something a visitor cannot see." % [str(spec[0]), metres, px, GAUGE_FLOOR_PX])


# ── THE ROOM: identical at every value ──────────────────────────────────────────────────
func _build_room() -> void:
	# The floor. It is the ROOM's, not the rack's, which is why it survives `none`: at that
	# value the controls stand over an empty tile and the absence of a machine under them is
	# the picture. It also fixes the union AABB in X and Z and gives every value the same
	# base-to-floor grounding, so a map cannot seat one value differently from another.
	_add(self, Vector3(0.0, TILE_T * 0.5, 0.0), Vector3(TILE_W, TILE_T, TILE_D),
		_mat(C_TILE, 0.95, 0.0))
	for m in MODULES:
		var spec: Array = m
		var cx: float = _bay_x(int(spec[0]))
		var cy: float = _bay_y(int(spec[1]))
		match str(spec[2]):
			"master":
				_cluster_master(cx, cy)
			"screen":
				_cluster_screen(cx, cy)
			"patch":
				_cluster_patch(cx, cy)
			"faders":
				_cluster_faders(cx, cy)
			"knobs":
				_cluster_knobs(cx, cy)


func _cluster_master(cx: float, cy: float) -> void:
	var knob: StandardMaterial3D = _mat(C_KNOB, 0.55, 0.10)
	var mark: StandardMaterial3D = _mat(C_MARK, 0.35, 0.30)
	_add(self, Vector3(cx - 0.130, cy, FRONT + 0.025), Vector3(0.104, 0.104, 0.050), knob)
	_add(self, Vector3(cx - 0.130, cy + 0.030, FRONT + 0.052), Vector3(0.012, 0.040, 0.006), mark)
	_add(self, Vector3(cx - 0.010, cy + 0.008, FRONT + 0.019), Vector3(0.064, 0.064, 0.038), knob)
	_add(self, Vector3(cx - 0.010, cy + 0.030, FRONT + 0.040), Vector3(0.010, 0.026, 0.006), mark)
	var cap: StandardMaterial3D = _mat(C_CAP, 0.40, 0.25)
	for dx in [0.110, 0.180]:
		_add(self, Vector3(cx + float(dx), cy - 0.030, FRONT + 0.011),
			Vector3(0.052, 0.034, 0.022), cap)


func _cluster_screen(cx: float, cy: float) -> void:
	_add(self, Vector3(cx - 0.105, cy, FRONT + 0.007), Vector3(0.180, 0.092, 0.014),
		_lit(C_SCREEN, 1.6))
	var knob: StandardMaterial3D = _mat(C_KNOB, 0.55, 0.10)
	var mark: StandardMaterial3D = _mat(C_MARK, 0.35, 0.30)
	for dx in [0.045, 0.130]:
		var x: float = cx + float(dx)
		_add(self, Vector3(x, cy + 0.012, FRONT + 0.021), Vector3(0.068, 0.068, 0.042), knob)
		_add(self, Vector3(x, cy + 0.038, FRONT + 0.044), Vector3(0.010, 0.028, 0.006), mark)


func _cluster_patch(cx: float, cy: float) -> void:
	var ring: StandardMaterial3D = _mat(C_JACK, 0.35, 0.80)
	var bore: StandardMaterial3D = _mat(C_HOLE, 0.85, 0.10)
	for jr in range(3):
		for jc in range(6):
			var jx: float = cx - 0.175 + float(jc) * 0.070
			var jy: float = cy + 0.048 - float(jr) * 0.048
			_add(self, Vector3(jx, jy, FRONT + 0.007), Vector3(0.034, 0.034, 0.014), ring)
			# The bore's face sits 6 mm behind the ring's, so a jack reads as a hole rather
			# than a stud. Nothing here is coplanar with anything.
			_add(self, Vector3(jx, jy, FRONT + 0.004), Vector3(0.017, 0.017, 0.008), bore)


func _cluster_faders(cx: float, cy: float) -> void:
	var rail: StandardMaterial3D = _mat(C_KNOB, 0.55, 0.10)
	var cap: StandardMaterial3D = _mat(C_CAP, 0.40, 0.25)
	for i in range(FADER_LEVEL.size()):
		var fx: float = cx - 0.150 + float(i) * 0.060
		_add(self, Vector3(fx, cy, FRONT + 0.007), Vector3(0.016, 0.132, 0.014), rail)
		_add(self, Vector3(fx, cy + float(FADER_LEVEL[i]), FRONT + 0.015),
			Vector3(0.042, 0.020, 0.030), cap)
	var on: StandardMaterial3D = _lit(C_SEG_ON, 2.0)
	var off: StandardMaterial3D = _mat(C_SEG_OFF, 0.70, 0.10)
	for s in range(8):
		var sy: float = cy + 0.030
		if s >= 4:
			sy = cy - 0.004
		var seg: StandardMaterial3D = off
		if s < 5:
			seg = on
		_add(self, Vector3(cx + 0.115 + float(s % 4) * 0.026, sy, FRONT + 0.005),
			Vector3(0.020, 0.026, 0.010), seg)


func _cluster_knobs(cx: float, cy: float) -> void:
	var knob: StandardMaterial3D = _mat(C_KNOB, 0.55, 0.10)
	var mark: StandardMaterial3D = _mat(C_MARK, 0.35, 0.30)
	for i in range(6):
		var kx: float = cx - 0.180 + float(i) * 0.072
		_add(self, Vector3(kx, cy, FRONT + 0.020), Vector3(0.060, 0.060, 0.040), knob)
		_add(self, Vector3(kx, cy + 0.024, FRONT + 0.042), Vector3(0.009, 0.024, 0.006), mark)


# ── THE MACHINE ─────────────────────────────────────────────────────────────────────────
#
# THE Z-STACK, written out, because operations_gallery's bezel was one 24 mm slab spanning
# z 0.000-0.024 that enclosed the panel face AND every mark its axis drew, and four values
# photographed as the front of one blank slab at 0.09%:
#
#   z 0.290 - 0.296   cover screws            (vacancy)   over free positions only
#   z 0.280 - 0.290   blanking covers         (vacancy)   over free positions only
#   z 0.280 - 0.330   the CONTROLS            (constant)  over occupied positions only
#   z 0.276 - 0.288   lit foot strip / jamb screw holes
#   z 0.264 - 0.280   the panel               (plate, vacancy)   absent over the open bay
#   z 0.250 - 0.280   punched rack strips     (frame)
#   z 0.252 - 0.260   lip rails               (plate, vacancy)   FOUR RAILS, NOT A SLAB
#   z 0.222 - 0.274   corner uprights, cross members (frame)
#   z 0.199 - 0.229   boards, standoffs, components (works)
#  z -0.206 - 0.264   the open bay cavity     (vacancy)
#
# The covers and the controls are DISJOINT IN PLAN — a cover only ever spans positions no
# control occupies — so no value of the axis puts anything in front of anything constant.
# The lip is four rails and not the family's full-size slab for exactly the operations_gallery
# reason: a slab at z 0.252-0.260 stands behind the open bay, and the cavity then photographs
# as the back of the lip. That was measured in the Python model (4,897 px of the plate frame
# turning into "lip" rather than "cavity") before it was fixed, not reasoned about.
func _build_machinery() -> void:
	var old: Node = get_node_or_null(MACH_HOST)
	if old != null:
		remove_child(old)
		old.queue_free()
	if machinery == "none" or not MACHINERY_SOURCE.MACHINERIES.has(machinery):
		return                       # the family's legacy lineage builds nothing at all
	var host := Node3D.new()
	host.name = MACH_HOST
	add_child(host)
	match machinery:
		"plate":
			_mach_plate(host, [])
		"vacancy":
			_mach_vacancy(host)
		"frame":
			_mach_frame(host)
		"works":
			_mach_works(host)
		_:
			pass


## PLATE — the machine as a SURFACE. One panel across both columns, a lip standing past its
## edge, a lit strip along the foot. The rack acquires a front, and therefore a back you are
## not shown: sound arrives from somewhere instead of from nowhere.
func _mach_plate(host: Node3D, hole: Array) -> void:
	_fascia(host, hole)
	# The lip: the family's rim, built as four rails so nothing opaque stands behind the
	# opening. Same colour, same 8 mm thickness, same 4 mm gap behind the panel.
	var lip: StandardMaterial3D = _mat(C_LIP, 0.62, 0.45)
	var lz: float = float(_g["lip_z"])
	var span: float = float(_g["panel_span"])
	for s in [-1.0, 1.0]:
		_add(host, Vector3(float(s) * (span + POST_W) * 0.5, float(_g["rack_mid"]), lz),
			Vector3(POST_W, float(_g["rack_h"]), LIP_T), lip)
	for sy in [float(_g["rack_y0"]) + FOOT * 0.5, float(_g["rack_y1"]) - FOOT * 0.5]:
		_add(host, Vector3(0.0, float(sy), lz), Vector3(float(_g["ext_w"]), FOOT, LIP_T), lip)
	# The only emissive surface on the body, so it owns the brightest pixels in any frame the
	# rack appears in — the family's reason, and the reason the strip is 30 mm rather than the
	# family's 7: 0.007 m would be 2.1 px in this frame and 0.030 is 9.12.
	_add(host, Vector3(0.0, float(_g["face_y0"]) - FOOT * 0.5, FRONT + 0.004),
		Vector3(span * 0.66, 0.030, 0.008), _lit(C_LIT, 2.4))


## The panel itself. `hole` is empty, or [x0, x1, y0, y1] of the open bay — in which case the
## panel is built as four pieces AROUND the opening, so the absence is a real absence in the
## geometry rather than a dark rectangle painted on a continuous sheet.
func _fascia(host: Node3D, hole: Array) -> void:
	var shell: StandardMaterial3D = _mat(C_SHELL, 0.72, 0.25)
	var span: float = float(_g["panel_span"])
	var x0: float = -span * 0.5
	var x1: float = span * 0.5
	var y0: float = float(_g["face_y0"])
	var y1: float = float(_g["face_y1"])
	var ymid: float = float(_g["face_mid"])
	var z: float = float(_g["plate_z"])
	if hole.is_empty():
		_add(host, Vector3(0.0, ymid, z), Vector3(span, float(_g["face_h"]), PLATE_T), shell)
		return
	var hx0: float = float(hole[0])
	var hx1: float = float(hole[1])
	var hy0: float = float(hole[2])
	var hy1: float = float(hole[3])
	_add(host, Vector3((x0 + hx0) * 0.5, ymid, z),
		Vector3(hx0 - x0, float(_g["face_h"]), PLATE_T), shell)
	_add(host, Vector3((hx1 + x1) * 0.5, ymid, z),
		Vector3(x1 - hx1, float(_g["face_h"]), PLATE_T), shell)
	_add(host, Vector3((hx0 + hx1) * 0.5, (hy1 + y1) * 0.5, z),
		Vector3(hx1 - hx0, y1 - hy1, PLATE_T), shell)
	_add(host, Vector3((hx0 + hx1) * 0.5, (y0 + hy0) * 0.5, z),
		Vector3(hx1 - hx0, hy0 - y0, PLATE_T), shell)


## VACANCY — the machine as a FORMAT. The plate, plus a blanking cover over every position no
## control occupies, adjacent free positions in a row merged into one cover the way a real
## blanking panel spans several units and the way _machinery_vacancy merges free cells. What
## you can touch is revealed as the small fitted subset of what the frame would accept.
##
## AND ONE BAY LEFT OPEN. This is the departure from the family's builder, which covers EVERY
## free cell, and it is the whole reason to build the axis at this size. At 0.08 m per cell a
## cover is the entire statement because there is nothing to see into; at 0.4426 x 0.1538 m
## with 0.47 m behind it, an uncovered position is a cavity with rails, a connector and four
## empty screw holes where its cover went. The covers stay — the family's reading is fully
## present — and the hole is what the family's scale could not hold: not "a position that is
## closed" but the empty bay where a module would be, which is the only thing in this artifact
## that says what the rack is MISSING rather than what it has.
func _mach_vacancy(host: Node3D) -> void:
	var ox: float = _bay_x(OPEN_COL)
	var oy: float = _bay_y(OPEN_ROW)
	var ow: float = float(_g["opening_w"])
	var oh: float = float(_g["opening_h"])
	var hole: Array = [ox - ow * 0.5, ox + ow * 0.5, oy - oh * 0.5, oy + oh * 0.5]
	_mach_plate(host, hole)

	var cover: StandardMaterial3D = _mat(C_COVER, 0.55, 0.38)
	var screw: StandardMaterial3D = _mat(C_SCREW, 0.35, 0.75)
	var bay_h: float = float(_g["bay_h"])
	for run in _cover_runs():
		var spec: Array = run
		var a: int = int(spec[0])
		var b: int = int(spec[1])
		var r: int = int(spec[2])
		var cx0: float = _bay_x(a) - PANEL_W * 0.5 + COVER_GAP
		var cx1: float = _bay_x(b) + PANEL_W * 0.5 - COVER_GAP
		var cy: float = _bay_y(r)
		var cw: float = cx1 - cx0
		var ch: float = bay_h - COVER_GAP
		_add(host, Vector3((cx0 + cx1) * 0.5, cy, FRONT + COVER_T * 0.5),
			Vector3(cw, ch, COVER_T), cover)
		var xs: Array = [cx0 + 0.030, cx1 - 0.030]
		if b > a:
			# a merged cover is bolted at the centre post too
			xs.append((cx0 + cx1) * 0.5 - 0.026)
			xs.append((cx0 + cx1) * 0.5 + 0.026)
		for sx in xs:
			for sy in [cy + ch * 0.5 - 0.028, cy - ch * 0.5 + 0.028]:
				_add(host, Vector3(float(sx), float(sy), FRONT + COVER_T + 0.003),
					Vector3(SCREW, SCREW, 0.006), screw)

	_open_bay(host, ox, oy, hole)


## Free positions merged along a row — the same walk as _machinery_vacancy's, with the open
## bay excluded so it never takes a cover.
func _cover_runs() -> Array:
	var occ: Dictionary = _g["occ"]
	var runs: Array = []
	for r in range(ROWS):
		var run: int = -1
		for c in range(COLS + 1):
			var is_open: bool = c == OPEN_COL and r == OPEN_ROW
			var free_cell: bool = c < COLS and not is_open and not occ.has("%d_%d" % [c, r])
			if free_cell:
				if run < 0:
					run = c
				continue
			if run < 0:
				continue
			runs.append([run, c - 1, r])
			run = -1
	return runs


## The open bay: a cavity, not a dark rectangle. Four inner walls and a back wall in near
## black, a punched rail down each side, a connector on the back wall with its cable, and
## four empty screw holes in the jamb outside the opening where the cover's screws were.
func _open_bay(host: Node3D, ox: float, oy: float, hole: Array) -> void:
	var cav: StandardMaterial3D = _mat(C_CAV, 1.0, 0.0)
	var rail: StandardMaterial3D = _mat(C_RAIL, 0.42, 0.68)
	var bore: StandardMaterial3D = _mat(C_HOLE, 0.85, 0.10)
	var ow: float = float(_g["opening_w"])
	var oh: float = float(_g["opening_h"])
	var back: float = FRONT - PLATE_T
	var zc: float = back - CAV_D * 0.5
	_add(host, Vector3(ox, oy, back - CAV_D), Vector3(ow, oh, 0.012), cav)
	for sx in [float(hole[0]) + 0.006, float(hole[1]) - 0.006]:
		_add(host, Vector3(float(sx), oy, zc), Vector3(0.012, oh, CAV_D), cav)
	for sy in [float(hole[2]) + 0.006, float(hole[3]) - 0.006]:
		_add(host, Vector3(ox, float(sy), zc), Vector3(ow, 0.012, CAV_D), cav)
	for sx in [float(hole[0]) + 0.030, float(hole[1]) - 0.030]:
		_add(host, Vector3(float(sx), oy, back - 0.030), Vector3(0.026, oh - 0.020, 0.040), rail)
		for k in range(3):
			_add(host, Vector3(float(sx), oy - 0.048 + float(k) * 0.048, back - 0.009),
				Vector3(0.013, 0.013, 0.006), bore)
	_add(host, Vector3(ox + 0.060, oy - 0.030, back - 0.400),
		Vector3(0.120, 0.050, 0.034), _mat(C_PART, 0.70, 0.20))
	_add(host, Vector3(ox + 0.060, oy - 0.056, back - 0.330),
		Vector3(0.026, 0.026, 0.150), _mat(C_WIRE, 0.55, 0.45))
	# The four holes the cover's screws left. Their faces stand 2 mm proud of the panel so
	# nothing is coplanar; being near black, they read as holes.
	for sx in [float(hole[0]) - 0.010, float(hole[1]) + 0.010]:
		for sy in [float(hole[2]) - 0.004, float(hole[3]) + 0.004]:
			_add(host, Vector3(float(sx), float(sy), FRONT - 0.001),
				Vector3(0.018, 0.018, 0.006), bore)


## FRAME — the machine as INSTALLED EQUIPMENT. Four corner uprights, eight cross members and
## four punched rack strips, with the room visible straight through where a panel would be.
## One unit among many, made to be pulled and replaced.
func _mach_frame(host: Node3D) -> void:
	var rail: StandardMaterial3D = _mat(C_RAIL, 0.42, 0.68)
	var bore: StandardMaterial3D = _mat(C_HOLE, 0.85, 0.10)
	var ux: float = float(_g["ext_w"]) * 0.5 - POST_W * 0.5
	var uz: float = FRONT - POST_W * 0.5 - 0.006
	for sx in [-ux, ux]:
		for sz in [-uz, uz]:
			_add(host, Vector3(float(sx), float(_g["rack_mid"]), float(sz)),
				Vector3(POST_W, float(_g["rack_h"]), POST_W), rail)
	var ys: Array = [float(_g["rack_y0"]) + POST_W * 0.5, float(_g["rack_y1"]) - POST_W * 0.5]
	for sz in [-uz, uz]:
		for sy in ys:
			_add(host, Vector3(0.0, float(sy), float(sz)),
				Vector3(float(_g["ext_w"]), POST_W, POST_W), rail)
	for sx in [-ux, ux]:
		for sy in ys:
			_add(host, Vector3(float(sx), float(sy), 0.0),
				Vector3(POST_W, POST_W, 2.0 * uz - POST_W), rail)
	for c in range(COLS):
		for s in [-1.0, 1.0]:
			var sx2: float = _bay_x(c) + float(s) * PANEL_W * 0.5
			_add(host, Vector3(sx2, float(_g["face_mid"]), FRONT - 0.015),
				Vector3(0.042, float(_g["face_h"]), 0.030), rail)
			for r in range(ROWS):
				for k in range(3):
					_add(host, Vector3(sx2, _bay_y(r) - 0.058 + float(k) * 0.058, FRONT + 0.0003),
						Vector3(0.014, 0.014, 0.006), bore)


## WORKS — the machine as CIRCUITRY. A board on standoffs behind each control cluster,
## component blocks on their faces, a wiring spine down the centre with a branch to every
## board, a transformer and a finned heatsink at the floor, and two side posts holding the
## stack. No panel at all: the knobs are shown as the near ends of parts, and the rack stops
## pretending the sound comes from nowhere.
func _mach_works(host: Node3D) -> void:
	var board: StandardMaterial3D = _mat(C_BOARD, 0.62, 0.15)
	var stand: StandardMaterial3D = _mat(C_STAND, 0.40, 0.72)
	var part: StandardMaterial3D = _mat(C_PART, 0.70, 0.20)
	var wire: StandardMaterial3D = _mat(C_WIRE, 0.55, 0.45)
	var bz: float = float(_g["board_z"])
	var ow: float = float(_g["opening_w"])
	var oh: float = float(_g["opening_h"])
	for m in MODULES:
		var spec: Array = m
		var cx: float = _bay_x(int(spec[0]))
		var cy: float = _bay_y(int(spec[1]))
		# A little larger than the opening, so a rim of board shows around every cluster.
		_add(host, Vector3(cx, cy, bz),
			Vector3(PANEL_W - 0.012, float(_g["bay_h"]) - 0.010, 0.006), board)
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				_add(host, Vector3(cx + float(sx) * (ow * 0.5 - 0.024),
					cy + float(sy) * (oh * 0.5 - 0.020), bz + 0.042),
					Vector3(0.014, 0.014, 0.078), stand)
		for comp in COMP_TABLE:
			var cs: Array = comp
			_add(host, Vector3(cx + float(cs[0]), cy + float(cs[1]), bz + 0.017),
				Vector3(float(cs[2]), float(cs[3]), 0.028), part)
		_add(host, Vector3(cx, cy - 0.052, bz + 0.010),
			Vector3(ow - 0.040, 0.026, 0.020), wire)
	_add(host, Vector3(0.0, float(_g["face_mid"]), FRONT - 0.185),
		Vector3(0.036, float(_g["face_h"]) * 0.95, 0.036), stand)
	for m2 in MODULES:
		var spec2: Array = m2
		var bx: float = _bay_x(int(spec2[0]))
		_add(host, Vector3(bx * 0.5, _bay_y(int(spec2[1])) - 0.052, FRONT - 0.170),
			Vector3(absf(bx), 0.026, 0.026), wire)
	_add(host, Vector3(-0.150, 0.145, FRONT - 0.190), Vector3(0.200, 0.170, 0.170), part)
	for k in range(7):
		_add(host, Vector3(0.120 + float(k) * 0.030, 0.150, FRONT - 0.190),
			Vector3(0.012, 0.140, 0.120), stand)
	# The family's side posts: just outside the panel width, 92% of the face height.
	for sx in [-1.0, 1.0]:
		_add(host, Vector3(float(sx) * (float(_g["panel_span"]) * 0.5 + 0.019),
			float(_g["face_mid"]), FRONT - 0.040),
			Vector3(0.030, float(_g["face_h"]) * 0.92, 0.055), stand)


# ── PRIMITIVES ──────────────────────────────────────────────────────────────────────────
# Boxes and materials only. Nothing here creates a body, a shape, an area, a light, an audio
# player or a group.

func _add(host: Node3D, center: Vector3, box_size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = box_size
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = mat
	mi.position = center
	host.add_child(mi)
	return mi


func _mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _lit(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.40
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
