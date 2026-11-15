extends Node3D
## A SENTENCE, ITS SCOPE, ITS EVIDENCE (floor Crisis_Synthesis; the pass, 2026-11-15)
##
## The hall, at its end: "six cards keep a sentence beside its scope and evidence. The first five return to the
## small computations you have made. The sixth carries an AI proposal with no checking procedure attached. Make
## its letters as large as the checked sentences. ... Nothing in those operations supplies the missing evidence."
## And: "a failed membership case, a search stopped at a budget, a measured return, an exhibited witness and a
## countermodel warrant different statements. Their records must travel with them."
## These are those six cards at body size, behind the wall of the large sentence - a ROBOT STATION form: five of
## them run something when you stand before them, and the sixth has nothing to run.
##
## Each card: a sentence in large letters, its scope, its evidence, and a record. Stand still on the plate in
## front of a card and its check is RUN, here, now, and the record is written with what it does not show:
##   1 Russell      a failed membership case   the diagonal row against four sets
##   2 Goedel       a search, to a budget      the hall's own checker (foundations-lineage/derivation.gd)
##   3 Escher       a measured return          four heights, the differences summed round
##   4 Brouwer      an exhibited witness       a row of eight, looked through for a 1
##   5 Florensky    a countermodel             both reports held; the alarm under the four-valued tables
##   6 an AI        nothing                    a claim from the cardboard on these floors, written by the same
##                                             model that wrote this, with no procedure attached. Its plate runs
##                                             nothing and says so.
## The five do not share one certificate: refuted, searched, measured, exhibited, countermodelled.
##
## `sixth` is the axis: large (its letters as large as the checked ones, as the hall asks), small.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const Derivation := preload("res://doc/book/studies/foundations-lineage/derivation.gd")
const Yard := preload("res://commons/artifacts/consequence_yard/consequence_yard.gd")
const NOTE_FONT := "res://commons/font/handwriting/PatrickHand.ttf"
const TITLE_FONT := "res://commons/font/handwriting/ArchitectsDaughter.ttf"
const PITCH := 1.5                      # six cards between the slab's two north columns
const CARD_W := 1.34
const CARD_H := 1.95
const CARD := Color("c4a070")
const INK := Color(0.09, 0.07, 0.05)
const PINK := Color("a81e58")
const CARDS := [
	{"from": "Russell, floor 189", "kind": "a failed membership case", "sentence": "AMONG THESE FOUR SETS THERE IS NO SET OF ALL THAT DO NOT CONTAIN THEMSELVES.", "scope": "these four sets. it says nothing of any other collection.",
		"evidence": "the diagonal row, compared with each of the four."},
	{"from": "Goedel, floor 190", "kind": "a search, to a budget", "sentence": "SSSSSS0 CAN BE DERIVED.", "scope": "this little system, searched as far as the budget goes.",
		"evidence": "the hall's own checker, run with a budget."},
	{"from": "Escher, floor 191", "kind": "a measured return", "sentence": "A CLOSED STAIR GIVES BACK EVERY HEIGHT IT GAINS.", "scope": "one up, measured the same all the way round. a moved room is outside it.",
		"evidence": "four heights; the differences summed round."},
	{"from": "Brouwer, floor 192", "kind": "an exhibited witness", "sentence": "THIS ROW HOLDS A 1.", "scope": "this row of eight. nothing about a row that goes on.",
		"evidence": "the row, looked through; an address if there is one."},
	{"from": "Florensky, floor 193", "kind": "a countermodel", "sentence": "FROM P AND NOT-P THE ALARM DOES NOT FOLLOW.", "scope": "under the four-valued tables. read classically, it does.",
		"evidence": "both reports held; the alarm's value under the tables."},
	{"from": "an AI (Claude), on the cardboard of floor 187", "kind": "nothing", "sentence": "THE ANGLES OF EVERY TRIANGLE ADD TO 180 EXACTLY WHEN THE FIFTH POSTULATE HOLDS.", "scope": "claimed of every triangle. given the other four postulates.",
		"evidence": "none attached. from memory."},
]

@export_enum("large", "small") var sixth := "large"

var _city = City.new()
var _model = Derivation.new()
var _records: Array[Label3D] = []
var _sentences: Array[Label3D] = []
var _runs: Array[int] = [0, 0, 0, 0, 0, 0]
var _last_record: Array[String] = ["", "", "", "", "", ""]
var _board: Label3D
var _fonts := {}
var _on := -1
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_sixth"): _take({"sixth": get_meta("config_sixth")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_size_sixth()
	_tell()


func _take(config_data: Dictionary) -> void:
	if config_data.has("sixth") and str(config_data["sixth"]) in ["large", "small"]: sixth = str(config_data["sixth"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := sixth
	_take(config_data)
	if is_inside_tree() and _board != null and sixth != before: _size_sixth()


func _size_sixth() -> void:
	_sentences[5].font_size = 46 if sixth == "large" else 22


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


## ---- the checks: each is run when asked, and says what it did ----

func check(i: int) -> String:
	_runs[i] += 1
	var n: int = _runs[i]
	var record := ""
	match i:
		0:
			# four sets: set r contains set c when c < r. the diagonal row takes the opposite of "r contains r".
			var rows := []
			for r in 4:
				var row := ""
				for c in 4: row += "1" if c < r else "0"
				rows.append(row)
			var made := ""
			for c in 4: made += "0" if rows[c][c] == "1" else "1"
			var differs := []
			for r in 4: differs.append("row %d at place %d" % [r, r] if made[r] != rows[r][r] else "SAME AS ROW %d" % r)
			record = "REFUTED for these four. the row made: %s. it differs from %s." % [made, ", ".join(differs)]
		1:
			var budget: int = 4 if n % 2 == 1 else 8
			var found: Dictionary = _model.search("SSSSSS0", budget)
			if str(found["status"]) == "CHECKED DERIVATION": record = "FOUND and checked, budget %d: %d lines examined, the last is SSSSSS0." % [budget, int(found["examined"])]
			else: record = "NOT FOUND within budget %d (%d lines examined). that shows a search that stopped - not that it cannot be derived. stand again: the budget will be 8." % [budget, int(found["examined"])]
		2:
			var rng := RandomNumberGenerator.new()
			rng.seed = 191 + n
			var heights: Array[float] = []
			for k in 4: heights.append(snappedf(rng.randf_range(0.0, 2.4), 0.1))
			var total := 0.0
			var parts := []
			for k in 4:
				var step: float = heights[(k + 1) % 4] - heights[k]
				total += step
				parts.append("%+.1f" % step)
			record = "MEASURED: heights %s; round: %s = %.1f." % [str(heights), " ".join(parts), absf(total)]
		3:
			var rng := RandomNumberGenerator.new()
			rng.seed = 192 + n * 7
			var row := ""
			for k in 8: row += "1" if rng.randf() < 0.22 else "0"
			var at: int = row.find("1")
			if at >= 0: record = "EXHIBITED: the row %s holds a 1 at place %d." % [row, at + 1]
			else: record = "NOT HERE: the row %s was looked through, all eight. the sentence is false of this row - and that says nothing of a ninth." % row
		4:
			var premise: Array = Yard.told("both", true, true)
			var alarm: Array = Yard.told("q", true, true)
			record = "COUNTERMODEL: P told true and told false; 'P and not-P' is told true: %s; the alarm is told true: %s. premises hold, conclusion does not. classically it follows: %s." % [
				"yes" if bool(premise[0]) else "no", "yes" if bool(alarm[0]) else "no", "yes" if Yard.follows_classically("q", true, true) else "no"]
		5:
			record = "NOTHING WAS RUN. there is no procedure attached to this card. its letters are %s the others'. that changes nothing about the line above." % ("as large as" if sixth == "large" else "smaller than")
	_last_record[i] = record
	_records[i].text = "record %d:  %s" % [n, record]
	_tell()
	return record


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var moved: float = p.distance_to(_last)
	_last = p
	var on := -1
	if absf(p.y) < 0.6:
		for i in 6:
			if Vector2(p.x - (float(i) - 2.5) * PITCH, p.z - 1.25).length() < 0.32: on = i
	if on != _on or moved > 0.004:
		_on = on
		_still = 0.0
		return
	if on < 0: return
	_still += delta
	if _still >= 0.8:
		_still = -99.0
		check(on)


func _tell() -> void:
	if _board == null: return
	var ran := 0
	for i in 5: ran += 1 if _runs[i] > 0 else 0
	var lines := PackedStringArray(["A SENTENCE, ITS SCOPE, ITS EVIDENCE"])
	lines.append("Six cards behind the large sentence. Stand still on the mark before a card: its check is run, here, and the record is written under it with what it does not show.")
	lines.append("Five kinds of warrant came down these floors and they are not one certificate: a failed membership case, a search stopped at a budget, a measured return, an exhibited witness, a countermodel. Checked so far: %d of 5." % ran)
	lines.append("The sixth card is a claim from the cardboard on these floors. It was written by the AI that wrote this board. It has no procedure. Its letters are as large as the others' because the hall asks for that: size is not evidence. Three more of the same hand, unchecked: Hilbert's theorem (floor 188, plate 6), Gauss's mountain triangle (188, plate 7), Gelfond and Schneider (192, plate 4).")
	lines.append("If a sentence says more than its record supports, that is where revision begins.")
	_board.text = "\n".join(lines)


## ---- building, once ----

func _font(path: String) -> Font:
	if not _fonts.has(path): _fonts[path] = load(path)
	return _fonts[path]


func _letter(parent: Node3D, text: String, at: Vector3, wide: float, font_path: String, size: int, colour: Color) -> Label3D:
	var words := Label3D.new()
	words.text = text
	words.font = _font(font_path)
	words.font_size = size
	words.pixel_size = 0.0011
	words.modulate = colour
	words.outline_size = 0
	words.double_sided = false
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.width = wide / 0.0011
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	words.position = at
	parent.add_child(words)
	return words


func _build_once() -> void:
	for i in 6:
		var card: Dictionary = CARDS[i]
		var holder := Node3D.new()
		holder.name = "Card%d" % (i + 1)
		holder.position = Vector3((float(i) - 2.5) * PITCH, 0, 0)
		add_child(holder)
		var sheet := Node3D.new()
		sheet.position = Vector3(0, 0.2, 0)
		sheet.rotation_degrees.x = -5.0
		holder.add_child(sheet)
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(CARD_W, CARD_H, 0.012)
		mesh.mesh = box
		mesh.material_override = _city.flat(CARD if i < 5 else Color("d9d2c2"), 0.95)
		mesh.position = Vector3(0, CARD_H * 0.5, 0)
		sheet.add_child(mesh)
		var solid := StaticBody3D.new()
		holder.add_child(solid)
		_city.wall(solid, Vector3(0, 0, -0.1), Vector3(CARD_W, 1.3, 0.3))
		for side in [-1.0, 1.0]: _city.part(holder, "crate", Vector3(side * 0.38, 0, -0.42), 7.0 * side, Vector3(0.5, 0.5, 0.5), false)
		var left: float = -CARD_W * 0.5 + 0.08
		var wide: float = CARD_W - 0.16
		_letter(sheet, "%d  %s" % [i + 1, str(card["from"])], Vector3(left, CARD_H - 0.05, 0.008), wide, NOTE_FONT, 34, PINK)
		_sentences.append(_letter(sheet, str(card["sentence"]), Vector3(left, CARD_H - 0.2, 0.008), wide, TITLE_FONT, 46, INK))
		_letter(sheet, "scope:  %s\n\nevidence:  %s\n\nkind of warrant:  %s" % [str(card["scope"]), str(card["evidence"]), str(card["kind"])], Vector3(left, 1.02, 0.008), wide, NOTE_FONT, 38, INK)
		_records.append(_letter(sheet, "record:  not run yet. stand on the mark.", Vector3(left, 0.5, 0.008), wide, NOTE_FONT, 36, PINK))
		var mark := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.3
		disc.bottom_radius = 0.3
		disc.height = 0.012
		mark.mesh = disc
		mark.material_override = _city.flat(Color("3f6fd0") if i < 5 else Color("5a5d66"), 0.5)
		mark.position = Vector3(holder.position.x, 0.008, 1.25)
		mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mark)
		_city.floor_words(self, Vector3(holder.position.x, 0.02, 1.25), "CHECK" if i < 5 else "CHECK?", 34, Color(0.98, 0.97, 0.94))
	_board = _city.board(self, Vector3(7.4, 0, 1.6), 3.4, 1.7)


## ---- for a test ----

func state() -> Dictionary:
	return {"sixth": sixth, "runs": _runs, "records": _last_record, "sixth_letters": _sentences[5].font_size, "other_letters": _sentences[0].font_size, "board": _board.text if _board != null else "",
		"prefab_parts": int(_city.parts), "build_ms": _build_ms}


func plate_point(i: int) -> Vector3:
	return to_global(Vector3((float(i) - 2.5) * PITCH, 0, 1.25))
