class_name PrefabBelt
extends Node3D
## THE PREFAB BELT (Palle, 2026-11-21: "Instead of showing all different prefabs, make one machine show 4 prefabs at
## the time of the time line. The machine should be a bit like a conveyor belt or air port security band with boxes at
## the ends of a band with 4 positions. That we can step with buttons or roll with a lever.")
##
## One machine for the whole prefab timeline. The timeline is the inventory's items (commons/data/inventory/items.json,
## the vending machines' stock) in the order of the floor that gives them. A band carries four trays between two
## housings; the timeline runs through it, earlier things leaving into the left housing, later ones coming out of the
## right. Two keys step it one tray; a lever rolls it while it is held off its middle.
##
## What a tray shows depends on where the machine stands (the Void floor; `floor` in the config overrides):
##   here    - given on this floor: the thing itself, to be taken, under its name
##   earlier - given on a floor above: the thing, to be taken, and its association line
##             `fire_extinguisher = association(config(cylinder))`
##   later   - not yet given: a closed box with the floor that opens it
## Off the tower (a bench, a grid map) every tray is `earlier`.
##   config: include prefabs|all (prefabs = the vending shelf's stock less the tools; all = every item);
##           floor; mini (m, a miniature's longest side); title; start (timeline index of the first tray);
##           formula_here (true: this floor's trays show the line as well)

const Items = preload("res://commons/player/inventory_items.gd")
const HandLib = preload("res://commons/player/inventory_hand.gd")
const Vending = preload("res://commons/artifacts/vending_machine/vending_machine.gd")   # tape_line, _quiet, _bounds, _box, _label
const SquareKey := preload("res://commons/interactables/cube_button.tscn")
const LeverScene := preload("res://commons/interactables/lever_zero.tscn")
const PICKABLE := "res://addons/godot-xr-tools/objects/pickable.tscn"

const POSITIONS := 4
const PITCH := 0.5               # between two trays
const BAND := POSITIONS * PITCH  # the open band between the housings
const HOUSING := 0.62            # a housing's width
const DEPTH := 0.62
const BELT_Y := 0.92             # the band's top
const HOUSING_H := 0.56          # a housing above the band
const SLAT := 0.125
const ROLL_SPEED := 2.4          # trays a second at the lever's stop
const STEP_SPEED := 2.2          # trays a second for a key press
const LEVER_DEAD := 5.0          # degrees
const BODY := Color("2a3236")
const STEEL := Color("9aa3a5")
const RUBBER := Color("15181a")
const TRAY := Color("8d9698")
const IVORY := Color("efe7d2")
const INK := Color("1d1d1f")
const CARD := Color("b08a55")

@export_enum("prefabs", "all") var include := "prefabs"
@export var mini := 0.26
@export var title := ""
@export var start := -1
@export var formula_here := false

var given_floor := -1
var timeline: Array = []          # the items, in the order of the floor that gives them
var pos := 0.0                    # the timeline index on the first position; whole when the band rests
var target := 0.0
var trays: Dictionary = {}        # timeline index -> {node, state, made, shell, home, id}
var lever: Node3D
var _slats: Array[MeshInstance3D] = []
var _turns: Array[Node3D] = []
var _counter: Label3D
var _loading: Dictionary = {}
var _rolling := false             # the lever holds the band
var _glow: Dictionary = {}

func apply_grid_config(config: Dictionary) -> void:
	if config.has("include") and str(config.include) in ["prefabs", "all"]: include = str(config.include)
	if config.has("mini"): mini = float(config.mini)
	if config.has("title"): title = str(config.title)
	if config.has("start"): start = int(config.start)
	if config.has("formula_here"): formula_here = str(config.formula_here) == "true" or config.formula_here == true
	if is_inside_tree() and _counter != null: _build()

func _ready() -> void:
	var cfg := {}
	for key in ["include", "mini", "title", "start", "formula_here"]:
		if has_meta("config_" + key): cfg[key] = get_meta("config_" + key)
	apply_grid_config(cfg)
	_build()

func _given_floor() -> int:
	if has_meta("config_floor"): return int(get_meta("config_floor"))
	var n: Node = get_parent()
	while n != null:
		if n.has_meta("void_content_floor"): return int(n.get_meta("void_content_floor"))
		n = n.get_parent()
	return -1

static func floor_of(it: Dictionary) -> int:
	var f: Variant = it.get("floor", 0)
	return int(f) if f != null else 0

## The timeline: the items this machine carries, by the floor that gives them (items.json's order within a floor).
func read_timeline() -> Array:
	var out := []
	for it in Items.items():
		var id := str(it.get("id", ""))
		if id == "": continue
		if include == "prefabs" and (not bool(it.get("vending", true)) or id in Vending.TOOLS): continue
		out.append(it)
	var order := {}
	for i in out.size(): order[str(out[i].id)] = i
	out.sort_custom(func(a, b):
		var fa := floor_of(a); var fb := floor_of(b)
		return fa < fb if fa != fb else int(order[str(a.id)]) < int(order[str(b.id)]))
	return out

## here | earlier | later, for the floor the machine stands on; off the tower everything is earlier.
func state_of(it: Dictionary) -> String:
	if given_floor < 0: return "earlier"
	var f := floor_of(it)
	return "here" if f == given_floor else ("earlier" if f < given_floor else "later")

func last_start() -> int:
	return maxi(0, timeline.size() - POSITIONS)

## Where the band starts: one earlier tray, then the first thing this floor gives; without one, the last four allowed.
func _start_index() -> int:
	if start >= 0: return clampi(start, 0, last_start())
	var first_here := -1; var last_allowed := -1
	for i in timeline.size():
		var s := state_of(timeline[i])
		if s == "here" and first_here < 0: first_here = i
		if s != "later": last_allowed = i
	if given_floor < 0: return 0
	if first_here >= 0: return clampi(first_here - 1, 0, last_start())
	return clampi(last_allowed - (POSITIONS - 1), 0, last_start())

func _build() -> void:
	for c in get_children(): remove_child(c); c.queue_free()
	trays.clear(); _slats.clear(); _turns.clear(); _glow.clear(); _loading.clear()
	given_floor = _given_floor()
	timeline = read_timeline()
	pos = float(_start_index()); target = pos
	var width := BAND + HOUSING * 2.0
	var hx := BAND * .5 + HOUSING * .5          # a housing's centre
	var body := StaticBody3D.new(); body.name = "Machine"; body.collision_layer = 1; add_child(body)
	# the band's frame: two rails, legs, a dark bed, the moving slats on it
	Vending._box(body, "Bed", Vector3(0, BELT_Y - .03, 0), Vector3(width, .05, DEPTH - .08), RUBBER)
	for s in [-1.0, 1.0]:
		Vending._box(body, "Rail", Vector3(0, BELT_Y - .01, s * (DEPTH * .5 - .02)), Vector3(width, .11, .04), STEEL)
	Vending._box(body, "Apron", Vector3(0, BELT_Y - .2, 0), Vector3(width - .1, .26, DEPTH - .1), BODY)
	for x in [-width * .5 + .12, -BAND * .5, 0.0, BAND * .5, width * .5 - .12]:
		for s in [-1.0, 1.0]:
			Vending._box(body, "Leg", Vector3(x, (BELT_Y - .32) * .5, s * (DEPTH * .5 - .06)), Vector3(.05, BELT_Y - .32, .05), STEEL)
	var slat_n := int(round(BAND / SLAT)) + 1
	for i in slat_n:
		var sl := Vending._box(body, "Slat", Vector3(0, BELT_Y - .003, 0), Vector3(.012, .004, DEPTH - .1), Color("2d3336"))
		_slats.append(sl)
	# the two housings, each with a dark mouth toward the band and rubber flaps over it
	for s in [-1.0, 1.0]:
		var h := Node3D.new(); h.name = "HousingLeft" if s < 0 else "HousingRight"; h.position = Vector3(s * hx, BELT_Y, 0); body.add_child(h)
		Vending._box(h, "Roof", Vector3(0, HOUSING_H - .025, 0), Vector3(HOUSING, .05, DEPTH + .04), BODY)
		Vending._box(h, "Back", Vector3(0, HOUSING_H * .5, -DEPTH * .5), Vector3(HOUSING, HOUSING_H, .04), BODY)
		Vending._box(h, "Front", Vector3(0, HOUSING_H * .5, DEPTH * .5), Vector3(HOUSING, HOUSING_H, .04), BODY)
		Vending._box(h, "End", Vector3(s * (HOUSING * .5 - .02), HOUSING_H * .5, 0), Vector3(.04, HOUSING_H, DEPTH), BODY)
		Vending._box(h, "Dark", Vector3(s * .04, HOUSING_H * .5 - .03, 0), Vector3(HOUSING - .12, HOUSING_H - .1, DEPTH - .06), Color("07090a"))
		for k in 7:
			var flap := Vending._box(h, "Flap", Vector3(-s * (HOUSING * .5 - .004), HOUSING_H * .5 - .01, -DEPTH * .5 + .075 + k * .0785), Vector3(.006, HOUSING_H - .09, .068), Color("23282b"))
			flap.rotation.x = (float(k % 3) - 1.0) * .05
		Vending._label(h, "EARLIER" if s < 0 else "LATER", Vector3(0, HOUSING_H - .07, DEPTH * .5 + .022), 30, .0012, Color("e9f2ee"))
	# colliders: the base under the band, and the two housings; the band's air is free for the hands
	_collider(body, Vector3(0, (BELT_Y - .02) * .5, 0), Vector3(width, BELT_Y - .02, DEPTH))
	for s in [-1.0, 1.0]: _collider(body, Vector3(s * hx, BELT_Y + HOUSING_H * .5, 0), Vector3(HOUSING, HOUSING_H, DEPTH))
	# the name plate and the counter, over the band on a thin gantry
	Vending._box(body, "Gantry", Vector3(0, BELT_Y + HOUSING_H - .04, -DEPTH * .5 + .02), Vector3(BAND, .08, .03), BODY)
	Vending._label(body, title if title != "" else "PREFAB TIMELINE", Vector3(0, BELT_Y + HOUSING_H - .04, -DEPTH * .5 + .037), 34, .0012, Color("e9f2ee"))
	_counter = Vending._label(body, "", Vector3(0, BELT_Y - .2, DEPTH * .5 - .047), 22, .0012, Color("9fb3ae"))
	# the keys on the right housing, the lever on the left
	var keys := [["Earlier", -1, -.14, "<"], ["Later", 1, .14, ">"]]
	for k in keys:
		var key := SquareKey.instantiate() as Node3D
		key.name = "Step" + str(k[0]); key.cube_size = 0.078
		key.position = Vector3(hx + float(k[2]), BELT_Y + .25, DEPTH * .5 + .034)
		key.pressed.connect(step.bind(int(k[1])))
		body.add_child(key)
		Vending._label(key, str(k[3]), Vector3(0, .105, .004), 34, .0013, IVORY)
	Vending._label(body, "STEP", Vector3(hx, BELT_Y + .09, DEPTH * .5 + .022), 20, .0012, Color("9fb3ae"))
	lever = LeverScene.instantiate() as Node3D
	lever.name = "RollLever"; lever.position = Vector3(-hx, BELT_Y + .22, DEPTH * .5 + .03); lever.scale = Vector3.ONE * 1.3
	body.add_child(lever)
	if lever.has_method("set_caption"): lever.set_caption("ROLL")
	if lever.has_method("set_readout_visible"): lever.set_readout_visible(false)
	Vending._label(body, "UP: LATER / DOWN: EARLIER", Vector3(-hx, BELT_Y + .025, DEPTH * .5 + .022), 15, .0012, Color("9fb3ae"))
	var light := OmniLight3D.new(); light.name = "BandLight"; light.light_color = Color("f3f7ff"); light.light_energy = .9
	light.omni_range = 1.6; light.position = Vector3(0, BELT_Y + .75, .25); light.shadow_enabled = false; body.add_child(light)
	_request(PICKABLE)
	_place(0.0)
	set_process(true)

func _collider(body: Node3D, at: Vector3, size: Vector3) -> void:
	var shape := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = size; shape.shape = bs; shape.position = at
	body.add_child(shape)

## One tray earlier (-1) or later (+1); the band rolls there.
func step(direction: int) -> void:
	if _rolling: return
	target = clampf(roundf(target) + float(direction), 0.0, float(last_start()))

## Straight to a timeline index (a probe; the editor).
func jump(index: int) -> void:
	target = float(clampi(index, 0, last_start())); pos = target
	_place(0.0)

func _process(delta: float) -> void:
	_place(delta)
	# the things lie still on their trays (Palle, 2026-11-21: "the object are floating; they must be freeze until
	# they are picked"): no turntable here, a band carries luggage, it does not display it
	for index in _glow.keys():
		_glow[index] = maxf(float(_glow[index]) - delta * .8, 0.0)
		var mat: StandardMaterial3D = trays.get(index, {}).get("spot")
		if mat != null:
			mat.emission_enabled = _glow[index] > 0.0; mat.emission = Color("f59e0b"); mat.emission_energy_multiplier = float(_glow[index]) * 2.0
		if _glow[index] <= 0.0 or mat == null: _glow.erase(index)

## Move the band (the lever while it is off its middle, else toward the step's target), then the slats and the trays.
func _place(delta: float) -> void:
	var angle: float = float(lever.get_angle_degrees()) if lever != null and lever.has_method("get_angle_degrees") else 0.0
	var limit: float = 45.0
	if lever != null and lever.get("hinge") != null: limit = maxf(absf(float(lever.hinge.hinge_limit_max)), 1.0)
	if absf(angle) > LEVER_DEAD:
		_rolling = true
		# the hinge's positive angle LOWERS the handle (measured, probe_prefab_belt check E): up is later
		var push: float = -signf(angle) * (absf(angle) - LEVER_DEAD) / maxf(limit - LEVER_DEAD, 1.0)
		pos = clampf(pos + push * ROLL_SPEED * delta, 0.0, float(last_start()))
		target = pos
	else:
		if _rolling:      # let go: the band comes to rest on the nearest tray
			_rolling = false
			target = roundf(pos)
		pos = move_toward(pos, target, STEP_SPEED * delta)
	# slats: fixed spacing, sliding with the band (a later tray moves left)
	var shift := fposmod(-pos * PITCH, SLAT)
	for i in _slats.size():
		var x: float = -BAND * .5 + shift + i * SLAT
		_slats[i].position.x = x
		_slats[i].visible = x <= BAND * .5
	# trays: the four on the band and whatever is inside a housing. A tray past a housing's end wall does not exist:
	# its pick shell would be a thing to grab in the open air beside the machine (the tower probe's box, 2026-11-21).
	var reach := BAND * .5 + HOUSING - .04 - (PITCH - .05) * .5
	var first := int(floor(pos)) - 2
	for index in range(first, first + POSITIONS + 5):
		if index < 0 or index >= timeline.size(): continue
		_request(Items.scene_for(str(timeline[index].get("token", ""))))
		var x: float = -BAND * .5 + PITCH * .5 + (float(index) - pos) * PITCH
		if absf(x) <= reach and not trays.has(index): _tray(index)
	var made_one := false
	for index in trays.keys():
		var t: Dictionary = trays[index]
		var node: Node3D = t.node
		var x: float = -BAND * .5 + PITCH * .5 + (float(index) - pos) * PITCH
		if absf(x) > reach:
			_turns.erase(t.get("turn")); node.queue_free(); trays.erase(index); continue
		node.position.x = x
		var on_band: bool = absf(x) < BAND * .5 - .08
		var shell: Node = t.get("shell")
		if shell != null and is_instance_valid(shell):
			for c in shell.get_children():
				if c is CollisionShape3D: (c as CollisionShape3D).disabled = not on_band   # nothing is taken out of a housing
		if not t.made and not made_one and _ready_to_make(Items.scene_for(str(timeline[index].get("token", "")))) and _ready_to_make(PICKABLE):
			_fill(index); made_one = true
	if _counter != null and timeline.size() > 0:
		var a := clampi(int(roundf(pos)), 0, timeline.size() - 1)
		var b := mini(a + POSITIONS, timeline.size())
		var words := "%d-%d OF %d" % [a + 1, b, timeline.size()]
		if given_floor >= 0: words += "  /  FLOOR %d" % given_floor
		if _counter.text != words: _counter.text = words

## A tray on the band: a grey tray with a rim and a tape on its front lip. Its thing is made later (_fill).
func _tray(index: int) -> void:
	var it: Dictionary = timeline[index]
	var state := state_of(it)
	var node := Node3D.new(); node.name = "Tray_%s" % str(it.id); node.position = Vector3(0, BELT_Y, 0); add_child(node)
	Vending._box(node, "TrayBase", Vector3(0, .012, 0), Vector3(PITCH - .08, .024, DEPTH - .2), TRAY)
	for s in [-1.0, 1.0]:
		Vending._box(node, "TrayRim", Vector3(s * (PITCH * .5 - .045), .035, 0), Vector3(.012, .046, DEPTH - .2), TRAY)
		Vending._box(node, "TrayRim", Vector3(0, .035, s * (DEPTH * .5 - .105)), Vector3(PITCH - .08, .046, .012), TRAY)
	var words: String = str(it.get("name", it.id)).get_slice(" - ", 0).to_upper()
	match state:
		"later":
			words = "FLOOR %d" % floor_of(it)
		"here":
			words += "\nGIVEN ON THIS FLOOR"
			if formula_here and Vending.tape_line(it) != "": words += "\n" + Vending.tape_line(it)
		_:
			var line: String = Vending.tape_line(it)
			if line != "": words += "\n" + line
	# the tape rides the tray's front rim, tilted up to the eye, and goes into the housing with the tray
	var lip := Node3D.new(); lip.name = "Lip"; lip.position = Vector3(0, .09, DEPTH * .5 - .05); lip.rotation.x = deg_to_rad(-52.0); node.add_child(lip)
	Vending._box(lip, "Tape", Vector3.ZERO, Vector3(PITCH - .05, .125, .004), IVORY if state != "later" else Color("6d6a62"))
	var print_ := Vending._label(lip, words, Vector3(0, 0, .003), 26, .001, INK)
	print_.name = "Print"; print_.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; print_.width = (PITCH - .07) / .001
	var spot_mat := StandardMaterial3D.new(); spot_mat.albedo_color = Color("2f3c41"); spot_mat.roughness = .7
	var spot := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = .15; cm.bottom_radius = .15; cm.height = .006; cm.radial_segments = 28
	spot.mesh = cm; spot.material_override = spot_mat; spot.position.y = .027; spot.name = "Spot"; node.add_child(spot)
	trays[index] = {"node": node, "state": state, "made": false, "id": str(it.id), "spot": spot_mat, "words": words}

## The tray's thing: a miniature in its own colours on a turntable with a pick shell round it, or a closed box.
func _fill(index: int) -> void:
	var t: Dictionary = trays[index]
	t.made = true
	var node: Node3D = t.node
	if t.state == "later":
		var box := Vending._box(node, "ClosedBox", Vector3(0, .03 + mini * .5, 0), Vector3.ONE * mini, CARD)
		box.rotation.y = .2
		Vending._box(box, "BoxTape", Vector3(0, mini * .5 + .001, 0), Vector3(mini * 1.002, .003, mini * .18), Color("d9c9a0"))
		return
	var turn := Node3D.new(); turn.name = "Turn"; turn.position = Vector3(0, .03, 0); turn.rotation.y = .45; node.add_child(turn)
	_turns.append(turn); t["turn"] = turn
	var n := _make_mini(str(t.id))
	if n != null:
		turn.add_child(n)
		_seat_later(n, turn)
	var shell := _shell(node)
	t["shell"] = shell; t["home"] = shell.transform
	shell.picked_up.connect(_on_picked_up.bind(index))

func _make_mini(id: String) -> Node3D:
	var it := Items.item(id)
	if it.is_empty(): return null
	var path := Items.scene_for(str(it.get("token", "")))
	if path == "" or not ResourceLoader.exists(path): return null
	var n: Node = (load(path) as PackedScene).instantiate()
	if not n is Node3D: n.free(); return null
	var cfg := Items.config_for(it, {})
	for k in cfg: n.set_meta("config_%s" % str(k), cfg[k])
	if n.has_method("apply_grid_config"): n.apply_grid_config(cfg)
	n.name = "Mini_" + id
	HandLib._make_inert(n)
	n.ready.connect(func(): HandLib._make_inert(n); Vending._quiet(n, false), CONNECT_ONE_SHOT)
	var size: Array = it.get("size", [0.1, 0.1, 0.1]); var side: float = maxf(maxf(float(size[0]), float(size[1])), float(size[2]))
	(n as Node3D).scale = Vector3.ONE * (mini / maxf(side, .01))
	return n

## Once the miniature has built itself: its base on the tray, centred (the vending machine's rule), and then OUT OF
## THE PHYSICS. A frozen RigidBody3D that rides a moving parent is written back by the physics server one step late,
## every step, so on a rolling band the thing slid off its tray and stayed off (Palle's picture, 2026-11-21: the
## warning triangle standing between two trays). process_mode DISABLED takes a body out of the simulation
## (CollisionObject3D.disable_mode REMOVE), and the thing is then only a picture that moves with its tray.
func _seat_later(n: Node3D, turn: Node3D) -> void:
	for i in 20: await get_tree().process_frame
	if not is_instance_valid(n) or not n.is_inside_tree(): return
	Vending._quiet(n, false)
	var b: AABB = Vending._bounds(n)
	if b.size.length() < .001:
		for m in n.find_children("*", "MeshInstance3D", true, false): (m as MeshInstance3D).visible = true
		Vending._quiet(n, false)
		b = Vending._bounds(n)
	HandLib._make_inert(n)
	n.process_mode = Node.PROCESS_MODE_DISABLED
	if b.size.length() < .001: return
	var centre := b.get_center()
	n.global_position += Vector3(turn.global_position.x - centre.x, turn.global_position.y - b.position.y, turn.global_position.z - centre.z)

## How far each made thing's picture is from the middle of its tray, metres (a probe's measure): {id: distance}.
func seat_errors() -> Dictionary:
	var out := {}
	for index in trays:
		var turn: Node3D = trays[index].get("turn")
		if turn == null or not is_instance_valid(turn): continue
		var b: AABB = Vending._bounds(turn)
		if b.size.length() < .001: continue
		var c := b.get_center()
		out[str(trays[index].id)] = Vector3(c.x - turn.global_position.x, b.position.y - turn.global_position.y, c.z - turn.global_position.z).length()
	return out

func _shell(holder: Node3D) -> RigidBody3D:
	var shell: RigidBody3D = (load(PICKABLE) as PackedScene).instantiate()
	for c in shell.get_children():
		if c is CollisionShape3D and (c as CollisionShape3D).shape == null: c.free()
	shell.name = "Pick"
	var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3.ONE * mini * 1.1; shape.shape = box; shell.add_child(shape)
	shell.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC; shell.freeze = true
	holder.add_child(shell); shell.position = Vector3(0, mini * .55 + .03, 0)
	return shell

## Grabbed: collected by every inventory hand, the tray's spot lights, the shell goes back to its tray.
func _on_picked_up(_what: Variant, index: int) -> void:
	var t: Dictionary = trays.get(index, {})
	var id := str(t.get("id", ""))
	var it := Items.item(id)
	if it.is_empty(): return
	var fresh := Items.collect(id)
	for h in get_tree().get_nodes_in_group("inventory_hands"):
		if h.has_method("collect"): h.collect(id)
	_glow[index] = 1.0
	var game := get_tree().get_first_node_in_group("void_game")
	if game != null and game.has_method("_notice"):
		var vr: bool = bool(game.get("vr"))
		var how := "Left stick click: choose\nTrigger: place / hold: move\nGrip: take back" if vr else "Tab: choose\nF: place / hold F: move\nX: take back"
		game._notice(("COLLECTED / " if fresh else "IN THE HAND / ") + str(it.get("name", id)).get_slice(" - ", 0) + "\n" + how)
	print("[prefab belt] %s (new %s)" % [id, fresh])
	_return_home.call_deferred(index)

func _return_home(index: int) -> void:
	var t: Dictionary = trays.get(index, {})
	var shell: RigidBody3D = t.get("shell") as RigidBody3D
	if shell == null or not is_instance_valid(shell): return
	if shell.has_method("is_picked_up") and shell.is_picked_up():
		var by: Node = shell.get_picked_up_by() if shell.has_method("get_picked_up_by") else null
		if by != null and by.has_method("drop_object"): by.drop_object()
		elif by != null: shell.let_go(by, Vector3.ZERO, Vector3.ZERO)
	await get_tree().physics_frame
	if not is_instance_valid(shell): return
	shell.linear_velocity = Vector3.ZERO; shell.angular_velocity = Vector3.ZERO
	shell.transform = t.home
	shell.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC; shell.freeze = true

func _request(path: String) -> void:
	if path == "" or _loading.has(path) or ResourceLoader.has_cached(path) or not ResourceLoader.exists(path): return
	if ResourceLoader.load_threaded_request(path, "PackedScene") == OK: _loading[path] = true

func _ready_to_make(path: String) -> bool:
	if path == "" or not _loading.has(path): return true
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS: return false
	if status == ResourceLoader.THREAD_LOAD_LOADED: ResourceLoader.load_threaded_get(path)
	_loading.erase(path)
	return true

func prepare_editor_preview() -> void:
	for i in 240:
		if window().all(func(w): return bool(w.made)): break
		await get_tree().process_frame
	for i in 22: await get_tree().process_frame

## The four trays on the band now: [{index, id, state, made, words}].
func window() -> Array:
	var out := []
	var a := int(roundf(pos))
	for index in range(a, mini(a + POSITIONS, timeline.size())):
		var t: Dictionary = trays.get(index, {})
		out.append({"index": index, "id": str(timeline[index].id), "state": state_of(timeline[index]), "made": bool(t.get("made", false)), "words": str(t.get("words", ""))})
	return out

func get_state() -> Dictionary:
	return {"given_floor": given_floor, "timeline": timeline.size(), "pos": pos, "target": target, "rolling": _rolling, "window": window(),
		"ids": timeline.map(func(it): return str(it.get("id", "")))}
