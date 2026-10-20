extends Node3D
## A rigid architectural assembly, articulated by Node3D transforms.
## Observation model only: moving bays deliberately have no collision/navigation.
## The fixed museum floor and console are collidable. No portals or gravity changes.
const Console = preload("res://commons/artifacts/architecture_spine/architecture_console.gd")
const Handle = preload("res://algorithms/randomness/proceduralrandomness/geometrybased/omoss/pivot_handle.gd")
const COUNT := 8
const LENGTH := 1.2
const HEIGHT := 2.6
const WIDTH := 2.2
const START := Vector3(-4.8,.38,-2.2)
const HANDLE_HOME := Vector3(-1.04,.93,3.4)
const HANDLE_TRAVEL := .65
var joints: Array[Node3D] = []
var markers: Array[Node3D] = []
var original_meshes: Array[MeshInstance3D] = []
var panel: Node3D
var handle: RigidBody3D
var readout: Label3D
var source: Node3D
var bend_degrees := 0.0
var separation := 0.0
var ratio := 1.0
var pivot_height := 0.0
var syncing := false
var concrete := Color("d3cbbd")
var pale := Color("ede3d0")
var ink := Color("243038")
var pink := Color("d75e93")

func _ready() -> void:
	panel=Console.new();panel.position=Vector3(0,0,3.7);add_child(panel)
	for dial in [panel.bend_dial,panel.gap_dial,panel.scale_dial]:
		dial.hinge_moved.connect(func(_v):read_controls())
	for id in panel.buttons: panel.buttons[id].pressed.connect(preset.bind(id))
	source=Node3D.new();source.name="ArchitectureRig";source.position=START;add_child(source)
	var parent:Node3D=source
	for i in COUNT:
		var joint:=Node3D.new();joint.name="Bay_%02d"%(i+1);parent.add_child(joint);joints.append(joint)
		build_bay(joint,i);parent=joint
		var marker:=Node3D.new();joint.add_child(marker);markers.append(marker)
		var axis:=MeshInstance3D.new();var axle:=CylinderMesh.new();axle.top_radius=.022;axle.bottom_radius=.022;axle.height=WIDTH+.28;axle.radial_segments=10
		axis.mesh=axle;axis.rotation_degrees.x=90;axis.material_override=panel.material(pink);marker.add_child(axis)
		for z in [-WIDTH*.5-.16,WIDTH*.5+.16]:
			var cap:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.064;sphere.height=.128;sphere.radial_segments=12;sphere.rings=6
			cap.mesh=sphere;cap.position.z=z;cap.material_override=panel.material(pink);marker.add_child(cap)
	panel.box(self,Vector3(0,.14,-1.7),Vector3(13,.28,7.6),ink,true)
	for x in range(-6,7):panel.box(self,Vector3(x,.286,-1.7),Vector3(.009,.005,7.5),Color("485159"))
	for z in range(-5,3):panel.box(self,Vector3(0,.286,z),Vector3(12.9,.005,.009),Color("485159"))
	# Fixed footprints are retained as a reference; the body can leave them.
	for i in COUNT:
		panel.box(self,START+Vector3(i*LENGTH+LENGTH*.5,-.085,0),Vector3(LENGTH-.06,.009,WIDTH+.15),Color("596068"))
		handle_marker(self,START+Vector3(i*LENGTH,-.075,WIDTH*.5+.2),i+1)
	handle=Handle.new();handle.name="HingeHeight";handle.freeze=true;handle.gravity_scale=0
	handle.release_mode=XRToolsPickable.ReleaseMode.FROZEN;handle.collision_layer=(1<<2)|(1<<18);handle.collision_mask=0
	var col:=CollisionShape3D.new();var s:=SphereShape3D.new();s.radius=.085;col.shape=s;handle.add_child(col)
	var ball:=MeshInstance3D.new();var sm:=SphereMesh.new();sm.radius=.075;sm.height=.15;ball.mesh=sm;ball.material_override=panel.material(pink);handle.add_child(ball)
	add_child(handle);handle.position=HANDLE_HOME
	panel.box(self,HANDLE_HOME+Vector3(0,HANDLE_TRAVEL*.5,-.12),Vector3(.015,HANDLE_TRAVEL+.05,.015),ink)
	panel.text(self,"ROOF",HANDLE_HOME+Vector3(0,HANDLE_TRAVEL+.09,0),.00055,ink)
	panel.text(self,"FLOOR",HANDLE_HOME+Vector3(0,-.14,0),.00055,ink)
	readout=panel.text(self,"",Vector3(0,.55,3.73),.00082,Color("efe5d4"))
	preset("PASSAGE")

func handle_marker(parent:Node3D,at:Vector3,number:int) -> void:
	var label:Label3D=panel.text(parent,"%02d"%number,at,.0013,pink)
	label.rotation_degrees.x=-90

func block(parent:Node3D,at:Vector3,size:Vector3,colour:Color) -> void:
	original_meshes.append(panel.box(parent,at,size,colour))

func build_bay(parent:Node3D,index:int) -> void:
	block(parent,Vector3(LENGTH*.5,-.065,0),Vector3(LENGTH,.13,WIDTH),concrete)
	# A frame, sill, ceiling cassette and slender balustrade form an ordinary bay.
	for z in [-WIDTH*.5+.10,WIDTH*.5-.10]:
		block(parent,Vector3(.095,HEIGHT*.5,z),Vector3(.19,HEIGHT,.20),pale)
		block(parent,Vector3(.105,.11,z),Vector3(.25,.22,.26),concrete)
		block(parent,Vector3(LENGTH*.53,.84,z),Vector3(LENGTH-.22,.045,.035),ink)
		for x in [.35,.65,.95]:block(parent,Vector3(x,.44,z),Vector3(.028,.78,.028),ink)
	block(parent,Vector3(.10,HEIGHT-.10,0),Vector3(.20,.2,WIDTH),pale)
	block(parent,Vector3(LENGTH*.5,HEIGHT+.04,0),Vector3(LENGTH,.08,WIDTH+.06),concrete)
	block(parent,Vector3(LENGTH*.56,HEIGHT-.04,0),Vector3(.65,.018,.045),Color("e6ad7a"))
	block(parent,Vector3(LENGTH*.5,.008,.30),Vector3(LENGTH,.008,.035),pink)
	var label:Label3D=panel.text(parent,"%02d"%(index+1),Vector3(.11,1.75,WIDTH*.5+.012),.0012,ink)
	label.rotation_degrees.y=0

func joint_basis(index:int) -> Basis:
	var angle:=deg_to_rad(bend_degrees) if index>0 else 0.0
	return Basis(Vector3.BACK,angle).scaled_local(Vector3.ONE*(ratio if index>0 else 1.0))

func update_assembly() -> void:
	var p:=Vector3(0,pivot_height,0)
	for i in COUNT:
		var b:=joint_basis(i)
		var next:=Vector3(LENGTH,0,0) if i>0 else Vector3.ZERO
		var slip:=Vector3(0,separation*(1.0 if i%2==1 else -1.0),0) if i>0 else Vector3.ZERO
		joints[i].transform=Transform3D(b,next+p-b*p+slip)
		markers[i].position=p
	readout.text="8 BAYS  /  HINGE %.2f m  /  BEND %.0f deg\nEACH BAY x%.2f   SEPARATION %.2f m"%[pivot_height,bend_degrees,ratio,separation]

func set_pivot_height(value:float) -> void:
	pivot_height=clampf(value,0,HEIGHT)
	handle.position=HANDLE_HOME+Vector3(0,pivot_height/HEIGHT*HANDLE_TRAVEL,0)
	update_assembly()

func _process(_delta:float) -> void:
	var value:=clampf((handle.position.y-HANDLE_HOME.y)/HANDLE_TRAVEL,0,1)*HEIGHT
	if not is_equal_approx(value,pivot_height):pivot_height=value;update_assembly()
	if not handle.is_picked_up():handle.position=HANDLE_HOME+Vector3(0,pivot_height/HEIGHT*HANDLE_TRAVEL,0)

func read_controls() -> void:
	if syncing:return
	bend_degrees=lerpf(-18,28,panel.bend_dial.get_normalized_value())
	separation=lerpf(0,1.2,panel.gap_dial.get_normalized_value())
	ratio=lerpf(.88,1.08,panel.scale_dial.get_normalized_value())
	update_assembly()

func sync_controls() -> void:
	syncing=true
	panel.bend_dial.set_normalized_value((bend_degrees+18)/46)
	panel.gap_dial.set_normalized_value(separation/1.2)
	panel.scale_dial.set_normalized_value((ratio-.88)/.20)
	syncing=false

func preset(id:String) -> void:
	match id:
		"PASSAGE","RESET":bend_degrees=0;separation=0;ratio=1;set_pivot_height(0)
		"FOLD":bend_degrees=24;separation=0;ratio=1;set_pivot_height(0)
		"SLIP":bend_degrees=9;separation=.65;ratio=1;set_pivot_height(HEIGHT*.5)
	sync_controls();update_assembly()

func apply_grid_config(_config:Dictionary) -> void:
	pass
