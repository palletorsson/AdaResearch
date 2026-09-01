extends SceneTree
## DOES THE GRADIENT STAY QUIET WHERE IT SHOULD?
##
## The old version of this probe checked that a room named everything it stood
## on. This one checks the opposite, because Palle's ruling inverted the default:
## silence is now the correct answer, and the failure mode worth catching is a
## room that speaks when nobody judged that it should.
##
## Six questions, one boot. Three of them are negatives.
##
## Tests Depth.gd, not info_board.gd: the board names GameManager, and a SceneTree
## probe cannot see an autoload, so the board fails to COMPILE here rather than
## failing a check. That is why the reader lives in its own file.

func _init() -> void:
	var D := load("res://commons/scenes/mapobjects/Depth.gd")
	var fails := 0

	# 1. a ruled room names its SUBJECT
	var subj = D.subject("Point_One")
	print("Point_One TEACHES: %d" % subj.size())
	for t in subj:
		print("    %s — %s" % [t.get("thing", ""), t.get("say", "")])
	if subj.size() != 4:
		print("  FAIL expected 4 things ruled 'understood'"); fails += 1

	# 2. THE NEGATIVE THAT MATTERS. 'function' is ruled 'used' in Point_One:
	#    the learner acts through it and the museum says nothing. If it ever
	#    surfaces, the wall is back.
	var said := ""
	for t in D.says("Point_One"):
		if str(t.get("thing", "")) == "function":
			said = "function"
	print("")
	print("'function' (ruled used) surfaces as: '%s' (must be empty)" % said)
	if said != "":
		print("  FAIL the dependency wall is back: a 'used' thing spoke"); fails += 1

	# 3. THE SECOND NEGATIVE. An unruled room says NOTHING — it does not fall
	#    back to a measured list. 243 of 244 rooms are unruled today.
	var quiet = D.says("Point_Lines")
	print("unruled room says: %d (must be 0)" % quiet.size())
	if quiet.size() != 0:
		print("  FAIL an unruled room invented something to say"); fails += 1

	# 4. THE THIRD NEGATIVE. The basement is never on a wall.
	var base = D.basement("Point_One")
	print("")
	print("basement (never rendered on a wall): %d" % base.size())
	for t in base:
		print("    %s" % t.get("thing", ""))
	if base.size() != 4:
		print("  FAIL expected 4 background things"); fails += 1
	for t in D.says("Point_One"):
		if str(t.get("status", "")) == "background":
			print("  FAIL a basement item reached the wall"); fails += 1

	# 5. a descent is OFFERED, and it is a real sentence
	var desc = D.descents("Point_One")
	print("")
	print("descents offered: %d" % desc.size())
	for t in desc:
		print("    %s -> %s" % [t.get("thing", ""), t.get("descend", "")])
	if desc.size() != 1:
		print("  FAIL expected exactly one glimpsed descent"); fails += 1

	# 6. the thrownness statement exists — it is the architecture, not decoration
	var th := str(D.thrownness())
	print("")
	print("thrownness: %s" % th.substr(0, 72))
	if th.length() < 40:
		print("  FAIL no thrownness statement to say at the entrance"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
