extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Ground-plane rigid body: a virtual spring at the hand supplies a model force.
## This is not a measurement of a visitor's muscle force. Work = sum(F · delta x).
const SPACING:=0.38
const CUT_RADIUS:=0.47
const PUSH_STIFFNESS:=100.0
const MAX_PUSH:=65.0
const DRAG:=13.0
var mower: RigidBody3D
var lawn_width:=20.0
var lawn_length:=28.0
var handle: RigidBody3D
var home: Transform3D
var lawn: Node3D
var grass: MultiMeshInstance3D
var stems: MultiMeshInstance3D
var flowers: MultiMeshInstance3D
var points: PackedVector3Array=[]
var grass_poses: Array[Transform3D]=[]
var cut: PackedByteArray=[]
var nx:=0
var nz:=0
var cut_count:=0
var flower_count:=0
var last_position:=Vector3.ZERO
var last_deck:=Vector3.ZERO
var push:=Vector3.ZERO
var drag_force:=Vector3.ZERO
var work:=0.0
var distance:=0.0
var roll:=0.0
var age:=0.0
var ready_to_push:=false
var resetting:=false
var tether: MeshInstance3D
var counter: Label3D

func _ready() -> void:
	# Placement settles before the independent lawn takes its fixed world pose.
	await get_tree().process_frame
	if not is_instance_valid(mower):return
	home=mower.global_transform
	lawn=Node3D.new(); lawn.name="FlowerLawn"; add_child(lawn)
	lawn.global_transform=Transform3D(home.basis.orthonormalized(),home.origin+home.basis.x.normalized()*(lawn_length*0.5-1.5))
	_build_lawn()
	handle=load("res://commons/artifacts/force_mower/mower_grip.gd").new()
	handle.name="PushAndSteer"; add_child(handle); _dock_handle()
	tether=MeshInstance3D.new(); var tube:=CylinderMesh.new(); tube.top_radius=0.012; tube.bottom_radius=0.012; tube.height=1
	tether.mesh=tube; tether.material_override=material("f18fb8"); add_child(tether)
	counter=Label3D.new(); counter.font_size=42; counter.pixel_size=0.0015; counter.outline_size=7
	counter.billboard=BaseMaterial3D.BILLBOARD_ENABLED; mower.add_child(counter)
	counter.position=mower.grip_local+Vector3(0.2,0.45,0)
	var reset=PUSH.instantiate(); reset.name="ResetGarden"; mower.add_child(reset)
	reset.position=mower.grip_local+Vector3(0.16,-0.16,0.27); reset.scale=Vector3.ONE*0.55
	reset.pressed.connect(reset_garden); buttons.RESET=reset
	var instructions=label("PUSH GRASS INTO FLOWERS\nGrip the pink handle. Push forward. Move your hand left / right to steer.\nRelease and feel the drag. The small button resets the garden.",Vector3.ZERO,0.003)
	instructions.global_position=home.origin-home.basis.x.normalized()*2.0+Vector3.UP*2.7
	instructions.billboard=BaseMaterial3D.BILLBOARD_ENABLED; instructions.outline_size=8
	last_position=mower.global_position; last_deck=last_position
	mower.freeze=false; ready_to_push=true

func _batch(mesh: Mesh,count: int,colours: bool,mat: Material) -> MultiMeshInstance3D:
	var node:=MultiMeshInstance3D.new(); var mm:=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D; mm.use_colors=colours; mm.mesh=mesh; mm.instance_count=count
	node.multimesh=mm; node.material_override=mat; lawn.add_child(node)
	return node

func _build_lawn() -> void:
	nx=int(ceil(lawn_length/SPACING)); nz=int(ceil(lawn_width/SPACING))
	var n:=nx*nz; cut.resize(n); cut.fill(0)
	box(Vector3(0,0.015,0),Vector3(lawn_length,0.03,lawn_width),material("40612c"),false,lawn)
	# Low visible boundary; the visitor has a wide, clear route around the plot.
	for side in [-1,1]:
		box(Vector3(0,0.13,side*(lawn_width*0.5+0.08)),Vector3(lawn_length+0.3,0.26,0.16),material("c3bb9d"),true,lawn)
		box(Vector3(side*(lawn_length*0.5+0.08),0.13,0),Vector3(0.16,0.26,lawn_width),material("c3bb9d"),true,lawn)
	var blade:=BoxMesh.new(); blade.size=Vector3(0.018,1,0.055)
	var green:=material("ffffff"); green.vertex_color_use_as_albedo=true
	grass=_batch(blade,n*3,true,green)
	var stalk:=CylinderMesh.new(); stalk.top_radius=0.008; stalk.bottom_radius=0.013; stalk.height=1; stalk.radial_segments=5
	stems=_batch(stalk,n,false,material("618641"))
	var petal_mat:=material("ffffff"); petal_mat.vertex_color_use_as_albedo=true; petal_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	flowers=_batch(_flower_mesh(),n,true,petal_mat)
	var rng:=RandomNumberGenerator.new(); rng.seed=771029
	var hidden:=Transform3D(Basis().scaled(Vector3.ONE*0.001),Vector3(0,-2,0))
	var palette: Array[Color]=[Color("fa76b5"),Color("c797ee"),Color("fff1ce"),Color("f2b32c"),Color("e99557")]
	for x in range(nx):
		for z in range(nz):
			var id:=x*nz+z
			var p:=Vector3(-lawn_length*0.5+(x+0.5)*lawn_length/nx,0,-lawn_width*0.5+(z+0.5)*lawn_width/nz)
			p+=Vector3(rng.randf_range(-0.08,0.08),0,rng.randf_range(-0.08,0.08)); points.append(p)
			for k in range(3):
				var h:=rng.randf_range(0.28,0.48)
				var at:=p+Vector3(rng.randf_range(-0.08,0.08),0.035+h*0.5,rng.randf_range(-0.08,0.08))
				var pose:=Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(1,h,1)),at)
				grass_poses.append(pose); grass.multimesh.set_instance_transform(id*3+k,pose)
				grass.multimesh.set_instance_color(id*3+k,Color.from_hsv(rng.randf_range(0.22,0.31),0.55,rng.randf_range(0.42,0.73)))
			stems.multimesh.set_instance_transform(id,hidden); flowers.multimesh.set_instance_transform(id,hidden)
			flowers.multimesh.set_instance_color(id,palette[id%palette.size()])

func _flower_mesh() -> ArrayMesh:
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for petal in range(5):
		var a:=TAU*petal/5.0; var dir:=Vector3(cos(a),0,sin(a)); var side:=Vector3(-sin(a),0,cos(a))
		var vertices: Array[Vector3]=[dir*0.018-side*0.025,dir*0.13-side*0.035,dir*0.15,dir*0.13+side*0.035,dir*0.018+side*0.025]
		for k in range(1,4):
			for v in [vertices[0],vertices[k],vertices[k+1]]:
				st.set_normal(Vector3.UP); st.add_vertex(v)
	return st.commit()

func anchor() -> Vector3:
	return mower.to_global(mower.grip_local)

func _dock_handle() -> void:
	handle.freeze=true; handle.linear_velocity=Vector3.ZERO
	handle.global_transform=Transform3D(mower.global_basis.orthonormalized(),anchor())

func _physics_process(dt: float) -> void:
	if not ready_to_push or resetting or not is_instance_valid(mower):return
	var at:=mower.global_position; var delta_position:=at-last_position
	# This is the previous tick's applied model force and the resulting displacement.
	work+=push.dot(delta_position); distance+=delta_position.length(); last_position=at
	var forward:=mower.global_basis.x.normalized(); var side:=mower.global_basis.z.normalized()
	push=Vector3.ZERO
	if handle.held():
		var error: Vector3=handle.global_position-anchor()
		push=forward*clampf(error.dot(forward)*PUSH_STIFFNESS,-MAX_PUSH,MAX_PUSH)
		var steering:=clampf(error.dot(side)*-32.0,-22.0,22.0)
		mower.apply_torque(Vector3.UP*steering)
		mower.sleeping=false
	else:_dock_handle()
	# Rolling drag plus greater sideways resistance; yaw also loses momentum.
	drag_force=-mower.linear_velocity*DRAG-side*mower.linear_velocity.dot(side)*55.0
	mower.apply_central_force(push+drag_force)
	mower.apply_torque(Vector3.UP*(-mower.angular_velocity.y*12.0))
	roll+=delta_position.dot(forward)/0.11
	for wheel in mower._wheels:wheel.rotation.z=-roll
	if at.distance_to(last_deck)<3.0 and at.distance_to(last_deck)>0.015:
		var steps:=maxi(1,int(ceil(at.distance_to(last_deck)/0.16)))
		for i in range(1,steps+1):_cut_at(last_deck.lerp(at,float(i)/steps))
		last_deck=at
	elif at.distance_to(last_deck)>=3.0:last_deck=at
	var span: Vector3=handle.global_position-anchor(); tether.visible=handle.held() and span.length()>0.05
	if tether.visible:
		tether.global_position=(handle.global_position+anchor())*0.5
		tether.global_basis=Basis(Quaternion(Vector3.UP,span.normalized())).scaled(Vector3(1,span.length(),1))
	age+=dt
	if age>0.1:
		age=0
		counter.text="MODEL PUSH %.0f N / DRAG %.0f N\n%.1f m / %.1f J / %d flowers"%[push.length(),drag_force.length(),distance,work,flower_count]

func _cut_at(world_point: Vector3) -> void:
	var p:=lawn.to_local(world_point)
	var ix:=int(floor((p.x+lawn_length*0.5)*nx/lawn_length)); var iz:=int(floor((p.z+lawn_width*0.5)*nz/lawn_width))
	for x in range(maxi(0,ix-2),mini(nx,ix+3)):
		for z in range(maxi(0,iz-2),mini(nz,iz+3)):
			var id:=x*nz+z
			if cut[id]!=0 or Vector2(p.x-points[id].x,p.z-points[id].z).length()>CUT_RADIUS:continue
			cut[id]=1; cut_count+=1
			for k in range(3):
				var pose:=grass_poses[id*3+k]; pose.basis=pose.basis.scaled(Vector3(1,0.12,1)); pose.origin.y=0.035+pose.basis.y.length()*0.5
				grass.multimesh.set_instance_transform(id*3+k,pose)
			if id%3==0:
				var h:=0.25+float(id%5)*0.035; var at:=points[id]+Vector3.UP*(0.04+h*0.5)
				stems.multimesh.set_instance_transform(id,Transform3D(Basis().scaled(Vector3(1,h,1)),at))
				flowers.multimesh.set_instance_transform(id,Transform3D(Basis(Vector3.UP,id*0.43),points[id]+Vector3.UP*(0.04+h)))
				flower_count+=1

func reset_garden() -> void:
	if not ready_to_push or resetting or handle.held():return
	resetting=true
	mower.freeze=true; mower.freeze_mode=RigidBody3D.FREEZE_MODE_STATIC
	mower.global_transform=home
	PhysicsServer3D.body_set_state(mower.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,home)
	mower.force_update_transform(); mower.reset_physics_interpolation()
	mower.linear_velocity=Vector3.ZERO; mower.angular_velocity=Vector3.ZERO
	push=Vector3.ZERO; work=0; distance=0; roll=0; cut_count=0; flower_count=0; cut.fill(0)
	for i in range(grass_poses.size()):grass.multimesh.set_instance_transform(i,grass_poses[i])
	var hidden:=Transform3D(Basis().scaled(Vector3.ONE*0.001),Vector3(0,-2,0))
	for i in range(points.size()):
		flowers.multimesh.set_instance_transform(i,hidden); stems.multimesh.set_instance_transform(i,hidden)
	last_position=home.origin; last_deck=home.origin; _dock_handle()
	_finish_reset.call_deferred()

func _finish_reset() -> void:
	await get_tree().physics_frame
	if is_instance_valid(mower):
		mower.linear_velocity=Vector3.ZERO; mower.angular_velocity=Vector3.ZERO
		mower.freeze_mode=RigidBody3D.FREEZE_MODE_KINEMATIC; mower.freeze=false; mower.sleeping=false
	resetting=false

func _exit_tree() -> void:
	if is_instance_valid(handle) and handle.has_method("drop") and handle.is_picked_up():handle.drop()
