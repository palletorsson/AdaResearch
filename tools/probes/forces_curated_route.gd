extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.set_process(true);museum.set_physics_process(true)
	var portal=museum.get("_portal_stream")
	var settling=Time.get_ticks_msec()
	while portal.busy and Time.get_ticks_msec()-settling<20000:await process_frame
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/force_halls/curation.json"))
	var rows: Array=plan.halls
	for i in rows.size():
		var current: Dictionary=portal.get("_current")
		check("arrives at "+str(rows[i].map),str(current.get("map",""))==rows[i].map)
		check("one resident hall",museum.get("_segments").size()==1)
		var exit_data: Dictionary=portal.get("_exit")
		observations[rows[i].map]={"exit":exit_data,"next":museum.call("_peek_next_authored_map")}
		check("exit clear",exit_data.has("door") and not exit_data.get("invalid",false))
		check("arrival supported",portal.call("_arrival_supported"))
		if i<rows.size()-1:
			check("forward crossing accepted",portal.request_crossing(1))
			var t=Time.get_ticks_msec()
			while portal.busy and Time.get_ticks_msec()-t<15000:await process_frame
			check("crossing completes",not portal.busy)
			if portal.busy:break
	check("previous hall accepted",portal.request_crossing(-1))
	var t=Time.get_ticks_msec()
	while portal.busy and Time.get_ticks_msec()-t<15000:await process_frame
	check("returns to collision hall",not portal.busy and str(portal.get("_current").get("map",""))==rows[11].map)

func finish() -> void:
	var result={"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Thirteen actual canonical halls forward and one back through the museum portal coordinator. Supplied crossing requests; headset untested."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("FORCES CURATED ROUTE ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
