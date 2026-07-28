extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BarberParadox

## @identity
## name: Barber Paradox
## lineage: Russell's paradox in story form — the village barber who shaves
##   exactly those who do not shave themselves.
## essence: two labelled bins, SHAVES SELF and SHAVED BY BARBER. A barber token
##   (figure + razor) is sorted by an arrow that can never land — it flips back
##   and forth between the bins forever, a red "?" pulsing above.
## truth: he belongs in neither bin; the rule eats itself. If the barber shaves
##   himself he is shaved-by-the-barber (forbidden); if he does not, the rule
##   says the barber must shave him — contradiction either way.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var bin_blue: Color = Color(0.40, 0.62, 0.95)
@export var contradiction_red: Color = Color(0.902, 0.224, 0.275)
@export var flip_period: float = 2.0

## Stage-2 DNA axis — `roster`.
##
## VARIES: how many slots the village rule offers, and whether the scheme admits
## it has no slot for the barber. The paradox is a fact about a CLASSIFICATION,
## and this object keeps its classification in furniture — bins — so the furniture
## is the honest knob. Bin count and bin width are the dominant mass in every
## framing, which is why the axis is cut here and not on the flip.
##
##   pair       the shipped scheme. Two 0.30 m bins at x = ±0.42, the token
##              oscillating between them under a red 64 pt "?". Nothing moves.
##   exception  a third 0.30 m bin at x = 0 labelled NEITHER; the token STANDS in
##              it and the "?" becomes a cool-white full-stop sphere. The
##              administrative escape — the paradox dissolved by minting a slot
##              for it, which is what every real institution does. A map can stand
##              this next to `pair` and let a walker decide whether anything was
##              answered.
##   blanket    one 1.10 m bin labelled EVERYONE spanning both old positions. The
##              distinction the rule depends on is gone, so the token has a slot —
##              but the red "?" is still built at full size, because the verdict is
##              no closer.
##   none       no bins, no glass, no bin labels. Only the post, the token riding
##              it and the "?" enlarged to 96 pt: a rule with nothing to sort
##              anyone into.
##
## NOT an axis: the flip. `flip_period` is a timer — swept blind it photographs as
## five identical tiles.
@export_enum("pair", "exception", "blanket", "none") var roster: String = "pair"

## Allow-list for `roster`. A token outside it falls back to the current value
## rather than half-recognising a typo and stranding a placement with no bins.
const ROSTERS: PackedStringArray = ["pair", "exception", "blanket", "none"]

# --- bin geometry, shared by every roster value ------------------------------
const BIN_W: float = 0.30          ## a single-category bin, metres wide
const BIN_WIDE_W: float = 1.10     ## `blanket`: one bin spanning both positions
const BIN_H: float = 0.34
const BIN_D: float = 0.24
const BIN_Y: float = 0.32          ## bin centre height; floor plate sits at 0.15

## Token feet on a bin's glowing floor plate: 0.32 - 0.17 + 0.005 + 0.04 (the
## body cylinder's local half-height).
const TOKEN_STAND_Y: float = 0.195

## Fixed — two builds of one roster value must be pixel-identical or the critic
## reads noise as signal. `_rng` is unused by the build; the seed is hygiene.
const BUILD_SEED: int = 20260728

var _token: Node3D
var _arrow_root: Node3D
var _qmark: Label3D
var _fullstop: MeshInstance3D
var _t: float = 0.0
var _left_pos: Vector3 = Vector3(-0.42, 0.62, 0.0)
var _right_pos: Vector3 = Vector3(0.42, 0.62, 0.0)

## Only nodes THIS script created. Freeing get_children() would destroy the grid's
## label plates, packaging and tag markers.
var _owned: Array[Node] = []
var _built: bool = false


func _ready() -> void:
	_rng.seed = BUILD_SEED
	_build()
	_built = true
	set_process(not Engine.is_editor_hint())


## Contract: this runs AFTER _ready(), via call_deferred from
## GridInteractablesComponent — and curation_station calls it with
## {"emissive": false} one line after hiding this artifact's labels. An
## unconditional rebuild there would throw that framing away, so a config that
## changes no geometry must touch nothing and say nothing.
func apply_grid_config(config: Dictionary) -> void:
	var before_roster: String = roster

	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("roster"):
		roster = _pick_axis(str(config["roster"]), ROSTERS, roster)
	if config.has("flip_period"):
		flip_period = maxf(0.05, float(config["flip_period"]))

	if not _built:
		return   # _ready has not run yet; it will build with these values.

	if roster == before_roster:
		# `emissive` and `flip_period` need no geometry — emissive is baked into
		# materials at build time and the next frame reads flip_period. Rebuilding
		# for them is the regression that broke curated placements.
		return

	_rebuild_now()
	print("[BarberParadox] Config applied — roster=%s" % [roster])


## Accept an axis value only if it names something we actually build.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous. A deferred rebuild that removes children first makes
## _auto_ground_artifact measure a zero AABB and never ground the artifact.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_token = null
	_arrow_root = null
	_qmark = null
	_fullstop = null
	_t = 0.0
	_build()


func _add(n: Node) -> Node:
	add_child(n)
	_owned.append(n)
	return n


func _build() -> void:
	# --- floor disc (a chalk ring on the ground, no bench) ---
	# Built for every roster. It is also the widest thing here at r = 0.62, so the
	# capture camera frames all four values identically and the bins are compared
	# against a fixed border rather than against a re-zoom.
	var ring_mat := _glow_mat(wire_purple, 0.5)
	_add(_torus(Vector3(0.0, 0.02, 0.0), 0.62, 0.012, ring_mat))

	# --- the roster: how many slots the rule offers ---
	match roster:
		"exception":
			# The administrative escape: the two original categories PLUS a minted
			# third one that exists only to hold the thing the rule could not hold.
			_build_bin(Vector3(-0.42, BIN_Y, 0.0), "SHAVES SELF", BIN_W)
			_build_bin(Vector3(0.42, BIN_Y, 0.0), "SHAVED BY BARBER", BIN_W)
			_build_bin(Vector3(0.0, BIN_Y, 0.0), "NEITHER", BIN_W)
		"blanket":
			# One category. The distinction is gone, so nothing can contradict it —
			# and nothing can be decided by it either.
			_build_bin(Vector3(0.0, BIN_Y, 0.0), "EVERYONE", BIN_WIDE_W)
		"none":
			pass   # a rule with nothing to sort anyone into
		_:
			# "pair" — the shipped scheme, untouched.
			_build_bin(Vector3(-0.42, BIN_Y, 0.0), "SHAVES SELF", BIN_W)
			_build_bin(Vector3(0.42, BIN_Y, 0.0), "SHAVED BY BARBER", BIN_W)

	# central post the token rides on, between the bins
	var post_mat := _steel_mat(Color(0.34, 0.36, 0.42))
	_add(_cylinder(Vector3(0.0, 0.31, 0.0), 0.02, 0.62, post_mat))

	# --- the barber token: a little figure holding a razor ---
	_token = Node3D.new()
	_token.position = _token_home()
	_add(_token)
	var skin := _matte_mat(cool_white, 0.6)
	# head
	_token.add_child(_sphere(Vector3(0.0, 0.16, 0.0), 0.05, skin))
	# body
	_token.add_child(_cylinder(Vector3(0.0, 0.05, 0.0), 0.045, 0.18, skin))
	# razor — a small steel blade on a red handle, jutting from the side
	var steel := _steel_mat(Color(0.80, 0.84, 0.92))
	var handle := _matte_mat(contradiction_red, 0.5)
	_token.add_child(_cylinder_between(Vector3(0.06, 0.08, 0.0), Vector3(0.13, 0.08, 0.0), 0.008, handle))
	_token.add_child(_box(Vector3(0.17, 0.10, 0.0), Vector3(0.07, 0.05, 0.004), steel))

	# --- the sorting arrow, pointing from above toward a bin ---
	# Under "pair" it is rebuilt each frame chasing the token; under every other
	# roster it is aimed once and left there, because the sorting has stopped.
	_arrow_root = Node3D.new()
	_add(_arrow_root)
	_reaim_arrow(_token_home())

	# --- the verdict above the post ---
	if roster == "exception":
		# A full stop, not a question mark: the paradox has been administered away.
		# Static — no pulse — because a settled verdict does not flicker.
		_fullstop = _sphere(Vector3(0.0, 1.18, 0.0), 0.05, _glow_mat(cool_white, 1.2))
		_add(_fullstop)
	else:
		# "none" has no categories left to argue about and shouts loudest.
		var qsize: int = 96 if roster == "none" else 64
		_qmark = _billboard_label("?", Vector3(0.0, 1.18, 0.0), qsize, contradiction_red)
		_add(_qmark)

	# --- billboard title ---
	_add(_billboard_label("BARBER PARADOX", Vector3(0.0, 1.5, 0.0), 34, cool_white))
	_add(_billboard_label("shaves all who don't shave themselves", Vector3(0.0, 1.36, 0.0), 16, wire_purple))


## Where the token lives. Under every roster but "pair" it is PARKED: a still that
## caught an arbitrary phase of the flip would show the token mid-air over a bin
## that no longer exists.
func _token_home() -> Vector3:
	match roster:
		"exception", "blanket":
			return Vector3(0.0, TOKEN_STAND_Y, 0.0)   # standing in the bin at x = 0
		"none":
			return Vector3(0.0, 0.62, 0.0)            # riding the bare post
		_:
			return _left_pos


func _build_bin(center: Vector3, label: String, bw: float) -> void:
	var wall_mat := _glass_mat(bin_blue, 0.22)
	var edge_mat := _glow_mat(bin_blue, 0.9)
	var bh: float = BIN_H
	var bd: float = BIN_D
	# three glass walls + glowing floor (open top — a bin)
	_add(_box(center + Vector3(0.0, 0.0, -bd * 0.5), Vector3(bw, bh, 0.01), wall_mat))
	_add(_box(center + Vector3(-bw * 0.5, 0.0, 0.0), Vector3(0.01, bh, bd), wall_mat))
	_add(_box(center + Vector3(bw * 0.5, 0.0, 0.0), Vector3(0.01, bh, bd), wall_mat))
	_add(_box(center + Vector3(0.0, -bh * 0.5, 0.0), Vector3(bw, 0.01, bd), edge_mat))
	# wireframe top rim
	var top: float = center.y + bh * 0.5
	_add(_box(Vector3(center.x, top, center.z - bd * 0.5), Vector3(bw, 0.008, 0.008), edge_mat))
	_add(_box(Vector3(center.x, top, center.z + bd * 0.5), Vector3(bw, 0.008, 0.008), edge_mat))
	_add(_box(Vector3(center.x - bw * 0.5, top, center.z), Vector3(0.008, 0.008, bd), edge_mat))
	_add(_box(Vector3(center.x + bw * 0.5, top, center.z), Vector3(0.008, 0.008, bd), edge_mat))
	# label above the bin
	_add(_billboard_label(label, Vector3(center.x, top + 0.12, center.z), 18, cool_white))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	if roster == "pair":
		# eased flip back and forth between the two bins — never settles
		var phase: float = fmod(_t, flip_period) / flip_period
		var tri: float = absf(phase * 2.0 - 1.0)  # 0..1..0 triangle
		var eased: float = tri * tri * (3.0 - 2.0 * tri)  # smoothstep
		var here: Vector3 = _left_pos.lerp(_right_pos, eased)
		if is_instance_valid(_token):
			_token.position = here
			# a little hop at the apex of each transfer
			_token.position.y = here.y + sin(phase * PI) * 0.06
			_token.rotation.y = sin(_t * 2.0) * 0.4

		# arrow re-aims from above toward whichever bin the token is nearer
		if is_instance_valid(_arrow_root):
			var target: Vector3 = _left_pos if eased < 0.5 else _right_pos
			_reaim_arrow(target)

	# the "?" pulses — the unresolvable verdict. Absent under "exception", where
	# the full-stop sphere holds still instead.
	if is_instance_valid(_qmark):
		var pulse: float = 0.5 + 0.5 * sin(_t * 4.0)
		_qmark.modulate = contradiction_red.lerp(cool_white, pulse * 0.4)
		_qmark.scale = Vector3.ONE * (1.0 + pulse * 0.25)


func _reaim_arrow(target_bin: Vector3) -> void:
	# Rebuild the arrow so it always points from above down toward target_bin.
	if not is_instance_valid(_arrow_root):
		return
	for c in _arrow_root.get_children():
		_arrow_root.remove_child(c)
		c.queue_free()
	var a: Vector3 = Vector3(0.0, 0.95, 0.0)
	var b: Vector3 = target_bin + Vector3(0.0, 0.16, 0.0)
	var arrow_mat := _glow_mat(contradiction_red, 1.4)
	var fresh: Node3D = _arrow(a, b, 0.014, arrow_mat)
	# reparent the arrow's parts onto our persistent root
	for c in fresh.get_children():
		fresh.remove_child(c)
		_arrow_root.add_child(c)
	fresh.queue_free()
