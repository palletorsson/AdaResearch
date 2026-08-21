extends SceneTree
## THE LO-FI BED, proven: exact loop arithmetic (282,240 frames = four 75 BPM
## bars at 22050 Hz), LOOP_FORWARD end-to-end, deterministic twice over.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var fails: Array = []
	var r = EmAudio.Rig.new()
	var t0 := Time.get_ticks_msec()
	var a: AudioStreamWAV = r._build_lofi()
	var ms := Time.get_ticks_msec() - t0
	var frames: int = a.data.size() / 2
	if frames != 282240:
		fails.append("loop is %d frames, the arithmetic says 282240" % frames)
	if a.loop_mode != AudioStreamWAV.LOOP_FORWARD or a.loop_end != frames:
		fails.append("loop mode/end wrong")
	var r2 = EmAudio.Rig.new()
	var b: AudioStreamWAV = r2._build_lofi()
	if a.data != b.data:
		fails.append("two builds differ — the seed is not the law")
	var f := FileAccess.open("res://ada_run/lofi_probe.txt", FileAccess.WRITE)
	f.store_string(("PASS %d ms" % ms) if fails.is_empty() else "FAIL: " + "; ".join(fails))
	f.close()
	print("LOFI: " + (("PASS — %.1f s loop in %d ms, deterministic" % [frames / 22050.0, ms]) if fails.is_empty() else "FAIL"))
	r.free()
	r2.free()
	quit(0 if fails.is_empty() else 1)
