extends Node3D
const PointBody = preload("point_body.gd")
const LIMIT := 10
const DISPLAY_SCALE := 0.2
var values: Array[int] = [1, 1]
var points: Array[XRToolsPickable] = []
var names: Array[Label3D] = []
var drawing: Node3D
var readout: Label3D
var latched := false

func _ready() -> void:
	drawing = Node3D.new()
	add_child(drawing)
	for i in 2:
		var point = PointBody.new()
		point.tint = Color("76d9d1") if i == 0 else Color("ffa366")
		add_child(point)
		point.position = home(i)
		point.action_pressed.connect(request_step)
		points.append(point)
		names.append(label("", home(i) + Vector3.UP * 0.18, self))
		names[i].pixel_size = 0.0012
	readout = label("", Vector3(0, 1.82, -0.08), self)
	readout.pixel_size = 0.0012
	redraw()

func home(i: int) -> Vector3:
	return Vector3(-0.32 + i * 0.64, 1.25, 0.46)

func any_held() -> bool:
	return points[0].held() or points[1].held()

func _physics_process(_dt: float) -> void:
	for i in 2:
		if not points[i].held():
			points[i].global_transform = global_transform * Transform3D(Basis.IDENTITY, home(i))
		names[i].global_position = points[i].global_position + global_basis.y * 0.18
	if not any_held():
		latched = false
		show_pair()
	elif not latched and points[0].position.distance_to(points[1].position) < 0.19:
		request_step()

func _process(_dt: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		request_step()

func request_step(_body = null) -> void:
	if latched:
		return
	latched = any_held()
	advance()

func advance() -> void:
	if values.size() >= LIMIT:
		readout.text = "Ten terms. Keep this record; run again to reset."
		return
	var a := values[-2]
	var b := values[-1]
	values.append(a + b)
	redraw()
	names[0].text = str(a)
	names[1].text = str(b)
	readout.text = "%d + %d = %d\nRelease both points for the next pair." % [a, b, a + b]

func height_for(value: int, linear: bool) -> float:
	if linear:
		return 0.05 * value
	return 0.5 * log(float(value)) + 0.5

func redraw() -> void:
	for child in drawing.get_children():
		drawing.remove_child(child)
		child.queue_free()
	for row in 2:
		var center_x := -0.64 if row == 0 else 0.64
		var linear := row == 0
		for i in values.size():
			var height := height_for(values[i], linear) * DISPLAY_SCALE
			var bar := MeshInstance3D.new()
			var shape := BoxMesh.new()
			shape.size = Vector3(0.075, height, 0.075)
			bar.mesh = shape
			bar.position = Vector3(center_x + (i - 4.5) * 0.10, 1.02 + height * 0.5, 0)
			var finish := StandardMaterial3D.new()
			finish.albedo_color = Color("76d9d1") if i == values.size() - 2 else Color("ffa366") if i == values.size() - 1 else Color("b3c0e6")
			bar.material_override = finish
			drawing.add_child(bar)
			label(str(values[i]), bar.position + Vector3(0, height * 0.5 + 0.05, 0), drawing)
		var heading := label("LINEAR" if linear else "LOGARITHMIC", Vector3(center_x, 1.67, 0), drawing)
		heading.pixel_size = 0.0011
	show_pair()

func show_pair() -> void:
	names[0].text = str(values[-2])
	names[1].text = str(values[-1])
	readout.text = "Same values / two height rules\n%d terms · bring the last pair together" % values.size()
	if values.size() == LIMIT:
		readout.text = "Ten terms · same record in both views\nRun again to reset."

func label(text: String, at: Vector3, host: Node3D) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.position = at
	tag.font_size = 32
	tag.pixel_size = 0.00065
	tag.outline_size = 7
	host.add_child(tag)
	return tag
