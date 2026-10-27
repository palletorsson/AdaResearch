extends "res://commons/void/trials/machinelearning/probe.gd"
func run() -> void:
	for use_xr in [false,true]:
		level=1;await start(use_xr)
		var gradient:Node3D=artifact("gradient_descent_visualization")
		game.place_player(gradient.to_global(Vector3(0,.06,4)));await frames(30)
		var before:int=gradient._mode
		await press(gradient._mode_button);check(str(xr)+" MODE",gradient._mode==(before+1)%3)
		before=gradient.function_preset
		await press(gradient._fn_button);check(str(xr)+" FUNCTION",gradient.function_preset==(before+1)%gradient.BASINS.size())
		game.queue_free();await frames(10)
		if xr:
			for t in [head,left,right]:XRServer.remove_tracker(t)
	quit(0 if failed.is_empty() else 1)
