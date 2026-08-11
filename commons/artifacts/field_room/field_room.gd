extends Node3D
class_name FieldRoom

# @identity
# essence: ONE vector function, stood up and read four ways at once — glyph arrows on a
#   lattice, streamlines, a population riding it, and the bare law on a plate. F is
#   computed by a single function; the four panels differ only in what they do with it.
# desire: to be stood in front of until the four readings stop agreeing. On the
#   cancelling mid-line of a dipole the glyphs say almost nothing, the streamlines say
#   the two sources are joined through exactly there, and the population says that
#   region is a road and not a place.
# critical_parameter: law — which rule the space obeys. Turning it turns all four
#   readings together, which is the only way to ask whether they are readings of one
#   thing rather than four separate drawings that happen to share a caption.
# triggers: none. Nothing moves, nothing is grabbed, nothing is timed. Every mark is
#   integrated once at build time from the same function.
# emerges: a reading is not neutral. Each panel is blind to something the others show,
#   and the blindness is not the same blindness — the glyphs cannot show where a body
#   ends up, the population cannot show the field where no body went, the streamlines
#   cannot show density, and the plate shows everything and draws nothing.
# relationships: synthesised from [[force_field_visualizer]], [[vector_field_grid]],
#   [[vector_fields]], [[weather_vector_field]], [[force_field_zone]] and
#   [[particle_flow_swarm]] — six artifacts that drew the same object six ways and were
#   never once in the same room. Replaces none of them.
# truth: the field is one thing and the picture of it is four choices. What you can see
#   is a property of the drawing, not of the space.

# ─────────────────────────────────────────────────────────────────────────────
# SYNTHESIS (2026-08-06). doc/plans/ARTIFACT_SYNTHESIS_PLAN.md, "field room".
#
# WHAT THE SIX SOURCES LEARNED, and what this room exhibits.
#
#   [[force_field_visualizer]]  coined `law` — gravity · point_charge · dipole · vortex
#       — and its finding is that these are four different SPATIAL GRAMMARS, not four
#       settings: gravity is the only one where position carries no information at all.
#       It also built the `evidence` ladder (result·trace·sources·longhand) and
#       recorded, in its own longhand plates, that an inverse-square field spans four
#       decades and a LINEAR ramp prints one white dot on a black square.
#   [[vector_field_grid]]       coined `coding` for this family — what the tint CLAIMS,
#       as against what it shows — and found that arrow LENGTH must keep carrying |v| at
#       every value, so `uniform` withholds the colour without withholding the
#       magnitude. It also measured the dilution: 96 arrows on an otherwise empty plane
#       is a thin subject, and warned the next artifact to crop before believing INERT.
#   [[vector_fields]]           took `coding` character for character and found that a
#       shared word is only honest when the siblings measure alike — and that the SAME
#       value can be right in one body and wrong in another for a reason about the MESH
#       (it declared `source`, which vector_field_grid had refused, because its arrow is
#       a cone with an apex and reversing it is visible where a headless box is not).
#   [[weather_vector_field]]    refused both `field` and `law`, because its field never
#       changes — it is always A + B — and what turns is the two summands. Its finding
#       is that every instrument in a room is a different read of ONE vector.
#   [[force_field_zone]]        took `law` and REFUSED three of its four values: a
#       uniform volume cannot be a point charge, a dipole or a vortex, and taking those
#       words would name a mechanism the object lacks.
#   [[particle_flow_swarm]]     is DECLARED a pair with vector_field_grid — one draws
#       the field, the other rides it — and found the one question a body can ask that
#       an arrow cannot: how much of its own path it admits. Its tail is INTEGRATED
#       BACKWARDS at draw time rather than recorded, so it is identical on frame one and
#       frame one thousand.
#
# The room takes all of that literally: ONE field function, FOUR readings, side by side.
#
#   panel 1  GLYPHS       an 8x8 lattice of arrows — local samples, one per cell
#   panel 2  STREAMLINES  16 curves integrated through the same field, both ways
#   panel 3  POPULATION   120 bodies dropped on the field and advected, each with a
#                         short upstream wake
#   panel 4  LAW          the equation, etched, and the field's value at one probe
#                         point printed as two numbers
#
# ONE COPY OF THE ARITHMETIC. `_field_at()` is the only place a force is computed. The
# glyphs sample it, the streamline integrator marches it, the population marches the
# SAME integrator, and the plate prints it. The panels cannot disagree about the physics
# by construction, which is a stronger guarantee than four functions that agree today.
#
# THE ARITHMETIC IS force_field_visualizer's `_calculate_field`, evaluated in ITS OWN
# unit frame — a 0.8 m square, its shipped field_size — with its own constants: the
# +0.01 softening in the inverse-square denominators, the 0.2 m dipole offset from a
# source_position that defaults to the origin (so the dipole is OFF-CENTRE; centring it
# would be tidier and would not be its field), and the vortex profile d/(d² + 0.02).
# Only the drawing gauge is the room's: the unit square is mapped onto a 1.10 m panel.
#
# THE PLANE IS RELABELLED, AND THAT IS A MEASURED DECISION. Every source draws its field
# on a HORIZONTAL plane. [[particle_flow_swarm]] measured what that costs on the capture
# bench: "the rig's pitch is -0.26 rad, so the plane is seen at 15 degrees and
# foreshortened by 0.26" — its whole subject peaked at 2.02% of frame and it needed
# framing 0.6 to say anything at all. The room stands the field UP: the four panels are
# vertical, and at the rig's yaw of 0.62 rad they project at cos(35.5°) x cos(14.9°) =
# 0.79 of their true area instead of 0.26. Same law, same constants, x/z swapped for
# x/y. Under `gravity` this is not merely cheaper, it is the only orientation where a
# uniform downward field is a picture at all — flat on a table it is 64 arrows seen end
# on.
#
# THE SECOND AXIS IS `coding`, AND IT IS ROOM-WIDE. Held fixed across three different
# KINDS of picture, it says something neither source could: what the colour claims is a
# choice separable from what kind of drawing you are looking at. Each source has exactly
# one kind of picture, so each could only ever show the choice inside one of them.
#
# FIVE WORDS REFUSED, each for a reason:
#
#   `field` (vector_field_grid, particle_flow_swarm: cells·orbit·sink·saddle·shear).
#       PANEL 4 DECIDES THIS. Four of those five values are the same linear rule
#       ẋ = A·p with a different matrix, so the plate would print one equation five
#       times over. `law`'s four values are four different equations with four different
#       falloffs, which is what a room with a LAW PANEL in it needs. The corpus already
#       holds these two words apart on exactly this ground; the room simply lands on the
#       side its fourth reading requires.
#   `evidence` (force_field_visualizer, weather_vector_field). The room's 2x2 layout
#       ALREADY IS a disclosure ladder — samples, structure, effect, symbols — laid out
#       in space rather than turned by a knob. Declaring it as well would give the sweep
#       two words for one drawing, which is the ground [[launch_arc]] refused
#       `foresight` on. Worse, an `evidence` axis on this host would have to hide whole
#       panels, and a room that hides three quarters of itself is not four readings.
#   `trace` (particle_flow_swarm: points·wake·streamline). Room-wide this would DESTROY
#       the exhibit at one of its own values: `streamline` drops the head emphasis and
#       turns each body into the field's integral curve, which is exactly what panel 2
#       already is. One value of the axis would collapse two of the four readings into
#       one. Panel 3 is therefore pinned at `wake` — the rung where a body still has
#       both a position and a history — and the pinning is the finding.
#   `poles` (vector_fields: dipole·sink·source·binary). It names what MAKES the field
#       while `law` names which rule it obeys, and vector_fields drew that distinction
#       itself. Here the two collide: `dipole` is in both lists meaning the same
#       picture, and this room's `law` list already contains a superposition.
#   `boundary` (force_field_zone: flow·cage·corners·open). How a place declares its edge
#       is mounting, not argument — and the panel plates and backing board must stand at
#       every value of both axes, because they are what pins the capture AABB.
#
# ALSO REFUSED: force_field_zone's OWN four values for the word `law` (gravity · lift ·
# crossing · weightless). All four are UNIFORM vectors, one vector everywhere, and three
# of this room's four readings only say something when the field varies with position —
# under that list the streamlines would be parallel lines and the population a uniform
# drift at four different headings. `gravity` appears in both lists meaning the same
# thing, which is the honesty test for a shared word, and it is the one value the two
# lists agree on.
#
# DETERMINISTIC AND STILL-VISIBLE. No _process, no timers, no physics bodies, no player,
# no Area3D. The only randomness is the population scatter and it is SEEDED BY DEFAULT
# (population_seed = 3, never a 0-means-unseeded path), so there is no fixture to
# supply: one still is a complete account of this artifact at any value.
#
# THE AABB CANNOT COLLAPSE. The backing board, the two feet and the four panel plates
# are MeshInstance3D standing at every value of both axes and spanning the whole
# subject, so the sweep's fixed camera is pinned by honest geometry — no layers=0 anchor
# is needed, and none would be honest, since a wall's footprint IS its extent. Every
# Label3D is unbillboarded and lies inside the wall's own outline, which closes the
# typographic floor [[foresight_range]] hit (billboarded plates are not in the AABB the
# rig fits to, and they were what stopped it framing tighter).
# ─────────────────────────────────────────────────────────────────────────────

## The family's value lists, READ from their homes rather than retyped — the
## slot_machine pattern. If the family ever revises a list this room follows it instead
## of contradicting it. The literal @export_enum lines below are written out as well,
## because the declaration gate reads the enum and GDScript cannot build one from a
## const; the two cannot disagree silently, since every word a map hands in is validated
## against these preloaded tables and anything unrecognised keeps the value already held.
const LAW_SOURCE := preload("res://commons/artifacts/force_field_visualizer/force_field_visualizer.gd")
const CODING_SOURCE := preload("res://algorithms/change/vector_field_grid.gd")

## AXIS — WHICH RULE the space obeys, at all four readings at once. The word and its four
## values are [[force_field_visualizer]]'s, character for character.
##   gravity        F = (0, -g, 0). Uniform: no source, no falloff, no centre. The only
##                  value where position carries no information at all
##   point_charge   F = k·r̂/r². One source, radial, inverse-square
##   dipole         F₊ + F₋. Two sources 0.2 apart with opposite sign, so the picture is
##                  a SUM and the cancelling mid-line is drawn by arithmetic
##   vortex         tangent(r)·profile(|r|). Curl: nothing enters or leaves
## DEFAULT dipole, not the source's point_charge. A synthesis has no shipped placements,
## so the default is a free design choice and this one is made for the room: dipole is
## the value where the four readings DISAGREE MOST, and the disagreement is the exhibit.
@export_enum("gravity", "point_charge", "dipole", "vortex") var law: String = "dipole"

## AXIS — WHAT THE TINT CLAIMS, across all three drawing panels at once. The word and its
## four values are [[vector_field_grid]]'s, character for character, and [[vector_fields]]
## already took them once on exactly this ground.
##   magnitude   the continuum — cool to hot on |F|
##   direction   heading as hue, the optical-flow convention; speed is not in the colour
##   banded      four classes instead of a ramp — the choropleth claim
##   uniform     no colour channel at all; length and density carry everything
## Mark LENGTH and particle DENSITY carry |F| at every value, so `uniform` withholds the
## colour without withholding the magnitude — vector_field_grid's rule, kept.
@export_enum("magnitude", "direction", "banded", "uniform") var coding: String = "magnitude"

## The population panel's scatter. Seeded at every value including the default: an
## unseeded draw would make four values of `law` four different clouds and the sweep
## would measure the RNG. Left configurable so a room can re-deal, never so it can
## un-seed.
@export var population_seed: int = 3

## Panel edge in metres. The room's gauge; the field is computed in the source's 0.8 m
## frame and mapped onto this.
@export var panel_size: float = 1.10
## Gap between panels, and the margin the backing board adds beyond them.
@export var gutter: float = 0.12

# ── The source's frame. force_field_visualizer's own numbers, not re-derived. ─────
const SRC_FIELD: float = 0.8            # its shipped field_size
const SRC_HALF: float = 0.4
const SRC_DIPOLE_SEP: float = 0.2       # its Vector3(0.2, 0, 0) second source
const SRC_SOFTEN: float = 0.01          # the +0.01 in the inverse-square denominators
const SRC_VORTEX_SOFTEN: float = 0.02   # the +0.02 in the vortex profile
const SRC_STRENGTH: float = 1.0         # its field_strength default
const SRC_DEAD: float = 0.01            # the radius inside which it returns ZERO

# ── The integrator. force_field_visualizer's `_ev_integrate`, constants and all. ──
const STEP_DT: float = 0.012            # EV_STREAM_DT, in source units per step
const STREAM_STEPS: int = 45            # EV_STREAM_STEPS, each way from a seed
const GLYPH_N: int = 8                  # its grid_resolution default

# SEED COUNT AND RIBBON WIDTH ARE THE ROOM'S, and this is the one place the source's
# literals are not kept. Its 5x5 seeds at 0.003 half-width are a bench drawing read at
# arm's length; at this room's ~200 px/m they are 1.5 px, the sub-pixel fault
# [[foresight_range]] paid a whole pass for. Holding the seed count and re-gauging the
# ribbon would flood the panel instead: 25 curves at a resolvable width cover 90% of a
# 1.10 m plate. So 16 seeds at 0.024 m — 4.9 px of ribbon with 14 px of gap — and the
# INTEGRATOR is untouched.
const STREAM_SEEDS: int = 4             # 4x4 lattice
const RIBBON_HW: float = 0.012          # half-width, metres

const POP_N: int = 120                  # bodies dropped on the field
const POP_STEPS: int = 30               # how far each is advected before the shutter
const POP_WAKE: int = 6                 # upstream beads behind each head
const POP_HEAD_R: float = 0.016

# ── Glyph gauge. Thickness is the room's pen; LENGTH is the field's magnitude. ────
const SHAFT_R: float = 0.011
const SHAFT_MIN: float = 0.028
const SHAFT_MAX: float = 0.090
const HEAD_R: float = 0.026
const HEAD_H: float = 0.036

# ── Colour. vector_field_grid's own two literals for the ramp; force_field_visualizer's
#    own two for the source markers. ────────────────────────────────────────────
const COOL := Color(0.85, 0.85, 1.0)        # vector_field_grid.arrow_color
const HOT := Color(1.0, 0.55, 0.25)         # vector_field_grid.arrow_color_hot
const SOURCE_POS_COL := Color(1.0, 0.8, 0.3)    # force_field_visualizer.color_source
const SOURCE_NEG_COL := Color(0.3, 0.5, 1.0)    # force_field_visualizer.color_negative
const PROBE_COL := Color(0.95, 0.97, 1.0)
const PLATE_COL := Color(0.10, 0.11, 0.14)
const BOARD_COL := Color(0.055, 0.06, 0.075)
const TEXT_COL := Color(0.88, 0.92, 1.0)

## THE PROBE. One point, read four ways: a ring at the same place in the three drawing
## panels and the field's value there printed on the fourth. It sits on x = 0.10, which
## under `dipole` is the perpendicular bisector of the two sources — where the vertical
## components cancel exactly and the sum is purely horizontal. The plate prints a number
## that is neither of its two terms, which is what a superposition means.
const PROBE_U := Vector2(0.10, 0.16)
const PROBE_R_IN: float = 0.028
const PROBE_R_OUT: float = 0.044

const LIFT_RIBBON: float = 0.014
const LIFT_MARK: float = 0.020
const LIFT_SOURCE: float = 0.045
const LIFT_PROBE: float = 0.030

const BASE_Y: float = 0.18

## The equations, and the glosses beside them, are [[force_field_visualizer]]'s own
## `_update_info` strings — the plate carries the source's words, not a paraphrase.
const LAW_TEXT := {
	"gravity": ["F = (0, -g, 0)", "uniform downward"],
	"point_charge": ["F = k * r / |r|³", "inverse-square"],
	"dipole": ["F = F₊ + F₋", "two opposing charges"],
	"vortex": ["F = tangent(r) × profile(|r|)", "curl field"],
}

var _stage: Node3D
var _built: bool = false
var _peak: float = 1.0


func _ready() -> void:
	_build()
	_built = true


## Guarded twice, the force_pad trap closed: a word is taken only when it VALIDATES
## against the family's own table AND DIFFERS from what is held, and the rebuild fires
## only after _ready has built once. A config call naming nothing this artifact owns
## reaches no assignment and tears nothing down.
func apply_grid_config(config_data: Dictionary) -> void:
	var dirty: bool = false
	if config_data.has("law"):
		var l: String = str(config_data["law"]).strip_edges().to_lower()
		var laws: PackedStringArray = LAW_SOURCE.LAWS
		if laws.has(l) and l != law:
			law = l
			dirty = true
	if config_data.has("coding"):
		var c: String = str(config_data["coding"]).strip_edges().to_lower()
		var codings: Array = CODING_SOURCE.CODINGS
		if codings.has(c) and c != coding:
			coding = c
			dirty = true
	if config_data.has("population_seed"):
		var s: int = int(config_data["population_seed"])
		if s != population_seed:
			population_seed = s
			dirty = true
	if not _built or not dirty:
		return
	_rebuild()


func _rebuild() -> void:
	if is_instance_valid(_stage):
		remove_child(_stage)
		_stage.queue_free()
	_stage = null
	_build()


# ── THE FIELD. The only place in this file a force is computed. ──────────────────
# force_field_visualizer's `_calculate_field`, in its own unit frame, with its own
# constants — the x/z plane relabelled x/y so the field can stand up. `law` is validated
# here as well as at the config hook, so a value the code does not know renders the
# shipped point_charge rather than blanking the room.

func _field_at(u: Vector2) -> Vector2:
	match _valid_law():
		"gravity":
			return Vector2(0.0, -SRC_STRENGTH)
		"dipole":
			var p2 := Vector2(SRC_DIPOLE_SEP, 0.0)
			var r1: Vector2 = u
			var r2: Vector2 = u - p2
			var d1: float = r1.length()
			var d2: float = r2.length()
			var f1 := Vector2.ZERO
			var f2 := Vector2.ZERO
			if d1 > SRC_DEAD:
				f1 = r1.normalized() * SRC_STRENGTH / (d1 * d1 + SRC_SOFTEN)
			if d2 > SRC_DEAD:
				f2 = -r2.normalized() * SRC_STRENGTH / (d2 * d2 + SRC_SOFTEN)
			return f1 + f2
		"vortex":
			var dv: float = u.length()
			if dv < SRC_DEAD:
				return Vector2.ZERO
			var tangent: Vector2 = Vector2(-u.y, u.x).normalized()
			var profile: float = dv / (dv * dv + SRC_VORTEX_SOFTEN)
			return tangent * SRC_STRENGTH * profile
	# point_charge — the source's shipped FieldType default, and the fallback for any
	# word the code does not know.
	var d: float = u.length()
	if d < SRC_DEAD:
		return Vector2.ZERO
	return u.normalized() * SRC_STRENGTH / (d * d + SRC_SOFTEN)


func _valid_law() -> String:
	var laws: PackedStringArray = LAW_SOURCE.LAWS
	return law if laws.has(law) else "point_charge"


## The centres of the live sources, in source units, and whether each pulls. gravity has
## none: its source is a plane, not a point — force_field_visualizer's own reasoning for
## drawing straight rules instead of rings at that value.
func _source_marks() -> Array:
	match _valid_law():
		"gravity":
			return []
		"dipole":
			return [[Vector2.ZERO, true], [Vector2(SRC_DIPOLE_SEP, 0.0), false]]
		"vortex":
			return [[Vector2.ZERO, true]]
	return [[Vector2.ZERO, true]]


## LOG-NORMALISED, and the reason is the source's own: "an inverse-square field spans
## four decades, and a linear ramp would print one white dot on a black square". That is
## force_field_visualizer's finding about its longhand PLATES; here it is applied to the
## tint AND to the arrow length, because a linear clamp saturates almost every arrow on
## this room's lattice and would leave the magnitude channel carrying nothing.
func _tone(mag: float) -> float:
	var denom: float = log(1.0 + _peak)
	if denom < 0.00001:
		return 0.0
	return clampf(log(1.0 + mag) / denom, 0.0, 1.0)


## vector_field_grid's `_tint_for`, its four branches and its two colour literals, with
## atan2(dir.z, dir.x) relabelled for the room's plane.
##
## A DIVERGENCE WAS TRIED HERE AND REVERTED, and the measurement is worth more than the
## change would have been. The source anchors its four classes to the ENDS of the ramp —
## floor(t*4)/3 sends them to 0, 1/3, 2/3, 1 — so a cell at t = 1.0 is reported by the
## choropleth at exactly its true value. Under `law = gravity`, which is a uniform field,
## every sample is the peak, every tone is 1.0, and `banded` and `magnitude` come out
## identical to the byte. The registry's `predicted_degeneracy` had computed that before
## the first capture; the sweep confirmed it at 0.00%.
##
## The repair attempted was to draw each class at its MIDPOINT instead — 1/8, 3/8, 5/8,
## 7/8 — on the argument that a choropleth reports each class by a representative value
## and should therefore never coincide with the continuum. It fixed gravity, 0.00% to
## 3.40%. It also made every other law WORSE, because a class drawn at its midpoint is by
## construction CLOSER to the values it stands for than one flung to the end of the scale:
##
##                    endpoint    midpoint
##     gravity           0.00%       3.40%    fixed
##     vortex            2.16%       0.54%    lost three quarters of it
##     point_charge      0.37%       0.19%
##     dipole            0.24%       0.10%
##
## The more faithful classing is the weaker axis, which is not a paradox — it is what
## faithful means. Reverted to the family's arithmetic. The gravity pair stays at 0.00%
## and stays TRUE: a ramp and a four-class legend cannot disagree about a field that has
## one value in it, and `uniform` and `direction` still separate there.
func _tint(dir: Vector2, t_mag: float) -> Color:
	match coding:
		"direction":
			var hue: float = fposmod(atan2(dir.y, dir.x), TAU) / TAU
			return Color.from_hsv(hue, 0.65, 1.0)
		"banded":
			var band: float = floor(clamp(t_mag, 0.0, 0.999) * 4.0) / 3.0
			return COOL.lerp(HOT, band)
		"uniform":
			return COOL
	return COOL.lerp(HOT, t_mag)


## March the normalised field from `start`; sign_dir = +1 downstream, -1 upstream. Stops
## at the domain edge or wherever the field dies — the centre of a vortex, the surface of
## a charge. force_field_visualizer's `_ev_integrate`, unchanged but for the plane.
func _integrate(start: Vector2, sign_dir: float, steps: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var p: Vector2 = start
	for _s in range(steps):
		var f: Vector2 = _field_at(p)
		if f.length() < 0.0001:
			break
		p = p + f.normalized() * (STEP_DT * sign_dir)
		if absf(p.x) > SRC_HALF or absf(p.y) > SRC_HALF:
			break
		out.append(p)
	return out


# ── BUILD ────────────────────────────────────────────────────────────────────────

func _build() -> void:
	_stage = Node3D.new()
	_stage.name = "Room"
	add_child(_stage)

	_peak = _peak_magnitude()

	var span: float = 2.0 * panel_size + gutter
	var half_pitch: float = (panel_size + gutter) * 0.5
	var top_y: float = BASE_Y + panel_size + gutter + panel_size * 0.5
	var bot_y: float = BASE_Y + panel_size * 0.5

	_build_backing(span)

	_build_panel(Vector3(-half_pitch, top_y, 0.0), "GLYPHS", 0)
	_build_panel(Vector3(half_pitch, top_y, 0.0), "STREAMLINES", 1)
	_build_panel(Vector3(-half_pitch, bot_y, 0.0), "POPULATION", 2)
	_build_panel(Vector3(half_pitch, bot_y, 0.0), "LAW", 3)


func _peak_magnitude() -> float:
	var peak: float = 0.0
	var cell: float = SRC_FIELD / float(GLYPH_N)
	for j in range(GLYPH_N):
		for i in range(GLYPH_N):
			var u := Vector2(
				-SRC_HALF + (float(i) + 0.5) * cell,
				-SRC_HALF + (float(j) + 0.5) * cell)
			peak = maxf(peak, _field_at(u).length())
	return peak


## The board, the feet and the plates. Present at every value of both axes; this is what
## the capture camera is fitted to and why the frame cannot drift when the marks change.
func _build_backing(span: float) -> void:
	var board := MeshInstance3D.new()
	board.name = "Board"
	var bm := BoxMesh.new()
	bm.size = Vector3(span + gutter * 0.8, span + gutter * 0.8, 0.05)
	board.mesh = bm
	board.material_override = _flat(BOARD_COL)
	board.position = Vector3(0.0, BASE_Y + span * 0.5, -0.035)
	_stage.add_child(board)

	# Height 0.14 against a board whose lower edge sits at 0.132, so the two OVERLAP by
	# 8 mm. Meeting them exactly would leave the board apparently floating the moment
	# either dimension is configured a hair differently.
	for s in [-1.0, 1.0]:
		var foot := MeshInstance3D.new()
		foot.name = "Foot"
		var fm := BoxMesh.new()
		fm.size = Vector3(0.18, BASE_Y - 0.04, 0.34)
		foot.mesh = fm
		foot.material_override = _flat(BOARD_COL)
		foot.position = Vector3(float(s) * (span * 0.42), (BASE_Y - 0.04) * 0.5, 0.0)
		_stage.add_child(foot)


func _build_panel(at: Vector3, caption: String, kind: int) -> void:
	var root := Node3D.new()
	root.name = "Panel_%s" % caption
	root.position = at
	_stage.add_child(root)

	var plate := MeshInstance3D.new()
	plate.name = "Plate"
	var pm := BoxMesh.new()
	pm.size = Vector3(panel_size, panel_size, 0.02)
	plate.mesh = pm
	plate.material_override = _flat(PLATE_COL)
	plate.position = Vector3(0.0, 0.0, -0.005)
	root.add_child(plate)

	var label := Label3D.new()
	label.name = "Caption"
	label.text = caption
	label.font_size = 28
	label.pixel_size = 0.0034
	label.modulate = TEXT_COL
	label.position = Vector3(0.0, panel_size * 0.5 + 0.055, 0.01)
	root.add_child(label)

	match kind:
		0:
			_draw_glyphs(root)
			_draw_sources(root)
			_draw_probe(root)
		1:
			_draw_streamlines(root)
			_draw_sources(root)
			_draw_probe(root)
		2:
			_draw_population(root)
			_draw_sources(root)
			_draw_probe(root)
		3:
			_draw_law_plate(root)


## Source units -> panel-local metres. The whole of the room's gauge, in one line.
func _to_panel(u: Vector2) -> Vector2:
	return u * (panel_size / SRC_FIELD)


# ── PANEL 1 — GLYPHS ─────────────────────────────────────────────────────────────
# An 8x8 lattice, force_field_visualizer's own grid_resolution default, on its own cell
# formula. Two MultiMeshes, shaft and head, exactly as the source renders arrows. The
# per-instance basis is a pure Z rotation because the field lies in the panel's plane —
# no looking_at, so no degenerate up-vector to guard.

func _draw_glyphs(root: Node3D) -> void:
	var cell: float = SRC_FIELD / float(GLYPH_N)
	var n: int = GLYPH_N * GLYPH_N

	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = SHAFT_R
	shaft_mesh.bottom_radius = SHAFT_R
	shaft_mesh.height = 1.0
	shaft_mesh.radial_segments = 8
	var shaft_mm := MultiMesh.new()
	shaft_mm.transform_format = MultiMesh.TRANSFORM_3D
	shaft_mm.use_colors = true
	shaft_mm.mesh = shaft_mesh
	shaft_mm.instance_count = n

	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = HEAD_R
	head_mesh.height = HEAD_H
	head_mesh.radial_segments = 10
	var head_mm := MultiMesh.new()
	head_mm.transform_format = MultiMesh.TRANSFORM_3D
	head_mm.use_colors = true
	head_mm.mesh = head_mesh
	head_mm.instance_count = n

	var idx: int = 0
	for j in range(GLYPH_N):
		for i in range(GLYPH_N):
			var u := Vector2(
				-SRC_HALF + (float(i) + 0.5) * cell,
				-SRC_HALF + (float(j) + 0.5) * cell)
			var f: Vector2 = _field_at(u)
			var mag: float = f.length()
			var base: Vector2 = _to_panel(u)
			if mag < 0.0001:
				var hidden := Transform3D(
					Basis.IDENTITY.scaled(Vector3.ONE * 0.001), Vector3(0.0, 0.0, -8.0))
				shaft_mm.set_instance_transform(idx, hidden)
				head_mm.set_instance_transform(idx, hidden)
				idx += 1
				continue
			var dir: Vector2 = f.normalized()
			var tone: float = _tone(mag)
			var col: Color = _tint(dir, tone)
			var shaft_len: float = lerpf(SHAFT_MIN, SHAFT_MAX, tone)
			var ang: float = atan2(dir.y, dir.x) - PI * 0.5
			var rot := Basis(Vector3(0.0, 0.0, 1.0), ang)
			var d3 := Vector3(dir.x, dir.y, 0.0)
			var origin := Vector3(base.x, base.y, LIFT_MARK)

			var shaft_xf := Transform3D(
				rot * Basis.IDENTITY.scaled(Vector3(1.0, shaft_len, 1.0)),
				origin + d3 * (shaft_len * 0.5))
			shaft_mm.set_instance_transform(idx, shaft_xf)
			shaft_mm.set_instance_color(idx, col)

			var head_xf := Transform3D(rot, origin + d3 * (shaft_len + HEAD_H * 0.5))
			head_mm.set_instance_transform(idx, head_xf)
			head_mm.set_instance_color(idx, col)
			idx += 1

	var shaft_node := MultiMeshInstance3D.new()
	shaft_node.name = "GlyphShafts"
	shaft_node.multimesh = shaft_mm
	shaft_node.material_override = _ink()
	root.add_child(shaft_node)

	var head_node := MultiMeshInstance3D.new()
	head_node.name = "GlyphHeads"
	head_node.multimesh = head_mm
	head_node.material_override = _ink()
	root.add_child(head_node)


# ── PANEL 2 — STREAMLINES ────────────────────────────────────────────────────────
# The arrows joined up. Seeds on force_field_visualizer's own lattice formula, its own
# 45 steps each way at its own dt, integrated on the NORMALISED field so step length is
# uniform and a strong region does not eat the budget. Drawn as ribbons rather than line
# primitives for its stated reason: a line renders one pixel wide and would be measured
# as noise, a ribbon is geometry. Vertex-coloured, so `coding` runs ALONG each curve —
# under `direction` a streamline changes hue as it turns, which is the one place in this
# room where the tint rule and the drawing are the same gesture.

func _draw_streamlines(root: Node3D) -> void:
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.name = "Streamlines"
	mi.mesh = im
	mi.material_override = _ink()

	var step: float = SRC_FIELD / float(STREAM_SEEDS + 1)
	var n: int = 0
	for j in range(STREAM_SEEDS):
		for i in range(STREAM_SEEDS):
			var seed_u := Vector2(
				-SRC_HALF + step * float(i + 1),
				-SRC_HALF + step * float(j + 1))
			var back: PackedVector2Array = _integrate(seed_u, -1.0, STREAM_STEPS)
			var fwd: PackedVector2Array = _integrate(seed_u, 1.0, STREAM_STEPS)
			var path := PackedVector2Array()
			for k in range(back.size()):
				path.append(back[back.size() - 1 - k])
			path.append(seed_u)
			path.append_array(fwd)
			# EACH RIBBON ON ITS OWN 0.2 mm SHELF. Under `gravity` the sixteen seeds
			# trace only four distinct lines — a uniform field has as many streamlines
			# as it has distinct starting columns, which is the reading — so four
			# ribbons land on each other exactly, and coincident coplanar strips are how
			# a still acquires a stipple pattern that is a fact about the depth buffer.
			_ribbon(im, path, LIFT_RIBBON + float(n) * 0.0002)
			n += 1

	root.add_child(mi)


func _ribbon(im: ImmediateMesh, path: PackedVector2Array, lift: float) -> void:
	if path.size() < 2:
		return
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(path.size()):
		var a: Vector2 = path[i]
		var b: Vector2 = path[mini(i + 1, path.size() - 1)]
		if i == path.size() - 1:
			b = a + (a - path[i - 1])
		var d: Vector2 = b - a
		if d.length() < 0.00001:
			d = Vector2.RIGHT
		var f: Vector2 = _field_at(a)
		var col: Color = _tint(f.normalized(), _tone(f.length()))
		var pa: Vector2 = _to_panel(a)
		var perp: Vector2 = Vector2(-d.y, d.x).normalized() * RIBBON_HW
		im.surface_set_color(col)
		im.surface_add_vertex(Vector3(pa.x + perp.x, pa.y + perp.y, lift))
		im.surface_set_color(col)
		im.surface_add_vertex(Vector3(pa.x - perp.x, pa.y - perp.y, lift))
	im.surface_end()


# ── PANEL 3 — POPULATION ─────────────────────────────────────────────────────────
# 120 bodies dropped on the field and advected by the SAME integrator the streamlines
# use, then photographed where they ended up. What this panel says that panel 2 cannot
# is DENSITY: under dipole the population evacuates one source and piles at the other,
# and the road between them is drawn by how few bodies are standing on it.
#
# Two rules taken from [[particle_flow_swarm]] verbatim. The wake is INTEGRATED
# BACKWARDS from the head rather than recorded, so it needs no history and is the same
# on frame one and frame one thousand. And a body that reaches the domain edge is PARKED
# at the last point inside it rather than wrapped — the swarm's wrap-around is
# bookkeeping for keeping a plane populated, and here it would claim a crossing the
# field never made. Under gravity that parking is the reading: a uniform field just moves
# everything one way and the population heaps against the floor.

func _draw_population(root: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = population_seed

	var mesh := SphereMesh.new()
	mesh.radius = POP_HEAD_R
	mesh.height = POP_HEAD_R * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = POP_N * (1 + POP_WAKE)

	var stride: int = 1 + POP_WAKE
	for i in range(POP_N):
		var p := Vector2(
			rng.randf_range(-SRC_HALF, SRC_HALF),
			rng.randf_range(-SRC_HALF, SRC_HALF))
		for _s in range(POP_STEPS):
			var f: Vector2 = _field_at(p)
			if f.length() < 0.0001:
				break
			var nxt: Vector2 = p + f.normalized() * STEP_DT
			if absf(nxt.x) > SRC_HALF or absf(nxt.y) > SRC_HALF:
				break
			p = nxt

		var fh: Vector2 = _field_at(p)
		var col: Color = _tint(fh.normalized(), _tone(fh.length()))
		var base: int = i * stride
		var head: Vector2 = _to_panel(p)
		mm.set_instance_color(base, col)
		mm.set_instance_transform(base, Transform3D(
			Basis.IDENTITY, Vector3(head.x, head.y, LIFT_MARK)))

		var q: Vector2 = p
		var live: bool = true
		for s in range(POP_WAKE):
			if live:
				var vv: Vector2 = _field_at(q)
				if vv.length() < 0.0001:
					live = false
				else:
					var back: Vector2 = q - vv.normalized() * STEP_DT
					if absf(back.x) > SRC_HALF or absf(back.y) > SRC_HALF:
						live = false
					else:
						q = back
			var sc: float = 0.0
			if live:
				sc = lerpf(0.85, 0.50, float(s) / float(maxi(POP_WAKE - 1, 1)))
			var qp: Vector2 = _to_panel(q)
			mm.set_instance_color(base + 1 + s, col)
			mm.set_instance_transform(base + 1 + s, Transform3D(
				Basis.IDENTITY.scaled(Vector3.ONE * sc), Vector3(qp.x, qp.y, LIFT_MARK)))

	var node := MultiMeshInstance3D.new()
	node.name = "Population"
	node.multimesh = mm
	node.material_override = _ink()
	root.add_child(node)


# ── PANEL 4 — LAW ────────────────────────────────────────────────────────────────
# The fourth reading is the one that draws nothing. It is also the only panel `coding`
# does not touch, which is deliberate and is stated in the registry: a colour rule has
# no purchase on a symbol.

func _draw_law_plate(root: Node3D) -> void:
	var words: Array = LAW_TEXT.get(_valid_law(), LAW_TEXT["point_charge"])
	var f: Vector2 = _field_at(PROBE_U)

	var eq := Label3D.new()
	eq.name = "Equation"
	eq.text = "%s\n%s" % [str(words[0]), str(words[1])]
	eq.font_size = 18
	eq.pixel_size = 0.0034
	eq.modulate = TEXT_COL
	eq.position = Vector3(0.0, 0.13, 0.012)
	root.add_child(eq)

	var probe := Label3D.new()
	probe.name = "ProbeValue"
	probe.text = "at p* = (%.2f, %.2f)\nF = (%.2f, %.2f)\n|F| = %.2f" % [
		PROBE_U.x, PROBE_U.y, f.x, f.y, f.length()]
	probe.font_size = 15
	probe.pixel_size = 0.0034
	probe.modulate = PROBE_COL
	probe.position = Vector3(0.0, -0.20, 0.012)
	root.add_child(probe)


# ── Shared marks ─────────────────────────────────────────────────────────────────

## The live sources, at force_field_visualizer's own 0.03 radius and its own two colours.
## They are NOT tinted by `coding`: a source is not a sample of the field, and colouring
## it by a rule about field values would be the one place in the room where the tint
## lied about what it encodes.
func _draw_sources(root: Node3D) -> void:
	var r: float = 0.03 * (panel_size / SRC_FIELD)
	for entry in _source_marks():
		var spec: Array = entry
		var u: Vector2 = spec[0]
		var pull: bool = spec[1]
		var mi := MeshInstance3D.new()
		mi.name = "Source"
		var sm := SphereMesh.new()
		sm.radius = r
		sm.height = r * 2.0
		mi.mesh = sm
		mi.material_override = _flat(SOURCE_POS_COL if pull else SOURCE_NEG_COL)
		var p: Vector2 = _to_panel(u)
		mi.position = Vector3(p.x, p.y, LIFT_SOURCE)
		root.add_child(mi)


## One ring, in the same place in all three drawing panels, so the four readings are
## commensurable: whatever else changes, they are all reading THIS point.
func _draw_probe(root: Node3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Probe"
	var tm := TorusMesh.new()
	tm.inner_radius = PROBE_R_IN
	tm.outer_radius = PROBE_R_OUT
	tm.rings = 24
	tm.ring_segments = 8
	mi.mesh = tm
	mi.material_override = _flat(PROBE_COL)
	# The ring's RADIUS is the room's pen, not a field quantity, so it is not scaled by
	# the gauge — only its POSITION is.
	var p: Vector2 = _to_panel(PROBE_U)
	mi.position = Vector3(p.x, p.y, LIFT_PROBE)
	mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	root.add_child(mi)


## NOTHING IN THIS ROOM IS EMISSIVE, and that is a decision rather than an omission —
## every source in the family lights its arrows with emission, so the departure needs
## saying. Under SHADING_MODE_UNSHADED the surface already renders at its full albedo,
## ignoring the room's light, and emission is ADDED on top. That costs twice here:
##
##   - on the INK it would whiten every mark equally, leaving the geometry moving under
##     `law` while `coding` measured nothing — the six-ways-null table's "axis real,
##     invisible in frame" in a new costume. The sources get away with it because their
##     emission colour is set per material FROM the field value; here one material serves
##     hundreds of differently coloured instances, so the colour must arrive as albedo.
##   - on the MARKERS it clips. force_field_visualizer's gold (1.0, 0.8, 0.3) at any
##     emission above zero saturates its red and green and lands on yellow, and the whole
##     job of that marker under `dipole` is to be distinguishable from the blue one.

## THE INK. Vertex-coloured, so a per-instance or per-vertex colour renders as ITSELF.
func _ink() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.WHITE
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


## A single fixed colour — the board, the plates, the source markers, the probe ring.
func _flat(col: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat
