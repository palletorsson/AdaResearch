# dump_godot_class_tree.gd — the engine as the authority on construction.
# Dumps ClassDB's full inheritance map {class: parent} to JSON so offline
# tools (mine_construction_edges.py) can walk real extends chains.
#
# Run (watchdog-wrapped, headless):
#   python tools/godot_watchdog.py --expect=commons/data/godot_class_tree.json -- \
#     <godot exe> --path . --headless --xr-mode off --script res://tools/dump_godot_class_tree.gd
extends SceneTree

func _init():
	var out := {}
	for c in ClassDB.get_class_list():
		out[c] = ClassDB.get_parent_class(c)
	var f := FileAccess.open("res://commons/data/godot_class_tree.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " "))
	f.close()
	print("godot_class_tree: ", out.size(), " classes")
	quit()
