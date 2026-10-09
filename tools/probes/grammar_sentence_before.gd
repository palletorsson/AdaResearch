extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(1.0).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:
		stream.set_process(false)
		observations.entry=stream.get("_entry")
		observations.exit=stream.get("_exit")
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var editor=find_scene("/lsystem_editor/lsystem_editor.gd")
	check("Original editor present",editor!=null)
	if editor!=null:
		var desk=editor.get_node("GrammarLesson")
		observations.editor_transform=str(editor.global_transform)
		await snapshot("arrival",hall.to_global(Vector3(9.5,1.75,1.8)),hall.to_global(Vector3(9.5,2.2,8)),78)
		desk.act("NEXT");desk.act("HOLD");desk.act("TURN")
		await snapshot("comparison",editor.to_global(Vector3(0,2.2,6.4)),editor.to_global(Vector3(0,1.9,0)),72)
	await snapshot("above",hall.to_global(Vector3(9.5,24,9)),hall.to_global(Vector3(9.5,0,13)),70)
	await snapshot("rear",hall.to_global(Vector3(9.5,2.0,18)),hall.to_global(Vector3(9.5,1.0,25)),78)
