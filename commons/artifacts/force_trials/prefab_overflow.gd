extends "res://commons/artifacts/force_play/play_space.gd"
## A moving contact surface, a hand-pulled hinge and a rocking receiver.
## No scripted catastrophe: prop contacts make the pile and move the receiver.
const PROP=preload("res://commons/artifacts/force_trials/overflow_prop.gd")
const CAPACITY=32
const INLET=Vector3(-0.8,3.6,-3.0)
var cargo: Array[RigidBody3D]=[]
var belt: StaticBody3D
var gate: RigidBody3D
var receiver: RigidBody3D
var gate_grip: RigidBody3D
var feed_running := false
var flood := false
var feed_clock := 0.0
var admitted := 0
var blocked := false
var marker_clock := 0.0
var marks: Array=[]
var passed_gate: Dictionary={}
var spilled: Dictionary={}

func build() -> void:
	kind="prefab_overflow";extent=Vector2(10,11);floor_patch(extent,ink)
	add_to_group("force_prefab_overflow")
	title("JUST GET IT THROUGH","Pull the rose grip. Trigger: flood. The pile stays.",4.8)
	# Shallow outer lip contains ordinary spills; the visitor can walk in at front.
	for x in [-4.85,4.85]:fixed(Vector3(x,0.25,0),Vector3(0.12,0.45,10.8),pink)
	fixed(Vector3(0,0.25,5.35),Vector3(9.8,0.45,0.12),pink)
	belt=fixed(Vector3(-0.8,1.0,-0.7),Vector3(2.4,0.2,6.2),pale)
	belt.name="MovingContactBelt";belt.physics_material_override=physics_material(0.95,0)
	belt.constant_linear_velocity=global_basis*Vector3(0,0,1.8)
	for z in [-3,-1,1]:
		for x in [-1.7,0.1]:fixed(Vector3(x,0.5,z),Vector3(0.12,0.95,0.15),pink)
	# Moving painted strips explain surface speed; only the fixed body's surface
	# velocity moves cargo. No direct cargo translation or collector teleport.
	for i in range(16):marks.append(box(Vector3(-0.8,1.105,-3.7+i*0.38),Vector3(2.3,0.014,0.07),blue))
	for x in [-2.4,0.8]:fixed(Vector3(x,2.2,-3.5),Vector3(0.18,4.4,0.18),pink)
	fixed(Vector3(-0.8,4.35,-3.5),Vector3(3.4,0.2,0.6),pink)
	box(INLET+Vector3(0,0.55,0),Vector3(1.25,0.15,1.25),pale)
	words("DELIVERIES",Vector3(-0.8,4.8,-3.5),0.0012)
	# A fixed hinge; the hand pulls a force proxy instead of tearing it off.
	var pier=fixed(Vector3(-2.06,1.7,0.8),Vector3(0.12,3.3,0.16),pink)
	gate=solid(Vector3(-0.8,1.72,0.8),Vector3(2.4,1.24,0.14),4,pink)
	gate.name="LoadingGate"
	var joint=hinge_at(pier,gate,Vector3(-2.0,1.72,0.8),Vector3.UP,1.5)
	joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER,0.03)
	gate_grip=grip(gate,Vector3(0.99,0.08,-0.16))
	gate_grip.action_pressed.connect(func(_object):flood=true;feed_running=true)
	gate_grip.action_released.connect(func(_object):flood=false)
	words("PULL THE GATE\nHOLD TRIGGER: FLOOD",Vector3(1.65,1.9,0.15),0.00072)
	# Cargo falls onto a real hinged tray. A return spring is an explicit torque.
	var pivot=fixed(Vector3(-0.8,0.48,3.4),Vector3(0.2,0.82,0.2),pink)
	receiver=solid(Vector3(-0.8,0.86,3.4),Vector3(3.1,0.16,1.8),3,pale)
	receiver.name="RockingReceiver"
	hinge_at(pivot,receiver,receiver.position,Vector3.RIGHT,0.8)
	for x in [-1.52,1.52]:
		box(Vector3(x,0.16,0),Vector3(0.06,0.25,1.8),pink,false,receiver)
		var c=CollisionShape3D.new();var s=BoxShape3D.new();s.size=Vector3(0.06,0.25,1.8);c.shape=s;c.position=Vector3(x,0.16,0);receiver.add_child(c)
	members.witness=sphere(Vector3(-0.8,1.25,3.9),0.3,0.8)
	# The cast is finite. Once delivered, every body remains in the encounter.
	for i in range(CAPACITY):
		var b: RigidBody3D
		if i%4==3:b=sphere(Vector3(0,-6,0),0.52 if i>=16 else 0.29,3.0 if i>=16 else 0.8)
		else:
			b=PROP.new();b.prop_kind=["crate","chair","extinguisher"][i%4]
			b.size_multiplier=1.65 if i>=16 else 1.0
			b.position=Vector3(0,-6,0);add_child(b);remember(b)
		b.name="Cargo%02d"%i;b.freeze=true;b.freeze_mode=RigidBody3D.FREEZE_MODE_STATIC
		b.collision_layer=0;b.collision_mask=0;b.visible=false
		b.physics_material_override=physics_material(0.8,0.12)
		b.set_meta("no_trail",true);cargo.append(b)
	control("FEED / PAUSE",Vector3(2.0,0,-3.6))
	var rack=load("res://commons/artifacts/force_play/push_stick_rack.gd").new()
	rack.position=Vector3(3.7,0,-0.8);add_child(rack)
	words("CRATE / CHAIR / EXTINGUISHER / POINT\n32 deliveries. Second half: OVERSIZE.",Vector3(0,1.5,-5.0),0.00075)

func action(id: String) -> void:
	if id=="FEED / PAUSE":feed_running=not feed_running

func step(dt: float) -> void:
	marker_clock=fmod(marker_clock+dt*1.8,6.1)
	for i in marks.size():marks[i].position.z=-3.75+fmod(i*0.38+marker_clock,6.1)
	# The door closes softly when released; the receiver rocks under its load.
	gate.apply_torque(global_basis*Vector3(0,clampf(-gate.rotation.y*60.0-gate.angular_velocity.dot(global_basis.y)*4.0,-120,120),0))
	receiver.apply_torque(global_basis*Vector3(clampf(-receiver.rotation.x*22.0-receiver.angular_velocity.dot(global_basis.x)*2.0,-30,30),0,0))
	if not is_held(gate_grip):flood=false
	if feed_running and admitted<CAPACITY:
		feed_clock+=dt
		var interval=0.3 if flood else 0.9
		if feed_clock>=interval:
			feed_clock=0;try_delivery()
	for i in range(admitted):
		var b=cargo[i]
		if b.position.z>1.7:passed_gate[i]=true
		if b.position.y<0.65:spilled[i]=true
	status.text="%d / 32 DELIVERED  ·  %d BEYOND GATE  ·  %d REACHED FLOOR\n%s"%[admitted,passed_gate.size(),spilled.size(),"INLET BLOCKED / clear it by hand" if blocked else ("ALL DELIVERED / the result stays" if admitted==CAPACITY else ("FLOOD" if flood else ("FEEDING" if feed_running else "PAUSED / the belt still moves")))]

func try_delivery() -> bool:
	if admitted>=CAPACITY or reset_in_progress:return false
	var shape=SphereShape3D.new();shape.radius=1.15 if admitted>=16 else 0.7
	var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=to_global(INLET);query.collision_mask=4|524290
	blocked=not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
	if blocked:return false
	var b=cargo[admitted]
	b.transform=Transform3D(Basis(Vector3.UP,float(admitted%3)*0.65),INLET)
	b.linear_velocity=Vector3.ZERO;b.angular_velocity=Vector3.ZERO
	b.collision_layer=4;b.collision_mask=524293;b.visible=true
	PhysicsServer3D.body_set_state(b.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,b.global_transform)
	b.force_update_transform();b.reset_physics_interpolation()
	b.freeze=false;b.sleeping=false;admitted+=1
	return true

func after_reset() -> void:
	feed_running=false;flood=false;feed_clock=0;admitted=0;blocked=false
	passed_gate.clear();spilled.clear()
	for b in cargo:b.collision_layer=0;b.collision_mask=0;b.visible=false
