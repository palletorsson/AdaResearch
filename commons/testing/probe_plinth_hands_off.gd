extends SceneTree
## DOES THE AUTOMATIC CURATOR KEEP ITS HANDS OFF?
##
## 2026-09-08, Palle: "in the endless museum map there is a platform under these
## artifact ... I think it related to auto config of the museum, the museum add
## plinth to some artifacts. remove plinth to the artifact."
##
## He was right and the map was innocent: in Point_Triangle_Context both cells
## are plain floor '1' with empty utilities, neither token carries #plinth:, the
## grid builds a support only for #plinth:, and neither artifact's .gd or .tscn
## draws a base. em_plinths decided by itself, from the token's NAME and a live
## AABB.
##
## THE PATH THAT MATTERS IS plan_measured(), NOT plan(). Neither token is in
## artifact_sizes.json — nor is line_demo, which has been on this list since
## 2026-09-01 — so plan() refuses them anyway with "unmeasured" and would make
## this probe pass for the wrong reason. plan_measured is what the museum calls
## with a height it measured itself, and it is the one that must refuse.
##
## The NEGATIVE is the point: a token NOT on the list, with the same dimensions,
## must still be plinthed. Without it this passes on a curator that plinths
## nothing at all.

const PLINTHS := "res://commons/scenes/em/em_plinths.gd"


func _init() -> void:
	var fails := 0
	var P: GDScript = load(PLINTHS) as GDScript
	if P == null:
		print("  FAIL em_plinths.gd will not load")
		quit(1)
		return

	# a low, small body on a floor cell — exactly the shape the curator lifts
	var cell := {"top": 0.0, "rank": "1s"}
	var H := 0.35     # short enough that the band wants to raise it
	var B := 0.60
	var named := ["folded_strip", "triangleprofiles", "line_demo"]

	print("HANDS OFF — plan_measured(h=%.2f, base=%.2f) on a floor cell" % [H, B])
	for t in named:
		var r: Dictionary = P.call("plan_measured", t, cell, H, B)
		var needs: bool = bool(r.get("needs", false))
		print("  %-18s needs=%-5s  %s" % [t, needs, str(r.get("why", "")).substr(0, 62)])
		# ONLY needs=false is asserted here. An earlier version also demanded the
		# reason contain "hands off", and failed the moment the curator was
		# switched off globally and started answering "the automatic curator is
		# off" instead — a green requirement turned red by a change that made the
		# outcome MORE correct. Assert the outcome; the reason is checked below,
		# where the list is the only thing that can produce it.
		if needs:
			print("    FAIL the curator still puts a plinth under it"); fails += 1

	# THE NEGATIVE, AND IT IS INVERTED NOW (2026-09-08, Palle: "just remove the
	# auto-plinth function we need more control"). With the curator OFF, a token
	# nobody excluded must ALSO be refused — that is the whole change. So the
	# thing that must still work is the SWITCH: flipping "auto" back to true has
	# to make the curator deal again, or this file has silently become dead code
	# and the tokens list above is decoration.
	var ctrl: Dictionary = P.call("plan_measured", "a_token_nobody_excluded", cell, H, B)
	print("")
	print("control, curator OFF: needs=%s  %s"
		% [bool(ctrl.get("needs", false)), str(ctrl.get("why", "")).substr(0, 58)])
	if bool(ctrl.get("needs", false)):
		print("  FAIL the curator is still dealing plinths"); fails += 1

	# THE SWITCH STILL WORKS. Forced in memory rather than by writing the file —
	# a probe must never edit what a live session reads.
	P.set("_auto_on", true)
	var on_ctrl: Dictionary = P.call("plan_measured", "a_token_nobody_excluded", cell, H, B)
	var on_named: Dictionary = P.call("plan_measured", "folded_strip", cell, H, B)
	print("with auto:true  unlisted needs=%s | folded_strip needs=%s (must be true, false)"
		% [bool(on_ctrl.get("needs", false)), bool(on_named.get("needs", false))])
	if not bool(on_ctrl.get("needs", false)):
		print("  FAIL the switch does not turn it back on — the curator is dead code,")
		print("       and the OFF result above proves nothing"); fails += 1
	if bool(on_named.get("needs", false)):
		print("  FAIL with auto on, the hands-off list stopped being honoured"); fails += 1
	elif not str(on_named.get("why", "")).contains("hands off"):
		print("  FAIL with auto on, folded_strip is refused for some OTHER reason —")
		print("       the list is not what is protecting it, and would not protect")
		print("       the next token added to it"); fails += 1
	P.set("_auto_on", false)

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
