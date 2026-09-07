extends SceneTree
## THREE BITES SPEND THE BAR, AND THE THIRD IS A DEATH.
##
## 2026-09-07, Palle: "The death sequence should be connected with the player
## health game manager and should go to the death scene then click to reload back
## to the same map."
##
## The museum used to count bites to three and kill; now a bite spends a third of
## the health bar and GameManager's own death sequence ends it. That makes the
## wrist readout the truth instead of a decoration — and it is the arithmetic here
## that decides whether "three bites" still means three bites.
##
## WHAT THIS CANNOT TEST, said plainly rather than implied: endless_museum.gd
## names GameManager, and a `extends SceneTree` probe has no autoloads, so it
## cannot load the museum at all. The handover, the death scene and the return
## trip are unverified by anything here and are read-only reasoning until Palle
## walks it. What IS testable is the health lane the whole chain now hangs on.

func _init() -> void:
	var fails := 0
	var gm = load("res://commons/managers/GameManager.gd").new()
	get_root().add_child(gm)
	await process_frame

	var maxh: float = float(gm.get("max_player_health"))
	print("max health: %.0f" % maxh)
	if maxh <= 0.0:
		print("  FAIL no health to spend"); fails += 1
		quit(1)
		return

	var died := [false]
	if gm.has_signal("player_died"):
		gm.connect("player_died", func(_p): died[0] = true)

	var bite: float = maxh / 3.0
	for i in range(1, 4):
		gm.call("apply_bite_damage", bite)
		print("  bite %d -> health %.1f" % [i, float(gm.get("player_health"))])

	var left: float = float(gm.get("player_health"))
	print("")
	print("after three bites: health %.2f (want 0)" % left)
	if left > 0.01:
		print("  FAIL three bites no longer kill — the feel changed"); fails += 1

	# THE NEGATIVE: two bites must NOT kill, or the bar is theatre and the third
	# bite is doing nothing the second did not already do.
	var gm2 = load("res://commons/managers/GameManager.gd").new()
	get_root().add_child(gm2)
	await process_frame
	gm2.call("apply_bite_damage", bite)
	gm2.call("apply_bite_damage", bite)
	var two: float = float(gm2.get("player_health"))
	print("after TWO bites:   health %.2f (must be > 0)" % two)
	if two <= 0.01:
		print("  FAIL two bites kill — that is not the three-bite museum"); fails += 1
	if abs(two - maxh / 3.0) > 0.5:
		print("  FAIL two bites did not leave a third of the bar"); fails += 1

	# and a bite of zero or less must do nothing at all
	var before: float = float(gm2.get("player_health"))
	gm2.call("apply_bite_damage", 0.0)
	gm2.call("apply_bite_damage", -50.0)
	if abs(float(gm2.get("player_health")) - before) > 0.001:
		print("  FAIL a zero or negative bite moved the bar"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
