extends Node3D
## Seven spherical comparisons and a free-space drawing. Standalone desktop study.
## Positions fed to stamp_space() / paint_direction() are also usable by a later XR adapter.
const RADIUS := 1.3
const MAX_STAMPS := 900
const W := 512
const H := 256
const PALETTE := [Color("ff88b6"), Color("62e5e3"), Color("ffc977"), Color("c0a0ff")]
const BRUSH_NAMES := ["SOFT COLOUR", "BUBBLES", "LIGHT POINTS"]
const NAMES := ["A SOLID", "POINTS", "LINES", "SHELLS", "A BRUSH IN SPACE", "A SURFACE FOUND", "SLICES", "A SHORT MEMORY"]
const NOTES := ["A continuous visible boundary.", "420 separate points describe one sphere.", "Latitude and longitude leave the body open.", "Three nested transparent shells. Their colours add.", "Left-drag to draw. Wheel moves the drawing plane. C clears; R restores.", "Left-drag to paint the hidden sphere. C clears; R restores.", "Thirteen sections imply the volume between them.", "Moving points leave fading tails. Space pauses time."]
var centres: Array[Vector3] = []
var camera := Camera3D.new()
var environment := Environment.new()
var canvas := CanvasLayer.new()
var detail := Label.new()
var selected := -1
var focus := Vector3(0, 1.6, 0)
var yaw := 0.22
var pitch := 0.52
var distance := 35.0
var time := 0.0
var paused := false
var drawing := false
var tick := 0.0
var brush_depth := 7.0
var brush_plane_point := Vector3.ZERO
var brush_plane_normal := Vector3.BACK
var brush_count := 0
var brush_next := 0
var brush: MultiMesh
var tails: MultiMesh
var points: MultiMesh
var line_count := 0
var paint_image: Image
var paint_texture: ImageTexture
var paint_dirty := false
var paint_count := 0
var pointer_position := Vector2(800, 500)
var capture_mode := false
var cursor := MeshInstance3D.new()
var font := FontFile.new()
var stage_roots: Array[Node3D] = []
var backdrop := Node3D.new()
var target_root: Node3D
var brush_forms: Array[MultiMesh] = []
var brush_state: Array[Dictionary] = []
var brush_style := 0
var ink_index := 0
var brush_radius := .20
var last_sample := Vector3.ZERO
var has_last_sample := false
var undo_stack: Array[Dictionary] = []
var guide := MeshInstance3D.new()
var tools_label := Label.new()
var status := Label.new()
const SAVE_PATH := "user://painting-space-v2.save"

func _ready() -> void:
    get_window().focus_exited.connect(_end_stroke)
    font.load_dynamic_font("res://JetBrainsMono-Medium.ttf")
    target_root = self
    _room()
    for i in 8:
        var centre := Vector3((float(i % 4) - 1.5) * 7.2, 2.05, -4.7 if i < 4 else 4.7)
        centres.append(centre)
    for i in 8:
        target_root = Node3D.new()
        target_root.name = "Study%02d" % (i + 1)
        add_child(target_root)
        stage_roots.append(target_root)
        _plinth(i, centres[i])
        match i:
            0: _solid()
            1: _points()
            2: _lines()
            3: _shells()
            4: _brush()
            5: _paint()
            6: _slices()
            7: _tails()
    target_root = self
    reset_demo()
    add_child(camera)
    camera.current = true
    camera.fov = 49
    update_camera()
    _hud()
    var cursor_ring := TorusMesh.new()
    cursor_ring.inner_radius = .94
    cursor_ring.outer_radius = 1.0
    cursor_ring.rings = 48
    cursor_ring.ring_segments = 6
    cursor.mesh = cursor_ring
    cursor.material_override = _mat(Color("fff1d5"), .8)
    cursor.visible = false
    add_child(cursor)
    var guide_mesh := CylinderMesh.new()
    guide_mesh.top_radius = .009
    guide_mesh.bottom_radius = .009
    guide_mesh.height = 1.0
    guide.mesh = guide_mesh
    guide.material_override = _mat(Color("718293"), .15)
    add_child(guide)
    guide.visible = false

func _mat(colour: Color, emission: float = 0.0) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = colour
    mat.roughness = .65
    if emission > 0:
        mat.emission_enabled = true
        mat.emission = colour
        mat.emission_energy_multiplier = emission
    return mat

func _sphere(radius: float, segments: int = 32) -> SphereMesh:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2
    mesh.radial_segments = segments
    mesh.rings = maxi(4, segments / 2)
    return mesh

func _object(mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.position = at
    instance.material_override = material
    target_root.add_child(instance)
    return instance

func _box(size: Vector3, at: Vector3, colour: Color) -> void:
    var mesh := BoxMesh.new()
    mesh.size = size
    _object(mesh, at, _mat(colour))

func _text(words: String, at: Vector3, size: int = 34, pixel: float = .007) -> void:
    var label := Label3D.new()
    label.font = font
    label.text = words
    label.font_size = size
    label.pixel_size = pixel
    label.outline_size = 0
    label.modulate = Color("d5d3db")
    label.position = at
    target_root.add_child(label)

func _room() -> void:
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("10131d")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("8694af")
    environment.ambient_light_energy = .26
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.tonemap_white = 4.0
    environment.glow_enabled = true
    environment.glow_intensity = 1.0
    environment.glow_hdr_threshold = .8
    environment.glow_bloom = 0.0
    var world := WorldEnvironment.new()
    world.environment = environment
    add_child(world)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-56, -24, 0)
    light.light_color = Color("e4d8d0")
    light.light_energy = 1.15
    light.shadow_enabled = true
    add_child(light)
    _box(Vector3(34, .2, 23), Vector3(0, -.13, 0), Color("202431"))
    add_child(backdrop)
    target_root = backdrop
    _box(Vector3(34, 7, .2), Vector3(0, 3.5, -10.5), Color("161c29"))
    _text("P A I N T I N G   S P A C E", Vector3(0, 5.5, -10.32), 62, .014)
    _text("One boundary. Eight ways of letting it appear.", Vector3(0, 4.4, -10.3), 30, .011)
    for x in [-15.8, 15.8]:
        _box(Vector3(.12, 5.8, .12), Vector3(x, 2.9, -10), Color("736777"))
    target_root = self

func _plinth(index: int, centre: Vector3) -> void:
    var disc := CylinderMesh.new()
    disc.top_radius = 2.65
    disc.bottom_radius = 2.65
    disc.height = .18
    disc.radial_segments = 80
    _object(disc, Vector3(centre.x, .09, centre.z), _mat(Color("373e4e")))
    _text("%02d / %s" % [index + 1, NAMES[index]], Vector3(centre.x, .4, centre.z + 2.55), 24, .0065)
    var ring: Array[Vector3] = []
    for i in 100:
        var a := TAU * i / 100.0
        ring.append(Vector3(cos(a) * 2.5, .191, sin(a) * 2.5) + Vector3(centre.x, 0, centre.z))
    _tubes([ring], .008, _mat(Color("727389"), .3))

func _solid() -> void:
    _object(_sphere(RADIUS, 64), centres[0], _mat(Color("d6d0ca")))

func _multi(mesh: Mesh, material: Material, count: int, use_colours: bool = false) -> MultiMesh:
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.use_colors = use_colours
    mm.mesh = mesh
    mm.instance_count = count
    var instance := MultiMeshInstance3D.new()
    instance.multimesh = mm
    instance.material_override = material
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    target_root.add_child(instance)
    return mm

func _points() -> void:
    points = _multi(_sphere(.026, 8), _mat(Color("ffc3c7"), 2.8), 420)
    var golden := PI * (3.0 - sqrt(5.0))
    for i in 420:
        var y := 1.0 - 2.0 * (i + .5) / 420.0
        var r := sqrt(1.0 - y * y)
        var p := Vector3(cos(i * golden) * r, y, sin(i * golden) * r)
        points.set_instance_transform(i, Transform3D(Basis.IDENTITY, centres[1] + p * RADIUS))

func _tubes(paths: Array, radius: float, material: Material) -> MultiMesh:
    var count := 0
    for path in paths:
        count += path.size()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius
    cylinder.height = 1.0
    cylinder.radial_segments = 6
    cylinder.rings = 0
    var mm := _multi(cylinder, material, count)
    var k := 0
    for path in paths:
        for j in path.size():
            var a: Vector3 = path[j]
            var b: Vector3 = path[(j + 1) % path.size()]
            var y := (b - a).normalized()
            var helper := Vector3.RIGHT if absf(y.dot(Vector3.UP)) > .95 else Vector3.UP
            var x := helper.cross(y).normalized()
            var z := x.cross(y).normalized()
            mm.set_instance_transform(k, Transform3D(Basis(x, y * a.distance_to(b), z), (a + b) * .5))
            k += 1
    return mm

func _lines() -> void:
    var paths: Array = []
    for latitude in range(1, 10):
        var theta := PI * latitude / 10.0
        var ring: Array[Vector3] = []
        for j in 96:
            var a := TAU * j / 96.0
            ring.append(centres[2] + Vector3(sin(theta) * cos(a), cos(theta), sin(theta) * sin(a)) * RADIUS)
        paths.append(ring)
    for longitude in 6:
        var phi := PI * longitude / 6.0
        var ring: Array[Vector3] = []
        for j in 96:
            var a := TAU * j / 96.0
            ring.append(centres[2] + Vector3(sin(a) * cos(phi), cos(a), sin(a) * sin(phi)) * RADIUS)
        paths.append(ring)
    var mm := _tubes(paths, .010, _mat(Color("91e4e8"), 2.2))
    line_count = mm.instance_count

func _shell_material(colour: Color, strength: float) -> ShaderMaterial:
    var mat := ShaderMaterial.new()
    mat.shader = preload("shell.gdshader")
    mat.set_shader_parameter("tint", colour)
    mat.set_shader_parameter("strength", strength)
    return mat

func _shells() -> void:
    for i in 3:
        var offset: Vector3 = [Vector3.ZERO, Vector3(.12, .10, -.10), Vector3(-.18, -.12, .16)][i]
        _object(_sphere(RADIUS - i * .30, 64), centres[3] + offset, _shell_material(Color(["ff96bc", "80e5f0", "eac183"][i]), .7))

func _brush() -> void:
    var quad := QuadMesh.new()
    quad.size = Vector2(2, 2)
    var soft := ShaderMaterial.new()
    soft.shader = preload("mist.gdshader")
    var light := ShaderMaterial.new()
    light.shader = preload("light.gdshader")
    brush_forms.append(_multi(quad, soft, MAX_STAMPS, true))
    brush_forms.append(_multi(_sphere(1.0, 16), _shell_material(Color.WHITE, .42), MAX_STAMPS, true))
    brush_forms.append(_multi(_sphere(1.0, 10), light, MAX_STAMPS, true))
    brush_state.resize(MAX_STAMPS)
    brush = brush_forms[0]
    _refresh_brush_visibility()

func stamp_space(world_position: Vector3, colour: Color = Color(-1, 0, 0), radius: float = -1.0) -> bool:
    if not world_position.is_finite() or radius > .5:
        return false
    var c: Color = PALETTE[ink_index] if colour.r < 0 else colour
    var r := brush_radius if radius <= 0 else radius
    brush_state[brush_next] = {"position": world_position, "colour": c, "radius": r}
    _write_stamp(brush_next)
    brush_next = (brush_next + 1) % MAX_STAMPS
    brush_count = mini(brush_count + 1, MAX_STAMPS)
    _refresh_brush_visibility()
    return true

func _write_stamp(index: int) -> void:
    var record := brush_state[index]
    for i in 3:
        var radius: float = record.radius * (.19 if i == 2 else 1.0)
        brush_forms[i].set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * radius), record.position))
        brush_forms[i].set_instance_color(index, record.colour)

func _refresh_brush_visibility() -> void:
    for i in brush_forms.size():
        brush_forms[i].visible_instance_count = brush_count if brush_style == i else 0
    brush = brush_forms[brush_style]

func set_brush_style(index: int) -> void:
    brush_style = posmod(index, 3)
    _refresh_brush_visibility()
    update_detail()

func sample_stroke(hit: Dictionary) -> void:
    if hit.is_empty():
        has_last_sample = false
        return
    var point: Vector3 = hit.position
    if selected == 4:
        var gap := last_sample.distance_to(point) if has_last_sample else 0.0
        var steps := clampi(ceili(gap / (brush_radius * .30)), 1, 96)
        for i in range(1, steps + 1):
            stamp_space(last_sample.lerp(point, i / float(steps)) if has_last_sample else point)
        last_sample = point
    elif selected == 5:
        var direction: Vector3 = hit.direction
        var angle := last_sample.angle_to(direction) if has_last_sample else 0.0
        var steps := clampi(ceili(angle / (brush_radius / RADIUS * .35)), 1, 64)
        for i in range(1, steps + 1):
            var d := last_sample.slerp(direction, i / float(steps)).normalized() if has_last_sample else direction
            paint_direction(d, PALETTE[ink_index], brush_radius / RADIUS)
        last_sample = direction
    has_last_sample = true

func _paint() -> void:
    paint_image = Image.create(W, H, false, Image.FORMAT_RGBA8)
    paint_image.fill(Color(0, 0, 0, 0))
    paint_texture = ImageTexture.create_from_image(paint_image)
    var mat := ShaderMaterial.new()
    mat.shader = preload("paint.gdshader")
    mat.set_shader_parameter("marks", paint_texture)
    _object(_sphere(RADIUS, 96), centres[5], mat)

func direction_uv(direction: Vector3) -> Vector2:
    var d := direction.normalized()
    return Vector2(fposmod(atan2(d.z, d.x) / TAU + .5, 1.0), acos(clampf(d.y, -1, 1)) / PI)

func paint_direction(direction: Vector3, colour: Color = Color("ffb6c8"), angle: float = .115) -> bool:
    if not direction.is_finite() or direction.length_squared() < .000001 or angle <= 0 or angle > .5:
        return false
    var d := direction.normalized()
    var uv := direction_uv(d)
    var theta := uv.y * PI
    var half_u := PI
    if theta > angle and theta < PI - angle:
        half_u = asin(clampf(sin(angle) / sin(theta), 0, 1))
    var span := ceili(half_u / TAU * W) + 1
    var cx := int(uv.x * W)
    var min_y := maxi(0, floori((theta - angle) / PI * H))
    var max_y := mini(H - 1, ceili((theta + angle) / PI * H))
    var cutoff := cos(angle)
    var left := 0 if span * 2 >= W else cx - span
    var right := W - 1 if span * 2 >= W else cx + span
    for y in range(min_y, max_y + 1):
        var a := PI * (y + .5) / H
        for xi in range(left, right + 1):
            var x := posmod(xi, W)
            var b := TAU * ((x + .5) / W - .5)
            var p := Vector3(sin(a) * cos(b), cos(a), sin(a) * sin(b))
            var closeness := p.dot(d)
            if closeness > cutoff:
                var amount := .8 * smoothstep(cutoff, lerpf(cutoff, 1.0, .7), closeness)
                var previous := paint_image.get_pixel(x, y)
                var alpha := amount + previous.a * (1 - amount)
                var rgb := (Vector3(colour.r, colour.g, colour.b) * amount + Vector3(previous.r, previous.g, previous.b) * previous.a * (1 - amount)) / maxf(alpha, .00001)
                paint_image.set_pixel(x, y, Color(rgb.x, rgb.y, rgb.z, alpha))
    paint_count += 1
    paint_dirty = true
    return true

func sphere_hit(origin: Vector3, direction: Vector3) -> Dictionary:
    if not origin.is_finite() or not direction.is_finite() or direction.length_squared() < .000001:
        return {}
    var offset := origin - centres[5]
    var d := direction.normalized()
    var b := offset.dot(d)
    var c := offset.length_squared() - RADIUS * RADIUS
    var discriminant := b * b - c
    if discriminant < 0:
        return {}
    var t := -b - sqrt(discriminant)
    if t < 0:
        t = -b + sqrt(discriminant)
    if t < 0:
        return {}
    var p := origin + d * t
    return {"position": p, "direction": (p - centres[5]).normalized()}

func _slices() -> void:
    var paths: Array = []
    for i in 13:
        var y := lerpf(-1.2, 1.2, i / 12.0)
        var r := sqrt(RADIUS * RADIUS - y * y)
        var disc := CylinderMesh.new()
        disc.top_radius = r
        disc.bottom_radius = r
        disc.height = .018
        disc.radial_segments = 64
        var mat := _mat(Color("b4b3ee"), .12)
        _object(disc, centres[6] + Vector3(0, y, 0), mat)
        var ring: Array[Vector3] = []
        for j in 80:
            var a := TAU * j / 80.0
            ring.append(centres[6] + Vector3(cos(a) * r, y, sin(a) * r))
        paths.append(ring)
    _tubes(paths, .008, _mat(Color("c4b9ff"), 1.0))

func _tails() -> void:
    var material := _mat(Color.WHITE, 2.0)
    material.vertex_color_use_as_albedo = true
    # Colour changes both albedo and emission through per-instance modulation.
    material.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
    tails = _multi(_sphere(.026, 8), material, 24 * 24, true)
    update_tails()

func update_tails() -> void:
    for strand in 24:
        var phi := TAU * strand / 24.0
        for j in 24:
            var age := j / 23.0
            var t := time * .55 - j * .028 + phi * 1.8
            var d := Vector3(sin(t) * cos(phi), cos(t), sin(t) * sin(phi))
            var scale_factor := lerpf(1.4, .18, age)
            tails.set_instance_transform(strand * 24 + j, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale_factor), centres[7] + d * RADIUS))
            var colour := Color("ffd6a0").lerp(Color("ee87ba"), strand / 23.0)
            colour *= pow(1.0 - age, 1.2)
            colour.a = 1.0
            tails.set_instance_color(strand * 24 + j, colour)

func clear_brush() -> void:
    brush_count = 0
    brush_next = 0
    _refresh_brush_visibility()
    has_last_sample = false

func clear_paint() -> void:
    paint_image.fill(Color(0, 0, 0, 0))
    paint_dirty = true
    paint_count = 0
    has_last_sample = false

func snapshot() -> Dictionary:
    return {"version": 2, "stamps": brush_state.duplicate(true), "count": brush_count,
        "next": brush_next, "style": brush_style, "paint": paint_image.save_png_to_buffer(),
        "paint_count": paint_count, "ink": ink_index, "radius": brush_radius}

func restore_snapshot(data: Dictionary) -> bool:
    if data.get("version") != 2 or not data.get("stamps") is Array or data.stamps.size() != MAX_STAMPS:
        return false
    for property in ["count", "next", "style", "paint_count", "ink"]:
        if not data.get(property) is int:
            return false
    if data.count < 0 or data.count > MAX_STAMPS or data.next < 0 or data.next >= MAX_STAMPS or data.style < 0 or data.style > 2 or data.ink < 0 or data.ink > 3:
        return false
    if not data.get("radius") is float or not is_finite(data.radius) or data.radius < .045 or data.radius > .38:
        return false
    if not data.get("paint") is PackedByteArray:
        return false
    var restored := Image.new()
    if restored.load_png_from_buffer(data.paint) != OK or restored.get_width() != W or restored.get_height() != H:
        return false
    for i in MAX_STAMPS:
        if not data.stamps[i] is Dictionary:
            return false
        if i >= data.count:
            continue
        var record: Dictionary = data.stamps[i]
        if not record.get("position") is Vector3 or not record.position.is_finite() or not record.get("colour") is Color or not record.get("radius") is float:
            return false
        if not is_finite(record.radius) or record.radius <= 0 or record.radius > .5:
            return false
    brush_state.assign(data.stamps.duplicate(true))
    brush_count = data.count
    brush_next = data.next
    brush_style = data.style
    ink_index = data.ink
    brush_radius = data.radius
    for i in brush_count:
        _write_stamp(i)
    _refresh_brush_visibility()
    restored.convert(Image.FORMAT_RGBA8)
    paint_image = restored
    paint_count = data.paint_count
    paint_dirty = true
    has_last_sample = false
    update_detail()
    return true

func remember_undo() -> void:
    undo_stack.append(snapshot())
    if undo_stack.size() > 12:
        undo_stack.pop_front()

func undo() -> bool:
    drawing = false
    has_last_sample = false
    if undo_stack.is_empty():
        return false
    return restore_snapshot(undo_stack.pop_back())

func save_drawing(path: String = SAVE_PATH) -> bool:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_var(snapshot())
    file.flush()
    return file.get_error() == OK

func load_drawing(path: String = SAVE_PATH) -> bool:
    if not FileAccess.file_exists(path):
        return false
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return false
    var data: Variant = file.get_var(false)
    if not data is Dictionary:
        return false
    var before := snapshot()
    if not restore_snapshot(data):
        return false
    undo_stack.append(before)
    if undo_stack.size() > 12:
        undo_stack.pop_front()
    drawing = false
    return true

func reset_demo(which: int = -1) -> void:
    if which == -1 or which == 4:
        clear_brush()
        for i in 540:
            var t := i / 540.0
            var a := t * TAU
            var radius := .81 + .29 * cos(3 * a)
            var p := Vector3(cos(2 * a) * radius, .49 * sin(3 * a), sin(2 * a) * radius)
            var colour: Color = PALETTE[int(t * 3)].lerp(PALETTE[(int(t * 3) + 1) % 3], fposmod(t * 3, 1.0))
            stamp_space(centres[4] + p, colour, .18)
    if which == -1 or which == 5:
        clear_paint()
        for i in 360:
            var t := i / 359.0
            var a := t * TAU
            var d := Vector3(.8 * sin(a), .6 * sin(2 * a), .65 + .2 * cos(a)).normalized()
            paint_direction(d, Color("ed94b9").lerp(Color("8ddedb"), t), .1)

func _hud() -> void:
    var strip := ColorRect.new()
    strip.color = Color(.025, .03, .05, .9)
    strip.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    strip.offset_bottom = 83
    strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(strip)
    var title := Label.new()
    title.position = Vector2(24, 15)
    title.text = "PAINTING SPACE    1–8 inspect  /  0 gallery    ·    drag orbit  ·  right mouse + WASD/QE fly  ·  G glow  ·  Space pause"
    title.add_theme_font_size_override("font_size", 17)
    canvas.add_child(title)
    detail.position = Vector2(24, 45)
    detail.add_theme_font_size_override("font_size", 16)
    detail.add_theme_color_override("font_color", Color("aeb7cc"))
    canvas.add_child(detail)
    tools_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    tools_label.offset_left = 24
    tools_label.offset_top = -85
    tools_label.offset_bottom = -48
    tools_label.add_theme_font_size_override("font_size", 16)
    canvas.add_child(tools_label)
    status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    status.offset_left = 24
    status.offset_top = -42
    status.offset_bottom = -12
    status.add_theme_font_size_override("font_size", 15)
    status.add_theme_color_override("font_color", Color("a1c9d2"))
    canvas.add_child(status)
    add_child(canvas)
    update_detail()

func update_detail() -> void:
    detail.text = "Choose a form to approach it. All spheres share a 2.6 m envelope."
    if selected >= 0:
        detail.text = "%02d  %s  /  %s" % [selected + 1, NAMES[selected], NOTES[selected]]
        if selected == 4 or selected == 5:
            detail.text = "%02d  %s   ·   Draw with left mouse. Shift-drag to orbit." % [selected + 1, NAMES[selected]]
    tools_label.visible = selected == 4 or selected == 5
    tools_label.text = "X colour   ·   [ / ] size   ·   Z undo   ·   C clear   ·   R example   ·   F5 save / F9 load"
    if selected == 4:
        tools_label.text = "B " + BRUSH_NAMES[brush_style] + "   ·   " + tools_label.text
    if tools_label.visible:
        status.text = "%s ink   ·   brush %.0f cm%s" % [["Pink", "Cyan", "Amber", "Lilac"][ink_index], brush_radius * 100, "   ·   depth %.1f m" % brush_depth if selected == 4 else ""]
    else:
        status.text = ""

func inspect(index: int) -> void:
    selected = index
    drawing = false
    has_last_sample = false
    for i in stage_roots.size():
        stage_roots[i].visible = index < 0 or index == i
    backdrop.visible = index < 0
    focus = centres[index] if index >= 0 else Vector3(0, 1.6, 0)
    distance = 6.5 if index >= 0 else 35.0
    pitch = .23 if index >= 0 else .52
    yaw = .25 if index >= 0 else .22
    brush_depth = distance
    update_camera()
    update_detail()

func update_camera() -> void:
    camera.position = focus + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
    camera.look_at(focus)

func _pointer() -> Dictionary:
    var origin := camera.project_ray_origin(pointer_position)
    var ray := camera.project_ray_normal(pointer_position)
    if selected == 5:
        return sphere_hit(origin, ray)
    if selected == 4:
        var point := brush_plane_point if drawing else camera.position - camera.basis.z * brush_depth
        var normal := brush_plane_normal if drawing else camera.basis.z
        var denom := normal.dot(ray)
        if absf(denom) > .0001:
            var t := normal.dot(point - origin) / denom
            if t > 0:
                return {"position": origin + ray * t}
    return {}

func _end_stroke() -> void:
    # A mouse release outside the window may never reach this scene.
    drawing = false
    has_last_sample = false
    tick = 0.0

func _input(event: InputEvent) -> void:
    if event is InputEventMouse:
        pointer_position = event.position
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode >= KEY_0 and event.keycode <= KEY_8:
            inspect(event.keycode - KEY_1)
        elif event.keycode == KEY_G:
            environment.glow_enabled = not environment.glow_enabled
        elif event.keycode == KEY_SPACE:
            paused = not paused
        elif event.keycode == KEY_C:
            if selected == 4:
                remember_undo()
                clear_brush()
            elif selected == 5:
                remember_undo()
                clear_paint()
        elif event.keycode == KEY_R:
            remember_undo()
            reset_demo(selected)
        elif event.keycode == KEY_B and selected == 4:
            set_brush_style(brush_style + 1)
        elif event.keycode == KEY_X:
            ink_index = (ink_index + 1) % PALETTE.size()
            update_detail()
        elif event.keycode == KEY_BRACKETLEFT or event.keycode == KEY_BRACKETRIGHT:
            brush_radius = clampf(brush_radius * (.8 if event.keycode == KEY_BRACKETLEFT else 1.25), .045, .38)
            update_detail()
        elif event.keycode == KEY_Z:
            status.text = "Last stroke undone." if undo() else "Nothing to undo."
        elif event.keycode == KEY_F5:
            status.text = "Drawing saved locally. F9 brings it back." if save_drawing() else "Could not save the drawing."
        elif event.keycode == KEY_F9:
            status.text = "Saved drawing restored." if load_drawing() else "No readable drawing saved yet."
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            drawing = event.pressed and (selected == 4 or selected == 5) and not event.shift_pressed
            if drawing:
                remember_undo()
                has_last_sample = false
                brush_plane_point = camera.position - camera.basis.z * brush_depth
                brush_plane_normal = camera.basis.z
                sample_stroke(_pointer())
                tick = 0.0
            else:
                has_last_sample = false
        if event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
            var step := -.3 if event.button_index == MOUSE_BUTTON_WHEEL_UP else .3
            if selected == 4:
                brush_depth = clampf(brush_depth + step, .7, 20)
                brush_plane_point = camera.position - camera.basis.z * brush_depth
                update_detail()
            else:
                distance = clampf(distance + step, 1.7, 48)
                update_camera()
    if event is InputEventMouseMotion:
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
            drawing = false
            camera.rotation.y -= event.relative.x * .004
            camera.rotation.x = clampf(camera.rotation.x - event.relative.y * .004, -1.5, 1.5)
        elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not drawing:
            yaw -= event.relative.x * .006
            pitch = clampf(pitch + event.relative.y * .006, -.5, 1.4)
            update_camera()
        elif drawing:
            sample_stroke(_pointer())
            tick = 0.0

func _process(delta: float) -> void:
    if not paused:
        time += delta
        update_tails()
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        var movement := Vector3(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
        camera.position += camera.basis * movement.normalized() * delta * 5
    var hit := _pointer()
    cursor.visible = not capture_mode and not hit.is_empty() and (selected == 4 or selected == 5)
    guide.visible = cursor.visible and selected == 4 and hit.position.y > .19
    if cursor.visible:
        cursor.position = hit.position
        var normal: Vector3 = hit.direction if selected == 5 else camera.basis.z
        var helper := Vector3.RIGHT if absf(normal.dot(Vector3.UP)) > .95 else Vector3.UP
        var x := helper.cross(normal).normalized()
        cursor.basis = Basis(x, normal, x.cross(normal)).scaled(Vector3.ONE * brush_radius)
    if guide.visible:
        var height: float = hit.position.y - .19
        guide.position = Vector3(hit.position.x, .19 + height * .5, hit.position.z)
        guide.scale = Vector3(1, height, 1)
    if drawing:
        tick += delta
        if hit.is_empty():
            has_last_sample = false
        elif tick >= .045:
            tick = 0
            sample_stroke(hit)
    if paint_dirty:
        paint_texture.update(paint_image)
        paint_dirty = false
