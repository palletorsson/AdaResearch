extends SceneTree
const Voice := preload("res://audio/generators/PhonemeVoice.gd")
const Library := preload("res://commons/void/phoneme_library.gd")
const Robot := preload("res://audio/generators/RobotVoiceGenerator.gd")
const Bank := preload("res://audio/generators/LJConsonants.gd")
const OUT := "C:/Users/palle/Documents/GitHub/AdaResearch_46/ada_run/phoneme-desktop/lj-hybrid/"
var rows := []

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT + "renders")
	var bank := Bank.new(1.0)
	assert(bank.samples.size() == 17)
	var options := {"speed": 1.0, "vocoder_mix": 0.23, "clarity": 0.55}
	for bad in [-0.01, 1.01, INF, NAN, "yes"]:
		assert(not Voice.validate_plan(Library.demo_plan("vowel", "a"), {"recorded_consonants": bad}).is_empty())
	for kind: String in ["vowel", "consonant"]:
		var table: Dictionary = Robot.VOWELS if kind == "vowel" else Robot.LOCUS
		for code: String in table:
			var plan := Library.demo_plan(kind, code)
			var current := Voice.render_phrase(plan, options)
			var hybrid := options.duplicate()
			hybrid["recorded_consonants"] = 1.0
			var mixed := Voice.render_phrase(plan, hybrid)
			check_save(kind + "_" + code, mixed, plan.frames)
			if kind == "vowel" or not Bank.COVERED.has(code):
				assert(current == mixed, "Pitch-bearing sounds must remain identical: " + code)
			else:
				assert(current != mixed, "Recording must affect " + code)
			if code in ["a", "i", "s", "p", "zh"]:
				var old := AudioStreamWAV.load_from_file(OUT + "../individual-20261116/after/" + kind + "_" + code + ".wav")
				assert(old != null and pcm_bytes(current) == old.data, "Default changed: " + kind + code)
	for path in ["res://audio/voice_scores/tower_roof_20261116.json", "res://audio/voice_scores/chimera_inner_opera_20261116.json"]:
		var score: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		for phrase: Dictionary in score.phrases:
			var hybrid := options.duplicate()
			hybrid["recorded_consonants"] = 0.75
			check_save("phrase_" + str(phrase.object_id), Voice.render_phrase(phrase.voice_plan, hybrid), phrase.voice_plan.frames)
			if phrase.object_id == "letters":
				check_save("compare_current", Voice.render_phrase(phrase.voice_plan, options), phrase.voice_plan.frames)
				var slow := hybrid.duplicate()
				slow["speed"] = 0.5
				check_save("compare_hybrid_slow", Voice.render_phrase(phrase.voice_plan, slow), phrase.voice_plan.frames * 2)
	var transpose := {"recorded_consonants": 1.0, "speed": 0.25, "transpose": 12.0}
	var stop := Library.demo_plan("consonant", "t")
	check_save("slow_transposed_t", Voice.render_phrase(stop, transpose), stop.frames * 4)
	var file := FileAccess.open(OUT + "render-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(rows, "  "))
	print("LJ HYBRID PASS: 17 recordings loaded; 40 sounds + 11 phrases; sustained vowels and 7 resonants identical; default regression; slow/transposed; finite/unclipped")
	quit()

func pcm_bytes(pcm: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(pcm.size() * 2)
	for i in pcm.size(): bytes.encode_s16(i * 2, roundi(pcm[i] * 32767.0))
	return bytes

func check_save(id: String, pcm: PackedFloat32Array, frames: int) -> void:
	assert(pcm.size() == frames)
	var peak := 0.0
	var energy := 0.0
	for sample in pcm:
		assert(is_finite(sample))
		peak = maxf(peak, absf(sample))
		energy += sample * sample
	assert(peak > 0.001 and peak < 1.0)
	assert(absf(pcm[0]) < 0.00001 and absf(pcm[-1]) < 0.00001)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 44100
	wav.data = pcm_bytes(pcm)
	assert(wav.save_to_wav(OUT + "renders/" + id + ".wav") == OK)
	rows.append({"id": id, "frames": frames, "peak": peak, "rms": sqrt(energy / frames)})
	print("CHECKED ", id)
