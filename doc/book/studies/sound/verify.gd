extends "res://supplied/verify_tools.gd"
## Headless checks of the Sound kit. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; the exit code is the number of
## checks that failed. No import step is needed: nothing here has a class_name.
## Nobody listens in this file. What it can know of a sound is (1) the numbers
## in the buffer and (2) what reached Godot's mixer: an AudioEffectCapture on
## the Master bus keeps the mixed samples, and from them come the loudest level
## and how much of each tone is in the mix. Headless Godot mixes with its Dummy
## driver, in real time, so the listening waits are counted in real
## milliseconds. Headless draws no frames and reads no bead back from a
## MultiMesh: what the eye gets is measured by sheet.gd, with a window.

const Look := preload("res://supplied/look.gd")
const CheckGuest := preload("res://supplied/check_guest.gd")
const Chord := preload("res://chord.gd")
const RATE := 44100
const VALUES := ["1:1", "2:1", "3:2", "45:32"]
const HIGH := {"1:1": 256.0, "2:1": 512.0, "3:2": 384.0, "45:32": 360.0}
const TONES := [256.0, 360.0, 384.0, 512.0]   # every tone a chord of this kit can hold

var ear: AudioEffectCapture   # on the Master bus: what reached the mixer

func world() -> Node3D:
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	await frames(2)
	return base

func close(node: Node) -> void:
	node.free()
	await frames(1)

func chord(ratio: String, member := 0) -> Node3D:
	var body := Node3D.new()
	body.set_script(Chord)
	body.ratio = ratio
	body.member = member
	return body

func walker_in(base: Node3D, at: Vector3) -> CharacterBody3D:
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = at      # before add_child: a body is in the room from the step it is added
	walker.through_eyes = true   # its Eyes are the camera, and Godot listens from the camera
	base.add_child(walker)
	await physics_frames(20)
	return walker

func flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

func text_of(path: String) -> String:
	return FileAccess.get_file_as_string(path)

func wait_ms(ms: int) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < ms:
		await process_frame

## The samples of a 16-bit buffer, and the loudest of them.
func loudest(data: PackedByteArray) -> int:
	var most := 0
	for i in data.size() / 2:
		most = maxi(most, absi(data.decode_s16(i * 2)))
	return most

## The largest step from one sample to the next inside a buffer.
func largest_step(data: PackedByteArray) -> int:
	var most := 0
	for i in range(1, data.size() / 2):
		most = maxi(most, absi(data.decode_s16(i * 2) - data.decode_s16(i * 2 - 2)))
	return most

## The step from the last sample back to the first: what a loop plays at its seam.
func seam(data: PackedByteArray) -> int:
	return absi(data.decode_s16(0) - data.decode_s16(data.size() - 2))

## One second of one tone, written as the lesson writes it: `scaled` is the
## repaired line, without it the wave is handed to encode_s16() as it is.
func one_tone(hz: float, scaled: bool) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(RATE * 2)
	for i in range(RATE):
		var t := float(i) / RATE
		var wave := sin(TAU * hz * t)
		if scaled:
			data.encode_s16(i * 2, int(wave * 32767.0))
		else:
			data.encode_s16(i * 2, wave)
	return data

func stream_of(data: PackedByteArray, looped: bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = RATE
	return stream

## How much of one tone is in a run of mixed samples: its amplitude, where a
## sine that fills the whole range is 1. A Goertzel filter under a Hann window.
func tone_in(mixed: PackedVector2Array, hz: float) -> float:
	if mixed.size() < 2:
		return 0.0
	var coefficient := 2.0 * cos(TAU * hz / AudioServer.get_mix_rate())
	var s1 := 0.0
	var s2 := 0.0
	var count := mixed.size()
	for i in count:
		var window := 0.5 - 0.5 * cos(TAU * i / (count - 1))
		var s := (mixed[i].x + mixed[i].y) * 0.5 * window + coefficient * s1 - s2
		s2 = s1
		s1 = s
	return 4.0 * sqrt(maxf(s1 * s1 + s2 * s2 - coefficient * s1 * s2, 0.0)) / count

## Listens to the Master bus for `ms` thousandths of a second, after letting
## a change settle: {"db": the loudest level of either side, "left_db",
## "right_db", and for each tone of TONES how much of it was in the mix}.
func hear(ms := 350, list: Array = TONES) -> Dictionary:
	await wait_ms(250)
	ear.clear_buffer()
	var left := -200.0
	var right := -200.0
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < ms:
		await process_frame
		left = maxf(left, AudioServer.get_bus_peak_volume_left_db(0, 0))
		right = maxf(right, AudioServer.get_bus_peak_volume_right_db(0, 0))
	var mixed := ear.get_buffer(ear.get_frames_available())
	var out := {"db": snappedf(maxf(left, right), 0.1), "left_db": snappedf(left, 0.1), "right_db": snappedf(right, 0.1)}
	for hz: float in list:
		out[str(int(hz))] = snappedf(tone_in(mixed, hz), 0.001)
	return out

## Which of the tones listened for are in what was heard: more than 0.03 of full range.
func tones(heard: Dictionary, list: Array = TONES) -> Array:
	var out := []
	for hz: float in list:
		if heard[str(int(hz))] > 0.03:
			out.append(int(hz))
	return out

func run() -> void:
	ear = AudioEffectCapture.new()
	ear.buffer_length = 1.0
	AudioServer.add_bus_effect(0, ear)
	measured["audio_driver"] = AudioServer.get_driver_name()
	measured["mix_rate"] = AudioServer.get_mix_rate()
	project()
	bytes()
	await planted_bug()
	debts()
	await family()
	await scene_and_walk()
	await bodies()
	await distance()
	await guest()
	await room_task()
	AudioServer.remove_bus_effect(0, 0)

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Sound" and ProjectSettings.get_setting("application/run/main_scene") == "res://chord.tscn"
		and ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"the project is named Sound, its main scene is chord.tscn, its renderer Compatibility")
	var named := []
	var supplied := []
	for file in DirAccess.get_files_at("res://supplied"):
		if not file.ends_with(".uid"):    # the editor writes one beside every script it has seen
			supplied.append(file)
		if file.ends_with(".gd") and RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text_of("res://supplied/" + file)) != null:
			named.append(file)
	check(supplied.size() == 15 and named.is_empty() and ProjectSettings.get_global_class_list().is_empty(),
		"supplied/ holds its 15 files, none declares a class_name, and the project lists no named class: nothing needs an import")
	var spaced := []
	for folder: String in ["res://", "res://supplied/", "res://guests/sound/"]:
		for file in DirAccess.get_files_at(folder):
			if file.ends_with(".gd") and RegEx.create_from_string("(?m)^ +\\S").search(text_of(folder + file)) != null:
				spaced.append(file)
	check(spaced.is_empty(), "every script is indented with tabs: %s" % [spaced])
	check(AudioServer.get_driver_name() == "Dummy" or DisplayServer.get_name() != "headless", "headless, Godot mixes with its Dummy driver at %d samples a second: nothing reaches a loudspeaker, and the mixer can still be read" % AudioServer.get_mix_rate())

## The numbers: what render() writes, and what the lesson's first steps wrote.
func bytes() -> void:
	var first := one_tone(256.0, true)
	var four := [first.decode_s16(0), first.decode_s16(2), first.decode_s16(4), first.decode_s16(6)]
	check(first.size() == 88200 and four == [0, 1194, 2388, 3578] and first.decode_s16(86) == 32766 and loudest(first) == 32766,
		"one second of one tone of 256 Hz is 88200 bytes; its first four samples are %s, sample 43 is %d, the loudest is %d of 32767" % [four, first.decode_s16(86), loudest(first)])
	measured["one_tone_256"] = {"bytes": first.size(), "first_four_samples": four, "sample_43": first.decode_s16(86), "loudest": loudest(first)}
	var body := chord("3:2")
	root.add_child(body)
	var data: PackedByteArray = body.render()
	var ok := data.size() == 88200
	for i: int in [0, 1, 2, 3, 43, 1000, 22050, 44099]:
		var t := float(i) / RATE
		ok = ok and data.decode_s16(i * 2) == int((0.5 * sin(TAU * 256.0 * t) + 0.5 * sin(TAU * 384.0 * t)) * 32767.0)
	four = [data.decode_s16(0), data.decode_s16(2), data.decode_s16(4), data.decode_s16(6)]
	check(ok and four == [0, 1493, 2983, 4466], "render() of the chord 3:2 writes 88200 bytes, each sample the two sines at half height times 32767, cut to a whole number: the first four are %s" % [four])
	check(loudest(data) == 31226, "the loudest sample of 3:2 is %d: the two tones never stand at their tops together" % loudest(data))
	var stream: AudioStreamWAV = body.voice.stream
	check(stream.format == AudioStreamWAV.FORMAT_16_BITS and stream.mix_rate == RATE and not stream.stereo and stream.data == data and is_equal_approx(stream.get_length(), 1.0),
		"the voice's stream is an AudioStreamWAV: 16 bits, 44100 samples a second, one channel, %.3f s long, holding those bytes" % stream.get_length())
	check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_begin == 0 and stream.loop_end == RATE, "it loops forward from sample 0 to sample 44100")
	check(body.voice is AudioStreamPlayer3D and is_equal_approx(body.voice.unit_size, 1.0) and body.voice.position.is_equal_approx(Vector3(0, 0.4, 0)) and not body.voice.playing,
		"the voice is an AudioStreamPlayer3D on top of the box, unit_size 1, silent until a body comes")
	var seams := {}
	var closes := true
	for value: String in VALUES:
		var member := chord(value)
		root.add_child(member)
		var bytes_of: PackedByteArray = member.render()
		seams[value] = {"high_hz": member.high_hz, "loudest": loudest(bytes_of), "seam_step": seam(bytes_of), "largest_step_inside": largest_step(bytes_of)}
		closes = closes and member.ratio == value and is_equal_approx(member.high_hz, HIGH[value]) and seam(bytes_of) <= largest_step(bytes_of)
		member.free()
	check(closes, "for 1:1, 2:1, 3:2 and 45:32 on 256 Hz the faster tone is 256, 512, 384 and 360 Hz, read back, and the loop closes: the step at the seam is no larger than a step inside. %s" % [seams])
	measured["the_four_chords"] = seams
	var piano := chord("3:2")
	piano.low_hz = 261.63
	root.add_child(piano)
	var open: PackedByteArray = piano.render()
	check(seam(open) > 2 * largest_step(open), "on 261.63 Hz, the piano's middle C, the second does not hold a whole number of turns: the step at the seam is %d, the largest inside %d. A click once a second" % [seam(open), largest_step(open)])
	measured["loop_on_261_63_hz"] = {"seam_step": seam(open), "largest_step_inside": largest_step(open), "high_hz": piano.high_hz}
	piano.free()
	body.free()

## The planted bug: the wave written into the 16-bit buffer as it is.
func planted_bug() -> void:
	var before := errors.size() + warnings.size()
	var silent := one_tone(256.0, false)
	check(loudest(silent) == 0 and silent.size() == 88200 and silent.decode_s16(86) == 0, "encode_s16(i * 2, wave) with the wave between -1 and 1: 88200 bytes and every sample is 0. Sample 43, where the wave is %.6f, is %d" % [sin(TAU * 256.0 * 43.0 / RATE), silent.decode_s16(86)])
	var holder := Node.new()
	root.add_child(holder)
	var voice := AudioStreamPlayer.new()
	holder.add_child(voice)
	var nothing := await hear()
	check(nothing["db"] < -100.0, "before anything plays the Master bus is at %.1f dB: Godot's floor" % nothing["db"])
	voice.stream = stream_of(silent, false)
	voice.play()
	await wait_ms(150)
	var playing := voice.playing
	var position := voice.get_playback_position()
	var heard := await hear(300)
	check(playing and position > 0.05 and heard["db"] < -100.0 and errors.size() + warnings.size() == before,
		"played, the unscaled buffer is silence: playing is %s, the position moves (%.2f s), the bus stays at %.1f dB, and Godot logs no error and no warning in this run" % [playing, position, heard["db"]])
	measured["planted_bug"] = {"loudest_sample": loudest(silent), "playing": playing, "bus_db": heard["db"], "errors_and_warnings": errors.size() + warnings.size() - before}
	await wait_ms(700)
	check(not voice.playing, "with no loop the player stops by itself when the second is over: playing is %s" % voice.playing)
	voice.stream = stream_of(one_tone(256.0, true), false)
	voice.play()
	heard = await hear(300)
	check(heard["db"] > -3.0 and tones(heard) == [256] and heard["256"] > 0.9, "the repaired buffer is heard: the bus reaches %.1f dB, and the mix holds 256 Hz at %.2f of full range and none of the other tones" % [heard["db"], heard["256"]])
	measured["one_tone_heard"] = heard
	voice.stop()
	var body := chord("3:2")
	holder.add_child(body)
	voice.stream = body.voice.stream
	voice.play()
	await wait_ms(1300)
	var still_playing := voice.playing
	heard = await hear(300)
	check(still_playing and tones(heard) == [256, 384] and absf(heard["256"] - 0.5) < 0.05 and absf(heard["384"] - 0.5) < 0.05,
		"the chord 3:2 through a plain player, looped: still playing after 1.3 s, the bus at %.1f dB, the mix holds 256 Hz at %.2f and 384 Hz at %.2f, and no 360 or 512" % [heard["db"], heard["256"], heard["384"]])
	measured["chord_3_2_heard_plain"] = heard
	voice.stop()
	holder.free()
	await frames(1)

## What the approximation owes: clipping, folding, and a tone at half the rate.
func debts() -> void:
	var wrapped := 0
	var first_wrapped := -1
	var asked := 0
	var most := 0
	var data := PackedByteArray()
	data.resize(RATE * 2)
	for i in range(RATE):
		var t := float(i) / RATE
		var wave := sin(TAU * 256.0 * t) + sin(TAU * 384.0 * t)   # the 0.5 left out
		var whole := int(wave * 32767.0)
		data.encode_s16(i * 2, whole)
		most = maxi(most, absi(whole))
		if data.decode_s16(i * 2) != whole:
			wrapped += 1
			if first_wrapped == -1:
				first_wrapped = i
				asked = whole
	check(most > 32767 and wrapped > 0 and first_wrapped > 0 and data.decode_s16(first_wrapped * 2) == asked - 65536,
		"without the two halves the sum reaches %d, past 32767; encode_s16() does not refuse it, it wraps: %d of 44100 samples read back as another number. The first is sample %d: %d was asked, %d is in the buffer" % [most, wrapped, first_wrapped, asked, data.decode_s16(first_wrapped * 2)])
	measured["sum_without_the_halves"] = {"largest_number_asked": most, "samples_wrapped": wrapped, "first_wrapped_sample": first_wrapped, "asked": asked, "in_the_buffer": data.decode_s16(first_wrapped * 2)}
	var low := one_tone(256.0, true)
	var folded := one_tone(RATE - 256.0, true)
	var apart := 0
	for i in range(RATE):
		apart = maxi(apart, absi(folded.decode_s16(i * 2) + low.decode_s16(i * 2)))
	check(apart <= 1, "a tone of 43844 Hz, 256 short of the rate, gives the samples of 256 Hz upside down: the largest difference over the second is %d of 32767. The buffer cannot tell the two apart" % apart)
	var half := one_tone(RATE / 2.0, true)
	check(loudest(half) == 0, "a tone of 22050 Hz, half the rate, is sampled where it crosses zero each time: every sample is %d" % loudest(half))
	measured["folding"] = {"tone_hz": RATE - 256, "largest_difference_from_256_hz_upside_down": apart, "loudest_sample_of_22050_hz": loudest(half)}

## The four values of the axis as bodies: what is built, and what the rule gives.
func family() -> void:
	var base := await world()
	var record := {}
	var ok := true
	for i in VALUES.size():
		var value: String = VALUES[i]
		var body := chord(value)
		body.position = Vector3(i * 2.0 - 3.0, 0.0, 0.0)
		base.add_child(body)
		await frames(1)
		var figures := body.find_children("*", "MultiMeshInstance3D", true, false)
		var beads: MultiMesh = figures[0].multimesh
		var bead: BoxMesh = beads.mesh
		ok = ok and figures.size() == 1 and beads.instance_count == Chord.BEADS and beads.instance_count == 5512 and bead.size.is_equal_approx(Vector3(0.02, 0.02, 0.02))
		ok = ok and figures[0].material_override.albedo_color.is_equal_approx(Look.LINE) and figures[0].find_children("*", "CollisionObject3D", true, false).is_empty()
		# The rule, counted here: cells of a 50 by 50 grid over the square that hold a bead.
		var seen := {}
		var widest := 0.0
		for k in Chord.BEADS:
			var t := float(k) / RATE
			var x := 0.5 * sin(TAU * body.low_hz * t)
			var y := 0.5 * sin(TAU * body.high_hz * t)
			widest = maxf(widest, maxf(absf(x), absf(y)))
			seen[Vector2i(clampi(int((x + 0.5) * 50.0), 0, 49), clampi(int((y + 0.5) * 50.0), 0, 49))] = true
		var parts := value.split(":")
		record[value] = {"beads": beads.instance_count, "cells_of_2500_with_a_bead": seen.size(), "closes_after_s": float(parts[1]) / 256.0, "turns_of_the_slower_tone": int(parts[1])}
		ok = ok and widest <= 0.5 and float(parts[1]) / 256.0 <= 0.125 + 0.0001
	check(ok, "each of the four chords has one figure: a MultiMesh of 5512 boxes of 2 cm in LINE, with no collider; by the rule no bead leaves the square of 1 m, and each figure closes within the eighth of a second the beads cover")
	check(record["1:1"]["cells_of_2500_with_a_bead"] < record["2:1"]["cells_of_2500_with_a_bead"] and record["2:1"]["cells_of_2500_with_a_bead"] < record["3:2"]["cells_of_2500_with_a_bead"]
		and record["45:32"]["cells_of_2500_with_a_bead"] > 4 * record["3:2"]["cells_of_2500_with_a_bead"],
		"by the rule the beads fall in %d, %d, %d and %d of the 2500 cells of a 50 by 50 grid over the square, for 1:1, 2:1, 3:2 and 45:32" % [record["1:1"]["cells_of_2500_with_a_bead"], record["2:1"]["cells_of_2500_with_a_bead"], record["3:2"]["cells_of_2500_with_a_bead"], record["45:32"]["cells_of_2500_with_a_bead"]])
	measured["figures_by_the_rule"] = record
	var readback: Vector3 = base.get_child(base.get_child_count() - 1).find_children("*", "MultiMeshInstance3D", true, false)[0].multimesh.get_instance_transform(100).origin
	measured["headless_bead_100_reads_back"] = [readback.x, readback.y, readback.z]
	# The export, set after the chord is in the room: nothing listens to it.
	var late: Node3D = base.get_child(base.get_child_count() - 1)
	late.ratio = "2:1"
	late.set("ration", "1:1")   # a name the script does not have
	check(late.ratio == "2:1" and is_equal_approx(late.high_hz, 360.0) and late.get("ration") == null, "ratio changed on a chord that already stands in the room is kept as a text and changes nothing: the faster tone is still %.0f Hz. set() with a name the script does not have does nothing, in silence" % late.high_hz)
	await close(base)

## chord.tscn, as it opens, and the walker's walk through the two reaches.
func scene_and_walk() -> void:
	var before := errors.size()
	var scene: Node3D = load("res://chord.tscn").instantiate()
	root.add_child(scene)
	await frames(180)
	var mine: Node3D = scene.get_node_or_null("Chord")
	var other: Node3D = scene.get_node_or_null("Neighbour")
	var walker: CharacterBody3D = scene.get_node_or_null("Walker")
	check(errors.size() == before and mine != null and other != null and walker != null, "chord.tscn runs 180 frames and Godot logs no error: %s" % [errors.slice(before)])
	if mine == null or other == null or walker == null:
		return
	check(mine.get_script() == Chord and mine.ratio == "3:2" and mine.member == 0 and other.scene_file_path == "res://guests/sound/sound.tscn" and other.ratio == "2:1" and other.member == 1
		and printed.has("Chord: 3:2, 256.0 and 384.0 Hz") and printed.has("Neighbour: 2:1, 256.0 and 512.0 Hz"),
		"in it Chord runs chord.gd at 3:2 and Neighbour is the guest at 2:1; each prints its line: Chord: 3:2, 256.0 and 384.0 Hz")
	var speaker: MeshInstance3D = null
	var ring: MeshInstance3D = null
	for part: MeshInstance3D in mine.find_children("*", "MeshInstance3D", false, false):
		if part.mesh is BoxMesh:
			speaker = part
		elif part.mesh is CylinderMesh:
			ring = part
	var other_box: MeshInstance3D = null
	for part: MeshInstance3D in other.find_children("*", "MeshInstance3D", false, false):
		if part.mesh is BoxMesh:
			other_box = part
	check(speaker != null and ring != null and other_box != null and speaker.material_override.albedo_color.is_equal_approx(Look.BODY) and other_box.material_override.albedo_color.is_equal_approx(Look.SECOND)
		and ring.material_override.albedo_color.is_equal_approx(Color(Look.GHOST, 0.45)) and speaker.find_children("*", "StaticBody3D", true, false).size() == 1
		and mine.find_children("*", "Area3D", false, false).size() == 1,
		"the chord is a box in BODY with a collider, a ring in GHOST on the floor, an Area3D and the figure; the neighbour's box is SECOND")
	check(walker.get_node("Eyes").current and walker.position.is_equal_approx(Vector3(-0.6, 0, 2.2)) and mine.position.is_equal_approx(Vector3(-0.6, 0, 0)) and other.position.is_equal_approx(Vector3(0.6, 0, 0)),
		"the walker starts 2.2 m in front of the Chord, looking through its Eyes; the two chords stand 1.2 m apart, so their rings of 0.8 m overlap")
	var heard := await hear()
	check(not mine.voice.playing and not other.voice.playing and heard["db"] < -100.0, "with the walker outside both reaches nothing plays: the bus is at %.1f dB" % heard["db"])
	var walk_record := {}
	# 0. By the keys, as the lesson says: W into the Chord, D to the right into both, D again to the Neighbour alone.
	await hold("move_forward", 45)
	await physics_frames(3)
	var by_w: bool = mine.voice.playing and not other.voice.playing
	var at_w: Vector3 = walker.global_position
	await hold("move_right", 18)
	await physics_frames(3)
	var by_d: bool = mine.voice.playing and other.voice.playing
	var at_d: Vector3 = walker.global_position
	await hold("move_right", 22)
	await physics_frames(3)
	var by_dd: bool = other.voice.playing and not mine.voice.playing
	check(by_w and by_d and by_dd, "by the keys: W held for 45 steps brings the walker to %s and the Chord sounds alone; D for 18 steps to %s and both sound; D for 22 more to %s and the Neighbour sounds alone" % [at_w.snappedf(0.01), at_d.snappedf(0.01), walker.global_position.snappedf(0.01)])
	walk_record["by_the_keys"] = {"after_W": [snappedf(at_w.x, 0.01), snappedf(at_w.z, 0.01)], "after_D": [snappedf(at_d.x, 0.01), snappedf(at_d.z, 0.01)], "after_D_again": [snappedf(walker.global_position.x, 0.01), snappedf(walker.global_position.z, 0.01)]}
	var how := await walk(walker, [Vector3(-0.6, 0.0, 2.2)])
	await physics_frames(3)
	check(how == "arrived" and not mine.voice.playing and not other.voice.playing, "walked back to its start it is outside both reaches and both are silent")
	# 1. Into the left chord's reach only.
	how = await walk(walker, [Vector3(-0.6, 0.0, 0.9)])
	await physics_frames(3)
	heard = await hear()
	walk_record["in_the_chord"] = {"walk": how, "heard": heard}
	check(how == "arrived" and mine.voice.playing and not other.voice.playing and printed.has("Chord sounds") and tones(heard) == [256, 384],
		"the walker walks into the Chord's reach and arrives: Chord sounds, the Neighbour does not; the mix holds %s Hz, at %.1f dB" % [tones(heard), heard["db"]])
	# The ears are the eyes: C moves both to the fixed camera, 5 m away.
	var near_db: float = heard["db"]
	await press("switch_camera")
	var far := await hear()
	walk_record["after_C"] = far
	check(scene.get_node("Camera3D").current and far["db"] < near_db - 6.0 and tones(far).has(256), "C changes to the fixed camera, and the ears go with the eyes: the same chord is now %.1f dB, was %.1f dB" % [far["db"], near_db])
	await press("switch_camera")
	check(walker.get_node("Eyes").current, "C again: back behind the walker's eyes")
	# 2. Where the two reaches overlap.
	how = await walk(walker, [Vector3(0.0, 0.0, 0.6), Vector3(0.0, 0.0, 0.0)])
	await physics_frames(3)
	heard = await hear()
	walk_record["in_both"] = {"walk": how, "heard": heard, "feet_m": snappedf(walker.global_position.y, 0.01)}
	check(how == "arrived" and mine.voice.playing and other.voice.playing and tones(heard) == [256, 384, 512] and absf(walker.global_position.y) < 0.01,
		"it walks between the two boxes and through both figures, which stop nothing, and arrives where the rings overlap: both sound, the mix holds %s Hz, at %.1f dB" % [tones(heard), heard["db"]])
	# 3. At the neighbour's box: a collider.
	how = await walk(walker, [Vector3(0.0, 0.0, 1.0), Vector3(0.6, 0.0, 1.0)])
	how = await walk(walker, [Vector3(0.6, 0.0, 0.0)])
	await physics_frames(3)
	heard = await hear()
	var gap := flat(walker.global_position - other.global_position).length()
	walk_record["at_the_neighbours_box"] = {"walk": how, "metres_from_its_middle": snappedf(gap, 0.01), "heard": heard}
	check(how == "blocked" and absf(gap - 0.45) < 0.03 and other.voice.playing and not mine.voice.playing and printed.has("Chord is silent") and tones(heard) == [256, 512],
		"walked at the Neighbour's box it is stopped, \"%s\", %.2f m from its middle; there only the Neighbour sounds: %s Hz, at %.1f dB" % [how, gap, tones(heard), heard["db"]])
	# 4. Away.
	how = await walk(walker, [Vector3(0.6, 0.0, 1.0), Vector3(2.6, 0.0, 1.6)])
	await physics_frames(3)
	heard = await hear()
	walk_record["away"] = {"walk": how, "heard": heard}
	check(how == "arrived" and not mine.voice.playing and not other.voice.playing and printed.has("Neighbour is silent") and heard["db"] < -100.0, "it walks away and both are silent again: %.1f dB" % heard["db"])
	measured["walk"] = walk_record
	check(errors.size() == before, "the whole walk, and Godot logged no error: %s" % [errors.slice(before)])
	await close(scene)

## What a body is to the chord: the marble on the box and through the figure,
## and who enters the reach before anybody walks.
func bodies() -> void:
	var base := await world()
	var body := chord("3:2")
	body.name = "Chord"
	base.add_child(body)
	var entered := []
	var reach: Area3D = body.find_children("*", "Area3D", false, false)[0]
	reach.body_entered.connect(func(who: Node3D) -> void: entered.append(who.get_class()))
	await physics_frames(10)
	check(entered.size() == 2 and entered.count("StaticBody3D") == 2 and not body.voice.playing,
		"in its first steps the reach is entered by two bodies, the floor's and the chord's own box, both a StaticBody3D: %s. The `if` keeps the chord silent for them" % [entered])
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	marble.position = Vector3(3.0, 0.1, 2.0)
	base.add_child(marble)
	await frames(2)
	marble.drop(Vector3(0.0, 2.0, 0.0))
	var on_box := await settle(marble)
	check(absf(on_box.y - 0.5) < 0.01 and flat(on_box).length() < 0.15 and not body.voice.playing, "the marble dropped over the middle falls through the figure and rests on the box, at %.2f m; a marble is not a walker, and the chord stays silent" % on_box.y)
	marble.drop(Vector3(0.35, 2.0, 0.0))
	var through := await settle(marble)
	check(absf(through.y - 0.1) < 0.01, "dropped 0.35 m to the side, through the beads, it lies on the floor at %.2f m: the figure stops nothing" % through.y)
	measured["marble"] = {"on_the_box_m": snappedf(on_box.y, 0.001), "through_the_figure_m": snappedf(through.y, 0.001), "entered_the_reach_at_the_start": entered}
	await close(base)

## AudioStreamPlayer3D and distance: the same voice from 1, 2 and 4 m.
func distance() -> void:
	var base := await world()
	var body := chord("3:2")
	base.add_child(body)
	var listener := Camera3D.new()
	base.add_child(listener)
	listener.make_current()
	body.voice.play()
	var levels := {}
	for metres: float in [1.0, 2.0, 4.0]:
		listener.position = body.voice.position + Vector3(0.0, 0.0, metres)
		levels[metres] = (await hear())["db"]
	var first_drop: float = levels[1.0] - levels[2.0]
	var second_drop: float = levels[2.0] - levels[4.0]
	check(first_drop > 5.0 and first_drop < 7.0 and second_drop > 5.0 and second_drop < 7.0, "with unit_size 1 the voice is heard at %.1f dB from 1 m, %.1f from 2 m and %.1f from 4 m: each doubling takes about 6 dB" % [levels[1.0], levels[2.0], levels[4.0]])
	listener.position = body.voice.position + Vector3(2.0, 0.0, 0.0)
	var side := await hear()
	check(side["left_db"] > side["right_db"] + 3.0, "with the voice 2 m to the listener's left the left side is louder: %.1f dB against %.1f dB" % [side["left_db"], side["right_db"]])
	body.voice.unit_size = 10.0   # Godot's own default
	listener.position = body.voice.position + Vector3(0.0, 0.0, 1.0)
	var default_near: float = (await hear())["db"]
	listener.position = body.voice.position + Vector3(0.0, 0.0, 4.0)
	var default_far: float = (await hear())["db"]
	check(absf(default_near - default_far) < 1.0, "with Godot's default unit_size of 10 the voice is as loud from 4 m as from 1 m, %.1f and %.1f dB: on a floor of 8 m distance would not be heard" % [default_far, default_near])
	measured["distance"] = {"unit_size_1_db_at_1_2_4_m": [levels[1.0], levels[2.0], levels[4.0]], "to_the_left_2_m": side, "unit_size_10_db_at_1_and_4_m": [default_near, default_far]}
	body.voice.stop()
	await close(base)

## The body handed to the room.
func guest() -> void:
	var folder := "res://guests/sound/"
	var needs := CheckGuest.outside(folder)
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names(folder).is_empty(), "the guest declares no class_name")
	var files := []
	for file in DirAccess.get_files_at(folder):
		if not file.ends_with(".uid"):
			files.append(file)
	check(files == ["sound.gd", "sound.tscn"], "its folder holds a scene and one script: %s" % [files])
	# sound.gd is chord.gd with the look written out: every other line is the same, in the same order.
	var theirs := text_of(folder + "sound.gd").split("\n")
	var missing := []
	var from := 0
	var compared := 0
	for line in text_of("res://chord.gd").split("\n"):
		if line.contains("Look") or line.begins_with("##") or line.strip_edges() == "":
			continue
		compared += 1
		var at := theirs.find(line, from)
		if at == -1:
			missing.append(line)
		else:
			from = at + 1
	check(missing.is_empty() and compared > 60, "the guest's script is chord.gd with the look's colours written out: %d lines of chord.gd that do not name the look stand in it, in order. Missing: %s" % [compared, missing])
	var base := await world()
	var before := errors.size()
	var body: Node3D = load(folder + "sound.tscn").instantiate()
	base.add_child(body)
	await frames(3)
	var low := 10.0
	var wide := 0.0
	var colours_ok := true
	for part: MeshInstance3D in body.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = part.global_transform * part.get_aabb()
		low = minf(low, box.position.y)
		wide = maxf(wide, maxf(maxf(absf(box.position.x), absf(box.end.x)), maxf(absf(box.position.z), absf(box.end.z))))
		if part.mesh is BoxMesh:
			colours_ok = colours_ok and part.material_override.albedo_color.is_equal_approx(Look.BODY)
		else:
			colours_ok = colours_ok and part.material_override.albedo_color.is_equal_approx(Color(Look.GHOST, 0.45))
	var figure: MultiMeshInstance3D = body.find_children("*", "MultiMeshInstance3D", true, false)[0]
	colours_ok = colours_ok and figure.material_override.albedo_color.is_equal_approx(Look.LINE)
	check(body is Node3D and errors.size() == before and low >= 0.0 and low < 0.02 and wide <= 0.8 + 0.0001 and colours_ok and body.ratio == "3:2" and is_equal_approx(body.high_hz, 384.0),
		"the guest loads alone: it stands on the ground (lowest point %.3f m), reaches %.2f m from its middle, so it fits the place of 1.6 m, and wears BODY, GHOST and LINE as the kit does" % [low, wide])
	var walker := await walker_in(base, Vector3(0.0, 0.0, 2.2))
	var how := await walk(walker, [Vector3(0.0, 0.0, 0.0)])
	await physics_frames(3)
	var heard := await hear()
	check(how == "blocked" and body.voice.playing and tones(heard) == [256, 384] and errors.size() == before,
		"a walker sent at it is stopped by its box, %.2f m from the middle, and stands in its reach: it sounds, %s Hz at %.1f dB" % [flat(walker.global_position).length(), tones(heard), heard["db"]])
	measured["guest"] = {"walk": how, "metres_from_the_middle": snappedf(flat(walker.global_position).length(), 0.01), "heard": heard, "lowest_point_m": snappedf(low, 0.001), "reaches_m": snappedf(wide, 0.001)}
	await close(base)

## The lesson's room task, done to a copy of the guest's script: 5:4 on 192 Hz
## and one line that makes the chord swell twice a second.
func room_task() -> void:
	var text := text_of("res://guests/sound/sound.gd")
	var wave_line := "\t\tvar wave := 0.5 * sin(TAU * low_hz * t) + 0.5 * sin(TAU * high_hz * t)\n"
	var edited := text.replace("@export var ratio := \"3:2\"", "@export var ratio := \"5:4\"").replace("@export var low_hz := 256.0", "@export var low_hz := 192.0")
	edited = edited.replace(wave_line, wave_line + "\t\twave *= 0.5 - 0.5 * cos(TAU * 2.0 * t)\n")
	var edits := 0
	for piece: String in ["@export var ratio := \"5:4\"", "@export var low_hz := 192.0", "\t\twave *= 0.5 - 0.5 * cos(TAU * 2.0 * t)\n"]:
		edits += edited.count(piece)
	var script := GDScript.new()    # the edited copy, compiled from its text: no file is written
	script.source_code = edited
	var before := errors.size()
	var compiled := script.reload()
	var base := await world()
	var body := Node3D.new()
	body.name = "Sound"
	body.set_script(script)
	base.add_child(body)
	await frames(2)
	var data: PackedByteArray = body.render()
	var quiet := absi(data.decode_s16(0)) + absi(data.decode_s16(22050 * 2))
	check(edits == 3 and compiled == OK and errors.size() == before and printed.has("Sound: 5:4, 192.0 and 240.0 Hz") and seam(data) <= largest_step(data) and quiet < 4,
		"the room task, done to a copy of the guest's script (5:4 on 192 Hz, and one line for a swell): it prints Sound: 5:4, 192.0 and 240.0 Hz, the loudest sample is %d, the samples at 0 s and 0.5 s are %d and %d, and the loop closes: the step at the seam is %d" % [loudest(data), data.decode_s16(0), data.decode_s16(22050 * 2), seam(data)])
	var walker := await walker_in(base, Vector3(0.0, 0.0, 2.2))
	var how := await walk(walker, [Vector3(0.0, 0.0, 0.0)])
	await physics_frames(3)
	var levels := []
	var holds := true
	for i in 6:   # the swell takes half a second: listen in short pieces
		await wait_ms(60)
		ear.clear_buffer()
		var loud := -200.0
		var start := Time.get_ticks_msec()
		while Time.get_ticks_msec() - start < 80:
			await process_frame
			loud = maxf(loud, maxf(AudioServer.get_bus_peak_volume_left_db(0, 0), AudioServer.get_bus_peak_volume_right_db(0, 0)))
		levels.append(snappedf(loud, 0.1))
	var heard := await hear(500, [192.0, 240.0, 256.0, 384.0])
	holds = how == "blocked" and body.voice.playing and tones(heard, [192.0, 240.0, 256.0, 384.0]) == [192, 240]
	check(holds and levels.max() - levels.min() > 6.0, "a walker in its reach: the mix holds %s Hz, and over six short listenings the level went from %.1f to %.1f dB: it swells" % [tones(heard, [192.0, 240.0, 256.0, 384.0]), levels.min(), levels.max()])
	measured["room_task"] = {"prints": "Sound: 5:4, 192.0 and 240.0 Hz", "loudest_sample": loudest(data), "seam_step": seam(data), "largest_step_inside": largest_step(data), "levels_db_over_six_listenings": levels, "heard": heard}
	# Recorded by hand from the real test: guest_trial.gd in a scratch copy of my-room, with this guest at place 2.
	measured["room_trial_recorded"] = {"from": "guest_trial.json of a scratch copy of my-room, 1 October 2026", "checks": "8 of 8", "place": 2, "walk_ended": "blocked", "metres_from_the_middle_of_the_place": 0.45, "feet_at_m": 0.0, "printed": "Sound sounds"}
	await close(base)
