extends "res://tools/probes/forces_layout.gd"
const VIEWS={
"bubble_blaster":[Vector3(2.2,1.6,-2.8),Vector3(0,0.25,0)],
"catapult":[Vector3(5,3,-5),Vector3(0,1.2,2)],
"human_catapult":[Vector3(4,2.2,6),Vector3(0,1,1)],
"firework_burst":[Vector3(8,2.2,-9),Vector3(0,3,0)],
"force_mower":[Vector3(-4,2,-4),Vector3(0,0.6,0)],
"wind_room":[Vector3(-7,1.8,-7),Vector3(0,1.4,1)],
"force_vortex":[Vector3(5,1.75,-6),Vector3(0,1.5,0)],
"viscosity_layers":[Vector3(1.7,1.1,2.4),Vector3(0,0.6,0)],
"centrifuge_ring":[Vector3(6,2.0,-6),Vector3(0,1.0,0)],
"SpringSuspension":[Vector3(4,2.1,5),Vector3(0,2,0)],
"spring_tower":[Vector3(4,2.2,-6),Vector3(0,2.6,0)],
"orbit_walk":[Vector3(5,1.75,-6),Vector3(0,2,0)],
"momentum_cradle":[Vector3(1.8,1.8,2.4),Vector3(0,1.0,0)],
"newton_cradle":[Vector3(1.6,0.9,2.2),Vector3(0,0.5,0)],
"launch_arc":[Vector3(-5,1.75,6),Vector3(0,1,0)]}

func landing_checks() -> void:
	await super.landing_checks()
	camera.set_cull_mask_value(19,false)
	var wardrobe: Node=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").visible=false
	var selection=JSON.parse_string(FileAccess.get_file_as_string("res://doc/vector_forces_selected.json"))
	observations.selected=[]
	for item in selection.artifacts:
		if item.map!=map_id:continue
		var obj: Node3D=null
		for record in museum.get("_edit_records"):
			if record.get("seg")==hall and record.get("token")==item.token:obj=record.node;break
		check("selected artifact placed: "+item.token,obj!=null)
		if obj==null:continue
		observations.selected.append({"id":item.token,"scale":xyz(obj.global_basis.get_scale()),"world":xyz(obj.global_position)})
		if item.token=="firework_burst":
			var f=obj.get_node_or_null("LiveFountain")
			check("large live firework variant in museum",f!=null)
			if f!=null:
				f.manual_pause=true;f.simulation_time=0.85;f.update_picture();f.status.text="HELD IN TIME / the museum is still running"
		if item.token=="viscosity_layers":
			obj._drop_all();await create_timer(0.25).timeout;obj.set_physics_process(false)
		if item.token=="bubble_blaster":obj._on_grab(null,null);await create_timer(0.4).timeout
		var view=VIEWS[item.token]
		await snapshot(item.token,obj.to_global(view[0]),obj.to_global(view[1]),65)
		if item.token=="viscosity_layers":obj.set_physics_process(true)
		if item.token=="bubble_blaster":obj._on_drop(null)
		if item.token=="wind_room":
			var w=obj.get_node_or_null("HandsOnWind")
			check("wind upgrade retains all eight dynamic bodies",w!=null and w.bodies.size()==8)
			if w!=null:
				w.buttons.TURN.pressed.emit();await create_timer(0.6).timeout
				await snapshot("wind-turned",obj.to_global(Vector3(7,2.6,-7)),obj.to_global(Vector3(0,1.3,0)),68)
		if item.token=="SpringSuspension":
			check("museum owns spring display camera",obj.find_children("*","Camera3D",true,false).is_empty())
		if item.token in ["firework_burst","wind_room","centrifuge_ring","SpringSuspension"]:
			check(item.token+" keeps metre scale",obj.global_basis.get_scale().is_equal_approx(Vector3.ONE))
	observations.physics_engine=ProjectSettings.get_setting("physics/3d/physics_engine")
