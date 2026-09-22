extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## A one-dimensional spring-damper model. The pickable is its handle, not a second solver.
const STEP := 1.0 / 120.0
const HEIGHT := 1.35
const PULL_LIMIT := 1.5
const FRAME_LIMIT := 2.25
const RATIOS := [0.0, 0.25, 1.0, 2.5]
const DAMP_NAMES := ["FREE", "LIGHT", "CRITICAL", "HEAVY"]
var displacement := 1.25
var velocity := 0.0
var mass_value := 2.0
var stiffness := 8.0
var damping_index := 0
var running := false
var grabbed := false
var frame_exit := false
var parts := false
var rule := false
var accumulator := 0.0
var elapsed := 0.0
var read_clock := 0.0
var crossings := 0
var handle: XRToolsPickable
var coil: MeshInstance3D
var board: Label3D
var bank_labels: Array[Label3D] = []
var force_labels: Array[Label3D] = []
var arrows: Array[Node3D] = []
var pull_index := 0

func damping_coefficient() -> float:
	return 2.0 * RATIOS[damping_index] * sqrt(stiffness * mass_value)

func forces() -> Vector3:
	var restoring := -stiffness * displacement
	var resistance := -damping_coefficient() * velocity
	return Vector3(restoring, resistance, restoring + resistance)

func energy() -> float:
	return 0.5 * mass_value * velocity * velocity + 0.5 * stiffness * displacement * displacement

func _ready() -> void:
	var steel = material("263a44")
	box(Vector3(0,0.07,0),Vector3(9.4,0.04,7.8),material("324750"))
	# A reference line belongs to the room; it stays still while the body moves.
	box(Vector3(0,0.10,0),Vector3(0.035,0.02,4.2),material("e9d27f",true))
	box(Vector3(0,HEIGHT,-0.55),Vector3(5.2,0.045,0.045),steel)
	for x in [-2.25,0.0,2.25]:
		box(Vector3(x,HEIGHT,-0.55),Vector3(0.025,0.28,0.04),steel)
		front_label("%.2f m"%x,Vector3(x,HEIGHT-0.3,-0.60),0.0013)
	for x in [-3.2,3.2]:
		box(Vector3(x,2.0,0.45),Vector3(0.14,4,0.14),steel,true)
	box(Vector3(0,4.0,0.45),Vector3(6.5,0.14,0.14),steel)
	box(Vector3(-3.2,HEIGHT,0),Vector3(0.25,0.4,0.4),steel)
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES,material("65cce0",true))
	var previous := Vector3.ZERO
	for i in range(1,145):
		var t := float(i)/144.0
		var p := Vector3(t,0.18*sin(t*TAU*12),0.18*cos(t*TAU*12))
		mesh.surface_add_vertex(previous);mesh.surface_add_vertex(p);previous=p
	mesh.surface_end()
	coil = MeshInstance3D.new();coil.mesh=mesh;coil.position=Vector3(-3.2,HEIGHT,0);add_child(coil)
	handle = preload("res://commons/artifacts/spring_tower/spring_handle.gd").new()
	handle.add_to_group("no_gravity_gun")
	handle.process_physics_priority=100
	handle.name="SpringHandle";handle.machine=self;handle.freeze=true;handle.release_mode=XRToolsPickable.ReleaseMode.FROZEN
	handle.collision_layer=131076;handle.collision_mask=0;handle.gravity_scale=0
	add_child(handle)
	box(Vector3.ZERO,Vector3.ONE*0.55,material("d582b8"),false,handle)
	var shape=CollisionShape3D.new();var cube=BoxShape3D.new();cube.size=Vector3.ONE*0.55;shape.shape=cube;handle.add_child(shape)
	handle.picked_up.connect(_on_grab);handle.dropped.connect(_on_drop)
	for i in 2:
		var controls=preload("res://commons/artifacts/timing_machines/machine_stage.gd").new();add_child(controls)
		controls.position=Vector3(-2.35 if i==0 else 2.35,0,-3.2);controls.rotation.y=PI
		controls.console(["PULL","RELEASE","RESET"] if i==0 else ["DAMP","MASS","SPRING","PARTS","RULE"],0,"PULL, THEN LET GO" if i==0 else "CHANGE ONE CONDITION")
		bank_labels.append(controls.readout)
		for id in controls.buttons:buttons[id]=controls.buttons[id];buttons[id].pressed.connect(act.bind(id))
	box(Vector3(0,2.85,3.35),Vector3(8.8,2.7,0.12),steel)
	board=front_label("",Vector3(0,3.75,3.26),0.0025)
	var colors=["65cce0","ee9f65","f2dc8d"]
	for i in 3:
		var y:=3.15-float(i)*0.55
		box(Vector3(0,y,3.23),Vector3(0.012,0.40,0.02),material("829294"))
		force_labels.append(front_label("",Vector3(-3.0,y,3.18),0.0019))
		arrows.append(make_arrow(material(colors[i],true)))
		arrows.append(make_arrow(material(colors[i],true)))
	front_label("GRAB THE CUBE / horizontal displacement only\nRelease starts from rest; hand throwing is excluded.",Vector3(0,0.48,-1.3),0.0015)
	update_visuals();update_text()

func front_label(text: String, at: Vector3, pixels: float) -> Label3D:
	var l=label(text,at,pixels);l.rotation.y=PI;return l

func _on_grab(_pickable: Node) -> void:
	grabbed=true;running=false;velocity=0;accumulator=0;frame_exit=false
	update_text()

func follow_handle(world_point: Vector3) -> void:
	displacement=clampf(to_local(world_point).x,-PULL_LIMIT,PULL_LIMIT)
	velocity=0;update_visuals()

func _on_drop(_pickable: Node) -> void:
	follow_handle(handle.global_position)
	grabbed=false;release_body()

func release_body() -> void:
	velocity=0;running=true;frame_exit=false;elapsed=0;crossings=0;accumulator=0
	update_text()

func reset_pose(x: float=1.25) -> void:
	displacement=x;velocity=0;elapsed=0;crossings=0;running=false;frame_exit=false;accumulator=0
	update_visuals();update_text()

func act(id: String) -> void:
	if grabbed and id in ["PULL","RELEASE","RESET"]:return
	match id:
		"PULL":
			pull_index=(pull_index+1)%3;reset_pose([1.25,-1.25,0.625][pull_index])
		"RELEASE":release_body()
		"RESET":reset_pose()
		"DAMP":damping_index=(damping_index+1)%4
		"MASS":mass_value=4.0 if mass_value==2 else (1.0 if mass_value==4 else 2.0)
		"SPRING":stiffness=16.0 if stiffness==8 else (4.0 if stiffness==16 else 8.0)
		"PARTS":parts=not parts
		"RULE":rule=not rule
	update_visuals();update_text()

func _physics_process(delta: float) -> void:
	advance(delta)
	update_visuals()
	read_clock+=delta
	if read_clock>=0.1:read_clock=0;update_text()

func advance(delta: float) -> void:
	if not running or grabbed:return
	accumulator+=minf(delta,0.25)
	while accumulator+0.0000001>=STEP and running:
		accumulator-=STEP
		var previous:=displacement
		var force: float = -stiffness * displacement - damping_coefficient() * velocity
		velocity += (force / mass_value) * STEP
		displacement += velocity * STEP
		elapsed+=STEP
		if previous*displacement<0:crossings+=1
		if absf(displacement)>FRAME_LIMIT:running=false;frame_exit=true

func update_visuals() -> void:
	if not is_instance_valid(handle):return
	if not grabbed:handle.position=Vector3(displacement,HEIGHT,0);handle.rotation=Vector3.ZERO
	coil.scale.x=displacement+3.2
	var f:=forces()
	for i in 3:
		place_arrow(arrows[i*2],Vector3(displacement,2.05+float(i)*0.35,0),Vector3(f[i]*0.04,0,0))
		place_arrow(arrows[i*2+1],Vector3(0,3.15-float(i)*0.55,3.15),Vector3(f[i]*0.04,0,0))

func update_text() -> void:
	if not is_instance_valid(board):return
	bank_labels[0].text="x %.2f m / v %.2f m/s\n%s / crossings %d"%[displacement,velocity,"HELD" if grabbed else ("FRAME EXIT" if frame_exit else ("RELEASED" if running else "READY")),crossings]
	bank_labels[1].text="m %.0f kg / k %.0f N/m / %s\nc %.2f kg/s"%[mass_value,stiffness,DAMP_NAMES[damping_index],damping_coefficient()]
	board.text="Does returning mean stopping?\nDisplace, release, then change DAMP."
	if rule:board.text="F = -k x - c v;  v += (F / m) dt;  x += v dt\nX only / 120 steps per second / arrows 0.04 m per N"
	var f:=forces()
	for i in 3:
		force_labels[i].text=["SPRING","DAMPING","SUM"][i]+("  %.2f N"%f[i] if parts else "  ?")

func make_arrow(mat: Material) -> Node3D:
	var rig=Node3D.new();add_child(rig)
	var shaft=CylinderMesh.new();shaft.top_radius=0.024;shaft.bottom_radius=0.024;shaft.height=1;shaft.radial_segments=8
	var body=MeshInstance3D.new();body.mesh=shaft;body.material_override=mat;rig.add_child(body)
	var cone=CylinderMesh.new();cone.top_radius=0;cone.bottom_radius=0.075;cone.height=0.16;cone.radial_segments=8
	var tip=MeshInstance3D.new();tip.mesh=cone;tip.material_override=mat;rig.add_child(tip)
	return rig

func place_arrow(rig: Node3D, origin: Vector3, vector: Vector3) -> void:
	rig.visible=parts and vector.length()>0.002
	if not rig.visible:return
	rig.position=origin+vector*0.5;rig.quaternion=Quaternion(Vector3.UP,vector.normalized())
	rig.get_child(0).scale.y=vector.length();rig.get_child(1).position.y=vector.length()*0.5-0.08
