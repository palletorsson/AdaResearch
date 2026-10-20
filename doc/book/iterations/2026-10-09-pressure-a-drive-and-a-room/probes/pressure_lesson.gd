extends SceneTree
const OUT:="res://doc/book/iterations/2026-10-09-pressure-a-drive-and-a-room/"
var checks:Array=[]
var failures:Array=[]
var observations:Dictionary={}
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("PRESSURE ","PASS " if ok else "FAIL ",title)
func ticks(n:int=2)->void:
	for i in n:await physics_frame;await process_frame
func positions(body:SoftBody3D)->PackedVector3Array:
	var out:=PackedVector3Array()
	for i in body.rest_points.size():out.append(body.get_point_transform(i))
	return out
func difference(a:PackedVector3Array,b:PackedVector3Array)->float:
	var d:=0.0
	for i in a.size():d=maxf(d,a[i].distance_to(b[i]))
	return d
func free_difference(body:SoftBody3D,a:PackedVector3Array,b:PackedVector3Array)->float:
	var d:=0.0
	for i in a.size():
		if i not in body.pins:d=maxf(d,a[i].distance_to(b[i]))
	return d
func run()->void:
	check("Prepared project uses Jolt",ProjectSettings.get_setting("physics/3d/physics_engine")=="Jolt Physics")
	var host:=Node3D.new();host.position=Vector3(3,.2,-2);host.rotation.y=.6;root.add_child(host)
	var study=load(OUT+"printed/study.gd").new();host.add_child(study);study.set_physics_process(false);await ticks()
	check("Full program constructs two panels, caption and inherited pickable point",study.panels.size()==2 and study.caption!=null and study.point.has_method("pick_up"))
	var left:SoftBody3D=study.panels[0];var right:SoftBody3D=study.panels[1]
	var rest:PackedVector3Array=left.rest_points.duplicate();var mesh:int=left.mesh.get_instance_id();var body:int=left.get_instance_id();var ball:int=study.point.get_instance_id()
	var fresh=load(OUT+"printed/pressure_panel.gd").new()
	check("Closed box has six faces and nonzero thickness",fresh.mesh is BoxMesh and fresh.mesh.size.is_equal_approx(Vector3(.16,1.2,1.8)) and fresh.mesh.get_mesh_arrays()[Mesh.ARRAY_INDEX].size()>36)
	fresh.free()
	var exact_pins:=true;var count:=0
	for i in rest.size():
		var edge:=absf(absf(rest[i].y)-.6)<.001 or absf(absf(rest[i].z)-.9)<.001
		exact_pins=exact_pins and left.is_point_pinned(i)==edge
		if edge:count+=1
	check("Perimeter rule pins only selected edges and leaves free entries",exact_pins and count==left.pins.size() and count>0 and count<rest.size())
	var error:=0.0
	for i in left.pins:error=maxf(error,left.get_point_transform(i).distance_to(study.to_global(Vector3(-.8,1.3,0)+rest[i])))
	check("Pins respect the translated and rotated host",error<.001)
	check("Matching panels start with matching response settings",left.linear_stiffness==right.linear_stiffness and left.damping_coefficient==right.damping_coefficient and left.rest_points==right.rest_points)
	check("Pressure starts at half amplitude",is_equal_approx(left.pressure_coefficient,.25))
	study._physics_process(.5);check("Phase advances by rate times elapsed time",is_equal_approx(study.phase,.5))
	for ph in [0.0,PI*.5,PI*1.5]:
		study.phase=ph;study.apply_pressure()
		var expected:float=(sin(ph)+1.0)*.25
		check("Signal gives expected coefficient at phase "+str(ph),is_equal_approx(left.pressure_coefficient,expected) and is_equal_approx(right.pressure_coefficient,expected))
	study.phase=PI*.5;study.apply_pressure();var before:=positions(left);await ticks(25)
	check("Applied pressure reaches a deforming surface",difference(before,positions(left))>.001)
	study.act("HOLD DRIVE");var phase:float=study.phase;var pressure:float=study.pressure;var shape:=positions(left)
	study._physics_process(.8)
	check("Hold preserves phase and pressure without replacing the body",study.phase==phase and study.pressure==pressure and left.get_instance_id()==body and difference(shape,positions(left))<.000001)
	await ticks(30);var movement:=free_difference(left,shape,positions(left))
	check("Free vertices keep responding while the pressure is held",movement>.0005)
	var pin_drift:=0.0
	for i in left.pins:pin_drift=maxf(pin_drift,shape[i].distance_to(left.get_point_transform(i)))
	check("Fixed boundary remains fixed",pin_drift<.001)
	study.act("AMPLITUDE")
	check("Amplitude changes pressure at the held phase",is_equal_approx(study.pressure,.15) and study.phase==phase and study.rate==1.0)
	study.act("RATE");check("Rate can change without advancing the held phase",is_equal_approx(study.rate,.5) and study.phase==phase and is_equal_approx(study.pressure,.15))
	study.act("STIFFNESS");check("Stiffness changes on both bodies without changing the drive",is_equal_approx(left.linear_stiffness,.2) and is_equal_approx(right.linear_stiffness,.2) and study.phase==phase and is_equal_approx(study.pressure,.15))
	shape=positions(left);study.act("RESET PHASE")
	check("Reset phase sets half amplitude, retains shape and hold state",is_zero_approx(study.phase) and is_equal_approx(study.pressure,.075) and study.held and difference(shape,positions(left))<.000001)
	check("Control changes retain mesh, rest coordinates and body identity",left.mesh.get_instance_id()==mesh and left.rest_points==rest and left.get_instance_id()==body)
	var event:=InputEventKey.new();event.keycode=KEY_3;event.pressed=true;study._unhandled_key_input(event);study._physics_process(.5)
	check("Keyboard resumes the existing clock at its selected rate",not study.held and is_equal_approx(study.phase,.25))
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	var contact_before_grab:bool=left.collision_mask & study.point.collision_layer!=0
	study.point.pick_up(pickup);await ticks();check("Same black PointBody is grabbable",study.point.is_picked_up() and contact_before_grab)
	study.point.action();check("Held trigger holds the pressure clock",study.held)
	study.point.action();check("Held trigger resumes without replacing panels",not study.held and left.get_instance_id()==body)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);study._physics_process(0);await ticks()
	check("Release parks the same ball at the opening",study.point.position.is_equal_approx(Vector3(0,1.3,1.2)) and study.point.get_instance_id()==ball)
	var half=load(OUT+"variation/study.gd").new();half.position=Vector3(4,0,0);host.add_child(half);half.set_physics_process(false);await ticks()
	var values:Array=[]
	for ph in [0.0,PI*.5,PI*1.5]:half.phase=ph;half.apply_pressure();values.append(half.pressure)
	check("Full amplitude edit produces .125, .25 and zero",is_equal_approx(values[0],.125) and is_equal_approx(values[1],.25) and is_zero_approx(values[2]))
	check("Amplitude edit retains rate, geometry and material",half.rate==1.0 and half.panels[0].rest_points==rest and half.panels[0].linear_stiffness==.5)
	half.phase=0;half._physics_process(TAU);check("Edited host completes the same period",is_zero_approx(half.phase))
	# A paired experiment keeps gravity and all other settings equal.
	var control=load(OUT+"printed/study.gd").new();control.position=Vector3(8,0,0);host.add_child(control);control.set_physics_process(false)
	var driven=load(OUT+"printed/study.gd").new();driven.position=Vector3(12,0,0);host.add_child(driven);driven.set_physics_process(false)
	control.amplitude=0;control.apply_pressure();driven.phase=PI*.5;driven.apply_pressure();await ticks(80)
	var a:=positions(control.panels[0]);var b:=positions(driven.panels[0]);var relative:=0.0
	for i in rest.size():relative=maxf(relative,(a[i]-control.global_position).distance_to(b[i]-driven.global_position))
	check("Otherwise matching native panels differ when pressure differs",relative>.001)
	for fault in ["fault-delta","fault-hold","fault-offset"]:
		var bad=load(OUT+fault+"/study.gd").new();bad.position=Vector3(16,0,0);host.add_child(bad);bad.set_physics_process(false);await ticks();var rejected:=false
		match fault:
			"fault-delta":bad._physics_process(.5);rejected=absf(bad.phase-.5)>.01
			"fault-hold":bad.act("HOLD DRIVE");bad._physics_process(.5);rejected=absf(bad.phase)>.01
			"fault-offset":bad.phase=0;bad.apply_pressure();rejected=absf(bad.pressure-.25)>.01
		check("Behaviour rejects "+fault,rejected);bad.queue_free();await ticks()
	observations={"free_motion_while_held":movement,"pressure_comparison_difference":relative,"entries":rest.size(),"pins":count,"scope":"Exact printed programs in native Jolt; synthetic XRTools actions, no headset or independent student."}
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	host.queue_free();origin.queue_free();await ticks();quit(0 if failures.is_empty() else 1)
