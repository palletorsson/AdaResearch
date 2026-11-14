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
## Origin: the floor, under the middle of the board; the face looks along +Z, its centre `face_height` up (1.35 m).

const StickerData := preload("res://commons/stickers/sticker_data.gd")
const StickerLayer := preload("res://commons/stickers/sticker_layer.gd")
const BOARD_DEPTH := 0.03          # stickers.ts BOARD_DEPTH
const FRAME := 0.04                # the timber's width round the paper
const FRAME_PROUD := 0.006         # how far the frame stands in front of the paper
## how far the timber laps over the paper's edge: flush, the paper's sides and the timber's inner faces were the same
## planes and fought (a pale stripe down both sides in the probe's board.png)
const FRAME_LAP := 0.003
const TIMBER := Color("c9a978")    # sticky-map's frame timber (stickers.ts PALETTES 'ink')
const TIMBER_DARK := Color("b98d5f")
const INK := Color("2b1d14")

@export var board := "visitors"
@export var face_height := 1.35

var data: Node = null
var face: StaticBody3D = null
var layer: Node3D = null
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

## Built from the board's record; built again only when the record (or the config) changed.
func _build() -> void:
	var b: Dictionary = data.board(board)
	var w := float(b.get("w", 1.6))
	var h := float(b.get("h", 1.0))
	var paper := Color(str(b.get("paper", "#f4f0e6")))
	var title := str(b.get("title", board))
	var sig := "%s|%s|%s|%s|%s|%s" % [board, w, h, paper.to_html(false), title, face_height]
	if sig == _built:
		return
	_built = sig
	for c in get_children():
		remove_child(c)
		c.queue_free()
	# the face: a body whose frame is the face's centre, its collider's front exactly at z = 0
	face = StaticBody3D.new()
	face.name = "Face"
	face.position = Vector3(0, face_height, 0)
	face.set_meta("sticker_host", {"kind": "board", "id": board})
	add_child(face)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w, h, BOARD_DEPTH)
	shape.shape = box
	shape.position = Vector3(0, 0, -BOARD_DEPTH / 2.0)
	face.add_child(shape)
	_box(face, "Paper", Vector3(w, h, BOARD_DEPTH), Vector3(0, 0, -BOARD_DEPTH / 2.0), paper, 0.92)
	# the frame: timber round the paper, a little proud of it, a body of its own (no host)
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
		_box(frame_body, "Timber", part[0], part[1], TIMBER, 0.7, true)
	# the stand: two posts behind the board, down to the floor, and their feet
	var bottom := face_height - h / 2.0 - FRAME
	if bottom > 0.05:
		var stand := StaticBody3D.new()
		stand.name = "Stand"
		add_child(stand)
		var post_z := -BOARD_DEPTH - 0.03
		for sx in [-w / 2.0 + 0.15, w / 2.0 - 0.15]:
			_box(stand, "Post", Vector3(0.05, face_height + h / 2.0 - 0.1, 0.05), Vector3(sx, (face_height + h / 2.0 - 0.1) / 2.0, post_z), TIMBER_DARK, 0.75, true)
			_box(stand, "Foot", Vector3(0.07, 0.04, 0.5), Vector3(sx, 0.02, post_z + 0.02), TIMBER_DARK, 0.75, true)
	# the title, over the frame
	var label := Label3D.new()
	label.name = "Title"
	label.text = title
	label.font_size = 48
	label.pixel_size = 0.0011
	label.modulate = INK
	label.outline_size = 0
	label.double_sided = false
	label.position = Vector3(0, face_height + h / 2.0 + FRAME + 0.045, 0.004)
	add_child(label)
	# the stickers: drawn in the face's frame
	layer = StickerLayer.new()
	layer.name = "StickerLayer"
	layer.host = {"kind": "board", "id": board}
	face.add_child(layer)

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
