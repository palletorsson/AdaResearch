extends Node3D

const PointBody = preload("point_body.gd")
const WIDTH := 32
const ROWS := 24
const SPAN := 1.6
# Inputs:                  000    001   010    011   100   101    110   111
var answers: Array[bool] = [false, true, false, true, true, false, true, false]
var seeds: Array[int] = [16]
var current: Array[bool] = []
var history: Array[Array] = []
var generation := 0
var selected := 16
var point: XRToolsPickable
var tiles := MultiMesh.new()
var reading := Label3D.new()
var marks: Array[MeshInstance3D] = []

func _ready() -> void:
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): step())
	reset()
	park_point()

func reset() -> void:
	current = []
	current.resize(WIDTH)
	current.fill(false)
	for address in seeds:
		assert(address >= 0 and address < WIDTH)
		current[address] = true
	generation = 0
	history.clear()
	remember()
	redraw()

func answer(left: bool, self_cell: bool, right: bool) -> bool:
	var index := 4 * int(left) + 2 * int(self_cell) + int(right)
	return answers[index]

func evolve(old: Array[bool]) -> Array[bool]:
	var next: Array[bool] = []
	next.resize(old.size())
	for i in range(old.size() - 1, -1, -1):
		var left := old[posmod(i - 1, old.size())]
		var right := old[posmod(i + 1, old.size())]
		next[i] = answer(left, old[i], right)
	return next

func step() -> void:
	current = evolve(current)
	generation += 1
	remember()
	redraw()

func remember() -> void:
	history.push_front(current.duplicate())
	if history.size() > ROWS:
		history.pop_back()

func _physics_process(_delta: float) -> void:
	if point.held():
		var x := to_local(point.global_position).x
		selected = clampi(int(floor((x / SPAN + 0.5) * WIDTH)), 0, WIDTH - 1)
	else:
		park_point()
	show_reading()

func park_point() -> void:
	point.position = Vector3(cell_x(selected), 1.15, 0.90)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER:
		step()
		get_viewport().set_input_as_handled()

func cell_x(i: int) -> float:
	return ((i + 0.5) / WIDTH - 0.5) * SPAN

func make_display() -> void:
	tiles.transform_format = MultiMesh.TRANSFORM_3D
	tiles.use_colors = true
	tiles.instance_count = WIDTH * ROWS
	var cell := BoxMesh.new()
	cell.size = Vector3(SPAN / WIDTH * 0.94, 0.014, 1.2 / ROWS * 0.94)
	tiles.mesh = cell
	var board := MultiMeshInstance3D.new()
	board.multimesh = tiles
	var finish := StandardMaterial3D.new()
	finish.vertex_color_use_as_albedo = true
	finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	board.material_override = finish
	add_child(board)
	for row in range(ROWS):
		for col in range(WIDTH):
			var at := Vector3(cell_x(col), 0.95, -0.6 + (row + 0.5) * 1.2 / ROWS)
			tiles.set_instance_transform(row * WIDTH + col, Transform3D(Basis.IDENTITY, at))
	reading.position = Vector3(0, 1.42, -0.66)
	reading.font_size = 30
	reading.pixel_size = 0.0017
	reading.outline_size = 4
	add_child(reading)
	for j in range(3):
		var mark := MeshInstance3D.new()
		var edge := BoxMesh.new()
		edge.size = Vector3(SPAN / WIDTH * 0.94, 0.006, 0.006)
		mark.mesh = edge
		var ink := StandardMaterial3D.new()
		ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ink.albedo_color = Color("ff80b4") if j == 1 else Color("ffd77d")
		mark.material_override = ink
		add_child(mark)
		marks.append(mark)

func redraw() -> void:
	tiles.visible_instance_count = history.size() * WIDTH
	for row in range(history.size()):
		for col in range(WIDTH):
			var ink := Color("87dca5") if history[row][col] else Color("243238")
			tiles.set_instance_color(row * WIDTH + col, ink)
	show_reading()

func show_reading() -> void:
	var left := posmod(selected - 1, WIDTH)
	var right := posmod(selected + 1, WIDTH)
	reading.text = "GEN %d / CELL %d\nLEFT %d   SELF %d   RIGHT %d\nMove point: inspect / trigger or Enter: STEP" % [generation, selected, int(current[left]), int(current[selected]), int(current[right])]
	for j in range(3):
		marks[j].position = Vector3(cell_x(posmod(selected + j - 1, WIDTH)), 0.963, -0.597)
