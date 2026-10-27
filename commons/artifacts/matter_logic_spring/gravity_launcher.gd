extends Node3D
## A raised timber ramp stores gravitational potential. The pink handle lifts
## a stop: it does not push the balls or assign them a launch velocity.
const WhiteBalls = preload("res://commons/artifacts/surface_ball_test/surface_ball_test.gd")
const Handle = preload("res://commons/artifacts/matter_logic_spring/pull_handle.gd")
const Plank = preload("res://commons/artifacts/line_relations_gallery/line_body.gd")
const Block = preload("res://commons/artifacts/primitive_encounters/platform_block.tscn")
const Finish = preload("res://commons/artifacts/machine_finish.gd")
const Surface = preload("res://commons/artifacts/matter_logic_spring/logic_finish.gd")
const BALL_LAYER := 1 << 25
const HEIGHT := .0336
const RISE := .30
const RUN := 1.0
signal released
signal ball_contact(ball: Node3D,body: Node3D)
var lanes: Array[float] = [0.0]
var balls: Array[XRToolsPickable] = []
var supply: Node3D
var stop_body: RigidBody3D
var handle: XRToolsPickable
var displacement := 0.0
var armed := true
var active := false
var resetting := false
var wood: Material

func _ready() -> void:
	wood = Surface.wood()
	var angle := -atan2(RISE,RUN)
	for z in lanes:
		var wedge := Block.instantiate();wedge.kind = "wedge";wedge.name = "OriginalWedgeSupport"
		wedge.position = Vector3(.25,0,z);wedge.rotation.y = -PI/2;wedge.scale = Vector3(.20,RISE,RUN*.5);add_child(wedge)
		for mesh in wedge.find_children("*","MeshInstance3D",true,false):mesh.material_override = wood
		var ramp := plank("DownhillTimberRun",Vector3(.25,RISE*.5+.015,z),Vector3(Vector2(RUN,RISE).length(),.03,.20));ramp.rotation.z = angle
		for side in [-1,1]:
			var curb := plank("DownhillCurb",Vector3(.25,RISE*.5+.045,z+side*.115),Vector3(Vector2(RUN,RISE).length(),.035,.012));curb.rotation.z = angle;curb.get_node("Skin").material_override = Surface.metal()
	var steel := Surface.metal()
	for z in [-.5,.5] if lanes.size()>1 else [-.17,.17]:rod(self,Vector3(-.1,.16,z),Vector3(-.1,.61,z),.014,steel)
	stop_body = RigidBody3D.new();stop_body.name = "LiftableBallStop";stop_body.freeze = true;stop_body.gravity_scale = 0
	stop_body.collision_layer = BALL_LAYER;stop_body.collision_mask = BALL_LAYER;add_child(stop_body)
	var face := MeshInstance3D.new();face.mesh = BoxMesh.new();face.mesh.size = Vector3(.035,.18,.8 if lanes.size()>1 else .14)
	face.material_override = Finish.pink();stop_body.add_child(face)
	var hit := CollisionShape3D.new();hit.shape = BoxShape3D.new();hit.shape.size = face.mesh.size;stop_body.add_child(hit)
	handle = Handle.new();handle.machine = self;handle.name = "PinkLiftRelease"
	handle.freeze = true;handle.gravity_scale = 0;handle.release_mode = XRToolsPickable.ReleaseMode.FROZEN
	handle.collision_layer = 4 | (1 << 20);handle.collision_mask = 0;handle.picked_up_layer = 0;handle.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	var grip := MeshInstance3D.new();var cylinder := CylinderMesh.new();cylinder.top_radius = .035;cylinder.bottom_radius = .035;cylinder.height = .14
	grip.mesh = cylinder;grip.rotation.x = PI/2;grip.material_override = Finish.pink();handle.add_child(grip)
	var handle_hit := CollisionShape3D.new();handle_hit.shape = SphereShape3D.new();handle_hit.shape.radius = .055;handle.add_child(handle_hit);add_child(handle)
	handle.dropped.connect(func(_body):
		if not resetting and not active:_lift(0))
	supply = WhiteBalls.new();supply.name = "OriginalWhiteGravityBalls";supply.radius = HEIGHT;supply.lifetime = 120;supply.drop_height = .1
	add_child(supply);supply.set_physics_process(false);reset_launcher()

func plank(id: String,p: Vector3,size: Vector3) -> RigidBody3D:
	var piece := Plank.new();piece.name = id;piece.skin = "plank";piece.span = size.x;piece.position = p;add_child(piece)
	piece.enabled = false;piece.freeze = true;piece.collision_layer = 1;piece.collision_mask = BALL_LAYER
	piece.body_size = size;piece.get_node("Skin").mesh = load("res://commons/artifacts/primitive_encounters/timber_finish.gd").mesh(size)
	piece.get_node("Skin").material_override = wood;piece.get_node("PickupBody").shape.size = size;return piece
func grip_position() -> Vector3:return Vector3(-.1,.34+displacement,.6 if lanes.size()>1 else .29)
func _lift(value: float) -> void:
	displacement = clampf(value,0,.18);stop_body.position = Vector3(-.1,.34+displacement,0)
	PhysicsServer3D.body_set_state(stop_body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,stop_body.global_transform)
func follow_handle(world: Vector3) -> void:
	if active:return
	_lift(to_local(world).y-.34)
	if displacement>.12:release_balls()
func release_balls() -> void:
	if active or not armed:return
	_lift(.18);active = true;armed = false
	# The ball may have slept against the stop. Removing that support must
	# wake it so gravity, rather than an assigned launch velocity, starts it.
	for ball in balls:
		if is_instance_valid(ball):ball.sleeping=false
	released.emit()
func reset_launcher() -> void:
	resetting = true
	if handle.is_picked_up():handle.drop()
	active = false;armed = true;_lift(0)
	for ball in balls:
		if not is_instance_valid(ball):continue
		ball.collision_layer = 0;ball.collision_mask = 0
		if ball.is_picked_up():ball.drop()
		ball.queue_free()
	balls.clear();supply.balls.clear();supply.cooldown = 0
	var points: Array[Vector3] = []
	var centre_y := RISE*(.75+.18)/RUN+.015+.015*cos(atan2(RISE,RUN))+HEIGHT/cos(atan2(RISE,RUN))
	for z in lanes:points.append(Vector3(-.18,centre_y,z))
	supply.drop(self,points)
	for original: RigidBody3D in supply.balls:
		var ball := XRToolsPickable.new();ball.name = "WhiteGravityBall";ball.mass = .04
		# Let Jolt put a genuinely resting ball to sleep; otherwise tiny contact
		# jitter can keep cancelling the user's ten-second rest countdown.
		ball.continuous_cd = true;ball.can_sleep = true;ball.physics_material_override = original.physics_material_override.duplicate()
		ball.physics_material_override.bounce = .02;ball.physics_material_override.friction = .3
		ball.collision_layer = BALL_LAYER|4;ball.collision_mask = 1|BALL_LAYER;ball.contact_monitor = true;ball.max_contacts_reported = 8
		ball.linear_damp = .005;ball.angular_damp = .005;ball.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE;ball.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
		for child in original.get_children():original.remove_child(child);ball.add_child(child)
		supply.remove_child(original);original.queue_free();supply.add_child(ball);balls.append(ball);ball.body_entered.connect(_contact.bind(ball))
	supply.balls.assign(balls)
	for i in balls.size():
		balls[i].global_position = to_global(points[i]);balls[i].global_basis = global_basis
		PhysicsServer3D.body_set_state(balls[i].get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,balls[i].global_transform)
	handle.position = grip_position();resetting = false
func _contact(body: Node3D,ball: Node3D) -> void:ball_contact.emit(ball,body)
func _physics_process(_delta: float) -> void:
	if not handle.is_picked_up():handle.position = grip_position()
func rod(host: Node3D,a: Vector3,b: Vector3,radius: float,mat: Material) -> void:
	var m := MeshInstance3D.new();var c := CylinderMesh.new();c.top_radius = radius;c.bottom_radius = radius;c.height = a.distance_to(b);c.radial_segments = 12
	m.mesh = c;m.position = (a+b)*.5;m.quaternion = Quaternion(Vector3.UP,(b-a).normalized());m.material_override = mat;host.add_child(m)
