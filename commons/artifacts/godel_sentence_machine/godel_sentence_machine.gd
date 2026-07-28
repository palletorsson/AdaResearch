extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GodelSentenceMachine

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: Godel's first incompleteness theorem, staged as a machine. A panel prints the sentence G, whose whole content is a claim ABOUT ITSELF — "G IS NOT PROVABLE" — a fixed point of the provability predicate built by the diagonal lemma. A self-reference arrow loops G's name back onto the sentence that names it, closing the circle. A prover arm reaches in to PROVE G, seizes (flares red), retracts; the verdict then resolves gold: TRUE — BUT UNPROVABLE. Forever: attempt -> jam -> conclude.
# desire: to make the self-reference LEGIBLE, not stated — to let the eye follow G's name looping back onto the sentence and feel the sentence talk about itself, so the crack is watched being built rather than asserted.
# critical_parameter: cycle_period — the pace of attempt -> jam -> conclude; slower reads as a solemn machine failing to prove, faster as a nervous loop that never settles.
# triggers: _ready -> _build (procedural, no scene deps); _process drives the arm swing, the jam flare, the spinning self-reference loop, and the gold verdict; apply_grid_config rebuilds and honours the emissive flag.
# emerges: the arm always jams and always retracts, and the verdict is always the same gold sentence — so incompleteness reads not as a bug the machine will fix next cycle but as the honest, permanent limit of the wall the whole book has been building.
# needs: the panel + G sentence [present]; the self-reference loop + arrowhead biting back into G [present]; the prover arm + PROVE clamp [present]; the jam spark [present]; the gold verdict [present].
# relationships: the keystone of foundationscrisis — the crack in every formal wall. Its TWIN limit, the halting problem (Turing — no machine decides whether an arbitrary program stops), is a SEPARATE artifact; this machine focuses purely on GODEL (a true sentence no proof reaches), leaving the un-decidable-run limit to that sibling. Kin to any fixed-point / self-reference artifact (the diagonal lemma is the same trick as Cantor's diagonal and the liar paradox made rigorous).
# truth: if G were provable it would be false (it asserts its own unprovability); a sound system proves no falsehoods, so G is not provable — and therefore G is true. True, and out of reach of proof. Every system strong enough to count is either unsound or incomplete; this machine chooses to stay honest, and so stays incomplete.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var panel_blue: Color = Color(0.40, 0.62, 0.95)
@export var jam_red: Color = Color(0.902, 0.224, 0.275)
@export var true_gold: Color = Color(1.0, 0.78, 0.30)
@export var cycle_period: float = 6.0

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA AXIS
# ─────────────────────────────────────────────────────────────────────────────
## What this machine CONCLUDES about G — the fork Godel's own dichotomy leaves open.
## The truth line says every system strong enough to count is either unsound or
## incomplete, and that this machine *chooses* to stay honest. A choice whose
## alternatives cannot be built is asserted, not staged. So the alternatives build:
##
##   honest    the shipped machine — G printed, the self-reference loop closed, the
##             prover arm jamming, and the gold plate TRUE — BUT UNPROVABLE.
##   proved    the UNSOUND machine: the clamp is closed on the G-dot with a cyan bar
##             bridging the jaws, no jam anywhere, and a cyan PROVED plate. It holds
##             a proof of G it should not have.
##   silent    the machine that hits the limit and files no report: the JAM board is
##             lit matte and permanent, and where the verdict plate stood there is a
##             blank steel strip.
##   harmless  the system too WEAK to diagonalise: no G, no loop, no G-dot, no jam —
##             the panel prints 0 + 1 = 1 + 0 and the plate reads CONSISTENT AND
##             COMPLETE. Nothing here is cracked, because nothing here can count.
##
## Every value is presence/absence and shape, never a rate — the evidence is a still.
@export_enum("honest", "proved", "silent", "harmless") var verdict: String = "honest"

## Allow-list for the axis. Anything unrecognised falls back to the shipped look.
const VERDICTS: PackedStringArray = ["honest", "proved", "silent", "harmless"]

## The unsound machine's colour — the same cyan on the plate and on the bar wedged
## between the closed jaws, so the two read as one claim.
const PROVED_CYAN: Color = Color(0.45, 0.85, 0.92)

## Fixed seed. Nothing in _build consumes _rng today, but a randomize() here would
## make two builds of one axis value legitimately differ, and the pixel critic reads
## any such difference as signal.
const RNG_SEED: int = 1931

var _t: float = 0.0
var _arm: Node3D
var _arm_pivot: Vector3 = Vector3(0.62, 0.92, 0.0)
var _g_panel: MeshInstance3D
var _g_panel_mat: StandardMaterial3D
var _loop_mi: MeshInstance3D
var _loop_mat: StandardMaterial3D
var _verdict: MeshInstance3D
var _verdict_mat: StandardMaterial3D
var _jam_spark: Node3D
var _spark_pos: Vector3 = Vector3(-0.30, 0.92, 0.07)

# Lifecycle bookkeeping — only nodes THIS script added may ever be freed; the grid
# adds label plates, packaging and tag markers as siblings and they must survive a
# rebuild untouched.
var _owned: Array[Node] = []
var _glow_reg: Array[Dictionary] = []
var _steel_reg: Array[StandardMaterial3D] = []
var _built: bool = false
## Does this build jam? Only the honest machine and the silent one hit the wall.
var _jams: bool = true
## Does the verdict plate fade in across the conclude window (shipped honest look),
## or is it simply there (every other value, so a still always catches it)?
var _verdict_animates: bool = true


func _ready() -> void:
	_rng.seed = RNG_SEED
	_build()
	_built = true
	set_process(not Engine.is_editor_hint())


# ─────────────────────────────────────────────────────────────────────────────
# GRID CONFIG
# ─────────────────────────────────────────────────────────────────────────────

## Contract: rebuild ONLY when geometry actually changes. curation_station calls this
## with {"emissive": false} one line after it has hidden the labels and framed the
## piece; an unconditional teardown there throws that framing away. `emissive` is a
## material property, so it is applied in place on the existing materials — the exact
## values a fresh build would have produced.
func apply_grid_config(config: Dictionary) -> void:
	var before_verdict: String = verdict
	var before_emissive: bool = emissive

	if config.has("verdict"):
		verdict = _pick_axis(str(config["verdict"]), VERDICTS, verdict)
	if config.has("emissive"):
		emissive = bool(config["emissive"])

	if emissive != before_emissive:
		_apply_emissive()

	if not _built:
		return
	if verdict == before_verdict:
		return

	_rebuild_now()
	print("[GodelSentenceMachine] Config applied — verdict=%s" % [verdict])


## Accept an axis value only if it names something we actually build. A typo in a map
## token has to land on the shipped look rather than on an empty machine.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous teardown + rebuild. No call_deferred: a deferred rebuild that has
## already removed its children makes the grid's auto-ground pass measure a zero AABB
## and give up, leaving the machine floating.
func _rebuild_now() -> void:
	for c: Node in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_glow_reg.clear()
	_steel_reg.clear()
	_arm = null
	_g_panel = null
	_g_panel_mat = null
	_loop_mi = null
	_loop_mat = null
	_verdict = null
	_verdict_mat = null
	_jam_spark = null
	_build()


## Re-apply the emissive flag to every material this script made, reproducing what
## _glow_mat / _steel_mat would have written on a fresh build. _process re-derives the
## loop and panel energies from `emissive` every frame, so those correct themselves.
func _apply_emissive() -> void:
	for e: Dictionary in _glow_reg:
		var m: StandardMaterial3D = e.get("mat")
		if m == null:
			continue
		var base: float = float(e.get("energy", 1.0))
		m.emission_energy_multiplier = base if emissive else base * 0.3
	for sm: StandardMaterial3D in _steel_reg:
		if sm == null:
			continue
		sm.emission_energy_multiplier = 0.1 if emissive else 0.0


# ─────────────────────────────────────────────────────────────────────────────
# BUILD
# ─────────────────────────────────────────────────────────────────────────────

func _build() -> void:
	_t = 0.0
	var v: String = verdict
	# The diagonal machinery — G, its named token, the loop that bites back. Only the
	# system too weak to diagonalise is built without it.
	var self_ref: bool = v != "harmless"
	_jams = v == "honest" or v == "silent"
	_verdict_animates = v == "honest"

	# --- chalk ring on the floor (no bench) ---
	var ring_mat := _glow_tracked(wire_purple, 0.5)
	_own(_torus(Vector3(0.0, 0.02, 0.0), 0.66, 0.012, ring_mat))

	# --- the machine panel: a standing slab the sentence is printed on ---
	var frame_mat := _steel_tracked(Color(0.34, 0.36, 0.42))
	var pw: float = 0.78
	var ph: float = 0.50
	var py: float = 0.92
	# back slab (the panel face, faint glow)
	_g_panel_mat = _glow_tracked(panel_blue, 0.35)
	_g_panel = _box(Vector3(0.0, py, 0.0), Vector3(pw, ph, 0.02), _g_panel_mat)
	_own(_g_panel)
	# panel frame edges
	_own(_box(Vector3(0.0, py + ph * 0.5, 0.0), Vector3(pw, 0.02, 0.04), frame_mat))
	_own(_box(Vector3(0.0, py - ph * 0.5, 0.0), Vector3(pw, 0.02, 0.04), frame_mat))
	_own(_box(Vector3(-pw * 0.5, py, 0.0), Vector3(0.02, ph, 0.04), frame_mat))
	_own(_box(Vector3(pw * 0.5, py, 0.0), Vector3(0.02, ph, 0.04), frame_mat))
	# two legs to the floor
	_own(_cylinder(Vector3(-pw * 0.34, py * 0.5 - 0.12, 0.0), 0.018, py - 0.24, frame_mat))
	_own(_cylinder(Vector3(pw * 0.34, py * 0.5 - 0.12, 0.0), 0.018, py - 0.24, frame_mat))

	if self_ref:
		# --- the sentence G, printed on the panel (integrated display boards) ---
		_add_tag("G:", Vector3(-0.30, py + 0.12, 0.05), 0.075, cool_white)
		_add_tag("\"G IS NOT PROVABLE\"", Vector3(0.04, py + 0.12, 0.05), 0.065, cool_white)
		# the named token of G the loop arrow points at — the "G" INSIDE the sentence
		var g_dot_mat := _glow_tracked(true_gold, 1.0)
		_own(_sphere(Vector3(-0.30, py - 0.04, 0.06), 0.028, g_dot_mat))
		_add_tag("= this very sentence", Vector3(0.02, py - 0.06, 0.05), 0.042, wire_purple, Color(0.42, 0.32, 0.62))

		# --- the self-reference loop: the name G points back at the sentence G names ---
		# A torus tilted to read as an arrow looping out of the "G" token and back onto
		# the whole sentence — the diagonal lemma's fixed point, drawn.
		_loop_mat = _glow_tracked(wire_purple, 1.1)
		_loop_mi = _torus(Vector3(-0.30, py + 0.04, 0.16), 0.11, 0.010, _loop_mat)
		_loop_mi.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		_own(_loop_mi)
		# little arrowhead biting back into the G dot — the self-reference closing
		_own(_arrow(Vector3(-0.30, py + 0.13, 0.20), Vector3(-0.30, py + 0.02, 0.09), 0.010, _loop_mat))
		_add_tag("G names itself", Vector3(-0.30, py + 0.20, 0.16), 0.040, wire_purple, Color(0.42, 0.32, 0.62))
	else:
		# A system too weak to talk about its own proofs: it can state a commutation
		# and nothing else. One line, dead centre, and no gold token for an arrow to
		# bite — there is simply nowhere on this panel for a sentence to name itself.
		_add_tag("0 + 1 = 1 + 0", Vector3(0.0, py + 0.10, 0.05), 0.075, cool_white)

	# --- the prover arm ---
	if v == "proved":
		_build_clamped_arm(py)
	else:
		_build_swinging_arm()

	# --- the jam ---
	if v == "honest":
		# red flare when the prover seizes, hidden between attempts
		_jam_spark = BakedText.make_tag("JAM", jam_red, 0.075, Color(0.10, 0.03, 0.04), true, jam_red)
		if _jam_spark != null:
			_jam_spark.position = _spark_pos + Vector3(0.0, 0.10, 0.0)
			_jam_spark.visible = false
			_own(_jam_spark)
	elif v == "silent":
		# The jam is no longer an event — it is the standing condition. Matte board,
		# no lit accent edge (accent alpha 0), never hidden, never pulsed: the machine
		# seizes every cycle and this is the only thing it ever shows you.
		var stuck: Node3D = BakedText.make_tag(
			"JAM", Color(0.52, 0.20, 0.23), 0.075, Color(0.10, 0.03, 0.04), true, Color(0, 0, 0, 0))
		if stuck != null:
			stuck.position = _spark_pos + Vector3(0.0, 0.10, 0.0)
			_own(stuck)
	# `proved` and `harmless` build no jam at all — nothing seizes in either machine.

	# --- the verdict at y = 1.30 ---
	match v:
		"proved":
			# Unsound: it reports a proof of G. Cyan, permanent, no fade — this machine
			# has no doubt to resolve.
			_build_verdict_plate("PROVED", PROVED_CYAN, Color(0.03, 0.09, 0.10))
		"silent":
			# No plate. A blank steel strip where the conclusion would be printed.
			var blank_mat := _steel_tracked(Color(0.19, 0.20, 0.23))
			_own(_box(Vector3(0.0, 1.30, 0.0), Vector3(0.30, 0.06, 0.012), blank_mat))
		"harmless":
			_build_verdict_plate("CONSISTENT AND COMPLETE", cool_white, Color(0.07, 0.08, 0.10))
		_:
			# honest — the shipped gold plate, eased in over the conclude window.
			_build_verdict_plate("TRUE — BUT UNPROVABLE", true_gold, Color(0.10, 0.08, 0.03))

	# --- title ---
	_add_tag("GODEL SENTENCE MACHINE", Vector3(0.0, 1.5, 0.0), 0.088, cool_white)


## The shipped arm: pivots at the right edge, swings in toward G, and is driven by
## _process. Used by honest, silent and harmless.
func _build_swinging_arm() -> void:
	_arm = Node3D.new()
	_own(_arm)
	var arm_mat := _steel_tracked(Color(0.78, 0.82, 0.90))
	# upper arm segment, pivoting at _arm_pivot
	_arm.add_child(_cylinder_between(Vector3.ZERO, Vector3(-0.34, 0.0, 0.08), 0.018, arm_mat))
	# the "PROVE" clamp at the reaching end
	var clamp_mat := _glow_tracked(panel_blue, 0.9)
	var clamp := Node3D.new()
	clamp.position = Vector3(-0.34, 0.0, 0.08)
	clamp.add_child(_box(Vector3(0.0, 0.04, 0.0), Vector3(0.10, 0.012, 0.05), clamp_mat))
	clamp.add_child(_box(Vector3(0.0, -0.04, 0.0), Vector3(0.10, 0.012, 0.05), clamp_mat))
	_arm.add_child(clamp)
	_arm.position = _arm_pivot
	_add_tag("PROVE", Vector3(0.40, 1.10, 0.0), 0.050, panel_blue, panel_blue)


## The unsound arm: it got there. Two segments run from the same pivot, under the
## printed sentence, to the gold G-dot, where the two 0.10 x 0.012 x 0.05 m jaws are
## closed (0.020 m apart instead of 0.080) on a 0.04 m cyan bar. Static — _arm is left
## null so _process never swings it. Nothing about this machine is still trying.
func _build_clamped_arm(py: float) -> void:
	var arm_mat := _steel_tracked(Color(0.78, 0.82, 0.90))
	var g_pos: Vector3 = Vector3(-0.30, py - 0.04, 0.06)
	var clamp_pos: Vector3 = g_pos + Vector3(0.0, 0.0, 0.045)
	var elbow: Vector3 = Vector3(0.15, py - 0.06, 0.09)
	var rig := Node3D.new()
	_own(rig)
	rig.add_child(_cylinder_between(_arm_pivot, elbow, 0.018, arm_mat))
	rig.add_child(_cylinder_between(elbow, clamp_pos + Vector3(0.06, 0.0, 0.0), 0.018, arm_mat))

	var clamp_mat := _glow_tracked(panel_blue, 0.9)
	var jaw := Node3D.new()
	jaw.position = clamp_pos
	jaw.add_child(_box(Vector3(0.0, 0.016, 0.0), Vector3(0.10, 0.012, 0.05), clamp_mat))
	jaw.add_child(_box(Vector3(0.0, -0.016, 0.0), Vector3(0.10, 0.012, 0.05), clamp_mat))
	# the bar bridging the closed jaws — the proof it should not be holding
	var bar_mat := _glow_tracked(PROVED_CYAN, 1.3)
	jaw.add_child(_box(Vector3.ZERO, Vector3(0.04, 0.020, 0.014), bar_mat))
	rig.add_child(jaw)

	_add_tag("PROVE", Vector3(0.40, 1.10, 0.0), 0.050, panel_blue, panel_blue)


## The 0.86 x 0.13 m plate at y = 1.30. Honest keeps the shipped fade-in (alpha driven
## by _process); every other value is printed once and left there, so a single frame
## always catches the conclusion.
func _build_verdict_plate(text: String, text_color: Color, bg: Color) -> void:
	_verdict = BakedText.make_panel_mesh(text, bg, text_color, Vector2(0.86, 0.13))
	if _verdict == null:
		return
	_verdict.position = Vector3(0.0, 1.30, 0.0)
	_verdict_mat = _verdict.material_override as StandardMaterial3D
	if _verdict_mat != null:
		_verdict_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_verdict_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_verdict_mat.albedo_color = Color(1, 1, 1, 0.0 if _verdict_animates else 1.0)
	_own(_verdict)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var phase: float = fmod(_t, cycle_period) / cycle_period  # 0..1

	# The cycle: attempt (reach in) -> jam (seize, red) -> conclude (gold verdict).
	# phase 0.00..0.40  attempt: arm swings in toward G
	# phase 0.40..0.55  jam: arm shudders, red spark flares
	# phase 0.55..1.00  conclude: arm retracts, gold verdict glows then fades
	var reach: float = 0.0
	var jam: float = 0.0
	var conclude: float = 0.0
	if phase < 0.40:
		reach = _smooth(phase / 0.40)
	elif phase < 0.55:
		reach = 1.0
		jam = (phase - 0.40) / 0.15
	else:
		conclude = (phase - 0.55) / 0.45
		reach = 1.0 - _smooth(conclude)
	# The unsound machine and the weak one never seize — no shudder, no red flush.
	if not _jams:
		jam = 0.0

	# arm swings from parked (out) to reaching (in toward G)
	# (`proved` leaves _arm null — its arm is already closed on the dot.)
	if is_instance_valid(_arm):
		var parked: float = -0.55
		var reaching: float = -1.30
		_arm.rotation.z = lerpf(parked, reaching, reach)
		# shudder while jammed
		if jam > 0.0:
			_arm.rotation.z += sin(_t * 60.0) * 0.05 * (1.0 - absf(jam * 2.0 - 1.0) * 0.0)

	# self-reference loop always spins — G chasing its own tail
	# (absent entirely on `harmless`: nothing there names itself.)
	if is_instance_valid(_loop_mi):
		_loop_mi.rotation.y = _t * 1.4
	if _loop_mat != null:
		_loop_mat.emission_energy_multiplier = (0.9 + 0.4 * sin(_t * 3.0)) if emissive else 0.0

	# jam spark: red flare during the jam window (board shown + pulsed while jammed).
	# `silent` builds its board untracked, so it is never touched here — it just stays.
	if is_instance_valid(_jam_spark):
		var a: float = 0.0
		if jam > 0.0:
			a = sin(jam * PI)  # 0..1..0 across the jam window
		_jam_spark.visible = a > 0.01
		_jam_spark.scale = Vector3.ONE * (1.0 + a * 0.5 + 0.1 * sin(_t * 50.0) * a)
	# panel flushes red at the jam, cools otherwise
	if _g_panel_mat != null:
		var heat: float = 0.0
		if jam > 0.0:
			heat = sin(jam * PI)
		_g_panel_mat.emission = panel_blue.lerp(jam_red, heat)
		_g_panel_mat.emission_energy_multiplier = (0.35 + heat * 0.9) if emissive else 0.0

	# verdict: gold conclusion plate, eased in over the conclude window, breathing
	if _verdict_animates and is_instance_valid(_verdict):
		var va: float = _smooth(clampf(conclude * 2.0, 0.0, 1.0))
		_verdict.visible = va > 0.001
		_verdict.scale = Vector3.ONE * (1.0 + 0.06 * sin(_t * 2.5) * va)
		if _verdict_mat != null:
			_verdict_mat.albedo_color = Color(1, 1, 1, va)


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

## Add a node AND record it as ours. Only nodes in _owned are ever freed.
func _own(n: Node) -> void:
	if n == null:
		return
	_owned.append(n)
	add_child(n)


## _glow_mat + registration, so the emissive flag can be re-applied without a rebuild.
func _glow_tracked(c: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = _glow_mat(c, energy)
	_glow_reg.append({"mat": m, "energy": energy})
	return m


func _steel_tracked(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = _steel_mat(c)
	_steel_reg.append(m)
	return m


func _add_tag(text: String, pos: Vector3, world_h: float, color: Color,
		accent: Color = Color(0.86, 0.40, 0.16)) -> void:
	var tag: Node3D = BakedText.make_tag(text, color, world_h, Color(0.08, 0.09, 0.11), true, accent)
	if tag == null:
		return
	tag.position = pos
	_own(tag)


func _smooth(x: float) -> float:
	var c: float = clampf(x, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)
