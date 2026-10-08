extends "res://commons/artifacts/concept_monitor/concept_monitor.gd"
## Passive observer. Every face is copied from the drawing tool's actual mesh.
const Record = preload("res://commons/artifacts/concept_monitor/triangle_reveal_record.gd")
@export var drawing_path: NodePath
var source: Node3D
var scan_elapsed := 1.0
var sample_elapsed := 0.0

func _process(delta: float) -> void:
	observe(delta)
	super(delta)

func observe(delta: float) -> void:
	scan_elapsed += delta
	if scan_elapsed >= 1.0:
		scan_elapsed = 0.0
		if not is_instance_valid(source): discover_source()
	sample_elapsed += delta
	if sample_elapsed < 0.2: return
	sample_elapsed = 0.0
	if stage.call("set_record", Record.capture(source)):
		refresh_once()

func discover_source() -> void:
	source = null
	if not drawing_path.is_empty():
		var candidate := get_node_or_null(drawing_path) as Node3D
		if is_drawing(candidate): source = candidate
		return
	var scope := get_parent()
	var ancestor := scope
	while ancestor != null:
		if ancestor.has_meta("em_map"):
			scope = ancestor
			break
		ancestor = ancestor.get_parent()
	if scope != null: find_drawing(scope)

func is_drawing(node: Node) -> bool:
	if not is_instance_valid(node): return false
	var script: Script = node.get_script()
	return script != null and script.resource_path.ends_with("/draw_triangle_faces.gd")

func find_drawing(node: Node) -> void:
	if node is SubViewport or is_instance_valid(source): return
	if is_drawing(node):
		source = node as Node3D
		return
	for child in node.get_children(): find_drawing(child)
