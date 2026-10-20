extends Node3D
const Sample = preload("sample.gd")
const Faces = preload("faces.gd")
const PointBody = preload("point_body.gd")
const START := [Vector3(-1.5,1,0), Vector3(0,1,0), Vector3(1.5,1,0)]
var model := Sample.new()
var frame := Node3D.new()
var bodies: Array = []
var skin := MeshInstance3D.new()
var point := PointBody.new()
var caption := Label3D.new()
var show_sample := false
var moved := false

func _ready() -> void:
	add_child(frame)
	frame.position = Vector3(0,0.8,0)
	frame.scale = Vector3.ONE * 0.3
	for i in START.size():
		var body := MeshInstance3D.new()
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE * Sample.BODY_EDGE
		body.mesh = cube
		body.position = START[i]
		body.rotation = Vector3(0.15*i, 0.3*i, 0.2*i)
		frame.add_child(body)
		bodies.append(body)
	frame.add_child(skin)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("b58b64")
	skin.material_override = material
	add_child(caption)
	caption.position = Vector3(0,2.45,0)
	caption.font_size = 26
	caption.pixel_size = 0.002
	add_child(point)
	point.action_pressed.connect(func(_p): act("SAMPLE"))
	act("SAMPLE")
	act("VIEW")

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0,1.1,1.5))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_SPACE: act("SAMPLE")
		KEY_V: act("VIEW")
		KEY_M: act("MOVE")
		KEY_R: act("RESET")

func act(command: String) -> void:
	match command:
		"SAMPLE":
			model.capture(frame, bodies)
			skin.mesh = Faces.build(model.faces(), model.origin, model.cell_size)
			show_sample = true
		"VIEW": show_sample = not show_sample
		"MOVE":
			moved = not moved
			bodies[2].position = START[2] + Vector3.RIGHT * (0.5 if moved else 0.0)
		"RESET":
			moved = false
			for i in bodies.size(): bodies[i].position = START[i]
			act("SAMPLE")
			show_sample = false
	skin.visible = show_sample
	for body in bodies: body.visible = not show_sample
	caption.text = "WHAT DO THE CENTRES KEEP?\n%d cells | %d exposed faces | spacing %.1f\nSPACE / held action: sample | V: view | M: move one cube | R: reset\n%s" % [model.cells.size(), model.faces().size(), model.cell_size,
		"SAMPLE: last captured centres" if show_sample else "ORIGINALS: current three cubes"]
