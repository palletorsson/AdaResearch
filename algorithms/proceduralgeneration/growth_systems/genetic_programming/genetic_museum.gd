extends Node3D
## The ordinary population/UI remain unchanged unless this placement opts in.
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
	lesson_node = load("res://algorithms/proceduralgeneration/growth_systems/genetic_programming/selection_lesson.gd").new()
	lesson_node.name = "SelectionLesson"
	lesson_node.model = $GeneticProgramming
	add_child(lesson_node)
