extends Node
## MODEL B'S INNER VOICE, MADE BY GODOT (Palle, 2026-11-16: "it has to run on the quest as a voice stream, no
## rust ... must be godot based")
##
## One voice, in the head: a plain AudioStreamPlayer, no position, no room. It sings the phrases of a voice score
## (res://audio/voice_scores/*.json, the handover kit's format: an authored plan of timed phonemes with a note
## each). The sound is made by the kit's own sample-free renderer in GDScript,
## res://audio/generators/RobotVoiceGenerator.gd - no native library, no recording, no service. That renderer is
## not the kit's approved Chimera voice (which is the Rust engine): it is the kit's robot voice, drier and more
## machine. Said plainly so nobody takes one for the other.
##
## GDScript makes every sample in a loop, so a phrase costs real time: about as long as the phrase on a PC and
## several times that on the headset. Nothing is rendered on the game's thread. Phrases are rendered one at a time
## on a worker thread, in the order asked, as soon as the score is loaded - which is while the opening is still
## black - and each is kept: in memory for this run, and as raw samples under user://inner_voice/ for the next
## one, under a name made from the plan and the settings, so a changed phrase is rendered again and an unchanged
## one never is.
##
## sing(id) sounds a phrase that is ready. If it is not ready yet it is moved to the front of the line and sounds
## when it lands, unless the wait has been longer than LATE seconds: a thought that arrives after the look has
## gone is dropped, not sung late.
signal started(object_id: String, text: String)
signal finished(object_id: String)
signal failed(object_id: String, message: String)
signal rendered(object_id: String, seconds: float, from_cache: bool)

## Godot renderers: the physical Airway, Model B's formant voice, the kit's Robot
## and the desktop pilot that uses formants measured from the Airway model.
const RENDERERS := {"airway": preload("res://audio/generators/AirwayVoice.gd"), "model_b": preload("res://audio/generators/ModelBVoice.gd"),
	"phoneme": preload("res://audio/generators/PhonemeVoice.gd"),
	"robot": preload("res://audio/generators/RobotVoiceGenerator.gd")}
const VERSION := "gd-3"
const RATE := 44100
const CACHE := "user://inner_voice/"
## Renders that travel with the game (made on a PC by the bench's KEEP, as .wav so an export carries them): looked in
## first, so a headset need not make a phrase the slow voice takes minutes over.
const SHIPPED := "res://audio/voice_cache/"
const LATE := 2.5

@export var volume_db := -6.0

var phrases := {}                         # object id -> the phrase of the score
var order: Array[String] = []
var options := {}                         # the renderer's own settings
var renderer_name := "model_b"
var score_id := ""
var streams := {}                         # object id -> AudioStreamWAV
var costs := {}                           # object id -> {"seconds": render time, "cached": bool, "length_s": ...}
var _player: AudioStreamPlayer
var _line: Array[String] = []
var _task := -1
var _task_for := ""
var _task_began := 0
var _generation := 0                      # raised by retune(): a render begun under older settings is not kept
var _task_generation := 0
var _lock := Mutex.new()
var _landed := PackedByteArray()
var _wanted := ""
var _wanted_since := 0.0
var _sounding := ""
var _playback_offset := 0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "InTheHead"
	_player.volume_db = volume_db
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)
	_player.finished.connect(_on_player_finished)


## "" when the score can be used, otherwise why not. Every phrase is put in line to be rendered.
func load_score(path: String, renderer_options: Dictionary = {}, renderer := "") -> String:
	if not renderer.is_empty():
		if not RENDERERS.has(renderer): return "no renderer called " + renderer
		renderer_name = renderer
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or not parsed.get("phrases") is Array: return "not a phrase document: " + path
	options = renderer_options.duplicate()
	score_id = str(parsed.get("id", path.get_file().get_basename()))
	for phrase in parsed.phrases:
		if not phrase is Dictionary or str(phrase.get("object_id", "")).is_empty() or not phrase.get("voice_plan") is Dictionary:
			return "a phrase without an object_id or a voice_plan in " + path
		var wrong: String = RENDERERS[renderer_name].validate_plan(phrase.voice_plan, options)
		if not wrong.is_empty(): return "%s: %s" % [str(phrase.object_id), wrong]
		phrases[str(phrase.object_id)] = phrase
		order.append(str(phrase.object_id))
	for id in order: _want_rendered(id)
	return ""


## Other settings for the renderer (formant_ratio 0.8-1.3, transpose in semitones, gain): everything is made again.
## "" when they can be used, otherwise why not; then nothing changes.
func retune(renderer_options: Dictionary, renderer := "") -> String:
	var with_renderer: String = renderer_name if renderer.is_empty() else renderer
	if not RENDERERS.has(with_renderer): return "no renderer called " + with_renderer
	for id in order:
		var wrong: String = RENDERERS[with_renderer].validate_plan(phrases[id].voice_plan, renderer_options)
		if not wrong.is_empty(): return wrong
	stop()
	renderer_name = with_renderer
	options = renderer_options.duplicate()
	_generation += 1
	streams.clear()
	costs.clear()
	_line.clear()
	for id in order: _want_rendered(id)
	return ""


func has_object(object_id: String) -> bool:
	return phrases.has(object_id)


## The desktop sound library prepares only the examples the listener requests.
## Existing entries are immutable here; retune() handles changed renderer settings.
func prepare_phrase(phrase: Dictionary) -> String:
	var id := str(phrase.get("object_id", ""))
	if id.is_empty() or not phrase.get("voice_plan") is Dictionary:
		return "A phrase needs an object_id and a voice_plan"
	var wrong: String = RENDERERS[renderer_name].validate_plan(phrase.voice_plan, options)
	if not wrong.is_empty():
		return wrong
	if phrases.has(id):
		if phrases[id] != phrase:
			return "A different phrase already uses " + id
	else:
		phrases[id] = phrase.duplicate(true)
		order.append(id)
	_want_rendered(id)
	# An explicitly requested audition takes priority over earlier queued sounds.
	if _line.has(id):
		_line.erase(id)
		_line.push_front(id)
	return ""


func text_of(object_id: String) -> String:
	return str(phrases.get(object_id, {}).get("text", ""))


func is_sounding() -> bool:
	return not _sounding.is_empty()


func playback_frame() -> int:
	if _sounding.is_empty():
		return -1
	var time := _player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	return _playback_offset + clampi(roundi(time * RATE), 0, roundi(_player.stream.get_length() * RATE))


func is_ready(object_id: String) -> bool:
	return streams.has(object_id)


## Sound a thought. True if it sounds now; false if it is still being made (it sounds when it lands, if soon).
func sing(object_id: String) -> bool:
	if not phrases.has(object_id):
		failed.emit(object_id, "no thought for " + object_id)
		return false
	if is_sounding(): return false
	if streams.has(object_id):
		_sound(object_id)
		return true
	_wanted = object_id
	_wanted_since = 0.0
	_line.erase(object_id)
	_line.push_front(object_id)
	return false


## Listen to one scored phoneme from an already-rendered phrase in the desktop bench.
func sing_frames(object_id: String, first: int, last: int) -> bool:
	var source: Variant = streams.get(object_id)
	if is_sounding() or not source is AudioStreamWAV:
		return false
	if source.format != AudioStreamWAV.FORMAT_16_BITS or source.stereo or source.mix_rate != RATE:
		return false
	if first < 0 or last <= first or last * 2 > source.data.size():
		return false
	var samples: PackedByteArray = source.data.slice(first * 2, last * 2)
	# A one-millisecond edge removes clicks caused by cutting inside a voiced cycle.
	var edge := mini(44, (last - first) / 2)
	for frame in edge:
		var gain := float(frame) / edge
		var tail := last - first - 1 - frame
		samples.encode_s16(frame * 2, roundi(samples.decode_s16(frame * 2) * gain))
		samples.encode_s16(tail * 2, roundi(samples.decode_s16(tail * 2) * gain))
	var segment := AudioStreamWAV.new()
	segment.format = AudioStreamWAV.FORMAT_16_BITS
	segment.mix_rate = RATE
	segment.data = samples
	_sound(object_id, segment, first)
	return true


func stop() -> void:
	_wanted = ""
	if _sounding.is_empty(): return
	var was := _sounding
	_sounding = ""
	_player.stop()
	finished.emit(was)


func _sound(object_id: String, segment: AudioStreamWAV = null, offset := 0) -> void:
	_wanted = ""
	_sounding = object_id
	_playback_offset = offset
	_player.stream = streams[object_id] if segment == null else segment
	_player.volume_db = volume_db
	_player.play()
	started.emit(object_id, text_of(object_id))


func _on_player_finished() -> void:
	var was := _sounding
	_sounding = ""
	if not was.is_empty(): finished.emit(was)


## ---- making the sound: off the game's thread, kept for next time ----

func _key(object_id: String) -> String:
	var phrase: Dictionary = phrases[object_id]
	var version := VERSION
	if renderer_name == "phoneme" and bool(options.get("individual_tuning", true)):
		version += "-individual-1"
	if renderer_name == "phoneme" and float(options.get("recorded_consonants", 0.0)) > 0.0:
		version += "-lj-consonants-1"
	if float(options.get("vocoder_mix", 0.0)) > 0.0 or float(options.get("clarity", 0.0)) > 0.0:
		version += "-vocoder-2"
	# by the thing and by what is sung how, not by the score file: the bench and the tower then share one render
	return "%s_%s" % [object_id, (version + renderer_name + JSON.stringify(phrase.voice_plan) + JSON.stringify(options)).sha1_text().substr(0, 16)]


func _want_rendered(object_id: String) -> void:
	if streams.has(object_id) or _line.has(object_id) or _task_for == object_id: return
	var shipped := SHIPPED + _key(object_id) + ".wav"
	if ResourceLoader.exists(shipped):
		# in an export (and wherever the editor has imported it) the wav is a resource
		var made: Resource = load(shipped)
		if made is AudioStream:
			streams[object_id] = made
			costs[object_id] = {"seconds": 0.0, "cached": true, "shipped": true, "length_s": (made as AudioStream).get_length()}
			rendered.emit(object_id, 0.0, true)
			return
	elif FileAccess.file_exists(shipped):
		# not imported (a run straight from the project folder): the file's own samples, 16-bit mono
		var file_bytes := FileAccess.get_file_as_bytes(shipped)
		var at := 12
		while at + 8 <= file_bytes.size():
			var size := file_bytes.decode_u32(at + 4)
			if file_bytes.slice(at, at + 4).get_string_from_ascii() == "data":
				_keep(object_id, file_bytes.slice(at + 8, mini(at + 8 + size, file_bytes.size())), 0.0, true)
				costs[object_id]["shipped"] = true
				return
			at += 8 + size + (size & 1)
	for folder in [CACHE]:
		var kept := str(folder) + _key(object_id) + ".s16"
		if not FileAccess.file_exists(kept): continue
		var bytes := FileAccess.get_file_as_bytes(kept)
		# a render is at least the phrase long (the airway voice adds a lead and a release)
		if bytes.size() >= int(phrases[object_id].voice_plan.frames) * 2 and bytes.size() % 2 == 0:
			_keep(object_id, bytes, 0.0, true)
			return
	_line.append(object_id)


func _keep(object_id: String, bytes: PackedByteArray, seconds: float, from_cache: bool) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	streams[object_id] = stream
	costs[object_id] = {"seconds": seconds, "cached": from_cache, "length_s": float(bytes.size() / 2) / RATE}
	rendered.emit(object_id, seconds, from_cache)


## On a worker thread. Everything it touches is its own, except the bytes it leaves under the lock.
func _render(plan: Dictionary, renderer_options: Dictionary, renderer: GDScript) -> void:
	var pcm: PackedFloat32Array = renderer.render_phrase(plan, renderer_options)
	var bytes := PackedByteArray()
	bytes.resize(pcm.size() * 2)
	for i in pcm.size(): bytes.encode_s16(i * 2, int(clampf(pcm[i], -1.0, 1.0) * 32767.0))
	_lock.lock()
	_landed = bytes
	_lock.unlock()


func _process(delta: float) -> void:
	if not _wanted.is_empty():
		_wanted_since += delta
		if _wanted_since > LATE:
			var late := _wanted
			_wanted = ""
			failed.emit(late, "not ready within %.1f s; not sung late" % LATE)
	if _task >= 0:
		if not WorkerThreadPool.is_task_completed(_task): return
		WorkerThreadPool.wait_for_task_completion(_task)          # a finished task is only released by being waited for
		_task = -1
		var id := _task_for
		_task_for = ""
		_lock.lock()
		var bytes := _landed
		_landed = PackedByteArray()
		_lock.unlock()
		var seconds: float = float(Time.get_ticks_msec() - _task_began) / 1000.0
		if _task_generation != _generation:
			_want_rendered(id)               # made under settings that have since changed: not kept, made again
		elif bytes.is_empty():
			if _wanted == id: _wanted = ""
			failed.emit(id, "the renderer returned nothing")
		else:
			DirAccess.make_dir_recursive_absolute(CACHE)
			var file := FileAccess.open(CACHE + _key(id) + ".s16", FileAccess.WRITE)
			if file != null:
				file.store_buffer(bytes)
				file.close()
			_keep(id, bytes, seconds, false)
			if _wanted == id and not is_sounding(): _sound(id)
	if _task < 0 and not _line.is_empty():
		_task_for = _line.pop_front()
		_task_began = Time.get_ticks_msec()
		_task_generation = _generation
		var plan: Dictionary = (phrases[_task_for].voice_plan as Dictionary).duplicate(true)
		_task = WorkerThreadPool.add_task(_render.bind(plan, options.duplicate(), RENDERERS[renderer_name]), false, "Model B's inner voice")


func _exit_tree() -> void:
	if _task >= 0: WorkerThreadPool.wait_for_task_completion(_task)
