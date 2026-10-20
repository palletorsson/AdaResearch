extends "res://tools/probes/transformation_encounters.gd"
var origin:Vector3
func at(p:Vector3)->Vector3:return origin+hall.global_basis*p
func landing_checks()->void:
	museum.call("flush_stamps")
	museum.get("_portal_stream").process_mode=Node.PROCESS_MODE_DISABLED
	var player=museum.get("_player");player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var exposure:=CameraAttributesPractical.new();exposure.exposure_multiplier=.5;camera.attributes=exposure
	var colony:=find_scene("/AntColonyOptimization.gd")
	check("Original colony present",colony!=null)
	if colony==null:return
	origin=colony.global_position-hall.global_basis*Vector3(4.5,0,4.5)
	origin.y=hall.global_position.y
	await snapshot("above",at(Vector3(11,29,19)),at(Vector3(11,0,5)),70)
	await snapshot("room",at(Vector3(6.5,1.7,8.3)),at(Vector3(8.5,1.2,3.5)),80)
	await snapshot("table",at(Vector3(9.5,2.8,6.6)),at(Vector3(9.5,1.1,3.5)),70)
func finish()->void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "));quit(0 if failures.is_empty() else 1)
