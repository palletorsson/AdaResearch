extends "res://commons/scenes/endless_museum.gd"
## Exportable museum entry: uses compiled scripts, not the dev launcher's source snapshot.
const ARENA_PLAN := "res://commons/maps/Catalyst_Test_Arena/museum_plan.json"
const SESSION := "user://head-arena/"
var arena: Node3D
var menu_button: Node3D

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SESSION))
	EM_CONTROL = SESSION + "control.json"
	_hand_path = SESSION + "hand.json"
	_overrides_path = SESSION + "overrides.json"
	FileAccess.open(EM_CONTROL, FileAccess.WRITE).store_string(JSON.stringify({"first_chapter":"transformation", "first_map":"Catalyst_Test_Arena", "dollhouse":0}))
	if not FileAccess.file_exists(_overrides_path):
		FileAccess.open(_overrides_path, FileAccess.WRITE).store_string("{}")
	super()
	_mount_arena.call_deferred()

func _parse_args() -> void:
	super()
	_plan_path = ARENA_PLAN
	plan_file = ARENA_PLAN
	start_chapter = "transformation"
	start_map = "Catalyst_Test_Arena"
	_first_chapter = "transformation"
	# This explicit menu destination consumes any stale chapter handoff.
	menu_chapter = ""; menu_map = ""
	_dollhouse = false; _edit_mode = false

func _mount_arena() -> void:
	var began := Time.get_ticks_msec()
	while not _museum_core_ready and Time.get_ticks_msec() - began < 60000:
		await get_tree().process_frame
	if not is_inside_tree(): return
	await get_tree().physics_frame
	flush_stamps()
	await get_tree().physics_frame
	for hall in get_children():
		if hall is Node3D and str(hall.get_meta("em_map", "")) == "Catalyst_Test_Arena":
			arena = load("res://commons/hazards/catalyst_counterpart/test_arena.gd").mount_arena(hall)
			break
	if arena == null:
		push_error("Head Arena could not mount in its museum hall")
		return
	menu_button = arena._control("MAIN MENU", Vector3(-4.6, 1.1, 2.5), get_parent().return_to_menu)
	arena._plinth(Vector3(-4.6, 0.49, 2.47), Vector3(0.7, 0.98, 0.45))
	print("[head-arena] Ready from game menu")

func is_map_ready() -> bool:
	return is_instance_valid(arena)

func _report_path(path: String) -> String:
	return SESSION + path.get_file()

# This practice room is not an authoring census of the whole museum.
func _save_inventory() -> void: pass
func _save_showing_cards() -> void: pass
func _layout_write() -> void: _layout_dirty = false
func _adopt_write() -> void: _adopt_dirty = false
func _ledger_save() -> void: _live_dirty = false
