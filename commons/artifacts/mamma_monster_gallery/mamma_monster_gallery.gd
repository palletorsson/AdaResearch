extends Node3D
class_name MammaMonsterGallery

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: MAMMA MONSTER — the origin gallery. Six plates carrying Kristina Torsson's pattern vocabulary as living shaders: varma backen (the Sudret meadow's winding line), Fjader (the henyard feather), Bonan (found in the pistachio bowl — chance as source), the Mah-Jong stripe (1966, with Helena Henschen and Veronika Nygren — design as ideology), Rutan Oscillerar (the Vamlingbo teenage room: the check that oscillates, neon silk, the queer CGI room before CGI), and Moders Drom (Mothers Dream 2023 — the img2img oscillation, every 280 frames the AI given more freedom, breathing here on TIME).
# desire: to stand the project's first maker in the world the project became — Ada Research begins in a landscape of my mother's patterns, and this room says so, with her name on it.
# critical_parameter: g_dream (each shader) — the Mothers Dream gene: 0 = the weave as she drew it, 1 = the dream the machine breathes into it; the oscillation between them is the artwork.
# triggers: _ready builds the six plates; the shaders animate on TIME (the check oscillates, the dream cycles); apply_grid_config({variant}) applies DNA gene presets.
# emerges: walked left to right the row reads as a life: meadow → henyard → chance → the collective 1966 → the teenage room → the dream that a machine and a son pressed from all of it.
# needs: the six mm_ shaders [present]; framed plates [built]; the family named [BakedText tags].
# relationships: the origin sibling of [[pattern_atlas_gallery]] — the atlas names the world's makers, this room names the FIRST one; sources kristina_torsson / mah_jong_collective / vamlingbolaget in the commons ledger; the thread runs loom → Jacquard → Ada Lovelace → this game (Sadie Plant's thread, material not metaphor).
# truth: the excavation record was never impersonal. The general intellect has a face here: the book's first debt is to the maker at the fabric table in Vamlingbo, and the walk returns it by name — Kristina Torsson, who wrote that making a pattern is like trying to catch a dream.

@export var plate_w: float = 1.3
@export var plate_h: float = 0.95

const PLATES := [
	{"shader": "mm_varma_backen", "title": "VARMA BACKEN", "makers": "Kristina Torsson · Vamlingbolaget · the Sudret meadow"},
	{"shader": "mm_fjader", "title": "FJADER", "makers": "Kristina Torsson · Vamlingbolaget · the henyard"},
	{"shader": "mm_bonan", "title": "BONAN", "makers": "Kristina Torsson · found in the pistachio bowl"},
	{"shader": "mm_mahjong_rand", "title": "MAH-JONG RAND", "makers": "K. Torsson · H. Henschen · V. Nygren · 1966"},
	{"shader": "mm_rutan_oscillerar", "title": "RUTAN OSCILLERAR", "makers": "the Vamlingbo room · satin, mirrors, neon silk"},
	{"shader": "mm_moders_drom", "title": "MODERS DROM", "makers": "Mothers Dream 2023 · Palle after Kristina Torsson"},
]

var _built := false

func _ready() -> void:
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()

func _build() -> void:
	_built = true
	var gap := 0.4
	var cw := plate_w + gap
	for i in PLATES.size():
		var x := (float(i) - float(PLATES.size() - 1) * 0.5) * cw
		_plate(PLATES[i], Vector3(x, 0, 0))
	var tag: Node3D = BakedText.make_tag("MAMMA MONSTER — Kristina Torsson · Mah-Jong 1966 · Vamlingbolaget", Color(0.95, 0.9, 0.88), 0.085)
	if tag:
		tag.position = Vector3(0, 2.3, 0.1)
		add_child(tag)
	var sub: Node3D = BakedText.make_tag("'Att skapa monster ar som att forsoka fanga en drom'", Color(0.8, 0.75, 0.72), 0.055)
	if sub:
		sub.position = Vector3(0, 2.12, 0.1)
		add_child(sub)

func _plate(entry: Dictionary, pos: Vector3) -> void:
	var root := Node3D.new()
	root.name = str(entry["shader"])
	root.position = pos
	add_child(root)

	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.62, 0.6, 0.56)

	var stand := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.55, 0.05, 0.32)
	stand.mesh = sm
	stand.material_override = smat
	stand.position = Vector3(0, 0.025, 0)
	root.add_child(stand)
	var post := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.05, 0.6, 0.05)
	post.mesh = pm
	post.material_override = smat
	post.position = Vector3(0, 0.32, 0)
	root.add_child(post)

	var frame := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(plate_w + 0.07, plate_h + 0.07, 0.045)
	frame.mesh = fm
	frame.material_override = smat
	frame.position = Vector3(0, 0.6 + plate_h * 0.5, 0)
	root.add_child(frame)

	var plate := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(plate_w, plate_h)
	plate.mesh = qm
	var shader = load("res://commons/artifacts/mamma_monster_gallery/shaders/%s.gdshader" % entry["shader"])
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		plate.material_override = mat
	plate.position = Vector3(0, 0.6 + plate_h * 0.5, 0.028)
	root.add_child(plate)

	var t1: Node3D = BakedText.make_tag(str(entry["title"]), Color(0.95, 0.93, 0.88), 0.055)
	if t1:
		t1.position = Vector3(0, 0.46, 0.07)
		root.add_child(t1)
	var t2: Node3D = BakedText.make_tag(str(entry["makers"]), Color(0.75, 0.8, 0.75), 0.038)
	if t2:
		t2.position = Vector3(0, 0.34, 0.07)
		root.add_child(t2)
