extends Node3D
## Hooke spring drives a real guided rigid piston. Contact launches the white
## balls. No ball velocity, path, logical result or target homing is prescribed.
const WhiteBalls = preload("res://commons/artifacts/surface_ball_test/surface_ball_test.gd")
const Handle = preload("res://commons/artifacts/matter_logic_spring/pull_handle.gd")
const Finish = preload("res://commons/artifacts/machine_finish.gd")
const BALL_LAYER := 1 << 25
const HEIGHT := .0336
const STROKE := .12
const STIFFNESS := 70.0
signal released
signal ball_contact(ball: Node3D,body: Node3D)
var lanes: Array[float] = [0.0]
var balls: Array[XRToolsPickable] = []
var supply: Node3D
var piston: RigidBody3D
var handle: XRToolsPickable
var anchor: StaticBody3D
var guide: SliderJoint3D
var coil: MeshInstance3D
var displacement := 0.0
var last_drawn := 100.0
var armed := false
var active := false
var resetting := false

func _ready() -> void:
	var steel := Finish.steel();var pink := Finish.pink()
	anchor = StaticBody3D.new();anchor.name = "FixedSpringAnchor";anchor.collision_layer = 0;add_child(anchor)
	for z in [-.5,.5] if lanes.size()>1 else [-.17,.17]:
		rod(self,Vector3(-.4,-.045,z),Vector3(.15,-.045,z),.016,steel)
	var back := MeshInstance3D.new();back.mesh = BoxMesh.new();back.mesh.size = Vector3(.035,.12,.11)
	back.position = Vector3(-.36,HEIGHT,0);back.material_override = steel;add_child(back)
	piston = RigidBody3D.new();piston.name = "ActualContactPiston";piston.mass = 2
	piston.gravity_scale = 0;piston.freeze = true;piston.continuous_cd = true;piston.can_sleep = false
	piston.collision_layer = BALL_LAYER;piston.collision_mask = BALL_LAYER;piston.linear_damp = .1
	piston.position = Vector3(0,HEIGHT,0);add_child(piston)
	var face := MeshInstance3D.new();face.mesh = BoxMesh.new()
	face.mesh.size = Vector3(.045,.055,.8 if lanes.size()>1 else .14);face.material_override = pink;piston.add_child(face)
	var hit := CollisionShape3D.new();hit.shape = BoxShape3D.new();hit.shape.size = face.mesh.size;piston.add_child(hit)
	guide = SliderJoint3D.new();guide.name = "OneAxisPistonGuide";guide.position = Vector3(0,HEIGHT,0);add_child(guide)
	guide.node_a = guide.get_path_to(anchor);guide.node_b = guide.get_path_to(piston)
	guide.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER,-STROKE)
	guide.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER,.06)
	guide.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_LOWER,0);guide.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_UPPER,0)
	coil = MeshInstance3D.new();coil.name = "VisibleCompressionSpring";coil.material_override = Finish.ivory();add_child(coil)
	handle = Handle.new();handle.machine = self;handle.name = "PinkPullHandle"
	handle.freeze = true;handle.collision_layer = 4;handle.collision_mask = 0;handle.picked_up_layer = 0
	handle.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	var handle_hit := CollisionShape3D.new();handle_hit.shape = SphereShape3D.new();handle_hit.shape.radius = .055;handle.add_child(handle_hit)
	var grip := MeshInstance3D.new();var cylinder := CylinderMesh.new();cylinder.top_radius = .035;cylinder.bottom_radius = .035;cylinder.height = .14
	grip.mesh = cylinder;grip.rotation.x = PI/2;grip.material_override = pink;handle.add_child(grip);add_child(handle)
	handle.dropped.connect(func(_body):
		if not resetting:fire())
	supply = WhiteBalls.new();supply.name = "OriginalWhiteGravityBalls";supply.radius = HEIGHT;supply.lifetime = 120;supply.drop_height = .1
	add_child(supply);supply.set_physics_process(false)
	reset_launcher()

func grip_position() -> Vector3:return Vector3(displacement,HEIGHT,.6 if lanes.size()>1 else .29)
func follow_handle(world: Vector3) -> void:
	if active:return
	compress(to_local(world).x)
func compress(value: float) -> void:
	if active:return
	displacement = clampf(value,-STROKE,0);armed = displacement<-.025
	piston.freeze = true;piston.position = Vector3(displacement,HEIGHT,0)
	PhysicsServer3D.body_set_state(piston.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,piston.global_transform)
	_draw_spring()
func cock() -> void:compress(-STROKE)
func fire() -> void:
	if active or not armed:return
	active = true;armed = false;piston.freeze = false;piston.sleeping = false;released.emit()
func reset_launcher() -> void:
	resetting = true
	if is_instance_valid(handle) and handle.is_picked_up():handle.drop()
	active = false;armed = false;displacement = 0;piston.freeze = true;piston.linear_velocity = Vector3.ZERO;piston.angular_velocity = Vector3.ZERO
	piston.position = Vector3(0,HEIGHT,0);PhysicsServer3D.body_set_state(piston.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,piston.global_transform)
	for ball in balls:
		if not is_instance_valid(ball):continue
		ball.collision_layer = 0;ball.collision_mask = 0
		if ball.is_picked_up():ball.drop()
		ball.queue_free()
	balls.clear();supply.balls.clear();supply.cooldown = 0
	var points: Array[Vector3] = []
	for z in lanes:points.append(Vector3(.08,HEIGHT,z))
	supply.drop(self,points)
	for original: RigidBody3D in supply.balls:
		var ball := XRToolsPickable.new();ball.name = "WhiteGravityBall";ball.mass = .04
		ball.transform = original.transform;ball.continuous_cd = true;ball.can_sleep = false
		ball.physics_material_override = original.physics_material_override.duplicate()
		ball.physics_material_override.bounce = .02;ball.physics_material_override.friction = .3
		ball.collision_layer = BALL_LAYER|4;ball.collision_mask = 1|BALL_LAYER
		ball.contact_monitor = true;ball.max_contacts_reported = 8;ball.linear_damp = .005;ball.angular_damp = .005
		ball.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE;ball.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
		for child in original.get_children():original.remove_child(child);ball.add_child(child)
		supply.remove_child(original);original.queue_free();supply.add_child(ball);balls.append(ball)
		ball.body_entered.connect(_contact.bind(ball))
	supply.balls.assign(balls)
	# Source supplies world poses. Explicitly place the real bodies in this
	# launcher's current frame, including after a saved move/turn.
	for i in balls.size():
		balls[i].global_position = to_global(points[i]);balls[i].global_basis = global_basis
		PhysicsServer3D.body_set_state(balls[i].get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,balls[i].global_transform)
	handle.position = grip_position();_draw_spring();resetting = false

func _contact(body: Node3D,ball: Node3D) -> void:ball_contact.emit(ball,body)

func _physics_process(_delta: float) -> void:
	if active:
		displacement = to_local(piston.global_position).x
		var axis := global_basis.x.normalized()
		var speed := piston.linear_velocity.dot(axis)
		piston.apply_central_force(axis*(-STIFFNESS*displacement-.6*speed))
	if not handle.is_picked_up():handle.position = grip_position()
	if absf(displacement-last_drawn)>.0005:_draw_spring()

func _draw_spring() -> void:
	last_drawn = displacement
	var surface := SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 80:
		for side in 6:
			var ring: Array[Vector3] = []
			for entry in [[i,side],[i+1,side],[i+1,side+1],[i,side+1]]:
				var t := float(entry[0])/80;var a := t*TAU*8;var b := float(entry[1])/6*TAU
				var centre := Vector3(lerpf(-.34,displacement-.03,t),HEIGHT+cos(a)*.025,sin(a)*.025)
				ring.append(centre+Vector3(cos(b),sin(b)*cos(a),sin(b)*sin(a))*.005)
			for vertex in [ring[0],ring[1],ring[2],ring[0],ring[2],ring[3]]:surface.add_vertex(vertex)
	surface.generate_normals();coil.mesh = surface.commit()

func rod(host: Node3D,a: Vector3,b: Vector3,radius: float,mat: Material) -> void:
	var m := MeshInstance3D.new();var c := CylinderMesh.new();c.top_radius = radius;c.bottom_radius = radius;c.height = a.distance_to(b);c.radial_segments = 12
	m.mesh = c;m.position = (a+b)*.5;m.quaternion = Quaternion(Vector3.UP,(b-a).normalized());m.material_override = mat;host.add_child(m)
