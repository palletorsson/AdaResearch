# test_scene_narrator.gd — Headless test for SceneNarrator
# Usage: godot --path . --xr-mode off --no-window --script res://commons/testing/test_scene_narrator.gd -- --map=CA_1
extends SceneTree

var target_map: String = "CA_1"

func _init():
	var args = OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--map="):
			target_map = arg.substr(6)
	print("=== SceneNarrator Test ===")
	print("Target map: %s" % target_map)

func _initialize():
	# Load GridSystem scene
	var grid_scene = load("res://commons/grid/grid_system.tscn")
	if not grid_scene:
		print("ERROR: Failed to load grid_system.tscn")
		quit(1)
		return
	var gs = grid_scene.instantiate()
	gs.map_name = target_map
	gs.auto_load_map_on_ready = true
	root.add_child(gs)

	# Wait for generation — 'self' IS the SceneTree, so use create_timer directly
	create_timer(5.0).timeout.connect(_run_test)

func _run_test():
	print("\n--- Running SceneNarrator.narrate_full() ---")

	var narrator = root.get_node_or_null("SceneNarrator")
	if not narrator:
		print("ERROR: SceneNarrator autoload not found!")
		for child in root.get_children():
			print("  autoload: %s" % child.name)
		quit(1)
		return

	# Check interactable count before narrating
	var gs_nodes = root.get_tree().get_nodes_in_group("grid_system")
	if gs_nodes.size() > 0:
		var gs = gs_nodes[0]
		if gs.interactables_component:
			print("  interactable_objects: %d entries" % gs.interactables_component.interactable_objects.size())

	narrator.narrate_full()

	# Wait for writes
	create_timer(2.0).timeout.connect(_print_results)

func _print_results():
	print("\n========== SPATIAL ANALYSIS ==========")
	_print_file("res://ada_run/scene_spatial.md")
	_print_file("user://ada_run/scene_spatial.md")

	print("\n========== JOURNEY NARRATIVE ==========")
	_print_file("res://ada_run/journey_narrative.md")
	_print_file("user://ada_run/journey_narrative.md")

	print("\n--- Test complete ---")
	quit(0)

func _print_file(path: String):
	if FileAccess.file_exists(path):
		var content = FileAccess.get_file_as_string(path)
		print("[%s]" % path)
		print(content)
		return true
	return false
