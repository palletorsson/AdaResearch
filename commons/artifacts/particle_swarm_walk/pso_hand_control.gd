extends Node3D
## Read existing scored records. All commands go through the printed host.
const PointBody=preload("point_body.gd")
const PushButton=preload("res://commons/interactables/push_button.tscn")
const DOCK=Vector3(-.7,1.2,6.9)
var study:Node3D
var point:XRToolsPickable
var panel:Node3D
var state_words:Label3D
var current_words:Label3D
var personal_words:Label3D
var shared_words:Label3D
var buttons:Array[Node3D]=[]
var released:=0.0

func _ready()->void:
	process_priority=1
	point=PointBody.new();point.name="CarrySwarmScores";add_child(point);point.position=DOCK
	point.action_pressed.connect(func(_p):
		if point.held():study.toggle_play())
	panel=Node3D.new();point.add_child(panel);panel.rotation.x=deg_to_rad(25)
	box(Vector3(.72,.025,.94),Vector3(0,.045,-.51),Color("121b28"),panel)
	box(Vector3(.3,1.04,.3),Vector3(DOCK.x,.52,DOCK.z),Color("e8e2d6"),self,true)
	state_words=words("",Vector3(0,.065,-.89),24)
	current_words=words("",Vector3(0,.065,-.75),24)
	personal_words=words("",Vector3(0,.065,-.65),24)
	shared_words=words("",Vector3(0,.065,-.55),24)
	personal_words.modulate=study.BLUE;shared_words.modulate=study.GOLD
	words("Change rule: keep motion, reset memories",Vector3(0,.065,-.445),18)
	var actions:Array[Callable]=[study.toggle_play,study.single_step,study.restart,func():study.change(0),func():study.change(1),func():study.change(2)]
	for i in range(6):
		var button:=PushButton.instantiate();button.name=["Run","Step","Reset","Center","Edge","Ridge"][i]
		panel.add_child(button);button.position=Vector3((i%3-1)*.23,.07,-.30 if i<3 else -.12);button.rotation=Vector3.ZERO
		button.pressed.connect(actions[i]);buttons.append(button)
		words(["RUN / PAUSE","ONE STEP","RESTART","CENTER","EDGE","RIDGE"][i],button.position+Vector3(0,.015,-.063),18)
	var notice:Label3D=study.label("TAKE THE BLACK POINT\nTrigger: run / pause\nDrop: docks after 5 s",DOCK+Vector3(.68,.24,-.45),18)
	notice.pixel_size=.0012;notice.outline_size=4;notice.name="HandControlInstructions"
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

func record_text(title:String,at:Vector2,score:float)->String:
	# Suppress signed zero at display precision; never alter a stored record.
	return "%s (%+.2f, %+.2f)  score %+.2f"%[title,display_value(at.x),display_value(at.y),display_value(score)]

func display_value(value:float)->float:
	return 0.0 if absf(value)<.005 else value

func _process(delta:float)->void:
	if point.held():released=0
	else:
		released+=delta
		if released>=5:point.position=DOCK;point.rotation=Vector3.ZERO
	var i:int=study.witness
	var mode:String="HELD: release sphere" if study.any_held() else ("RUN" if study.playing else "PAUSE")
	state_words.text="Point %d / %s / step %d\n%s / larger wins"%[i,mode,study.model.steps,["CENTER","EDGE","RIDGE"][study.model.objective]]
	current_words.text=record_text("NOW",study.model.positions[i],study.model.score(study.model.positions[i]))
	personal_words.text=record_text("MY BEST",study.model.best_positions[i],study.model.best_scores[i])
	shared_words.text=record_text("GROUP BEST",study.model.shared_position,study.model.shared_score)
	buttons[0].set_selected(study.playing and not study.any_held())
	for j in range(3):buttons[j+3].set_selected(study.model.objective==j)
