extends "res://commons/void/lines_area.gd"
## AND is a pair of missing supports. Only actual arrival of the released ball
## records a one; input flags never drive the ball or fabricate the result.
const Block = preload("res://commons/artifacts/primitive_encounters/platform_block.tscn")
const Ramp = preload("res://commons/artifacts/primitive_encounters/wedge_blocker.tscn")
const Plank = preload("res://commons/artifacts/line_relations_gallery/line_body.gd")
const BallBox = preload("res://commons/artifacts/matter_gates/ball_box.gd")
const ButtonScene = preload("res://commons/interactables/cube_button.tscn")
const BALL_LAYER := 1 << 25
# Dimensions are built in metres, including colliders. No scaled dynamic bodies.
const UNIT := .12
const TABLE_HEIGHT := .84
const Timber = preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
signal result_observed(inputs: Vector2i, arrived: bool)
signal interaction_completed
var lesson_complete := false
var required_observations: Dictionary = {}
var inputs := Vector2i.ZERO
var cubes: Array[RigidBody3D] = []
var gates: Array[Node3D] = []
var buttons: Array[Node3D] = []
var supply: Node3D
var ball: RigidBody3D
var ball_box: Node3D
var result_label: Label3D
var table: Label3D
var observations: Dictionary = {}
var running := false
var waiting := false
var wait_elapsed := 0.0
var elapsed := 0.0
var outcome := -1
var attempt_inputs := Vector2i.ZERO
var run_samples: Array[Vector3] = []
var receiver: Area3D
var wood: StandardMaterial3D
var fragment := false

func _ready() -> void:
	var catalogue: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/primitive-prefabs.json"))
	for definition in catalogue.prefabs:
		if definition.id=="matter_and":required_observations=definition.completion.observations
	wood=StandardMaterial3D.new()
	wood.albedo_texture=load("res://commons/void/textures/construction_wood.png")
	wood.roughness=.9
	_build_table()
	var ramp := Ramp.instantiate() as Node3D
	ramp.name="EntryWedge";ramp.position=on_table(Vector3(-4.6,1,-.5));ramp.scale=Vector3.ONE*UNIT;ramp.rotation_degrees.y=-90
	add_child(ramp)
	for entry in [["EntrySupport",-5.1],["LowWedgeSupport",-4.1]]:
		var block := Block.instantiate() as Node3D
		block.name=entry[0];block.platform_size=Vector3.ONE*UNIT;block.position=on_table(Vector3(float(entry[1]),0,-.5));add_child(block)
	track("EntryPlanks",-3.6,-2.13)
	track("MiddlePlanks",-1.07,1.07)
	track("ExitPlanks",2.13,6.0)
	for i in 2:
		var gate := Node3D.new();gate.name="InputX" if i==0 else "InputY"
		gate.position=on_table(Vector3(-1.6 if i==0 else 1.6,0,-.5));add_child(gate);gates.append(gate)
		var cube := RigidBody3D.new();cube.name="OneMetreCube";cube.position.y=2.8*UNIT
		cube.freeze=true;cube.mass=.5;cube.collision_layer=BALL_LAYER;cube.collision_mask=1|BALL_LAYER
		cube.continuous_cd=true;cube.linear_damp=.3;cube.angular_damp=.8
		# A guided vertical drop: gravity supplies all motion; rails prevent the
		# miniature cube from tumbling or snagging a deck edge. Jolt retains Y.
		cube.lock_rotation=true;cube.axis_lock_linear_x=true;cube.axis_lock_linear_z=true
		gate.add_child(cube)
		var visible_cube := Block.instantiate() as Node3D
		visible_cube.name="OriginalBuildingCube";visible_cube.platform_size=Vector3.ONE*UNIT;visible_cube.position.y=-.5*UNIT;cube.add_child(visible_cube)
		# Retain the source cube's mesh and exact box shape, replacing its static
		# holder with a rigid body. No second invisible support remains below it.
		var original_shape: BoxShape3D
		for node in visible_cube.find_children("*","CollisionShape3D",true,false):
			if node.shape is BoxShape3D: original_shape=node.shape.duplicate()
		for node in visible_cube.find_children("*","StaticBody3D",true,false): node.free()
		var collider := CollisionShape3D.new();collider.name="CubeCollision";collider.shape=original_shape;cube.add_child(collider)
		cubes.append(cube)
		var cable := rod_part(gate,"Suspension",Vector3(0,3.65,0),Vector3.UP,.7,"stick")
		cable.scale=Vector3(1,.6,.6)
		for side in [-1,1]:rod_part(gate,"GuideLeft" if side<0 else "GuideRight",Vector3(side*.64,1.75,-.64),Vector3.UP,3.4,"stick")
		caption(gate,"GateName","X" if i==0 else "Y",Vector3(0,3.75,.02)*UNIT,.0007)
	var beam := rod_part(self,"HangingBeam",Vector3(0,4.05,-2),Vector3.RIGHT,8,"beam")
	for x in [-3.5,3.5]:
		var light := OmniLight3D.new();light.name="WorkLightLeft" if x<0 else "WorkLightRight"
		light.position=Vector3(x,.1,1.5)*UNIT;light.light_color=Color("fff1d9");light.light_energy=.4;light.omni_range=2
		beam.add_child(light)
	for x in [-3.5,3.5]: rod_part(self,"CeilingTieLeft" if x<0 else "CeilingTieRight",Vector3(x,2.025,-2),Vector3.UP,4.05,"beam")
	for x in [-1.6,1.6]:rod_part(self,"SuspensionArmX" if x<0 else "SuspensionArmY",Vector3(x,4.05,-1.25),Vector3.BACK,1.5,"beam")
	var target := Block.instantiate() as Node3D
	target.name="ReceivingCube";target.platform_size=Vector3.ONE*UNIT;target.position=on_table(Vector3(6.5,0,-.5));add_child(target)
	for side in [-1,1]: rod_part(target,"TraySideLeft" if side<0 else "TraySideRight",Vector3(0,1.14,side*.43),Vector3.RIGHT,1,"plank")
	rod_part(target,"EndStop",Vector3(.46,1.13,0),Vector3.BACK,1,"plank").rotation.x=PI/2
	receiver=Area3D.new();receiver.name="ArrivalSensor";receiver.collision_layer=0;receiver.collision_mask=BALL_LAYER
	var sensing := CollisionShape3D.new();var sensor_box := BoxShape3D.new();sensor_box.size=Vector3(.65,.5,.65)*UNIT
	sensing.shape=sensor_box;receiver.add_child(sensing);target.add_child(receiver);receiver.position=Vector3(0,1.2,0)*UNIT
	receiver.body_entered.connect(_arrived)
	ball_box=BallBox.new();ball_box.name="BallRelease";ball_box.unit_size=UNIT;ball_box.position=on_table(Vector3(-5.43,1.9,-.5));add_child(ball_box)
	supply=ball_box.supply
	ball_box.ball_released.connect(_begin_observation)
	ball_box.ball_held.connect(_ball_held)
	var console := Node3D.new();console.name="Controls";console.position=Vector3(-.1,TABLE_HEIGHT+.1,.29);add_child(console)
	for i in 4:
		var button := ButtonScene.instantiate() as Node3D
		button.name=["X","Y","Release","Reset"][i];button.label=["X / DROP","Y / DROP","LIFT GATE","RESET"][i]
		button.position=Vector3(-.33+i*.22,0,0);button.cube_size=.065
		button.accent=Color("e8dfcc");button.cap_color=Color("292a29");console.add_child(button);buttons.append(button)
		if i<2: button.pressed.connect(toggle_gate.bind(i))
		elif i==2: button.pressed.connect(release_ball)
		else: button.pressed.connect(reset_gate)
	caption(console,"Title","MATTER / AND",Vector3(0,.38,-.02),.0013)
	result_label=caption(console,"ObservedResult","DROP X + Y. LIFT LEVER / DROP BALL.",Vector3(0,.24,.02),.00065)
	table=caption(self,"ObservedTable","",Vector3(.58,1.30,-.12),.00065)
	caption(self,"Instruction","TWO GAPS. TWO CUBES. ONE BALL.",Vector3(.08,.75,.431),.001)

	_refresh_table()
	_restock()
	for child in get_children():
		if child is Node3D:
			var bounds := _mesh_bounds(child,child)
			part_defaults[str(child.name)]={"position":[child.position.x,child.position.y,child.position.z],"rotation":[child.rotation_degrees.x,child.rotation_degrees.y,child.rotation_degrees.z],"bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]}

func on_table(at: Vector3) -> Vector3:
	return at*UNIT+Vector3.UP*TABLE_HEIGHT

func _rod_size(piece: Node3D, size: Vector3) -> void:
	# Bake dimensions into meshes/shapes, retaining unit physics-body transforms.
	piece.body_size=size
	piece.get_node("Skin").mesh=Timber.mesh(size) if piece.skin=="plank" else _box_mesh(size)
	piece.get_node("PickupBody").shape.size=size

func _box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new();mesh.size=size;return mesh

func _build_table() -> void:
	var top := Plank.new();top.name="Tabletop";top.skin="plank";top.span=1.8
	top.position=Vector3(.08,TABLE_HEIGHT-.03,0);add_child(top)
	top.enabled=false;top.freeze=true;top.collision_layer=1;top.collision_mask=0
	_rod_size(top,Vector3(1.8,.06,.85))
	for side in [-1,1]:
		var support := Block.instantiate() as Node3D
		support.name="TableSupportLeft" if side<0 else "TableSupportRight"
		support.platform_size=Vector3(.22,TABLE_HEIGHT-.06,.72)
		support.position=Vector3(.08+side*.6,0,0);add_child(support)

func track(title: String, first: float, last: float) -> void:
	var part := Node3D.new();part.name=title;part.position=on_table(Vector3((first+last)/2,.97,-.5));add_child(part)
	for i in 3: rod_part(part,"OriginalPlank%d"%i,Vector3(0,0,(i-1)*.25),Vector3.RIGHT,last-first,"plank")
	# At marble scale a millimetre of cube wobble can otherwise send the ball
	# sideways off the run. Visible timber curbs guide it only on solid decks;
	# they end at both input gaps, so missing supports still cause a real fall.
	for side in [-1,1]:
		var rail := rod_part(part,"MarbleCurbLeft" if side<0 else "MarbleCurbRight",Vector3.ZERO,Vector3.RIGHT,last-first,"plank")
		rail.position=Vector3(0,.03*UNIT+.0125,side*.045)
		_rod_size(rail,Vector3((last-first)*UNIT,.025,.006))
	# Real one-metre source cubes carry the fixed decks. Recess their bases
	# by the plank thickness so their tops meet the deck's underside exactly;
	# the running surface and both logical gaps retain their original heights.
	var count := maxi(1,floori(last-first))
	for i in count:
		var support := Block.instantiate() as Node3D
		support.name=title+"SupportCube%d"%(i+1)
		support.platform_size=Vector3.ONE*UNIT
		support.position=on_table(Vector3((first+last)/2+i-(count-1)*.5,-.06,-.5))
		add_child(support)

func rod_part(parent: Node3D, title: String, at: Vector3, axis: Vector3, length: float, skin_name: String) -> Node3D:
	var piece := Plank.new();piece.name=title;piece.skin=skin_name;piece.span=length*UNIT;piece.position=on_table(at) if parent==self else at*UNIT
	piece.quaternion=Quaternion(Vector3.RIGHT,axis);parent.add_child(piece)
	piece.enabled=false;piece.freeze=true;piece.collision_layer=1;piece.collision_mask=0
	_rod_size(piece,Vector3(piece.body_size.x,piece.body_size.y*UNIT,piece.body_size.z*UNIT))
	if skin_name=="plank":piece.get_node("Skin").material_override=wood
	return piece

func caption(parent: Node3D, title: String, text: String, at: Vector3, pixels: float) -> Label3D:
	var label := Label3D.new();label.name=title;label.text=text;label.position=at
	label.font_size=42;label.pixel_size=pixels;label.outline_size=0;label.modulate=Color("ece7d9")
	parent.add_child(label);return label

func toggle_gate(index: int) -> void:
	if fragment or running or waiting:return
	set_gate(index,inputs[index]==0)

func set_gate(index: int, filled: bool) -> void:
	if fragment or running or waiting:return
	inputs[index]=1 if filled else 0
	var cube := cubes[index]
	cube.freeze=true;cube.linear_velocity=Vector3.ZERO;cube.angular_velocity=Vector3.ZERO
	cube.transform=Transform3D(Basis.IDENTITY,Vector3(0,2.8*UNIT,0))
	# Releasing a suspended source cube lets gravity fill the actual opening.
	if filled:cube.freeze=false;cube.sleeping=false
	gates[index].get_node("Suspension").visible=not filled
	buttons[index].get_node("PushButton").set_selected(filled)
	result_label.text="X %d   Y %d / RELEASE TO OBSERVE"%[inputs.x,inputs.y]

func _restock() -> void:
	if not is_instance_valid(supply):return
	ball_box.reset_box()
	ball=ball_box.ball

func release_ball() -> void:
	if fragment or running or waiting or outcome>=0:return
	outcome=-1;waiting=true;wait_elapsed=0;attempt_inputs=inputs
	result_label.text="WAIT / CUBES SETTLING"

func _ball_held() -> void:
	if fragment:return
	running=false;waiting=false;outcome=-1
	result_label.text="DROP THE BALL ONTO THE WEDGE"

func _begin_observation() -> void:
	if fragment or running or outcome>=0 or ball_box.ball.is_picked_up():return
	ball=ball_box.ball
	waiting=false;running=true;elapsed=0;outcome=-1;attempt_inputs=inputs;run_samples.clear()
	result_label.text="OBSERVING THE BALL"

func reset_gate() -> void:
	if fragment:return
	running=false;waiting=false;outcome=-1;elapsed=0
	for i in 2:set_gate(i,false)
	_restock();result_label.text="DROP X + Y. LIFT LEVER / DROP BALL."

func _arrived(body: Node3D) -> void:
	if running and body==ball:_finish(true)

func _finish(arrived: bool) -> void:
	running=false;outcome=1 if arrived else 0
	observations["%d%d"%[attempt_inputs.x,attempt_inputs.y]]=outcome
	result_label.text="OBSERVED %d / %s"%[outcome,"BALL ARRIVED" if arrived else "BALL FELL / NO ARRIVAL"]
	_refresh_table();result_observed.emit(attempt_inputs,arrived)
	if not lesson_complete and not fragment and not required_observations.is_empty() and required_observations.keys().all(func(key):return observations.get(key,-1)==required_observations[key]):
		lesson_complete=true
		interaction_completed.emit()
		result_label.text += "\nAND STUDY COMPLETE"

func _refresh_table() -> void:
	var text := "X   Y    EXPECTED   OBSERVED\n"
	for x in 2:
		for y in 2:
			var key := "%d%d"%[x,y]
			text+="%d   %d          %d               %s\n"%[x,y,1 if x==1 and y==1 else 0,str(observations[key]) if observations.has(key) else "—"]
	table.text=text

func _physics_process(delta: float) -> void:
	if waiting:
		wait_elapsed+=delta
		if wait_elapsed>=1.2:
			waiting=false;ball_box.open_gate()
	if not running or not is_instance_valid(ball):return
	elapsed+=delta
	var local := to_local(ball.global_position);run_samples.append(local)
	if local.y<TABLE_HEIGHT+.5*UNIT or elapsed>15:_finish(false)

func apply_grid_config(config: Dictionary) -> void:
	super.apply_grid_config(config)
	fragment=["InputX","InputY","BallRelease","ReceivingCube","Controls"].any(func(key):return not has_node(NodePath(key)))
	if fragment:
		set_physics_process(false)
		return
	# The source supply is positioned by its editable release part on every take.
	_restock.call_deferred()
