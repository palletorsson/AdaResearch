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

# --- caption rows ------------------------------------------------------------
#
# WHY THESE EXIST. commons/grid/LabelFramer.gd turns every hanging Label3D into an
# OPAQUE anthracite panel with a bezel at spawn — the project's rule that text in
# 3D is a plate, not floating glyphs. The captions here were authored when text was
# see-through, so they hung at body height: probe_label_placement measured five
# plates crossing the body, the "SHAVED BY BARBER" tag alone covering 13.3% of the
# frontal area. Nothing about the object changes below. These are only the heights
# at which its captions hang, chosen so every plate clears the body's frontal
# footprint.
#
# Top of the body, per roster. The tallest geometry is the sorting arrow's tail at
# y = 0.95; the tilted shaft's transformed AABB adds ~0.016. Under "exception" the
# full-stop sphere (y = 1.18, r = 0.05) is body and lifts the line to 1.23.
const BODY_TOP: float = 0.97
const BODY_TOP_EXCEPTION: float = 1.23

# Half-height of the plate the framer will build behind each caption: the glyphs
# (about font_size * pixel_size, pixel_size = 0.005) plus 0.10 m of padding and
# bezel, halved. The "?" is pulsed to 1.25x in _process and its plate is parented
# to the label, so it carries that factor.
const HALF_TAG: float = 0.11      ## font 18 — bin tags
const HALF_SUB: float = 0.10      ## font 16 — subtitle
const HALF_TITLE: float = 0.16    ## font 34 — title
const HALF_Q: float = 0.30        ## font 64 "?" pulsed
const HALF_Q_LOUD: float = 0.42   ## font 96 "?" pulsed, under `none`
const CAPTION_GAP: float = 0.05   ## air between one plate and the next

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

## Every emissive material this artifact made, with the energy it carries lit and dimmed.
##
## WHY THIS EXISTS. `emissive` is the parent's @export and the parent bakes it into the
## material AT CREATION (embodied_prop.gd:30 and :50). Before promotion apply_grid_config
## freed every child and rebuilt, so a new `emissive` value was picked up by the new
## materials. The Stage-2 early-return correctly stopped that rebuild — and silently took
## `emissive` with it, because nothing re-reads it. curation_station.gd:372,
## artifact_runner.gd:206 and artifact_review_station.gd:520 all pass exactly
## {"emissive": false}, so three call sites were being ignored.
##
## Overriding the two parent factories rather than editing eight call sites means every
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

	# Retint BEFORE the early return: emissive changes no geometry, so it must not
	# trigger a rebuild, but it must still be applied. Skipping this was a silent
	# no-op on the three call sites that pass {"emissive": false}.
	_apply_emissive()

	if not _built:
		return   # _ready has not run yet; it will build with these values.

	if roster == before_roster:
		# `emissive` and `flip_period` need no geometry — emissive was just applied in
		# place above, and the next frame reads flip_period. Rebuilding for either is
		# the regression that broke curated placements.
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
	# The old materials die with the nodes; keeping them would retint freed objects.
	_emissive_mats.clear()
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
		_qmark = _billboard_label("?", Vector3(0.0, _verdict_y(), 0.0), qsize, contradiction_red)
		_add(_qmark)

	# --- billboard title ---
	# One column, one merge gap apart: the framer folds these two into a single
	# nameplate riding above the whole apparatus.
	_add(_billboard_label("BARBER PARADOX", Vector3(0.0, _title_y(), 0.0), 34, cool_white))
	_add(_billboard_label("shaves all who don't shave themselves", Vector3(0.0, _subtitle_y(), 0.0), 16, wire_purple))


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


## Where this roster's own geometry stops, so a caption plate knows what to clear.
func _body_top() -> float:
	return BODY_TOP_EXCEPTION if roster == "exception" else BODY_TOP


## The bin tags: the lowest caption row, one plate-half clear of the body and
## still standing in its own bin's column, so each tag reads over the bin it names.
func _tag_row_y() -> float:
	return _body_top() + CAPTION_GAP + HALF_TAG


## The subtitle. Deliberately far enough above the tag row that the framer does
## NOT merge the two — its merge gap is 0.16 m of text-to-text, and under
## `blanket`/`exception` a centre tag shares this column. A bin tag has no
## business inside the nameplate.
func _subtitle_y() -> float:
	return _tag_row_y() + HALF_TAG + CAPTION_GAP + HALF_SUB + 0.04


## The title, held close enough under the merge gap that the framer folds it and
## the subtitle into ONE nameplate rather than two stacked cards.
func _title_y() -> float:
	return _subtitle_y() + HALF_SUB + HALF_TITLE - 0.10


## The "?" crowns the stack. Its plate is by far the tallest here — a font-64
## glyph pulsed to 1.25x is ~0.60 m of panel, ~0.84 m at font 96 under `none` —
## so anywhere lower it either lands on the body or swallows the nameplate.
## Nameplate width is roster-invariant, so the four values still frame alike.
func _verdict_y() -> float:
	var q_half: float = HALF_Q_LOUD if roster == "none" else HALF_Q
	return _title_y() + HALF_TITLE + CAPTION_GAP + q_half


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
	# Tag above the bin — but on the caption row, not on the rim. Framed, a tag at
	# rim height is an opaque plate laid straight across the bins it names.
	_add(_billboard_label(label, Vector3(center.x, _tag_row_y(), center.z), 18, cool_white))


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
