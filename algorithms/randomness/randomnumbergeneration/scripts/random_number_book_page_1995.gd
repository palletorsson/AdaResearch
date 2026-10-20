extends Node3D
const HallSeed = preload("res://commons/artifacts/randomness_space/hall_seed.gd")

## Live-cascading random number page inspired by the RAND Corporation's
## "A Million Random Digits" (1955).  Numbers scroll top-to-bottom like a
## stock ticker.  Touch any number in VR (poke) to freeze it in place —
## frozen numbers glow amber while the rest keep flowing.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-02) — the RAND page joins the randomness
# family's ONE axis.
#
#   disclosure   oracle  <  tally  <  ledger  <  works  <  origin
#
# The word, the five values and the reader are prng_crank_machine's; coin_toss
# already parses through them. Adopting rather than inventing is the point: this
# tier's whole subject is where a random number came from, and three artifacts
# asking that question in three vocabularies would be three artifacts nobody can
# compare. A Million Random Digits IS the origin rung made literal — randomness
# printed, bound, paginated and sold, so that nobody had to trust a generator
# they could not inspect. Whatever else this page is, it is the strongest claim
# in the curriculum that provenance is a PUBLISHING problem.
#
# WHAT THE RUNGS MEAN ON A PRINTED PAGE. A page's provenance apparatus is its
# typography: the folio, the line numbers, the running head, the imprint. Each
# of those costs space, and space on a page is data — so the field of digits
# fills whatever the apparatus leaves, which is why the rungs are legible from
# across a room and not just legible under a magnifier.
#
#   oracle  A SLAB. Fifteen columns of five-digit numbers, set solid — no
#           five-line grouping, no cluster gaps, no margin, edge to edge. No
#           folio, no line numbers, no running head, no imprint. The densest,
#           blackest version of the page and the least usable one: you cannot
#           cite it, check it, or find it again. Digits with no address —
#           print's version of the API call.
#   tally   The slab, six lines shorter, and under it a DIGIT-FREQUENCY CHART:
#           ten bars over a ruled baseline, one per digit, counted off this
#           page's own numerals. The statistician's alibi — "every digit
#           appears about as often" is a true sentence answering a different
#           question than the one asked, and it is printed here INSTEAD of any
#           way to locate a single digit.
#   ledger  The apparatus of record returns: the line-number column down the
#           margin and the folio in the corner. Every numeral now has an
#           address — page 356, line 17,614, column 3 — and the field returns to
#           its measured ten-column setting because the margin has taken its
#           space back. Still anonymous: nothing says who printed it.
#   works   + the running head. TABLE OF RANDOM DIGITS / A Million Random
#           Digits / RAND Corporation, 1955. Who made it and what it is. THIS
#           IS THE LEGACY PAGE, byte for byte — same twenty-eight lines, same
#           spacing, same four labels.
#   origin  + the imprint block at the foot: the method (an electronic roulette
#           wheel, pulses counted mod 32, 1947), the correction (the raw table
#           was biased and was corrected in 1948), and this page's exact
#           position in the million. The rung at which the book stops being a
#           book of numbers and becomes a record of an experiment.
#
# THE SEAT-SWAP, DECLARED. The foot band carries the tally at `tally` and the
# imprint at `origin` and is empty at the three rungs between — the same shape
# prng_crank_machine's middle seat has (distribution at tally/ledger, arithmetic
# at works/origin). The ladder is monotone in HOW MUCH IS ADMITTED, not in how
# many widgets are stacked, and the legacy page must survive `works` untouched.
#
# NOT PROMOTED: cascade_speed. It is the obvious knob and it is invisible to a
# still (info_board was swept across five duration exports and produced six
# identical tiles). grid_width / grid_height are not promoted either: they
# change how much of the same thing there is, which is a quantity, not a claim.
#
# NOT TOUCHED: the digits themselves. Every rung prints numerals drawn the same
# way from the same source, in the same 5-digit form, and freezes them amber on
# touch. This axis changes what the PAGE says about where they came from.
# ─────────────────────────────────────────────────────────────────────────────

## The family's ladder, defined once in prng_crank_machine.gd. Preloaded rather
## than reached through class_name — the packaging family proved class_name
## lookups are not reliable headless, and every frame of the evidence loop is
## rendered headless.
const Disclosure = preload("res://algorithms/randomness/prng_crank_machine/prng_crank_machine.gd")

@export var font_file: FontFile
@export var grid_width: int = 10   ## columns of 5-digit numbers
@export var grid_height: int = 28  ## visible rows
@export var number_spacing_y: float = 0.15
@export var cascade_speed: float = 1.0  ## rows per second (adjustable)
@export var row_stream: bool = false  ## Live rows enter an empty page from the top, with visible downward motion.
@export_range(0, 100, 1) var initial_rows: int = 0  ## Prefill from the same stream, oldest row below the newest.

## THE AXIS — how much this page admits about where its digits came from. Same
## five rungs, same order, same spellings as prng_crank_machine and coin_toss.
## `works` is the legacy page.
@export_enum("oracle", "tally", "ledger", "works", "origin") var disclosure: String = "works"

## The allow-list, in ladder order — the same five words the @export_enum above
## declares. What a map token is checked against.
const DISCLOSURES: PackedStringArray = ["oracle", "tally", "ledger", "works", "origin"]

## SEED. -1 (the default) is today's behaviour exactly: every numeral is drawn
## from the GLOBAL rng, so no two instantiations of this page agree and the
## cascade keeps flowing. Any value >= 0 draws from a private, seeded generator
## instead and FREEZES the cascade — which is what a printed page is.
##
## This is not decoration. Comparing two photographs of this artifact is
## meaningless while 1,400 numerals re-roll between them: a sweep of `disclosure`
## on an unseeded page would measure the digits and report a confident bite that
## is entirely about noise. The DNA fixture must set it.
@export var page_seed: int = -1

## Folio is an address, never a draw from the number stream. Changing it does
## not skip values or turn a page into a different seeded sequence.
@export_range(1, 999999, 1) var page_number: int = 1

## Extra yaw, in degrees, applied to the whole sheet at build.
##
## LATENT DEFECT THIS EXISTS FOR (reported, not silently fixed): the printed face
## of this page looks along -Z. The scene rotates the paper 180° and the script
## rotates every label 180° to match, so the readable side points AWAY from the
## direction every capture camera in this project shoots from. The shipped
## capture at public/artifact-gallery/captures/random_number_book_page_1955/
## front.png is a blank white rectangle — the back of the sheet. Turning the
## page would change all ten live placements, so the default stays 0.0 (today,
## byte for byte) and the sweep's fixture sets 180 to photograph the front.
@export var page_yaw_deg: float = 0.0

@onready var label3D: Label3D = $Label3D_Title
@onready var label3D_side_number: Label3D = $Label3D_Side_Number

# ── Per-cell state ──────────────────────────────────────────────────────
# _cells[row][col] = Label3D node
var _cells: Array = []           # Array[Array[Label3D]]
var _frozen: Array = []          # Array[Array[bool]]
var _cell_areas: Array = []      # Array[Array[Area3D]]  (VR touch zones)

# Cascade timing
var _cascade_timer: float = 0.0
var _stream_moves: Array = []
var _stream_elapsed: float = 0.0
var _stream_duration: float = 0.9

# Colors
const COLOR_NORMAL := Color(0, 0, 0)
const COLOR_FROZEN := Color(0.85, 0.55, 0.05)  # Amber glow
const COLOR_FROZEN_OUTLINE := Color(1.0, 0.75, 0.1, 0.6)

## Printer's ink for the rules, bars and stamp the axis prints. The numerals use
## COLOR_NORMAL (pure black); the apparatus is a shade softer so a rule never
## out-blacks the data it is ruling.
const INK := Color(0.07, 0.07, 0.08)

# ── Page metrics ────────────────────────────────────────────────────────
# The sheet is a 4 x 6 QuadMesh at the origin: x in [-2, 2], y in [-3, 3].
# EVERYTHING the axis prints stays inside it, deliberately — the sweep frames
# the subject by its MeshInstance3D bounding box, and that box is the sheet, so
# furniture inside the page cannot move the camera between variants.
const LEGACY_TOP := 2.3      # first row's y with the running head above it
const OPEN_TOP := 2.75       # first row's y when no running head takes the space
const LEGACY_X := 1.35       # first column's x with the line-number margin present
const OPEN_X := 1.85         # first column's x when the margin is given back to data
const FLAT_LEFT := -1.75     # last column's x in the solid setting
const CELL_W := 0.25
const CLUSTER_GAP := 0.12
const SLAB_FOOT := -2.85     # lowest row in the solid setting (oracle)
const CHART_FOOT := -0.55    # lowest row when the frequency chart takes the foot
const FURNITURE_INK_Z := -0.003
const FURNITURE_TEXT_Z := -0.006

var side_number: int
var start_index: int

# ── Lifecycle bookkeeping ───────────────────────────────────────────────
## Everything THIS script added to the sheet. A rung change frees exactly these
## and rebuilds — get_children() would also destroy the scene's own paper, its
## running head and the folio, which are .tscn nodes this script only dims.
## Keep these children on tree exit: museum cartridge compilation temporarily
## detaches and reattaches the page. Godot frees them when the page is deleted;
## _reprint() explicitly replaces them when the page's configuration changes.
var _owned: Array[Node] = []
var _built: bool = false
var _built_rows: int = 0
var _built_cols: int = 0
var _page_furniture: Node3D = null

## The private generator. Only ever consulted when page_seed >= 0, so the global
## stream is untouched on every shipped placement.
var _rng := RandomNumberGenerator.new()
var _pinned: bool = false


# ═══════════════════════════════════════════════════════════════════════
# THE AXIS — readers
# ═══════════════════════════════════════════════════════════════════════

## Rank of the current rung, 0..4, read through the family's one table.
func _rung() -> int:
	return int(Disclosure.DISCLOSURE_RUNGS.get(disclosure, 3))


## Is the type set as a book (five-line groups, two-column clusters) or solid?
## Grouping is reading apparatus: it is what lets you keep your place, and it
## arrives with the rest of the record apparatus at `ledger`.
func _grouped() -> bool:
	return _rung() >= 2


## Where the first row sits. The running head owns the top of the sheet from
## `works` up; below that the data takes the space.
func _top_y() -> float:
	return LEGACY_TOP if _rung() >= 3 else OPEN_TOP


## Where the first column sits. The line-number margin owns the right edge from
## `ledger` up.
func _x_base() -> float:
	return LEGACY_X if _rung() >= 2 else OPEN_X


## How many columns are printed. Five more in the solid setting, because there
## is no margin to leave clear.
func _cols() -> int:
	return grid_width if _rung() >= 2 else grid_width + 5


## How many lines are printed. The apparatus takes space and the field gives it:
## the imprint block costs two lines, the frequency chart costs six, and a page
## with no head at all gains two or three.
func _rows() -> int:
	var r: int = _rung()
	if r == 0:
		return grid_height + 2
	if r == 1:
		return maxi(4, grid_height - 6)
	if r == 2:
		return grid_height + 3
	if r == 4:
		return maxi(4, grid_height - 2)
	return grid_height


## Row pitch in the solid setting, chosen so the block fills the band it is
## given rather than trailing off in the middle of the sheet.
func _flat_pitch() -> float:
	var foot: float = CHART_FOOT if _rung() == 1 else SLAB_FOOT
	return (_top_y() - foot) / float(maxi(1, _rows() - 1))


## Column pitch in the solid setting — fifteen columns spread edge to edge.
func _flat_col_pitch() -> float:
	return (OPEN_X - FLAT_LEFT) / float(maxi(1, _cols() - 1))


func _row_y(row: int) -> float:
	if _grouped():
		# The legacy walk, in closed form: one spacing per line, plus an extra
		# 1.2 spacings after every fifth. Same numbers the loop produced.
		return _top_y() - number_spacing_y * float(row) \
			- number_spacing_y * 1.2 * float(row / 5)
	return _top_y() - _flat_pitch() * float(row)


# ═══════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child, so the meta
	# read must happen here, before any geometry exists. apply_grid_config()
	# arrives call_deferred — after this — and is a re-read, not the read.
	_read_meta_overrides()
	if font_file == null:
		push_error("[RandomNumberBook] Font file not assigned!")
		return

	# Additive: rotate_y(0) is a no-op, so every shipped placement is untouched.
	# Applied as a ROTATION, not an assignment, so a map's own facing survives.
	if page_yaw_deg != 0.0:
		rotate_y(deg_to_rad(page_yaw_deg))

	if page_seed >= 0:
		_rng.seed = page_seed
		_pinned = true
	if HallSeed.enabled(self):
		page_seed = HallSeed.current(self)
		_rng.seed = page_seed
		_pinned = false # A seeded, flowing page; pinning is a separate display mode.

	_update_page_address()

	_apply_head_visibility()
	_create_cell_grid()
	_build_page_furniture()
	_built = true
	_ensure_select_sign()
	if row_stream and not _pinned:
		_cascade_timer = 1.0 if initial_rows == 0 else 0.0 # A prefilled page waits one cadence before its next row.
	HallSeed.bind(self)

func _apply_hall_seed(value: int, _receipt: Dictionary) -> void:
	page_seed = value
	_rng.seed = value
	_pinned = false
	_update_page_address()
	_reprint()

func _update_page_address() -> void:
	page_number = maxi(1, page_number)
	side_number = page_number
	label3D_side_number.text = str(side_number)
	start_index = (page_number - 1) * _rows()
	for row in range(_built_rows):
		var label := get_node_or_null("RowIdx_%d" % row) as Label3D
		if label != null: label.text = str(start_index + row)

func _process(delta: float) -> void:
	if _pinned or not _built:
		return   # a seeded page is a PRINTED page: it does not flow
	if row_stream:
		_advance_stream(delta)
	_cascade_timer += delta * cascade_speed
	if _cascade_timer >= 1.0 and _stream_moves.is_empty():
		# Never turn a long frame into a burst of unreadably fast rows.
		_cascade_timer = 0.0 if row_stream else _cascade_timer - 1.0
		_cascade_step()

func _ensure_select_sign() -> void:
	var existing := get_node_or_null("SelectStand")
	if not row_stream or _pinned:
		if existing != null:
			remove_child(existing)
			existing.queue_free()
		return
	if existing != null: return
	var sign = preload("res://commons/artifacts/randomness_space/select_sign.gd").new()
	sign.name = "SelectStand"
	# Page is six metres tall, centred on its origin and facing local -Z.
	sign.position = Vector3(0,-3.0,-0.65)
	sign.rotation.y = PI
	add_child(sign)

# ═══════════════════════════════════════════════════════════════════════
# GRID CREATION
# ═══════════════════════════════════════════════════════════════════════

## The seeded page reads the same randf() sequence as the colour window's
## baseline. Each RGB channel there becomes one five-digit group here.
## Truncate the full value, not a rounded display string; retain leading zeros.
static func five_digits_from_value(value: float) -> String:
	return str(clampi(int(floor(value * 100000.0)), 0, 99999)).pad_zeros(5)

func book_capture_ready() -> bool:
	# Photograph the first full, settled page; observing readiness changes no draws.
	if not _built or _built_rows == 0 or not _stream_moves.is_empty(): return false
	for row in _cells:
		for cell in row:
			if cell.text.is_empty() or cell.modulate.a < 0.999: return false
	return true

func capture_book_state() -> Dictionary:
	var digits: Array = []
	for row in _cells:
		var values: Array = []
		for cell in row: values.append(cell.text)
		digits.append(values)
	return {"seed":page_seed,"rng_state":str(_rng.state),"page_number":page_number,
		"digits":digits,"frozen":_frozen.duplicate(true),"row_stream":row_stream,
		"cascade_speed":cascade_speed,"stream_elapsed":_stream_elapsed,
		"full_and_settled":book_capture_ready(),"rows":_built_rows,"columns":_built_cols,"initial_rows":initial_rows}

func _five_digits() -> String:
	if _pinned or HallSeed.enabled(self):
		return five_digits_from_value(_rng.randf())
	return NumberHelper.random_5_digit_number()


func _create_cell_grid() -> void:
	_built_rows = _rows()
	_built_cols = _cols()
	var show_margin: bool = _rung() >= 2

	_cells.resize(_built_rows)
	_frozen.resize(_built_rows)
	_cell_areas.resize(_built_rows)

	for row in range(_built_rows):
		_cells[row] = []
		_frozen[row] = []
		_cell_areas[row] = []
		(_cells[row] as Array).resize(_built_cols)
		(_frozen[row] as Array).resize(_built_cols)
		(_cell_areas[row] as Array).resize(_built_cols)

		var row_y: float = _row_y(row)

		for col in range(_built_cols):
			_frozen[row][col] = false

			# Position: index column takes ~0.7, then numbers spaced with cluster gaps
			var x_pos := _col_x_position(col)
			var cell_label := Label3D.new()
			cell_label.name = "Cell_%d_%d" % [row, col]
			cell_label.text = "" if row_stream and not _pinned else _five_digits()
			cell_label.font = font_file
			cell_label.font_size = 16
			cell_label.outline_size = 3
			cell_label.modulate = COLOR_NORMAL
			cell_label.position = Vector3(x_pos, row_y, -0.001)
			cell_label.rotate(Vector3(0, 1, 0), PI)
			add_child(cell_label)
			_owned.append(cell_label)
			_cells[row][col] = cell_label

			# Touch area for VR interaction
			var area := _create_touch_area(cell_label, row, col)
			_cell_areas[row][col] = area

		# Row index label (left margin) — disclosure:ledger and up. THE ADDRESS.
		# Below that rung the page keeps no line numbers, which is precisely what
		# makes a table of digits uncitable.
		if show_margin:
			var idx_label := Label3D.new()
			idx_label.name = "RowIdx_%d" % row
			idx_label.text = str(start_index + row)
			idx_label.font = font_file
			idx_label.font_size = 16
			idx_label.outline_size = 3
			idx_label.modulate = Color(0.3, 0.3, 0.3)
			idx_label.position = Vector3(1.7, row_y, -0.001)
			idx_label.rotate(Vector3(0, 1, 0), PI)
			add_child(idx_label)
			_owned.append(idx_label)
	_prime_stream_rows()

func _prime_stream_rows() -> void:
	if not row_stream or _pinned: return
	# Match the natural downward stream: the first ten draws are the lowest
	# seeded row, later groups sit above them, and the next draw continues it.
	for row in range(clampi(initial_rows,0,_built_rows)-1,-1,-1):
		for col in _built_cols:
			var cell: Label3D = _cells[row][col]
			cell.text = _five_digits()
			cell.modulate = COLOR_NORMAL

func _col_x_position(col: int) -> float:
	## Map column index to X position, with cluster gaps every 2 columns.
	if not _grouped():
		# Solid setting: no clusters, spread edge to edge across the sheet.
		return OPEN_X - _flat_col_pitch() * float(col)
	var base := _x_base()  # right of row-index column
	var cell_width := CELL_W
	var cluster_gap := CLUSTER_GAP
	var x := base - col * cell_width
	# Add gap after every 2nd column
	x -= int(col / 2) * cluster_gap
	return x

# ═══════════════════════════════════════════════════════════════════════
# TOUCH AREAS
# ═══════════════════════════════════════════════════════════════════════

func _create_touch_area(cell_label: Label3D, row: int, col: int) -> Area3D:
	var area := Area3D.new()
	area.name = "Touch_%d_%d" % [row, col]
	area.collision_layer = 0
	area.collision_mask = 393216  # VR hand layers (18+19)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.22, 0.12, 0.04)
	shape.shape = box
	area.add_child(shape)

	cell_label.add_child(area)
	area.position = Vector3(0, 0, 0.02)

	# Connect touch signal
	area.body_entered.connect(_on_cell_touched.bind(row, col))
	return area

func _on_cell_touched(_body: Node3D, row: int, col: int) -> void:
	var cell: Label3D = _cells[row][col]
	if cell.text.is_empty():
		return
	# Toggle freeze state
	var is_frozen: bool = _frozen[row][col]
	_frozen[row][col] = not is_frozen
	# A selected number occupies its row address, even if touched mid-slide.
	cell.position.y = _row_y(row)
	_stream_moves = _stream_moves.filter(func(move: Dictionary) -> bool: return move.row != row or move.col != col)
	_update_cell_visual(row, col)

func _update_cell_visual(row: int, col: int) -> void:
	var label: Label3D = _cells[row][col]
	if _frozen[row][col]:
		label.modulate = COLOR_FROZEN
		label.outline_modulate = COLOR_FROZEN_OUTLINE
		label.outline_size = 5
	else:
		label.modulate = COLOR_NORMAL
		label.outline_modulate = Color(0, 0, 0, 0)
		label.outline_size = 3

# ═══════════════════════════════════════════════════════════════════════
# CASCADE LOGIC
# ═══════════════════════════════════════════════════════════════════════

func _cascade_step() -> void:
	if row_stream and not _pinned:
		_stream_step()
		return
	## Shift numbers down one row per column. Frozen cells stay put.
	## New random number appears at top of each column.
	for col in range(_built_cols):
		# Walk bottom-up: move non-frozen values down into non-frozen slots
		# First, collect the column values and frozen state
		var values: Array[String] = []
		var frozen_flags: Array[bool] = []
		for row in range(_built_rows):
			values.append((_cells[row][col] as Label3D).text)
			frozen_flags.append(_frozen[row][col])

		# Build new column: frozen cells keep their value and position,
		# non-frozen cells shift down (bottom falls off, top gets new random)
		var flowing: Array[String] = []
		for row in range(_built_rows):
			if not frozen_flags[row]:
				flowing.append(values[row])

		# New number enters at top, bottom value falls off
		flowing.insert(0, _five_digits())
		if flowing.size() > 1:
			flowing.pop_back()  # Drop the bottom-most flowing value

		# Re-distribute flowing values into non-frozen slots
		var flow_idx := 0
		for row in range(_built_rows):
			if not frozen_flags[row]:
				if flow_idx < flowing.size():
					(_cells[row][col] as Label3D).text = flowing[flow_idx]
					flow_idx += 1


## One new row per cadence. Values descend into free row addresses; amber
## selections remain in place. Pinned/seeded printed pages never use this path.
func _stream_step() -> void:
	_stream_moves.clear()
	_stream_elapsed = 0.0
	_stream_duration = minf(0.9, 0.55 / maxf(0.05, cascade_speed))
	for col in range(_built_cols):
		var free_rows: Array[int] = []
		for row in range(_built_rows):
			if not _frozen[row][col]: free_rows.append(row)
		# Bottom-up preserves each source until its destination has read it.
		for i in range(free_rows.size() - 1, -1, -1):
			var row: int = free_rows[i]
			var cell: Label3D = _cells[row][col]
			var source_row: int = free_rows[i - 1] if i > 0 else -1
			cell.text = (_cells[source_row][col] as Label3D).text if i > 0 else _five_digits()
			var destination: float = _row_y(row)
			cell.position.y = destination
			if cell.text.is_empty(): continue
			# Fade into view at the top, or after skipping a held address.
			# Do not slide a moving label through a selected amber number.
			var fade: bool = source_row < 0 or row - source_row > 1
			var origin: float = destination if fade else _row_y(source_row)
			cell.position.y = origin
			cell.modulate = Color(0, 0, 0, 0.0 if fade else 1.0)
			_stream_moves.append({"row":row,"col":col,"from_y":origin,"to_y":destination,"fade":fade})
	if _rung() == 1: _build_page_furniture() # Keep live frequency counts current.


func _advance_stream(delta: float) -> void:
	if _stream_moves.is_empty(): return
	_stream_elapsed += maxf(0.0, delta)
	var progress: float = clampf(_stream_elapsed / _stream_duration, 0.0, 1.0)
	var eased: float = progress * progress * (3.0 - 2.0 * progress)
	for move in _stream_moves:
		var cell: Label3D = _cells[move.row][move.col]
		cell.position.y = lerpf(move.from_y, move.to_y, eased)
		if move.fade: cell.modulate.a = eased
	if progress >= 1.0: _stream_moves.clear()

# ═══════════════════════════════════════════════════════════════════════
# THE APPARATUS — what the page admits, printed
# ═══════════════════════════════════════════════════════════════════════

## The running head (title / book / subtitle) and the folio. These are .tscn
## nodes, so the axis dims them rather than building them.
##
## layers = 0, NOT visible = false. Two of these labels are leaf nodes today and
## one is not guaranteed to stay that way; hiding a node hides its whole subtree,
## and a hidden subtree is how an axis silently deletes something it never meant
## to touch. Zeroing the visual layers takes the node out of every camera and
## leaves the tree exactly as it was.
func _apply_head_visibility() -> void:
	var r: int = _rung()
	_set_visual_layers(get_node_or_null("Label3D_Title"), r >= 3)
	_set_visual_layers(get_node_or_null("Label3D_BookInfo"), r >= 3)
	_set_visual_layers(get_node_or_null("Label3D_BookSubtitle"), r >= 3)
	_set_visual_layers(get_node_or_null("Label3D_Side_Number"), r >= 2)


func _set_visual_layers(n: Node, shown: bool) -> void:
	if n == null or not (n is VisualInstance3D):
		return
	(n as VisualInstance3D).layers = 1 if shown else 0


## The foot band. Carries the frequency chart at `tally`, the imprint block at
## `origin`, and nothing at the three rungs between — including `works`, which
## has to stay the legacy page.
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
		_build_frequency_chart()
	else:
		_build_imprint_block()


## A rectangle of ink on the sheet. Unshaded so it reads as printing rather than
## as an object lying on paper, and double-sided so it survives whichever way the
## page has been turned.
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


## A line of printing on the sheet, set the same way as the numerals (mirrored
## with the rest of the page, so it turns with it).
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
	l.rotate(Vector3(0, 1, 0), PI)
	_page_furniture.add_child(l)


## disclosure:tally — the aggregate, and only the aggregate. Ten bars counted off
## this page's own numerals over a ruled baseline. Uniformity is the one thing a
## table of random digits can prove about itself without telling you anything
## about where it came from, which is exactly why it sits on the rung below the
## line numbers rather than above them.
func _build_frequency_chart() -> void:
	var counts: Array[int] = []
	for i in range(10):
		counts.append(0)
	var total: int = 0
	for row in range(_built_rows):
		for col in range(_built_cols):
			var s: String = (_cells[row][col] as Label3D).text
			for ci in range(s.length()):
				var d: int = s.unicode_at(ci) - 48
				if d >= 0 and d <= 9:
					counts[d] += 1
					total += 1
	var peak: int = 1
	for c in counts:
		peak = maxi(peak, c)

	var baseline: float = -2.72
	var max_h: float = 1.85
	var pitch: float = 0.34
	var bar_w: float = 0.26
	var x0: float = -pitch * 4.5

	_print_line("DIGIT FREQUENCY - %d NUMERALS ON THIS PAGE" % total, 0.1, baseline + max_h + 0.16, 14)
	for d in range(10):
		var h: float = maxf(0.03, max_h * float(counts[d]) / float(peak))
		var cx: float = x0 + pitch * float(d)
		_ink(cx, baseline + h * 0.5, bar_w, h)
		_print_line(str(d), cx, baseline - 0.14, 15)
	# The rule the bars stand on — a chart without a baseline is a smear.
	_ink(0.0, baseline - 0.012, 3.5, 0.016)


## disclosure:origin — the imprint. Method, correction, and this page's exact
## position in the million: the three facts that make the book a record of an
## experiment rather than a bag of numerals. Boxed, because an imprint is a
## block on a page and not a footnote.
func _build_imprint_block() -> void:
	var top: float = -2.46
	var bot: float = -2.94
	var left: float = -1.72
	var right: float = 1.72
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

	_print_line("ELECTRONIC ROULETTE WHEEL - PULSE COUNT MOD 32 - 1947", 0.25, cy + 0.09, 13)
	_print_line("CORRECTED FOR BIAS 1948 - LINES %d-%d OF 1000000" % [
		start_index, start_index + maxi(0, _built_rows - 1)], 0.25, cy - 0.06, 13)
	var seed_line: String = "SEED NOT RECORDED"
	if page_seed >= 0:
		seed_line = "SEED %d" % page_seed
	_print_line(seed_line, 0.25, cy - 0.19, 12)


# ═══════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═══════════════════════════════════════════════════════════════════════

## LATENT BUG PAID as part of this promotion: this method was `pass`. Every
## `#token: value` a map put on a random_number_book_page_1955 placement was
## parsed, logged by GridInteractablesComponent, stashed as metadata — and then
## discarded, because nothing here ever read it back. A registry block derived
## from a file that ignores its own configuration is a declaration that lies.
##
## THE EARLY RETURNS ARE LOAD-BEARING. curation_station.gd:367 calls
## apply_grid_config({"emissive": false}) on everything it curates, one line
## after it has finished framing the labels; that dict carries no disclosure key,
## and an unconditional rebuild there would throw the framing away. Unchanged
## rung means touch nothing.
func apply_grid_config(config: Dictionary) -> void:
	var before: String = disclosure
	var stream_before: bool = row_stream
	var initial_before: int = initial_rows
	var page_before: int = page_number
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()
	if not _built:
		return                       # nothing built yet; _ready will use these values
	if page_before != page_number:
		_update_page_address()
		_build_page_furniture() # Preserve digits, held cells and generator state.
	if disclosure == before and stream_before == row_stream and initial_before == initial_rows:
		return                       # curation_station's {"emissive": false} lands here
	_reprint()


## Strip the sheet back to the scene's own paper and set it again. Only the nodes
## this script added are freed; the QuadMesh, the running head and the folio are
## .tscn nodes and are dimmed, never destroyed.
func _reprint() -> void:
	_ensure_select_sign()
	_stream_moves.clear()
	_stream_elapsed = 0.0
	_cascade_timer = 1.0 if row_stream and not _pinned and initial_rows == 0 else 0.0
	for n in _owned:
		if is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_owned.clear()
	_page_furniture = null
	_cells.clear()
	_frozen.clear()
	_cell_areas.clear()
	_apply_head_visibility()
	_create_cell_grid()
	_build_page_furniture()


func _read_meta_overrides() -> void:
	if has_meta("config_row_stream"):
		row_stream = str(get_meta("config_row_stream")).to_lower() == "true"
	if has_meta("config_initial_rows"):
		initial_rows = clampi(int(str(get_meta("config_initial_rows"))),0,100)
	if has_meta("config_cascade_speed"):
		var speed_text: String = str(get_meta("config_cascade_speed"))
		if speed_text.is_valid_float():
			var requested: float = float(speed_text)
			if is_finite(requested): cascade_speed = clampf(requested, 0.05, 10.0)
	if has_meta("config_disclosure"):
		# Read through the family's one reader, so a typo falls back to the legacy
		# page rather than quietly stripping ten rooms' worth of attribution.
		disclosure = Disclosure.disclosure_name(str(get_meta("config_disclosure")))
	if has_meta("config_page_seed"):
		page_seed = int(str(get_meta("config_page_seed")))
	if has_meta("config_page_number"):
		page_number = maxi(1, int(str(get_meta("config_page_number"))))
	if has_meta("config_page_yaw_deg"):
		page_yaw_deg = float(str(get_meta("config_page_yaw_deg")))
