# biome_grammar.gd — what the biome may be made of, do and know at a given hall.
#
# The ladder is commons/data/biome_vocabulary.json: per-hall entries for the halls
# that have them (all of primitives), per-sequence entries for every spine sequence.
# A stage's CLOSURE is cumulative: every hall at or before it in the walk, plus every
# sequence entry whose sequence is at or before the stage's. The walk order is the
# spine (commons/maps/curriculum_spine.json) for sequences and map_authored.json for
# the halls inside one. A stage may be a hall (map name) or a sequence key — a
# sequence key means "all of that sequence learned", i.e. its last hall.
#
# Preloaded by its users, like the other biome_layers helpers, so headless runs resolve it.
extends RefCounted
class_name BiomeGrammar

const VOCAB_PATH := "res://commons/data/biome_vocabulary.json"
const SPINE_PATH := "res://commons/maps/curriculum_spine.json"
const AUTHORED_PATH := "res://commons/data/map_authored.json"
const COLUMNS: Array[String] = ["made_of", "does", "knows"]

static var _vocab: Dictionary = {}
static var _spine: Array[String] = []          # sequence keys in walk order
static var _halls: Dictionary = {}             # sequence -> Array[String] of maps in walk order
static var _loaded: bool = false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var v: Variant = _read(VOCAB_PATH)
	_vocab = v if v is Dictionary else {}
	var s: Variant = _read(SPINE_PATH)
	_spine.clear()
	if s is Dictionary:
		var sp: Variant = (s as Dictionary).get("spine", s)
		for row in (sp as Dictionary).get("sequences", []):
			if row is Dictionary and String((row as Dictionary).get("name", "")) != "":
				_spine.append(String((row as Dictionary)["name"]))
	var a: Variant = _read(AUTHORED_PATH)
	_halls.clear()
	if a is Dictionary:
		for key in (a as Dictionary).keys():
			var lst: Variant = (a as Dictionary)[key]
			if lst is Array:
				var maps: Array[String] = []
				for m in lst:
					maps.append(String(m))
				_halls[String(key)] = maps


static func _read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


## Drop the caches (tests, or after the vocabulary was edited).
static func invalidate() -> void:
	_loaded = false


## Where a stage stands on the walk: {known, sequence, spine (0-based), hall (0-based
## within the sequence, -1 when the stage is the whole sequence), map, is_hall}.
static func position_of(stage: String) -> Dictionary:
	_load()
	var key := stage.strip_edges()
	var out := {"known": false, "sequence": "", "spine": -1, "hall": -1, "map": "", "is_hall": false}
	if key == "":
		return out
	# a hall?
	for seq in _halls.keys():
		var maps: Array = _halls[seq]
		var i: int = maps.find(key)
		if i >= 0:
			out["known"] = true
			out["sequence"] = String(seq)
			out["spine"] = _spine.find(String(seq))
			out["hall"] = i
			out["map"] = key
			out["is_hall"] = true
			return out
	# a sequence? (the whole sequence learned = its last hall)
	var lower := key.to_lower()
	if _spine.has(lower) or (_vocab.get("sequences", {}) as Dictionary).has(lower):
		out["known"] = true
		out["sequence"] = lower
		out["spine"] = _spine.find(lower)
		var maps: Array = _halls.get(lower, [])
		out["hall"] = maps.size() - 1
		return out
	return out


## The cumulative vocabulary at a stage. {made_of, does, knows: Array[String]; position}.
static func closure(stage: String) -> Dictionary:
	_load()
	var pos: Dictionary = position_of(stage)
	var out := {"made_of": [] as Array[String], "does": [] as Array[String], "knows": [] as Array[String], "position": pos}
	if not bool(pos["known"]):
		return out
	var halls_v: Dictionary = _vocab.get("halls", {})
	var seqs_v: Dictionary = _vocab.get("sequences", {})
	var my_spine: int = int(pos["spine"])
	for si in range(_spine.size()):
		var seq: String = _spine[si]
		var before: bool = si < my_spine
		var same: bool = si == my_spine
		if not (before or same):
			continue
		# the sequence's own words arrive with its first hall
		_merge(out, seqs_v.get(seq, {}))
		var maps: Array = _halls.get(seq, [])
		for hi in range(maps.size()):
			if same and int(pos["hall"]) >= 0 and hi > int(pos["hall"]):
				break
			_merge(out, halls_v.get(String(maps[hi]), {}))
	# a sequence not on the spine (biome_lab, mosaicanalysis): its own entry only
	if my_spine < 0:
		_merge(out, seqs_v.get(String(pos["sequence"]), {}))
	return out


static func _merge(into: Dictionary, entry: Dictionary) -> void:
	for col in COLUMNS:
		var words: Variant = entry.get(col, [])
		if words is Array:
			for w in words:
				var s := String(w)
				if not (into[col] as Array).has(s):
					(into[col] as Array).append(s)


static func allows(cl: Dictionary, word: String) -> bool:
	for col in COLUMNS:
		if (cl.get(col, []) as Array).has(word):
			return true
	return false


## The walk as stages: for every spine sequence, its halls that HAVE vocabulary entries
## (in map_authored order), else the sequence key itself. A ladder room in map_authored
## is not a lesson, so it is skipped; a sequence with no per-hall words is one stage.
static func walk() -> Array[String]:
	_load()
	var out: Array[String] = []
	var halls_v: Dictionary = _vocab.get("halls", {})
	for seq in _spine:
		var any := false
		for m in _halls.get(seq, []):
			if halls_v.has(String(m)):
				out.append(String(m))
				any = true
		if not any:
			out.append(seq)
	return out


## The stage before and after `stage` on the walk ("" at the ends). A sequence key is
## the last stage of its sequence; a hall without words maps to its sequence's last stage.
static func neighbours(stage: String) -> Dictionary:
	var w: Array[String] = walk()
	var key := stage.strip_edges()
	var i: int = w.find(key)
	if i < 0:
		var pos: Dictionary = position_of(key)
		if bool(pos["known"]):
			var seq: String = String(pos["sequence"])
			for j in range(w.size() - 1, -1, -1):
				if w[j] == seq or String(position_of(w[j]).get("sequence", "")) == seq:
					i = j
					break
	if i < 0:
		return {"prev": "", "next": "", "index": -1, "count": w.size()}
	return {"prev": w[i - 1] if i > 0 else "", "next": w[i + 1] if i + 1 < w.size() else "",
		"index": i, "count": w.size()}


## The halls of a sequence in walk order (empty when unknown).
static func halls_of(sequence: String) -> Array[String]:
	_load()
	var out: Array[String] = []
	for m in _halls.get(sequence, []):
		out.append(String(m))
	return out


## The vocabulary line written for a hall, or "".
static func line_of(stage: String) -> String:
	return _field_of(stage, "line")


## What the biome may say beyond what the hall wrote ("you arrive late"), or "".
static func beyond_of(stage: String) -> String:
	return _field_of(stage, "beyond")


static func _field_of(stage: String, field: String) -> String:
	_load()
	var pos: Dictionary = position_of(stage)
	if bool(pos["is_hall"]):
		return String(((_vocab.get("halls", {}) as Dictionary).get(String(pos["map"]), {}) as Dictionary).get(field, ""))
	if bool(pos["known"]):
		return String(((_vocab.get("sequences", {}) as Dictionary).get(String(pos["sequence"]), {}) as Dictionary).get(field, ""))
	return ""
