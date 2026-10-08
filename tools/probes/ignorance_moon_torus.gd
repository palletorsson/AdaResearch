extends "res://tools/probes/ignorance_form_in_hand.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.0).timeout
	var station := find_scene("/form_in_hand.gd")
	check("last bay and torus installed",station != null and station.moon_torus != null)
	if station == null: return
	var study: Node3D=station.moon_torus
	study.playing=false
	var torus: MeshInstance3D=study.body
	var moon: DirectionalLight3D=museum.get("_moon")
	check("existing museum moon casts shadows",moon!=null and moon.shadow_enabled)
	if moon == null: return
	museum.call("_aim_moon",0.0)
	check("torus centre is five metres above hall floor",is_equal_approx(torus.global_position.y-station.global_position.y,5.0))
	check("torus remains horizontal",torus.global_basis.y.is_equal_approx(Vector3.UP))
	check("real mesh casts the shadow",torus.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
	check("no second moon or fill lights added to the last bay",station.find_children("*","Light3D",true,false).is_empty())
	check("last bay has no low ceiling slab",station.find_children("*","MeshInstance3D",true,false).all(func(m): return not (m.mesh is BoxMesh and m.mesh.size.x>4 and m.position.y>3.0)))
	var radii := Vector2(study.form.inner_radius,study.form.outer_radius)
	var pose: Transform3D=torus.global_transform
	var previous: Vector2i=study.steps[0]
	for i in study.steps.size():
		study.set_step(i)
		var now: Vector2i=study.steps[i]
		check("one count changes at step "+str(i),now.x==previous.x or now.y==previous.y)
		check("valid native mesh at step "+str(i),study.form.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()>0 and now.x>=4 and now.y>=4)
		previous=now
	check("cycle joins without changing both counts",previous.x==study.steps[0].x or previous.y==study.steps[0].y)
	check("animation preserves radii, height and orientation",radii==Vector2(study.form.inner_radius,study.form.outer_radius) and torus.global_transform.is_equal_approx(pose))
	study.set_step(0);study.elapsed=0.0;study.playing=true;study._process(1.5);study.playing=false
	check("clock advances to the next resolution",study.step_index==1 and study.form.rings==32 and study.form.ring_segments==24)
	study.set_step(0)
	await snapshot("moon-court",station.to_global(Vector3(-3.7,1.7,-5.8)),station.to_global(Vector3(-0.6,2.4,0)),82)
	# Project along the actual moon ray. The image comparison below verifies its visible shadow.
	var direction := -moon.global_basis.z
	var centre := torus.global_position+direction*((station.global_position.y+0.015-torus.global_position.y)/direction.y)
	observations["shadow_centre"]=xyz(centre)
	observations["torus_centre"]=xyz(torus.global_position)
	observations["moon_direction"]=xyz(direction)
	var eye := centre+Vector3(-0.2,3.1,-4.4)
	await snapshot("shadow-fine",eye,centre,64)
	torus.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	await snapshot("shadow-control",eye,centre,64)
	torus.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	study.set_step(7)
	await snapshot("shadow-four-rings",eye,centre,64)
	study.set_step(13)
	await snapshot("moon-court-coarse",station.to_global(Vector3(-3.7,1.7,-5.8)),station.to_global(Vector3(-0.6,2.4,0)),82)
	await snapshot("torus-four-by-four",station.to_global(Vector3(-1.0,1.7,-3.0)),torus.global_position,66)
	study.set_step(0)
	# The earlier catalyst remains reachable and functional after the rearrangement.
	await station_checks(station)
