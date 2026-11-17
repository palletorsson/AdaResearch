extends Control
## MODEL B'S INNER VOICE, ON THE BENCH (Palle, 2026-11-16: "can we test the voice in desktop using only godot?")
##
## One window, no tower, nothing but Godot: the same voice node the game uses (commons/void/inner_voice_godot.gd)
## with the roof's five phrases and the kit's approved six. Click a phrase, or press its number, and it is sung.
## Compare Phoneme Library, Airway, Model B and Robot. Settings can be changed and everything made again.
## For the existing tower renderers, KEEP writes the voice and its settings to
## commons/data/opera/tower_bindings.json, where the tower reads them.
##
##   Godot --path . --xr-mode off res://commons/void/inner_voice_bench.tscn
##
## Nothing sounds until a phrase is asked for. Esc closes the window. With --check (for a test) it renders, sings
## nothing, writes user://inner_voice_bench.json and quits.
const Voice := preload("res://commons/void/inner_voice_godot.gd")
const PhonemeTimeline := preload("res://commons/void/phoneme_timeline.gd")
const PhonemeLibrary := preload("res://commons/void/phoneme_library.gd")
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
var keep_button: Button
var dry_compare: CheckButton
var earlier_compare: CheckButton
var hybrid_compare: CheckButton
var ab_row: HBoxContainer
var _ab_pending := ""
var timeline: PhonemeTimeline
var selected_phrase := ""
var phoneme_button: Button
var library_button: Button
var library: PhonemeLibrary
var _phonemes: Array = []
var _play_generation := 0
const RESTS := {"airway": {"formant_ratio": 1.0, "transpose": 0.0, "gain": 1.0, "air": 0.62, "flow_sharpness": 0.45},
	"phoneme": {"formant_ratio": 1.0, "transpose": 0.0, "gain": 1.0, "air": 0.62, "flow_sharpness": 0.45,
		"vocoder_mix": 0.23, "clarity": 0.55, "speed": 0.5},
	"model_b": {"formant_ratio": 1.12, "transpose": 0.0, "gain": 1.0, "air": 0.62, "flow_sharpness": 0.45},
	"robot": {"formant_ratio": 1.0, "transpose": 0.0, "gain": 0.35, "air": 0.62, "flow_sharpness": 0.45}}
const NEXT_VOICE := {"phoneme": "airway", "airway": "model_b", "model_b": "robot", "robot": "phoneme"}
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
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(395, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(scroll)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 7)
	scroll.add_child(right)
	_say(left, "MODEL B  ·  THE INNER VOICE", 26, PAPER)
	_say(left, "Made by Godot only, no native engine. Click a phrase or press its number.", 15, DIM)
	timeline = PhonemeTimeline.new()
	timeline.custom_minimum_size = Vector2(0, 146)
	left.add_child(timeline)
	var phrase_scroll := ScrollContainer.new()
	phrase_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	phrase_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(phrase_scroll)
	var phrase_list := VBoxContainer.new()
	phrase_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phrase_list.add_theme_constant_override("separation", 8)
	phrase_scroll.add_child(phrase_list)
	voice = Voice.new()
	voice.set("volume_db", 0.0)
	add_child(voice)
	voice.connect("rendered", _on_rendered)
	voice.connect("started", _on_started)
	voice.connect("finished", _on_finished)
	voice.connect("failed", func(id, message): _tell("NOT SUNG  %s:  %s" % [id, message]))
	var kept: Variant = JSON.parse_string(FileAccess.get_file_as_string(BINDINGS)) if FileAccess.file_exists(BINDINGS) else null
	if kept is Dictionary and RESTS.has(str(kept.get("renderer", ""))): renderer = str(kept.renderer)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--voice=") and RESTS.has(arg.trim_prefix("--voice=")): renderer = arg.trim_prefix("--voice=")
	var settings: Dictionary = kept.get("voice", {}) if kept is Dictionary and kept.get("renderer") == renderer else {}
	if renderer == "phoneme":
		settings = RESTS[renderer].duplicate()
		if OS.get_cmdline_user_args().has("--lj-hybrid"):
			settings["recorded_consonants"] = 0.75
	var number := 1
	var scores := SCORES.duplicate()
	if OS.get_cmdline_user_args().has("--listening-tests"):
		scores.push_front(["LISTENING TESTS · compare the consonants", "res://audio/voice_scores/lj_listening_20261117.json"])
	for group in scores:
		_say(phrase_list, "", 6, DIM)
		_say(phrase_list, str(group[0]), 15, HOT)
		var before: Array = (voice.get("order") as Array).duplicate()
		var wrong := str(voice.call("load_score", str(group[1]), settings, renderer))
		if not wrong.is_empty():
			_say(phrase_list, "cannot be used: " + wrong, 14, Color("ff6a5a"))
			continue
		for id in voice.get("order"):
			if before.has(id): continue
			var button := Button.new()
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			button.add_theme_font_size_override("font_size", 17)
			labels[id] = "%s   %s      —  %s" % [str(number) if number < 10 else ("0" if number == 10 else " "), str(voice.call("text_of", id)), str((voice.get("phrases") as Dictionary)[id].get("object_label", id))]
			button.text = labels[id] + "      (being made)"
			if voice.is_ready(str(id)):
				button.text = "%s      (%.1f s long, ready)" % [labels[id], float(voice.costs[id].length_s)]
			button.pressed.connect(_sing.bind(str(id)))
			phrase_list.add_child(button)
			buttons[id] = button
			number += 1
	if buttons.has("test_stops"):
		_show_phonemes("test_stops")
	elif buttons.has("letters"):
		_show_phonemes("letters")
	_say(right, "THE VOICE", 15, HOT)
	renderer_button = Button.new()
	renderer_button.add_theme_font_size_override("font_size", 15)
	renderer_button.pressed.connect(_other_voice)
	right.add_child(renderer_button)
	var rest: Dictionary = RESTS[renderer]
	ab_row = HBoxContainer.new()
	right.add_child(ab_row)
	_button(ab_row, "A · CURRENT", _compare_recorded.bind(false))
	_button(ab_row, "B · LJ HYBRID", _compare_recorded.bind(true))
	hybrid_compare = CheckButton.new()
	hybrid_compare.text = "LJ recorded consonants"
	hybrid_compare.set_pressed_no_signal(float(settings.get("recorded_consonants", 0.0)) > 0.0)
	hybrid_compare.toggled.connect(func(_enabled): _retune())
	right.add_child(hybrid_compare)
	_slider(right, "recorded_consonants", "Recorded consonant blend", 0.0, 1.0, 0.05, 0.75)
	_slider(right, "speed", "Singing speed · same pitch", 0.25, 1.0, 0.05, float(rest.get("speed", 1.0)))
	phoneme_button = _button(right, "HEAR EACH PHONEME", _hear_phonemes)
	library_button = _button(right, "EXPLORE THE FULL SOUND LIBRARY", func(): library.show_library(voice.options))
	earlier_compare = CheckButton.new()
	earlier_compare.text = "Compare earlier articulation"
	earlier_compare.toggled.connect(func(_enabled): _retune())
	right.add_child(earlier_compare)
	_slider(right, "vocoder_mix", "Vocoder blend", 0.0, 1.0, 0.01, float(rest.get("vocoder_mix", 0.0)))
	_slider(right, "clarity", "Consonant clarity", 0.0, 1.0, 0.01, float(rest.get("clarity", 0.0)))
	dry_compare = CheckButton.new()
	dry_compare.text = "Compare dry voice"
	dry_compare.toggled.connect(func(_enabled): _retune())
	right.add_child(dry_compare)
	_slider(right, "formant_ratio", "size of the voice  (formants)", 0.8, 1.3, 0.02, float(settings.get("formant_ratio", rest.formant_ratio)))
	_slider(right, "transpose", "pitch, in semitones", -12.0, 12.0, 1.0, float(settings.get("transpose", rest.transpose)))
	_slider(right, "gain", "level out of the renderer", 0.1, 1.5, 0.05, float(settings.get("gain", rest.gain)))
	_slider(right, "air", "breath  (Model B and Phoneme Library)", 0.0, 1.0, 0.02, float(settings.get("air", rest.air)))
	_slider(right, "flow_sharpness", "edge  (Model B and Phoneme Library)", 0.0, 1.0, 0.05, float(settings.get("flow_sharpness", rest.flow_sharpness)))
	_button(right, "MAKE ALL AGAIN WITH THESE", _retune)
	_button(right, "SING ALL, IN ORDER", _sing_all)
	_button(right, "STOP", _stop_playback)
	keep_button = _button(right, "KEEP THESE FOR THE TOWER", _keep)
	_name_voice()
	_say(right, "", 6, DIM)
	status = _say(right, "making the phrases, one at a time, off the window's thread", 15, PAPER)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_say(right, "A / B sings the selected phrase at matched loudness, using the same notes and timing. LJ adds 17 recorded bursts / fricatives; vowels and 7 resonant consonants stay synthesized. Sliders apply with MAKE ALL AGAIN or A / B.", 13, DIM).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	library = PhonemeLibrary.new()
	library.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	library.offset_left = 20
	library.offset_top = 20
	library.offset_right = -20
	library.offset_bottom = -20
	library.opened.connect(_stop_playback)
	add_child(library)
	if OS.get_cmdline_user_args().has("--sound-library"):
		library.show_library.call_deferred(voice.options)
	if checking and voice.streams.size() == buttons.size():
		_report.call_deferred()


func _say(parent: Control, text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


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
		if readouts.has(key):
			var value := str(snappedf((sliders[key] as HSlider).value, 0.01))
			if key == "speed":
				value = "%.2f×" % (sliders[key] as HSlider).value
			(readouts[key] as Label).text = "%s   %s" % [str((sliders[key] as HSlider).get_meta("title")), value]


func _settings() -> Dictionary:
	var out := {"formant_ratio": snappedf((sliders["formant_ratio"] as HSlider).value, 0.01), "transpose": (sliders["transpose"] as HSlider).value, "gain": snappedf((sliders["gain"] as HSlider).value, 0.01)}
	if renderer == "airway": out.erase("formant_ratio")          # a body has its own size: only pitch and level are the bench's to change
	if renderer in ["model_b", "phoneme"]:
		out["air"] = snappedf((sliders["air"] as HSlider).value, 0.01)
		out["flow_sharpness"] = snappedf((sliders["flow_sharpness"] as HSlider).value, 0.01)
	if renderer == "phoneme":
		out["individual_tuning"] = not earlier_compare.button_pressed
		if hybrid_compare.button_pressed:
			out["recorded_consonants"] = snappedf((sliders["recorded_consonants"] as HSlider).value, 0.01)
		out["speed"] = snappedf((sliders["speed"] as HSlider).value, 0.01)
		for key in ["vocoder_mix", "clarity"]:
			out[key] = 0.0 if dry_compare.button_pressed else snappedf((sliders[key] as HSlider).value, 0.01)
	return out


func _name_voice() -> void:
	renderer_button.text = {"phoneme": "PHONEME LIBRARY  ·  click for AIRWAY", "airway": "AIRWAY  ·  click for MODEL B",
		"model_b": "MODEL B  ·  click for ROBOT", "robot": "ROBOT  ·  click for PHONEME LIBRARY"}[renderer]
	var effects := renderer == "phoneme"
	for key in ["speed", "vocoder_mix", "clarity", "recorded_consonants"]:
		(sliders[key] as HSlider).visible = effects
		(readouts[key] as Label).visible = effects
	dry_compare.visible = effects
	earlier_compare.visible = effects
	hybrid_compare.visible = effects
	ab_row.visible = effects
	phoneme_button.visible = effects
	library_button.visible = effects
	keep_button.disabled = effects
	timeline.visible = effects


## The other voice, at its own resting settings; everything is made again.
func _other_voice() -> void:
	renderer = NEXT_VOICE[renderer]
	for key in sliders: (sliders[key] as HSlider).value = float(RESTS[renderer].get(key, 0.0))
	dry_compare.set_pressed_no_signal(false)
	earlier_compare.set_pressed_no_signal(false)
	hybrid_compare.set_pressed_no_signal(false)
	(sliders["recorded_consonants"] as HSlider).value = 0.75
	var kept: Variant = JSON.parse_string(FileAccess.get_file_as_string(BINDINGS))
	if kept is Dictionary and kept.get("renderer") == renderer and kept.get("voice") is Dictionary:
		for key in sliders:
			if kept.voice.has(key):
				(sliders[key] as HSlider).value = float(kept.voice[key])
	_name_voice()
	_retune()


func _tell(text: String) -> void:
	if status != null: status.text = text


func _show_phonemes(id: String) -> void:
	selected_phrase = id
	if renderer == "phoneme":
		var phrases: Dictionary = voice.get("phrases")
		var options: Dictionary = voice.get("options")
		timeline.show_phrase(phrases[id].voice_plan, float(options.get("formant_ratio", 1.0)), float(options.get("speed", 1.0)), bool(options.get("individual_tuning", true)))


func _on_started(id: String, text: String) -> void:
	_show_phonemes(id)
	_tell("singing:  %s" % text)


func _process(_delta: float) -> void:
	if timeline == null or renderer != "phoneme":
		return
	var frame: int = voice.call("playback_frame")
	timeline.following = frame >= 0
	if timeline.following:
		timeline.set_frame(frame)


func _sing(id: String) -> void:
	_stop_playback()
	voice.volume_db = 0.0
	_show_phonemes(id)
	if not bool(voice.call("is_ready", id)):
		_tell("'%s' is still being made" % id)
		return
	voice.call("sing", id)


func _sing_all() -> void:
	_stop_playback()
	singing_all.assign(voice.get("order"))
	_next_of_all()


func _stop_playback() -> void:
	_ab_pending = ""
	voice.volume_db = 0.0
	_play_generation += 1
	singing_all.clear()
	_phonemes.clear()
	voice.call("stop")


func _hear_phonemes() -> void:
	if selected_phrase.is_empty() or not bool(voice.call("is_ready", selected_phrase)):
		_tell("The selected phrase is still being made.")
		return
	_stop_playback()
	_show_phonemes(selected_phrase)
	var plan: Dictionary = timeline.get("_plan")
	_phonemes = plan.phones.duplicate()
	_next_phoneme()


func _next_phoneme() -> void:
	var phone: Dictionary = _phonemes.pop_front()
	if not bool(voice.call("sing_frames", selected_phrase, int(phone.start), int(phone.end))):
		_phonemes.clear()
		_tell("This phrase could not be played in parts.")
		return
	_tell("Sound %s · %s" % [str(phone.phoneme), str(voice.call("text_of", selected_phrase))])


func _next_of_all() -> void:
	while not singing_all.is_empty():
		var id: String = singing_all.pop_front()
		if bool(voice.call("is_ready", id)):
			voice.call("sing", id)
			return


func _on_finished(_id: String) -> void:
	var generation := _play_generation
	if not _phonemes.is_empty():
		await get_tree().create_timer(0.22).timeout
		if generation == _play_generation and not _phonemes.is_empty():
			_next_phoneme()
		return
	if singing_all.is_empty():
		_tell("ready")
		return
	await get_tree().create_timer(0.7).timeout
	if generation == _play_generation:
		_next_of_all()


func _on_rendered(id: String, seconds: float, cached: bool) -> void:
	if buttons.has(id):
		var length: float = float((voice.get("costs") as Dictionary)[id].length_s)
		(buttons[id] as Button).text = "%s      (%.1f s long, %s)" % [labels[id], length, "kept from before" if cached else "made in %.1f s" % seconds]
	if _ab_pending == id:
		_play_comparison(id)
	if (voice.get("streams") as Dictionary).size() == buttons.size():
		_tell("all %d phrases are ready" % buttons.size())
		if checking: _report()
		elif OS.get_cmdline_user_args().has("--sing-all") and singing_all.is_empty(): _sing_all.call_deferred()      # sung once, unasked, when ready


func _retune() -> void:
	_stop_playback()
	var wrong := str(voice.call("retune", _settings(), renderer))
	if not wrong.is_empty():
		_tell("these settings cannot be used: " + wrong)
		return
	if not selected_phrase.is_empty():
		_show_phonemes(selected_phrase)
		voice.prepare_phrase(voice.phrases[selected_phrase])
	for id in buttons:
		if not bool(voice.call("is_ready", id)): (buttons[id] as Button).text = labels[id] + "      (being made)"
	if (voice.get("streams") as Dictionary).size() == buttons.size():
		_tell("All phrases are ready.")
	else:
		_tell("Making phrases with the current settings.")


func _compare_recorded(enabled: bool) -> void:
	if renderer != "phoneme" or selected_phrase.is_empty(): return
	hybrid_compare.set_pressed_no_signal(enabled)
	_retune()
	_ab_pending = selected_phrase
	if voice.is_ready(selected_phrase):
		_play_comparison(selected_phrase)
	else:
		_tell("Preparing %s for the selected phrase…" % ("LJ hybrid" if enabled else "current synthesis"))


func _play_comparison(id: String) -> void:
	_ab_pending = ""
	var stream: AudioStreamWAV = voice.streams[id]
	var bytes := stream.data
	var energy := 0.0
	var peak := 0.0
	var count := bytes.size() / 2
	for i in count:
		var sample := bytes.decode_s16(i * 2) / 32768.0
		energy += sample * sample
		peak = maxf(peak, absf(sample))
	var rms := sqrt(energy / maxi(1, count))
	# Match whole-phrase RMS with a peak guard; the renderer remains untouched.
	var level := minf(0.08 / maxf(rms, 0.000001), 0.8 / maxf(peak, 0.000001))
	voice.volume_db = linear_to_db(level)
	voice.sing(id)
	_tell("%s · matched loudness · %s" % ["B / LJ HYBRID" if hybrid_compare.button_pressed else "A / CURRENT", voice.text_of(id)])


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
		if library.visible:
			library.close_library()
			get_viewport().set_input_as_handled()
			return
		get_tree().quit()
		return
	if library.visible:
		return
	var index := -1
	if key.keycode >= KEY_1 and key.keycode <= KEY_9: index = key.keycode - KEY_1
	elif key.keycode == KEY_0: index = 9
	var ids: Array = buttons.keys()
	if index >= 0 and index < ids.size(): _sing(str(ids[index]))
