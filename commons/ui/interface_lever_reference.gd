extends Node3D
## Keep the receiver identical so detents and release are the only changing laws.
const BakedText=preload("res://commons/utils/baked_text_albedo.gd")
var controls: Array[Node3D]=[]
var receivers: Array[Node3D]=[]
var station: Node3D
func _ready() -> void:
	station=Node3D.new(); station.name="Controls"
	station.position=Vector3(0,.99,.5); station.rotation_degrees.x=-40
	add_child(station)
	_box(station,"Case",Vector3(.72,.29,.05),Vector3(0,0,-.037),Color(.16,.20,.21))
	var stand:=Node3D.new(); stand.name="ConsoleStand"; stand.position.z=.5; add_child(stand)
	_box(stand,"Stem",Vector3(.14,.94,.12),Vector3(0,.47,0),Color(.16,.20,.21))
	_box(stand,"Foot",Vector3(.60,.04,.36),Vector3(0,.02,0),Color(.16,.20,.21))
	for i in 3:
		var x: float=(i-1)*.24
		var type: String=["smooth","snap","zero"][i]
		var control: Node3D=load("res://commons/interactables/lever_"+type+".tscn").instantiate()
		control.position.x=x; station.add_child(control); controls.append(control)
		control.set_caption(["CONTINUOUS","STEP 5°","RETURN 0°"][i])
		var receiver:=Node3D.new(); receiver.name="Receiver"+str(i)
		receiver.position=Vector3(x,1.48,0); add_child(receiver); receivers.append(receiver)
		_box(receiver,"Arm",Vector3(.16,.025,.03),Vector3(.025,0,.03),[Color(.95,.4,.11),Color(.20,.73,.78),Color(.76,.46,.85)][i])
		_box(self,"Backing",Vector3(.22,.33,.024),Vector3(x,1.48,-.012),Color(.08,.11,.13))
		_print(["ANY ANGLE","5° STEPS","LET GO: 0°"][i],Vector2(.21,.027),Vector3(x,1.61,.003))
		_print(["stays","stays","returns"][i],Vector2(.21,.025),Vector3(x,1.35,.003))
		_box(self,"Post",Vector3(.03,1.35,.03),Vector3(x,.675,-.025),Color(.16,.20,.21))
		control.hinge_moved.connect(func(angle: float): receiver.rotation_degrees.z=angle)
	_box(self,"Header",Vector3(.75,.14,.024),Vector3(0,1.79,-.012),Color(.08,.11,.13))
	_print("SAME HAND / THREE LAWS",Vector2(.71,.035),Vector3(0,1.82,.003))
	_print("Move each lever. Then let go.",Vector2(.71,.028),Vector3(0,1.76,.003))
func exhibit_control_parts() -> Array[Node3D]: return [station,get_node("ConsoleStand")]
func _print(text: String,size: Vector2,at: Vector3) -> void:
	var label:=BakedText.make_label_mesh(text,Color(.91,.94,.86),size,2200,true)
	label.position=at; add_child(label)
func _box(parent: Node3D,label: String,size: Vector3,at: Vector3,color: Color) -> void:
	var mesh:=MeshInstance3D.new(); mesh.name=label; mesh.mesh=BoxMesh.new(); mesh.mesh.size=size; mesh.position=at
	var mat:=StandardMaterial3D.new(); mat.albedo_color=color; mat.roughness=.7; mesh.material_override=mat
	parent.add_child(mesh)
