extends "bench.gd"
const Comparison = preload("step_comparison.gd")
const LOW := 1.12
const TRAVEL := 0.48
var model := Comparison.new()
var textures: Array[ImageTexture] = []
var captions: Array[Label3D] = []

func _ready() -> void:
    start("SAME START / SAME MODEL TIME",
        ["+6 TIME", "RESTART", "NEW SEED", "DT / 2", "KEEP"],
        [advance, restart, new_seed, toggle_step, keep])
    for side in 2:
        var x := -0.42+side*1.05
        var image := Image.create(32,32,false,Image.FORMAT_RGB8)
        var texture := ImageTexture.create_from_image(image)
        textures.append(texture)
        var screen := block(self,Vector3(x,1.32,0.05),Vector3(0.9,0.62,0.025),Color.WHITE)
        var face := QuadMesh.new()
        face.size = Vector2(0.9,0.62)
        screen.mesh = face
        screen.material_override.albedo_texture = texture
        screen.material_override.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
        captions.append(label(self,"",Vector3(x,1.68,0.05),17))
    redraw()

func _process(_delta: float) -> void:
    if point == null or not point.held(): return
    model.set_weight((to_local(point.global_position).y-LOW)/TRAVEL)
    update_readout()

func advance() -> void:
    if point.held(): return
    model.advance()
    redraw()

func restart() -> void:
    if point.held(): return
    model.restart()
    redraw()

func new_seed() -> void:
    if point.held(): return
    model.new_seed()
    redraw()

func toggle_step() -> void:
    if point.held(): return
    model.toggle_step()
    redraw()

func keep() -> void:
    if point.held(): return
    model.keep()
    update_readout()

func tint(value: float) -> Color:
    return Color("123039").lerp(Color("efbf80"),clampf(value,0.0,1.0))

func redraw() -> void:
    for side in 2:
        var values: PackedFloat32Array = model.coarse.b if side == 0 else model.fine.b
        var image := Image.create(32,32,false,Image.FORMAT_RGB8)
        for y in 32:
            for x in 32:image.set_pixel(x,y,tint(values[y*32+x]))
        textures[side].update(image)
        captions[side].text = "DT %.3f" % (model.dt if side == 0 else model.dt*0.5)
    update_readout()

func update_readout() -> void:
    point_home = Vector3(-1.17,LOW+model.weight*TRAVEL,0.22)
    var r := model.reading()
    var record := "KEEP: no comparison yet"
    if not model.kept.is_empty():
        record = "KEEP L %.2f / seed %d / t %.0f / RMS %.5f" % [
            model.kept.weight,model.kept.seed-Comparison.Field.START_SEED,
            model.kept.coarse_time,model.kept.rms]
    readout.text = "LAMBDA %.2f / seed %d / 32 x 32\nSteps %d / %d; time %.1f / %.1f\nB difference %.5f / %s\n%s" % [
        r.weight,r.seed-Comparison.Field.START_SEED,r.coarse_ticks,r.fine_ticks,
        r.coarse_time,r.fine_time,r.rms,"READY" if r.fault.is_empty() else "FAULT: "+r.fault,record]
