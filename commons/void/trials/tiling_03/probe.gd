extends "res://commons/void/trials/tiling_02/probe.gd"
## Reuse the already-tested hand and panel helpers, not the previous lessons.
func expected_empty_source(node: Node3D) -> bool:
	return node.get_script().resource_path=="res://commons/void/pattern_empty_preview.gd" and node.group=="unset" and node.config_path.is_empty()

func focused_checks(tag: String) -> void:
	check(tag+"standard floor "+str(level),game.building.spec.width==42 and game.building.spec.depth==32 and game.building.spec.storey_height==6)
	for i in 30:await frames(1)
	match level:
		1:await address_checks(tag)
		2:await symmetry_checks(tag)
		3:await temple_checks(tag)
		4:await layer_checks(tag)
		5:await colour_checks(tag)
	game.place_player(game.spawn_for(level));await frames(15)

func address_checks(tag: String) -> void:
	await puzzle_checks(tag,"pattern_tile_4x4")
	var m:Node3D=artifact("pattern_tunnel_machine")
	var lesson:Node3D=m.address_lesson
	check(tag+"original six metre address passage",m.tunnel_length==6 and lesson.platform_route)
	await approach(lesson.panel,.9)
	var col:int=lesson.column
	await press(lesson.buttons["COL +"])
	check(tag+"COL moves addressed cell",lesson.column!=col)
	await press(lesson.buttons["FACE"])
	check(tag+"same address can be read on wall",lesson.face==1)
	await press(lesson.buttons["CELL SIZE"])
	check(tag+"cell size changes repetition not carrier",is_equal_approx(lesson.pitch,.6) and m.tunnel_length==6)
	await press(lesson.buttons["UNDO"])
	check(tag+"UNDO restores pitch",is_equal_approx(lesson.pitch,.4))
	check(tag+"local miniature initialized",artifact("grid_model")._initialized)
	check(tag+"original four-shaft loom populated",artifact("panel_bridge_loom").panel_bridge.data_store.shafts==4)

func symmetry_checks(tag: String) -> void:
	for key in ["loom_escher_mirror","loom_alhambra_p6m","mill_persian_p4","mill_alhambra_p6m","mill_escher_p4g"]:
		var n:Node3D=artifact(key)
		var def:Dictionary=game.building.content.catalog.artifacts[key]
		for k in def.delegate_params:
			var expected:Variant=def.delegate_params[k]
			var actual:Variant=n.get(k)
			check(tag+key+" preset "+k,actual==expected)
			if actual!=expected:print("PRESET_VALUE ",key," ",k," actual=",actual," expected=",expected)
	var v:Node3D=artifact("vr_tile_editor")
	var lesson:Node3D=v.symmetry_lesson
	check(tag+"original symmetry comparison present",lesson!=null)
	await approach(lesson,1.7)
	var source:Array=lesson.puzzle.get_pattern_data().duplicate(true)
	await press(lesson.buttons.PM)
	check(tag+"PM changes symmetry while source stays",lesson.group_index==1 and lesson.puzzle.get_pattern_data()==source)
	await press(lesson.buttons.HOLD)
	var held:Texture2D=lesson.held.material_override.albedo_texture
	await press(lesson.buttons.PG)
	check(tag+"PG changes live while held sample stays",lesson.group_index==2 and lesson.held.material_override.albedo_texture==held)
	await press(lesson.buttons.UNDO)
	check(tag+"UNDO restores comparison",lesson.group_index==1)
	check(tag+"gallery stays in own mount",artifact("wall_pattern_gallery").get_children().filter(func(n):return n is MeshInstance3D and absf(n.position.y)<4).size()==360)

func temple_checks(tag: String) -> void:
	var n:Node3D=artifact("pattern_temple")
	check(tag+"all eight original receiver classes",n.materials.size()==8 and n.has_node("Dome") and n.has_node("DomeShell"))
	var b:Node3D=panel_button(n,"DRESS THE TEMPLE","SOURCE")
	await approach(b.get_parent().get_parent().get_parent(),1.5)
	var old:int=n.dressing[n.target].source
	await press(b)
	check(tag+"SOURCE changes targeted surface",n.dressing[n.target].source!=old)
	await press(panel_button(n,"DRESS THE TEMPLE","ALL"))
	check(tag+"ALL dresses original court surfaces",n.dressing.all(func(d):return d==n.dressing[n.target]))
	await press(panel_button(n,"DRESS THE TEMPLE","AGE"))
	check(tag+"AGE changes original shader",n.dressing[n.target].age==1)
	await press(panel_button(n,"DRESS THE TEMPLE","CLEAN"))
	check(tag+"CLEAN restores all ages",n.dressing.all(func(d):return d.age==0))

func layer_checks(tag: String) -> void:
	var volume:Node3D=artifact("grid_3d_4x4x4")
	var lesson:Node3D=volume.get_node("LayerPatternLesson")
	check(tag+"paired plane and volume found on floor four",lesson.ready_for_use and lesson.plane==artifact("grid_2d_4x4"))
	check(tag+"all 64 original addresses stored",lesson.voxels.size()==64 and lesson.flat.size()==16)
	await approach(lesson.mount,1.1)
	await press(lesson.buttons["LAYER +"])
	check(tag+"layer selector advances",lesson.layer==1)
	var values:Array=lesson.values.duplicate(true)
	await press(lesson.buttons["SLICE / ALL"])
	check(tag+"slice hides cells without deleting values",lesson.slice_only and lesson.values==values and lesson.voxels.values().filter(func(n):return n.visible).size()==16)
	await press(lesson.buttons["REPEAT / SHIFT"])
	check(tag+"height enters addressed lookup",lesson.shifted and lesson.values!=values)
	await press(lesson.buttons.UNDO)
	check(tag+"UNDO restores repeated layers",not lesson.shifted and lesson.values==values)

func colour_checks(tag: String) -> void:
	var context:Node3D=artifact("SimultaneousContrast").lesson
	await approach(context.mount,1.1)
	var colour:Color=context.samples[0].material_override.albedo_color
	await press(context.buttons.SURROUNDS)
	check(tag+"context changes neighbours while targets stay",context.neutral and context.samples.all(func(n):return n.material_override.albedo_color==colour))
	await press(context.buttons.CONNECT)
	check(tag+"CONNECT reveals equal-colour bridge",context.connected and context.bridge.visible)
	var carrier:Node3D=artifact("MetamerismLab").lesson
	await approach(carrier.mount,1.1)
	var source:Texture2D=carrier.material.get_shader_parameter("motif")
	await press(carrier.buttons["FLAT / SHADED"])
	check(tag+"same source across flat and curved carriers",carrier.shaded and carrier.samples.all(func(n):return n.material_override==carrier.material) and carrier.material.get_shader_parameter("motif")==source)
	await press(carrier.buttons["LIGHT SIDE"])
	check(tag+"light direction responds",carrier.right_light)
	await press(carrier.buttons["REPEAT SIZE"])
	check(tag+"repeat size responds without replacing source",carrier.dense and carrier.material.get_shader_parameter("motif")==source)

func capture_floor() -> void:
	var y:float=game.building.spec.levels[level]
	match level:
		1:await photo("01-address-passage",Vector3(-13,y+3.6,-13),Vector3(-14,y+2,-3))
		2:await photo("02-symmetry-machines",Vector3(18,y+4,13),Vector3(1,y+1.2,4))
		3:await photo("03-pattern-temple",Vector3(2,y+2.3,-1),Vector3(0,y+2.8,5))
		4:await photo("04-layer-patterns",Vector3(15,y+4,12),Vector3(0,y+1,0))
		5:await photo("05-pattern-carriers",Vector3(7,y+2.6,5),Vector3(7,y+1.7,9))
