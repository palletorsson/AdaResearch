extends "res://supplied/sheet_tools.gd"
## The Sound kit's sheet. It needs a window, so run it WITHOUT --headless, from
## this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    the four values of `ratio`, each chord alone in the studio,
##                from the side and from straight above
##   process.png  the strip: one still after each operation, from one standpoint
##   scene.png    chord.tscn as it opens, through the walker's eyes: the one
##                picture here of the look as a RUNNING scene shows it, and not measured
##   sheet.json   the measurements: every pair of values from both standpoints,
##                how much of its square each figure covers, how far the beads
##                stand from the rule, how much each step of the strip changed,
##                the quarter turn, the coarse figure
## and the stills, in stills/. While the walker of the strip stands in the two
## reaches the two chords sound: about a second, if your sound is on.

const Chord := preload("res://chord.gd")
const VALUES := ["1:1", "2:1", "3:2", "45:32"]
const VIEWS := ["level", "above"]
const DISTANCE := 2.6                    # metres from the eye to the middle
const MIDDLE := Vector3(0.0, 0.8, 0.0)   # the middle of a chord: half its height

func chord(ratio: String, member := 0) -> Node3D:
	var body := Node3D.new()
	body.set_script(Chord)
	body.ratio = ratio
	body.member = member
	return body

func figure_of(body: Node3D) -> MultiMeshInstance3D:
	return body.find_children("*", "MultiMeshInstance3D", true, false)[0]

func run() -> void:
	await scene_still()
	await sheet()
	await quarter_turn()
	await coarse_figure()
	await process_strip()

## chord.tscn as it opens: through the walker's eyes, then from the fixed camera.
func scene_still() -> void:
	var scene: Node3D = load("res://chord.tscn").instantiate()
	root.add_child(scene)
	for i in 20:
		await physics_frame
	var still := await shot("scene")
	still.resize(640, 480, Image.INTERPOLATE_BILINEAR)   # the running look's sky is a gradient: smaller, the file stays light
	still.save_png("res://scene.png")
	report["scene_png"] = {"width": still.get_width(), "height": still.get_height(), "bytes": FileAccess.get_file_as_bytes("res://scene.png").size()}
	scene.get_node("Camera3D").make_current()
	await shot("scene_fixed_camera")
	scene.free()
	await process_frame

## The comparison sheet: every value from both standpoints, every pair measured.
func sheet() -> void:
	var tiles: Array[Image] = []
	report["values"] = VALUES
	report["eye_distance_m"] = DISTANCE
	for view: String in VIEWS:
		var stills := []
		var pixels := []
		var rows := {}
		for value: String in VALUES:
			var body := chord(value)
			await stand(body)
			look(view, DISTANCE, MIDDLE)
			var taken: Array = await portrait(body, "%s_%s" % [value.replace(":", "_"), view])
			stills.append(taken[0])
			pixels.append(taken[1])
			tiles.append(small(taken[0]))
			var row := {"ratio_read_back": body.ratio, "low_hz": body.low_hz, "high_hz": body.high_hz, "body_pct_of_still": share(taken[1])}
			if view == "level":
				row["figure_covers_pct_of_its_square"] = square_cover(taken[1])
				row["farthest_bead_from_the_rule_m"] = off_the_rule(body)
			rows[value] = row
			print("%s, %s: the chord covers %.2f%% of the still %s" % [view, value, row["body_pct_of_still"], row])
		report["values_" + view] = rows
		report["pairs_" + view] = compare_all(VALUES, stills, pixels)
	report["sheet_png"] = await compose(tiles, VALUES.size(), VALUES, "res://sheet.png")

## How much of the figure's own square, 1 m by 1 m and 1.1 m up, the body's
## pixels cover in the still the eye has now, in percent.
func square_cover(pixels: PackedByteArray) -> float:
	var a := eye.unproject_position(Vector3(-0.51, 1.61, 0.0)) - Vector2(crop.position)
	var b := eye.unproject_position(Vector3(0.51, 0.59, 0.0)) - Vector2(crop.position)
	var inside := 0
	var all := 0
	for y in range(int(a.y), int(b.y) + 1):
		for x in range(int(a.x), int(b.x) + 1):
			all += 1
			inside += pixels[y * crop.size.x + x]
	report["figure_square_pct_of_still"] = snappedf(100.0 * all / pixels.size(), 0.01)
	return snappedf(100.0 * inside / all, 0.01)

## How far the bead farthest from the rule stands from it, read back from the
## MultiMesh: 0 when every bead is where the two sines put it. (Headless, a
## MultiMesh reads back zeros, so this is measured here, with a window.)
func off_the_rule(body: Node3D) -> float:
	var beads: MultiMesh = figure_of(body).multimesh
	var most := 0.0
	for i in beads.instance_count:
		var t := float(i) / Chord.RATE
		var rule := Vector3(0.5 * sin(TAU * body.low_hz * t), 1.1 + 0.5 * sin(TAU * body.high_hz * t), 0.0)
		most = maxf(most, beads.get_instance_transform(i).origin.distance_to(rule))
	return snappedf(most, 0.000001)

## The difference the lesson offers to follow: the faster tone started a part
## of a turn ahead. Built here by hand, bead by bead, as the lesson's rule
## would: an eighth and a quarter of a turn, on 1:1 and on 3:2.
func quarter_turn() -> void:
	var record := {}
	for value: String in ["1:1", "3:2"]:
		var plain := chord(value)
		await stand(plain)
		look("level", DISTANCE, MIDDLE)
		var a: Array = await portrait(plain, "")
		record[value] = {"loudest_wave_plain": loudest_wave(plain.low_hz, plain.high_hz, 0.0)}
		for turn: float in [0.125, 0.25]:
			var turned := chord(value)
			await stand(turned)
			var beads: MultiMesh = figure_of(turned).multimesh
			for i in beads.instance_count:
				var t := float(i) / Chord.RATE
				beads.set_instance_transform(i, Transform3D(Basis(), Vector3(0.5 * sin(TAU * turned.low_hz * t), 1.1 + 0.5 * sin(TAU * (turned.high_hz * t + turn)), 0.0)))
			look("level", DISTANCE, MIDDLE)
			var b: Array = await portrait(turned, "%s_turned_%s" % [value.replace(":", "_"), str(turn).replace(".", "_")])
			record[value]["turned_%s" % turn] = {"differ_pct": compare(a[0], a[1], b[0], b[1])["differ_pct"], "figure_covers_pct_of_its_square": square_cover(b[1]),
				"loudest_wave": loudest_wave(turned.low_hz, turned.high_hz, turn)}
		print("turned, %s: %s" % [value, record[value]])
	report["quarter_turn"] = record

## The loudest the summed wave gets in one second, the range being 1, with the
## faster tone `turn` of a turn ahead.
func loudest_wave(low_hz: float, high_hz: float, turn: float) -> float:
	var loudest := 0.0
	for i in Chord.RATE:
		var t := float(i) / Chord.RATE
		loudest = maxf(loudest, absf(0.5 * sin(TAU * low_hz * t) + 0.5 * sin(TAU * (high_hz * t + turn))))
	return snappedf(loudest, 0.0001)

## The debt, seen: 45:32 with one bead in eight. The same curve, sampled thinner.
func coarse_figure() -> void:
	var full := chord("45:32")
	await stand(full)
	look("level", DISTANCE, MIDDLE)
	var a: Array = await portrait(full, "")
	var coarse := chord("45:32")
	await stand(coarse)
	var beads: MultiMesh = figure_of(coarse).multimesh
	beads.visible_instance_count = Chord.BEADS / 8
	for i in Chord.BEADS / 8:
		var t := float(i * 8) / Chord.RATE
		beads.set_instance_transform(i, Transform3D(Basis(), Vector3(0.5 * sin(TAU * coarse.low_hz * t), 1.1 + 0.5 * sin(TAU * coarse.high_hz * t), 0.0)))
	look("level", DISTANCE, MIDDLE)
	var b: Array = await portrait(coarse, "45_32_one_bead_in_eight")
	report["one_bead_in_eight"] = {"beads": Chord.BEADS / 8, "differ_pct_from_the_full_figure": compare(a[0], a[1], b[0], b[1])["differ_pct"],
		"figure_covers_pct_of_its_square": square_cover(b[1]), "full_figure_covers_pct_of_its_square": square_cover(a[1])}
	print("one bead in eight: %s" % [report["one_bead_in_eight"]])

## The process strip: one still after each operation, from one standpoint.
func process_strip() -> void:
	var names := ["1 one tone, in bytes", "2 two tones, looped", "3 a voice, a box, a reach", "4 the figure", "5 a neighbour, 2:1", "6 a walker in both"]
	var tiles: Array[Image] = []
	var group := Node3D.new()
	await stand(group, false)     # not held: the walker has to stand and the areas to find it
	look_from(Vector3(0.0, 1.9, 4.3), Vector3(0.0, 0.75, 0.0))
	var first := chord("3:2")
	first.position = Vector3(-0.6, 0.0, 0.0)
	first.visible = false         # steps 1 and 2 made the sound: nothing of it is seen
	group.add_child(first)
	await process_frame
	tiles.append(small(await shot("strip_1")))
	tiles.append(small(await shot("strip_2")))
	first.visible = true
	figure_of(first).visible = false
	tiles.append(small(await shot("strip_3")))
	figure_of(first).visible = true
	tiles.append(small(await shot("strip_4")))
	var second := chord("2:1", 1)
	second.position = Vector3(0.6, 0.0, 0.0)
	group.add_child(second)
	tiles.append(small(await shot("strip_5")))
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = Vector3(0.0, 0.0, 0.0)   # before add_child
	group.add_child(walker)
	for i in 30:
		await physics_frame
	var both: bool = first.voice.playing and second.voice.playing
	tiles.append(small(await shot("strip_6")))
	report["strip"] = await strip(tiles, names)
	report["strip"]["both_voices_playing_at_step_6"] = both
	print("strip: at step 6 both voices play: ", both)
