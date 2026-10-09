extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Metre-scale analytic projectile visualization. No player velocity or rigid-body force.
const ORIGIN_X := -5.0
const HEIGHT := 0.3
const SAMPLES := 64
var angle_deg := 30.0
var speed := 10.0
var gravity := 10.0
var paired := false
var show_path := false
var show_parts := false
var revealed := false
var slow := false
var fired := false
var elapsed := 0.0
var flight_root: Node3D
var vectors: Node3D
var readouts: Array[Label3D] = []
var balls: Array[MeshInstance3D] = []
var wall: Label3D
var amber: Material
var pink: Material
var cyan: Material
var muted: Material
var arrow_pool: Array[Node3D] = []
var arrow_cursor := 0

func _ready() -> void:
	amber=material("ffc667",true);pink=material("f69bc5",true);cyan=material("65e3d5",true);muted=material("48606c")
	# Thin markings on the existing museum floor: the middle remains walkable.
	for x in range(-6,7):box(Vector3(x,0.008,0),Vector3(0.012,0.008,10),muted)
	for z in range(-5,6):box(Vector3(0,0.008,z),Vector3(12,0.008,0.012),muted)
	for x in [-6.2,6.2]:
		for z in [-4.6,4.6]:box(Vector3(x,3.25,z),Vector3(0.12,6.5,0.12),material("21323c"),true)
	for z in [-4.6,4.6]:box(Vector3(0,6.48,z),Vector3(12.5,0.07,0.08),cyan)
	for x in [-6.2,6.2]:box(Vector3(x,6.48,0),Vector3(0.08,0.07,9.2),cyan)
	for z in [-3.0,3.0]:
		box(Vector3(0,0.02,z),Vector3(11,0.018,0.3),material("29434d"))
		box(Vector3(ORIGIN_X,0.1,z),Vector3(0.6,0.2,0.6),material("31525c"),true)
	box(Vector3(0,2.1,-5.15),Vector3(6.4,3.8,0.10),material("152831"),true)
	label("STAND INSIDE THE QUESTION",Vector3(0,3.6,-5.08),0.0038)
	wall=label("",Vector3(0,2.2,-5.06),0.0025)
	label("1 floor square = 1 metre / visual flight markers, no collision",Vector3(0,0.58,-5.06),0.0019)
	bank(["ANGLE-","ANGLE+","SPEED","PAIR","FIRE"],-1.0,0.0)
	bank(["SLOW","GRAVITY","PATH","PARTS","RULE"],1.1,PI)
	var center=label("STAND HERE\nLOOK AROUND",Vector3(0,0.026,0),0.0017);center.rotation_degrees.x=-90
	flight_root=Node3D.new();flight_root.name="PredictedPaths";add_child(flight_root)
	vectors=Node3D.new();vectors.name="VelocityAndAcceleration";add_child(vectors)
	for i in 2:
		var ball=MeshInstance3D.new();var mesh=SphereMesh.new();mesh.radius=0.16;mesh.height=0.32;ball.mesh=mesh;ball.material_override=amber if i==0 else pink;add_child(ball);balls.append(ball)
	rebuild();update_flight()

func bank(ids: Array, z: float, yaw: float) -> void:
	var rig=Node3D.new();add_child(rig);rig.position.z=z;rig.rotation.y=yaw
	box(Vector3(0,0.94,0),Vector3(3.8,0.16,0.55),material("263a44"),true,rig)
	for x in [-1.6,1.6]:box(Vector3(x,0.45,0),Vector3(0.13,0.9,0.25),material("263a44"),true,rig)
	for i in ids.size():
		var id: String=ids[i];var button=PUSH.instantiate();rig.add_child(button);button.position=Vector3((i-2)*0.7,1.04,0);button.scale=Vector3.ONE*1.15;buttons[id]=button;button.pressed.connect(act.bind(id))
		var caption=Label3D.new();rig.add_child(caption);caption.text=id;caption.position=button.position+Vector3(0,0.06,0.18);caption.font_size=42;caption.pixel_size=0.001;caption.rotation_degrees.x=-55
	var info=Label3D.new();rig.add_child(info);info.position=Vector3(0,1.13,-0.21);info.rotation_degrees.x=-55;info.font_size=42;info.pixel_size=0.0011;readouts.append(info)

func launch_velocity(index: int) -> Vector3:
	var theta=deg_to_rad(angle_deg if index==0 else 90.0-angle_deg)
	return Vector3(speed*cos(theta),speed*sin(theta),0)

func duration(index: int) -> float:
	return 2.0*launch_velocity(index).y/gravity

func flight_position(index: int, time: float) -> Vector3:
	var t=clampf(time,0,duration(index))
	return Vector3(ORIGIN_X,HEIGHT,-3.0 if index==0 else 3.0)+launch_velocity(index)*t+Vector3.DOWN*0.5*gravity*t*t

func flight_velocity(index: int, time: float) -> Vector3:
	return launch_velocity(index)+Vector3.DOWN*gravity*clampf(time,0,duration(index))

func line(host: Node3D, start: Vector3, end: Vector3, mat: Material, arrow: bool=false) -> void:
	var d=end-start
	if d.length()<0.0001:return
	if host==vectors:
		dynamic_arrow(start,end,mat);return
	var mesh=MeshInstance3D.new();var cylinder=CylinderMesh.new();cylinder.top_radius=0.022;cylinder.bottom_radius=0.022;cylinder.height=d.length();cylinder.radial_segments=8
	mesh.mesh=cylinder;mesh.material_override=mat;host.add_child(mesh);mesh.position=(start+end)*0.5;mesh.quaternion=Quaternion(Vector3.UP,d.normalized())
	if arrow:
		var tip=MeshInstance3D.new();var cone=CylinderMesh.new();cone.top_radius=0;cone.bottom_radius=0.09;cone.height=0.2;cone.radial_segments=8
		tip.mesh=cone;tip.material_override=mat;host.add_child(tip);tip.position=end-d.normalized()*0.1;tip.quaternion=mesh.quaternion

func dynamic_arrow(start: Vector3, end: Vector3, mat: Material) -> void:
	# Reuse at most eight arrow rigs during flight rather than allocating per frame.
	if arrow_cursor==arrow_pool.size():
		var rig=Node3D.new();vectors.add_child(rig);arrow_pool.append(rig)
		var shaft=MeshInstance3D.new();var cylinder=CylinderMesh.new();cylinder.top_radius=0.022;cylinder.bottom_radius=0.022;cylinder.height=1;cylinder.radial_segments=8;shaft.mesh=cylinder;rig.add_child(shaft)
		var tip=MeshInstance3D.new();var cone=CylinderMesh.new();cone.top_radius=0;cone.bottom_radius=0.09;cone.height=0.2;cone.radial_segments=8;tip.mesh=cone;rig.add_child(tip)
	var rig=arrow_pool[arrow_cursor];arrow_cursor+=1
	var d=end-start;rig.visible=true;rig.position=(start+end)*0.5;rig.quaternion=Quaternion(Vector3.UP,d.normalized())
	rig.get_child(0).scale.y=d.length();rig.get_child(0).material_override=mat
	rig.get_child(1).position.y=d.length()*0.5-0.1;rig.get_child(1).material_override=mat

func clear(host: Node3D) -> void:
	if host==vectors:
		arrow_cursor=0
		for rig in arrow_pool:rig.visible=false
		return
	for child in host.get_children():host.remove_child(child);child.queue_free()

func rebuild() -> void:
	clear(flight_root)
	for i in (2 if paired else 1):
		var mat=amber if i==0 else pink
		if show_path:
			for step in SAMPLES:
				line(flight_root,flight_position(i,duration(i)*step/SAMPLES),flight_position(i,duration(i)*(step+1)/SAMPLES),mat)
			box(flight_position(i,duration(i))+Vector3(0,-0.26,0),Vector3(0.45,0.05,0.6),mat,false,flight_root)
	if show_path and paired:
		line(flight_root,flight_position(0,duration(0)),flight_position(1,duration(1)),muted)
	update_text()

func update_flight() -> void:
	clear(vectors)
	for i in 2:
		balls[i].visible=(i==0 or paired)
		if not balls[i].visible:continue
		var p=flight_position(i,elapsed if fired else 0.0);balls[i].position=p
		var velocity=flight_velocity(i,elapsed if fired else 0.0)
		if not fired or show_parts:
			# Arrow lengths encode velocity with 0.2 seconds, acceleration with 0.1 s².
			line(vectors,p,p+velocity*0.2,amber if i==0 else pink,true)
		if show_parts:
			line(vectors,p,p+Vector3(velocity.x,0,0)*0.2,cyan,true)
			line(vectors,p,p+Vector3(0,velocity.y,0)*0.2,pink,true)
			line(vectors,p+Vector3(0,0,0.4),p+Vector3(0,-gravity*0.1,0.4),muted,true)

func act(id: String) -> void:
	match id:
		"FIRE":elapsed=0;fired=true
		"SLOW":slow=not slow
		"PATH":show_path=not show_path
		"PARTS":show_parts=not show_parts
		"RULE":revealed=not revealed
		_:
			fired=false;elapsed=0
			match id:
				"ANGLE-":angle_deg=maxf(15,angle_deg-5)
				"ANGLE+":angle_deg=minf(75,angle_deg+5)
				"SPEED":speed=6.0 if speed>=10 else speed+2.0
				"GRAVITY":gravity=15.0 if gravity==10.0 else 10.0
				"PAIR":paired=not paired
	rebuild();update_flight()

func _process(delta: float) -> void:
	if not fired:return
	var end=maxf(duration(0),duration(1) if paired else 0)
	if elapsed>=end:return
	elapsed=minf(end,elapsed+delta*(0.25 if slow else 1.0))
	update_flight();update_text()

func update_text() -> void:
	readouts[0].text="%d deg | %.0f m/s | PAIR %s" % [angle_deg,speed,"ON" if paired else "OFF"]
	readouts[1].text="g %.0f m/s² | time x%s | t %.2f s" % [gravity,"0.25" if slow else "1",elapsed]
	var instructions="FIRE, then watch the flight.\nPAIR adds the complementary angle behind you.\nSame speed: does it land at the same X?\nTurn around: which lands first?\nPATH and PARTS reveal the construction."
	if revealed:
		instructions="v0 = (%.2f, %.2f, 0) m/s\np(t) = origin + v0*t + 0.5*g*t*t\nrange %.2f m | flight %.2f s\n%s\nVelocity: 1 m/s drawn as 0.2 m\nAcceleration: 1 m/s² drawn as 0.1 m" % [launch_velocity(0).x,launch_velocity(0).y,flight_position(0,duration(0)).x-ORIGIN_X,duration(0),"paired flight %.2f s" % duration(1) if paired else "single flight"]
	var state="READY" if not fired else ("A LANDED" if elapsed>=duration(0) else "A IN FLIGHT")
	if fired and paired:state+=" / B LANDED" if elapsed>=duration(1) else " / B IN FLIGHT"
	wall.text=state+"\n\n"+instructions+"\n\nUniform gravity; no drag or collisions.\nEqual launch/landing height; landing freezes the impact state.\nParameter edits reset this flight; SLOW changes playback time."
