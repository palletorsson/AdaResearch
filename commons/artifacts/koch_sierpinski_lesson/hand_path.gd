extends Node3D
## Read the existing Koch records by hand; a floor drawing receives the same point.
## The pointer selects the nearest span. Its reading is arc position, not hand travel.
const PointBody = preload("res://commons/artifacts/recursive_tree_lesson/fork_point.gd")
const MINI_SCALE := 1.5
const MINI_ORIGIN := Vector3(0, 1.17, 0.20)
const FLOOR_ORIGIN := Vector3(0, 0.018, -2.0)
var desk: Node3D
var source: Node3D
var model: Node3D
var grip: XRToolsPickable
var floor_mark: MeshInstance3D
var mini_path: MeshInstance3D
var floor_path: MeshInstance3D
var caption: Label3D
var points: Array[Vector3] = []
var cursor := Vector3.ZERO
var along := 0.0
var total := 0.0
var last_text := ""
var buttons: Dictionary = {}

func _ready() -> void:
	desk = get_parent(); source = desk.source
	model = Node3D.new(); model.position = Vector3(1.8, 0, 2.0); add_child(model)
	var pale = desk.material("eee9e1")
	desk.box(Vector3(0, 0.52, -0.2), Vector3(1.5, 1.04, 1.5), pale, true, model)
	mini_path = make_drawing(model, "d98cac")
	floor_path = make_drawing(self, "e6a7c0")
	# Floor ribbon is non-colliding and lies on the museum's existing support.
	floor_mark = MeshInstance3D.new()
	var ball := SphereMesh.new(); ball.radius = 0.085; ball.height = 0.17
	ball.radial_segments = 16; ball.rings = 8; floor_mark.mesh = ball
	floor_mark.material_override = desk.material("26212a")
	add_child(floor_mark)
	grip = PointBody.new(); grip.name = "PathPoint"; model.add_child(grip)
	grip.action_pressed.connect(func(_body): desk.act("NEXT"))
	for i in 3:
		var id: String = ["NEXT", "BACK", "RESET"][i]
		var button = desk.PUSH.instantiate(); button.position = Vector3((i - 1) * 0.4, 1.06, 0.43)
		buttons[id] = button
		model.add_child(button); button.pressed.connect(desk.act.bind(id))
		var text = desk.label(id, Vector3.ZERO, 0.00060); text.reparent(model, false)
		text.position = button.position + Vector3(0, 0.005, 0.09); text.rotation_degrees.x = -70
	caption = desk.label("", Vector3.ZERO, 0.00076); caption.reparent(model, false)
	caption.position = Vector3(0, 1.72, -0.4)
	desk.box(Vector3(0, 1.72, -0.43), Vector3(1.54, 0.36, 0.025), desk.material("28252c"), false, model)
	var prompt = desk.label("HOLD THE POINT · FOLLOW THE LINE\nTrigger: replace once · release: park on the line", Vector3.ZERO, 0.00060)
	prompt.reparent(model, false); prompt.position = Vector3(0, 0.85, 0.56)
	prompt.modulate = Color("28252c"); prompt.outline_size = 0
	rebuild()

func make_drawing(host: Node3D, colour: String) -> MeshInstance3D:
	var drawing := MeshInstance3D.new(); drawing.mesh = ImmediateMesh.new()
	var mat = desk.material(colour); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED; drawing.material_override = mat
	drawing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(drawing); return drawing

func flat(p: Vector3) -> Vector3:
	return Vector3(p.x, 0, -p.y)

func ribbon(drawing: MeshInstance3D, origin: Vector3, factor: float, width: float) -> void:
	var mesh := drawing.mesh as ImmediateMesh; mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size() - 1:
		var a := origin + flat(points[i]) * factor
		var b := origin + flat(points[i + 1]) * factor
		var side := (b - a).normalized().cross(Vector3.UP) * width * 0.5
		for p in [a-side,b-side,b+side,a-side,b+side,a+side]: mesh.surface_add_vertex(p)
	mesh.surface_end()

func rebuild() -> void:
	points.clear()
	var records: Array = source._lines_by_depth[source._current_depth]
	for segment in records: points.append(segment.start)
	points.append(records[-1].end)
	total = 0.0
	for i in points.size() - 1: total += points[i].distance_to(points[i + 1]) * 5.0
	cursor = points[0]; along = 0.0
	ribbon(mini_path, MINI_ORIGIN, MINI_SCALE, 0.007)
	ribbon(floor_path, FLOOR_ORIGIN, 5.0, 0.045)
	update_pointer()

func sample(query: Vector3) -> Dictionary:
	var best := INF; var prefix := 0.0
	var answer := {"point":points[0], "along":0.0}
	for i in points.size() - 1:
		var a := points[i]; var delta := points[i + 1] - a
		var t := clampf((query - a).dot(delta) / delta.length_squared(), 0.0, 1.0)
		var p := a + delta * t
		var distance := p.distance_squared_to(query)
		if distance < best:
			best = distance; answer = {"point":p, "along":prefix + t * delta.length() * 5.0}
		prefix += delta.length() * 5.0
	return answer

func _physics_process(_dt: float) -> void:
	if grip.held():
		var p := (model.to_local(grip.global_position) - MINI_ORIGIN) / MINI_SCALE
		var answer := sample(Vector3(p.x, -p.z, 0))
		cursor = answer.point; along = answer.along
	update_pointer()

func update_pointer() -> void:
	if not grip.held():
		grip.global_transform = model.global_transform * Transform3D(Basis.IDENTITY, MINI_ORIGIN + flat(cursor) * MINI_SCALE)
	floor_mark.position = FLOOR_ORIGIN + flat(cursor) * 5.0 + Vector3.UP * 0.085
	var gap := points[0].distance_to(points[-1]) * 5.0
	var text := "ENDS %.3f m · PATH %.3f m\nAT %.3f m ALONG · step %d / 4" % [gap, total, along, source._current_depth]
	if text != last_text: caption.text = text; last_text = text
