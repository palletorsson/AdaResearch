extends SceneTree
## Render a voice score to WAV files with one of the Godot renderers, to be measured (tools/probes/voice_compare.py)
## or listened to. Nothing is played.
##
##   godot --headless --audio-driver Dummy --path . --script res://tools/probes/render_voice.gd --
##       --score=res://audio/voice_scores/chimera_inner_opera_20261116.json --renderer=robot|model_b|airway|phoneme [--only=<object_id>]
##       --out=<dir> [--options={"formant_ratio":1.12}]
##
## <dir>/<object_id>.wav (16-bit mono 44.1 kHz) and <dir>/render.json: per phrase the seconds it took, its length,
## its peak.
func _initialize() -> void:
	var score := ""
	var which := "model_b"
	var out := ""
	var only := ""
	var options := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--score="): score = arg.trim_prefix("--score=")
		if arg.begins_with("--renderer="): which = arg.trim_prefix("--renderer=")
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--only="): only = arg.trim_prefix("--only=")
		if arg.begins_with("--options="): options = JSON.parse_string(arg.trim_prefix("--options="))
	DirAccess.make_dir_recursive_absolute(out)
	var renderers := {"robot": "res://audio/generators/RobotVoiceGenerator.gd", "airway": "res://audio/generators/AirwayVoice.gd",
		"model_b": "res://audio/generators/ModelBVoice.gd", "phoneme": "res://audio/generators/PhonemeVoice.gd"}
	if not renderers.has(which):
		push_error("Unknown renderer " + which)
		quit(1)
		return
	var renderer: GDScript = load(renderers[which])
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(score))
	var report := {"renderer": which, "options": options, "phrases": {}}
	for phrase in parsed.phrases:
		if only != "" and str(phrase.object_id) != only: continue
		var began := Time.get_ticks_msec()
		var pcm: PackedFloat32Array = renderer.render_phrase(phrase.voice_plan, options)
		var seconds := float(Time.get_ticks_msec() - began) / 1000.0
		var bytes := PackedByteArray()
		bytes.resize(pcm.size() * 2)
		var peak := 0.0
		for i in pcm.size():
			peak = maxf(peak, absf(pcm[i]))
			bytes.encode_s16(i * 2, int(clampf(pcm[i], -1.0, 1.0) * 32767.0))
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = 44100
		wav.data = bytes
		wav.save_to_wav(out.path_join(str(phrase.object_id) + ".wav"))
		report.phrases[str(phrase.object_id)] = {"made_in_s": seconds, "length_s": float(pcm.size()) / 44100.0, "peak": peak}
		print("[render_voice] %s %s: %.2f s for %.2f s, peak %.3f" % [which, str(phrase.object_id), seconds, float(pcm.size()) / 44100.0, peak])
	var file := FileAccess.open(out.path_join("render.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	quit()
