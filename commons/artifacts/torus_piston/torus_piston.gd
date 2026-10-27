extends "res://commons/artifacts/single_cube_turntable/single_cube_turntable.gd"
## Exposed slider crank: the same wheel angle places the pin, connecting rod and
## cylinder. Finite rod length makes this different from the exact sine yoke.
## Ideal kinematics, not a contact/force simulation or a simulated pump.
const CRANK := .8
const LINK := 2.3
const AXIS := Vector3(-2,1.85,0)
var flywheel: Node3D
var crank_pin: MeshInstance3D
var connecting_rod: MeshInstance3D
var cylinder_carriage: Node3D
var stroke := 0.0

func _ready() -> void:
	super._ready()
	part_defaults.DiskAndCrank.bounds = [-3.4,0,-.62,6.7,3.25,2.65]
	console.title = "TURN / STROKE"
	for label in controls.find_children("*","Label3D",true,false):
		if label.text=="HAND / PLATE / CUBE":label.text = "WHEEL / ROD / CYLINDER"
	set_meta("void_preview_kind","Exposed finite-rod slider crank and moving cylinder entering a stationary torus. Ideal kinematics; static editor pose.")

func build_disk() -> void:
	var red := finish("d52b54",.35,.3)
	# Independent fixed support and coupled moving assembly; all motion is local.
	for x in [-2,1.5]:
		box(drive,Vector3(x,.12,0),Vector3(1.25,.24,1.05),steel,true)
		box(drive,Vector3(x,.88,-.3),Vector3(.22,1.4,.25),steel,true)
	box(drive,Vector3(-.45,.32,-.3),Vector3(4.5,.17,.2),steel,true)
	flywheel = Node3D.new();flywheel.name = "LargeFlywheel";flywheel.position = AXIS
	drive.add_child(flywheel);disk = flywheel
	var rim := ring(flywheel,Vector3.ZERO,1.12,1.31,steel)
	rim.name = "BlackSteelFlywheel"
	ring(flywheel,Vector3(0,0,.02),1.24,1.29,pink)
	for i in 5:
		var a := i*TAU/5
		rod(flywheel,Vector3.ZERO,Vector3(cos(a),sin(a),0)*1.17,.045,ivory)
	rod(drive,AXIS+Vector3(0,0,-.38),AXIS+Vector3(0,0,.2),.13,steel)
	crank_pin = rod(drive,AXIS,AXIS+Vector3(0,0,.4),.095,red)
	crank_pin.name = "ExposedCrankPin"
	connecting_rod = rod(drive,AXIS,AXIS+Vector3(LINK,0,.34),.065,pink)
	connecting_rod.name = "FixedLengthConnectingRod"
	cylinder_carriage = Node3D.new();cylinder_carriage.name = "CylinderCarriage";drive.add_child(cylinder_carriage)
	rod(cylinder_carriage,Vector3(0,0,-.06),Vector3(0,0,.43),.1,steel)
	rod(cylinder_carriage,Vector3(0,0,0),Vector3(.25,0,0),.12,steel)
	rod(cylinder_carriage,Vector3(.2,0,0),Vector3(2.0,0,0),.32,ivory).name = "ReciprocatingCylinder"
	for x in [.3,1.9]:
		var band := ring(cylinder_carriage,Vector3(x,0,0),.321,.355,red)
		band.rotation.y = PI/2
	var portal := ring(drive,Vector3(1.5,1.85,0),.58,.89,pink)
	portal.name = "ReceivingTorus";portal.rotation.y = PI/2
	for z in [-.42,.42]:
		rod(drive,Vector3(1.5,.4,z),Vector3(1.5,1.2,z),.055,steel)
	# The two rails make the cylinder's one allowed direction visible.
	for y in [1.35,2.35]:rod(drive,Vector3(-.65,y,-.24),Vector3(1.2,y,-.24),.035,steel)

func ring(host: Node3D,p: Vector3,inner: float,outer: float,mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new();var t := TorusMesh.new()
	t.inner_radius = inner;t.outer_radius = outer;t.rings = 80;t.ring_segments = 12
	m.mesh = t;m.material_override = mat;m.rotation.x = PI/2;m.position = p;host.add_child(m);return m

func build_crank() -> void:
	wheel = HandWheel.new();wheel.name = "HandWheel";wheel.assemble()
	wheel.position = Vector3(-2,1.18,1.3);wheel.scale = Vector3.ONE*.65
	var rotor: Node3D = wheel.get_node("HingeOrigin/InteractableHinge")
	var rim := MeshInstance3D.new();var t := TorusMesh.new()
	t.inner_radius = .435;t.outer_radius = .485;t.rings = 48;t.ring_segments = 10
	rim.mesh = t;rim.rotation.z = PI/2;rim.position.x = .04;rim.material_override = steel;rotor.add_child(rim)
	for i in 3:
		var a := i*TAU/3
		rod(rotor,Vector3(.04,0,0),Vector3(.04,sin(a)*.45,-cos(a)*.45),.025,steel)
	rod(rotor,Vector3(-.18,0,0),Vector3(.11,0,0),.07,ivory)
	rod(rotor,Vector3(.04,0,-.48),Vector3(.32,0,-.48),.027,ivory)
	rod(rotor,Vector3(.22,0,-.48),Vector3(.34,0,-.48),.045,pink)
	drive.add_child(wheel)
	rod(drive,Vector3(-2,1.18,1.3),Vector3(-2,1.18,.65),.045,steel)
	rod(drive,Vector3(-2,1.18,.65),Vector3(-2,1.85,.65),.045,steel)
	rod(drive,Vector3(-2,1.85,.65),AXIS,.045,steel)
	box(drive,Vector3(-2,.58,1.25),Vector3(.12,1.1,.14),steel,true)
	box(drive,Vector3(-2,.06,1.25),Vector3(.65,.12,.6),steel,true)

func _on_turn(degrees: float) -> void:
	angle_degrees = degrees
	var a := deg_to_rad(degrees)
	flywheel.rotation.z = a
	var pin_at := AXIS+Vector3(CRANK*cos(a),CRANK*sin(a),.34)
	var slider_at := AXIS+Vector3(CRANK*cos(a)+sqrt(LINK*LINK-pow(CRANK*sin(a),2)),0,.34)
	crank_pin.position = pin_at-Vector3(0,0,.14)
	connecting_rod.position = (pin_at+slider_at)*.5
	connecting_rod.quaternion = Quaternion(Vector3.UP,(slider_at-pin_at).normalized())
	connecting_rod.mesh.height = pin_at.distance_to(slider_at)
	cylinder_carriage.position = slider_at-Vector3(0,0,.34)
	stroke = slider_at.x-AXIS.x-(LINK-CRANK)
	state_changed.emit({"angle":degrees,"stroke":stroke})

func _process(delta: float) -> void:
	if is_instance_valid(wheel):super._process(delta)

func _on_parameter(index: int,value: float) -> void:
	if index==1 and not is_instance_valid(wheel):return
	super._on_parameter(index,value)

func refresh_controls() -> void:
	if not is_instance_valid(console) or not console.is_node_ready():return
	if not is_instance_valid(wheel):
		console.set_reading("CONTROL PANEL / mechanism not included");return
	console.set_parameter(0,motor_rpm/rpm_limit);console.set_parameter(1,fposmod(angle_degrees,360)/360)
	console.set_action_selected(0,auto_run);console.set_action_selected(1,reverse)
	console.set_reading("%.1f RPM | STROKE %.2f / 1.60 m\n%s | %s"%[motor_rpm,stroke,"HAND" if hand_active() or manual_cooldown>0 else ("AUTO" if auto_run else "STOP"),"REVERSE" if reverse else "FORWARD"])
