extends "res://commons/artifacts/timing_machines/machine_stage.gd"
const CRAB = preload("res://commons/artifacts/arena_relation_lab/lesson_crab.gd")
const FOOD = preload("res://commons/artifacts/arena_relation_lab/lesson_food.gd")
const BEACONS := [Vector3(0,0.1,2.4),Vector3(3,0.1,1.6),Vector3(-3,0.1,1.6)]
var crab: MeshInstance3D
var food: Node3D
var beacon: MeshInstance3D
var use_visitor:=false
var beacon_index:=0
var screen_on:=false
var running:=false
var boundary:=false
var parts:=false
var rule:=false
var text_clock:=0.0
var banks: Array[Label3D]=[]
var board: Label3D
var screen: StaticBody3D
var screen_mesh: MeshInstance3D
var sight_line: MeshInstance3D
var preview: Dictionary={}
func _ready() -> void:
	box(Vector3(0,0.035,0),Vector3(11,0.07,11),material("354a53"))
	for x in range(-5,6):
		box(Vector3(x,0.078,0),Vector3(0.015,0.01,10),material("567078"))
		box(Vector3(0,0.078,x),Vector3(10,0.01,0.015),material("567078"))
	for edge in [-5.0,5.0]:
		box(Vector3(edge,0.09,0),Vector3(0.03,0.02,10),material("e8c377",true))
		box(Vector3(0,0.09,edge),Vector3(10,0.02,0.03),material("e8c377",true))
	beacon=box(BEACONS[0],Vector3(0.3,0.2,0.3),material("77d6e8",true))
	var caption=label("BEACON / a nominated visitor",Vector3(0,0.14,3.2),0.0011);caption.rotation_degrees.x=-90
	box(Vector3(-2,0.1,-1),Vector3(0.7,0.08,0.7),material("d9a0b4"))
	var food_label=label("FOOD",Vector3(-2,0.16,-1.6),0.0012);food_label.rotation_degrees.x=-90
	screen=StaticBody3D.new();screen.position=Vector3(0,0.7,0);add_child(screen)
	var col=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(2.4,1.4,0.16);col.shape=shape;screen.add_child(col)
	screen_mesh=box(screen.position,shape.size,material("997383"))
	for side in 2:
		var panel=preload("res://commons/artifacts/timing_machines/machine_stage.gd").new();add_child(panel);panel.position=Vector3(-2.3 if side==0 else 2.3,0,-4.5);panel.rotation.y=PI
		panel.console(["RUN","RESET","BEACON","VISITOR"] if side==0 else ["FOOD","SCREEN","PARTS","RULE"],0,"WHO COUNTS AS A TARGET?")
		banks.append(panel.readout)
		for id in panel.buttons:buttons[id]=panel.buttons[id];buttons[id].pressed.connect(act.bind(id))
	box(Vector3(0,3.1,5.2),Vector3(10.5,3.0,0.1),material("223740"))
	board=label("",Vector3(0,3.1,5.13),0.0022);board.rotation.y=PI
	sight_line=MeshInstance3D.new();sight_line.mesh=ImmediateMesh.new();sight_line.material_override=material("efcc89",true);add_child(sight_line)
	reset_experiment()
func recipient() -> Node3D:
	if not use_visitor:return beacon
	for group in ["em_walker","player_body","player"]:
		for node in get_tree().get_nodes_in_group(group):
			if node is Node3D:return node
	return null
func reset_experiment() -> void:
	running=false;boundary=false
	if is_instance_valid(food):food.queue_free()
	food=null
	if is_instance_valid(crab):remove_child(crab);crab.queue_free()
	crab=CRAB.new();crab.name="EncounterCrab";crab.station=self;crab.crab_scale=0.3;crab.can_bite=false;crab.patrol_speed=0;crab.chase_speed=0.8;crab.detect_m=6;crab.bait_range=6;crab.path_on=false;crab.sight_memory=0
	add_child(crab);crab.position=Vector3(0,0,-2.4);crab.set_process(false)
	# Learn the placed floor/feet once without advancing the encounter.
	crab._process(0.0);update_visuals();update_text()
func offer_food() -> void:
	if is_instance_valid(food) or crab._rooted:return
	food=FOOD.new();food.can_be_picked_up=false;add_child(food);food.position=Vector3(-2,0.1,-1)
func act(id: String) -> void:
	match id:
		"RUN":
			if not boundary:running=not running;crab.set_process(running)
		"RESET":reset_experiment()
		"BEACON":beacon_index=(beacon_index+1)%3;beacon.position=BEACONS[beacon_index]
		"VISITOR":use_visitor=not use_visitor
		"FOOD":offer_food()
		"SCREEN":screen_on=not screen_on
		"PARTS":parts=not parts
		"RULE":rule=not rule
	update_visuals();update_text()
func _process(delta: float) -> void:
	if running and (absf(crab.position.x)>5 or absf(crab.position.z)>5):boundary=true;running=false;crab.set_process(false)
	update_visuals();text_clock+=delta
	if text_clock>=0.1:text_clock=0;update_text()
func update_visuals() -> void:
	screen.collision_layer=1 if screen_on else 0;screen_mesh.visible=screen_on;beacon.visible=not use_visitor
	preview=crab.choose()
	sight_line.visible=parts
	var mesh: ImmediateMesh=sight_line.mesh;mesh.clear_surfaces()
	var selected=preview.get("node")
	if parts and is_instance_valid(selected):
		mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		var at=to_local(crab.global_position);at.y=0.25;var target=to_local(selected.global_position);target.y=0.25
		mesh.surface_add_vertex(at);mesh.surface_add_vertex(target);mesh.surface_end()
func update_text() -> void:
	var chosen=preview.get("node");var who="NONE"
	if is_instance_valid(chosen):who="FOOD" if chosen==food else ("YOU" if use_visitor else "BEACON")
	var state="STOPPED AT 5 MEALS" if crab._rooted else ("EATING" if crab._meal_t>0 else ("MOVING" if running else "PAUSED"))
	if not running and state!="PAUSED":state="PAUSED / "+state
	if boundary:state="OBSERVATION BOUNDARY"
	banks[0].text="%s / candidate: %s\nVISITOR: %s"%[state,who,"YOU" if use_visitor else "BEACON"]
	banks[1].text="Completed meals %d / 5\nMeal %.2f s / distance %s"%[crab._degree,maxf(0,crab._meal_t),("%.2f m"%float(preview["dist"])) if preview.has("dist") else "--"] if parts else "Change the encounter, then reveal.\nFOOD offers one mushroom at a time."
	board.text="RUN, then move BEACON or offer FOOD. Which way does it go?\nSCREEN blocks the low sight line; VISITOR lets you become the candidate.\nThis encounter has no bite. Food can still change its state."
	if rule:board.text="Nearest visible candidate within 6 m: FOOD and the nominated visitor.\nDistance is 3-D; sight rays are horizontal at floor + 0.20 m.\nNo sight memory here. Steering and gait write position; no body momentum.\nA meal takes 2 seconds. At five completed meals, movement is disabled."
	board.text+="\nGolden boundary pauses observation. RESET replaces this animal, retaining panel choices."
