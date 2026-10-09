extends Node3D
## One read-only spatial receiver of the explorer's actual stored rows.
## No random seed, second clock, rule evaluator, collision or synthetic history.
const PITCH := 0.18
var work: Node3D
var cells: MultiMesh
var rendered: Array[Array] = [] # chronological, oldest displayed row first
var caption: Label3D
var newest: MeshInstance3D
var _signature := ""

func build(source: Node3D) -> void:
	name = "ComparisonFloor"
	work = source
	# This opt-in placement belongs to the existing 180-degree CA comparison desk.
	# Museum floor: x 4.52..10.28, z 6.18..10.50; desk and pyramid stay clear.
	position = Vector3(-3.9, -1.03, -2.84)
	rotation.y = PI
	cells = MultiMesh.new()
	cells.transform_format = MultiMesh.TRANSFORM_3D
	cells.use_colors = true
	cells.instance_count = work.cells_x * work.rows_visible
	var tile := BoxMesh.new()
	tile.size = Vector3(PITCH * 0.95, 0.006, PITCH * 0.95)
	cells.mesh = tile
	var receiver := MultiMeshInstance3D.new()
	receiver.name = "StoredHistory"
	receiver.multimesh = cells
	receiver.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	receiver.material_override = mat
	add_child(receiver)
	var width: float = work.cells_x * PITCH
	var depth: float = work.rows_visible * PITCH
	for x in [-width / 2 - .025, width / 2 + .025]:
		bar(Vector3(.025, .006, depth + .07), Vector3(x, 0, 0), Color("928777"))
	for z in [-depth / 2 - .025, depth / 2 + .025]:
		bar(Vector3(width, .006, .025), Vector3(0, 0, z), Color("928777"))
	newest = bar(Vector3(width, .004, .012), Vector3.ZERO, Color("ffd77d"))
	newest.name = "NewestRow"
	caption = Label3D.new()
	caption.name = "HistoryCaption"
	caption.rotation_degrees = Vector3(-90, 180, 0)
	caption.position = Vector3(0, .009, -depth / 2 - .28)
	caption.font_size = 32
	caption.pixel_size = .0025
	caption.outline_size = 3
	caption.modulate = Color("eadcc1")
	add_child(caption)
	refresh()

func at(col: int, row: int) -> Vector3:
	return Vector3((col - work.cells_x / 2.0 + .5) * PITCH, 0,
		(row - work.rows_visible / 2.0 + .5) * PITCH)

func refresh() -> void:
	var signature := "%d:%d:%s" % [work.generation, work.rule, work.seed_pair]
	if signature == _signature: return
	_signature = signature
	rendered = work._grid.duplicate(true)
	rendered.reverse()
	for row in range(work.rows_visible):
		for col in range(work.cells_x):
			var present: bool = row < rendered.size()
			var state: bool = present and bool(rendered[row][col])
			var basis := Basis.IDENTITY if present else Basis.IDENTITY.scaled(Vector3.ZERO)
			cells.set_instance_transform(row * work.cells_x + col, Transform3D(basis, at(col, row)))
			cells.set_instance_color(row * work.cells_x + col, work.alive_color if state else work.dead_color)
	newest.position = at(0, rendered.size() - 1) + Vector3((work.cells_x - 1) * PITCH / 2, .008, PITCH / 2)
	caption.text = "SAME HISTORY  /  RULE %d  /  ROWS %d–%d  /  TIME ↑" % [work.rule, work.generation - rendered.size() + 1, work.generation]

func bar(size: Vector3, at_position: Vector3, colour: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.position = at_position
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	n.material_override = mat
	add_child(n)
	return n
