extends Node3D
## Read the account beside a body; filtering never removes its support.
const PointBody=preload("point_body.gd")
const PushButton=preload("res://commons/interactables/push_button.tscn")
const DOCK=Vector3(-.7,1.2,7.1)
const ROWS=["INITIAL","BORN","LOST","SUPPLIED","EXPECTED","ACTUAL","GAP"]
var study:Node3D
var point:XRToolsPickable
var panel:Node3D
var state_words:Label3D
var selected_words:Label3D
var cells:Array[Label3D]=[]
var buttons:Array[Node3D]=[]
var released:=0.0

func _ready()->void:
	process_priority=1
	point=PointBody.new();point.name="CarryPopulationAccount";add_child(point);point.position=DOCK
	point.action_pressed.connect(func(_p):
		if point.held():study.toggle_play())
	panel=Node3D.new();point.add_child(panel);panel.rotation.x=deg_to_rad(25)
	box(Vector3(.78,.025,1.02),Vector3(0,.045,-.55),Color("121b28"),panel)
	box(Vector3(.3,1.04,.3),Vector3(DOCK.x,.52,DOCK.z),Color("e8e2d6"),self,true)
	state_words=words("",Vector3(0,.065,-.96),22)
	selected_words=words("",Vector3(0,.065,-.835),20)
	words("PREY",Vector3(.015,.065,-.735),22).modulate=study.PREY
	words("PREDATORS",Vector3(.245,.065,-.735),22).modulate=study.PREDATOR
	for row in range(7):
		var z:float=-.68+row*.047
		words(ROWS[row],Vector3(-.245,.065,z),22)
		for column in range(2):cells.append(words("",Vector3(.015+column*.23,.065,z),24))
	var actions:Array[Callable]=[study.toggle_play,study.single_step,study.restart,study.toggle_supply]
	for i in range(4):
		var b:=PushButton.instantiate();b.name=["Run","Step","Restart","SupplyRow"][i]
		panel.add_child(b);b.position=Vector3(-.19 if i%2==0 else .19,.07,-.255 if i<2 else -.11);b.rotation=Vector3.ZERO
		b.pressed.connect(actions[i]);buttons.append(b)
		words(["RUN / PAUSE","ONE STEP","RESTART","SUPPLY ROW"][i],b.position+Vector3(0,.015,-.06),18)
	var notice:Label3D=study.label("TAKE THE BLACK POINT\nTrigger: run / pause\nDrop: docks after 5 s",DOCK+Vector3(.74,.24,-.45),18)
	notice.pixel_size=.0012;notice.outline_size=4;notice.name="HandAccountInstructions"
	_process(0)

func words(text:String,at:Vector3,size:int)->Label3D:
	var label:=Label3D.new();label.text=text;label.position=at;label.font_size=size;label.pixel_size=.001
	label.rotation.x=-PI/2;label.outline_size=3;panel.add_child(label);return label

func box(size:Vector3,at:Vector3,colour:Color,parent:Node3D,solid:bool=false)->void:
	var surface:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size;surface.mesh=mesh
	var finish:=StandardMaterial3D.new();finish.albedo_color=colour;surface.material_override=finish;surface.position=at;parent.add_child(surface)
	if solid:
		var body:=StaticBody3D.new();body.position=at;parent.add_child(body)
		var c:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;c.shape=shape;body.add_child(c)

func _process(delta:float)->void:
	if point.held():released=0
	else:
		released+=delta
		if released>=5:point.position=DOCK;point.rotation=Vector3.ZERO
	var mode:String="HELD: release sphere" if study.any_held() else ("RUN" if study.playing else "PAUSE")
	state_words.text="%s / step %d\n%s"%[mode,study.model.tick,"FULL ACCOUNT" if study.show_supply else "SUPPLY OMITTED / bodies remain"]
	selected_words.text="No selected body"
	for body in study.bodies():
		if body.get_instance_id()==study.witness:
			selected_words.text="Selected %s / %s\nhealth %.2f"%["PREY" if study.model.prey_list.has(body) else "PREDATOR",str(body.get_meta("arrival")).to_upper(),body.health]
			break
	for column in range(2):
		var species:String=["prey","predator"][column]
		var actual:int=study.model.prey_list.size() if column==0 else study.model.predator_list.size()
		var values:Array=[study.account.initial[species],study.account.total(species,"birth"),study.account.total(species,"loss"),
			study.account.total(species,"supplied") if study.show_supply else "omitted",study.account.expected(species,study.show_supply),actual,study.account.difference(species,actual,study.show_supply)]
		for row in range(7):
			var cell:Label3D=cells[row*2+column];cell.text=str(values[row])
			cell.modulate=study.SUPPLY if row==3 else Color.WHITE
			if row==6:cell.modulate=Color("ff8290") if int(values[row])!=0 else Color("9ff082")
	buttons[0].set_selected(study.playing and not study.any_held())
	buttons[3].set_selected(study.show_supply)
