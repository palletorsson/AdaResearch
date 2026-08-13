extends Node3D
class_name ServiceYard

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

## THE FAMILY WORD, TAKEN WHOLE AND NEVER RETYPED. station_plinth.gd is preloaded because
## it is the script three of the seven registry names in the `upkeep` family resolve to
## (station_plinth, station_plinth_wide, station_micropod), and because it carries the
## const byte for byte identical to the ones in station_wall.gd and station_floorline.gd.
## The four bays, their names, their order and their count all come out of UPKEEPS at
## build time. _check_family_list() validates in both directions at _ready.
const UPKEEP_SRC := preload("res://commons/artifacts/station/station_plinth.gd")

# @identity
# essence: a working yard for ONE piece of equipment held in FOUR conditions at once — four kerbed bays round a quad, the same pump skid parked in every one of them, dressed by the station kit's own `upkeep` vocabulary (service, works, store, scrap) read out of station_plinth.gd's const rather than retyped. A fleet of 16 units is distributed across the bays by a stationary solve, and the routes between the bays are laid in the aisles. Origin at the apron centre; the apron is 6.50 x 4.00 m and its top face is the working ground at y = 0.04.
# desire: to stand the whole life of a machine in one frame. Every one of the seven family members can be caught in exactly one of the four conditions, because a body can only be one way at a time; the yard is the place where all four are visible simultaneously and nobody has to pretend equipment is only ever working.
# critical_parameter: policy — the yard's RULE for a unit that falls due (repair | replace | cannibal | hoard), which sets the whole picture through one stationary solve: how many units stand in each bay, and how much moves along each leg. circuit — how much of the passage between the conditions is drawn (bays | line | loop | traffic).
# triggers: _ready/_read_config_meta/_check_family_list/_solve/_build. apply_grid_config rebuilds only when a value actually changed and only after _ready has built once.
# emerges: at `bays` the four conditions read as a set with no claim about how a thing gets between them — the members' own picture. At `line` the three arrows a value list invites appear, and one of them is a diagonal cutting across the yard to a bay it has no business reaching. At `loop` the six real legs are lit and the diagonal is barred. At `traffic` the same solve is read a second way, as heights.
# needs: an apron [present]; four kerbed bays with lettered name tabs [present]; sixteen copies of one unit, dressed by condition [present]; empty slot outlines so a bay with nothing in it is still a bay [present]; route lanes with standing guide rails [present]; a flow post per leg and a dwell column per bay, both on fixed ceilings [present].
# relationships: the SYNTHESIS of the seven registry names that declare `upkeep` — [[station_wall]], [[station_plinth]], [[station_plinth_wide]], [[station_pillar]], [[station_micropod]], [[station_floorline]], [[station_crates]] — which resolve to five scripts and one const. Replaces none of them and re-runs none of their axes from the outside. Composed by nothing; it is the exhibit the kit's own promotion notes describe and cannot build.
# truth: a condition is a decision somebody made, not a fact about the object. The same skid is service or scrap depending on what the yard's policy says to do with it, and the yard's arithmetic is honest enough to show that the four bays refill differently under four rules that never touch the equipment at all.

# ─────────────────────────────────────────────────────────────────────────────
# WHAT THE FAMILY MEANS BY ITS OWN WORDS, and a divergence worth recording.
#
# The brief that commissioned this yard glossed the four values as: works = in
# operation, service = opened up and being maintained. THE FAMILY'S CODE SAYS THE
# OPPOSITE, in all five scripts and in every one of their promotion blocks:
#
#   service  "in commission — the legacy lineage, byte for byte"   (working)
#   works    "mid-job — a trestle barrier standing ACROSS the run" (opened up)
#
# Both readings are natural English — "in service" is operating, "under works" is
# being worked on — which is exactly why the two drifted. This yard follows the
# CODE, because the code is what 7 registry entries and their live placements
# mean, and because DERIVE-never-transcribe governs. So:
#
#   service  in commission, working, nothing added   — cover on, lamp lit
#   works    opened up, mid-job                      — panel swung out, loom
#                                                      spilling, tool tray,
#                                                      trestle over it
#   store    packed down, sealed                     — sleeved and banded, the
#                                                      lamp under the wrap
#   scrap    robbed, kept for parts                  — cladding gone, core bared,
#                                                      hazard tape, lamp dead
#
# The brief's ARGUMENT survives the swap intact: "the state in which a thing is
# most itself and least useful" is `works`, the one with its guts out.
#
# ─────────────────────────────────────────────────────────────────────────────
# LAW 2 — NEST OR SIDE BY SIDE, decided from the members' CODE, not their prose.
#
# The four values are MIXED, and the mixture is asymmetric:
#
#   works NESTS ON service in 5 of 5 scripts. station_crates._build() runs the
#     whole legacy stack loop and only then, at its last line, calls
#     _upkeep_works(); station_pillar and station_floorline both build the legacy
#     body and append _upkeep_works() after the `match`. works = service + apparatus.
#
#   store and scrap DO NOT NEST, and they are opposite operations.
#     store ADDS A COVERING: pillar wraps a sleeve round the shaft, floorline
#       sheets a board runner over the whole strip. Nothing is removed from the
#       graph; the lit surface is OCCLUDED.
#     scrap SUBTRACTS MATERIAL: pillar swaps the solid shaft for _scrap_shaft()'s
#       stripped frame, floorline rebuilds the lit run as dead metal
#       (`if upkeep == "scrap": lit = HangarKit.worn_metal(...)`).
#     station_crates makes the non-nesting explicit — both values `return` before
#       the legacy loop ever runs, replacing the arrangement outright.
#
# So there is one containment (service < works) inside a set of four conditions of
# which no member contains all the others. That is the PARALLEL case, which is
# exactly the condition under which showing them all at once is NOT merely the top
# value. The yard therefore takes the retention_corridor / slack_yard move: it
# stands all four simultaneously, exhibits the word rather than sweeping it, and
# varies something else.
#
# ─────────────────────────────────────────────────────────────────────────────
# THE ORDER THIS YARD TOOK, AND THE OTHER ONE.
#
# TAKEN:    service, works, store, scrap  — the const, and 6 of the 7 registry entries.
# THE OTHER: service, store, scrap, works — station_crates.json only.
#
# WHY THE OTHER EXISTS, which nobody had written down: station_crates.gd is one of
# the two scripts in the family with NO `const UPKEEPS`. Its registry list is its
# own _build() BRANCH ORDER with the export default hoisted to the front —
# `if upkeep == "store"` at line 117, `if upkeep == "scrap"` at 120, and the
# trailing `if upkeep == "works"` at 161. It is derived from the code; it is just
# derived from a different part of the code.
#
# WHY IT MATTERS: build_dna_gallery trims a value list from the TAIL. The six
# const-order entries end ...store, scrap; crates ends ...scrap, works. So at
# --max 3 the six are measured on {service, works, store} and crates on
# {service, store, scrap} — DIFFERENT SETS, not merely a different tile order —
# and at --max 2 it is {service, works} against {service, store}. The two orders
# agree only at the full 4. (The `slack` family's three orders all agreed down to
# 3; this one does not.) A single-axis `upkeep` sweep must run --max=4 or it
# compares unlike with unlike.
#
# ─────────────────────────────────────────────────────────────────────────────
# THE TWO AXES, and why neither of them is `upkeep`.
#
#   policy   the yard's RULE for a unit that falls due     repair · replace · cannibal · hoard
#   circuit  how much of the PASSAGE between conditions    loop · bays · line · traffic
#            is drawn
#
# `policy` sits SIDE BY SIDE — four institutions, none contained in another.
# `circuit` NESTS — bays < line < loop < traffic, each rung keeping every mark the
# last one drew and adding to it. Declared in that order for law 15: dropping the
# tail of a parallel axis loses a case, dropping the tail of a nested one only
# lowers the ceiling, so the parallel axis is declared FIRST and survives trimming
# whole. At the gallery's default cap of 9 a 4x4 declaration renders 4x2: all four
# policies against [loop, bays], which is the ladder's default and its floor.
# THE FULL SHEET NEEDS --max=16.
#
# ─────────────────────────────────────────────────────────────────────────────
# ONE COPY OF THE ARITHMETIC (law 3). _solve() runs a 4-state stationary solve
# ONCE per build and its result is read THREE ways:
#
#   1. HOW MANY UNITS STAND IN EACH BAY  = largest-remainder round of pi * 16
#   2. HOW MUCH MOVES ALONG EACH LEG     = pi[from] * P[from][to], drawn as a post
#   3. HOW LONG A UNIT DWELLS IN A BAY   = pi itself, drawn as a column
#
# Readings 2 and 3 are summaries of the same numbers and they DISAGREE, which is
# the point of the `traffic` rung: at `hoard` the store bay carries the tallest
# dwell column in the whole sweep (0.600 m) while the two legs that feed it are
# the shortest posts in the whole sweep (0.017 m). A bay can be full because
# things arrive fast or because they never leave, and a still cannot tell you
# which — unless it shows you both numbers.
#
# THE FINDING THE ARITHMETIC PRODUCED, which contradicts the brief that asked for
# it. The brief says the life of a piece of equipment "is not a line but a loop".
# For the OBJECT that is false: scrap is absorbing. A unit that is condemned does
# not come back; the `scrap -> store` leg is not the same skid returning, it is a
# REPLACEMENT being bought. The loop closes through PROCUREMENT, not through the
# thing. What loops is the FLEET; what runs in a line and stops is the unit. So
# the yard's own claim is narrower and truer than the one it was commissioned to
# make, and the `line` rung is not a straw man — one third of it is right.
# ─────────────────────────────────────────────────────────────────────────────

@export_group("Axis")
## THE YARD'S RULE for a unit that falls due. Sets the transition matrix, and through one
## stationary solve it sets how many units stand in each bay and how much moves on each leg.
## It never touches the equipment: four rules, one machine, four different yards.
@export_enum("repair", "replace", "cannibal", "hoard") var policy: String = "repair"
## HOW MUCH OF THE PASSAGE between the four conditions is drawn. A nested ladder: each rung
## keeps every mark the last one drew. bays = no routes; line = the three arrows the family's
## declared value order invites; loop = those plus the six real legs, with the leg that does
## not exist barred; traffic = those plus the flow posts and the dwell columns.
@export_enum("loop", "bays", "line", "traffic") var circuit: String = "loop"

@export_group("Yard")
## How many units the yard holds in total. They are distributed across the four bays by the
## stationary solve; 16 is four bays' worth of the 8-slot grid at half capacity.
@export var fleet: int = 16

@export_group("Surface")
@export var wear: float = 0.10
@export var body_color: Color = Color(0.74, 0.72, 0.68)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

# ── LAYOUT (every number here was measured in a Python replica of this geometry
# ── at this exact camera before a line of it was built; see dna.framing_why) ──
const APRON_X := 6.50
const APRON_Z := 4.00
const APRON_H := 0.04
const GY := 0.04                    # apron top = the working ground. Lowest mesh is y = 0,
                                    # so the grid's base-to-floor grounding is a no-op.
const PAD_X := 2.60
const PAD_Z := 1.30
const PAD_H := 0.06
const PY := 0.10                    # GY + PAD_H, the pad top the units stand on
const BAY_CX := 1.75
const BAY_CZ := 1.00
const SLOT_COLS := 4
const SLOT_ROWS := 2
const SLOT_PX := 0.62
const SLOT_PZ := 0.55
const KERB_W := 0.07
const KERB_H := 0.10
const TAB_W := 0.62
const TAB_H := 0.18
const TAB_Y := 0.70
const LANE_W := 0.22
const LANE_H := 0.012
const RAIL_Y := 0.30
const RAIL_T := 0.09
const POST_T := 0.05
const HEAD_W := 0.28
const HEAD_H := 0.22
const HEAD_Y := 0.40
const GATE_Y := 0.52
const GATE_T := 0.08
const NAIVE_W := 0.30
## FIXED CEILINGS (law 5). A dwell column of height 1.20 m means pi = 1; a flow post of
## height 1.00 m means 0.25 of the fleet moves on that leg per period. Both are 1:1 gauges
## with the same ceiling in every one of the sixteen frames, so a 0.520 m post in the repair
## frame and a 0.193 m post in the hoard frame are the same instrument reading two numbers.
## Neither is normalised to its own frame, its own axis value or its own busiest mark.
const DWELL_CEIL := 1.20
const DWELL_W := 0.26
const FLOW_CEIL := 4.00
const FLOW_LEN := 0.60
const FLOW_T := 0.14
## The datum band each gauge carries: a fixed collar at 0.30 m on a dwell column (pi = 0.25,
## the even-split line) and at 0.40 m on a flow post (flow = 0.10). Present at every value,
## so the ceiling is legible in the picture and not only in this file.
const DWELL_DATUM := 0.30
const FLOW_DATUM := 0.40

## THE SIX REAL LEGS of the fleet circuit, as [from, to, key]. Named in the yard's own
## language: a unit falls DUE and is opened up; it is FIXED and goes back in commission; it
## is STOOD DOWN into store; it is ISSUED back out; it is CONDEMNED; and a replacement is
## bought to stand in its place. Every leg joins two bays that are ADJACENT on the quad, so
## no real leg is a diagonal — that is what `_corner()`'s ordering buys.
const LEGS: Array = [
	["service", "works", "due"],
	["works", "service", "fix"],
	["service", "store", "down"],
	["store", "service", "issue"],
	["works", "scrap", "cond"],
	["scrap", "store", "repl"],
]

## The four rules. Each is six rates on the six legs, and nothing else about the yard changes.
const RATES: Dictionary = {
	# things get fixed; condemnation is rare and the hulks that do appear linger,
	# because a yard that repairs has no procurement habit to dispose of them.
	"repair": {"due": 0.28, "down": 0.06, "fix": 0.55, "cond": 0.05, "issue": 0.28, "repl": 0.06},
	# a unit that is opened up is condemned rather than closed up, and a replacement
	# is bought straight away, so store turns over fast.
	"replace": {"due": 0.28, "down": 0.06, "fix": 0.22, "cond": 0.38, "issue": 0.42, "repl": 0.42},
	# nothing is bought. Units are fixed with parts robbed off the hulks, so `repl`
	# nearly vanishes and the scrap bay becomes the yard's real stores.
	"cannibal": {"due": 0.28, "down": 0.06, "fix": 0.48, "cond": 0.12, "issue": 0.28, "repl": 0.05},
	# units are stood down and not issued. Almost nothing falls due because almost
	# nothing is running.
	"hoard": {"due": 0.14, "down": 0.22, "fix": 0.52, "cond": 0.05, "issue": 0.16, "repl": 0.06},
}

const POLICIES: PackedStringArray = ["repair", "replace", "cannibal", "hoard"]
const CIRCUITS: PackedStringArray = ["loop", "bays", "line", "traffic"]

var _built := false
var _bays: PackedStringArray = PackedStringArray()   # the family's array, at build time
var _pi: Array = []                                  # the ONE solve
var _alloc: Array = []                               # reading 1
var _flow: Dictionary = {}                           # reading 2


func _ready() -> void:
	_read_config_meta()
	_check_family_list()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	var before := "%s|%s|%d" % [policy, circuit, fleet]
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_config_meta()
	# Rebuild ONLY when something this artifact owns actually changed, and only after
	# _ready has built once. force_pad tore down every child on any call at all.
	if _built and before != "%s|%s|%d" % [policy, circuit, fleet]:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()


## Three ways in, one door. The sweep sets the @export directly before add_child; the grid
## stamps config_* metadata (on this node or on an ancestor, depending on the component);
## apply_grid_config takes a dictionary. All three land here and all three are validated —
## an unrecognised word keeps the standing value rather than silently building a default.
func _read_config_meta() -> void:
	var p: String = _meta_str("config_policy")
	if p != "" and POLICIES.has(p):
		policy = p
	var c: String = _meta_str("config_circuit")
	if c != "" and CIRCUITS.has(c):
		circuit = c
	var f: String = _meta_str("config_fleet")
	if f != "":
		fleet = clampi(int(f), 4, SLOT_COLS * SLOT_ROWS * 4)
	var w: String = _meta_str("config_wear")
	if w != "":
		wear = clampf(float(w), 0.0, 1.0)


func _meta_str(key: String) -> String:
	var n: Node = self
	var hops: int = 0
	while n != null and hops < 4:
		if n.has_meta(key):
			return str(n.get_meta(key)).strip_edges().to_lower()
		n = n.get_parent()
		hops += 1
	return ""


## LAW 1, in both directions. The four bays ARE the family's array — not a copy of it —
## and this refuses to let the two drift silently. A value the family declares that this
## yard has no bay builder for is a missing exhibit; a builder this yard has that the
## family has dropped is a stale one. Reading UPKEEP_SRC.UPKEEPS directly also fails at
## PARSE time if the const is renamed, which is a better failure than a runtime fallback.
func _check_family_list() -> void:
	_bays = UPKEEP_SRC.UPKEEPS
	var mine: PackedStringArray = ["service", "works", "store", "scrap"]
	for v in _bays:
		if not mine.has(v):
			push_error("service_yard: the `upkeep` family declares '%s' and this yard has no bay for it. Add a branch in _unit() or refuse the value on the record." % v)
	for v in mine:
		if not _bays.has(v):
			push_error("service_yard: this yard builds a bay for '%s' and the family no longer declares it. station_plinth.gd's UPKEEPS is the truth; this yard is stale." % v)
	if _bays.size() != 4:
		push_error("service_yard: the `upkeep` family now has %d values and the yard has four corners. The quad layout is what makes every real leg an edge rather than a diagonal; a fifth value needs a new layout, not a fifth corner." % _bays.size())


# ── THE ONE ARITHMETIC ───────────────────────────────────────────────────────
# A four-state chain over the FLEET. Solved once per build by power iteration for a
# FIXED 4000 steps with no tolerance and no early exit, so it does the same float
# arithmetic in the same order every time: two captures of one value are two
# photographs of one object. Read three ways afterwards and never re-solved.

func _index_of(v: String) -> int:
	for i in range(_bays.size()):
		if _bays[i] == v:
			return i
	return -1


func _solve() -> void:
	var r: Dictionary = RATES[policy] if RATES.has(policy) else RATES["repair"]
	var si: int = _index_of("service")
	var wi: int = _index_of("works")
	var ti: int = _index_of("store")
	var ci: int = _index_of("scrap")
	var n: int = _bays.size()
	if si < 0 or wi < 0 or ti < 0 or ci < 0 or n < 4:
		# _check_family_list has already pushed the error. Do not build a chain over a
		# vocabulary this yard cannot read; stand every bay at an even share instead, so
		# the failure is a flat picture rather than a crash or a plausible-looking lie.
		_pi = []
		_alloc = []
		for _i in range(maxi(n, 0)):
			_pi.append(1.0 / float(maxi(n, 1)))
			_alloc.append(int(float(fleet) / float(maxi(n, 1))))
		_flow = {}
		for leg in LEGS:
			_flow[str(leg[2])] = 0.0
		return
	var P: Array = []
	for i in range(n):
		var row: Array = []
		row.resize(n)
		for j in range(n):
			row[j] = 0.0
		P.append(row)
	P[si][wi] = float(r["due"])
	P[si][ti] = float(r["down"])
	P[si][si] = 1.0 - float(r["due"]) - float(r["down"])
	P[wi][si] = float(r["fix"])
	P[wi][ci] = float(r["cond"])
	P[wi][wi] = 1.0 - float(r["fix"]) - float(r["cond"])
	P[ti][si] = float(r["issue"])
	P[ti][ti] = 1.0 - float(r["issue"])
	P[ci][ti] = float(r["repl"])
	P[ci][ci] = 1.0 - float(r["repl"])

	var v: Array = []
	v.resize(n)
	for i in range(n):
		v[i] = 1.0 / float(n)
	for _step in range(4000):
		var nx: Array = []
		nx.resize(n)
		for j in range(n):
			var acc: float = 0.0
			for i in range(n):
				acc += float(v[i]) * float(P[i][j])
			nx[j] = acc
		var s: float = 0.0
		for j in range(n):
			s += float(nx[j])
		for j in range(n):
			nx[j] = float(nx[j]) / s
		v = nx
	_pi = v

	# READING 1 — how many units stand in each bay. Largest remainder, ties broken by
	# index, so the allocation is a pure function of pi and never of iteration order.
	var total: int = clampi(fleet, 4, SLOT_COLS * SLOT_ROWS * n)
	var base: Array = []
	base.resize(n)
	var used: int = 0
	for i in range(n):
		base[i] = int(floor(float(_pi[i]) * float(total)))
		used += int(base[i])
	var left: int = total - used
	while left > 0:
		var best: int = -1
		var best_rem: float = -1.0
		for i in range(n):
			var raw: float = float(_pi[i]) * float(total)
			# a bay already topped up sits above its own floor; skip it
			if int(base[i]) > int(floor(raw)):
				continue
			var rem: float = raw - floor(raw)
			if rem > best_rem:
				best_rem = rem
				best = i
		if best < 0:
			break
		base[best] = int(base[best]) + 1
		left -= 1
	_alloc = base

	# READING 2 — how much moves along each leg. pi[from] * P[from][to], which is the
	# thing the post claims to show and not a proxy for it: it is the fraction of the
	# whole fleet that traverses that leg per period. A leg that carries nothing
	# reports a post of height zero and that is a true statement, not a silent one —
	# the base plate and the datum collar are still there under it.
	_flow = {}
	for leg in LEGS:
		var a: int = _index_of(str(leg[0]))
		var b: int = _index_of(str(leg[1]))
		_flow[str(leg[2])] = float(_pi[a]) * float(P[a][b])


# ── LAYOUT ───────────────────────────────────────────────────────────────────
## Where a condition's bay sits. The cyclic order round the quad is
## scrap -> store -> service -> works -> scrap, which is EXACTLY the four adjacencies the
## six real legs need, so every leg is a quad edge and no two legs cross. It is also the
## reason the naive `line` reading is legible as wrong: its middle arrow, works -> store,
## is the one pair the circuit never joins, so it has to cut diagonally across the yard.
func _corner(cond: String) -> Vector2:
	match cond:
		"scrap": return Vector2(-BAY_CX, BAY_CZ)
		"store": return Vector2(BAY_CX, BAY_CZ)
		"service": return Vector2(BAY_CX, -BAY_CZ)
		"works": return Vector2(-BAY_CX, -BAY_CZ)
	return Vector2.ZERO


func _build() -> void:
	_built = true
	_solve()

	var apron_mat: StandardMaterial3D = HangarKit.rams_body(body_color.darkened(0.18), wear)
	add_child(_box(Vector3(0, APRON_H * 0.5, 0), Vector3(APRON_X, APRON_H, APRON_Z), apron_mat))

	for i in range(_bays.size()):
		_build_bay(str(_bays[i]), int(_alloc[i]) if i < _alloc.size() else 0)

	if circuit != "bays":
		_build_naive()
	if circuit == "loop" or circuit == "traffic":
		_build_legs()
	if circuit == "traffic":
		_build_gauges()


# ── A BAY ────────────────────────────────────────────────────────────────────
## Pad, kerb, lettered name tab, eight slots. The pad, the kerb, the tab and the eight slot
## outlines are drawn at EVERY value of both axes: they are the control, and they are why a
## bay with nothing in it still reads as a bay. A condition is a PLACE in this yard, which
## is the claim the artifact would lose if an empty bay simply vanished.
func _build_bay(cond: String, count: int) -> void:
	var c: Vector2 = _corner(cond)
	var outer: float = signf(c.y)
	var pad_mat: StandardMaterial3D = HangarKit.rams_body(body_color.darkened(0.06), wear)
	var kerb_mat: StandardMaterial3D = HangarKit.worn_metal(body_color.darkened(0.30))
	add_child(_box(Vector3(c.x, GY + PAD_H * 0.5, c.y), Vector3(PAD_X, PAD_H, PAD_Z), pad_mat))
	add_child(_box(Vector3(c.x, GY + KERB_H * 0.5, c.y + outer * (PAD_Z * 0.5 - KERB_W * 0.5)),
		Vector3(PAD_X, KERB_H, KERB_W), kerb_mat))
	for sx in [-1.0, 1.0]:
		add_child(_box(Vector3(c.x + sx * (PAD_X * 0.5 - KERB_W * 0.5), GY + KERB_H * 0.5, c.y),
			Vector3(KERB_W, KERB_H, PAD_Z), kerb_mat))

	# The name tab. The word is LETTERED from the family's own array — the tab reads
	# whatever UPKEEPS says, in whatever order UPKEEPS says it. No pixel of any tile is
	# a rendered word naming an axis value of THIS artifact; the four words present are
	# the exhibited vocabulary and they are identical in all sixteen frames.
	var ty: float = c.y + outer * (PAD_Z * 0.5 + 0.16)
	for sx in [-1.0, 1.0]:
		add_child(_box(Vector3(c.x + sx * 0.24, GY + TAB_Y * 0.5, ty),
			Vector3(0.05, TAB_Y, 0.05), kerb_mat))
	add_child(_box(Vector3(c.x, GY + TAB_Y + TAB_H * 0.5, ty), Vector3(TAB_W, TAB_H, 0.03),
		HangarKit.painted_metal(body_color.lightened(0.10), wear * 0.5, 0.2, 0.6)))
	var q: MeshInstance3D = HangarKit.stencil(cond.to_upper(), Vector2(TAB_W * 0.82, TAB_H * 0.62),
		Color(0.16, 0.16, 0.18))
	if q:
		q.position = Vector3(c.x, GY + TAB_Y + TAB_H * 0.5, ty + outer * 0.020)
		if outer < 0.0:
			q.rotation_degrees = Vector3(0, 180, 0)
		add_child(q)

	# SILENT-DROP GUARD (law 6's cousin: a proxy that quietly reports less than the truth is
	# worse than no measure). A bay draws SLOT_COLS x SLOT_ROWS = 8 slots and the solve can
	# hand it more. Measured across the four policies: at the shipped fleet of 16 the worst
	# case is hoard/store at EXACTLY 8 of 8 — zero headroom — and at fleet 17 that same bay is
	# allocated 9, so the ninth unit would simply never be drawn while the dwell column beside
	# it still reports pi = 0.50. A frame showing eight units next to a gauge reporting nine is
	# a disagreement a still cannot expose, so it is made loud here instead of left silent.
	# _read_config_meta clamps fleet to 32 (the yard's TOTAL capacity), which is only reachable
	# if the allocation were even, and it never is. The default is unaffected by this check.
	if count > SLOT_COLS * SLOT_ROWS:
		push_error("service_yard: bay '%s' was allocated %d units and has %d slots; %d would go undrawn while the gauges still report the full share. Lower `fleet` — 16 is the most this quad holds under every policy — or grow SLOT_COLS/SLOT_ROWS." % [cond, count, SLOT_COLS * SLOT_ROWS, count - SLOT_COLS * SLOT_ROWS])

	for i in range(SLOT_COLS * SLOT_ROWS):
		var col: int = i % SLOT_COLS
		var row: int = i / SLOT_COLS
		var ux: float = c.x + (float(col) - float(SLOT_COLS - 1) * 0.5) * SLOT_PX
		var uz: float = c.y + (float(SLOT_ROWS - 1) * 0.5 - float(row)) * SLOT_PZ * outer
		if i < count:
			_unit(ux, uz, cond)
		else:
			add_child(_box(Vector3(ux, PY + 0.004, uz), Vector3(0.52, 0.008, 0.38),
				HangarKit.worn_metal(body_color.darkened(0.42))))


# ── ONE PIECE OF EQUIPMENT, FOUR CONDITIONS ──────────────────────────────────
## The same skid every time: a 0.56 x 0.10 x 0.42 base and a 0.50 x 0.42 x 0.34 body, drawn
## FIRST and identically in all four conditions, so the only difference between two bays is
## what the condition does to that one object.
##
## THE Z-STACK, written out because operations_gallery photographed a blank slab (law 7).
## Every mark a condition makes sits at a z STRICTLY IN FRONT of the face it marks or on a
## face nothing covers. Local z from the unit centre, front is +z:
##   body front face          +0.170
##   cover panel (on)         +0.170 .. +0.190     service, works
##   lamp block               +0.170 .. +0.190     service, works   (offset in x, clear of
##                                                                   the panel's own width)
##   swung panel (works)      +0.120 .. +0.480     hinged out to the LEFT at x -0.30, so it
##                                                 stands clear of the body face, not on it
##   sleeve (store)           -0.240 .. +0.240     ENCLOSES the body — deliberately: `store`
##                                                 is the value that hides the object, and
##                                                 the straps at +0.250 sit proud of it
##   hazard tape (scrap)      +0.185 .. +0.195     in front of the BARED CORE, which is
##                                                 0.34 -> 0.26 wide, so the tape is proud
##   leaning panel (scrap)    +0.240 .. +0.280     stood off the skid entirely
## Nothing opaque is in front of a mark except the store sleeve, which is the mark.
func _unit(cx: float, cz: float, cond: String) -> void:
	var skid: StandardMaterial3D = HangarKit.worn_metal(body_color.darkened(0.34))
	var shell: StandardMaterial3D = HangarKit.painted_metal(body_color, wear, 0.25, 0.62)
	add_child(_box(Vector3(cx, PY + 0.05, cz), Vector3(0.56, 0.10, 0.42), skid))

	if cond == "scrap":
		# ROBBED. The body itself is what changed — the cladding is off, so the core is
		# narrower and shorter, exactly as station_pillar._scrap_shaft() rebuilds its shaft
		# rather than dressing it. The lamp is not built at all: it went with the panel.
		add_child(_box(Vector3(cx, PY + 0.23, cz), Vector3(0.50, 0.26, 0.34),
			HangarKit.worn_metal(body_color.darkened(0.20))))
		for i in range(3):
			add_child(_box(Vector3(cx + (float(i) - 1.0) * 0.16, PY + 0.28, cz + 0.132),
				Vector3(0.030, 0.22, 0.010),
				HangarKit.painted_metal(Color(0.38, 0.19, 0.09), 0.55, 0.15, 0.94)))
		var lean: MeshInstance3D = _box(Vector3(cx + 0.16, PY + 0.20, cz + 0.26),
			Vector3(0.40, 0.022, 0.30), HangarKit.worn_metal(body_color.darkened(0.10)))
		lean.rotation_degrees = Vector3(72.0, 8.0, 0)
		add_child(lean)
		add_child(_box(Vector3(cx, PY + 0.30, cz + 0.19), Vector3(0.56, 0.05, 0.010),
			HangarKit.striped_mat()))
		# Rust bloom where the robbed skid meets the pad. NOT HangarKit.grime_band: that
		# helper returns a mesh positioned at a z it is handed and an x of 0, so hung on
		# this root it would have landed at the YARD's centre, not at this unit's foot —
		# sixteen bays' worth of rust in one stripe through the middle of the apron.
		add_child(_box(Vector3(cx, PY + 0.045, cz + 0.21), Vector3(0.58, 0.09, 0.006),
			HangarKit.painted_metal(Color(0.36, 0.18, 0.08), 0.60, 0.05, 0.96)))
		var mk: MeshInstance3D = HangarKit.stencil("SCRAP", Vector2(0.30, 0.07),
			Color(0.46, 0.22, 0.10))
		if mk:
			mk.position = Vector3(cx, PY + 0.16, cz + 0.176)
			add_child(mk)
		return

	add_child(_box(Vector3(cx, PY + 0.31, cz), Vector3(0.50, 0.42, 0.34), shell))

	if cond == "store":
		# PACKED DOWN. A sleeve swallows the body and three straps band it. The lamp is
		# built and then covered — the same move station_pillar makes with its sleeve and
		# station_floorline makes with its board runner: nothing is deleted, the light is
		# OCCLUDED, which is why this value reads from across a room.
		add_child(_box(Vector3(cx, PY + 0.50, cz + 0.18), Vector3(0.10, 0.07, 0.02),
			HangarKit.emissive(accent_color, 1.6)))
		add_child(_box(Vector3(cx, PY + 0.30, cz), Vector3(0.62, 0.54, 0.48),
			HangarKit.painted_metal(body_color.lightened(0.30), 0.03, 0.0, 0.95)))
		for i in range(3):
			add_child(_box(Vector3(cx + (float(i) - 1.0) * 0.18, PY + 0.30, cz),
				Vector3(0.03, 0.56, 0.50), HangarKit.worn_metal(Color(0.15, 0.14, 0.13))))
		var seal: MeshInstance3D = HangarKit.brand_patch("SEALED", Vector2(0.30, 0.075),
			accent_color, Color(0.98, 0.96, 0.92))
		if seal:
			seal.position = Vector3(cx, PY + 0.34, cz + 0.245)
			add_child(seal)
		return

	# service and works both carry the cover and the lit lamp: the object is intact and
	# powered in both. This is the one containment in the family, built as one.
	add_child(_box(Vector3(cx, PY + 0.34, cz + 0.18), Vector3(0.44, 0.26, 0.02),
		HangarKit.painted_metal(body_color.darkened(0.08), wear, 0.25, 0.55)))
	add_child(_box(Vector3(cx + 0.16, PY + 0.50, cz + 0.180), Vector3(0.10, 0.07, 0.02),
		HangarKit.emissive(accent_color, 1.7)))

	if cond == "works":
		# OPENED UP. The panel is swung out on the left, the loom spills onto the pad, a
		# tool tray sits beside it and a trestle stands over the whole thing. The trestle
		# is the silhouette change — 0.94 m of standing mass over a 0.55 m object — and it
		# is the family's own gesture: a barrier across the run, a cage round the column.
		var panel: MeshInstance3D = _box(Vector3(cx - 0.30, PY + 0.44, cz + 0.26),
			Vector3(0.02, 0.30, 0.34), HangarKit.painted_metal(body_color.darkened(0.08), wear, 0.25, 0.55))
		panel.rotation_degrees = Vector3(0, 62.0, 0)
		add_child(panel)
		add_child(_box(Vector3(cx + 0.02, PY + 0.09, cz + 0.32), Vector3(0.30, 0.05, 0.20),
			HangarKit.worn_metal(accent_color.darkened(0.40))))
		add_child(_box(Vector3(cx + 0.30, PY + 0.20, cz + 0.30), Vector3(0.26, 0.04, 0.18),
			HangarKit.worn_metal(body_color.lightened(0.04))))
		var steel: StandardMaterial3D = HangarKit.worn_metal(body_color.lightened(0.02))
		for sx in [-1.0, 1.0]:
			add_child(_box(Vector3(cx + sx * 0.36, PY + 0.42, cz), Vector3(0.05, 0.84, 0.05), steel))
		add_child(_box(Vector3(cx, PY + 0.86, cz), Vector3(0.82, 0.08, 0.06),
			HangarKit.striped_mat()))
		var pl: MeshInstance3D = HangarKit.brand_patch("WORKS", Vector2(0.28, 0.075),
			Color(0.95, 0.75, 0.05), Color(0.10, 0.10, 0.12))
		if pl:
			pl.position = Vector3(cx, PY + 0.66, cz + 0.192)
			add_child(pl)


# ── THE NAIVE READING ────────────────────────────────────────────────────────
## The three arrows a VALUE LIST invites: service -> works -> store -> scrap, drawn straight
## from the family's own array by walking it pairwise. Neutral grey, standing gate posts and
## a chevron plate at each head, laid on the ground BENEATH everything the real circuit
## draws. Nothing here is hard-coded: reorder UPKEEPS and these arrows reorder with it, and
## _build_legs() will bar whichever of them turns out to have no real leg behind it.
##
## Two of the three are wrong, and the geometry says so without a caption:
##   service -> works   REAL. It is the `due` leg. One third of the naive reading is right.
##   works   -> store   FICTIONAL. The circuit never joins that pair, so the arrow has to
##                      cut DIAGONALLY across the yard — the only diagonal in the artifact.
##   store   -> scrap   BACKWARDS. That edge exists and carries `repl`, in the other
##                      direction: a hulk is written off and a replacement enters store.
func _build_naive() -> void:
	var mat: StandardMaterial3D = HangarKit.worn_metal(body_color.darkened(0.26))
	for i in range(_bays.size() - 1):
		var a: Vector2 = _corner(str(_bays[i]))
		var b: Vector2 = _corner(str(_bays[i + 1]))
		var d: Vector2 = b - a
		var mid: Vector2 = (a + b) * 0.5
		var span: float = d.length() - 0.90
		if span < 0.10:
			continue
		var u: Vector2 = d.normalized()
		# ONE ROTATED LANE, not three special cases. The first cut of this branched on
		# along_x / along_z and built the diagonal as an AXIS-ALIGNED BOX spanning its own
		# bounding rectangle — a 2.72 x 1.55 m grey slab across the middle of the yard
		# instead of a 0.30 x 3.13 m lane, 4.5x the ink and nothing like an arrow. Every
		# lane is now a +Z box yawed onto its own direction: yaw = atan2(u.x, u.y) takes
		# (0,0,1) to (u.x, 0, u.y).
		var yaw: float = rad_to_deg(atan2(u.x, u.y))
		var lane: MeshInstance3D = _box(Vector3(mid.x, GY + 0.008, mid.y),
			Vector3(NAIVE_W, 0.016, span), mat)
		lane.rotation_degrees = Vector3(0, yaw, 0)
		add_child(lane)
		var head: Vector2 = b - d * 0.30
		var perp: Vector2 = Vector2(-u.y, u.x)
		for s in [-1.0, 1.0]:
			var off: Vector2 = perp * 0.20 * s
			add_child(_box(Vector3(head.x + off.x, GY + GATE_Y * 0.5, head.y + off.y),
				Vector3(GATE_T, GATE_Y, GATE_T), mat))
		var chev: MeshInstance3D = _box(Vector3(head.x, GY + GATE_Y + 0.13, head.y),
			Vector3(0.36, 0.26, 0.04), HangarKit.worn_metal(body_color.darkened(0.36)))
		chev.rotation_degrees = Vector3(0, yaw, 0)
		add_child(chev)


# ── THE REAL CIRCUIT ─────────────────────────────────────────────────────────
## Six legs in the aisles. Each is a lit floor rib plus a STANDING guide rail on two posts
## and a vertical arrowhead plate — standing, because the sweep camera is pitched only 15
## degrees down, so a floor mark projects at sin(15) = 0.26 of its length and a standing one
## at cos(15) = 0.97. The first cut of this artifact drew the whole circuit flat and measured
## 1.77% focus against `line`; the same routes drawn standing measure 7.6-15.2%. That is a
## fact about the standpoint, not about the routes.
##
## Where an edge carries a leg in BOTH directions (service-works and service-store do), the
## two are offset +/- 0.16 m across the aisle so they read as two lanes rather than one.
func _build_legs() -> void:
	var lit: StandardMaterial3D = HangarKit.emissive(accent_color, 0.8)
	var rail_mat: StandardMaterial3D = HangarKit.worn_metal(body_color.lightened(0.06))
	var seen: Dictionary = {}
	var joined: Dictionary = {}
	for leg in LEGS:
		var from: String = str(leg[0])
		var to: String = str(leg[1])
		var key: String = str(leg[2])
		var a: Vector2 = _corner(from)
		var b: Vector2 = _corner(to)
		var pair: String = (from + "|" + to) if from < to else (to + "|" + from)
		joined[pair] = true
		var double: bool = _edge_is_double(from, to)
		var off: float = 0.0
		if double:
			off = -0.16 if not seen.has(pair) else 0.16
		seen[pair] = true

		var d: Vector2 = b - a
		var u: Vector2 = d.normalized()
		var along_x: bool = absf(d.x) > absf(d.y)
		var span: float = (absf(d.x) - PAD_X) if along_x else (absf(d.y) - PAD_Z)
		var mid: Vector2 = (a + b) * 0.5
		if along_x:
			mid.y += off
		else:
			mid.x += off
		var rib_size: Vector3 = Vector3(span, LANE_H, LANE_W) if along_x else Vector3(LANE_W, LANE_H, span)
		add_child(_box(Vector3(mid.x, GY + 0.014 + LANE_H * 0.5, mid.y), rib_size, lit))
		for q in [-0.30, 0.30]:
			add_child(_box(Vector3(mid.x + u.x * span * q, GY + RAIL_Y * 0.5, mid.y + u.y * span * q),
				Vector3(POST_T, RAIL_Y, POST_T), rail_mat))
		var rail_size: Vector3 = Vector3(span, RAIL_T, POST_T) if along_x else Vector3(POST_T, RAIL_T, span)
		add_child(_box(Vector3(mid.x, GY + RAIL_Y, mid.y), rail_size, rail_mat))
		var hd: Vector2 = mid + u * span * 0.42
		add_child(_box(Vector3(hd.x, GY + HEAD_Y, hd.y),
			Vector3(0.035, HEAD_H, HEAD_W) if along_x else Vector3(HEAD_W, HEAD_H, 0.035),
			HangarKit.emissive(accent_color, 1.9)))
		set_meta("leg_mid_%s" % key, Vector3(mid.x, 0.0, mid.y))
		set_meta("leg_axis_%s" % key, 1.0 if along_x else 0.0)

	# THE LEG THAT DOES NOT EXIST. Asked, not told: whichever consecutive pair of the
	# family's array is joined by no real leg gets a barred plate stood across its arrow.
	# On the shipped const that is works -> store, the diagonal. Reorder UPKEEPS and the
	# bar moves by itself, which is the difference between a finding and a decoration.
	for i in range(_bays.size() - 1):
		var f: String = str(_bays[i])
		var t: String = str(_bays[i + 1])
		var pr: String = (f + "|" + t) if f < t else (t + "|" + f)
		if joined.has(pr):
			continue
		var m: Vector2 = (_corner(f) + _corner(t)) * 0.5
		add_child(_box(Vector3(m.x, GY + 0.30, m.y), Vector3(0.44, 0.10, 0.44),
			HangarKit.striped_mat(Color(0.92, 0.72, 0.06), Color(0.14, 0.13, 0.12))))
		for s in [-1.0, 1.0]:
			add_child(_box(Vector3(m.x + s * 0.18, GY + 0.15, m.y + s * 0.18),
				Vector3(0.06, 0.30, 0.06), HangarKit.worn_metal(body_color.darkened(0.30))))


func _edge_is_double(a: String, b: String) -> bool:
	var n: int = 0
	for leg in LEGS:
		if (str(leg[0]) == a and str(leg[1]) == b) or (str(leg[0]) == b and str(leg[1]) == a):
			n += 1
	return n > 1


# ── THE SAME SOLVE, READ TWO MORE WAYS ───────────────────────────────────────
## A flow post at each leg's midpoint (height = flow * 4.00, ceiling 1.00 m at flow 0.25)
## and a dwell column beside each bay (height = pi * 1.20, ceiling 1.20 m at pi = 1). Both
## carry a fixed datum collar at a fixed height, present whatever the numbers are, so the
## gauge is legible in the picture. Neither is normalised to anything in its own frame.
##
## They are summaries of ONE set of numbers and they disagree. At `hoard` the store bay's
## dwell column is the tallest mark in the sweep (0.600 m) and the two legs feeding it carry
## the smallest flows in the sweep (0.017 m posts). Full because nothing leaves, not because
## much arrives — which is precisely what a single number could not have told you.
func _build_gauges() -> void:
	var gauge: StandardMaterial3D = HangarKit.painted_metal(accent_color, 0.10, 0.2, 0.5)
	var plinth: StandardMaterial3D = HangarKit.worn_metal(body_color.darkened(0.24))
	var datum: StandardMaterial3D = HangarKit.painted_metal(Color(0.36, 0.72, 0.85), 0.06, 0.1, 0.5)

	for leg in LEGS:
		var key: String = str(leg[2])
		if not has_meta("leg_mid_%s" % key):
			continue
		var m: Vector3 = get_meta("leg_mid_%s" % key)
		var along_x: bool = float(get_meta("leg_axis_%s" % key)) > 0.5
		var h: float = float(_flow.get(key, 0.0)) * FLOW_CEIL
		var base_s: Vector3 = Vector3(FLOW_LEN, 0.02, FLOW_T + 0.06) if along_x else Vector3(FLOW_T + 0.06, 0.02, FLOW_LEN)
		add_child(_box(Vector3(m.x, GY + 0.02, m.z), base_s, plinth))
		if h > 0.004:
			var s: Vector3 = Vector3(FLOW_LEN, h, FLOW_T) if along_x else Vector3(FLOW_T, h, FLOW_LEN)
			add_child(_box(Vector3(m.x, GY + 0.03 + h * 0.5, m.z), s, gauge))
		var ds: Vector3 = Vector3(FLOW_LEN + 0.10, 0.05, FLOW_T + 0.10) if along_x else Vector3(FLOW_T + 0.10, 0.05, FLOW_LEN + 0.10)
		add_child(_box(Vector3(m.x, GY + 0.03 + FLOW_DATUM, m.z), ds, datum))

	for i in range(_bays.size()):
		if i >= _pi.size():
			break
		var c: Vector2 = _corner(str(_bays[i]))
		var outer: float = signf(c.y)
		var dx: float = c.x + signf(c.x) * (PAD_X * 0.5 + 0.20)
		var dz: float = c.y - outer * 0.30
		var hh: float = float(_pi[i]) * DWELL_CEIL
		add_child(_box(Vector3(dx, GY + 0.03, dz), Vector3(DWELL_W + 0.06, 0.06, DWELL_W + 0.06), plinth))
		if hh > 0.004:
			add_child(_box(Vector3(dx, GY + 0.06 + hh * 0.5, dz), Vector3(DWELL_W, hh, DWELL_W), gauge))
		add_child(_box(Vector3(dx, GY + 0.06 + DWELL_DATUM, dz),
			Vector3(DWELL_W + 0.10, 0.05, DWELL_W + 0.10), datum))


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi
