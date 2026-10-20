extends "res://tools/probes/transformation_encounters.gd"
## Actual museum transition coordinator; supplied crossing requests, no headset.
func landing_checks()->void:
	museum.set_process(true);museum.set_physics_process(true)
	var portal=museum.get("_portal_stream")
	var start:=Time.get_ticks_msec()
	while portal.busy and Time.get_ticks_msec()-start<20000:await process_frame
	check("Starts in Flow Fields",portal.get("_current").get("map","")=="SwarmIntelligence_FlowFields")
	check("Flow Fields arrival is supported",portal.call("_arrival_supported"))
	check("Flow Fields has valid authored entry and exit",not portal.get("_entry").get("invalid",false) and not portal.get("_exit").get("invalid",false))
	check("Forward crossing accepted",portal.request_crossing(1))
	start=Time.get_ticks_msec()
	while portal.busy and Time.get_ticks_msec()-start<40000:await process_frame
	check("Forward crossing completes",not portal.busy and portal.get("failure")=="")
	observations.next_map=portal.get("_current").get("map","")
	check("Arrives at the next Boids hall",observations.next_map=="SwarmIntelligence_Boids_Algorithm")
	check("Next hall arrival is supported",portal.call("_arrival_supported"))
	check("Only one hall is resident",museum.get("_segments").size()==1)
	check("Return crossing accepted",portal.request_crossing(-1))
	start=Time.get_ticks_msec()
	while portal.busy and Time.get_ticks_msec()-start<40000:await process_frame
	check("Returns to Flow Fields",not portal.busy and portal.get("_current").get("map","")=="SwarmIntelligence_FlowFields")
	check("Returned arrival is supported",portal.call("_arrival_supported"))
	check("One hall remains after return",museum.get("_segments").size()==1)
	observations.events=portal.get("events")
	observations.headset_tested=false
func finish()->void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if failures.is_empty() else 1)
