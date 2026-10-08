extends "res://commons/artifacts/concept_monitor/preview.gd"
## Desktop demonstration uses the real drawing tool with an explicitly supplied outline.
var drawing: Node3D
var shape_index := 0

func _ready() -> void:
	super()
	drawing = load("res://commons/primitives/point/draw_triangle_faces.tscn").instantiate()
	drawing.name = "PreviewDrawing"
	add_child(drawing)
	drawing.position = Vector3(20, 1, 0)
	drawing.set_process(false)
	drawing.set_physics_process(false)
	monitor.set("drawing_path", monitor.get_path_to(drawing))
	monitor.call("discover_source")
	set_example(0)
	for child in get_children():
		if child is Label:
			child.text += "\nD: triangle / four corners / six corners / open path (supplied examples)"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_D:
		set_example((shape_index + 1) % 4)
		return
	super(event)

func set_example(index: int) -> void:
	shape_index = index
	drawing.call("clear_all")
	var points: Array[Vector3] = [Vector3(-1, -0.7, 0), Vector3(1, -0.7, 0), Vector3(-0.3, 0.9, 0)]
	if index == 1 or index == 3:
		points = [Vector3(-1, -0.7, 0), Vector3(1, -0.7, 0.35), Vector3(0.9, 0.7, -0.2), Vector3(-0.8, 1.0, 0)]
	if index == 2:
		points = [Vector3(-1.2,-0.6,0), Vector3(0,-0.95,0.25), Vector3(1.2,-0.5,0), Vector3(0.85,0.6,-0.2), Vector3(0,1,0.35), Vector3(-1,0.5,0)]
	for point in points: drawing.call("_create_new_point", drawing.to_global(point))
	if index != 3: drawing.call("_handle_snap_to_point", 0)
	drawing.call("_rebuild_lines")
	monitor.call("observe", 0.25)
	monitor.get("stage").record.source_name = "SUPPLIED EXAMPLE / actual drawing-tool mesh"
	monitor.get("stage").call("refresh")
	monitor.call("refresh_once")
