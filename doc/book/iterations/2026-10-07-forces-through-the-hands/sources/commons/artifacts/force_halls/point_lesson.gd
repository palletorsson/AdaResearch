extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Three vector readings of the same PointBody used in the earlier halls.
## These are geometric relations, not simulated forces.
const POINT=preload("res://commons/artifacts/force_halls/lesson_point.gd")
@export_enum("direction","addition","projection") var principle := "direction"
var points: Array = []
var starts: Array[Vector3] = []
var strokes: MeshInstance3D
var result_body: MeshInstance3D
var output: Label3D
var unit_visible := false
var origin := Vector3(0,1.2,0)
var a := Vector3.ZERO
var b := Vector3.ZERO
var result := Vector3.ZERO
var remainder := Vector3.ZERO
var last_positions: Array = []
var ink: StandardMaterial3D
var rose: StandardMaterial3D

func _ready() -> void:
	set_meta("em_keep_scale",true)
	add_to_group("force_point_lesson")
	ink=material("16171b");ink.roughness=0.14;ink.metallic=0.2
	rose=material("ba6d89")
	var pale=material("ece9e1")
	# An open diagram: hand movement remains possible beyond its drawn grid.
	for n in range(-3,4):
		box(Vector3(n,0.012,0),Vector3(0.016,0.012,6),pale)
		box(Vector3(0,0.012,n),Vector3(6,0.012,0.016),pale)
	box(Vector3(0,0.53,0),Vector3(0.42,1.06,0.42),pale,true)
	var pin=MeshInstance3D.new();var sm=SphereMesh.new();sm.radius=0.07;sm.height=0.14;pin.mesh=sm;pin.material_override=rose;pin.position=origin;add_child(pin)
	make_point(Vector3(1.8,1.55,0.8))
	if principle=="addition":make_point(Vector3(-0.9,1.8,1.4))
	strokes=MeshInstance3D.new();strokes.material_override=ink;add_child(strokes)
	result_body=MeshInstance3D.new();var dot=SphereMesh.new();dot.radius=0.105;dot.height=0.21;result_body.mesh=dot;result_body.material_override=rose;add_child(result_body)
	box(Vector3(0,0.65,-3.4),Vector3(4.8,1.3,0.12),pale,true)
	output=label("",Vector3(0,1.05,-3.49),0.0013);output.font_size=80;output.modulate=Color("25262a");output.rotation.y=PI
	var hint=label({"direction":"HOLD THE POINT / CHANGE THE DISPLACEMENT","addition":"TWO DISPLACEMENTS / ONE ARRIVAL","projection":"THE PART ALONG THE RAIL / THE PART LEFT OVER"}[principle],Vector3(0,1.65,-3.45),0.00125)
	hint.font_size=82;hint.rotation.y=PI;hint.modulate=Color("25262a")
	hint.outline_size=0;output.outline_size=0
	for i in range(2 if principle=="direction" else 1):
		var id="RESET" if i==0 else "UNIT"
		var button=PUSH.instantiate();button.position=Vector3(-2+i*4,0.85,-3.65);add_child(button);buttons[id]=button;button.pressed.connect(act.bind(id))
		var caption=label(id,button.position+Vector3(0,0.25,-0.05),0.001);caption.rotation.y=PI;caption.modulate=Color("25262a")
	update_reading()

func make_point(at: Vector3) -> void:
	var point=POINT.new();point.position=at;point.get_child(0).material_override=ink;point.name="PointBody"+str(points.size());add_child(point);points.append(point);starts.append(at)

func act(id: String) -> void:
	if id=="UNIT":unit_visible=not unit_visible
	if id=="RESET":
		for point in points:
			if point.is_picked_up() or point.has_meta("lesson_held"):return
		for i in points.size():
			points[i].position=starts[i]
			points[i].force_update_transform()
			points[i].reset_physics_interpolation()
	update_reading()

func _process(_delta: float) -> void:
	for i in points.size():
		if i>=last_positions.size() or not points[i].position.is_equal_approx(last_positions[i]):
			update_reading();break

func update_reading() -> void:
	last_positions.clear()
	for point in points:last_positions.append(point.position)
	a=points[0].position-origin
	var segments: Array = [[origin,points[0].position]]
	match principle:
		"direction":
			result=a.normalized() if a.length()>0.001 else Vector3.ZERO
			result_body.visible=unit_visible
			output.text="displacement  (%.2f, %.2f, %.2f) m\nlength  %.2f m   /   direction shown separately" % [a.x,a.y,a.z,a.length()]
			if unit_visible:segments.append([origin,origin+result])
		"addition":
			b=points[1].position-origin;result=a+b
			segments.append([origin,origin+b]);segments.append([origin+a,origin+result]);segments.append([origin,origin+result])
			output.text="a + b = (%.2f, %.2f, %.2f) m\nChange either point. The rose point marks the sum." % [result.x,result.y,result.z]
		"projection":
			result=Vector3.RIGHT*a.dot(Vector3.RIGHT);remainder=a-result
			segments.append([origin-Vector3.RIGHT*3,origin+Vector3.RIGHT*3]);segments.append([origin+result,origin+a])
			output.text="along rail  %.2f m   /   remainder  %.2f m\nprojection + remainder = original displacement" % [result.x,remainder.length()]
	result_body.position=origin+result
	var mesh=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for pair in segments:mesh.surface_add_vertex(pair[0]);mesh.surface_add_vertex(pair[1])
	mesh.surface_end();strokes.mesh=mesh
