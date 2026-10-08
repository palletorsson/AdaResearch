extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Three readings of the earlier PointBody, together in one museum hall.
## Each station declares its own local frame in metres. No force law.
const POINT=preload("res://commons/artifacts/force_halls/lesson_point.gd")
const ARROW=preload("res://commons/artifacts/force_halls/vector_arrow.gd")
@export_enum("direction","addition","projection") var principle := "direction"
var points: Array = []
var starts: Array[Vector3] = []
var arrows: Array = []
var point_labels: Array[Label3D] = []
var result_body: MeshInstance3D
var output: Label3D
var result_label: Label3D
var origin := Vector3(0,1.12,0)
var unit_origin := Vector3(-1.35,1.12,0)
var a := Vector3.ZERO
var b := Vector3.ZERO
var result := Vector3.ZERO
var remainder := Vector3.ZERO
var last_positions: Array = []
var ink: StandardMaterial3D
var rose: StandardMaterial3D
var secondary: StandardMaterial3D

func annotation(words: String, at: Vector3, size := 0.0008) -> Label3D:
	var text=label(words,at,size)
	text.font_size=72; text.modulate=Color("17181b")
	text.outline_modulate=Color("f1eee7"); text.outline_size=2
	text.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	return text

func arrow(start: Vector3, end: Vector3, mat: Material, width := 0.014, tip := true) -> Node3D:
	var body=ARROW.new(); add_child(body); body.build(mat,width,tip); body.set_ends(start,end)
	return body

func _ready() -> void:
	set_meta("em_keep_scale",true)
	add_to_group("force_point_lesson")
	ink=material("16171b"); ink.roughness=0.14; ink.metallic=0.2
	rose=material("ba6d89"); secondary=material("5b747d")
	var pale=material("ece9e1"); var gray=material("888783")
	for n in range(-2,3):
		box(Vector3(n,0.012,0),Vector3(0.01,0.012,4),pale)
		box(Vector3(0,0.012,n),Vector3(4,0.012,0.01),pale)
	box(Vector3(0,0.46,0),Vector3(0.28,0.92,0.28),pale,true)
	var pin=MeshInstance3D.new(); var sm=SphereMesh.new()
	sm.radius=0.045; sm.height=0.09; pin.mesh=sm; pin.material_override=ink; pin.position=origin; add_child(pin)
	annotation("O",origin+Vector3(0,-0.16,-0.07))
	# A small local triad; the drawn axes do not limit where the ball can go.
	for axis in [Vector3.RIGHT,Vector3.UP,Vector3.BACK]:
		arrow(origin,origin+axis*0.45,gray,0.006)
		var name_axis="X" if axis==Vector3.RIGHT else "Y" if axis==Vector3.UP else "Z"
		annotation(name_axis,origin+axis*0.52,0.00055)
	make_point(Vector3(0.9,1.6,0.6))
	if principle=="addition":make_point(Vector3(-0.7,1.5,0.9))
	for i in range(5):arrows.append(arrow(origin,origin,ink))
	result_body=MeshInstance3D.new(); var dot=SphereMesh.new()
	dot.radius=0.065; dot.height=0.13; result_body.mesh=dot; result_body.material_override=rose; add_child(result_body)
	result_label=annotation("",origin)
	result_label.modulate=Color.WHITE; result_label.outline_modulate=Color("202126"); result_label.outline_size=5
	var titles={"direction":"01 / DIRECTION + LENGTH","addition":"02 / TWO MOVES, ONE ARRIVAL","projection":"03 / WHAT THE RAIL KEEPS"}
	# Low station names leave the moving annotations and the museum wall clear.
	annotation(titles[principle],Vector3(0,0.31,-1.8),0.00085)
	annotation("LOCAL X Y Z  /  METRES  /  GRAB + MOVE",Vector3(0,0.10,-1.8),0.0006)
	output=annotation("",Vector3(0,0.63,-0.9),0.0008)
	# One nearby reset; the hands control the mathematical example.
	box(Vector3(-0.7,0.43,-0.9),Vector3(0.2,0.86,0.2),pale,true)
	var reset=PUSH.instantiate(); reset.position=Vector3(-0.7,0.87,-0.9)
	reset.rotation.x=-PI/2; add_child(reset); buttons.RESET=reset; reset.pressed.connect(act.bind("RESET"))
	annotation("RESET",Vector3(-0.7,1.02,-0.9),0.0005)
	if principle=="projection":
		arrow(origin-Vector3.RIGHT*1.9,origin+Vector3.RIGHT*1.9,gray,0.007,false)
		for step in range(-3,4):
			var at=origin+Vector3.RIGHT*step*0.5
			arrow(at-Vector3.BACK*0.055,at+Vector3.BACK*0.055,gray,0.006,false)
			if step!=0:annotation("%+.1f" % (step*0.5),at+Vector3(0,-0.14,0),0.0005)
		annotation("X RAIL / 0.5 m TICKS",origin+Vector3(0,-0.38,0.25),0.00055)
	update_reading()

func make_point(at: Vector3) -> void:
	var point=POINT.new(); point.position=at; point.get_child(0).material_override=ink
	point.name="PointBody"+str(points.size()); add_child(point); points.append(point); starts.append(at)
	var reading=annotation("",at,0.001)
	reading.modulate=Color.WHITE; reading.outline_modulate=Color("202126"); reading.outline_size=5
	point_labels.append(reading)

func act(id: String) -> void:
	if id!="RESET":return
	for point in points:
		if point.is_picked_up() or point.has_meta("lesson_held"):return
	for i in points.size():
		points[i].position=starts[i]; points[i].force_update_transform(); points[i].reset_physics_interpolation()
	update_reading()

func _process(_delta: float) -> void:
	for i in points.size():
		if i>=last_positions.size() or not points[i].position.is_equal_approx(last_positions[i]):
			update_reading(); break

func tuple(v: Vector3) -> String:
	return "(%+.2f, %+.2f, %+.2f)" % [v.x,v.y,v.z]

func set_arrow(index: int, start: Vector3, end: Vector3, mat: Material) -> void:
	arrows[index].shaft.material_override=mat; arrows[index].head.material_override=mat
	arrows[index].set_ends(start,end)

func update_reading() -> void:
	last_positions.clear()
	for i in points.size():
		var at: Vector3=points[i].position; last_positions.append(at)
		var displacement=at-origin
		point_labels[i].position=at+Vector3(0,0.38,0)
		point_labels[i].text=("a" if i==0 else "b")+"  "+tuple(displacement)+" m\nlength %.2f m" % displacement.length()
	a=points[0].position-origin
	for item in arrows:item.visible=false
	set_arrow(0,origin,origin+a,ink)
	var result_at=origin
	result_body.visible=true
	match principle:
		"direction":
			result=a.normalized() if a.length()>0.0001 else Vector3.ZERO
			set_arrow(1,unit_origin,unit_origin+result,rose)
			result_at=unit_origin+result
			result_body.visible=not result.is_zero_approx()
			result_label.text="unit direction\n"+tuple(result) if result_body.visible else "zero displacement\ndirection undefined"
			output.text="a = point - origin\nlength %.2f m  /  unit display 1 m" % a.length()
		"addition":
			b=points[1].position-origin; result=a+b; result_at=origin+result
			set_arrow(1,origin,origin+b,secondary)
			set_arrow(2,origin+a,result_at,secondary)
			set_arrow(3,origin,result_at,rose)
			result_label.text="a + b\n"+tuple(result)+" m"
			output.text="end distance %.2f m\ntravelled a then b: %.2f m" % [result.length(),a.length()+b.length()]
		"projection":
			result=Vector3.RIGHT*a.dot(Vector3.RIGHT); remainder=a-result; result_at=origin+result
			set_arrow(1,origin,result_at,rose)
			set_arrow(2,result_at,origin+a,secondary)
			result_label.text="along X  %+.2f m" % result.x
			output.text="remainder "+tuple(remainder)+" m\nalong + remainder = a"
	result_body.position=result_at
	result_label.position=result_at+Vector3(0,-0.25,-0.12)
