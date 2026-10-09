extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## One softened gravity law; fixed source and mutual receivers are explicit adapters.
const G := 1.0 # m^3 / (kg s^2), a chosen miniature universe
const EPS := 0.25 # metres, Plummer softening
const STEP := 1.0 / 240.0
const FRAME := 5.2
const HISTORY := 240 # 12 seconds at 20 Hz
const SPEEDS := [0.6,1.0,1.25,1.6]
var mutual := false
var body_count := 2
var speed_index := 1
var nudge_index := 0
var running := false
var frame_exit := false
var parts := false
var paths := true
var rule := false
var elapsed := 0.0
var accumulator := 0.0
var sample_steps := 0
var text_clock := 0.0
var masses: Array[float] = []
var states: Array = []
var markers: Array = []
var trail_meshes: Array = []
var histories: Array = []
var arrows: Array = []
var centres: Array[Node3D] = []
var bank_labels: Array[Label3D] = []
var board: Label3D

func _ready() -> void:
	var steel=material("263a44")
	box(Vector3(0,0.06,0),Vector3(11.2,0.04,11.2),material("354e59"))
	for edge in [-FRAME,FRAME]:
		box(Vector3(edge,0.09,0),Vector3(0.025,0.02,FRAME*2),material("dfbf75",true))
		box(Vector3(0,0.09,edge),Vector3(FRAME*2,0.02,0.025),material("dfbf75",true))
	for x in range(-5,6):
		box(Vector3(x,0.087,0),Vector3(0.015,0.01,10.4),steel)
		box(Vector3(0,0.087,x),Vector3(10.4,0.01,0.015),steel)
	box(Vector3(0,0.10,0),Vector3(0.9,0.02,0.04),material("f1e5bd"))
	box(Vector3(0,0.10,0),Vector3(0.04,0.02,0.9),material("f1e5bd"))
	for side in 2:
		var controls=preload("res://commons/artifacts/timing_machines/machine_stage.gd").new();add_child(controls)
		controls.position=Vector3(-2.4 if side==0 else 2.4,0,-4.5);controls.rotation.y=PI
		var ids: Array=["RUN","RESET","BODIES","NUDGE"] if mutual else ["RUN","RESET","SPEED","REVERSE"]
		controls.console(ids if side==0 else ["PATH","PARTS","RULE"],0,"CHANGE A BEGINNING" if side==0 else "WATCH BEFORE REVEALING")
		bank_labels.append(controls.readout)
		for id in controls.buttons:buttons[id]=controls.buttons[id];buttons[id].pressed.connect(act.bind(id))
	box(Vector3(0,2.7,5.5),Vector3(10.4,2.2,0.12),steel)
	board=label("",Vector3(0,2.7,5.42),0.0025);board.rotation.y=PI
	var colors=["ea79ad","f2ca74","70cfd8"]
	for copy in 2:
		var bodies=[];var lines=[];var records=[];var vectors=[]
		for i in 3:
			var mat=material(colors[i],true)
			if copy==1:mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.albedo_color.a=0.35
			var marker=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=0.20 if i>0 or mutual else 0.32;sphere.height=sphere.radius*2;sphere.radial_segments=16;sphere.rings=8;marker.mesh=sphere;marker.material_override=mat;add_child(marker);bodies.append(marker)
			var line=MeshInstance3D.new();line.mesh=ImmediateMesh.new();line.material_override=mat;add_child(line);lines.append(line);records.append(PackedVector3Array())
			vectors.append(make_arrow(material("93ddf0" if copy==0 else "f1f4e6",true)))
		markers.append(bodies);trail_meshes.append(lines);histories.append(records);arrows.append(vectors)
		var centre=Node3D.new();add_child(centre)
		box(Vector3.ZERO,Vector3(0.25,0.04,0.04),material("fff3cd"),false,centre)
		box(Vector3.ZERO,Vector3(0.04,0.04,0.25),material("fff3cd"),false,centre);centres.append(centre)
	reset_experiment()

func circular_speed() -> float:
	# Circular speed for THIS softened central acceleration at r=3, not point gravity.
	return sqrt(G*12.0*9.0/pow(9.0+EPS*EPS,1.5))

func nudge() -> float:
	return [0.0,0.03,0.15][nudge_index]

func reset_experiment() -> void:
	running=false;frame_exit=false;elapsed=0;accumulator=0;sample_steps=0
	masses.assign([4.0,4.0,4.0] if mutual else [12.0,1.0])
	states.clear()
	for copy in 2:
		var p: Array[Vector3]=[];var v: Array[Vector3]=[]
		if mutual:
			var binary_speed=sqrt(G*4.0*4.0*2.0/pow(16.0+EPS*EPS,1.5))
			p=[Vector3(-2,0,0),Vector3(2,0,0)];v=[Vector3(0,0,-binary_speed),Vector3(0,0,binary_speed)]
			if body_count==3:p.append(Vector3(0,0,2.6));v.append(Vector3.ZERO)
			if copy==1:p[body_count-1]+=Vector3(nudge(),0,0)
		else:
			p=[Vector3.ZERO,Vector3(3,0,0)];v=[Vector3.ZERO,Vector3(0,0,circular_speed()*SPEEDS[speed_index])]
		states.append({"p":p,"v":v})
		for i in 3:histories[copy][i]=PackedVector3Array()
	sample_history();update_visuals();update_text()

func accelerations(state: Dictionary) -> Array[Vector3]:
	var a: Array[Vector3]=[]
	for i in state.p.size():a.append(Vector3.ZERO)
	for i in state.p.size():
		for j in range(i+1,state.p.size()):
			var arm: Vector3 = state.p[j] - state.p[i]
			var pair_force: Vector3 = G * masses[i] * masses[j] * arm / pow(arm.length_squared() + EPS * EPS, 1.5)
			if mutual or i!=0:a[i] += pair_force / masses[i]
			if mutual or j!=0:a[j] -= pair_force / masses[j]
	return a

func advance(delta: float) -> void:
	if not running:return
	accumulator+=minf(delta,0.25)
	while accumulator+0.0000001>=STEP and running:
		accumulator-=STEP
		# Kick-drift-kick (velocity Verlet); forces sample the whole state together.
		for state in states:
			var a=accelerations(state)
			for i in state.p.size():
				state.v[i] += a[i] * (STEP * 0.5)
				state.p[i] += state.v[i] * STEP
			a=accelerations(state)
			for i in state.p.size():state.v[i] += a[i] * (STEP * 0.5)
		elapsed+=STEP;sample_steps+=1
		if sample_steps>=12:sample_steps=0;sample_history()
		for state in states:
			for p in state.p:
				if absf(p.x)>FRAME or absf(p.z)>FRAME:frame_exit=true;running=false

func _physics_process(delta: float) -> void:
	advance(delta);update_visuals();text_clock+=delta
	if text_clock>=0.1:text_clock=0;update_text()

func act(id: String) -> void:
	match id:
		"RUN":if not frame_exit:running=not running
		"RESET":reset_experiment()
		"SPEED":speed_index=(speed_index+1)%SPEEDS.size();reset_experiment()
		"BODIES":body_count=3 if body_count==2 else 2;reset_experiment()
		"NUDGE":nudge_index=(nudge_index+1)%3;reset_experiment()
		"REVERSE":
			for state in states:state.v[1]=-state.v[1]
		"PATH":paths=not paths
		"PARTS":parts=not parts
		"RULE":rule=not rule
	update_visuals();update_text()

func centre_of_mass(state: Dictionary) -> Vector3:
	var result:=Vector3.ZERO;var total:=0.0
	for i in state.p.size():result+=state.p[i]*masses[i];total+=masses[i]
	return result/total

func momentum(state: Dictionary) -> Vector3:
	var result:=Vector3.ZERO
	for i in state.p.size():result+=state.v[i]*masses[i]
	return result

func energy(state: Dictionary) -> float:
	var e:=0.0
	for i in state.p.size():
		e+=0.5*masses[i]*state.v[i].length_squared()
		for j in range(i+1,state.p.size()):e-=G*masses[i]*masses[j]/sqrt(state.p[i].distance_squared_to(state.p[j])+EPS*EPS)
	return e

func separation() -> float:
	var sum:=0.0
	for i in states[0].p.size():sum+=states[0].p[i].distance_squared_to(states[1].p[i])
	return sqrt(sum/states[0].p.size())

func sample_history() -> void:
	for copy in 2:
		for i in states[copy].p.size():
			var points: PackedVector3Array=histories[copy][i];points.append(states[copy].p[i])
			if points.size()>HISTORY:points.remove_at(0)
			histories[copy][i]=points
			var mesh: ImmediateMesh=trail_meshes[copy][i].mesh;mesh.clear_surfaces()
			if points.size()<2:continue
			mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
			for p in points:mesh.surface_add_vertex(p+Vector3(0,0.12+copy*0.025,0))
			mesh.surface_end()

func update_visuals() -> void:
	for copy in 2:
		var shown: bool=copy==0 or (mutual and nudge_index>0)
		var state: Dictionary=states[copy];var a=accelerations(state)
		for i in 3:
			var active: bool=shown and i<state.p.size()
			markers[copy][i].visible=active;trail_meshes[copy][i].visible=active and paths
			arrows[copy][i].visible=false
			if not active:continue
			var p: Vector3=state.p[i]+Vector3(0,1.45+copy*0.65,0);markers[copy][i].position=p
			place_arrow(arrows[copy][i],p,a[i]*0.3)
		centres[copy].visible=shown and mutual;centres[copy].position=centre_of_mass(state)+Vector3(0,0.20+copy*0.035,0)

func update_text() -> void:
	var status="FRAME EXIT" if frame_exit else ("RUNNING" if running else "PAUSED")
	bank_labels[0].text="%s / t %.2f s\n%s"%[status,elapsed,("%d mutual bodies / nudge %.2f m"%[body_count,nudge()]) if mutual else ("initial speed %.3f m/s"%(circular_speed()*SPEEDS[speed_index]))]
	# This script is the opt-in gravity lesson. Let RULE explain the held source;
	# PARTS can show acceleration first without naming the implementation choice.
	bank_labels[1].text=("Paired X-Z difference %.4f m\nWhite crosses: centres of mass"%separation()) if mutual else ("Fixed source / free satellite\nREVERSE changes current velocity" if rule else "Watch both bodies, then reveal RULE.\nREVERSE changes current velocity")
	board.text="Add a body. Which earlier paths change?\nNUDGE starts a second copy with one X position changed.\nTranslucent copy drawn 0.65 m higher; both calculate in X-Z." if mutual else "Change the starting speed, then RUN.\nWatch both bodies. What moves, and what stays?\nWalk inside the calculation; markers do not collide with you."
	if rule:board.text="Fij = G mi mj r / (r² + epsilon²)^(3/2)\nG = 1 m³/(kg s²); epsilon = 0.25 m\n240 steps/s; acceleration arrows 0.30 m per m/s², capped at 2 m\n"+("Equal and opposite pair forces; both bodies respond." if mutual else "Source mass 12 kg; satellite 1 kg; reaction omitted.")
	if parts:
		var peak:=0.0
		for acceleration in accelerations(states[0]):peak=maxf(peak,acceleration.length())
		board.text+="\nBaseline max acceleration %.3f m/s²; arrows capped at 2 m."%peak
	board.text+="\nGolden frame: observation ends, not a collision or proof of escape."

func make_arrow(mat: Material) -> Node3D:
	var rig=Node3D.new();add_child(rig)
	var shaft=CylinderMesh.new();shaft.height=1;shaft.top_radius=0.025;shaft.bottom_radius=0.025;shaft.radial_segments=8
	var node=MeshInstance3D.new();node.mesh=shaft;node.material_override=mat;rig.add_child(node)
	var cone=CylinderMesh.new();cone.height=0.15;cone.top_radius=0;cone.bottom_radius=0.07;cone.radial_segments=8
	var tip=MeshInstance3D.new();tip.mesh=cone;tip.material_override=mat;rig.add_child(tip);return rig

func place_arrow(rig: Node3D, origin: Vector3, vector: Vector3) -> void:
	rig.visible=parts and vector.length()>0.002
	if not rig.visible:return
	vector=vector.limit_length(2.0) # Drawing limit only; acceleration remains unchanged.
	rig.position=origin+vector*0.5;rig.quaternion=Quaternion(Vector3.UP,vector.normalized())
	rig.get_child(0).scale.y=vector.length();rig.get_child(1).position.y=vector.length()*0.5-0.075
