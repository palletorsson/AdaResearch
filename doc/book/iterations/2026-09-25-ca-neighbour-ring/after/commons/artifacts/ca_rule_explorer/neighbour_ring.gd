extends Node3D
## The explorer's stored rows wrapped around the visitor; never a second automaton.
const RADIUS := 1.65
const CURRENT_Y := 2.02
const ROW_PITCH := 0.095
var work: Node3D
var cells: MultiMesh
var witness: Array[MeshInstance3D] = []
var rendered: Array[Array] = []
var _signature := ""

func build(source: Node3D) -> void:
	name = "NeighbourRing"
	work = source
	# CA_Introduction: beside the board, above the clear right-hand corridor.
	position = Vector3(1.6, -1.04, 0.5)
	cells = MultiMesh.new()
	cells.transform_format = MultiMesh.TRANSFORM_3D
	cells.use_colors = true
	cells.instance_count = work.cells_x * work.rows_visible
	var tile := BoxMesh.new()
	tile.size = Vector3(2 * RADIUS * sin(PI / work.cells_x) * .95, ROW_PITCH * .87, .035)
	cells.mesh = tile
	var view := MultiMeshInstance3D.new()
	view.name = "StoredRows"
	view.multimesh = cells
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	view.material_override = material
	add_child(view)
	# Numbering locates the seam in the straight board, not a break in the ring.
	for col in range(work.cells_x):
		var label := Label3D.new()
		label.text = str(col)
		label.font_size = 30
		label.pixel_size = .0018
		label.modulate = Color("ffd77d") if col in [0, work.cells_x - 1] else Color("b5c3bd")
		label.position = at(col, -2, RADIUS - .04)
		label.rotation.y = angle(col) + PI
		label.outline_size = 2
		label.double_sided = false
		add_child(label)
	for j in range(3):
		var mark := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(tile.size.x, .028, .028)
		mark.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color("ff80b4") if j == 1 else Color("ffd77d")
		mark.material_override = mat
		add_child(mark)
		witness.append(mark)
	# The support stays still. No shifting floor or generated collision.
	var outline := ImmediateMesh.new()
	var frame := MeshInstance3D.new()
	frame.mesh = outline
	var rim := StandardMaterial3D.new()
	rim.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rim.albedo_color = Color("626d68")
	outline.surface_begin(Mesh.PRIMITIVE_LINES, rim)
	for row in [-.6, work.rows_visible - .4]:
		for col in range(work.cells_x):
			outline.surface_add_vertex(at(col, row, RADIUS + .03))
			outline.surface_add_vertex(at(col + 1, row, RADIUS + .03))
	for col in [0, 8, 16, 24]:
		outline.surface_add_vertex(at(col, -.6, RADIUS + .03))
		outline.surface_add_vertex(at(col, work.rows_visible - .4, RADIUS + .03))
	outline.surface_end()
	add_child(frame)
	refresh()

func angle(col: int) -> float:
	return TAU * float(col) / work.cells_x

func at(col: int, row: float, radius: float = RADIUS) -> Vector3:
	var a := angle(col)
	return Vector3(sin(a) * radius, CURRENT_Y + row * ROW_PITCH, cos(a) * radius)

func refresh() -> void:
	# Only this readout changes: all rule evaluation and stored history belong to work.
	var signature := str(work.generation) + ":" + str(work.rule) + ":" + str(work.seed_pair)
	if signature != _signature:
		rendered = work._grid.duplicate(true)
		for row in range(work.rows_visible):
			for col in range(work.cells_x):
				var present: bool = row < rendered.size()
				var state: bool = present and bool(rendered[row][col])
				var basis := Basis(Vector3.UP, angle(col))
				if not present: basis = basis.scaled(Vector3.ZERO)
				cells.set_instance_transform(row * work.cells_x + col, Transform3D(basis, at(col, row)))
				cells.set_instance_color(row * work.cells_x + col, work.alive_color if state else work.dead_color)
		_signature = signature
	for j in range(3):
		var col: int = posmod(work.sample_cell + j - 1, work.cells_x)
		witness[j].position = at(col, -.7, RADIUS - .04)
		witness[j].rotation.y = angle(col)
