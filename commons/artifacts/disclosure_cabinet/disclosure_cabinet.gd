# disclosure_cabinet.gd
# Disclosure Cabinet — one generator, five accounts of it.
#
# A synthesis artifact. Thirteen artifacts in this corpus carry the word
# `disclosure`; eleven of them run one ladder — oracle < tally < ledger < works <
# origin — and each asks it of a DIFFERENT machine, on a different organ, one rung
# at a time. This cabinet asks it once, of itself: a single seeded LCG draws
# forty-eight numbers, reports one figure, and the axis decides how much of that
# work the face is willing to carry.
#
# QFEP: what a system declines to say about itself is a design decision, not an
# absence — and the deployed condition is always the bottom rung.
#
# @identity
# essence: one seeded stream, one reported figure, and five different amounts of account behind it
# desire: stand in front of a machine at `oracle`, read a number that fills the whole face, and have no way at all to check it
# critical_parameter: disclosure — how much of its own working the cabinet admits (oracle | tally | ledger | works | origin); the FACE IS A FIXED RECTANGLE, so every account it adds is taken out of the answer's height
# triggers: none — the run is integrated once at build time; there is no _process and no interaction
# emerges: the more the machine discloses, the smaller its answer gets; at `oracle` the figure IS the object and at `origin` it is one line of five
# needs: nothing supplied — _ready builds standalone and the stream is deterministic from draw_seed
# relationships: synthesised from the `disclosure` family, whose ladder and rank table are read out of [[prng_crank_machine]] by preload rather than copied
# truth: An answer is not evidence. Every rung of this ladder computes the same number; only one of them lets you disagree with it.

extends Node3D

class_name DisclosureCabinet

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# ─────────────────────────────────────────────────────────────────────────────
# SYNTHESIS (2026-08-06) — born promoted, out of the `disclosure` family.
#
# WHAT THE FAMILY LEARNED, AND WHAT ONLY A SYNTHESIS CAN SAY. Eleven artifacts
# carry this ladder and every one of them can only be ONE rung at a time, which
# is exactly right for a machine in a room and leaves one finding permanently
# unsaid. Read the eleven notes side by side and the same sentence keeps being
# written by different agents in different words:
#
#   [[random_number_book_page_1955]]  "each of those costs space, and space on a
#   page is data" — the apparatus of record (folio, line numbers, running head,
#   imprint) is paid for out of the field of digits. Its `oracle` is the DENSEST
#   version of the page and the least usable one.
#
# That is the finding this cabinet is built out of, generalised past typography
# and made structural: THE FACE IS A FIXED RECTANGLE. It is full at every rung.
# What changes is who is standing in it. Each rung appends one account band at
# the bottom and every band above it gives up height, the answer most of all —
# 0.90 m of face at `oracle`, 0.16 m at `origin`. The figure is the same six
# characters in all five frames and it is drawn about four times smaller in the
# last one. An exhibit that discloses everything has almost no room left to
# announce anything, and an exhibit that announces is using the whole wall.
#
# Nobody in the family could show that, because showing it needs two rungs at
# once — or one rung whose LAYOUT is a consequence of the whole ladder.
#
# THE RUNGS, and each one is a member's own organ rebuilt at cabinet scale:
#
#   oracle  ONE LIT SHEET AND ONE FIGURE. 0.3958, drawn 0.70 m wide, with no
#           header naming it, no scale to read it against, no record to check it
#           in, no rule to derive it from and no seed to repeat it with. Seventy
#           per cent of the panel is lit, empty and saying nothing — that is the
#           rung, not a layout failure. [[prng_crank_machine]] calls this "the
#           API call, the slot machine, the RNG behind the loot box";
#           [[monte_carlo_dartboard]] calls it "an announcement";
#           [[random_number_book_page_1955]] "print's version of the API call";
#           [[hardware_entropy_decay]] "wear as a fact of nature";
#           [[bias_visualizer]] "the deployed condition, where the skew arrives
#           inside the output and the machine does not mention it". FIVE AGENTS
#           INDEPENDENTLY FOUND THE SAME THING: the bottom rung is what the world
#           actually ships, which is what makes this ladder political rather than
#           decorative. It is the most important frame in the strip and it is the
#           one this artifact spends the most ink on.
#   tally + THE SPREAD, and with it a RULER. Eight bins of the draw range over a
#           ruled baseline, an accent rule at the expected count, and a graduated
#           scale up the left edge. [[shannon_entropy_meter]]'s finding exactly:
#           its `oracle` "shows the reading and withholds the ruler — there is no
#           way to tell 2.997 from 3.997 without the log2(N) it is measured
#           against". The bins are 8 because [[prng_crank_machine]] says 8; the
#           number is read out of its DIST_BINS, not typed here.
#   ledger + THE RECORD. All forty-eight draws, in order, as two lanes of bars
#           with the half rule struck through them, each bar coloured by the
#           verdict that rule gave it. [[monte_carlo_dartboard]]'s step, which is
#           the sharpest sentence anyone in this family wrote: at this rung "the
#           ratio on the screen is now a claim you can falsify with your eyes".
#           The lanes also give up a left margin to an index rail, which is
#           [[random_number_book_page_1955]]'s line-number column taking its space
#           back — and here you can watch what it costs, because the bars get
#           narrower to pay for it.
#   works  + THE MECHANISM. state = (state x a + c) mod m, with a, c and m
#           printed. [[prng_crank_machine]]'s arithmetic pocket, and the family's
#           legacy rung on eight of eleven members.
#   origin + THE SUBSTRATE. SEED and STATE in hex, and thirty-two bit lamps, MSB
#           left, two rows of sixteen — the register [[prng_crank_machine]] and
#           [[env_one]] both built independently. AND the record is re-inked: each
#           bar keeps its verdict hue and takes its draw index as brightness, so
#           the two lanes stop being a picture of forty-eight numbers and become a
#           sequence walked in order across a wrap. That is
#           [[monte_carlo_dartboard]]'s `origin` finding — "the darts stop being
#           random and become entry 280 of a stream with an address" — and it is
#           the one place where a rung improves a band it already showed instead
#           of adding a new one.
#
# WHY THERE IS NO BLANK PLATE, and it is a deliberate departure from the family's
# own repaired idiom. [[prng_crank_machine]] and [[coin_toss]] cover a declined
# seat with a bolted plate standing 30 mm proud in the machine's own accent,
# because a flush dark patch could not be told from an unlit screen at capture
# resolution — "a closure that cannot be seen is not a closure". That repair is
# correct for a machine with fixed seats. This cabinet has no fixed seats: at
# `oracle` the answer does not leave a hole where the account would be, it ERASES
# the hole. Nothing on the face says a record was ever possible. That is the more
# common and the more dishonest deployed condition, and it is the whole reason
# the bottom rung of this ladder needed a word — a sealed seat at least admits
# there is something behind it.
#
# NOT TOUCHED BY THE AXIS, AND THIS IS THE FAMILY'S ONE NON-NEGOTIABLE: the
# stream. The same forty-eight draws come off the same LCG from the same seed in
# the same order at every rung, the same nineteen of them land at or above one
# half, and the same figure 0.3958 is printed at all five — including `oracle`.
# There is no rung at which this machine reports nothing, so this axis has no
# `none`, exactly as the family's other ten do not.
#
# THE FIGURE WAS NOT CHOSEN. draw_seed is 20260806, the promotion date, and 19/48
# is what it gave. It is a visibly poor estimate of one half, the eight bins are
# visibly lumpy (8 7 7 7 4 3 4 8 against an expected 6) and one side of the rule
# runs ten deep at one point. All of that is honest small-sample behaviour and
# all of it is invisible at `oracle`, where 0.3958 arrives with nothing beside
# it and you cannot tell a fair generator from a broken one from a sample too
# short to ask. Picking a prettier seed would have been this artifact's own
# subject matter, committed against itself.
# ─────────────────────────────────────────────────────────────────────────────

## The family's ladder and its ranks, defined once in the file that owns them.
## Preloaded rather than reached through class_name: the packaging family proved
## class_name lookups are not reliable headless, and every frame of the evidence
## loop is rendered headless. Nine artifacts already make this exact link.
const Disclosure = preload("res://algorithms/randomness/prng_crank_machine/prng_crank_machine.gd")

## THE AXIS — how much of its own working this cabinet admits. Same five rungs,
## same order, same spellings as prng_crank_machine, coin_toss, slot_machine,
## monte_carlo_dartboard, shannon_entropy_meter, hardware_entropy_decay, env_one,
## trng_vs_prng, bias_visualizer and the two book pages.
@export_enum("oracle", "tally", "ledger", "works", "origin") var disclosure: String = "origin"

## The export hint's five words, mirrored — and this const exists for ONE reason,
## which is not the reason its namesake exists on seven siblings. GDScript requires
## the @export_enum hint to be string literals, so a copy of the vocabulary is
## unavoidable in this file. It is therefore not trusted: _pick_disclosure tests
## membership against Disclosure.DISCLOSURE_RUNGS, the owner's table, and _ready
## CHECKS THIS COPY AGAINST THE OWNER'S LIST and raises if they have drifted. An
## unavoidable duplicate that reports its own divergence is the honest form of a
## shared vocabulary; a silent one is how `guard` became two word-lists.
const DISCLOSURES: PackedStringArray = ["oracle", "tally", "ledger", "works", "origin"]

## Rank of the current rung, 0..4. Every gate in this file is `_rung() >= n`, and
## the number of account bands on the face is exactly `_rung() + 1`.
##
## THE FALLBACK IS 4, NOT THE FAMILY'S 3. See the default note below: this cabinet
## ships fully disclosed, so an unreadable token must not quietly strip the seed,
## the rule and the record off a face somebody placed on purpose. bias_visualizer
## made the same departure for the same reason and said so on the record.
func _rung() -> int:
	return int(Disclosure.DISCLOSURE_RUNGS.get(disclosure, 4))


## Strip, lower, test against the OWNER'S table, fall back to what is already set.
func _pick_disclosure(raw: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	if Disclosure.DISCLOSURE_RUNGS.has(v):
		return v
	if v != "":
		push_warning("disclosure_cabinet: unknown rung '%s' — keeping '%s'" % [v, disclosure])
	return disclosure

# ── The stream ───────────────────────────────────────────────────────────────
## The seed. NOT an axis, for prng_crank_machine's stated reason: it changes
## digits, not form, and sweeping it would produce five tiles differing only in
## which numerals are painted on the same cabinet. It is read from map config
## through int(str(...)) rather than assigned raw, because a map token delivers a
## STRING and a typed int silently rejects it — the corpus's single most common
## unreachable-parameter fault, 371 placements deep.
@export var draw_seed: int = 20260806
## The LCG, Numerical Recipes' constants — the same recurrence prng_crank_machine
## cranks. TYPED HERE AND NOT PRELOADED, deliberately and on the record: prng
## exposes a, c and m as @export instance state rather than as a const table, so
## there is nothing static to read. The ladder, the bin count and the register
## width ARE read from it. If prng's exports are ever promoted to constants this
## should follow them.
const LCG_A: int = 1664525
const LCG_C: int = 1013904223
const LCG_M: int = 4294967296
## Forty-eight. Small enough that every draw is an individually legible bar in a
## 760 px still (24 to a lane at ~7 px wide), large enough that eight bins are a
## distribution rather than a list. This is the whole content of the number: the
## record has to AUDIT the tally, so the two must be accounts of one stream, and
## a stream long enough to look statistical is one whose ledger draws as a
## hairline. The brief's lesson, taken as a constraint.
const DRAWS: int = 48
## The rule the figure reports against. Half.
const RULE: float = 0.5

# ── Cabinet body (cabinet grammar, vertical dialect) ─────────────────────────
@export var body_width: float = 0.86
@export var body_height: float = 1.02
@export var body_depth: float = 0.28
## Built DOWNWARD from y=0 by HangarKit.plinth, so every authored coordinate
## stays put and auto-grounding supplies the lift.
@export var plinth_height: float = 0.34
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "DC-01"

## THE FACE. One fixed rectangle, full at every rung. This is the artifact.
const FACE_W: float = 0.78
const FACE_H: float = 0.90
const FACE_TOP: float = 0.98

## Band order down the face, and the rung each band arrives at. Band k is present
## when _rung() >= k, so the ladder is drawn top to bottom on the object itself.
const B_FIGURE: int = 0
const B_SPREAD: int = 1
const B_RECORD: int = 2
const B_RULEBAND: int = 3
const B_SEEDBAND: int = 4
const BAND_HEADERS: PackedStringArray = ["FIGURE", "SPREAD", "RECORD", "RULE", "SEED"]

## Band heights per rung, summing to FACE_H in every row. The table IS the
## argument — read down the FIGURE column: 0.90, 0.48, 0.30, 0.22, 0.16.
const BAND_HEIGHTS := {
	"oracle": [0.90],
	"tally": [0.48, 0.42],
	"ledger": [0.30, 0.26, 0.34],
	"works": [0.22, 0.20, 0.28, 0.20],
	"origin": [0.16, 0.16, 0.24, 0.16, 0.18],
}

## Drawn width of the figure per rung. It has to be listed rather than derived:
## six glyphs across a fixed width are WIDTH-limited by the font fitter, so a
## shorter band alone would not shrink them at all and the axis would move the
## apparatus while leaving the answer the same size — the exact opposite of what
## this cabinet claims. Ratio 0.70 : 0.17 is 4.1x, and the quad's height follows
## at 0.3694x width, which is where the fitter's width and height limits agree.
const FIGURE_W := [0.70, 0.48, 0.33, 0.24, 0.17]
const FIGURE_ASPECT: float = 0.3694

## Verdict colours — monte_carlo_dartboard's green-in / red-out, so a visitor who
## has met the dartboard reads this record without being told.
const VERDICT_OVER := Color(0.42, 0.88, 0.46)
const VERDICT_UNDER := Color(0.88, 0.34, 0.27)

# ── Palette, filled from the finish in _build_all ────────────────────────────
var color_body: Color = Color(0.14, 0.14, 0.155)
var color_accent: Color = Color(0.85, 0.30, 0.12)
var color_screen: Color = Color(0.05, 0.10, 0.06)
var color_text: Color = Color(0.45, 0.95, 0.50)
var color_dim: Color = Color(0.45, 0.45, 0.50)

# ── Internal ─────────────────────────────────────────────────────────────────
var _face_z: float = 0.14
var _cab: Node3D
## The top-level nodes THIS script added. A rebuild frees exactly these — a
## get_children() sweep would also destroy the grid's own label plates, packaging
## and tag markers, which other systems add after we build.
var _owned: Array[Node] = []
## True once _build_all has run. apply_grid_config arriving before this is a value
## change with no geometry to answer it; _ready will use the new value.
var _built: bool = false
## Material cache — 48 bars and 32 lamps must not mint 80 StandardMaterial3D.
var _mats: Dictionary = {}

## The run. Integrated once, at build time, and read by every band. The raw 32-bit
## draws are not kept: the record draws them normalised and the register shows the
## final state, so an integer array would be state nothing reads.
var _norm: Array[float] = []
var _over: int = 0
var _bins: Array[int] = []
var _final_state: int = 0


# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child, so the meta
	# read happens here, before any geometry exists. apply_grid_config arrives
	# call_deferred — after this — and is a re-read, not the read.
	_read_meta_overrides()
	_check_vocabulary()
	_build_all()
	_built = true


## The drift guard. The @export_enum hint above is five string literals the
## language will not let this file compute, so it cannot be preloaded; what it CAN
## do is check itself against the file that owns the vocabulary and say so loudly
## when they part. Nothing else in this family does this — the two orders already
## in the registry (seven artifacts declaring works-first, four ladder-first) are
## the harmless half of the same drift, and cube_lines and penrose_triangle are
## the other half.
func _check_vocabulary() -> void:
	var owned: PackedStringArray = Disclosure.DISCLOSURES
	if owned != DISCLOSURES:
		push_error("disclosure_cabinet: the ladder has drifted — prng_crank_machine holds %s, this file's export hint holds %s. Fix the hint, not the owner." % [str(owned), str(DISCLOSURES)])


## Everything, SYNCHRONOUSLY, so _auto_ground_artifact measures a real AABB in the
## same deferred pass. Reads `disclosure` and `draw_seed` and nothing else; there
## is no randf, randi or randomize anywhere in this file, so two calls with the
## same values build the same object down to the vertex.
func _build_all() -> void:
	_resolve_palette()
	_run_stream()
	_create_plinth()
	_create_shell()
	_create_face()


func _resolve_palette() -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	color_body = pal["body"]
	color_accent = pal["accent"]
	color_screen = pal["screen"]
	color_text = pal["text"]
	color_dim = pal["panel"].lightened(0.40)


## THE GENERATOR. One seeded LCG, run once. Every band on the face is a read of
## these four arrays; there is nothing on this cabinet that can disagree with
## anything else on it, because there is nothing else for it to agree with.
func _run_stream() -> void:
	_norm.clear()
	_bins.clear()
	var bins: int = int(Disclosure.DIST_BINS)
	for i in range(bins):
		_bins.append(0)
	var x: int = draw_seed & 0xFFFFFFFF
	_over = 0
	for i in range(DRAWS):
		x = (x * LCG_A + LCG_C) & 0xFFFFFFFF
		var u: float = float(x) / float(LCG_M)
		_norm.append(u)
		if u >= RULE:
			_over += 1
		var b: int = clampi(int(u * float(bins)), 0, bins - 1)
		_bins[b] = int(_bins[b]) + 1
	_final_state = x


## The figure. The same six characters at every rung — this is the invariant the
## whole family insists on: there is no rung at which the machine says nothing.
func _figure_text() -> String:
	return "%.4f" % (float(_over) / float(DRAWS))


# ═════════════════════════════════════════════════════════════════════════════
# BODY
# ═════════════════════════════════════════════════════════════════════════════

func _create_plinth() -> void:
	var p: Node3D = HangarKit.plinth(
		body_width + 0.06, body_depth + 0.10, plinth_height,
		finish, wear, color_accent, unit_code)
	if p:
		add_child(p)
		_owned.append(p)


## The shell. One body, flanks, a cap carrying the sign band baked flush into it,
## and the family's service marks low on the face — everything here is IDENTICAL
## at all five rungs, on purpose: every pixel the sweep measures should be a pixel
## the axis moved.
func _create_shell() -> void:
	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	add_child(cab)
	_owned.append(cab)
	_cab = cab
	_face_z = body_depth * 0.5

	var shell: StandardMaterial3D = HangarKit.finish_body(finish, color_body, wear)
	var steel: StandardMaterial3D = HangarKit.worn_metal(color_body.lightened(0.10))
	var panel: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.09, 0.09, 0.105), wear, 0.4, 0.5)
	var accent: StandardMaterial3D = HangarKit.emissive(color_accent, 2.2)

	cab.add_child(HangarKit.box(
		Vector3(0, body_height * 0.5, 0),
		Vector3(body_width, body_height, body_depth), shell))

	# side flanks, full height — the vertical dialect's shoulders
	for sx in [-1.0, 1.0]:
		cab.add_child(HangarKit.box(
			Vector3(float(sx) * (body_width * 0.5 + 0.018), body_height * 0.5, 0.0),
			Vector3(0.036, body_height, body_depth + 0.02), steel))

	# cap plate + the sign baked flush into it. The sign names the CABINET and
	# never the rung: a caption carrying the axis value would let a measurement of
	# the argument be padded by a measurement of the label.
	var cap_y: float = body_height + 0.028
	cab.add_child(HangarKit.box(
		Vector3(0, cap_y, 0), Vector3(body_width + 0.05, 0.056, body_depth + 0.03), steel))
	var sign: MeshInstance3D = HangarKit.stencil(
		"DISCLOSURE", Vector2(body_width * 0.62, 0.030), color_accent.lightened(0.35))
	if sign:
		sign.position = Vector3(0, cap_y, (body_depth + 0.03) * 0.5 + 0.003)
		cab.add_child(sign)

	# ember stripe under the cap lip
	cab.add_child(HangarKit.box(
		Vector3(0, body_height - 0.006, _face_z + 0.004),
		Vector3(body_width * 0.98, 0.007, 0.006), accent))

	# service marks in the low strip the face does not use (y 0 .. FACE bottom)
	for i in range(3):
		cab.add_child(HangarKit.box(
			Vector3(-body_width * 0.26, 0.026 + float(i) * 0.018, _face_z + 0.002),
			Vector3(body_width * 0.24, 0.008, 0.005), panel))
	var bar: Node3D = HangarKit.three_color_bar(body_width * 0.28, 0.012)
	if bar:
		bar.position = Vector3(body_width * 0.22, 0.042, _face_z + 0.005)
		cab.add_child(bar)
	var gb: MeshInstance3D = HangarKit.grime_band(
		body_width * 0.9, 0.05, _face_z + 0.003, color_body)
	if gb:
		gb.position.y = 0.022
		cab.add_child(gb)

	# bolted panel line down each flank. x is 0.418, which is 16 mm outside the
	# face rebate's edge at 0.402 and 12 mm inside the flank at 0.430 — the face
	# is a fixed rectangle and nothing is allowed to grow into it.
	for sx in [-1.0, 1.0]:
		cab.add_child(HangarKit.bolts(
			Vector3(float(sx) * (body_width * 0.5 - 0.012), 0.10, _face_z + 0.004),
			Vector3(float(sx) * (body_width * 0.5 - 0.012), body_height - 0.10, _face_z + 0.004),
			6, 0.0055, steel))

	# one collider for the whole cabinet — a body you can walk into, not 48 of them
	var col: StaticBody3D = HangarKit.box_collider(
		Vector3(body_width + 0.06, body_height, body_depth),
		Vector3(0, body_height * 0.5, 0))
	if col:
		cab.add_child(col)


# ═════════════════════════════════════════════════════════════════════════════
# THE FACE — a fixed rectangle, partitioned by the rung
# ═════════════════════════════════════════════════════════════════════════════

## Walk the band table top-down, seat each band, fill it. Band k exists when the
## rung has reached it, and every band above it has already given up the height.
func _create_face() -> void:
	var r: int = _rung()
	var heights: Array = BAND_HEIGHTS.get(disclosure, BAND_HEIGHTS["origin"])
	# The claim, asserted rather than trusted: the face is FULL at every rung, so
	# every row of the table must sum to FACE_H. A row that does not is an exhibit
	# quietly arguing something else — the account would be growing into empty
	# panel instead of being paid for out of the answer.
	var total: float = 0.0
	for hh in heights:
		total += float(hh)
	if absf(total - FACE_H) > 0.0005:
		push_error("disclosure_cabinet: band row '%s' sums to %.3f, not FACE_H %.3f" % [disclosure, total, FACE_H])
	var y: float = FACE_TOP
	for k in range(heights.size()):
		var bk: int = int(k)
		var h: float = float(heights[bk])
		var mid: float = y - h * 0.5
		_seat_band(bk, mid, h, r)
		match bk:
			B_FIGURE:
				_fill_figure(mid, h, r)
			B_SPREAD:
				_fill_spread(mid, h)
			B_RECORD:
				_fill_record(mid, h, r)
			B_RULEBAND:
				_fill_rule(mid, h)
			B_SEEDBAND:
				_fill_seed(mid, h)
		y -= h


## The pocket: a milled rebate, the lit face, an ember lip along the top edge that
## also separates this band from the one above, and — from `tally` up — a header
## stencil naming the part. At `oracle` there is NO header: the number arrives
## unlabelled, and the machine only begins naming its own organs once it has more
## than one.
func _seat_band(k: int, mid: float, h: float, r: int) -> void:
	var dark: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.07, 0.075, 0.09), wear, 0.35, 0.55)
	var accent: StandardMaterial3D = HangarKit.emissive(color_accent, 2.0)
	_cab.add_child(HangarKit.box(
		Vector3(0.0, mid, _face_z + 0.002),
		Vector3(FACE_W + 0.024, h + 0.008, 0.014), dark))
	_cab.add_child(HangarKit.box(
		Vector3(0.0, mid, _face_z + 0.008),
		Vector3(FACE_W, h - 0.004, 0.005),
		HangarKit.emissive(color_screen, 0.45)))
	_cab.add_child(HangarKit.box(
		Vector3(0.0, mid + h * 0.5 - 0.002, _face_z + 0.011),
		Vector3(FACE_W + 0.024, 0.004, 0.005), accent))
	if r >= 1:
		var tag: MeshInstance3D = HangarKit.stencil(
			BAND_HEADERS[k], Vector2(FACE_W * 0.22, 0.015),
			color_accent.lightened(0.30))
		if tag:
			tag.position = Vector3(
				-FACE_W * 0.36, mid + h * 0.5 - 0.016, _face_z + 0.014)
			_cab.add_child(tag)


## THE FIGURE. Same string, five sizes. Everything this cabinet argues is in the
## relationship between this function's width table and _create_face's height
## table: the answer is not a fixed headline that the apparatus grows around, it
## is the thing the apparatus is taken out of.
func _fill_figure(mid: float, h: float, r: int) -> void:
	var w: float = float(FIGURE_W[clampi(r, 0, 4)])
	var qh: float = minf(w * FIGURE_ASPECT, h - 0.030)
	# From `tally` up the band carries a header stencil in its top-left corner, so
	# the figure drops 10 mm to sit clear of it. At `oracle` there is no header and
	# the figure is dead centre in the whole face.
	var drop: float = 0.0
	if r >= 1:
		drop = 0.010
	var q: MeshInstance3D = BakedText.make_label_mesh(
		_figure_text(), color_text, Vector2(w, qh), 1400, true)
	if q:
		q.position = Vector3(0.0, mid - drop, _face_z + 0.016)
		_cab.add_child(q)


## THE SPREAD, and the RULER with it. Eight bins over a ruled baseline, an accent
## rule at the expected count, and a graduated scale up the left edge. The count
## is Disclosure.DIST_BINS — the family's number, read rather than typed.
func _fill_spread(mid: float, h: float) -> void:
	var bins: int = _bins.size()
	if bins <= 0:
		return
	var w: float = FACE_W * 0.86
	var top_pad: float = 0.022
	var area: float = h - top_pad - 0.020
	var base_y: float = mid - h * 0.5 + 0.016
	var slot: float = w / float(bins)
	var trough: StandardMaterial3D = _mat_flat(Color(0.06, 0.07, 0.06))
	var lit: StandardMaterial3D = _mat_lit(color_text, 1.9)
	var rail: StandardMaterial3D = _mat_lit(color_accent, 1.6)
	var tickm: StandardMaterial3D = _mat_lit(color_dim, 0.8)
	# the ruled baseline
	_cab.add_child(HangarKit.box(
		Vector3(0.0, base_y, _face_z + 0.014), Vector3(w + 0.020, 0.004, 0.004), rail))
	# the expected level — shannon_entropy_meter's ruler. Without it the bars are a
	# shape; with it they are a measurement, and the lumpiness becomes readable.
	var expected: float = float(DRAWS) / float(bins)
	var unit: float = area * 0.60 / expected
	_cab.add_child(HangarKit.box(
		Vector3(0.0, base_y + expected * unit, _face_z + 0.015),
		Vector3(w + 0.020, 0.003, 0.004), rail))
	# the graduated scale up the left edge. Three ticks, not four: a tick at the
	# full height of the shortest band this table can hand out would run into the
	# header stencil, and a scale that collides with its own label is not a scale.
	for t in range(1, 4):
		_cab.add_child(HangarKit.box(
			Vector3(-w * 0.5 - 0.018, base_y + area * 0.25 * float(t), _face_z + 0.014),
			Vector3(0.016, 0.003, 0.004), tickm))
	for i in range(bins):
		var cx: float = -w * 0.5 + slot * (float(i) + 0.5)
		_cab.add_child(HangarKit.box(
			Vector3(cx, base_y + area * 0.5, _face_z + 0.013),
			Vector3(slot * 0.70, area, 0.004), trough))
		var bh: float = maxf(0.005, minf(area, float(_bins[i]) * unit))
		_cab.add_child(HangarKit.box(
			Vector3(cx, base_y + bh * 0.5, _face_z + 0.016),
			Vector3(slot * 0.58, bh, 0.005), lit))


## THE RECORD. Forty-eight draws in order, two lanes of twenty-four, each bar as
## tall as its value with the half rule struck across it — so every bar can be
## checked against the boundary that judged it. The left margin is given to an
## index rail and the bars pay for it in width: random_number_book_page_1955's
## finding, where you can watch the apparatus cost the data its room.
##
## AT `origin` each bar additionally takes its draw index as brightness. The
## lanes stop being a picture of forty-eight numbers and become a sequence walked
## in order across a wrap — monte_carlo_dartboard's rung, exactly.
func _fill_record(mid: float, h: float, r: int) -> void:
	var margin: float = 0.062
	# 0.030, not 0.022: a bar at u ~ 0.99 rises the full lane, and at 0.022 the
	# tallest bar in this run touched the header stencil. The band is fixed, so
	# every clearance in it is arithmetic rather than taste.
	var top_pad: float = 0.030
	var lanes: int = 2
	var per_lane: int = DRAWS / lanes
	var gap: float = 0.014
	var lane_h: float = (h - top_pad - 0.016 - gap) / float(lanes)
	var area_w: float = FACE_W * 0.90 - margin
	var x0: float = -FACE_W * 0.45 + margin
	var pitch: float = area_w / float(per_lane)
	var rail: StandardMaterial3D = _mat_lit(color_accent, 1.5)
	var idx: StandardMaterial3D = _mat_lit(color_dim, 0.8)
	var top_y: float = mid + h * 0.5 - top_pad
	for ln in range(lanes):
		var base_y: float = top_y - lane_h * float(ln + 1) - gap * float(ln)
		# lane baseline and the half rule struck through it
		_cab.add_child(HangarKit.box(
			Vector3(x0 + area_w * 0.5, base_y, _face_z + 0.014),
			Vector3(area_w, 0.003, 0.004), rail))
		_cab.add_child(HangarKit.box(
			Vector3(x0 + area_w * 0.5, base_y + lane_h * RULE, _face_z + 0.015),
			Vector3(area_w, 0.003, 0.004), rail))
		# the index rail in the margin — the apparatus of record, drawn as a rail
		# and not as numerals because a numeral at this height is four pixels in
		# the evidence still, which is the documented way an axis reads as inert
		# when it is not.
		_cab.add_child(HangarKit.box(
			Vector3(x0 - margin * 0.45, base_y + lane_h * 0.5, _face_z + 0.014),
			Vector3(0.004, lane_h, 0.004), idx))
		for t in range(0, per_lane, 6):
			_cab.add_child(HangarKit.box(
				Vector3(x0 + pitch * (float(t) + 0.5), base_y - 0.007, _face_z + 0.014),
				Vector3(0.003, 0.010, 0.004), idx))
		for i in range(per_lane):
			var n: int = ln * per_lane + i
			var u: float = float(_norm[n])
			var bh: float = maxf(0.004, u * lane_h)
			var over: bool = u >= RULE
			var step: int = 7
			if r >= 4:
				step = clampi(int(float(n) / float(DRAWS) * 8.0), 0, 7)
			_cab.add_child(HangarKit.box(
				Vector3(x0 + pitch * (float(i) + 0.5), base_y + bh * 0.5, _face_z + 0.016),
				Vector3(pitch * 0.62, bh, 0.005), _mat_bar(over, step)))


## THE MECHANISM. prng_crank_machine's arithmetic, printed. The recurrence is the
## same one it cranks and the same one this file ran to fill the two bands above.
func _fill_rule(mid: float, h: float) -> void:
	var lines: Array = [
		"state = (state x a + c) mod m",
		"a = %d    c = %d    m = 2^32" % [LCG_A, LCG_C],
	]
	var lh: float = minf(0.030, (h - 0.034) * 0.42)
	var block: Node3D = BakedText.make_text_block(
		lines, color_dim, lh, FACE_W * 0.86, 0.008, true)
	if block:
		block.position = Vector3(0.0, mid - 0.010, _face_z + 0.016)
		_cab.add_child(block)


## THE SUBSTRATE. Seed and state in hex, then thirty-two bit lamps, MSB top-left,
## two rows of sixteen — the register prng_crank_machine and env_one each built
## for this rung. The widths are read from the owner (REGISTER_BITS, REGISTER_ROW)
## rather than typed, for the same reason the ladder is.
func _fill_seed(mid: float, h: float) -> void:
	var nbits: int = int(Disclosure.REGISTER_BITS)
	var per_row: int = int(Disclosure.REGISTER_ROW)
	var rows: int = int(ceil(float(nbits) / float(per_row)))
	var v: int = _final_state & 0xFFFFFFFF
	var hex: String = String.num_int64(v, 16).to_upper()
	while hex.length() < 8:
		hex = "0" + hex
	var line: MeshInstance3D = BakedText.make_label_mesh(
		"SEED %d    STATE 0x%s" % [draw_seed, hex], color_text,
		Vector2(FACE_W * 0.80, 0.022), 1400, true)
	if line:
		line.position = Vector3(0.0, mid + h * 0.5 - 0.040, _face_z + 0.016)
		_cab.add_child(line)
	var on_mat: StandardMaterial3D = _mat_lit(color_text, 2.6)
	var off_mat: StandardMaterial3D = _mat_flat(Color(0.05, 0.08, 0.05))
	var lamp_pitch: float = FACE_W * 0.84 / float(per_row)
	var lamp_w: float = lamp_pitch * 0.66
	# The two rows sit centred in what the SEED line leaves: content runs from
	# 0.029 below the band top to 0.146, whose midpoint is 0.087 against a band
	# half-height of 0.090.
	var row_pitch: float = 0.042
	var first_y: float = mid + h * 0.5 - 0.098
	for row in range(rows):
		for col in range(per_row):
			var i: int = row * per_row + col
			if i >= nbits:
				break
			var bit: int = nbits - 1 - i           # MSB at the top left
			var on: bool = ((v >> bit) & 1) == 1
			_cab.add_child(HangarKit.box(
				Vector3(-FACE_W * 0.42 + lamp_pitch * (float(col) + 0.5),
					first_y - row_pitch * float(row), _face_z + 0.016),
				Vector3(lamp_w, 0.011, 0.004),
				on_mat if on else off_mat))


# ═════════════════════════════════════════════════════════════════════════════
# MATERIALS — cached, because 48 bars and 32 lamps must not mint 80 of them
# ═════════════════════════════════════════════════════════════════════════════

func _mat_lit(c: Color, energy: float) -> StandardMaterial3D:
	var key: String = "lit|%.3f_%.3f_%.3f|%.2f" % [c.r, c.g, c.b, energy]
	if not _mats.has(key):
		_mats[key] = HangarKit.emissive(c, energy)
	return _mats[key] as StandardMaterial3D


func _mat_flat(c: Color) -> StandardMaterial3D:
	var key: String = "flat|%.3f_%.3f_%.3f" % [c.r, c.g, c.b]
	if not _mats.has(key):
		_mats[key] = HangarKit.painted_metal(c, wear, 0.20, 0.70)
	return _mats[key] as StandardMaterial3D


## One bar's material: the verdict hue, at one of eight brightness steps. At every
## rung below `origin` the step is fixed at 7 (full), so the record is a picture
## of forty-eight judged values; at `origin` the step carries the draw index and
## the same forty-eight bars become a sequence with an address.
func _mat_bar(over: bool, step: int) -> StandardMaterial3D:
	var s: int = clampi(step, 0, 7)
	var key: String = "bar|%s|%d" % ["o" if over else "u", s]
	if not _mats.has(key):
		var base: Color = VERDICT_OVER if over else VERDICT_UNDER
		var f: float = 0.26 + 0.74 * (float(s) / 7.0)
		_mats[key] = HangarKit.emissive(
			Color(base.r * f, base.g * f, base.b * f), 0.7 + 1.6 * f)
	return _mats[key] as StandardMaterial3D


# ═════════════════════════════════════════════════════════════════════════════
# CONFIG
# ═════════════════════════════════════════════════════════════════════════════

## Map tokens: "disclosure_cabinet#disclosure:oracle", "…#draw_seed:12345".
##
## THE EARLY RETURNS ARE LOAD-BEARING. curation_station calls
## apply_grid_config({"emissive": false}) on every artifact it curates, one line
## after _hide_labels() has darkened and unbillboarded everything — a dict naming
## nothing this file owns. An unconditional rebuild there would free every child
## and rebuild fresh, throwing away framing that is never re-applied. So an
## unchanged rung means touch nothing and say nothing.
func apply_grid_config(config: Dictionary) -> void:
	var before_disclosure: String = disclosure
	var before_seed: int = draw_seed

	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()

	if not _built:
		return                      # nothing built yet; _ready will use these values
	if disclosure == before_disclosure and draw_seed == before_seed:
		return                      # curation_station's {"emissive": false} lands here
	_rebuild_now()
	print("[DisclosureCabinet] Config applied — disclosure=%s seed=%d" % [disclosure, draw_seed])


## Tear down what this script built and build it again, INLINE. No call_deferred:
## a deferred rebuild leaves the node empty for a frame, and _auto_ground_artifact
## — later in the same deferred queue — would measure a zero AABB, return early,
## and leave the cabinet ungrounded.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)         # leaves the tree synchronously — no double-render
			c.queue_free()
	_owned.clear()
	_cab = null
	_mats.clear()
	_build_all()


func _read_meta_overrides() -> void:
	if has_meta("config_disclosure"):
		disclosure = _pick_disclosure(str(get_meta("config_disclosure")))
	if has_meta("config_draw_seed"):
		# int(str(...)) on purpose — a map token delivers a STRING and a typed int
		# would silently reject it, which is the corpus's most common unreachable
		# -parameter fault.
		var raw: String = str(get_meta("config_draw_seed")).strip_edges()
		if raw.is_valid_int():
			draw_seed = int(raw)
