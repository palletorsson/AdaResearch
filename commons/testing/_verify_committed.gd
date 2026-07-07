extends SceneTree
# Temp: confirm the editor + add-on plugin + grid files load clean. Delete after.
func _initialize() -> void:
	var e = load("res://commons/scenes/map_tool_editor.gd")
	var p = load("res://addons/map_tool_3d/map_tool_3d_plugin.gd")
	var c = load("res://commons/grid/GridCommon.gd")
	if e == null:
		print("FAIL: map_tool_editor.gd"); quit(2); return
	if p == null:
		print("FAIL: map_tool_3d_plugin.gd"); quit(3); return
	if c == null:
		print("FAIL: GridCommon.gd"); quit(4); return
	print("OK: editor + plugin + grid all compile")
	quit(0)
