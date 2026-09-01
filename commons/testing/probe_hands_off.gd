extends SceneTree
## THE CURATOR KEEPS ITS HANDS OFF WHAT IT IS TOLD TO.
##
## Palle: "remove the em_plinths is automatic, can we say to not touch the line
## demo?" Four checks, two of them negatives — because a list that refuses
## EVERYTHING is as wrong as one that refuses nothing, and a silent list is worse
## than either.

func _init() -> void:
	var P := load("res://commons/scenes/em/em_plinths.gd")
	var fails := 0
	var cell := {"x": 4, "y": 4, "rank": 2, "top": 0.0}

	var a: Dictionary = P.plan("line_demo", cell)
	print("1  line_demo (named)      needs=%s  why=%s" % [a.get("needs"), str(a.get("why", "")).substr(0, 70)])
	if bool(a.get("needs", false)):
		print("   FAIL the curator still raised it"); fails += 1
	if not str(a.get("why", "")).begins_with("hands off"):
		print("   FAIL refused, but not for the stated reason - the list is not what stopped it")
		fails += 1

	# the measured path must refuse too, or the escape hatch reopens it
	var b: Dictionary = P.plan_measured("line_demo", cell, 0.6, 3.0)
	print("2  line_demo (measured)   needs=%s  why=%s" % [b.get("needs"), str(b.get("why", "")).substr(0, 50)])
	if bool(b.get("needs", false)):
		print("   FAIL plan_measured walks around the list"); fails += 1

	# NEGATIVE: a token NOT on the list must be judged normally, not blanket-refused
	var c: Dictionary = P.plan_measured("some_ordinary_object", cell, 0.55, 0.4)
	print("3  an unnamed token       needs=%s  why=%s" % [c.get("needs"), str(c.get("why", "")).substr(0, 60)])
	if str(c.get("why", "")).begins_with("hands off"):
		print("   FAIL the list is refusing everything"); fails += 1

	# NEGATIVE: the list must not silently swallow a missing file
	print("4  register loaded from disk: %s" % [P._hands_off.size() > 0])
	if P._hands_off.size() == 0:
		print("   FAIL nothing was read - a list nobody loads refuses nothing"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
