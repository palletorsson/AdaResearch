extends Node3D
## Small side instrument for the boundary and face encounters. No sample copies.
const Casing = preload("res://commons/ui/instrument_panel_case.gd")
var text_label: Label3D
var subject: Node3D
var is_puzzle: bool
var _refresh: float = 0.0

func _ready() -> void:
	subject = get_parent()
	is_puzzle = subject.has_method("toggle_discovery_face")
	var screen := MeshInstance3D.new()
	screen.name = "Screen"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.90,0.64)
	screen.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.025,0.035,0.055)
	screen.material_override = material
	add_child(screen)
	var housing := Casing.new()
	housing.name = "Casing"
	add_child(housing)
	housing.fit_rect(Vector2.ZERO,quad.size,Color(1,0.4,0.65))
	text_label = Label3D.new()
	text_label.name = "Readout"
	text_label.font_size = 28
	text_label.pixel_size = 0.001
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text_label.position = Vector3(-0.4,0.27,0.004)
	text_label.outline_size = 0
	add_child(text_label)
	var button: Node3D = preload("res://commons/interactables/push_button.tscn").instantiate()
	button.name = "FillButton"
	button.position = Vector3(0.20,-0.23,0.03)
	button.pressed.connect(_toggle_fill)
	add_child(button)
	var caption := Label3D.new()
	caption.text = "SHOW / HIDE FILL"
	caption.font_size = 21
	caption.pixel_size = 0.001
	caption.position = Vector3(0.20,-0.16,0.01)
	caption.outline_size = 0
	add_child(caption)
	if not is_puzzle:
		subject.get_node("NewOutlineButton").position = position + Vector3(-0.22,-0.23,0.03)
		var restart: Label3D = subject.get_node("NewOutlineLabel")
		restart.text = "NEW OUTLINE"
		restart.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		restart.position = position + Vector3(-0.22,-0.16,0.01)
		restart.font_size = 21
		restart.outline_size = 0
	update_readout()

func _process(delta: float) -> void:
	_refresh += delta
	if _refresh >= 0.1:
		_refresh = 0
		update_readout()

func _toggle_fill() -> void:
	if is_puzzle: subject.toggle_discovery_face()
	else: subject.toggle_fill_visibility()
	update_readout()

func update_readout() -> void:
	if is_puzzle:
		var fitted := 0
		for line in subject.snap_lines:
			if line.is_at_target(): fitted += 1
		var closed: bool = subject.is_completed
		var filled: bool = is_instance_valid(subject.discovery_face) and subject.discovery_face.visible
		text_label.text = "BOUNDARY / FACE\n\nEdges at targets: %d / 3\nBoundary: %s\nFill: %s\n%s" % [fitted,"closed" if closed else "open", "visible" if filled else "hidden", "Try the fill. Look from both sides." if closed else "Close the three edges first."]
	else:
		var path: Array = subject.current_path
		var first: int = int(path[0]) if not path.is_empty() else -1
		var triangles := 0
		for face in subject.completed_triangles: triangles += maxi(0,face.points.size()-2)
		text_label.text = "OUTLINE / TRIANGLE FAN\n\nPath entries: %d | First: %s\nFilled loops: %d | Triangles: %d\nGrid: %.2f m | Hold: %.1f s\n%s" % [path.size(),str(first+1) if first>=0 else "--", subject.completed_triangles.size(),triangles,subject.grid_size,subject.hold_place_seconds,"Recording while held" if subject._is_grabbed else "Released / sampling rests"]
		for i in subject.point_indicators.size():
			var point: Node3D = subject.point_indicators[i]
			var number: Label3D = point.get_node_or_null("CornerNumber")
			if number == null:
				number = Label3D.new()
				number.name = "CornerNumber"
				number.position.y = 0.075
				number.font_size = 28
				number.pixel_size = 0.001
				number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				point.add_child(number)
			number.text = ("START " if i == first else "") + str(i+1)
