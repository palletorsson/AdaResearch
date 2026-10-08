extends "res://commons/testing/probe_point_one_radio.gd"
## Add eye-to-text occlusion checks to the real hall placement probe.
func capture(tag: String) -> void:
	if tag=="radio-operating":
		report.readouts=[]
		for control in [artifact.tuning_control,artifact.volume_control]:
			var screen: MeshInstance3D=control._reading.screen
			var blocked:=0
			for x in [-.045,0,.045]:
				for y in [-.009,0,.009]:
					var target:=screen.to_global(Vector3(x,y,0))
					var ray:=PhysicsRayQueryParameters3D.create(camera.global_position,target,1|(1<<20)|(1<<22))
					if walker:ray.exclude=[walker.get_rid()]
					var hit:=museum.get_world_3d().direct_space_state.intersect_ray(ray)
					if not hit.is_empty():blocked+=1
			report.readouts.append({"control":str(control.name),"blocked_samples":blocked,"samples":9})
			check(blocked==0,str(control.name)+" numeric window clears grips from standing eye")
	await super.capture(tag)

	if tag=="radio-approach":
		var tune:Transform3D=artifact.tuning_control.transform
		var selected:int=artifact.current_station
		var level:float=artifact.target_volume_db
		for face in ["scale","presets","list","void"]:
			artifact.apply_grid_config({"face":face,"orientation":"inclined"})
			check(artifact.tuning_control.transform.is_equal_approx(tune),face+": refreshing face does not accumulate mount rotation")
			check(artifact.current_station==selected and is_equal_approx(artifact.target_volume_db,level),face+": mount preserves station and gain")
		artifact.apply_grid_config({"orientation":"upright"})
		check(artifact.tuning_control.basis.is_equal_approx(Basis.IDENTITY),"Upright option restores authored control frame")
		artifact.apply_grid_config({"orientation":"inclined","face":"scale"})
		check(artifact.tuning_control.transform.is_equal_approx(tune),"Incline can be restored without drift")
		artifact.apply_grid_config({"orientation":"unknown"})
		check(artifact.tuning_control.transform.is_equal_approx(tune),"Unknown mount option leaves the current placement intact")
