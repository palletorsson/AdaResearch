extends "res://commons/void/trials/forces_03/probe.gd"
func run() -> void:
	trial="forces_03"
	for use_xr in [false,true]:
		await start(use_xr)
		for f in [4,5]:
			level=f;game.place_player(game.spawn_for(f));await frames(40)
			await focused_checks(("XR: " if xr else "Desktop: ")+"focused: ")
		game.queue_free();await frames(10)
		if xr:
			for t in [head,left,right]:XRServer.remove_tracker(t)
	print("FOCUSED_RESULT ",failed)
	quit(0 if failed.is_empty() else 1)
