extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(2.0).timeout
	for node in root.find_children("*", "Node", true, false):
		if node.get_script()!=null and str(node.get_script().resource_path).ends_with("/MushroomHand.gd"):
			var hud:CanvasLayer=node.get("_hud")
			if hud!=null:hud.visible=false
	match map_id:
		"Symmetry_Seventeen":await symmetry()
		"Ribbon_Patterns_02":await contrast()
		"Ribbon_Patterns_03":await turret()

func symmetry() -> void:
	var lesson=find_scene("/symmetry_compare_lesson.gd")
	check("authored symmetry lesson present in loaded museum",lesson!=null)
	if lesson==null:return
	observations["lesson_world"]=xyz(lesson.global_position)
	var source=lesson.puzzle.get_pattern_data().duplicate(true)
	var original_held:PackedByteArray=lesson.held.material_override.albedo_texture.get_image().get_data()
	check("held comparison begins as P1",lesson.held_label.text.contains("P1"))
	lesson.buttons["PG"].pressed.emit()
	await tick()
	check("actual PG button selects glide",lesson.group_index==2)
	check("changing rule preserves source cells",lesson.puzzle.get_pattern_data()==source)
	check("held P1 pixels remain unchanged",lesson.held.material_override.albedo_texture.get_image().get_data()==original_held)
	check("live glide pixels differ from held translation",lesson.live.material_override.albedo_texture.get_image().get_data()!=original_held)
	check("caption explains the two-row shift",lesson.status.text.contains("2 SOURCE ROWS"))
	await snapshot("symmetry-p1-pg",lesson.to_global(Vector3(0,1.7,5.8)),lesson.to_global(Vector3(0,1.7,-1.2)),62)
	await snapshot("symmetry-side-bay",lesson.to_global(Vector3(-3.0,1.7,6.0)),lesson.to_global(Vector3(0,1.55,-0.4)),68)
	var gallery=find_scene("/wall_pattern_gallery.gd")
	var atlas=find_scene("/pattern_atlas_gallery.gd")
	observations["gallery_present"]=gallery!=null
	observations["atlas_present"]=atlas!=null
	var groups={}
	if gallery!=null:
		for node in gallery.find_children("*","MeshInstance3D",true,false):
			var material=node.material_override
			if material is ShaderMaterial:
				var value=material.get_shader_parameter("wallpaper_group")
				if value!=null:groups[str(value)]=true
	observations["gallery_rendered_group_values"]=groups.keys()
	if atlas!=null:
		observations["atlas_credit_mode"]=atlas.credit
		await snapshot("symmetry-gallery",atlas.to_global(Vector3(1.8,1.7,7.3)),atlas.to_global(Vector3(0,1.5,0)),66)

func contrast() -> void:
	var lesson:Node3D
	for node in hall.find_children("*","Node3D",true,false):
		if node.get_script()!=null and str(node.get_script().resource_path).ends_with("/carrier_comparison.gd") and node.get("mode")=="context":lesson=node;break
	check("authored contrast lesson present in loaded museum",lesson!=null)
	if lesson==null:return
	observations["lesson_world"]=xyz(lesson.global_position)
	var unchanged=[]
	for sample in lesson.samples:unchanged.append(sample.material_override.albedo_color)
	await snapshot("contrast-neighbours",lesson.to_global(Vector3(0,1.7,4.3)),lesson.to_global(Vector3(0,1.7,0)),98)
	lesson.buttons["SURROUNDS"].pressed.emit()
	await tick()
	check("real SURROUNDS button selects equal backgrounds",lesson.neutral)
	var equal=true
	for i in 2:
		equal=equal and lesson.samples[i].material_override.albedo_color==unchanged[i] and lesson.backgrounds[i].material_override.albedo_color==unchanged[i]
	check("targets preserved and surrounds match their RGB",equal)
	await snapshot("contrast-equal",lesson.to_global(Vector3(0,1.7,4.3)),lesson.to_global(Vector3(0,1.7,0)),98)
	lesson.buttons["UNDO"].pressed.emit()
	check("UNDO restores unequal surrounds",not lesson.neutral)

func turret() -> void:
	var t=find_scene("/laser_turret.gd")
	var studio=find_scene("/fabric_shader_studio.gd")
	check("exit turret present in actual loaded hall",t!=null)
	if t==null:return
	check("map configuration excludes the visitor",not t.target_player)
	check("existing scene range retained",is_equal_approx(t.detection_range,25.0))
	observations["turret_world"]=xyz(t.global_position)
	t.set_process(false)
	# This renderer has no tracked XR body. Supply the actual resolver's group/node
	# contract for selection only; do not claim headset damage/locomotion tests.
	var xr_fixture=Node3D.new();xr_fixture.name="ReviewXRTargetFixture"
	hall.add_child(xr_fixture);xr_fixture.add_to_group("xr_origin")
	var xr_head=Node3D.new();xr_head.name="XRCamera3D";xr_fixture.add_child(xr_head)
	var player=t._find_player()
	check("production player resolver finds supplied XR target contract",player==xr_head)
	if player!=null:
		var old:Vector3=player.global_position
		player.global_position=t.global_position+Vector3(0,1,1)
		t._lose_target();t._find_target()
		check("nearby visitor is not selected",t.current_target!=player)
		# A supplied ball tests the retained selection branch without firing or damage.
		var ball=Node3D.new();ball.name="ReviewProbeBall";hall.add_child(ball);ball.global_position=t.global_position+Vector3(0,0.2,0)
		t._lose_target();t._find_target()
		check("ball hunting still selects a nearby ball",t.current_target==ball)
		t._lose_target();ball.free()
		t.apply_grid_config({"target_player":true});t._acquire_target(player)
		check("other placements can still opt into player targeting",t.target_player and t.current_target==player)
		t.apply_grid_config({"target_player":"false"})
		check("disabling player targeting releases an existing player lock",not t.target_player and t.current_target==null)
		t.apply_grid_config({"target_player":"unrecognised"})
		check("unrecognised config does not change targeting policy",not t.target_player)
		player.global_position=old
	xr_fixture.free()
	var default=load("res://commons/artifacts/turret_targeting/laser_turret.tscn").instantiate()
	check("other turret placements retain original defaults",default.target_player and is_equal_approx(default.detection_range,25.0))
	default.free()
	await snapshot("ribbon-exit",t.to_global(Vector3(-6.0,1.7,-3.5)),t.to_global(Vector3(-1.5,1.1,1.5)),67)
	if studio!=null:
		await snapshot("fabric-studio",studio.to_global(Vector3(1.8,1.7,6.8)),studio.to_global(Vector3(0,1.7,0)),67)
