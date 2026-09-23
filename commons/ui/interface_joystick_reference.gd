extends Node3D
## Three XY settings, displayed as points: continuous, detented and returning.
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
var scene_root := "res://commons/interactables/"
var controls: Array[Node3D] = []
var receivers: Array[Node3D] = []
var station: Node3D

func _ready() -> void:
	station = Node3D.new()
	station.name = "Controls"
	station.position = Vector3(0,.88,.60)
	station.rotation_degrees.x = -55
	add_child(station)
	_box(station,"Case",Vector3(.86,.36,.07),Vector3(0,-.025,-.057),Color(.18,.21,.22))
	_box(station,"Face",Vector3(.84,.34,.018),Vector3(0,-.025,-.03),Color(.76,.78,.73))
	var stand := Node3D.new()
	stand.name = "ConsoleStand"
	stand.position.z = .60
	add_child(stand)
	_box(stand,"Stem",Vector3(.14,.82,.13),Vector3(0,.41,0),Color(.18,.21,.22))
	_box(stand,"Foot",Vector3(.65,.045,.38),Vector3(0,.0225,0),Color(.18,.21,.22))
	for index in 3:
		var x := (index-1)*.27
		var control: Node3D = load(scene_root+"joystick_"+["smooth","snap","zero"][index]+".tscn").instantiate()
		control.position.x = x
		station.add_child(control)
		controls.append(control)
		var display := Node3D.new()
		display.name = "Receiver_%d" % index
		display.position = Vector3(x,1.42,0)
		add_child(display)
		_box(display,"Case",Vector3(.25,.32,.045),Vector3(0,.017,-.028),Color(.16,.19,.21))
		_box(display,"Plot",Vector3(.23,.23,.01),Vector3(0,-.011,0),Color(.04,.06,.08))
		for line in [-1,0,1]:
			_box(display,"GridH",Vector3(.22,.0015,.001),Vector3(0,line*.10-.011,.006),Color(.33,.39,.42))
			_box(display,"GridV",Vector3(.0015,.22,.001),Vector3(line*.10,-.011,.006),Color(.33,.39,.42))
		_print(display,["CONTINUOUS","5° DETENTS","RETURN TO ZERO"][index],Vector2(.222,.026),Vector3(0,.145,.002))
		var marker := _box(display,"Point",Vector3(.025,.025,.018),Vector3(0,-.011,.016),Color(.99,.37,.10))
		receivers.append(marker)
		_box(self,"DisplayPost",Vector3(.03,1.27,.035),Vector3(x,.635,-.035),Color(.18,.21,.22))
		control.get_node("JoystickOrigin/InteractableJoystick").joystick_moved.connect(func(a:float,b:float): marker.position=Vector3(a/45*.10,-b/45*.10-.011,.016))
	_print(self,"GRAB · MOVE · LET GO",Vector2(.85,.060),Vector3(0,1.89,0))
	_print(self,"Same hand. Three release rules.",Vector2(.83,.038),Vector3(0,1.81,0))
	_box(self,"HeadingBacking",Vector3(.89,.16,.025),Vector3(0,1.852,-.015),Color(.10,.13,.15))

func exhibit_control_parts() -> Array[Node3D]:
	return [station,get_node("ConsoleStand")]

func _print(parent: Node3D, text: String, size: Vector2, at: Vector3) -> void:
	var label := BakedText.make_label_mesh(text,Color(.92,.94,.86),size,2200,true)
	label.position=at
	parent.add_child(label)

func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name=node_name
	mesh.mesh=BoxMesh.new()
	mesh.mesh.size=size
	mesh.position=at
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=color
	mat.roughness=.65
	mesh.material_override=mat
	parent.add_child(mesh)
	return mesh
