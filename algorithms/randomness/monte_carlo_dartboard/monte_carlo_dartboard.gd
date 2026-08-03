# monte_carlo_dartboard.gd
# Monte Carlo Dart Board — throw darts to estimate π
# A square board with inscribed circle. Darts that land inside the circle
# vs total darts gives ratio ≈ π/4. Live counter shows π estimate improving.
#
# QFEP: Computation through accumulation — random sampling converges to truth.
#
# @identity
# essence: π ≈ 4 · (points inside circle / total points) — Monte Carlo integration
# desire: throw darts at a board and watch π emerge from chaos — green inside, red outside, gold answer
# critical_parameter: max_darts — more darts means tighter convergence; error scales as 1/sqrt(n); disclosure — how much of the sampling the cabinet lets you check the answer against (oracle | tally | ledger | works | origin)
# triggers: _throw_dart() samples uniform (rx, ry) in [0,1]², tests dx²+dy² <= 0.25
# emerges: the π estimate converges — randomness computes a transcendental number without algebra; at disclosure:oracle the same number arrives with the board wiped, and π stops being a measurement and becomes an announcement
# needs: VR push buttons for THROW/AUTO/RESET [has]; dart visual markers [has]
# relationships: contrasts with galton_board (integration vs distribution); feeds understanding of random sampling; shares the `disclosure` ladder word for word with [[prng_crank_machine]], [[coin_toss]], [[trng_vs_prng]] and [[hardware_entropy_decay]]
# truth: Randomness is not the enemy of precision — given enough samples, it converges to any truth.

extends Node3D

class_name MonteCarloDartboard

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# ─────────────────────────────────────────────────────────────────────────────
# DNA PROMOTION (2026-08-02) — disclosure
#
# ADOPTED, NOT INVENTED. The randomness registry already runs one ladder across
# five machines — prng_crank_machine (which owns the table), coin_toss,
# trng_vs_prng, hardware_entropy_decay, env_one — and this is the sixth. Same
# five words, same order, same spellings, same default. The rungs are read
# through prng_crank_machine's DISCLOSURE_RUNGS, not through a private copy,
# because the exhibits family shipped `guard` as two disjoint word-lists on two
# siblings and needed a whole convergence pass to reunite them.
#
#   disclosure    oracle  <  tally  <  ledger  <  works  <  origin
#
# WHY THIS QUESTION BELONGS ON THIS MACHINE. Monte Carlo is the one algorithm in
# the tier whose ANSWER and whose EVIDENCE are separable objects. The number
# 3.14 can be printed on a screen with nothing behind it, or it can be printed
# next to fourteen hundred dots you can count yourself. Nothing about the
# arithmetic changes; what changes is whether the visitor is a witness or an
# audience. That is the whole content of "randomness computes a truth" — you
# either watched it compute or you were told.
#
# WHAT THE RUNGS MEAN ON A DARTBOARD:
#
#   oracle  the aperture is a black square. No darts, no ring, no reference
#           disc, no corner axes, no formula band — and the census screen says
#           one line: PI ~ 3.141234. The machine still throws every dart and
#           still counts every hit; it simply does not show you one of them.
#           This is Monte Carlo as a verdict.
#   tally   + the aggregate. The darts come back as a field of PALE UNIFORM
#           marks — you can count them, you cannot tell which one scored — and
#           the screen returns darts / inside / outside / ratio. The numbers
#           claim a partition the picture does not show.
#   ledger  + the per-trial record. Every dart takes its own verdict colour
#           (green in, red out) and the inscribed circle is drawn, so each mark
#           can be checked against the boundary that judged it. This is the rung
#           where the picture becomes auditable: the ratio on the screen is now
#           a claim you can falsify with your eyes.
#   works   + the model. The filled reference disc, the (0,0)/(1,1) corner axes
#           and the two-line formula band — area(circle)/area(square) = π/4 —
#           plus actual π and the error on the screen. THE LEGACY LINEAGE,
#           byte for byte: this is the artifact exactly as it has always shipped.
#   origin  + the state that produced it, and this rung puts it on the BOARD,
#           not on a label: every mark keeps its verdict hue and takes its draw
#           index as brightness, so the first darts sit nearly black and the
#           newest blaze. The scatter stops being a cloud that was always there
#           and becomes a sequence being walked, in order, in front of you. A
#           SOURCE plate on the service column names the generator and its seed.
#           The darts stop being "random" and become entry 280 of a stream with
#           an address.
#
# THE ASYMMETRY, DECLARED. On the prng the tally→ledger step is a whole pocket
# appearing; on the coin it is a ribbon of letters; here it is COLOUR — 140
# pale marks become 140 green-and-red ones with a ring through them. Different
# organ, same step, and the three siblings never go quiet on the same rung.
#
# WHAT IS DELIBERATELY NOT THE AXIS. darts_per_second and max_darts are the
# tempting knobs and both are TIME: the sweep photographs at a fixed wall-clock
# moment ~0.5 s after the value is applied, so every rate renders as whatever
# the harness's clock caught. preseed_darts is invisible for the same reason at
# one remove. finish (rams | terminal) was the other candidate and it is a
# COLOUR, not a claim.
#
# NOT TOUCHED, AND NOT NEGOTIABLE: the estimate. rx, ry are drawn the same way,
# dx² + dy² <= 0.25 judges them the same way, _inside_count / _total_count is
# accumulated the same way and π is printed at every rung including oracle.
# There is no rung at which the machine reports nothing — an instrument that
# says nothing is not a quieter instrument, it is a broken one — so this axis
# has no `none`, exactly as the family's other five do not.
# ─────────────────────────────────────────────────────────────────────────────

## The family's ladder, defined once in prng_crank_machine. Preloaded (not the
## global class_name) because class_name lookups are not reliable headless and
## every frame of the evidence loop is rendered headless.
const Disclosure = preload("res://algorithms/randomness/prng_crank_machine/prng_crank_machine.gd")

## THE AXIS — how much of its own sampling this cabinet lets you check. Same five
## rungs, same order, same spellings as prng_crank_machine and coin_toss.
## `works` is the legacy default.
@export_enum("oracle", "tally", "ledger", "works", "origin") var disclosure: String = "works"

## The allow-list, in ladder order — the same five words the @export_enum above
## declares. This is what a map token (#disclosure:) is checked against.
const DISCLOSURES: PackedStringArray = ["oracle", "tally", "ledger", "works", "origin"]

## Rank of the current rung, 0..4, read through the family's one table. An
## unreadable word resolves to the legacy rung rather than to silence.
func _rung() -> int:
	return int(Disclosure.DISCLOSURE_RUNGS.get(Disclosure.disclosure_name(disclosure), 3))


## Neutral mark colour for `tally` — one pale dot per dart, countable and
## unjudged. Not a palette choice: it is the ABSENCE of the verdict colours.
const COLOR_UNJUDGED := Color(0.72, 0.74, 0.80)

## Housing finish — "rams" (light Braun default) or "terminal" (dark console).
## Every colour derives from HangarKit.finish_palette(), so one word re-skins
## the whole body instead of a dozen hand-typed constants.
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "MC-02"

## Pedestal height. These machines are authored at bench scale but ground
## base-to-floor, which left their keypads at knee height (G5-reach). The
## plinth hangs BELOW the origin, so every coordinate above stays as authored
## and auto-grounding lifts the whole assembly. Set 0.0 for a floor-standing
## build.
@export var plinth_height: float = 0.38


# ── Board ────────────────────────────────────────────────────────────────────
@export var board_size: float = 0.6
@export var board_thickness: float = 0.03
@export var board_height: float = 1.3  # Height off ground (eye level)

# ── Darts ────────────────────────────────────────────────────────────────────
@export var dart_radius: float = 0.005
@export var dart_length: float = 0.08
@export var max_darts: int = 500
@export var auto_throw: bool = true
@export var darts_per_second: float = 3.0
## How many darts are already on the board when the artifact appears. Enough that
## the ratio reads as a ratio, few enough that the estimate is still visibly rough
## and keeps tightening while you watch.
@export var preseed_darts: int = 140

# ── Determinism ──────────────────────────────────────────────────────────────
# 140 preseeded darts off the global randf() means two launches of the same room
# are two different dart fields — right in a room, and fatal to a measurement.
# An evidence sweep renders each value in its OWN Godot process, so five
# unseeded variants are five different scatters, and a critic comparing them
# reports the SCATTER as a confident bite belonging to the axis. Seeded, the
# five frames differ only where the rung differs.
#
# -1 = do not touch the stream, i.e. today exactly: randf() off the global
# generator, a fresh board every launch. Any value >= 0 builds a LOCAL generator
# and draws from that — never seed() on the global stream, because this cabinet
# shares a map with artifacts that draw too and re-seeding the process to pin
# one board would silently move every one of them.
@export var dart_seed: int = -1
var _rng: RandomNumberGenerator = null

# ── Colors ───────────────────────────────────────────────────────────────────
@export var color_board: Color = Color(0.15, 0.15, 0.18)
@export var color_circle: Color = Color(0.1, 0.15, 0.35)
@export var color_inside: Color = Color(0.2, 0.9, 0.3)   # Green — inside circle
@export var color_outside: Color = Color(0.9, 0.25, 0.2)  # Red — outside circle
@export var color_pi: Color = Color(1.0, 0.85, 0.2)       # Gold for π display

# ── Internal ─────────────────────────────────────────────────────────────────
var _inside_count: int = 0
var _seeding: bool = false   # suppress per-dart readout rebuilds while pre-seeding
var _total_count: int = 0
var _throw_timer: float = 0.0
var _dart_meshes: Array[MeshInstance3D] = []
# The last trial, for the `ledger` readout line. Written by _throw_dart from
# values it has already drawn — this adds no call to the RNG.
var _last_rx: float = 0.0
var _last_ry: float = 0.0
var _last_inside: bool = false

# Integrated 2D-in-3D readout — the estimate panel (π + darts + hits + error),
# consolidated onto ONE baked-text block that rebuilds only when its text changes.
var _readout_root: Node3D          # anchor holding the readout block (fixed position)
var _readout_block: Node3D         # the current make_text_block child (swapped on change)
var _readout_cache: String = ""    # last-rendered joined text — the rebuild cache guard
var _readout_color: Color = Color(0.85, 0.87, 0.95)
var _circle_mesh: MeshInstance3D

const _READOUT_LINE_H: float = 0.045
const _READOUT_WIDTH: float = 0.40
const _READOUT_GAP: float = 0.014
# live metrics (cabinet compacts these so the readout fits its column screen)
var _readout_line_h: float = _READOUT_LINE_H
var _readout_width: float = _READOUT_WIDTH



# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# APPENDED FIRST and draws nothing: _setup_seeded_stream() only constructs (or
	# clears) a generator. The first sample is taken in _preseed() at the bottom of
	# this list, so no draw above or below this line shifts on the default path.
	_setup_seeded_stream()
	_build_all()


## The build sequence, lifted verbatim out of _ready so apply_grid_config can run
## it again after a rung change. Order is unchanged and load-bearing:
## _create_cabinet() retires the floating title/formula blocks _create_labels()
## made and re-homes the readout into the column screen, and _preseed() must run
## after the screen exists or the first 140 darts have nowhere to report.
func _build_all() -> void:
	_create_board()
	_create_circle_overlay()
	_create_labels()
	_create_vr_controls()
	_create_cabinet()
	_preseed()


## Builds the local generator, or leaves it null. Null is the default and the
## room behaviour: _unit_draw() falls straight through to the global randf() this
## file has always used.
func _setup_seeded_stream() -> void:
	if dart_seed < 0:
		_rng = null
		return
	_rng = RandomNumberGenerator.new()
	_rng.seed = dart_seed


## One uniform draw. Identical to randf() unless seeded.
func _unit_draw() -> float:
	if _rng != null:
		return _rng.randf()
	return randf()


## ARRIVE WITH A SAMPLE ALREADY THROWN.
##
## The estimate needs a crowd to mean anything: pi is read off the RATIO of green
## darts to all darts, and a ratio of two darts is not a ratio. At 3 darts/second
## a visitor waited most of a minute before the board said anything, the readout sat
## at "pi = ?", and every still ever taken of this artifact — contact sheet, gallery,
## the book — showed an empty square. The algorithm was never wrong; it just had no
## opening state, so the thing you came to see was absent exactly when you arrived.
##
## Seeding is not faking: these are the same randf() draws _throw_dart() makes, run
## without waiting. Live throwing continues on top of them.
func _preseed() -> void:
	if preseed_darts <= 0:
		return
	_seeding = true
	for _i in range(mini(preseed_darts, max_darts)):
		_throw_dart()
	_seeding = false
	_update_display()


func _process(delta: float) -> void:
	if auto_throw and _total_count < max_darts:
		_throw_timer += delta
		var interval := 1.0 / darts_per_second
		while _throw_timer >= interval and _total_count < max_darts:
			_throw_timer -= interval
			_throw_dart()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				auto_throw = not auto_throw
			KEY_D:
				_throw_dart()
			KEY_R:
				_reset()


# ═════════════════════════════════════════════════════════════════════════════
# BOARD
# ═════════════════════════════════════════════════════════════════════════════

func _create_board() -> void:
	# Board backing — a square
	var body := StaticBody3D.new()
	body.name = "Board"

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(board_size, board_size, board_thickness)
	col.shape = shape
	body.add_child(col)

	# Board face mesh
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(board_size, board_size, board_thickness)
	mesh.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_board
	mat.metallic = 0.1
	mat.roughness = 0.8
	mesh.material_override = mat
	body.add_child(mesh)

	# Position: vertical, at board_height
	body.position = Vector3(0, board_height, 0)
	add_child(body)

	# Frame around the board
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.3, 0.25, 0.18)
	frame_mat.metallic = 0.3

	var frame_width := 0.015
	var sides := [
		[Vector3(0, board_size / 2.0 + frame_width / 2.0, 0), Vector3(board_size + frame_width * 2, frame_width, board_thickness + 0.005)],
		[Vector3(0, -(board_size / 2.0 + frame_width / 2.0), 0), Vector3(board_size + frame_width * 2, frame_width, board_thickness + 0.005)],
		[Vector3(board_size / 2.0 + frame_width / 2.0, 0, 0), Vector3(frame_width, board_size, board_thickness + 0.005)],
		[Vector3(-(board_size / 2.0 + frame_width / 2.0), 0, 0), Vector3(frame_width, board_size, board_thickness + 0.005)],
	]

	for s in sides:
		var frame := MeshInstance3D.new()
		var frame_box := BoxMesh.new()
		frame_box.size = s[1]
		frame.mesh = frame_box
		frame.material_override = frame_mat
		frame.position = s[0] + Vector3(0, board_height, 0)
		add_child(frame)

	# Corner axis tags: (0,0) → (1,1) coordinate display, as small integrated boards.
	# THE MODEL'S FRAME. These name the unit square the integral is taken over, so
	# they belong to `works` — below that rung there is no stated domain, only marks.
	if _rung() < 3:
		return
	var corner_z := board_thickness / 2.0 + 0.012
	var corner_positions := [
		[Vector3(-board_size / 2.0 - 0.045, board_height - board_size / 2.0, corner_z), "(0,0)"],
		[Vector3(board_size / 2.0 + 0.045, board_height + board_size / 2.0, corner_z), "(1,1)"],
	]
	for cp in corner_positions:
		var tag := BakedText.make_tag(
			cp[1], Color(0.6, 0.6, 0.68), 0.032,
			Color(0.08, 0.09, 0.11), true, Color(0.4, 0.6, 1.0))
		if tag:
			tag.position = cp[0]
			add_child(tag)


func _create_circle_overlay() -> void:
	# THE BOUNDARY THAT JUDGES. The ring is what makes a dart's colour checkable,
	# so it arrives with the per-trial record at `ledger`. Below that the marks are
	# on a blank square and the partition exists only as a number on the screen.
	if _rung() < 2:
		return

	# Draw the inscribed circle using ImmediateMesh (line loop)
	_circle_mesh = MeshInstance3D.new()
	_circle_mesh.name = "CircleOverlay"

	var imesh := ImmediateMesh.new()
	var segments := 64
	var radius := board_size / 2.0

	imesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(segments + 1):
		var angle := float(i) / float(segments) * TAU
		var x := cos(angle) * radius
		var y := sin(angle) * radius
		imesh.surface_add_vertex(Vector3(x, y, 0))
	imesh.surface_end()

	_circle_mesh.mesh = imesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.6, 1.0, 0.6)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# no_depth_test was ON, so the ring composited OVER the frame above the
	# board — a teal seam at the aperture top (off-family). Depth-test it so it
	# stays on the board face.
	mat.no_depth_test = false
	_circle_mesh.material_override = mat

	_circle_mesh.position = Vector3(0, board_height, board_thickness / 2.0 + 0.002)
	add_child(_circle_mesh)

	# Also draw a faint filled circle for reference.
	# THE MODEL'S AREA, shaded — the thing whose ratio to the square IS π/4. That is
	# the claim, not the record, so it waits for `works`.
	if _rung() < 3:
		return
	var fill := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.001
	disc.radial_segments = 48
	fill.mesh = disc
	fill.rotation_degrees.x = 90

	var fill_mat := StandardMaterial3D.new()
	fill_mat.albedo_color = Color(color_circle.r, color_circle.g, color_circle.b, 0.15)
	fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	fill.material_override = fill_mat

	fill.position = Vector3(0, board_height, board_thickness / 2.0 + 0.001)
	add_child(fill)


# ═════════════════════════════════════════════════════════════════════════════
# DART THROWING
# ═════════════════════════════════════════════════════════════════════════════

func _throw_dart() -> void:
	if _total_count >= max_darts:
		return

	# Random point in unit square [0,1] × [0,1], mapped to board.
	# _unit_draw() IS randf() whenever dart_seed is -1, which is every shipped
	# room: same two calls, same order, same count.
	var rx := _unit_draw()
	var ry := _unit_draw()

	# Check if inside inscribed circle (center 0.5, 0.5, radius 0.5)
	var dx := rx - 0.5
	var dy := ry - 0.5
	var inside := (dx * dx + dy * dy) <= 0.25  # radius^2 = 0.25

	_total_count += 1
	if inside:
		_inside_count += 1
	# The last trial, kept for the `ledger` line. Bookkeeping only — no draw.
	_last_rx = rx
	_last_ry = ry
	_last_inside = inside

	# THE MARKS. At `oracle` the machine throws, judges and counts exactly as
	# always and simply does not paint the evidence: no marker is built, the
	# aperture stays a black square, and π still appears on the screen. Every
	# statistic above this line has already been accumulated.
	if _rung() < 1:
		if not _seeding:
			_update_display()
		return

	# Map to board coordinates
	var board_x := (rx - 0.5) * board_size
	var board_y := (ry - 0.5) * board_size
	var dart_z := board_thickness / 2.0 + 0.003

	# Create dart marker (small sphere)
	var marker := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = dart_radius
	sphere.height = dart_radius * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	marker.mesh = sphere

	var mat := StandardMaterial3D.new()
	# THE VERDICT, or its absence. At `tally` every mark is the same pale colour:
	# the field is countable and unjudged, which is exactly what "aggregate without
	# account" looks like when the aggregate is a partition. From `ledger` up each
	# dart wears the verdict that produced the number — the legacy line, unchanged.
	mat.albedo_color = COLOR_UNJUDGED if _rung() < 2 else (color_inside if inside else color_outside)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# ORIGIN — the stream's ORDER, written on the board. Hue still carries the
	# verdict (in/out is not taken away), and brightness now carries the draw
	# index: the first darts sit dark and the newest blaze, so the scatter reads
	# as a SEQUENCE being walked rather than a cloud that was always there. This
	# is the rung's real evidence; the SOURCE plate on the column only names what
	# the board is already showing. Nothing here touches rx, ry or the verdict.
	if _rung() >= 4:
		var age: float = clampf(float(_total_count) / float(maxi(preseed_darts, 1)), 0.0, 1.0)
		mat.albedo_color = mat.albedo_color.darkened(0.62 * (1.0 - age))
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = lerpf(0.10, 1.30, age)

	marker.material_override = mat

	marker.position = Vector3(board_x, board_height + board_y, dart_z)
	add_child(marker)
	_dart_meshes.append(marker)

	# Recycle oldest darts if over visual limit
	if _dart_meshes.size() > 300:
		var old: MeshInstance3D = _dart_meshes.pop_front() as MeshInstance3D
		if old:
			old.queue_free()

	if not _seeding:
		_update_display()


# ═════════════════════════════════════════════════════════════════════════════
# DISPLAY
# ═════════════════════════════════════════════════════════════════════════════

func _create_labels() -> void:
	var label_z := board_thickness / 2.0 + 0.012

	# ── TITLE — one integrated board above the dartboard (title + subtitle lines).
	var title_block := BakedText.make_text_block(
		["MONTE CARLO", "Estimating π with random darts"],
		Color(0.9, 0.9, 0.95), 0.05, board_size + 0.1, 0.012, true)
	if title_block:
		title_block.name = "TitleBlock"
		title_block.position = Vector3(0, board_height + board_size / 2.0 + 0.09, label_z)
		add_child(title_block)

	# ── READOUT — the converging estimate, consolidated onto ONE panel to the right.
	# An opaque plate behind the block gives it a clean "instrument screen" read; the
	# text block itself is swapped in _update_display() only when its lines change.
	_readout_root = Node3D.new()
	_readout_root.name = "ReadoutPanel"
	_readout_root.position = Vector3(board_size / 2.0 + 0.34, board_height, label_z)
	add_child(_readout_root)

	# A MILLED POCKET behind the plate. Without it this readout is a plate taped to
	# the body — the one thing G6 exists to catch, and it was catching it here: the
	# family's only standing advisory was this panel, correctly flagged.
	var recess: MeshInstance3D = HangarKit.box(
		Vector3(0, 0, -0.014),
		Vector3(_READOUT_WIDTH + 0.088, 0.468, 0.014),
		HangarKit.painted_metal(Color(0.07, 0.075, 0.09), wear, 0.35, 0.55))
	if recess:
		recess.name = "ReadoutPocket"
		_readout_root.add_child(recess)

	var plate := BakedText.make_panel_mesh(
		"", Color(0.06, 0.07, 0.10), Color.WHITE,
		Vector2(_READOUT_WIDTH + 0.06, 0.44), 1400, false)
	if plate:
		plate.name = "ReadoutPlate"
		plate.position = Vector3(0, 0, -0.006)
		_readout_root.add_child(plate)

	_rebuild_readout(["π ≈ ?", "", "darts: 0", "inside: 0", "outside: 0"])

	# ── FORMULA — one integrated board below the dartboard.
	var formula_block := BakedText.make_text_block(
		["π/4 = area(circle) / area(square)",
		 "π ≈ 4 × (inside / total)"],
		Color(0.6, 0.6, 0.68), 0.04, board_size + 0.14, 0.012, true)
	if formula_block:
		formula_block.name = "FormulaBlock"
		formula_block.position = Vector3(0, board_height - board_size / 2.0 - 0.1, label_z)
		add_child(formula_block)


# Swap the readout text block for a fresh one holding `lines`. Called only when the
# joined text differs from the cache (guarded by the caller), so no per-frame churn.
func _rebuild_readout(lines: Array) -> void:
	if _readout_block and is_instance_valid(_readout_block):
		_readout_block.queue_free()
	_readout_block = BakedText.make_text_block(
		lines, _readout_color, _readout_line_h, _readout_width, _READOUT_GAP, true)
	if _readout_block:
		_readout_block.position = Vector3(0, 0, 0.002)
		_readout_root.add_child(_readout_block)


## THE CENSUS, by rung. The ladder is monotone: every rung prints everything the
## rung below prints and adds one more kind of account. π itself is on every rung
## including `oracle` — see the header: no rung reports nothing.
##
## `works` returns the nine legacy lines in the legacy order with the legacy
## format strings, so the shipped placements render character for character what
## they rendered before this axis existed.
func _readout_lines(pi_estimate: float, error: float, error_pct: float) -> Array:
	var rung: int = _rung()

	# oracle — the answer, and nothing to check it with.
	var lines: Array = ["π ≈ %.6f" % pi_estimate]
	if rung < 1:
		return lines

	# tally — the aggregate.
	lines.append("")
	lines.append("darts: %d" % _total_count)
	lines.append("inside: %d" % _inside_count)
	lines.append("outside: %d" % (_total_count - _inside_count))
	lines.append("ratio: %.4f" % (float(_inside_count) / float(_total_count)))
	if rung < 2:
		return lines

	# ledger — the per-trial record. The board carries the whole of it in colour;
	# the screen carries the newest row, the one entry whose coordinates you could
	# still walk over and verify against the ring.
	if rung == 2:
		lines.append("")
		lines.append("last: (%.3f, %.3f)" % [_last_rx, _last_ry])
		lines.append("      %s" % ("IN" if _last_inside else "OUT"))
		return lines

	# works — the model's claim about the tally. THE LEGACY LINEAGE, byte for byte.
	lines.append("")
	lines.append("actual π: %.6f" % PI)
	lines.append("error: %.6f (%.2f%%)" % [error, error_pct])
	if rung < 4:
		return lines

	# origin — the state that produced it. The estimate acquires an address.
	lines.append("")
	lines.append("source: %s" % ("prng seed" if dart_seed >= 0 else "engine rng"))
	lines.append("seed: %s" % (str(dart_seed) if dart_seed >= 0 else "unpinned"))
	lines.append("draw: %d" % (_total_count * 2))
	return lines


func _update_display() -> void:
	if _total_count == 0:
		return

	var pi_estimate: float = 4.0 * float(_inside_count) / float(_total_count)
	var error: float = absf(pi_estimate - PI)
	var error_pct: float = error / PI * 100.0

	# Every readout string, consolidated onto one panel — as much of it as the
	# rung admits. `works` returns the legacy nine lines verbatim.
	var lines := _readout_lines(pi_estimate, error, error_pct)

	# Color the whole readout by accuracy — green excellent, gold good, orange far.
	if error_pct < 1.0:
		_readout_color = Color(0.4, 1.0, 0.45)
	elif error_pct < 5.0:
		_readout_color = color_pi
	else:
		_readout_color = Color(1.0, 0.6, 0.35)

	# Cache guard: rebuild the baked block only when its text (or colour) changed.
	var joined := "%s|%s" % [_readout_color, "\n".join(PackedStringArray(lines))]
	if joined == _readout_cache:
		return
	_readout_cache = joined
	_rebuild_readout(lines)


# ═════════════════════════════════════════════════════════════════════════════
# VR CONTROLS
# ═════════════════════════════════════════════════════════════════════════════

## THE CABINET — the 2026-07-20 interface ruling propagated (2nd artifact):
## the dartboard becomes ONE appliance, vending-machine grammar. The board
## is the poster window; the pi census lives on an inset column screen; the
## THROW/AUTO/RESET pad seats on a wedge; sign band in the cap; maroon
## flank; vent grille; plinth on feet. The free-floating title, formula and
## readout plates are retired — every interface element is a face of the
## same volume.
func _create_cabinet() -> void:
	var half: float = board_size / 2.0
	var bd: float = board_thickness
	var cw: float = 0.27
	var colx: float = half + cw / 2.0
	var face_z: float = 0.09
	var win_bot: float = board_height - half
	var win_top: float = board_height + half
	var total_w: float = board_size + cw + 0.10
	var cx: float = (half + cw) - (total_w / 2.0)
	var cap_h: float = 0.12
	var body_top: float = win_top + 0.06

	var cab := Node3D.new()
	cab.name = "Cabinet"
	add_child(cab)

	# ── One palette word drives every part (kit finish system) ──────────
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_panel: Color = pal["panel"]
	var col_accent: Color = pal["accent"]
	var ew: float = float(pal["wear"]) if finish.to_lower() == "terminal" else wear
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, ew)
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), ew, 0.4, 0.5)
	var maroon: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.11, 0.09), ew)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_panel)
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.04, 0.05, 0.08)
	glass_mat.roughness = 0.15
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.05, 0.08, 0.12)
	glass_mat.emission_energy_multiplier = 0.6
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	# back slab — full height
	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(total_w, body_top, 0.05)
	back.mesh = back_mesh
	back.material_override = shell
	back.position = Vector3(cx, body_top / 2.0, -bd / 2.0 - 0.035)
	cab.add_child(back)

	# maroon flank (left, full height)
	var flank := MeshInstance3D.new()
	var flank_mesh := BoxMesh.new()
	flank_mesh.size = Vector3(0.10, body_top, 0.16)
	flank.mesh = flank_mesh
	flank.material_override = maroon
	flank.position = Vector3(-half - 0.05, body_top / 2.0, -0.005)
	cab.add_child(flank)

	# front shell panels around the window (below + above, window width)
	var below := MeshInstance3D.new()
	var below_mesh := BoxMesh.new()
	below_mesh.size = Vector3(board_size, win_bot, 0.05)
	below.mesh = below_mesh
	below.material_override = shell
	below.position = Vector3(0.0, win_bot / 2.0, bd / 2.0 - 0.010)
	cab.add_child(below)
	var above := MeshInstance3D.new()
	var above_mesh := BoxMesh.new()
	above_mesh.size = Vector3(board_size, body_top - win_top, 0.05)
	above.mesh = above_mesh
	above.material_override = shell
	above.position = Vector3(0.0, (win_top + body_top) / 2.0, bd / 2.0 - 0.010)
	cab.add_child(above)

	# FORMULA — signage in the below-window panel (was a floating block).
	# THE MECHANISM STATED. This band is the model's own account of why the ratio
	# is π/4 at all, so it is the `works` rung's signature and is absent below it:
	# at `ledger` you can audit every dart and still not be told what the count is
	# supposed to mean.
	if _rung() >= 3:
		var f_band := MeshInstance3D.new()
		var f_band_mesh := BoxMesh.new()
		f_band_mesh.size = Vector3(board_size - 0.06, 0.11, 0.012)
		f_band.mesh = f_band_mesh
		f_band.material_override = dark
		f_band.position = Vector3(0.0, win_bot - 0.12, bd / 2.0 + 0.012)
		cab.add_child(f_band)
		var f1: Node3D = BakedText.make_tag(
			"PI/4 = AREA(CIRCLE) / AREA(SQUARE)", Color(0.62, 0.64, 0.72), 0.020,
			Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
		if f1:
			f1.position = Vector3(0.0, win_bot - 0.095, bd / 2.0 + 0.020)
			cab.add_child(f1)
		var f2: Node3D = BakedText.make_tag(
			"PI ~ 4 x (INSIDE / TOTAL)", Color(0.85, 0.75, 0.35), 0.024,
			Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
		if f2:
			f2.position = Vector3(0.0, win_bot - 0.140, bd / 2.0 + 0.020)
			cab.add_child(f2)

	# right service column
	var col := MeshInstance3D.new()
	var col_mesh := BoxMesh.new()
	col_mesh.size = Vector3(cw, body_top, 0.16)
	col.mesh = col_mesh
	col.material_override = shell
	col.position = Vector3(colx, body_top / 2.0, -0.005)
	cab.add_child(col)

	# inset PI screen (upper column) — the readout re-homes here
	var scr_w: float = cw - 0.05
	var scr_h: float = 0.46
	var scr_y: float = board_height + 0.10
	var pocket := MeshInstance3D.new()
	var pocket_mesh := BoxMesh.new()
	pocket_mesh.size = Vector3(scr_w + 0.02, scr_h + 0.05, 0.015)
	pocket.mesh = pocket_mesh
	pocket.material_override = dark
	pocket.position = Vector3(colx, scr_y, face_z + 0.002)
	cab.add_child(pocket)
	var glass := MeshInstance3D.new()
	var glass_mesh := BoxMesh.new()
	glass_mesh.size = Vector3(scr_w, scr_h, 0.006)
	glass.mesh = glass_mesh
	glass.material_override = glass_mat
	glass.position = Vector3(colx, scr_y - 0.008, face_z + 0.010)
	cab.add_child(glass)
	var head_tag: Node3D = BakedText.make_tag(
		"PI CENSUS", Color(0.92, 0.93, 0.97), 0.020,
		Color(0.055, 0.06, 0.075), true, Color(0.86, 0.30, 0.10))
	if head_tag:
		head_tag.position = Vector3(colx, scr_y + scr_h / 2.0 + 0.014, face_z + 0.014)
		cab.add_child(head_tag)
	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(scr_w + 0.02, 0.005, 0.004)
	stripe.mesh = stripe_mesh
	stripe.material_override = accent
	stripe.position = Vector3(colx, scr_y + scr_h / 2.0 - 0.002, face_z + 0.012)
	cab.add_child(stripe)

	# retire the floats; re-home the live readout INTO the screen
	var tb: Node = get_node_or_null("TitleBlock")
	if tb != null:
		tb.queue_free()
	var fb: Node = get_node_or_null("FormulaBlock")
	if fb != null:
		fb.queue_free()
	if _readout_root != null and is_instance_valid(_readout_root):
		var old_plate: Node = _readout_root.get_node_or_null("ReadoutPlate")
		if old_plate != null:
			old_plate.queue_free()
		_readout_root.position = Vector3(colx, scr_y - 0.01, face_z + 0.014)
		_readout_line_h = 0.026
		_readout_width = scr_w - 0.02
		_readout_cache = ""
		_rebuild_readout(["PI ~ ?", "", "darts: 0", "inside: 0", "outside: 0"])

	# keypad wedge + (pad repositioned in _create_vr_controls)
	var wedge := _make_wedge(cw - 0.03, 0.16, 0.062, 0.018, dark)
	wedge.position = Vector3(colx, 0.62, face_z - 0.045)
	cab.add_child(wedge)

	# vent grille (lower column)
	for gi in range(7):
		var slat := MeshInstance3D.new()
		var slat_mesh := BoxMesh.new()
		slat_mesh.size = Vector3(cw - 0.06, 0.010, 0.012)
		slat.mesh = slat_mesh
		slat.material_override = dark
		slat.position = Vector3(colx, 0.18 + float(gi) * 0.024, face_z + 0.002)
		cab.add_child(slat)

	# header cap with the integrated sign band
	var cap := MeshInstance3D.new()
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(total_w, cap_h, 0.20)
	cap.mesh = cap_mesh
	cap.material_override = shell
	cap.position = Vector3(cx, body_top + cap_h / 2.0, -0.005)
	cab.add_child(cap)
	var cap_stripe := MeshInstance3D.new()
	var cap_stripe_mesh := BoxMesh.new()
	cap_stripe_mesh.size = Vector3(total_w, 0.006, 0.004)
	cap_stripe.mesh = cap_stripe_mesh
	cap_stripe.material_override = accent
	cap_stripe.position = Vector3(cx, body_top + 0.004, 0.093)
	cab.add_child(cap_stripe)
	var sign := MeshInstance3D.new()
	var sign_mesh := BoxMesh.new()
	sign_mesh.size = Vector3(total_w - 0.08, 0.078, 0.012)
	sign.mesh = sign_mesh
	sign.material_override = dark
	sign.position = Vector3(cx, body_top + cap_h / 2.0, 0.096)
	cab.add_child(sign)
	var sign_title: Node3D = BakedText.make_tag(
		"MONTE CARLO", Color(0.93, 0.94, 0.97), 0.032,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_title:
		sign_title.position = Vector3(cx, body_top + cap_h / 2.0 + 0.014, 0.104)
		cab.add_child(sign_title)
	var sign_sub: Node3D = BakedText.make_tag(
		"ESTIMATING PI WITH RANDOM DARTS", Color(0.55, 0.58, 0.66), 0.015,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_sub:
		sign_sub.position = Vector3(cx, body_top + cap_h / 2.0 - 0.020, 0.104)
		cab.add_child(sign_sub)

	# plinth + feet
	var plinth := MeshInstance3D.new()
	var plinth_mesh := BoxMesh.new()
	plinth_mesh.size = Vector3(total_w, 0.10, 0.24)
	plinth.mesh = plinth_mesh
	plinth.material_override = dark
	plinth.position = Vector3(cx, 0.05, 0.0)
	cab.add_child(plinth)
	for fx in [-total_w / 2.0 + 0.08, total_w / 2.0 - 0.08]:
		var foot := MeshInstance3D.new()
		var foot_mesh := BoxMesh.new()
		foot_mesh.size = Vector3(0.10, 0.035, 0.20)
		foot.mesh = foot_mesh
		foot.material_override = dark
		foot.position = Vector3(cx + fx, 0.017, 0.0)
		cab.add_child(foot)


## Right-triangle prism shoulder (shared cabinet grammar — see galton_board).

	# ── Kit details: the manufactured read the station props carry ──────
	cab.add_child(HangarKit.bolts(
		Vector3(colx + cw / 2.0 - 0.02, 0.14, face_z - 0.004),
		Vector3(colx + cw / 2.0 - 0.02, body_top - 0.10, face_z - 0.004),
		7, 0.009, steel))
	var bar: Node3D = HangarKit.three_color_bar(cw - 0.06, 0.016)
	if bar:
		bar.position = Vector3(colx, win_bot + 0.10, face_z + 0.004)
		cab.add_child(bar)
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.12, 0.030),
		col_accent.lightened(0.25))
	if code:
		code.position = Vector3(-half + 0.10, 0.155, bd / 2.0 + 0.056)
		cab.add_child(code)
	var gb: MeshInstance3D = HangarKit.grime_band(total_w * 0.9, 0.055,
		bd / 2.0 + 0.058, col_body)
	if gb:
		gb.position.x = cx                  # keep the kit's baked z
		cab.add_child(gb)

	# ── Pedestal: raise the controls into the VR reach band ─────────────
	var ped: Node3D = HangarKit.plinth(total_w, bd + 0.18, plinth_height, finish, ew,
		col_accent, unit_code)
	if ped:
		cab.add_child(ped)

	# ── ORIGIN, appended LAST so every child index and position above is
	# untouched at every other rung. `works` falls through and adds nothing.
	if _rung() >= 4:
		_disclosure_origin_plate(cab, colx, win_bot, face_z, dark, accent)


## ORIGIN — the source plate. A small dark plate low on the service column,
## under the vent, naming the stream the darts came out of: which generator, what
## seed, how many draws have been taken. Nothing about the estimate changes; what
## changes is that the estimate now has a provenance, and "random" stops being a
## property of the darts and becomes a property of a machine somebody configured.
##
## Built from the same kit parts as the rest of the cabinet (dark plate, accent
## hairline, baked tags) so the rung reads as a FACE OF THE VOLUME and not as a
## label taped on — the cabinet-grammar rule the readout pocket exists to honour.
func _disclosure_origin_plate(cab: Node3D, colx: float, win_bot: float,
		face_z: float, dark: Material, accent: Material) -> void:
	var plate_y: float = win_bot - 0.14
	var plate := MeshInstance3D.new()
	var plate_mesh := BoxMesh.new()
	plate_mesh.size = Vector3(0.22, 0.115, 0.014)
	plate.mesh = plate_mesh
	plate.material_override = dark
	plate.position = Vector3(colx, plate_y, face_z + 0.004)
	cab.add_child(plate)

	var hair := MeshInstance3D.new()
	var hair_mesh := BoxMesh.new()
	hair_mesh.size = Vector3(0.22, 0.004, 0.004)
	hair.mesh = hair_mesh
	hair.material_override = accent
	hair.position = Vector3(colx, plate_y + 0.055, face_z + 0.012)
	cab.add_child(hair)

	var head: Node3D = BakedText.make_tag(
		"SOURCE", Color(0.90, 0.92, 0.97), 0.017,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if head:
		head.position = Vector3(colx, plate_y + 0.036, face_z + 0.014)
		cab.add_child(head)

	# Static claims only. This plate is built inside _create_cabinet, which runs
	# BEFORE _preseed, so a live draw counter here would bake the string "0" and
	# stay there — the count lives on the census screen, which rebuilds. What
	# belongs on the plate is what does not move: the generator and its domain.
	var origin_lines: Array = [
		"PRNG SEED" if dart_seed >= 0 else "ENGINE RNG",
		("SEED %d" % dart_seed) if dart_seed >= 0 else "SEED UNPINNED",
		"UNIFORM [0,1]",
	]
	for i in range(origin_lines.size()):
		var row: Node3D = BakedText.make_tag(
			str(origin_lines[i]), Color(0.72, 0.68, 0.42), 0.015,
			Color(0.06, 0.065, 0.08), false, Color(0, 0, 0, 0))
		if row:
			row.position = Vector3(colx, plate_y + 0.010 - float(i) * 0.022, face_z + 0.014)
			cab.add_child(row)

func _make_wedge(w: float, h: float, d_bottom: float, d_top: float, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0: float = -w / 2.0
	var x1: float = w / 2.0
	var y0: float = -h / 2.0
	var y1: float = h / 2.0
	var bbl := Vector3(x0, y0, 0.0)
	var bbr := Vector3(x1, y0, 0.0)
	var btl := Vector3(x0, y1, 0.0)
	var btr := Vector3(x1, y1, 0.0)
	var fbl := Vector3(x0, y0, d_bottom)
	var fbr := Vector3(x1, y0, d_bottom)
	var ftl := Vector3(x0, y1, d_top)
	var ftr := Vector3(x1, y1, d_top)
	var faces := [
		[fbl, fbr, ftr, ftl],
		[bbr, bbl, btl, btr],
		[bbl, fbl, ftl, btl],
		[fbr, bbr, btr, ftr],
		[btl, ftl, ftr, btr],
		[bbl, bbr, fbr, fbl],
	]
	for f in faces:
		st.add_vertex(f[0]); st.add_vertex(f[1]); st.add_vertex(f[2])
		st.add_vertex(f[0]); st.add_vertex(f[2]); st.add_vertex(f[3])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("", [
		[
			{"type": "button", "label": "THROW"},
			{"type": "button", "label": "AUTO"},
			{"type": "button", "label": "RESET"},
		],
	])
	# seated on the service column's wedge (all-in-one cabinet)
	panel.position = Vector3(board_size / 2.0 + 0.135, 0.62, 0.105)
	panel.rotation_degrees = Vector3(-15, 0, 0)
	panel.scale = Vector3(0.72, 0.72, 0.72)
	add_child(panel)

	# THROW button (Btn_0)
	var throw_btn: Node = panel.find_child("Btn_0", true, false)
	if throw_btn:
		var area = throw_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _throw_dart())

	# AUTO button (Btn_1)
	var auto_btn: Node = panel.find_child("Btn_1", true, false)
	if auto_btn:
		var area = auto_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): auto_throw = not auto_throw)

	# RESET button (Btn_2)
	var reset_btn: Node = panel.find_child("Btn_2", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _reset())


func _reset() -> void:
	_inside_count = 0
	_total_count = 0
	_throw_timer = 0.0

	for m in _dart_meshes:
		if is_instance_valid(m):
			m.queue_free()
	_dart_meshes.clear()

	_readout_color = Color(0.85, 0.87, 0.95)
	_readout_cache = ""
	_rebuild_readout(["π ≈ ?", "", "darts: 0", "inside: 0", "outside: 0"])

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## LATENT BUG PAID (2026-08-02): this was `pass`. Every `#token: value` a map put
## on a monte_carlo_dartboard placement was parsed, logged by
## GridInteractablesComponent, stashed as metadata — and then silently discarded,
## because nothing on this artifact ever read it back. A declared axis with a
## `pass` here is a declaration that lies, and the capture harness applies DNA
## through exactly this method (commons/testing/capture_artifact_config.gd:108),
## AFTER add_child, i.e. after _ready has already built the cabinet. So the rung
## has to be able to arrive late and move the geometry.
##
## THE GUARD IS LOAD-BEARING. curation_station.gd calls
## apply_grid_config({"emissive": false}) on every artifact it curates, one line
## after it has hidden labels and darkened modulates. That dict carries no
## disclosure key; an unconditional rebuild would throw that framing away on every
## curated shelf. Unchanged rung means touch nothing.
func apply_grid_config(config: Dictionary) -> void:
	var before: String = disclosure
	var reseed: bool = false

	if config.has("disclosure"):
		# Fall back to the LEGACY rung, not the current value: an unreadable word
		# must not quietly seal a machine four rooms expect open.
		disclosure = Disclosure.disclosure_name(str(config["disclosure"]))
	if config.has("dart_seed"):
		var want: int = int(str(config["dart_seed"]))
		if want != dart_seed:
			dart_seed = want
			reseed = true

	if disclosure == before and not reseed:
		return
	_rebuild_now()
	print("[MonteCarloDartboard] Config applied — disclosure=%s seed=%d" % [disclosure, dart_seed])


## Tear down what this script built and build it again, INLINE. No call_deferred:
## a deferred rebuild leaves the node empty for a frame, and _auto_ground_artifact
## — which runs later in the same deferred queue — would measure a zero AABB and
## leave the cabinet ungrounded. Every child of this node is script-built (the
## .tscn holds only the root), so clearing them all is exactly the teardown.
func _rebuild_now() -> void:
	for c in get_children():
		remove_child(c)          # leaves the tree synchronously — no double render
		c.queue_free()
	_dart_meshes.clear()
	_inside_count = 0
	_total_count = 0
	_throw_timer = 0.0
	_last_rx = 0.0
	_last_ry = 0.0
	_last_inside = false
	# Cached refs point at freed nodes now; the readout path is null-guarded, so
	# clearing these is what keeps a rung that drops a pocket from repainting into
	# a corpse.
	_readout_root = null
	_readout_block = null
	_readout_cache = ""
	_readout_color = Color(0.85, 0.87, 0.95)
	_readout_line_h = _READOUT_LINE_H
	_readout_width = _READOUT_WIDTH
	_circle_mesh = null
	# Restart the draw sequence so a pinned board is pinned from its first dart.
	_setup_seeded_stream()
	_build_all()
