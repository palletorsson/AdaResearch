extends SceneTree
## Two live bugs, two negatives. Both were invisible to every probe that already
## existed, because both failure modes look EXACTLY like a legitimate outcome.
##
## 1. street_talker in the museum built nothing, because a hall segment carries
##    em_map (endless_museum.gd:7611) and the board asked only for map_name.
##    An unruled room building nothing is correct, so the bug wore the shape of
##    the feature. The negative here is the one that matters: an em_map naming
##    a room with NO ruling must still build nothing.
##
## 2. line_sledgehammer discarded any swing over HEAD_SPEED_MAX and, worse, ZEROED
##    the peak-hold when it did. The cap was 14 m/s, which a real VR swing clears,
##    so hard swings died at the moment of impact and only taps registered.

func _init() -> void:
	var fails := 0

	# ---------- 1. the museum's vocabulary reaches the board ----------
	var scene := load("res://commons/artifacts/street_talker/street_talker.tscn")

	# a hall segment, as the museum builds it: em_map, never map_name
	var hall := Node3D.new()
	hall.set_meta("em_map", "Point_Lines")
	get_root().add_child(hall)
	var a = scene.instantiate()
	hall.add_child(a)
	await process_frame
	await process_frame
	var built: int = a.get_child_count()
	print("museum hall (em_map=Point_Lines): %d children" % built)
	if built == 0:
		print("  FAIL the board is blind to the museum's name for the map"); fails += 1

	# NEGATIVE: em_map naming an UNRULED room must still build nothing
	var hall2 := Node3D.new()
	hall2.set_meta("em_map", "Unruled_Room_That_Does_Not_Exist")
	get_root().add_child(hall2)
	var b = scene.instantiate()
	hall2.add_child(b)
	await process_frame
	await process_frame
	print("museum hall (em_map=unruled): %d children (must be 0)" % b.get_child_count())
	if b.get_child_count() != 0:
		print("  FAIL an unruled room got a sign"); fails += 1

	# NEGATIVE: an empty em_map must not resolve
	var hall3 := Node3D.new()
	hall3.set_meta("em_map", "")
	get_root().add_child(hall3)
	var c = scene.instantiate()
	hall3.add_child(c)
	await process_frame
	await process_frame
	print("museum hall (em_map=\"\"): %d children (must be 0)" % c.get_child_count())
	if c.get_child_count() != 0:
		print("  FAIL an empty em_map built something"); fails += 1

	# ---------- 2. the swing gate ----------
	var src := FileAccess.open("res://commons/artifacts/line_sledgehammer/line_sledgehammer.gd",
		FileAccess.READ)
	var txt := src.get_as_text()
	src.close()

	var cap := 0.0
	for line in txt.split("\n"):
		if line.begins_with("const HEAD_SPEED_MAX"):
			cap = line.split(":=")[1].strip_edges().to_float()
	print("")
	print("HEAD_SPEED_MAX = %.1f m/s" % cap)

	# A hard human swing: head at the end of a ~0.6 m haft, arm+wrist rotation.
	# 20 m/s is a firm two-handed swing; it MUST survive the gate.
	if cap < 20.0:
		print("  FAIL a 20 m/s swing is a real swing, not a teleport"); fails += 1
	# A grab or spawn moves the head metres in ONE frame: 1 m at 72 fps = 72 m/s.
	if cap > 60.0:
		print("  FAIL the cap no longer catches a teleport"); fails += 1

	# and the peak must NOT be zeroed on an over-cap sample
	if txt.contains("_recent_speed = 0.0            # a teleport"):
		print("  FAIL an over-cap frame still wipes the peak-hold"); fails += 1
	else:
		print("over-cap sample is ignored, not zeroed: ok")

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
