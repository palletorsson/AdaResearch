extends Node3D
## Ten retained panels: layout -> trace/cut -> robot transfer -> fit -> wear.
const Cloth = preload("res://commons/artifacts/garment_cutting_table/cloth_record.gd")
const Panels = preload("res://commons/artifacts/garment_cutting_table/suit_panels.gd")
const Suit = preload("res://commons/player/tailored_suit.gd")
const G = preload("res://commons/artifacts/jacquard_weaver/weave_geometry.gd")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
@export var cloth_path: String = Cloth.SAVE_PATH
var record: Dictionary = {}
var phase := "layout"
var elapsed := 0.0
var completed := 0
var panels: Array[MeshInstance3D] = []
var fitted_meshes: Array[ArrayMesh] = []
var outlines: Array[MeshInstance3D] = []
var buttons: Dictionary = {}
var status: Label3D
var source_label: Label3D
var bolt: MeshInstance3D
var suit: Node3D
var fitting: Node3D
var arm_a: MeshInstance3D
var arm_b: MeshInstance3D
var elbow: MeshInstance3D
var tool: Node3D
var cutter: MeshInstance3D
var tip := Vector3(-1.1,2.3,-.9)
var jaws: Array[MeshInstance3D] = []
var notices := "Choose cloth. CUT traces ten pieces."
var previous_outfit := ""
var worn_wardrobe: WeakRef
const FIT := Vector3(2.15,1.72,-.2)
const SHOULDER := Vector3(-1.1,1.65,-1.4)
const STEP_TIME := 2.0

func _ready() -> void:
	add_to_group("garment_cutting_tables")
	var dark := G.material("282c30",.3); var oak := G.material("ba9a72"); var brass := G.material("c9a668",.6)
	G.box(self,Vector3(-1.1,.91,0),Vector3(3.4,.16,2.55),oak,true)
	G.box(self,Vector3(-1.1,1.0,0),Vector3(3.27,.025,2.43),G.material("233c37"))
	for x in [-2.48,.28]:
		for z in [-1.0,1.0]:G.box(self,Vector3(x,.43,z),Vector3(.09,.86,.09),dark,true)
	for i in range(33):
		G.box(self,Vector3(-2.68+i*.1,1.016,1.03),Vector3(.004,.005,.09 if i%5==0 else .04),brass)
	bolt=MeshInstance3D.new();var plane:=QuadMesh.new();plane.size=Vector2(2.6,1.95);bolt.mesh=plane
	bolt.rotation_degrees.x=-90;bolt.position=Vector3(-1.11,1.019,0);add_child(bolt)
	for i in range(10):
		fitted_meshes.append(Panels.mesh(i))
		var piece:=MeshInstance3D.new();piece.mesh=Panels.mesh(i,0);piece.position=Panels.table_position(i);piece.name="Cut_"+str(i+1);add_child(piece);panels.append(piece)
		var path:=PackedVector3Array()
		for v in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1),Vector2(0,0)]:path.append(Panels.flat_point(i,v.x,v.y)+piece.position+Vector3(0,.007,0))
		outlines.append(G.yarn(self,path,G.material("f1d493"),.005))
		var label:=G.label(self,"%02d %s"%[i+1,Panels.NAMES[i]],piece.position+Vector3(0,.035,.44),8);label.rotation_degrees.x=-90
	G.box(self,Vector3(2.15,.08,-.2),Vector3(1.15,.16,1.15),dark,true)
	fitting=Node3D.new();fitting.position=FIT;fitting.rotation.y=PI;add_child(fitting)
	suit=Suit.new();fitting.add_child(suit);suit.visible=false
	var head:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.10;sphere.height=.26;head.mesh=sphere;head.position=Vector3(0,.10,0);head.material_override=G.material("d8cec0",.3);fitting.add_child(head)
	G.box(fitting,Vector3(0,-.34,0),Vector3(.24,.55,.17),G.material("a19c96",.3))
	G.box(self,Vector3(2.15,.7,-.2),Vector3(.035,1.4,.035),brass)
	G.box(self,Vector3(2.15,2.22,-.43),Vector3(1.7,.30,.04),dark)
	G.label(self,"02 / ASSEMBLE & FIT",Vector3(2.15,2.22,-.4),17)
	G.box(self,Vector3(-1.1,2.61,-1.58),Vector3(3.35,.42,.04),dark)
	G.label(self,"01 / CUTTING TABLE",Vector3(-1.1,2.68,-1.55),22)
	source_label=G.label(self,"",Vector3(-1.1,2.52,-1.55),11)
	G.box(self,Vector3(-1.1,.76,1.33),Vector3(3.22,.34,.05),dark)
	status=G.label(self,"",Vector3(-1.1,.76,1.36),11)
	for i in range(6):
		var key: String=["CLOTH","CUT","ASSEMBLE","PAUSE","WEAR","RESET"][i]
		button(key,Vector3(-2.42+i*.53,1.06,1.17))
	button("LOAD LOOM",Vector3(.80,1.08,.76))
	button("TAKE OFF",Vector3(2.15,1.08,.88))
	for p in [Vector3(.8,0,.76),Vector3(2.15,0,.88)]:
		G.box(self,p+Vector3(0,.50,0),Vector3(.045,1,.045),brass)
		G.box(self,p+Vector3(0,1.04,.05),Vector3(.40,.045,.35),dark)
	_build_arm(dark,brass)
	for p in [Vector3(-2.8,3.2,1.2),Vector3(2.7,3.2,1.1)]:
		var light:=OmniLight3D.new();light.position=p;light.omni_range=6;light.light_energy=1.7;add_child(light)
	set_meta("em_visibility_bounds",AABB(Vector3(-3,0,-1.9),Vector3(6.1,4.2,3.7)))
	record=Cloth.load_record(cloth_path)
	if record.is_empty():record=Cloth.sample("tartan")
	set_record(record)

func button(key: String, p: Vector3) -> void:
	var b:Node3D=PUSH_BUTTON.instantiate();b.position=p;b.scale=Vector3.ONE*.8;add_child(b)
	b.get_node("InteractableAreaButton").button_pressed.connect(func(_b):act(key))
	buttons[key]=b
	var l:=G.label(self,key,p+Vector3(0,.008,.12),9);l.rotation_degrees.x=-65

var paused := false
func act(key: String) -> void:
	match key:
		"CUT":
			if phase=="layout":phase="cutting";elapsed=0;completed=0;paused=false
		"ASSEMBLE":
			if phase=="cut":phase="assembling";elapsed=0;completed=0;paused=false
			elif phase!="ready":notices="CUT the pieces first."
		"PAUSE":paused=not paused
		"RESET":set_record(record)
		"CLOTH":
			var keys := ["tartan","houndstooth","optical"]
			var at: int=keys.find(str(record.get("sample","tartan")))
			var next: String=keys[(at+1)%keys.size()]
			var data:=Cloth.sample(next);data["sample"]=next;set_record(data)
		"LOAD LOOM":
			var data:=Cloth.load_record(cloth_path)
			if data.is_empty():notices="At the loom: SAVE CLOTH, then LOAD LOOM here."
			else:set_record(data)
		"WEAR":wear()
		"TAKE OFF":
			var w:Node=worn_wardrobe.get_ref() if worn_wardrobe else null
			if is_instance_valid(w):w.choose_outfit(previous_outfit);worn_wardrobe=null;notices="Previous outfit restored."
	refresh()

func set_record(data: Dictionary) -> bool:
	if not Cloth.valid(data):return false
	record=data.duplicate(true);phase="layout";elapsed=0;completed=0;paused=false
	if panels.is_empty():return true
	var mat:=Cloth.material(record);bolt.material_override=mat;bolt.visible=true
	for i in range(10):
		panels[i].mesh=Panels.mesh(i,0);panels[i].material_override=mat;panels[i].position=Panels.table_position(i);panels[i].rotation=Vector3.ZERO;panels[i].visible=true;outlines[i].visible=true
	suit.set_record(record);suit.visible=false;tip=Vector3(-1.1,2.3,-.9)
	notices="Choose cloth. CUT traces ten pieces.";refresh();return true

func _process(delta: float) -> void:
	advance(delta)
	pose_arm(tip)

func advance(delta: float) -> void:
	if paused or (phase!="cutting" and phase!="assembling"):return
	elapsed=minf(elapsed+maxf(0,delta),10*STEP_TIME)
	completed=mini(10,int(elapsed/STEP_TIME))
	var index:=mini(9,completed);var t:=fmod(elapsed,STEP_TIME)/STEP_TIME
	if phase=="cutting":
		var corners := [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1),Vector2(0,0)]
		var edge:=mini(3,int(t*4));var uv:Vector2=corners[edge].lerp(corners[edge+1],fmod(t*4,1))
		tip=Panels.table_position(index)+Panels.flat_point(index,uv.x,uv.y)+Vector3(0,.055,0)
		if completed==10:phase="cut";bolt.visible=false;notices="Ten cut pieces. ASSEMBLE carries them to the fitting."
	else:
		for i in range(10):
			if i<completed:
				panels[i].mesh=fitted_meshes[i];panels[i].position=FIT;panels[i].rotation.y=PI
				outlines[i].visible=false
			elif i==index:
				var a:=smoothstep(0.0,1.0,t)
				panels[i].position=Panels.table_position(i).lerp(FIT,a)+Vector3.UP*sin(a*PI)*.65
				panels[i].rotation.y=a*PI;panels[i].mesh=Panels.mesh(i,smoothstep(.25,.95,t));outlines[i].visible=false
		var centre:=Panels.flat_point(index,.5,.5).lerp(Panels.curved_point(index,.5,.5),smoothstep(.25,.95,t))
		tip=to_local(panels[index].to_global(centre))+Vector3(0,.09,0)
		if completed==10:
			phase="ready";suit.visible=true
			for panel in panels:panel.visible=false
			notices="Fitted. WEAR puts this cloth and these panels on you."
	refresh()

func wardrobe() -> Node:
	var cam:=get_viewport().get_camera_3d()
	for w in get_tree().get_nodes_in_group("costume_wardrobes"):
		if w.has_method("wears_head") and w.wears_head(cam):return w
	return null

func wear() -> bool:
	if phase!="ready":notices="Finish CUT and ASSEMBLE before wearing.";return false
	var w:=wardrobe()
	if not w:notices="No active player wardrobe found.";return false
	if not worn_wardrobe or worn_wardrobe.get_ref()!=w:
		previous_outfit=w.costume.outfit_id;worn_wardrobe=weakref(w)
	var ok:bool=w.set_tailored_suit(record)
	notices="Suit worn. Look down or use the nearby mirror." if ok else "Suit applied; appearance could not be saved."
	return ok

func refresh() -> void:
	if not status:return
	status.text=("PAUSED / " if paused else "")+phase.to_upper()+" · "+str(completed)+" / 10\n"+notices
	source_label.text=str(record.get("name","LOOM CLOTH"))+" · "+str(record.picks.size())+" RECORDED PICKS → TEN PANELS"

func _build_arm(dark: Material, brass: Material) -> void:
	G.box(self,Vector3(-1.1,.80,-1.4),Vector3(.45,1.6,.45),dark,true)
	G.box(self,SHOULDER,Vector3(.23,.16,.23),brass)
	arm_a=G.box(self,Vector3.ZERO,Vector3(.12,1,.12),G.material("ded9cb",.6))
	arm_b=G.box(self,Vector3.ZERO,Vector3(.095,1,.095),G.material("ded9cb",.6))
	elbow=G.box(self,Vector3.ZERO,Vector3(.23,.23,.23),brass)
	tool=Node3D.new();add_child(tool)
	G.box(tool,Vector3(0,.04,0),Vector3(.18,.07,.12),dark)
	for side in [-1.0,1.0]:jaws.append(G.box(tool,Vector3(side*.07,-.03,0),Vector3(.025,.09,.09),brass))
	cutter=MeshInstance3D.new();var disc:=CylinderMesh.new();disc.top_radius=.055;disc.bottom_radius=.055;disc.height=.012;cutter.mesh=disc;cutter.rotation.z=PI*.5;cutter.position.y=-.025;cutter.material_override=brass;tool.add_child(cutter)
	pose_arm(tip)

func pose_arm(target: Vector3) -> void:
	cutter.visible=phase=="cutting"
	for jaw in jaws:jaw.visible=phase!="cutting"
	var d:=target-SHOULDER;var length:=d.length();var middle:Vector3=SHOULDER+d*.5
	var normal:=d.cross(Vector3.FORWARD).normalized()
	if normal.y<0:normal=-normal
	if normal.length_squared()<.1:normal=Vector3.UP
	var joint:=middle+normal*sqrt(maxf(0,2.25*2.25-length*length*.25))
	segment(arm_a,SHOULDER,joint);segment(arm_b,joint,target);elbow.position=joint;tool.position=target

func segment(mesh: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	mesh.position=(a+b)*.5;mesh.scale.y=a.distance_to(b)
	mesh.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
