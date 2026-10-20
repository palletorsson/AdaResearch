# Verify a browser-authored placement through the actual Void game scene.
extends SceneTree
var out := "user://"
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	run.call_deferred()
func run() -> void:
	var packed: PackedScene=load("res://commons/void/void.tscn")
	var game: Node3D=packed.instantiate()
	root.add_child(game)
	for i in range(4):await physics_frame
	var barrier: Node3D=game.building.content.exhibits["3/directions"].get_node("Artifact/PoliceBarricade")
	var checks: Dictionary={
		"browser_position_reaches_real_game":barrier.global_position.is_equal_approx(Vector3(-3.2,-18,-2)),
		"browser_rotation_reaches_real_game":is_equal_approx(barrier.rotation_degrees.y,90),
		"original_police_artifact_script":barrier.get_script().resource_path=="res://commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.gd",
		"original_collision_enabled":barrier.solid,
		"real_scene_is_xr_scene_base":game.get_script().get_base_script().resource_path.ends_with("staging/scene_base.gd"),
		"structural_floor_count":game.building.floors.size()==4,
		"floor_three_checkpoint":game.checkpoint==3
	}
	var passed:=true
	for value in checks.values():if not value:passed=false
	FileAccess.open(out.path_join("godot-roundtrip.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"position":[barrier.global_position.x,barrier.global_position.y,barrier.global_position.z],"rotation":barrier.rotation_degrees.y},"  "))
	print("VOID_WEB_ROUNDTRIP ",JSON.stringify(checks))
	game.queue_free();await process_frame;await process_frame
	quit(0 if passed else 1)
