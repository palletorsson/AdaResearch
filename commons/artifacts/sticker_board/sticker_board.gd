extends Node3D
## THE STICKER BOARD: the visitors' board (config `board`, default "visitors") - the same flat surface the encyclopedia's
## /stickers page draws in SVG (Board) and in three.js (3D), drawn here from the same files (commons/data/stickers/,
## through StickerData): the board's w x h in metres in its paper colour, a thin timber frame, a stand, its title.
##
## The board's frame is its face (stickers.ts: origin at the middle of the face, x right, y up, z out; a sticker on it
## has n = +Z). That frame is the StaticBody3D "Face": its box collider's front is EXACTLY the face (z = 0, not proud of
## it, so a stuck sticker lies on the paper, never floating), it carries meta sticker_host {kind: board, id} for the
## pad, and its StickerLayer child draws the board's stickers. The frame and the stand have their own bodies, without a
## host: a ray that meets the frame is not a ray that meets the board.
##
## A board with DEPTH (boards.json `depth`, read as the server reads it: StickerData.board_spec) is an INSTALLATION: its
## stickers hang anywhere from the paper to `depth` in front of it (the layer draws each at its at.z), the paper is cork
## (a grain over the paper's colour) in a darker frame, and with `hang` a RAIL runs forward from the frame's top - two
## arms, a front beam and two front posts to the floor - from which every live sticker hangs on a cord
## (stickers.ts cordOf) on a rod at its depth. The Threads child (sticker_threads.gd) draws the threads tied between
## the stickers, their tags, the pins, the cords and the rods; all of it is redrawn when the truth changes. A tall board
## stands on its stand at least STAND_CLEAR over the floor (the mind map is 2.8 m high: at the default 1.35 its paper
## went into the floor).
##
## Origin: the floor, under the middle of the board; the face looks along +Z, its centre `face_height` up (1.35 m, or
## h / 2 + STAND_CLEAR for a board taller than that allows).

const StickerData := preload("res://commons/stickers/sticker_data.gd")
const StickerLayer := preload("res://commons/stickers/sticker_layer.gd")
const StickerThreads := preload("res://commons/artifacts/sticker_board/sticker_threads.gd")
const BOARD_DEPTH := 0.03          # stickers.ts BOARD_DEPTH
const FRAME := 0.04                # the timber's width round the paper
const FRAME_PROUD := 0.006         # how far the frame stands in front of the paper
## how far the timber laps over the paper's edge: flush, the paper's sides and the timber's inner faces were the same
## planes and fought (a pale stripe down both sides in the probe's board.png)
const FRAME_LAP := 0.003
const TIMBER := Color("c9a978")    # sticky-map's frame timber (stickers.ts PALETTES 'ink')
const TIMBER_DARK := Color("b98d5f")
const WALNUT := Color("6b4a2f")    # the rail of a hanging board: darker than the cork and its frame
const INK := Color("2b1d14")
const STAND_CLEAR := 0.2           # a tall board's paper stands at least this far over the floor
const ARM := 0.045                 # the rail's timber, square
## Cork: the paper's own colour, grained (granules about 1 cm and 4 mm, dark specks), from the board frame's position,
## so a deep board reads as a pin board at arm's length. No texture to load or make.
const CORK_SHADER := """shader_type spatial;
uniform vec3 paper : source_color = vec3(0.788, 0.663, 0.471);
varying vec3 lp;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() { lp = VERTEX; }
void fragment() {
	float g = noise(lp.xy * 90.0) * 0.6 + noise(lp.xy * 260.0) * 0.4;
	float speck = step(0.9, hash(floor(lp.xy * 420.0)));
	ALBEDO = paper * (0.88 + 0.2 * g) * (1.0 - 0.22 * speck);
	ROUGHNESS = 0.96;
}
"""

@export var board := "visitors"
@export var face_height := 1.35

var data: Node = null
var face: StaticBody3D = null
var layer: Node3D = null
var threads: Node3D = null
var rail: StaticBody3D = null
var _built := ""

func apply_grid_config(config: Dictionary) -> void:
	board = str(config.get("board", board))
	face_height = clampf(float(config.get("face_height", face_height)), 0.6, 3.0)
	if is_inside_tree():
		_build()

func _ready() -> void:
	var cfg := {}
	for key in ["board", "face_height"]:
		if has_meta("config_" + key):
			cfg[key] = get_meta("config_" + key)
	if not cfg.is_empty():
		board = str(cfg.get("board", board))
		face_height = clampf(float(cfg.get("face_height", face_height)), 0.6, 3.0)
	data = StickerData.get_or_create(get_tree())
	data.boards_changed.connect(_build)
	_build()

## Built from the board's record (as the server reads it: w, h, paper, title, depth, hang); built again only when the
## record (or the config) changed.
func _build() -> void:
	var b: Dictionary = data.board_spec(board) if data.has_method("board_spec") else data.board(board)
	var w := float(b.get("w", 1.6))
	var h := float(b.get("h", 1.0))
	var paper := Color(str(b.get("paper", "#f4f0e6")))
	var title := str(b.get("title", board))
	var deep := float(b.get("depth", 0.0))
	var hang := bool(b.get("hang", false)) and deep > 0.0
	var centre := maxf(face_height, h / 2.0 + FRAME + STAND_CLEAR)   # 1.35 for every board but a tall one
	var sig := "%s|%s|%s|%s|%s|%s|%s|%s" % [board, w, h, paper.to_html(false), title, centre, deep, hang]
	if sig == _built:
		return
	_built = sig
	for c in get_children():
		remove_child(c)
		c.queue_free()
	rail = null
	# the face: a body whose frame is the face's centre, its collider's front exactly at z = 0
	face = StaticBody3D.new()
	face.name = "Face"
	face.position = Vector3(0, centre, 0)
	face.set_meta("sticker_host", {"kind": "board", "id": board})
	add_child(face)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w, h, BOARD_DEPTH)
	shape.shape = box
	shape.position = Vector3(0, 0, -BOARD_DEPTH / 2.0)
	face.add_child(shape)
	var paper_mesh := _box(face, "Paper", Vector3(w, h, BOARD_DEPTH), Vector3(0, 0, -BOARD_DEPTH / 2.0), paper, 0.92)
	if deep > 0.0:
		var cork := ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = CORK_SHADER
		cork.shader = sh
		cork.set_shader_parameter("paper", paper)
		paper_mesh.material_override = cork
	# the frame: timber round the paper, a little proud of it, a body of its own (no host); darker round cork
	var frame_body := StaticBody3D.new()
	frame_body.name = "Frame"
	frame_body.position = face.position
	add_child(frame_body)
	var depth := BOARD_DEPTH + FRAME_PROUD + 0.006
	var z := FRAME_PROUD - depth / 2.0
	var wide := FRAME + FRAME_LAP      # each timber laps FRAME_LAP over the paper's edge
	for part in [[Vector3(w + 2 * FRAME, wide, depth), Vector3(0, h / 2.0 + FRAME / 2.0 - FRAME_LAP / 2.0, z)],
			[Vector3(w + 2 * FRAME, wide, depth), Vector3(0, -h / 2.0 - FRAME / 2.0 + FRAME_LAP / 2.0, z)],
			[Vector3(wide, h, depth), Vector3(-w / 2.0 - FRAME / 2.0 + FRAME_LAP / 2.0, 0, z)],
			[Vector3(wide, h, depth), Vector3(w / 2.0 + FRAME / 2.0 - FRAME_LAP / 2.0, 0, z)]]:
		_box(frame_body, "Timber", part[0], part[1], TIMBER_DARK if deep > 0.0 else TIMBER, 0.7, true)
	# the stand: two posts behind the board, down to the floor, and their feet
	var bottom := centre - h / 2.0 - FRAME
	if bottom > 0.05:
		var stand := StaticBody3D.new()
		stand.name = "Stand"
		add_child(stand)
		var post_z := -BOARD_DEPTH - 0.03
		for sx in [-w / 2.0 + 0.15, w / 2.0 - 0.15]:
			_box(stand, "Post", Vector3(0.05, centre + h / 2.0 - 0.1, 0.05), Vector3(sx, (centre + h / 2.0 - 0.1) / 2.0, post_z), TIMBER_DARK, 0.75, true)
			_box(stand, "Foot", Vector3(0.07, 0.04, 0.5), Vector3(sx, 0.02, post_z + 0.02), TIMBER_DARK, 0.75, true)
	# the rail of a hanging board: in the face's frame, at the paper's top edge (y = h / 2, where every cord begins),
	# two arms forward past the depth, a front beam, and two front posts down to the floor
	if hang:
		rail = StaticBody3D.new()
		rail.name = "Rail"
		rail.position = face.position
		add_child(rail)
		var ry := h / 2.0 + StickerThreads.ROD_R          # the rods' axis: their underside is the cords' top
		var ax := w / 2.0 + FRAME + ARM / 2.0              # the arms stand just outside the frame
		var reach := deep + ARM                            # the arms reach past the deepest rod
		var z0 := -BOARD_DEPTH
		for sx in [-ax, ax]:
			_box(rail, "Arm", Vector3(ARM, ARM, reach - z0), Vector3(sx, ry, (reach + z0) / 2.0), WALNUT, 0.6, true)
			if bottom > 0.05:
				var post_h := centre + ry - ARM / 2.0
				_box(rail, "FrontPost", Vector3(ARM, post_h, ARM), Vector3(sx, ry - ARM / 2.0 - post_h / 2.0, reach - ARM / 2.0), WALNUT, 0.6, true)
		_box(rail, "Beam", Vector3(2.0 * ax + ARM, ARM, ARM), Vector3(0, ry, reach + ARM / 2.0), WALNUT, 0.6, true)
	# the title, over the frame (a wide board's grows with it); on a hanging board on top of the rail's front beam,
	# outlined in paper so it reads against whatever is behind it (over the frame it hid behind the rods)
	var grow := maxf(1.0, w / 2.4)
	var label := Label3D.new()
	label.name = "Title"
	label.text = title
	label.font_size = 48
	label.pixel_size = 0.0011 * grow
	label.modulate = INK
	label.outline_size = 0
	label.double_sided = false
	label.position = Vector3(0, centre + h / 2.0 + FRAME + 0.045 * grow, 0.004)
	if hang:
		label.outline_size = 12
		label.outline_modulate = Color("f6f0e2")
		label.position = Vector3(0, centre + h / 2.0 + StickerThreads.ROD_R + ARM / 2.0 + 0.03 * grow, deep + ARM * 1.5 + 0.002)
	add_child(label)
	# the stickers: drawn in the face's frame
	layer = StickerLayer.new()
	layer.name = "StickerLayer"
	layer.host = {"kind": "board", "id": board}
	face.add_child(layer)
	# the threads tied between them, their tags, the pins, and on a hanging board the cords and the rods
	threads = StickerThreads.new()
	threads.name = "Threads"
	threads.board_id = board
	face.add_child(threads)

func _box(parent: Node3D, node_name: String, box_size: Vector3, at: Vector3, colour: Color, rough: float, solid := false) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = node_name
	var bm := BoxMesh.new()
	bm.size = box_size
	m.mesh = bm
	m.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = rough
	m.material_override = mat
	parent.add_child(m)
	if solid:
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = box_size
		shape.shape = bs
		shape.position = at
		parent.add_child(shape)
	return m
