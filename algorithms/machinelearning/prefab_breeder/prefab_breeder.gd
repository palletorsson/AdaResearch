extends Node3D
## THE BREEDING YARD (floor ML_Evolution; the pass, 2026-11-14)
##
## Palle, 2026-11-14: "can we use machine learning to create new strange prefabs or designs". The hall already
## names the method: the flowers evolve toward a taste someone wrote down, and in Karl Sims's Galapagos (1997)
## visitors selected forms by standing in front of them; the selected forms survived and produced varied offspring.
## "A written taste and a visitor's choice give selection different histories."
##
## Six forms stand in a row, each grown from a genome whose genes are the tower's own prefabs: which prefab, on which
## face of which earlier part it sits, how big, which way up, and whether the whole is mirrored. Stand still on the
## pad in front of one: it stays, and the other five become its varied children (one to three genes changed). Nothing
## here is trained: this is selection, by one of three judges, and `judge` is the axis -
##   visitor  = whoever stands on a pad;
##   sentence = a written taste, TALL (2 points a metre) MIRRORED (3 points) FEW KINDS (-1 a kind): stand on its
##              plate and it chooses the highest score every two and a half seconds;
##   nobody   = one of the six is kept by lot: stand on its plate and watch drift.
## All three are on the floor at once; the axis is who has been choosing before anyone arrives (`generations`).
## The number under each form is what the sentence would give it, whoever chose it.
##
## KEEP puts the last chosen form on the shelf behind the row and writes it as a recipe - its genome and its parts,
## each a prefab id with a place, a turn and an envelope - to a file anyone can build again through the lab adapter.
## Kept recipes are read back when the floor is built: what was bred yesterday stands on the shelf today. They are
## proposals, not catalogue entries.
##
## Built through prefab_city.gd from ten of the spatial lab's inputs; the adapter fits each source's own meshes to
## the envelope the genome asks for, so a part can be a stretched or upended version of its prefab.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const SLOTS := 6
const PITCH := 2.4
const PLOT := 2.0
const TALLEST := 3.2
const DWELL := 0.8
const TICK := 2.5
const SHELF := 6
## The genes' alphabet: a lab input and the envelope it has at its own size.
const KINDS := [
	["crate", Vector3(0.76, 0.76, 0.76)], ["construction_cube", Vector3(1.0, 1.0, 1.0)], ["timber_plank_2m", Vector3(2.0, 0.06, 0.25)],
	["timber_panel_1x1", Vector3(1.0, 0.045, 1.0)], ["traffic_pyramid_5", Vector3(0.6, 0.9, 0.6)], ["pentagonal_bipyramid_7", Vector3(0.84, 0.9, 0.84)],
	["trace_point_ball", Vector3(0.56, 0.56, 0.56)], ["tetrahedron_blocker", Vector3(1.62, 1.32, 1.4)], ["wp", Vector3(1.0, 1.0, 2.0)], ["barrier", Vector3(2.0, 1.03, 0.6)]]
const SIZES := [0.6, 0.8, 1.0, 1.25, 1.5]
const JUDGES := ["visitor", "sentence", "nobody"]

@export_enum("visitor", "sentence", "nobody") var judge := "visitor"
## Generations bred before anyone arrives, by the axis's judge (the visitor cannot choose in advance: 0 for that).
@export var generations := 0
@export var yard_seed := 7
## Where KEEP writes and the shelf reads; empty = ada_run/bred_prefabs in the project, user://bred_prefabs in an export.
@export var keep_folder := ""

var _city = City.new()
var _rng := RandomNumberGenerator.new()
var _genomes: Array = []
var _stands: Array[Node3D] = []
var _tags: Array[Label3D] = []
var _measures: Array = []               # per slot {"height": float, "kinds": int, "parts": int}
var _pending: Array[int] = []
var _generation := 0
var _chosen_by := {"visitor": 0, "sentence": 0, "nobody": 0}
var _last := -1
var _last_judge := ""
var _kept: Array = []                   # recipes on the shelf, newest last
var _shelf: Array[Node3D] = []
var _plates: Array = []                 # {"at": Vector3, "what": String, "slot": int, "time": float, "held": bool, "tile": MeshInstance3D}
var _board: Label3D
var _body: CharacterBody3D
var _saved := ""
var _build_ms := 0


func _ready() -> void:
	for key in ["judge", "generations", "yard_seed", "keep_folder"]:
		if has_meta("config_" + key): _take({key: get_meta("config_" + key)})
	var began := Time.get_ticks_msec()
	_build_once()
	set_yard()
	reload_shelf()
	_build_ms = Time.get_ticks_msec() - began


func _take(config_data: Dictionary) -> void:
	if config_data.has("judge") and str(config_data["judge"]) in JUDGES: judge = str(config_data["judge"])
	if config_data.has("generations"): generations = clampi(int(float(str(config_data["generations"]))), 0, 200)
	if config_data.has("yard_seed"): yard_seed = int(float(str(config_data["yard_seed"])))
	if config_data.has("keep_folder"): keep_folder = str(config_data["keep_folder"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := [judge, generations, yard_seed, keep_folder]
	_take(config_data)
	if is_inside_tree() and not _stands.is_empty() and before != [judge, generations, yard_seed, keep_folder]:
		set_yard()
		reload_shelf()


## ---- genomes ----

func _gene(parts_so_far: int) -> Dictionary:
	return {"k": _rng.randi_range(0, KINDS.size() - 1), "on": _rng.randi_range(0, maxi(0, parts_so_far - 1)), "face": _rng.randi_range(0, 4), "s": _rng.randi_range(0, SIZES.size() - 1),
		"yaw": _rng.randi_range(0, 1), "up": _rng.randi_range(0, 2), "off": _rng.randi_range(-1, 1)}


func _founder() -> Dictionary:
	var parts := []
	for i in _rng.randi_range(3, 5): parts.append(_gene(i))
	return {"parts": parts, "mirror": _rng.randf() < 0.4}


## A child: the parent with one to three genes changed.
func mutate(parent: Dictionary) -> Dictionary:
	var child: Dictionary = parent.duplicate(true)
	var parts: Array = child["parts"]
	for n in _rng.randi_range(1, 3):
		var roll := _rng.randf()
		var i := _rng.randi_range(0, parts.size() - 1)
		if roll < 0.22: parts[i]["k"] = (int(parts[i]["k"]) + _rng.randi_range(1, KINDS.size() - 1)) % KINDS.size()
		elif roll < 0.42: parts[i]["s"] = clampi(int(parts[i]["s"]) + (1 if _rng.randf() < 0.5 else -1), 0, SIZES.size() - 1)
		elif roll < 0.56: parts[i]["face"] = (int(parts[i]["face"]) + _rng.randi_range(1, 4)) % 5
		elif roll < 0.66: parts[i]["up"] = (int(parts[i]["up"]) + _rng.randi_range(1, 2)) % 3
		elif roll < 0.74: parts[i]["yaw"] = 1 - int(parts[i]["yaw"])
		elif roll < 0.86 and parts.size() < 7: parts.append(_gene(parts.size()))
		elif roll < 0.93 and parts.size() > 2: parts.pop_back()
		else: child["mirror"] = not bool(child["mirror"])
	for i in parts.size(): parts[i]["on"] = clampi(int(parts[i]["on"]), 0, maxi(0, i - 1))
	if child == parent: child["mirror"] = not bool(child["mirror"])
	return child


## The genome grown into parts: [{"prefab", "at" (foot), "yaw" (degrees), "fit" (envelope)}], and what it measures.
func grow(genome: Dictionary) -> Dictionary:
	var boxes: Array = []               # world boxes of the grown parts: {"min": Vector3, "max": Vector3}
	var out: Array = []
	var genes: Array = genome["parts"]
	for i in genes.size():
		var g: Dictionary = genes[i]
		var kind: Array = KINDS[int(g["k"])]
		var natural: Vector3 = kind[1]
		var env := natural
		if int(g["up"]) == 1: env = Vector3(natural.y, natural.x, natural.z)
		elif int(g["up"]) == 2: env = Vector3(natural.x, natural.z, natural.y)
		env *= float(SIZES[int(g["s"])])
		var turned: bool = int(g["yaw"]) == 1
		var size := Vector3(env.z, env.y, env.x) if turned else env
		var centre := Vector3(0, size.y * 0.5, 0)
		if i > 0:
			var p: Dictionary = boxes[int(g["on"])]
			var lo: Vector3 = p["min"]
			var hi: Vector3 = p["max"]
			var mid := (lo + hi) * 0.5
			var slide: float = float(int(g["off"])) * 0.3
			match int(g["face"]):
				0: centre = Vector3(mid.x + slide * (hi.x - lo.x), hi.y + size.y * 0.5, mid.z)
				1: centre = Vector3(hi.x + size.x * 0.5, lo.y + size.y * 0.5 + maxf(0.0, slide) * (hi.y - lo.y), mid.z)
				2: centre = Vector3(lo.x - size.x * 0.5, lo.y + size.y * 0.5 + maxf(0.0, slide) * (hi.y - lo.y), mid.z)
				3: centre = Vector3(mid.x, lo.y + size.y * 0.5 + maxf(0.0, slide) * (hi.y - lo.y), hi.z + size.z * 0.5)
				_: centre = Vector3(mid.x, lo.y + size.y * 0.5 + maxf(0.0, slide) * (hi.y - lo.y), lo.z - size.z * 0.5)
		boxes.append({"min": centre - size * 0.5, "max": centre + size * 0.5})
		out.append({"prefab": str(kind[0]), "at": Vector3(centre.x, centre.y - size.y * 0.5, centre.z), "yaw": 90.0 if turned else 0.0, "fit": env, "size": size})
	if bool(genome["mirror"]):
		for part in out.duplicate():
			var at: Vector3 = part["at"]
			if absf(at.x) < 0.05: continue
			var twin: Dictionary = part.duplicate()
			twin["at"] = Vector3(-at.x, at.y, at.z)
			out.append(twin)
	var lo_all := Vector3(INF, INF, INF)
	var hi_all := Vector3(-INF, -INF, -INF)
	var kinds := {}
	for part in out:
		var at: Vector3 = part["at"]
		var size: Vector3 = part["size"]
		lo_all = lo_all.min(Vector3(at.x - size.x * 0.5, at.y, at.z - size.z * 0.5))
		hi_all = hi_all.max(Vector3(at.x + size.x * 0.5, at.y + size.y, at.z + size.z * 0.5))
		kinds[part["prefab"]] = true
	return {"parts": out, "min": lo_all, "max": hi_all, "height": hi_all.y, "kinds": kinds.size()}


## What the written taste gives a grown form.
func score(grown: Dictionary, genome: Dictionary) -> float:
	return float(grown["height"]) * 2.0 + (3.0 if bool(genome["mirror"]) else 0.0) - float(int(grown["kinds"]))


func best_slot() -> int:
	var best := 0
	for i in SLOTS:
		if float(_measures[i]["score"]) > float(_measures[best]["score"]): best = i
	return best


## ---- the yard ----

func set_yard() -> void:
	_rng.seed = yard_seed
	_genomes.clear()
	for i in SLOTS: _genomes.append(_founder())
	_generation = 0
	_chosen_by = {"visitor": 0, "sentence": 0, "nobody": 0}
	_last = -1
	_last_judge = ""
	_measure_all()
	if judge != "visitor":
		for n in generations: choose(best_slot() if judge == "sentence" else _rng.randi_range(0, SLOTS - 1), judge, false)
	_pending.clear()
	for i in SLOTS: _raise(i)
	_tell()


func _measure_all() -> void:
	_measures.clear()
	for i in SLOTS:
		var grown := grow(_genomes[i])
		_measures.append({"height": float(grown["height"]), "kinds": int(grown["kinds"]), "parts": (grown["parts"] as Array).size(), "score": score(grown, _genomes[i])})


## One generation: the chosen form stays, the other five become its children.
func choose(slot: int, by: String, raise_now: bool = true) -> void:
	var parent: Dictionary = _genomes[slot]
	for i in SLOTS:
		if i != slot: _genomes[i] = mutate(parent)
	_generation += 1
	_chosen_by[by] = int(_chosen_by[by]) + 1
	_last = slot
	_last_judge = by
	_measure_all()
	if raise_now:
		for i in SLOTS:
			if i != slot and not _pending.has(i): _pending.append(i)
		_tell()


## Build a slot's form from its genome: the prefabs through the lab adapter, fitted to the plot.
func _raise(slot: int) -> void:
	var stand := _stands[slot]
	for child in stand.get_children(): child.queue_free()
	_form(stand, grow(_genomes[slot]), PLOT, TALLEST)
	_tags[slot].text = "%d\nthe sentence: %.1f" % [slot + 1, float(_measures[slot]["score"])]


func _form(parent: Node3D, grown: Dictionary, plot: float, tallest: float) -> Node3D:
	var lo: Vector3 = grown["min"]
	var hi: Vector3 = grown["max"]
	var form := Node3D.new()
	form.name = "Form"
	parent.add_child(form)
	var fit: float = minf(1.0, minf(plot / maxf(0.01, hi.x - lo.x), minf(plot / maxf(0.01, hi.z - lo.z), tallest / maxf(0.01, hi.y))))
	form.scale = Vector3.ONE * fit
	form.position = Vector3(-(lo.x + hi.x) * 0.5 * fit, 0, -(lo.z + hi.z) * 0.5 * fit)
	for part in grown["parts"]:
		_city.part(form, str(part["prefab"]), part["at"], float(part["yaw"]), part["fit"], false)
	return form


## ---- keeping ----

func _folder() -> String:
	if keep_folder != "": return keep_folder
	var project := ProjectSettings.globalize_path("res://ada_run")
	if project != "" and DirAccess.dir_exists_absolute(project): return project.path_join("bred_prefabs")
	return "user://bred_prefabs"


func recipe(slot: int) -> Dictionary:
	var grown := grow(_genomes[slot])
	var parts := []
	for part in grown["parts"]:
		var at: Vector3 = part["at"]
		var fit: Vector3 = part["fit"]
		parts.append({"prefab": str(part["prefab"]), "at": [snappedf(at.x, 0.001), snappedf(at.y, 0.001), snappedf(at.z, 0.001)], "yaw": float(part["yaw"]),
			"fit": [snappedf(fit.x, 0.001), snappedf(fit.y, 0.001), snappedf(fit.z, 0.001)]})
	return {"id": "bred_%d_g%d_s%d" % [yard_seed, _generation, slot + 1], "bred": {"seed": yard_seed, "generation": _generation, "chosen_by": _last_judge, "choices": _chosen_by.duplicate(),
		"sentence_score": snappedf(float(_measures[slot]["score"]), 0.01)}, "how_to_build": "each part: commons/modular/lab_input.gd with token = prefab, fit_box = fit, at = its foot (lift by half fit.y), yaw in degrees",
		"genome": _genomes[slot].duplicate(true), "parts": parts}


## Keep the last chosen form: on the shelf, and as a recipe file.
func keep() -> String:
	if _last < 0: return ""
	var made := recipe(_last)
	var folder := _folder()
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join(str(made["id"]) + ".json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return ""
	file.store_string(JSON.stringify(made, "\t"))
	file.close()
	_saved = path
	_kept.append(made)
	while _kept.size() > SHELF: _kept.pop_front()
	_show_shelf()
	_tell()
	return path


## Read the kept recipes back: the newest six stand on the shelf.
func reload_shelf() -> void:
	_kept.clear()
	var folder := _folder()
	var dir := DirAccess.open(folder)
	if dir != null:
		var names := []
		for found in dir.get_files():
			if found.ends_with(".json"): names.append(found)
		names.sort_custom(func(a, b): return FileAccess.get_modified_time(folder.path_join(a)) < FileAccess.get_modified_time(folder.path_join(b)))
		for kept_name in names.slice(maxi(0, names.size() - SHELF)):
			var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join(kept_name)))
			if data is Dictionary and (data as Dictionary).get("genome") is Dictionary: _kept.append(data)
	_show_shelf()


func _show_shelf() -> void:
	for i in SHELF:
		var place := _shelf[i]
		for child in place.get_children(): child.queue_free()
		if i >= _kept.size(): continue
		var genome: Dictionary = _fix(_kept[i]["genome"])
		_form(place, grow(genome), 1.0, 1.6)
		var tag: Label3D = _city.sign_post(place, Vector3(0, 1.85, 0))
		tag.pixel_size = 0.002
		tag.text = str(_kept[i].get("id", "kept"))


## A genome read from a file has floats where the genes are whole numbers.
func _fix(genome: Dictionary) -> Dictionary:
	var parts := []
	for g in genome.get("parts", []):
		var gene := {}
		for key in g: gene[key] = int(g[key])
		parts.append(gene)
	return {"parts": parts, "mirror": bool(genome.get("mirror", false))}


## ---- the body ----

func _physics_process(delta: float) -> void:
	var here := _body != null and is_instance_valid(_body)
	var p := Vector3.ZERO
	if here: p = to_local(_body.global_position)
	for plate in _plates:
		var at: Vector3 = plate["at"]
		var on_plate: bool = here and Vector2(p.x - at.x, p.z - at.z).length() < 0.32
		var still: bool = on_plate and Vector2(_body.velocity.x, _body.velocity.z).length() < 0.3
		var what := str(plate["what"])
		if not still:
			plate["time"] = 0.0
			if not on_plate: plate["held"] = false
			continue
		plate["time"] = float(plate["time"]) + delta
		if what == "pad" or what == "keep":
			if float(plate["time"]) >= DWELL and not bool(plate["held"]) and _pending.is_empty():
				plate["held"] = true
				if what == "pad": choose(int(plate["slot"]), "visitor")
				else: keep()
		elif float(plate["time"]) >= (DWELL if not bool(plate["held"]) else TICK) and _pending.is_empty():
			# a judge's plate: a generation now, and one every two and a half seconds while the body stays
			plate["held"] = true
			plate["time"] = 0.0
			choose(best_slot() if what == "sentence" else _rng.randi_range(0, SLOTS - 1), what)


func _process(_delta: float) -> void:
	if not _pending.is_empty(): _raise(_pending.pop_front())


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["THE BREEDING YARD"])
	lines.append("Six forms grown from the tower's prefabs. Stand still on the pad in front of the one you like: it stays, and the other five become its varied children. Nothing is trained here; something selects.")
	var last := "Nobody has chosen yet." if _last < 0 else "Last kept: form %d, by %s." % [_last + 1, "you" if _last_judge == "visitor" else ("the sentence" if _last_judge == "sentence" else "lot")]
	lines.append("Generation %d. Chosen by a visitor %d times, by the sentence %d, by nobody %d. %s" % [_generation, int(_chosen_by["visitor"]), int(_chosen_by["sentence"]), int(_chosen_by["nobody"]), last])
	lines.append("The sentence: TALL (2 points a metre), MIRRORED (3), FEW KINDS (-1 a kind). Stand on its plate and it chooses for you; on the other plate nobody does - one is kept by lot. The number under a form is what the sentence would give it.")
	lines.append("KEEP puts the last chosen form on the shelf behind and writes its recipe%s." % ("" if _saved == "" else ": " + _saved.get_file()))
	_board.text = "\n".join(lines)


## ---- building, once ----

func _build_once() -> void:
	var ground := Node3D.new()
	ground.name = "Ground"
	add_child(ground)
	var half: float = float(SLOTS - 1) * PITCH * 0.5
	for i in SLOTS:
		var x: float = -half + float(i) * PITCH
		_city.sheet(ground, Vector3(x, 0.004, 0), Vector2(PLOT + 0.2, PLOT + 0.2), Color("2a2d36"))
		var stand := Node3D.new()
		stand.name = "Stand%d" % i
		stand.position = Vector3(x, 0.01, 0)
		ground.add_child(stand)
		_stands.append(stand)
		var tag: Label3D = _city.floor_words(ground, Vector3(x, 0.014, PLOT * 0.5 + 0.42), "", 30)
		_tags.append(tag)
		_plate(ground, Vector3(x, 0, PLOT * 0.5 + 1.15), "pad", i, Color("5fd08a"), "")
		var place := Node3D.new()
		place.name = "Kept%d" % i
		place.position = Vector3(x, 0.01, -PLOT * 0.5 - 1.1)
		ground.add_child(place)
		_shelf.append(place)
	_city.sheet(ground, Vector3(0, 0.003, -PLOT * 0.5 - 1.1), Vector2(half * 2.0 + PLOT, 1.3), Color("3b3340"))
	_city.floor_words(ground, Vector3(-half - 0.2, 0.014, -PLOT * 0.5 - 0.25), "KEPT", 30, Color(1.0, 0.75, 0.88))
	_plate(ground, Vector3(-2.4, 0, PLOT * 0.5 + 2.7), "sentence", -1, Color("e2ac70"), "THE SENTENCE CHOOSES\nstand here")
	_plate(ground, Vector3(0.0, 0, PLOT * 0.5 + 2.7), "nobody", -1, Color("8a8f98"), "NOBODY CHOOSES\nstand here")
	_plate(ground, Vector3(2.4, 0, PLOT * 0.5 + 2.7), "keep", -1, Color("ff5fa8"), "KEEP\nthe last chosen")
	for end in [-1.0, 1.0]: _city.part(ground, "traffic_pyramid_5", Vector3(end * (half + PLOT * 0.5 + 0.5), 0, 0), 0, Vector3(0.45, 0.7, 0.45))
	var sensor := Area3D.new()
	sensor.name = "Reach"
	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(half * 2.0 + PLOT + 4.0, 2.4, 10.0)
	var shape := CollisionShape3D.new()
	shape.shape = room
	shape.position = Vector3(0, 1.2, 1.5)
	sensor.add_child(shape)
	ground.add_child(sensor)
	sensor.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _body = b)
	sensor.body_exited.connect(func(b: Node) -> void:
		if b == _body: _body = null)
	_board = _city.board(ground, Vector3(4.7, 0, PLOT * 0.5 + 3.2), 3.3, 1.3)


func _plate(parent: Node3D, at: Vector3, what: String, slot: int, colour: Color, words: String) -> void:
	var tile: MeshInstance3D = _city.sheet(parent, at + Vector3(0, 0.006, 0), Vector2(0.62, 0.62), colour)
	if words != "": _city.floor_words(parent, at + Vector3(0, 0.014, 0.6), words, 28)
	_plates.append({"at": at, "what": what, "slot": slot, "time": 0.0, "held": false, "tile": tile})


## ---- for a test ----

func state() -> Dictionary:
	var texts := []
	for g in _genomes: texts.append(JSON.stringify(g))
	return {"judge": judge, "generation": _generation, "chosen_by": _chosen_by.duplicate(), "last": _last, "last_judge": _last_judge, "genomes": texts, "measures": _measures.duplicate(true),
		"best": best_slot(), "pending": _pending.size(), "kept": _kept.size(), "saved": _saved, "folder": _folder(), "prefab_parts": int(_city.parts), "build_ms": _build_ms}


func plate_point(what: String, slot: int = -1) -> Vector3:
	for plate in _plates:
		if str(plate["what"]) == what and int(plate["slot"]) == slot: return to_global(plate["at"])
	return global_position


func point_at(local: Vector3) -> Vector3:
	return to_global(local)
