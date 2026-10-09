extends "res://tools/probes/force_trials.gd"
## Exercise the museum's real portal coordinator through the optional route.
func landing_checks() -> void:
	museum.set_process(true);museum.set_physics_process(true)
	var portal=museum.get("_portal_stream")
	var settling=Time.get_ticks_msec()
	while portal.busy and Time.get_ticks_msec()-settling<20000:await process_frame
	var sequence=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/sequences/forces_review.json"))
	var maps: Array=sequence.sequences.forces_review.maps
	for i in range(10):
		var current: Dictionary=portal.get("_current")
		check("route: arrives at "+str(maps[i]),str(current.get("map",""))==maps[i])
		check("route: one resident museum hall",museum.get("_segments").size()==1)
		var exit_data: Dictionary=portal.get("_exit")
		observations[maps[i]]={"exit":exit_data,"next":museum.call("_peek_next_authored_map")}
		check("route: authored exit clear in "+str(maps[i]),exit_data.has("door") and not exit_data.get("invalid",false))
		check("route: visitor arrival supported",portal.call("_arrival_supported"))
		if i<9:
			check("route: accepts forward crossing",portal.request_crossing(1))
			var t=Time.get_ticks_msec()
			while portal.busy and Time.get_ticks_msec()-t<15000:await process_frame
			check("route: crossing completes",not portal.busy)
			if portal.busy:break
	check("route: accepts previous hall",portal.request_crossing(-1))
	var t=Time.get_ticks_msec()
	while portal.busy and Time.get_ticks_msec()-t<15000:await process_frame
	check("route: returns to bowling",not portal.busy and str(portal.get("_current").get("map",""))==maps[8])
	observations.scope="Actual museum portal transitions: ten halls forward, one back. Supplied crossing requests; headset untested."

func finish() -> void:
	var result={"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()}
	FileAccess.open("res://doc/book/iterations/2026-10-07-forces-ten-more/navigation-checks.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("FORCE ROUTE ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
