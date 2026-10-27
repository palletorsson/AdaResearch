extends "res://commons/artifacts/force_play/play_space.gd"
## Motion becomes an input to another body. Only the motor supplies energy;
## joints, contact and gravity determine the other bodies' motion and results.
## Hand grips reuse the bounded-force proxy: constrained bodies never teleport.
const TIMBER=preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
var wood: StandardMaterial3D
var steel: StandardMaterial3D
var motor: HingeJoint3D
var motor_running:=false
var motor_speed:=1.1
var drops: Dictionary={}
var released:=false
var outputs: Dictionary={}
var pin_message:=""

func build() -> void:
	wood=TIMBER.material();steel=material("59636a");steel.metallic=.8;steel.roughness=.32
	pale=material("eee9df");ink=material("20252a");pink=material("d58c9b")
	motor_speed=float(get_meta("config_motor_speed",1.1))
	match kind:
		"crank":build_crank()
		"lever":build_lever()
		"suspended":build_suspended()
		"sorter":build_sorter()
	# Diagnostic trails are available in the source family; this room leaves
	# the actual rods and ropes as its traces instead of adding coloured jets.
	for b in bodies:
		b.set_meta("no_trail",true)
		for child in b.get_children():
			if child is MeshInstance3D and child.mesh is BoxMesh and child.material_override==wood:
				child.mesh=TIMBER.mesh(child.mesh.size)

func bar(a:Vector3,b:Vector3,width:float,height:float,mat:Material=null) -> StaticBody3D:
	var body=fixed((a+b)*.5,Vector3(width,height,a.distance_to(b)),mat if mat!=null else steel)
	body.basis=Basis.looking_at((a-b).normalized(),Vector3.UP) if absf((a-b).normalized().dot(Vector3.UP))<.999 else Basis(Vector3.RIGHT,PI*.5)
	return body

func ceiling_frame(width:float,z:float) -> StaticBody3D:
	var beam=fixed(Vector3(0,5.48,z),Vector3(width,.18,.24),steel)
	for x in [-width*.4,width*.4]:fixed(Vector3(x,5.59,z),Vector3(.12,.1,.36),steel)
	return beam

func joint(a:Node3D,b:RigidBody3D,at:Vector3) -> HingeJoint3D:
	var h=hinge_at(a,b,at,Vector3.FORWARD,PI)
	h.set_flag(HingeJoint3D.FLAG_USE_LIMIT,false)
	return h

func observed(id:String,value:bool) -> void:
	if value and not outputs.get(id,false):outputs[id]=true

func build_crank() -> void:
	extent=Vector2(6,3)
	var pivot=Vector3(-1.75,2.65,0)
	var bracket=ceiling_frame(5.6,.5)
	bar(Vector3(-1.75,5.4,.5),Vector3(-1.75,2.65,.5),.14,.14)
	bar(Vector3(1.3,5.4,.5),Vector3(1.3,2.2,.5),.12,.12)
	var rotor=solid(pivot,Vector3(1.5,.19,.28),1.2,wood)
	rotor.rotation.z=PI*.5;rotor.gravity_scale=0
	motor=joint(bracket,rotor,pivot)
	motor.name="MotorHinge"
	motor.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY,motor_speed)
	motor.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE,2)
	var radius=.65;var length=2.0
	var pin=pivot+Vector3(0,radius,0)
	var end=pivot+Vector3(sqrt(length*length-radius*radius),0,0)
	var piston=solid(end,Vector3(.6,.6,.6),1,wood);piston.gravity_scale=0
	keep_attached(piston)
	var slide=SliderJoint3D.new();slide.name="ActualPistonGuide";slide.position=end;add_child(slide)
	slide.node_a=slide.get_path_to(bracket);slide.node_b=slide.get_path_to(piston);slide.exclude_nodes_from_collision=true
	slide.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER,-1.55)
	slide.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER,.85)
	slide.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_LOWER,0)
	slide.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_UPPER,0)
	joints.append(slide)
	var rod=solid((pin+end)*.5,Vector3(length,.1,.12),.5,steel)
	rod.rotation.z=atan2(end.y-pin.y,end.x-pin.x);rod.gravity_scale=0
	# These parts meet at a pin, so their overlapping joint ends must not
	# collide even if the pin is removed during the coupling comparison.
	rotor.add_collision_exception_with(rod);rod.add_collision_exception_with(rotor)
	var pin_joint=joint(rotor,rod,pin);pin_joint.name="CrankPin"
	joint(rod,piston,end).name="PistonPin"
	for z in [-.46,.46]:bar(Vector3(-.8,2.26,z),Vector3(1.65,2.26,z),.12,.12)
	fixed(Vector3(1.45,2.26,0),Vector3(1.5,.08,.78),wood)
	var witness=sphere(Vector3(1.3,2.48,0),.18,1,pale)
	witness.physics_material_override=physics_material(.08,.1)
	# A real tray catches what the piston manages to push from its shelf.
	fixed(Vector3(2.15,.13,0),Vector3(1.0,.26,1.25),wood)
	for z in [-.65,.65]:fixed(Vector3(2.15,.42,z),Vector3(1,.6,.09),steel)
	fixed(Vector3(2.7,.42,0),Vector3(.09,.6,1.35),steel)
	grip(rotor,Vector3(.65,0,-.24))
	control("MOTOR / PAUSE",Vector3(-2.3,0,-.8))
	control("PIN / UNPIN",Vector3(-.9,0,-.8))
	members={"rotor":rotor,"rod":rod,"piston":piston,"witness":witness,"pivot":pivot,"radius":radius,"length":length,"pin_joint":pin_joint,"start_piston":end.x}
	words("TURN → TRANSLATE",Vector3(0,3.85,.35),.0011)

func build_lever() -> void:
	extent=Vector2(5.5,3)
	var fulcrum=fixed(Vector3(0,.58,0),Vector3(.28,1.16,.65),steel)
	var prism=MeshInstance3D.new();var profile=PrismMesh.new();profile.size=Vector3(.8,1.1,.72);prism.mesh=profile;prism.material_override=wood;prism.position=Vector3(0,.55,0);add_child(prism)
	var beam=solid(Vector3(0,1.25,0),Vector3(4.8,.18,.7),2,wood)
	var hinge=hinge_at(fulcrum,beam,beam.position,Vector3.FORWARD,.35)
	hinge.name="WorkingLeverPivot"
	var load=solid(Vector3(.75,1.69,0),Vector3.ONE*.7,2,pale)
	pin_at(beam,load,load.position)
	grip(beam,Vector3(-2,0,-.45));grip(beam,Vector3(-.4,0,-.45))
	ceiling_frame(3.4,.9)
	bar(Vector3(0,5.4,.9),Vector3(0,1.25,.9),.1,.1)
	members={"beam":beam,"load":load,"load_home":load.position.y,"pivot":beam.position}
	words("SAME LOAD / DIFFERENT ARM",Vector3(0,2.8,.6),.001)

func build_suspended() -> void:
	extent=Vector2(4.5,3)
	var anchor=ceiling_frame(3.8,0)
	var previous:Node3D=anchor
	for i in range(4):
		var y=5.4-(i+.5)*.8
		var link=solid(Vector3(0,y,0),Vector3(.055,.8,.055),.25,material("a58d65"))
		link.linear_damp=.25;link.angular_damp=.25
		pin_at(previous,link,Vector3(0,5.4-i*.8,0))
		previous=link
	var load=solid(Vector3(0,1.7,0),Vector3.ONE,2,wood)
	pin_at(previous,load,Vector3(0,2.2,0))
	grip(load,Vector3(0,0,-.56))
	# The slot is actual collision geometry. A diagonal cube can meet it
	# differently from a square-on cube; no invisible success funnel is added.
	for z in [-.85,.85]:fixed(Vector3(1.6,1,z),Vector3(.18,2,.18),steel)
	fixed(Vector3(1.6,2.1,0),Vector3(.18,.16,1.9),steel)
	members={"load":load,"anchor":Vector3(0,5.4,0)}
	words("PULL / RELEASE / KEEP ATTACHED",Vector3(0,4.65,.5),.0009)

func build_sorter() -> void:
	extent=Vector2(5.6,5)
	ceiling_frame(5.2,0)
	for x in [-2.5,2.5]:bar(Vector3(x,5.4,0),Vector3(x,2.6,0),.1,.1)
	var balls:Array=[]
	for lane in range(3):
		var x=(lane-1)*1.7
		# Identical diverging rails in every lane. The only changed operand is
		# sphere size. All three bodies have one kilogram and ordinary gravity.
		for side in [-1,1]:
			bar(Vector3(x+side*.2,3.05,-2),Vector3(x+side*.68,2.15,2),.16,.1,wood)
		fixed(Vector3(x,.13,0),Vector3(1.55,.26,4.7),wood)
		for z in [-2.4,-.8,.6,2.4]:fixed(Vector3(x,.65,z),Vector3(1.55,1.2,.08),steel)
		for side in [-1,1]:fixed(Vector3(x+side*.79,.48,0),Vector3(.07,.7,4.7),steel)
		var radius=[.16,.29,.44][lane]
		var b=sphere(Vector3(x,3.38+radius,-1.85),radius,1,pale)
		b.freeze=true;b.physics_material_override=physics_material(.18,.05)
		balls.append(b)
	control("RELEASE",Vector3(-2.1,0,-2.2))
	members={"balls":balls}
	words("SAME MASS / DIFFERENT SIZE",Vector3(0,4.65,0),.001)

func action(id:String) -> void:
	if id=="MOTOR / PAUSE" and motor!=null:
		motor_running=not motor_running
		motor.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR,motor_running)
		for b in bodies:b.sleeping=false
	if id=="PIN / UNPIN" and kind=="crank":
		if is_instance_valid(members.pin_joint):
			joints.erase(members.pin_joint);members.pin_joint.queue_free();members.pin_joint=null
			pin_message="PIN REMOVED / the motor can still turn"
		else:
			var a:Vector3=members.rotor.to_global(Vector3(.65,0,0))
			var b:Vector3=members.rod.to_global(Vector3(-1,0,0))
			if a.distance_to(b)<.12:
				members.pin_joint=joint(members.rotor,members.rod,to_local(a));pin_message=""
			else:pin_message="PIN ENDS MISALIGNED / RESET to reconnect"
	if id=="RELEASE" and kind=="sorter":
		released=true
		for b in members.balls:b.freeze=false;b.sleeping=false

func after_reset() -> void:
	outputs.clear();drops.clear();released=false
	pin_message=""
	if motor!=null:
		motor_running=false;motor.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR,false)
		if not is_instance_valid(members.pin_joint):members.pin_joint=joint(members.rotor,members.rod,members.pivot+Vector3(0,.65,0))

func step(_dt:float) -> void:
	if status==null:return
	match kind:
		"crank":
			var b:RigidBody3D=members.witness
			observed("delivered",b.position.x>2.0 and b.position.y<1.5)
			status.text="DELIVERY OBSERVED" if outputs.get("delivered",false) else ("MOTOR ON / contact decides delivery" if motor_running else "Pull the crank, or MOTOR / PAUSE")
			if not pin_message.is_empty():status.text=pin_message
		"lever":status.text="LOAD / %.2f m above its initial height"%(members.load.position.y-float(members.load_home))
		"suspended":status.text="LOAD / %.2f m sideways / still attached"%members.load.position.x
		"sorter":
			for i in members.balls.size():
				var b:RigidBody3D=members.balls[i]
				var rail_y:float=3.05-(b.position.z+2)*.225
				if released and not drops.has(str(i)) and b.position.y<rail_y-.35:drops[str(i)]=b.position.z
			status.text="RELEASE / sizes differ; all masses are 1 kg" if not released else "ACTUAL EXITS / %d of 3 observed"%drops.size()

func prepare_editor_preview() -> void:
	# Export original meshes at their assembled rest pose. No fake pistons,
	# ropes, particles or predicted outcomes are substituted for the bodies.
	pass
