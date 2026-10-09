extends "res://commons/artifacts/force_play/play_space.gd"
## Larger hand-led encounters. Engine contact/joints; explicit forces in SI units.
const GUN=preload("res://commons/artifacts/force_play/gravity_point.gd")
const THRUSTER=preload("res://commons/artifacts/force_capability_lab/force_point.gd")
var links: Array=[]
var readouts: Array=[]
var field_arrows: Array=[]
var visitor_override: Node3D
var magnet_remaining:=0.0
var magnet_releases:=0
var checkpoint:=0
var flight_points: Array=[]
var flight_mat: Node3D
var flight_origin:=Vector3(0,0.14,-10)
var last_forces: Array=[]

func build() -> void:
	match kind:
		"tower":build_tower()
		"gravity":build_gravity()
		"mass":build_mass()
		"trolley":build_trolley()
		"puzzle":build_puzzle()
		"bowling":build_bowling()
		"recoil":build_recoil()
		"friction":build_friction()
		"liquids":build_liquids()
		"springs":build_springs()
		"swings":build_swings()
		"torque":build_torque()
		"constraints":build_constraints()
		"magnet":build_magnet()
		"vortex":build_vortex()
		"mutual":build_mutual()
		"support":build_support()
		"flight":build_flight()

func prefab(at: Vector3,index: int,mass_kg:=1.0) -> RigidBody3D:
	match index%3:
		0:return sphere(at,0.25,mass_kg)
		1:return solid(at,Vector3(0.5,0.5,0.5),mass_kg,pink)
		_:return cylinder_body(at,0.23,0.55,mass_kg)

func beam(at: Vector3,size: Vector3,mat: Material=null) -> StaticBody3D:
	return fixed(at,size,mat if mat!=null else ink)

func build_tower() -> void:
	extent=Vector2(10,12);floor_patch(extent)
	title("ONE BRICK HOLDS THE QUESTION","Pull the rose support. The remaining bodies keep their own momentum.",6.7)
	var key=solid(Vector3(0,0.45,0),Vector3(1.1,0.8,1.3),5,pink)
	members.key=key
	var slab=solid(Vector3(0,0.96,0),Vector3(2.15,0.2,2.15),3,ink)
	members.slab=slab
	# The low, visible edge catches one side when the main support is removed.
	beam(Vector3(-0.91,0.14,0),Vector3(0.22,0.18,2.3),blue)
	for course in range(14):
		for j in range(3):
			var pos=Vector3((j-1)*0.7,1.23+course*0.34,0)
			var size=Vector3(0.67,0.32,2.05)
			if course%2:pos=Vector3(0,pos.y,(j-1)*0.7);size=Vector3(2.05,0.32,0.67)
			var brick=solid(pos,size,0.7,pale if course%2 else blue)
			brick.physics_material_override=physics_material(0.75,0.02)
	words("PULL THIS BRICK",Vector3(0,0.9,-1.3),0.001)
	for b in bodies:b.can_sleep=false
	var mini=load("res://commons/artifacts/force_play/stacking_table.tscn").instantiate()
	mini.name="MiniStackingTable";mini.position=Vector3(0,0,-3.7);add_child(mini)

func build_gravity() -> void:
	extent=Vector2(22,10);floor_patch(extent)
	title("THE ROOM LETS GO","Enter the rose threshold: cargo, trapdoor and pole lose support.")
	var pier=beam(Vector3(-7,0.3,1),Vector3(0.5,0.6,0.5))
	var pole=solid(Vector3(-7,2.2,1),Vector3(0.24,3.8,0.24),4,pink)
	pole.rotation.z=0.09;hinge_at(pier,pole,Vector3(-7,0.3,1),Vector3.FORWARD,PI/2);pole.freeze=true
	var frame=beam(Vector3(0,1.3,2.6),Vector3(4,0.2,0.2))
	var door=solid(Vector3(0,1.3,1),Vector3(3.8,0.16,3.1),3,blue)
	hinge_at(frame,door,Vector3(0,1.3,2.55),Vector3.RIGHT,PI/2);door.freeze=true
	for i in range(6):prefab(Vector3((i%3-1)*0.65,1.8+(i/3)*0.65,1),i)
	var cargo=solid(Vector3(7,3.7,1),Vector3(1.1,1.1,1.1),6,pink);cargo.freeze=true
	rod(Vector3(7,4.8,1),cargo.position,ink,0.035)
	beam(Vector3(7,4.9,1),Vector3(3,0.2,0.25));beam(Vector3(8.4,2.5,1),Vector3(0.2,5,0.2))
	members.released=[pole,door,cargo]
	var area=Area3D.new();area.position=Vector3(0,1,-3);area.collision_layer=0;area.collision_mask=524290;add_child(area)
	var c=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(10,2,1.5);c.shape=shape;area.add_child(c)
	area.body_entered.connect(func(b):
		if b is CharacterBody3D:action("RELEASE"))
	box(Vector3(0,0.06,-3),Vector3(10,0.03,1.5),pink)
	control("RELEASE",Vector3(-4,0,-3))

func build_mass() -> void:
	extent=Vector2(12,10);floor_patch(extent)
	title("SAME FORCE / DIFFERENT MASS","Three identical PointBody spheres. One newton for one second.")
	for i in range(3):
		var x=(i-1)*3.2
		var b=sphere(Vector3(x,0.42,-2.8),0.36,pow(2,i))
		b.gravity_scale=0;b.axis_lock_linear_y=true;b.axis_lock_linear_x=true;b.linear_damp=0;b.linear_damp_mode=RigidBody3D.DAMP_MODE_REPLACE
		b.physics_material_override=physics_material(0,0)
		box(Vector3(x,0.065,0),Vector3(2.2,0.025,8),blue)
		readouts.append(words("",Vector3(x,1.15,-2.9),0.001))
	control("PUSH 1 s",Vector3(-4.8,0,-3.8))

func build_trolley() -> void:
	extent=Vector2(10,10);floor_patch(extent)
	title("LOAD CHANGES THE PUSH","Pull the rose handle; add the loose cargo.")
	var cart=solid(Vector3(0,0.65,-1),Vector3(2.6,0.28,2.3),3,blue)
	cart.axis_lock_angular_x=true;cart.axis_lock_angular_z=true;cart.physics_material_override=physics_material(0.08)
	for x in [-1.05,1.05]:
		for z in [-0.8,0.8]:
			var wheel=MeshInstance3D.new();var mesh=CylinderMesh.new();mesh.top_radius=0.3;mesh.bottom_radius=0.3;mesh.height=0.15;wheel.mesh=mesh;wheel.material_override=ink;wheel.rotation.z=PI/2;wheel.position=Vector3(x,-0.32,z);cart.add_child(wheel)
			var contact=CollisionShape3D.new();var bound=SphereShape3D.new();bound.radius=0.3;contact.shape=bound;contact.position=wheel.position;cart.add_child(contact)
	# Wheels are a visual cue; the measured resistance is a declared sliding contact.
	box(Vector3(0,0.6,-1.15),Vector3(2.1,0.12,0.12),pink,false,cart)
	grip(cart,Vector3(0,0.6,-1.15));members.cart=cart
	for i in range(5):prefab(Vector3(2.9,0.4+i*0.6,1),i,2)
	words("3 kg cart + 2 kg per parcel\nLow-friction sliding base",Vector3(0,1.8,-1),0.0009)

func build_puzzle() -> void:
	extent=Vector2(10,10);floor_patch(extent)
	title("MAKE ROOM FOR A BODY","Push the cubes through the staggered openings.")
	for i in range(3):
		var x=(i-1)*2.8
		var b=solid(Vector3(x,0.55,-3),Vector3.ONE,1+i*2,ink);b.physics_material_override=physics_material(0.35)
		box(Vector3(x,0.07,3.2),Vector3(1.25,0.03,1.25),pink)
		beam(Vector3(x-1.0,0.4,0.5),Vector3(0.25,0.8,3),blue)
		words(str(b.mass)+" kg",Vector3(x,1.3,-3),0.0009)
	beam(Vector3(4,0.4,0.5),Vector3(0.25,0.8,3),blue)

func bowling_pin(at: Vector3) -> RigidBody3D:
	var b=BODY.new();b.position=at;b.mass=0.7
	b.center_of_mass_mode=RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM;b.center_of_mass=Vector3(0,0.60,0)
	var profile=[Vector2(0,0.105),Vector2(0.04,0.14),Vector2(0.22,0.22),Vector2(0.38,0.20),Vector2(0.53,0.13),Vector2(0.70,0.09),Vector2(0.81,0.145),Vector2(0.97,0.145),Vector2(1.05,0.03)]
	var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(profile.size()-1):
		for i in range(24):
			var a=TAU*i/24;var next=TAU*(i+1)/24
			for address in [[row,a],[row+1,a],[row+1,next],[row,a],[row+1,next],[row,next]]:
				var p: Vector2=profile[address[0]];var angle: float=address[1]
				surface.set_normal(Vector3(cos(angle),0,sin(angle)))
				surface.add_vertex(Vector3(cos(angle)*p.y,p.x,sin(angle)*p.y))
	var mesh=MeshInstance3D.new();mesh.mesh=surface.commit();mesh.material_override=pale;b.add_child(mesh)
	for spec in [[0.105,0.08,0.04],[0.19,0.25,0.29],[0.085,0.38,0.59],[0.13,0.18,0.89]]:
		var c=CollisionShape3D.new();var s=CylinderShape3D.new();s.radius=spec[0];s.height=spec[1];c.shape=s;c.position.y=spec[2];b.add_child(c)
	var stripe=MeshInstance3D.new();var ring=CylinderMesh.new();ring.top_radius=0.1;ring.bottom_radius=0.11;ring.height=0.075;stripe.mesh=ring;stripe.material_override=pink;stripe.position.y=0.65;b.add_child(stripe)
	add_child(b);b.physics_material_override=physics_material(0.9,0.12);return remember(b)

func build_bowling() -> void:
	extent=Vector2(10,25);floor_patch(extent)
	title("TEN PINS / ONE COMMITMENT","Roll the point. Bumpers and a bank keep the consequences in play.",4)
	box(Vector3(0,0.06,0),Vector3(4.3,0.04,23),blue)
	for x in [-2.4,2.4]:
		beam(Vector3(x,0.38,0),Vector3(0.24,0.65,23),pink)
		var bank=beam(Vector3(x*1.24,0.24,0),Vector3(1,0.2,23),ink);bank.rotation.z=signf(x)*0.28
	beam(Vector3(0,0.5,11.5),Vector3(6.6,0.9,0.3),pink)
	var pins: Array=[]
	for row in range(4):
		for col in range(row+1):pins.append(bowling_pin(Vector3((col-row*0.5)*0.62,0.1,6+row*0.57)))
	members.pins=pins;members.ball=sphere(Vector3(0,0.44,-9.5),0.34,3)
	members.ball.physics_material_override=physics_material(0.55,0.1)
	members.ball.linear_damp=0;members.ball.linear_damp_mode=RigidBody3D.DAMP_MODE_REPLACE
	control("ROLL",Vector3(-3.8,0,-9.5))
	for z in range(-8,8,2):box(Vector3(0,0.09,z),Vector3(0.08,0.02,0.18),pale)

func build_recoil() -> void:
	extent=Vector2(12,10);floor_patch(extent)
	title("THE LAUNCHER ALSO MOVES","Same opposite impulse. Compare a free cart and a braced cart.")
	var carts: Array=[];var balls: Array=[]
	for i in range(2):
		var x=-2.8+i*5.6
		box(Vector3(x,0.07,0),Vector3(3.8,0.035,8),blue)
		var c=solid(Vector3(x,0.4,-1.4),Vector3(1.5,0.5,1.4),4,pink);c.freeze=i==1;c.axis_lock_linear_x=true;c.axis_lock_linear_y=true;c.lock_rotation=true;c.linear_damp=0;c.linear_damp_mode=RigidBody3D.DAMP_MODE_REPLACE;c.physics_material_override=physics_material(0)
		for wx in [-0.66,0.66]:
			for wz in [-0.46,0.46]:
				var wheel=MeshInstance3D.new();var mesh=CylinderMesh.new();mesh.top_radius=0.15;mesh.bottom_radius=0.15;mesh.height=0.14;wheel.mesh=mesh;wheel.material_override=ink;wheel.position=Vector3(wx,-0.2,wz);wheel.rotation.z=PI/2;c.add_child(wheel)
		var b=sphere(Vector3(x,0.44,0),0.35,1);b.gravity_scale=0;b.axis_lock_linear_y=true;b.axis_lock_linear_x=true;b.linear_damp=0;b.linear_damp_mode=RigidBody3D.DAMP_MODE_REPLACE;b.physics_material_override=physics_material(0)
		carts.append(c);balls.append(b);words("FREE" if i==0 else "BRACED",Vector3(x,1.3,-2.2),0.001)
	members.carts=carts;members.balls=balls;control("FIRE",Vector3(0,0,-3.4))

func build_friction() -> void:
	extent=Vector2(24,16);floor_patch(extent)
	title("THE SLOPE DOES NOT CHOOSE THE ENDING","Release together; compare sliding, rolling and rough contact.",4.4)
	var runners: Array=[]
	for i in range(4):
		var x=(i-1.5)*5.2
		var ramp=beam(Vector3(x,1.05,0),Vector3(4.2,0.18,11),pale if i%2 else blue);ramp.rotation.x=0.18
		ramp.physics_material_override=physics_material(0.03 if i<2 else 0.95)
		for edge in [-2.15,2.15]:
			var side=beam(Vector3(x+edge,1.22,0),Vector3(0.12,0.55,11),pink);side.rotation.x=0.18
		var p=Vector3(x,2.25,-4.3)
		var b=sphere(p,0.34,1) if i%2 else solid(p,Vector3.ONE*0.65,1,ink)
		b.physics_material_override=physics_material(0.03 if i<2 else 0.95);b.freeze=true;runners.append(b)
		words(["SMOOTH / CUBE","SMOOTH / BALL","ROUGH / CUBE","ROUGH / BALL"][i],Vector3(x,2.9,-4.3),0.0009)
		for j in range(3):cylinder_body(Vector3(x+(j-1)*0.8,0.45,6.3),0.18,0.75,0.4)
	members.runners=runners;control("RELEASE",Vector3(-10.5,0,-6.4))

func build_liquids() -> void:
	extent=Vector2(24,16);floor_patch(extent)
	title("WALK INTO RESISTANCE","A drag-and-buoyancy model. Same point, three coefficients; no fluid solver.",4.4)
	for i in range(3):
		var x=(i-1)*7.2
		var liquid=material(["72ceec","ba75d6","e8ad4a"][i]);liquid.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;liquid.albedo_color.a=0.17;liquid.cull_mode=BaseMaterial3D.CULL_DISABLED
		box(Vector3(x,1.65,0),Vector3(5.7,3.2,11),liquid)
		box(Vector3(x,0.07,0),Vector3(5.7,0.04,11),blue if i==0 else pink)
		words(["THIN","THICK","VERY THICK"][i],Vector3(x,3.8,0),0.0016)
		var b=sphere(Vector3(x,4.0,0),0.32,1);b.freeze=true
		members["drop"+str(i)]=b
	control("DROP",Vector3(0,0,-6.5))

func fluid_index(p: Vector3) -> int:
	if absf(p.z)>5.5 or p.y<0 or p.y>3.3:return -1
	for i in range(3):
		if absf(p.x-(i-1)*7.2)<2.85:return i
	return -1

func add_link(a: RigidBody3D,b: RigidBody3D,anchor: Vector3,rest: float,k: float,c: float) -> void:
	links.append({"a":a,"b":b,"anchor":anchor,"rest":rest,"k":k,"c":c,"rod":rod(Vector3.ZERO,Vector3.UP,blue,0.025)})

func build_springs() -> void:
	extent=Vector2(18,12);floor_patch(extent)
	title("PULL ONE / DISTURB THE ROW","Hanging points share springs. Hold, swing, collide, release.",4.3)
	beam(Vector3(0,3.5,0),Vector3(14,0.22,0.24));beam(Vector3(-6.9,1.75,0),Vector3(0.2,3.5,0.2));beam(Vector3(6.9,1.75,0),Vector3(0.2,3.5,0.2))
	for i in range(7):
		var x=(i-3)*1.7
		var b=sphere(Vector3(x,1.6,0),0.34,1)
		add_link(b,null,Vector3(x,3.4,0),1.5,32,0.5)
		if i>0:add_link(b,bodies[i-1],Vector3.ZERO,1.7,18,0.12)

func swing(x: float,z: float,damping: float) -> RigidBody3D:
	var anchor=beam(Vector3(x,3.2,z),Vector3(0.3,0.22,0.3))
	var body=solid(Vector3(x,2.3,z),Vector3(0.12,1.7,0.12),1,ink)
	box(Vector3(0,-0.85,0),Vector3(1.15,0.16,0.7),pink,false,body)
	var collider=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(1.15,0.16,0.7);collider.shape=shape;collider.position.y=-0.85;body.add_child(collider)
	hinge_at(anchor,body,Vector3(x,3.15,z),Vector3.RIGHT,1.3)
	body.set_meta("damper",damping);body.angular_damp=0;body.angular_damp_mode=RigidBody3D.DAMP_MODE_REPLACE
	grip(body,Vector3(0,-0.85,0));return body

func build_swings() -> void:
	extent=Vector2(24,11);floor_patch(extent)
	title("HOW LONG SHOULD A DISTURBANCE LAST?","Three connected swing pairs. Equal nudge, increasing damping.",4.1)
	for i in range(3):
		var x=(i-1)*7.4
		beam(Vector3(x,3.35,0),Vector3(5,0.18,0.2))
		beam(Vector3(x-2.45,1.7,0),Vector3(0.14,3.4,0.14));beam(Vector3(x+2.45,1.7,0),Vector3(0.14,3.4,0.14))
		var a=swing(x-1,0,[0.03,0.8,3.5][i]);var b=swing(x+1,0,[0.03,0.8,3.5][i])
		add_link(a,b,Vector3.ZERO,2,8,0)
		words(["ALMOST FREE","SETTLING","SOFT CLOSE"][i],Vector3(x,2.2,-2),0.001)
	control("NUDGE",Vector3(0,0,-4))

func build_torque() -> void:
	extent=Vector2(22,10);floor_patch(extent)
	title("WHERE YOU PUSH MATTERS","A gate, seesaw and crank. Pull the rose grips; the joints stay attached.",4.1)
	var post=beam(Vector3(-9,1,0),Vector3(0.25,2,0.25))
	var gate=solid(Vector3(-7.3,1,0),Vector3(3.3,1.5,0.16),4,pale);hinge_at(post,gate,Vector3(-8.94,1,0),Vector3.UP,1.5)
	grip(gate,Vector3(1.4,0,0));grip(gate,Vector3(-1.2,0,0))
	var fulcrum=beam(Vector3(0,0.65,0),Vector3(0.35,1.3,1.5))
	var see=solid(Vector3(0,1.35,0),Vector3(5,0.2,1.3),3,blue);hinge_at(fulcrum,see,Vector3(0,1.35,0),Vector3.FORWARD,0.45)
	grip(see,Vector3(-2,0,0));grip(see,Vector3(2,0,0));prefab(Vector3(1.4,1.8,0),1,3)
	var stand=beam(Vector3(7,1,0.4),Vector3(0.3,2,0.4))
	var crank=solid(Vector3(7,1.3,0),Vector3(2.8,0.15,0.15),2,pink);hinge_at(stand,crank,Vector3(7,1.3,0),Vector3.FORWARD,PI)
	grip(crank,Vector3(1.25,0,0));grip(crank,Vector3(0.35,0,0))

func build_constraints() -> void:
	extent=Vector2(24,11);floor_patch(extent)
	title("ATTACHMENT CHANGES THE POSSIBLE","Swing a basket, a chain, a suspended plank and a two-joint arm.",4.3)
	for x in [-9,-3,3,9]:beam(Vector3(x,3.3,0),Vector3(4,0.2,0.2));beam(Vector3(x-1.9,1.65,0),Vector3(0.14,3.3,0.14))
	var anchor=beam(Vector3(-9,3.1,0),Vector3(0.2,0.2,0.2))
	var basket=solid(Vector3(-9,1.6,0),Vector3(1.6,0.18,1.4),2,blue)
	for x in [-0.74,0.74]:
		box(Vector3(x,0.32,0),Vector3(0.12,0.65,1.4),pale,false,basket)
		var c=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(0.12,0.65,1.4);c.shape=shape;c.position=Vector3(x,0.32,0);basket.add_child(c)
	# Pin joint at the suspension point; the rigid connector is part of the basket body.
	box(Vector3(0,0.75,0),Vector3(0.06,1.5,0.06),ink,false,basket)
	pin_at(anchor,basket,Vector3(-9,3.1,0));grip(basket,Vector3(0,0.2,-0.7));sphere(Vector3(-9,1.95,0),0.22)
	var previous: Node3D=beam(Vector3(-3,3.1,0),Vector3(0.2,0.2,0.2))
	for i in range(3):
		var link=solid(Vector3(-3,2.72-i*0.76,0),Vector3(0.18,0.73,0.18),1,pink);pin_at(previous,link,Vector3(-3,3.1-i*0.76,0));previous=link
	grip(previous,Vector3(0,-0.3,0))
	var plank=solid(Vector3(3,1.3,0),Vector3(3,0.18,1),3,pale)
	var bar=beam(Vector3(3,3.1,0),Vector3(3,0.14,0.14))
	pin_at(bar,plank,Vector3(1.7,3.1,0));pin_at(bar,plank,Vector3(4.3,3.1,0));grip(plank,Vector3(0,0,-0.45))
	for x in [-1.3,1.3]:box(Vector3(x,0.9,0),Vector3(0.035,1.8,0.035),ink,false,plank)
	var base=beam(Vector3(7.6,0.65,0),Vector3(0.3,1.3,0.4))
	var upper=solid(Vector3(8.5,1.3,0),Vector3(1.8,0.17,0.2),2,blue);hinge_at(base,upper,Vector3(7.6,1.3,0),Vector3.FORWARD,1.3)
	var lower=solid(Vector3(10,1.3,0),Vector3(1.2,0.17,0.2),1,pink);hinge_at(upper,lower,Vector3(9.4,1.3,0),Vector3.FORWARD,1.5)
	var handle=grip(lower,Vector3(0.5,0,0));members.jaw_open=true;members.jaws=[]
	for side in [-1,1]:
		var jaw=box(Vector3(0.5,-0.32,side*0.44),Vector3(0.5,0.65,0.14),blue,false,lower)
		var shape=CollisionShape3D.new();var bound=BoxShape3D.new();bound.size=Vector3(0.5,0.65,0.14);shape.shape=bound;shape.position=Vector3(0.5,-0.32,side*0.44);lower.add_child(shape)
		members.jaws.append([jaw,shape,side])
	handle.action_pressed.connect(func(_p):members.jaw_open=not members.jaw_open)
	for i in range(2):solid(Vector3(10,0.34,1.5+i*0.8),Vector3.ONE*0.5,0.6,blue)
	words("CLAW: TRIGGER TO OPEN / CLOSE",Vector3(9,2,-2),0.0007)

func build_magnet() -> void:
	extent=Vector2(14,14);floor_patch(extent)
	title("THE CATCH MUST END","Activate the magnet: three seconds of attraction, then release.",4.7)
	for x in [-2,2]:beam(Vector3(x,1.7,1),Vector3(0.55,3.4,0.6),pink)
	beam(Vector3(0,3.7,1),Vector3(4.5,0.6,0.6),pink)
	members.source=Vector3(0,2.7,1)
	for i in range(12):prefab(Vector3((i%4-1.5)*1.2,0.5+(i/4)*0.7,-0.5),i,0.8+(i%3)*0.4)
	control("MAGNET 3 s",Vector3(-3.3,0,-2))
	var gun=GUN.new();gun.position=Vector3(3.6,1.15,-2.5);gun.candidates=bodies.duplicate();add_child(gun);members.gun=gun;remember(gun)
	beam(Vector3(3.6,0.45,-2.5),Vector3(0.65,0.9,0.65),pale)
	words("GRAVITY POINT\nGrab / aim / trigger / release",Vector3(3.6,1.7,-2.5),0.00085)

func swirl(p: Vector3) -> Vector3:
	var flat=Vector3(p.x,0,p.z);var distance=flat.length()
	if distance<0.05:return Vector3.ZERO
	return -flat*0.65+Vector3(-flat.z,0,flat.x).normalized()*2.8

func build_vortex() -> void:
	extent=Vector2(20,18);floor_patch(extent)
	title("THE FIELD TAKES A TURN","Walk into the arrows. Point, cube and cylinder meet the same acceleration.",4.4)
	for i in range(18):
		var a=TAU*i/18.0
		var b=prefab(Vector3(cos(a)*5,1.1+(i%3)*0.35,sin(a)*5),i)
		b.gravity_scale=0;b.axis_lock_linear_y=true;b.linear_damp=0.12
		b.linear_velocity=Vector3(-sin(a),0,cos(a))*1.8
	for x in range(-6,7,2):
		for z in range(-6,7,2):
			var p=Vector3(x,0.15,z);field_arrows.append(rod(p,p+swirl(p)*0.32,blue,0.022,true))

func build_mutual() -> void:
	extent=Vector2(20,20);floor_patch(extent)
	title("YOU BECOME ANOTHER SOURCE","Softened attraction; contact off. Enter the field to disturb the orbits.",4.5)
	for i in range(5):
		var a=TAU*i/5
		var b=sphere(Vector3(cos(a)*5,1.5,sin(a)*5),0.32,2)
		b.gravity_scale=0;b.axis_lock_linear_y=true;b.collision_mask=0;b.collision_layer=0;b.linear_damp=0;b.linear_damp_mode=RigidBody3D.DAMP_MODE_REPLACE
		b.linear_velocity=Vector3(-sin(a),0,cos(a))*1.45
	words("Visitor source: model mass 6 kg\nG = 4 · softening = 1.2 m",Vector3(0,0.8,-7),0.001)

func visitor() -> Node3D:
	if is_instance_valid(visitor_override):return visitor_override
	var navigation=get_tree().get_first_node_in_group("museum_portal_navigation")
	if navigation!=null and not bool(navigation.museum.get("_vr")):
		var player=navigation.museum.get("_player")
		if player is Node3D and _point_inside(player.global_position):return player
	for body in get_tree().get_nodes_in_group("player_body"):
		if body is Node3D and _point_inside(body.global_position):return body
	for body in get_tree().get_nodes_in_group("player"):
		if body is CharacterBody3D and _point_inside(body.global_position):return body
	return null

func attraction(a: Vector3,b: Vector3,ma: float,mb: float) -> Vector3:
	var r=b-a
	return r*4.0*ma*mb/pow(r.length_squared()+1.44,1.5)

func build_support() -> void:
	extent=Vector2(18,16);floor_patch(extent)
	title("MOVE A LEG / INHERIT THE LOAD","Nothing is scripted to fall. The contact arrangement carries the table.",5.5)
	for x in [-1.7,1.7]:
		for z in [-1.2,1.2]:
			var leg=solid(Vector3(x,0.68,z),Vector3(0.6,1.25,0.6),3,pink if x>0 and z<0 else ink)
			if x>0 and z<0:members.leg=leg
	var table=solid(Vector3(0,1.41,0),Vector3(4.1,0.2,3.1),4,pale);members.table=table
	# Most of the load is over the removable corner, outside the remaining support triangle.
	members.load=[]
	for i in range(9):
		var c=solid(Vector3(1.25,1.832+(i/3)*0.642,-1.0+(i%3)*0.69),Vector3(0.7,0.64,0.64),3,blue if i%2 else pale)
		c.physics_material_override=physics_material(0.8,0)
		c.linear_damp=0.15;c.angular_damp=0.15;members.load.append(c)
	for i in range(4):prefab(Vector3(-1+(i%2)*0.7,1.84+(i/2)*0.65,0.6),i,0.4)
	words("THE ROSE LEG",Vector3(2.3,1.1,-2),0.001)
	for b in bodies:
		b.can_sleep=false;b.physics_material_override=physics_material(0.8,0)

func build_flight() -> void:
	extent=Vector2(14,26);floor_patch(extent,ink)
	title("A MAT / TWO POINTS / A WAY THROUGH","Stand on the mat; point where you want to fly and hold the triggers. Release to coast.",5)
	flight_mat=Node3D.new();flight_mat.position=flight_origin;add_child(flight_mat)
	box(Vector3.ZERO,Vector3(2.1,0.16,1.6),pink,false,flight_mat)
	for i in range(8):box(Vector3((i-3.5)*0.23,0.09,0),Vector3(0.1,0.02,1.4),blue,false,flight_mat)
	for x in [-0.55,0.55]:
		var p=THRUSTER.new();p.position=flight_origin+Vector3(x,1.1,0);add_child(p);flight_points.append(p);remember(p)
	var gates: Array=[]
	for spec in [[-3,1.8,-5],[3,3.0,0],[-3,4.0,5],[0,2.2,9]]:
		var at=Vector3(spec[0],spec[1],spec[2]);gates.append(at)
		var m=MeshInstance3D.new();var torus=TorusMesh.new();torus.inner_radius=1.0;torus.outer_radius=1.12;torus.rings=40;torus.ring_segments=8;m.mesh=torus;m.material_override=blue;m.position=at;m.rotation.x=PI/2;add_child(m)
		words(str(gates.size()),at+Vector3.UP*1.35,0.0014)
	members.gates=gates
	for x in [-6.6,6.6]:beam(Vector3(x,0.45,0),Vector3(0.18,0.9,25),blue)
	words("Start here. Carry the two points through the gates.\nThe mat follows your feet; gravity still acts.",Vector3(0,2,-10),0.0008)

func action(id: String) -> void:
	match kind:
		"mass":
			if id=="PUSH 1 s":pulse=1
		"gravity":
			if id=="RELEASE":
				for b in members.released:b.freeze=false;b.sleeping=false
		"friction":
			if id=="RELEASE":
				for b in members.runners:b.freeze=false;b.sleeping=false
		"liquids":
			if id=="DROP":
				for b in bodies:b.freeze=false;b.sleeping=false
		"bowling":
			if id=="ROLL":members.ball.apply_central_impulse(global_basis*Vector3(0,0,30))
		"recoil":
			if id=="FIRE":
				for i in range(2):members.carts[i].apply_central_impulse(global_basis*Vector3(0,0,-6));members.balls[i].apply_central_impulse(global_basis*Vector3(0,0,6))
		"swings":
			if id=="NUDGE":
				for b in bodies:b.apply_impulse(global_basis*Vector3(0,0,1.1),global_basis*Vector3(0,-0.85,0))
		"magnet":
			if id=="MAGNET 3 s" and magnet_remaining<=0:magnet_remaining=3

func step(dt: float) -> void:
	match kind:
		"mass":
			var interval=minf(pulse,dt)
			for i in bodies.size():
				if interval>0 and not is_held(bodies[i]):bodies[i].apply_central_force(global_basis*Vector3(0,0,interval/dt))
				readouts[i].text="%.0f kg · %.2f m/s"%[bodies[i].mass,bodies[i].linear_velocity.length()]
			pulse=maxf(0,pulse-dt)
		"bowling":
			var count=0
			for pin in members.pins:
				if pin.global_basis.y.dot(Vector3.UP)<0.7 or pin.position.y< -0.1:count+=1
			status.text="%d / 10 pins down · roll again, or reset"%count
		"liquids":
			for b in bodies:
				var i=fluid_index(b.position)
				if i>=0 and not is_held(b):
					var c=[0.6,3.0,9.0][i]
					var resistance=(-b.linear_velocity*b.linear_velocity.length()*c).limit_length(b.mass*b.linear_velocity.length()/maxf(dt,0.001))
					b.apply_central_force(resistance+Vector3.UP*3.0*b.mass)
		"springs","swings":update_links()
		"constraints":
			for pair in members.jaws:
				var z=pair[2]*(0.44 if members.jaw_open else 0.315)
				for part in [pair[0],pair[1]]:part.position.z=move_toward(part.position.z,z,0.4*dt)
		"magnet":
			if magnet_remaining>0:
				magnet_remaining=maxf(0,magnet_remaining-dt)
				for b in members.gun.candidates:
					if not is_held(b):b.apply_central_force(((to_global(members.source)-b.global_position)*15-b.linear_velocity*3).limit_length(55))
				if magnet_remaining==0:magnet_releases+=1
			status.text="MAGNET %.1f s / automatic release"%magnet_remaining if magnet_remaining>0 else "MAGNET OFF / gravity has the cargo"
		"vortex":
			for b in bodies:
				if not is_held(b):b.apply_central_force(global_basis*swirl(b.position)*b.mass)
		"mutual":update_mutual()
		"flight":
			status.text="Gate %d / %d · point where you want to fly"%[checkpoint,members.gates.size()]
		_:
			if elapsed<0.1:status.text="Grab / pull / release. Motion leaves a bounded trail."

func update_links() -> void:
	for link in links:
		var a: RigidBody3D=link.a;var b: RigidBody3D=link.b
		var end=to_global(link.anchor) if b==null else b.global_position
		var r=end-a.global_position;var length=r.length();var direction=r/maxf(length,0.001)
		var relative=a.linear_velocity-(Vector3.ZERO if b==null else b.linear_velocity)
		var f=(direction*(length-link.rest)*link.k-relative*link.c).limit_length(150)
		if not is_held(a):a.apply_central_force(f)
		if b!=null and not is_held(b):b.apply_central_force(-f)
		link.rod.set_ends(to_local(a.global_position),to_local(end))
	if kind=="swings":
		for b in bodies:b.apply_torque(-b.angular_velocity*float(b.get_meta("damper",0)))

func update_mutual() -> void:
	last_forces=[]
	for b in bodies:last_forces.append(Vector3.ZERO)
	for i in bodies.size():
		for j in range(i+1,bodies.size()):
			var f=attraction(bodies[i].position,bodies[j].position,bodies[i].mass,bodies[j].mass)
			last_forces[i]+=f;last_forces[j]-=f
	var person=visitor()
	if person!=null:
		var at=to_local(person.global_position);at.y=1.5
		for i in bodies.size():last_forces[i]+=attraction(bodies[i].position,at,bodies[i].mass,6)
	for i in bodies.size():
		if not is_held(bodies[i]):bodies[i].apply_central_force(global_basis*last_forces[i])
	status.text="FIVE SOURCES + YOU (6 kg model)" if person!=null else "FIVE SOURCES · enter to become the sixth"

func carry_velocity(body: CharacterBody3D,dt: float,incoming: Vector3) -> Vector3:
	var v=super.carry_velocity(body,dt,incoming)
	match kind:
		"liquids":
			var i=fluid_index(to_local(body.global_position))
			if i>=0:
				# Implicit resistance keeps walking stable for every supported physics tick.
				v/=1+[0.7,3.0,8.0][i]*dt;v.y+=3*dt
		"vortex":v+=global_basis*swirl(to_local(body.global_position))*dt
		"mutual":
			var p=to_local(body.global_position);p.y=1.5
			for other in bodies:v+=global_basis*attraction(p,other.position,6,other.mass)/6*dt
		"flight":
			var id=body.get_instance_id()
			if not members.has("rider"):
				var p=to_local(body.global_position)
				if Vector2(p.x-flight_origin.x,p.z-flight_origin.z).length()<1.6:members.rider=id
			if members.get("rider",0)==id:
				v=_carry.get(id,incoming);v.y-=9.8*dt
				for point in get_tree().get_nodes_in_group("ada_thrust_points"):
					if point.receiver()==body:v+=point.acceleration()*dt
				var steer=walk_velocity(body);v.x=move_toward(v.x,steer.x,0.5*dt);v.z=move_toward(v.z,steer.z,0.5*dt)
				v=v.limit_length(7)
				if body.is_on_floor():v.y=maxf(v.y,0)
				flight_mat.global_position=body.global_position+Vector3(0,0.04,0)
				if checkpoint<members.gates.size() and body.global_position.distance_to(to_global(members.gates[checkpoint]))<1.25:checkpoint+=1
	return v

func after_reset() -> void:
	magnet_remaining=0;checkpoint=0;_carry.clear();members.erase("rider")
	if kind=="constraints":members.jaw_open=true
	if is_instance_valid(flight_mat):flight_mat.position=flight_origin
