extends SceneTree
## Does the A-frame actually stand, and does it stay AWAY where it should?
##
## Five questions, one boot, and two of them are negatives. The negatives matter
## more here than the positives: 243 of 244 rooms are unruled, so the common case
## is the sign NOT being built, and an empty A-frame in every hall would advertise
## that somebody meant to say something and did not.
##
## Built in a real tree (add_child), not just .new(), because everything this
## artifact makes it makes in _ready — a probe that skips the tree would report
## an empty artifact as a working one.

func _init() -> void:
	var scene := load("res://commons/artifacts/street_talker/street_talker.tscn")
	var fails := 0

	# 1. a RULED room raises a sign with two faces
	var a = scene.instantiate()
	a.map_name = "Point_One"
	get_root().add_child(a)
	await process_frame
	await process_frame

	var front = a.get_node_or_null("BoardFront")
	var back = a.get_node_or_null("BoardBack")
	print("Point_One: front=%s back=%s children=%d"
		% [front != null, back != null, a.get_child_count()])
	if front == null or back == null:
		print("  FAIL a street talker needs two faces or it is a poster"); fails += 1

	# 2. the faces carry DIFFERENT text — the whole design is that the descent is
	#    somewhere the front is not.
	var ftxt := _screen_body(front)
	var btxt := _screen_body(back)
	print("")
	print("FRONT (%d ch): %s" % [ftxt.length(), ftxt.substr(0, 120).replace("\n", " / ")])
	print("BACK  (%d ch): %s" % [btxt.length(), btxt.substr(0, 120).replace("\n", " / ")])
	if ftxt == "" or btxt == "":
		print("  FAIL a blank face"); fails += 1
	elif ftxt == btxt:
		print("  FAIL both faces say the same thing — then why go round it"); fails += 1

	# 3. the front NAMES the other side, or the back is a secret rather than an offer
	var names_back := false
	for n in _screens(front):
		if str(n.body).to_lower().contains("other side"):
			names_back = true
	print("")
	print("front points at the back: %s" % names_back)
	if not names_back:
		print("  FAIL the descent is hidden, not offered"); fails += 1

	# 4. NEGATIVE. An unruled room builds NOTHING. Not an empty frame.
	var b = scene.instantiate()
	# A name no room will ever have. This named Point_Lines until Point_Lines was
	# ruled, at which point the negative quietly became a positive and tested
	# nothing. A negative keyed to a real subject rots when the subject changes.
	b.map_name = "Unruled_Room_That_Does_Not_Exist"
	get_root().add_child(b)
	await process_frame
	await process_frame
	print("")
	print("unruled room builds: %d children (must be 0)" % b.get_child_count())
	if b.get_child_count() != 0:
		print("  FAIL an empty sign in a room with nothing to say"); fails += 1

	# 5. NEGATIVE. No hall at all is the same answer — a sign that cannot tell
	#    where it is must not guess.
	var c = scene.instantiate()
	get_root().add_child(c)
	await process_frame
	await process_frame
	print("no map resolved builds: %d children (must be 0)" % c.get_child_count())
	if c.get_child_count() != 0:
		print("  FAIL it invented a hall"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)


func _screens(board: Node) -> Array:
	var out: Array = []
	if board == null:
		return out
	var stack: Array = [board]
	while not stack.is_empty():
		var n = stack.pop_back()
		for ch in n.get_children():
			stack.append(ch)
		if "body" in n and "title" in n and "width_m" in n:
			out.append(n)
	return out


func _screen_body(board: Node) -> String:
	var parts := PackedStringArray()
	for s in _screens(board):
		parts.append(str(s.title) + "\n" + str(s.body))
	return "\n".join(parts).strip_edges()
