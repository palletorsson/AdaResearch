extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Physical museum studies. Shared units: metres, kilograms, seconds.
const BODY=preload("res://commons/artifacts/force_play/play_body.gd")
const POINT=preload("res://commons/artifacts/force_capability_lab/loose_point.gd")
const GRIP=preload("res://commons/artifacts/force_play/constraint_grip.gd")
const ARROW=preload("res://commons/artifacts/force_halls/vector_arrow.gd")
const ADAPTER=preload("res://commons/artifacts/force_field_zone/field_carry_provider.gd")
@export var kind := "tower"
var extent := Vector2(10,10)
var bodies: Array[RigidBody3D]=[]
var homes: Array[Transform3D]=[]
var initial_freeze: Array[bool]=[]
var initial_velocity: Array[Vector3]=[]
var grips: Array=[]
var members: Dictionary={}
var status: Label3D
var trails: Dictionary={}
var trail_mesh: MeshInstance3D
var trail_clock:=0.0
var active:=false
var elapsed:=0.0
var pulse:=0.0
var reset_pending:=false
var reset_in_progress:=false
var ink: StandardMaterial3D
var pale: StandardMaterial3D
var pink: StandardMaterial3D
var blue: StandardMaterial3D
var joints: Array=[]
var _carry: Dictionary={}
var recovered:=0
var push_stick: Node3D

func _ready() -> void:
	set_meta("em_keep_scale",true);add_to_group("force_play")
	ink=material("181a22");ink.roughness=0.16;ink.metallic=0.2
	pale=material("e9e4d8");pink=material("eb75a8");blue=material("55c9c1")
	build()
	if kind in ["springs","swings","torque","constraints","friction"]:
		push_stick=load("res://commons/artifacts/force_play/push_stick_rack.gd").new()
		push_stick.position=Vector3(-extent.x*0.5+0.7,0,-extent.y*0.5+1.5)
		add_child(push_stick)
	set_meta("em_visibility_bounds",AABB(Vector3(-extent.x*0.5,-1,-extent.y*0.5),Vector3(extent.x,10,extent.y)))
	status=words("",Vector3(0,0.6,-extent.y*0.5+0.1),0.00085)
	control("RESET",Vector3(extent.x*0.5-0.7,0,-extent.y*0.5+0.7))
	for b in bodies:homes.append(b.transform);initial_freeze.append(b.freeze);initial_velocity.append(b.linear_velocity)
	trail_mesh=MeshInstance3D.new();add_child(trail_mesh)
	var trail_material=StandardMaterial3D.new();trail_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;trail_material.vertex_color_use_as_albedo=true
	trail_mesh.material_override=trail_material
	if kind in ["liquids","vortex","mutual","flight"]:
		add_to_group("ada_museum_carry")
		get_tree().node_added.connect(func(n):
			if n is XRToolsPlayerBody:install_adapter.call_deferred())
		install_adapter.call_deferred()

func build() -> void:pass
func step(_dt: float) -> void:pass
func action(_id: String) -> void:pass
func after_reset() -> void:pass

func words(text: String,at: Vector3,pixels:=0.0011) -> Label3D:
	var l=label(text,at,pixels*1.8);l.font_size=72
	l.billboard=BaseMaterial3D.BILLBOARD_ENABLED;l.modulate=Color.WHITE
	l.outline_modulate=Color("25232a");l.outline_size=4;return l

func title(text: String,sub: String,height:=3.3) -> void:
	words(text,Vector3(0,height,extent.y*0.5-0.4),0.0019)
	words(sub,Vector3(0,height-0.35,extent.y*0.5-0.4),0.0009)

func floor_patch(size: Vector2,colour: Material=null) -> void:
	box(Vector3(0,0.025,0),Vector3(size.x,0.05,size.y),colour if colour!=null else pale,true)

func control(id: String,at: Vector3) -> void:
	box(at+Vector3.UP*0.45,Vector3(0.28,0.9,0.28),pale,true)
	var button=PUSH.instantiate();button.position=at+Vector3.UP*0.94;button.rotation.x=-PI/2
	button.scale=Vector3.ONE*1.4;add_child(button);buttons[id]=button;button.pressed.connect(act.bind(id))
	words(id,at+Vector3.UP*1.18,0.0007)

func act(id: String) -> void:
	if id=="RESET":reset_pending=true
	else:action(id)

func is_held(b: RigidBody3D) -> bool:
	return (b is XRToolsPickable and b.is_picked_up()) or b.has_meta("capability_desktop_held") or (b.has_method("held") and b.held())

func remember(b: RigidBody3D) -> RigidBody3D:
	b.name="Body"+str(bodies.size())
	b.collision_layer=4;b.collision_mask=524293
	b.continuous_cd=true;b.linear_damp=0.02;b.angular_damp=0.03
	bodies.append(b);return b

func sphere(at: Vector3,radius:=0.28,mass_kg:=1.0,mat: Material=null) -> RigidBody3D:
	var b=POINT.new();b.position=at;b.mass=mass_kg
	b.sphere.radius=radius;b.sphere.height=radius*2;b.get_child(1).shape.radius=radius
	b.get_child(0).material_override=mat if mat!=null else ink
	add_child(b);b.freeze=false;return remember(b)

func solid(at: Vector3,size: Vector3,mass_kg:=1.0,mat: Material=null) -> RigidBody3D:
	var b=BODY.new();b.position=at;b.mass=mass_kg
	var mesh=MeshInstance3D.new();var shape=BoxMesh.new();shape.size=size;mesh.mesh=shape;mesh.material_override=mat if mat!=null else pale;b.add_child(mesh)
	var c=CollisionShape3D.new();var bound=BoxShape3D.new();bound.size=size;c.shape=bound;b.add_child(c)
	add_child(b);return remember(b)

func fixed(at: Vector3,size: Vector3,mat: Material=null) -> StaticBody3D:
	var b=StaticBody3D.new();b.position=at;add_child(b)
	box(Vector3.ZERO,size,mat if mat!=null else pale,false,b)
	var c=CollisionShape3D.new();var s=BoxShape3D.new();s.size=size;c.shape=s;b.add_child(c);return b

func cylinder_body(at: Vector3,radius: float,height: float,mass_kg:=1.0) -> RigidBody3D:
	var b=BODY.new();b.position=at;b.mass=mass_kg
	var mesh=MeshInstance3D.new();var m=CylinderMesh.new();m.top_radius=radius;m.bottom_radius=radius;m.height=height;mesh.mesh=m;mesh.material_override=pink;b.add_child(mesh)
	var c=CollisionShape3D.new();var s=CylinderShape3D.new();s.radius=radius;s.height=height;c.shape=s;b.add_child(c)
	add_child(b);return remember(b)

func physics_material(friction: float,bounce:=0.05) -> PhysicsMaterial:
	var m=PhysicsMaterial.new();m.friction=friction;m.bounce=bounce;return m

func rod(start: Vector3,end: Vector3,mat: Material=null,width:=0.018,tip:=false) -> Node3D:
	var node=ARROW.new();add_child(node);node.build(mat if mat!=null else ink,width,tip);node.set_ends(start,end);return node

func grip(target: RigidBody3D,offset: Vector3) -> Node3D:
	var handle=GRIP.new();handle.target=target;handle.offset=offset
	add_child(handle);handle.global_position=target.to_global(offset)
	handle.add_collision_exception_with(target);target.add_collision_exception_with(handle)
	grips.append(handle);return handle

func keep_attached(body: Node3D) -> void:
	if not body is RigidBody3D:return
	# Keep the dynamic collider, but forbid the pickup systems' direct transform
	# ownership. The separate rose grip applies a bounded force instead.
	body.set_meta("force_constraint_body",true)
	if body is XRToolsPickable:body.enabled=false

func hinge_at(anchor: Node3D,body: RigidBody3D,at: Vector3,axis: Vector3,limit:=1.4) -> HingeJoint3D:
	keep_attached(anchor);keep_attached(body)
	var joint=HingeJoint3D.new();joint.position=at;add_child(joint)
	joint.quaternion=Quaternion(Vector3.FORWARD,axis.normalized())
	joint.node_a=joint.get_path_to(anchor);joint.node_b=joint.get_path_to(body);joint.exclude_nodes_from_collision=true
	joint.set_flag(HingeJoint3D.FLAG_USE_LIMIT,true)
	joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER,-limit);joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER,limit)
	joints.append(joint);return joint

func pin_at(anchor: Node3D,body: RigidBody3D,at: Vector3) -> PinJoint3D:
	keep_attached(anchor);keep_attached(body)
	var joint=PinJoint3D.new();joint.position=at;add_child(joint)
	joint.node_a=joint.get_path_to(anchor);joint.node_b=joint.get_path_to(body);joint.exclude_nodes_from_collision=true;joints.append(joint);return joint

func reset() -> bool:
	if reset_in_progress:return false
	for b in bodies+grips:
		if is_instance_valid(b) and is_held(b):status.text="Release the held object before RESET.";return false
	reset_in_progress=true
	# Move the whole experiment atomically. A kinematic teleport can otherwise
	# act like a high-speed collision with neighbours that have not reset yet.
	for b in bodies:
		b.freeze=true;b.freeze_mode=RigidBody3D.FREEZE_MODE_STATIC
		if b.has_meta("forces_calm_state"):
			var calm: Dictionary=b.get_meta("forces_calm_state")
			b.linear_damp=calm.linear;b.angular_damp=calm.angular;b.remove_meta("forces_calm_state")
	for i in bodies.size():
		var b=bodies[i];b.transform=homes[i];b.linear_velocity=Vector3.ZERO;b.angular_velocity=Vector3.ZERO
		PhysicsServer3D.body_set_state(b.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,b.global_transform)
		b.force_update_transform();b.reset_physics_interpolation();b.sleeping=false
	trails.clear();trail_mesh.mesh=null;pulse=0;elapsed=0
	after_reset();status.text="A new trial. Ordinary misses stay until RESET."
	finish_reset.call_deferred();return true

func finish_reset() -> void:
	await get_tree().physics_frame
	for i in bodies.size():
		var b=bodies[i];b.freeze_mode=RigidBody3D.FREEZE_MODE_KINEMATIC;b.freeze=initial_freeze[i]
		b.linear_velocity=initial_velocity[i];b.angular_velocity=Vector3.ZERO;b.sleeping=false
	reset_in_progress=false

func _physics_process(dt: float) -> void:
	if reset_pending:reset_pending=false;reset();return
	if reset_in_progress:return
	elapsed+=dt;step(dt)
	trail_clock+=dt
	if trail_clock>=0.1:
		trail_clock=0;record_trails()
	for i in bodies.size():
		var b=bodies[i]
		if not is_held(b) and (b.position.y< -12 or b.position.length()>85):
			b.freeze=true;b.transform=homes[i];b.linear_velocity=Vector3.ZERO;b.angular_velocity=Vector3.ZERO;recovered+=1
			trails.erase(b.get_instance_id());status.text="Recovered an out-of-bounds body. RESET for a matched trial."

func record_trails() -> void:
	var mesh=ImmediateMesh.new();var segments: Array=[]
	for i in bodies.size():
		var b=bodies[i]
		if b.get_meta("no_trail",false):continue
		var id=b.get_instance_id();var path: Array=trails.get(id,[])
		if path.is_empty() or path.back().distance_to(b.position)>0.04:path.append(b.position)
		if path.size()>64:path.pop_front()
		trails[id]=path
		var colour=Color.from_hsv(fmod(float(i)*0.17,1),0.65,1.0)
		for j in range(1,path.size()):
			if path[j].distance_to(path[j-1])<5.0:segments.append([path[j-1],path[j],colour])
	if segments.is_empty():return
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for segment in segments:
		mesh.surface_set_color(segment[2]);mesh.surface_add_vertex(segment[0]);mesh.surface_add_vertex(segment[1])
	mesh.surface_end();trail_mesh.mesh=mesh

func install_adapter() -> void:
	for body in get_tree().get_nodes_in_group("player_body"):
		if not body is XRToolsPlayerBody or body.get_node_or_null("FieldCarryAdapter")!=null:continue
		var adapter=ADAPTER.new();adapter.name="FieldCarryAdapter";adapter.receiver=body;body.add_child(adapter)
		if adapter not in body._movement_providers:body._movement_providers.append(adapter)
		body._movement_providers.sort_custom(body.sort_by_order)

func _point_inside(world: Vector3) -> bool:
	var p=to_local(world)
	return kind in ["liquids","vortex","mutual","flight"] and absf(p.x)<extent.x*0.5 and absf(p.z)<extent.y*0.5 and p.y> -1 and p.y<9

func walk_velocity(body: CharacterBody3D) -> Vector3:
	if body is XRToolsPlayerBody:
		var frame=body.camera_node.global_basis
		return (frame.x.slide(Vector3.UP).normalized()*body.ground_control_velocity.x-frame.z.slide(Vector3.UP).normalized()*body.ground_control_velocity.y)*XRServer.world_scale
	var x=float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A))
	var z=float(Input.is_key_pressed(KEY_S))-float(Input.is_key_pressed(KEY_W))
	return body.global_basis*Vector3(x,0,z).normalized()*3.0

func carry_velocity(body: CharacterBody3D,dt: float,incoming: Vector3) -> Vector3:
	var v: Vector3=_carry.get(body.get_instance_id(),incoming)
	var desired=walk_velocity(body)
	v.x=move_toward(v.x,desired.x,6*dt);v.z=move_toward(v.z,desired.z,6*dt)
	v.y=maxf(-12,v.y-9.8*dt)
	return v

func record_carry(body: CharacterBody3D) -> void:_carry[body.get_instance_id()]=body.velocity
func release_carry(body: CharacterBody3D) -> void:_carry.erase(body.get_instance_id())
