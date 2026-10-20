extends Node3D
## A portable view/control of the existing colony. No separate model or agents.
const PointBody=preload("point_body.gd")
const PushButton=preload("res://commons/interactables/push_button.tscn")
const DOCK=Vector3(-1.2,1.2,6.5)
var study:Node3D
var point:XRToolsPickable
var state_words:Label3D
var read_words:Label3D
var write_words:Label3D
var samples:Label3D
var buttons:Array[Node3D]=[]
var released:=0.0

func _ready()->void:
	process_priority=1
	point=PointBody.new();point.name="CarryColonyControls";add_child(point);point.position=DOCK
	point.action_pressed.connect(func(_p):
		if point.held():study.toggle_play())
	box(Vector3(.62,.025,.67),Vector3(0,.045,-.365),Color("121b28"),point)
	box(Vector3(.3,1.04,.3),Vector3(DOCK.x,.52,DOCK.z),Color("e8e2d6"),self,true)
	state_words=words("",Vector3(0,.065,-.61),22)
	read_words=words("",Vector3(-.15,.065,-.49),19)
	write_words=words("",Vector3(.15,.065,-.49),19)
	samples=words("",Vector3(0,.065,-.415),18)
	var actions:Array[Callable]=[study.toggle_play,study.single_step,study.replace,study.restart]
	for i in range(4):
		var b:=PushButton.instantiate();b.name=["Run","Step","Replace","Reset"][i]
		point.add_child(b);b.position=Vector3(-.15 if i%2==0 else .15,.07,-.29 if i<2 else -.12);b.rotation=Vector3.ZERO
		b.pressed.connect(actions[i]);buttons.append(b)
		words(["RUN / PAUSE","ONE TICK","REPLACE POINTS","CLEAR ALL"][i],b.position+Vector3(0,.015,-.061),14)
	var notice:Label3D=study.label("TAKE THE BLACK POINT\nTrigger: run / pause\nDrop: docks after 5 s",DOCK+Vector3(0,.48,-.45),18)
	notice.pixel_size=.0015;notice.outline_size=4
	notice.name="HandControlInstructions"
	_process(0)

func words(text:String,at:Vector3,size:int)->Label3D:
	var label:=Label3D.new();label.text=text;label.position=at;label.font_size=size;label.pixel_size=.001
	label.rotation.x=-PI/2;label.outline_size=3;point.add_child(label);return label

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
	var i:int=study.witness
	var returning:bool=study.model.carrying[i]
	var mode:String="HELD: release agent to step" if study.any_held() else ("RUN" if study.playing else "PAUSE")
	state_words.text="Point %d / %s\n%s / tick %d\nDelivered %d"%[i,"RETURN" if returning else "SEARCH",mode,study.model.steps,study.model.delivered]
	read_words.text="READ\n"+("HOME" if returning else "FOOD")
	write_words.text="LEAVE\n"+("FOOD" if returning else "HOME")
	read_words.modulate=study.BLUE if returning else study.ROSE
	write_words.modulate=study.ROSE if returning else study.BLUE
	samples.text="L %.2f   F %.2f   R %.2f"%[study.model.sense(i,study.Colony.TURN,returning),study.model.sense(i,0,returning),study.model.sense(i,-study.Colony.TURN,returning)]
	buttons[0].set_selected(study.playing and not study.any_held())
