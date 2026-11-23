# MenuBoard.gd - a board that says how the in-game menu works, in sticker notes and badge notes
#
# @identity
# essence: a standing board with six sticker notes on the menu (open it, its tabs, choose, place, the belt, this floor) and the four verb badges with what each does and whether it is the visitor's yet
# desire: the learner knows which button opens the board and how a thing gets from the belt into the world before trying it
# critical_parameter: none; the words are data (commons/data/prefab_test/menu_board.json) and the badge notes are read from the coins (commons/data/badges/coins.json)
# triggers: none; the badge notes re-read whether a verb is collected every two seconds
# emerges: the visitor sees which verbs are still locked, here, before the floor that gives them
# relationships: explains [[select_board]] (the big board), [[prefab_belt]] and the inventory hand; the badge notes are the verbs of [[badge_coin]]
# truth: on this floor one can place and take back; lifting, pushing, turning and resizing come as coins further down.
extends Node3D

## WHERE THIS COMES FROM. Palle, 22 November 2026: "Add an infoboard explaining with stickers and badges notes how
## to use the in game menu."
##
## The notes are drawn in the stickers' look - a paper cut with a white edge, a little turned, a soft shadow - by
## this board itself. They are NOT laid in the sticker app (commons/data/stickers): they are instructions, not
## readings of a text, and that truth takes only lines quoted word for word from the halls.
## The badges are drawn as coins. Their words (what the verb does, the desktop keys, the headset's way) come from
## coins.json, and LOCKED / YOURS from the visitor's own collection (commons/player/badge_verbs.gd).
## Origin: the floor, under the middle of the board; the face looks along +Z.

const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const BadgeVerbs = preload("res://commons/player/badge_verbs.gd")
const WORDS := "res://commons/data/prefab_test/menu_board.json"
const COINS := "res://commons/data/badges/coins.json"
const WIDE := 3.4
const TALL := 1.9
const FACE_Y := 1.25             # the middle of the face over the floor (the floor row stands the board at 1.3 times this size)
const TIMBER := Color("c9a978")
const PAPER := Color("f4f0e6")
const INK := Color("1d1d1f")
const GOLD := Color("d9b45a")

var notes: Array[Node3D] = []
var badges: Array[Dictionary] = []     # {verb, state: Label3D}
var words := {}
var _tick := 0.0


func apply_grid_config(_config: Dictionary) -> void:
	pass


func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(WORDS)) if FileAccess.file_exists(WORDS) else null
	words = parsed if parsed is Dictionary else {}
	_build()


func _build() -> void:
	# the stand and the board
	for sx in [-1.0, 1.0]:
		Kit.block(self, Vector3(0.07, FACE_Y + TALL * 0.5, 0.07), Vector3(sx * (WIDE * 0.5 - 0.2), (FACE_Y + TALL * 0.5) * 0.5, -0.06), Color("6b4a2f"), true)
	Kit.block(self, Vector3(WIDE + 0.08, TALL + 0.08, 0.03), Vector3(0, FACE_Y, -0.02), TIMBER, false).name = "Frame"
	Kit.block(self, Vector3(WIDE, TALL, 0.012), Vector3(0, FACE_Y, 0.0), PAPER, false).name = "Paper"
	var top := FACE_Y + TALL * 0.5
	_text(self, str(words.get("title", "THE MENU")), Vector3(-WIDE * 0.5 + 0.12, top - 0.13, 0.012), 0.0021, 64, HORIZONTAL_ALIGNMENT_LEFT, INK)
	_text(self, str(words.get("subtitle", "")), Vector3(-WIDE * 0.5 + 0.12, top - 0.27, 0.012), 0.0011, 46, HORIZONTAL_ALIGNMENT_LEFT, Color("3d362f"))
	# six sticker notes, three across, on the left two thirds
	var list: Array = words.get("notes", [])
	var note_w := 0.66
	var note_h := 0.62
	for i in list.size():
		var col := i % 3
		var row := i / 3
		var at := Vector3(-WIDE * 0.5 + 0.12 + note_w * 0.5 + col * (note_w + 0.06), top - 0.42 - note_h * 0.5 - row * (note_h + 0.07), 0.012)
		notes.append(_note(list[i], at, note_w, note_h))
	# the badge notes, down the right third
	var left := -WIDE * 0.5 + 0.12 + 3.0 * (note_w + 0.06) + 0.04
	_text(self, str(words.get("badges_title", "BADGES")), Vector3(left, top - 0.13, 0.012), 0.0013, 50, HORIZONTAL_ALIGNMENT_LEFT, INK)
	var room := WIDE * 0.5 - 0.1 - left
	var about := _text(self, str(words.get("badges_note", "")), Vector3(left, top - 0.22, 0.012), 0.00086, 40, HORIZONTAL_ALIGNMENT_LEFT, Color("3d362f"))
	_wrap(about, left, room)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(COINS)) if FileAccess.file_exists(COINS) else null
	var verbs: Dictionary = (parsed as Dictionary).get("verbs", {}) if parsed is Dictionary else {}
	var n := 0
	for verb: String in verbs:
		_badge(verb, verbs[verb], Vector3(left + 0.11, top - 0.56 - n * 0.325, 0.012), room - 0.26)
		n += 1
	_states()


## A sticker note: a soft shadow, a white cut edge, the paper, a heading and its lines.
func _note(data: Dictionary, at: Vector3, w: float, h: float) -> Node3D:
	var note := Node3D.new()
	note.name = "Note_" + str(data.get("title", "")).to_lower().replace(" ", "_")
	note.position = at
	note.rotation.z = deg_to_rad(float(data.get("turn", 0.0)))
	add_child(note)
	var shade := _card(note, Vector3(w + 0.03, h + 0.03, 0.001), Vector3(0.012, -0.014, 0.0005), Color(0.1, 0.08, 0.06, 0.28))
	(shade.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_card(note, Vector3(w + 0.03, h + 0.03, 0.002), Vector3(0, 0, 0.002), Color("ffffff"))
	_card(note, Vector3(w, h, 0.002), Vector3(0, 0, 0.004), Color.from_string(str(data.get("colour", "#ffe066")), Color("ffe066")))
	_text(note, str(data.get("title", "")), Vector3(-w * 0.5 + 0.035, h * 0.5 - 0.06, 0.0065), 0.00105, 52, HORIZONTAL_ALIGNMENT_LEFT, INK)
	var lines := PackedStringArray()
	for line in data.get("lines", []): lines.append(str(line))
	var body := _text(note, "\n".join(lines), Vector3(-w * 0.5 + 0.035, h * 0.5 - 0.14, 0.0065), 0.00098, 40, HORIZONTAL_ALIGNMENT_LEFT, INK)
	_wrap(body, -w * 0.5 + 0.035, w - 0.07)
	return note


## A badge note: the coin, the verb, what it does, how, and whether it is the visitor's.
func _badge(verb: String, data: Dictionary, at: Vector3, room: float) -> void:
	var coin := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.1
	disc.bottom_radius = 0.1
	disc.height = 0.016
	disc.radial_segments = 40
	coin.mesh = disc
	coin.name = "Coin_" + verb
	coin.position = at + Vector3(0, 0, 0.01)
	coin.rotation.x = PI / 2.0
	var metal := StandardMaterial3D.new()
	metal.albedo_color = GOLD
	metal.metallic = 0.75
	metal.roughness = 0.32
	coin.material_override = metal
	add_child(coin)
	_text(self, str(data.get("title", verb)).substr(0, 1).to_upper(), at + Vector3(0, 0, 0.021), 0.0022, 60, HORIZONTAL_ALIGNMENT_CENTER, Color("3a2c12"))
	var x := at.x + 0.15
	_text(self, str(data.get("title", verb)).to_upper(), Vector3(x, at.y + 0.085, at.z), 0.00105, 50, HORIZONTAL_ALIGNMENT_LEFT, INK)
	var state := _text(self, "", Vector3(x + 0.42, at.y + 0.085, at.z), 0.00082, 44, HORIZONTAL_ALIGNMENT_LEFT, INK)
	var body := _text(self, "%s.\nDesktop: %s.\nHeadset: %s." % [str(data.get("does", "")), str(data.get("desktop", "")), str(data.get("vr", ""))], Vector3(x, at.y + 0.04, at.z), 0.00078, 40, HORIZONTAL_ALIGNMENT_LEFT, Color("2f2924"))
	_wrap(body, x, room)
	badges.append({"verb": verb, "state": state})


func _card(parent: Node3D, size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
	var card := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	card.mesh = box
	card.position = at
	var paint := StandardMaterial3D.new()
	paint.albedo_color = colour
	paint.roughness = 0.9
	card.material_override = paint
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(card)
	return card


func _text(parent: Node3D, said: String, at: Vector3, pixel: float, font: int, align: HorizontalAlignment, colour: Color) -> Label3D:
	var label := Label3D.new()
	label.text = said
	label.position = at
	label.pixel_size = pixel
	label.font_size = font
	label.outline_size = 0
	label.modulate = colour
	label.horizontal_alignment = align
	parent.add_child(label)
	return label


## A block of lines that starts at `start` (the parent's x), is `metres` wide, wraps, and hangs down from its place.
func _wrap(label: Label3D, start: float, metres: float) -> void:
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.width = metres / label.pixel_size
	label.position.x = start


## LOCKED or YOURS, from the visitor's own coins.
func _states() -> void:
	for badge in badges:
		var locked := BadgeVerbs.locked(str(badge.verb), false)
		var label := badge.state as Label3D
		label.text = str(words.get("locked", "LOCKED")) if locked else str(words.get("yours", "YOURS"))
		label.modulate = Color("b0361f") if locked else Color("1f7a3a")


func _process(delta: float) -> void:
	_tick += delta
	if _tick < 2.0: return
	_tick = 0.0
	_states()
