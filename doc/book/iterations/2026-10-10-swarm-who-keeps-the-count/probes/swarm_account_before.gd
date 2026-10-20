extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps")
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.process_mode=Node.PROCESS_MODE_DISABLED
	var player=museum.get("_player")
	if player is Node3D:
		player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.35;camera.attributes=attributes
	var s=find_scene("/ecosystem.gd")
	check("Original ecosystem exists",s!=null)
	if s==null:return
	s.set_process(false)
	var origin:Vector3=s.global_position-hall.global_basis*Vector3(5.5,.8,6.5);origin.y=hall.global_position.y
	await snapshot("eye-before",origin+hall.global_basis*Vector3(6.5,1.7,2.5),s.global_position+Vector3.UP*.5,70)
	await snapshot("above-before",origin+hall.global_basis*Vector3(6.5,23,21),origin+hall.global_basis*Vector3(6.5,0,6.5),60)
