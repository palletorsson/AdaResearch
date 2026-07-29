extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MicrostateCounter

## @identity
## name: Microstate Counter
## truth: entropy counts the ways — S = k log W; one macrostate, astronomically many microstates.
##
## E as POSSIBILITY SPACE (QFE = F − λE(S) + φΔE(S,t)). A sealed glass box of gas holds
## ONE fixed macrostate ("UNIFORM  T=300K") while its ~40 particles ceaselessly SHUFFLE
## into ever-new microstates. A readout climbs/holds a huge W and S = k log W — making the
## Boltzmann count legible: the macrostate never changes, yet the arrangements behind it
## are uncountably many. Entropy is not disorder; it is the size of the ways-to-be ledger.

const TextScreenScript = preload("res://commons/ui/text_screen.gd")

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA AXIS — #macrostate:corner
# ═══════════════════════════════════════════════════════════════════

## WHICH macrostate the sealed chamber actually holds — and therefore how many ways
## there are to be it, or whether the chamber holds anything at all.
##
##   uniform — the legacy build: the gas free across the whole 0.62 m chamber,
##             W ~ 10^55, plate reads UNIFORM T=300K.
##   corner  — the same particle count squeezed into one 0.20 m octant, the rest of
##             the chamber visibly empty, an amber wireframe marking the constraint.
##             W falls to ~10^21. Fewer ways to be it, RENDERED rather than asserted.
##   layered — sorted into two 0.12 m slabs with a 0.14 m empty band between them,
##             warm above, cooled below. W ~ 10^33.
##   spilled — the lid and its four top edges are not built and 14 particles are
##             outside the rim. W ~ unbounded: the seal is what made the count mean
##             anything, and this value is the chamber admitting it.
##
## The axis lives in the ARRANGEMENT, which is placed deterministically at build time
## and is stable on frame 1. The shuffle only moves particles inside whatever region
## the value has fenced.
@export_enum("uniform", "corner", "layered", "spilled") var macrostate: String = "uniform"

## Allow-list. A typo in a map token falls back to the legacy look rather than
## stranding a placement with no gas region at all.
const MACROSTATES: PackedStringArray = ["uniform", "corner", "layered", "spilled"]

## Phase-cells per particle, per macrostate. W = cells^N, so log10(W) = N·log10(cells).
## With particle_count = 40: 24.0 -> 10^55, 3.35 -> 10^21, 6.8 -> 10^33.
## `spilled` keeps the uniform base only so the internal number stays finite; its
## ledger never prints an exponent.
const CELLS_BASE: Dictionary = {
	"uniform": 24.0,
	"corner": 3.35,
	"layered": 6.8,
	"spilled": 24.0,
}

## What the macrostate plate reads. `uniform` defers to the macrostate_label export
## so an author who set it still gets their string on the legacy value.
const PLATE_TEXT: Dictionary = {
	"uniform": "UNIFORM  T=300K",
	"corner": "CORNERED",
	"layered": "SORTED T=380/220K",
	"spilled": "OPEN",
}

const CORNER_SIDE: float = 0.20     # the confined octant, metres
const SLAB_H: float = 0.12          # each sorted slab's thickness
const SLAB_GAP: float = 0.14        # the empty band between them
const SLAB_SPAN: float = 0.57       # slab width/depth across the interior
const SPILL_RISE: float = 0.35      # how far escaped particles drift above the rim
const SPILL_FRAC: float = 0.35      # fraction of the gas that is outside (14 of 40)
const COOL_COLOR: Color = Color(0.35, 0.6, 1.0)
const AMBER: Color = Color(1.0, 0.68, 0.2)

## Fixed seed: the arrangement must be the same draw every launch, so a still of
## `corner` differs from a still of `uniform` because of the axis and not the dice.
const RNG_SEED: int = 20260729

@export var particle_count: int = 40
@export var box_size: Vector3 = Vector3(0.62, 0.62, 0.62)
@export var shuffle_speed: float = 1.4
@export var macrostate_label: String = "UNIFORM  T=300K"
@export var glow_color: Color = Color(0.45, 0.85, 1.0)
@export var particle_color: Color = Color(0.7, 0.95, 1.0)
@export var frame_color: Color = Color(0.55, 0.7, 0.95)

# Each gas group: {mm, pos, tgt, lo, hi, phase}. `uniform`/`corner` build one group,
# `layered` and `spilled` build two — the second group is the whole point of the value.
var _gas: Array = []
var _title: Label3D
var _readout: Label3D
var _screen: Node3D
var _last_body: String = ""
var _owned: Array[Node] = []
## Materials this script made, with their lit and unlit emission energies, so an
## `emissive` key can be honoured IN PLACE instead of by a rebuild that would
## discard label framing applied one line earlier by the curation station.
var _emis: Array = []
var _built: bool = false
var _t: float = 0.0
var _reshuffle_at: float = 0.0
var _log10_w: float = 0.0  # log10 of the number of microstates


func _ready() -> void:
	_build_all()
	_built = true
	set_process(not Engine.is_editor_hint())


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config: Dictionary) -> void:
	var before_m: String = macrostate
	if config.has("macrostate"):
		macrostate = _pick_axis(str(config["macrostate"]), MACROSTATES, macrostate)

	# Applied in place, before every early return. An accepted key must DO something,
	# and curation_station.gd sends {"emissive": false} with no axis key at all.
	if config.has("emissive"):
		var e: bool = bool(config["emissive"])
		if e != emissive:
			emissive = e
			_apply_emissive_in_place()

	if not _built:
		return
	if macrostate == before_m:
		return
	_rebuild_now()
	print("[MicrostateCounter] Config applied — macrostate=%s" % [macrostate])


## Accept an axis value only if it names something we actually build.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _rebuild_now() -> void:
	# Free ONLY what this script made. get_children() here would destroy the plates
	# and bezels the grid added behind the labels.
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_gas.clear()
	_emis.clear()
	_title = null
	_readout = null
	_screen = null
	_last_body = ""
	_build_all()          # SYNCHRONOUS — a deferred rebuild leaves auto-grounding a zero AABB


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	_rng.seed = RNG_SEED
	var box_center: Vector3 = Vector3(0.0, 0.72, 0.0)
	_build_plinth()
	_build_chamber(box_center)
	_build_gas(box_center)
	_build_labels()


func _build_plinth() -> void:
	# --- floor base / instrument plinth (y ~ 0) ---
	var base_mat: StandardMaterial3D = _steel_mat(Color(0.16, 0.2, 0.3))
	_own(_cylinder(Vector3(0.0, 0.04, 0.0), 0.42, 0.08, base_mat))
	_own(_cylinder(Vector3(0.0, 0.11, 0.0), 0.36, 0.06, _matte_mat(Color(0.2, 0.26, 0.4), 0.6, 0.3)))

	# --- support pedestal up to the sealed box ---
	var post_mat: StandardMaterial3D = _steel_mat(frame_color * 0.7)
	_own(_cylinder(Vector3(0.0, 0.32, 0.0), 0.05, 0.34, post_mat))


func _build_chamber(box_center: Vector3) -> void:
	var glass: StandardMaterial3D = _glass_mat(glow_color, 0.12)
	var open_top: bool = macrostate == "spilled"

	if open_top:
		# THE SEAL IS THE THING THAT MADE W COUNTABLE. Five plates instead of six:
		# four walls and a floor, and no lid.
		var hx: float = box_size.x * 0.5
		var hy: float = box_size.y * 0.5
		var hz: float = box_size.z * 0.5
		var t: float = 0.01
		_own(_box(box_center + Vector3(hx, 0.0, 0.0), Vector3(t, box_size.y, box_size.z), glass))
		_own(_box(box_center + Vector3(-hx, 0.0, 0.0), Vector3(t, box_size.y, box_size.z), glass))
		_own(_box(box_center + Vector3(0.0, 0.0, hz), Vector3(box_size.x, box_size.y, t), glass))
		_own(_box(box_center + Vector3(0.0, 0.0, -hz), Vector3(box_size.x, box_size.y, t), glass))
		_own(_box(box_center + Vector3(0.0, -hy, 0.0), Vector3(box_size.x, t, box_size.z), glass))
	else:
		# --- the sealed glass chamber (the macrostate container), centered ~0.72 ---
		_own(_box(box_center, box_size, glass))

	# glowing edge frame so the sealed boundary reads clearly — minus the four top
	# edges when there is no longer a boundary up there to read.
	_add_box_frame(box_center, box_size, 0.012, _glow_mat(frame_color, 2.0), open_top)

	# a thin emissive floor inside the chamber (the "gas resting plane")
	_own(_box(box_center + Vector3(0.0, -box_size.y * 0.5 + 0.01, 0.0),
		Vector3(box_size.x * 0.92, 0.012, box_size.z * 0.92),
		_glow_mat(glow_color * 0.6, 1.0)))

	if macrostate == "corner":
		# The constraint made visible: an amber cage around the only octant the gas
		# is allowed to occupy. Without it a viewer reads a half-empty box as a bug.
		var lo: Vector3 = _interior_half() * -1.0
		var cage_c: Vector3 = box_center + lo + Vector3.ONE * (CORNER_SIDE * 0.5)
		_add_box_frame(cage_c, Vector3.ONE * CORNER_SIDE, 0.008, _glow_mat(AMBER, 2.2), false)


func _build_gas(box_center: Vector3) -> void:
	# --- the gas: one MultiMesh per REGION the macrostate fences off ---
	for plan_v in _region_plan():
		var plan: Dictionary = plan_v
		var n: int = int(plan["count"])
		if n <= 0:
			continue
		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.instance_count = n
		var sph: SphereMesh = SphereMesh.new()
		sph.radius = 0.018
		sph.height = 0.036
		sph.radial_segments = 7
		sph.rings = 4
		mm.mesh = sph
		var inst: MultiMeshInstance3D = MultiMeshInstance3D.new()
		inst.name = str(plan["name"])
		inst.multimesh = mm
		var col: Color = plan["color"]
		inst.material_override = _glow_mat(col, float(plan["energy"]))
		inst.position = box_center
		_own(inst)

		var lo: Vector3 = plan["lo"]
		var hi: Vector3 = plan["hi"]
		var clear_x: float = float(plan.get("clear_x", 0.0))
		var pos: PackedVector3Array = PackedVector3Array()
		var tgt: PackedVector3Array = PackedVector3Array()
		pos.resize(n)
		tgt.resize(n)
		var i: int = 0
		while i < n:
			var p: Vector3 = _draw_in(lo, hi, clear_x)
			pos[i] = p
			tgt[i] = _draw_in(lo, hi, clear_x)
			mm.set_instance_transform(i, Transform3D(Basis(), p))
			mm.set_instance_color(i, col)
			i += 1
		_gas.append({
			"mm": mm, "pos": pos, "tgt": tgt,
			"lo": lo, "hi": hi, "clear_x": clear_x,
			"phase": float(_gas.size()) * 1.9,
		})


## The regions the current macrostate fences off, and how many particles live in each.
## Every value returns a DIFFERENT set of regions — there is no no-op branch here.
func _region_plan() -> Array:
	var h: Vector3 = _interior_half()
	var plans: Array = []

	if macrostate == "corner":
		# One 0.20 m octant at the lower-left-back inner corner. The other
		# 0.55 m of the chamber stays empty, which IS the falling count.
		var c_lo: Vector3 = h * -1.0
		plans.append({
			"name": "GasParticles", "count": particle_count,
			"lo": c_lo, "hi": c_lo + Vector3.ONE * CORNER_SIDE,
			"color": particle_color, "energy": 2.4,
		})
	elif macrostate == "layered":
		# Two slabs, a dead band between them, sorted warm over cold.
		var s: float = SLAB_SPAN * 0.5
		var y0: float = SLAB_GAP * 0.5
		var y1: float = y0 + SLAB_H
		var top_n: int = particle_count / 2
		plans.append({
			"name": "GasParticlesWarm", "count": top_n,
			"lo": Vector3(-s, y0, -s), "hi": Vector3(s, y1, s),
			"color": particle_color, "energy": 2.4,
		})
		plans.append({
			"name": "GasParticlesCool", "count": particle_count - top_n,
			"lo": Vector3(-s, -y1, -s), "hi": Vector3(s, -y0, s),
			"color": COOL_COLOR, "energy": 2.0,
		})
	elif macrostate == "spilled":
		# Most of the gas still in the box; the rest already out over the rim.
		# `clear_x` holds the plume out of the caption corridor: the framed plates
		# above the chamber are opaque and reach x ±0.385, so escaped particles
		# spill over the two side rims instead of standing behind the signage.
		var out_n: int = int(round(float(particle_count) * SPILL_FRAC))
		var rim: float = box_size.y * 0.5
		plans.append({
			"name": "GasParticles", "count": particle_count - out_n,
			"lo": h * -1.0, "hi": h,
			"color": particle_color, "energy": 2.4,
		})
		plans.append({
			"name": "GasEscaped", "count": out_n,
			"lo": Vector3(-0.55, rim + 0.02, -0.45),
			"hi": Vector3(0.55, rim + SPILL_RISE, 0.45),
			"color": particle_color, "energy": 2.4,
			"clear_x": 0.42,
		})
	else:
		# uniform — the legacy region, the whole interior.
		plans.append({
			"name": "GasParticles", "count": particle_count,
			"lo": h * -1.0, "hi": h,
			"color": particle_color, "energy": 2.4,
		})

	return plans


func _build_labels() -> void:
	# --- titles / readouts ---------------------------------------------------
	# Every hanging label here is FRAMED at spawn into an opaque plate roughly
	# text width + 0.05 m by text height + 0.035 m. The stack below was authored
	# for see-through billboards and shingles once the plates are real, so the
	# three captions are re-spaced and the ledger has left the stack entirely.
	_title = _billboard_label("MICROSTATE COUNTER", Vector3(0.0, 1.56, 0.0), 28, glow_color)
	_own(_title)

	# macrostate plate: the ONE thing that never changes while the gas shuffles
	_own(_billboard_label("MACROSTATE", Vector3(0.0, 1.33, 0.0), 17, Color(0.8, 0.9, 1.0)))
	_own(_billboard_label(_plate_text(), Vector3(0.0, 1.15, 0.0), 22, Color(1.0, 1.0, 1.0)))

	# The ledger is a READOUT, not a caption — and its three-line plate was landing
	# 0.165 m below the chamber top, covering the lid, the top frame edge and the
	# particles nearest it. It moves onto a side-mounted lab screen beside the box.
	var ts: Node3D = TextScreenScript.new()
	ts.name = "LedgerScreen"
	ts.set("mode", 0)            # TextScreen.Mode.SCREEN — a framed panel alone
	ts.set("width_m", 0.56)
	ts.position = Vector3(0.66, 0.78, 0.0)
	_screen = ts

	# The Label3D survives as the text source under the screen: billboard disabled
	# (so the framer leaves it alone) and glyphs scaled to nothing.
	_readout = _billboard_label("", Vector3(0.0, 0.0, -0.02), 18, glow_color)
	_readout.name = "LedgerText"
	_readout.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_readout.no_depth_test = false
	_readout.outline_size = 0
	_readout.pixel_size = 0.0001
	ts.add_child(_readout)

	_own(ts)
	_refresh_count()
	_update_readout()


func _plate_text() -> String:
	if macrostate == "uniform":
		return macrostate_label
	return str(PLATE_TEXT.get(macrostate, macrostate_label))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# Continuously interpolate each particle toward its current target microstate,
	# then re-roll a new target — the macrostate is fixed, the microstate never settles.
	var reached: bool = true
	for g_v in _gas:
		var g: Dictionary = g_v
		var mm: MultiMesh = g["mm"]
		var pos: PackedVector3Array = g["pos"]
		var tgt: PackedVector3Array = g["tgt"]
		var phase: float = float(g["phase"])
		var n: int = pos.size()
		var i: int = 0
		while i < n:
			var cur: Vector3 = pos[i]
			var dst: Vector3 = tgt[i]
			var nxt: Vector3 = cur.lerp(dst, clampf(delta * shuffle_speed * 2.2, 0.0, 1.0))
			pos[i] = nxt
			if nxt.distance_to(dst) > 0.02:
				reached = false
			# subtle thermal jitter so the gas always shimmers
			var f: float = float(i) + phase
			var jit: Vector3 = Vector3(
				sin(_t * 3.1 + f) * 0.004,
				cos(_t * 2.7 + f * 1.7) * 0.004,
				sin(_t * 2.3 + f * 0.9) * 0.004)
			mm.set_instance_transform(i, Transform3D(Basis(), nxt + jit))
			i += 1
		g["pos"] = pos

	# whole gas drifts to a brand-new microstate arrangement on a cadence — but only
	# ever inside the region this macrostate fenced off.
	_reshuffle_at -= delta
	if reached or _reshuffle_at <= 0.0:
		_reshuffle_at = 0.7 / maxf(shuffle_speed, 0.1)
		for g_v2 in _gas:
			var g2: Dictionary = g_v2
			var tgt2: PackedVector3Array = g2["tgt"]
			var lo: Vector3 = g2["lo"]
			var hi: Vector3 = g2["hi"]
			var cx: float = float(g2.get("clear_x", 0.0))
			var j: int = 0
			while j < tgt2.size():
				tgt2[j] = _draw_in(lo, hi, cx)
				j += 1
			g2["tgt"] = tgt2
		_refresh_count()

	_update_readout()

	# gentle instrument breathing on the title
	if _title != null and is_instance_valid(_title):
		var pulse: float = 0.5 + 0.5 * sin(_t * 1.6)
		_title.modulate = glow_color.lerp(Color(1.0, 1.0, 1.0), 0.25 * pulse)


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

func _own(n: Node) -> Node:
	_owned.append(n)
	add_child(n)
	return n


## Half-extent of the usable interior, in chamber-local metres (the legacy 0.42 factor).
func _interior_half() -> Vector3:
	return Vector3(box_size.x * 0.42, box_size.y * 0.42, box_size.z * 0.42)


func _random_in(lo: Vector3, hi: Vector3) -> Vector3:
	return Vector3(
		_rng.randf_range(lo.x, hi.x),
		_rng.randf_range(lo.y, hi.y),
		_rng.randf_range(lo.z, hi.z))


## A draw inside the region, with an optional forbidden middle band in x. Used only
## by `spilled`: the escaped gas must not stand behind the opaque caption plates,
## so anything drawn inside the corridor is pushed out to the nearer side rim.
func _draw_in(lo: Vector3, hi: Vector3, clear_x: float) -> Vector3:
	var p: Vector3 = _random_in(lo, hi)
	if clear_x > 0.0 and absf(p.x) < clear_x:
		var s: float = 1.0 if p.x >= 0.0 else -1.0
		p.x = s * (clear_x + absf(p.x) * 0.7)
	return p


func _refresh_count() -> void:
	# W ~ phase-cells ^ particles. Each fresh draw nudges the exponent so S breathes
	# slightly while staying at the magnitude this macrostate permits. The jitter is
	# a fixed FRACTION of the base (6.25%, i.e. exactly the legacy ±1.5 on 24.0), so
	# a small cell count does not swing wildly.
	var base: float = float(CELLS_BASE.get(macrostate, 24.0))
	var wob: float = base * 0.0625
	var cells: float = maxf(base + _rng.randf_range(-wob, wob), 1.05)
	_log10_w = float(particle_count) * (log(cells) / log(10.0))


func _update_readout() -> void:
	# S = k log W. Display in J/K with Boltzmann k, and W as a 10^N magnitude —
	# except when the lid is off, where the count has no boundary to be taken over.
	var k: float = 1.380649e-23
	var ln_w: float = _log10_w * log(10.0)
	var s: float = k * ln_w
	var w_text: String = "W ~ 10^%d microstates" % int(round(_log10_w))
	var s_text: String = "= %.2e J/K" % s
	var tail: String = "(one macrostate, all of these)"
	if macrostate == "spilled":
		w_text = "W ~ unbounded"
		s_text = "= —"
		tail = "(the count needed the seal)"
	var body: String = w_text + "\n" + s_text + "\n" + tail

	if _readout != null and is_instance_valid(_readout):
		_readout.text = body
	if body == _last_body:
		return
	_last_body = body
	# TextScreen bakes its text into a mesh, so only push when the string actually
	# changed — this runs every frame.
	if _screen != null and is_instance_valid(_screen) and _screen.has_method("set_text"):
		_screen.call("set_text", "S = k log W", body)


func _add_box_frame(center: Vector3, size: Vector3, r: float, mat: Material, skip_top: bool = false) -> void:
	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5
	var corners: Array = [
		Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz),
		Vector3(hx, -hy, hz), Vector3(-hx, -hy, hz),
		Vector3(-hx, hy, -hz), Vector3(hx, hy, -hz),
		Vector3(hx, hy, hz), Vector3(-hx, hy, hz)]
	var edges: Array = [
		[0, 1], [1, 2], [2, 3], [3, 0],
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7]]
	for e in edges:
		if skip_top and e[0] >= 4 and e[1] >= 4:
			continue
		var a: Vector3 = center + corners[e[0]]
		var b: Vector3 = center + corners[e[1]]
		_own(_cylinder_between(a, b, r, mat))


# ------------------------------------------------------------------
# Emissive, applied in place
# ------------------------------------------------------------------
# The three emissive material helpers are wrapped so every material this script
# makes records its lit and unlit energies. An `emissive` key then flips them
# without a rebuild — barber_paradox and impossible_trident accepted the key and
# applied it nowhere once their early return removed the rebuild that used to.

func _glow_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = super._glow_mat(c, energy)
	_track_emissive(m, energy, energy * 0.3)
	return m


func _steel_mat(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = super._steel_mat(c)
	_track_emissive(m, 0.1, 0.0)
	return m


func _glass_mat(c: Color, alpha: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = super._glass_mat(c, alpha)
	_track_emissive(m, 0.3, 0.0)
	return m


func _track_emissive(m: StandardMaterial3D, on: float, off: float) -> void:
	_emis.append({"m": m, "on": on, "off": off})


func _apply_emissive_in_place() -> void:
	for e_v in _emis:
		var e: Dictionary = e_v
		var m: StandardMaterial3D = e["m"]
		if m == null:
			continue
		m.emission_energy_multiplier = float(e["on"]) if emissive else float(e["off"])
