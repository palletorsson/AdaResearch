extends "res://tools/probes/transformation_encounters.gd"
var origin:Vector3
func at(p:Vector3)->Vector3:return origin+hall.global_basis*p
func landing_checks()->void:
	museum.call("flush_stamps")
	museum.get("_portal_stream").process_mode=Node.PROCESS_MODE_DISABLED
	var player=museum.get("_player");player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var exposure:=CameraAttributesPractical.new();exposure.exposure_multiplier=.5;camera.attributes=exposure
	var drones:=find_scene("/drone_comparison.gd")
	origin=drones.global_position-hall.global_basis*Vector3(20.5,0,6.5)
	await snapshot("above",at(Vector3(10,32,23)),at(Vector3(10,0,6.5)),73)
	await snapshot("room",at(Vector3(6.5,1.7,11)),at(Vector3(8,1.3,4)),85)
	var control:=find_scene("/flocking_controls.gd")
	if control!=null:
		observations.control=xyz(control.global_position)
		observations.panel=xyz(control._control_panel.global_position)
		await snapshot("controls",control.to_global(Vector3(.1,.9,1.7)),control.global_position,65)
func finish()->void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "));quit(0 if failures.is_empty() else 1)
