extends Node3D
class_name PatternAtlasGallery

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the pattern atlas made walkable — twelve world pattern traditions (Kente, Ikat, Bingata, Kanga, indigo shibori, Tibetan tiger rug, Iznik, zellige, the Pompeii meander, Anni Albers, Sonia Delaunay, Vasarely, Bridget Riley) each reproduced AS A SHADER (the rule, not an image) on an upright plate, with its makers named on a tag beneath. The commons ledger's return performed in-game.
# desire: to stand the world's pattern grammars in one room, each beside the hands it was pressed from — the reparative gallery: reproduce the rule, name the maker.
# critical_parameter: columns — plates per row; the walk between plates is the reading order.
# triggers: _ready builds plates from the shader manifest; apply_grid_config({columns}) relayouts.
# emerges: walking the row reads as a census of makers — most collective, most women, most unnamed by history; the shader IS the credit made visible.
# needs: the twelve atlas shaders [present, shaders/]; framed plates [built]; maker tags [BakedText].
# relationships: the in-game twin of the /pattern-atlas web gallery; pays the same commons_sources the ledger tracks (kente weavers, ikat resist-dyers, bingata dyers, kanga printers, indigo dyers, Tibetan carpet-knotters, Iznik potters, al-Andalus zellige cutters, Pompeii mosaicists, Anni Albers, Sonia Delaunay, Vasarely, Bridget Riley); sibling of [[wall_pattern_gallery]] and the symmetry chapter's looms.
# truth: a pattern reproduced without its makers is an enclosure; reproduced beside their names it is a return. This room is the difference, standing up.

@export var columns: int = 7
@export var plate_w: float = 1.15
@export var plate_h: float = 0.85

## AXIS — WHAT THE ROOM DOES WITH THE HANDS THE PATTERN CAME FROM.
##
## This artifact's truth is a comparison it could never actually make: "a pattern
## reproduced without its makers is an enclosure; reproduced beside their names it is a
## return. This room is the difference, standing up." The room only ever stood up ONE
## side of that. Nineteen shaders, nineteen credits, always. The claim was asserted, never
## exhibited. `credit` is the other side made buildable, so the difference can be walked
## rather than read off a wall text.
##
##   named       the legacy lineage, board for board. Tradition on the upper tag, the hands
##               that pressed it on the lower one. The return.
##   title_only  the museum label that stops at the style. KENTE is named; the Ashanti and
##               Ewe strip-weavers are not. The commonest form the enclosure actually takes
##               — nobody denies where it came from, they just do not say who.
##   redacted    the record is kept and the content blacked out. The maker board is still
##               there, still lit, still exactly as wide as the names it is holding, and
##               the names have gone the colour of their own ground. What is missing is
##               legible AS missing.
##   anonymous   no boards at all. Nineteen world pattern traditions hanging as pure
##               surface, free for the taking. The enclosure, standing up.
##
## NOT the sibling word. [[pattern_loom]] carries `colophon` (none/repeat/symmetry/
## catalogue) and [[pattern_mill]] / [[pattern_machine_c]] carry `exhibit` (bolt/unit/
## operation/catalogue), and both ask the same good question — how much of the RULE the
## goods admit to. Refused here, deliberately: three of those four values need each
## pattern's repeat period or its plane symmetry group, and this gallery holds nineteen
## heterogeneous traditions whose groups it does not know and in several cases (kente
## strips, the batik crackle, hitomezashi) does not have. Declaring `colophon` here would
## mean inventing nineteen lattices and calling them measurements. The word is right for a
## machine that manufactures one group; this room is not that machine, and what it argues
## about is not the rule but the credit.
@export_enum("named", "title_only", "redacted", "anonymous") var credit: String = "named"
const CREDITS: PackedStringArray = ["named", "title_only", "redacted", "anonymous"]

const PLATES := [
	{"shader": "atlas_kente", "title": "KENTE", "makers": "Ashanti & Ewe strip-weavers · Ghana"},
	{"shader": "atlas_ikat", "title": "IKAT", "makers": "resist-dyers · Indonesia / C. Asia / Japan"},
	{"shader": "atlas_bingata", "title": "BINGATA", "makers": "stencil-dyers · Ryukyu / Okinawa"},
	{"shader": "atlas_kanga", "title": "KANGA", "makers": "printers · Swahili coast"},
	{"shader": "atlas_shibori", "title": "INDIGO SHIBORI", "makers": "resist-dyers · Japan / Yoruba / worldwide"},
	{"shader": "atlas_tiger", "title": "TIGER RUG", "makers": "carpet-knotters · Tibet"},
	{"shader": "atlas_iznik", "title": "IZNIK", "makers": "fritware potters · Ottoman Iznik"},
	{"shader": "atlas_zellige", "title": "ZELLIGE", "makers": "tile-cutters (maalem) · al-Andalus / Maghreb"},
	{"shader": "atlas_meander", "title": "MEANDER", "makers": "mosaic workshops · Pompeii"},
	{"shader": "atlas_albers", "title": "ANNI ALBERS", "makers": "weaver · Bauhaus / Black Mountain"},
	{"shader": "atlas_delaunay", "title": "SONIA DELAUNAY", "makers": "Orphism · textile + paint"},
	{"shader": "atlas_vasarely", "title": "VASARELY", "makers": "op art · the deformed grid"},
	{"shader": "atlas_riley", "title": "BRIDGET RILEY", "makers": "op art · the eye supplies the motion"},
	{"shader": "atlas2_wang", "title": "WANG TILES", "makers": "Hao Wang 1961 · Berger 1966 — tiling is undecidable"},
	{"shader": "atlas2_batik", "title": "BATIK", "makers": "batik makers of Java — the crackle is the hand"},
	{"shader": "atlas2_kuba", "title": "KUBA / SHOOWA", "makers": "Kuba kingdom weavers & embroiderers · DR Congo"},
	{"shader": "atlas2_hitomezashi", "title": "HITOMEZASHI", "makers": "farm households of northern Japan — mending as pattern"},
	{"shader": "atlas2_sami", "title": "SAMI BAND", "makers": "Sami band weavers · Sapmi"},
	{"shader": "atlas2_adinkra", "title": "ADINKRA", "makers": "carvers & stampers of Gyaman / Asante · Ghana"},
]

var _built := false

func _ready() -> void:
	_read_meta_overrides()
	_build()

## Guarded: the gallery is rebuilt only when a value it actually reads has moved, and only
## after _ready has built once. The old body tore down and re-built on EVERY call, which
## was a no-op that happened to produce the same nineteen plates — harmless until an axis
## exists, at which point an unconditional teardown is the standard way a shipped placement
## gets destroyed by a config key it does not care about.
func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	var prev_columns: int = columns
	var prev_credit: String = credit
	_read_meta_overrides()
	if _built and (columns != prev_columns or credit != prev_credit):
		for c in get_children():
			c.queue_free()
		_built = false
		_build()

func _read_meta_overrides() -> void:
	if has_meta("config_columns"):
		columns = int(str(get_meta("config_columns")))
	if has_meta("config_credit"):
		credit = _norm_credit(str(get_meta("config_credit")))

## An unrecognised word keeps whatever is already set rather than crashing or inventing a
## fifth value — the same contract [[pattern_mill]].exhibit uses, so a typo in a map token
## is inert instead of destructive.
func _norm_credit(raw: String) -> String:
	var s: String = raw.strip_edges().to_lower()
	return s if CREDITS.has(s) else credit

## The room's own headline, which must not outlive the thing it claims. A gallery whose
## plates carry no names cannot go on calling itself "the makers, named".
func _title_line() -> String:
	match credit:
		"title_only":
			return "PATTERN ATLAS — the traditions, named"
		"redacted":
			return "PATTERN ATLAS — the makers, struck out"
		"anonymous":
			return "PATTERN ATLAS"
		_:
			return "PATTERN ATLAS — the makers, named"

func _build() -> void:
	_built = true
	var gap := 0.35
	var cw := plate_w + gap
	var rows := int(ceil(float(PLATES.size()) / float(columns)))
	for i in PLATES.size():
		var col := i % columns
		var row := i / columns
		var x := (float(col) - float(columns - 1) * 0.5) * cw
		var z := float(row) * -2.2
		_plate(PLATES[i], Vector3(x, 0, z))
	# gallery title tag
	var tag: Node3D = BakedText.make_tag(_title_line(), Color(0.92, 0.9, 0.85), 0.09)
	if tag:
		tag.position = Vector3(0, 2.25, -1.1)
		add_child(tag)

func _plate(entry: Dictionary, pos: Vector3) -> void:
	var root := Node3D.new()
	root.name = str(entry["shader"])
	root.position = pos
	add_child(root)

	# stand
	var stand := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.5, 0.05, 0.3)
	stand.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.62, 0.6, 0.56)
	stand.material_override = smat
	stand.position = Vector3(0, 0.025, 0)
	root.add_child(stand)
	var post := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.05, 0.55, 0.05)
	post.mesh = pm
	post.material_override = smat
	post.position = Vector3(0, 0.3, 0)
	root.add_child(post)

	# frame + the shader plate
	var frame := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(plate_w + 0.06, plate_h + 0.06, 0.04)
	frame.mesh = fm
	frame.material_override = smat
	frame.position = Vector3(0, 0.55 + plate_h * 0.5, 0)
	root.add_child(frame)

	var plate := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(plate_w, plate_h)
	plate.mesh = qm
	var shader = load("res://commons/artifacts/pattern_atlas_gallery/shaders/%s.gdshader" % entry["shader"])
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		plate.material_override = mat
	plate.position = Vector3(0, 0.55 + plate_h * 0.5, 0.025)
	root.add_child(plate)

	# maker tags — the credit, in the room. Everything below is what `credit` owns; the
	# stand, post, frame and shader plate above it are identical under all four values, so
	# the bounding box the capture frames on never moves and no value is handed a
	# reframing to be measured as evidence.
	if credit == "anonymous":
		return

	var t1: Node3D = BakedText.make_tag(str(entry["title"]), Color(0.95, 0.93, 0.88), 0.055)
	if t1:
		t1.position = Vector3(0, 0.42, 0.06)
		root.add_child(t1)

	if credit == "title_only":
		return

	# "redacted" keeps the board, its width and its lit edge, and sinks the names into
	# their own ground — the strike done in colour rather than in geometry, so it holds
	# from every angle the capture orbits through and adds not one node.
	var maker_ink: Color = Color(0.75, 0.82, 0.75)
	var maker_bg: Color = Color(0.08, 0.09, 0.11)
	if credit == "redacted":
		maker_ink = Color(0.045, 0.05, 0.06)
		maker_bg = Color(0.04, 0.045, 0.055)
	var t2: Node3D = BakedText.make_tag(str(entry["makers"]), maker_ink, 0.04, maker_bg)
	if t2:
		t2.position = Vector3(0, 0.3, 0.06)
		root.add_child(t2)
