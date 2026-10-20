extends Node3D

const PointBody = preload("point_body.gd")
const SIDE := 32
const MAX_LAYERS := 4
const FIXED_BOUND := 3.0

var sample_seed := 42
var layer_count := 1
var lacunarity := 2.0
var persistence := 0.7
var base_frequency := 4.0
var rng := RandomNumberGenerator.new()
var offsets: Array[Vector2] = []
var parts: Array[Array] = []
var raw: Array[float] = []
var screens: Array[MeshInstance3D] = []
var point: XRToolsPickable
var status: Label3D

func _ready() -> void:
    box(Vector3(4.0, 0.9, 1.0), Vector3(0, 0.45, 0.0))
    box(Vector3(4.0, 1.9, 0.05), Vector3(0, 1.85, -0.36))
    for i in range(3):
        var screen := MeshInstance3D.new()
        var quad := QuadMesh.new()
        quad.size = Vector2(1.12, 1.12)
        screen.mesh = quad
        screen.position = Vector3((i - 1) * 1.3, 1.77, -0.3)
        var finish := StandardMaterial3D.new()
        finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        finish.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
        screen.material_override = finish
        add_child(screen)
        screens.append(screen)
        var caption: String = ["LAST LAYER", "SUM: FIXED", "SUM: STRETCHED"][i]
        label(caption, Vector3((i - 1) * 1.3, 2.4, -0.29), 23)
    status = label("", Vector3(0, 2.65, -0.29), 21)
    for i in range(4):
        var action: String = ["REPLAY", "OCT", "WEIGHT", "SEED"][i]
        label(action, Vector3((i - 1.5) * 0.65, 0.77, 0.52), 24)
    point = PointBody.new()
    point.position = Vector3(0, 1.05, 0.3)
    add_child(point)
    point.action_pressed.connect(use_point)
    replay()

func replay() -> void:
    rng.seed = sample_seed
    offsets.clear()
    for i in range(8):
        offsets.append(Vector2(rng.randf_range(-100.0, 100.0), rng.randf_range(-100.0, 100.0)))
    sample_fields()

func wave(x: float, y: float) -> float:
    var value := sin(x + y * 1.7)
    value += sin(x * 2.3 - y * 0.9)
    value += sin((x + y) * 1.3 + 0.5)
    value += sin((x - y) * 1.8 - 0.3)
    value += sin(x * 0.7 + y * 2.1 + x * y * 0.15)
    return value / 5.0

func sample_fields() -> void:
    parts.clear()
    raw.clear()
    for i in range(layer_count):
        parts.append([])
    for y in range(SIDE):
        for x in range(SIDE):
            var uv := Vector2(float(x) / SIDE, float(y) / SIDE)
            var amplitude := 1.0
            var frequency := base_frequency
            var total := 0.0
            for i in range(layer_count):
                var contribution := amplitude * wave(
                    uv.x * frequency + offsets[i].x, uv.y * frequency + offsets[i].y)
                parts[i].append(contribution)
                total += contribution
                amplitude *= persistence
                frequency *= lacunarity
            raw.append(total)
    redraw()

func picture(values: Array, stretch: bool) -> Image:
    var low := -FIXED_BOUND
    var width := FIXED_BOUND * 2.0
    if stretch:
        low = values.min()
        width = float(values.max()) - low
        if width < 0.0001:
            width = 1.0
    var image := Image.create(SIDE, SIDE, false, Image.FORMAT_RGBA8)
    for y in range(SIDE):
        for x in range(SIDE):
            var t := clampf((float(values[y * SIDE + x]) - low) / width, 0.0, 1.0)
            image.set_pixel(x, y, Color(t, t, t))
    return image

func redraw() -> void:
    screens[0].material_override.albedo_texture = ImageTexture.create_from_image(picture(parts.back(), false))
    screens[1].material_override.albedo_texture = ImageTexture.create_from_image(picture(raw, false))
    screens[2].material_override.albedo_texture = ImageTexture.create_from_image(picture(raw, true))
    var centre := (SIDE / 2) * SIDE + SIDE / 2
    status.text = "seed %d | OCT %d | LAC %.1f | PER %.2f | %d x %d samples\nAt the centre: last %.3f | sum %.3f | raw range %.3f to %.3f\nFirst two screens: -3 black, 0 grey, +3 white" % [
        sample_seed, layer_count, lacunarity, persistence, SIDE, SIDE,
        parts.back()[centre], raw[centre], raw.min(), raw.max()]

func next_layer() -> void:
    layer_count = layer_count % MAX_LAYERS + 1
    sample_fields()

func change_weight() -> void:
    persistence = 0.3 if persistence > 0.4 else 0.7
    sample_fields()

func next_seed() -> void:
    sample_seed += 1
    replay()

func use_point(_held) -> void:
    var x := to_local(point.global_position).x
    if x < -0.65:
        replay()
    elif x < 0.0:
        next_layer()
    elif x < 0.65:
        change_weight()
    else:
        next_seed()

func box(size: Vector3, at: Vector3) -> void:
    var view := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    view.mesh = mesh
    view.position = at
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color(0.84, 0.82, 0.78)
    finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    view.material_override = finish
    add_child(view)

func label(words: String, at: Vector3, font_size: int) -> Label3D:
    var view := Label3D.new()
    view.text = words
    view.position = at
    view.font_size = font_size
    view.pixel_size = 0.0025
    view.modulate = Color(0.02, 0.02, 0.02)
    view.outline_size = 0
    add_child(view)
    return view
