extends SceneTree
## Run in the isolated audio fixture after ship_voice and ship_opera_music.
const Opera := preload("res://commons/void/inner_opera.gd")
class Content extends RefCounted:
	var data := {"floors": [{"map": "Point_Zero"}, {"map": "OutsideVoiceChapters"}]}
	var exhibits := {}
	var props := {}
class Building extends RefCounted:
	var content := Content.new()
class Stream extends RefCounted:
	var focus := 0
class Game extends Node3D:
	var building := Building.new()
	var floor_stream := Stream.new()
	var checkpoint := 0
	var ready_for_play := true
	var body: Node3D
	var charge_display: Node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game := Game.new()
	root.add_child(game)
	var opera := Opera.new()
	game.add_child(opera)
	opera.set_physics_process(false)
	var music = opera.music
	assert(music != null and music.prepared)
	music.set_process(false)
	assert(opera.voice.streams.size() == opera.voice.order.size() and opera.voice.order.size() >= 5 and opera.voice._line.is_empty())
	for id in opera.voice.order: assert(opera.voice.costs[id].get("shipped", false))
	assert(opera.voice_options.recorded_consonants == 1.0 and opera.voice_options.vocoder_mix == 0.0)
	assert(opera.voice_options.air == 0.25 and opera.voice_options.vibrato_depth_cents == 6.0)
	assert(music.bed.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
	assert(music.bed.stream.data.size() == music.pulse.stream.data.size())
	assert(music.bed.playing and music.pulse.playing)
	opera._physics_process(2.1)
	music._process(1.5)
	assert(music.active and is_equal_approx(music.bed.volume_db, -8.0))
	assert(opera.voice.sing("clock"))
	assert(music.singing)
	music._process(0.9)
	assert(is_equal_approx(music.bed.volume_db, -5.0) and is_equal_approx(music.pulse.volume_db, -9.0))
	await opera.voice.finished
	await process_frame # Let the audio finished signal finish unwinding.
	assert(not music.singing)
	music._process(3.0)
	assert(is_equal_approx(music.bed.volume_db, -8.0) and is_equal_approx(music.pulse.volume_db, -28.0))
	game.floor_stream.focus = 1
	opera._physics_process(0.1)
	music._process(1.5)
	assert(not music.active and music.bed.volume_db == -80.0)
	game.floor_stream.focus = 0
	opera._physics_process(0.1)
	music._process(1.5)
	opera.quiet = true
	opera._physics_process(0.1)
	assert(music.bed.volume_db == -80.0 and music.pulse.volume_db == -80.0)
	music.set_singing(true)
	opera.voice.failed.emit("clock", "fixture failure")
	assert(not music.singing)
	game.queue_free()
	await create_timer(0.2).timeout # Allow the mixer to release stopped loop playbacks.
	print("OPERA_MUSIC PASS: version 3; all active phrases shipped; aligned loops; actual singing raises score; natural finish releases; floor exit and quiet mute; failure clears lift; teardown clean")
	quit()
