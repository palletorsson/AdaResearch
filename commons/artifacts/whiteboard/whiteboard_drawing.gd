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
	for i in range(5):
		var pen = Pen.new()
		pen.name = "Eraser" if i == 4 else "BoardPen%d" % i
		pen.board = self
		pen.ink = [Color(0.13,0.10,0.18), Color(0.85,0.05,0.07), Color(0.03,0.5,0.15), Color(0.08,0.18,0.85), Color.WHITE][i]
		pen.resolution_mm = [0.0,10.0,40.0,80.0,0.0][i]
		pen.eraser = i == 4
		pen.freeze = true
		pen.release_mode = XRToolsPickable.ReleaseMode.FROZEN
		pen.collision_layer = 4
		pen.collision_mask = 0
		pen.position = Vector3((i - 2) * minf(0.30, board_width / 5.5), 0.50, 0.50)
		var collision := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.026
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
		var label := Label3D.new()
		label.text = "ERASE" if pen.eraser else ("NO GRID" if i == 0 else "%d mm" % pen.resolution_mm)
		label.font_size = 36
		label.pixel_size = 0.001
		label.position.y = 0.26
		label.outline_size = 8
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
