extends Node3D
## Supplied display: geometry, individual materials, labels and replay input.
## It never requests a random value or changes the learner's generator.
var left: Array[MeshInstance3D] = []
var right: Array[MeshInstance3D] = []
var replay_button: Button

func _ready() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var title := Label.new()
	title.text = "A PATTERN THAT RETURNS"
	title.position = Vector2(48, 28)
	title.add_theme_font_size_override("font_size", 28)
	canvas.add_child(title)
	var hint := Label.new()
	hint.text = "Edit study.gd  /  one change at a time"
	hint.position = Vector2(48, 65)
	hint.modulate = Color(0.67, 0.75, 0.78)
	canvas.add_child(hint)
	replay_button = Button.new()
	replay_button.text = "REPLAY   [space]"
	replay_button.position = Vector2(523, 624)
	replay_button.size = Vector2(234, 48)
	replay_button.add_theme_font_size_override("font_size", 21)
	replay_button.pressed.connect(func(): get_parent().replay())
	canvas.add_child(replay_button)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		get_parent().replay()
		get_viewport().set_input_as_handled()

func build(side: int, paired: bool) -> void:
	# Construction runs once, from the learner's _ready(). Replay only colours.
	assert(left.is_empty(), "Build once in _ready; replay changes only colours.")
	left = _grid(side, -1.5 if paired else 0.0, "LEFT" if paired else "ONE COLOUR" if side == 1 else "ONE GRID")
	if paired:
		right = _grid(side, 1.5, "RIGHT")

func _grid(side: int, centre: float, caption: String) -> Array[MeshInstance3D]:
	var cubes: Array[MeshInstance3D] = []
	var board := MeshInstance3D.new()
	var backing := BoxMesh.new()
	backing.size = Vector3(2.4, 2.4, 0.08)
	board.mesh = backing
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.15, 0.17)
	board.material_override = dark
	board.position = Vector3(centre, 1.85, -0.23)
	add_child(board)
	for row in range(side):
		for col in range(side):
			var cube := MeshInstance3D.new()
			var box := BoxMesh.new()
			var edge := 1.8 / float(side)
			box.size = Vector3(edge * 0.88, edge * 0.88, 0.16)
			cube.mesh = box
			var material := StandardMaterial3D.new()
			material.albedo_color = Color.WHITE
			material.roughness = 0.8
			cube.material_override = material
			cube.position = Vector3(centre + (col - (side-1) * 0.5) * edge, 1.85 + (row - (side-1) * 0.5) * edge, 0)
			add_child(cube)
			cubes.append(cube)
	var label := Label3D.new()
	label.text = caption
	label.position = Vector3(centre, 0.42, 0)
	label.font_size = 28
	label.pixel_size = 0.003
	label.outline_size = 0
	add_child(label)
	return cubes
