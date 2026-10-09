extends Node3D
## A hand reads the explorer's current row. No second automaton or clock.
var work: Node3D
var point: XRToolsPickable

func _ready() -> void:
	name = "HandPoint"
	work = get_parent().work
	point = load("res://commons/artifacts/ca_rule_explorer/point_body.gd").new()
	point.name = "PointBody"
	add_child(point)
	park()
	point.action_pressed.connect(func(_body): work.step())
	var rail := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(work.board_size, 0.008, 0.008)
	rail.mesh = mesh
	rail.position = Vector3(0, 0.10, 1.45)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ffd77d")
	rail.material_override = material
	add_child(rail)
	var label := Label3D.new()
	label.text = "MOVE POINT: INSPECT     TRIGGER: STEP"
	label.font_size = 30
	label.pixel_size = 0.0015
	label.outline_size = 4
	label.position = Vector3(0, -0.08, 1.49)
	add_child(label)

func _physics_process(_delta: float) -> void:
	if point.held():
		var x: float = to_local(point.global_position).x
		work.sample_cell = clampi(int(floor((x / work.board_size + 0.5) * work.cells_x)), 0, work.cells_x - 1)
	else:
		park()

func park() -> void:
	var x: float = ((work.sample_cell + 0.5) / work.cells_x - 0.5) * work.board_size
	point.position = Vector3(x, 0.20, 1.45)
