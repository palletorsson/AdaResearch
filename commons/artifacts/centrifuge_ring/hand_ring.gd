extends "res://commons/artifacts/force_play/play_space.gd"
## Prescribed circular ride, with a held handle and collision-aware player motion.
## The tracked head is never rotated. Release keeps the tangent, then slows.
const HANDLE=preload("res://commons/artifacts/centrifuge_ring/ride_handle.gd")
var handle: Node3D
var rider: CharacterBody3D
var pod: Node3D
var radius := 3.4
var speed := 2.0
var phase := -PI/2
var coast := 0.0
var velocity_vector: Node3D
var acceleration_vector: Node3D
var tether: Node3D

func build() -> void:
	extent=Vector2(12,12);kind="hand_ring"
	floor_patch(extent)
	title("HOLD ON / LET GO","Hold the rose handle. Trigger changes speed. Release into the tangent.",3.5)
	for i in range(64):
		var a=TAU*float(i)/64;var b=TAU*float(i+1)/64
		rod(Vector3(cos(a)*radius,0.07,sin(a)*radius),Vector3(cos(b)*radius,0.07,sin(b)*radius),blue,0.026)
	box(Vector3(0,0.35,0),Vector3(0.5,0.7,0.5),ink,true)
	pod=Node3D.new();add_child(pod)
	box(Vector3.ZERO,Vector3(0.7,0.12,0.7),pink,false,pod)
	handle=HANDLE.new();add_child(handle);grips.append(handle)
	handle.action_pressed.connect(func(_p):action("SPEED"))
	velocity_vector=rod(Vector3.ZERO,Vector3.RIGHT,blue,0.025,true)
	acceleration_vector=rod(Vector3.ZERO,Vector3.LEFT,pink,0.025,true)
	tether=rod(Vector3.ZERO,Vector3.UP,ink,0.015)
	control("SPEED",Vector3(1.5,0,-4.5))
	add_to_group("ada_museum_carry")
	get_tree().node_added.connect(func(n):
		if n is XRToolsPlayerBody:install_adapter.call_deferred())
	install_adapter.call_deferred();update_pose()

func step(dt: float) -> void:
	var held=handle.held()
	if held:
		var body=handle.receiver()
		if body!=null:
			if rider!=body:
				rider=body;var p=to_local(body.global_position);phase=atan2(p.z,p.x)
			coast=1.5
	elif is_instance_valid(rider):
		coast=maxf(0,coast-dt)
		if coast<=0:rider=null;_carry.clear()
	if held and is_instance_valid(rider):
		var p=to_local(rider.global_position);phase=atan2(p.z,p.x)
	update_pose()
	status.text="v %.1f m/s · r %.1f m · a %.2f m/s²\nPrescribed circle; release retains tangent. Head direction stays yours."%[speed,radius,speed*speed/radius]

func update_pose() -> void:
	var radial=Vector3(cos(phase),0,sin(phase));var tangent=Vector3(-sin(phase),0,cos(phase))
	var at=radial*radius;pod.position=at+Vector3.UP*0.08
	var anchor=at+radial*0.35+Vector3.UP*1.15
	if not handle.held():handle.freeze=true;handle.global_position=to_global(anchor)
	tether.set_ends(at+Vector3.UP*0.12,to_local(handle.global_position))
	velocity_vector.set_ends(at+Vector3.UP*1.7,at+Vector3.UP*1.7+tangent*speed*0.35)
	acceleration_vector.set_ends(at+Vector3.UP*1.9,at+Vector3.UP*1.9-radial*(speed*speed/radius)*0.23)

func _point_inside(world: Vector3) -> bool:
	return is_instance_valid(rider) and (handle.held() or coast>0) and world.distance_to(rider.global_position)<0.3 and world.distance_to(global_position)<10

func carry_velocity(body: CharacterBody3D,dt: float,incoming: Vector3) -> Vector3:
	if body!=rider:return incoming
	var v: Vector3=_carry.get(body.get_instance_id(),incoming)
	if handle.held():
		var p=to_local(body.global_position);p.y=0
		var radial=p.normalized();var tangent=Vector3(-radial.z,0,radial.x)
		var desired=global_basis*(tangent*speed+radial*clampf((radius-p.length())*2,-2,2))
		v.x=move_toward(v.x,desired.x,4*dt);v.z=move_toward(v.z,desired.z,4*dt)
	else:
		v.x=move_toward(v.x,0,1.5*dt);v.z=move_toward(v.z,0,1.5*dt)
	v.y=maxf(-8,v.y-9.8*dt)
	if body.is_on_floor():v.y=maxf(0,v.y)
	return v

func action(id: String) -> void:
	if id=="SPEED":speed=4.0 if speed<3 else (6.0 if speed<5 else 2.0)

func after_reset() -> void:
	if handle.held():return
	rider=null;coast=0;phase=-PI/2;_carry.clear();update_pose()
