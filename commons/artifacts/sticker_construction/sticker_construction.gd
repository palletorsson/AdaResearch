extends Node3D
## A CARDBOARD CONSTRUCTION (Palle, 2026-11-14: "temporary constructions of cardboard, like 3D mind mapping on tables:
## walls read from different directions, stickers clustered on them, scribbles in different pens and sizes, and red
## thread between the walls describing the research"). Config `construction` (default "research"): a construction of
## commons/data/stickers/constructions.json, stood from that file and boards.json through StickerData - the same
## construction the encyclopedia's /stickers 3D view stands (cardboard3d.ts standConstruction), by the same contract
## (stickers.ts Construction, Table, Wall, wallPoint, wallYaw; ported in sticker_data.gd):
##   - its frame is the floor under its origin, +Y up (this node's own frame);
##   - a TABLE is a top TABLE_TOP thick whose upper face is the table's h, on four legs, at `at` turned `yaw` about +Y
##     (drawn as the bench's table is, so the two read as one furniture), with collision;
##   - a WALL is its board - a board of stock cardboard, w x h, CARDBOARD thick - in the board's own frame: the front
##     face at z = 0, the back at z = -CARDBOARD, the four cut edges showing the corrugation (C flute, FLUTE_PITCH);
##     that frame stood where wall_point puts the board frame's origin, turned R_y(wall_yaw). Each wall is ONE body
##     ("Wall_<board>", meta sticker_host {kind: board, id}), its one box collider exactly the slab, and ONE StickerLayer
##     that draws both faces: the stickers on each (settle's rule: a sticker whose normal points back is on the back)
##     and the scribbles on each (stroke_z), so the pad sticks and peels on either face and the pen writes on either;
##   - the THREADS (construction_threads.gd): a wall's own threads as a board draws its own, and red thread between
##     the walls between drawn_wall_threads' pins, each with its word on a tag; A THREAD NEVER PASSES THROUGH CARDBOARD:
##     one that would goes over the wall's top edge (drawn_wall_threads' `over`, over_board for a wall's own thread from
##     its front to its back), drawn in pieces (thread_pieces).
## A wall whose board is gone, or is not cardboard, or whose table is not there, is not stood (`missing` says why).
## It follows the truth (StickerData's file watch, a second; this device's own ops at once) and builds again only what
## changed: a table whose record changed, a wall whose board's size or paper changed (one whose place changed is only
## moved); the layers redraw their own stickers and scribbles and the threads their own. It builds once, at the
## frame's end (_queue_build): the tower ADDS a work and THEN calls apply_grid_config, and a build in _ready plus one
## on the config would leave two of everything (edge_carving.gd, tools/probes/edge_carving_bench.gd B1).
## The build itself only plans: it moves what moved, drops what went, and the bodies it has to make (a table, a wall's
## slab, collider and layer) are made a piece at a time after it, and what is drawn ON them is STAGED too
## (sticker_layer.gd STAGED): the bodies, each wall's layer and the threads take a few milliseconds of each frame, shared
## by them all, and drawing() says whether any of it is still to make or draw. Until 2026-11-15 the first build made and
## drew everything at once and held the main thread 210 to 293 ms in one frame (700 scribbles' ribbons, 33 designs'
## pictures, 33 threads and their tags); made at once, the bodies alone took 3.5 to 11 ms.

const StickerData := preload("res://commons/stickers/sticker_data.gd")
const StickerLayer := preload("res://commons/stickers/sticker_layer.gd")
const ConstructionThreads := preload("res://commons/artifacts/sticker_construction/construction_threads.gd")
# --- the furniture, as the web stands it (cardboard3d.ts; the bench's table: stickers.ts BENCH.thickness) ---
const TABLE_TOP := 0.06
const LEG := 0.06
const LEG_IN_X := 0.12             # the legs set in 12 cm along a table's width and 10 cm along its depth
const LEG_IN_Z := 0.1
const WOOD := Color("b98d5f")      # the bench's wood
## C flute: about 4 mm of fluted medium between two liners in 5 mm of board, some 120 to 140 flutes a metre (128 here:
## one wave every 7.8 mm along a cut edge); each liner about a tenth of the thickness
const FLUTE_PITCH := 1.0 / 128.0
const LINER := 0.1
## A cardboard face: the board's paper colour times a pale grain (values just under 1, so the board keeps its colour),
## with faint streaks along the flutes, which run up the wall, and a few darker specks - the web's cardboardGrain (2.5
## mm cells, streaks 0.975 to 1, speckle 0.94 to 1, 3 % of cells 0.8 to 0.92 darker), smoothed between cells so it does
## not read as pixels at arm's length. UV is the point in the board frame, metres.
const FACE_SHADER := """shader_type spatial;
uniform vec3 paper : source_color = vec3(0.769, 0.635, 0.478);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	vec2 cell = UV / 0.0025;
	float streak = 0.975 + 0.025 * noise(vec2(cell.x, 0.5));
	float v = streak * (0.94 + 0.06 * noise(cell));
	float speck = hash(floor(cell * 0.5) + vec2(31.0, 17.0));
	if (speck < 0.03) { v *= 0.8 + 0.12 * hash(floor(cell * 0.5) + vec2(5.0, 3.0)); }
	ALBEDO = paper * v;
	ROUGHNESS = 0.93;
}
"""
## A cut edge: u (UV.x) along the edge in flutes, v (UV.y) across the board's thickness from the front face (0) to the
## back (1). The two liners pale bands at either face, the fluted medium a wave from one liner to the other, the air in
## the flutes in its shadow (the web's fluteTexture: every value the board's colour times 0.92 times 0.72 to 0.97).
const EDGE_SHADER := """shader_type spatial;
uniform vec3 paper : source_color = vec3(0.769, 0.635, 0.478);
uniform float liner = 0.1;
void fragment() {
	float v = UV.y;
	float k = 0.97;
	if (v > liner && v < 1.0 - liner) {
		float amp = (0.5 - liner) * 0.9;
		float wave = 0.5 + amp * sin(6.2831853 * UV.x);
		float slope = amp * 6.2831853 * cos(6.2831853 * UV.x) * 0.64;
		float d = abs(v - wave) / sqrt(1.0 + slope * slope);
		k = mix(0.72, 0.9, 1.0 - smoothstep(0.03, 0.06, d));
	}
	ALBEDO = paper * 0.92 * k;
	ROUGHNESS = 1.0;
}
"""

@export var construction := "research"

var data: Node = null
var tables_node: Node3D = null
var walls_node: Node3D = null
var threads: Node3D = null
var walls: Dictionary = {}         # board id -> its wall's body (StaticBody3D), as stood
var tables: Dictionary = {}        # table id -> its body
var missing: Array = []            # [{board, why}]: the walls not stood
var builds := 0                    # how many times _build ran (a probe asks for one per change)
var made := {"tables": 0, "walls": 0}   # tables and walls made (again), over all builds
var build_ms := 0.0                # what the last build's own slice cost (the bodies it planned are made after it)
var warm_ms: Array = []            # what each frame of making the shared looks cost, before the first build (probes)
var build_frame := -1              # the process frame the last build ran at the end of (probes)
var _queued := false
var _pieces: Array = []            # what the last build still has to make: ["table", t, sig] or ["wall", id, board, look, t, w]
## The looks every construction shares, made once a session: a Shader made from code costs 8 to 11 ms on this desktop
## (measured 2026-11-15, the same code made again costs as much), so they are made one a frame before the first build
## (_warm) and never again. Paper colour -> [face material, edge material]; the tables' one wood.
static var _shaders: Dictionary = {}
static var _looks: Dictionary = {}
static var _wood: StandardMaterial3D = null
static var _boxes: Dictionary = {}   # a size -> [BoxMesh, BoxShape3D]: the tables' parts and the walls' colliders
static var _slabs: Dictionary = {}   # a wall's w and h -> its slab's ArrayMesh

func apply_grid_config(config: Dictionary) -> void:
	construction = str(config.get("construction", construction))
	if is_inside_tree():
		_queue_build()

func _ready() -> void:
	set_process(false)
	if has_meta("config_construction"):
		construction = str(get_meta("config_construction"))
	data = StickerData.get_or_create(get_tree())
	if not data.constructions_changed.is_connected(_queue_build):
		data.constructions_changed.connect(_queue_build)
		data.boards_changed.connect(_queue_build)
	_queue_build()

## One build, at the frame's end, after the last config (edge_carving.gd _queue_build).
func _queue_build() -> void:
	if _queued:
		return
	_queued = true
	_build.call_deferred()

## Before the first build of a session: one of the shared looks made (a shader, the wood), and true when one was - the
## build then waits for the next frame's end, so no frame makes more than one.
func _warm() -> bool:
	var t0 := Time.get_ticks_usec()
	var made_one := true
	if not _shaders.has("face"):
		_shaders["face"] = _shader(FACE_SHADER)
	elif not _shaders.has("edge"):
		_shaders["edge"] = _shader(EDGE_SHADER)
	elif _wood == null:
		_wood = StandardMaterial3D.new()
		_wood.albedo_color = WOOD
		_wood.roughness = 0.8
	else:
		made_one = false
	if made_one:
		warm_ms.append(snappedf(float(Time.get_ticks_usec() - t0) / 1000.0, 0.001))
	return made_one

## A shader from code, and a first material on it, kept (a shader is compiled for its first material).
static func _shader(code: String) -> Shader:
	var sh := Shader.new()
	sh.code = code
	var first := ShaderMaterial.new()
	first.shader = sh
	_shaders["first_" + str(_shaders.size())] = first
	return sh

func _build() -> void:
	if is_inside_tree() and _warm():
		# again at the NEXT frame's end (a call deferred from a deferred call would run in this frame's flush)
		get_tree().process_frame.connect(func(): _build.call_deferred(), CONNECT_ONE_SHOT)
		return
	_queued = false
	if not is_inside_tree() or data == null:
		return
	builds += 1
	build_frame = Engine.get_process_frames()
	var t0 := Time.get_ticks_usec()
	if tables_node == null:
		tables_node = Node3D.new()
		tables_node.name = "Tables"
		add_child(tables_node)
		walls_node = Node3D.new()
		walls_node.name = "Walls"
		add_child(walls_node)
	var c: Dictionary = data.construction(construction)
	# what this build makes is made a piece at a time after it (_process); a build planned again drops what was still
	# to make, and plans from what stands
	_pieces = []
	# the tables
	var by_table: Dictionary = {}
	for t in c.get("tables", []):
		var id := str(t.get("id", ""))
		by_table[id] = t
		var sig := JSON.stringify(t)
		var body: StaticBody3D = tables.get(id)
		if body != null and str(body.get_meta("sig", "")) == sig:
			continue
		if body != null:
			_drop(body)
			tables.erase(id)
		_pieces.append(["table", t, sig])
	for id in tables.keys():
		if not by_table.has(id):
			_drop(tables[id])
			tables.erase(id)
	# the walls: made again when their board's size or paper changed, moved when their place did
	missing = []
	var standing: Dictionary = {}
	for w in c.get("walls", []):
		var bid := str(w.get("board", ""))
		var b: Dictionary = data.board_spec(bid)
		var t: Variant = by_table.get(str(w.get("table", "")))
		if b.is_empty() or not b.has("w"):
			missing.append({"board": bid, "why": "no such board"})
			continue
		if not StickerData.two_sided(b):
			missing.append({"board": bid, "why": "not cardboard"})
			continue
		if not t is Dictionary:
			missing.append({"board": bid, "why": "no such table"})
			continue
		standing[bid] = true
		var look := JSON.stringify([b.get("w"), b.get("h"), str(b.get("paper", ""))])
		var body: StaticBody3D = walls.get(bid)
		if body != null and str(body.get_meta("look", "")) != look:
			_drop(body)
			walls.erase(bid)
			body = null
		if body == null:
			_pieces.append(["wall", bid, b, look, t, w])
		else:
			body.transform = _wall_frame(t, w, b)
	for bid in walls.keys():
		if not standing.has(bid):
			_drop(walls[bid])
			walls.erase(bid)
	# the threads: their own node, drawn again by what they are made of
	if threads == null:
		threads = ConstructionThreads.new()
		threads.name = "Threads"
		threads.set("construction_id", construction)
		add_child(threads)
	elif str(threads.get("construction_id")) != construction:
		threads.set("construction_id", construction)
		threads.call("_again")
	build_ms = float(Time.get_ticks_usec() - t0) / 1000.0
	set_process(not _pieces.is_empty())

## The bodies a build planned, a table or a wall a piece, within the frame's budget shared with the walls' layers and
## the threads (sticker_layer.gd stage_may, stage_spent); off again when they all stand.
func _process(_delta: float) -> void:
	while not _pieces.is_empty():
		var piece: Array = _pieces[0]
		var kind := "build_" + str(piece[0])
		if not StickerLayer.stage_may(kind):
			return
		_pieces.pop_front()
		var t0 := Time.get_ticks_usec()
		if str(piece[0]) == "table":
			tables[str((piece[1] as Dictionary).get("id", ""))] = _table(piece[1], piece[2])
		else:
			var body := _wall(str(piece[1]), piece[2], str(piece[3]))
			body.transform = _wall_frame(piece[4], piece[5], piece[2])
			walls[str(piece[1])] = body
		StickerLayer.stage_spent(kind, Time.get_ticks_usec() - t0)
	set_process(false)

## Where a wall's board frame stands in the construction's frame: at wall_point of its origin, turned R_y(wall_yaw).
static func _wall_frame(t: Dictionary, w: Dictionary, b: Dictionary) -> Transform3D:
	var at: Array = StickerData.wall_point(t, w, b, [0.0, 0.0, 0.0])
	return Transform3D(Basis(Vector3.UP, deg_to_rad(StickerData.wall_yaw(t, w))), Vector3(float(at[0]), float(at[1]), float(at[2])))

func _drop(n: Node) -> void:
	if is_instance_valid(n):
		n.get_parent().remove_child(n)
		n.queue_free()

## A table: a top whose upper face is at h, on four legs, at its `at` turned `yaw`; one body with a collider per part.
func _table(t: Dictionary, sig: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Table_" + str(t.get("id", ""))
	body.set_meta("sig", sig)
	var at: Array = t.get("at", [0.0, 0.0])
	body.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(t.get("yaw", 0.0)))), Vector3(float(at[0]), 0.0, float(at[1])))
	tables_node.add_child(body)
	made.tables += 1
	var w := float(t.get("w", 1.0))
	var d := float(t.get("d", 0.8))
	var h := float(t.get("h", 0.74))
	if _wood == null:
		_warm_all()
	var wood := _wood
	_solid(body, "Top", Vector3(w, TABLE_TOP, d), Vector3(0.0, h - TABLE_TOP / 2.0, 0.0), wood)
	var leg_h := h - TABLE_TOP
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_solid(body, "Leg", Vector3(LEG, leg_h, LEG), Vector3(sx * maxf(0.0, w / 2.0 - LEG_IN_X), leg_h / 2.0, sz * maxf(0.0, d / 2.0 - LEG_IN_Z)), wood)
	return body

## A box part of a table: its mesh and its collider, both the session's one box of that size (_box: a mesh made is a
## buffer on the GPU, and 20 of them were most of a build's 5 to 10 ms).
func _solid(body: Node3D, node_name: String, size: Vector3, at: Vector3, mat: Material) -> void:
	var box := _box(size)
	var m := MeshInstance3D.new()
	m.name = node_name
	m.mesh = box[0]
	m.position = at
	m.material_override = mat
	body.add_child(m)
	var shape := CollisionShape3D.new()
	shape.shape = box[1]
	shape.position = at
	body.add_child(shape)

## The box mesh and box shape of a size, shared by every part of that size in the session (never changed once made).
static func _box(size: Vector3) -> Array:
	var key := "%.5f|%.5f|%.5f" % [size.x, size.y, size.z]
	if not _boxes.has(key):
		var bm := BoxMesh.new()
		bm.size = size
		var bs := BoxShape3D.new()
		bs.size = size
		_boxes[key] = [bm, bs]
	return _boxes[key]

## A wall: its board's slab of cardboard in the board frame, one body whose one box collider is exactly the slab (the
## front at z = 0, the back at z = -CARDBOARD: the layer prints a sticker on the face it faces), meta sticker_host, and
## its StickerLayer (both faces' stickers and scribbles).
func _wall(bid: String, b: Dictionary, look: String) -> StaticBody3D:
	var w := float(b.get("w", 0.8))
	var h := float(b.get("h", 0.6))
	var body := StaticBody3D.new()
	body.name = "Wall_" + bid
	body.set_meta("sticker_host", {"kind": "board", "id": bid})
	body.set_meta("look", look)
	walls_node.add_child(body)
	made.walls += 1
	var shape := CollisionShape3D.new()
	shape.shape = _box(Vector3(w, h, StickerData.CARDBOARD))[1]
	shape.position = Vector3(0.0, 0.0, -StickerData.CARDBOARD / 2.0)
	body.add_child(shape)
	var slab := MeshInstance3D.new()
	slab.name = "Cardboard"
	var slab_key := "%.5f|%.5f" % [w, h]
	if not _slabs.has(slab_key):
		_slabs[slab_key] = _slab(w, h)   # one a size, shared by every wall of it (never changed once made)
	slab.mesh = _slabs[slab_key]
	var looks := _looks_of(Color(str(b.get("paper", "#c4a27a"))))
	slab.set_surface_override_material(0, looks[0])
	slab.set_surface_override_material(1, looks[1])
	body.add_child(slab)
	var layer: Node3D = StickerLayer.new()
	layer.name = "StickerLayer"
	layer.set("host", {"kind": "board", "id": bid})
	layer.set("staged", true)
	body.add_child(layer)
	return body

## The slab's mesh in the board frame: surface 0 its two faces (UV = the point in the board frame, for the grain),
## surface 1 its four cut edges (UV = along the edge in flutes, across from the front face to the back).
static func _slab(w: float, h: float) -> ArrayMesh:
	var x := w / 2.0
	var y := h / 2.0
	var z := -StickerData.CARDBOARD
	var mesh := ArrayMesh.new()
	# accumulators are objects: a packed array held in a Dictionary is a value, and an append to it lands on a copy
	var f := _Part.new()
	_quad(f, [Vector3(-x, -y, 0), Vector3(x, -y, 0), Vector3(x, y, 0), Vector3(-x, y, 0)], [Vector2(-x, -y), Vector2(x, -y), Vector2(x, y), Vector2(-x, y)], Vector3(0, 0, 1))
	_quad(f, [Vector3(-x, -y, z), Vector3(x, -y, z), Vector3(x, y, z), Vector3(-x, y, z)], [Vector2(-x, -y), Vector2(x, -y), Vector2(x, y), Vector2(-x, y)], Vector3(0, 0, -1))
	var e := _Part.new()
	for edge in [[[Vector3(-x, y, 0), Vector3(x, y, 0), Vector3(x, y, z), Vector3(-x, y, z)], w, Vector3(0, 1, 0)],
			[[Vector3(-x, -y, 0), Vector3(x, -y, 0), Vector3(x, -y, z), Vector3(-x, -y, z)], w, Vector3(0, -1, 0)],
			[[Vector3(-x, -y, 0), Vector3(-x, y, 0), Vector3(-x, y, z), Vector3(-x, -y, z)], h, Vector3(-1, 0, 0)],
			[[Vector3(x, -y, 0), Vector3(x, y, 0), Vector3(x, y, z), Vector3(x, -y, z)], h, Vector3(1, 0, 0)]]:
		var l := float(edge[1]) / FLUTE_PITCH
		_quad(e, edge[0], [Vector2(0, 0), Vector2(l, 0), Vector2(l, 1), Vector2(0, 1)], edge[2])
	for part in [f, e]:
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = part.verts
		arrays[Mesh.ARRAY_NORMAL] = part.norms
		arrays[Mesh.ARRAY_TEX_UV] = part.uvs
		arrays[Mesh.ARRAY_INDEX] = part.idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

## A quad from four corners in cyclic order, wound as Godot's front face seen from `out` (clockwise from outside:
## (b - a) x (c - a) points into the slab).
static func _quad(acc: _Part, c: Array, uv: Array, out: Vector3) -> void:
	var base: int = acc.verts.size()
	for i in 4:
		acc.verts.append(c[i])
		acc.norms.append(out)
		acc.uvs.append(uv[i])
	var flip := (Vector3(c[1]) - Vector3(c[0])).cross(Vector3(c[2]) - Vector3(c[0])).dot(out) > 0.0
	if flip:
		acc.idx.append_array([base, base + 2, base + 1, base, base + 3, base + 2])
	else:
		acc.idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])

## One surface of the slab as it is made.
class _Part:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()

## The looks of one paper colour's walls, shared by every construction: [the face (the colour times the grain), the
## edge (times the flutes)], on the session's two shaders.
func _looks_of(paper: Color) -> Array:
	var key := paper.to_html(false)
	if _looks.has(key):
		return _looks[key]
	_warm_all()
	var out: Array = []
	for k in ["face", "edge"]:
		var m := ShaderMaterial.new()
		m.shader = _shaders[k]
		m.set_shader_parameter("paper", paper)
		out.append(m)
	(out[1] as ShaderMaterial).set_shader_parameter("liner", LINER)
	_looks[key] = out
	return out

## The shared looks all made at once (a build that did not wait for _warm: one called from a tool or a probe).
func _warm_all() -> void:
	while _warm():
		pass

## Where a wall's board frame stands (for probes and tools): the wall's body, or null when it is not stood.
func wall(board_id: String) -> StaticBody3D:
	return walls.get(board_id)

## Whether anything of it is still to be built or drawn: a build queued, a table or a wall still to make, a wall's layer
## or the threads still drawing (STAGED). False once what the truth holds is all drawn.
func drawing() -> bool:
	if _queued or not _pieces.is_empty():
		return true
	for bid in walls:
		var layer: Node = (walls[bid] as Node).get_node_or_null("StickerLayer") if is_instance_valid(walls[bid]) else null
		if layer != null and layer.has_method("busy") and bool(layer.call("busy")):
			return true
	return threads != null and threads.has_method("busy") and bool(threads.call("busy"))

## What its staged drawing has cost (for probes): over its walls' layers and its threads, the pieces done and their time.
func stage_cost() -> Dictionary:
	var usec := 0
	var pieces := 0
	for bid in walls:
		var layer: Node = (walls[bid] as Node).get_node_or_null("StickerLayer") if is_instance_valid(walls[bid]) else null
		if layer != null:
			usec += int(layer.get("stage_usec") if layer.get("stage_usec") != null else 0)
			pieces += int(layer.get("stage_pieces") if layer.get("stage_pieces") != null else 0)
	if threads != null:
		usec += int(threads.get("stage_usec") if threads.get("stage_usec") != null else 0)
		pieces += int(threads.get("stage_pieces") if threads.get("stage_pieces") != null else 0)
	return {"ms": float(usec) / 1000.0, "pieces": pieces}
