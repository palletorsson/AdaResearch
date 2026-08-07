extends Node3D

# @identity
# essence: a page from a book that RAND never printed — "A Million Random
#   Colors": 28 numbered lines of 10 chips each, every chip Color(randf, randf,
#   randf), typeset like the 1955 digit table it is a pastiche of
# desire: to hold uniform RGB the way the century held uniform digits — bound,
#   paginated, addressable; randomness as a PUBLISHED object you can cite
# critical_parameter: disclosure — how much the page admits about where its
#   colors came from; page_seed — whether this page is printed or re-dealt on
#   every visit
# triggers: _ready deals the whole sheet once; no interaction, no animation
# emerges: the chips form no picture and that is the point — 280 draws from the
#   RGB cube, each one nothing, the aggregate unmistakably "random"
# relationships: the colour twin of [[random_number_book_page_1955]] (this
#   collection's sheets even carry that scene's node names); shares `disclosure`
#   word for word with it, with [[prng_crank_machine]] and [[coin_toss]]
# truth: a random color is a random number wearing its value on its face — the
#   page needs no magnifier, which is why its provenance apparatus matters more,
#   not less

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-06) — the colour page joins the randomness
# family's ONE axis.
#
#   disclosure   oracle < tally < ledger < works < origin
#
# The word, the five values, the reader and the rung table are
# prng_crank_machine's; random_number_book_page_1955 (this page's typographic
# twin) already parses through them. Adopting rather than inventing is the
# point: this tier's whole subject is where a random value came from, and the
# colour page asking it in a private vocabulary would be a page nobody can
# compare with the digit page hanging beside it.
#
# WHAT THE RUNGS MEAN ON A PRINTED PAGE OF COLOUR. The provenance apparatus is
# typography — the running head, the folio, the line numbers, the imprint —
# and apparatus costs space, so the field of chips fills whatever it leaves:
#
#   oracle  A SLAB. Thirteen butt-jointed chips per line, edge to edge across
#           the sheet, two extra lines top and bottom; no head, no folio, no
#           line numbers. A continuous mosaic of unaddressed colour — you can
#           look at it and never cite it. Print's version of the API call.
#   tally   The slab, six lines shorter, and under it a HUE-FREQUENCY CHART:
#           ten bars over a ruled baseline, one per hue decile, each bar tinted
#           with the decile it counts, counted off this page's own chips. The
#           statistician's alibi — "every hue appears about as often" is true
#           and answers a different question than the one asked.
#   ledger  The apparatus of record returns: the line-number column down the
#           left margin and the folio in the corner; the field returns to its
#           measured ten-chip setting with the five-line grouping. Every chip
#           now has an address. Still anonymous — nothing says who made it.
#   works   + the running head: TABLE OF RANDOM COLORS, and the folio. THIS IS
#           THE LEGACY PAGE, byte for byte — same 28 lines, same spacing, same
#           chip positions, same draw order from the same global stream.
#   origin  + the imprint block at the foot: the method admitted — three
#           uniform draws from the RGB cube per chip, no gamut correction —
#           this page's position in the million, and the seed if one was
#           recorded. The rung at which the book becomes a record of an
#           experiment.
#
# THE SEAT-SWAP, DECLARED (same shape as the twin): the foot band carries the
# tally at `tally` and the imprint at `origin` and is empty at the three rungs
# between. The ladder is monotone in HOW MUCH IS ADMITTED.
#
# NOT PROMOTED: grid_width / grid_height (quantities, not claims);
# change_interval (a duration — invisible to a still, and note it is exported
# yet unused by this script: reported, not silently deleted).
#
# NOT TOUCHED: the chips themselves. Every rung draws colours the same way in
# the same order. The axis changes what the PAGE says about where they came
# from.
#
# THE STREAM TAX, DOCUMENTED: `start_index` is initialised with a global randi
# draw at INSTANTIATE time (before exports arrive) and then unconditionally
# overwritten in _ready — a wasted draw, but one every shipped placement has
# always made. It stays, verbatim, because removing it would shift the global
# RNG stream for everything sampled after this page (R1).
# ─────────────────────────────────────────────────────────────────────────────

## The family's ladder, defined once in prng_crank_machine.gd. Preloaded rather
## than reached through class_name — class_name lookups are not reliable
## headless, and every frame of the evidence loop is rendered headless.
const Disclosure = preload("res://algorithms/randomness/prng_crank_machine/prng_crank_machine.gd")

@export var font_file: FontFile
@export var grid_width: int = 10 # Number of columns (excluding the index column)
@export var grid_height: int = 28 # Number of rows per page
@export var number_spacing_x: float = 0.3
@export var number_spacing_y: float = 0.15  # Adjusted for better spacing
@export var cluster_spacing_x: float = 0.7
@export var cluster_spacing_y: float = 0.6
@export var change_interval: float = 10.0

## THE AXIS — how much this page admits about where its colours came from.
## Same five rungs, same order, same spellings as the digit page. `works` is
## the legacy page.
@export_enum("oracle", "tally", "ledger", "works", "origin") var disclosure: String = "works"

## The allow-list, in ladder order — what a map token is checked against.
const DISCLOSURES: PackedStringArray = ["oracle", "tally", "ledger", "works", "origin"]

## SEED. -1 (the default) is today's behaviour exactly: every chip is drawn from
## the GLOBAL rng, so no two instantiations of this page agree. Any value >= 0
## deals from a private, seeded generator instead — which is what a printed page
## is. Comparing two photographs of an unseeded page measures 840 re-rolled
## draws, not the axis; the DNA fixture must set it. The collection root offsets
## it per sheet so three seeded pages are three different pages.
@export var page_seed: int = -1

@onready var label3D = $Label3D_Title
@onready var label3D_side_number = $Label3D_Side_Number

var color_labels: Array[Label3D] = []
var color_blocks: Array[MeshInstance3D] = []
var timer: Timer
var start_index: int = 100 + randi() % 900  # Randomized starting index (see THE STREAM TAX above)
var side_number: int

# ── Page metrics ────────────────────────────────────────────────────────
# The sheet is a 4 x 6 QuadMesh centred at (-0.567, -2.379): x in [-2.567,
# 1.433], y in [-5.379, 0.621]. Everything the axis prints stays inside it —
# the sweep frames the subject by its MeshInstance3D bounding box, and that box
# is the sheet, so furniture cannot move the camera between variants.
const LEGACY_TOP := 0.0      # first row's y with the running head above it (today's row 0)
const OPEN_TOP := 0.45       # first row's y when no running head takes the space
const LEGACY_X := -1.7       # first chip column's x with the line-number margin present
const SOLID_X := -2.41       # first chip column's x in the solid setting (margin given back)
const SLAB_FOOT := -5.15     # lowest row in the solid setting (oracle)
const CHART_FOOT := -2.95    # lowest row when the hue chart takes the foot
const FURNITURE_INK_Z := 0.006
const FURNITURE_TEXT_Z := 0.012

## Printer's ink for rules, box and caption text — a shade softer than the
## row-number black so a rule never out-blacks the data it is ruling.
const INK := Color(0.07, 0.07, 0.08)

# ── Lifecycle bookkeeping ───────────────────────────────────────────────
## Everything THIS script added to the sheet. A rung change frees exactly these
## and re-deals — get_children() would also destroy the scene's own paper,
## running head and folio, which are .tscn nodes this script only dims.
var _owned: Array[Node] = []
var _built: bool = false
var _page_furniture: Node3D = null
## Every chip colour dealt onto this sheet, in deal order — what the tally counts.
var _chip_colors: Array[Color] = []

## The private generator. Only consulted when page_seed >= 0, so the global
## stream is untouched on every shipped placement.
var _rng := RandomNumberGenerator.new()
var _pinned: bool = false


# ═══════════════════════════════════════════════════════════════════════
# THE AXIS — readers (same gates as the digit page)
# ═══════════════════════════════════════════════════════════════════════

## Rank of the current rung, 0..4, read through the family's one table.
func _rung() -> int:
	return int(Disclosure.DISCLOSURE_RUNGS.get(disclosure, 3))


## Book setting (five-line groups, line numbers) or solid slab? Grouping is
## reading apparatus and arrives with the rest of the record at `ledger`.
func _grouped() -> bool:
	return _rung() >= 2


func _top_y() -> float:
	return LEGACY_TOP if _rung() >= 3 else OPEN_TOP


## Chips per line. Three more in the solid setting — the margin's space given
## back to data (the digit page gains five; a chip is wider than a numeral).
func _cols() -> int:
	return grid_width if _rung() >= 2 else grid_width + 3


## Lines on the page. The apparatus takes space and the field gives it: the
## imprint costs two lines, the hue chart six; a page with no head gains one
## or two. (`ledger` gains one, not the digit page's three — this sheet's
## grouped rhythm runs out of paper below 29 lines.)
func _rows() -> int:
	var r: int = _rung()
	if r == 0:
		return grid_height + 2
	if r == 1:
		return maxi(4, grid_height - 6)
	if r == 2:
		return grid_height + 1
	if r == 4:
		return maxi(4, grid_height - 2)
	return grid_height


## Row pitch in the solid setting — the block fills the band it is given.
func _flat_pitch() -> float:
	var foot: float = CHART_FOOT if _rung() == 1 else SLAB_FOOT
	return (_top_y() - foot) / float(maxi(1, _rows() - 1))


func _row_y(row: int) -> float:
	if _grouped():
		# The legacy walk in closed form: one spacing per line plus an extra 1.2
		# spacings after every fifth. Same numbers the shipped loop produced.
		return _top_y() - number_spacing_y * float(row) \
			- number_spacing_y * 1.2 * float(row / 5)
	return _top_y() - _flat_pitch() * float(row)


func _col_x(col: int) -> float:
	if _grouped():
		return LEGACY_X + number_spacing_x * float(col)   # (col * 0.3) - 1.7, verbatim
	# Solid setting: butt-jointed chips (0.3 wide on a 0.3 pitch), edge to edge.
	return SOLID_X + number_spacing_x * float(col)


# ═══════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child, so the
	# meta read happens here; apply_grid_config arrives deferred and is a
	# re-read, not the read.
	_read_meta_overrides()
	if font_file == null:
		push_error("Font file not assigned!")
		return

	if page_seed >= 0:
		_rng.seed = page_seed
		_pinned = true

	_apply_head_visibility()
	_deal_page()
	_built = true


## One colour chip's worth of chance. The unpinned path is the shipped call,
## unchanged, so the global rng sequence is identical to the day this shipped.
func _chip_color() -> Color:
	if _pinned:
		return Color(_rng.randf(), _rng.randf(), _rng.randf())
	return Color(randf(), randf(), randf())


## Deal the whole sheet: folio, start index, chip grid, furniture. Draw order
## on the default path is byte-for-byte the shipped _ready + _create_label_grid.
func _deal_page() -> void:
	side_number = _rng.randi_range(100, 999) if _pinned else randi_range(100, 999)
	label3D_side_number.text = str(side_number)

	# Scale the start_index based on the original relation (17600 → 353)
	var scale_factor = 17600.0 / 353.0
	start_index = int(side_number * scale_factor)

	_create_label_grid()
	_build_page_furniture()


func _create_label_grid() -> void:
	var rows: int = _rows()
	var cols: int = _cols()
	var show_margin: bool = _grouped()

	for row in range(rows):
		var row_text = str(start_index + row) + "       "
		var row_y: float = _row_y(row)

		for col in range(cols):
			# Generate a random color
			var color: Color = _chip_color()
			_chip_colors.append(color)

			# Create color block visual representation
			var block_position = Vector3(_col_x(col), row_y, 0.0)
			var color_block = ColorHelper.create_color_block(block_position, color)
			add_child(color_block)
			color_blocks.append(color_block)
			_owned.append(color_block)

		# Line-number label (left margin) — ledger and up. THE ADDRESS. Below
		# that rung the page keeps no line numbers, which is precisely what
		# makes a table of random colours uncitable.
		if show_margin:
			var row_label = LabelHelper.create_number_label(Vector3(-2, row_y, 0), row_text, font_file)
			row_label.font_size = 16
			row_label.outline_size = 3
			row_label.modulate = Color(0, 0, 0)  # Black text
			add_child(row_label)
			_owned.append(row_label)


# ═══════════════════════════════════════════════════════════════════════
# THE APPARATUS — what the page admits, printed
# ═══════════════════════════════════════════════════════════════════════

## The running head and the folio are .tscn nodes, so the axis dims them rather
## than building them. layers = 0, NOT visible = false: hiding a node hides its
## whole subtree, and zeroing the visual layers leaves the tree exactly as it
## was while taking the label out of every camera.
func _apply_head_visibility() -> void:
	var r: int = _rung()
	_set_visual_layers(get_node_or_null("Label3D_Title"), r >= 3)
	_set_visual_layers(get_node_or_null("Label3D_Side_Number"), r >= 2)


func _set_visual_layers(n: Node, shown: bool) -> void:
	if n == null or not (n is VisualInstance3D):
		return
	(n as VisualInstance3D).layers = 1 if shown else 0


## The foot band: the hue chart at `tally`, the imprint at `origin`, nothing at
## the three rungs between — including `works`, which stays the legacy page.
func _build_page_furniture() -> void:
	if _page_furniture != null and is_instance_valid(_page_furniture):
		_owned.erase(_page_furniture)
		_page_furniture.queue_free()
		_page_furniture = null

	var r: int = _rung()
	if r != 1 and r != 4:
		return

	_page_furniture = Node3D.new()
	_page_furniture.name = "PageFurniture"
	add_child(_page_furniture)
	_owned.append(_page_furniture)

	if r == 1:
		_build_hue_chart()
	else:
		_build_imprint_block()


## A rectangle of printing on the sheet — unshaded so it reads as ink, not as
## an object lying on paper.
func _ink(cx: float, cy: float, w: float, h: float, col: Color = INK) -> void:
	if _page_furniture == null:
		return
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.position = Vector3(cx, cy, FURNITURE_INK_Z)
	_page_furniture.add_child(mi)


## A line of printing, set the same way as the sheet's own labels (this page
## faces +Z; nothing here is mirrored).
func _print_line(txt: String, cx: float, cy: float, size: int, col: Color = INK) -> void:
	if _page_furniture == null or font_file == null:
		return
	var l := Label3D.new()
	l.text = txt
	l.font = font_file
	l.font_size = size
	l.outline_size = 0
	l.modulate = col
	l.position = Vector3(cx, cy, FURNITURE_TEXT_Z)
	_page_furniture.add_child(l)


## disclosure:tally — the aggregate, and only the aggregate. Ten bars, one per
## hue decile, each tinted with the decile it counts, counted off this page's
## own chips over a ruled baseline. Uniformity is the one thing a table of
## random colours can prove about itself without telling you where any colour
## came from — which is why it sits BELOW the line numbers on the ladder.
func _build_hue_chart() -> void:
	var counts: Array[int] = []
	for i in range(10):
		counts.append(0)
	for c in _chip_colors:
		var d: int = clampi(int(floor(c.h * 10.0)), 0, 9)
		counts[d] += 1
	var peak: int = 1
	for n in counts:
		peak = maxi(peak, n)

	var baseline: float = -4.85
	var max_h: float = 1.45
	var pitch: float = 0.36
	var bar_w: float = 0.28
	var x0: float = -0.567 - pitch * 4.5   # centred on the sheet

	_print_line("HUE FREQUENCY - %d CHIPS ON THIS PAGE" % _chip_colors.size(),
		-0.567, baseline + max_h + 0.16, 14)
	for d in range(10):
		var h: float = maxf(0.03, max_h * float(counts[d]) / float(peak))
		var cx: float = x0 + pitch * float(d)
		_ink(cx, baseline + h * 0.5, bar_w, h, Color.from_hsv((float(d) + 0.5) / 10.0, 0.85, 0.9))
	# The rule the bars stand on — a chart without a baseline is a smear.
	_ink(-0.567, baseline - 0.012, 3.6, 0.016)


## disclosure:origin — the imprint. The method, this page's position in the
## million, and the seed: the facts that make the book a record of an
## experiment rather than a bag of colours. Boxed, because an imprint is a
## block on a page and not a footnote.
func _build_imprint_block() -> void:
	var top: float = -4.78
	var bot: float = -5.30
	var left: float = -2.35
	var right: float = 1.25
	var h: float = top - bot
	var cy: float = (top + bot) * 0.5
	var rule: float = 0.014

	# The box
	_ink((left + right) * 0.5, top, right - left, rule)
	_ink((left + right) * 0.5, bot, right - left, rule)
	_ink(left, cy, rule, h)
	_ink(right, cy, rule, h)

	# The seal — solid ink with the folio reversed out of it.
	_ink(left + 0.30, cy, 0.44, h - 0.10)
	_print_line(str(side_number), left + 0.30, cy - 0.03, 20, Color(0.97, 0.97, 0.95))

	_print_line("COLOR(RANDF, RANDF, RANDF) - UNIFORM RGB CUBE - UNGRADED", -0.35, cy + 0.10, 13)
	_print_line("AFTER RAND 1955 - LINES %d-%d OF A MILLION COLORS" % [
		start_index, start_index + maxi(0, _rows() - 1)], -0.35, cy - 0.04, 13)
	var seed_line: String = "SEED NOT RECORDED"
	if page_seed >= 0:
		seed_line = "SEED %d" % page_seed
	_print_line(seed_line, -0.35, cy - 0.17, 12)


# ═══════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═══════════════════════════════════════════════════════════════════════

## Strip the sheet back to the scene's own paper and deal it again. Only the
## nodes this script added are freed; the paper, head and folio are dimmed,
## never destroyed. A pinned page re-seeds first, so the same seed always
## prints the same page whatever rung it is re-set to.
func _reprint() -> void:
	for n in _owned:
		if is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_owned.clear()
	_page_furniture = null
	color_blocks.clear()
	color_labels.clear()
	_chip_colors.clear()
	if _pinned:
		_rng.seed = page_seed
	_apply_head_visibility()
	_deal_page()


## Was `pass` — every `#token: value` a map put on a placement was parsed,
## stashed as metadata and discarded. Guarded like the digit page's: an
## unchanged rung touches nothing, so curation_station's blanket
## apply_grid_config({"emissive": false}) lands here and returns.
func apply_grid_config(config: Dictionary) -> void:
	var before_rung: String = disclosure
	var before_seed: int = page_seed
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()
	if not _built:
		return                       # nothing built yet; _ready will use these values
	if disclosure == before_rung and page_seed == before_seed:
		return
	if page_seed != before_seed and page_seed >= 0:
		_rng.seed = page_seed
		_pinned = true
	_reprint()


func _read_meta_overrides() -> void:
	if has_meta("config_disclosure"):
		# Read through the family's one reader, so a typo falls back to the
		# legacy page rather than quietly stripping a room's attribution.
		disclosure = Disclosure.disclosure_name(str(get_meta("config_disclosure")))
	if has_meta("config_page_seed"):
		page_seed = int(str(get_meta("config_page_seed")))


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
