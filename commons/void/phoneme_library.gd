extends PanelContainer
## A truthful inventory of the desktop prototype, separate from a phrase's events.
## Auditions use the current renderer, synthesize on demand, and share its cache.
signal opened

const Voice := preload("res://commons/void/inner_voice_godot.gd")
const Timeline := preload("res://commons/void/phoneme_timeline.gd")
const Phoneme := preload("res://audio/generators/PhonemeVoice.gd")
const Robot := preload("res://audio/generators/RobotVoiceGenerator.gd")
const Tuning := preload("res://audio/generators/PhonemeArticulation.gd")
const CONSONANTS := [
	["p", "pin"], ["b", "bin"], ["t", "tin"], ["d", "din"], ["k", "cat"], ["g", "go"],
	["f", "fan"], ["v", "van"], ["th", "thin"], ["dh", "this"], ["s", "sip"], ["z", "zip"],
	["sh", "ship"], ["zh", "measure"], ["h", "hat"], ["ch", "chin"], ["j", "gin"],
	["m", "map"], ["n", "nap"], ["ng", "sing"], ["l", "lip"], ["r", "red"], ["w", "wet"], ["y", "yes"]]

var voice: Node
var timeline: Control
var status: Label
var sound_buttons := {}
var _requested := ""
var earlier: CheckButton
var hybrid: CheckButton
var note: Label
var _kind := "vowel"
var _code := "a"


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("14171f")
	style.border_color = Color("454b5b")
	style.set_border_width_all(1)
	style.set_content_margin_all(20)
	add_theme_stylebox_override("panel", style)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	add_child(content)
	var heading := HBoxContainer.new()
	content.add_child(heading)
	var title := _label(heading, "THE SOUND LIBRARY", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := Button.new()
	close.text = "Back to phrases"
	close.pressed.connect(close_library)
	heading.add_child(close)
	_label(content, "English is often taught as about 44 phonemes: 24 consonants and 20 vowels / diphthongs. The count varies with accent. This prototype is still incomplete.")
	earlier = CheckButton.new()
	earlier.text = "Compare earlier articulation · off = individually tuned"
	earlier.toggled.connect(_compare)
	content.add_child(earlier)
	hybrid = CheckButton.new()
	hybrid.text = "LJ hybrid · recorded consonants with singing synthesis"
	hybrid.toggled.connect(_hybrid)
	content.add_child(hybrid)
	timeline = Timeline.new()
	content.add_child(timeline)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var sounds := VBoxContainer.new()
	sounds.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sounds.add_theme_constant_override("separation", 10)
	scroll.add_child(sounds)
	_label(sounds, "%d consonant recipes · click to hear between two /a/ vowels" % Robot.LOCUS.size(), 16)
	var consonants := HFlowContainer.new()
	sounds.add_child(consonants)
	for item in CONSONANTS:
		var code := str(item[0])
		var symbol := Phoneme.display_symbol("consonant", code) if code != "zh" else "ʒ"
		_add_sound(consonants, "consonant", code, "%s · %s" % [symbol, item[1]], not Robot.LOCUS.has(code))
	_label(sounds, "%d vowel / resonant targets · click to sustain a sound" % Robot.VOWELS.size(), 16)
	var vowels := HFlowContainer.new()
	sounds.add_child(vowels)
	for code: String in Robot.VOWELS:
		_add_sound(vowels, "vowel", code, "%s  [%s]" % [Phoneme.display_symbol("vowel", code), code])
	_label(sounds, "Targets are not a phoneme count: r and er share /ɝ/, l uses a lateral approximation, and /y ø œ/ are extra non-English vowel colours. The measured table has 22 vowel postures; only a subset is wired to the score.", 13)
	_label(sounds, "/ʒ/ is now available. Complete English vowel and diphthong mapping remains unfinished. Only /a → ɪ/ and /a → u/ have dedicated long-glide rules today.", 13)
	note = _label(content, "Each target has its own tuning. Compare at the same singing settings.", 13)
	status = _label(content, "Choose a sound. Examples are made only when requested.")
	voice = Voice.new()
	voice.renderer_name = "phoneme"
	voice.volume_db = 0.0
	add_child(voice)
	voice.rendered.connect(_rendered)
	voice.finished.connect(func(_id): status.text = "Choose another sound, or return to the phrases.")
	voice.failed.connect(func(_id, message): status.text = message)
	hide()


func _label(parent: Node, text: String, font_size := 15) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _add_sound(parent: Node, kind: String, code: String, text: String, missing := false) -> void:
	var button := Button.new()
	button.text = text + (" · missing" if missing else "")
	button.custom_minimum_size = Vector2(94, 32)
	button.disabled = missing
	button.tooltip_text = "Not implemented in this prototype" if missing else "%s target · score code %s" % [kind, code]
	button.pressed.connect(audition.bind(kind, code))
	parent.add_child(button)
	sound_buttons[kind + ":" + code] = button


func show_library(settings: Dictionary) -> void:
	opened.emit()
	_requested = ""
	voice.stop()
	earlier.set_pressed_no_signal(not bool(settings.get("individual_tuning", true)))
	hybrid.set_pressed_no_signal(float(settings.get("recorded_consonants", 0.0)) > 0.0)
	if voice.options != settings:
		var problem: String = voice.retune(settings, "phoneme")
		if not problem.is_empty():
			status.text = problem
	if _code == "zh" and earlier.button_pressed:
		_code = "sh"
	timeline.show_phrase(demo_plan(_kind, _code), float(settings.get("formant_ratio", 1.0)), float(settings.get("speed", 1.0)), not earlier.button_pressed)
	earlier.disabled = _code == "zh"
	show()


func _compare(enabled: bool) -> void:
	_requested = ""
	voice.stop()
	var options: Dictionary = voice.options.duplicate()
	options["individual_tuning"] = not enabled
	var problem: String = voice.retune(options, "phoneme")
	if not problem.is_empty():
		status.text = problem
		return
	audition(_kind, _code)


func _hybrid(enabled: bool) -> void:
	_requested = ""
	voice.stop()
	var options: Dictionary = voice.options.duplicate()
	if enabled: options["recorded_consonants"] = 0.75
	else: options.erase("recorded_consonants")
	var problem: String = voice.retune(options, "phoneme")
	if not problem.is_empty():
		status.text = problem
		return
	audition(_kind, _code)


func close_library() -> void:
	_requested = ""
	voice.stop()
	hide()


## Consonants are heard in context. A target is not a recording of a whole word.
static func demo_plan(kind: String, code: String) -> Dictionary:
	var phones := []
	var frames := 35280
	if kind == "vowel":
		phones.append({"kind": kind, "phoneme": code, "start": 0, "end": frames, "midi": 60})
	else:
		phones = [
			{"kind": "vowel", "phoneme": "a", "start": 0, "end": 11025, "midi": 60},
			{"kind": kind, "phoneme": code, "start": 11025, "end": 18081, "midi": 60},
			{"kind": "vowel", "phoneme": "a", "start": 18081, "end": frames, "midi": 60}]
	return {"frames": frames, "phones": phones,
		"syllables": [{"start": 0, "end": frames, "vowel": 0, "midi": 60, "gain": 0.9}],
		"word_groups": [{"start": 0, "end": frames}]}


func audition(kind: String, code: String) -> void:
	_requested = ""
	voice.stop()
	_kind = kind
	_code = code
	if code == "zh" and earlier.button_pressed:
		earlier.set_pressed_no_signal(false)
		var options: Dictionary = voice.options.duplicate()
		options["individual_tuning"] = true
		voice.retune(options, "phoneme")
	earlier.disabled = code == "zh"
	note.text = str(Tuning.NOTES.get(("consonant:" if kind == "consonant" else "") + code, ""))
	if hybrid.button_pressed:
		note.text += " LJ recorded noise + synthesized singing voice." if kind == "consonant" and Phoneme.Recorded.COVERED.has(code) else " This sound stays synthesized."
	if code == "zh": note.text += " New sound; no earlier recording to compare."
	var id := "library_" + kind + "_" + code
	var plan := demo_plan(kind, code)
	timeline.show_phrase(plan, float(voice.options.get("formant_ratio", 1.0)), float(voice.options.get("speed", 1.0)), bool(voice.options.get("individual_tuning", true)))
	_requested = id
	status.text = "Making /%s/…" % Phoneme.display_symbol(kind, code)
	var problem: String = voice.prepare_phrase({"object_id": id, "text": Phoneme.display_symbol(kind, code), "voice_plan": plan})
	if not problem.is_empty():
		_requested = ""
		status.text = problem
	elif _requested == id and voice.is_ready(id):
		_play(id)


func _rendered(id: String, _seconds: float, _cached: bool) -> void:
	if visible and _requested == id:
		_play(id)


func _play(id: String) -> void:
	_requested = ""
	status.text = "Listening to /%s/ · same singing settings as the phrase bench" % voice.text_of(id)
	voice.sing(id)


func _process(_delta: float) -> void:
	if voice == null or not visible:
		return
	var frame: int = voice.playback_frame()
	timeline.following = frame >= 0
	if timeline.following:
		timeline.set_frame(frame)
