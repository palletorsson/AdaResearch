extends Node3D
class_name JSpaceRing

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the endless scroller made walkable — twenty-four topic arcs of the spine (point, line, grid, array, loop, random, walk, noise, wave, sound, fractal, recursion, grammar, branch, growth, cell, neighbor, spring, cloth, force, agent, flock, learn, proof) laid around a ring, with sixty concept-words standing as pillars at the angle of their PEAK topic. Your angular position on the ring IS the reading axis; walk it and the whole field re-lights continuously, each word's height and glow interpolating between the two topics you stand between. The loop never ends.
# desire: to walk a topic change as locomotion — for the world to change around you, topic to topic, forever, with the changes MEASURED (LSA activation in the book's own corpus) not decorated.
# critical_parameter: player angle -> fractional topic; each word's height = its activation under the interpolated reading axis. Nothing moves; the light rotates with you.
# triggers: _process reads the camera's angle around the ring, interpolates the activation column, resizes and re-lights every pillar; the topic tag under you updates; the floor arc you stand in glows.
# emerges: point-country sinks behind you as line-country rises ahead; the spine's whole arc becomes one endless walk; where you stand is how much the question has changed.
# needs: jspace_topics.json [baked by scratchpad/jspace_topics.py]; BakedText tags; a camera to read the angle from.
# relationships: the ring form of [[jspace_zoom_chamber]] (one topic) and [[jspace_shift]] (two topics); the endless twin of the mind-map distance loop; the spine read as a circle you never leave.
# truth: a curriculum is usually a line with an end. This one is a ring with none — because the questions don't finish, they hand on. Walk long enough and point comes back around after proof.

const TOPICS_PATH := "res://commons/artifacts/jspace/jspace_topics.json"
const RING_R := 6.0            # walkable ring radius (metres)
const PILLAR_SPREAD := 1.6     # how far pillars sit off the path (inner/outer walls)
const MARKER_R := 8.2          # topic-name markers, outer
const MAX_H := 2.4             # tallest pillar at full activation

var _data: Dictionary = {}
var _topics: Array = []
var _pillars: Array = []       # {node, mat, acts, base_y}
var _topic_tags: Array = []    # {node, mat, index}
var _floor_arcs: Array = []    # {mat, index}
var _reader_tag: Node3D
var _reader_mat: StandardMaterial3D
var _n := 0

func _ready() -> void:
	_data = _load()
	_topics = _data.get("topics", [])
	_n = _topics.size()
	if _n == 0:
		push_warning("JSpaceRing: no topics json")
		return
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])

func _load() -> Dictionary:
	if not FileAccess.file_exists(TOPICS_PATH):
		return {}
	var f := FileAccess.open(TOPICS_PATH, FileAccess.READ)
	var p = JSON.parse_string(f.get_as_text())
	return p if p is Dictionary else {}

func _angle_of_topic(i: int) -> float:
	return TAU * float(i) / float(_n)

func _build() -> void:
	# hub disc + honesty plaque
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = MARKER_R + 1.4
	cyl.bottom_radius = cyl.top_radius
	cyl.height = 0.04
	disc.mesh = cyl
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.06, 0.07, 0.11)
	dmat.roughness = 0.85
	disc.material_override = dmat
	disc.position = Vector3(0, 0.02, 0)
	add_child(disc)

	var plaque: Node3D = BakedText.make_tag(
		"THE SPINE AS A RING — 24 topics, %d words · activation = LSA cosine, book corpus" % _pillar_count(),
		Color(0.92, 0.9, 0.85), 0.09)
	if plaque:
		plaque.position = Vector3(0, 3.0, 0)
		add_child(plaque)
	var plaque2: Node3D = BakedText.make_tag(
		"where you stand is how much the question has changed — the loop never ends",
		Color(0.65, 0.75, 0.9), 0.06)
	if plaque2:
		plaque2.position = Vector3(0, 2.75, 0)
		add_child(plaque2)

	# the reader tag — floats above center, names the topic you stand in
	_reader_tag = BakedText.make_tag("POINT", Color(0.98, 0.94, 0.88), 0.16,
		Color(0.10, 0.08, 0.09), true, Color(0.86, 0.40, 0.16))
	if _reader_tag:
		_reader_tag.position = Vector3(0, 1.7, 0)
		add_child(_reader_tag)
		for c in _reader_tag.get_children():
			var mo = c.material_override
			if mo is StandardMaterial3D and mo.emission_enabled:
				_reader_mat = mo

	# topic markers + floor arcs
	for i in _n:
		var ang := _angle_of_topic(i)
		var dir := Vector3(cos(ang), 0, sin(ang))
		var tag: Node3D = BakedText.make_tag(str(_topics[i]).to_upper(),
			Color(0.9, 0.93, 1.0), 0.10)
		if tag:
			tag.position = dir * MARKER_R + Vector3(0, 0.9, 0)
			add_child(tag)
			_topic_tags.append({"node": tag, "index": i})
		# floor arc wedge under this topic
		var arc := MeshInstance3D.new()
		var am := BoxMesh.new()
		am.size = Vector3(1.4, 0.02, 2.2)
		arc.mesh = am
		var amat := StandardMaterial3D.new()
		amat.albedo_color = Color(0.1, 0.13, 0.2)
		amat.emission_enabled = true
		amat.emission = Color(0.2, 0.4, 0.75)
		amat.emission_energy_multiplier = 0.05
		arc.material_override = amat
		arc.position = dir * RING_R + Vector3(0, 0.03, 0)
		arc.look_at_from_position(arc.position, Vector3.ZERO, Vector3.UP)
		add_child(arc)
		_floor_arcs.append({"mat": amat, "index": i})

	# word pillars — each at its peak topic's angle, jittered so the arc reads as a crowd
	var words: Array = _data.get("words", [])
	var per_topic := {}
	for e in words:
		var pt := str(e.get("peak_topic", ""))
		per_topic[pt] = int(per_topic.get(pt, 0)) + 1
		_pillar(e, int(per_topic[pt]) - 1)

func _pillar_count() -> int:
	return int((_data.get("words", []) as Array).size())

func _pillar(e: Dictionary, rank: int) -> void:
	var word := str(e.get("word", ""))
	var peak := str(e.get("peak_topic", ""))
	var ti := _topics.find(peak)
	if ti < 0:
		ti = 0
	var acts: Array = e.get("activations", [])
	# angle = peak topic's arc, nudged by rank so pillars fan across the wedge
	var nudge := (float(rank % 5) - 2.0) * 0.045
	var ang := _angle_of_topic(ti) + nudge
	var dir := Vector3(cos(ang), 0, sin(ang))
	# alternate inner/outer wall so you walk a corridor of words
	var side := 1.0 if (rank % 2 == 0) else -1.0
	var r := RING_R + side * PILLAR_SPREAD
	var pos := dir * r

	var root := Node3D.new()
	root.name = word
	root.position = pos
	add_child(root)

	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.42, 1.0, 0.42)   # y scaled per-frame
	body.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.09, 0.13, 0.22)
	mat.emission_enabled = true
	mat.emission = Color(0.22, 0.5, 0.9)
	mat.emission_energy_multiplier = 0.1
	body.material_override = mat
	body.position = Vector3(0, 0.5, 0)
	root.add_child(body)

	var tag: Node3D = BakedText.make_tag(word.to_upper(), Color(0.95, 0.93, 0.88), 0.06)
	if tag:
		tag.position = Vector3(0, 1.2, 0)
		root.add_child(tag)

	_pillars.append({"body": body, "mat": mat, "tag": tag, "acts": acts, "root": root})

# ── the scroll: player angle -> reading axis -> re-light everything ──────────
func _process(_delta: float) -> void:
	if _n == 0:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var lp := to_local(cam.global_position)
	var ang := atan2(lp.z, lp.x)
	if ang < 0.0:
		ang += TAU
	# fractional topic position on the ring
	var f := ang / TAU * float(_n)
	var i0 := int(floor(f)) % _n
	var i1 := (i0 + 1) % _n
	var frac := f - floor(f)

	# re-light every pillar by its interpolated activation
	for p in _pillars:
		var acts: Array = p["acts"]
		if acts.size() <= i1:
			continue
		var a := lerp(float(acts[i0]), float(acts[i1]), frac)
		a = clampf(a, 0.0, 0.6) / 0.6            # normalize typical range
		var h := 0.12 + a * MAX_H
		var body: MeshInstance3D = p["body"]
		body.scale.y = h
		body.position.y = h * 0.5
		var mat: StandardMaterial3D = p["mat"]
		mat.emission_energy_multiplier = 0.1 + a * 2.4
		if p["tag"]:
			p["tag"].position.y = h + 0.22
			p["tag"].visible = a > 0.28        # only near-topic words announce themselves

	# the topic tag you stand in
	if _reader_tag:
		var name := str(_topics[i0]) if frac < 0.5 else str(_topics[i1])
		_relabel_reader(name.to_upper())
	# glow the two floor arcs you straddle
	for fa in _floor_arcs:
		var mat: StandardMaterial3D = fa["mat"]
		var idx: int = fa["index"]
		var near := 0.0
		if idx == i0:
			near = 1.0 - frac
		elif idx == i1:
			near = frac
		mat.emission_energy_multiplier = 0.05 + near * 1.6
	for tt in _topic_tags:
		var idx: int = tt["index"]
		var d := absi(idx - i0)
		d = mini(d, _n - d)
		var vis: bool = d <= 3
		tt["node"].visible = vis

var _last_reader := ""
func _relabel_reader(name: String) -> void:
	if name == _last_reader:
		return
	_last_reader = name
	# rebuild the reader tag's text quad (cheap; BakedText caches by string)
	var new_tag: Node3D = BakedText.make_tag(name, Color(0.98, 0.94, 0.88), 0.16,
		Color(0.10, 0.08, 0.09), true, Color(0.86, 0.40, 0.16))
	if new_tag == null:
		return
	new_tag.position = _reader_tag.position
	_reader_tag.queue_free()
	add_child(new_tag)
	_reader_tag = new_tag
