class_name VendingMachine
extends Node3D
## THE VENDING MACHINE (Palle, 2026-11-06: "one interface to pick up the prefabs and it should look like a vending
## machine ... when we pick a tape that config should be the one we use. We should have another vending machine for
## the planks and measuring rod etc."; then: "The artifact we can pick should be normal color, show all the different
## configurations of tape").
##
## A cabinet with a lit glass front and shelves. Every slot holds a MINIATURE of one inventory item
## (commons/data/inventory/items.json) in its own colours, over a tape label - the item's name, its configuration when
## it is one of several (`printed (words), hazard`), and the association line `rubber_ball = association(config(point))`
## that the hall's tape writes where the form was first met. The config a slot hands over is the one on its label:
## the item's defaults with that configuration's knobs. Grabbing a slot (an XR hand's grip, the desktop's grab)
## COLLECTS the item: its knobs are set on every hand that keeps an inventory and it goes on the belt and into the
## hand, as picking the example up from its association_plinth does; the miniature goes straight back. A machine
## never runs out. The glass has no collider, so hands reach through it. An item its floor has not handed over yet
## shows dark, with its floor on the tape.
##   config: kind prefabs|tools; columns (6 prefabs, 4 tools); mini (m, a miniature's longest side); title;
##           variants ({"item": [{knob: value}, ...]} JSON, added to VARIANTS)

const Items = preload("res://commons/player/inventory_items.gd")
const HandLib = preload("res://commons/player/inventory_hand.gd")   # its static _make_inert; a hand itself may be absent (a bench)
const Composite = preload("res://commons/modular/composite.gd")
const TOOLS := ["tape", "rubber", "pin", "test", "measuringstick", "plank", "plank2", "clock"]
## Items shown in every configuration: one slot per entry, its knobs over the item's defaults (the tape's four kinds,
## and the printed kind in each of its designs).
const VARIANTS := {"tape": [{"kind": "printed"}, {"kind": "printed", "tape": "hazard"}, {"kind": "printed", "tape": "survey"},
	{"kind": "printed", "tape": "blueprint"}, {"kind": "printed", "tape": "chevron"}, {"kind": "printed", "tape": "dotted_note"},
	{"kind": "masking"}, {"kind": "pink"}, {"kind": "barrier"}]}
const PITCH_X := 0.24
const PITCH_Y := 0.24
const DEPTH := 0.62
const REACH := 0.22              # the front of the cabinet the collider leaves free: the hands' way in
const BODY := Color("2a3236")
const SHELF := Color("3c474b")
const DARK := Color(0.3, 0.32, 0.34, 0.55)
const INK := Color("1d1d1f")
const IVORY := Color("efe7d2")

@export_enum("prefabs", "tools") var kind := "prefabs"
@export var columns := 0        # 0: 6 for prefabs, 4 for tools
@export var mini := 0.15
@export var title := ""
@export_multiline var variants := ""   # JSON, added to VARIANTS

var slots: Dictionary = {}      # slot key -> {id, knobs, holder, shell, home, spot}
var width := 1.0
var height := 1.9
var _variants: Dictionary = VARIANTS.duplicate(true)
var _glow: Dictionary = {}      # slot key -> glow left (the spot lights up when taken)
var _turns: Array[Node3D] = []  # the miniatures' turntables
## THE STOCKING (2026-11-07, the arrival stutter in the Void): a machine used to load every item's scene and make every
## miniature in its _ready - 744 ms for the first prefabs machine, 128 ms once the scenes were cached, in one frame. Now
## the cabinet stands at once, the item scenes load on a worker thread, and the slots are filled a few per frame
## (STOCK_BUDGET_MS) in their order, each once its scene is in. `stocked` says when the last slot is made.
const STOCK_BUDGET_MS := 6.0
const PICKABLE := "res://addons/godot-xr-tools/objects/pickable.tscn"
var stocked := false
var _stock: Array = []          # [entry, at] still to be made, in shelf order
var _loading: Dictionary = {}   # scene path -> true while its worker load runs
var _loaded: Dictionary = {}    # scene path -> PackedScene, held while the machine stocks
signal stock_complete

func apply_grid_config(config: Dictionary) -> void:
	if config.has("kind") and str(config.kind) in ["prefabs", "tools"]: kind = str(config.kind)
	if config.has("columns"): columns = int(config.columns)
	if config.has("mini"): mini = float(config.mini)
	if config.has("title"): title = str(config.title)
	if config.has("variants"):
		var v: Variant = config.variants
		if v is String: v = JSON.parse_string(str(v))
		if v is Dictionary:
			for id in v:
				if v[id] is Array: _variants[str(id)] = v[id]
	if is_inside_tree() and not slots.is_empty(): _build()   # a config that arrives after _ready rebuilds

func _ready() -> void:
	var cfg := {}
	for key in ["kind", "columns", "mini", "title", "variants"]:
		if has_meta("config_" + key): cfg[key] = get_meta("config_" + key)
	apply_grid_config(cfg)
	_build()

## The items this machine sells: the tools, or everything else, in items.json's order.
func stock() -> Array:
	var out := []
	for it in Items.items():
		var id := str(it.get("id", ""))
		if id != "" and ((id in TOOLS) == (kind == "tools")): out.append(it)
	return out

## One entry per slot: an item in each of its configurations ({item, knobs, key}).
func slot_list() -> Array:
	var out := []
	for it in stock():
		var id := str(it.get("id", ""))
		var vs: Array = _variants.get(id, [])
		if vs.is_empty(): out.append({"item": it, "knobs": {}, "key": id})
		else:
			for i in vs.size(): out.append({"item": it, "knobs": vs[i], "key": "%s_%d" % [id, i + 1]})
	return out

## The line the hall's tape writes for this item (`rubber_ball = association(config(point))`), or "" without a term.
static func tape_line(it: Dictionary) -> String:
	var prefab := str(it.get("prefab", ""))
	if prefab == "": return ""
	var term: Dictionary = Composite.terms().get(prefab, {})
	var expr := str(term.get("expr", ""))
	if not expr.begins_with("association("): return ""
	return "%s = %s" % [prefab, expr.get_slice(" = ", 0)]

## A configuration's knobs in the words of the item's knob names: {"kind": "printed", "tape": "hazard"} ->
## "printed (words), hazard".
static func knob_names(it: Dictionary, knobs: Dictionary) -> String:
	var parts: Array[String] = []
	for k in knobs:
		var shown := str(knobs[k])
		for knob in it.get("knobs", []):
			if str(knob.get("key", "")) != str(k): continue
			var i: int = (knob.get("choices", []) as Array).find(str(knobs[k]))
			if i >= 0 and i < (knob.get("names", []) as Array).size(): shown = str(knob.names[i])
		if shown != "": parts.append(shown)
	return ", ".join(parts)

## An item marked "collect" is unlocked by picking up its example on its plinth; here the machine IS that plinth, so
## only its floor (in the Void) or its sequence (in a grid map) gates it.
func _unlocked(it: Dictionary) -> bool:
	var rule := it.duplicate(); rule.erase("collect")
	return Items.unlocked(rule, get_node_or_null("/root/LabManager"), get_tree().get_first_node_in_group("void_game"))

func _build() -> void:
	for c in get_children(): remove_child(c); c.queue_free()
	slots.clear(); _glow.clear(); _turns.clear()
	var entries := slot_list()
	var cols: int = columns if columns > 0 else (4 if kind == "tools" else 6)
	var rows: int = maxi(1, ceili(float(entries.size()) / float(cols)))
	width = cols * PITCH_X + .24
	var shelves_h: float = rows * PITCH_Y
	height = maxf(1.9, shelves_h + .78)
	var d := DEPTH
	var cabinet := StaticBody3D.new(); cabinet.name = "Cabinet"; cabinet.collision_layer = 1; add_child(cabinet)
	_box(cabinet, "Back", Vector3(0, height * .5, -d * .5 + .03), Vector3(width, height, .06), BODY)
	for s in [-1.0, 1.0]: _box(cabinet, "Side", Vector3(s * (width * .5 - .025), height * .5, 0), Vector3(.05, height, d), BODY)
	_box(cabinet, "Top", Vector3(0, height - .03, 0), Vector3(width, .06, d), BODY)
	_box(cabinet, "Plinth", Vector3(0, .05, 0), Vector3(width, .10, d), Color("17191b"))
	_box(cabinet, "Head", Vector3(0, height - .19, .02), Vector3(width - .1, .26, d - .08), Color("1d2427"))
	_box(cabinet, "Tray", Vector3(0, .25, .02), Vector3(width - .1, .30, d - .08), Color("1d2427"))
	_box(cabinet, "TrayMouth", Vector3(0, .25, d * .5 - .03), Vector3(width * .6, .18, .02), Color("0d0f10"))
	# one collider: the cabinet less its front REACH, so a hand reaches the shelves and a body cannot walk through it
	var shape := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(width, height, d - REACH); shape.shape = bs
	shape.position = Vector3(0, height * .5, -REACH * .5); cabinet.add_child(shape)
	# the lit interior
	var mid: float = .40 + shelves_h * .5 + .02
	_box(cabinet, "Interior", Vector3(0, mid, -d * .5 + .07), Vector3(width - .1, shelves_h + .12, .02), Color("aab6b4"))
	var light := OmniLight3D.new(); light.name = "ShelfLight"; light.light_color = Color("f3f7ff"); light.light_energy = 1.2
	light.omni_range = maxf(width, shelves_h) + .4; light.position = Vector3(0, mid, .05); light.shadow_enabled = false; cabinet.add_child(light)
	# the glass: no collider, the hands reach through
	var glass := StandardMaterial3D.new(); glass.albedo_color = Color(.8, .92, .94, .09)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS; glass.roughness = .15; glass.metallic = .05; glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var pane := _box(cabinet, "Glass", Vector3(0, mid, d * .5 - .02), Vector3(width - .1, shelves_h + .12, .012), Color.WHITE)
	pane.material_override = glass; pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# the name plate
	_label(cabinet, title if title != "" else ("TOOLS" if kind == "tools" else "PREFABS"), Vector3(0, height - .165, d * .5 - .018), 40, .0012, Color("e9f2ee"))
	_label(cabinet, "GRAB A THING: INTO YOUR HAND", Vector3(0, height - .25, d * .5 - .018), 15, .0012, Color("9fb3ae"))
	# the shelves and their lips, then a slot per entry
	var x0: float = -(cols - 1) * PITCH_X * .5
	var y0: float = .40
	for r in rows:
		var y: float = y0 + r * PITCH_Y
		_box(cabinet, "Shelf", Vector3(0, y - .008, -.04), Vector3(width - .12, .016, d - .22), SHELF)
		_box(cabinet, "ShelfLip", Vector3(0, y + .022, d * .5 - .14), Vector3(width - .12, .06, .006), Color("c8d0cc"))
	_stock.clear(); stocked = false
	for i in entries.size():
		var c: int = i % cols; var r: int = floori(float(i) / float(cols))
		_stock.append([entries[i], Vector3(x0 + c * PITCH_X, y0 + r * PITCH_Y, -.04)])
		_request(Items.scene_for(str(entries[i].item.get("token", ""))))
	_request(PICKABLE)
	set_process(true)

## Ask a worker thread for a scene this machine will need, unless it is cached or already asked for.
func _request(path: String) -> void:
	if path == "" or _loading.has(path) or _loaded.has(path) or ResourceLoader.has_cached(path) or not ResourceLoader.exists(path): return
	if ResourceLoader.load_threaded_request(path, "PackedScene") == OK: _loading[path] = true

## Whether a slot's scene can be used now without a load on this thread (a failed worker load falls back to load()).
func _ready_to_make(path: String) -> bool:
	if path == "" or not _loading.has(path): return true
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS: return false
	if status == ResourceLoader.THREAD_LOAD_LOADED: _loaded[path] = ResourceLoader.load_threaded_get(path)
	_loading.erase(path)
	return true

## A few slots per frame, in shelf order, within the budget.
func _stock_some() -> void:
	if stocked: return
	if not _ready_to_make(PICKABLE): return
	var start := Time.get_ticks_usec()
	while not _stock.is_empty() and (Time.get_ticks_usec() - start) / 1000.0 < STOCK_BUDGET_MS:
		var next: Array = _stock[0]
		if not _ready_to_make(Items.scene_for(str(next[0].item.get("token", "")))): return
		_stock.pop_front()
		_slot(next[0], next[1])
	if _stock.is_empty():
		stocked = true; _loaded.clear()
		stock_complete.emit()

func _slot(entry: Dictionary, at: Vector3) -> void:
	var it: Dictionary = entry.item; var id := str(it.get("id", "")); var key := str(entry.key); var knobs: Dictionary = entry.knobs
	var locked := not _unlocked(it)
	var holder := Node3D.new(); holder.name = "Slot_" + key; holder.position = at; add_child(holder)
	var spot_mat := StandardMaterial3D.new(); spot_mat.albedo_color = Color("222a2e") if locked else Color("2f3c41"); spot_mat.roughness = .7
	var spot := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = .085; cm.bottom_radius = .085; cm.height = .01; cm.radial_segments = 24
	spot.mesh = cm; spot.material_override = spot_mat; spot.position.y = .005; spot.name = "Spot"; holder.add_child(spot)
	# the tape on the shelf's lip: the name, the configuration, the association line, and the floor if not yet
	var words: String = str(it.get("name", id)).get_slice(" - ", 0).to_upper()
	var variant := knob_names(it, knobs)
	if variant != "": words += "\n" + variant
	var line := tape_line(it)
	if line != "": words += "\n" + line
	if locked: words += "\n" + ("FROM FLOOR %d" % int(it.get("floor", 0)) if int(it.get("floor", 0)) > 0 else "NOT YET")
	_box(holder, "Tape", Vector3(0, .032, .2135), Vector3(PITCH_X - .03, .048, .004), IVORY if not locked else Color("6d6a62"))
	var print_ := _label(holder, words, Vector3(0, .032, .216), 15, .00052, INK)
	print_.name = "Print"
	# the miniature, in its own colours, on a turntable
	var turn := Node3D.new(); turn.name = "Turn"; turn.position = Vector3(0, .012, 0); holder.add_child(turn); _turns.append(turn)
	var n := _make_mini(id, knobs, mini, locked)
	if n != null:
		turn.add_child(n)
		_seat_later(n, turn, locked)
	if locked: return
	# the pick: an invisible XR Tools pickable fitted round the miniature; grabbed, it collects and goes straight back.
	# home is the shell's LOCAL transform: XR Tools never reparents a held pickable, and the machine may be moved after
	# it is built (a bench sets the position after add_child; the Void's editor drags a mount)
	var shell := _shell(holder)
	slots[key] = {"id": id, "knobs": knobs, "holder": holder, "shell": shell, "home": shell.transform, "spot": spot_mat}
	shell.picked_up.connect(_on_picked_up.bind(key))

## A miniature of an item in one configuration: its own scene with the label's config (the item's defaults, the
## configuration's knobs over them), inert, scaled so its longest side is `longest`, its own materials; dimmed when
## locked. Null if it cannot be made.
func _make_mini(id: String, knobs: Dictionary, longest: float, locked: bool) -> Node3D:
	var it := Items.item(id)
	if it.is_empty(): return null
	var path := Items.scene_for(str(it.get("token", "")))
	if path == "" or not ResourceLoader.exists(path): return null
	var n: Node = (load(path) as PackedScene).instantiate()
	if not n is Node3D: n.free(); return null
	var cfg := Items.config_for(it, knobs)
	for k in cfg: n.set_meta("config_%s" % str(k), cfg[k])
	if n.has_method("apply_grid_config"): n.apply_grid_config(cfg)
	n.name = "Mini_" + id
	HandLib._make_inert(n)   # inert before it enters the tree: a pickable's _ready must not register it anywhere first
	n.ready.connect(func(): HandLib._make_inert(n); _quiet(n, locked), CONNECT_ONE_SHOT)
	var size: Array = it.get("size", [0.1, 0.1, 0.1]); var side: float = maxf(maxf(float(size[0]), float(size[1])), float(size[2]))
	(n as Node3D).scale = Vector3.ONE * (longest / maxf(side, .01))
	return n

## After the miniature has built itself (some build over a few frames): its base seated on the spot, centred on the
## turntable; a kit ball or rod, drawn by the kit's shared multimesh in the world and keeping its own meshes hidden,
## is out of every group here and shows its own meshes instead.
func _seat_later(n: Node3D, turn: Node3D, locked: bool) -> void:
	for i in 20: await get_tree().process_frame
	if not is_instance_valid(n) or not n.is_inside_tree(): return
	_quiet(n, locked)
	var b := _bounds(n)
	if b.size.length() < .001:
		for m in n.find_children("*", "MeshInstance3D", true, false): (m as MeshInstance3D).visible = true
		_quiet(n, locked)
		b = _bounds(n)
		if b.size.length() < .001: return
	var centre := b.get_center()
	n.global_position += Vector3(turn.global_position.x - centre.x, turn.global_position.y - b.position.y, turn.global_position.z - centre.z)
	HandLib._make_inert(n)

## A miniature keeps its own colours; its labels and lights are not for the shelf. Locked, it is dimmed to a shade.
static func _quiet(n: Node, locked: bool) -> void:
	var shade: StandardMaterial3D = null
	if locked:
		shade = StandardMaterial3D.new(); shade.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shade.albedo_color = DARK; shade.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; shade.cull_mode = BaseMaterial3D.CULL_DISABLED
	for g in n.find_children("*", "GeometryInstance3D", true, false):
		if g is Label3D: (g as Label3D).visible = false; continue
		(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if shade != null: (g as GeometryInstance3D).material_override = shade
	for l in n.find_children("*", "Light3D", true, false): (l as Light3D).visible = false

## The miniature's meshes in world space (their merged box), or an empty AABB.
static func _bounds(root: Node3D) -> AABB:
	var box := AABB(); var first := true
	for m in root.find_children("*", "MeshInstance3D", true, false):
		if (m as MeshInstance3D).mesh == null or not (m as Node3D).is_visible_in_tree(): continue
		var b: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b); first = false
	return box

## An invisible pickable round the miniature: XR Tools' pickable with one box of the miniature's size, frozen on the
## shelf. Grabbed, it collects; let go, it goes back (the miniature never moved).
func _shell(holder: Node3D) -> RigidBody3D:
	var packed: PackedScene = load("res://addons/godot-xr-tools/objects/pickable.tscn")
	var shell: RigidBody3D = packed.instantiate()
	for c in shell.get_children():
		if c is CollisionShape3D and (c as CollisionShape3D).shape == null: c.free()
	shell.name = "Pick"
	var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3.ONE * mini * 1.1; shape.shape = box; shell.add_child(shape)
	shell.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC; shell.freeze = true
	holder.add_child(shell); shell.position = Vector3(0, mini * .55 + .012, 0)
	return shell

## Grabbed: the slot's configuration is set on every hand that keeps an inventory (the VR prism's, the desktop's) and
## the item collected by it; the spot lights; the shell is put back on its shelf once the hand has let it go.
func _on_picked_up(_what: Variant, key: String) -> void:
	var s: Dictionary = slots.get(key, {})
	var id := str(s.get("id", ""))
	var it := Items.item(id)
	if it.is_empty(): return
	var knobs: Dictionary = s.get("knobs", {})
	var fresh := Items.collect(id)
	for h in get_tree().get_nodes_in_group("inventory_hands"):
		if h.has_method("set_knob_for"):
			for k in knobs: h.set_knob_for(id, str(k), knobs[k])
		if h.has_method("collect"): h.collect(id)
	_glow[key] = 1.0
	var shown: String = str(it.get("name", id)).get_slice(" - ", 0)
	var variant := knob_names(it, knobs)
	if variant != "": shown += " / " + variant
	var game := get_tree().get_first_node_in_group("void_game")
	if game != null and game.has_method("_notice"):
		var vr: bool = bool(game.get("vr"))
		var how := "Left stick click: choose\nTrigger: place / hold: move\nGrip: take back" if vr else "Tab: choose\nF: place / hold F: move\nX: take back"
		game._notice(("COLLECTED / " if fresh else "IN THE HAND / ") + shown + "\n" + how)
	print("[vending] %s machine: %s (new %s)" % [kind, key, fresh])
	_return_home.call_deferred(key)

func _return_home(key: String) -> void:
	var s: Dictionary = slots.get(key, {})
	var shell: RigidBody3D = s.get("shell") as RigidBody3D
	if shell == null or not is_instance_valid(shell): return
	if shell.has_method("is_picked_up") and shell.is_picked_up():
		var by: Node = shell.get_picked_up_by() if shell.has_method("get_picked_up_by") else null
		if by != null and by.has_method("drop_object"): by.drop_object()
		elif by != null: shell.let_go(by, Vector3.ZERO, Vector3.ZERO)
	await get_tree().physics_frame
	if not is_instance_valid(shell): return
	shell.linear_velocity = Vector3.ZERO; shell.angular_velocity = Vector3.ZERO
	shell.transform = s.home
	shell.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC; shell.freeze = true

func _process(delta: float) -> void:
	_stock_some()
	for t in _turns:
		if is_instance_valid(t): t.rotation.y += delta * .5
	for key in _glow.keys():
		_glow[key] = maxf(float(_glow[key]) - delta * .8, 0.0)
		var mat: StandardMaterial3D = slots.get(key, {}).get("spot")
		if mat == null: _glow.erase(key); continue
		mat.emission_enabled = _glow[key] > 0.0; mat.emission = Color("f59e0b"); mat.emission_energy_multiplier = float(_glow[key]) * 2.0
		if _glow[key] <= 0.0: _glow.erase(key)

func get_state() -> Dictionary:
	return {"kind": kind, "slots": slots.size(), "entries": slot_list().size(), "stock": stock().size(), "width": width, "height": height, "stocked": stocked}

static func _box(parent: Node3D, title_: String, at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new(); m.name = title_; m.position = at
	var b := BoxMesh.new(); b.size = size; m.mesh = b
	var mat := StandardMaterial3D.new(); mat.albedo_color = colour; mat.roughness = .82; m.material_override = mat
	parent.add_child(m)
	return m

static func _label(parent: Node3D, words: String, at: Vector3, size: int, px: float, colour: Color) -> Label3D:
	var l := Label3D.new(); l.text = words; l.position = at; l.font_size = size; l.pixel_size = px; l.outline_size = 0
	l.modulate = colour; l.double_sided = false; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l
