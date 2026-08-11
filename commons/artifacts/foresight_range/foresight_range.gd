extends Node3D
class_name ForesightRange

# @identity
# essence: four ballistic machines standing on one firing line, all firing the same
#   way down one field. p(t) = p0 + v0*t + 0.5*g*t^2 is computed ONCE and drawn four
#   times with four v0. One parabola family, four machines, four scales.
# desire: to be walked along. To make you look down the row and see that the arcs are
#   not four drawings, they are four readings of one equation.
# critical_parameter: v0 — and only v0. Every station takes the same gravity, and the
#   four gravity arrows are drawn identical length on purpose. What each machine
#   contributes is its own velocity; what is given is given equally.
# triggers: none. Nothing here fires. This is the row of machines BEFORE the button,
#   which is the only moment the word `foresight` is about.
# emerges: reach does not follow size. The mortar is the second-smallest machine on
#   the row and, at the charge it rests at, throws the shortest arc of the four — and
#   it is the only one that can be aimed. It buys range with time, not with timber.
# truth: velocity is what you give, gravity is what is given, and the arc is their sum.
#   Four machines can disagree about everything except the second half of that.

# ─────────────────────────────────────────────────────────────────────────────
# SYNTHESIS (2026-08-06). Sources: catapult, force_pad, human_catapult,
# mortar_vector_siege — four artifacts that were promoted separately and arrived,
# separately, at the same two words. This is what they earned together.
#
# The sources are NOT instanced here. They are heavy interactive machines: two
# consoles with sliders and FIRE buttons, an Area3D that launches the VR player,
# and a swarm of drones with an auto-aim solver. Four of those in one scene would
# be four rooms in a trench coat. What the range needs from each is its SILHOUETTE
# and its NUMBERS, so each station is an icon at the machine's true size, and the
# numbers are the ones its source ships with.
#
# WHAT EACH STATION FIRES WITH — one rule, applied four times: the setting the
# source is standing at BEFORE anything is touched. That rule is not a convenience,
# it is forced by the axis. `foresight` asks how much of the flight is handed to you
# BEFORE you fire; a range showing four machines mid-shot would be a range with no
# foresight in it at all.
#
#   FORCE PAD          v0 = forward 6.0 + up 7.0 m/s   (the two @exports, exactly)
#   MORTAR             v0 = 6.0 m/s at 50 deg          (min_force — what _ready sets;
#                                                       50 deg is the tube's own
#                                                       fallback elevation in
#                                                       _solve_aim_basis)
#   CATAPULT           v0 = 9.0 m/s at 50 deg          (default_force / default_angle)
#   HUMAN CATAPULT     v0 = 12.0 m/s at 52 deg         (launch_force / launch_angle)
#
# ROW ORDER is by machine height — pad 0.25 m, mortar ~1.0 m, catapult ~1.6 m, human
# catapult 3.2 m — because "at increasing scale" is the argument and the registries'
# own footprints say the mortar tube is shorter than the catapult frame (mortar
# [3,1,3] against catapult [2,2,3]). The ranges that come out are 8.7, 4.8, 9.5,
# 15.9 m, which does NOT increase down the row, and that dip is the exhibit: size is
# not reach, v^2 is reach, and the mortar buys its v by holding a trigger.
#
# TWO AXES, BOTH THE FAMILY'S WORDS, character for character, applied RANGE-WIDE:
#
#   foresight   how much of the ARC is handed to you before you fire
#               parabola · apex · landing · none
#   vectors     how "what you give" is drawn at the launch point
#               sum · components · velocity · gravity
#
# Range-wide is the whole point. On one machine the axis is a display option; on four
# at once it is a comparison held at a fixed disclosure, which is the only way to ask
# whether the four machines are saying the same thing. The value lists are not
# retyped — they are read at load out of force_pad.gd's own const tables, so this
# artifact cannot drift from the family even if somebody edits the family.
#
# EACH STATION KEEPS ITS OWN DIALECT. A synthesis that flattens its members into
# examples has thrown away what they learned:
#   - the landing ring is 0.35 m at the pad and the catapult (a stone lands on a
#     point), 0.70 m at the human catapult (a BODY lands, and it is player-sized),
#     and 2.2 m at the mortar — its true aoe_radius, because a mortar lands on an
#     AREA. That ring is wider than the lane and crosses its neighbours. It is not
#     shrunk to be tidy; the overlap is the finding.
#   - the mortar keeps its ring LIT at foresight=parabola as well as at landing,
#     which is exactly what mortar_vector_siege does and no other member does.
#   - apex crosses stand in the ratio 0.16 : 0.35 : 0.16 : 0.28 — each source's own
#     literal, kept exactly — scaled by one common MARK_SCALE for the field. What a
#     dialect carries is the RELATION between the four, and a 0.16 m marker chosen for
#     a 1.6 m catapult is not the same relation once it stands on an 18 m range.
#
# THE ETCHING SAYS WHAT EACH MACHINE IS AND NEVER WHERE IT LANDS. Station plates
# carry the name and v0 and nothing else. Printing the range in metres would hand
# the answer back in text at every value and quietly destroy the axis — catapult's
# `none` exists to withhold the prediction so the machine stops being a promise and
# becomes a wager, and a caption reading "lands at 9.5 m" un-withholds it.
#
# WHAT THIS PAYS BACK TO THE HARNESS. catapult's harness_note recorded that turning
# its preview off COLLAPSED its AABB and re-zoomed the whole tile, so part of its
# measured bite was the camera moving rather than the picture changing; it declined a
# layers=0 anchor because the anchor would have inflated the footprint the sync tool
# writes. The range does not need the trick. The four lane strips and the distance
# ticks are permanent floor geometry spanning the whole field at EVERY value, so the
# box cannot collapse when the arcs go out. The frame is pinned by the exhibit's own
# floor, which is honest geometry rather than an invisible prop.
#
# DETERMINISTIC. No randf anywhere, no _process, no timers, no physics bodies, no
# player. Every number below is a literal or is computed from one. One still is a
# complete account of this artifact at any value.
# ─────────────────────────────────────────────────────────────────────────────

## The family's value lists, READ from a source rather than retyped. force_pad.gd
## holds them as consts; catapult (where the words started) inlines its lists inside
## apply_grid_config, so the pad is the honest place to read them from. If the family
## ever revises a value list, this artifact follows it instead of contradicting it.
const AXIS_SOURCE := preload("res://commons/artifacts/force_pad/force_pad.gd")

## foresight — how much of the arc is handed to you BEFORE you fire, at every station
## at once. parabola: the whole dotted flight. apex: only the summit. landing: only
## where it comes down. none: nothing — read the row from its arrows alone.
@export_enum("parabola", "apex", "landing", "none") var foresight: String = "parabola"

## vectors — how "what you give" is drawn at each launch point. sum: the velocity
## arrow beside the constant gravity arrow. components: the velocity taken apart into
## horizontal and vertical. velocity: the throw alone. gravity: the given alone.
@export_enum("sum", "components", "velocity", "gravity") var vectors: String = "sum"

@export var gravity_magnitude: float = 9.8     # m/s^2, the one constant all four share
@export var lane_pitch: float = 1.8            # metres between firing positions

const FLOOR_Y := 0.0
const FIELD_BACK := -1.4                       # lane strips start behind the firing line
const FIELD_FRONT := 17.0                      # and run past the furthest landing
const LANE_WIDTH := 0.62
const VEL_SCALE := 0.10                        # metres of arrow per (m/s) — catapult's
const GRAV_ARROW_LEN := 0.60                   # IDENTICAL at all four stations, on purpose

# ── MARK GAUGE — the range's, not the bench's. See dna.deepened. ─────────────
# MEASURED: at the sweep's framing an 0.035 m beam was 0.7 px of a 760 px frame, so
# `foresight` was drawn in marks the camera could not resolve and apex against none
# came back at 0.164 per cent — a number about a line width. The arc already had this
# correction (its sources emit hairline ImmediateMesh and it draws beads instead); the
# apex crosses, the plumbs and the landing rings never got it.
#
# WHAT IS PRESERVED AND WHAT IS NOT. The apex crosses keep their RATIOS exactly —
# 0.16 : 0.35 : 0.16 : 0.28, each source's own literal — and are scaled by one common
# factor, because a 0.16 m marker chosen for a 1.6 m catapult is a different RELATION
# on an 18 m field than the one that source drew, and it is the relation the dialect
# was keeping. The landing rings keep their OUTER radius untouched, so the mortar's
# 2.2 m splash is still 2.2 m and still crosses its neighbours' lanes; only the tube
# thickens inward. Line weight lands at 0.15 m, which is the gauge of the exhibit's own
# timber (the human catapult's posts are 0.16 m), so a mark reads as a member of the
# object rather than a wire laid over it.
const MARK_SCALE: float = 2.0                  # apex crosses + launch ticks
const MARK_T: float = 0.15                     # apex cross / launch tick weight
const PLUMB_T: float = 0.11                    # the plumb is a construction line, lighter
const RING_T: float = 0.18                     # landing ring tube, drawn INWARD from r
const CROSS_T: float = 0.12                    # landing crosshairs
const BEAD_R: float = 0.09                     # trajectory bead radius

const VELOCITY_COLOR := Color(0.20, 1.0, 0.55)     # green = the throw
const GRAVITY_COLOR := Color(1.0, 0.30, 0.30)      # red = constant down
const TRAJECTORY_COLOR := Color(1.0, 0.95, 0.55)   # yellow parabola
const COMPONENT_COLOR := Color(0.35, 0.75, 1.0)    # blue = the vertical leg
const LANE_COLOR := Color(0.13, 0.15, 0.18)
const TICK_COLOR := Color(0.42, 0.47, 0.55)

## One row. Every launch number is the source's own shipped rest setting; every
## marker size is the source's own literal. `p0` is the muzzle in station-local
## space, and each icon below is BUILT TO IT, so the arc leaves the machine it
## belongs to rather than floating near it.
const STATIONS: Array = [
	{
		"key": "force_pad", "label": "FORCE PAD", "icon": "pad",
		"speed": 9.2195, "elev": 49.399,          # = forward 6.0 + up 7.0, exactly
		"p0_y": 0.20, "p0_z": 0.0,                # force_pad.LAUNCH_ORIGIN
		"land_r": 0.35, "apex_s": 0.16, "tick": 0.30,
		"ring_at_parabola": false, "plate_y": 0.75, "spec": ""
	},
	{
		"key": "mortar_vector_siege", "label": "MORTAR", "icon": "mortar",
		"speed": 6.0, "elev": 50.0,               # min_force; the solver's fallback elevation
		"p0_y": 0.87, "p0_z": 0.578,
		"land_r": 2.2, "apex_s": 0.35, "tick": 0.30,
		"ring_at_parabola": true, "plate_y": 1.55,
		# The only station whose v0 is an INTERVAL rather than a number: force is a
		# held trigger. At full charge this shell leaves the range entirely, and that
		# is a fact about the machine, so it is etched rather than drawn.
		"spec": "charge band 6 - 22 m/s"
	},
	{
		"key": "catapult", "label": "CATAPULT", "icon": "catapult",
		"speed": 9.0, "elev": 50.0,               # default_force / default_angle_deg
		"p0_y": 1.45, "p0_z": 0.30,
		"land_r": 0.35, "apex_s": 0.16, "tick": 0.28,
		"ring_at_parabola": false, "plate_y": 2.15, "spec": ""
	},
	{
		"key": "human_catapult", "label": "HUMAN CATAPULT", "icon": "human",
		"speed": 12.0, "elev": 52.0,              # launch_force / launch_angle
		"p0_y": 1.75, "p0_z": 0.35,
		"land_r": 0.70, "apex_s": 0.28, "tick": 0.50,
		"ring_at_parabola": false, "plate_y": 3.70, "spec": ""
	}
]

var _foresights: PackedStringArray = AXIS_SOURCE.FORESIGHTS
var _vector_drawings: PackedStringArray = AXIS_SOURCE.VECTOR_DRAWINGS
var _built: bool = false


func _ready() -> void:
	_build_all()
	_built = true


## Map tokens: "foresight_range#foresight:landing", "foresight_range#vectors:components".
##
## GUARDED, the way the family learned to guard it. force_pad and human_catapult both
## shipped an apply_grid_config that freed every child and re-ran _ready() on ANY call,
## including one whose dictionary named nothing they own. Here a rebuild happens only
## when a value we recognise actually CHANGED, and only after the first build.
func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = false
	if config.has("foresight"):
		var f: String = _pick_axis(str(config["foresight"]), _foresights, foresight)
		if f != foresight:
			foresight = f
			changed = true
	if config.has("vectors"):
		var v: String = _pick_axis(str(config["vectors"]), _vector_drawings, vectors)
		if v != vectors:
			vectors = v
			changed = true
	if config.has("lane_pitch"):
		var lp: float = float(config["lane_pitch"])
		if lp > 0.4 and not is_equal_approx(lp, lane_pitch):
			lane_pitch = lp
			changed = true
	if config.has("gravity"):
		var gm: float = float(config["gravity"])
		if gm > 0.01 and not is_equal_approx(gm, gravity_magnitude):
			gravity_magnitude = gm
			changed = true
	if changed and _built:
		_rebuild()


## An unknown string must NOT fall through to a default branch and publish a lie —
## science_screen's failure, where a mistyped value rendered the default and the critic
## reported the artifact inert. Anything we do not recognise keeps the value we hold.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	for a in allowed:
		if v == a:
			return v
	return fallback


func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build_all()


func _build_all() -> void:
	_build_field()
	for i in range(STATIONS.size()):
		var st: Dictionary = STATIONS[i]
		var lane := Node3D.new()
		lane.name = "Station_%s" % str(st["label"]).replace(" ", "")
		lane.position = Vector3(_lane_x(i), 0.0, 0.0)
		add_child(lane)
		_build_icon(lane, str(st["icon"]))
		_build_plate(lane, st)
		_build_vectors(lane, st)
		_build_foresight(lane, st)


func _lane_x(index: int) -> float:
	var span: float = lane_pitch * float(STATIONS.size() - 1)
	return -0.5 * span + lane_pitch * float(index)


# ═════════════════════════════════════════════════════════════════════════
# BALLISTICS — one function, four v0. Everything drawn below goes through it.
# ═════════════════════════════════════════════════════════════════════════

## p(t) = p0 + v0*t + 0.5*g*t^2. The family's line, written once.
func _flight_point(p0: Vector3, v0: Vector3, t: float) -> Vector3:
	return p0 + v0 * t + Vector3(0.0, -0.5 * gravity_magnitude * t * t, 0.0)


## The launch velocity of a station, in station-local space: speed times the direction
## its elevation names. Firing is +Z for every lane, which is what makes the row a row.
func _launch_velocity(st: Dictionary) -> Vector3:
	var a: float = deg_to_rad(float(st["elev"]))
	var s: float = float(st["speed"])
	return Vector3(0.0, sin(a) * s, cos(a) * s)


func _muzzle(st: Dictionary) -> Vector3:
	return Vector3(0.0, float(st["p0_y"]), float(st["p0_z"]))


## Time from the muzzle back down to the floor, from p0.y + v0.y*t - g/2*t^2 = 0.
func _time_to_floor(p0: Vector3, v0: Vector3) -> float:
	var g: float = maxf(gravity_magnitude, 0.001)
	var disc: float = v0.y * v0.y + 2.0 * g * maxf(p0.y - FLOOR_Y, 0.0)
	return (v0.y + sqrt(maxf(disc, 0.0))) / g


func _apex_point(p0: Vector3, v0: Vector3) -> Vector3:
	var t: float = maxf(v0.y / maxf(gravity_magnitude, 0.001), 0.0)
	return _flight_point(p0, v0, t)


func _landing_point(p0: Vector3, v0: Vector3) -> Vector3:
	var t: float = _time_to_floor(p0, v0)
	return Vector3(p0.x + v0.x * t, FLOOR_Y, p0.z + v0.z * t)


# ═════════════════════════════════════════════════════════════════════════
# THE FIELD — lane strips + distance ticks. Permanent at every axis value, so
# the capture box cannot collapse when the arcs go out.
# ═════════════════════════════════════════════════════════════════════════

func _build_field() -> void:
	var length: float = FIELD_FRONT - FIELD_BACK
	var mid: float = FIELD_BACK + 0.5 * length
	for i in range(STATIONS.size()):
		var strip := MeshInstance3D.new()
		strip.name = "Lane_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(LANE_WIDTH, 0.02, length)
		strip.mesh = bm
		strip.position = Vector3(_lane_x(i), 0.01, mid)
		strip.material_override = _matte(LANE_COLOR, 0.9)
		add_child(strip)

	# A ruler, not a prediction: ticks every two metres across all four lanes. It
	# lets the four landings be COMPARED when the axis chooses to draw them, and it
	# says nothing whatever about where anything lands when the axis does not.
	var half: float = 0.5 * lane_pitch * float(STATIONS.size() - 1) + 0.5 * LANE_WIDTH
	var z: float = 2.0
	while z <= FIELD_FRONT - 0.5:
		var tick := MeshInstance3D.new()
		tick.name = "Tick_%d" % int(z)
		var tm := BoxMesh.new()
		tm.size = Vector3(2.0 * half, 0.02, 0.05)
		tick.mesh = tm
		tick.position = Vector3(0.0, 0.025, z)
		tick.material_override = _matte(TICK_COLOR, 0.7)
		add_child(tick)
		z += 2.0

	var title := _make_label(
		"FORESIGHT RANGE\nfour machines  one parabola  g = 9.8", Color(0.85, 0.90, 1.0), 60)
	title.position = Vector3(0.0, 0.95, FIELD_BACK - 0.15)
	add_child(title)


# ═════════════════════════════════════════════════════════════════════════
# ICONS — each machine's silhouette at its true size, built around its muzzle
# ═════════════════════════════════════════════════════════════════════════

func _build_icon(lane: Node3D, kind: String) -> void:
	match kind:
		"pad":
			_icon_pad(lane)
		"mortar":
			_icon_mortar(lane)
		"catapult":
			_icon_catapult(lane)
		_:
			_icon_human(lane)


## force_pad: a 1 x 1 m plate in a recessed dark ring, three forward chevrons, and a
## launch point 0.20 m above it. The whole machine is ankle-high; that is the point.
func _icon_pad(lane: Node3D) -> void:
	_box(lane, Vector3(1.10, 0.06, 1.10), Vector3(0.0, 0.03, 0.0),
		_matte(Color(0.10, 0.12, 0.14), 0.85), "PadBase")
	_box(lane, Vector3(0.92, 0.05, 0.92), Vector3(0.0, 0.09, 0.0),
		_glow(Color(0.12, 0.92, 1.0), 1.6), "PadPlate")
	for i in range(3):
		var z: float = -0.22 + 0.22 * float(i)
		for k in range(2):
			var s: float = -1.0 + 2.0 * float(k)
			var wing := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.30, 0.012, 0.05)
			wing.mesh = bm
			wing.position = Vector3(0.11 * s, 0.12, z)
			wing.rotation = Vector3(0.0, deg_to_rad(38.0 * s), 0.0)
			wing.material_override = _glow(Color(0.55, 0.98, 1.0), 2.2)
			lane.add_child(wing)


## mortar_vector_siege: a low round base, two bipod legs and a 0.9 m tube standing at
## the elevation its own solver falls back to. The muzzle is the tube's tip.
func _icon_mortar(lane: Node3D) -> void:
	var base := MeshInstance3D.new()
	base.name = "MortarBase"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.42
	cm.bottom_radius = 0.46
	cm.height = 0.12
	cm.radial_segments = 20
	base.mesh = cm
	base.position = Vector3(0.0, 0.06, 0.0)
	base.material_override = _matte(Color(0.22, 0.24, 0.27), 0.6)
	lane.add_child(base)

	var elev: float = deg_to_rad(50.0)
	var tube := MeshInstance3D.new()
	tube.name = "MortarTube"
	var tm := CylinderMesh.new()
	tm.top_radius = 0.085
	tm.bottom_radius = 0.095
	tm.height = 0.90
	tm.radial_segments = 14
	tube.mesh = tm
	# The tube's own axis is +Y; tip it back by (90 - elev) so its bore points along
	# the launch direction and its tip lands exactly on the station's p0.
	tube.rotation = Vector3(deg_to_rad(90.0) - elev, 0.0, 0.0)
	tube.position = Vector3(0.0, 0.18 + 0.45 * sin(elev), 0.45 * cos(elev))
	tube.material_override = _matte(Color(0.16, 0.18, 0.20), 0.4)
	lane.add_child(tube)

	for k in range(2):
		var s: float = -1.0 + 2.0 * float(k)
		var leg := MeshInstance3D.new()
		var lm := CylinderMesh.new()
		lm.top_radius = 0.025
		lm.bottom_radius = 0.03
		lm.height = 0.62
		lm.radial_segments = 8
		leg.mesh = lm
		leg.position = Vector3(0.20 * s, 0.30, 0.10)
		leg.rotation = Vector3(deg_to_rad(-16.0), 0.0, deg_to_rad(-20.0 * s))
		leg.material_override = _matte(Color(0.20, 0.22, 0.24), 0.5)
		lane.add_child(leg)


## catapult: A-frame base, torsion pivot, a throwing arm tilted to the release angle
## with a counterweight on the short end and the basket at the tip — at 1.45 m, which
## is the station's p0.
func _icon_catapult(lane: Node3D) -> void:
	var wood := _matte(Color(0.32, 0.22, 0.14), 0.85)
	var arm_mat := _matte(Color(0.45, 0.30, 0.18), 0.8)
	_box(lane, Vector3(0.90, 0.10, 1.70), Vector3(0.0, 0.05, -0.10), wood, "Sill")
	for k in range(2):
		var s: float = -1.0 + 2.0 * float(k)
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.11, 1.00, 0.11)
		post.mesh = pm
		post.position = Vector3(0.34 * s, 0.50, -0.10)
		post.rotation = Vector3(0.0, 0.0, deg_to_rad(9.0 * s))
		post.material_override = wood
		lane.add_child(post)

	var pivot := MeshInstance3D.new()
	pivot.name = "Torsion"
	var tm := CylinderMesh.new()
	tm.top_radius = 0.09
	tm.bottom_radius = 0.09
	tm.height = 0.72
	tm.radial_segments = 14
	pivot.mesh = tm
	pivot.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	pivot.position = Vector3(0.0, 0.98, -0.10)
	pivot.material_override = _matte(Color(0.55, 0.40, 0.20), 0.6)
	lane.add_child(pivot)

	# Arm from the counterweight end up to the basket at (0, 1.45, 0.30).
	var tip := Vector3(0.0, 1.45, 0.30)
	var heel := Vector3(0.0, 0.72, -0.62)
	_beam(lane, heel, tip, 0.085, arm_mat, "ThrowingArm")
	_box(lane, Vector3(0.26, 0.26, 0.26), heel + Vector3(0.0, -0.06, -0.05),
		_matte(Color(0.18, 0.18, 0.20), 0.4), "Counterweight")
	_box(lane, Vector3(0.22, 0.16, 0.22), tip + Vector3(0.0, 0.05, 0.0),
		_matte(Color(0.30, 0.22, 0.12), 0.9), "Basket")
	var stone := MeshInstance3D.new()
	stone.name = "Stone"
	var sm := SphereMesh.new()
	sm.radius = 0.075
	sm.height = 0.15
	sm.radial_segments = 10
	sm.rings = 6
	stone.mesh = sm
	stone.position = tip + Vector3(0.0, 0.10, 0.0)
	stone.material_override = _matte(Color(0.85, 0.55, 0.20), 0.7)
	lane.add_child(stone)


## human_catapult: a heavy 3.2 m timber frame, a long arm, and a basket you stand IN,
## with its floor at 1.75 m — the station's p0, because here the payload is a person.
func _icon_human(lane: Node3D) -> void:
	var timber := _matte(Color(0.30, 0.21, 0.13), 0.9)
	var arm_mat := _matte(Color(0.42, 0.28, 0.17), 0.8)
	_box(lane, Vector3(1.60, 0.14, 2.20), Vector3(0.0, 0.07, -0.25), timber, "Sill")
	for kx in range(2):
		var sx: float = -1.0 + 2.0 * float(kx)
		for kz in range(2):
			var sz: float = -1.0 + 2.0 * float(kz)
			var post := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.16, 3.10, 0.16)
			post.mesh = pm
			post.position = Vector3(0.62 * sx, 1.60, -0.25 + 0.55 * sz)
			post.material_override = timber
			lane.add_child(post)
	_box(lane, Vector3(1.50, 0.16, 0.20), Vector3(0.0, 3.22, -0.25), timber, "HeadBeam")
	for kb in range(2):
		var bx: float = -1.0 + 2.0 * float(kb)
		_beam(lane, Vector3(0.62 * bx, 3.15, -0.25), Vector3(0.62 * bx, 1.30, 0.75),
			0.06, timber, "Brace")

	var tip := Vector3(0.0, 1.75, 0.35)
	var heel := Vector3(0.0, 2.60, -0.95)
	_beam(lane, heel, tip, 0.10, arm_mat, "ThrowingArm")
	_box(lane, Vector3(0.38, 0.38, 0.38), heel + Vector3(0.0, 0.10, -0.10),
		_matte(Color(0.18, 0.18, 0.20), 0.4), "Counterweight")
	# The basket: a floor you stand on and three low walls. Player-sized, which is why
	# this machine's landing ring is 0.70 m and the catapult's is 0.35 m.
	_box(lane, Vector3(0.72, 0.08, 0.72), tip + Vector3(0.0, -0.04, 0.0),
		_matte(Color(0.28, 0.20, 0.12), 0.9), "BasketFloor")
	for kw in range(2):
		var wx: float = -1.0 + 2.0 * float(kw)
		_box(lane, Vector3(0.06, 0.42, 0.72), tip + Vector3(0.36 * wx, 0.21, 0.0),
			timber, "BasketWall")
	_box(lane, Vector3(0.72, 0.42, 0.06), tip + Vector3(0.0, 0.21, -0.36), timber, "BasketBack")


# ═════════════════════════════════════════════════════════════════════════
# vectors — what you give, drawn at the muzzle. sum is the family's thesis:
# one velocity arrow beside one gravity arrow, and the arc is their sum.
# ═════════════════════════════════════════════════════════════════════════

func _build_vectors(lane: Node3D, st: Dictionary) -> void:
	var p0: Vector3 = _muzzle(st)
	var v0: Vector3 = _launch_velocity(st)
	var split: bool = vectors == "components"
	var show_velocity: bool = vectors != "gravity"
	var show_gravity: bool = vectors != "velocity"

	if split:
		# Tip to tail, the catapult's order: the horizontal leg out of the muzzle,
		# then the vertical leg standing on its end. The two legs the elevation
		# trades between, drawn rather than asserted.
		var vx_end: Vector3 = p0 + Vector3(0.0, 0.0, v0.z) * VEL_SCALE
		_arrow(lane, p0, vx_end - p0, VELOCITY_COLOR, "Vx")
		_arrow(lane, vx_end, Vector3(0.0, v0.y, 0.0) * VEL_SCALE, COMPONENT_COLOR, "Vy")
	elif show_velocity:
		_arrow(lane, p0, v0 * VEL_SCALE, VELOCITY_COLOR, "Velocity")

	if show_gravity:
		# Drawn to the SAME length at every station. The velocity arrows differ
		# because the machines differ; this one does not, because g does not.
		_arrow(lane, p0 + Vector3(0.34, 0.0, 0.0),
			Vector3(0.0, -GRAV_ARROW_LEN, 0.0), GRAVITY_COLOR, "Gravity")


# ═════════════════════════════════════════════════════════════════════════
# foresight — how much of the flight is handed over, at all four at once
# ═════════════════════════════════════════════════════════════════════════

func _build_foresight(lane: Node3D, st: Dictionary) -> void:
	if foresight == "none":
		return
	var p0: Vector3 = _muzzle(st)
	var v0: Vector3 = _launch_velocity(st)
	match foresight:
		"apex":
			_emit_apex(lane, st, p0, v0)
		"landing":
			_emit_landing(lane, st, p0, v0)
		_:
			_emit_arc(lane, p0, v0)
			# mortar_vector_siege leaves its splash ring lit at `parabola` as well as
			# at `landing` — the whole solution at once was what it always drew. No
			# other member does this, and the range does not tidy it away.
			if bool(st["ring_at_parabola"]):
				_emit_landing(lane, st, p0, v0)


## foresight:parabola — the whole flight, dotted. The sources emit hairline
## ImmediateMesh segments, which is right at a bench and sub-pixel across a 17 m
## field, so the same sampling is drawn as beads: every other step of p(t), which is
## the sources' own dotting rule, made visible at the range's viewing distance.
func _emit_arc(lane: Node3D, p0: Vector3, v0: Vector3) -> void:
	var total: float = _time_to_floor(p0, v0)
	var steps: int = 44
	var bead := SphereMesh.new()
	bead.radius = BEAD_R
	bead.height = BEAD_R * 2.0
	bead.radial_segments = 8
	bead.rings = 4
	var mat: StandardMaterial3D = _glow(TRAJECTORY_COLOR, 2.0)
	for i in range(1, steps + 1):
		if i % 2 != 0:
			continue
		var t: float = total * float(i) / float(steps)
		var dot := MeshInstance3D.new()
		dot.mesh = bead
		dot.material_override = mat
		dot.position = _flight_point(p0, v0, t)
		lane.add_child(dot)


## foresight:apex — the summit only. How high this throws, and nothing about where it
## comes down: a tick out of the muzzle, a cross at the peak, a plumb line to the floor.
##
## THE PLUMB HAS NO FOOT MARK, and that is not an omission. A cross on the floor under
## the summit would be half the range for any near-symmetric arc, which hands back the
## number this value exists to withhold — [[catapult]]'s `none` reasoning, one rung up.
## It is also why apex is and should remain the THINNEST reading on this axis: it shows
## the least of the flight while still showing something.
func _emit_apex(lane: Node3D, st: Dictionary, p0: Vector3, v0: Vector3) -> void:
	var mat: StandardMaterial3D = _glow(TRAJECTORY_COLOR, 2.0)
	var apex: Vector3 = _apex_point(p0, v0)
	var s: float = float(st["apex_s"]) * MARK_SCALE
	_beam(lane, p0, p0 + v0.normalized() * float(st["tick"]) * MARK_SCALE, MARK_T, mat, "LaunchTick")
	_beam(lane, apex - Vector3(s, 0.0, 0.0), apex + Vector3(s, 0.0, 0.0), MARK_T, mat, "ApexX")
	_beam(lane, apex - Vector3(0.0, s, 0.0), apex + Vector3(0.0, s, 0.0), MARK_T, mat, "ApexY")
	_beam(lane, apex - Vector3(0.0, 0.0, s), apex + Vector3(0.0, 0.0, s), MARK_T, mat, "ApexZ")
	_beam(lane, apex, Vector3(apex.x, FLOOR_Y + 0.02, apex.z), PLUMB_T, mat, "Plumb")


## foresight:landing — the target only, at each machine's OWN radius: a stone lands on
## a point (0.35), a body lands player-sized (0.70), and a mortar lands on an AREA at
## its true 2.2 m splash, which is wider than the lane and crosses its neighbours.
func _emit_landing(lane: Node3D, st: Dictionary, p0: Vector3, v0: Vector3) -> void:
	var hit: Vector3 = _landing_point(p0, v0)
	var r: float = float(st["land_r"])
	var mat: StandardMaterial3D = _glow(TRAJECTORY_COLOR, 1.8)

	var ring := MeshInstance3D.new()
	ring.name = "LandingRing"
	var tm := TorusMesh.new()
	# Thickened INWARD only: outer_radius is the source's own literal and stays put, so
	# the mortar's ring is still 2.2 m and still crosses the lanes either side of it.
	tm.inner_radius = maxf(r - RING_T, 0.02)
	tm.outer_radius = r
	tm.rings = 40
	tm.ring_segments = 8
	ring.mesh = tm
	ring.position = Vector3(hit.x, FLOOR_Y + 0.04, hit.z)
	ring.material_override = mat
	lane.add_child(ring)

	var c: float = r * 0.5
	_beam(lane, Vector3(hit.x - c, FLOOR_Y + 0.04, hit.z),
		Vector3(hit.x + c, FLOOR_Y + 0.04, hit.z), CROSS_T, mat, "CrossX")
	_beam(lane, Vector3(hit.x, FLOOR_Y + 0.04, hit.z - c),
		Vector3(hit.x, FLOOR_Y + 0.04, hit.z + c), CROSS_T, mat, "CrossZ")


# ═════════════════════════════════════════════════════════════════════════
# Etching + small builders
# ═════════════════════════════════════════════════════════════════════════

## Name and v0. Never the range: catapult's `none` exists to withhold the prediction,
## and a plate reading "lands at 9.5 m" would hand it back at every value.
func _build_plate(lane: Node3D, st: Dictionary) -> void:
	var text: String = "%s\nv0 %.1f m/s @ %d deg" % [
		str(st["label"]), float(st["speed"]), int(round(float(st["elev"])))]
	var spec: String = str(st["spec"])
	if spec != "":
		text += "\n" + spec
	var plate := _make_label(text, Color(0.92, 0.95, 1.0), 48)
	plate.position = Vector3(0.0, float(st["plate_y"]), -0.75)
	lane.add_child(plate)


func _make_label(text: String, color: Color, size: int) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.010
	l.modulate = color
	l.outline_size = 8
	l.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D,
		node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


## A box beam from a to b — used for timbers, apex crosses and crosshairs alike, so a
## mark and a member are the same primitive at different thicknesses.
func _beam(parent: Node3D, a: Vector3, b: Vector3, thick: float,
		mat: StandardMaterial3D, node_name: String) -> void:
	var d: Vector3 = b - a
	var l: float = d.length()
	if l < 0.001:
		return
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = Vector3(thick, l, thick)
	mi.mesh = bm
	mi.material_override = mat
	mi.transform = Transform3D(_basis_along(d / l), a + d * 0.5)
	parent.add_child(mi)


## An arrow: shaft + cone head, the family's shape (catapult._create_arrow), built at
## its final length rather than scaled at runtime — nothing here ever moves.
func _arrow(parent: Node3D, origin: Vector3, dir: Vector3, color: Color,
		node_name: String) -> void:
	var l: float = dir.length()
	if l < 0.02:
		return
	var head: float = minf(0.22, l * 0.34)
	var shaft_len: float = maxf(l - head, 0.01)
	var mat: StandardMaterial3D = _glow(color, 1.9)
	var root := Node3D.new()
	root.name = node_name
	root.transform = Transform3D(_basis_along(dir / l), origin)
	parent.add_child(root)

	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.028
	cm.bottom_radius = 0.028
	cm.height = shaft_len
	cm.radial_segments = 10
	shaft.mesh = cm
	shaft.position = Vector3(0.0, shaft_len * 0.5, 0.0)
	shaft.material_override = mat
	root.add_child(shaft)

	var tip := MeshInstance3D.new()
	tip.name = "Head"
	var hm := CylinderMesh.new()
	hm.top_radius = 0.0
	hm.bottom_radius = 0.072
	hm.height = head
	hm.radial_segments = 12
	tip.mesh = hm
	tip.position = Vector3(0.0, shaft_len + head * 0.5, 0.0)
	tip.material_override = mat
	root.add_child(tip)


## A basis whose +Y runs along `dir` (unit). Box and cylinder primitives are built
## along +Y, so every beam and arrow can share one orientation helper.
func _basis_along(dir: Vector3) -> Basis:
	var y_axis: Vector3 = dir
	var ref: Vector3 = Vector3.FORWARD
	if absf(y_axis.dot(ref)) > 0.99:
		ref = Vector3.RIGHT
	var x_axis: Vector3 = ref.cross(y_axis).normalized()
	var z_axis: Vector3 = x_axis.cross(y_axis).normalized()
	return Basis(x_axis, y_axis, z_axis)


func _matte(color: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = 0.05
	return m


func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m
