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

@export var columns: int = 6
@export var plate_w: float = 1.15
@export var plate_h: float = 0.85

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
]

var _built := false

func _ready() -> void:
	_read_meta_overrides()
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_meta_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()

func _read_meta_overrides() -> void:
	if has_meta("config_columns"):
		columns = int(str(get_meta("config_columns")))

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
	var tag: Node3D = BakedText.make_tag("PATTERN ATLAS — the makers, named", Color(0.92, 0.9, 0.85), 0.09)
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

	# maker tags — the credit, in the room
	var t1: Node3D = BakedText.make_tag(str(entry["title"]), Color(0.95, 0.93, 0.88), 0.055)
	if t1:
		t1.position = Vector3(0, 0.42, 0.06)
		root.add_child(t1)
	var t2: Node3D = BakedText.make_tag(str(entry["makers"]), Color(0.75, 0.82, 0.75), 0.04)
	if t2:
		t2.position = Vector3(0, 0.3, 0.06)
		root.add_child(t2)
