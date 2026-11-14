extends Node
## THE VOID'S STICKERS: hosts the stickers stuck on Void works and Void floors in the running tower, so they stream with
## their floor. Made by one gated line in game.gd (only when res://commons/data/stickers/placements.json exists), as a
## child of the game; it finds everything else from there.
##
## Hosts are keyed by NAME, never by floor index (a floor was inserted at 18 on 11-09; indices shift): a work is
## {kind: void_work, floor: <the floor's map name>, work: <its rooms.json id>}, a floor {kind: void_floor, floor: <map>}.
## A work's frame is the frame of its exported GLB (tools/probes/export_void_editor.gd snapshot()):
##     host_to_world = Artifact.global_transform * Transform3D(Basis(UP, -museum_yaw))
## museum_yaw being the rooms.json row's config value (0 when absent). Its StickerLayer is a child of the work's MOUNT
## (Building/FloorContent/Content<f>/<work id>) with transform Artifact.transform * R_y(-museum_yaw), never of
## current_scene and never of the Artifact (a procedural work frees its own children): the floor's residency then hides,
## pauses and wakes the stickers with the work. A floor's frame is its Floor<i> node; its layer lives under Content<i>
## (the same frame), so a sticker on a wall or a prop hides with the floor's content, never floating over a hidden wall.
##
## (Re)hosting: a floor or work being (re)built - floor_content's artifact_built and floor_changed, which reset_floor,
## a trial reset and a live-update reload all come back through - and any change of the placements. A layer added to a
## floor that is not live is adopted by that floor's residency record (records[f].adopt), never announced with
## floor_changed (which re-walks the whole floor). A host that is gone (a work removed) keeps its stickers in the truth;
## they are drawn again when it comes back.

const StickerData := preload("res://commons/stickers/sticker_data.gd")
const StickerLayer := preload("res://commons/stickers/sticker_layer.gd")
const LAYER := "StickerLayer"
const FLOOR_LAYER := "StickerLayer_Floor"
## stickers.ts cleanHost: a map name, a rooms.json id, a body path inside a work
static var MAP_NAME := RegEx.create_from_string("^[A-Za-z][A-Za-z0-9_-]{0,79}$")
static var WORK_ID := RegEx.create_from_string("^[A-Za-z0-9][A-Za-z0-9_.-]{0,79}$")
static var BODY_PART := RegEx.create_from_string("^[A-Za-z0-9_@-][A-Za-z0-9_@. -]*$")

var game: Node = null
var building: Node3D = null
var content: Node3D = null
var data: Node = null
var _floor_of_map: Dictionary = {}

func _init() -> void:
	name = "StickerWorld"

func _ready() -> void:
	add_to_group("sticker_world")
	var parent := get_parent()
	game = parent if parent != null and parent.get("building") != null else get_tree().get_first_node_in_group("void_game")
	if game == null or game.get("building") == null or game.building.get("content") == null:
		push_warning("StickerWorld: no Void game to host stickers in")
		return
	building = game.building
	content = building.content
	data = StickerData.get_or_create(get_tree())
	content.artifact_built.connect(_on_built)
	content.floor_changed.connect(_on_floor_changed)
	data.placements_changed.connect(rehost_all)
	rehost_all.call_deferred()

func _on_built(index: int, _added: Array) -> void:
	host_floor(index)

func _on_floor_changed(index: int) -> void:
	host_floor(index)

## Every Void host that has stickers gets its layer, on every floor that is built now.
func rehost_all() -> void:
	if content == null or data == null:
		return
	for key in data.host_keys():
		var h: Dictionary = data.host_of(key)
		var kind := str(h.get("kind", ""))
		if kind != "void_work" and kind != "void_floor":
			continue
		var index := floor_index(str(h.get("floor", "")))
		if index >= 0:
			_host(index, h)

## The hosts of one floor (by its map name), after it or one of its works was (re)built.
func host_floor(index: int) -> void:
	if content == null or data == null:
		return
	var map := map_of(index)
	if map == "":
		return
	for key in data.host_keys():
		var h: Dictionary = data.host_of(key)
		if str(h.get("floor", "")) == map and str(h.get("kind", "")) in ["void_work", "void_floor"]:
			_host(index, h)

func _host(index: int, h: Dictionary) -> Node3D:
	var root: Variant = content.roots.get(index)
	if not is_instance_valid(root) or not (root as Node).is_inside_tree() or (root as Node).is_queued_for_deletion():
		return null   # not built: hosted when it is
	var parent: Node3D = null
	var frame := Transform3D.IDENTITY
	var layer_name := LAYER
	if str(h.kind) == "void_work":
		var mount := mount_of(content, index, str(h.work))
		if mount == null:
			return null
		var artifact := mount.get_node_or_null("Artifact") as Node3D
		if artifact == null:
			return null   # a collected pickup frees its own node
		parent = mount
		frame = artifact.transform * Transform3D(Basis(Vector3.UP, deg_to_rad(-museum_yaw(content, index, str(h.work)))), Vector3.ZERO)
	else:
		parent = root
		layer_name = FLOOR_LAYER
		var floor_node := _floor_node(index)
		if floor_node != null:
			frame = (root as Node3D).global_transform.affine_inverse() * floor_node.global_transform
	var layer := parent.get_node_or_null(layer_name) as Node3D
	if layer == null:
		layer = StickerLayer.new()
		layer.name = layer_name
		layer.host = h.duplicate(true)
		parent.add_child(layer)
		layer.transform = frame
		_adopt(index, layer)
	else:
		layer.transform = frame
		if layer.has_method("redraw"):
			layer.redraw()
	return layer

## A layer added to a floor that is not live is paused and filtered like the rest of it, without re-walking the floor.
func _adopt(index: int, layer: Node3D) -> void:
	var stream: Variant = game.get("floor_stream") if game != null else null
	if stream == null:
		return
	var records: Dictionary = stream.records
	if records.has(index) and str(records[index].mode) != "live":
		records[index].adopt(layer)

func map_of(index: int) -> String:
	var floors: Array = content.data.get("floors", []) if content != null and content.data is Dictionary else []
	return str(floors[index].get("map", "")) if index >= 0 and index < floors.size() else ""

## The floor that carries `map` now (keyed by name: indices shift when a floor is inserted).
func floor_index(map: String) -> int:
	if map == "":
		return -1
	if _floor_of_map.has(map) and map_of(int(_floor_of_map[map])) == map:
		return int(_floor_of_map[map])
	_floor_of_map.clear()
	var floors: Array = content.data.get("floors", [])
	for i in floors.size():
		var m := str(floors[i].get("map", ""))
		if not _floor_of_map.has(m):
			_floor_of_map[m] = i
	return int(_floor_of_map.get(map, -1))

func _floor_node(index: int) -> Node3D:
	var floors: Variant = building.get("floors")
	if floors is Array and index >= 0 and index < (floors as Array).size() and is_instance_valid(floors[index]):
		return floors[index]
	return null

## A work's mount on a floor: the node floor_content built for the rooms.json row `work`.
static func mount_of(floor_content: Node, index: int, work: String) -> Node3D:
	var exhibits: Variant = floor_content.get("exhibits")
	if exhibits is Dictionary:
		var m: Variant = (exhibits as Dictionary).get("%d/%s" % [index, work])
		if is_instance_valid(m) and m is Node3D and (m as Node).is_inside_tree():
			return m
	var roots: Variant = floor_content.get("roots")
	if roots is Dictionary and is_instance_valid((roots as Dictionary).get(index)):
		return (roots[index] as Node).get_node_or_null(NodePath(work.validate_node_name())) as Node3D
	return null

## The rooms.json row's config museum_yaw (degrees), 0 when absent: the turn the GLB export takes out of the Artifact.
static func museum_yaw(floor_content: Node, index: int, work: String) -> float:
	var d: Variant = floor_content.get("data")
	if not d is Dictionary:
		return 0.0
	var floors: Array = (d as Dictionary).get("floors", [])
	if index < 0 or index >= floors.size():
		return 0.0
	for list_key in ["artifacts", "copies"]:
		for item in floors[index].get(list_key, []):
			if item is Dictionary and str(item.get("id", "")) == work:
				var cfg: Variant = item.get("config", {})
				return float(cfg.get("museum_yaw", 0.0)) if cfg is Dictionary else 0.0
	return 0.0

## WHAT A RAY HIT CAN CARRY A STICKER, and in which frame (the pad asks this): {ok, host, frame (host to world),
## node, void} or {ok: false, reason}. In order: a node that says what it is (meta sticker_host: the board's face, the
## bench's primitives); a Void work (the ancestor whose parent is a floor's content root, with its Artifact); anything
## else on a floor's content root (a wall, a prop) and a floor's own slab: that floor. Anything else is refused.
static func host_at(collider: Object) -> Dictionary:
	if not collider is Node:
		return {"ok": false, "reason": "NOT A STICKER SURFACE"}
	var n: Node = collider
	while n != null:
		if n is Node3D and n.has_meta("sticker_host"):
			var h: Variant = n.get_meta("sticker_host")
			if h is Dictionary and str(h.get("kind", "")) in ["board", "primitive"]:
				return {"ok": true, "host": (h as Dictionary).duplicate(true), "frame": (n as Node3D).global_transform, "node": n, "void": false}
		n = n.get_parent()
	n = collider
	while n != null and n.get_parent() != null:
		var p := n.get_parent()
		if p is Node3D and p.has_meta("void_content_floor"):
			return _void_host(n, p as Node3D, collider)
		n = p
	n = collider
	while n != null:
		if n is Node3D and n.has_meta("void_floor_index") and n.has_meta("basin"):
			var map := str(n.get_meta("map", ""))
			if MAP_NAME.search(map) == null:
				return {"ok": false, "reason": "THIS FLOOR'S NAME CANNOT CARRY A STICKER"}
			return {"ok": true, "host": {"kind": "void_floor", "floor": map}, "frame": (n as Node3D).global_transform, "node": n, "void": true}
		n = n.get_parent()
	return {"ok": false, "reason": "NOT A STICKER SURFACE"}

static func _void_host(unit: Node, root: Node3D, collider: Object) -> Dictionary:
	var index := int(root.get_meta("void_content_floor"))
	var map := str(root.get_meta("map", ""))
	if MAP_NAME.search(map) == null:
		return {"ok": false, "reason": "THIS FLOOR'S NAME CANNOT CARRY A STICKER"}
	var floor_content := root.get_parent()
	var artifact := unit.get_node_or_null("Artifact") as Node3D
	if unit is Node3D and artifact != null:
		var work := _work_id(floor_content, index, unit)
		if WORK_ID.search(work) == null or work.contains(".."):
			return {"ok": false, "reason": "THIS WORK'S ID CANNOT CARRY A STICKER"}
		var host := {"kind": "void_work", "floor": map, "work": work}
		var body := str(unit.get_path_to(collider as Node))
		if body != "" and body != "." and body.length() <= 200 and not body.contains("@"):
			var clean := true
			for part in body.split("/"):
				if part == "." or part == ".." or BODY_PART.search(part) == null:
					clean = false
			if clean:
				host["body"] = body
		var yaw := museum_yaw(floor_content, index, work)
		return {"ok": true, "host": host, "frame": artifact.global_transform * Transform3D(Basis(Vector3.UP, deg_to_rad(-yaw)), Vector3.ZERO), "node": unit, "void": true}
	# a wall, a prop, a lead on the content root: the floor's own, in its Floor<i> frame
	var frame := root.global_transform
	var building: Node = floor_content.get_parent() if floor_content != null else null
	var floors: Variant = building.get("floors") if building != null else null
	if floors is Array and index >= 0 and index < (floors as Array).size() and is_instance_valid(floors[index]):
		frame = (floors[index] as Node3D).global_transform
	return {"ok": true, "host": {"kind": "void_floor", "floor": map}, "frame": frame, "node": root, "void": true}

## The rooms.json id of a work's mount. The pad asks every physics frame while it aims at a work, and floor_content's
## exhibits holds every work of every floor built so far (2001 of them: 287 us a call when this always scanned them, 11
## us with one), so: the key "<floor>/<mount name>" first (a mount is named by its id); then a cache by the mount's
## instance id, checked against exhibits; a scan only when both miss (an id with a character a node name cannot hold,
## such as '.'), and its answer cached. `lookups` counts each road, for probes.
static var _work_ids: Dictionary = {}       # mount instance id -> work id
static var lookups := {"named": 0, "cached": 0, "scanned": 0}

static func _work_id(floor_content: Node, index: int, mount: Node) -> String:
	var exhibits: Variant = floor_content.get("exhibits") if floor_content != null else null
	if exhibits is Dictionary:
		var ex: Dictionary = exhibits
		var hit: Variant = ex.get("%d/%s" % [index, mount.name])
		if is_instance_valid(hit) and hit == mount:
			lookups.named += 1
			return str(mount.name)
		var cached: Variant = _work_ids.get(mount.get_instance_id())
		if cached != null:
			hit = ex.get("%d/%s" % [index, cached])
			if is_instance_valid(hit) and hit == mount:
				lookups.cached += 1
				return str(cached)
		lookups.scanned += 1
		var prefix := "%d/" % index
		for key in ex:
			if str(key).begins_with(prefix) and is_instance_valid(ex[key]) and ex[key] == mount:
				if _work_ids.size() > 4096:
					_work_ids.clear()
				_work_ids[mount.get_instance_id()] = str(key).substr(prefix.length())
				return str(key).substr(prefix.length())
	return str(mount.name)
