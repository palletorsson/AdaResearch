extends Node3D
## Graded distance and approach speed act on the same fourteen retained ribs.
## No camera hijack, player force or moving collision. The centre stays walkable.
const Console = preload("res://commons/artifacts/fuzzy_doorway/doorway_console.gd")
const CORAL := Color("e67f96")
const MINT := Color("79cfbe")
const GOLD := Color("ead29c")
const SECTIONS := 7
const STEPS := 32
const SIDES := 8
const TUBE := .075
var panel: Node3D
var sculpture: MeshInstance3D
var rule_board: Node3D
var bars: Array[MeshInstance3D]=[]
var labels: Array[Label3D]=[]
var title: Label3D
var museum: Node
var visitor: Node3D
var source_kind := "NO VISITOR"
var mode := 0 # 0 actual visitor, 1 declared slow input, 2 declared fast input.
var reach := 4.0
var pace := 1.2
var sample_distance := 99.0
var raw_speed := 0.0
var speed := 0.0
var weights := Vector3(0,0,1) # open / curl / rest
var target := Vector2.ZERO
var pose := Vector2.ZERO
var previous_position := Vector3.ZERO
var previous_distance := 0.0
var have_previous := false
var syncing := false
var mesh_time := 0.0
var ui_time := 0.0
var last_drawn := Vector2(INF,INF)
var vertices := PackedVector3Array()
var original := PackedVector3Array()
var reset_jumps := 0
var reversed_rules := false

func _ready() -> void:
	panel=Console.new();panel.position=Vector3(-3.8,0,3.1);add_child(panel)
	for i in 3:panel.buttons[["LIVE","DEMO SLOW","DEMO FAST"][i]].pressed.connect(select_mode.bind(i))
	panel.buttons["RESET"].pressed.connect(reset)
	panel.buttons["SWAP RULES"].pressed.connect(swap_rules)
	panel.reach_dial.hinge_moved.connect(read_controls);panel.pace_dial.hinge_moved.connect(read_controls)
	sculpture=MeshInstance3D.new();sculpture.name="FourteenRibs";add_child(sculpture)
	var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=.28;mat.metallic=.18;sculpture.material_override=mat
	build_room();draw_ribs();original=vertices.duplicate();sync_controls();update_labels()
	museum=get_parent()
	while museum!=null and not museum.has_method("_vr_eye"):museum=museum.get_parent()

func choose_visitor() -> Node3D:
	# The museum knows which XR rig is active. Avoid spectator/capture cameras.
	if is_instance_valid(museum):
		if museum.call("_is_vr"):
			source_kind="XR HEAD"
			return museum.call("_vr_eye") as Node3D
		source_kind="MUSEUM BODY"
		return museum.get("_player") as Node3D
	source_kind="NO VISITOR"
	return null

func gate_distance(local: Vector3) -> float:
	# Distance to the centre plane and its 2.8m-wide sensing opening, on XZ.
	return Vector2(maxf(absf(local.x)-1.4,0.0),local.z).length()

func evaluate(distance: float, approach: float) -> Vector3:
	var near:=1.0-smoothstep(.65,reach,maxf(distance,0))
	var fast:=smoothstep(pace*.4,pace*1.5,maxf(approach,0))
	var slow_rule:=minf(near,1.0-fast);var fast_rule:=minf(near,fast)
	return Vector3(fast_rule,slow_rule,1.0-near) if reversed_rules else Vector3(slow_rule,fast_rule,1.0-near)

func consequent(rules: Vector3) -> Vector2:
	var total:=rules.x+rules.y+rules.z
	return Vector2(rules.x,rules.y)/maxf(total,.000001)

func observe(world_position: Vector3, delta: float) -> void:
	var local:=to_local(world_position)
	sample_distance=gate_distance(local)
	if not have_previous:
		have_previous=true;raw_speed=0;speed=0
	else:
		var shift:=Vector2(world_position.x-previous_position.x,world_position.z-previous_position.z).length()
		# A teleport is a discontinuity, not a running body. Reset only the
		# derivative; normal approaches retain their measured speed.
		if shift/maxf(delta,.001)>12.0:
			raw_speed=0;speed=0;reset_jumps+=1
		else:
			raw_speed=maxf(0,(previous_distance-sample_distance)/maxf(delta,.001))
			speed=lerpf(speed,raw_speed,1-exp(-delta/.12))
	previous_position=world_position;previous_distance=sample_distance

func _physics_process(delta: float) -> void:
	if mode==0:
		var person:=choose_visitor()
		if person!=visitor:visitor=person;have_previous=false
		if is_instance_valid(person):observe(person.global_position,delta)
		else:sample_distance=99;speed=0;have_previous=false
	else:
		source_kind="DEMO INPUT";sample_distance=1.0;speed=.15 if mode==1 else 2.6;raw_speed=speed
	weights=evaluate(sample_distance,speed);target=consequent(weights)
	# Response easing is explicitly additional to the fuzzy inference.
	pose=pose.lerp(target,1-exp(-delta/.24))
	mesh_time+=delta;ui_time+=delta
	if mesh_time>=.05 and pose.distance_to(last_drawn)>.001:
		mesh_time=0;draw_ribs()
	if ui_time>=.1:ui_time=0;update_labels()

func rib_point(t: float, side: float, depth: float, shape: Vector2) -> Vector3:
	var theta:=t*PI*.5;var s:=sin(theta)
	return Vector3(side*(2.5*cos(theta)+(.9*shape.x-1.15*shape.y)*s*s),s*(3.8+.45*shape.x+.20*shape.y),depth+.8*shape.y*s*s*s)

func draw_ribs() -> void:
	vertices.clear();var normals:=PackedVector3Array();var colors:=PackedColorArray();var indices:=PackedInt32Array()
	for frame in SECTIONS:
		var depth:float=-1.65+frame*.55
		for side in [-1.0,1.0]:
			var base:int=vertices.size()
			for step in range(STEPS+1):
				var t:float=float(step)/STEPS
				var p:=rib_point(t,side,depth,pose)
				var tangent:Vector3=(rib_point(minf(t+.001,1),side,depth,pose)-rib_point(maxf(t-.001,0),side,depth,pose)).normalized()
				var axis:=tangent.cross(Vector3.BACK).normalized();var other:=tangent.cross(axis).normalized()
				for ring in SIDES:
					var a:=TAU*ring/SIDES;var n:=cos(a)*axis+sin(a)*other
					vertices.append(p+n*TUBE);normals.append(n)
					var col:Color=(Color("e3e0d7")+MINT*pose.x*1.7+CORAL*pose.y*1.7)/(1+1.7*(pose.x+pose.y))
					colors.append(col)
			for step in STEPS:
				for ring in SIDES:
					var a:int=base+step*SIDES+ring;var b:int=base+step*SIDES+(ring+1)%SIDES;var c:int=a+SIDES;var d:int=b+SIDES
					indices.append_array(PackedInt32Array([a,c,b,b,c,d]))
	var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);sculpture.mesh=mesh;last_drawn=pose

func build_room() -> void:
	panel.box(self,Vector3(0,.008,0),Vector3(2.8,.016,5.6),Color("314b54"))
	for side in [-1,1]:
		panel.box(self,Vector3(side*2.5,.12,0),Vector3(.32,.24,4.1),Color("24373c"),true)
		panel.box(self,Vector3(side*1.4,.019,0),Vector3(.025,.006,5.6),GOLD)
	# Fixed supports outside the always-open walking lane.
	for x in [-3.05,3.05]:panel.box(self,Vector3(x,2.5,0),Vector3(.12,5,.12),Color("24373c"),true)
	panel.box(self,Vector3(0,5.02,0),Vector3(6.22,.16,.20),Color("24373c"))
	title=panel.text(self,"A DOORWAY READS YOUR APPROACH",Vector3(0,5.38,.1),.0025,Color("24373c"))
	panel.box(self,Vector3(0,5.4,0),Vector3(6.6,.72,.08),Color("e7e2d7"))
	panel.text(self,"ENDLESS MUSEUM / always another room",Vector3(0,5.15,.07),.0011,Color("24373c"))
	var mark:Label3D=panel.text(self,"WALK THROUGH / THEN RETURN",Vector3(0,.028,3),.00135,Color("24373c"));mark.rotation_degrees.x=-90
	rule_board=Node3D.new();rule_board.position=Vector3(3.85,1.65,2);add_child(rule_board)
	panel.box(rule_board,Vector3(0,.35,-.05),Vector3(2.3,2.25,.10),Color("e7e2d7"))
	panel.text(rule_board,"THE RULES AT WORK",Vector3(0,1.25,.01),.0011,Color("24373c"))
	for i in 3:
		var row:=Node3D.new();row.position.y=.8-i*.55;rule_board.add_child(row)
		labels.append(panel.text(row,"",Vector3(0,.12,.01),.00078,Color("24373c")))
		panel.box(row,Vector3(0,-.07,0),Vector3(1.8,.085,.015),Color("24373c"))
		bars.append(panel.box(row,Vector3(0,-.07,.013),Vector3(1.8,.075,.015),[MINT,CORAL,GOLD][i]))
	panel.text(rule_board,"approach speed / distance to opening",Vector3(0,-.62,.01),.00055,Color("24373c"))
	var light:=OmniLight3D.new();light.position=Vector3(0,4,3);light.omni_range=8;light.light_energy=1.8;add_child(light)

func update_labels() -> void:
	var names:=["NEAR + SLOW / OPEN","NEAR + FAST / CURL","FAR / REST"]
	if reversed_rules:names=["NEAR + FAST / OPEN","NEAR + SLOW / CURL","FAR / REST"]
	for i in 3:
		bars[i].scale.x=maxf(weights[i],.002);bars[i].position.x=-.9+.9*weights[i]
		labels[i].text=names[i]+"  %.2f"%weights[i]
	panel.screen_title.text=source_kind
	panel.screen_state.text="DISTANCE %.2fm\nAPPROACH %.2fm/s"%[sample_distance,speed]

func select_mode(value: int) -> void:
	mode=clampi(value,0,2);have_previous=false;speed=0;sync_controls()

func sync_controls() -> void:
	syncing=true
	panel.reach_dial.set_normalized_value((reach-1)/6)
	panel.pace_dial.set_normalized_value((pace-.4)/2)
	for i in 3:panel.buttons[["LIVE","DEMO SLOW","DEMO FAST"][i]].set_selected(mode==i)
	panel.buttons["SWAP RULES"].set_selected(reversed_rules)
	syncing=false

func read_controls(_v: float) -> void:
	if syncing:return
	reach=1+6*panel.reach_dial.get_normalized_value();pace=.4+2*panel.pace_dial.get_normalized_value()

func reset() -> void:
	reach=4;pace=1.2;reversed_rules=false;select_mode(0)

func swap_rules() -> void:
	reversed_rules=not reversed_rules;sync_controls();update_labels()
