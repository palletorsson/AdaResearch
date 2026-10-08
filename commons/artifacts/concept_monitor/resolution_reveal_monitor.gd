extends "res://commons/artifacts/concept_monitor/concept_monitor.gd"
## The shared monitor controls playback; this second row changes the two
## independent counts used by the private resolution illustration.

func _ready() -> void:
	super._ready()
	box("ResolutionControls", Vector3(2.15, 0.22, 0.16), Vector3(0, 0.53, 0.10), Color("d9d6d0"))
	var keys: Array[String] = ["segments_minus", "segments_plus", "rings_minus", "rings_plus"]
	var captions: Array[String] = ["S-", "S+", "R-", "R+"]
	for i in range(keys.size()):
		var label := add_button(keys[i], Vector3(-0.78 + float(i) * 0.52, 0.54, 0.21))
		label.text = captions[i]

func activate(key: String) -> void:
	var segments := int(stage.get("segments"))
	var rings := int(stage.get("rings"))
	match key:
		"segments_minus": segments = maxi(4, segments - 1)
		"segments_plus": segments = mini(64, segments + 1)
		"rings_minus": rings = maxi(0, rings - 1)
		"rings_plus": rings = mini(32, rings + 1)
		_:
			super.activate(key)
			return
	stage.call("set_resolution", segments, rings)
	pause_label.text = "PAUSE" if bool(stage.get("running")) else "PLAY"
	refresh_once()
