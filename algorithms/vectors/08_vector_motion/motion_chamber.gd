extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Actual rigid-body state, in a deliberately limited horizontal collision world.
const BODY_LAYER := 1 << 19
const START := Vector3(-2,1.0,-2)
const PUSH_FORCE := 2.0
const TRAIL_LIMIT := 120
var body: RigidBody3D
var command := Vector3.ZERO
var pulse_left := 0.0
var braking := false
var drag_on := false
var parts := false
var trail_on := false
var revealed := false
var measured_acceleration := Vector3.ZERO
var previous_velocity := Vector3.ZERO
var local_force := Vector3.ZERO
var run_time := 0.0
var sample_time := 0.0
var text_time := 0.0
var trail_points: Array[Vector3] = []
var trail_mesh := ImmediateMesh.new()
var trail_view: MeshInstance3D
var wall: Label3D
var panels: Array[Label3D] = []
var arrows: Array[Node3D] = []
var cyan: Material
var pink: Material
var amber: Material
var frame_material: PhysicsMaterial

func _ready() -> void:
	cyan=material("63edd9",true);pink=material("f88db9",true);amber=material("ffbd61",true)
	var steel=material("243a44")
	for x in range(-5,6):box(Vector3(x,0.012,0),Vector3(0.012,0.01,8),steel)
	for z in range(-4,5):box(Vector3(0,0.012,z),Vector3(10,0.01,0.012),steel)
	frame_material=PhysicsMaterial.new();frame_material.friction=0;frame_material.bounce=0
	for x in [-5.2,5.2]:boundary(Vector3(x,1,0),Vector3(0.16,2,8.5))
	for z in [-4.2,4.2]:boundary(Vector3(0,1,z),Vector3(10.5,2,0.16))
	box(Vector3(0,2.1,-5),Vector3(6.8,3.8,0.1),steel,true)
	label("WHEN THE PUSH ENDS",Vector3(0,3.5,-4.93),0.004)
	wall=label("",Vector3(0,2.0,-4.92),0.0025)
	label("Horizontal model / metres, seconds, kilograms, newtons",Vector3(0,0.55,-4.92),0.0019)
	bank(["PUSH X","PUSH F","COAST","BRAKE","RESET"],-1.0,0)
	bank(["MASS","DRAG","PARTS","TRAIL","RULE"],1.1,PI)
	var centre=label("STAND HERE",Vector3(0,0.025,0),0.002);centre.rotation_degrees.x=-90
	body=RigidBody3D.new();body.name="MotionBody";body.mass=1;body.gravity_scale=0
	body.linear_damp_mode=RigidBody3D.DAMP_MODE_REPLACE;body.linear_damp=0
	body.angular_damp_mode=RigidBody3D.DAMP_MODE_REPLACE;body.angular_damp=0
	body.axis_lock_linear_y=true;body.axis_lock_angular_x=true;body.axis_lock_angular_y=true;body.axis_lock_angular_z=true
	body.can_sleep=false;body.continuous_cd=true;body.collision_layer=BODY_LAYER;body.collision_mask=BODY_LAYER
	var physics=PhysicsMaterial.new();physics.friction=0;physics.bounce=1;body.physics_material_override=physics
	add_child(body);body.position=START
	box(Vector3.ZERO,Vector3.ONE*0.4,cyan,false,body)
	var c=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3.ONE*0.4;c.shape=shape;body.add_child(c)
	trail_view=MeshInstance3D.new();trail_view.mesh=trail_mesh;trail_view.material_override=pink;add_child(trail_view)
	for mat in [cyan,pink,amber]:arrows.append(make_arrow(mat))
	update_views()

func boundary(at: Vector3, size: Vector3) -> void:
	var fence=StaticBody3D.new();fence.position=at;fence.collision_layer=BODY_LAYER;fence.collision_mask=BODY_LAYER;fence.physics_material_override=frame_material;add_child(fence)
	var collider=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;collider.shape=shape;fence.add_child(collider)
	# Mark the solver boundary without making a wall for the visitor.
	box(Vector3(at.x,0.03,at.z),Vector3(size.x,0.04,size.z),amber)

func bank(ids: Array, z: float, yaw: float) -> void:
	var rig=Node3D.new();add_child(rig);rig.position.z=z;rig.rotation.y=yaw
	box(Vector3(0,0.94,0),Vector3(3.8,0.16,0.55),material("263a44"),true,rig)
	for x in [-1.6,1.6]:box(Vector3(x,0.45,0),Vector3(0.13,0.9,0.25),material("263a44"),true,rig)
	for i in ids.size():
		var id: String=ids[i];var button=PUSH.instantiate();rig.add_child(button);button.position=Vector3((i-2)*0.7,1.04,0);button.scale=Vector3.ONE*1.15;buttons[id]=button;button.pressed.connect(act.bind(id))
		var caption=Label3D.new();rig.add_child(caption);caption.text=id;caption.position=button.position+Vector3(0,0.06,0.18);caption.font_size=42;caption.pixel_size=0.001;caption.rotation_degrees.x=-55
	var info=Label3D.new();rig.add_child(info);info.position=Vector3(0,1.14,-0.22);info.rotation_degrees.x=-55;info.font_size=42;info.pixel_size=0.0011;panels.append(info)

func velocity() -> Vector3:
	return global_basis.inverse()*body.linear_velocity

func make_arrow(mat: Material) -> Node3D:
	var rig=Node3D.new();add_child(rig)
	var shaft=MeshInstance3D.new();var cylinder=CylinderMesh.new();cylinder.top_radius=0.025;cylinder.bottom_radius=0.025;cylinder.height=1;cylinder.radial_segments=8;shaft.mesh=cylinder;shaft.material_override=mat;rig.add_child(shaft)
	var tip=MeshInstance3D.new();var cone=CylinderMesh.new();cone.top_radius=0;cone.bottom_radius=0.09;cone.height=0.18;cone.radial_segments=8;tip.mesh=cone;tip.material_override=mat;rig.add_child(tip);return rig

func arrow(rig: Node3D, start: Vector3, value: Vector3, gain: float) -> void:
	var d=(value*gain).limit_length(2.5);rig.visible=parts and d.length()>0.001
	if not rig.visible:return
	rig.position=start+d*0.5;rig.quaternion=Quaternion(Vector3.UP,d.normalized());rig.get_child(0).scale.y=d.length();rig.get_child(1).position.y=d.length()*0.5-0.09

func act(id: String) -> void:
	match id:
		"PUSH X":command=Vector3.RIGHT*PUSH_FORCE;pulse_left=1;braking=false
		"PUSH F":command=Vector3.FORWARD*PUSH_FORCE;pulse_left=1;braking=false
		"COAST":pulse_left=0;command=Vector3.ZERO;braking=false
		"BRAKE":pulse_left=0;command=Vector3.ZERO;braking=true
		"RESET":reset_body()
		"MASS":body.mass=1 if body.mass>=4 else body.mass*2;reset_body()
		"DRAG":drag_on=not drag_on;body.linear_damp=0.8 if drag_on else 0.0
		"PARTS":parts=not parts
		"TRAIL":trail_on=not trail_on;trail_view.visible=trail_on
		"RULE":revealed=not revealed
	update_views()

func reset_body() -> void:
	body.position=START;body.linear_velocity=Vector3.ZERO;body.angular_velocity=Vector3.ZERO
	command=Vector3.ZERO;pulse_left=0;braking=false;previous_velocity=Vector3.ZERO;measured_acceleration=Vector3.ZERO;local_force=Vector3.ZERO
	run_time=0;sample_time=0;trail_points.clear();trail_mesh.clear_surfaces()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(body):return
	run_time+=delta
	var v=velocity();measured_acceleration=(v-previous_velocity)/delta;previous_velocity=v
	local_force=Vector3.ZERO
	if braking:
		if v.length()<0.001:braking=false
		else:local_force=-v.normalized()*minf(PUSH_FORCE,body.mass*v.length()/delta)
	elif pulse_left>0:
		var active=minf(pulse_left,delta);local_force=command*(active/delta);pulse_left=maxf(0,pulse_left-delta)
	body.apply_central_force(global_basis*local_force)
	sample_time+=delta
	if sample_time>=0.1:
		sample_time=fmod(sample_time,0.1);trail_points.append(body.position)
		if trail_points.size()>TRAIL_LIMIT:trail_points.pop_front()
		trail_mesh.clear_surfaces()
		if trail_points.size()>1:
			trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
			for p in trail_points:trail_mesh.surface_add_vertex(p)
			trail_mesh.surface_end()
	arrow(arrows[0],body.position,v,0.35)
	arrow(arrows[1],body.position+Vector3(0,0.12,0),measured_acceleration,0.2)
	arrow(arrows[2],body.position+Vector3(0,-0.12,0),local_force,0.3)
	text_time+=delta
	if text_time>=0.1:text_time=0;update_views()

func update_views() -> void:
	var v=velocity();panels[0].text="2 N pulse / 1 second | %s" % ("BRAKING" if braking else ("PUSHING" if pulse_left>0 else "COAST"))
	panels[1].text="mass %.0f kg | DRAG %s | speed %.2f m/s" % [body.mass,"ON" if drag_on else "OFF",v.length()]
	var text="PUSH X, then wait.\nWhen the pulse ends, does motion end?\nCOAST ends the command; BRAKE opposes velocity.\nPUSH F while already moving.\nMASS resets for a new comparison."
	if revealed:
		text="v = (%.2f, %.2f, %.2f) m/s\nmeasured a = (%.2f, %.2f, %.2f) m/s²\ncommand force = %.2f N | mass %.0f kg\nF/m changes velocity; velocity carries position.\nCyan v: 0.35 m per m/s\nPink measured a: 0.2 m per m/s²\nGold command F: 0.3 m per N / arrows capped at 2.5 m" % [v.x,v.y,v.z,measured_acceleration.x,measured_acceleration.y,measured_acceleration.z,local_force.length(),body.mass]
	wall.text=text+"\n\nNo gravity. Height and rotation locked.\nElastic solver frame; player and furniture excluded.\nDRAG is engine damping. COAST leaves it active.\nTrail: latest 120 samples at 10 Hz. RESET resets this run."
	trail_view.visible=trail_on
