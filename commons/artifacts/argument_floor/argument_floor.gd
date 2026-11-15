extends Node3D
## AN ARGUMENT, STOOD ON A FLOOR (the pass, 2026-11-14)
##
## Palle, 2026-11-14: round the artifact, mad-scientist 3D knowledge graphs with home-made stickers and cardboard
## plates, "as if you were really trying to explain it to your self, what are these paradoxes and principles about";
## hero the artifact; "show me inside the Void".
##
## The thinking is authored, one file a hall: commons/data/arguments/<hall>.json (checked by tools/arguments.py).
## This work only stands it up: each PLATE a sheet of cardboard propped on two crates, its notes in marker on the
## front and in pink on the back; its STICKERS stuck along the bottom (yellow: a claim of mine, red: what it is not,
## blue: a question I still have, white: the hall text, word for word); a pole behind each plate, and between the
## poles the red THREADS, each with its word on a tag and the same word printed on TEXT TAPE along the floor from
## plate to plate (the tape rolls' printed strip); two work lights and a ring of tape for the HERO.
##
## It is a stand-in and says so: the sticker app's cardboard constructions (commons/data/stickers/constructions.json:
## walls you can stick on, peel from and scribble on, in SVG, three.js and VR) are the real medium, and their VR
## artifact had not landed when this was written (forum 261113-pcs7b). Nothing here can be edited by a visitor, and
## no rule of the sticker app is copied: this reads one authored file and letters it. When the constructions land,
## the same file is laid through their ops and this row goes.
##
## `hall` is the axis: which hall's argument stands here. The file gives every place in the floor's own frame, so
## the row stands at [0, 0] with facing 0.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const Strip := preload("res://commons/artifacts/tape_roll/strip.gd")
const DIR := "res://commons/data/arguments/"
const NOTE_FONT := "res://commons/font/handwriting/PatrickHand.ttf"
const TITLE_FONT := "res://commons/font/handwriting/ArchitectsDaughter.ttf"
const BACK_FONT := "res://commons/font/handwriting/Caveat.ttf"
const CARD := Color("c4a070")
const INK := Color(0.09, 0.07, 0.05)
const PINK_INK := Color("a81e58")
const THREAD := Color("c81e2c")
const PAPER := {"quote": Color("f4f0e6"), "claim": Color("ffe25a"), "not": Color("ff9a9a"), "question": Color("a6d8ff")}
const PLATE_W := 1.34
const PLATE_H := 1.8
const FOOT := 0.2
const POLE := 2.7
const PIXEL := 0.0011

@export_enum("Russell_Paradox", "Godel_Incompleteness", "NonEuclidean_Spaces", "Euclid_Parallel", "Escher_Impossible", "Brouwer_Intuitionism", "Florensky_Paraconsistent", "Crisis_Synthesis", "QFEP_Introduction", "QFEP_F_Term", "QFEP_E_Term", "QFEP_Lambda_Spectrum", "QFEP_Phi_Term", "QFEP_Edge_Of_Chaos", "QFEP_Sandbox", "QFEP_Synthesis") var hall := "Russell_Paradox"
## Where this row stands on its floor. The file's places are in the floor's frame; a row that cannot stand at the
## floor's middle (another work is there) says where it stands and everything is shifted back.
@export var stands_at := Vector2.ZERO

var _city = City.new()
var _doc: Dictionary = {}
var _root: Node3D
var _tops := {}
var _feet := {}
var _used := {}
var _counts := {"plates": 0, "notes": 0, "stickers": 0, "threads": 0}
var _fonts := {}
var _build_ms := 0


func _ready() -> void:
	for key in ["hall", "stands_at"]:
		if has_meta("config_" + key): _take({key: get_meta("config_" + key)})
	_build()


func _take(config_data: Dictionary) -> void:
	if config_data.has("hall") and str(config_data["hall"]) in ["Russell_Paradox", "Godel_Incompleteness", "NonEuclidean_Spaces", "Euclid_Parallel", "Escher_Impossible", "Brouwer_Intuitionism", "Florensky_Paraconsistent", "Crisis_Synthesis", "QFEP_Introduction", "QFEP_F_Term", "QFEP_E_Term", "QFEP_Lambda_Spectrum", "QFEP_Phi_Term", "QFEP_Edge_Of_Chaos", "QFEP_Sandbox", "QFEP_Synthesis"]: hall = str(config_data["hall"])
	if config_data.has("stands_at"):
		var given: Variant = config_data["stands_at"]
		if given is String: given = (given as String).split_floats(",")
		if (given is Array or given is PackedFloat64Array or given is PackedFloat32Array) and given.size() >= 2: stands_at = Vector2(float(given[0]), float(given[1]))
		elif given is Vector2: stands_at = given


func apply_grid_config(config_data: Dictionary) -> void:
	var before := [hall, stands_at]
	_take(config_data)
	if is_inside_tree() and before != [hall, stands_at]: _build()


func _font(path: String) -> Font:
	if not _fonts.has(path): _fonts[path] = load(path)
	return _fonts[path]


func _build() -> void:
	var began := Time.get_ticks_msec()
	if _root != null:
		remove_child(_root)
		_root.queue_free()
	_root = Node3D.new()
	_root.name = "Argument"
	_root.position = Vector3(-stands_at.x, 0, -stands_at.y)
	add_child(_root)
	_tops.clear()
	_feet.clear()
	_used.clear()
	_counts = {"plates": 0, "notes": 0, "stickers": 0, "threads": 0}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR + hall + ".json"))
	_doc = data if data is Dictionary else {}
	if _doc.is_empty():
		push_warning("argument_floor: no argument is written for " + hall)
		return
	for plate in _doc.get("plates", []): _plate(plate)
	for thread in _doc.get("threads", []): _thread(thread)
	_hero(_doc.get("hero", {}))
	_build_ms = Time.get_ticks_msec() - began


## Words lettered on a face: returns the height they took, in metres.
func _letter(parent: Node3D, text: String, at: Vector3, wide: float, font_path: String, size: int, colour: Color, back: bool = false, tilt: float = 0.0) -> float:
	var label := Label3D.new()
	label.text = text
	label.font = _font(font_path)
	label.font_size = size
	label.pixel_size = PIXEL
	label.modulate = colour
	label.outline_size = 0
	label.shaded = false
	label.double_sided = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.width = wide / PIXEL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	label.position = at
	label.rotation = Vector3(0, PI if back else 0.0, deg_to_rad(tilt))
	parent.add_child(label)
	var took: Vector2 = _font(font_path).get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, wide / PIXEL, size)
	return took.y * PIXEL


func _jitter(text: String, span: float) -> float:
	return (float(hash(text) % 2001) / 1000.0 - 1.0) * span


## One plate: cardboard on two crates, a pole for its threads, its notes and its stickers.
func _plate(plate: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = "Plate_" + str(plate.get("id", ""))
	var at: Array = plate.get("at", [0, 0])
	holder.position = Vector3(float(at[0]), 0, float(at[1]))
	holder.rotation_degrees.y = float(plate.get("yaw", 0))
	_root.add_child(holder)
	var sheet := Node3D.new()
	sheet.name = "Sheet"
	sheet.position = Vector3(0, FOOT, 0)
	sheet.rotation_degrees.x = -5.0
	holder.add_child(sheet)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(PLATE_W, PLATE_H, 0.012)
	mesh.mesh = box
	mesh.material_override = _city.flat(CARD.darkened(absf(_jitter(str(plate.get("id", "")), 0.08))), 0.95)
	mesh.position = Vector3(0, PLATE_H * 0.5, 0)
	sheet.add_child(mesh)
	var solid := StaticBody3D.new()
	holder.add_child(solid)
	_city.wall(solid, Vector3(0, 0, -0.1), Vector3(PLATE_W, 1.3, 0.3))
	for side in [-1.0, 1.0]: _city.part(holder, "crate", Vector3(side * 0.38, 0, -0.42), _jitter(str(plate.get("id", "")) + str(side), 14.0), Vector3(0.5, 0.5, 0.5), false)
	_city.part(holder, "timber_plank_2m", Vector3(0, 0.3, -0.36), 0, Vector3(0.05, POLE - 0.3, 0.18), false)
	_tops[str(plate.get("id", ""))] = _root.to_local(holder.to_global(Vector3(0, POLE, -0.36)))
	_feet[str(plate.get("id", ""))] = _root.to_local(holder.to_global(Vector3(0, 0, 0.55)))
	# the front, in marker
	var left: float = -PLATE_W * 0.5 + 0.07
	var wide: float = PLATE_W - 0.14
	var y: float = PLATE_H - 0.05
	y -= _letter(sheet, str(plate.get("title", "")), Vector3(left, y, 0.008), wide, TITLE_FONT, 60, INK, false, _jitter(str(plate.get("title", "")), 0.6)) + 0.04
	for note in plate.get("front", []):
		y -= _letter(sheet, str(note), Vector3(left + absf(_jitter(str(note), 0.02)), y, 0.008), wide - 0.03, NOTE_FONT, 50, INK, false, _jitter(str(note), 0.5)) + 0.024
		_counts["notes"] = int(_counts["notes"]) + 1
	# the back, in pink
	var by: float = PLATE_H - 0.07
	by -= _letter(sheet, str(plate.get("title", "")), Vector3(-left, by, -0.008), wide, TITLE_FONT, 44, PINK_INK.darkened(0.2), true) + 0.05
	for note in plate.get("back", []):
		by -= _letter(sheet, str(note), Vector3(-left, by, -0.008), wide - 0.03, BACK_FONT, 54, PINK_INK, true, _jitter(str(note), 1.2)) + 0.04
		_counts["notes"] = int(_counts["notes"]) + 1
	# the stickers, along the bottom
	var x: float = left
	var row_y: float = 0.09
	var row_h: float = 0.0
	for sticker in _doc.get("stickers", []):
		if str(sticker.get("plate", "")) != str(plate.get("id", "")): continue
		var words := str(sticker.get("text", ""))
		if words == "": words = (str(sticker.get("a", "")) + "\n" + str(sticker.get("b", ""))).strip_edges()
		var font := _font(TITLE_FONT)
		var size: Vector2 = font.get_multiline_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, 0.5 / PIXEL, 30) * PIXEL
		var chip_w: float = minf(size.x, 0.5) + 0.05
		var chip_h: float = size.y + 0.03
		if x + chip_w > PLATE_W * 0.5 - 0.04:
			x = left
			row_y += row_h + 0.03
			row_h = 0.0
		row_h = maxf(row_h, chip_h)
		var chip := MeshInstance3D.new()
		var paper := BoxMesh.new()
		paper.size = Vector3(chip_w, chip_h, 0.004)
		chip.mesh = paper
		chip.material_override = _city.flat(PAPER.get(str(sticker.get("kind", "claim")), PAPER["claim"]), 0.5)
		chip.position = Vector3(x + chip_w * 0.5, row_y + chip_h * 0.5, 0.01)
		chip.rotation_degrees.z = _jitter(words, 5.0)
		sheet.add_child(chip)
		var label := Label3D.new()
		label.text = words
		label.font = font
		label.font_size = 30
		label.pixel_size = PIXEL
		label.modulate = INK
		label.outline_size = 0
		label.shaded = false
		label.double_sided = false
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.width = 0.5 / PIXEL
		label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		label.position = Vector3(0, 0, 0.004)
		chip.add_child(label)
		x += chip_w + 0.03
		_counts["stickers"] = int(_counts["stickers"]) + 1
	_counts["plates"] = int(_counts["plates"]) + 1


## A red thread between two plates' poles, sagging, with its word on a tag.
func _thread(thread: Dictionary) -> void:
	var a := str(thread.get("a", ""))
	var b := str(thread.get("b", ""))
	if not _tops.has(a) or not _tops.has(b): return
	var from: Vector3 = _tops[a] - Vector3(0, 0.05 * float(int(_used.get(a, 0))), 0)
	var to: Vector3 = _tops[b] - Vector3(0, 0.05 * float(int(_used.get(b, 0))), 0)
	_used[a] = int(_used.get(a, 0)) + 1
	_used[b] = int(_used.get(b, 0)) + 1
	var sag: float = minf(0.3, 0.06 + 0.012 * from.distance_to(to))
	var paint: StandardMaterial3D = _city.flat(THREAD, 0.6)
	var steps := 10
	var before := from
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var point := from.lerp(to, t) - Vector3(0, sag * 4.0 * t * (1.0 - t), 0)
		var piece := MeshInstance3D.new()
		var rod := CylinderMesh.new()
		rod.top_radius = 0.011
		rod.bottom_radius = 0.011
		rod.height = before.distance_to(point)
		rod.radial_segments = 6
		rod.rings = 1
		piece.mesh = rod
		piece.material_override = paint
		piece.position = (before + point) * 0.5
		piece.basis = Basis(Quaternion(Vector3.UP, (point - before).normalized()))
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_root.add_child(piece)
		before = point
	var tag := Label3D.new()
	tag.text = str(thread.get("word", ""))
	tag.font = _font(NOTE_FONT)
	tag.font_size = 52
	tag.pixel_size = 0.0016
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color("8e0c16")
	tag.outline_size = 16
	tag.outline_modulate = Color("f6f1e4")
	# a tag a third of the way along, so that threads crossing in the middle do not pile their words up
	var along: float = 0.34 + 0.32 * float(hash(a + b) % 100) / 100.0
	tag.position = from.lerp(to, along) - Vector3(0, sag * 4.0 * along * (1.0 - along) + 0.12, 0)
	_root.add_child(tag)
	# the same word on TEXT TAPE along the floor, from the foot of one plate to the foot of the other: the printed
	# tape of the tape rolls (commons/artifacts/tape_roll/strip.gd), which prints a note along its own length
	if _feet.has(a) and _feet.has(b):
		var strip: MeshInstance3D = Strip.new()
		strip.set("tape_width", 0.075)
		var phrase := str(thread.get("word", "")) + "   ·   "
		strip.set("print_source", func(_from: Vector3, _to: Vector3, _length: float) -> String: return phrase)
		strip.position.y = 0.0015 * float(int(_counts["threads"]) % 12)
		_root.add_child(strip)
		strip.call("draw_surface_path", PackedVector3Array([_feet[a], _feet[b]]), Vector3.UP)
		_counts["tapes"] = int(_counts.get("tapes", 0)) + 1
	_counts["threads"] = int(_counts["threads"]) + 1


## The hero: a ring of tape on the floor round it and two work lights crossing on it. A file may say `"ring": false`
## for a hero whose place has no floor that was judged (the ring would hang in the air): nothing is laid then.
func _hero(hero: Dictionary) -> void:
	var at: Array = hero.get("at", [])
	if at.size() < 2: return
	var centre := Vector3(float(at[0]), 0, float(at[1]))
	if hero.get("ring", true) == false: return
	var ring := MeshInstance3D.new()
	var tape := TorusMesh.new()
	tape.inner_radius = 1.72
	tape.outer_radius = 1.8
	ring.mesh = tape
	ring.scale = Vector3(1, 0.04, 1)
	ring.material_override = _city.flat(Color("ffcd3c"), 0.5)
	ring.position = centre + Vector3(0, 0.006, 0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root.add_child(ring)
	for light in hero.get("lights", []):
		var spot := Vector3(float(light[0]), 0, float(light[1]))
		var toward := centre - spot
		_city.catalogue_part(_root, "work_light", spot, rad_to_deg(atan2(-toward.x, -toward.z)))
	var words: Label3D = _city.floor_words(_root, centre + Vector3(0, 0.014, 1.95), "THE HERO OF THIS HALL - every thread starts here", 34, Color("ffcd3c"))
	words.name = "HeroWords"


## ---- for a test ----

func state() -> Dictionary:
	var tops := {}
	for id in _tops: tops[id] = [snappedf((_tops[id] as Vector3).x, 0.01), snappedf((_tops[id] as Vector3).z, 0.01)]
	return {"hall": hall, "title": str(_doc.get("title", "")), "plates": int(_counts["plates"]), "notes": int(_counts["notes"]), "stickers": int(_counts["stickers"]), "threads": int(_counts["threads"]), "tapes": int(_counts.get("tapes", 0)),
		"tops": tops, "written": (_doc.get("plates", []) as Array).size(), "stickers_written": (_doc.get("stickers", []) as Array).size(), "threads_written": (_doc.get("threads", []) as Array).size(),
		"prefab_parts": int(_city.parts), "build_ms": _build_ms, "hero_at": (_doc.get("hero", {}) as Dictionary).get("at", []), "hero_ring": (_doc.get("hero", {}) as Dictionary).get("ring", true) != false}


func plate_point(id: String, off: float = 1.6) -> Vector3:
	for plate in _doc.get("plates", []):
		if str(plate.get("id", "")) == id:
			var at: Array = plate.get("at", [0, 0])
			var yaw: float = deg_to_rad(float(plate.get("yaw", 0)))
			return _root.to_global(Vector3(float(at[0]) + sin(yaw) * off, 0, float(at[1]) + cos(yaw) * off))
	return global_position
