extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## One sum in floor coordinates feeds both receivers. Inputs are metres, not forces.
const LIMIT := 1.0
const STEP := 0.5
const SPEED := 0.8
var a := Vector2(1, 0)
var b := Vector2(0, 1)
var result := Vector2.ZERO
var selected_a := true
var detour := true
var revealed := false
var running := false
var travelled := 0.0
var route: Array[Vector3] = []
var carriage: AnimatableBody3D
var diagram: Node3D
var floor_drawing: Node3D
var heading: Label3D
var numbers: Label3D
var status: Label3D
var cached_status := ""
var amber: Material
var coral: Material
var cyan: Material

func _ready() -> void:
	amber=material("ffc05d",true);coral=material("ff779b",true);cyan=material("65ecdc",true)
	var dark=material("152c37")
	box(Vector3(0,0.07,0),Vector3(5.4,0.14,5.4),dark,true)
	for i in range(-2,3):
		box(Vector3(i,0.148,0),Vector3(0.016,0.008,5),material("526f79"))
		box(Vector3(0,0.148,i),Vector3(5,0.008,0.016),material("526f79"))
	# The carriage is a demonstration inside a guarded stage, with walkways outside.
	var glass=material("97d5dc");glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glass.albedo_color.a=0.16
	for x in [-2.72,2.72]:
		box(Vector3(x,0.7,0),Vector3(0.06,1.4,5.5),glass,true)
		box(Vector3(x,1.4,0),Vector3(0.065,0.055,5.5),dark)
	box(Vector3(0,0.7,2.72),Vector3(5.5,1.4,0.06),glass,true)
	box(Vector3(0,1.4,2.72),Vector3(5.5,0.055,0.065),dark)
	box(Vector3(0,1.9,-3.15),Vector3(7,3.8,0.16),dark,true)
	box(Vector3(0,3.83,-3.15),Vector3(7.12,0.07,0.22),cyan)
	heading=label("TWO CONTRIBUTIONS / ONE DESTINATION",Vector3(0,3.42,-3.04),0.0035)
	label("FLOOR PLAN   /   +X right, +forward up",Vector3(-1.65,2.98,-3.04),0.0018)
	numbers=label("",Vector3(1.65,2.12,-3.03),0.0026)
	status=label("",Vector3(0,0.53,-3.03),0.0019)
	diagram=Node3D.new();diagram.name="WallVectors";add_child(diagram)
	floor_drawing=Node3D.new();floor_drawing.name="FloorVectors";add_child(floor_drawing)
	for i in range(-2,3):
		box(Vector3(-1.65+i*0.48,1.95,-3.045),Vector3(0.01,2.4,0.008),material("526f79"))
		box(Vector3(-1.65,1.95+i*0.48,-3.045),Vector3(2.4,0.01,0.008),material("526f79"))
	carriage=AnimatableBody3D.new();carriage.name="Carriage";add_child(carriage)
	# We move inside the physics callback ourselves; do not defer each waypoint write.
	carriage.sync_to_physics=false
	carriage.position=floor_point(Vector2.ZERO)
	box(Vector3.ZERO,Vector3(0.5,0.5,0.5),material("cee8e5"),false,carriage)
	box(Vector3(0,0.258,0),Vector3(0.42,0.02,0.42),cyan,false,carriage)
	var shape=CollisionShape3D.new();var cube=BoxShape3D.new();cube.size=Vector3.ONE*0.5;shape.shape=cube;carriage.add_child(shape)
	# Two reachable rows; both use the canonical pointer/near-hand push buttons.
	console(["A/B","X-","X+","F-","F+"],3.65,"Choose A or B, then change a component")
	var first_readout=readout
	# Side-mounted and tilted: a standing visitor must see over the controls.
	first_readout.position=Vector3(-3.1,1.2,3.8)
	first_readout.pixel_size=0.0011
	first_readout.rotation_degrees.x=-35
	for child in get_children():
		if child is MeshInstance3D and child.position.is_equal_approx(Vector3(0,1.52,3.48)):
			child.position=Vector3(-3.1,1.17,3.76)
			child.mesh.size=Vector3(2.5,0.5,0.055)
			child.rotation_degrees.x=-35
	box(Vector3(-3.1,0.52,3.75),Vector3(0.18,1.04,0.25),dark,true)
	add_button_row(["PATH","SWAP","CANCEL","GO","RULE"],4.22)
	readout=first_readout
	refresh()

func add_button_row(ids: Array, z: float) -> void:
	box(Vector3(0,0.94,z),Vector3(3.8,0.16,0.45),material("263a44"),true)
	for i in ids.size():
		var id: String=ids[i];var button=PUSH.instantiate()
		button.position=Vector3((i-2)*0.7,1.04,z);button.scale=Vector3.ONE*1.15
		add_child(button);buttons[id]=button;button.pressed.connect(act.bind(id))
		var caption=label(id,button.position+Vector3(0,0.06,0.16),0.00095);caption.rotation_degrees.x=-55

func floor_point(v: Vector2, height: float=0.43) -> Vector3:
	return Vector3(v.x,height,-v.y)

func wall_point(v: Vector2) -> Vector3:
	return Vector3(-1.65+v.x*0.48,1.95+v.y*0.48,-2.99)

func arrow(host: Node3D, start: Vector3, end: Vector3, mat: Material) -> void:
	var d=end-start
	if d.length()<0.0001:return
	var mesh=MeshInstance3D.new();var shaft=CylinderMesh.new()
	shaft.top_radius=0.025;shaft.bottom_radius=0.025;shaft.height=d.length();shaft.radial_segments=8
	mesh.mesh=shaft;mesh.material_override=mat;host.add_child(mesh);mesh.position=(start+end)*0.5
	mesh.quaternion=Quaternion(Vector3.UP,d.normalized())
	var tip=MeshInstance3D.new();var cone=CylinderMesh.new();cone.top_radius=0;cone.bottom_radius=0.075;cone.height=0.15;cone.radial_segments=8
	tip.mesh=cone;tip.material_override=mat;host.add_child(tip);tip.position=end-d.normalized()*0.075;tip.quaternion=mesh.quaternion

func refresh() -> void:
	result=a+b
	for host in [diagram,floor_drawing]:
		for child in host.get_children():host.remove_child(child);child.queue_free()
	arrow(diagram,wall_point(Vector2.ZERO),wall_point(a),amber)
	arrow(diagram,wall_point(a),wall_point(result),coral)
	arrow(diagram,wall_point(Vector2.ZERO)+Vector3(0,0,0.035),wall_point(result)+Vector3(0,0,0.035),cyan)
	arrow(floor_drawing,floor_point(Vector2.ZERO,0.19),floor_point(a,0.19),amber)
	arrow(floor_drawing,floor_point(a,0.19),floor_point(result,0.19),coral)
	arrow(floor_drawing,floor_point(Vector2.ZERO,0.22),floor_point(result,0.22),cyan)
	box(floor_point(result,0.17),Vector3(0.24,0.035,0.24),cyan,false,floor_drawing)
	readout.text="Editing %s  /  half-metre steps\nPATH: %s   |   GO starts at home" % ["A" if selected_a else "B","via A" if detour else "direct"]
	numbers.text=("A = (%.1f, %.1f) m\nB = (%.1f, %.1f) m\nA+B = (%.1f, %.1f) m\n\n|A|+|B| = %.2f m\n|A+B| = %.2f m\n\nresult = a + b" % [a.x,a.y,b.x,b.y,result.x,result.y,a.length()+b.length(),result.length()]) if revealed else "Amber A, then pink B.\nCyan marks the destination.\n\nSWAP their order.\nDoes anything stay?\n\nCANCEL, then GO.\nWhere did the journey go?\n\nRULE reveals the arithmetic."
	update_status()

func act(id: String) -> void:
	if id=="GO":
		carriage.position=floor_point(Vector2.ZERO);travelled=0
		route.clear()
		if detour:route.append(floor_point(a))
		route.append(floor_point(result));running=true;update_status();return
	if id=="RULE":revealed=not revealed;refresh();return
	if id=="A/B":selected_a=not selected_a;refresh();return
	running=false;route.clear();travelled=0;carriage.position=floor_point(Vector2.ZERO)
	match id:
		"PATH":detour=not detour
		"SWAP":var old=a;a=b;b=old
		"CANCEL":b=-a
		_:
			var v=a if selected_a else b
			match id:
				"X-":v.x-=STEP
				"X+":v.x+=STEP
				"F-":v.y-=STEP
				"F+":v.y+=STEP
			v=v.clamp(Vector2.ONE*-LIMIT,Vector2.ONE*LIMIT)
			if selected_a:a=v
			else:b=v
	refresh()

func _physics_process(delta: float) -> void:
	if running:
		var budget=SPEED*delta
		while not route.is_empty():
			var distance=carriage.position.distance_to(route[0])
			if distance>budget:
				carriage.position=carriage.position.move_toward(route[0],budget);travelled+=budget;break
			carriage.position=route.pop_front();travelled+=distance;budget-=distance
		if route.is_empty():running=false
	update_status()

func update_status() -> void:
	var text="%s / travelled %.2f m\nInputs limited to +/-1 m per component. One floor square = 1 m.\nPrescribed carriage speed: 0.8 m/s. GO homes instantly; edits reset the trip." % ["MOVING" if running else "READY",travelled]
	if text!=cached_status:status.text=text;cached_status=text
