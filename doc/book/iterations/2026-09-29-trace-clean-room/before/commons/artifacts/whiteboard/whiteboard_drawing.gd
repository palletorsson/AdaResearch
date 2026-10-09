extends Node3D
## Reuses the drawing-paper canvas and pen asset with board-local coordinates.
const Paper = preload("res://commons/context/drawingboard/paper_draw_surface.gd")
const Pen = preload("res://commons/artifacts/whiteboard/whiteboard_pen.gd")
const PenModel = preload("res://commons/context/drawingboard/pen.tscn")
var board_width: float = 1.6
var board_height: float = 1.2
var canvas: MeshInstance3D
var pens: Array[XRToolsPickable] = []
var stroke_events: int = 0
var shelf_enabled := false

func _ready() -> void:
	# The existing canvas expects a sibling status label; keep its debug text off
	# the visitor's board. The tools themselves carry their color/grid labels.
	var status := Label3D.new()
	status.name = "Label3D"
	status.visible = false
	add_child(status)
	canvas = Paper.new()
	canvas.name = "WritingSurface"
	var quad := QuadMesh.new()
	quad.size = Vector2(board_width, board_height)
	canvas.mesh = quad
	canvas.position = Vector3(0, board_height * 0.5, 0.044)
	canvas.texture_size = Vector2i(1024, maxi(64, roundi(1024 * board_height / board_width)))
	add_child(canvas)
	# Dry marker ink must not diffuse/fade through the wet-paint simulation.
	canvas.get_node("WetPaintCanvas/SimulationPass").visible = false
	canvas.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var surface_material := canvas.material_override as StandardMaterial3D
	surface_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if shelf_enabled:
		_build_shelf()
	for i in range(5):
		var pen = Pen.new()
		pen.name = "Eraser" if i == 4 else "BoardPen%d" % i
		pen.board = self
		pen.ink = [Color(0.13,0.10,0.18), Color(0.85,0.05,0.07), Color(0.03,0.5,0.15), Color(0.08,0.18,0.85), Color.WHITE][i]
		pen.resolution_mm = [0.0,10.0,40.0,80.0,0.0][i]
		pen.eraser = i == 4
		pen.freeze = true
		pen.release_mode = XRToolsPickable.ReleaseMode.UNFROZEN if shelf_enabled else XRToolsPickable.ReleaseMode.FROZEN
		pen.collision_layer = 4
		pen.collision_mask = 1 | 4 if shelf_enabled else 0
		pen.return_enabled = shelf_enabled
		pen.mass = 0.08 if shelf_enabled else 1.0
		pen.continuous_cd = shelf_enabled
		var slot_x := (i - 2) * minf(0.34, board_width / 5.5)
		pen.position = Vector3(slot_x, -0.018, 0.22) if shelf_enabled else Vector3((i - 2) * minf(0.30, board_width / 5.5), 0.50, 0.50)
		var collision := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.041 if shelf_enabled else 0.026
		shape.height = 0.22
		collision.shape = shape
		collision.position.y = 0.1
		pen.add_child(collision)
		var writing_tip := Marker3D.new()
		writing_tip.name = "WritingTip"
		pen.add_child(writing_tip)
		if not pen.eraser:
			var model := PenModel.instantiate()
			# Remove the asset's lateral authoring offset; its nib points along +Y.
			model.position = Vector3(-0.00968,0.00054,-0.02409)
			var material := StandardMaterial3D.new()
			material.albedo_color = pen.ink
			material.roughness = 0.5
			model.get_node("pen/PenBody").material_override = material
			model.get_node("pen/tip").material_override = material
			pen.add_child(model)
			var nib: MeshInstance3D = model.get_node("pen/tip")
			var nib_bounds: AABB = (model.transform * nib.get_parent().transform * nib.transform) * nib.get_aabb()
			writing_tip.position = Vector3(nib_bounds.get_center().x, nib_bounds.end.y, nib_bounds.get_center().z)
		else:
			var eraser_shape := BoxShape3D.new()
			eraser_shape.size = Vector3(0.085,0.04,0.055)
			collision.shape = eraser_shape
			collision.position.y = 0.02
			var block := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.085,0.04,0.055)
			block.mesh = box
			block.position.y = 0.02
			var felt := StandardMaterial3D.new()
			felt.albedo_color = Color(0.16,0.18,0.21)
			block.material_override = felt
			pen.add_child(block)
		if shelf_enabled and not pen.eraser:
			_dress_handle(pen, i)
		var label := Label3D.new()
		label.text = "ERASE" if pen.eraser else ("NO GRID" if i == 0 else "%d mm" % pen.resolution_mm)
		label.font_size = 36
		label.pixel_size = 0.001
		label.outline_size = 8
		if shelf_enabled:
			label.font_size = 24
			label.position = Vector3(slot_x, -0.082, 0.374)
			add_child(label)
			_build_dock(slot_x, pen.ink, pen.eraser)
		else:
			label.position.y = 0.26
			pen.add_child(label)
		add_child(pen)
		pens.append(pen)

func sample_uv(world_tip: Vector3, grid_mm: float) -> Vector2:
	var p := to_local(world_tip)
	if absf(p.z - 0.044) > 0.035 or absf(p.x) > board_width * 0.5 or p.y < 0 or p.y > board_height:
		return Vector2(-1,-1)
	var xy := Vector2(p.x, p.y - board_height * 0.5)
	if grid_mm > 0:
		xy = xy.snapped(Vector2.ONE * grid_mm / 1000.0)
	return Vector2(clampf(xy.x / board_width + 0.5,0,1), clampf(0.5 - xy.y / board_height,0,1))

func paint(previous: Vector2, uv: Vector2, ink: Color, erase: bool) -> void:
	var radius: int = 22 if erase else 3
	# Board-space quantization already happened. Use a negligible UV snap here,
	# and pass Color explicitly: the old controller passed brush size in its slot.
	if previous.x < 0:
		canvas.draw_point(uv, ink, radius, 1000000)
	else:
		canvas.draw_line(previous, uv, ink, radius, 1000000)
	canvas.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	stroke_events += 1


func _finish(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.42
	return material


func _piece(parent: Node3D, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	part.material_override = material
	parent.add_child(part)
	return part


func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _piece(parent, mesh, at, material)


func _build_shelf() -> void:
	var shelf := StaticBody3D.new()
	shelf.name = "PenShelf"
	shelf.collision_layer = 1
	shelf.collision_mask = 0
	add_child(shelf)
	var size := Vector3(board_width + 0.1, 0.075, 0.36)
	var at := Vector3(0, -0.0625, 0.18)
	_box(shelf, at, size, _finish(Color(0.16, 0.08, 0.18)))
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = at
	shelf.add_child(collision)
	var brass := _finish(Color(0.76, 0.5, 0.22), 0.65)
	_box(shelf, Vector3(0, -0.021, 0.355), Vector3(size.x, 0.009, 0.015), brass)
	for x in [-board_width * 0.35, board_width * 0.35]:
		_box(shelf, Vector3(x, -0.16, 0.035), Vector3(0.035, 0.24, 0.055), brass)
		_box(shelf, Vector3(x, -0.11, 0.18), Vector3(0.035, 0.035, 0.29), brass)


func _build_dock(x: float, ink: Color, erase: bool) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = 0.027 if not erase else 0.045
	ring.outer_radius = 0.039 if not erase else 0.053
	ring.rings = 16
	ring.ring_segments = 8
	_piece(self, ring, Vector3(x, -0.018, 0.22), _finish(ink.lightened(0.15), 0.3))


func _dress_handle(pen: Node3D, index: int) -> void:
	# Same working nib, four tactile silhouettes; ornament stays below its tip.
	var body := Node3D.new()
	body.name = "SculpturalGrip"
	pen.add_child(body)
	var metal := _finish(Color(0.88, 0.65, 0.28), 0.55)
	var ink := _finish(pen.ink.lightened(0.10), 0.18)
	match index:
		0: # Pearl-ended drawing pen.
			for y in [0.035, 0.085, 0.135]:
				var pearl := SphereMesh.new()
				pearl.radius = 0.027 if y == 0.085 else 0.02
				pearl.height = pearl.radius * 2.0
				pearl.radial_segments = 16
				pearl.rings = 8
				_piece(body, pearl, Vector3(0, y, 0), ink)
		1: # A small tilted ribbon-loop around the barrel.
			var loop := TorusMesh.new()
			loop.inner_radius = 0.027
			loop.outer_radius = 0.035
			loop.rings = 24
			loop.ring_segments = 8
			var part := _piece(body, loop, Vector3(0, 0.105, 0), metal)
			part.rotation.z = PI / 2.0
			part.scale.y = 1.4
		2: # Three fins rising around the grip.
			for i in range(3):
				var fin := _box(body, Vector3(0, 0.055 + i * 0.04, 0), Vector3(0.065, 0.022, 0.028), ink)
				fin.rotation.y = i * TAU / 3.0
		3: # A stepped, square sleeve.
			for i in range(4):
				var width := 0.060 - i * 0.006
				var step := _box(body, Vector3(0, 0.038 + i * 0.031, 0), Vector3(width, 0.029, width), ink)
				step.rotation.y = PI / 4.0
