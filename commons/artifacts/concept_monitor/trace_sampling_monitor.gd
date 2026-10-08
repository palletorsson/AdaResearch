extends "res://commons/artifacts/concept_monitor/concept_monitor.gd"
## Observe the same pen-tip and held-state DrawDot uses, before its grain/snap.
const DrawDot = preload("res://commons/primitives/point/draw_dot.gd")
@export var draw_dot_path: NodePath
var sources: Array[Node3D] = []
var active_source: Node3D
var scan_elapsed := 1.0

func _process(delta: float) -> void:
	observe(delta)
	super(delta)

func observe(delta: float) -> void:
	scan_elapsed += delta
	if scan_elapsed >= 1.0:
		scan_elapsed = 0.0
		discover_sources()
	if is_instance_valid(active_source) and drawing(active_source):
		var tip: Node3D = active_source.get("_draw_sphere")
		var board: Dictionary = active_source.call("_nearest_board_face", tip.global_position)
		stage.record.append(tip.global_position, delta, board)
		return
	if active_source != null or stage.record.capturing:
		stage.record.end()
		active_source = null
		stage.replay()
	for candidate in sources:
		if not drawing(candidate): continue
		active_source = candidate
		var tip: Node3D = candidate.get("_draw_sphere")
		var board: Dictionary = candidate.call("_nearest_board_face", tip.global_position)
		stage.record.begin(tip.global_position, board, float(candidate.get("min_segment_distance")), str(candidate.name))
		stage.playhead = 0.0
		return

func drawing(source: Node3D) -> bool:
	if not is_instance_valid(source) or not source.is_visible_in_tree(): return false
	var tip: Node3D = source.get("_draw_sphere")
	var grab: Node3D = source.get("_grab_point")
	if not is_instance_valid(tip) or not is_instance_valid(grab): return false
	if tip.global_position.distance_to(global_position) > active_distance: return false
	if not bool(source.get("record_only_when_grabbed")): return true
	return bool(grab.call("is_drawing_ready")) if grab.has_method("is_drawing_ready") else bool(grab.call("is_picked_up"))

func discover_sources() -> void:
	sources.clear()
	if not draw_dot_path.is_empty():
		var explicit := get_node_or_null(draw_dot_path) as Node3D
		if explicit != null and explicit.get_script() == DrawDot: sources.append(explicit)
		return
	var scope := get_parent()
	var ancestor := scope
	while ancestor != null:
		if ancestor.has_meta("em_map"):
			scope = ancestor
			break
		ancestor = ancestor.get_parent()
	if scope != null: collect_sources(scope)

func collect_sources(node: Node) -> void:
	if node is SubViewport: return
	if node.get_script() == DrawDot and node is Node3D: sources.append(node)
	for child in node.get_children(): collect_sources(child)
