extends "../probe_base.gd"

func _run() -> void:
    setup("materials")
    make_quad(study.material)
    var flat := await capture("flat")
    study.next_mode(study.control)
    var height := await capture("height")
    study.next_mode(study.control)
    var normals := await capture("normal")
    var relief_delta := difference(flat,height)
    var methods_delta := difference(height,normals)
    check(relief_delta>0.01,"height-derived normals visibly alter lit shading",relief_delta)
    check(methods_delta<relief_delta*0.3,"prepared normal map stays substantially closer to height relief than flat",methods_delta)
    await move_control(Vector3(0.65,0.9,1.2))
    var zero := await capture("zero-strength")
    check(difference(flat,zero)<0.001,"zero normal strength returns flat image",difference(flat,zero))
    if mode == "variation":
        var original := Image.load_from_file(folder+"original-height.png")
        check(difference(original,height)>0.025,"inverting height changes the rendered relief",difference(original,height))
        var original_flat := Image.load_from_file(folder+"original-flat.png")
        check(difference(original_flat,flat)<0.001,"height inversion leaves flat reading unchanged",difference(original_flat,flat))
    check(study.control.surface.material_override == study.receivers[0].material_override,"carried point receives same relief material")
    finish()
