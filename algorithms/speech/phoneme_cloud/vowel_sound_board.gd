extends Node3D

# Vowel Sound Board - Simplified
# Allows selecting speech phrases directly in the Godot Inspector.


# @identity
# essence: vowel(formant1, formant2) -> pulse_train filtered through formant resonances
# desire: Press buttons in VR to hear synthesized vowels and words assembled from phoneme chains
# critical_parameter: formant frequencies (F1, F2) — the two resonant peaks that define each vowel
# triggers: phrase selection triggers sequential phoneme playback with pitch interpolation
# emerges: recognizable speech from pure synthesis — words without a voice, language from mathematics
# needs: VR button press [has], phrase selection [has], ambient mode [has]
# relationships: depends on formant synthesis engine; contrasts with timbre_sculptor (speech vs musical timbre); unlocks the physics of voice
# truth: Every vowel is a pair of resonant frequencies — the mouth is a tunable resonator.

# --- STAGE-2 DNA (promoted 2026-08-05, by hand) -------------------------------
# ONE AXIS, AND IT IS ABOUT THE CHART, NOT THE TUNING.
#
# The @identity truth of this board is "every vowel is a pair of resonant
# frequencies — the mouth is a tunable resonator". That claim is a claim about a
# PLANE: F1 against F2 (here F1 against the F2−F1 delta the synth actually
# wants), the space every phonetics textbook draws. The board moves through that
# plane continuously — _tween_mapper interpolates between ANCHORS to make a word
# — and until now it drew almost none of it. `_spawn_visual_anchors()` hung seven
# billboarded phoneme labels at their coordinates and stopped. The space itself,
# the thing the truth statement is about, was never on screen: no figures, no
# bounding figure, no continuum. You could see WHERE /a/ is and never learn that
# "where" was a measurement.
#
# So `chart` asks what a vowel IS here, and the four alternatives are four real
# positions in phonetics, not four decorations:
#   anchors        the shipped build — a vowel is one of seven named landmarks,
#                  and the space between them is unmarked
#   none           the landmarks removed — an instrument that sounds a vowel and
#                  tells you nothing about where it lives
#   ticks          F1 and the delta ruled and numbered in Hz — a vowel is a
#                  MEASUREMENT, an acoustic fact with units
#   quadrilateral  the closed i–e–a–o–u figure — a vowel is a vertex of the
#                  canonical published diagram, and the diagram has an inside
#   field          a lattice over the whole plane — the named vowels are only the
#                  conventional stops on a continuum that does not have any
#
# WHY NOT A TUNING AXIS. The obvious knob is ANCHORS itself, or the F1/DELTA
# bounds: shift them and you get a child's vowel space, a soprano's, another
# language's. That is real, and it is a live argument about whose mouth counts as
# the reference. It is refused here for the reason resonating_metallophone was
# refused: it retunes the instrument, it does not change it. Every value would
# render as the same seven labels a few pixels apart.
#
# NOT PROMOTED, AND THIS IS THE LARGER HALF OF THE ARTIFACT: everything audible.
# repeat_interval, phrase_selection, pulse_hz, the whole phoneme chain, the
# plosive/fricative/nasal triggers. The evidence for a DNA axis is one still PNG
# per value and this board's real work is a time series of formant transitions.
# Twelve phrases would photograph as twelve identical boards. The sound stays an
# export.
# ------------------------------------------------------------------------------

@onready var mapper = $ValueMapper3D
@onready var synth = $VowelSynth3D
@onready var label_word = $LabelWord

# --- Editor Selection ---
@export_enum("None", "Ada", "Research", "I Love You", "Right Here Right Now", "Funk", "Hello World", "Right About Now", "Soul Brother", "Check It Out", "Rockafeller", "Alphabet") var phrase_selection: String = "Ada"
@export var is_ambient_enabled: bool = true
@export var repeat_interval: float = 3.0

## Allow-list. An unknown word from a map token keeps the shipped chart rather
## than blanking the board.
const CHARTS: PackedStringArray = ["anchors", "none", "ticks", "quadrilateral", "field"]

## How much of the formant plane is drawn. `anchors` is the shipped build: the
## seven phoneme labels and nothing else.
@export_enum("anchors", "none", "ticks", "quadrilateral", "field") var chart: String = "anchors"

## Colour for everything `chart` adds beyond the shipped labels.
@export var chart_color: Color = Color(0.45, 0.85, 1.0, 0.75)

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

# Everything _spawn_visual_anchors() put in the mapper, so a chart change can
# clear exactly what it drew and nothing else.
var _chart_parts: Array[Node3D] = []
var _built: bool = false

func _ready() -> void:
	_read_dna_meta()

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

	_built = true

## GridInteractablesComponent stamps `config_*` metadata on the ROOT before
## add_child, so this runs ahead of the build.
func _read_dna_meta() -> void:
	if has_meta("config_chart"):
		var c_in: String = str(get_meta("config_chart")).strip_edges().to_lower()
		chart = c_in if CHARTS.has(c_in) else chart

func apply_grid_config(data: Dictionary) -> void:
	# GATED THREE WAYS: the key must be present, the word must be one this board
	# knows, and the value must actually have CHANGED. Only then is anything
	# rebuilt, and only after _ready has drawn once — an unguarded rebuild here
	# would tear the chart off the four existing placements on any config call.
	if data.has("chart"):
		var c_in: String = str(data["chart"]).strip_edges().to_lower()
		if CHARTS.has(c_in) and c_in != chart:
			chart = c_in
			if _built:
				_rebuild_chart()

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
	# `none` is the only value that skips the shipped labels. Every other value
	# draws them exactly as before and then adds to them, so `anchors` — the
	# default — reaches the end of this loop and stops, node for node identical
	# to the build the four existing placements have always had.
	if chart == "none":
		return

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
		_chart_parts.append(viz)

	match chart:
		"ticks":
			_build_ticks()
		"quadrilateral":
			_build_quadrilateral()
		"field":
			_build_field()

## Mapper-local position of a point in the formant field. Same normalisation the
## anchor loop above uses — F1 up the Y axis, the F2−F1 delta across X.
func _field_point(f1_hz: float, delta_hz: float) -> Vector3:
	var norm_x: float = (delta_hz - DELTA_MIN) / (DELTA_MAX - DELTA_MIN)
	var norm_y: float = (f1_hz - F1_MIN) / (F1_MAX - F1_MIN)
	return Vector3(
		norm_x * mapper.space_size.x,
		norm_y * mapper.space_size.y,
		mapper.space_size.z * 0.5)

func _chart_material() -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = chart_color
	mat.emission_enabled = true
	mat.emission = chart_color
	mat.emission_energy_multiplier = 0.7
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

## A thin bar from a to b in mapper-local space. The basis is built by hand
## rather than with look_at, which needs the node to be in the tree already.
func _add_bar(a: Vector3, b: Vector3, thickness: float) -> void:
	var delta_v: Vector3 = b - a
	var length: float = delta_v.length()
	if length < 0.0005:
		return
	var fwd: Vector3 = delta_v / length
	var up: Vector3 = Vector3.UP
	if absf(fwd.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right: Vector3 = up.cross(fwd).normalized()
	var true_up: Vector3 = fwd.cross(right).normalized()

	var bar: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(thickness, thickness, length)
	bar.mesh = box
	bar.material_override = _chart_material()
	bar.transform = Transform3D(Basis(right, true_up, fwd), (a + b) * 0.5)
	mapper.add_child(bar)
	_chart_parts.append(bar)

func _add_figure(text: String, pos: Vector3) -> void:
	var fig: Label3D = Label3D.new()
	fig.text = text
	fig.font_size = 20
	fig.modulate = chart_color
	fig.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	fig.position = pos
	fig.scale = Vector3.ONE * 0.06
	mapper.add_child(fig)
	_chart_parts.append(fig)

## `ticks` — the two axes ruled and numbered in Hz. A vowel becomes a reading.
func _build_ticks() -> void:
	var t: float = mapper.space_size.x * 0.05
	var deltas: Array[float] = [400.0, 1000.0, 1600.0, 2200.0]
	for d_hz in deltas:
		var p: Vector3 = _field_point(F1_MIN, d_hz)
		_add_bar(p, p + Vector3(0.0, -t, 0.0), 0.005)
		_add_figure(str(int(d_hz)), p + Vector3(0.0, -t * 2.0, 0.0))
	var f1s: Array[float] = [300.0, 500.0, 700.0, 900.0]
	for f_hz in f1s:
		var q: Vector3 = _field_point(f_hz, DELTA_MIN)
		_add_bar(q, q + Vector3(-t, 0.0, 0.0), 0.005)
		_add_figure(str(int(f_hz)), q + Vector3(-t * 2.2, 0.0, 0.0))
	_add_figure("F2-F1 (Hz)", _field_point(F1_MIN, (DELTA_MIN + DELTA_MAX) * 0.5) + Vector3(0.0, -t * 3.4, 0.0))
	_add_figure("F1 (Hz)", _field_point((F1_MIN + F1_MAX) * 0.5, DELTA_MIN) + Vector3(-t * 4.0, 0.0, 0.0))

## `quadrilateral` — the closed i–e–a–o–u figure of the published vowel chart.
## The claim is that the cardinal vowels BOUND a region, and the region has an
## inside the board can be in.
func _build_quadrilateral() -> void:
	var ring: Array[String] = ["i", "e", "a", "o", "u"]
	for idx in range(ring.size()):
		var here: Vector2 = ANCHORS[ring[idx]]
		var next: Vector2 = ANCHORS[ring[(idx + 1) % ring.size()]]
		_add_bar(_field_point(here.x, here.y), _field_point(next.x, next.y), 0.007)

## `field` — a lattice over the whole plane. The named vowels are stops on a
## continuum, and the continuum is what is actually there.
func _build_field() -> void:
	var divisions: int = 6
	var z: float = mapper.space_size.z * 0.5
	for step in range(divisions + 1):
		var frac: float = float(step) / float(divisions)
		var x: float = frac * mapper.space_size.x
		var y: float = frac * mapper.space_size.y
		_add_bar(Vector3(x, 0.0, z), Vector3(x, mapper.space_size.y, z), 0.004)
		_add_bar(Vector3(0.0, y, z), Vector3(mapper.space_size.x, y, z), 0.004)

## Frees exactly what _spawn_visual_anchors() drew, then redraws. Reached only
## from apply_grid_config, and only when the word actually changed.
func _rebuild_chart() -> void:
	for part in _chart_parts:
		if is_instance_valid(part):
			part.queue_free()
	_chart_parts.clear()
	_spawn_visual_anchors()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

