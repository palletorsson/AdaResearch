extends Node3D

const PointBody = preload("point_body.gd")
const LIMIT := 2
const VIEW_SCALE := 0.09
const VIEW_CENTER := Vector3(0, 1.43, 0)
var current: Array[Vector3] = [Vector3.ZERO]
var edge := 9.0
var generation := 0
var drawing := Node3D.new()
var point := PointBody.new()
var readout := Label3D.new()
var selected := Vector3i(0, 0, 1)

func _ready() -> void:
	add_child(drawing)
	point.position = Vector3(0, 1.35, 0.56)
	add_child(point)
	point.action_pressed.connect(func(_body): advance())
	readout.position = Vector3(0, 2.05, 0)
	readout.font_size = 32
	readout.pixel_size = 0.001
	add_child(readout)
	redraw()

func keep_cell(offset: Vector3i) -> bool:
	var middles := int(offset.x == 0) + int(offset.y == 0) + int(offset.z == 0)
	return middles < 2

func replace_cells(centres: Array[Vector3], parent_edge: float) -> Array[Vector3]:
	var next: Array[Vector3] = []
	var child_edge := parent_edge / 3.0
	for centre in centres:
		for z in range(-1, 2):
			for y in range(-1, 2):
				for x in range(-1, 2):
					var offset := Vector3i(x, y, z)
					if keep_cell(offset):
						next.append(centre + Vector3(offset) * child_edge)
	return next

func advance() -> void:
	if generation == LIMIT:
		return
	current = replace_cells(current, edge)
	edge /= 3.0
	generation += 1
	redraw()

func retained_volume() -> float:
	return current.size() * edge * edge * edge

func redraw() -> void:
	for old in drawing.get_children():
		drawing.remove_child(old)
		old.queue_free()
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * edge * VIEW_SCALE
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.91, 0.89, 0.86, 0.32)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for centre in current:
		var cube := MeshInstance3D.new()
		cube.mesh = mesh
		cube.material_override = material
		cube.position = VIEW_CENTER + centre * VIEW_SCALE
		drawing.add_child(cube)
	update_readout()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		advance()

func _physics_process(_delta: float) -> void:
	if point.held():
		var p := (to_local(point.global_position) - VIEW_CENTER) / VIEW_SCALE
		selected = Vector3i(clampi(roundi(p.x / 3.0), -1, 1), clampi(roundi(p.y / 3.0), -1, 1), clampi(roundi(p.z / 3.0), -1, 1))
		update_readout()
	else:
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 1.35, 0.56))

func update_readout() -> void:
	readout.text = "%d cubes · %.0f m3 retained · cut %d / 2\nFirst-cell offset %s: %s" % [current.size(), retained_volume(), generation, selected, "KEEP" if keep_cell(selected) else "REMOVE"]
