extends "res://commons/artifacts/single_cube_turntable/single_cube_turntable.gd"
## Two hand-driven pulleys share one belt displacement: R*a = r*b.
## An ideal taut, open belt with no slip or simulated traction/tension. Geometry,
## wheel angles and travelling witness marks derive from the same input.
const BIG_RADIUS := 1.1
const SMALL_RADIUS := .55
const BIG_CENTRE := Vector3(-2,1.75,0)
const SMALL_CENTRE := Vector3(1.2,1.75,0)
const RATIO := BIG_RADIUS/SMALL_RADIUS
var secondary: Node3D
var belt_points: PackedVector3Array = []
var belt_distances: PackedFloat32Array = []
var belt_length := 0.0
var belt_marks: Array[Node3D] = []
var syncing := false

func _ready() -> void:
	super._ready()
	secondary.hinge_moved.connect(_on_small_turn)
	part_defaults.DiskAndCrank.bounds = [-3.22,0,-.5,5.12,3.05,1.5]
	set_meta("void_preview_kind","Real two-pulley 2:1 open belt, fixed-radius wheels and travelling witness marks. Static phase-zero editor model; ideal no-slip kinematics run in Godot.")

func build_disk() -> void:
	disk = Node3D.new();disk.name = "BeltAndBearings";drive.add_child(disk)
	for centre in [BIG_CENTRE,SMALL_CENTRE]:
		box(drive,Vector3(centre.x,.1,0),Vector3(.9,.2,.9),steel,true)
		box(drive,Vector3(centre.x,.9,-.3),Vector3(.18,1.6,.2),steel,true)
		rod(drive,centre+Vector3(0,0,-.42),centre+Vector3(0,0,.10),.12,ivory)
	box(drive,Vector3(-.4,.3,-.3),Vector3(4.2,.15,.18),steel,true)
	build_belt_path()
	var rubber := finish("10121a",0,.68);rubber.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh := MeshInstance3D.new();mesh.name = "ContinuousOpenBelt";mesh.mesh = belt_mesh();mesh.material_override = rubber;disk.add_child(mesh)
	for i in 8:
		var mark := box(disk,Vector3.ZERO,Vector3(.10,.055,.27),pink if i==0 else ivory)
		mark.name = "TravellingBeltWitness%02d"%i;belt_marks.append(mark)

func build_belt_path() -> void:
	# Exact external tangencies for unequal circles. Both runs are straight;
	# arcs wrap each pitch radius and meet the runs without a kink.
	var alpha := acos((BIG_RADIUS-SMALL_RADIUS)/(SMALL_CENTRE.x-BIG_CENTRE.x))
	var top_a := BIG_CENTRE+Vector3(cos(alpha),sin(alpha),0)*BIG_RADIUS
	var top_b := SMALL_CENTRE+Vector3(cos(alpha),sin(alpha),0)*SMALL_RADIUS
	var bottom_a := BIG_CENTRE+Vector3(cos(alpha),-sin(alpha),0)*BIG_RADIUS
	var bottom_b := SMALL_CENTRE+Vector3(cos(alpha),-sin(alpha),0)*SMALL_RADIUS
	for i in 12:belt_points.append(top_a.lerp(top_b,float(i)/12))
	for i in 64:
		var a := alpha-float(i)/64*2*alpha
		belt_points.append(SMALL_CENTRE+Vector3(cos(a),sin(a),0)*SMALL_RADIUS)
	for i in 12:belt_points.append(bottom_b.lerp(bottom_a,float(i)/12))
	for i in 80:
		var a := -alpha-float(i)/80*(TAU-2*alpha)
		belt_points.append(BIG_CENTRE+Vector3(cos(a),sin(a),0)*BIG_RADIUS)
	belt_points.append(top_a);belt_distances.append(0)
	for i in range(1,belt_points.size()):
		belt_length += belt_points[i-1].distance_to(belt_points[i]);belt_distances.append(belt_length)

func belt_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(belt_points.size()-1):
		var frames: Array = []
		for j in [i,i+1]:
			var index: int = j%(belt_points.size()-1)
			var tangent := (belt_points[(index+1)%(belt_points.size()-1)]-belt_points[posmod(index-1,belt_points.size()-1)]).normalized()
			var normal := Vector3(tangent.y,-tangent.x,0)*.0225
			var p := belt_points[j]
			frames.append([p+normal+Vector3(0,0,.12),p-normal+Vector3(0,0,.12),p-normal-Vector3(0,0,.12),p+normal-Vector3(0,0,.12)])
		for face in 4:
			var a: Vector3 = frames[0][face];var b: Vector3 = frames[1][face]
			var c: Vector3 = frames[1][(face+1)%4];var d: Vector3 = frames[0][(face+1)%4]
			for vertex in [a,b,c,a,c,d]:surface.add_vertex(vertex)
	surface.generate_normals();return surface.commit()

func build_crank() -> void:
	wheel = make_pulley("LargeInputWheel",BIG_CENTRE,BIG_RADIUS)
	secondary = make_pulley("SmallOutputWheel",SMALL_CENTRE,SMALL_RADIUS)

func make_pulley(id: String,centre: Vector3,radius: float) -> Node3D:
	var control: Node3D = HandWheel.new();control.name = id;control.assemble()
	control.position = centre;control.scale = Vector3.ONE*(radius/.5)
	var rotor: Node3D = control.get_node("HingeOrigin/InteractableHinge")
	var rim := MeshInstance3D.new();var t := TorusMesh.new()
	t.inner_radius = .435;t.outer_radius = .49;t.rings = 80;t.ring_segments = 12
	rim.mesh = t;rim.rotation.z = PI/2;rim.material_override = steel;rotor.add_child(rim)
	# A single pink spoke on each wheel makes a full turn countable.
	for i in 5:
		var a := i*TAU/5
		rod(rotor,Vector3.ZERO,Vector3(0,sin(a)*.46,-cos(a)*.46),.017,pink if i==0 else ivory)
	rod(rotor,Vector3(-.03,0,0),Vector3(.08,0,0),.07,steel)
	rod(rotor,Vector3(.02,0,-.48),Vector3(.32,0,-.48),.025,ivory)
	# World grip size stays comfortable on the large and small wheels.
	rod(rotor,Vector3(.24,0,-.48),Vector3(.34,0,-.48),.04/(radius/.5),pink)
	drive.add_child(control);return control

func build_controls() -> void:
	super.build_controls();controls.position.x = -.4
	console.title = "BELT / 2 : 1"
	for label in controls.find_children("*","Label3D",true,false):
		if label.text=="HAND / PLATE / CUBE":label.text = "TURN EITHER WHEEL"

func _on_turn(degrees: float) -> void:
	if syncing:return
	angle_degrees = degrees
	syncing = true
	if is_instance_valid(secondary):secondary.set_angle_degrees(degrees*RATIO)
	syncing = false
	# Path runs clockwise, so positive counterclockwise rotation travels backwards.
	var distance := -deg_to_rad(degrees)*BIG_RADIUS
	for i in belt_marks.size():
		var pose := belt_pose(distance+float(i)*belt_length/belt_marks.size())
		belt_marks[i].position = pose.origin;belt_marks[i].basis = pose.basis
	state_changed.emit({"large_angle":degrees,"small_angle":degrees*RATIO,"belt_travel":distance})

func _on_small_turn(degrees: float) -> void:
	if not syncing and is_instance_valid(wheel):wheel.set_angle_degrees(degrees/RATIO)

func belt_pose(distance: float) -> Transform3D:
	var along := fposmod(distance,belt_length)
	for i in range(1,belt_distances.size()):
		if along>belt_distances[i]:continue
		var weight := (along-belt_distances[i-1])/(belt_distances[i]-belt_distances[i-1])
		var p := belt_points[i-1].lerp(belt_points[i],weight)
		var direction := belt_points[i]-belt_points[i-1]
		return Transform3D(Basis(Vector3.BACK,atan2(direction.y,direction.x)),p)
	return Transform3D.IDENTITY

func hand_active() -> bool:
	return super.hand_active() or (is_instance_valid(secondary) and (is_instance_valid(secondary._pointer) or not secondary.hinge.grabbed_handles.is_empty()))

func _process(delta: float) -> void:
	if is_instance_valid(wheel):super._process(delta)

func _on_parameter(index: int,value: float) -> void:
	if index==1 and not is_instance_valid(wheel):return
	super._on_parameter(index,value)

func refresh_controls() -> void:
	if not is_instance_valid(console) or not console.is_node_ready():return
	if not is_instance_valid(wheel):
		console.set_reading("CONTROL PANEL / mechanism not included");return
	console.set_parameter(0,motor_rpm/rpm_limit);console.set_parameter(1,fposmod(angle_degrees,360)/360)
	console.set_action_selected(0,auto_run);console.set_action_selected(1,reverse)
	console.set_reading("LARGE %.1f / SMALL %.1f RPM\n1 TURN : 2 TURNS | %s"%[motor_rpm,motor_rpm*RATIO,"HAND" if hand_active() else ("AUTO" if auto_run else "STOP")])
