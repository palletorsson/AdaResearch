extends "res://tools/probes/forces_layout.gd"

func landing_checks() -> void:
	await super.landing_checks()
	camera.set_cull_mask_value(19,false)
	var wardrobe: Node=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").visible=false
	for e in get_nodes_in_group("force_play"):
		if not hall.is_ancestor_of(e):continue
		if e.kind=="friction":
			await snapshot("basin-ramps",e.to_global(Vector3(12,6,-10)),e.to_global(Vector3(0,1,0)),74)
			e.action("RELEASE");await create_timer(4).timeout
			await snapshot("basin-trails",e.to_global(Vector3(-9,2.2,8.6)),e.to_global(Vector3(0,0.6,0)),75)
			check("Four slope bodies remain inside their basin",e.members.runners.all(func(b):return b.position.z<7.75 and b.position.y>0.1))
		if e.kind=="swings":
			check("Museum seats refuse direct XR pickup",e.bodies.all(func(b):return not b.enabled and b.get_meta("force_constraint_body",false)))
			await snapshot("take-the-stick",e.to_global(Vector3(-12.6,1.7,-8.3)),e.to_global(Vector3(-10.8,1.5,-3.4)),58)
			await snapshot("stick-and-swings",e.to_global(Vector3(-11,1.75,-6)),e.to_global(Vector3(-5,1.5,0)),73)
			e.action("NUDGE");await create_timer(0.7).timeout
			await snapshot("swings-in-motion",e.to_global(Vector3(-7,1.65,-5)),e.to_global(Vector3(-7.4,1.8,0)),70)
		if e.kind=="springs":
			check("Spring points now use seven force-transmitting grips",e.grips.size()==7 and e.bodies.all(func(b):return not b.enabled))
			await snapshot("spring-points",e.to_global(Vector3(-7,1.65,-5.7)),e.to_global(Vector3(0,1.7,0)),74)
	var pedestal=hall.find_child("ForcesCatalyst",true,false)
	if map_id in ["VFM_03_Motion","Vectors_Act4b_Oscillation","VFM_08_Arena"]:
		check("Existing full catalyst is offered in the hall",pedestal!=null)
		if pedestal!=null:
			var catalyst=pedestal.get("_crystal")
			check("Catalyst starts in Forces with no timed lease",catalyst!=null and catalyst.home_sequence=="forces" and catalyst._get_current_mode_def().id=="forces" and catalyst.lease_s==0)
			await snapshot("catalyst",pedestal.global_position+Vector3(-1.5,1.4,2.0),pedestal.global_position+Vector3.UP*0.8,60)
	observations.physics_engine=ProjectSettings.get_setting("physics/3d/physics_engine")
