extends RefCounted
## One route shared by standalone play, museum entries and the planning evidence.
const SCENE := "res://commons/hazards/biome_ladder/ladder_world.tscn"
const STAGES := [
	{"sequence": "primitives", "title": "PRIMITIVES", "last": "Primitives_Melencolia", "next": "transformation", "first": "Trans_Pre"},
	{"sequence": "transformation", "title": "TRANSFORMATION", "last": "Trans_Pit", "next": "array_tutorial", "first": "Array"},
	{"sequence": "array_tutorial", "title": "ARRAYS", "last": "Tutorial_Disco", "next": "color", "first": "Color_Context_Placed"},
	{"sequence": "color", "title": "COLOUR", "last": "Color_Walls", "next": "tiling", "first": "Pattern_Disco"},
	{"sequence": "tiling", "title": "TILING", "last": "Ribbon_Patterns_03", "next": "change", "first": "Change_Intro"},
	{"sequence": "change", "title": "CHANGE", "last": "Flow_Field", "next": "forces", "first": "Vectors_Act1_WhatAVectorIs"},
]
static var selected_stage := 0
static var from_museum := false

static func index_for_map(map_id: String) -> int:
	for i in range(STAGES.size()):
		if STAGES[i].last == map_id: return i
	return -1

static func enter(context: Node, stage: int, museum: bool = false) -> void:
	selected_stage = clampi(stage, 0, STAGES.size() - 1)
	from_museum = museum
	load_scene(context, SCENE)

static func load_scene(context: Node, path: String) -> void:
	var ancestor := context.get_parent()
	while ancestor != null:
		if ancestor.has_method("load_scene") and ancestor.has_method("return_to_main_menu"):
			ancestor.load_scene(path)
			return
		ancestor = ancestor.get_parent()
	context.get_tree().change_scene_to_file.call_deferred(path)

static func continue_museum(context: Node) -> void:
	var stage: Dictionary = STAGES[selected_stage]
	# Dynamic lookup avoids a circular preload with the museum's entry hook.
	var museum: GDScript = load("res://commons/scenes/endless_museum.gd")
	museum.open_at(stage.next, stage.first)
	load_scene(context, "res://commons/scenes/endless_museum_staged.tscn")
