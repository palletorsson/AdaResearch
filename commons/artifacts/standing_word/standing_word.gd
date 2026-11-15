extends Node3D
## A WORD STANDING ON THE FLOOR (the pass, 2026-11-15)
##
## Palle, 2026-11-15, with a picture of red letters ERROR standing on a floor, seen from behind: "add letter like
## this for the paradoxes, error, null, infinity, etc".
##
## One word in thick red letters, as tall as a person, standing on the slab. From the front it reads; from behind
## it is the same letters the wrong way round, which nobody arranged: a word has a side it is said from. It is a
## landmark for a hall's idea - the one word a visitor can see from the arrival - and it is solid: you walk round it.
##
## `word` is the axis, the words the foundations halls keep coming back to: ERROR (what both answers at Russell's
## bench amount to), NULL (the set that contains nothing, where the four sets begin), INFINITY (the hotel that is
## full and takes one more), TRUE and PROVABLE (the two words Goedel's theorem pulls apart), EVERYTHING (the
## collection the repair gives up). `text`, when it is not empty, stands instead of the axis's word.
##
## The letters are a TextMesh in commons/font/static/Roboto_Condensed-ExtraBold.ttf, extruded. Not the heaviest
## face: in Roboto-Black the P and the R have contours that cross themselves, a TextMesh cannot triangulate them,
## and ERROR stood with three of its letters as empty outlines (tools/probes/standing_word_faces.gd lists, for
## every heavy face of the project, the capitals that come out without a front).
##
## `tall` is the height of a capital in metres, `deep` the extrusion, `fit_width` the most room it may take along
## the floor (a longer word is made smaller, not cut).
const FACE := "res://commons/font/static/Roboto_Condensed-ExtraBold.ttf"
const WORDS := ["ERROR", "NULL", "INFINITY", "TRUE", "PROVABLE", "EVERYTHING"]

@export_enum("ERROR", "NULL", "INFINITY", "TRUE", "PROVABLE", "EVERYTHING") var word := "ERROR"
@export var text := ""
@export var tall := 1.6
@export var deep := 0.34
@export var fit_width := 8.0
@export var colour := Color("c1121c")

var _letters: MeshInstance3D
var _solid: StaticBody3D
var _size := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	for key in ["word", "text", "tall", "deep", "fit_width", "colour"]:
		if has_meta("config_" + key): _take({key: get_meta("config_" + key)})
	_build()


func _take(config_data: Dictionary) -> void:
	if config_data.has("word") and str(config_data["word"]) in WORDS: word = str(config_data["word"])
	if config_data.has("text"): text = str(config_data["text"]).left(24)
	if config_data.has("tall"): tall = clampf(float(str(config_data["tall"])), 0.2, 4.0)
	if config_data.has("deep"): deep = clampf(float(str(config_data["deep"])), 0.02, 1.5)
	if config_data.has("fit_width"): fit_width = clampf(float(str(config_data["fit_width"])), 0.5, 30.0)
	if config_data.has("colour"): colour = Color(str(config_data["colour"])) if config_data["colour"] is String else config_data["colour"]


func apply_grid_config(config_data: Dictionary) -> void:
	var before := [word, text, tall, deep, fit_width, colour]
	_take(config_data)
	if is_inside_tree() and before != [word, text, tall, deep, fit_width, colour]: _build()


func said() -> String:
	return text if text != "" else word


func _build() -> void:
	var began := Time.get_ticks_msec()
	for child in get_children(): child.queue_free()
	var mesh := TextMesh.new()
	mesh.text = said()
	mesh.font = load(FACE)
	mesh.font_size = 160
	# a capital of this face is 0.711 of its em
	mesh.pixel_size = tall / (0.711 * 160.0)
	mesh.depth = deep
	mesh.curve_step = 1.0
	mesh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var box: AABB = mesh.get_aabb()
	# the letters as tall as asked (the face's capitals are not exactly 0.711 of its em in a TextMesh), then no
	# wider than the room given
	var shrink: float = tall / maxf(0.01, box.size.y)
	shrink = minf(shrink, fit_width / maxf(0.01, box.size.x))
	_letters = MeshInstance3D.new()
	_letters.name = "Letters"
	_letters.mesh = mesh
	var paint := StandardMaterial3D.new()
	paint.albedo_color = colour
	paint.roughness = 0.38
	paint.metallic = 0.08
	_letters.material_override = paint
	_letters.scale = Vector3.ONE * shrink
	# stand it on the floor, centred on the row's place
	_letters.position = Vector3(-(box.position.x + box.size.x * 0.5) * shrink, -box.position.y * shrink, 0)
	add_child(_letters)
	_size = box.size * shrink
	_solid = StaticBody3D.new()
	_solid.name = "Solid"
	var shape := CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = Vector3(_size.x, _size.y, maxf(_size.z, 0.2))
	shape.shape = block
	shape.position = Vector3(0, _size.y * 0.5, 0)
	_solid.add_child(shape)
	add_child(_solid)
	_build_ms = Time.get_ticks_msec() - began


## ---- for a test ----

func state() -> Dictionary:
	return {"said": said(), "word": word, "tall": tall, "size": [snappedf(_size.x, 0.01), snappedf(_size.y, 0.01), snappedf(_size.z, 0.01)], "fit_width": fit_width, "build_ms": _build_ms}
