extends Node3D
## Opt-in museum mount. Transform the existing canvas, trails and arrows together;
## keep their local sampling coordinates and the simulation unchanged.

func build(painter: Node3D, lesson: Node3D, button_labels: Array[Label3D]) -> Node3D:
	var screen := Node3D.new()
	screen.name = "Screen"
	screen.position = Vector3(0, 2.2, -0.05)
	screen.rotation_degrees.x = 90.0
	screen.scale = Vector3.ONE * 8.0
	add_child(screen)
	for visual in [painter._canvas_mesh, painter.get_node("Frame"), painter._trail_mesh, lesson.arrows]:
		visual.reparent(screen, false)
	# The canvas is a dark, constant receiver rather than a lit tabletop.
	var canvas_ink: StandardMaterial3D = painter._canvas_mesh.material_override
	canvas_ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	canvas_ink.albedo_color = Color("090e18")
	var graphite := StandardMaterial3D.new()
	graphite.albedo_color = Color("20252c")
	graphite.roughness = 0.72
	_box(self, "MonitorCase", Vector3(4.96, 3.36, 0.12), Vector3(0, 2.2, -0.13), graphite)
	_box(self, "StatusRail", Vector3(4.96, 0.15, 0.12), Vector3(0, 3.955, -0.13), graphite)
	lesson.status.position = Vector3(0, 3.955, 0.005)
	lesson.status.pixel_size = 0.0018
	lesson.status.font_size = 26

	var console := Node3D.new()
	console.name = "ControlsConsole"
	console.position = Vector3(0, 1.1, 1.25)
	add_child(console)
	painter._control_panel.reparent(console, false)
	painter._control_panel.position = Vector3(0, 0.035, -0.02)
	painter._control_panel.rotation_degrees.x = -65.0
	painter._control_panel.scale = Vector3.ONE * 2.5
	for i in 2:
		var id: String = ["ARROWS", "FIELD TIME"][i]
		var button: Node3D = lesson.buttons[id]
		button.reparent(console, false)
		button.position = Vector3(-0.35 + i * 0.7, 0.015, 0.37)
		button.rotation_degrees = Vector3.ZERO
		button.scale = Vector3.ONE * 0.875
		var label := button_labels[i]
		label.reparent(console, false)
		label.position = button.position + Vector3(0, 0.09, 0.10)
		label.pixel_size = 0.0013
		label.rotation_degrees.x = -45.0
	var porcelain := StandardMaterial3D.new()
	porcelain.albedo_color = Color("e1ded5")
	porcelain.roughness = 0.85
	_box(console, "ConsoleTop", Vector3(1.2, 0.10, 0.94), Vector3(0, -0.11, 0.15), porcelain)
	_box(console, "ConsoleStem", Vector3(0.32, 0.94, 0.36), Vector3(0, -0.63, 0.12), porcelain)
	var body := StaticBody3D.new()
	body.name = "ConsoleBody"
	console.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.2, 1.04, 0.94)
	collision.shape = shape
	collision.position = Vector3(0, -0.58, 0.15)
	body.add_child(collision)
	return screen

func _box(parent: Node3D, label: String, size: Vector3, at: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	parent.add_child(instance)
