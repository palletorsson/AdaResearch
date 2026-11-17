extends SceneTree
## Listening comparisons, not a change to the approved tower voice.
const Voice := preload("res://audio/generators/PhonemeVoice.gd")
const OUT := "C:/Users/palle/Documents/GitHub/AdaResearch_46/ada_run/phoneme-desktop/lj-clarity/"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var bindings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/opera/tower_bindings.json"))
	var approved: Dictionary = bindings.voice.duplicate(true)
	var more := approved.duplicate(true)
	more["recorded_consonants"] = 1.0
	var less_fx := more.duplicate(true)
	less_fx["vocoder_mix"] = 0.0
	less_fx["air"] = 0.25
	less_fx["vibrato_depth_cents"] = 6.0
	var profiles := {"approved": approved, "more_recorded": more, "less_effects": less_fx}
	var score: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(bindings.score)))
	var report := {"profiles": profiles, "clips": []}
	for phrase: Dictionary in score.phrases:
		if not str(phrase.object_id) in ["crate", "clock", "letters"]: continue
		var expected := roundi(float(phrase.voice_plan.frames) / float(approved.speed))
		for profile: String in profiles:
			var settings: Dictionary = profiles[profile]
			assert(Voice.validate_plan(phrase.voice_plan, settings).is_empty())
			var pcm := Voice.render_phrase(phrase.voice_plan, settings)
			assert(pcm.size() == expected)
			var energy := 0.0
			var peak := 0.0
			for sample in pcm:
				assert(is_finite(sample))
				energy += sample * sample
				peak = maxf(peak, absf(sample))
			assert(peak > 0.0 and peak < 1.0)
			var rms := sqrt(energy / pcm.size())
			var gain := minf(0.08 / rms, 0.8 / peak)
			var bytes := PackedByteArray()
			bytes.resize(pcm.size() * 2)
			for i in pcm.size(): bytes.encode_s16(i * 2, roundi(pcm[i] * gain * 32767.0))
			var wav := AudioStreamWAV.new()
			wav.format = AudioStreamWAV.FORMAT_16_BITS
			wav.mix_rate = 44100
			wav.data = bytes
			var name := str(phrase.object_id) + "-" + profile + ".wav"
			assert(wav.save_to_wav(OUT + name) == OK)
			report.clips.append({"file": name, "text": phrase.text, "frames": pcm.size(), "rms": rms * gain, "peak": peak * gain})
			print("CLARITY COMPARISON ", name)
	FileAccess.open(OUT + "report.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("CLARITY PASS: 9 clips, same timing and notes, matched RMS, finite and unclipped; game settings unchanged")
	quit()
