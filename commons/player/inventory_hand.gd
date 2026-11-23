class_name InventoryHand
extends Node
## The bracelet's PLACE mode: which inventory item the hand produces (or none), each item's knob values, and the
## making of it. Trigger spawns the current item into the hand as a pickable (an InventoryCarrier round the
## artifact, or the artifact itself when it is a pickable); let go and it settles (see the carrier). Grip takes
## the last one back. An item that mounts "worn" (the tape) is not made: it is WORN, a bangle on the bracelet's
## controller (sync_worn), and the trigger and grip go to it: tape is laid from the hand without holding a roll. The web page's hand (hand.json: {item, config}) is watched once a
## second, so a choice made in the browser lands here; the panel's ITEMS tab is the same choice made in VR.

const Items = preload("res://commons/player/inventory_items.gd")   # by path: a new class_name is not in the cache until the editor scans
const KitStructure = preload("res://commons/artifacts/playground_kit/kit_structure.gd")
const Carrier = preload("res://commons/player/inventory_carrier.gd")
const InstancerLib = preload("res://commons/player/inventory_instancer.gd")

signal item_changed(id: String)
signal config_changed(id: String, cfg: Dictionary)
signal collected(id: String)

var current := ""                 # item id, "" = none
var values: Dictionary = {}       # id -> {knob key: value}, over the item's defaults
var placed: Array[Node3D] = []
var held: Node3D = null
var _worn: Dictionary = {}        # item id -> the node worn on the controller (mount "worn": the tape), made once
var _mini: Node3D = null          # the current item as a MINIATURE over the hand (Palle: "the current object must be a small version of the original")
var _mini_id := ""
const MINI := 0.10                # the miniature's longest side - the clock came out at 3 cm with its own scale folded in
var lab: Node = null              # answers is_sequence_completed; null = all unlocked
var notice := ""                  # one line for the HAND face: why the last trigger did nothing ("the clock needs a wall")
var budget_override: Dictionary = {}   # a probe's budget instead of items.json's
var stage_override: Dictionary = {}    # a probe's bench stage instead of workbench.json's
var _instancer: Node3D = null

## The tool the current item is, "" for a thing to place ("rubber": the trigger erases instead; "pin": it freezes or releases).
func current_tool() -> String:
	return str(Items.item(current).get("tool", "")) if current != "" else ""

# ── THE BUDGET (Palle: "an object budget in VR") ──────────────────────────────────────────────────────────────

func budget() -> Dictionary:
	return budget_override if not budget_override.is_empty() else Items.budget()

## What the placed things cost now: each placed item's measured cost (a copy instanced after the first pays no
## draws), each tape strip one draw and a picture when printed.
func spent() -> Dictionary:
	var sum := {"draws": 0, "triangles": 0, "lights": 0, "viewports": 0}
	var seen_keys: Dictionary = {}
	var kit_paid := false
	for n in placed:
		if not is_instance_valid(n):continue
		var id := str(n.get_meta("inv_item", ""));var c := Items.cost_of(id)
		if _is_kit(n):   # the playground kit is drawn by its own multimeshes (kit_structure.gd): six draws once for all
			if not kit_paid:sum.draws += KitStructure.KIT_DRAWS;kit_paid = true
			var st: Node = KitStructure.current(null)
			var built: bool = st != null and st.is_built(n)
			sum.triangles += KitStructure.BUILT_TRIANGLES["ball" if n.has_method("grid_point") else "rod"] if built else int(c.triangles)
			continue
		var key := str(n.get_meta("inv_key", ""))
		var instanced: bool = key != "" and seen_keys.has(key)
		seen_keys[key] = true
		sum.draws += 0 if instanced else c.draws;sum.triangles += c.triangles;sum.lights += c.lights;sum.viewports += c.viewports
	var roll: Node = worn_of("tape")
	if roll != null:
		for s in roll.segments:
			# A strip is a draw. A PRINTED strip is not a viewport: its words are drawn once (UPDATE_ONCE) into a picture
			# that is its skin from then on - no render a frame. Counted as one, sixteen printed strips filled the
			# budget's 16 viewports and every placement after them was refused, its ghost red (2026-11-10). The
			# pictures' memory is bounded by the roll's own max_strips and print_max_px.
			if is_instance_valid(s):sum.draws += 1;sum.triangles += 16 * maxi(1, (s.anchors as Array).size())
	return sum

## Would one more of `id` fit the budget? Sets the notice when not.
func fits(id: String) -> bool:
	var b := budget()
	if b.is_empty():return true
	var now := spent();var c := Items.cost_of(id)
	var key := instance_key(id);var instanced: bool = _instancer != null and is_instance_valid(_instancer) and _instancer.count(key) > 0
	if _kit_item(id):   # the kit's multimeshes: their six draws are paid once, by the first kit piece
		instanced = placed.any(func(n):return is_instance_valid(n) and _is_kit(n))
		c = c.duplicate();c.draws = KitStructure.KIT_DRAWS
	var want := {"draws": now.draws + (0 if instanced else c.draws), "triangles": now.triangles + c.triangles, "lights": now.lights + c.lights, "viewports": now.viewports + c.viewports}
	for k in ["draws", "lights", "viewports", "triangles"]:
		if b.has(k) and int(want[k]) > int(b[k]):
			notice = "BUDGET FULL: %s %d/%d - take something back" % [k, now[k], int(b[k])];return false
	return true

## A playground kit piece (a ball, rod or brace): drawn by the kit's own multimeshes, not the instancer.
static func _is_kit(n: Node) -> bool:
	return n.is_in_group("playground_balls") or n.is_in_group("playground_rods")

static func _kit_item(id: String) -> bool:
	return str(Items.item(id).get("token", "")) in ["playground_ball", "playground_rod"]

func instance_key(id: String) -> String:
	return id + "|" + JSON.stringify(config_for(id))

func instancer() -> Node3D:
	if _instancer == null or not is_instance_valid(_instancer):
		_instancer = InstancerLib.new();_instancer.name = "InventoryInstancer";get_tree().current_scene.add_child(_instancer)
	return _instancer

## What the controller points at, if the hand placed it (or a tape strip): the node, or null.
func pointed_own(controller: Node3D, reach := 8.0, exclude: Array = []) -> Node:
	var origin: Vector3 = controller.global_position;var dir: Vector3 = -controller.global_basis.z
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * reach, SURFACES);q.exclude = exclude
	var hit := get_viewport().world_3d.direct_space_state.intersect_ray(q)
	if hit.is_empty():return null
	var n: Node = hit.collider
	while n != null and n is Node3D:   # up to the scene's root, never into the Window (a typed Array[Node3D] refuses it)
		if placed.has(n):return n
		if n.get("paid_length") != null and n.get("issuer") != null:return n
		n = n.get_parent()
	return null

## THE RUBBER: the thing the controller points at, if the hand placed it, is taken back; a tape strip too.
func erase_at(controller: Node3D, reach := 8.0, exclude: Array = []) -> bool:
	var origin: Vector3 = controller.global_position;var dir: Vector3 = -controller.global_basis.z
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * reach, SURFACES);q.exclude = exclude
	var hit := get_viewport().world_3d.direct_space_state.intersect_ray(q)
	if hit.is_empty():notice = "point the rubber at a thing";return false
	var n: Node = hit.collider
	while n != null and n is Node3D:
		if placed.has(n):
			placed.erase(n)
			if n.has_method("is_picked_up") and n.is_picked_up() and n.has_method("drop"):n.drop()
			n.get_parent().remove_child(n);n.queue_free();notice = "";return true
		if n.get("paid_length") != null and n.get("issuer") != null:   # a tape strip
			var roll: Node = (n.get("issuer") as WeakRef).get_ref() if n.get("issuer") is WeakRef else null
			if roll != null and roll.has_method("remove_strip"):roll.remove_strip(n)
			else:n.queue_free()
			notice = "";return true
		n = n.get_parent()
	notice = "not yours: the rubber takes back only what the hand placed";return false

func _void() -> Node:
	return get_tree().get_first_node_in_group("void_game") if is_inside_tree() else null
var _hand_stamp := -1
var _born: int = int(Time.get_unix_time_from_system()) - 1   # a hand.json older than this game is not applied unasked
var _hand_path := ""
var _since := 0.0

func _process(delta: float) -> void:
	if not placed.is_empty():_follow_floors()
	if keep_path != "":
		_keep_since += delta
		if _keep_since >= KEEP_EVERY:
			_keep_since = 0.0;_wake_kept();save_kept()
	_since += delta
	if _since < 1.0:return
	_since = 0.0
	var path := Items.hand_path();var stamp := FileAccess.get_modified_time(path)
	# first sight of a file written BEFORE this game started: its stamp is noted, its content is old news
	# (the choice made in VR stands); one written since - the page's SEND TO VR, the headset's copy - lands,
	# as does any change from here on
	if _hand_path == "" and stamp != 0 and stamp < _born:_hand_path = path;_hand_stamp = stamp;return
	if path != _hand_path or (stamp != 0 and stamp != _hand_stamp):_read_hand()

## The web page's hand: {item, config: {id: {...}}}; an unknown or locked item is left alone.
func _read_hand() -> void:
	_hand_path = Items.hand_path();_hand_stamp = FileAccess.get_modified_time(_hand_path)
	if not FileAccess.file_exists(_hand_path):return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(_hand_path))
	if not data is Dictionary:return
	var cfgs: Variant = data.get("config", {})
	if cfgs is Dictionary:
		for id in cfgs:
			if cfgs[id] is Dictionary:
				values[str(id)] = (cfgs[id] as Dictionary).duplicate()
				config_changed.emit(str(id), config_for(str(id)))
				if is_instance_valid(held) and held.has_method("apply_config") and str(held.get("item").get("id", "")) == str(id):held.apply_config(config_for(str(id)))
				_apply_worn(str(id))
	var want := str(data.get("item", current))
	if want != current and (want == "" or (not Items.item(want).is_empty() and Items.unlocked(Items.item(want), lab, _void()))):
		current = want;item_changed.emit(current)

## The items as the panel lists them.
func available() -> Array:
	var out := []
	for it in Items.items():
		var id := str(it.get("id", ""))
		out.append({"id": id, "name": str(it.get("name", id)), "unlocked": Items.unlocked(it, lab, _void()), "coming": str(it.get("coming", "")), "knobs": it.get("knobs", []), "values": config_for(id), "mount": str(it.get("mount", "any")), "floor": int(it.get("floor", 0))})
	return out

func set_current(id: String) -> void:
	if id != "" and (Items.item(id).is_empty() or not Items.unlocked(Items.item(id), lab, _void())):return
	if id == current:return
	current = id;notice = "";item_changed.emit(current)

# ── THE BELT (Palle, 2026-11-04: "one thumbstick down, we can choose between the different prefabs") ─────────────

## What the thumbstick click steps through: the empty hand, then every item collected, in the order taken.
func belt() -> Array:
	var out: Array = [""]
	for id in Items.collected():
		if not Items.item(str(id)).is_empty():out.append(str(id))
	return out

## One step along the belt (d = 1 on, -1 back); an item chosen on the prism that is not on the belt starts the walk
## from the empty hand. Returns the item now in the hand, "" for the empty hand (place mode off: the hand is free).
func cycle(d := 1) -> String:
	var b := belt()
	var i: int = b.find(current)
	current = str(b[posmod((i if i >= 0 else 0) + d, b.size())]);notice = ""
	item_changed.emit(current)
	return current

## PICKED UP = COLLECTED: the example's item goes on the belt and into the hand at once, its miniature over the
## hand (sync_worn). Returns true when it was new to the belt.
func collect(id: String) -> bool:
	if Items.item(id).is_empty():return false
	var fresh := Items.collect(id)
	if current != id:current = id;item_changed.emit(current)
	notice = "";collected.emit(id)
	return fresh

## The display name of an item, or "empty hand".
func name_of(id: String) -> String:
	return "empty hand" if id == "" else str(Items.item(id).get("name", id)).get_slice(" - ", 0)

# ── MOVE (Palle: "we can place, remove and move the objects"): a placed thing is LIFTED - its collisions off, frozen -
# and follows the aim as its own ghost until it is set down by the same placement rule that made it ─────────────

var lifted: Node3D = null

## THE TURN (Palle, 2026-11-04: "see and turn"): degrees about the world's up added to every placement - a new thing's
## and a dragged one's. The VR prism sets it from the right wrist's twist, the desktop from Q / E. A grid thing takes it
## in quarter turns (the sand-block rule refuses a rest more than 8 degrees off square); a wall thing ignores it.
var yaw_offset := 0.0

func _turned(basis: Basis, square: bool) -> Basis:
	var t: float = snappedf(yaw_offset, 90.0) if square else yaw_offset
	return Basis(Vector3.UP, deg_to_rad(t)) * basis if absf(t) > .01 else basis

## The placed thing the controller points at is lifted; false (with a notice) if it is not the hand's.
func lift_pointed(controller: Node3D, reach := 8.0, exclude: Array = []) -> bool:
	var n: Node = pointed_own(controller, reach, exclude)
	if n == null or n.get("paid_length") != null:return false   # tape keeps its own grip and undo
	if not n is Node3D:return false
	lifted = n
	if n is RigidBody3D:
		n.set_meta("inv_was_frozen", bool((n as RigidBody3D).freeze))
		pin_node(n)
	var layers: Dictionary = {}
	for c in _bodies_of(n):
		if c is CollisionObject3D:layers[c.get_instance_id()] = [(c as CollisionObject3D).collision_layer, (c as CollisionObject3D).collision_mask];(c as CollisionObject3D).collision_layer = 0;(c as CollisionObject3D).collision_mask = 0
	n.set_meta("inv_lift_layers", layers)
	notice = ""
	return true

## Where the lifted thing would land now, by its own item's rule.
func lifted_placement(controller: Node3D, reach := 8.0, exclude: Array = []) -> Dictionary:
	if not is_instance_valid(lifted):lifted = null;return {"ok": false, "reason": "nothing lifted"}
	return placement_at(controller, reach, exclude, str(lifted.get_meta("inv_item", "")))

## The lifted thing set down where the controller points (its collisions back, settled or hung as when it was made).
func set_down(controller: Node3D, reach := 8.0, exclude: Array = []) -> bool:
	if not is_instance_valid(lifted):lifted = null;return false
	var at := lifted_placement(controller, reach, exclude)
	if not at.ok:notice = str(at.reason);return false
	var n: Node3D = lifted;lifted = null
	n.global_transform = at.xform
	_set_down_on(n, at)
	var layers: Dictionary = n.get_meta("inv_lift_layers", {})
	for c in _bodies_of(n):
		if c is CollisionObject3D and layers.has(c.get_instance_id()):(c as CollisionObject3D).collision_layer = layers[c.get_instance_id()][0];(c as CollisionObject3D).collision_mask = layers[c.get_instance_id()][1]
	n.remove_meta("inv_lift_layers")
	var it := Items.item(str(n.get_meta("inv_item", "")))
	if at.hang and (str(it.get("snap", "")) == "grid" or not bool(it.get("gravity", true))):pin_node(n)
	else:
		unpin_node(n)
		if n.has_method("settle"):n.settle()
	if at.on_grid and not at.hang:n.global_position = Vector3(at.point.x, n.global_position.y, at.point.z)
	notice = "";return true

static func _bodies_of(n: Node) -> Array:
	var out: Array = [n]
	out.append_array(n.find_children("*", "CollisionObject3D", true, false))
	return out

## SET DOWN, NOT DROPPED (2026-11-04): a carrier with gravity knows its extent - its collider is that box - so a thing
## put onto a floor or a top stands 2 cm over it instead of falling from the half-height lift placement_at allows for
## things whose origin is their centre: from there the tall extinguisher tipped over, new or moved. Its physics state is
## moved with it. A thing without gravity is left to the carrier's stand rule (a health plus floats over its origin).
func _set_down_on(n: Node3D, at: Dictionary) -> void:
	var ext: Variant = n.get("extent")
	if not ext is AABB or at.hang or (at.hit as Dictionary).is_empty() or absf(Vector3(at.hit.normal).y) <= .5:return
	if n.get("gravity") == false:return   # a thing without gravity is stood by the carrier's own floor ray (settle), not dropped
	n.global_position.y = Vector3(at.hit.position).y - (ext as AABB).position.y + .02
	if n is RigidBody3D:PhysicsServer3D.body_set_state((n as RigidBody3D).get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, n.global_transform)

## A lift given up (the hand emptied or put away mid-move): the thing is taken back, as the grip would.
func cancel_lift() -> void:
	if not is_instance_valid(lifted):lifted = null;return
	var n: Node3D = lifted;lifted = null
	placed.erase(n);n.queue_free()

func set_knob(key: String, value: Variant) -> void:
	if current == "":return
	if not values.has(current):values[current] = {}
	values[current][key] = value
	var cfg := config_for(current);config_changed.emit(current, cfg)
	if is_instance_valid(held) and held.has_method("apply_config"):held.apply_config(cfg)
	_apply_worn(current)

## A knob of an item that is not the one in the hand (the prism's TAPE face dresses the roll whatever is held).
func set_knob_for(id: String, key: String, value: Variant) -> void:
	if Items.item(id).is_empty():return
	if not values.has(id):values[id] = {}
	values[id][key] = value
	config_changed.emit(id, config_for(id))
	if id == current and is_instance_valid(held) and held.has_method("apply_config"):held.apply_config(config_for(id))
	_apply_worn(id)

## The node worn for an item whether or not it is the current one (the tape's roll keeps its strips and metres).
func worn_of(id: String) -> Node:
	var n: Node = _worn.get(id)
	return n if is_instance_valid(n) else null

func _apply_worn(id: String) -> void:
	var w: Node = _worn.get(id)
	if is_instance_valid(w) and w.has_method("apply_config"):w.apply_config(config_for(id))
	if id == _mini_id and is_instance_valid(_mini):   # a knob turned: the miniature is remade with it
		var ctrl: Node3D = _mini.get_parent();_mini.get_parent().remove_child(_mini);_mini.queue_free();_mini = null;_mini_id = ""
		_sync_mini(ctrl)

## What the hand WEARS for the current item: a worn item (mount "worn" - the tape) is the real thing as a
## bangle on the controller, made once per item and shown while it is current; any other item is shown as a
## MINIATURE of itself over the back of the hand (Palle, 2026-10-29: "the current object must be a small
## version of the original") - the trigger makes the full-size one. Everything else is put away. `controller`
## null puts all away (the bracelet out of PLACE, or dropped). Returns the node now worn, or null.
func sync_worn(controller: Node3D) -> Node3D:
	var it := Items.item(current)
	var want: bool = controller != null and not it.is_empty() and str(it.get("mount", "")) == "worn" and str(it.get("coming", "")) == ""
	_sync_mini(controller if not want else null)
	for id in _worn:
		var n: Node = _worn[id]
		if is_instance_valid(n) and not (want and str(id) == current) and n.has_method("put_away"):n.put_away()
	if not want:return null
	var n: Node = _worn.get(current)
	if not is_instance_valid(n):
		var path := Items.scene_for(str(it.get("token", "")))
		if path == "" or not ResourceLoader.exists(path):return null
		n = (load(path) as PackedScene).instantiate()
		if not n.has_method("wear"):n.free();return null
		var cfg := config_for(current)
		for k in cfg:n.set_meta("config_%s" % str(k), cfg[k])
		if n.has_method("apply_grid_config"):n.apply_grid_config(cfg)
		n.name = "Worn_" + current;_worn[current] = n
	n.wear(controller, float(it.get("scale", 0.4)))   # wear() parents it under the controller
	return n

## The miniature over the hand: made from the item's own scene, scaled to MINI on its longest side, its physics and pickup off, out of every group (a tiny ball must not join the support graph).
func _sync_mini(controller: Node3D) -> void:
	var it := Items.item(current)
	var want: bool = controller != null and not it.is_empty() and str(it.get("coming", "")) == "" and str(it.get("mount", "")) != "worn"
	if not want or current != _mini_id or not is_instance_valid(_mini) or _mini.get_parent() != controller:
		if is_instance_valid(_mini):_mini.get_parent().remove_child(_mini);_mini.queue_free()
		_mini = null;_mini_id = ""
	if not want:return
	if _mini != null:return
	var n: Node3D = make_mini(current, MINI)
	if n == null:return
	controller.add_child(n)
	n.position = Vector3(0, .05, .09)
	_mini = n;_mini_id = current

## A miniature of any item: its own scene with its config, scaled so its longest side is `longest`, inert (no physics,
## no pickup, out of every group - a tiny ball must not join the support graph). Not parented. Null if it cannot be made.
func make_mini(id: String, longest: float) -> Node3D:
	var it := Items.item(id)
	if it.is_empty():return null
	var path := Items.scene_for(str(it.get("token", "")))
	if path == "" or not ResourceLoader.exists(path):return null
	var n: Node = (load(path) as PackedScene).instantiate()
	if not n is Node3D:n.free();return null
	var cfg := config_for(id)
	for k in cfg:n.set_meta("config_%s" % str(k), cfg[k])
	if n.has_method("apply_grid_config"):n.apply_grid_config(cfg)
	n.name = "Mini_" + id
	# inert before it enters the tree: a pickable's _ready must not register it anywhere first
	_make_inert(n)
	n.ready.connect(func():_make_inert(n), CONNECT_ONE_SHOT)   # what its _ready built, inert too
	var size: Array = it.get("size", [0.1, 0.1, 0.1]);var side: float = maxf(maxf(float(size[0]), float(size[1])), float(size[2]))
	(n as Node3D).scale = Vector3.ONE * (longest / maxf(side, .01))   # the item's own scale is for the real thing, not the miniature
	return n

static func _make_inert(n: Node) -> void:
	var stack: Array = [n]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		for c in x.get_children():stack.append(c)
		for g in x.get_groups():x.remove_from_group(g)
		if x is CollisionShape3D:(x as CollisionShape3D).disabled = true
		if x is CollisionObject3D:(x as CollisionObject3D).collision_layer = 0;(x as CollisionObject3D).collision_mask = 0
		if x is RigidBody3D:(x as RigidBody3D).freeze = true;(x as RigidBody3D).gravity_scale = 0
		if "enabled" in x and x.has_method("pick_up"):x.set("enabled", false)
		x.set_physics_process(false)

func mini_node() -> Node3D:
	return _mini if is_instance_valid(_mini) else null

## The node worn and in use now, or null: the bracelet's trigger and grip go to it instead of making things.
func worn_node() -> Node3D:
	var n: Node = _worn.get(current)
	return n if is_instance_valid(n) and n.get("worn_on") != null and bool(n.get("worn_active")) else null

## The bench's stage here (workbench.json by the Void's floor; `default` elsewhere): {snap, grid, grid_y}.
func stage() -> Dictionary:
	return stage_override if not stage_override.is_empty() else Items.stage(_void())

## The horizontal and vertical pitch of the bench, metres (1, 1 with no stage).
func pitch() -> Vector2:
	var st := stage()
	var g := maxf(float(st.get("grid", 1.0)), .05)
	return Vector2(g, maxf(float(st.get("grid_y", g)), .05))

## An item's config: its defaults, under the BENCH'S stage (grid, grid_y, snap_to - the rule of the floor the
## person stands on), under the person's own knobs.
func config_for(id: String) -> Dictionary:
	var over: Dictionary = {}
	var st := stage()
	if not st.is_empty():
		var pt := pitch()
		over = {"grid": pt.x, "grid_y": pt.y, "snap_to": str(st.get("snap", "grid"))}
		for key in ["diagonals", "rigidity", "fold"]:   # the Triangle stage's and the built look's (playground_ball.gd); a stage without them adds nothing
			if st.has(key):over[key] = st[key]
	over.merge(values.get(id, {}), true)
	return Items.config_for(Items.item(id), over)

## Make the current item at a transform (the hand's, or in front of a desktop camera) and return it, or null.
## Make an item at a transform and return it, or null: the one in the hand with the hand's knobs, or - a kept thing
## stood again - `for_id` with the config it was made with (`cfg_over`), outside the budget it already paid.
func spawn_at(xform: Transform3D, for_id := "", cfg_over: Dictionary = {}) -> Node3D:
	var iid: String = for_id if for_id != "" else current
	var restoring: bool = for_id != ""
	if iid == "":return null
	var it := Items.item(iid)
	if it.is_empty() or str(it.get("coming", "")) != "":return null
	if str(it.get("tool", "")) != "":notice = "a tool is not placed";return null
	if not restoring and not fits(iid):return null
	var cfg: Dictionary = cfg_over if restoring and not cfg_over.is_empty() else config_for(iid);var node: Node3D = null
	var path := Items.scene_for(str(it.get("token", "")))
	if path == "" or not ResourceLoader.exists(path):return null
	var probe := load(path);var inst: Node = probe.instantiate()
	if inst is XRToolsPickable:   # a pickable of its own (a roll of tape): held as it is
		for k in cfg:inst.set_meta("config_%s" % str(k), cfg[k])
		if inst.has_method("apply_grid_config"):inst.apply_grid_config(cfg)
		node = inst;node.name = "Held_" + iid
	else:
		inst.free()
		var carrier := Carrier.new()
		get_tree().current_scene.add_child(carrier);carrier.global_transform = xform
		if not carrier.build(it, cfg):carrier.queue_free();return null
		carrier.pitch = pitch()   # the bench's grid for the sand-block rule
		node = carrier
	if node.get_parent() == null:get_tree().current_scene.add_child(node)
	node.global_transform = xform
	# the body's physics state too, at once: measured 2026-11-04, a falling carrier kept the transform it entered the
	# tree with (yaw 0) and the first physics step wrote that back over the node - the turn and the face-the-person
	# basis were lost for every thing with gravity (frozen things were not affected)
	if node is RigidBody3D:PhysicsServer3D.body_set_state((node as RigidBody3D).get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, xform)
	var key: String = iid + "|" + JSON.stringify(cfg)
	node.set_meta("inv_item", iid);node.set_meta("inv_key", key);node.set_meta("inv_cfg", cfg)
	placed.append(node)
	# copies of one prefab share one multimesh after the first (Palle: "keep the copies multi mesh")
	if bool(it.get("instance", true)) and not _is_kit(node):   # the kit draws itself as multimeshes (kit_structure.gd)
		var art: Node3D = node
		if node is Carrier:
			var a: Variant = node.get("work")   # the carrier's artifact
			art = a if a is Node3D else node
		instancer().register(node, art, key)
	return node

# -- KEEP WHAT YOU BUILD (Palle, 2026-11-04: "keep improving" - after "nothing persists across maps") --------------
# The placed things of the Void's main tower are written to keep_path every KEEP_EVERY seconds when something changed,
# and stood again by the next game (restore_kept). They come back frozen where they were left - the Void streams its
# floors, and a body stood on a floor not yet built would fall through it - and a thing with gravity becomes a body
# again once a short ray finds its floor under it. keep_path "" keeps nothing (a trial floor, the museum, a probe).

var keep_path := ""
static var keep_default := "user://inventory/placed.json"   # a probe points it at its own folder before the game boots
const KEEP_EVERY := 2.0
var _keep_since := 0.0
var _kept := ""                    # the last snapshot written

## FORGETFUL FLOORS (Palle, 2026-11-23, on the Prefab Test floor: "when we add an object the objects stay ... for now the
## world should not remember these"). A thing standing on a floor whose map is listed in FORGET_PATH is not kept: it
## stands for the visit, and a row kept there before is not stood again.
const FORGET_PATH := "res://commons/data/inventory/forget.json"
static var _forget_maps: Array = []
static var _forget_read := false

func _forgotten(at: Vector3) -> bool:
	if not _forget_read:
		_forget_read = true
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(FORGET_PATH)) if FileAccess.file_exists(FORGET_PATH) else null
		if data is Dictionary and data.get("maps") is Array: _forget_maps = data.maps
	if _forget_maps.is_empty(): return false
	var g := _void()
	if g == null or g.get("building") == null: return false
	var index := -1
	var stream: Variant = g.get("floor_stream")
	if stream != null and is_instance_valid(stream): index = int(stream.floor_at_position(at))
	else:
		var levels: Array = g.building.spec.levels
		for i in levels.size():
			if at.y >= float(levels[i]) - 0.5:
				index = i
				break
	var floors: Array = g.building.content.data.floors
	return index >= 0 and index < floors.size() and _forget_maps.has(str(floors[index].map))

## What would be written now: one row per placed thing (not a lifted one, not one held, not one lost below the tower).
func kept_rows() -> Array:
	var rows: Array = []
	for n in placed:
		if not is_instance_valid(n) or not n.is_inside_tree() or n == lifted or not n.has_meta("inv_item"):continue
		if n.has_method("is_picked_up") and n.is_picked_up():continue
		var t: Transform3D = n.global_transform
		if _forgotten(t.origin):continue   # a forgetful floor: stands for the visit, not kept
		if t.origin.y < -2000.0:continue
		var b: Basis = t.basis.orthonormalized()
		var flat: Array = []
		for v in [b.x, b.y, b.z]:flat.append_array([snappedf(v.x, .0001), snappedf(v.y, .0001), snappedf(v.z, .0001)])
		rows.append({"item": str(n.get_meta("inv_item")), "config": n.get_meta("inv_cfg", {}), "basis": flat,
			"at": [snappedf(t.origin.x, .001), snappedf(t.origin.y, .001), snappedf(t.origin.z, .001)],
			"frozen": bool(n.get_meta("inv_slept")) if n.has_meta("inv_slept") else bool(n.get("freeze")), "how": str(n.get("how")) if n.get("how") != null else "", "pinned": bool(n.get("pinned"))})
	return rows

## Written if it changed since the last write (tmp + rename). Returns true when written.
func save_kept(force := false) -> bool:
	if keep_path == "":return false
	var text := JSON.stringify({"version": 1, "placed": kept_rows()}, "  ")
	if text == _kept and not force:return false
	var abs_path := ProjectSettings.globalize_path(keep_path)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var f := FileAccess.open(abs_path + ".tmp", FileAccess.WRITE)
	if f == null:push_warning("inventory: could not keep the placed things at " + abs_path);return false
	f.store_string(text + "\n");f.close()
	if FileAccess.file_exists(abs_path):DirAccess.remove_absolute(abs_path)
	DirAccess.rename_absolute(abs_path + ".tmp", abs_path)
	_kept = text
	return true

## Stand the kept things again; returns how many. Every one frozen; one with gravity is marked to wake on its floor.
func restore_kept() -> int:
	if keep_path == "" or not FileAccess.file_exists(keep_path):return 0
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(keep_path))
	if not data is Dictionary or not data.get("placed") is Array:return 0
	var made := 0
	for row in data.placed:
		if not row is Dictionary or Items.item(str(row.get("item", ""))).is_empty():continue
		var bv: Array = row.get("basis", []);var at: Array = row.get("at", [0, 0, 0])
		if bv.size() != 9 or at.size() != 3:continue
		var t := Transform3D(Basis(Vector3(bv[0], bv[1], bv[2]), Vector3(bv[3], bv[4], bv[5]), Vector3(bv[6], bv[7], bv[8])), Vector3(at[0], at[1], at[2]))
		if _forgotten(t.origin):continue   # kept before its floor became forgetful: not stood again
		var cfg: Dictionary = row.get("config", {}) if row.get("config") is Dictionary else {}
		var n: Node3D = spawn_at(t, str(row.item), cfg)
		if n == null:continue
		made += 1
		if n is RigidBody3D:
			var rb := n as RigidBody3D
			rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;rb.linear_velocity = Vector3.ZERO;rb.angular_velocity = Vector3.ZERO;rb.freeze = true
			if n.get("how") != null:n.set("how", str(row.get("how", "")))
			if n.get("pinned") != null:n.set("pinned", bool(row.get("pinned", false)))
			if not bool(row.get("frozen", false)):n.set_meta("inv_wake", true)   # a body again when its floor is there
	_kept = JSON.stringify({"version": 1, "placed": kept_rows()}, "  ")   # as restored: nothing new to write
	return made

## Keep the placed things here if this is the Void's main tower (not a trial floor, not the museum): the path set and the
## kept things stood again, once the scene is current. Returns how many came back, or -1 when nothing is kept here.
func keep_in_void() -> int:
	for i in 30:
		if is_inside_tree() and get_tree().current_scene != null and _void() != null:break
		await get_tree().process_frame
	var g := _void()
	if g == null or str(g.get("trial_id")) != "":return -1
	keep_path = keep_default
	var n := restore_kept()
	if n > 0:print("[inventory] %d placed things stood again from %s" % [n, keep_path])
	return n

## THE FLOOR'S SLEEP (2026-11-04): the Void puts a floor you left to sleep and REMOVES its content's colliders (the cube
## islands, the plinths, the works; the slab stays). A placed thing - a child of the scene, not of the floor - stood on
## them would fall, and the keeping would write it down where it landed. So a placed body follows its floor: frozen
## where it stands while that floor sleeps (meta inv_slept), a body again when it wakes. Every frame: a sleep removes the
## support at once.
func _follow_floors() -> void:
	var g := _void()
	var stream: Node = g.get("floor_stream") if g != null else null
	if stream == null or not stream.has_method("floor_at_position"):return
	var records: Dictionary = stream.get("records")
	for n in placed:
		if not is_instance_valid(n) or not n is RigidBody3D or n == lifted:continue
		var rb := n as RigidBody3D
		var rec: Variant = records.get(int(stream.floor_at_position(rb.global_position)))
		var asleep: bool = rec != null and str(rec.get("mode")) == "sleep"
		if asleep and not rb.has_meta("inv_slept"):
			if rb.has_method("is_picked_up") and rb.is_picked_up():continue
			rb.set_meta("inv_slept", rb.freeze)   # what it was, for the waking and for the keeping
			if not rb.freeze:rb.linear_velocity = Vector3.ZERO;rb.angular_velocity = Vector3.ZERO;rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;rb.freeze = true
		elif not asleep and rb.has_meta("inv_slept"):
			var was: bool = bool(rb.get_meta("inv_slept"));rb.remove_meta("inv_slept")
			if not was:rb.freeze = false;rb.sleeping = false

## A restored thing with gravity becomes a body again once its floor is under it (the Void builds floors as you near them).
func _wake_kept() -> void:
	if get_viewport() == null:return
	var space := get_viewport().world_3d.direct_space_state
	for n in placed:
		if not is_instance_valid(n) or not n.has_meta("inv_wake") or not n is RigidBody3D:continue
		var ext: Variant = n.get("extent")
		var low: float = (n.global_transform * (ext as AABB).position).y if ext is AABB else n.global_position.y
		var from := Vector3(n.global_position.x, low + .05, n.global_position.z)
		var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * .15, 1, [(n as RigidBody3D).get_rid()])
		if space.intersect_ray(q).is_empty():continue
		n.remove_meta("inv_wake");unpin_node(n)

const SURFACES := 0xFFFFFFFF & ~((1 << 17) | (1 << 19))   # all solid bodies but the avatar and the collision hands
const HANG_REACH := 2.0   # pointing at nothing: the thing hangs this far along the wand (Garry's Mod's frozen prop in the air)

## Frozen where it is - a carrier by its pin, any other body (a plank) by its freeze.
static func pin_node(n: Node) -> void:
	if n.has_method("pin"):n.pin()
	elif n is RigidBody3D:(n as RigidBody3D).freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;(n as RigidBody3D).linear_velocity = Vector3.ZERO;(n as RigidBody3D).angular_velocity = Vector3.ZERO;(n as RigidBody3D).freeze = true

## A body again, under gravity.
static func unpin_node(n: Node) -> void:
	if n.has_method("unpin"):n.unpin()
	elif n is RigidBody3D:(n as RigidBody3D).freeze = false;(n as RigidBody3D).gravity_scale = 1.0;(n as RigidBody3D).sleeping = false

## THE PIN TOOL (the policy's rule 5): the thing pointed at, if the hand placed it, is frozen where it is - mid-air
## included - or, frozen, released to be a body again. The kit's ball and rod keep their own rule ("hang": false) and
## tape is not a body. Returns "pinned", "released" or "" (the notice says why).
func pin_at(controller: Node3D, reach := 8.0, exclude: Array = []) -> String:
	var n: Node = pointed_own(controller, reach, exclude)
	if n == null:notice = "point the pin at a thing you placed";return ""
	if n.get("paid_length") != null and n.get("issuer") != null:notice = "tape is not pinned";return ""
	var it := Items.item(str(n.get_meta("inv_item", "")))
	if not bool(it.get("hang", true)):notice = str(it.get("name", "it")) + " keeps its own rule";return ""
	if not n is RigidBody3D:notice = "not a body";return ""
	notice = ""
	if bool(n.get("freeze")):unpin_node(n);return "released"
	pin_node(n);return "pinned"

## Turned to face the person from `at`, upright; `square` snaps that to the nearest quarter turn (a grid thing is
## placed square, or the sand-block rule would never catch it - it refuses a rest more than 8 degrees off).
static func _facing(controller: Node3D, at: Vector3, square := false) -> Basis:
	var to_me: Vector3 = controller.global_position - at;to_me.y = 0
	var b: Basis = Basis.looking_at(-to_me.normalized(), Vector3.UP) if to_me.length() > .01 else Basis()
	return Basis(Vector3.UP, roundf(b.get_euler().y / (PI / 2)) * (PI / 2)) if square else b

## GARRY'S MOD PLACEMENT (Palle, 2026-10-30: "add them to the scene like in garry's mod"): the item appears where
## the controller points - a ray along its -Z up to `reach` - standing on a floor or hung on a wall, settled by
## its own rule (the carrier's wall snap, the ball's grid, the rod's sockets, a plank's gravity). An item that
## mounts "wall" asks for a vertical surface and refuses a floor with a notice; "floor" the other way round.
## `exclude` is for bodies the ray must look past (the palette's own panels). Returns the node, or null.
## Where the current item would go if the trigger were pulled now: {ok, xform, hit, reason, on_grid, point}.
## The ghost asks every frame, the trigger once; one rule. Not ok: `reason` says why (the notice's words).
func placement_at(controller: Node3D, reach := 8.0, exclude: Array = [], for_id := "") -> Dictionary:
	var iid: String = for_id if for_id != "" else current   # a lifted thing asks with its own item
	var out := {"ok": false, "reason": "", "hit": {}, "xform": Transform3D(), "on_grid": false, "point": Vector3.ZERO, "hang": false}
	if iid == "":out.reason = "nothing in the hand";return out
	var it := Items.item(iid)
	if it.is_empty() or str(it.get("coming", "")) != "":out.reason = "not here yet";return out
	if str(it.get("tool", "")) != "":out.reason = "a tool is not placed";return out
	var origin: Vector3 = controller.global_position;var dir: Vector3 = -controller.global_basis.z
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * reach, SURFACES)
	q.exclude = exclude;q.hit_from_inside = false
	var hit := get_viewport().world_3d.direct_space_state.intersect_ray(q)
	var mount := str(it.get("mount", "any"));var cfg := config_for(iid)
	if hit.is_empty():
		# FREE HANGING (the policy's rule 4, Garry's Mod's frozen prop in the air): pointing at nothing, the thing goes
		# HANG_REACH along the wand - a grid thing to the nearest metre point in all three axes, to be frozen there (a
		# floating platform); a loose thing falls from there. The kit's ball and rod ("hang": false) have rules of
		# their own and come into the hand instead, as before; a wall thing still needs its wall.
		if not bool(it.get("hang", true)):out.reason = "point at a floor or a wall";return out
		if mount == "wall":out.reason = str(it.get("name", iid)) + " needs a wall";return out
		var where_h: Vector3 = origin + dir * HANG_REACH
		var grid_h: bool = str(it.get("snap", "")) == "grid"
		var pt_h := pitch()
		if grid_h:where_h = Vector3(snappedf(where_h.x, pt_h.x), snappedf(where_h.y, pt_h.y), snappedf(where_h.z, pt_h.x))
		var basis_h: Basis = Basis(Vector3.UP, -deg_to_rad(float(cfg["_yaw"]))) if cfg.has("_yaw") else _facing(controller, where_h, grid_h)
		out.xform = Transform3D(_turned(basis_h, grid_h), where_h);out.on_grid = grid_h;out.point = where_h;out.hang = true
		if for_id == "" and not fits(iid):out.reason = notice;return out   # a moved thing is already paid for
		out.ok = true;return out
	out.hit = hit
	var n: Vector3 = hit.normal;var vertical: bool = absf(n.y) < 0.5
	var size: Array = it.get("size", [0.3, 0.3, 0.3]);var scale_k: float = float(it.get("scale", 1.0))
	var where: Vector3 = hit.position
	# THE METRE GRID (Palle: "all artifacts should fit in the snap meter system like in the grid system"): an item
	# with "snap": "grid" stands on the metre points of the floor, turned by its _yaw knob - north, east, south,
	# west - instead of toward the person
	var on_grid: bool = str(it.get("snap", "")) == "grid" and not vertical
	var pt := pitch()
	if on_grid:where = Vector3(snappedf(hit.position.x, pt.x), hit.position.y, snappedf(hit.position.z, pt.x))
	var basis := Basis()
	if vertical:   # facing out of the wall, its back to it
		basis = Basis.looking_at(-n, Vector3.UP) if absf(n.dot(Vector3.UP)) < .99 else Basis()
		basis = Basis(basis.x, basis.y, -basis.z) if basis.z.dot(n) < 0 else basis
	elif cfg.has("_yaw"):   # turned by the knob, on the world's compass
		basis = Basis(Vector3.UP, -deg_to_rad(float(cfg["_yaw"])))
	else:basis = _facing(controller, hit.position, on_grid)   # upright, turned to face the person; a grid thing square
	var lift: float = (float(size[2]) * .5 * scale_k) if vertical else (float(size[1]) * .5 * scale_k + .02)
	if on_grid and mount == "floor":lift = .02   # a grid thing's origin is its base
	if bool(it.get("gravity", true)) and not vertical:lift = maxf(lift, .06)   # above whatever is there, then the drop
	out.xform = Transform3D(basis if vertical else _turned(basis, on_grid), where + n * lift);out.on_grid = on_grid;out.point = where
	if mount == "wall" and not vertical:out.reason = str(it.get("name", iid)) + " needs a wall";return out
	if mount == "floor" and vertical:out.reason = str(it.get("name", iid)) + " needs a floor";return out
	if for_id == "" and not fits(iid):out.reason = notice;return out   # a moved thing is already paid for
	out.ok = true;return out

func spawn_where_pointed(controller: Node3D, reach := 8.0, exclude: Array = []) -> Node3D:
	var at := placement_at(controller, reach, exclude)
	if not at.ok:notice = at.reason;return null
	notice = ""
	var node: Node3D = spawn_at(at.xform)
	if node == null:
		if notice == "":notice = "could not make it"   # spawn_at's own reason stands
		return null
	var it_s := Items.item(current)
	_set_down_on(node, at)
	if at.hang and (str(it_s.get("snap", "")) == "grid" or not bool(it_s.get("gravity", true))):
		pin_node(node)   # hung in the air: a grid thing or one without gravity is frozen there; a loose thing falls from there
	elif node.has_method("settle"):node.settle()
	if at.on_grid and not at.hang and node.is_inside_tree():node.global_position = Vector3(at.point.x, node.global_position.y, at.point.z)   # settling keeps its height, the grid its point
	# the headset's log is the only instrument for "it lands somewhere else in VR" (Palle, 2026-10-30): one line per placement
	var origin: Node = controller.get_parent() if controller.get_parent() is XROrigin3D else null
	print("[inventory] placed %s hand=%s hit=%s at=%s now=%s parent=%s origin=%s origin_scale=%s world_scale=%.3f how=%s" % [current, controller.global_position, at.hit.get("position", null), at.xform.origin, node.global_position, str(node.get_parent().get_path()) if node.get_parent() else "-", (origin as Node3D).global_position if origin else "-", (origin as Node3D).scale if origin else "-", XRServer.world_scale, str(node.get("how"))])
	call_deferred("_report_later", node, current)
	notice = "";return node

func _report_later(node: Node3D, id: String) -> void:
	await get_tree().physics_frame;await get_tree().physics_frame
	if is_instance_valid(node) and node.is_inside_tree():print("[inventory] %s two physics frames on: now=%s frozen=%s" % [id, node.global_position, str(node.get("freeze"))])

## Make the current item in a controller's hand: picked up at once by that hand's pickup function; with no
## pickup (a desktop), left 0.35 m ahead of the hand and settled.
func spawn_in(controller: Node3D) -> Node3D:
	var ahead := controller.global_transform.translated_local(Vector3(0, 0, -.35))
	var node := spawn_at(ahead)
	if node == null:return null
	var pk: Node = XRToolsFunctionPickup.find_instance(controller) if controller is XRController3D else null
	if pk != null and pk.has_method("_pick_up_object"):
		node.set("freeze", true);pk._pick_up_object(node)
		if node.has_method("is_picked_up") and node.is_picked_up():held = node;return node
	if node.has_method("settle"):node.settle()
	return node

func remove_last() -> Node3D:
	while not placed.is_empty():
		var n: Node3D = placed.pop_back()
		if is_instance_valid(n):
			if n.has_method("is_picked_up") and n.is_picked_up() and n.has_method("drop"):n.drop()
			n.queue_free();return n
	return null
