extends SceneTree
var checks: Array = []
var out := ""
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	call_deferred("run")
func check(label: String, value: bool) -> void:
	checks.append({"check":label,"passed":value})
	print("PASS " if value else "FAIL ",label)
func run() -> void:
	var editor := preload("res://addons/void_floor_editor/dock.gd").new()
	root.add_child(editor)
	editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	var doc: RefCounted = editor.document
	doc.floor_index=3;editor.floor_select.select(3);editor.refresh()
	check("Four floors read from shared source",doc.data.floors.size()==4)
	var original := JSON.stringify(doc.data)
	var found := -1
	var entries: Array = doc.entries()
	for i in range(entries.size()):
		if entries[i].kind=="part" and entries[i].key=="MeasurementRoom": found=i
	check("Actual runtime artifact parts are individually editable",found>=0)
	if found>=0:
		editor.select_entry(found)
		editor.x_value.value=1;editor.z_value.value=3.5;editor.move_selected()
		check("Move writes local part override, not another artifact",Vector3(doc.floor_data().artifacts[0].config.parts.MeasurementRoom.position[0],doc.floor_data().artifacts[0].config.parts.MeasurementRoom.position[1],doc.floor_data().artifacts[0].config.parts.MeasurementRoom.position[2]).is_equal_approx(Vector3(17.5,0,3.5)))
		FileAccess.open(out.path_join("editor-roundtrip.json"),FileAccess.WRITE).store_string(JSON.stringify(doc.data,"  "))
		editor.rotate_selected()
		check("Rotate retains authored orientation",doc.floor_data().artifacts[0].config.parts.MeasurementRoom.rotation[1]==270)
		doc.undo();doc.undo();check("Undo restores all fields",JSON.stringify(doc.data)==original)
		doc.redo();check("Redo reapplies the part edit",doc.dirty());doc.undo()
	editor.tool_select.select(1);editor.place(Vector2(-17,-8));editor.place(Vector2(-15,-7.5))
	check("Wall uses two clicks and nearest grid axis",doc.vec(doc.floor_data().walls.back().to).is_equal_approx(Vector2(-15,-8)))
	check("Wall is explicitly unfinished",doc.floor_data().walls.back().finish=="unfinished")
	doc.undo()
	doc.add_prop("pallet",Vector2(-18,-5));check("Existing prefab can be placed",doc.floor_data().props.back().kind=="pallet")
	doc.undo()
	doc.add_route(Vector2(1,2));check("Route annotations persist in shared model",doc.vec(doc.floor_data().route.back().position).is_equal_approx(Vector2(1,2)));doc.undo()
	check("All probe edits reverted without saving production data",JSON.stringify(doc.data)==original)
	editor.tool_select.select(0);editor.canvas.move_tool=true
	editor.select_entry(found)
	for i in range(4): await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("native-editor.png"))
	var passed := true
	for item in checks: passed=passed and item.passed
	FileAccess.open(out.path_join("native-editor-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks},"  "))
	editor.queue_free();await process_frame;quit(0 if passed else 1)
