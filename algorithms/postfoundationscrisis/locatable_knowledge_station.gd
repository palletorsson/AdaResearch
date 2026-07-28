# Locatable Knowledge Station — every fact carries its address
#
# A study desk with three open books. Each book displays a glowing claim, but each claim
# is tagged with its source — a place, a person, a moment. The tag is *part of* the claim,
# not an annotation after the fact. As the player approaches each book, the claim and
# its location reveal together.
#
# This counters the encyclopedia fantasy of placeless knowledge. Every fact is *from
# somewhere*. Knowledge is locatable; without a where, the fact is the encyclopedia's
# own ghost.
#
# @identity: First map where knowledge carries its origin like grain in wood.
# @qfep_term: Edge — locatable, not universal.

extends Node3D
class_name LocatableKnowledgeStation

@export var desk_color: Color = Color(0.4, 0.3, 0.22, 1.0)
@export var book_color: Color = Color(0.6, 0.85, 0.95, 1.0)
@export var tag_color: Color = Color(0.95, 0.7, 0.4, 1.0)

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — provenance
# ═══════════════════════════════════════════════════════════════════
#
# What varies: how visibly each claim carries the place it came from — or whether it
# has been cut loose from it.
#
# Why it is worth varying: the artifact's whole thesis was a font-14 orange line sitting
# 6 cm over a book. From across the room you saw three glowing books on a desk and no
# argument at all. Each value here converts provenance into MASS — something with a
# silhouette:
#
#   tagged   the shipped look; the address is a caption
#   ghost    the counter-case the header comment names and the code never built —
#            the source is deleted and the fact floats, translucent, over an empty desk
#   chained  the address is a rod running from the book, through the desk, to a plate
#            bolted to a specific patch of floor; the tag hangs on the rod at knee height
#   mapped   the desk is a survey plate and each book is pinned to a named cell of it
#
# `tagged` is byte-for-byte the pre-promotion build — every map that already places this
# station is untouched.
@export_enum("tagged", "ghost", "chained", "mapped") var provenance: String = "tagged"

## Accepted spellings. A map token outside this list lands on the legacy look rather
## than half-applying — a station with a rod and no anchor plate would be worse than
## no rod at all.
const PROVENANCES: PackedStringArray = ["tagged", "ghost", "chained", "mapped"]

# ── Desk geometry, hoisted so every provenance builds to the same working heights ──
const DESK_SIZE: Vector3 = Vector3(1.6, 0.05, 0.6)
const DESK_Y: float = 0.9              # centre of the slab
const DESK_TOP: float = 0.925          # working surface — books sit just above this

# ── ghost ──
## The lift is deliberately large. A hand's width would have read as a modelling
## mistake; 0.35 m reads as "this is not resting on anything" from the doorway.
const GHOST_LIFT: float = 0.35
const GHOST_ALPHA: float = 0.25

# ── chained ──
const ROD_RADIUS: float = 0.01                              # a 0.02 m rod
const ANCHOR_X: Array = [-0.55, 0.0, 0.55]                  # each book lands somewhere else
const ANCHOR_PLATE: Vector3 = Vector3(0.2, 0.03, 0.2)
const TAG_W: float = 0.28
const TAG_H: float = 0.12
const KNEE_Y: float = 0.5

# ── mapped ──
## 12 x 5 cells with a 0.01 m groove between them. The grooves are REAL gaps between
## real tiles standing on a lower base slab, not dark lines painted on a flat top —
## at 0.02 m deep they still catch shadow at a grazing angle.
const MAP_COLS: int = 12
const MAP_ROWS: int = 5
const MAP_GROOVE: float = 0.01
const MAP_TILE_H: float = 0.02
const PIN_HEIGHT: float = 0.4
const PIN_RADIUS: float = 0.012

## A cell is 0.124 x 0.112 m and a book is 0.32 x 0.22 m — so a book covers about
## 2.6 x 2.0 cells and a single tinted cell is invisible UNDER the thing standing on
## it. The plot is therefore a BAND, not a cell: the book's column padded one cell each
## side (0.393 m, wider than the book) running the full 0.6 m depth of the plate (the
## book is 0.22 m deep). Roughly 70% of the marked surface is never covered, and it
## runs out to both edges of the plate where a standing eye meets it side-on.
const MAP_PLOT_PAD: int = 1
## The plot stands proud of the surrounding tiles, so the boundary is a step with a
## shadow rather than a change of colour on a flat top.
const MARK_LIFT: float = 0.012
## A kerb across each end of the plot — the part of the mark that has a silhouette
## from a standing eye height instead of only from above.
const KERB_H: float = 0.03
const KERB_T: float = 0.02
const KERB_INSET: float = 0.02          # keeps adjacent plots' kerbs visibly apart

var _book_positions: Array = [
	{"pos": Vector3(-0.5, 0.95, 0.1), "claim": "Water boils at 100°C", "source": "at sea level, Earth, 1742"},
	{"pos": Vector3(0.0, 0.95, 0.15), "claim": "Money is real", "source": "in markets where trust holds"},
	{"pos": Vector3(0.5, 0.95, 0.1), "claim": "X is a man", "source": "in the eyes of the registrar"},
]


## Everything this script puts in the tree, so a rebuild frees its own work and nothing
## else. The grid system adds children of its own after us — label plates, packaging,
## tags — and get_children() would have eaten those too.
var _owned: Array[Node] = []
var _built: bool = false


func _ready() -> void:
	_build_all()
	_built = true


func _own(n: Node) -> void:
	add_child(n)
	_owned.append(n)


func _build_all() -> void:
	if provenance == "mapped":
		_build_map_plate()
	else:
		_build_desk()
	for i in range(_book_positions.size()):
		var book: Dictionary = _book_positions[i]
		_build_book(book, i)
	_build_label()


func apply_grid_config(config_data: Dictionary) -> void:
	# Stage-2 DNA axis — #provenance:chained
	var before_provenance: String = provenance
	if config_data.has("provenance"):
		provenance = _pick_axis(str(config_data["provenance"]), PROVENANCES, provenance)
	if not _built:
		return
	if provenance == before_provenance:
		return
	_rebuild_now()
	print("[LocatableKnowledgeStation] Config applied — provenance=%s" % [provenance])


## Accept an axis value only if it names something we actually build. Anything else is
## a typo, and a typo has to fall back to the shipped look.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous by contract. The old build leaves the tree on this frame (remove_child,
## not just queue_free, so there is never a frame with two builds in it) and the new one
## is standing before this call returns — nothing deferred, so a rebuild can never land
## after the grid system has framed our labels or measured our AABB for grounding.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			if c.get_parent() == self:
				remove_child(c)
			c.queue_free()
	_owned.clear()
	_build_all()


# ═══════════════════════════════════════════════════════════════════
# THE DESK — a slab, or a survey plate
# ═══════════════════════════════════════════════════════════════════

func _desk_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = desk_color
	mat.roughness = 0.7
	return mat


func _build_desk() -> void:
	var desk := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = DESK_SIZE
	desk.mesh = box
	var mat: StandardMaterial3D = _desk_material()
	desk.material_override = mat
	desk.position.y = DESK_Y
	_own(desk)
	_build_legs(mat)


func _build_legs(mat: StandardMaterial3D) -> void:
	for x_off in [-0.7, 0.7]:
		for z_off in [-0.25, 0.25]:
			var leg := MeshInstance3D.new()
			var leg_box := BoxMesh.new()
			leg_box.size = Vector3(0.06, 0.85, 0.06)
			leg.mesh = leg_box
			leg.material_override = mat
			leg.position = Vector3(x_off, 0.45, z_off)
			_own(leg)


## mapped: the desktop is replaced by a scored map plate of the same 1.6 x 0.6 m
## footprint — a low base slab carrying 60 tiles with 0.01 m grooves between them.
## Each book's plot is marked in tag_color and raised MARK_LIFT above its neighbours:
## the book's own column padded one cell each side, running the full depth of the
## plate. The plate reads as a survey sheet with three positions already claimed, and
## the claims are legible from a standing eye because most of each one is uncovered.
func _build_map_plate() -> void:
	var mat: StandardMaterial3D = _desk_material()

	var base := MeshInstance3D.new()
	var base_box := BoxMesh.new()
	base_box.size = Vector3(DESK_SIZE.x, 0.04, DESK_SIZE.z)
	base.mesh = base_box
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = desk_color.darkened(0.55)
	base_mat.roughness = 0.85
	base.material_override = base_mat
	base.position.y = DESK_TOP - MAP_TILE_H - 0.02
	_own(base)

	var plots: Array[Vector2i] = []
	for i in range(_book_positions.size()):
		var b: Dictionary = _book_positions[i]
		var bp: Vector3 = b["pos"]
		plots.append(_plot_cols(_cell_of(bp)))

	var tile_mat := StandardMaterial3D.new()
	tile_mat.albedo_color = desk_color
	tile_mat.roughness = 0.65

	var mark_mat := StandardMaterial3D.new()
	mark_mat.albedo_color = tag_color
	mark_mat.emission_enabled = true
	mark_mat.emission = tag_color
	mark_mat.emission_energy_multiplier = 0.35
	mark_mat.roughness = 0.5

	var cw: float = _cell_w()
	var cd: float = _cell_d()
	var mark_h: float = MAP_TILE_H + MARK_LIFT
	for col in range(MAP_COLS):
		var in_plot: bool = false
		for pi in range(plots.size()):
			var r: Vector2i = plots[pi]
			if col >= r.x and col <= r.y:
				in_plot = true
		for row in range(MAP_ROWS):
			var tile := MeshInstance3D.new()
			var tb := BoxMesh.new()
			tb.size = Vector3(cw, mark_h if in_plot else MAP_TILE_H, cd)
			tile.mesh = tb
			tile.material_override = mark_mat if in_plot else tile_mat
			var c: Vector3 = _cell_center(col, row)
			if in_plot:
				# Same top face for the whole plot, sitting MARK_LIFT above the field.
				c.y = DESK_TOP + MARK_LIFT - mark_h * 0.5
			tile.position = c
			_own(tile)

	_build_legs(mat)


## The band of columns a book's plot occupies: its own column plus MAP_PLOT_PAD each
## side. 3 cells is 0.393 m against a 0.32 m book, so the mark out-reaches the thing
## standing on it in x, and it runs the full plate depth in z.
func _plot_cols(cell: Vector2i) -> Vector2i:
	var lo: int = clampi(cell.x - MAP_PLOT_PAD, 0, MAP_COLS - 1)
	var hi: int = clampi(cell.x + MAP_PLOT_PAD, 0, MAP_COLS - 1)
	return Vector2i(lo, hi)


func _plot_span(cell: Vector2i) -> Vector2:
	var r: Vector2i = _plot_cols(cell)
	var cw: float = _cell_w()
	var left: float = -DESK_SIZE.x * 0.5 + float(r.x) * (cw + MAP_GROOVE)
	var right: float = -DESK_SIZE.x * 0.5 + float(r.y) * (cw + MAP_GROOVE) + cw
	return Vector2(left, right)


## A cell has a name, not just a tint — column letter, row number, survey-sheet style.
func _cell_name(cell: Vector2i) -> String:
	return String.chr(65 + cell.x) + str(cell.y + 1)


func _cell_w() -> float:
	return (DESK_SIZE.x - float(MAP_COLS - 1) * MAP_GROOVE) / float(MAP_COLS)


func _cell_d() -> float:
	return (DESK_SIZE.z - float(MAP_ROWS - 1) * MAP_GROOVE) / float(MAP_ROWS)


func _cell_center(col: int, row: int) -> Vector3:
	var cw: float = _cell_w()
	var cd: float = _cell_d()
	var x: float = -DESK_SIZE.x * 0.5 + cw * 0.5 + float(col) * (cw + MAP_GROOVE)
	var z: float = -DESK_SIZE.z * 0.5 + cd * 0.5 + float(row) * (cd + MAP_GROOVE)
	return Vector3(x, DESK_TOP - MAP_TILE_H * 0.5, z)


func _cell_of(p: Vector3) -> Vector2i:
	var cw: float = _cell_w()
	var cd: float = _cell_d()
	var col: int = int(floor((p.x + DESK_SIZE.x * 0.5) / (cw + MAP_GROOVE)))
	var row: int = int(floor((p.z + DESK_SIZE.z * 0.5) / (cd + MAP_GROOVE)))
	return Vector2i(clampi(col, 0, MAP_COLS - 1), clampi(row, 0, MAP_ROWS - 1))


# ═══════════════════════════════════════════════════════════════════
# THE BOOKS — and what they are, or are not, attached to
# ═══════════════════════════════════════════════════════════════════

func _build_book(book: Dictionary, index: int) -> void:
	var pos: Vector3 = book["pos"]
	if provenance == "mapped":
		# Sit the book squarely on its plot so "marked cell" is literally true — and
		# ON it, resting on the raised surface rather than floating 5 mm over the old
		# flat one.
		var cell: Vector2i = _cell_of(pos)
		var c: Vector3 = _cell_center(cell.x, cell.y)
		pos = Vector3(c.x, DESK_TOP + MARK_LIFT + 0.02, c.z)
	elif provenance == "ghost":
		pos = pos + Vector3(0, GHOST_LIFT, 0)

	# ── the book itself ──
	var book_mesh := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.32, 0.04, 0.22)
	book_mesh.mesh = b
	var mat := StandardMaterial3D.new()
	if provenance == "ghost":
		# Cut loose from its source, the fact stops being solid. Emission OFF — a lit
		# translucent box still reads as an object; an unlit one reads as a leftover.
		mat.albedo_color = Color(book_color.r, book_color.g, book_color.b, GHOST_ALPHA)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = false
		mat.roughness = 0.4
	else:
		mat.albedo_color = book_color
		mat.emission_enabled = true
		mat.emission = book_color
		mat.emission_energy_multiplier = 0.5
		mat.roughness = 0.4
	book_mesh.material_override = mat
	book_mesh.position = pos
	_own(book_mesh)

	# ── claim label — the fact, always present ──
	var claim := Label3D.new()
	claim.text = book["claim"]
	claim.font_size = 18
	claim.outline_size = 4
	claim.modulate = book_color
	claim.position = pos + Vector3(0, 0.16, 0)
	claim.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_own(claim)

	# ── the address, in whatever form this provenance gives it ──
	match provenance:
		"tagged":
			_build_source_caption(book, pos)
		"ghost":
			pass  # No source is built. That absence IS this value.
		"chained":
			_build_chain(book, pos, index)
		"mapped":
			_build_plot_frame(pos)
			_build_pin(book, pos)


## tagged: the shipped caption — a font-14 orange line 6 cm over the book.
func _build_source_caption(book: Dictionary, pos: Vector3) -> void:
	var source := Label3D.new()
	source.text = "· " + str(book["source"])
	source.font_size = 14
	source.outline_size = 3
	source.modulate = tag_color
	source.position = pos + Vector3(0, 0.06, 0)
	source.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_own(source)


## chained: a 0.02 m rod leaves the book's underside, passes through the desktop and
## lands on a 0.2 x 0.2 m plate bolted to the floor at its own offset — each claim
## anchored somewhere ELSE, which is the point. The source text hangs on the rod at
## knee height on a 0.28 x 0.12 m tag, font 22, where a standing body can read it.
func _build_chain(book: Dictionary, pos: Vector3, index: int) -> void:
	var anchor_x: float = float(ANCHOR_X[index % ANCHOR_X.size()])
	var from: Vector3 = Vector3(pos.x, pos.y - 0.02, pos.z)
	var to: Vector3 = Vector3(anchor_x, ANCHOR_PLATE.y, 0.0)
	var dir: Vector3 = to - from
	var span: float = dir.length()

	var rod_mat := StandardMaterial3D.new()
	rod_mat.albedo_color = Color(0.55, 0.55, 0.58)
	rod_mat.metallic = 0.7
	rod_mat.roughness = 0.35

	var rod := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = ROD_RADIUS
	cyl.bottom_radius = ROD_RADIUS
	cyl.height = span
	cyl.radial_segments = 10
	rod.mesh = cyl
	rod.material_override = rod_mat
	# Cylinders stand on +Y; swing that axis onto the run of the tether.
	var swing: Basis = Basis(Quaternion(Vector3.UP, dir.normalized()))
	rod.transform = Transform3D(swing, (from + to) * 0.5)
	_own(rod)

	# Floor anchor plate — the patch of world this claim is actually from.
	var plate := MeshInstance3D.new()
	var pbox := BoxMesh.new()
	pbox.size = ANCHOR_PLATE
	plate.mesh = pbox
	var plate_mat := StandardMaterial3D.new()
	plate_mat.albedo_color = tag_color.darkened(0.35)
	plate_mat.metallic = 0.4
	plate_mat.roughness = 0.5
	plate.material_override = plate_mat
	plate.position = Vector3(anchor_x, ANCHOR_PLATE.y * 0.5, 0.0)
	_own(plate)

	# The tag, hung on the rod where it passes the knee.
	var t: float = clampf((from.y - KNEE_Y) / maxf(from.y - to.y, 0.001), 0.0, 1.0)
	var tag_pos: Vector3 = from.lerp(to, t)

	var tag := MeshInstance3D.new()
	var tag_box := BoxMesh.new()
	tag_box.size = Vector3(TAG_W, TAG_H, 0.012)
	tag.mesh = tag_box
	var tag_mat := StandardMaterial3D.new()
	tag_mat.albedo_color = tag_color
	tag_mat.emission_enabled = true
	tag_mat.emission = tag_color
	tag_mat.emission_energy_multiplier = 0.25
	tag_mat.roughness = 0.6
	tag.material_override = tag_mat
	tag.position = tag_pos + Vector3(0, 0, 0.09)
	_own(tag)

	var tag_text := Label3D.new()
	tag_text.text = str(book["source"])
	tag_text.font_size = 22
	tag_text.outline_size = 4
	tag_text.pixel_size = 0.0018
	tag_text.width = 145.0
	tag_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	tag_text.modulate = Color(0.12, 0.09, 0.06)
	tag_text.outline_modulate = tag_color
	tag_text.position = tag_pos + Vector3(0, 0, 0.098)
	_own(tag_text)


## mapped: the plot's own furniture — a kerb across each end of the band and the cell's
## NAME standing at the near end. Both live outside the book's footprint: the kerbs are
## 0.3 m in front of and behind it, and the name is off the plate surface entirely,
## which is what makes the mark survive being stood on.
func _build_plot_frame(pos: Vector3) -> void:
	var cell: Vector2i = _cell_of(pos)
	var span: Vector2 = _plot_span(cell)
	var plot_cx: float = (span.x + span.y) * 0.5
	var kerb_w: float = maxf((span.y - span.x) - KERB_INSET * 2.0, 0.05)
	var top_y: float = DESK_TOP + MARK_LIFT

	var kerb_mat := StandardMaterial3D.new()
	kerb_mat.albedo_color = tag_color
	kerb_mat.emission_enabled = true
	kerb_mat.emission = tag_color
	kerb_mat.emission_energy_multiplier = 0.45
	kerb_mat.roughness = 0.5

	var near_z: float = -DESK_SIZE.z * 0.5 + KERB_T * 0.5
	var far_z: float = DESK_SIZE.z * 0.5 - KERB_T * 0.5
	for z_edge in [near_z, far_z]:
		var kerb := MeshInstance3D.new()
		var kbox := BoxMesh.new()
		kbox.size = Vector3(kerb_w, KERB_H, KERB_T)
		kerb.mesh = kbox
		kerb.material_override = kerb_mat
		kerb.position = Vector3(plot_cx, top_y + KERB_H * 0.5, z_edge)
		_own(kerb)

	var name_label := Label3D.new()
	name_label.text = _cell_name(cell)
	name_label.font_size = 20
	name_label.outline_size = 4
	name_label.pixel_size = 0.0016
	name_label.modulate = tag_color
	name_label.position = Vector3(plot_cx, top_y + KERB_H + 0.055, near_z - 0.01)
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_own(name_label)


## mapped: a 0.4 m survey pin stands out of the book's marked cell, straight through
## the book, with the source text banded around its head at eye-catching height.
func _build_pin(book: Dictionary, pos: Vector3) -> void:
	var base_y: float = DESK_TOP + MARK_LIFT
	var pin := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = PIN_RADIUS
	cyl.bottom_radius = PIN_RADIUS
	cyl.height = PIN_HEIGHT
	cyl.radial_segments = 10
	pin.mesh = cyl
	var pin_mat := StandardMaterial3D.new()
	pin_mat.albedo_color = Color(0.62, 0.62, 0.66)
	pin_mat.metallic = 0.75
	pin_mat.roughness = 0.3
	pin.material_override = pin_mat
	pin.position = Vector3(pos.x, base_y + PIN_HEIGHT * 0.5, pos.z)
	_own(pin)

	# The band — the address wrapped physically around the pin's head.
	var band := MeshInstance3D.new()
	var band_mesh := CylinderMesh.new()
	band_mesh.top_radius = 0.042
	band_mesh.bottom_radius = 0.042
	band_mesh.height = 0.1
	band_mesh.radial_segments = 16
	band.mesh = band_mesh
	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = tag_color
	band_mat.emission_enabled = true
	band_mat.emission = tag_color
	band_mat.emission_energy_multiplier = 0.4
	band_mat.roughness = 0.55
	band.material_override = band_mat
	var head_y: float = base_y + PIN_HEIGHT - 0.07
	band.position = Vector3(pos.x, head_y, pos.z)
	_own(band)

	var source := Label3D.new()
	source.text = str(book["source"])
	source.font_size = 22
	source.outline_size = 4
	source.pixel_size = 0.0016
	source.width = 160.0
	source.autowrap_mode = TextServer.AUTOWRAP_WORD
	source.modulate = tag_color
	source.position = Vector3(pos.x, head_y, pos.z + 0.05)
	source.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_own(source)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "every fact is from somewhere"
	label.font_size = 26
	label.outline_size = 6
	label.modulate = tag_color
	label.position = Vector3(0, 1.55, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_own(label)
