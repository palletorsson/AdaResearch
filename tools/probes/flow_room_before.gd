extends "res://tools/probes/transformation_encounters.gd"
var origin:Vector3
func at(p:Vector3)->Vector3:return origin+hall.global_basis*p
func landing_checks()->void:
	museum.call("flush_stamps")
	var stream=museum.get("_portal_stream");stream.process_mode=Node.PROCESS_MODE_DISABLED
	var player=museum.get("_player")
	player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var exposure:=CameraAttributesPractical.new();exposure.exposure_multiplier=.65;camera.attributes=exposure
	var table:=find_scene("/flow_direction_table.gd")
	check("Carried-point table is present",table!=null)
	if table==null:return
	origin=table.global_position-hall.global_basis*Vector3(4.5,0,2.5)
	observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
	await room_photos()
func room_photos()->void:
	await snapshot("above",at(Vector3(16,34,27)),at(Vector3(16,0,7)),68)
	await snapshot("gallery",at(Vector3(6.5,1.7,7.5)),at(Vector3(6.5,1.05,2.5)),85)
	await snapshot("passage",at(Vector3(9,1.7,5.5)),at(Vector3(20,1.1,7.5)),83)
func finish()->void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if failures.is_empty() else 1)
