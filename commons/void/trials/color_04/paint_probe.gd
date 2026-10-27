extends "res://commons/void/trials/color_04/probe.gd"
## Focused diagnostic while the second floor is being transferred.
func visit(use_xr: bool) -> void:
	level=1; await start(use_xr)
	await paint_checks("XR: " if xr else "Desktop: ")
	if not xr: await capture_floor()
	# XRTools defers removal of the hand/body collision exceptions after release.
	await frames(180)
	game.queue_free(); await frames(10)
	if xr:
		for item in [head,left,right]: XRServer.remove_tracker(item)
