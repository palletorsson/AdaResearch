extends Node3D
const Reflection = preload("reflection.gd")
const PointBody = preload("point_body.gd")
const FIELD := [[1,0,1,0,0], [0,1,0,1,0], [0,1,1,0,1],
	[1,0,1,0,0], [0,1,0,0,1]]
const EDGE := 0.16
var model := Reflection.new()
var cells: Array = [[], []]
var point := PointBody.new()
var caption := Label3D.new()
var finishes: Array = []

func _ready() -> void:
	model.hold(FIELD)
	for tint in [Color("25212a"), Color("f4f0e8"), Color("653647"), Color("f3a7c0")]:
		var material := StandardMaterial3D.new()
		material.albedo_color = tint
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		finishes.append(material)
	for side in 2:
		for y in FIELD.size():
			for x in FIELD.size():
				var cell := MeshInstance3D.new()
				var cube := BoxMesh.new()
				cube.size = Vector3(EDGE*0.9, EDGE*0.9, 0.04)
				cell.mesh = cube
				cell.position = Vector3((side*2-1)*0.55 + (x-2)*EDGE, 1.55 + (2-y)*EDGE, 0)
				add_child(cell)
				cells[side].append(cell)
	add_child(caption)
	caption.position = Vector3(0,2.2,0)
	caption.font_size = 26
	caption.pixel_size = 0.0018
	add_child(point)
	point.action_pressed.connect(func(_p): act("REFLECT"))
	refresh()

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0,1.1,1.2))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_SPACE: act("REFLECT")
		KEY_V: act("ORIGINAL")
		KEY_M: act("MARK")
		KEY_H: act("HOLD")
		KEY_R: act("RESET")

func act(command: String) -> void:
	match command:
		"REFLECT": model.reflect()
		"ORIGINAL": model.original()
		"MARK": model.result[2][4] = 1 - model.result[2][4]
		"HOLD": model.hold(model.result)
		"RESET": model.hold(FIELD)
	refresh()

func refresh() -> void:
	var fields := [model.held, model.result]
	var differences := 0
	for y in 5:
		for x in 5:
			if model.held[y][x] != model.result[y][x]: differences += 1
			for side in 2:
				var axis := 2 if x == 2 or y == 2 else 0
				cells[side][y*5+x].material_override = finishes[axis + fields[side][y][x]]
	caption.text = "HELD INPUT                         RESULT\nPink cross: centre row and column | %d changed cells\nAction / SPACE: reflect | V: original | M: mark right tip\nH: hold result | R: reset | include axes: %s" % [differences, Reflection.INCLUDE_AXES]
