extends "res://commons/void/lines_area.gd"
## 2x the Cube-floor working parts, with the table and controls at human height.
## AND: serial supports. OR: two independently supported lanes/two test balls.
## NOT: an input lowers a real blocker. Outcomes come from impacts and falls;
## the expected truth table never drives a ball or fabricates an arrival.
const Block = preload("res://commons/artifacts/primitive_encounters/platform_block.tscn")
const Plank = preload("res://commons/artifacts/line_relations_gallery/line_body.gd")
const GravityRamp = preload("res://commons/artifacts/matter_logic_spring/gravity_launcher.gd")
const ButtonScene = preload("res://commons/interactables/cube_button.tscn")
const Finish = preload("res://commons/artifacts/machine_finish.gd")
const Surface = preload("res://commons/artifacts/matter_logic_spring/logic_finish.gd")
const ObjectTouch = preload("res://commons/interactables/object_touch.gd")
const RestReset = preload("res://commons/interactables/settled_ball_reset.gd")
const UNIT := .24
const TABLE_HEIGHT := .84
const DECK_Y := TABLE_HEIGHT+UNIT
const BALL_LAYER := 1 << 25
const READOUT_AT := Vector3(.8,1.76,-.62)
@export_enum("AND","OR","NOT") var operator := "AND"
@export var object_controls := true
@export_range(0,60,.5) var reset_after_rest := 10.0
signal result_observed(inputs: Vector2i,arrived: bool)
signal interaction_completed
var cubes: Array[RigidBody3D] = []
var gates: Array[Node3D] = []
var buttons: Dictionary = {}
var inputs := Vector2i.ZERO
var launcher: Node3D
var target: RigidBody3D
var result_label: Label3D
var truth_label: Label3D
var wood: Material
var observations: Dictionary = {}
var required_observations: Dictionary = {}
var attempt_inputs := Vector2i.ZERO
var running := false
var outcome := -1
var elapsed := 0.0
var lesson_complete := false
var fragment := false
var run_samples: Array = []
var input_joints: Array[SliderJoint3D] = []
var target_rest: Transform3D
var rest_reset: Node
var reset_countdown: Label3D

func front_offset() -> float:
	# Keep the outer OR lane and target bearings on the board while bringing
	# each narrower single-lane assembly closer to the same player-facing edge.
	return .24 if operator=="OR" else .50

func _ready() -> void:
	wood = Surface.wood()
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/primitive-prefabs.json"))
	for entry in catalogue.prefabs:
		if entry.id=="matter_spring_"+operator.to_lower():required_observations = entry.completion.observations
	build_table()
	match operator:
		"AND":
			track("EntryPlanks",-1.68,-.504,0);track("MiddlePlanks",-.264,.264,0);track("ExitPlanks",.504,1.55,0)
			input_cube("InputX",-.384,0);input_cube("InputY",.384,0)
		"OR":
			for z in [-.3,.3]:
				track("ParallelLeft" if z<0 else "ParallelRight",-1.68,-.12,z)
				track("ExitLeft" if z<0 else "ExitRight",.12,1.55,z)
			input_cube("InputX",0,-.3);input_cube("InputY",0,.3)
		"NOT":
			track("UnbrokenRun",-1.68,1.55,0);input_cube("InputX",0,0)
	var receiving := Node3D.new();receiving.name = "ImpactTarget";receiving.position.z=front_offset();add_child(receiving)
	target = plank(receiving,"EndTarget",Vector3(1.62,DECK_Y+.13,0),Vector3(.035,.24,.88 if operator=="OR" else .24))
	target.get_node("Skin").material_override = Finish.pink()
	target.mass = .025;target.gravity_scale = 1;target.can_sleep = false;target.continuous_cd = true
	target.collision_layer = 1|BALL_LAYER;target.collision_mask = 1|BALL_LAYER;target_rest = target.transform
	var foot := Block.instantiate();foot.name = "TargetPlinth";foot.platform_size = Vector3(.28,UNIT,.96 if operator=="OR" else .30);foot.position = Vector3(1.62,TABLE_HEIGHT,0);receiving.add_child(foot)
	var hinge_anchor := StaticBody3D.new();hinge_anchor.name = "FixedTargetAxle";hinge_anchor.collision_layer = 0;receiving.add_child(hinge_anchor)
	# Hang the paddle from its upper edge. Its lower edge clears the plinth,
	# so the mount cannot jam the very motion the impact is meant to reveal.
	var hinge := HingeJoint3D.new();hinge.name = "JoltImpactHinge";hinge.position = Vector3(1.62,DECK_Y+.25,0);receiving.add_child(hinge)
	hinge.node_a = hinge.get_path_to(hinge_anchor);hinge.node_b = hinge.get_path_to(target)
	hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR,false);hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT,true)
	hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER,-PI*.45);hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER,PI*.45)
	for z in [-.50,.50] if operator=="OR" else [-.20,.20]:
		var upright := plank(receiving,"AxleUpright",Vector3(1.62,TABLE_HEIGHT+.27,z),Vector3(.025,.54,.025));upright.get_node("Skin").material_override = Surface.metal()
	var axle := plank(receiving,"TargetAxle",Vector3(1.62,DECK_Y+.25,0),Vector3(.025,.025,1.08 if operator=="OR" else .48));axle.get_node("Skin").material_override = Surface.metal()
	# The hinge supplies the bearing. Its visible axle must not collide with
	# the paddle at the same pivot, which would lock the bearing solid.
	axle.collision_layer = 0;axle.collision_mask = 0
	target.freeze = false
	launcher = GravityRamp.new();launcher.name = "SpringLauncher";launcher.position = Vector3(-1.45,DECK_Y,front_offset())
	if operator=="OR":launcher.lanes.assign([-.3,.3])
	add_child(launcher);launcher.released.connect(_begin_observation);launcher.ball_contact.connect(_contact)
	build_controls()
	var readout := Node3D.new();readout.name = "Readout";readout.position = READOUT_AT;add_child(readout)
	var board_size := Vector3(1.8,.70,.035) if object_controls else Vector3(.76,.32,.035)
	var board := plank(readout,"SteelReadoutPanel",Vector3(0,0,-.035),board_size);board.get_node("Skin").material_override = Surface.metal()
	for x in [-.29,.29]:launcher.rod(readout,Vector3(x,-.92,-.06),Vector3(x,-.35 if object_controls else -.14,-.06),.014,Surface.metal())
	truth_label = caption(readout,"ObservedTruthTable","",Vector3.ZERO,.0009)
	_refresh_table()
	for child in get_children():
		if not child is Node3D:continue
		var b := _mesh_bounds(child,child)
		part_defaults[str(child.name)] = {"position":[child.position.x,child.position.y,child.position.z],"rotation":[0,0,0],"bounds":[b.position.x,b.position.y,b.position.z,b.size.x,b.size.y,b.size.z]}
	part_defaults.SpringLauncher.bounds = [-.3,0,-.55,1.1,.7,1.25]
	part_defaults.SpringLauncher.label = "Gravity ramp / lift release"
	if object_controls:
		part_defaults.Controls.bounds=[-.9,-.34,0,1.8,.68,.015]
		part_defaults.Controls.label="Title, instructions and rest timer / on binary readout"
	set_meta("void_preview_kind","Real double-size construction parts, guided input cubes, downhill ramps and white source balls held by a liftable stop. Gravity supplies motion; actual target impacts/falls record outcomes. Static editor pose.")

func build_table() -> void:
	var table := Node3D.new();table.name = "TableAndSupports";add_child(table)
	for z in [-.54,0,.54]:plank(table,"TimberPlatformBoard",Vector3(0,TABLE_HEIGHT-.03,z),Vector3(3.6,.06,.528))
	for z in [-.67,.67]:
		var rail := plank(table,"SteelBearer",Vector3(0,TABLE_HEIGHT-.095,z),Vector3(3.55,.07,.045));rail.get_node("Skin").material_override = Surface.metal()
	for x in [-1.2,1.2]:
		var b := Block.instantiate() as Node3D;b.name = "ConcreteSupportLeft" if x<0 else "ConcreteSupportRight"
		b.platform_size = Vector3(.50,TABLE_HEIGHT-.13,1.15);b.position = Vector3(x,0,0);table.add_child(b)
		var bearer := plank(table,"SteelCrossBearer",Vector3(x,TABLE_HEIGHT-.095,0),Vector3(.055,.07,1.42));bearer.get_node("Skin").material_override = Surface.metal()
	var screw_points: Array[Vector3] = []
	for x in [-1.65,-1.2,1.2,1.65]:
		for z in [-.67,.67]:screw_points.append(Vector3(x,TABLE_HEIGHT+.003,z))
	Surface.bolts(table,screw_points)

func track(id: String,a: float,b: float,z: float) -> void:
	var part := Node3D.new();part.name = id;part.position.z=front_offset();add_child(part)
	for dz in [-.06,0,.06]:plank(part,"OriginalPlank",Vector3((a+b)*.5,DECK_Y-.0072,z+dz),Vector3(b-a,.0144,.06))
	# Recess the rail ends from each slot so a falling support does not sit
	# on top of the curb. The running planks still meet the cube's top.
	for side in [-1,1]:plank(part,"TimberCurb",Vector3((a+b)*.5,DECK_Y+.0175,z+side*.103),Vector3(b-a-.07,.035,.012))
	var support := Block.instantiate() as Node3D;support.name = "VisibleSupportCube"
	var length := b-a
	support.platform_size = Vector3(minf(.24,length),UNIT-.0144,.18);support.position = Vector3((a+b)*.5,TABLE_HEIGHT,z)
	part.add_child(support)

func input_cube(id: String,x: float,z: float) -> void:
	var part := Node3D.new();part.name = id;part.position = Vector3(x,TABLE_HEIGHT,z+front_offset());add_child(part);gates.append(part)
	var body := RigidBody3D.new();body.name = "GuidedInputCube";body.mass = .5;body.freeze = true
	body.collision_layer = BALL_LAYER;body.collision_mask = 1|BALL_LAYER;body.continuous_cd = true
	body.position.y = 2.8*UNIT;part.add_child(body)
	var original := Block.instantiate() as Node3D;original.name = "OriginalBuildingCube";original.platform_size = Vector3.ONE*UNIT
	original.position.y = -.5*UNIT;body.add_child(original)
	var cube_skin: MeshInstance3D = original.get_node("Platform");cube_skin.material_override = Finish.ivory();Finish.outline(cube_skin,UNIT)
	var shape: BoxShape3D
	for c in original.find_children("*","CollisionShape3D",true,false):
		if c.shape is BoxShape3D:shape = c.shape.duplicate()
	# Three-millimetre assembly clearance on the guided cube's sides.
	shape.size.x -= .006;shape.size.z -= .006
	for c in original.find_children("*","StaticBody3D",true,false):c.free()
	var hit := CollisionShape3D.new();hit.shape = shape;body.add_child(hit);cubes.append(body)
	var anchor := StaticBody3D.new();anchor.name = "FixedGuideAnchor";anchor.collision_layer = 0;part.add_child(anchor)
	var guide := SliderJoint3D.new();guide.name = "JoltVerticalGuide";guide.position = Vector3(0,2.8*UNIT,0);guide.rotation.z = PI/2;part.add_child(guide)
	guide.node_a = guide.get_path_to(anchor);guide.node_b = guide.get_path_to(body)
	guide.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER,-2.3*UNIT);guide.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER,0)
	guide.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_LOWER,0);guide.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_UPPER,0);input_joints.append(guide)
	for dx in [-.16,.16]:
		var rail := plank(part,"VisibleGuide",Vector3(dx,.39,-.15),Vector3(.022,.8,.022));rail.get_node("Skin").material_override = Surface.metal()
	var tie := plank(part,"SupportTie",Vector3(0,.8,-.15),Vector3(.38,.04,.04));tie.get_node("Skin").material_override = Surface.metal()
	caption(part,"InputName",id.trim_prefix("Input"),Vector3(0,.87,0),.0012)

func plank(host: Node3D,id: String,p: Vector3,size: Vector3) -> RigidBody3D:
	var piece := Plank.new();piece.name = id;piece.skin = "plank";piece.span = size.x;piece.position = p;host.add_child(piece)
	piece.enabled = false;piece.freeze = true;piece.collision_layer = 1;piece.collision_mask = BALL_LAYER
	piece.body_size = size;piece.get_node("Skin").mesh = load("res://commons/artifacts/primitive_encounters/timber_finish.gd").mesh(size)
	piece.get_node("Skin").material_override = wood;piece.get_node("PickupBody").shape.size = size
	return piece

func build_controls() -> void:
	if object_controls:
		build_object_controls()
		return
	var console := Node3D.new();console.name = "Controls";console.position = Vector3(0,1.02,.67);add_child(console)
	var plate := plank(console,"SteelControlNamePlate",Vector3(0,.265,-.065),Vector3(.96,.27,.035));plate.get_node("Skin").material_override = Surface.metal()
	var names: Array = ["X","RELEASE","RESET"] if operator=="NOT" else ["X","Y","RELEASE","RESET"]
	for i in names.size():
		var name: String = names[i];var button: Node3D = ButtonScene.instantiate();button.name = name;button.label = name
		button.position.x = (i-(names.size()-1)*.5)*.22;button.cube_size = .075
		button.accent = Finish.IVORY;button.cap_color = Finish.PINK if name!="RESET" else Finish.STEEL;button.plate_color = Color("343944");button.frame_color = Color("191d26");console.add_child(button);buttons[name] = button
		for label in button.get_children():
			if label is Label3D:label.modulate = Finish.IVORY
		match name:
			"X":button.pressed.connect(toggle_input.bind(0))
			"Y":button.pressed.connect(toggle_input.bind(1))
			"RELEASE":button.pressed.connect(release_balls)
			"RESET":button.pressed.connect(reset_gate)
	caption(console,"GateName","MATTER / "+operator+" / GRAVITY",Vector3(0,.35,-.02),.0013)
	result_label = caption(console,"ObservedResult","SET INPUTS / LIFT TO RELEASE",Vector3(0,.19,.02),.0008)

func build_object_controls() -> void:
	# Titles and live instructions share the binary-results board behind the
	# mechanism. Keep the editable Controls label group; no front plate remains.
	var host := Node3D.new();host.name="Controls";host.position=READOUT_AT;add_child(host)
	caption(host,"GateName",operator+" / TOUCH CUBES · LIFT BALL STOP",Vector3(0,.265,.006),.00065)
	result_label=caption(host,"ObservedResult","SET INPUTS / LIFT TO RELEASE",Vector3(0,-.205,.006),.00065)
	reset_countdown=caption(host,"RestCountdown","RESET / 10 s AFTER BALLS REST",Vector3(0,-.285,.006),.00055)
	for i in cubes.size():
		var touch := ObjectTouch.new();touch.name="TouchInput"
		touch.available=func():return not fragment and not running and outcome==-1
		var shape := CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=Vector3.ONE*(UNIT+.03)
		touch.add_child(shape);cubes[i].add_child(touch);touch.touched.connect(toggle_input.bind(i))
	rest_reset=RestReset.new();rest_reset.name="ResetAfterBallRest";rest_reset.wait_seconds=reset_after_rest
	rest_reset.balls=func():return launcher.balls.duplicate()
	rest_reset.take_started=func():return not fragment and launcher.active
	rest_reset.interaction_busy=func():return launcher.handle.is_picked_up() or launcher.handle.is_dragging()
	rest_reset.restore=reset_gate
	rest_reset.countdown_changed.connect(func(seconds):
		if is_instance_valid(reset_countdown):reset_countdown.text="RESET IN %.0f s"%ceilf(seconds) if seconds>=0 else "RESET / %.0f s AFTER BALLS REST"%reset_after_rest)
	add_child(rest_reset)

func caption(host: Node3D,id: String,text: String,p: Vector3,pixels: float) -> Label3D:
	var label := Label3D.new();label.name = id;label.text = text;label.position = p;label.font_size = 42;label.pixel_size = pixels;label.outline_size = 0;label.modulate = Finish.IVORY;host.add_child(label);return label

func toggle_input(index: int) -> void:set_input(index,inputs[index]==0)
func set_input(index: int,on: bool) -> void:
	if fragment or running:return
	inputs[index] = 1 if on else 0
	var body := cubes[index];body.freeze = true;body.linear_velocity = Vector3.ZERO;body.angular_velocity = Vector3.ZERO
	body.position = Vector3(0,2.8*UNIT,0);PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	if on:body.freeze = false;body.sleeping = false
	var key := "X" if index==0 else "Y"
	if buttons.has(key):buttons[key].get_node("PushButton").set_selected(on)
func release_balls() -> void:
	if not fragment and not running and outcome==-1:launcher.release_balls()
func reset_gate() -> void:
	if fragment:return
	running = false;outcome = -1;elapsed = 0
	target.freeze = true;target.transform = target_rest;target.linear_velocity = Vector3.ZERO;target.angular_velocity = Vector3.ZERO
	PhysicsServer3D.body_set_state(target.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,target.global_transform);target.freeze = false;target.sleeping = false
	for i in cubes.size():
		set_input(i,false)
		var touch := cubes[i].get_node_or_null("TouchInput")
		if touch != null:touch.rearm()
	launcher.reset_launcher();result_label.text = "SET INPUTS / LIFT TO RELEASE"
func _begin_observation() -> void:
	if fragment:return
	running = true;outcome = -1;elapsed = 0;attempt_inputs = inputs;run_samples.clear();result_label.text = "OBSERVING REAL BALL CONTACTS"
func _contact(ball: Node3D,body: Node3D) -> void:
	if not running or ball not in launcher.balls:return
	if body==target:_finish(true,"END TARGET HIT")
	elif operator=="NOT" and body==cubes[0]:_finish(false,"INPUT BLOCKER HIT")
func _finish(arrived: bool,evidence: String) -> void:
	running = false;outcome = 1 if arrived else 0
	var key := str(attempt_inputs.x) if operator=="NOT" else "%d%d"%[attempt_inputs.x,attempt_inputs.y]
	observations[key] = outcome;result_label.text = "OBSERVED %d / %s"%[outcome,evidence];_refresh_table();result_observed.emit(attempt_inputs,arrived)
	if not lesson_complete and not required_observations.is_empty() and required_observations.keys().all(func(k):return observations.get(k,-1)==required_observations[k]):
		lesson_complete = true;interaction_completed.emit();result_label.text += "\nREUSABLE ASSEMBLY EARNED"
func _refresh_table() -> void:
	var text := "INPUT   EXPECTED   OBSERVED\n"
	for key in required_observations:
		text += "%s          %d             %s\n"%[key,required_observations[key],str(observations[key]) if observations.has(key) else "—"]
	truth_label.text = text
func _physics_process(delta: float) -> void:
	# Once released, input bodies remain dynamic. Jolt joints supply the stops;
	# no per-frame pose correction or completion flag can move a test object.
	if not running:return
	elapsed += delta;var fallen := 0
	var sample: Array = []
	for ball in launcher.balls:
		var p := to_local(ball.global_position);sample.append([p.x,p.y,p.z])
		if p.y<TABLE_HEIGHT+.5*UNIT:fallen += 1
		if ball.is_picked_up():running = false;outcome = -2;result_label.text = "BALL TAKEN / RESET TO RETRY";return
	run_samples.append(sample)
	if fallen==launcher.balls.size():_finish(false,"BALL FELL THROUGH OPEN ROUTE")
	elif elapsed>18:running = false;outcome = -2;result_label.text = "NO RESULT / STALLED. RESET TO RETRY."
func apply_grid_config(config: Dictionary) -> void:
	super.apply_grid_config(config)
	reset_after_rest=clampf(float(config.get("reset_after_rest",reset_after_rest)),0,60)
	if is_instance_valid(rest_reset):rest_reset.wait_seconds=reset_after_rest
	fragment = ["SpringLauncher","ImpactTarget","Controls","TableAndSupports"].any(func(key):return not has_node(NodePath(key))) or not has_node("InputX") or (operator!="NOT" and not has_node("InputY"))
	if fragment:set_physics_process(false)
	else:launcher.reset_launcher.call_deferred()
func prepare_editor_preview() -> void:
	set_physics_process(false)
	if is_instance_valid(rest_reset):rest_reset.set_physics_process(false)
	if fragment:return
	reset_gate();target.freeze = true;launcher.set_physics_process(false)
	for ball in launcher.balls:ball.freeze = true
	await get_tree().process_frame
