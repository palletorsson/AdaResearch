extends "res://algorithms/nature_system/demo/nature_system_demo.gd"
## Trial-only adapter (randomness_03) for the original Nature System test scene.
##
## The source hands CritterSpawner its LOCAL grid coordinates, and spawner.gd sets
## them as global_position. All 48 critters therefore stood at the world origin, not
## in the hall, in the museum and the Void alike. This adapter keeps the original
## spawner, grid (3 rows x 4 columns x 4 kingdoms at 3.5 m), DNA, LOD and evolution.
## It maps only the demo's own spawns into the demo's frame. Evolution offspring are
## placed between their parents' world positions and need no mapping.
##
## The standalone screen UI (a 2D CanvasLayer) is hidden. The keyboard handler is
## disabled because its R, Space and C keys collide with the Void's own controls.
## The same original actions are offered as pointer buttons on a rack panel.

const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const ACTIONS: Array = [["TREE", "CREATURE", "FLOWER", "FUNGUS"], ["RANDOMIZE", "EVOLVE", "REPOPULATE"], ["CLEAR", "LOD", "HYBRID"]]
## Demo-local panel pose: 1.5 m along local x and 2 m along local -z, facing local -z.
## With the placement turned 270 degrees that is 2 m in from the strip's start.
const PANEL_AT := Vector3(1.5, 1.1, -2.0)

var buttons: Dictionary = {}
var spawned_by_demo: int = 0

func _ready() -> void:
	super._ready()
	set_process_unhandled_input(false)
	var ui: Node = get_node_or_null("UI")
	if ui is CanvasLayer: (ui as CanvasLayer).visible = false
	_build_controls()

func _spawn_kingdom_grid() -> void:
	var before: Array = _critter_root.get_children()
	super._spawn_kingdom_grid()
	_map_new(before)

func _spawn_single_kingdom(kingdom: int) -> void:
	var before: Array = _critter_root.get_children()
	super._spawn_single_kingdom(kingdom)
	_map_new(before)

## The spawner wrote demo-local coordinates as world coordinates: read them back as
## local and place each new critter in this placement's frame.
func _map_new(before: Array) -> void:
	for child in _critter_root.get_children():
		if child in before or not child is Node3D: continue
		var node := child as Node3D
		node.global_position = to_global(node.global_position)
		spawned_by_demo += 1

func _build_controls() -> void:
	var rows: Array = []
	for row in ACTIONS:
		rows.append(row.map(func(key): return {"type": "button", "label": key}))
	var panel: Node3D = Rack.create_panel("NATURE SYSTEM / ORIGINAL KEYS", rows)
	panel.name = "VoidKeyPanel"
	panel.position = PANEL_AT
	panel.rotation.y = PI
	add_child(panel)
	var index := 0
	for row in ACTIONS:
		for key in row:
			var b: Node3D = panel.find_child("Btn_"+str(index), true, false)
			b.rotation.x = PI/2
			b.pressed.connect(func(): act.call_deferred(key))
			buttons[key] = b
			index += 1

## The original key map (keys 1-4, R, E, Space, C, L, H), one button each.
func act(key: String) -> void:
	match key:
		"TREE": _spawn_single_kingdom(0)
		"CREATURE": _spawn_single_kingdom(1)
		"FLOWER": _spawn_single_kingdom(2)
		"FUNGUS": _spawn_single_kingdom(3)
		"RANDOMIZE": _randomize_all()
		"EVOLVE":
			_evolution.evolve_step()
			_update_label()
		"REPOPULATE":
			_spawner.despawn_all()
			_spawn_kingdom_grid()
		"CLEAR":
			_spawner.despawn_all()
			_update_label()
		"LOD": _cycle_lod()
		"HYBRID":
			_hybrid_mode = not _hybrid_mode
			_update_label()
