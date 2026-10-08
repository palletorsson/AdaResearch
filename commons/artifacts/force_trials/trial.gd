extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Ten optional review encounters. Each scene selects one construction, not a film.
## Metres / kilograms / seconds. Contacts and joints use the project's physics engine.
const POINT = preload("res://commons/artifacts/force_capability_lab/loose_point.gd")
const CUBE = preload("res://commons/interactables/grab_cube.gd")
@export var kind := "mass"
var bodies: Array[RigidBody3D] = []
var homes: Array[Transform3D] = []
var members: Dictionary = {}
var active := false
var elapsed := 0.0
var pulse := 0.0
var emissions := 0
var selected_only := true
var receiver_open := false
var collected := 0
var recovered := 0
var note: Label3D
var hinge: HingeJoint3D
var arm: RigidBody3D
var gate: StaticBody3D
var reset_pending := false
var markers: Array[Vector3] = []
var trail_mesh: MeshInstance3D
var trail_time := 0.0
var ink: StandardMaterial3D
var pale: StandardMaterial3D
var pink: StandardMaterial3D
var initial_freeze: Array[bool] = []

func _ready() -> void:
	set_meta("em_keep_scale",true)
	add_to_group("force_review_trial")
	ink=material("17191e"); ink.roughness=0.14; ink.metallic=0.25
	pale=material("e7e3da"); pink=material("c67d9a")
	# An open, low trial field leaves passage around all four sides.
	box(Vector3(0,0.025,0),Vector3(8,0.05,8),pale,true)
	for x in [-4.0,4.0]: box(Vector3(x,0.16,0),Vector3(0.08,0.3,8),material("777782"),true)
	box(Vector3(0,0.16,4),Vector3(8,0.3,0.08),material("777782"),true)
	call("build_"+kind)
	button("RESET",Vector3(3.3,0,-4.7))
	note=plaque("Predict. Release. Keep the result.",Vector3(0,0.8,-4.5),0.001)
	trail_mesh=MeshInstance3D.new();trail_mesh.material_override=pink;add_child(trail_mesh)
	for b in bodies:
		homes.append(b.transform);initial_freeze.append(b.freeze)

func plaque(words: String, at: Vector3, pixels: float=0.0015) -> Label3D:
	var l := label(words,at,pixels); l.font_size=100;l.rotation.y=PI;l.modulate=Color("262830")
	return l

func heading(title: String, subtitle: String) -> void:
	box(Vector3(0,2.7,3.8),Vector3(7,1.0,0.06),pale)
	plaque(title,Vector3(0,2.95,3.75),0.002)
	plaque(subtitle,Vector3(0,2.52,3.75),0.0011)

func button(id: String, at: Vector3) -> void:
	box(at+Vector3.UP*0.5,Vector3(0.42,1,0.42),pale,true)
	var b=PUSH.instantiate();b.position=at+Vector3.UP*1.03;b.scale=Vector3.ONE*1.5
	add_child(b);buttons[id]=b;b.pressed.connect(act.bind(id))
	plaque(id,at+Vector3.UP*1.3,0.00095)

func point(at: Vector3, radius: float=0.22, mass_kg: float=1.0) -> RigidBody3D:
	var b=POINT.new();b.position=at;b.mass=mass_kg;b.freeze=true
	b.sphere.radius=radius;b.sphere.height=2*radius;b.get_child(1).shape.radius=radius
	b.get_child(0).material_override=ink
	b.collision_layer=4;b.collision_mask=524293;b.linear_damp=0.0;b.angular_damp=0.0
	b.continuous_cd=true;add_child(b);bodies.append(b);return b

func cube(at: Vector3, size: Vector3, mass_kg: float=1.0) -> RigidBody3D:
	var b=CUBE.new();b.cube_size=size.x;b.cube_color=Color("d9d6ce");b.mass=mass_kg
	b.position=at;b.freeze=true;b.linear_damp=0;b.angular_damp=0.05
	b.collision_layer=4;b.collision_mask=524293;b.continuous_cd=true;add_child(b)
	for child in b.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			child.mesh.size=size;child.material_override=pale
		if child is CollisionShape3D and child.shape is BoxShape3D:child.shape.size=size
	bodies.append(b);return b

func held(b: RigidBody3D) -> bool:
	if b.has_method("is_picked_up") and b.is_picked_up():return true
	if b.has_meta("capability_desktop_held"):return true
	for pointer in get_tree().get_nodes_in_group("desktop_interaction_pointer"):
		if pointer.get("_held")==b:return true
	# Desktop pointer has no shared group in older museum builds.
	for p in get_tree().root.find_children("*","Node3D",true,false):
		if p.has_method("_grab_held") and p.get("_held")==b:return true
	return false

func release_all() -> void:
	for b in bodies:
		if not held(b):b.freeze=false;b.sleeping=false

func reset_trial() -> bool:
	for b in bodies:
		if held(b):note.text="Put the held object down before resetting.";return false
	active=false;elapsed=0;emissions=0;collected=0;pulse=0;receiver_open=false
	markers.clear();trail_mesh.mesh=null
	for i in bodies.size():
		var b=bodies[i];b.freeze=true;b.transform=homes[i];b.linear_velocity=Vector3.ZERO;b.angular_velocity=Vector3.ZERO;b.sleeping=false
		if kind=="conveyor":b.get_node("TrialShape").disabled=false
	if gate != null:gate.position=Vector3(0,1.3,1.4)
	note.text="Reset. Predict again.";return true

func build_mass() -> void:
	heading("SAME FORCE / DIFFERENT MASS","A one-second push. Nothing tells the points where to stop.")
	for i in range(3):
		var b=point(Vector3(-2+i*2,0.55,-2.4),0.3,pow(2,i));b.gravity_scale=0;b.axis_lock_linear_y=true;b.axis_lock_linear_x=true
		box(Vector3(b.position.x,0.06,0),Vector3(0.6,0.04,6),material("b4b0ac"))
		plaque("%d kg" % b.mass,Vector3(b.position.x,1.25,-2.4))
	button("PUSH",Vector3(-2,0,-4.7))

func build_vortex() -> void:
	heading("THE DRAIN BECOMES AN ORBIT","Radial attraction + sideways force. Release with or without a sideways push.")
	for r in [0.8,1.6,2.4,3.2]:ring(Vector3(0,0.065,0),r,0.015,pink)
	point(Vector3(2.4,0.35,0));cube(Vector3(-2.5,0.35,-0.3),Vector3.ONE*0.4)
	for b in bodies:b.gravity_scale=0;b.axis_lock_linear_y=true
	button("SPIRAL",Vector3(-2,0,-4.7));button("RADIAL",Vector3(-0.7,0,-4.7))

func build_roll() -> void:
	heading("SLIDE / ROLL / TIP","Same slope. The left ball cannot rotate. The next one can.")
	for i in range(3):
		var x: float=-2+i*2
		var ramp=Node3D.new();ramp.position=Vector3(x,0.7,0);ramp.rotation.x=deg_to_rad(14);add_child(ramp)
		var deck=box(Vector3.ZERO,Vector3(1.45,0.15,5),pale,true,ramp)
		var mat=PhysicsMaterial.new();mat.friction=0.8
		deck.get_parent().get_child(1).physics_material_override=mat
		var b: RigidBody3D=point(Vector3(x,1.55,-1.8),0.28) if i<2 else cube(Vector3(x,1.55,-1.8),Vector3.ONE*0.5)
		b.physics_material_override=mat
		if i==0:b.axis_lock_angular_x=true;b.axis_lock_angular_y=true;b.axis_lock_angular_z=true
		if i<2:box(Vector3(0,0,0.28),Vector3(0.05,0.42,0.018),pink,false,b)
	button("RELEASE",Vector3(-2,0,-4.7))

func build_pipe() -> void:
	heading("WHERE THE PIPE LETS GO","An open curved channel changes the path. After its end, gravity continues.")
	var glass=material("9ab3c3");glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glass.albedo_color.a=0.18
	# Straight tangent after a quarter-circle, segmented collision walls, no path follower.
	for i in range(20):
		var angle: float=-PI/2+i*PI/2/19
		var at=Vector3(-1.8+2*cos(angle),1.7-i*0.035,-0.8+2*sin(angle))
		var section=Node3D.new();section.position=at;section.rotation.y=-angle;add_child(section)
		box(Vector3(0,-0.08,0),Vector3(0.6,0.12,0.23),pale,true,section)
		for x in [-0.34,0.34]:box(Vector3(x,0.23,0),Vector3(0.07,0.65,0.25),glass,true,section)
		if i%4==0:box(Vector3(at.x,at.y/2-0.1,at.z),Vector3(0.08,at.y-0.2,0.08),pale,true)
	point(Vector3(-1.8,1.96,-2.78),0.16)
	box(Vector3(0.2,0.13,2.6),Vector3(1.8,0.2,1.4),pink,true)
	for x in [-0.7,1.1]:box(Vector3(x,0.4,2.6),Vector3(0.08,0.5,1.4),pale,true)
	button("LAUNCH",Vector3(-2,0,-4.7))

func build_conveyor() -> void:
	heading("THE BELT KEEPS GOING","Pause the receiver. The belt keeps pushing. The queue has a history.")
	var belt=StaticBody3D.new();belt.position=Vector3(0,0.72,0);belt.constant_linear_velocity=Vector3(0,0,1.4);add_child(belt)
	box(Vector3.ZERO,Vector3(1.5,0.18,6.0),material("565862"),false,belt)
	var col=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(1.5,0.18,6);col.shape=shape;belt.add_child(col)
	for z in range(-3,4):box(Vector3(0,0.6,z),Vector3(1.8,0.12,0.12),pale,true)
	gate=StaticBody3D.new();gate.position=Vector3(0,1.3,1.4);add_child(gate)
	box(Vector3.ZERO,Vector3(1.5,1.0,0.15),pink,false,gate)
	var c=CollisionShape3D.new();var s=BoxShape3D.new();s.size=Vector3(1.5,1,0.15);c.shape=s;gate.add_child(c)
	for i in range(12):
		var b=cube(Vector3(-3+(i%3)*0.7,0.38,-2.5+(i/3)*0.7),Vector3.ONE*0.5)
		for child in b.get_children():
			if child is CollisionShape3D:child.name="TrialShape"
	button("FEED",Vector3(-2,0,-4.7));button("GATE",Vector3(-0.7,0,-4.7))

func build_attractor() -> void:
	heading("IT CAUGHT THE DOORSTOP","A selected point, or every loose body? The filter changes what the room loses.")
	var source=point(Vector3(0,1.0,2.4),0.38,4);members.source=source
	box(Vector3(0,0.35,2.4),Vector3(0.8,0.7,0.8),pale,true)
	var wanted=point(Vector3(-1.5,0.4,-1.2),0.27);members.wanted=wanted
	var stop=cube(Vector3(2.02,0.3,-0.65),Vector3(0.6,0.5,0.6),2);members.stop=stop
	var contact=PhysicsMaterial.new();contact.friction=0.6;stop.physics_material_override=contact
	var door=cube(Vector3(2.4,1.4,0.0),Vector3(0.16,2.6,1.8),3);members.door=door
	var anchor=StaticBody3D.new();anchor.position=Vector3(2.4,1.4,0.9);add_child(anchor)
	hinge=HingeJoint3D.new();hinge.position=anchor.position;hinge.rotation.x=PI/2;add_child(hinge)
	hinge.node_a=hinge.get_path_to(anchor);hinge.node_b=hinge.get_path_to(door);hinge.exclude_nodes_from_collision=true
	button("SELECTED",Vector3(-2,0,-4.7));button("ALL",Vector3(-0.7,0,-4.7))

func build_threebody() -> void:
	heading("THREE BODIES / TWO BEGINNINGS","Planar attraction, softened at close range. The right trio starts 0.03 m/s differently.")
	for side in range(2):
		var centre=Vector3(-2+side*4,0.55,0)
		ring(Vector3(centre.x,0.07,0),1.7,0.02,pink)
		for i in range(3):
			var a: float=TAU*i/3
			var b=point(centre+Vector3(cos(a),0,sin(a))*0.9,0.14)
			b.gravity_scale=0;b.axis_lock_linear_y=true;b.collision_mask=0;b.set_meta("side",side)
	button("RELEASE",Vector3(-2,0,-4.7))

func build_support() -> void:
	heading("REMOVE ONE SUPPORT","Four feet carry a loaded table. Pull the marked support; keep what falls.")
	for x in [-1.3,1.3]:
		for z in [-0.8,0.8]:
			var b=cube(Vector3(x,0.7,z),Vector3(0.48,1.3,0.48),2)
			if x>0 and z<0:members.foot=b
	var slab=cube(Vector3(0,1.45,0),Vector3(3.2,0.18,2.2),5);members.slab=slab
	for i in range(3):cube(Vector3(1.15,1.8+i*0.53,-0.75),Vector3.ONE*0.52,3)
	button("SETTLE",Vector3(-2,0,-4.7));button("PULL FOOT",Vector3(-0.5,0,-4.7))

func build_bowling() -> void:
	heading("ONE PUSH / TWO DIRECTIONS","The launch impulse has an equal opposite partner. Lock or free the cart.")
	var cart=cube(Vector3(0,0.35,-2.5),Vector3(1.3,0.4,0.8),3);members.cart=cart
	cart.axis_lock_linear_y=true;cart.axis_lock_angular_x=true;cart.axis_lock_angular_y=true;cart.axis_lock_angular_z=true
	var ball=point(Vector3(0,0.78,-2),0.25);members.ball=ball
	for row in range(3):
		for col in range(row+1):
			cube(Vector3((col-row*0.5)*0.6,0.55,0.8+row*0.65),Vector3(0.3,1,0.3),0.7)
	button("BRACED",Vector3(-2,0,-4.7));button("FREE",Vector3(-0.7,0,-4.7))

func build_catapult() -> void:
	heading("THE LEVER LETS GO","A hinged arm receives torque for 0.35 seconds. The point leaves through contact.")
	box(Vector3(0,0.3,0),Vector3(1.5,0.6,1),pale,true)
	var anchor=StaticBody3D.new();anchor.position=Vector3(0,1.45,0);add_child(anchor)
	for x in [-0.46,0.46]:box(Vector3(x,0.9,0),Vector3(0.15,1.4,0.28),pale,true)
	arm=cube(Vector3(0,1.45,0),Vector3(0.55,0.15,2.5),2);arm.rotation.x=deg_to_rad(-18)
	hinge=HingeJoint3D.new();hinge.position=anchor.position;hinge.rotation.y=PI/2;add_child(hinge)
	hinge.node_a=hinge.get_path_to(anchor);hinge.node_b=hinge.get_path_to(arm);hinge.exclude_nodes_from_collision=true
	# Cup floor is the lever itself; a rear rim stops the point rolling away before release.
	box(Vector3(0,0.18,-1.15),Vector3(0.55,0.28,0.08),pink,false,arm)
	var rim=CollisionShape3D.new();var rs=BoxShape3D.new();rs.size=Vector3(0.55,0.28,0.08);rim.shape=rs;rim.position=Vector3(0,0.18,-1.15);arm.add_child(rim)
	var b=point(Vector3.ZERO) # set the point on the actual inclined cup
	b.position=to_local(arm.to_global(Vector3(0,0.32,-0.9)));members.ball=b
	box(Vector3(0,0.1,2.5),Vector3(2,0.12,1.5),pink,true)
	button("FIRE",Vector3(-2,0,-4.7))

func ring(at: Vector3, radius: float, thickness: float, mat: Material) -> void:
	var m=MeshInstance3D.new();var torus=TorusMesh.new();torus.inner_radius=radius-thickness;torus.outer_radius=radius+thickness;torus.rings=48;torus.ring_segments=6;m.mesh=torus;m.position=at;m.material_override=mat;add_child(m)

func act(id: String) -> void:
	if id=="RESET":reset_pending=true;return
	if id=="GATE":
		receiver_open=not receiver_open;gate.position.y=3.4 if receiver_open else 1.3
		note.text="Receiver open. The backlog still has to move." if receiver_open else "Receiver closed. The belt continues.";return
	if id=="PULL FOOT":
		members.foot.freeze=false;members.foot.apply_central_impulse(global_basis*Vector3(18,0,-12));return
	if active and kind in ["mass","roll","pipe","threebody","bowling","catapult"]:
		note.text="Keep the aftermath, or RESET for a matched trial.";return
	active=true;elapsed=0
	match kind:
		"mass":release_all();pulse=1.0
		"vortex":
			release_all();selected_only=(id=="RADIAL")
			if not selected_only:bodies[0].linear_velocity=global_basis*Vector3(0,0,1.8)
		"roll","support":release_all()
		"pipe":release_all();bodies[0].linear_velocity=global_basis*Vector3(2.6,0,0)
		"conveyor":pass
		"attractor":
			selected_only=(id=="SELECTED");members.wanted.freeze=false;members.stop.freeze=false;members.door.freeze=false
		"threebody":
			release_all()
			for i in bodies.size():
				var a: float=TAU*(i%3)/3
				bodies[i].linear_velocity=global_basis*Vector3(-sin(a),0,cos(a))*0.7
			bodies[3].linear_velocity+=global_basis*Vector3(0.03,0,0)
		"bowling":
			release_all();members.cart.freeze=(id=="BRACED")
			members.ball.apply_central_impulse(global_basis*Vector3(0,0,6))
			if id=="FREE":members.cart.apply_central_impulse(global_basis*Vector3(0,0,-6))
		"catapult":release_all();pulse=0.35
	note.text="The experiment is running. Misses stay until RESET."

func _physics_process(dt: float) -> void:
	if reset_pending:reset_pending=false;reset_trial();return
	if not active:return
	elapsed+=dt
	match kind:
		"mass":
			if pulse>0:
				for b in bodies:b.apply_central_force(global_basis*Vector3(0,0,2))
				pulse-=dt
			note.text="Speed  %.2f / %.2f / %.2f m/s" % [bodies[0].linear_velocity.length(),bodies[1].linear_velocity.length(),bodies[2].linear_velocity.length()]
		"vortex":
			for b in bodies:
				if b.freeze:continue
				var r: Vector3=b.position*Vector3(1,0,1)
				var tangent=Vector3(-r.z,0,r.x).normalized()
				b.apply_central_force(global_basis*(-r*1.4+tangent*(0.0 if selected_only else 0.7))-b.linear_velocity*0.18)
		"conveyor":
			if emissions<12 and elapsed>emissions*0.7:
				var b=bodies[emissions];b.position=Vector3(0,1.3,-2.6);b.freeze=false;b.sleeping=false;emissions+=1
			for b in bodies:
				if receiver_open and not b.freeze and b.position.z>2.6:
					b.freeze=true;b.position=Vector3(2.1+(collected%2)*0.65,0.4+(collected/4)*0.55,1+(collected%4)/2*0.65);b.get_node("TrialShape").disabled=true;collected+=1
			note.text="Feed %d / 12     Received %d     Objects persist" % [emissions,collected]
		"attractor":
			for b in [members.wanted,members.stop]:
				if b.freeze or (selected_only and b==members.stop):continue
				var offset: Vector3=members.source.global_position-b.global_position
				b.apply_central_force(offset.normalized()*80.0/(1+offset.length_squared()*0.15))
			members.door.apply_torque(global_basis*Vector3(0,2.5,0))
		"threebody":
			for side in range(2):
				for i in range(3):
					for j in range(i+1,3):
						var a=bodies[side*3+i];var b=bodies[side*3+j]
						var r=b.global_position-a.global_position
						var f=r*1.2/pow(r.length_squared()+0.16,1.5)
						a.apply_central_force(f);b.apply_central_force(-f)
			note.text="Paired states differ by %.4f m\nNo scripted divergence; no claim every start is chaotic." % ((bodies[0].position-Vector3(-2,0,0))-(bodies[3].position-Vector3(2,0,0))).length()
		"catapult":
			if pulse>0:arm.apply_torque(global_basis*Vector3(30,0,0));pulse-=dt
	# Keep finite trails; motion remains physical. Lost-object recovery never erases an ordinary miss.
	trail_time+=dt
	if trail_time>0.1 and kind in ["vortex","threebody","pipe","catapult"]:
		trail_time=0
		for b in bodies:markers.append(b.position)
		if markers.size()>600:markers=markers.slice(markers.size()-600)
		var mesh=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		for p in markers:mesh.surface_add_vertex(p);mesh.surface_add_vertex(p+Vector3.UP*0.035)
		mesh.surface_end();trail_mesh.mesh=mesh
	for i in bodies.size():
		var b=bodies[i]
		if b.position.y < -8 or b.position.length()>35:
			b.freeze=true;b.transform=homes[i];b.linear_velocity=Vector3.ZERO;b.angular_velocity=Vector3.ZERO;recovered+=1
			note.text="A body left the trial bounds and was returned. RESET for a matched trial."
