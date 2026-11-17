extends SceneTree
## Offline, deterministic, original accompaniment. Run in an isolated audio project.
func _initialize() -> void:
	var bindings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/opera/tower_bindings.json"))
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(bindings.accompaniment))
	var synth: GDScript = load(str(config.get("synth", "res://audio/generators/OperaLofi.gd")))
	assert(synth != null and synth.can_instantiate())
	var stems: Dictionary = synth.render(config)
	DirAccess.make_dir_recursive_absolute("res://audio/opera_music")
	for id in ["bed", "pulse"]:
		var wav: AudioStreamWAV = stems[id]
		assert(wav.save_to_wav(config[id]) == OK)
		print("SHIP_MUSIC ", id, " ", config[id], " ", wav.data.size(), " bytes / ", stems.seconds, " s")
	quit()
