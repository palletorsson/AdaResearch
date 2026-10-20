extends "../probe_base.gd"

func _run() -> void:
    setup("shaping")
    make_quad(study.material)
    var first := await capture("start")
    check(pixel(first,Vector2(0.5,0.5)).r > 0.8 if mode == "original" else pixel(first,Vector2(0.5,0.5)).r < 0.2,"centre follows circle versus annulus prediction")
    check(pixel(first,Vector2(0.70,0.5)).r > 0.8,"sample between inner and outer radii is ink")
    check(pixel(first,Vector2(0.9,0.5)).r < 0.2,"outside starts dark")
    await move_control(Vector3(0.65,1.65,1.2))
    var raised := await capture("raised")
    check(pixel(raised,Vector2(0.9,0.5)).r > 0.8,"raising point expands visible mark to previously dark sample")
    note("radius_after_raise",study.radius)
    study.toggle_edge(study.control)
    var soft := await capture("soft")
    check(difference(raised,soft)>0.005,"edge action changes rendered transition",difference(raised,soft))
    check(study.receivers[0].material_override == study.receivers[1].material_override,"both actual receivers share the tested material")
    finish()
