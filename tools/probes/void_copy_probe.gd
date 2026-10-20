# Load browser-authored copies through the actual game; exercise a copied pickable reset.
extends SceneTree
var output := "user://"
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output=arg.trim_prefix("--out=")
	run.call_deferred()
func run() -> void:
	var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("expected.json")))
	var game: Node3D=load("res://commons/void/void.tscn").instantiate()
	root.add_child(game)
	# Freeze the authored copy while inspecting its build, before simulation moves it.
	var content: Node3D=game.building.content
	var original: Node3D=content.exhibits["3/directions"].get_node("Artifact/PoliceBarricade")
	var area: Node3D=content.exhibits["3/"+expected.barrier].get_node("Artifact")
	var barrier: Node3D=area.get_node("PoliceBarricade")
	var second: Node3D=content.exhibits["3/"+expected.second].get_node("Artifact/PoliceBarricade")
	var plank_area: Node3D=content.exhibits["3/"+expected.plank].get_node("Artifact")
	var plank: RigidBody3D=plank_area.get_node("Hand_plank")
	var start: Transform3D=plank.transform
	plank.freeze=true
	var checks: Dictionary={
		"copy_is_independent":barrier!=original and second!=barrier,
		"copy_has_original_script":barrier.get_script()==original.get_script(),
		"copy_has_original_collision":barrier.solid and barrier.find_children("*","CollisionShape3D",true,false).size()==original.find_children("*","CollisionShape3D",true,false).size(),
		"copy_is_not_double_built":barrier.get_child_count()==original.get_child_count(),
		"only_chosen_part_survives":area.get_child_count()==1 and plank_area.get_child_count()==1,
		"copied_position":barrier.global_position.is_equal_approx(Vector3(-3.2,-18,-2)),
		"copied_rotation":is_equal_approx(barrier.global_rotation_degrees.y,90),
		"second_copy_position":second.global_position.is_equal_approx(Vector3(-2.2,-18,-3.8)),
		"pickable_script_and_state":plank.has_method("pick_up") and plank.enabled,
		"pruned_reset_list":plank_area.reusable.size()==1 and plank_area.reusable[0]==plank
	}
	plank.position+=Vector3(2,1,0)
	plank_area.reset_after_fall()
	checks["copied_pickable_resets"]=plank.transform.is_equal_approx(start)
	var editor: RefCounted=load("res://addons/void_floor_editor/document.gd").new()
	editor.data=content.data.duplicate(true)
	editor.catalog=content.catalog
	editor.parts=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/line_parts.json"))
	editor.floor_index=3
	var copied_entries: Array=editor.entries().filter(func(e):return e.kind=="part" and e.get("collection","")=="copies")
	checks["native_editor_sees_only_copied_parts"]=copied_entries.size()==3
	if copied_entries.size()>0:
		editor.move_entry(copied_entries[0],Vector2(-4,-2))
		checks["native_editor_moves_copy_independently"]=editor.data.floors[3].copies[0].position==[-4.0,-2.0] and editor.data.floors[3].artifacts==content.data.floors[3].artifacts
	for i in range(3): await physics_frame
	var passed:=true
	for value in checks.values(): if not value: passed=false
	FileAccess.open(output.path_join("godot-copies.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks},"  "))
	print("VOID_COPY_TEST ",JSON.stringify(checks))
	game.queue_free();await process_frame;await process_frame
	quit(0 if passed else 1)
