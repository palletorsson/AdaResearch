extends SceneTree
## Authoring helper: make the offline synthetic voice a native Godot resource.
## ResourceLoader can then load it in packaged Quest builds as well as the editor.
func _initialize() -> void:
	var wav := AudioStreamWAV.load_from_file("res://commons/artifacts/ambient_patch/room_memory_demo.wav")
	var error := ResourceSaver.save(wav,"res://commons/artifacts/ambient_patch/room_memory_demo.res")
	quit(0 if error==OK else 1)
