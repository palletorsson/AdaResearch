extends Node3D
class_name JSpaceZoomChamber

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the hidden layer made walkable — seventeen feature-words from the "count to five and introspect" interpretability image, each standing as a pillar whose FLOOR POSITION is its real coordinate in the book's own LSA space (MDS of cosine distances, stress-1 reported on a plaque, not hidden). Walking distance between pillars IS semantic distance in the corpus, up to the plaque's honesty number.
# desire: for the world model to align with a real 3D space — the Riemann dream: geometry you can walk as truth, with the projection's lie measured and posted at the door.
# critical_parameter: stress1 — how much the 2D floor lies about the 128-D truth; activation — pillar height and glow, from real document frequency in the book.
# triggers: introspective pillars (thoughts, claude, human, fascinating) stay dark until LOOKED at — the observer effect as floor; OOV words stand on the rim, unplaceable, because the book has never said them.
# emerges: "claude" is the tallest pillar in the book's own hidden space; "consciousness" stands outside the manifold entirely. The room does not decorate these facts; it measures them.
# needs: jspace_layout.json [baked by scratchpad/jspace_layout.py]; BakedText tags; a camera to be seen by.
# relationships: geometry from the same LSA recipe as tools/handoff_score.py; the walkable face of the mind-map distance loop; sibling of [[jspace_count_plates]] (the output) and [[jspace_feature_field]] (the raw field).
# truth: a projection that reports its stress is a chart; one that hides it is a myth. This floor is a chart of the book's mind, and the plaque at the center says exactly how much it lies.

const LAYOUT_PATH := "res://commons/artifacts/jspace/jspace_layout.json"
const GAZE_DOT := 0.965          # how directly you must look at an introspective pillar
const GAZE_RANGE := 14.0
const GAZE_FADE := 2.2           # fade-in speed per second

var _gaze_pillars: Array = []    # {node, mat, tag, amount}
var _layout: Dictionary = {}

func _ready() -> void:
	_layout = _load_layout()
	if _layout.is_empty():
		push_warning("JSpaceZoomChamber: no layout json")
		return
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])

func _load_layout() -> Dictionary:
	if not FileAccess.file_exists(LAYOUT_PATH):
		return {}
	var f := FileAccess.open(LAYOUT_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}

func _build() -> void:
	var tiles: Array = _layout.get("tiles", [])
	var stress: float = float(_layout.get("stress1", 0.0))
	var docs: int = int(_layout.get("corpus_docs", 0))

	# floor disc — the chart itself
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = float(_layout.get("half_width_m", 3.6)) + 1.6
	cyl.bottom_radius = cyl.top_radius
	cyl.height = 0.05
	disc.mesh = cyl
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.07, 0.08, 0.12)
	dmat.roughness = 0.8
	disc.material_override = dmat
	disc.position = Vector3(0, 0.025, 0)
	add_child(disc)

	# the honesty plaque, at the center where a monument would go
	var plaque: Node3D = BakedText.make_tag(
		"THE BOOK'S HIDDEN SPACE — %d docs · stress-1 %.2f (how much this floor lies)" % [docs, stress],
		Color(0.92, 0.9, 0.85), 0.07)
	if plaque:
		plaque.position = Vector3(0, 2.4, 0)
		add_child(plaque)
	var plaque2: Node3D = BakedText.make_tag(
		"walking distance = cosine distance, up to the stress", Color(0.65, 0.75, 0.9), 0.05)
	if plaque2:
		plaque2.position = Vector3(0, 2.2, 0)
		add_child(plaque2)

	# pillars
	var placed: Array = []
	for t in tiles:
		_pillar(t)
		if not bool(t.get("oov", false)):
			placed.append(t)

	# nearest-neighbour threads on the floor — the geometry made legible
	for a in placed:
		var best = null
		var best_d := INF
		for b in placed:
			if b == a:
				continue
			var d: float = Vector2(a["x"] - b["x"], a["z"] - b["z"]).length()
			if d < best_d:
				best_d = d
				best = b
		if best != null:
			_thread(Vector3(a["x"], 0.06, a["z"]), Vector3(best["x"], 0.06, best["z"]))

func _pillar(t: Dictionary) -> void:
	var word := str(t.get("word", ""))
	var act := float(t.get("activation", 0.0))
	var oov := bool(t.get("oov", false))
	var intro := bool(t.get("introspective", false))
	var pos := Vector3(float(t.get("x", 0)), 0, float(t.get("z", 0)))

	var root := Node3D.new()
	root.name = word
	root.position = pos
	add_child(root)

	# activation as HEIGHT — superposition drawn as stacking
	var h := 0.25 + act * 1.6 if not oov else 0.35
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.55, h, 0.55)
	body.mesh = bm
	var mat := StandardMaterial3D.new()
	if oov:
		mat.albedo_color = Color(0.16, 0.15, 0.17)
		mat.roughness = 0.9
	else:
		var glow := Color(0.22, 0.54, 0.87).lerp(Color(0.71, 0.83, 0.96), 1.0 - act)
		mat.albedo_color = Color(0.10, 0.14, 0.22)
		mat.emission_enabled = true
		mat.emission = glow
		mat.emission_energy_multiplier = 0.0 if intro else (0.4 + act * 1.8)
	body.material_override = mat
	body.position = Vector3(0, h * 0.5, 0)
	root.add_child(body)

	# the word, named on the pillar
	var doc_note := "%d docs" % int(t.get("docs", 0)) if not oov else "not in the book"
	var tag: Node3D = BakedText.make_tag(word.to_upper(), Color(0.95, 0.93, 0.88), 0.075,
		Color(0.08, 0.09, 0.11), true,
		Color(0.86, 0.40, 0.16) if not oov else Color(0.5, 0.12, 0.12))
	if tag:
		tag.position = Vector3(0, h + 0.28, 0)
		tag.visible = not intro     # introspective names appear only under gaze
		root.add_child(tag)
	var sub: Node3D = BakedText.make_tag(doc_note, Color(0.6, 0.68, 0.78), 0.045)
	if sub:
		sub.position = Vector3(0, h + 0.14, 0)
		sub.visible = not intro
		root.add_child(sub)

	if intro and not oov:
		_gaze_pillars.append({"node": root, "mat": mat, "tags": [tag, sub], "amount": 0.0, "act": act})

func _thread(a: Vector3, b: Vector3) -> void:
	var mid := (a + b) * 0.5
	var d := a.distance_to(b)
	var seg := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.03, 0.01, d)
	seg.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.5, 0.8, 0.5)
	m.emission_enabled = true
	m.emission = Color(0.3, 0.55, 0.9)
	m.emission_energy_multiplier = 0.5
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	seg.material_override = m
	seg.position = mid
	seg.look_at_from_position(mid, b, Vector3.UP)
	add_child(seg)

# ── the observer effect: introspective pillars light only under gaze ────────
func _process(delta: float) -> void:
	if _gaze_pillars.is_empty():
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var cam_pos := cam.global_position
	var cam_fwd := -cam.global_transform.basis.z
	for g in _gaze_pillars:
		var node: Node3D = g["node"]
		var to_pillar: Vector3 = node.global_position + Vector3(0, 1.0, 0) - cam_pos
		var dist := to_pillar.length()
		var looked := dist < GAZE_RANGE and cam_fwd.dot(to_pillar.normalized()) > GAZE_DOT
		var target := 1.0 if looked else 0.0
		g["amount"] = move_toward(float(g["amount"]), target, GAZE_FADE * delta)
		var mat: StandardMaterial3D = g["mat"]
		mat.emission_energy_multiplier = float(g["amount"]) * (0.6 + float(g["act"]) * 2.2)
		for tg in g["tags"]:
			if tg:
				tg.visible = float(g["amount"]) > 0.45
