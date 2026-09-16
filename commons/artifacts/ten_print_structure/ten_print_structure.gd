# @identity
# essence: 10 PRINT at the scale of a room: a field of diagonal slabs laid on the floor, one per character, printed by a ten_print screen elsewhere in the hall
# desire: that a visitor presses SEMICOLON or BIAS + at the screen, turns round, and finds the room already different, because the room is the same stream seen from inside
# critical_parameter: form. "floor" is ridges you read standing, "wall" a maze you walk in, "overhead" a maze you read above your head; the stream is the same in all three
# triggers: _ready builds the slabs (one MultiMesh), the plate and, when a channel is given, looks for a screen with that channel in its own hall for LINK_RETRY_FRAMES frames; a linked screen's cell_drawn / field_reset / field_scrolled drive the slabs
# emerges: the book's two views of one maze (p. 84): the screen shows it as Daedalus sees it, from above and outside, the room as Theseus does
# needs: a ten_print (algorithms/randomness/ten_print) with #channel:<word> in the same hall [present, 2026-09-16]; commons/ui/text_screen.gd for every word [present]
# relationships: ten_print is the interface (#controls:panel); composition_stochastique counts the same two diagonals where this one flips a coin; wall_drawing_291 hands the choice to a person
# truth: the maze is not in the program. It appears only where a one-dimensional stream of coin flips is wrapped into a grid (p. 68), and the size of the grid is not the program's business either: the same stream makes a screen or a room.

extends Node3D
class_name TenPrintStructure

## ten_print_structure: the larger 10 PRINT, printed cell by cell from a ten_print screen.
##
## THE FIELD. `cols` x `rows` cells (default 20 x 20) at `size` metres a cell (default 0.5, so
## 10 x 10 m), laid on the floor in the XZ plane. ORIGIN CORNER: the node's origin is the
## outer corner of cell (col 0, row 0), the screen's HOME cell, where 10 PRINT starts printing.
## The field extends toward +X (columns) and +Z (rows). Cell (c, r) spans x c*size .. (c+1)*size
## and z r*size .. (r+1)*size. Rotation turns the whole field about that corner: a yaw of 90
## degrees (Godot's rotation.y, +X to -Z) sends it toward -Z and +X, 180 toward -X and -Z,
## 270 toward +Z and -X. The NEAR EDGE is z = rows*size, where the plate stands; the visitor
## reads the room from there, looking toward -Z.
##
## THE SCREEN LAID DOWN. Read the ten_print screen from its front (its +Z side) and tip it away
## from you onto the floor, hinged at its bottom edge: its top row goes farthest away, its left
## column stays on your left. So from the near edge, looking toward -Z:
##   screen column c           -> floor column c   (x grows to your right, as on the screen)
##   screen row r (0 = top)    -> floor row r       (row 0 farthest, at z 0 .. size)
##   forward flag (the line rotated +45 deg about Z, logged "/", SEEN AS "\" from the front)
##                             -> a slab from the cell's far-left corner (c, r) to its near-right
##                                corner (c+1, r+1): yaw -45 degrees
##   backward flag (logged "\", seen as "/")
##                             -> a slab from the near-left corner (c, r+1) to the far-right
##                                corner (c+1, r): yaw +45 degrees
## Seen from the near edge the floor draws the same glyph the screen draws in that cell.
## A PAIR READS THE SAME WAY ROUND ONLY WHEN BOTH TOKENS CARRY ONE YAW and the screen stands
## beyond the field's far edge (row 0): then a visitor at the plate faces the screen's front.
##
## FORM (the DNA axis, words):
##   floor     ridges on the floor, 0.25 m tall but never taller than half a cell
##             (min(0.25, size / 2): 0.25 m at the default 0.5 m cell, 0.1 m at #size:0.2), so
##             a small field still shows its floor between the ridges. You step among them and
##             read them standing; the next-cell tile lies on the ridge tops
##   wall      slabs 2.4 m tall: a maze to walk in. The corridor between two parallel slabs in
##             neighbouring cells is size / sqrt 2 minus the slab, so walking wants size >= 1.0
##             (#size:1.2 gives 0.79 m); at the default 0.5 it is a maze to look into. The
##             next-cell tile lies on the floor, inside the maze
##   overhead  slabs 0.2 m tall hung from 2.9 m: a maze read above your head; the tile hangs
##             just under the slabs
## SOLID (words): "off" (default) builds NO collider: the field is a VENUE, you walk through it.
## "on" gives every drawn slab a box collider. IN THE MUSEUM ANY CollisionShape3D SEALS THE
## WHOLE FOOTPRINT: a solid field is a closed 10 x 10 m block to the museum's walk. Words only:
## `solid` is not a listed key, so #solid:1 would be rotation shorthand and is refused.
##
## THE LINK. `channel` (a WORD, default ""). With a channel the structure looks for a node in
## group "ten_print_interface" with the same channel. call_group and get_nodes_in_group cross
## halls in the streaming museum, so the search is SCOPED: it walks up from this node's parent
## and takes the nearest candidate under the first ancestor that holds one. It stops at a hall
## (a node with em_map meta or a name starting "Seg"), and it never searches the whole scene
## (current_scene) unless that is this node's own parent. It retries for LINK_RETRY_FRAMES
## frames, because the grid adds siblings in order and hands config over deferred; after that a
## screen that joins its group, or changes its channel, announces itself (the museum can place
## one hall's artifacts across many frames), and the structure re-runs the same scoped search.
## A linked structure whose screen has left its channel lets it go and searches again.
##
## FOLLOWING. On link the field is read whole from get_field(). A character (cell_drawn) is one
## instance write. A reset or a scroll only MARKS the field for a reload: one SEMICOLON press on
## a full when_full-scroll screen prints its count again inside that one call and, without the
## semicolon, scrolls once per character (380 scrolls for #count:400), so rewriting the room per
## scroll would be 150,000 instance writes in a frame. The reload runs once, deferred, at the
## end of the frame: it reads get_field() and writes only the cells whose state changed (and
## tells only their colliders). Characters that arrive while a reload is pending are read with
## it. Readbacks (slabs_node, marker_node, get_cells) apply a pending reload first. The cell
## where the screen's NEXT character will land is marked with a bright tile. When linked, the
## field takes the screen's grid (get_grid_dims); `cols` and `rows` shape the standalone field.
##
## STANDALONE (no channel, or no screen found). The field is printed here from `seed` and
## `count`, with ten_print's pinned rule copied exactly: character i is forward when
##   RandomNumberGenerator(seed = hash([seed, i])).randf() < 0.5 + 0.3 sin(i * TAU / 540)
## laid out as ten_print lays it with semicolon on and when_full scroll: row-major, and a full
## field scrolls up one row before the next character. After N characters on a cols x rows
## grid that has scrolled s = ceil((N - cols*rows) / cols) times (0 while N fits), cell (c, r)
## holds character (s + r) * cols + c when that is below N, and is empty otherwise; the field is
## laid from that directly. So the default (seed 1982, count 400) is the field the 10 PRINT
## hall's #seed:1982#count:400 screens print at build. It does not tick: without a screen there
## is nothing to print it, and the plate says so.
##
## COLOUR follows ten_print's rule by cell: forward (1, 0.3 + 0.7 k, 0.3), backward
## (0.3, 0.3 + 0.7 k, 1), k = (col + row) / (cols + rows). One divergence, knowingly: the screen
## keeps each line's print colour when it scrolls, the floor recolours by position.
##
## CONFIG. `cols`, `rows`, `size`, `seed` and `count` are in
## GridInteractablesComponent.CONFIG_PARAM_NAMES and arrive as values. `form`, `solid` and
## `channel` take WORDS. Safe before the tree (museum) and after _ready (grid, deferred).
##
## CAPTURE. The slabs are a MultiMeshInstance3D, which the capture AABB does not count, so a
## `layers = 0` MeshInstance3D anchor spans the field from y 0 to the form's top.

signal linked(screen: Node)
signal unlinked()

@export_enum("floor", "wall", "overhead") var form: String = "floor"
@export_enum("off", "on") var solid: String = "off"
@export var channel: String = ""
@export_range(1, 40) var cols: int = 20
@export_range(1, 40) var rows: int = 20
@export var size: float = 0.5
@export var seed: int = 1982
@export var count: int = 400

const FORMS := ["floor", "wall", "overhead"]
const INTERFACE_GROUP := "ten_print_interface"
## A screen that joins its group, or changes its channel, calls interface_announced on this group.
const LISTENER_GROUP := "ten_print_structure_listener"
const MAX_SIDE := 40
const COUNT_MAX := 2000
const SIZE_MIN := 0.1
const SIZE_MAX := 3.0
## ten_print's pinned breath, copied: one full 0.2..0.8 cycle every 540 characters.
const SEEDED_BREATH := TAU / 540.0
const LINK_RETRY_FRAMES := 60

const EMPTY := 0
const FORWARD := 1
const BACKWARD := 2

const SLAB_T := 0.06
const FORM_BASE := {"floor": 0.0, "wall": 0.0, "overhead": 2.9}
const FORM_HEIGHT := {"floor": 0.25, "wall": 2.4, "overhead": 0.2}
## A floor ridge is never taller than this share of its cell.
const FLOOR_HEIGHT_PER_CELL := 0.5
const MARK_THICK := 0.02
const MARK_LIFT := 0.012

const PLATE_W := 0.8
const PLATE_OUT := 0.6
const PLATE_TITLE := "10 PRINT, AT THE SCALE OF A ROOM"
const MARK_COLOR := Color(1.0, 0.95, 0.25)
const TEXT_SCREEN := preload("res://commons/ui/text_screen.gd")

var _built := false
var _created: Array[Node] = []
var _cols: int = 20
var _rows: int = 20
## What each cell should show: EMPTY, FORWARD or BACKWARD.
var _cells := PackedByteArray()
## What the MultiMesh (and the colliders) show now. A write happens only where the two differ.
var _written := PackedByteArray()
## A reset or scroll arrived: the next flush reads the whole field from the screen.
var _reload_pending := false
var _flush_queued := false
## Instance writes since the build, for probes: the batching is measured, not assumed.
var _instance_writes: int = 0
var _mm: MultiMesh = null
var _slabs: MultiMeshInstance3D = null
var _anchor: MeshInstance3D = null
var _marker: MeshInstance3D = null
var _plate: Node3D = null
var _solid_body: StaticBody3D = null
var _shapes: Array[CollisionShape3D] = []

var _interface: Node = null
## "standalone" | "searching" | "linked"
var _link_state: String = "standalone"
var _link_frames_left: int = 0
## what the slabs currently show: "standalone" or "linked"
var _content: String = ""


func _ready() -> void:
	set_process(false)
	add_to_group(LISTENER_GROUP)
	if not _built:
		_normalise()
		_cols = cols
		_rows = rows
		_build_nodes()
		_fill_standalone()
		_built = true
	_begin_link()


# ── config ──────────────────────────────────────────────────────────────────────

func apply_grid_config(config: Dictionary) -> void:
	var rebuild := false
	var relink := false
	if config.has("form"):
		var f: String = _word_of(config["form"], FORMS, form)
		if f != form:
			form = f
			rebuild = true
	if config.has("solid"):
		var so: String = _word_of(config["solid"], ["off", "on"], solid)
		if so != solid:
			solid = so
			rebuild = true
	if config.has("cols"):
		var c: int = clampi(_int_of(config["cols"], cols), 1, MAX_SIDE)
		if c != cols:
			cols = c
			rebuild = true
	if config.has("rows"):
		var r: int = clampi(_int_of(config["rows"], rows), 1, MAX_SIDE)
		if r != rows:
			rows = r
			rebuild = true
	if config.has("size"):
		var sz: float = clampf(_float_of(config["size"], size), SIZE_MIN, SIZE_MAX)
		if not is_equal_approx(sz, size):
			size = sz
			rebuild = true
	if config.has("seed"):
		var sd: int = _int_of(config["seed"], seed)
		if sd != seed:
			seed = sd
			rebuild = true
	if config.has("count"):
		var n: int = clampi(_int_of(config["count"], count), 0, COUNT_MAX)
		if n != count:
			count = n
			rebuild = true
	if config.has("channel"):
		var ch: String = _channel_of(config["channel"], channel)
		if ch != channel:
			channel = ch
			relink = true
	if not _built:
		return                  # _ready builds with these values, once
	if rebuild:
		_rebuild()
	if relink:
		_begin_link()


func _normalise() -> void:
	cols = clampi(cols, 1, MAX_SIDE)
	rows = clampi(rows, 1, MAX_SIDE)
	size = clampf(size, SIZE_MIN, SIZE_MAX)
	count = clampi(count, 0, COUNT_MAX)
	if not FORMS.has(form):
		form = "floor"
	if solid != "on":
		solid = "off"


## Rebuild the nodes and repopulate from whatever feeds the field now.
func _rebuild() -> void:
	_normalise()
	if _link_state == "linked" and linked_interface() != null:
		_load_from_interface(true)
	else:
		_cols = cols
		_rows = rows
		_build_nodes()
		_fill_standalone()
	_refresh_plate()


# ── building ────────────────────────────────────────────────────────────────────

func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


func _free_own() -> void:
	for c in _created:
		if is_instance_valid(c):
			if c.get_parent() == self:
				remove_child(c)
			c.queue_free()
	_created.clear()
	_shapes.clear()
	_mm = null
	_slabs = null
	_anchor = null
	_marker = null
	_plate = null
	_solid_body = null


func slab_base() -> float:
	return float(FORM_BASE.get(form, 0.0))


func slab_height() -> float:
	var h: float = float(FORM_HEIGHT.get(form, 0.25))
	if form == "floor":
		# never taller than half a cell: at #size:0.2 a 0.25 m fin would hide the floor behind it
		h = minf(h, size * FLOOR_HEIGHT_PER_CELL)
	return h


func slab_thickness() -> float:
	return minf(SLAB_T, size * 0.3)


## A box whose two ends reach the cell's corners: turned 45 degrees it reaches
## (L + T) / (2 sqrt 2) along each axis, which is size / 2 when L = size sqrt 2 - T.
func slab_length() -> float:
	return maxf(0.01, size * sqrt(2.0) - slab_thickness())


func _build_nodes() -> void:
	_free_own()
	var n: int = _cols * _rows
	_cells = PackedByteArray()
	_cells.resize(n)
	_cells.fill(EMPTY)
	_written = PackedByteArray()
	_written.resize(n)
	_written.fill(EMPTY)
	_reload_pending = false
	var w: float = float(_cols) * size
	var d: float = float(_rows) * size
	var top: float = slab_base() + slab_height()

	var slab_mesh := BoxMesh.new()
	slab_mesh.size = Vector3(slab_length(), slab_height(), slab_thickness())
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true          # before instance_count, or the colour buffer is not made
	_mm.mesh = slab_mesh
	_mm.instance_count = n
	# Every instance starts EMPTY, which is what _written says (the colliders below start disabled).
	for i in range(n):
		var col: int = i % _cols
		var row: int = i / _cols
		_mm.set_instance_transform(i, slab_transform(col, row, EMPTY))
		_mm.set_instance_color(i, slab_color(col, row, EMPTY))
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.7
	mat.metallic = 0.0
	_slabs = MultiMeshInstance3D.new()
	_slabs.name = "Slabs"
	_slabs.multimesh = _mm
	_slabs.material_override = mat
	_own(_slabs)

	# The capture AABB counts MeshInstance3D only: this invisible box is the field's extent.
	_anchor = MeshInstance3D.new()
	_anchor.name = "CaptureAnchor"
	var anchor_box := BoxMesh.new()
	anchor_box.size = Vector3(w, top, d)
	_anchor.mesh = anchor_box
	_anchor.position = Vector3(w * 0.5, top * 0.5, d * 0.5)
	_anchor.layers = 0
	_anchor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_own(_anchor)

	_marker = MeshInstance3D.new()
	_marker.name = "NextCellMarker"
	var mark_box := BoxMesh.new()
	mark_box.size = Vector3(size * 0.7, MARK_THICK, size * 0.7)
	_marker.mesh = mark_box
	var mark_mat := StandardMaterial3D.new()
	mark_mat.albedo_color = MARK_COLOR
	mark_mat.emission_enabled = true
	mark_mat.emission = MARK_COLOR
	mark_mat.emission_energy_multiplier = 1.6
	_marker.material_override = mark_mat
	_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_marker.position = Vector3(size * 0.5, marker_y(), size * 0.5)
	_marker.visible = false
	_own(_marker)

	var ts: Node3D = TEXT_SCREEN.new()
	ts.name = "Plate"
	ts.mode = 1                    # STAND: on a post at reading height
	ts.width_m = PLATE_W
	ts.title = PLATE_TITLE
	ts.body = _plate_body()
	ts.position = Vector3(w * 0.5, 0.0, d + PLATE_OUT)
	_own(ts)
	_plate = ts

	if solid == "on":
		_solid_body = StaticBody3D.new()
		_solid_body.name = "Solid"
		_solid_body.collision_layer = 1
		_solid_body.collision_mask = 0
		var shape := BoxShape3D.new()
		shape.size = Vector3(slab_length(), slab_height(), slab_thickness())
		for i in range(n):
			var cs := CollisionShape3D.new()
			cs.name = "Slab_%d" % i
			cs.shape = shape
			cs.disabled = true
			cs.transform = slab_transform(i % _cols, i / _cols, FORWARD)
			_solid_body.add_child(cs)
			_shapes.append(cs)
		_own(_solid_body)


## Where the next-cell tile's centre stands: on the ridge tops for floor (among 0.25 m ridges a
## tile on the ground is hidden from a standing eye), on the ground inside a wall maze, just
## under the slabs overhead.
func marker_y() -> float:
	match form:
		"overhead":
			return slab_base() - MARK_THICK
		"wall":
			return MARK_LIFT
	return slab_base() + slab_height() + MARK_LIFT


## The instance transform for cell (col, row) in state `st`. EMPTY collapses the basis to
## zero at the cell's centre, so the MultiMesh AABB stays inside the field.
func slab_transform(col: int, row: int, st: int) -> Transform3D:
	var centre := Vector3((float(col) + 0.5) * size, slab_base() + slab_height() * 0.5, (float(row) + 0.5) * size)
	if st == EMPTY:
		return Transform3D(Basis.from_scale(Vector3.ZERO), centre)
	var yaw: float = -PI * 0.25 if st == FORWARD else PI * 0.25
	return Transform3D(Basis(Vector3.UP, yaw), centre)


func slab_color(col: int, row: int, st: int) -> Color:
	var k: float = float(col + row) / float(maxi(1, _cols + _rows))
	if st == BACKWARD:
		return Color(0.3, 0.3 + k * 0.7, 1.0, 1.0)
	return Color(1.0, 0.3 + k * 0.7, 0.3, 1.0)


## Bring instance i to its cell's state. Only a real change is written, and only a slab that
## moved tells its collider, so a reload after a scroll touches the cells that differ.
func _write_instance(i: int) -> void:
	if _mm == null or i < 0 or i >= _cells.size():
		return
	var st: int = _cells[i]
	if _written[i] == st:
		return
	var col: int = i % _cols
	var row: int = i / _cols
	_mm.set_instance_transform(i, slab_transform(col, row, st))
	_mm.set_instance_color(i, slab_color(col, row, st))
	_written[i] = st
	_instance_writes += 1
	if not _shapes.is_empty():
		var cs: CollisionShape3D = _shapes[i]
		# Deferred: a press can arrive inside a physics flush (a fingertip's body_entered).
		if st == EMPTY:
			cs.set_deferred("disabled", true)
		else:
			cs.set_deferred("transform", slab_transform(col, row, st))
			cs.set_deferred("disabled", false)


func _write_changed() -> void:
	for i in range(_cells.size()):
		if _written[i] != _cells[i]:
			_write_instance(i)


func _set_cell(col: int, row: int, st: int) -> void:
	if col < 0 or row < 0 or col >= _cols or row >= _rows:
		return
	var i: int = row * _cols + col
	_cells[i] = st
	_write_instance(i)


# ── the standalone field ────────────────────────────────────────────────────────

## ten_print's pinned coin, copied (see the class doc). True is the forward flag.
func coin_is_forward(index: int) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, index])
	return rng.randf() < 0.5 + sin(float(index) * SEEDED_BREATH) * 0.3


## `count` characters, semicolon on, when_full scroll, as ten_print would lay them, laid from
## the closed form in the class doc: s scrolls, then cell (c, r) holds (s + r) * cols + c.
func _fill_standalone() -> void:
	_cells.fill(EMPTY)
	_reload_pending = false
	var n: int = _cols * _rows
	var total: int = clampi(count, 0, COUNT_MAX)
	var scrolls: int = 0
	if total > n:
		scrolls = (total - n + _cols - 1) / _cols
	var first: int = scrolls * _cols
	for i in range(n):
		var index: int = first + i
		if index >= total:
			break
		_cells[i] = FORWARD if coin_is_forward(index) else BACKWARD
	_write_changed()
	_content = "standalone"
	if _marker != null:
		_marker.visible = false


# ── the link ────────────────────────────────────────────────────────────────────

func _begin_link() -> void:
	_unlink()
	if channel == "" or not _built:
		_link_state = "standalone"
		_ensure_standalone_content()
		_refresh_plate()
		return
	_link_state = "searching"
	_link_frames_left = LINK_RETRY_FRAMES
	_refresh_plate()
	if is_inside_tree() and _try_link():
		return
	set_process(true)


func _process(_delta: float) -> void:
	if _link_state != "searching":
		set_process(false)
		return
	if _try_link():
		set_process(false)
		return
	_link_frames_left -= 1
	if _link_frames_left <= 0:
		_link_state = "standalone"
		_ensure_standalone_content()
		_refresh_plate()
		set_process(false)


## Called by a ten_print that has just joined its group or changed its channel. The caller is
## NOT trusted as the partner: call_group reaches every hall, so an unlinked structure only
## re-runs its own scoped search, which can find nothing outside its hall, and a linked one
## only checks that its OWN screen still carries its channel.
func interface_announced(_screen: Node) -> void:
	if not _built or not is_inside_tree():
		return
	if _link_state == "linked":
		var iface: Node = linked_interface()
		if iface == null or str(iface.get("channel")) != channel:
			_begin_link()
		return
	if channel == "":
		return
	if _try_link():
		set_process(false)


func _try_link() -> bool:
	var iface: Node = find_interface()
	if iface == null:
		return false
	_link_to(iface)
	return true


## The screen this structure listens to: same channel, and in this structure's own hall.
func find_interface() -> Node:
	if channel == "" or not is_inside_tree():
		return null
	var tree: SceneTree = get_tree()
	var candidates: Array[Node] = []
	for n in tree.get_nodes_in_group(INTERFACE_GROUP):
		if n == self or not is_instance_valid(n) or n.is_queued_for_deletion():
			continue
		if str(n.get("channel")) != channel:
			continue
		if not (n.has_method("get_field") and n.has_signal("cell_drawn")):
			continue
		candidates.append(n)
	if candidates.is_empty():
		return null
	var scene_root: Node = tree.current_scene
	var parent_node: Node = get_parent()
	var scope: Node = parent_node
	while scope != null and scope != tree.root:
		# the whole scene is too wide a scope, unless this structure stands directly in it
		if scope == scene_root and scope != parent_node:
			break
		var best: Node = null
		var best_d: float = INF
		for c in candidates:
			if not scope.is_ancestor_of(c):
				continue
			var d: float = 0.0
			if c is Node3D:
				d = global_position.distance_to((c as Node3D).global_position)
			if best == null or d < best_d:
				best = c
				best_d = d
		if best != null:
			return best
		if scope.has_meta("em_map") or str(scope.name).begins_with("Seg"):
			break                   # a hall is the boundary of its audience
		scope = scope.get_parent()
	return null


func _link_to(iface: Node) -> void:
	_unlink()
	_interface = iface
	if not iface.is_connected("cell_drawn", _on_cell_drawn):
		iface.connect("cell_drawn", _on_cell_drawn)
	if not iface.is_connected("field_reset", _on_field_reset):
		iface.connect("field_reset", _on_field_reset)
	if not iface.is_connected("field_scrolled", _on_field_scrolled):
		iface.connect("field_scrolled", _on_field_scrolled)
	if not iface.is_connected("tree_exiting", _on_interface_exiting):
		iface.connect("tree_exiting", _on_interface_exiting)
	_link_state = "linked"
	_load_from_interface(false)
	_refresh_plate()
	linked.emit(iface)


func _unlink() -> void:
	var had: bool = _interface != null
	if _interface != null and is_instance_valid(_interface):
		if _interface.is_connected("cell_drawn", _on_cell_drawn):
			_interface.disconnect("cell_drawn", _on_cell_drawn)
		if _interface.is_connected("field_reset", _on_field_reset):
			_interface.disconnect("field_reset", _on_field_reset)
		if _interface.is_connected("field_scrolled", _on_field_scrolled):
			_interface.disconnect("field_scrolled", _on_field_scrolled)
		if _interface.is_connected("tree_exiting", _on_interface_exiting):
			_interface.disconnect("tree_exiting", _on_interface_exiting)
	_interface = null
	_reload_pending = false
	if had:
		unlinked.emit()


## The whole field from the screen: its grid, then every cell it shows now.
func _load_from_interface(force_nodes: bool) -> void:
	if linked_interface() == null:
		return
	var dims: Vector2i = _interface.call("get_grid_dims")
	var want_c: int = clampi(dims.x, 1, MAX_SIDE)
	var want_r: int = clampi(dims.y, 1, MAX_SIDE)
	if force_nodes or want_c != _cols or want_r != _rows or _mm == null:
		_cols = want_c
		_rows = want_r
		_build_nodes()
	_reload_pending = false
	_read_field_into_cells()
	_write_changed()
	_content = "linked"
	_update_marker()


## _cells := what the screen shows now (get_field reads its live lines).
func _read_field_into_cells() -> void:
	_cells.fill(EMPTY)
	var field: Dictionary = _interface.call("get_field")
	for key in field.keys():
		if not (key is Vector2i):
			continue
		var cell: Vector2i = key
		if cell.x < 0 or cell.y < 0 or cell.x >= _cols or cell.y >= _rows:
			continue
		_cells[cell.y * _cols + cell.x] = FORWARD if bool(field[key]) else BACKWARD


func _ensure_standalone_content() -> void:
	if not _built or _content == "standalone":
		return
	_cols = cols
	_rows = rows
	_build_nodes()
	_fill_standalone()


func _on_cell_drawn(_draw_index: int, row: int, col: int, forward: bool) -> void:
	if _reload_pending:
		return                  # the queued reload reads this character from the screen
	_set_cell(col, row, FORWARD if forward else BACKWARD)
	_update_marker()


func _on_field_reset() -> void:
	_reload_pending = true
	_queue_flush()


func _on_field_scrolled() -> void:
	_reload_pending = true
	_queue_flush()


func _queue_flush() -> void:
	if _flush_queued:
		return
	_flush_queued = true
	call_deferred("flush_pending")


## Apply a pending reload: read the whole field from the screen once and write only the cells
## that changed. Runs deferred after a reset or scroll; readbacks call it first.
func flush_pending() -> void:
	_flush_queued = false
	if _reload_pending:
		_reload_pending = false
		if _link_state == "linked" and linked_interface() != null:
			_read_field_into_cells()
		_write_changed()
	_update_marker()


func _on_interface_exiting() -> void:
	_unlink()
	_link_state = "standalone"
	if _marker != null:
		_marker.visible = false
	# The screen may only be moving (or the whole hall leaving): look again next frame.
	call_deferred("_after_interface_left")


func _after_interface_left() -> void:
	if not is_inside_tree() or _link_state == "linked":
		return
	_begin_link()


func _update_marker() -> void:
	if _marker == null:
		return
	if _link_state != "linked" or linked_interface() == null \
			or not _interface.has_method("get_next_cell"):
		_marker.visible = false
		return
	var nc: Vector2i = _interface.call("get_next_cell")
	if nc.x < 0 or nc.y < 0 or nc.x >= _cols or nc.y >= _rows:
		_marker.visible = false
		return
	_marker.position = Vector3((float(nc.x) + 0.5) * size, marker_y(), (float(nc.y) + 0.5) * size)
	_marker.visible = true


# ── the plate ───────────────────────────────────────────────────────────────────

func link_state_line() -> String:
	match _link_state:
		"linked":
			return "printed by the screen with channel %s" % channel
		"searching":
			return "looking for the screen with channel %s" % channel
	if channel != "":
		return "standalone: no screen linked (no screen with channel %s here)" % channel
	return "standalone: no screen linked"


func _plate_body() -> String:
	var lines := PackedStringArray([
		"each cell is one character printed",
		"by the screen · change the rule",
		"there, and the room follows",
		link_state_line(),
	])
	if _link_state != "linked":
		lines.append("seed %d · %d characters" % [seed, clampi(count, 0, COUNT_MAX)])
	return "\n".join(lines)


func _refresh_plate() -> void:
	if _plate == null or not is_instance_valid(_plate):
		return
	var b: String = _plate_body()
	if str(_plate.get("body")) != b:
		_plate.set("body", b)


# ── readbacks (for probes and anyone curious) ───────────────────────────────────

func link_state() -> String:
	return _link_state


func linked_interface() -> Node:
	return _interface if _interface != null and is_instance_valid(_interface) else null


func get_dims() -> Vector2i:
	return Vector2i(_cols, _rows)


## The field as this structure's own state holds it: Vector2i(col, row) -> true for forward.
## A probe should prefer reading the MultiMesh itself (slabs_node()).
func get_cells() -> Dictionary:
	if _reload_pending:
		flush_pending()
	var out: Dictionary = {}
	for i in range(_cells.size()):
		if _cells[i] != EMPTY:
			out[Vector2i(i % _cols, i / _cols)] = _cells[i] == FORWARD
	return out


func slabs_node() -> MultiMeshInstance3D:
	if _reload_pending:
		flush_pending()
	return _slabs


func marker_node() -> MeshInstance3D:
	if _reload_pending:
		flush_pending()
	return _marker


func plate_node() -> Node3D:
	return _plate


func solid_body() -> StaticBody3D:
	return _solid_body


## Instance writes since this structure was made (every rebuild included).
func instance_writes() -> int:
	return _instance_writes


## Is a reload waiting for the end of the frame?
func reload_pending() -> bool:
	return _reload_pending


# ── parsing ─────────────────────────────────────────────────────────────────────

## A word from `allowed`; a bool (the shorthand misparse of an unlisted key:number) and an
## unknown word both keep the current value.
func _word_of(v: Variant, allowed: Array, fallback: String) -> String:
	if v is bool:
		return fallback
	var t: String = str(v).strip_edges().to_lower()
	return t if allowed.has(t) else fallback


func _channel_of(v: Variant, fallback: String) -> String:
	if v is bool:
		return fallback
	var t: String = str(v).strip_edges()
	if t.to_lower() in ["none", "off"]:
		return ""
	return t


func _int_of(v: Variant, fallback: int) -> int:
	if v is bool:
		return fallback
	if v is int:
		return int(v)
	if v is float:
		return int(v)
	var t: String = str(v).strip_edges()
	if t.is_valid_int():
		return t.to_int()
	if t.is_valid_float():
		return int(t.to_float())
	return fallback


func _float_of(v: Variant, fallback: float) -> float:
	if v is bool:
		return fallback
	if v is int or v is float:
		return float(v)
	var t: String = str(v).strip_edges()
	if t.is_valid_float():
		return t.to_float()
	return fallback
