extends Node3D

# Vowel Sound Board - Simplified
# Allows selecting speech phrases directly in the Godot Inspector.

@onready var mapper = $ValueMapper3D
@onready var synth = $VowelSynth3D
@onready var label_word = $LabelWord

# --- Editor Selection ---
@export_enum("None", "Ada", "Research", "I Love You", "Right Here Right Now", "Funk", "Hello World", "Right About Now", "Soul Brother", "Check It Out", "Rockafeller", "Alphabet") var phrase_selection: String = "Ada"
@export var is_ambient_enabled: bool = true
@export var repeat_interval: float = 3.0

# Field Constraints (Matches Vowels.json / Theory)
const F1_MIN = 200.0
const F1_MAX = 900.0
const DELTA_MIN = 200.0
const DELTA_MAX = 2200.0

# Anchors for Patterns (F1, Delta)
const ANCHORS = {
	"i": Vector2(240, 2160),
	"e": Vector2(390, 1910),
	"a": Vector2(850, 760),
	"o": Vector2(360, 280),
	"u": Vector2(250, 345),
	"r": Vector2(450, 750), # Approx
	"d_locus": Vector2(200, 1600) # Locus
}

# Playback State
var is_playing_sequence: bool = false
var _time_elapsed: float = 0.0

func _ready() -> void:
	# Configure Mapper Range
	mapper.output_x_min = DELTA_MIN
	mapper.output_x_max = DELTA_MAX
	mapper.output_y_min = F1_MIN
	mapper.output_y_max = F1_MAX
	mapper.output_z_min = 0.0
	mapper.output_z_max = 1.0
	
	mapper.values_changed.connect(_on_mapper_changed)
	
	# Initial UI State
	label_word.text = ""
	
	# Visuals
	_spawn_visual_anchors()
	
	# Start Background Loop
	_start_ambient_loop()

func apply_grid_config(data: Dictionary) -> void:
	# Support for grid-level overrides
	if data.has("say"):
		is_ambient_enabled = false
		var phrase = str(data["say"]).to_lower()
		var should_repeat = str(data.get("repeat", "false")).to_lower() == "true"
		
		var cleaned = phrase.replace(",", "").replace(".", "").replace("!", "").replace("?", "").replace(" ", "")
		
		# Delay slightly to ensure everything is ready
		await get_tree().create_timer(1.0).timeout
		
		if should_repeat:
			while not is_ambient_enabled:
				await play_word(cleaned)
				await get_tree().create_timer(repeat_interval).timeout
		else:
			await play_word(cleaned)

func _start_ambient_loop() -> void:
	await get_tree().create_timer(1.0).timeout
	while true:
		if not is_inside_tree(): return
		if not is_ambient_enabled: 
			await get_tree().create_timer(1.0).timeout
			continue
			
		if phrase_selection != "None":
			# Map enum name to word key
			var word_key = phrase_selection.to_lower().replace(" ", "")
			await play_word(word_key)
			await get_tree().create_timer(repeat_interval).timeout
		else:
			await get_tree().create_timer(1.0).timeout

func play_word(word: String, pitch: float = 130.0) -> void:
	if is_playing_sequence: return
	is_playing_sequence = true
	label_word.text = word
	synth.pulse_hz = pitch
	
	match word.to_lower():
		"ada": await _play_ada()
		"research": await _play_research()
		"iloveyou": await _play_iloveyou()
		"alphabet": await _play_alphabet()
		"righthererightnow": await _play_right_here_right_now()
		"funk": await _play_funk()
		"helloworld": await _play_hello_world()
		"rightaboutnow": await _play_right_about_now()
		"soulbrother": await _play_soul_brother()
		"checkitout": await _play_check_it_out()
		"rockafeller": await _play_rockafeller()
	
	is_playing_sequence = false

# --- Speech Unit Implementations ---

func _play_ada() -> void:
	_set_mapper_pos(ANCHORS["a"], 0.0)
	await get_tree().create_timer(0.1).timeout
	_tween_mapper(ANCHORS["a"], 1.0, 0.1)
	await get_tree().create_timer(0.4).timeout
	_tween_mapper(ANCHORS["d_locus"], 0.0, 0.08)
	await get_tree().create_timer(0.08).timeout
	_tween_mapper(ANCHORS["a"], 1.0, 0.05)
	await get_tree().create_timer(0.4).timeout
	_tween_mapper(ANCHORS["a"], 0.0, 0.1)
	await get_tree().create_timer(0.2).timeout
	synth.stop()

func _play_research() -> void:
	_set_mapper_pos(ANCHORS["r"], 0.0)
	_tween_mapper(ANCHORS["r"], 0.9, 0.1)
	await get_tree().create_timer(0.2).timeout
	_tween_mapper(ANCHORS["i"], 1.0, 0.2)
	await get_tree().create_timer(0.3).timeout
	_tween_mapper(ANCHORS["i"], 0.0, 0.1)
	await get_tree().create_timer(0.15).timeout
	_set_mapper_pos(ANCHORS["e"], 0.0)
	_tween_mapper(ANCHORS["e"], 1.0, 0.1)
	await get_tree().create_timer(0.2).timeout
	_tween_mapper(ANCHORS["r"], 1.0, 0.2)
	await get_tree().create_timer(0.2).timeout
	_tween_mapper(ANCHORS["r"], 0.0, 0.05)
	await get_tree().create_timer(0.1).timeout
	synth.stop()

func _play_iloveyou() -> void:
	_set_mapper_pos(ANCHORS["a"], 0.0)
	label_word.text = "I"
	_tween_mapper(ANCHORS["a"], 1.0, 0.1)
	await get_tree().create_timer(0.3).timeout
	_tween_mapper(ANCHORS["i"], 1.0, 0.2)
	await get_tree().create_timer(0.3).timeout
	_tween_mapper(ANCHORS["i"], 0.0, 0.2)
	await get_tree().create_timer(0.25).timeout
	label_word.text = "Love"
	var pos_l = Vector2(800, 400)
	_set_mapper_pos(pos_l, 0.0)
	_tween_mapper(pos_l, 1.0, 0.1)
	await get_tree().create_timer(0.2).timeout
	_tween_mapper(ANCHORS["a"], 1.0, 0.2)
	await get_tree().create_timer(0.3).timeout
	_tween_mapper(ANCHORS["i"], 0.0, 0.2)
	await get_tree().create_timer(0.2).timeout
	label_word.text = "You"
	_set_mapper_pos(ANCHORS["i"], 0.0)
	_tween_mapper(ANCHORS["i"], 1.0, 0.1)
	await get_tree().create_timer(0.15).timeout
	_tween_mapper(ANCHORS["u"], 1.0, 0.3)
	await get_tree().create_timer(0.8).timeout
	_tween_mapper(ANCHORS["u"], 0.0, 0.5)
	await get_tree().create_timer(0.5).timeout
	synth.stop()

func _play_right_here_right_now() -> void:
	await _play_right()
	await get_tree().create_timer(0.2).timeout
	await _play_here()
	await get_tree().create_timer(0.3).timeout
	await _play_right()
	await get_tree().create_timer(0.2).timeout
	await _play_now()
	synth.stop()

func _play_right() -> void:
	_set_mapper_pos(ANCHORS["r"], 0.0)
	_tween_mapper(ANCHORS["r"], 0.8, 0.1)
	await get_tree().create_timer(0.15).timeout
	_tween_mapper(ANCHORS["a"], 1.0, 0.1)
	await get_tree().create_timer(0.1).timeout
	_tween_mapper(ANCHORS["i"], 1.0, 0.15)
	await get_tree().create_timer(0.15).timeout
	synth.trigger_plosive("t")
	_tween_mapper(ANCHORS["i"], 0.0, 0.03) # FAST fade during closure
	await get_tree().create_timer(0.2).timeout

func _play_here() -> void:
	synth.trigger_fricative("h", 100)
	await get_tree().create_timer(0.05).timeout
	_set_mapper_pos(ANCHORS["i"], 0.0)
	_tween_mapper(ANCHORS["i"], 0.9, 0.1)
	await get_tree().create_timer(0.2).timeout
	_tween_mapper(ANCHORS["a"], 0.7, 0.15)
	await get_tree().create_timer(0.15).timeout
	_tween_mapper(ANCHORS["r"], 0.8, 0.1)
	await get_tree().create_timer(0.2).timeout
	_tween_mapper(ANCHORS["r"], 0.0, 0.1)

func _play_now() -> void:
	synth.trigger_nasal("n", 150)
	await get_tree().create_timer(0.1).timeout
	_set_mapper_pos(ANCHORS["a"], 0.0)
	_tween_mapper(ANCHORS["a"], 1.0, 0.1)
	await get_tree().create_timer(0.2).timeout
	_tween_mapper(ANCHORS["u"], 1.0, 0.2)
	await get_tree().create_timer(0.4).timeout
	_tween_mapper(ANCHORS["u"], 0.0, 0.2)
	await get_tree().create_timer(0.2).timeout
	synth.stop()

func _play_funk() -> void:
	synth.trigger_fricative("f", 120)
	await get_tree().create_timer(0.08).timeout
	_set_mapper_pos(ANCHORS["a"], 0.0)
	_tween_mapper(ANCHORS["a"], 1.0, 0.1)
	await get_tree().create_timer(0.25).timeout
	synth.trigger_nasal("ng", 150)
	await get_tree().create_timer(0.15).timeout
	synth.trigger_plosive("k")
	_tween_mapper(ANCHORS["a"], 0.0, 0.03) # FAST fade
	await get_tree().create_timer(0.2).timeout
	synth.stop()

func _play_hello_world() -> void:
	synth.trigger_fricative("h", 100)
	await get_tree().create_timer(0.05).timeout
	_tween_mapper(ANCHORS["e"], 1.0, 0.2)
	await get_tree().create_timer(0.3).timeout
	_tween_mapper(ANCHORS["r"], 0.8, 0.2) # /l/
	await get_tree().create_timer(0.3).timeout
	_tween_mapper(ANCHORS["o"], 1.0, 0.3)
	await get_tree().create_timer(0.5).timeout
	_tween_mapper(ANCHORS["o"], 0.0, 0.2)
	await get_tree().create_timer(0.3).timeout
	_set_mapper_pos(ANCHORS["u"], 0.0) # /w/
	_tween_mapper(ANCHORS["u"], 1.0, 0.1)
	await get_tree().create_timer(0.2).timeout
	_tween_mapper(ANCHORS["r"], 0.9, 0.3)
	await get_tree().create_timer(0.4).timeout
	synth.trigger_plosive("d")
	_tween_mapper(ANCHORS["r"], 0.0, 0.03) # FAST fade
	await get_tree().create_timer(0.2).timeout
	synth.stop()

func _play_right_about_now() -> void:
	await _play_right()
	await get_tree().create_timer(0.1).timeout
	await _play_about()
	await get_tree().create_timer(0.1).timeout
	await _play_now()
	synth.stop()

func _play_about() -> void:
	_tween_mapper(ANCHORS["a"], 0.7, 0.1)
	await get_tree().create_timer(0.1).timeout
	synth.trigger_plosive("b")
	await get_tree().create_timer(0.05).timeout
	_tween_mapper(ANCHORS["u"], 0.9, 0.15)
	await get_tree().create_timer(0.15).timeout
	synth.trigger_plosive("t")
	_tween_mapper(ANCHORS["u"], 0.0, 0.03) # FAST fade
	await get_tree().create_timer(0.1).timeout

func _play_soul_brother() -> void:
	synth.trigger_fricative("s", 120)
	await get_tree().create_timer(0.08).timeout
	_tween_mapper(ANCHORS["o"], 1.0, 0.25)
	await get_tree().create_timer(0.25).timeout
	_tween_mapper(ANCHORS["r"], 0.7, 0.15)
	await get_tree().create_timer(0.15).timeout
	_tween_mapper(ANCHORS["r"], 0.0, 0.1)
	await get_tree().create_timer(0.2).timeout
	synth.trigger_plosive("b")
	await get_tree().create_timer(0.05).timeout
	_tween_mapper(ANCHORS["r"], 0.8, 0.15)
	await get_tree().create_timer(0.15).timeout
	_tween_mapper(ANCHORS["a"], 0.9, 0.1)
	await get_tree().create_timer(0.1).timeout
	synth.trigger_fricative("th", 80)
	await get_tree().create_timer(0.08).timeout
	synth.trigger_plosive("t")
	_tween_mapper(ANCHORS["r"], 0.8, 0.1)
	await get_tree().create_timer(0.2).timeout
	_tween_mapper(ANCHORS["r"], 0.0, 0.1)
	await get_tree().create_timer(0.1).timeout
	synth.stop()

func _play_check_it_out() -> void:
	synth.trigger_affricate("ch")
	await get_tree().create_timer(0.15).timeout
	_set_mapper_pos(ANCHORS["e"], 1.0); await get_tree().create_timer(0.2).timeout
	synth.trigger_plosive("k");
	_tween_mapper(ANCHORS["e"], 0.0, 0.03); await get_tree().create_timer(0.2).timeout
	_set_mapper_pos(ANCHORS["i"], 1.0); await get_tree().create_timer(0.15).timeout
	synth.trigger_plosive("t");
	_tween_mapper(ANCHORS["i"], 0.0, 0.03); await get_tree().create_timer(0.2).timeout
	_set_mapper_pos(ANCHORS["a"], 1.0); await get_tree().create_timer(0.15).timeout
	_tween_mapper(ANCHORS["u"], 1.0, 0.2); await get_tree().create_timer(0.3).timeout
	_tween_mapper(ANCHORS["u"], 0.0, 0.1)
	await get_tree().create_timer(0.2).timeout
	synth.stop()

func _play_rockafeller() -> void:
	await _play_right_about_now()
	await get_tree().create_timer(0.2).timeout
	var old_pitch = synth.pulse_hz
	synth.pulse_hz = 160.0
	await _play_funk()
	synth.pulse_hz = old_pitch
	await get_tree().create_timer(0.1).timeout
	await _play_soul_brother()
	await get_tree().create_timer(0.2).timeout
	await _play_check_it_out()
	await get_tree().create_timer(0.1).timeout
	await _play_now()
	synth.stop()

func _play_alphabet() -> void:
	# 1. Vowels
	var vowels = ["i", "e", "a", "o", "u"]
	for v in vowels:
		_set_mapper_pos(ANCHORS[v], 0.0)
		label_word.text = "/ " + v + " /"
		_tween_mapper(ANCHORS[v], 1.0, 0.1)
		await get_tree().create_timer(0.4).timeout
		_tween_mapper(ANCHORS[v], 0.0, 0.1)
		await get_tree().create_timer(0.1).timeout
	
	# 2. fricatives
	var fricatives = ["s", "z", "f", "v", "sh", "th", "h"]
	_set_mapper_pos(ANCHORS["e"], 0.0) # Background neutral vowel
	for f in fricatives:
		label_word.text = "/ " + f + " /"
		synth.trigger_fricative(f, 200)
		await get_tree().create_timer(0.4).timeout
	
	# 3. plosives
	var plosives = ["p", "b", "t", "d", "k", "g"]
	for p in plosives:
		label_word.text = "/ " + p + " /"
		synth.trigger_plosive(p)
		await get_tree().create_timer(0.4).timeout
	
	# 4. Nasals
	var nasals = ["m", "n", "ng"]
	for n in nasals:
		label_word.text = "/ " + n + " /"
		_tween_mapper(ANCHORS["a"], 0.8, 0.1)
		synth.trigger_nasal(n, 150)
		await get_tree().create_timer(0.3).timeout
		_tween_mapper(ANCHORS["a"], 0.0, 0.1)
		await get_tree().create_timer(0.2).timeout
		
	synth.stop()

# --- Internal Core ---

func _on_mapper_changed(delta_val: float, f1_val: float, intensity_val: float) -> void:
	synth.f1 = f1_val
	synth.delta = delta_val
	synth.target_intensity = intensity_val
	synth.is_speaking = (intensity_val > 0.01)

func _set_mapper_pos(target_field: Vector2, target_intensity: float) -> void:
	mapper.set_values(target_field.y, target_field.x, target_intensity)

func _tween_mapper(target_field: Vector2, target_intensity: float, duration: float) -> void:
	var tween = create_tween()
	var start_val = mapper.get_values()
	var update_lambda = func(val: float):
		var cur_delta = lerp(start_val.x, target_field.y, val)
		var cur_f1 = lerp(start_val.y, target_field.x, val)
		var cur_int = lerp(start_val.z, target_intensity, val)
		mapper.set_values(cur_delta, cur_f1, cur_int)
	tween.tween_method(update_lambda, 0.0, 1.0, duration)
	await tween.finished

func _spawn_visual_anchors() -> void:
	# Simple coordinate labels in the graph
	for vowel in ANCHORS:
		var coords = ANCHORS[vowel]
		var norm_x = (coords.y - DELTA_MIN) / (DELTA_MAX - DELTA_MIN)
		var norm_y = (coords.x - F1_MIN) / (F1_MAX - F1_MIN)
		var pos = Vector3(norm_x * mapper.space_size.x, norm_y * mapper.space_size.y, mapper.space_size.z * 0.5)
		
		var viz = Label3D.new()
		viz.text = "/" + vowel + "/"
		viz.font_size = 24
		viz.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		viz.position = pos + Vector3(0.05, -0.05, 0)
		viz.scale = Vector3.ONE * 0.08
		mapper.add_child(viz)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

