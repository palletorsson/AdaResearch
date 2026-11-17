extends SceneTree
var bench: Control
const OUT := "C:/Users/palle/Documents/GitHub/AdaResearch_46/ada_run/phoneme-desktop/lj-hybrid/"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	AudioServer.set_bus_mute(0, true)
	bench = preload("res://commons/void/inner_voice_bench.tscn").instantiate()
	root.add_child(bench)
	await process_frame
	assert(bench.renderer == "phoneme")
	bench.sliders.speed.value = 1.0
	bench._show_phonemes("letters")
	bench._compare_recorded(false)
	await comparison_ready()
	var current: PackedByteArray = bench.voice.streams.letters.data.duplicate()
	var loud_a := output_rms()
	bench._compare_recorded(true)
	await comparison_ready()
	var hybrid: PackedByteArray = bench.voice.streams.letters.data.duplicate()
	var loud_b := output_rms()
	assert(current.size() == hybrid.size() and current != hybrid)
	assert(absf(loud_a - loud_b) < 0.0001)
	assert(bench.voice.options.recorded_consonants == 0.75)
	# Cached A/B and rapid changes must settle on the requested version.
	bench._compare_recorded(false)
	bench._compare_recorded(true)
	await comparison_ready()
	assert(bench.voice.streams.letters.data == hybrid)
	bench._stop_playback()
	bench.timeline.set_frame(22000)
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(OUT + "desktop-hybrid.png") == OK)
	bench.library.show_library(bench.voice.options)
	assert(bench.library.hybrid.button_pressed)
	bench.library.audition("consonant", "sh")
	await library_ready()
	var recorded: PackedByteArray = bench.library.voice.streams.library_consonant_sh.data.duplicate()
	bench.library.hybrid.button_pressed = false
	await library_ready()
	assert(recorded != bench.library.voice.streams.library_consonant_sh.data)
	bench.library.hybrid.button_pressed = true
	await library_ready()
	bench.library.voice.stop()
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(OUT + "library-hybrid.png") == OK)
	bench.library.close_library()
	bench._compare_recorded(false)
	await comparison_ready()
	assert(bench.voice.streams.letters.data == current)
	bench._stop_playback()
	print("LJ UI PASS: A/B changes audio, preserves duration, matches RMS %.6f / %.6f; rapid toggles preserve newest; library toggle works; current restored" % [loud_a, loud_b])
	quit()

func comparison_ready() -> void:
	var until := Time.get_ticks_msec() + 55000
	while not bench._ab_pending.is_empty() and Time.get_ticks_msec() < until: await process_frame
	assert(bench._ab_pending.is_empty(), "Comparison timed out")
	assert(bench.voice.is_sounding())

func library_ready() -> void:
	var until := Time.get_ticks_msec() + 30000
	while not bench.library._requested.is_empty() and Time.get_ticks_msec() < until: await process_frame
	assert(bench.library._requested.is_empty())
	assert(bench.library.voice.is_sounding())

func output_rms() -> float:
	var bytes: PackedByteArray = bench.voice.streams.letters.data
	var energy := 0.0
	for i in bytes.size() / 2:
		var value := bytes.decode_s16(i * 2) / 32768.0
		energy += value * value
	return sqrt(energy / (bytes.size() / 2)) * db_to_linear(bench.voice.volume_db)
