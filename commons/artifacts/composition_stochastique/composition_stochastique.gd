# @identity
# essence: four ten-by-ten grids of one diagonal in which exactly 1, 5, 30 and 50 cells carry the other diagonal, after François and Vera Molnar's Composition Stochastique (1959)
# desire: that someone walks the row, finds the grid still reading as parallel lines at one and at five, cannot say at which count between five and thirty it stopped, then presses RESEED and watches every position move while every count holds
# critical_parameter: turned — series / one / five / thirty / fifty. The count is the only thing that differs between the grids, and it is DEALT, never rolled per cell
# triggers: _ready builds board, grids, captions, plate and the RESEED panel synchronously; RESEED advances a draw counter from the seed and rebuilds only the stroke meshes
# emerges: the count at which order stops reading as order. That threshold is in the visitor; the code only ever knows 1, 5, 30 and 50
# needs: commons/ui/text_screen.gd for every word [present]; the RackTemplates push button, the one press both hands reach [present]
# relationships: near kin to ten_print_toy and ten_print_bench (the same two diagonals, chosen per cell by a coin, where here a count chooses); the button wiring is shannon_entropy_meter's
# truth: a probability and a count are different instruments. A 30 percent chance per cell turns exactly thirty of a hundred cells about one time in eleven; a shuffle of the hundred indices with the first thirty taken turns thirty every time. These grids are dealt, not flipped, so the only thing chance decides here is WHERE.

extends Node3D
class_name CompositionStochastique

## Every visible word goes through the canonical screen. Label3D and a bare
## make_label_mesh do not reach a capture; text_screen does (serial_principle
## measured this on 2026-09-09). A differently named const, so the global
## class_name TextScreen is never shadowed.
const TEXT_SCREEN := preload("res://commons/ui/text_screen.gd")
## Loaded, not preloaded, exactly as shannon_entropy_meter does it: the panel is a
## convenience, and a parse failure in RackTemplates must not take the grids down.
const RACK_TEMPLATES_PATH := "res://commons/audio/rack_templates/RackTemplates.gd"

const SIDE: int = 10
const CELLS: int = 100
## The four counts on p. 80 of the chapter: 1, 5, 30 and 50 percent of a
## hundred-cell grid, which is exactly 1, 5, 30 and 50 cells.
const COUNTS: Array[int] = [1, 5, 30, 50]
## The word for each count, in the same order. `turned` takes WORDS, never
## digits: `turned` is not in GridInteractablesComponent.CONFIG_PARAM_NAMES, so
## `#turned:30` would be read as the tutorial's rotation shorthand and arrive as
## the boolean true.
const WORDS: Array[String] = ["one", "five", "thirty", "fifty"]
## Draw d is dealt from seed + d * DRAW_STRIDE. RandomNumberGenerator hashes its
## seed, so neighbouring integers give unrelated streams; the stride only keeps
## two draws of nearby seeds from ever sharing an integer.
const DRAW_STRIDE: int = 1000003

# ── layout (metres). The plate's bottom edge is the anchor and the stack grows
# upward from it, so a larger `cell_size` raises the grids instead of pushing
# the plate into the floor.
const PLATE_W: float = 0.74
const CAPTION_W: float = 0.20
const PLATE_BOTTOM: float = 0.60
const PLATE_TO_CAPTION: float = 0.035
const CAPTION_TO_GRID: float = 0.03
const BOARD_MARGIN: float = 0.07
const BOARD_T: float = 0.03
const EDGE: float = 0.012
const INK_LIFT: float = 0.0015
## text_screen's frame reaches 14 mm behind its own origin; 15 mm keeps it proud
## of the board face instead of buried in it.
const TEXT_LIFT: float = 0.015
const PANEL_SCALE: float = 1.4
const PANEL_GAP: float = 0.07
## RackTemplates' one-button panel is 0.092 m wide before scale. Used only to
## size the board before the panel exists; the panel is placed by its real width.
const PANEL_W_EST: float = 0.13
const LEG_W: float = 0.04
const LEG_INSET: float = 0.16
## The dark reveal is BOARD_T * 0.6 deep, centred on the board's back face, so the
## rearmost board geometry is the reveal's back at -(BOARD_T*0.5 + BOARD_T*0.3).
## The legs stand flush against it. (EDGE is the reveal's margin in x and y, not
## its depth: using it here once left a 3 mm gap and a board hanging in front of
## its own legs.)
const REVEAL_D: float = BOARD_T * 0.6
const BOARD_BACK_Z: float = -BOARD_T * 0.5 - REVEAL_D * 0.5
const LEG_Z: float = BOARD_BACK_Z - LEG_W * 0.5
const FOOT_SIZE := Vector3(0.07, 0.03, 0.42)
const FOOT_Z: float = -0.05

const BOARD_COLOR := Color(0.90, 0.89, 0.85)
const EDGE_COLOR := Color(0.30, 0.29, 0.27)
const INK_COLOR := Color(0.07, 0.07, 0.08)
const STAND_COLOR := Color(0.22, 0.22, 0.24)
const CAPTION_BG := Color(0.83, 0.82, 0.78)
const CAPTION_FRAME := Color(0.62, 0.61, 0.58)
const CAPTION_INK := Color(0.10, 0.10, 0.11)

## Every deal starts here. At the defaults the four grids are the same four
## pictures on every boot, which is what lets a capture be compared with a capture.
@export var seed: int = 1959
## series = all four grids side by side, in the chapter's order. The four words
## are ONE grid with that count, for a collation of single works on one wall.
## A single grid is dealt from the same order as the series, so `five` alone is
## the series' fifth-count grid, cell for cell.
@export_enum("series", "one", "five", "thirty", "fifty") var turned: String = "series"
## One cell of the ten-by-ten, in metres. 35 mm gives a 0.35 m grid: large
## enough to read as a grid from a walking distance of two metres, small enough
## that four fit on a two-metre board. Map key: `cell_size` (a listed name).
@export_range(0.02, 0.10) var cell_m: float = 0.035
## The drawn diagonal's width. 7 mm is a marker line at two metres and about two
## pixels in the sweep's frame, the thinnest that survives a still.
@export_range(0.002, 0.02) var stroke_m: float = 0.007
## Space between neighbouring grids in the series, in metres.
@export var grid_gap_m: float = 0.11
## Collision for the board, legs and feet. A free-standing board a visitor can
## walk through has not been met. Map key `solid` takes WORDS (`#solid:off`):
## `solid` is not a listed config name, so `#solid:0` would become a rotation.
@export var solid: bool = true

## True once _ready has built. The museum hands config to apply_grid_config
## BEFORE _ready; until then values are only stored, and _ready builds once.
var _built: bool = false
## How many times RESEED has been pressed since the last build.
var _draw: int = 0
## This draw's permutation of the hundred cell indices. Grid k turns the first k.
## One order for all four grids, so the series is one deal read at four depths:
## the turned cells of `one` are among those of `five`, and so on up to `fifty`.
var _order: PackedInt32Array = PackedInt32Array()
var _owned: Array[Node] = []
## count -> the MeshInstance3D holding that grid's hundred strokes
var _grids: Dictionary = {}
var _ink: StandardMaterial3D = null
var _reseed_area: Node = null

var _grid_side: float = 0.35
var _grid_y: float = 1.5
var _caption_y: float = 1.2
var _plate_y: float = 0.85
var _board_w: float = 1.9
var _board_bottom: float = 0.53
var _board_top: float = 1.74


func _ready() -> void:
	_build()
	_built = true


# ── public surface (the probe reads these; the RESEED button calls reseed) ──

## Deal again. Every count stays exact; only which cells are turned changes.
func reseed() -> void:
	_draw += 1
	_deal()
	_refresh_strokes()


func draw_index() -> int:
	return _draw


## The counts this instance is showing, left to right.
func shown_counts() -> Array[int]:
	var out: Array[int] = []
	var at: int = WORDS.find(turned)
	if at >= 0:
		out.append(COUNTS[at])
		return out
	for k in COUNTS:
		out.append(k)
	return out


## The script's own record of which cells grid k turns, sorted. A probe should
## compare this against the MESH, never trust it alone.
func turned_cells(k: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	var n: int = mini(maxi(k, 0), _order.size())
	for i in range(n):
		out.append(_order[i])
	out.sort()
	return out


# ── build ──

func _build() -> void:
	_clear()
	_measure()
	_ink = StandardMaterial3D.new()
	_ink.albedo_color = INK_COLOR
	_ink.roughness = 0.9
	_ink.metallic = 0.0
	# Winding is set clockwise in _stroke_quad; this is the belt to that brace,
	# because a wrong winding would photograph four blank boards.
	_ink.cull_mode = BaseMaterial3D.CULL_DISABLED
	_build_board()
	_deal()
	var counts: Array[int] = shown_counts()
	for i in range(counts.size()):
		var x: float = _grid_x(i, counts.size())
		_build_grid(counts[i], x)
		_build_caption(counts[i], x)
	_build_plate(counts)
	_build_reseed_panel()
	if solid:
		_build_body()


func _clear() -> void:
	# Read each entry as a Variant first: a node something else already freed must
	# be skipped, not assigned to a typed Node (which errors on a freed instance).
	for i in range(_owned.size()):
		var item: Variant = _owned[i]
		if not is_instance_valid(item):
			continue
		var node: Node = item
		if node.get_parent() == self:
			remove_child(node)
		node.queue_free()
	_owned.clear()
	_grids.clear()
	_reseed_area = null


func _own(n: Node) -> void:
	add_child(n)
	_owned.append(n)


func _measure() -> void:
	_grid_side = cell_m * float(SIDE)
	var n: int = shown_counts().size()
	var row_w: float = float(n) * _grid_side + float(n - 1) * grid_gap_m
	var bezel: float = TEXT_SCREEN.BEZEL * 2.0
	var plate_h: float = PLATE_W * TEXT_SCREEN.ASPECT + bezel
	var caption_h: float = CAPTION_W * TEXT_SCREEN.ASPECT + bezel
	_plate_y = PLATE_BOTTOM + plate_h * 0.5
	var plate_top: float = PLATE_BOTTOM + plate_h
	_caption_y = plate_top + PLATE_TO_CAPTION + caption_h * 0.5
	var caption_top: float = _caption_y + caption_h * 0.5
	_grid_y = caption_top + CAPTION_TO_GRID + _grid_side * 0.5
	_board_top = _grid_y + _grid_side * 0.5 + BOARD_MARGIN
	_board_bottom = PLATE_BOTTOM - BOARD_MARGIN
	# The RESEED panel stands right of the plate; the board stays symmetric, so a
	# single grid gets a board as wide as plate + panel on both sides.
	var control_reach: float = PLATE_W * 0.5 + TEXT_SCREEN.BEZEL + PANEL_GAP + PANEL_W_EST
	_board_w = maxf(row_w + BOARD_MARGIN * 2.0, (control_reach + BOARD_MARGIN) * 2.0)


func _grid_x(i: int, n: int) -> float:
	var row_w: float = float(n) * _grid_side + float(n - 1) * grid_gap_m
	return -row_w * 0.5 + _grid_side * 0.5 + float(i) * (_grid_side + grid_gap_m)


func _build_board() -> void:
	var board_h: float = _board_top - _board_bottom
	var mid_y: float = (_board_top + _board_bottom) * 0.5

	var board := MeshInstance3D.new()
	board.name = "Board"
	var bm := BoxMesh.new()
	bm.size = Vector3(_board_w, board_h, BOARD_T)
	board.mesh = bm
	board.material_override = _mat(BOARD_COLOR, 0.92)
	board.position = Vector3(0.0, mid_y, 0.0)
	_own(board)

	# A dark reveal behind the board, 12 mm proud on every side: it is what makes
	# a pale board read as an object against a pale wall.
	var edge := MeshInstance3D.new()
	edge.name = "BoardEdge"
	var em := BoxMesh.new()
	em.size = Vector3(_board_w + EDGE * 2.0, board_h + EDGE * 2.0, REVEAL_D)
	edge.mesh = em
	edge.material_override = _mat(EDGE_COLOR, 0.8)
	edge.position = Vector3(0.0, mid_y, -BOARD_T * 0.5)
	_own(edge)

	var leg_h: float = _board_bottom + 0.15
	for side in [-1.0, 1.0]:
		var sx: float = float(side)
		var lx: float = sx * (_board_w * 0.5 - LEG_INSET)
		var leg := MeshInstance3D.new()
		leg.name = "Leg_L" if sx < 0.0 else "Leg_R"
		var lm := BoxMesh.new()
		lm.size = Vector3(LEG_W, leg_h, LEG_W)
		leg.mesh = lm
		leg.material_override = _mat(STAND_COLOR, 0.6)
		leg.position = Vector3(lx, leg_h * 0.5, LEG_Z)
		_own(leg)

		var foot := MeshInstance3D.new()
		foot.name = "Foot_L" if sx < 0.0 else "Foot_R"
		var fm := BoxMesh.new()
		fm.size = FOOT_SIZE
		foot.mesh = fm
		foot.material_override = _mat(STAND_COLOR, 0.6)
		# origin is the base: the foot's underside sits exactly on y = 0
		foot.position = Vector3(lx, FOOT_SIZE.y * 0.5, FOOT_Z)
		_own(foot)


## One grid: a Node3D named Grid_<count> with a single MeshInstance3D "Strokes"
## holding all hundred diagonals, so a reseed swaps one mesh and nothing else.
func _build_grid(k: int, x: float) -> void:
	var g := Node3D.new()
	g.name = "Grid_%d" % k
	g.position = Vector3(x, _grid_y, BOARD_T * 0.5 + INK_LIFT)
	g.set_meta("turned_count", k)
	var mi := MeshInstance3D.new()
	mi.name = "Strokes"
	mi.mesh = _stroke_mesh(k)
	mi.material_override = _ink
	g.add_child(mi)
	_own(g)
	_grids[k] = mi


func _build_caption(k: int, x: float) -> void:
	var s: Node3D = TEXT_SCREEN.new()
	s.name = "Caption_%d" % k
	s.mode = 0                     # SCREEN: a face on the board, no stand
	s.title = ""
	s.body = "%d of 100" % k
	s.width_m = CAPTION_W
	s.bg_color = CAPTION_BG
	s.frame_color = CAPTION_FRAME
	s.body_color = CAPTION_INK
	s.title_color = CAPTION_INK
	s.position = Vector3(x, _caption_y, BOARD_T * 0.5 + TEXT_LIFT)
	_own(s)


func _build_plate(counts: Array[int]) -> void:
	var s: Node3D = TEXT_SCREEN.new()
	s.name = "Plate"
	s.mode = 0
	s.title = "COMPOSITION STOCHASTIQUE"
	s.body = _plate_body(counts)
	s.width_m = PLATE_W
	s.position = Vector3(0.0, _plate_y, BOARD_T * 0.5 + TEXT_LIFT)
	_own(s)


## Lines are laid out here, each under text_screen's 38-column wrap for a 0.74 m
## plate, so its reflow never splits a sentence in an ugly place.
func _plate_body(counts: Array[int]) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("after François and Vera Molnar, 1959")
	if counts.size() == 1:
		lines.append("%d of 100 cells turned, exactly:" % counts[0])
		lines.append("a count, not a chance per cell")
	else:
		lines.append("the same two marks; only the count")
		lines.append("of turned cells changes: 1, 5, 30, 50")
		lines.append("exact counts, not a chance per cell")
	lines.append("where does the grid stop")
	lines.append("reading as a grid?")
	return "\n".join(lines)


## RESEED, wired the way shannon_entropy_meter wires SORT / CONTRAST / DISCLOSE.
## InteractableAreaButton.button_pressed carries ONE argument, so the handler is a
## one-argument lambda: a 0-argument method connected directly is refused at every
## emit and the button is dead. The area answers a VR fingertip (body_entered) and
## the desktop pointer (pointer_event -> _on_button_entered) with the same signal.
func _build_reseed_panel() -> void:
	var rack: GDScript = load(RACK_TEMPLATES_PATH)
	if rack == null:
		return
	var panel: Node3D = rack.create_panel(" ", [
		[{"type": "button", "label": "RESEED"}],
	])
	if panel == null:
		return
	panel.name = "ReseedPanel"
	# A blank title still builds an empty Label3D; nothing on this board is a Label3D.
	var blank_title: Node = panel.get_node_or_null("Title")
	if blank_title != null:
		panel.remove_child(blank_title)
		blank_title.free()
	# the panel's button area is a hand target, not the installation's footprint
	panel.set_meta("em_local_instrument", true)
	panel.scale = Vector3.ONE * PANEL_SCALE
	var pw: float = float(panel.get_meta("panel_w", 0.092)) * PANEL_SCALE
	var ph: float = float(panel.get_meta("panel_h", 0.122)) * PANEL_SCALE
	var plate_top: float = _plate_y + (PLATE_W * TEXT_SCREEN.ASPECT) * 0.5 + TEXT_SCREEN.BEZEL
	panel.position = Vector3(PLATE_W * 0.5 + TEXT_SCREEN.BEZEL + PANEL_GAP + pw * 0.5,
		plate_top - ph * 0.5, BOARD_T * 0.5 + 0.008)
	_own(panel)
	var btn: Node = panel.find_child("Btn_0", true, false)
	if btn == null:
		return
	var area: Node = btn.get_node_or_null("InteractableAreaButton")
	if area != null and area.has_signal("button_pressed"):
		area.button_pressed.connect(func(_b): reseed())
		_reseed_area = area


## Board, legs and feet as boxes matching what is drawn. The panel's own button
## bodies are marked em_local_instrument and are not part of this.
func _build_body() -> void:
	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = 1
	body.collision_mask = 0
	_own(body)
	var board_h: float = _board_top - _board_bottom
	var mid_y: float = (_board_top + _board_bottom) * 0.5
	var back_z: float = BOARD_BACK_Z
	var front_z: float = BOARD_T * 0.5
	_add_box(body, Vector3(0.0, mid_y, (front_z + back_z) * 0.5),
		Vector3(_board_w + EDGE * 2.0, board_h + EDGE * 2.0, front_z - back_z))
	var leg_h: float = _board_bottom + 0.15
	for side in [-1.0, 1.0]:
		var lx: float = float(side) * (_board_w * 0.5 - LEG_INSET)
		_add_box(body, Vector3(lx, leg_h * 0.5, LEG_Z),
			Vector3(LEG_W, leg_h, LEG_W))
		_add_box(body, Vector3(lx, FOOT_SIZE.y * 0.5, FOOT_Z), FOOT_SIZE)


func _add_box(body: StaticBody3D, centre: Vector3, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = centre
	body.add_child(cs)


# ── the deal ──

## Fisher-Yates over the hundred indices, seeded from (seed, draw). The first k of
## the permutation are grid k's turned cells, so every count is exact by
## construction and only positions depend on chance.
func _deal() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + _draw * DRAW_STRIDE
	var order := PackedInt32Array()
	order.resize(CELLS)
	for i in range(CELLS):
		order[i] = i
	for i in range(CELLS - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var t: int = order[i]
		order[i] = order[j]
		order[j] = t
	_order = order


func _refresh_strokes() -> void:
	for key in _grids.keys():
		var mi: MeshInstance3D = _grids[key]
		if is_instance_valid(mi):
			mi.mesh = _stroke_mesh(int(key))


## Every cell carries exactly one stroke. The base diagonal rises left to right
## ("/"); a turned cell falls ("\"). Cell (row, col) with row 0 at the top.
func _stroke_mesh(k: int) -> ArrayMesh:
	var is_turned := PackedByteArray()
	is_turned.resize(CELLS)
	is_turned.fill(0)
	var n: int = mini(maxi(k, 0), _order.size())
	for i in range(n):
		is_turned[_order[i]] = 1
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var half_g: float = _grid_side * 0.5
	var h: float = cell_m * 0.5
	var hw: float = stroke_m * 0.5
	for row in range(SIDE):
		for col in range(SIDE):
			var idx: int = row * SIDE + col
			var cx: float = -half_g + (float(col) + 0.5) * cell_m
			var cy: float = half_g - (float(row) + 0.5) * cell_m
			var p0: Vector2
			var p1: Vector2
			if is_turned[idx] == 1:
				p0 = Vector2(cx - h, cy + h)
				p1 = Vector2(cx + h, cy - h)
			else:
				p0 = Vector2(cx - h, cy - h)
				p1 = Vector2(cx + h, cy + h)
			verts.append_array(_stroke_quad(p0, p1, hw))
			for _j in range(6):
				normals.append(Vector3.BACK)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Six vertices, two triangles, one stroke from p0 to p1 of half-width hw, in the
## plane z = 0 facing +Z. Godot winds front faces CLOCKWISE seen from the side they
## face; a negative z-cross is clockwise with x right and y up, so the winding is
## checked rather than assumed.
func _stroke_quad(p0: Vector2, p1: Vector2, hw: float) -> PackedVector3Array:
	var d: Vector2 = (p1 - p0).normalized()
	var nrm := Vector2(-d.y, d.x) * hw
	var a := Vector3(p0.x + nrm.x, p0.y + nrm.y, 0.0)
	var b := Vector3(p1.x + nrm.x, p1.y + nrm.y, 0.0)
	var c := Vector3(p1.x - nrm.x, p1.y - nrm.y, 0.0)
	var e := Vector3(p0.x - nrm.x, p0.y - nrm.y, 0.0)
	var cross_z: float = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
	if cross_z < 0.0:
		return PackedVector3Array([a, b, c, a, c, e])
	return PackedVector3Array([a, c, b, a, e, c])


func _mat(col: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = 0.0
	return m


# ── config ──

## Keys: `seed` (listed, numeric is safe), `turned` (WORDS only), `cell_size`
## (listed), `solid` (WORDS only: on / off). Nothing changed means nothing is
## touched, so a curator's apply_grid_config({"emissive": false}) is a no-op.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false
	if config_data.has("seed"):
		var s: int = _as_int(config_data["seed"], seed)
		if s != seed:
			seed = s
			changed = true
	if config_data.has("turned"):
		var t: String = _turned_word(config_data["turned"])
		if t == "":
			push_warning("composition_stochastique: turned '%s' is not one of series, one, five, thirty, fifty; keeping '%s'"
				% [str(config_data["turned"]), turned])
		elif t != turned:
			turned = t
			changed = true
	if config_data.has("cell_size"):
		var cs: float = clampf(_as_float(config_data["cell_size"], cell_m), 0.02, 0.10)
		if not is_equal_approx(cs, cell_m):
			cell_m = cs
			changed = true
	if config_data.has("solid"):
		var so: bool = _flag(config_data["solid"])
		if so != solid:
			solid = so
			changed = true
	if not changed:
		return
	_draw = 0
	if not _built:
		return
	_build()


func _turned_word(v: Variant) -> String:
	var ty: int = typeof(v)
	if ty == TYPE_INT or ty == TYPE_FLOAT:
		var at: int = COUNTS.find(int(v))
		return WORDS[at] if at >= 0 else ""
	if ty != TYPE_STRING and ty != TYPE_STRING_NAME:
		return ""
	var s: String = str(v).strip_edges().to_lower()
	if s in ["series", "all", "four"]:
		return "series"
	if WORDS.has(s):
		return s
	if s.is_valid_int():
		var at2: int = COUNTS.find(s.to_int())
		return WORDS[at2] if at2 >= 0 else ""
	return ""


## NOT int(str(v)): String.to_int drops the decimal point, so "1959.0" would read
## as 19590 and a JSON number would silently become another seed.
func _as_int(v: Variant, fallback: int) -> int:
	var ty: int = typeof(v)
	if ty == TYPE_INT:
		return int(v)
	if ty == TYPE_FLOAT:
		return int(round(float(v)))
	if ty == TYPE_STRING or ty == TYPE_STRING_NAME:
		var s: String = str(v).strip_edges()
		if s.is_valid_int():
			return s.to_int()
		if s.is_valid_float():
			return int(round(s.to_float()))
	return fallback


func _as_float(v: Variant, fallback: float) -> float:
	var ty: int = typeof(v)
	if ty == TYPE_INT or ty == TYPE_FLOAT:
		return float(v)
	if ty == TYPE_STRING or ty == TYPE_STRING_NAME:
		var s: String = str(v).strip_edges()
		if s.is_valid_float():
			return s.to_float()
	return fallback


## bool("0") and bool("false") are both TRUE in GDScript; read the word instead.
func _flag(v: Variant) -> bool:
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	return str(v).strip_edges().to_lower() in ["true", "1", "yes", "on"]
