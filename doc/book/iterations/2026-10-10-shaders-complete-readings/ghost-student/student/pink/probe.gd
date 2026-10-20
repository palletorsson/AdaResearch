extends "../probe_base.gd"

func _run() -> void:
    setup("pink")
    probe_quad = MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.85
    sphere.height = 1.7
    probe_quad.mesh = sphere
    probe_quad.material_override = study.material
    probe_quad.position = Vector3(5,0,0)
    space.add_child(probe_quad)
    camera.size = 3.0
    var neighbour := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3.ONE * 0.3
    neighbour.mesh = box
    neighbour.position = Vector3(6.15,0,0)
    var grey := StandardMaterial3D.new()
    grey.albedo_color = Color(0.5,0.5,0.5)
    neighbour.material_override = grey
    space.add_child(neighbour)
    var composed := await capture("composed")
    study.next_mode(study.control)
    var base := await capture("base")
    check(difference(composed,base)>0.01,"base switch removes visible additions",difference(composed,base))
    study.next_mode(study.control)
    var restored := await capture("restored")
    check(difference(composed,restored)==0.0,"composition returns after comparison",difference(composed,restored))
    for lamp in space.find_children("*","Light3D",true,false): lamp.light_energy = 0.0
    for child in space.get_children():
        if child is WorldEnvironment: child.environment.ambient_light_energy = 0.0
    await move_control(Vector3(-0.35,0.6,0.9))
    var dark := await capture("dark-zero")
    await move_control(Vector3(-0.35,0.6,1.7))
    var glow := await capture("dark-glow")
    check(pixel(glow,Vector2(0.5,0.5)).r > pixel(dark,Vector2(0.5,0.5)).r + 0.02,"emission brightens sphere without lamps")
    var ng := pixel(glow,Vector2(0.8833,0.5)); var nd := pixel(dark,Vector2(0.8833,0.5))
    check(ng == nd,"adjacent grey receiver remains unchanged in this renderer",str(ng))
    await move_control(Vector3(-0.35,1.2,0.9))
    var rim := await capture("rim-only")
    if mode == "variation":
        var original := Image.load_from_file(folder+"original-rim-only.png")
        check(pixel(rim,Vector2(0.66,0.5)).g > pixel(original,Vector2(0.66,0.5)).g + 0.03,"linear exponent brings rim inward",[pixel(original,Vector2(0.66,0.5)).g,pixel(rim,Vector2(0.66,0.5)).g])
    await move_control(Vector3(0.25,0.9,1.3))
    var chosen := await capture("chosen-composition")
    note("chosen_local_point",str(study.control.position))
    note("chosen_amounts",str(study.amounts))
    check(difference(chosen,rim)>0.005,"chosen composition differs from isolated rim")
    finish()
