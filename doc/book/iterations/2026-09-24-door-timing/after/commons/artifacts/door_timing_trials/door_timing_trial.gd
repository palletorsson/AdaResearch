extends Node3D
## Two choices, one short route. Timing is retained as separate DRAW/CHOOSE/REVEAL events.
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
enum Schedule { SHOWN_FIRST, DRAWN_AFTER, HIDDEN_FIRST }
@export var schedule: Schedule = Schedule.SHOWN_FIRST
@export var run_seed: int = 39017
const INK := Color(0.085,0.13,0.17)
const CHALK := Color(0.92,0.92,0.85)
const CYAN := Color(0.24,0.76,0.80)
const AMBER := Color(0.98,0.68,0.26)
signal trial_changed(state: Dictionary)
var rng := RandomNumberGenerator.new()
var short_door := -1
var chosen := -1
var revealed := false
var draws := 0
var round_id := 0
var ready_to_walk := false
var events: Array[String] = []
var event_labels: Array[Label3D] = []
var choice_labels: Array[Label3D] = []
var entries: Array[MeshInstance3D] = []
var entry_locks: Array[CollisionShape3D] = []
var shortcuts: Array[MeshInstance3D] = []
var shortcut_locks: Array[CollisionShape3D] = []
var triggers: Array[Area3D] = []
var occupancy: Area3D
var status: Label3D
var motion: Tween
var museum: Node

func _ready() -> void:
	museum = get_parent()
	while museum != null and not museum.has_method("_basin_burned"): museum = museum.get_parent()
	_build()
	_begin_round()

func lane_x(index: int) -> float:
	return 0.70 if index == 0 else -0.70

func _build() -> void:
	var colour: Color = [CYAN,AMBER,Color(0.95,0.43,0.64)][schedule]
	# Opaque partitions keep an unrevealed outcome from leaking through the architecture.
	for x in [-2.45,2.45]:
		Stage.box(self,Vector3(x,1.35,-0.8),Vector3(0.10,2.7,3.4),INK,true)
		Stage.box(self,Vector3(x,2.75,-0.8),Vector3(0.14,0.08,3.6),colour)
		# Seal the outside corridors at their front; enter via the chosen inner lane.
		Stage.box(self,Vector3(signf(x)*1.90,1.35,-2.45),Vector3(1.1,2.7,0.10),INK,true)
	Stage.box(self,Vector3(0,1.35,-0.85),Vector3(0.10,2.7,3.20),INK,true)
	for side in [-1.0,1.0]:
		# Gap at z=-1.15 leads out to a longer path around the blocked shortcut.
		Stage.box(self,Vector3(side*1.35,1.35,-2.075),Vector3(0.10,2.7,0.75),CHALK,true)
		Stage.box(self,Vector3(side*1.35,1.35,0.15),Vector3(0.10,2.7,1.30),CHALK,true)
		Stage.box(self,Vector3(side*1.90,0.012,-0.4),Vector3(0.08,0.02,3.0),colour)
		Stage.box(self,Vector3(side*1.35,0.012,-1.12),Vector3(1.10,0.02,0.08),colour)
		Stage.box(self,Vector3(side*1.35,0.012,1.10),Vector3(1.10,0.02,0.08),colour)
	for i in range(2):
		var x := lane_x(i)
		Stage.box(self,Vector3(x,0.012,-1.35),Vector3(0.08,0.02,4.30),colour)
		Stage.box(self,Vector3(x,2.65,-2.45),Vector3(1.35,0.25,0.28),INK,true)
		var door := Stage.box(self,Vector3(x,1.20,-2.45),Vector3(1.24,2.4,0.14),colour,true)
		door.name = "Entry%d" % i
		entries.append(door);entry_locks.append(door.find_children("*","CollisionShape3D",true,false)[0])
		var short_gate := Stage.box(self,Vector3(x,1.20,0.0),Vector3(1.26,2.4,0.14),INK,true)
		short_gate.name = "Shortcut%d" % i
		shortcuts.append(short_gate);shortcut_locks.append(short_gate.find_children("*","CollisionShape3D",true,false)[0])
		var marker := Stage.box(self,Vector3(x,0.025,-3.28),Vector3(1.20,0.04,0.72),colour)
		marker.name = "ChoicePlate%d" % i
		var plate := _label("A" if i == 0 else "B",Vector3(x,0.049,-3.28),0.15)
		plate.rotation_degrees.x = -90
		choice_labels.append(_label("",Vector3(x,2.80,-2.62),0.058))
		var area := Area3D.new();area.name = "Choice%d" % i
		area.position = Vector3(x,1.0,-3.28);area.collision_layer = 0;area.collision_mask = 1 | 524288
		var shape := CollisionShape3D.new();var bounds := BoxShape3D.new();bounds.size = Vector3(1.20,2.2,0.72);shape.shape = bounds;area.add_child(shape);add_child(area)
		area.body_entered.connect(_on_choice_body.bind(i));triggers.append(area)
	Stage.box(self,Vector3(0,3.27,-2.46),Vector3(4.90,0.66,0.16),INK)
	var titles := ["SHOWN FIRST","DRAWN AFTER","HIDDEN FIRST"]
	_label(titles[schedule],Vector3(0,3.47,-2.56),0.10)
	for i in range(3):
		Stage.box(self,Vector3((1-i)*1.50,3.15,-2.56),Vector3(1.42,0.23,0.025),Color(0.19,0.25,0.27))
		event_labels.append(_label("",Vector3((1-i)*1.50,3.15,-2.58),0.049))
	status = _label("",Vector3(0,2.97,-2.58),0.035)
	var panel := Rack.create_panel("",[[{"type":"button","label":"REPLAY"},{"type":"button","label":"NEW ROUND"}]],true)
	panel.name = "RoundControls";panel.position = Vector3(2.00,1.04,-3.65);panel.rotation = Vector3(deg_to_rad(-50),PI,0);panel.scale = Vector3.ONE*1.8;add_child(panel)
	Stage.box(self,Vector3(2.00,0.45,-3.60),Vector3(0.30,0.90,0.22),INK,true)
	panel.find_child("Btn_0",true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b): replay())
	panel.find_child("Btn_1",true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b): new_round())
	var instruction := _label("STEP ON A PLATE TO CHOOSE",Vector3(0,0.035,-4.15),0.09)
	instruction.rotation_degrees.x = -90
	occupancy = Area3D.new();occupancy.name = "OccupiedRoute";occupancy.position = Vector3(0,1.2,-0.10);occupancy.collision_layer = 0;occupancy.collision_mask = 1 | 524288
	var shape := CollisionShape3D.new();var bounds := BoxShape3D.new();bounds.size = Vector3(4.85,3.2,5.40);shape.shape = bounds;occupancy.add_child(shape);add_child(occupancy)
	occupancy.body_exited.connect(func(_body): call_deferred("_refresh_route_notice"))

func _label(text: String, pos: Vector3, height: float) -> Label3D:
	var node := Label3D.new();node.text = text;node.position = pos;node.rotation.y = PI;node.font_size = 44;node.pixel_size = height/44.0;node.outline_size = 4;add_child(node);return node

func is_player(body: Node) -> bool:
	if museum != null:
		var walker = museum.get("_player")
		if walker != null and body == walker: return true
	return body.is_in_group("player") or body.is_in_group("player_body") or body.is_in_group("vr_player")

func _on_choice_body(body: Node3D, index: int) -> void:
	if is_player(body): choose(index)

func occupied() -> bool:
	for body in occupancy.get_overlapping_bodies():
		if is_player(body): return true
	return false

func _refresh_route_notice() -> void:
	if ready_to_walk and not occupied():
		status.text = "DIRECT PASSAGE" if chosen == short_door else "AROUND THE WALL / follow the floor line"

func replay() -> bool:
	if occupied():
		status.text = "LEAVE THE ROUTE BEFORE RESET"
		return false
	_begin_round()
	return true

func new_round() -> bool:
	if occupied():
		status.text = "LEAVE THE ROUTE BEFORE RESET"
		return false
	var source := RandomNumberGenerator.new();source.randomize()
	var next_seed := run_seed
	while next_seed == run_seed: next_seed = source.randi_range(10000,99999)
	run_seed = next_seed
	_begin_round()
	return true

func _begin_round() -> void:
	round_id += 1
	if motion != null: motion.kill()
	motion = null
	rng.seed = run_seed
	short_door = -1;chosen = -1;revealed = false;draws = 0;ready_to_walk = false;events.clear()
	for i in range(2):
		entries[i].position.y = 1.20;shortcuts[i].position.y = 1.20
		entry_locks[i].set_deferred("disabled",false);shortcut_locks[i].set_deferred("disabled",false)
	if schedule != Schedule.DRAWN_AFTER: _draw()
	if schedule == Schedule.SHOWN_FIRST: _reveal()
	_update_labels()
	status.text = "SEED %d / choose by stepping onto A or B" % run_seed

func _draw() -> void:
	short_door = rng.randi_range(0,1)
	draws += 1
	events.append("DRAW")

func _reveal() -> void:
	revealed = true
	events.append("REVEAL")

func choose(index: int) -> bool:
	if index < 0 or index > 1 or chosen != -1: return false
	chosen = index
	events.append("CHOOSE "+("A" if index == 0 else "B"))
	if schedule == Schedule.DRAWN_AFTER: _draw()
	if not revealed: _reveal()
	_update_labels()
	status.text = "OPENING / wait for the panel"
	motion = create_tween().set_parallel(true)
	motion.tween_property(entries[index],"position:y",3.90,0.80)
	if index == short_door: motion.tween_property(shortcuts[index],"position:y",3.90,0.80)
	motion.set_parallel(false)
	motion.tween_callback(_opened)
	trial_changed.emit(get_state())
	return true

func _opened() -> void:
	entry_locks[chosen].set_deferred("disabled",true)
	if chosen == short_door: shortcut_locks[chosen].set_deferred("disabled",true)
	ready_to_walk = true;motion = null
	status.text = "DIRECT PASSAGE" if chosen == short_door else "AROUND THE WALL / follow the floor line"
	trial_changed.emit(get_state())

func _update_labels() -> void:
	for i in range(3):event_labels[i].text = "%d / %s"%[i+1,events[i]] if i < events.size() else "%d / ..."%(i+1)
	for i in range(2):
		choice_labels[i].text = ("A" if i == 0 else "B")+" / "+(("DIRECT" if i == short_door else "AROUND") if revealed else "?")

func get_state() -> Dictionary:
	return {"schedule":schedule,"seed":run_seed,"round":round_id,"short_door":short_door,"chosen":chosen,"revealed":revealed,"draws":draws,"ready":ready_to_walk,"events":events.duplicate(),"route":"unselected" if chosen < 0 else ("direct" if chosen == short_door else "around")}
