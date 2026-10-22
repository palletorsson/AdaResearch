## live_update.gd — the APPLICATION half of a live JSON update.
##
## 2026-10-22, the brief "Live JSON Streaming from the Web Editor to Desktop and
## Quest VR". The web editor saves the canonical `commons/maps/<Map>/map_data.json`
## (that file stays the source of truth), the encyclopedia diffs old against new
## into a revision envelope, tools/vr_link.py broadcasts it to every attached
## game, and this script applies it to the scene that is loaded — the same code
## on the desktop and on the Quest, because the transport (vr_link.gd) already is.
##
## Separation: vr_link.gd carries bytes; this file decides what an envelope
## means for the loaded scene and answers with ONE ack. Nothing here evaluates
## code: an operation is a cell value, and a cell value goes through the grid's
## own token parser and config coercion exactly as a map load would.
##
## ENVELOPE (cmd "update"):
##   revision_id   editor's id, unique            base_revision  sha256 of the file the
##   map_id        the map folder name                           editor started from ("" = unknown)
##   seq           per-map, monotonic (vr_link.py)  revision      sha256 of the file as saved
##   operations    [{op:"set_cell", layer, at:[x,z], before, after, kind}
##                  {op:"move", layer:"interactables", from:[x,z], to:[x,z], token}]
##   map_text      optional: the saved file verbatim, for a reload where the pck is stale
##
## ACK ({k:"update_ack"}): status applied | rejected | conflict | requires_reload,
## with `reason` (duplicate, obsolete, already_current, not_loaded, invalid, busy,
## object_missing, museum_plan), `mode` (in_place | reload), per-op results, and
## `device` = OS.get_name() so the PC ledger can tell Windows from Android.
##
## WHAT IS IN PLACE AND WHAT IS A RELOAD (the update boundary):
##   A  interactables cell edits on a loaded grid map — in place, the player untouched
##   B  structure / utilities edits, or a token family the single-cell path does not
##      build (mc:, gridagent:, cluster:, criticalinfo:) — GridSystem.reload_map_setter,
##      the lane push_map_to_quest.ps1 -Live already uses; on Android the carried
##      map_data is written to user://override_map/<Map>/ first, because the pck
##      cannot be changed and GridDataComponent reads that override first
##   C  an endless-museum hall — reported, not applied: a map-authored hall stamps
##      from em_plan.json (memory: museum-stamps-from-plan-not-map), so the lane is
##      tools/em_map_halls.py --apply + em_bake.py, then the museum's own follow
extends RefCounted

const RELOAD_FAMILIES := ["mc", "gridagent", "cluster", "criticalinfo", "dialectic"]
const BUSY_PATIENCE_MS := 10000

var _tree: SceneTree
## map_id -> {revision_id, revision, seq}: the last envelope this scene applied
var _last: Dictionary = {}
## revision_id -> true: never apply one twice, whatever its seq says
var _applied_ids: Dictionary = {}
## map_id -> sha256 of the file the grid loaded (recorded when the grid is hooked
## and on every map_loaded), so a replay of a revision the scene already holds is
## answered `already_current` instead of applied twice
var _loaded_rev: Dictionary = {}
## envelopes that arrived while the grid was still generating: [{env, since_ms}]
var pending: Array = []


func _init(tree: SceneTree) -> void:
	_tree = tree


## Record which file the grid for `map_id` is standing on.
func note_loaded(map_id: String) -> void:
	if map_id == "":
		return
	var p: String = _map_file(map_id)
	if FileAccess.file_exists(p):
		_loaded_rev[map_id] = FileAccess.get_sha256(p)


func _map_file(map_id: String) -> String:
	if OS.has_feature("android"):
		var o: String = "user://override_map/%s/map_data.json" % map_id
		if FileAccess.file_exists(o):
			return o
	return "res://commons/maps/%s/map_data.json" % map_id


## Apply one envelope. Returns the ack, or {"defer": true} when the grid is busy
## (the caller queues it in `pending` and asks again next frame).
func apply(env: Dictionary) -> Dictionary:
	var rid: String = String(env.get("revision_id", ""))
	var map_id: String = String(env.get("map_id", ""))
	var seq: int = int(env.get("seq", 0))
	var ops_v: Variant = env.get("operations", null)
	if rid == "" or map_id == "" or not (ops_v is Array):
		return _ack(env, "rejected", "invalid", "revision_id, map_id and operations are required")
	var ops: Array = ops_v
	if String(env.get("project_id", "")) != "void":
		for op_v in ops:
			var why: String = _validate_op(op_v)
			if why != "":
				return _ack(env, "rejected", "invalid", why)

	var gate: Dictionary = _gate(env)
	if not gate.is_empty():
		return gate
	if String(env.get("project_id", "")) == "void":
		return _apply_void(env)
	var last: Dictionary = _last.get(map_id, {})

	# where is this map standing?
	var gs: Node = _grid_for(map_id)
	if gs == null:
		if _museum_has(map_id):
			return _ack(env, "requires_reload", "museum_plan",
				"the hall is an endless-museum segment: it stamps from em_plan.json — run tools/em_map_halls.py --apply then tools/em_bake.py; the museum follows the plan", "museum")
		return _ack(env, "rejected", "not_loaded", "map %s is not loaded here (loaded: %s)" % [map_id, _loaded_names()])
	if bool(gs.get("generation_in_progress")):
		return {"defer": true}

	# revision lineage: what we hold against what the editor started from
	var expected: String = String(last.get("revision", "")) if not last.is_empty() else String(_loaded_rev.get(map_id, ""))
	var base: String = String(env.get("base_revision", ""))
	var target: String = String(env.get("revision", ""))
	if target != "" and expected != "" and target == expected:
		_remember(env)
		return _ack(env, "rejected", "already_current", "the scene already holds revision %s" % target.substr(0, 12))
	var conflict: bool = base != "" and expected != "" and base != expected
	if conflict and _stale_replay(env):
		return _ack(env, "rejected", "stale_replay", "a replay of %s, but this scene loaded a newer file (%s) the bridge has not seen; nothing applied" % [target.substr(0, 12), expected.substr(0, 12)], "grid")

	var results: Array = []
	var needs_reload: bool = conflict
	var reload_why: String = "base revision %s is not what this scene holds (%s)" % [base.substr(0, 12), expected.substr(0, 12)] if conflict else ""
	if not conflict:
		for op_v in ops:
			var op: Dictionary = op_v
			var r: Dictionary = _apply_op(gs, op)
			results.append(r)
			if bool(r.get("reload", false)):
				needs_reload = true
				if reload_why == "":
					reload_why = String(r.get("detail", ""))

	if needs_reload:
		var how: String = _reload(gs, map_id, env)
		if how != "":
			return _ack(env, "requires_reload", "reload_unavailable", how, "grid", "reload", results)
		_remember(env)
		# after a reload the scene holds whatever FILE the grid reads — on the desktop the
		# working tree (which may be newer than this envelope), on Android the override
		# just written — so the lineage continues from that file's hash, not from a guess
		note_loaded(map_id)
		if _loaded_rev.has(map_id):
			_last[map_id]["revision"] = String(_loaded_rev[map_id])
		if conflict:
			return _ack(env, "conflict", "resolved_by_reload", reload_why, "grid", "reload", results)
		return _ack(env, "applied", "", reload_why, "grid", "reload", results)

	var failed: int = 0
	for r_v in results:
		if not bool((r_v as Dictionary).get("ok", false)):
			failed += 1
	_remember(env)
	if failed > 0 and failed == results.size():
		return _ack(env, "rejected", "object_missing", "no operation could be applied", "grid", "in_place", results)
	return _ack(env, "applied", "" if failed == 0 else "partial", "%d of %d operation(s) applied in place" % [results.size() - failed, results.size()], "grid", "in_place", results)


## A REPLAY IS BEST EFFORT, A LIVE SAVE IS AUTHORITATIVE (2026-10-22, measured):
## the bridge's "latest" can be OLDER than the file a desktop game just loaded
## (a save made while the bridge was down leaves no envelope), and reloading from
## it would regress the scene to the stale record. On the desktop the file on
## disk is the editor's own truth, so a conflicting replay is refused. On Android
## the pck is older than every ledger revision by construction, so a conflicting
## replay still converges by the full reload.
func _stale_replay(env: Dictionary) -> bool:
	return bool(env.get("replay", false)) and not OS.has_feature("android")


## Duplicate and obsolete revisions are refused before any scene is touched.
func _gate(env: Dictionary) -> Dictionary:
	var rid: String = String(env.get("revision_id", ""))
	var map_id: String = String(env.get("map_id", ""))
	var seq: int = int(env.get("seq", 0))
	if _applied_ids.has(rid):
		return _ack(env, "rejected", "duplicate", "revision already applied here")
	var last: Dictionary = _last.get(map_id, {})
	if not last.is_empty() and seq > 0 and seq <= int(last.get("seq", 0)):
		return _ack(env, "rejected", "obsolete", "seq %d is not after the last applied %d (%s)" % [seq, int(last.get("seq", 0)), String(last.get("revision_id", ""))])
	return {}


func _remember(env: Dictionary) -> void:
	var rid: String = String(env.get("revision_id", ""))
	_applied_ids[rid] = true
	_last[String(env.get("map_id", ""))] = {"revision_id": rid,
		"revision": String(env.get("revision", "")), "seq": int(env.get("seq", 0))}


func _validate_op(op_v: Variant) -> String:
	if not (op_v is Dictionary):
		return "operation is not an object"
	var op: Dictionary = op_v
	var kind: String = String(op.get("op", ""))
	var layer: String = String(op.get("layer", ""))
	if not (layer in ["structure", "utilities", "interactables"]):
		return "unknown layer %s" % layer
	match kind:
		"set_cell":
			if not _is_cell(op.get("at", null)):
				return "set_cell needs at:[x,z]"
			if not (op.get("after", null) is String):
				return "set_cell needs after:<string>"
		"move":
			if layer != "interactables":
				return "move is an interactables operation"
			if not _is_cell(op.get("from", null)) or not _is_cell(op.get("to", null)):
				return "move needs from:[x,z] and to:[x,z]"
			if not (op.get("token", null) is String):
				return "move needs token:<string>"
		_:
			return "unknown op %s" % kind
	return ""


func _is_cell(v: Variant) -> bool:
	if not (v is Array) or (v as Array).size() < 2:
		return false
	var a: Array = v
	return (a[0] is float or a[0] is int) and (a[1] is float or a[1] is int)


## ————————————————————————————————————————————————————————————————————
## Finding the scene
## ————————————————————————————————————————————————————————————————————

func _grid_for(map_id: String) -> Node:
	for g in _tree.get_nodes_in_group("grid_system"):
		if not is_instance_valid(g) or not g.is_inside_tree():
			continue
		if String(g.get("map_name")) == map_id:
			return g
	return null


func _loaded_names() -> String:
	var names: Array = []
	for g in _tree.get_nodes_in_group("grid_system"):
		if is_instance_valid(g):
			names.append(String(g.get("map_name")))
	if _tree.current_scene != null and _tree.current_scene.get("_segments") != null:
		names.append("endless museum")
	var vc: Node = _void_content()
	if vc != null:
		names.append("the Void (%s)" % _void_key(String(vc.get("trial_id"))))
	return ", ".join(PackedStringArray(names)) if not names.is_empty() else "nothing"


## Is `map_id` one of the museum's LIVE halls? Read from the outside, like
## vr_link._hall does — `_segments` is [{node, map, ...}] and never edited here.
func _museum_has(map_id: String) -> bool:
	var cur: Node = _tree.current_scene
	if cur == null:
		return false
	var segs_v: Variant = cur.get("_segments")
	if not (segs_v is Array):
		return false
	for s_v in (segs_v as Array):
		if s_v is Dictionary and String((s_v as Dictionary).get("map", "")) == map_id:
			return true
	return false


## ————————————————————————————————————————————————————————————————————
## One operation on a loaded grid
## ————————————————————————————————————————————————————————————————————

func _apply_op(gs: Node, op: Dictionary) -> Dictionary:
	var kind: String = String(op.get("op", ""))
	var layer: String = String(op.get("layer", ""))
	var r: Dictionary = {"op": kind, "layer": layer, "ok": false}
	if layer != "interactables":
		r["reload"] = true
		r["detail"] = "%s edits rebuild the grid" % layer
		return r
	if kind == "move":
		var from: Vector2i = _cell(op.get("from"))
		var to: Vector2i = _cell(op.get("to"))
		var token: String = String(op.get("token", ""))
		r["from"] = [from.x, from.y]
		r["to"] = [to.x, to.y]
		r["object_id"] = _object_id(gs, from)
		if _family_needs_reload(token):
			r["reload"] = true
			r["detail"] = "token family %s is built by the full map load" % token.split(":")[0]
			return r
		var removed: int = _remove_at(gs, from)
		if removed == 0:
			r["detail"] = "nothing stood at %s" % str([from.x, from.y])
			return r
		r["ok"] = _place_at(gs, to, token)
		r["detail"] = "moved %d node(s) %s -> %s" % [removed, str([from.x, from.y]), str([to.x, to.y])] if r["ok"] else "removed at %s but could not place %s at %s" % [str([from.x, from.y]), token, str([to.x, to.y])]
		return r
	# set_cell
	var at: Vector2i = _cell(op.get("at"))
	var after: String = String(op.get("after", "")).strip_edges()
	r["at"] = [at.x, at.y]
	r["object_id"] = _object_id(gs, at)
	if after.begins_with("#"):
		after = ""   # a commented token is intent, not a placement
	if after != "" and _family_needs_reload(after):
		r["reload"] = true
		r["detail"] = "token family %s is built by the full map load" % after.split(":")[0]
		return r
	var removed: int = _remove_at(gs, at)
	if after == "":
		r["ok"] = true
		r["detail"] = "cleared %d node(s)" % removed
		return r
	r["ok"] = _place_at(gs, at, after)
	r["detail"] = ("replaced %d node(s) with " % removed if removed > 0 else "placed ") + after if r["ok"] else "could not place %s" % after
	return r


func _cell(v: Variant) -> Vector2i:
	var a: Array = v
	return Vector2i(int(a[0]), int(a[1]))


func _object_id(gs: Node, at: Vector2i) -> String:
	return "%s/interactables/%d,%d" % [String(gs.get("map_name")), at.x, at.y]


func _family_needs_reload(token: String) -> bool:
	var head: String = token.split(":")[0].split("#")[0].strip_edges()
	return head in RELOAD_FAMILIES


## Every artifact the grid placed at this cell, and its dress plinth. The grid
## tags each placement with meta grid_cell and the group vr_editable_artifact
## (GridInteractablesComponent._place_artifact); interactable_objects is not
## written by that path, so the group is the index.
func _remove_at(gs: Node, at: Vector2i) -> int:
	var n_removed: int = 0
	for n in _tree.get_nodes_in_group("vr_editable_artifact"):
		if not (n is Node3D) or not is_instance_valid(n) or not gs.is_ancestor_of(n):
			continue
		if not n.has_meta("grid_cell") or not ((n.get_meta("grid_cell") is Vector2i) and (n.get_meta("grid_cell") as Vector2i) == at):
			continue
		_free_placed(n)
		n_removed += 1
	return n_removed


## Free one placed artifact and the dress plinth the grid built under it.
func _free_placed(n: Node) -> void:
	if n.has_meta("dress_plinth_path"):
		var pp: Variant = n.get_meta("dress_plinth_path")
		if pp is NodePath and not (pp as NodePath).is_empty():
			var plinth: Node = n.get_node_or_null(pp)
			if plinth != null:
				plinth.queue_free()
	n.remove_from_group("vr_editable_artifact")
	if n.has_meta("grid_cell"):
		n.remove_meta("grid_cell")
	var parent: Node = n.get_parent()
	if parent != null:
		parent.remove_child(n)   # out of the tree NOW, so a scan this frame cannot see it
	n.queue_free()


## Every artifact the grid placed, for the reload lane: GridSystem._reload_current_map
## clears interactable_objects, which _place_artifact never fills, so the artifacts
## it placed would survive the reload and STACK under the fresh ones.
func _remove_all_placed(gs: Node) -> int:
	var n_removed: int = 0
	for n in _tree.get_nodes_in_group("vr_editable_artifact"):
		if n is Node3D and is_instance_valid(n) and gs.is_ancestor_of(n):
			_free_placed(n)
			n_removed += 1
	return n_removed


## The single-cell twin of GridInteractablesComponent.generate_interactables:
## the same parser, the same seat on the cube top, the same placer.
func _place_at(gs: Node, at: Vector2i, token: String) -> bool:
	var ic: Node = gs.get("interactables_component")
	var sc: Node = gs.get("structure_component")
	var uc: Node = gs.get("utilities_component")
	if ic == null or sc == null:
		return false
	var parsed: Dictionary = ic.call("_parse_interactable_token", token)
	var lookup: String = String(parsed.get("lookup_name", ""))
	if lookup == "":
		return false
	var y: int = int(sc.call("find_highest_y_at", at.x, at.y))
	if uc != null and bool(uc.call("has_utility_at", at.x, y, at.y)):
		y += 1
	var total: float = float(gs.get("cube_size")) + float(gs.get("gutter"))
	return bool(ic.call("_place_artifact", at.x, y, at.y, lookup, total,
		parsed.get("overrides", {}), parsed.get("config_data", {}),
		String(parsed.get("tag", "")), String(parsed.get("trigger_action", ""))))


## The full-map lane. Returns "" when the reload was asked for, else why not.
func _reload(gs: Node, map_id: String, env: Dictionary) -> String:
	if OS.has_feature("android"):
		# the pck is read-only and stale; the override is what the loader reads first.
		# map_text is the file EXACTLY as the editor saved it, so its sha256 is the
		# envelope's `revision` and the lineage stays whole; map_data is the fallback
		var dir: String = "user://override_map/%s" % map_id
		var text: String = String(env.get("map_text", ""))
		if text == "":
			var md: Variant = env.get("map_data", null)
			if not (md is Dictionary):
				return "the headset's map is in the pck and the envelope carried no map_text to reload from"
			text = JSON.stringify(md, "  ") + "\n"
		DirAccess.make_dir_recursive_absolute(dir)
		var f: FileAccess = FileAccess.open(dir + "/map_data.json", FileAccess.WRITE)
		if f == null:
			return "cannot write %s" % dir
		f.store_string(text)
		f.close()
	if not gs.has_method("reload_map_setter"):
		return "the grid has no reload_map_setter"
	var n_old: int = _remove_all_placed(gs)
	gs.call("reload_map_setter", true)
	print("[live-update] reload of %s asked for (%d placed artifact(s) freed first)" % [map_id, n_old])
	return ""


## ————————————————————————————————————————————————————————————————————
## The Void (commons/void) — rooms.json floors, free transforms
## ————————————————————————————————————————————————————————————————————
##
## /lab-editor?mode=void saves commons/void/rooms.json: 18 floors, each with
## `artifacts` and `props` records keyed by `id` and placed by position [x,z],
## height, facing, scale (plus config.parts). The game keeps that document in
## memory (floor_content.data) and builds a floor's mount nodes named by the
## record id (artifacts: `<id>`, props: `Prop_<id>`); reset_floor + load_floor
## is the game's own per-floor rebuild (the checkpoint lane in game.gd).
##
## In place: a transform-only change (position / height / facing on an artifact;
## position / facing / scale on a prop) moves the node and patches the record;
## an `add` builds the one new mount through the Void's own builders and a
## `remove` frees one (2026-10-22, the spawn menu).
## Everything else (config, parts, scale on an artifact, walls,
## route, painted construction) replaces the floor's record and rebuilds that
## one floor — the player, the architecture and the other floors stay. A floor
## that is not resident (streamed out) only has its record replaced; it builds
## from it when entered. Nothing is written to disk here: the editor already
## wrote the file; on the Quest the pck stays stale until the next export,
## which the ack's `mode` makes visible.

const VOID_TRIALS := "res://commons/void/trials/playable.json"


func _void_content() -> Node:
	for n in _tree.get_nodes_in_group("biome_grid"):
		if is_instance_valid(n) and n.is_inside_tree() and n.has_method("load_floor") and n.has_method("reset_floor"):
			return n
	return null


func _void_key(trial: String) -> String:
	return "void" if trial == "" else trial


func _void_rooms_path(map_id: String) -> String:
	if map_id == "" or map_id == "void":
		return "res://commons/void/rooms.json"
	if FileAccess.file_exists(VOID_TRIALS):
		var m: Variant = JSON.parse_string(FileAccess.get_file_as_string(VOID_TRIALS))
		if m is Dictionary:
			var rec: Variant = ((m as Dictionary).get("trials", {}) as Dictionary).get(map_id, null)
			if rec is Dictionary:
				return String((rec as Dictionary).get("rooms", "res://commons/void/rooms.json"))
	return ""


## Record which rooms file the Void loaded (called by vr_link when it first sees the Void).
func note_loaded_void(trial: String) -> void:
	var p: String = _void_rooms_path(trial)
	if p != "" and FileAccess.file_exists(p):
		_loaded_rev[_void_key(trial)] = FileAccess.get_sha256(p)


func _validate_void_op(op_v: Variant) -> String:
	if not (op_v is Dictionary):
		return "operation is not an object"
	var op: Dictionary = op_v
	match String(op.get("op", "")):
		"void_item":
			if not (String(op.get("collection", "")) in ["artifacts", "props"]):
				return "void_item needs collection artifacts|props"
			if String(op.get("id", "")) == "":
				return "void_item needs id"
			if not (String(op.get("kind", "")) in ["transform", "parameter", "replace", "add", "remove"]):
				return "void_item kind %s unknown" % String(op.get("kind", ""))
		"void_floor":
			pass
		_:
			return "unknown op %s" % String(op.get("op", ""))
	return ""


func _apply_void(env: Dictionary) -> Dictionary:
	var map_id: String = String(env.get("map_id", "void"))
	var floor_i: int = int(env.get("floor_id", -1))
	var ops: Array = env.get("operations", [])
	for op_v in ops:
		var why: String = _validate_void_op(op_v)
		if why != "":
			return _ack(env, "rejected", "invalid", why, "void")
	var content: Node = _void_content()
	if content == null:
		return _ack(env, "rejected", "not_loaded", "the Void is not loaded here (loaded: %s)" % _loaded_names(), "void")
	var want_trial: String = "" if map_id == "void" else map_id
	if String(content.get("trial_id")) != want_trial:
		return _ack(env, "rejected", "not_loaded", "the Void here is %s, not %s" % [_void_key(String(content.get("trial_id"))), map_id], "void")
	var data: Variant = content.get("data")
	if not (data is Dictionary) or not ((data as Dictionary).get("floors", null) is Array):
		return _ack(env, "rejected", "not_loaded", "the Void holds no floors yet", "void")
	var floors: Array = (data as Dictionary)["floors"]
	if floor_i < 0 or floor_i >= floors.size():
		return _ack(env, "rejected", "invalid", "floor %d is not one of the %d floors" % [floor_i, floors.size()], "void")

	var last: Dictionary = _last.get(map_id, {})
	var expected: String = String(last.get("revision", "")) if not last.is_empty() else String(_loaded_rev.get(map_id, ""))
	var base: String = String(env.get("base_revision", ""))
	var target: String = String(env.get("revision", ""))
	if target != "" and expected != "" and target == expected:
		_remember(env)
		return _ack(env, "rejected", "already_current", "the Void already holds revision %s" % target.substr(0, 12), "void")
	var conflict: bool = base != "" and expected != "" and base != expected
	if conflict and _stale_replay(env):
		return _ack(env, "rejected", "stale_replay", "a replay of %s, but this Void loaded a newer file (%s) the bridge has not seen; nothing applied" % [target.substr(0, 12), expected.substr(0, 12)], "void")
	var record: Variant = env.get("floor_record", null)

	var roots: Variant = content.get("roots")
	var resident: bool = roots is Dictionary and (roots as Dictionary).has(floor_i) \
		and is_instance_valid((roots as Dictionary)[floor_i])
	if not resident:
		if not (record is Dictionary):
			return _ack(env, "requires_reload", "reload_unavailable", "floor %d is not resident and the envelope carried no floor_record" % floor_i, "void")
		floors[floor_i] = record
		_remember(env)
		return _ack(env, "applied", "", "floor %d is not resident; its record is replaced and it builds from it when entered" % floor_i, "void", "data")

	var root: Node = (roots as Dictionary)[floor_i]
	var results: Array = []
	var needs_reload: bool = conflict
	var reload_why: String = "base revision %s is not what this Void holds (%s)" % [base.substr(0, 12), expected.substr(0, 12)] if conflict else ""
	if not conflict:
		for op_v in ops:
			var op: Dictionary = op_v
			var r: Dictionary = {"op": String(op.get("op", "")), "ok": false,
				"object_id": String(op.get("object_id", ""))}
			var op_kind: String = String(op.get("kind", ""))
			if String(op.get("op", "")) == "void_item" and op_kind == "transform":
				r = _void_move(root, floors[floor_i], op)
			elif String(op.get("op", "")) == "void_item" and op_kind == "add":
				r = _void_add(content, root, floor_i, floors[floor_i], op)
			elif String(op.get("op", "")) == "void_item" and op_kind == "remove":
				r = _void_remove(content, root, floor_i, floors[floor_i], op)
			else:
				r["reload"] = true
				r["detail"] = "%s rebuilds the floor" % (String(op.get("kind", "")) if op.has("kind") else "a floor change")
			results.append(r)
			if bool(r.get("reload", false)):
				needs_reload = true
				if reload_why == "":
					reload_why = String(r.get("detail", ""))
	if needs_reload:
		if not (record is Dictionary):
			return _ack(env, "requires_reload", "reload_unavailable", "the envelope carried no floor_record to rebuild floor %d from" % floor_i, "void", "reload", results)
		floors[floor_i] = record
		_void_floor_reload(content, floor_i)
		_remember(env)
		if conflict:
			return _ack(env, "conflict", "resolved_by_reload", reload_why, "void", "reload", results)
		return _ack(env, "applied", "", "floor %d rebuilt: %s" % [floor_i, reload_why], "void", "reload", results)
	var failed: int = 0
	for r_v in results:
		if not bool((r_v as Dictionary).get("ok", false)):
			failed += 1
	_remember(env)
	if failed > 0 and failed == results.size():
		return _ack(env, "rejected", "object_missing", "no operation could be applied", "void", "in_place", results)
	return _ack(env, "applied", "" if failed == 0 else "partial", "%d of %d operation(s) applied in place on floor %d" % [results.size() - failed, results.size(), floor_i], "void", "in_place", results)


## Move one mount and patch its record, so a later reset_floor rebuilds it where it is.
func _void_move(root: Node, floor_rec: Dictionary, op: Dictionary) -> Dictionary:
	var coll: String = String(op.get("collection", ""))
	var id: String = String(op.get("id", ""))
	var r: Dictionary = {"op": "void_item", "kind": "transform", "collection": coll, "id": id,
		"object_id": String(op.get("object_id", "")), "ok": false}
	var after: Variant = op.get("after", null)
	if not (after is Dictionary):
		r["detail"] = "transform needs the record after the change"
		return r
	var item: Dictionary = after
	var node: Node = root.get_node_or_null(NodePath(id if coll == "artifacts" else "Prop_" + id))
	if not (node is Node3D):
		r["detail"] = "no mount named %s on this floor" % id
		return r
	var at: Variant = item.get("position", null)
	if not (at is Array) or (at as Array).size() < 2:
		r["detail"] = "position must be [x, z]"
		return r
	var n3: Node3D = node
	var y: float = float(item.get("height", 0.0)) if coll == "artifacts" else 0.0
	n3.position = Vector3(float((at as Array)[0]), y, float((at as Array)[1]))
	n3.rotation_degrees.y = float(item.get("facing", 0.0))
	if coll == "props":
		n3.scale = Vector3.ONE * float(item.get("scale", 1.0))
	var items: Variant = floor_rec.get(coll, null)
	if items is Array:
		for i in (items as Array).size():
			var cur: Variant = (items as Array)[i]
			if cur is Dictionary and String((cur as Dictionary).get("id", "")) == id:
				(items as Array)[i] = item
				break
	r["ok"] = true
	r["detail"] = "%s moved to [%s, %s] facing %s" % [id, str((at as Array)[0]), str((at as Array)[1]), str(item.get("facing", 0))]
	return r


## Spawn one record in place (2026-10-22, the spawn menu): an artifact through the
## Void's own `_build_artifact` (the mount named by id, exhibits["%d/%s"] registered,
## supply cable, reactions — everything load_floor would do for it), a prop through
## SetDressing.build as _build_content does. The record is appended to the floor's
## in-memory list so a later reset_floor rebuilds it where it stands. Nothing is
## written to disk here: the editor's save already did.
func _void_add(content: Node, root: Node, floor_i: int, floor_rec: Dictionary, op: Dictionary) -> Dictionary:
	var coll: String = String(op.get("collection", ""))
	var id: String = String(op.get("id", ""))
	var r: Dictionary = {"op": "void_item", "kind": "add", "collection": coll, "id": id,
		"object_id": String(op.get("object_id", "")), "ok": false}
	var after: Variant = op.get("after", null)
	if not (after is Dictionary):
		r["detail"] = "add needs the record"
		return r
	var item: Dictionary = (after as Dictionary).duplicate(true)
	if root.get_node_or_null(NodePath(id if coll == "artifacts" else "Prop_" + id)) != null:
		r["detail"] = "a mount named %s already stands on floor %d" % [id, floor_i]
		return r
	if not (floor_rec.get(coll, null) is Array):
		floor_rec[coll] = []
	var catalog: Variant = content.get("catalog")
	if coll == "artifacts":
		if String(item.get("artifact", "")) == "":
			r["detail"] = "an artifact record needs `artifact`"
			return r
		if not item.has("station"):
			item["station"] = "NW"
		if not item.has("height"):
			item["height"] = 0.0
		if not item.has("facing"):
			item["facing"] = 0.0
		if not item.has("config"):
			item["config"] = {}
		if not content.has_method("_build_artifact"):
			r["detail"] = "this Void has no per-artifact builder"
			r["reload"] = true
			return r
		content.call("_build_artifact", root, floor_i, item)
		if root.get_node_or_null(NodePath(id)) == null:
			r["detail"] = "%s did not build (unregistered artifact %s?)" % [id, String(item.get("artifact", ""))]
			return r
	else:
		var kind: String = String(item.get("kind", ""))
		if not (catalog is Dictionary) or not ((catalog as Dictionary).get("props", {}) as Dictionary).has(kind):
			r["detail"] = "prop kind %s is not in the Void's catalog" % kind
			return r
		var dressing: Variant = load("res://commons/void/set_dressing.gd")
		var body: Node = dressing.build(content.get("building"), root, item, ((catalog as Dictionary)["props"] as Dictionary)[kind])
		var props_v: Variant = content.get("props")
		if props_v is Dictionary:
			(props_v as Dictionary)["%d/%s" % [floor_i, id]] = body
	(floor_rec[coll] as Array).append(after)
	if content.has_signal("floor_changed"):
		content.emit_signal("floor_changed", floor_i)
	r["ok"] = true
	r["detail"] = "%s spawned on floor %d at [%s, %s]" % [id, floor_i, str((item.get("position", [0, 0]) as Array)[0]), str((item.get("position", [0, 0]) as Array)[1])]
	return r


## Take one record out in place: free its mount, forget it in the content's
## registries (exhibits / props, as reset_floor does for a whole floor), drop it
## from the in-memory list.
func _void_remove(content: Node, root: Node, floor_i: int, floor_rec: Dictionary, op: Dictionary) -> Dictionary:
	var coll: String = String(op.get("collection", ""))
	var id: String = String(op.get("id", ""))
	var r: Dictionary = {"op": "void_item", "kind": "remove", "collection": coll, "id": id,
		"object_id": String(op.get("object_id", "")), "ok": false}
	var node: Node = root.get_node_or_null(NodePath(id if coll == "artifacts" else "Prop_" + id))
	if node == null:
		r["detail"] = "no mount named %s on floor %d" % [id, floor_i]
	else:
		node.queue_free()
	var key: String = "%d/%s" % [floor_i, id]
	var reg: Variant = content.get("exhibits" if coll == "artifacts" else "props")
	if reg is Dictionary:
		(reg as Dictionary).erase(key)
	var items: Variant = floor_rec.get(coll, null)
	if items is Array:
		for i in range((items as Array).size() - 1, -1, -1):
			var cur: Variant = (items as Array)[i]
			if cur is Dictionary and String((cur as Dictionary).get("id", "")) == id:
				(items as Array).remove_at(i)
	if node == null:
		return r
	if content.has_signal("floor_changed"):
		content.emit_signal("floor_changed", floor_i)
	r["ok"] = true
	r["detail"] = "%s removed from floor %d" % [id, floor_i]
	return r


## The game's own per-floor rebuild (game.gd's checkpoint lane): forget the
## stream's residency record, free the floor root, build it from the record.
func _void_floor_reload(content: Node, floor_i: int) -> void:
	var building: Node = content.get_parent()
	var game: Node = building.get_parent() if building != null else null
	if game != null and game.get("floor_stream") != null:
		var fs: Variant = game.get("floor_stream")
		if fs is Node:
			var recs: Variant = (fs as Node).get("records")
			if recs is Dictionary:
				(recs as Dictionary).erase(floor_i)
	content.call("reset_floor", floor_i)
	content.call("load_floor", floor_i, true)
	print("[live-update] Void floor %d rebuilt from its new record" % floor_i)


## ————————————————————————————————————————————————————————————————————
## The ack
## ————————————————————————————————————————————————————————————————————

func _ack(env: Dictionary, status: String, reason: String, detail: String,
		scene: String = "none", mode: String = "", results: Array = []) -> Dictionary:
	var a: Dictionary = {"k": "update_ack",
		"revision_id": String(env.get("revision_id", "")),
		"map_id": String(env.get("map_id", "")),
		"seq": int(env.get("seq", 0)),
		"status": status, "reason": reason, "detail": detail,
		"scene": scene, "mode": mode, "ops": results,
		"device": OS.get_name(), "t": Time.get_ticks_msec() / 1000.0}
	if bool(env.get("replay", false)):
		a["replay"] = true
	print("[live-update] %s %s %s%s — %s" % [a["revision_id"], a["map_id"], status,
		(" (" + reason + ")") if reason != "" else "", detail])
	return a
