extends Node3D
## Angle is a setting; angular velocity accumulates pose until the command stops.
const BakedText=preload("res://commons/utils/baked_text_albedo.gd")
var controls:Array[Node3D]=[]
var rotors:Array[Node3D]=[]
var station:Node3D
var speed_degrees:=0.0
var accumulated_degrees:=0.0

func _ready()->void:
	station=Node3D.new()
	station.name="Controls"
	station.position=Vector3(0,.99,.5)
	station.rotation_degrees.x=-40
	add_child(station)
	_box(station,"Case",Vector3(.54,.29,.05),Vector3(0,0,-.037),Color(.16,.20,.21))
	var stand:=Node3D.new()
	stand.name="ConsoleStand"
	stand.position.z=.5
	add_child(stand)
	_box(stand,"Stem",Vector3(.12,.94,.10),Vector3(0,.47,0),Color(.16,.20,.21))
	_box(stand,"Foot",Vector3(.48,.04,.36),Vector3(0,.02,0),Color(.16,.20,.21))
	for i in 2:
		var x:float=(-1 if i==0 else 1)*.14
		var control:Node3D=load("res://commons/interactables/"+("wheel" if i==0 else "lever")+"_smooth.tscn").instantiate()
		control.position.x=x
		station.add_child(control)
		controls.append(control)
		var rotor:=Node3D.new()
		rotor.name="PositionRotor" if i==0 else "SpeedRotor"
		rotor.position=Vector3(x,1.5,0)
		add_child(rotor)
		rotors.append(rotor)
		_box(rotor,"Blade",Vector3(.19,.028,.032),Vector3(.025,0,.024),Color(.95,.40,.11) if i==0 else Color(.20,.73,.78))
		_box(self,"ReceiverBacking",Vector3(.25,.36,.024),Vector3(x,1.5,-.012),Color(.08,.11,.13))
		_print(self,"ANGLE" if i==0 else "SPEED",Vector2(.23,.033),Vector3(x,1.65,.003))
		_print(self,"stays here" if i==0 else "moves while held",Vector2(.23,.025),Vector3(x,1.35,.003))
		_box(self,"ReceiverPost",Vector3(.035,1.35,.035),Vector3(x,.675,-.025),Color(.16,.20,.21))
	controls[0].hinge.hinge_limit_min=-180
	controls[0].hinge.hinge_limit_max=180
	controls[0].set_caption("SET ANGLE")
	controls[0].hinge_moved.connect(func(angle:float):rotors[0].rotation_degrees.z=angle)
	controls[1].hinge.default_on_release=true
	controls[1].hinge.default_position=0
	controls[1].set_caption("COMMAND SPEED")
	controls[1].set_display_range(-90,90,"°/s")
	controls[1].hinge_moved.connect(func(angle:float):speed_degrees=angle*2;set_process(not is_zero_approx(speed_degrees)))
	_box(self,"Header",Vector3(.59,.15,.024),Vector3(0,1.82,-.012),Color(.08,.11,.13))
	_print(self,"PLACE / KEEP MOVING",Vector2(.55,.038),Vector3(0,1.85,.003))
	_print(self,"Let go. What stops? What stays?",Vector2(.55,.028),Vector3(0,1.79,.003))
	set_process(false)

func _process(delta:float)->void: advance_receiver(delta)
func advance_receiver(delta:float)->void:
	accumulated_degrees=wrapf(accumulated_degrees+speed_degrees*delta,-180,180)
	rotors[1].rotation_degrees.z=accumulated_degrees
func exhibit_control_parts()->Array[Node3D]:return [station,get_node("ConsoleStand")]
func _print(parent:Node3D,text:String,size:Vector2,at:Vector3)->void:
	var label:=BakedText.make_label_mesh(text,Color(.91,.94,.86),size,2200,true)
	label.position=at
	parent.add_child(label)
func _box(parent:Node3D,label:String,size:Vector3,at:Vector3,color:Color)->void:
	var mesh:=MeshInstance3D.new()
	mesh.name=label
	mesh.mesh=BoxMesh.new()
	mesh.mesh.size=size
	mesh.position=at
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=color
	mat.roughness=.7
	mesh.material_override=mat
	parent.add_child(mesh)
