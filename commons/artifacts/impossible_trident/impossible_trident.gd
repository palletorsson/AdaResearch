extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ImpossibleTrident

## @identity
## name: Impossible Trident
## lineage: the blivet / "devil's fork" / poiuyt — an impossible object first
##   widely printed in 1964. Two round prongs at the base resolve into three
##   rectangular prongs at the top with no consistent junction between them.
## essence: a U-channel diagram standing on the floor. Read the BASE and you count
##   TWO round prongs; read the TOP and you count THREE flat prongs. The middle is
##   drawn so each end is locally correct — and globally cannot exist. A faint amber
##   highlight crawls along the contradictory edge so the impossibility keeps reading.
## truth: two prongs become three; the drawing is consistent locally and impossible
##   globally — every junction is fine on its own, no assembly of them is.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent_amber: Color = Color(1.0, 0.70, 0.22)
@export var spin_period: float = 14.0
@export var trace_period: float = 3.2

## Stage-2 DNA axis — WHERE THE CONTRADICTION LIVES.
##
## The whole object is about one number: the discrepancy between what you count at
## the base and what you count at the top. Before promotion that number was written
## into two literal loops (`range(3)` tines, `range(2)` rods) and no map could touch
## the single thing the figure means. `fault` is that number, plus the less obvious
## question of whether the break has an address.
##
##   global     the shipped blivet — 3 flat tines over 2 round rods, both
##              contradictory bridging walls present. The impossibility is smeared
##              through the whole figure; every junction is locally fine and you
##              cannot point at the one that lies.
##   confessed  the central tine is built short, leaving a 0.12 m air gap at the
##              shank, ringed in amber, and the wall beneath it is not built. A
##              system that shows you where it breaks instead of distributing the
##              break so evenly you cannot name it.
##   none       the consistent sibling: 3 round rods directly under 3 flat tines,
##              no bridging walls, base tally rebuilt to 3. A drawing of an object
##              that could actually be machined. This is the value that earns the
##              axis — hang it beside `global` and the eye discovers that only one
##              of the two can be built.
##   doubled    4 flat tines over the same 2 rods, a third bridging wall at x = 0,
##              top tally rebuilt to 4. The mismatch widened from one prong to two.
##
## Prong COUNT is the variable on purpose: _body spins on a 14 s period, so a still
## catches an arbitrary yaw, and a count reads at every yaw where a face detail
## would not. One prong is ~0.21 m on a 1.24 m span — a fifth of the figure's width.
@export_enum("global", "confessed", "none", "doubled") var fault: String = "global"

const FAULTS: PackedStringArray = ["global", "confessed", "none", "doubled"]

var _body: Node3D
var _trace_root: Node3D
var _t: float = 0.0

## True while the figure HAS a contradictory edge for the amber highlight to haunt.
## `none` has no seam, so the crawling bar is not drawn there — the dot still runs
## the top rim, because counting the tines is still the point.
var _seam_trace: bool = true

var _built: bool = false
## Every node THIS script added to `self`. Teardown walks this list and nothing
## else, so grid-added label plates, packaging and tag markers survive a rebuild.
var _created: Array[Node] = []

## Every emissive material this artifact made, with the energy it carries lit and dimmed.
##
## WHY THIS EXISTS. `emissive` is the parent's @export and the parent bakes it into the
## material AT CREATION (embodied_prop.gd:30 and :50). Before promotion apply_grid_config
## freed every child and rebuilt, so a new `emissive` value reached the new materials. The
## Stage-2 early-return correctly stopped that rebuild — and silently took `emissive` with
## it. curation_station.gd:372, artifact_runner.gd:206 and artifact_review_station.gd:520
## all pass exactly {"emissive": false}, so three call sites were being ignored.
##
## Overriding the two parent factories rather than editing six call sites means every
## material is registered wherever it is made, including any added later.
var _emissive_mats: Array[Dictionary] = []


func _glow_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = super._glow_mat(c, energy)
	_emissive_mats.append({"m": m, "on": energy, "off": energy * 0.3})
	return m


func _steel_mat(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = super._steel_mat(c)
	_emissive_mats.append({"m": m, "on": 0.1, "off": 0.0})
	return m


## Retint in place. The same numbers the parent bakes, applied without a rebuild.
func _apply_emissive() -> void:
	for e in _emissive_mats:
		var m: StandardMaterial3D = e["m"]
		if is_instance_valid(m):
			m.emission_energy_multiplier = float(e["on"]) if emissive else float(e["off"])

# Geometry of the figure (local to _body, which is lifted onto the floor).
const SPAN: float = 0.62          # half-width of the channel
const Y_TOP: float = 0.46         # top of the prongs
const Y_BOT: float = -0.46        # bottom (base plate sits here)
const PRONG_LEN: float = 0.40     # how far the prongs stick out toward viewer

## `doubled`: x of the two inner tines. 0.21 splits the half-span into thirds, so
## four tines sit evenly across the same 1.24 m and the widened mismatch reads as
## crowding rather than as a different object.
const INNER_X: float = 0.21

## `confessed`: how long the severed central tine is built. 0.28 of 0.40 leaves a
## 0.12 m gap against the shank — big enough to survive the auto-framed capture,
## small enough that the tine still reads as that tine and not as debris.
const CONFESSED_LEN: float = 0.28
## Radius of the amber ring drawn around the confessed gap.
const CONFESSED_RING_R: float = 0.09


func _ready() -> void:
	# Fixed seed, not randomize(). Nothing in _build reads it today, but two builds
	# of one axis value must never differ or the pixel critic reads noise as signal.
	_rng.seed = 20260728
	_build_all()
	_built = true
	set_process(not Engine.is_editor_hint())


## Grid config. Keys: "emissive" (pre-existing), "fault" (Stage-2 axis).
##
## curation_station hands EVERY artifact it curates {"emissive": false} one line
## after un-billboarding and dimming its labels. That dict carries no axis key, so
## it must fall through the guard below and touch nothing — an unconditional
## rebuild there throws the framing away and it is never re-applied.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_fault: String = fault

	if config_data.has("emissive"):
		emissive = bool(config_data["emissive"])
	if config_data.has("fault"):
		fault = _pick_axis(str(config_data["fault"]), FAULTS, fault)

	# Retint BEFORE the early return: emissive changes no geometry, so it must not
	# trigger a rebuild, but it must still be applied. Skipping this was a silent
	# no-op on the three call sites that pass {"emissive": false}.
	_apply_emissive()

	if not _built:
		# Called before _ready — nothing exists to tear down, and _build_all will
		# use the values just resolved.
		return
	if fault == before_fault:
		return

	_rebuild_now()
	print("[ImpossibleTrident] Config applied — fault=%s" % [fault])


## Accept an axis value only if it names something we actually build. A typo in a
## map token falls back to the shipped look rather than stranding the placement.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous, inline. No call_deferred: a deferred rebuild that removes children
## first makes _auto_ground_artifact measure a zero AABB, bail, and leave the
## figure floating.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	# The old materials die with the nodes; keeping them would retint freed objects.
	_emissive_mats.clear()
	_body = null
	_trace_root = null
	_build_all()


## add_child + remember, so teardown only ever frees our own work.
func _own(n: Node) -> void:
	_created.append(n)
	add_child(n)


func _build_all() -> void:
	# Resolve defensively: a sweep or the editor can set the @export directly.
	var f: String = _pick_axis(fault, FAULTS, "global")

	# --- the figure, one value at a time ------------------------------------
	# tine_xs  : the flat rectangular prongs at the top (what you count up there)
	# rod_xs   : the round rods at the base (what you count down there)
	# wall_xs  : the vertical bridging walls that make each rod's far edge read as
	#            the GAP between two tines — the contradiction, spread out
	# under_wall: the central tine's underside wall descending INTO the solid
	#            channel between the rods — the contradiction, concentrated
	var tine_xs: Array[float] = [-SPAN, 0.0, SPAN]
	var rod_xs: Array[float] = [-SPAN * 0.5, SPAN * 0.5]
	var wall_xs: Array[float] = [-SPAN * 0.5, SPAN * 0.5]
	var under_wall: bool = true
	var cut_centre: bool = false

	match f:
		"confessed":
			# The break gets one nameable location: a gap you can put a finger in,
			# and no smeared wall beneath it.
			cut_centre = true
			under_wall = false
		"none":
			# The machinable sibling. Three rods directly beneath three tines and
			# nothing bridging: every junction is fine AND the assembly is too.
			rod_xs = [-SPAN, 0.0, SPAN]
			wall_xs = []
			under_wall = false
		"doubled":
			# Four tines over two rods. The base still says 2; the top now says 4.
			tine_xs = [-SPAN, -INNER_X, INNER_X, SPAN]
			wall_xs = [-SPAN * 0.5, 0.0, SPAN * 0.5]

	_seam_trace = f != "none"

	# --- chalk ring on the floor (no bench) ---
	var ring_mat := _glow_mat(wire_purple, 0.5)
	_own(_torus(Vector3(0.0, 0.02, 0.0), 0.58, 0.012, ring_mat))

	# the whole figure rides on a slowly rotating body, lifted so the base
	# plate sits near the floor and the prongs reach ~1.1m.
	_body = Node3D.new()
	_body.position = Vector3(0.0, 0.62, 0.0)
	_own(_body)

	var steel := _steel_mat(Color(0.78, 0.82, 0.90))
	var wire := _glow_mat(wire_purple, 0.8)
	var white := _matte_mat(cool_white, 0.55)

	# === THE TOP PRONGS (rectangular) ===
	# Flat tines across the span. They are unambiguous at the top — that is the
	# whole trick, and it is why the count up here is a countable fact.
	for i in range(tine_xs.size()):
		var x: float = tine_xs[i]
		# `confessed` severs the central tine at the shank end: it starts 0.12 m
		# out instead of at z = 0, so the junction it cannot honestly make is
		# simply absent instead of quietly drawn.
		var z0: float = 0.0
		if cut_centre and is_equal_approx(x, 0.0):
			z0 = PRONG_LEN - CONFESSED_LEN
		var seg: float = PRONG_LEN - z0
		var zc: float = z0 + seg * 0.5
		# a flat rectangular prong extending toward the viewer (+z)
		_body.add_child(_box(Vector3(x, Y_TOP - 0.02, zc), Vector3(0.10, 0.05, seg), white))
		# crisp top edge wire so it reads as a drawn rectangle
		_body.add_child(_box(Vector3(x, Y_TOP + 0.012, zc), Vector3(0.11, 0.008, seg), wire))
		# rounded tip cap (small, keeps the flat-tine silhouette)
		_body.add_child(_box(Vector3(x, Y_TOP - 0.02, PRONG_LEN + 0.01), Vector3(0.10, 0.05, 0.02), wire))

	# The confession itself: an amber ring standing in the air where the central
	# tine should have met the shank. The figure points at its own bad junction.
	if cut_centre:
		var gap_mat := _glow_mat(accent_amber, 1.4)
		var gap_ring: MeshInstance3D = _torus(
			Vector3(0.0, Y_TOP - 0.02, (PRONG_LEN - CONFESSED_LEN) * 0.5),
			CONFESSED_RING_R, 0.012, gap_mat)
		gap_ring.rotation.x = PI * 0.5   # ring plane = XY, so it encircles the gap
		_body.add_child(gap_ring)

	# === THE BASE PRONGS (round) ===
	# In `global`/`confessed`/`doubled` there are only two: the channel between the
	# outer tines is solid, so the middle tine has nowhere to be born from. In
	# `none` there are three, one under each tine, and nothing is being hidden.
	for j in range(rod_xs.size()):
		var bx: float = rod_xs[j]
		_body.add_child(_cylinder_between(
			Vector3(bx, Y_BOT + 0.05, 0.0),
			Vector3(bx, Y_BOT + 0.05, PRONG_LEN),
			0.055, steel))
		# rounded cap so they read as round rods
		_body.add_child(_sphere(Vector3(bx, Y_BOT + 0.05, PRONG_LEN), 0.055, steel))

	# === THE BASE PLATE / SHANK ===
	# The flat back wall that the round prongs leave and the flat prongs arrive at.
	# This is the surface where the count silently changes.
	_body.add_child(_box(Vector3(0.0, (Y_TOP + Y_BOT) * 0.5, -0.02), Vector3(SPAN * 2.0 + 0.12, Y_TOP - Y_BOT, 0.04), white))
	# its drawn outline
	_body.add_child(_box(Vector3(0.0, Y_TOP, -0.02), Vector3(SPAN * 2.0 + 0.14, 0.008, 0.05), wire))
	_body.add_child(_box(Vector3(0.0, Y_BOT, -0.02), Vector3(SPAN * 2.0 + 0.14, 0.008, 0.05), wire))

	# The contradictory connecting walls: each base rod's far edge becomes the
	# GAP between top tines, and vice-versa. We draw both interpretations as thin
	# bridging walls so the eye keeps trying (and failing) to assemble them.
	for k in range(wall_xs.size()):
		_body.add_child(_box(Vector3(wall_xs[k], 0.0, PRONG_LEN * 0.5), Vector3(0.008, Y_TOP - Y_BOT, PRONG_LEN), wire))
	# the central top tine's underside wall — it descends INTO the solid channel
	# between the two round rods (the impossible part, unattributable).
	if under_wall:
		_body.add_child(_box(Vector3(0.0, 0.0, PRONG_LEN * 0.5), Vector3(0.06, Y_TOP - Y_BOT, 0.008), wire))

	# --- the crawling amber highlight along the contradictory edge ---
	_trace_root = Node3D.new()
	_body.add_child(_trace_root)

	# --- labels ---
	# The tallies are the readout of the axis: base count, top count. In `global`
	# they read 2 and 3 exactly as shipped.
	var base_n: int = rod_xs.size()
	var top_n: int = tine_xs.size()
	_own(_billboard_label("IMPOSSIBLE TRIDENT", Vector3(0.0, 1.5, 0.0), 32, cool_white))
	_own(_billboard_label("count the base: %d   count the top: %d" % [base_n, top_n], Vector3(0.0, 1.36, 0.0), 16, accent_amber))
	# small standing tallies near each end of the figure
	_own(_billboard_label(str(base_n), Vector3(0.0, 0.20, 0.0), 30, accent_amber))
	_own(_billboard_label(str(top_n), Vector3(0.0, 1.18, 0.0), 30, accent_amber))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# slow rotation so the impossibility reads from changing angles
	if is_instance_valid(_body):
		_body.rotation.y = (_t / spin_period) * TAU
		# gentle nod so the depth ambiguity flickers
		_body.rotation.x = sin(_t * 0.6) * 0.07

	# the amber highlight crawls along the seam between "2 round" and "3 flat"
	if is_instance_valid(_trace_root):
		for c in _trace_root.get_children():
			_trace_root.remove_child(c)
			c.queue_free()
		var phase: float = fmod(_t, trace_period) / trace_period
		# the seam runs across the base plate in +z then sweeps along the span
		var sweep_x: float = lerp(-SPAN, SPAN, phase)
		var glow: float = 1.6 + 0.8 * sin(_t * 5.0)
		var trace_mat := _glow_mat(accent_amber, glow)
		# a short bright segment riding the contradictory vertical edge —
		# omitted when there is no contradictory edge to ride.
		if _seam_trace:
			_trace_root.add_child(_box(
				Vector3(sweep_x, 0.0, PRONG_LEN * 0.5),
				Vector3(0.018, (Y_TOP - Y_BOT) * 0.9, 0.018),
				trace_mat))
		# a bright dot tracing the top rim back-and-forth, marking the tine it haunts
		var dot_x: float = lerp(-SPAN, SPAN, absf(phase * 2.0 - 1.0))
		_trace_root.add_child(_sphere(Vector3(dot_x, Y_TOP + 0.02, PRONG_LEN * 0.5), 0.03, trace_mat))
