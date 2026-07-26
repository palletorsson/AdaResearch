extends Node3D

## Request Note — the project's own annotation apparatus, placed in the world.
##
## STAGE-2 DNA PROMOTION (2026-07-26). This is the most-placed artifact in the
## project — 716 placements, more than any teaching artifact — and before this it
## had ZERO exports and no body: a Label3D billboarding in mid-air with a sine bob.
## Its docstring claimed the text sat "on a cream plate"; there was no plate. The
## single most common object in the world was naked floating text, which is the one
## thing the cabinet grammar's first rule forbids.
##
## Promoted the way surreal_lab is promoted: one script, several lineages off a
## parameter, instead of one fixed thing. Two axes —
##
##   mode  the BODY the note has          float · plate · stake · decal
##   tone  the REGISTER it speaks in      request · bug · question · done
##
## mode=float is the old behaviour exactly, and it is the default, so all 716
## existing placements are untouched. A note is apparatus, not scenery: it is
## deliberately NOT in the world's visual family, because a dev annotation that
## looks like a exhibit is a lie about what it is.
##
## Usage in map_data.json:
##   "request_note#text:Fix the lighting here"
##   "request_note#text:Wall clips the ramp#mode:stake#tone:bug"
##   "request_note#key:bug_42#mode:plate"

## The note's body. float = billboard text only (legacy default, no body);
## plate = a card the text is printed on; stake = a card on a post that meets the
## floor; decal = laid flat on the ground, read by looking down.
@export var mode: String = "float"
## The register the note speaks in — drives the accent stripe and the corner glyph.
@export var tone: String = "request"
## The note's message. Overridden by #text: or #key: in map_data.
@export var text: String = "REQUEST"
## Height the card floats at, for float and plate.
@export var hover_height: float = 0.5
## Card width in metres (plate, stake, decal).
@export var card_width: float = 0.62

const TONES := {
	"request": {"accent": Color(0.92, 0.62, 0.12), "glyph": "»"},
	"bug": {"accent": Color(0.86, 0.26, 0.20), "glyph": "!"},
	"question": {"accent": Color(0.26, 0.56, 0.92), "glyph": "?"},
	"done": {"accent": Color(0.32, 0.66, 0.34), "glyph": "+"},
}
const PAPER := Color(0.90, 0.87, 0.80)
const INK := Color(0.12, 0.12, 0.12)

var _text: String = "REQUEST"
var _label: Label3D
var _time: float = 0.0
var _base_y: float = 0.0
var _bobs: bool = true


func _ready() -> void:
	if text != "REQUEST":
		_text = text
	_build()


func _accent() -> Color:
	var t: Dictionary = TONES.get(tone, TONES["request"])
	return t["accent"]


func _glyph() -> String:
	var t: Dictionary = TONES.get(tone, TONES["request"])
	return str(t["glyph"])


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_bobs = true
	match mode:
		"plate":
			_build_card(Vector3(0, hover_height, 0), false)
		"stake":
			_build_stake()
		"decal":
			_build_decal()
		_:
			_build_float()
	_base_y = transform.origin.y


## LEGACY LINEAGE — untouched. Billboard text, no body, gentle bob. This is what
## all 716 existing placements get, and changing it silently would rewrite the look
## of a fifth of the project's maps.
func _build_float() -> void:
	_label = _make_label(48, 500)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.transform.origin.y = hover_height
	add_child(_label)


## The cream plate the old docstring promised and never built: the text is printed
## ON something. Faces +Z rather than billboarding, because a card has a front.
func _build_card(centre: Vector3, grounded: bool) -> void:
	var h: float = card_width * 0.42
	var card := MeshInstance3D.new()
	card.name = "Card"
	var box := BoxMesh.new()
	box.size = Vector3(card_width, h, 0.012)
	card.mesh = box
	card.material_override = _matte(PAPER)
	card.position = centre
	add_child(card)

	# tone stripe down the leading edge — the register, readable before the words
	var stripe := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(0.030, h, 0.014)
	stripe.mesh = sb
	stripe.material_override = _matte(_accent())
	stripe.position = centre + Vector3(-card_width * 0.5 + 0.015, 0, 0.001)
	add_child(stripe)

	var g := Label3D.new()
	g.text = _glyph()
	g.font_size = 40
	g.pixel_size = 0.001
	g.modulate = _accent()
	g.position = centre + Vector3(-card_width * 0.5 + 0.062, h * 0.5 - 0.045, 0.010)
	add_child(g)

	_label = _make_label(34, int(card_width * 620.0))
	_label.position = centre + Vector3(0.026, 0, 0.010)
	add_child(_label)
	if grounded:
		_bobs = false


## A surveyor's stake. The note MEETS THE FLOOR — for a todo about a place rather
## than about the air above it.
func _build_stake() -> void:
	# The post stops at the card's BOTTOM EDGE. Running it to the card's centre puts
	# the shaft through the face of the note, which reads as two objects clipping
	# rather than a card mounted on a stake.
	var card_h: float = card_width * 0.42
	var post_h: float = hover_height
	var post := MeshInstance3D.new()
	post.name = "Stake"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.012
	cyl.bottom_radius = 0.012
	cyl.height = post_h
	post.mesh = cyl
	post.material_override = _matte(Color(0.34, 0.30, 0.24))
	post.position = Vector3(0, post_h * 0.5, 0)
	add_child(post)
	# a painted band at the foot, the way a real marker stake is banded
	var band := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.014
	bc.bottom_radius = 0.014
	bc.height = 0.06
	band.mesh = bc
	band.material_override = _matte(_accent())
	band.position = Vector3(0, 0.10, 0)
	add_child(band)
	# seated just above the post top, overlapping by a hair so it reads as mounted
	_build_card(Vector3(0, post_h + card_h * 0.5 - 0.015, 0), true)


## Laid flat on the ground and read by looking down — the horizontal register, for
## marking a spot rather than labelling a thing.
func _build_decal() -> void:
	var h: float = card_width * 0.42
	var card := MeshInstance3D.new()
	card.name = "Decal"
	var box := BoxMesh.new()
	box.size = Vector3(card_width, 0.008, h)
	card.mesh = box
	card.material_override = _matte(PAPER)
	card.position = Vector3(0, 0.006, 0)
	add_child(card)

	var stripe := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(card_width, 0.010, 0.030)
	stripe.mesh = sb
	stripe.material_override = _matte(_accent())
	stripe.position = Vector3(0, 0.007, -h * 0.5 + 0.015)
	add_child(stripe)

	_label = _make_label(30, int(card_width * 620.0))
	_label.rotation_degrees = Vector3(-90, 0, 0)
	_label.position = Vector3(0, 0.013, 0.012)
	add_child(_label)
	_bobs = false


func _make_label(size: int, width: int) -> Label3D:
	var l := Label3D.new()
	l.name = "Text"
	l.text = _text
	l.font_size = size
	l.pixel_size = 0.001
	l.modulate = INK
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.width = width
	l.outline_size = 4
	l.outline_modulate = Color(PAPER.r, PAPER.g, PAPER.b, 0.8)
	return l


func _matte(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	m.metallic = 0.0
	return m


func _process(delta: float) -> void:
	if not _bobs:
		return
	_time += delta
	transform.origin.y = _base_y + sin(_time * 1.5) * 0.015


func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false
	if config_data.has("mode"):
		mode = str(config_data["mode"])
		rebuild = true
	if config_data.has("tone"):
		tone = str(config_data["tone"])
		rebuild = true
	if config_data.has("card_width"):
		card_width = float(config_data["card_width"])
		rebuild = true
	if config_data.has("hover_height"):
		hover_height = float(config_data["hover_height"])
		rebuild = true
	if config_data.has("text"):
		_text = str(config_data["text"])
	if config_data.has("key"):
		_text = _load_key(str(config_data["key"]))
	if rebuild and is_inside_tree():
		_build()
	elif _label:
		_label.text = _text


func _load_key(key_name: String) -> String:
	var grid_system: Node = get_tree().get_first_node_in_group("grid_system") if is_inside_tree() else null
	var map_name: String = ""
	if grid_system and "map_name" in grid_system:
		map_name = str(grid_system.map_name)
	if map_name != "":
		var path: String = "res://commons/maps/%s/requests.json" % map_name
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var json := JSON.new()
				if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
					if (json.data as Dictionary).has(key_name):
						return str((json.data as Dictionary)[key_name])
	return "[%s]" % key_name
