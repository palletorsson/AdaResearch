extends "res://tools/probes/transformation_encounters.gd"
var study:Node3D
func landing_checks()->void:
	museum.call("flush_stamps");museum.get("_portal_stream").process_mode=Node.PROCESS_MODE_DISABLED
	var player=museum.get("_player");player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var exposure:=CameraAttributesPractical.new();exposure.exposure_multiplier=.5;camera.attributes=exposure
	study=find_scene("/population_account_walk.gd")
	check("Existing Population Support lesson present",study!=null)
	if study==null:return
	study.restart()
	await snapshot("above",study.to_global(Vector3(0,28,18)),study.to_global(Vector3(0,0,0)),62)
	await snapshot("field",study.to_global(Vector3(1,1.7,5.8)),study.to_global(Vector3(-.7,1.2,0)),82)
	await snapshot("controls",study.to_global(Vector3(-2.5,1.85,8)),study.to_global(Vector3(-2.5,1.2,6.8)),78)
func finish()->void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "));quit(0 if failures.is_empty() else 1)
