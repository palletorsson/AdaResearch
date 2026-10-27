extends "res://commons/void/trials/tiling_03/probe.gd"

# Reproduce the fifth view without changing the acceptance receipt.
func run() -> void:
	trial = "tiling_03"
	out = "res://commons/void/trials/tiling_03/evidence"
	take_photos = true
	await start(false)
	level = 5
	game.place_player(game.spawn_for(level))
	await frames(120)
	await capture_floor()
	game.queue_free()
	await frames(5)
	quit()
