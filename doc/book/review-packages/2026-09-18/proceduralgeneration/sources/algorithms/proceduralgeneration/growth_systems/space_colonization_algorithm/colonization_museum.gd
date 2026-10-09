extends Node3D
## The museum lesson is opt-in; ordinary placements retain the tip policy and 3D UI.
var lesson := false
var lesson_node: Node3D

func _ready() -> void:
	lesson = lesson or str(get_meta("config_lesson", "false")) == "true"
	if lesson and not Engine.is_editor_hint(): _enable()

func apply_grid_config(config: Dictionary) -> void:
	if config.has("lesson"): lesson = str(config.lesson).to_lower() == "true"
	if lesson and is_node_ready() and not Engine.is_editor_hint(): _enable()

func _enable() -> void:
	if is_instance_valid(lesson_node): return
	$UI.hide()
	$UI.process_mode = Node.PROCESS_MODE_DISABLED
	for body in $UI.find_children("*", "CollisionObject3D", true, false):
		body.collision_layer = 0
		body.collision_mask = 0
	$DirectionalLight3D.hide()
	lesson_node = load("res://algorithms/proceduralgeneration/growth_systems/space_colonization_algorithm/colonization_lesson.gd").new()
	lesson_node.name = "ColonizationLesson"
	lesson_node.model = $SpaceColonizationAlgorithm
	add_child(lesson_node)
