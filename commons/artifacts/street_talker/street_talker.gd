extends Node3D

## THE STREET TALKER — the museum's threshold notice, standing on the pavement.
##
## 2026-09-01, Palle: "should we add the info board as a very nice standing large
## street talker to the room and say something about it in the text?"
##
## Yes, and the form is arguing, not decorating. An A-frame is the sign a shop
## puts OUT, on public ground, on your side of the door: chalked, provisional,
## moveable, easy to walk past. That is the right register for what it carries.
## What a room raises to 'named' or 'understood' is a judgment somebody made and
## can revise — commons/data/depth_rulings.json is authored by hand — and
## institutional signage bolted to a wall would say the opposite: that this is
## the settled account, issued by the building.
##
## AND IT HAS TWO FACES, WHICH IS THE GRADIENT IN FURNITURE:
##
##     front   what you can do here — the things ruled 'understood'
##     back    the descents — things ruled 'glimpsed', which go deeper
##
## You meet the front walking in. To read the back you have to go round it. So
## the descent is genuinely offered and genuinely declinable, and declining costs
## nothing and looks like nothing — which is what "a small optional inscription"
## has to mean if it means anything. One flat panel could not do this: it would
## either show both, making the descent compulsory reading, or hide the descent,
## making it a secret. A secret is not an offer.
##
## The faces are TextScreen (commons/ui/text_screen.gd) in SCREEN mode. That
## component owns wrapping, truncation and the minimum legible glyph. The reason
## not to lay out text here is on the record: legibility knowledge living in the
## heads of callers is what once put an unreadable 655-character smear on a
## museum wall.
##
## Content comes from Depth.gd, reading the derived commons/data/depth.json.
## AN UNRULED ROOM GETS NO SIGN AT ALL — not an empty frame, not a placeholder.
## 243 of 244 rooms are unruled today and their silence is the ruling; an empty
## A-frame in each of them would advertise, in every hall, that somebody meant to
## say something here and did not.

const TextScreenScript = preload("res://commons/ui/text_screen.gd")
const DepthReader = preload("res://commons/scenes/mapobjects/Depth.gd")

## Pavement-sign scale: reads standing, steps over easily, screens no one.
@export var board_height: float = 1.24
@export var board_width: float = 0.66
## Degrees each board leans back from vertical. Both lean, so the top is a hinge
## and the base is a stance.
@export var lean_degrees: float = 18.0
@export var frame_color: Color = Color(0.22, 0.20, 0.17)
@export var hinge_color: Color = Color(0.42, 0.40, 0.36)

## Set from a map cell config, or found by walking up to whatever knows the hall.
@export var map_name: String = ""

var _built := false


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("map"):
		map_name = str(config_data["map"])
	if config_data.has("board_height"):
		board_height = float(config_data["board_height"])
	if config_data.has("board_width"):
		board_width = float(config_data["board_width"])
	if _built:
		_build()


## Which hall am I standing in? Asked of the TREE, never of an autoload — every
## probe in this repo is `extends SceneTree` and cannot see one, and the info
## board learned that by naming GameManager and becoming untestable.
func _resolve_map() -> String:
	if map_name != "":
		return map_name
	var n: Node = self
	while n:
		if n.has_meta("map_name"):
			return str(n.get_meta("map_name"))
		# The museum calls the same fact something else. A hall segment carries
		# em_map (endless_museum.gd:7611) and never map_name, so a board that
		# asks only for map_name resolves "" inside the museum, gets an empty
		# subject, and builds NOTHING -- silently, because an unruled room
		# building nothing is a legitimate outcome here. Two vocabularies for
		# one fact, and the failure looks exactly like the success.
		if n.has_meta("em_map") and str(n.get_meta("em_map")) != "":
			return str(n.get_meta("em_map"))
		if "map_name" in n and str(n.get("map_name")) != "":
			return str(n.get("map_name"))
		n = n.get_parent()
	return ""


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_built = true

	var mp := _resolve_map()
	var subject: Array = DepthReader.subject(mp) if mp != "" else []
	# The whole 'glimpsed' rung, not only those with an inscription written. A
	# rung is a ruling; a missing sentence is a to-do, and filtering on it
	# silently demoted a ruled thing to 'used' and dropped it off the sign.
	var deeper: Array = DepthReader.glimpsed(mp) if mp != "" else []
	if subject.is_empty() and deeper.is_empty():
		# SAY WHY YOU ARE INVISIBLE. Silence is a legal answer here, so an
		# unbuilt sign and a broken sign look identical from outside — which is
		# the shape of bug that hides for weeks. Naming which of the two happened
		# costs one line and turns a mystery into a fact.
		if mp == "":
			push_warning("street_talker: no hall resolved (no map_name, and no "
				+ "ancestor carries one) — built nothing")
		else:
			print("street_talker: %s has no depth ruling — built nothing, which "
				% mp + "is the ruling, not a fault")
		return

	# IT HANGS FROM THE HINGE. The first version pivoted each board at its BASE,
	# which put both feet at the origin and splayed the tops: a V, screens facing
	# each other on the inside where nobody could read them. Photographing it was
	# what showed this — the geometry was self-consistent and wrong, and no probe
	# asking "did two boards get built?" would ever have caught it.
	var lean := deg_to_rad(lean_degrees)
	var apex := board_height * cos(lean)
	_add_board(false, lean, apex, "HERE YOU CAN", _front_body(subject), deeper.size())
	_add_board(true, lean, apex, "GOES DEEPER", _back_body(deeper), 0)
	_add_hinge(apex)


## THE NAMES ONLY. The first version put each thing's plaque sentence on the
## front too, and the photograph settled it: four sentences wrapped to eight
## lines, the glyphs fell to the floor TextScreen defends, and the fourth was
## truncated to "a point has no extent You can see…" — a sign that runs out of
## room mid-argument.
##
## Terseness here is not a compromise for space, it is the form keeping its
## promise. A board chalked on the pavement lists what is inside; it does not
## explain it. The sentences are plaque lines and belong BESIDE the things they
## name, where a visitor is already standing and looking at one.
func _front_body(subject: Array) -> String:
	var out := PackedStringArray()
	for t in subject:
		out.append(str(t.get("thing", "")))
	return "\n".join(out)


## The plaque line first, the descent under it — because the plaque is what the
## learner needs and the descent is what they may want. Reversed, the machinery
## becomes the point.
func _back_body(deeper: Array) -> String:
	if deeper.is_empty():
		return "Nothing here goes deeper than the room itself."
	var out := PackedStringArray()
	for t in deeper:
		out.append(str(t.get("say", "")))
		var d := str(t.get("descend", ""))
		if d != "":
			out.append("   " + d)
	return "\n".join(out)


## One leaf of the A: it HANGS from the hinge at the apex and leans out at the
## foot, so the two leaves meet at the top and stand apart at the bottom.
##
## The screen goes on the OUTWARD face (local +Z, which the lean carries away
## from the other leaf), because a sandwich board that talks to itself is a
## sandwich board nobody reads. TextScreen faces +Z — frame at z = -0.008, glass
## at 0, text plates at +0.004 — so +Z here is genuinely outward-facing and not
## a guess about which side of a panel is the front.
func _add_board(is_back: bool, lean: float, apex: float, title: String,
		body: String, deeper_count: int) -> void:
	var pivot := Node3D.new()
	pivot.name = "BoardBack" if is_back else "BoardFront"
	pivot.rotation = Vector3(0, PI if is_back else 0.0, 0)
	add_child(pivot)

	# Hung at the apex, tipped so the FOOT travels outward (+Z in this leaf's
	# frame) while the head stays at the hinge.
	var tilt := Node3D.new()
	tilt.position = Vector3(0, apex, 0)
	tilt.rotation = Vector3(-lean, 0, 0)
	pivot.add_child(tilt)

	var plank := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(board_width + 0.06, board_height, 0.035)
	plank.mesh = bm
	plank.position = Vector3(0, -board_height * 0.5, 0)
	plank.material_override = _mat(frame_color, 0.85)
	tilt.add_child(plank)

	var screen := TextScreenScript.new()
	screen.mode = 0                                   # TextScreen.Mode.SCREEN
	screen.width_m = board_width
	screen.title = title
	screen.body = body
	screen.position = Vector3(0, -board_height * 0.40, 0.026)
	tilt.add_child(screen)

	# The one line saying the other face exists. Without it the back is a secret
	# rather than an offer, and a secret cannot be declined.
	if not is_back and deeper_count > 0:
		var hint := TextScreenScript.new()
		hint.mode = 0
		hint.width_m = board_width * 0.92
		hint.title = ""
		var verb := "goes" if deeper_count == 1 else "go"
		var plural := "" if deeper_count == 1 else "s"
		hint.body = "%d thing%s here %s deeper. Round the other side." % [deeper_count, plural, verb]
		hint.position = Vector3(0, -board_height * 0.81, 0.026)
		tilt.add_child(hint)

	# A foot at the bottom of THIS leaf, carried by the same tilt — so it lands
	# where the board actually lands. Free-standing feet floated beside the sign
	# in the first capture, which is what a foot placed by arithmetic instead of
	# by hierarchy looks like.
	var foot := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(board_width + 0.10, 0.036, 0.10)
	foot.mesh = fb
	foot.position = Vector3(0, -board_height + 0.018, 0.02)
	foot.material_override = _mat(hinge_color.darkened(0.35), 0.7)
	tilt.add_child(foot)


## The pin the two leaves turn on, at the apex where they meet.
func _add_hinge(apex: float) -> void:
	var h := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.020
	cyl.bottom_radius = 0.020
	cyl.height = board_width + 0.10
	h.mesh = cyl
	h.rotation = Vector3(0, 0, PI * 0.5)
	h.position = Vector3(0, apex, 0)
	h.material_override = _mat(hinge_color, 0.4)
	add_child(h)


func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m
