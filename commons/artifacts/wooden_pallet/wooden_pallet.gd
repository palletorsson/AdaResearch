extends Node3D
class_name WoodenPallet

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: a standard block/EUR shipping pallet with cardboard cartons stacked on its deck — the logistics-warehouse vocabulary for "this stuff is MID-JOURNEY, palletised, waiting to move". A slatted pale-timber platform (six deck boards with finger-gaps, stringer blocks lifting it off the floor to leave forklift slots on every side) carrying light kraft cardboard boxes sealed with tape, marked FRAGILE in red, this-way-up arrows in black, a barcode and a small yellow shipping label. The warehouse's confession that everything is FREIGHT before it is a thing — boxed, labelled, lifted, and bound for somewhere else.
# desire: every loaded pallet wants to read as a UNIT OF TRANSIT — one liftable, stackable, addressable parcel of the world. It wants the timber to say "lift me here, by the forks" and the boxes to say "handle me thus, send me there". The pallet wants to be the smallest legible quantum of supply: not a box, not a crate, but the standardised slab on which commerce agrees to move.
# critical_parameter: box_arrangement — "single" reads as "one parcel, lightly loaded, a sample shipment"; "pair" reads as "two side-by-side, a balanced base course, a half-load"; "pyramid" reads as "2 + 1 stacked = a built load, the reference Setup C, freight assembled and ready to shrink-wrap". Same pallet, three different stages of being loaded — empty-ish, courses laid, load topped out.
# triggers: _ready() builds slatted top deck + bottom deck boards + stringer blocks + the box stack (1, 2, or 2+1 per box_arrangement) with tape seams, FRAGILE strip, this-way-up arrows, barcode, and shipping label when show_decals=true; apply_grid_config rebuilds
# emerges: single + no decals = "blank stock, awaiting marking"; pair + decals = "a base course, marked, mid-pack"; pyramid + decals = "topped-out load, fully marked, ready to ship"; many deck boards reads as a denser, sturdier EUR deck; the box_arrangement + show_decals combination tells the player WHERE IN THE PACKING PROCESS this freight is.
# needs: slatted top deck of deck_board_count boards with finger-gaps between them, origin at deck bottom y=0 [present]; a few bottom deck boards for the block-pallet underside [present]; stringer/foot blocks between top and bottom decks leaving forklift gaps on the sides [present]; cardboard boxes stacked upward per box_arrangement [present]; packing-tape seam down each box [present]; FRAGILE red vertical tape strip, this-way-up arrow pictograms, barcode, and yellow shipping label as decals at default rotation facing +Z [present]
# relationships: sibling to crate (both are FREIGHT vessels — the crate is the hard reusable shell, the pallet is the soft standardised base; a crate often RIDES a pallet); cousin to conveyor_belt (the belt MOVES individual parcels, the pallet BUNDLES them for the forklift — different scales of the same flow); peer to floor_grate (both are walked-over industrial decks, but the grate is fixed to the building and the pallet is the building's mobile counterpart)
# truth: a wooden pallet is not just a platform. It is the WORLD'S UNIT OF AGREEMENT ABOUT MOVEMENT — a shared module that lets any forklift anywhere lift any goods, so long as they consent to the deck's dimensions. The boxes on top are particular; the pallet under them is universal. Loading a pallet is the act of translating something specific into something SHIPPABLE, and shippability is the freight's true confession that it was always meant to leave.

## A wooden block/EUR shipping pallet carrying cardboard boxes.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER of
## the pallet — the pallet's lowest face sits on y=0, centred in X and Z.
## Length runs along X, width along Z, height grows upward (+Y). Boxes
## stack on the top deck and grow upward in +Y. The "interesting" marked
## faces (FRAGILE strip, arrows, barcode, label) face +Z / +X toward the
## 3/4 capture camera.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Pallet")
@export var pallet_length: float = 1.2
@export var pallet_width: float = 0.8
@export var pallet_height: float = 0.144
@export_range(2, 12, 1) var deck_board_count: int = 6
@export var wood_color: Color = Color(0.74, 0.62, 0.45)

@export_group("Boxes")
@export var box_arrangement: String = "pyramid"
@export var box_w: float = 0.5
@export var box_h: float = 0.5
@export var box_d: float = 0.5
@export var box_color: Color = Color(0.80, 0.78, 0.73)

@export_group("Decals")
@export var tape_color: Color = Color(0.85, 0.18, 0.18)
@export var label_color: Color = Color(0.95, 0.90, 0.55)
@export var show_decals: bool = true

# ── Constants ─────────────────────────────────────────────────────────

const TOP_DECK_THICKNESS: float = 0.022    # thickness of each top deck board
const BOTTOM_DECK_THICKNESS: float = 0.022 # thickness of each bottom deck board
const BOTTOM_DECK_COUNT: int = 3           # bottom boards (block-pallet underside)
const BLOCK_INSET: float = 0.04            # stringer-block inset from pallet edges
const FOOT_COLUMNS: int = 3                # 3 rows of feet along X (left/center/right)
const FOOT_ROWS: int = 3                   # 3 feet across Z per row
const TAPE_SEAM_WIDTH: float = 0.03
const TAPE_SEAM_DEPTH: float = 0.004
const FRAGILE_STRIP_WIDTH: float = 0.07
const FRAGILE_STRIP_DEPTH: float = 0.004
const ARROW_PANEL_SIZE: float = 0.10
const ARROW_PANEL_DEPTH: float = 0.004
const BARCODE_WIDTH: float = 0.12
const BARCODE_HEIGHT: float = 0.06
const BARCODE_DEPTH: float = 0.004
const BARCODE_BARS: int = 11
const LABEL_W: float = 0.13
const LABEL_H: float = 0.085
const LABEL_DEPTH: float = 0.004
# LABEL_PIXEL_SIZE / LABEL_FONT_SIZE removed — Label3Ds replaced by BakedText quads.

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_pallet()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_pallet()


func _read_metadata_overrides() -> void:
	if has_meta("config_pallet_length"):
		pallet_length = float(str(get_meta("config_pallet_length")))
	if has_meta("config_pallet_width"):
		pallet_width = float(str(get_meta("config_pallet_width")))
	if has_meta("config_pallet_height"):
		pallet_height = float(str(get_meta("config_pallet_height")))
	if has_meta("config_deck_board_count"):
		deck_board_count = int(str(get_meta("config_deck_board_count")))
	if has_meta("config_wood_color"):
		wood_color = _parse_color(str(get_meta("config_wood_color")), wood_color)
	if has_meta("config_box_arrangement"):
		box_arrangement = str(get_meta("config_box_arrangement"))
	if has_meta("config_box_w"):
		box_w = float(str(get_meta("config_box_w")))
	if has_meta("config_box_h"):
		box_h = float(str(get_meta("config_box_h")))
	if has_meta("config_box_d"):
		box_d = float(str(get_meta("config_box_d")))
	if has_meta("config_box_color"):
		box_color = _parse_color(str(get_meta("config_box_color")), box_color)
	if has_meta("config_tape_color"):
		tape_color = _parse_color(str(get_meta("config_tape_color")), tape_color)
	if has_meta("config_label_color"):
		label_color = _parse_color(str(get_meta("config_label_color")), label_color)
	if has_meta("config_show_decals"):
		show_decals = str(get_meta("config_show_decals")).to_lower() in ["true", "1", "yes", "on"]


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_pallet() -> void:
	_built = true
	_build_bottom_deck()
	_build_feet()
	_build_top_deck()
	_build_boxes()


func _wood_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = wood_color
	mat.roughness = 0.85
	mat.metallic = 0.0
	return mat


func _deck_top_y() -> float:
	# Y of the top surface of the top deck (where boxes rest).
	return pallet_height


func _build_bottom_deck() -> void:
	# A few bottom deck boards running along X (full length), spaced across Z.
	var root := Node3D.new()
	root.name = "BottomDeck"
	add_child(root)
	var mat := _wood_material()

	var board_w: float = pallet_width * 0.16
	var y: float = BOTTOM_DECK_THICKNESS * 0.5
	for i in range(BOTTOM_DECK_COUNT):
		var board := MeshInstance3D.new()
		board.name = "BottomBoard_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(pallet_length, BOTTOM_DECK_THICKNESS, board_w)
		board.mesh = bm
		board.material_override = mat
		var z: float
		if BOTTOM_DECK_COUNT > 1:
			var t: float = float(i) / float(BOTTOM_DECK_COUNT - 1)
			z = lerp(-pallet_width * 0.5 + board_w * 0.5, pallet_width * 0.5 - board_w * 0.5, t)
		else:
			z = 0.0
		board.position = Vector3(0.0, y, z)
		root.add_child(board)


func _build_feet() -> void:
	# Stringer / foot blocks lifting the top deck off the bottom deck, arranged
	# in a 3×3 grid so forklift gaps remain open on all four sides.
	var root := Node3D.new()
	root.name = "Feet"
	add_child(root)
	var mat := _wood_material()

	var foot_h: float = pallet_height - TOP_DECK_THICKNESS - BOTTOM_DECK_THICKNESS
	if foot_h < 0.01:
		foot_h = 0.01
	var y: float = BOTTOM_DECK_THICKNESS + foot_h * 0.5
	var foot_size: float = 0.09

	var span_x: float = pallet_length * 0.5 - BLOCK_INSET - foot_size * 0.5
	var span_z: float = pallet_width * 0.5 - BLOCK_INSET - foot_size * 0.5

	for cx in range(FOOT_COLUMNS):
		for cz in range(FOOT_ROWS):
			var foot := MeshInstance3D.new()
			foot.name = "Foot_%d_%d" % [cx, cz]
			var bm := BoxMesh.new()
			bm.size = Vector3(foot_size, foot_h, foot_size)
			foot.mesh = bm
			foot.material_override = mat
			var fx: float = 0.0
			var fz: float = 0.0
			if FOOT_COLUMNS > 1:
				fx = lerp(-span_x, span_x, float(cx) / float(FOOT_COLUMNS - 1))
			if FOOT_ROWS > 1:
				fz = lerp(-span_z, span_z, float(cz) / float(FOOT_ROWS - 1))
			foot.position = Vector3(fx, y, fz)
			root.add_child(foot)


func _build_top_deck() -> void:
	# Slatted top deck: deck_board_count boards running along Z (full width),
	# spaced across X with small finger-gaps between them.
	var root := Node3D.new()
	root.name = "TopDeck"
	add_child(root)
	var mat := _wood_material()

	var n: int = deck_board_count
	if n < 1:
		n = 1
	# Boards fill the length with a gap fraction between them.
	var gap_frac: float = 0.18
	var board_len: float = pallet_length / (float(n) + (float(n) - 1.0) * gap_frac)
	var gap: float = board_len * gap_frac
	var pitch: float = board_len + gap
	var start_x: float = -pallet_length * 0.5 + board_len * 0.5
	var y: float = pallet_height - TOP_DECK_THICKNESS * 0.5

	for i in range(n):
		var board := MeshInstance3D.new()
		board.name = "TopBoard_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(board_len, TOP_DECK_THICKNESS, pallet_width)
		board.mesh = bm
		board.material_override = mat
		var x: float = start_x + pitch * float(i)
		board.position = Vector3(x, y, 0.0)
		root.add_child(board)


# ── Boxes ─────────────────────────────────────────────────────────────

func _box_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = box_color
	mat.roughness = 0.92
	mat.metallic = 0.0
	return mat


func _build_boxes() -> void:
	var root := Node3D.new()
	root.name = "Boxes"
	add_child(root)

	var deck_y: float = _deck_top_y()
	# How far apart the two base boxes sit along X (centres), used by pair/pyramid.
	var base_gap: float = 0.02
	var base_off: float = (box_w + base_gap) * 0.5

	match box_arrangement:
		"single":
			_make_box(root, Vector3(0.0, deck_y + box_h * 0.5, 0.0), true)
		"pair":
			_make_box(root, Vector3(-base_off, deck_y + box_h * 0.5, 0.0), true)
			_make_box(root, Vector3(base_off, deck_y + box_h * 0.5, 0.0), true)
		_: # "pyramid" (and any unknown value) → 2 base + 1 on top
			_make_box(root, Vector3(-base_off, deck_y + box_h * 0.5, 0.0), true)
			_make_box(root, Vector3(base_off, deck_y + box_h * 0.5, 0.0), true)
			_make_box(root, Vector3(0.0, deck_y + box_h * 1.5, 0.0), true)


func _make_box(parent: Node3D, center: Vector3, decorate: bool) -> void:
	# A box is a Node3D at `center`; its faces are at ±box_w/2 (X), ±box_h/2 (Y),
	# ±box_d/2 (Z) in local space. Decals are parented so the front face is +Z.
	var box_root := Node3D.new()
	box_root.name = "Box"
	box_root.position = center
	parent.add_child(box_root)

	var body := MeshInstance3D.new()
	body.name = "Carton"
	var bm := BoxMesh.new()
	bm.size = Vector3(box_w, box_h, box_d)
	body.mesh = bm
	body.material_override = _box_material()
	box_root.add_child(body)

	# Packing-tape seam across the top, running along X (the "lid" seam).
	var seam := MeshInstance3D.new()
	seam.name = "TapeSeam"
	var sm := BoxMesh.new()
	sm.size = Vector3(box_w * 1.001, TAPE_SEAM_DEPTH, TAPE_SEAM_WIDTH)
	seam.mesh = sm
	var seam_mat := StandardMaterial3D.new()
	seam_mat.albedo_color = Color(0.78, 0.70, 0.55)  # kraft packing tape, slightly glossy
	seam_mat.roughness = 0.5
	seam_mat.metallic = 0.0
	seam.material_override = seam_mat
	seam.position = Vector3(0.0, box_h * 0.5 + TAPE_SEAM_DEPTH * 0.5, 0.0)
	box_root.add_child(seam)

	# Vertical tape seam down the front face (+Z), where cardboard flaps meet.
	var vseam := MeshInstance3D.new()
	vseam.name = "TapeSeamFront"
	var vsm := BoxMesh.new()
	vsm.size = Vector3(TAPE_SEAM_WIDTH, box_h * 1.001, TAPE_SEAM_DEPTH)
	vseam.mesh = vsm
	vseam.material_override = seam_mat
	vseam.position = Vector3(0.0, 0.0, box_d * 0.5 + TAPE_SEAM_DEPTH * 0.5)
	box_root.add_child(vseam)

	if decorate and show_decals:
		_decorate_front(box_root)


func _decorate_front(box_root: Node3D) -> void:
	# All decals live on the +Z front face (toward the capture camera) and the
	# +X right face, slightly proud of the carton surface.
	var fz: float = box_d * 0.5 + 0.002

	# 1) Red FRAGILE vertical tape strip on the left of the front face.
	var strip := MeshInstance3D.new()
	strip.name = "FragileStrip"
	var stm := BoxMesh.new()
	stm.size = Vector3(FRAGILE_STRIP_WIDTH, box_h * 0.9, FRAGILE_STRIP_DEPTH)
	strip.mesh = stm
	var strip_mat := StandardMaterial3D.new()
	strip_mat.albedo_color = tape_color
	strip_mat.roughness = 0.45
	strip_mat.metallic = 0.0
	strip.material_override = strip_mat
	strip.position = Vector3(-box_w * 0.30, 0.0, fz)
	box_root.add_child(strip)

	# FRAGILE text baked onto the red strip — rotated 90° about Z so it reads
	# vertically, still facing +Z.  world_size matches the tape: strip height as
	# the "width" dimension, strip width as the "height" dimension (we rotate the
	# quad so they swap visually).
	var frag: MeshInstance3D = BakedText.make_label_mesh(
		"FRAGILE",
		Color(0.98, 0.97, 0.95),
		Vector2(box_h * 0.9, FRAGILE_STRIP_WIDTH)
	)
	if frag:
		frag.name = "FragileText"
		frag.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))  # vertical text, still faces +Z
		frag.position = Vector3(-box_w * 0.30, 0.0, fz + FRAGILE_STRIP_DEPTH + 0.001)
		box_root.add_child(frag)

	# 2) Two "this way up" pictogram squares (black border, white field, ↑) stacked
	#    on the right of the front face.
	var arrow_x: float = box_w * 0.22
	for i in range(2):
		var ay: float = box_h * 0.16 - float(i) * (ARROW_PANEL_SIZE + 0.02)
		_make_arrow_panel(box_root, Vector3(arrow_x, ay, fz))

	# 3) Barcode (white field with thin black vertical bars) lower-left of front.
	_make_barcode(box_root, Vector3(-box_w * 0.04, -box_h * 0.30, fz))

	# 4) Small pale-yellow shipping label, lower-right of front.
	_make_shipping_label(box_root, Vector3(box_w * 0.24, -box_h * 0.30, fz))


func _make_arrow_panel(box_root: Node3D, pos: Vector3) -> void:
	# White square panel with a black border and an upward arrow (↑) glyph.
	var panel := MeshInstance3D.new()
	panel.name = "ArrowPanel"
	var pm := BoxMesh.new()
	pm.size = Vector3(ARROW_PANEL_SIZE, ARROW_PANEL_SIZE, ARROW_PANEL_DEPTH)
	panel.mesh = pm
	var white_mat := StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.95, 0.95, 0.93)
	white_mat.roughness = 0.6
	white_mat.metallic = 0.0
	panel.material_override = white_mat
	panel.position = pos
	box_root.add_child(panel)

	# Black border frame (thin box slightly larger, behind the white field).
	var border := MeshInstance3D.new()
	border.name = "ArrowBorder"
	var brm := BoxMesh.new()
	brm.size = Vector3(ARROW_PANEL_SIZE * 1.16, ARROW_PANEL_SIZE * 1.16, ARROW_PANEL_DEPTH * 0.5)
	border.mesh = brm
	var black_mat := StandardMaterial3D.new()
	black_mat.albedo_color = Color(0.08, 0.08, 0.08)
	black_mat.roughness = 0.6
	black_mat.metallic = 0.0
	border.material_override = black_mat
	border.position = pos - Vector3(0.0, 0.0, ARROW_PANEL_DEPTH * 0.3)
	box_root.add_child(border)

	# Up-arrow glyph baked onto the arrow panel, facing +Z.
	var glyph: MeshInstance3D = BakedText.make_label_mesh(
		"↑↑",
		Color(0.08, 0.08, 0.08),
		Vector2(ARROW_PANEL_SIZE, ARROW_PANEL_SIZE)
	)
	if glyph:
		glyph.name = "ArrowGlyph"
		glyph.position = pos + Vector3(0.0, 0.0, ARROW_PANEL_DEPTH * 0.5 + 0.001)
		box_root.add_child(glyph)


func _make_barcode(box_root: Node3D, pos: Vector3) -> void:
	# White field with a set of thin black vertical bars of varying width.
	var field := MeshInstance3D.new()
	field.name = "BarcodeField"
	var fm := BoxMesh.new()
	fm.size = Vector3(BARCODE_WIDTH, BARCODE_HEIGHT, BARCODE_DEPTH)
	field.mesh = fm
	var white_mat := StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.96, 0.96, 0.95)
	white_mat.roughness = 0.55
	white_mat.metallic = 0.0
	field.material_override = white_mat
	field.position = pos
	box_root.add_child(field)

	var black_mat := StandardMaterial3D.new()
	black_mat.albedo_color = Color(0.06, 0.06, 0.06)
	black_mat.roughness = 0.55
	black_mat.metallic = 0.0

	# Deterministic pseudo-random bar widths from a fixed seed for a stable look.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var inner_w: float = BARCODE_WIDTH * 0.88
	var x: float = pos.x - inner_w * 0.5
	var bar_z: float = pos.z + BARCODE_DEPTH * 0.5 + 0.001
	var slot: float = inner_w / float(BARCODE_BARS)
	for i in range(BARCODE_BARS):
		# Roughly alternate bar/space, varying bar thickness.
		var bw: float = slot * (0.25 + rng.randf() * 0.45)
		var bar := MeshInstance3D.new()
		bar.name = "Bar_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(bw, BARCODE_HEIGHT * 0.82, BARCODE_DEPTH * 0.6)
		bar.mesh = bm
		bar.material_override = black_mat
		bar.position = Vector3(x + slot * float(i) + slot * 0.5, pos.y, bar_z)
		box_root.add_child(bar)


func _make_shipping_label(box_root: Node3D, pos: Vector3) -> void:
	# Small pale-yellow label panel — baked text (bg + text) replaces the
	# separate coloured-box + Label3D pair with one textured quad.
	var panel: MeshInstance3D = BakedText.make_panel_mesh(
		"SHIP TO\nADA-46",
		label_color,
		Color(0.10, 0.10, 0.12),
		Vector2(LABEL_W, LABEL_H)
	)
	if panel:
		panel.name = "ShippingLabel"
		panel.position = pos + Vector3(0.0, 0.0, LABEL_DEPTH * 0.5)
		box_root.add_child(panel)


# ── Helpers ───────────────────────────────────────────────────────────

func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)
