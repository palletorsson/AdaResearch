extends "res://commons/artifacts/force_play/play_space.gd"
## Relative air velocity pushes real bodies. The same law reaches the visitor.
const HANDLE=preload("res://commons/artifacts/centrifuge_ring/ride_handle.gd")
var handle: Node3D
var air := Vector3(7,0,0)
var gust := true
var socks: Array[Node3D]=[]
var airflow: Array=[]
var direction_vector: Node3D

func build() -> void:
	extent=Vector2(16,14);kind="wind"
	floor_patch(extent,ink)
	title("THE ROOM PUSHES BACK","Aim the rose point to turn the wind. Push a body into the current. Step in.",4)
	for x in [-7.4,7.4]:fixed(Vector3(x,0.6,0),Vector3(0.16,1.2,12),pale)
	for z in [-5.7,5.7]:
		for x in [-5,0,5]:
			rod(Vector3(x,0,z),Vector3(x,3.1,z),pale,0.04)
			var sock=Node3D.new();sock.position=Vector3(x,3.1,z);add_child(sock);socks.append(sock)
			for j in range(5):box(Vector3(0.17+j*0.18,0,0),Vector3(0.16,0.18-j*0.02,0.16),pink if j%2 else pale,false,sock)
	for i in range(8):
		var at=Vector3(-3.5+float(i%4)*2,0.5,-2+float(i/4)*3)
		var b=sphere(at,0.32,0.5+float(i%3)) if i%2==0 else solid(at,Vector3.ONE*0.6,0.5+float(i%3),pink)
		b.physics_material_override=physics_material(0.12,0.2)
	handle=HANDLE.new();add_child(handle);handle.position=Vector3(0,1.15,-6);handle.freeze=true;grips.append(handle)
	box(Vector3(0,0.5,-6),Vector3(0.35,1,0.35),pale,true)
	direction_vector=rod(Vector3(0,2.1,0),Vector3(3,2.1,0),blue,0.07,true)
	for i in range(32):
		var arrow=rod(Vector3.ZERO,Vector3.RIGHT,blue,0.012,true)
		airflow.append({"arrow":arrow,"x":-6.5+float(i%8)*1.8,"z":-4.5+float(i/8)*3})
	control("WIND / CALM",Vector3(1.2,0,-6));control("TURN",Vector3(-1.2,0,-6))
	add_to_group("ada_museum_carry")
	get_tree().node_added.connect(func(n):
		if n is XRToolsPlayerBody:install_adapter.call_deferred())
	install_adapter.call_deferred()

func air_velocity() -> Vector3:
	return global_basis*air if gust else Vector3.ZERO

func wind_delta(velocity: Vector3,mass_kg: float,dt: float,coefficient:=0.16) -> Vector3:
	# Implicit drag step: same nominal force, differing acceleration by mass.
	var relative=air_velocity()-velocity
	var k=coefficient*relative.length()/maxf(mass_kg,0.1)
	return relative*(k*dt/(1+k*dt))

func step(dt: float) -> void:
	if handle.held():
		var direction=-handle.global_basis.z;direction.y=0
		if direction.length()>0.1:air=global_basis.inverse()*direction.normalized()*7
	for b in bodies:
		if not is_held(b):b.apply_central_force(wind_delta(b.linear_velocity,b.mass,dt)*b.mass/dt)
	for i in socks.size():
		socks[i].rotation.y=-atan2(air.z,air.x)
		socks[i].rotation.z=(sin(elapsed*5+i)*0.12 if gust else -1.25)
	var direction=air.normalized()
	direction_vector.set_ends(Vector3(0,2.1,0),Vector3(0,2.1,0)+direction*(3 if gust else 0.1))
	for item in airflow:
		var p=Vector3(item.x,0.35+sin(elapsed+item.z)*0.07,item.z)
		item.arrow.set_ends(p,p+direction*(0.8 if gust else 0.08))
	status.text="AIR %.1f m/s / drag follows relative velocity\nBODIES 0.5, 1.5, 2.5 kg / visitor uses a 1 kg comparison mass"%air_velocity().length()

func _point_inside(world: Vector3) -> bool:
	var p=to_local(world);return absf(p.x)<7 and absf(p.z)<5.5 and p.y> -0.2 and p.y<5

func carry_velocity(body: CharacterBody3D,dt: float,incoming: Vector3) -> Vector3:
	var v=super.carry_velocity(body,dt,incoming)
	return v+wind_delta(v,1,dt,0.12)

func action(id: String) -> void:
	if id=="WIND / CALM":gust=not gust
	if id=="TURN":air=air.rotated(Vector3.UP,PI/2)

func after_reset() -> void:
	air=Vector3(7,0,0);gust=true;handle.freeze=true;handle.position=Vector3(0,1.15,-6)
