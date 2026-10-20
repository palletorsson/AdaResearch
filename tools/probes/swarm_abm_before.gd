extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps")
	var stream= museum.get("_portal_stream")
	if stream != null:stream.process_mode=Node.PROCESS_MODE_DISABLED
	var player= museum.get("_player")
	if player is Node3D:
		player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.35;camera.attributes=attributes
	var colony:=find_scene("/AntColonyOptimization.gd")
	check("Existing colony loaded",colony!=null)
	if colony==null:return
	var origin:Vector3=colony.global_position-hall.global_basis*Vector3(4.5,0,4.5)
	origin.y=hall.global_position.y
	observations.origin=xyz(origin)
	observations.colony=xyz(colony.global_position)
	await snapshot("above-before",origin+hall.global_basis*Vector3(6.5,20,16),origin+hall.global_basis*Vector3(6.5,0,5),60)
	await snapshot("colony-before",colony.to_global(Vector3(0,2.6,-3)),colony.to_global(Vector3(0,2,0)),65)
func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "))
	quit(0 if failures.is_empty() else 1)
