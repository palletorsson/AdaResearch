extends "../probe_base.gd"

func _run() -> void:
    setup("patterns")
    make_quad(study.material)
    var first := await capture("start")
    check(pixel(first,Vector2(0.5,0.5)).r > 0.8 if mode == "original" else pixel(first,Vector2(0.5,0.5)).r < 0.2,"shear changes the centre address as predicted")
    check(pixel(first,Vector2(1.0/3.0,0.5)).r < 0.2 if mode == "original" else pixel(first,Vector2(1.0/3.0,0.5)).r > 0.8,"shear brings the adjacent address into the circle")
    await move_control(Vector3(1.15,1.2,1.2))
    var half := await capture("half-shift")
    check(difference(first,half)>0.1,"half-tile shift changes the rendered field",difference(first,half))
    await move_control(Vector3(1.65,1.2,1.2))
    var whole := await capture("whole-shift")
    check(difference(first,whole)<0.001,"one tile of control shift returns the rendered field",difference(first,whole))
    await move_control(Vector3(-0.35,1.2,1.2))
    var negative := await capture("negative-shift")
    check(difference(first,negative)<0.001,"negative whole shift also returns",difference(first,negative))
    finish()
