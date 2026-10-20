extends "res://tools/probes/transformation_encounters.gd"
var ui:Node3D
var wardrobe:Node
func press(id:String)->void:
    var area:Node3D=ui.buttons[id].get_node("InteractableAreaButton")
    XRToolsPointerEvent.pressed(camera,area,area.global_position)
    XRToolsPointerEvent.released(camera,area,area.global_position)
    for i in 4:await tick()
func photo(name:String)->void:
    await snapshot(name,ui.to_global(Vector3(0,2.1,5)),ui.to_global(Vector3(0,1.55,0)),90)
func landing_checks()->void:
    AudioServer.set_bus_mute(0,true);root.size=Vector2i(1440,1000)
    for i in 3600:
        ui=find_scene("/fabric_shader_studio.gd")
        if ui!=null and ui.buttons.size()==32:break
        await process_frame
    museum.call("flush_stamps");await create_timer(.6).timeout
    check("actual museum studio loaded with32 source and action controls",ui!=null and ui.buttons.size()==32)
    if ui==null:return
    camera.queue_free()
    camera=museum.get("_cam")
    camera.current=true
    ui.save_path=folder+"original-recipe.json"
    var player:Node3D=museum.get("_player")
    if player:player.hide();player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
    wardrobe=museum.get("_wardrobe");wardrobe.appearance_save_path=folder+"test-appearance.cfg"
    # Keep the real museum viewer; isolate every appearance write.
    wardrobe.costume.hide()
    camera.set_cull_mask_value(19,false)
    for n in museum.get_children():
        if n is Node3D and n.has_meta("em_map") and n!=hall:n.hide()
    var initial:Dictionary=ui.recipe.duplicate(true)
    var original_look:String=wardrobe.costume.outfit_id;var original_fabric:Dictionary=wardrobe.skirt_fabric.duplicate(true)
    check("declared wardrobe bound to isolated viewer and save",ui.wardrobe()==wardrobe and wardrobe.appearance_save_path==folder+"test-appearance.cfg")
    await photo("installed-studio")
    await press("paint_3");await press("cell_1_0")
    check("real pointer paints source and preview",ui.recipe.cells[0][1]==3 and ui.preview.outfit.skirt_fabric.cells[0][1]==3)
    await press("UNDO");check("paint undo restores source",ui.recipe==initial)
    var collision:BoxShape3D=ui.wall.get_node("WallCollision/CollisionShape3D").shape
    var size:Vector3=collision.size;var vertices:PackedVector3Array=ui.wall.mesh.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
    for id in ["UV / FABRIC","OFFSET","REPEAT","CUT OUT","FINISH","VERTICES"]:await press(id)
    check("existing shader controls set explicit fields",ui.recipe.uv_view and ui.recipe.repeats==8 and ui.recipe.offset==.125 and ui.recipe.mask and ui.recipe.finish==1 and ui.recipe.displace)
    check("full studio shader flags and displacement reach material",ui.wall.material_override.get_shader_parameter("uv_view") and ui.wall.material_override.get_shader_parameter("cut_out") and ui.wall.material_override.get_shader_parameter("metal_finish") and is_equal_approx(ui.wall.material_override.get_shader_parameter("amplitude"),.04))
    check("rendering effects leave collision and CPU mesh intact",collision.size==size and ui.wall.mesh.get_mesh_arrays()[Mesh.ARRAY_VERTEX]==vertices)
    await press("UV / FABRIC")
    await photo("installed-cutout")
    var q:=PhysicsRayQueryParameters3D.create(ui.wall.to_global(Vector3(.8,0,1)),ui.wall.to_global(Vector3(.8,0,-.2)),1)
    var hit:=hall.get_world_3d().direct_space_state.intersect_ray(q)
    check("cut-out drawing retains sample wall collision",not hit.is_empty() and hit.collider==ui.wall.get_node("WallCollision"))
    ui.recipe=initial.duplicate(true);ui.history.clear();ui.refresh();await tick()
    await press("REPEAT");await press("OFFSET");await press("SAVE")
    var saved:Dictionary=ui.saved_recipe()
    check("SAVE records supported values in isolated file",saved==ui.recipe and ui.save_path.begins_with(folder))
    await press("LOOK");await press("WEAR SAVED")
    check("WEAR selects current preview silhouette and saved fabric",wardrobe.costume.outfit_id==ui.preview.outfit.LOOKS[ui.look] and wardrobe.skirt_fabric==saved and wardrobe.costume.drag_outfit.skirt_fabric==saved)
    check("only wearer skirt receives fabric",wardrobe.costume.drag_outfit.get_node("Skirt").material_override is ShaderMaterial and wardrobe.costume.drag_outfit.get_node("Bodice").material_override!=wardrobe.costume.drag_outfit.get_node("Skirt").material_override)
    var disk:=ConfigFile.new()
    check("isolated appearance file retains saved fabric",disk.load(wardrobe.appearance_save_path)==OK and disk.get_value("appearance","skirt_fabric")==saved)
    await press("OFFSET")
    check("preview editing leaves worn and saved record unchanged",ui.recipe!=saved and wardrobe.skirt_fabric==saved and ui.saved_recipe()==saved)
    await press("UNDO");await press("UNDO")
    check("wear UNDO restores former outfit and fabric",wardrobe.costume.outfit_id==original_look and wardrobe.skirt_fabric==original_fabric)
    var stage:Node3D=ui.runway()
    check("same hall supplies four performers",stage!=null and stage.agents.size()==4)
    var prior:Array=[]
    for a in stage.agents:prior.append(a.outfit.skirt_fabric.duplicate(true))
    await press("RUNWAY SAVED")
    check("four performers receive saved version",stage.agents.all(func(a):return a.outfit.skirt_fabric==saved))
    stage.agents[0].set_look(2)
    check("performer look switch retains fabric",stage.agents[0].outfit.skirt_fabric==saved)
    camera.global_position=stage.to_global(Vector3(5,2,7))
    museum.call("_cull_artifacts")
    var travelled:Array=stage.travelled.duplicate()
    for i in 120:await tick()
    check("runway continues moving with saved fabric",stage.travelled!=travelled)
    await snapshot("installed-runway",stage.to_global(Vector3(5,3.3,9)),stage.to_global(Vector3(0,1.1,6)),75)
    await press("UNDO")
    var restored:=true
    for i in stage.agents.size():restored=restored and stage.agents[i].outfit.skirt_fabric==prior[i]
    check("runway UNDO restores each previous recipe",restored)
    var mirror:Node3D=find_scene("/super_drag_mirror.gd")
    check("mirror exists and shares current World3D",mirror!=null and mirror.viewport.world_3d==hall.get_world_3d())
    var capsule:=CapsuleShape3D.new();capsule.radius=.25;capsule.height=1.7
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1|4
    observations["approaches"]=[]
    for frame in [ui,mirror,stage]:
        var local:=Vector3(0,0,3.8) if frame!=stage else Vector3(0,0,-1)
        var foot:Vector3=frame.to_global(local);query.transform.origin=foot+Vector3.UP*.9
        var support:=floor_at(foot);var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query,12)
        var names:Array=[]
        for h in hits:names.append(str(h.collider.get_path()))
        observations.approaches.append({"foot":xyz(foot),"colliders":names,"support_y":support.position.y if not support.is_empty() else null})
        check("clear supported approach "+str(frame.name),not support.is_empty() and absf(support.position.y-foot.y)<.08 and hits.is_empty())
    # Replace only this runtime instance in the isolated hall with the exact printed scene.
    var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
    var frame:Transform3D=ui.global_transform;var host:Node=ui.get_parent()
    host.remove_child(ui);ui.queue_free();await process_frame
    ui=load(spec.lesson).instantiate();ui.save_path=folder+"printed-recipe.json";host.add_child(ui);ui.global_transform=frame
    for i in 5:await tick()
    var shader:Shader=load(str(spec.lesson).get_base_dir()+"/09_fabric_sample.gdshader")
    check("exact printed scene fits original studio transform",ui.global_transform.is_equal_approx(frame) and ui.wall.material_override.shader==shader and ui.preview.outfit.get_node("Skirt").material_override.shader==shader)
    await photo("student-repeat4")
    await press("OFFSET");await press("REPEAT")
    check("real pointer reaches printed shader repeat and phase",ui.wall.material_override.get_shader_parameter("repeats")==8.0 and ui.wall.material_override.get_shader_parameter("phase")==.125)
    await press("paint_2");await press("cell_1_0")
    check("printed shader survives real pointer repaint",ui.recipe.cells[0][1]==2 and ui.wall.material_override.shader==shader and ui.preview.outfit.get_node("Skirt").material_override.shader==shader)
    await photo("student-repeat8-offset")
    host.remove_child(ui);ui.queue_free();await process_frame
    ui=load(str(spec.lesson).replace('/printed/','/three_vertical/')).instantiate();ui.save_path=folder+"edited-recipe.json";host.add_child(ui);ui.global_transform=frame
    for i in 5:await tick()
    var edited_shader:Shader=ui.wall.material_override.shader
    check("independent three vertical shader loaded on existing receivers",edited_shader.code.contains("vec2(repeats, 3.0)") and ui.preview.outfit.get_node("Skirt").material_override.shader==edited_shader)
    await photo("student-three-vertical")
    await press("SAVE");await press("WEAR SAVED")
    check("WEAR SAVED keeps original receiver shader while preview uses edit",wardrobe.costume.drag_outfit.get_node("Skirt").material_override.shader==ui.Recipe.SHADER and ui.wall.material_override.shader==edited_shader)
    check("saved schema contains neither vertical count nor shader text",ui.saved_recipe().keys().size()==8 and not ui.saved_recipe().has("vertical_repeats") and not ui.saved_recipe().has("shader"))
    await press("UNDO")
