extends "res://commons/interfaces/qfep/chaos_particles.gd"
## Export-only image of the actual source GPU emitter. No fabricated particles.
## Browser receives an explicitly labelled static billboard, not GPU state.
func prepare_editor_preview() -> void:
    var view := SubViewport.new()
    view.size = Vector2i(512,512)
    view.transparent_bg = true
    view.own_world_3d = true
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    view.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(view)
    var stage := Node3D.new()
    view.add_child(stage)
    _particles.reparent(stage,false)
    _particles.transform = Transform3D.IDENTITY
    _particles.preprocess = _particles.lifetime
    _particles.restart()
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    var radius: float = emission_radius + maxf(absf(speed_min),absf(speed_max))*lifetime
    camera.size = maxf(radius*2.1,1.0)
    camera.position = Vector3(0,0,radius*2.5+1)
    camera.far = radius*6+10
    camera.current = true
    view.add_child(camera)
    for i in 6: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    var picture := view.get_texture().get_image()
    if picture == null or picture.is_empty():
        push_error("Source particle renderer produced no image")
        return
    var panel := MeshInstance3D.new()
    panel.name = "OriginalParticleRendererSnapshot"
    var quad := QuadMesh.new()
    quad.size = Vector2.ONE*camera.size
    panel.mesh = quad
    var finish := StandardMaterial3D.new()
    finish.albedo_texture = ImageTexture.create_from_image(picture)
    finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    finish.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    finish.cull_mode = BaseMaterial3D.CULL_DISABLED
    finish.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    panel.material_override = finish
    add_child(panel)
    set_meta("void_preview_kind","source_gpu_particle_image_snapshot")
    remove_child(view)
    view.queue_free()
