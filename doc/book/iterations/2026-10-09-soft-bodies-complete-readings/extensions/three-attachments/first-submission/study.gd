extends Node3D

const Sheet = preload("hanging_sheet.gd")
const Point = preload("point_body.gd")
const THREE := [Vector3(-0.6, 0.7, 0), Vector3(-0.6, -0.7, 0), Vector3(0.6, 0, 0)]
const PARK := Vector3(0, 1.05, 0.7)
var bodies: Array[SoftBody3D] = []
var point = Point.new()
var displays := Node3D.new()
var caption := Label3D.new()

func _ready() -> void:
	add_child(displays)
	point.position = PARK
	add_child(point)
	point.action_pressed.connect(func(_source): rebuild())
	caption.text = "TWO CORNERS  /  THREE PLACES\nSame sheet. Different attachments.\nGold marks held points. Trigger / R: rebuild."
	caption.position = Vector3(0, 2.75, 0)
	caption.font_size = 40
	caption.pixel_size = 0.0018
	caption.modulate = Color("25212a")
	add_child(caption)
	rebuild()

func nearest(points: PackedVector3Array, target: Vector3) -> int:
	var selected := 0
	for i in range(1, points.size()):
		if points[i].distance_squared_to(target) < points[selected].distance_squared_to(target):
			selected = i
	return selected

func three_places(sheet: SoftBody3D) -> void:
	var selected: Array[int] = []
	for target in THREE:
		var i := nearest(sheet.rest_points, target)
		assert(i not in selected)
		selected.append(i)
	sheet.pins.clear()
	for i in sheet.rest_points.size():
		var keep: bool = i in selected
		sheet.set_point_pinned(i, keep)
		if keep:
			sheet.pins.append(i)

func rebuild() -> void:
	for body in bodies:
		remove_child(body)
		body.queue_free()
	bodies.clear()
	for child in displays.get_children():
		displays.remove_child(child)
		child.queue_free()
	for side in 2:
		var sheet := Sheet.new()
		if side == 0:
			sheet.set_pins(1)
		else:
			three_places(sheet)
		sheet.position = Vector3(-0.85 if side == 0 else 0.85, 1.55, 0)
		add_child(sheet)
		bodies.append(sheet)
		for i in sheet.pins:
			var marker := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.03
			sphere.height = 0.06
			marker.mesh = sphere
			var gold := StandardMaterial3D.new()
			gold.albedo_color = Color("d7ad67")
			gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			marker.material_override = gold
			marker.position = sheet.position + sheet.rest_points[i] + Vector3(0, 0, 0.01)
			displays.add_child(marker)

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, PARK)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		rebuild()
