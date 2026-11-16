extends Control
## MODEL B'S INNER VOICE, ON THE BENCH (Palle, 2026-11-16: "can we test the voice in desktop using only godot?")
##
## One window, no tower, nothing but Godot: the same voice node the game uses (commons/void/inner_voice_godot.gd)
## with the roof's five phrases and the kit's approved six. Click a phrase, or press its number, and it is sung.
## Two voices to hear against each other: MODEL B (audio/generators/ModelBVoice.gd, learned from the Rust engine
## and tuned against the recordings of the approved voice) and ROBOT (the kit's RobotVoiceGenerator.gd). Settings
## can be changed and everything made again; KEEP writes the voice and its settings to
## commons/data/opera/tower_bindings.json, where the tower reads them.
##
##   Godot --path . --xr-mode off res://commons/void/inner_voice_bench.tscn
##
## Nothing sounds until a phrase is asked for. Esc closes the window. With --check (for a test) it renders, sings
## nothing, writes user://inner_voice_bench.json and quits.
const Voice := preload("res://commons/void/inner_voice_godot.gd")
const SCORES := [["THE ROOF  ·  new study", "res://audio/voice_scores/tower_roof_20261116.json"],
	["THE KIT'S SIX  ·  the approved words, in this Godot voice", "res://audio/voice_scores/chimera_inner_opera_20261116.json"]]
const BINDINGS := "res://commons/data/opera/tower_bindings.json"
const PAPER := Color("efe9dc")
const DIM := Color("9aa0ad")
const HOT := Color("f2a23a")

var voice: Node
var buttons := {}                         # object id -> Button
var labels := {}                          # object id -> what the button says without its state
var sliders := {}
var readouts := {}
var status: Label
var singing_all: Array[String] = []
var renderer := "model_b"
var renderer_button: Button
const RESTS := {"airway": {"formant_ratio": 1.0, "transpose": 0.0, "gain": 1.0, "air": 0.62, "flow_sharpness": 0.45},
	"model_b": {"formant_ratio": 1.12, "transpose": 0.0, "gain": 1.0, "air": 0.62, "flow_sharpness": 0.45},
	"robot": {"formant_ratio": 1.0, "transpose": 0.0, "gain": 0.35, "air": 0.62, "flow_sharpness": 0.45}}
var checking := false


func _ready() -> void:
	checking = OS.get_cmdline_user_args().has("--check")
	get_window().title = "Model B · inner voice bench (Godot only)"
	var back := ColorRect.new()
	back.color = Color("14171f")
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 40)
	margin.add_child(columns)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	columns.add_child(left)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(380, 0)
	right.add_theme_constant_override("separation", 10)
	columns.add_child(right)
	_say(left, "MODEL B  ·  THE INNER VOICE", 26, PAPER)
	_say(left, "Made by Godot only, no native engine. Click a phrase or press its number.", 15, DIM)
	voice = Voice.new()
	voice.set("volume_db", 0.0)
	add_child(voice)
	voice.connect("rendered", _on_rendered)
	voice.connect("started", func(id, text): _tell("singing:  %s" % text))
	voice.connect("finished", _on_finished)
	voice.connect("failed", func(id, message): _tell("NOT SUNG  %s:  %s" % [id, message]))
	var kept: Variant = JSON.parse_string(FileAccess.get_file_as_string(BINDINGS)) if FileAccess.file_exists(BINDINGS) else null
	if kept is Dictionary and RESTS.has(str(kept.get("renderer", ""))): renderer = str(kept.renderer)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--voice=") and RESTS.has(arg.trim_prefix("--voice=")): renderer = arg.trim_prefix("--voice=")
	var settings := _kept_settings()
	var number := 1
	for group in SCORES:
		_say(left, "", 6, DIM)
		_say(left, str(group[0]), 15, HOT)
		var before: Array = (voice.get("order") as Array).duplicate()
		var wrong := str(voice.call("load_score", str(group[1]), settings, renderer))
		if not wrong.is_empty():
			_say(left, "cannot be used: " + wrong, 14, Color("ff6a5a"))
			continue
		for id in voice.get("order"):
			if before.has(id): continue
			var button := Button.new()
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.add_theme_font_size_override("font_size", 17)
			labels[id] = "%s   %s      —  %s" % [str(number) if number < 10 else ("0" if number == 10 else " "), str(voice.call("text_of", id)), str((voice.get("phrases") as Dictionary)[id].get("object_label", id))]
			button.text = labels[id] + "      (being made)"
			button.pressed.connect(_sing.bind(str(id)))
			left.add_child(button)
			buttons[id] = button
			number += 1
	_say(right, "THE VOICE", 15, HOT)
	renderer_button = Button.new()
	renderer_button.add_theme_font_size_override("font_size", 15)
	renderer_button.pressed.connect(_other_voice)
	right.add_child(renderer_button)
	_name_voice()
	var rest: Dictionary = RESTS[renderer]
	_slider(right, "formant_ratio", "size of the voice  (formants)", 0.8, 1.3, 0.02, float(settings.get("formant_ratio", rest.formant_ratio)))
	_slider(right, "transpose", "pitch, in semitones", -12.0, 12.0, 1.0, float(settings.get("transpose", rest.transpose)))
	_slider(right, "gain", "level out of the renderer", 0.1, 1.5, 0.05, float(settings.get("gain", rest.gain)))
	_slider(right, "air", "breath in the voice  (Model B only)", 0.0, 1.0, 0.02, float(settings.get("air", rest.air)))
	_slider(right, "flow_sharpness", "edge: how abruptly the breath is cut  (Model B only)", 0.0, 1.0, 0.05, float(settings.get("flow_sharpness", rest.flow_sharpness)))
	_button(right, "MAKE ALL AGAIN WITH THESE", _retune)
	_button(right, "SING ALL, IN ORDER", _sing_all)
	_button(right, "STOP", func(): singing_all.clear(); voice.call("stop"))
	_button(right, "KEEP THESE FOR THE TOWER", _keep)
	_say(right, "", 6, DIM)
	status = _say(right, "making the phrases, one at a time, off the window's thread", 15, PAPER)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_say(right, "Neither is the voice that was approved: that is the kit's Rust engine, which is not used. MODEL B is the Godot voice measured against its recordings.", 13, DIM).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _say(parent: Control, text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(action)
	parent.add_child(button)


func _slider(parent: Control, key: String, title: String, low: float, high: float, step: float, value: float) -> void:
	readouts[key] = _say(parent, "", 14, PAPER)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = value
	slider.value_changed.connect(func(_v): _show_settings())
	parent.add_child(slider)
	sliders[key] = slider
	slider.set_meta("title", title)
	_show_settings()


func _show_settings() -> void:
	for key in sliders:
		if readouts.has(key): (readouts[key] as Label).text = "%s:   %s" % [str((sliders[key] as HSlider).get_meta("title")), str(snappedf((sliders[key] as HSlider).value, 0.01))]


func _settings() -> Dictionary:
	var out := {"formant_ratio": snappedf((sliders["formant_ratio"] as HSlider).value, 0.01), "transpose": (sliders["transpose"] as HSlider).value, "gain": snappedf((sliders["gain"] as HSlider).value, 0.01)}
	if renderer == "airway": out.erase("formant_ratio")          # a body has its own size: only pitch and level are the bench's to change
	if renderer == "model_b":
		out["air"] = snappedf((sliders["air"] as HSlider).value, 0.01)
		out["flow_sharpness"] = snappedf((sliders["flow_sharpness"] as HSlider).value, 0.01)
	return out


func _name_voice() -> void:
	renderer_button.text = {"airway": "AIRWAY  (the physical voice: lungs, folds, mouth; slow to make)   -   click for MODEL B",
		"model_b": "MODEL B  (formant voice, quick)   -   click for ROBOT", "robot": "ROBOT  (the kit's)   -   click for AIRWAY"}[renderer]


## The other voice, at its own resting settings; everything is made again.
func _other_voice() -> void:
	renderer = {"airway": "model_b", "model_b": "robot", "robot": "airway"}[renderer]
	for key in sliders: (sliders[key] as HSlider).value = float(RESTS[renderer][key])
	_name_voice()
	_retune()


func _kept_settings() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BINDINGS)) if FileAccess.file_exists(BINDINGS) else null
	return parsed.voice if parsed is Dictionary and parsed.get("voice") is Dictionary else {}


func _tell(text: String) -> void:
	if status != null: status.text = text


func _sing(id: String) -> void:
	if not bool(voice.call("is_ready", id)):
		_tell("'%s' is still being made" % id)
		return
	voice.call("stop")
	voice.call("sing", id)


func _sing_all() -> void:
	singing_all.assign(voice.get("order"))
	_next_of_all()


func _next_of_all() -> void:
	while not singing_all.is_empty():
		var id: String = singing_all.pop_front()
		if bool(voice.call("is_ready", id)):
			voice.call("sing", id)
			return


func _on_finished(_id: String) -> void:
	if singing_all.is_empty():
		_tell("ready")
		return
	await get_tree().create_timer(0.7).timeout
	_next_of_all()


func _on_rendered(id: String, seconds: float, cached: bool) -> void:
	if buttons.has(id):
		var length: float = float((voice.get("costs") as Dictionary)[id].length_s)
		(buttons[id] as Button).text = "%s      (%.1f s long, %s)" % [labels[id], length, "kept from before" if cached else "made in %.1f s" % seconds]
	if (voice.get("streams") as Dictionary).size() == buttons.size():
		_tell("all %d phrases are ready" % buttons.size())
		if checking: _report()


func _retune() -> void:
	singing_all.clear()
	var wrong := str(voice.call("retune", _settings(), renderer))
	if not wrong.is_empty():
		_tell("these settings cannot be used: " + wrong)
		return
	for id in buttons:
		if not bool(voice.call("is_ready", id)): (buttons[id] as Button).text = labels[id] + "      (being made)"
	_tell("making all again:  %s  %s" % [renderer, str(_settings())])


## The settings go to the tower's bindings file: the tower's voice is made with them from its next start.
func _keep() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BINDINGS))
	if not parsed is Dictionary:
		_tell("the tower's bindings file cannot be read")
		return
	parsed["voice"] = _settings()
	parsed["renderer"] = renderer
	# the phrases as made now travel with the game, so a headset plays them without making them
	var shipped := 0
	DirAccess.make_dir_recursive_absolute("res://audio/voice_cache")
	for id in buttons:
		if not bool(voice.call("is_ready", id)): continue
		var made: Variant = (voice.get("streams") as Dictionary).get(id)
		if made is AudioStreamWAV and (made as AudioStreamWAV).save_to_wav("res://audio/voice_cache/" + str(voice.call("_key", id)) + ".wav") == OK: shipped += 1
	var file := FileAccess.open(BINDINGS, FileAccess.WRITE)
	if file == null:
		_tell("the tower's bindings file cannot be written here")
		return
	file.store_string(JSON.stringify(parsed, "  ") + "\n")
	file.close()
	_tell("kept for the tower:  %s  %s   (%d phrases as made now travel with the game)" % [renderer, str(_settings()), shipped])


func _report() -> void:
	var file := FileAccess.open("user://inner_voice_bench.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"phrases": buttons.size(), "ready": (voice.get("streams") as Dictionary).size(), "costs": voice.get("costs"), "renderer": renderer, "settings": _settings(), "sounding": bool(voice.call("is_sounding"))}, "\t"))
	file.close()
	get_tree().quit()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo: return
	if key.keycode == KEY_ESCAPE:
		get_tree().quit()
		return
	var index := -1
	if key.keycode >= KEY_1 and key.keycode <= KEY_9: index = key.keycode - KEY_1
	elif key.keycode == KEY_0: index = 9
	var ids: Array = buttons.keys()
	if index >= 0 and index < ids.size(): _sing(str(ids[index]))
