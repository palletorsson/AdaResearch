extends "res://tools/probes/transformation_encounters.gd"
const ABM="SwarmIntelligence_Ant_Colony_Optimization"
const ACO="SwarmIntelligence_Particle_Swarm_Optimization"
func landing_checks()->void:
	museum.set_process(true);museum.set_physics_process(true)
	var portal=museum.get("_portal_stream");var start:=Time.get_ticks_msec()
	while portal.busy and Time.get_ticks_msec()-start<20000:await process_frame
	check("Starts in Ant Colony",portal.get("_current").get("map","")==ABM)
	check("Ant Colony arrival supported",portal.call("_arrival_supported"))
	check("Ant Colony authored entry and exit clear",not portal.get("_entry").get("invalid",false) and not portal.get("_exit").get("invalid",false))
	check("Forward crossing accepted",portal.request_crossing(1));start=Time.get_ticks_msec()
	while portal.busy and Time.get_ticks_msec()-start<40000:await process_frame
	check("Arrives in Particle Swarm",not portal.busy and portal.get("_current").get("map","")==ACO)
	check("Next arrival supported",portal.call("_arrival_supported"))
	check("One resident hall",museum.get("_segments").size()==1)
	check("Return crossing accepted",portal.request_crossing(-1));start=Time.get_ticks_msec()
	while portal.busy and Time.get_ticks_msec()-start<40000:await process_frame
	check("Returns to Ant Colony",not portal.busy and portal.get("_current").get("map","")==ABM)
	check("Returned arrival supported",portal.call("_arrival_supported"))
	check("One resident hall after return",museum.get("_segments").size()==1)
	observations.events=portal.get("events");observations.headset_tested=false
func finish()->void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "));quit(0 if failures.is_empty() else 1)
