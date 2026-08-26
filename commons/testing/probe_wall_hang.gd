extends SceneTree
## THE HANG (2026-08-26, Palle: "I need to be able to move the wall work, they
## should stick to the wall"). A wall work's place is a WALL FACE — the wall
## cell plus the way it looks into the room — not a point and not an offset.
## Proves, against em_detail directly (no museum needed):
##   1. a retarget puts the six boxes ON the named face
##   2. moving from a z-wall to an x-wall TURNS the work — which a translation
##      could never do, and is the whole reason a face is the right address
##   3. the four frame bars travel with their mount and field
##   4. a nonsense direction is refused rather than half-applied
const OUT := "res://ada_run/wall_hang_probe.txt"
const EMD := preload("res://commons/scenes/em/em_detail.gd")

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var fails: Array = []
	var notes: Array = []
	# one showing, built the ordinary way: on a wall at z, facing -z
	var fr: Array = []
	var mo: Array = []
	var fi: Array = []
	EMD._hang_one(4.5, 6.0, true, -1.0, Vector2(1.2, 0.9), fr, mo, fi)
	if mo.size() != 1 or fi.size() != 1 or fr.size() != 4:
		fails.append("the ordinary hang built %d mount / %d field / %d frame" % [mo.size(), fi.size(), fr.size()])
		_report(fails, notes); return
	notes.append("a wall work is six boxes: 1 mount, 1 field, 4 frame bars")
	var before_o: Vector3 = (mo[0] as Transform3D).origin
	var before_b: Basis = (mo[0] as Transform3D).basis

	# 1 + 2. move it to a wall cell at (9, 3) looking in +x
	var ok: bool = EMD._hang_retarget(0, Vector2i(9, 3), Vector2i(1, 0), fr, mo, fi)
	if not ok:
		fails.append("the retarget refused a good face")
		_report(fails, notes); return
	var after_o: Vector3 = (mo[0] as Transform3D).origin
	# the named face: cell 9,3 stepping +x -> the plane at x = 10.0, centred in z
	if absf(after_o.x - 10.0) > 0.12 or absf(after_o.z - 3.5) > 0.12:
		fails.append("it landed at %s, not on the face of cell 9,3 facing +x" % str(after_o))
	else:
		notes.append("it lands ON the named wall face (%.2f, %.2f)" % [after_o.x, after_o.z])
	if after_o.distance_to(before_o) < 1.0:
		fails.append("it did not move")

	# it TURNED: the box that was wide along x is now wide along z
	var after_b: Basis = (mo[0] as Transform3D).basis
	var was_x: float = before_b.x.length()
	var now_x: float = after_b.x.length()
	var now_z: float = after_b.z.length()
	if absf(now_z - was_x) > 0.12:
		fails.append("it did not turn: was %.2f wide along x, now %.2f along z" % [was_x, now_z])
	else:
		notes.append("crossing to the other wall TURNS it (%.2f wide along x -> along z)" % was_x)
	if now_x > now_z:
		fails.append("still facing the old way")

	# 3. the frame travelled with it
	var far := 0
	for k in range(4):
		if (fr[k] as Transform3D).origin.distance_to(after_o) > 1.6:
			far += 1
	if far > 0:
		fails.append("%d frame bar(s) stayed behind" % far)
	else:
		notes.append("all four frame bars travelled with the mount")

	# 4. a nonsense direction is refused
	var keep: Vector3 = (mo[0] as Transform3D).origin
	var bad: bool = EMD._hang_retarget(0, Vector2i(2, 2), Vector2i(0, 0), fr, mo, fi)
	if bad or (mo[0] as Transform3D).origin.distance_to(keep) > 0.001:
		fails.append("a zero direction was accepted and moved the work")
	else:
		notes.append("a face with no direction is refused, and nothing moves")
	_report(fails, notes)

func _report(fails: Array, notes: Array) -> void:
	var r := "WALL HANG PROBE\n"
	for n in notes: r += "  ok   %s\n" % n
	for f in fails: r += "  FAIL %s\n" % f
	r += "%d fail(s)\n" % fails.size()
	var fh := FileAccess.open(OUT, FileAccess.WRITE); fh.store_string(r); fh.close()
	print(r)
	quit(1 if not fails.is_empty() else 0)
