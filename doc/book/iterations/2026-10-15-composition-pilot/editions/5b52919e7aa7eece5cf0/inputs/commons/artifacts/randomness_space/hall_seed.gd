extends Node
## Random Definition's shared starting number; each exhibit owns its own stream.
const PATH := "res://commons/artifacts/randomness_space/hall_seed.gd"
const START := 435
const RECEIPT := "res://algorithms/randomness/seed_replay/opening_seed.json"
var value := START
var receipt: Dictionary = {}
var participants: Array[WeakRef] = []
var applying := false

static func enabled(node: Node) -> bool:
	var cursor := node
	while cursor != null:
		if cursor.has_meta("config_hall_seed"): return str(cursor.get_meta("config_hall_seed")) == "435"
		if str(cursor.get_meta("em_map", "")) == "Random_Definition": return true
		cursor = cursor.get_parent()
	return false

static func scope(node: Node) -> Node:
	var cursor := node.get_parent()
	var outer := cursor
	while cursor != null and not cursor is Window:
		if cursor.has_meta("em_map") or cursor.has_meta("hall_seed_scope"): return cursor
		outer = cursor
		cursor = cursor.get_parent()
	return outer

static func state(node: Node) -> Node:
	if not enabled(node) or not node.is_inside_tree(): return null
	var room := scope(node)
	if room == null: return null
	var reference: Variant = room.get_meta("_hall_seed_state") if room.has_meta("_hall_seed_state") else null
	if reference is WeakRef and is_instance_valid(reference.get_ref()): return reference.get_ref()
	var created: Node = load(PATH).new()
	created.name = "RandomDefinitionSeed"
	created.receipt = JSON.parse_string(FileAccess.get_file_as_string(RECEIPT))
	room.set_meta("_hall_seed_state",weakref(created))
	room.add_child.call_deferred(created) # Child _ready may run while the room is adding children.
	return created

static func bind(node: Node) -> void:
	var hub := state(node)
	if hub == null: return
	for reference in hub.participants:
		if reference.get_ref() == node: return
	hub.participants.append(weakref(node))
	hub.applying = true
	node.call("_apply_hall_seed", hub.value, hub.receipt.duplicate(true))
	hub.applying = false

static func current(node: Node) -> int:
	var hub := state(node)
	return int(hub.value) if hub != null else START

static func choose(node: Node, number: int, source: Dictionary = {}, keep_local: bool = false) -> bool:
	var hub := state(node)
	if hub == null: return false
	if hub.applying: return true
	return hub.select(number, source, node if keep_local else null)

static func next(node: Node) -> bool:
	return choose(node, (current(node) + 1) % 1000)

static func reset(node: Node) -> bool:
	return choose(node, START, JSON.parse_string(FileAccess.get_file_as_string(RECEIPT)))

static func allowed(number: int, source: Dictionary) -> bool:
	if number < 0 or number > 999: return false
	var provider := str(source.get("provider", "fixed"))
	if provider in ["", "fixed", "movement", "saved_record"]: return true
	if provider == "RANDOM.ORG":
		var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RECEIPT))
		return number == START and source == original
	return false

func select(number: int, source: Dictionary, skip: Node = null) -> bool:
	if not allowed(number, source): return false
	participants = participants.filter(func(reference: WeakRef): return is_instance_valid(reference.get_ref()))
	for reference in participants:
		var artifact: Node = reference.get_ref()
		if artifact.has_method("can_apply_hall_seed") and not artifact.call("can_apply_hall_seed"):
			return false # Never move a held body/hand or silently interrupt a recording.
	value = number
	receipt = source.duplicate(true)
	if receipt.is_empty(): receipt = {"provider":"fixed", "label":"Chosen number", "seed":number, "recorded":true}
	applying = true
	for reference in participants:
		var artifact: Node = reference.get_ref()
		if artifact != skip: artifact.call("_apply_hall_seed", value, receipt.duplicate(true))
	applying = false
	return true
