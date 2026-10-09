extends Node3D
## Six renderings of the same independent stored strokes. Desktop research scene.
const Geometry = preload("res://stroke_geometry.gd")
const NAMES = ["A ROUND LINE", "A FLAT STROKE", "A LOADED STROKE", "A TURNING RIBBON", "A TRANSLUCENT WASH", "A DRY BRUSH"]
const NOTES = ["A small round section follows the path.", "Two edges enclose a continuous face.", "The width grows and narrows along the gesture.", "The section turns while the path stays fixed.", "Overlaps depend on opacity and view.", "Gaps interrupt the image; the mesh remains."]
const COLOURS = [Color("f39abd"), Color("79dacc"), Color("e9bb74"), Color("ac9ee8")]
const MAX_POINTS = 1600
const MAX_STROKES = 24
const MAX_RENDER_SAMPLES = 4096
const MAX_SAMPLES_PER_STROKE = 512
const SAVE = "user://line-brush-drawing.json"
var strokes: Array = []
var undo_stack: Array = []
var roots: Array[Node3D] = []
var meshes: Array[Node3D] = []
var centres: Array[Vector3] = []
var camera = Camera3D.new()
var environment = Environment.new()
var canvas = CanvasLayer.new()
var title = Label.new()
var info = Label.new()
var status = Label.new()
var backdrop = Node3D.new()
var selected = -1
var preset = 0
var width = 0.42
var spacing = 0.055
var twist = TAU
var opacity = 0.34
var ink_index = 0
var yaw = 0.28
var pitch = 0.47
var distance = 29.0
var focus = Vector3(0, 1.3, 0)
var pointer = Vector2(800, 500)
var drawing = false
var draw_normal = Vector3.BACK
var draw_origin = Vector3.ZERO
var depth_offset = 0.0
var pending_rebuild = false
var font: FontFile
var notice = ""
var adaptive_sampling = false

func _ready() -> void:
    font = load("res://JetBrainsMono-Medium.ttf")
    _room()
    for i in 6:
        var centre = Vector3((i % 3 - 1) * 6.4, 2.5, -4.2 if i < 3 else 4.2)
        centres.append(centre)
        var stand = Node3D.new()
        add_child(stand)
        roots.append(stand)
        _box(stand, Vector3(5.05, .18, 3.5), Vector3(centre.x, .09, centre.z), Color("c7c3bf"))
        _label(stand, "%02d   %s" % [i + 1, NAMES[i]], Vector3(centre.x, .196, centre.z + 1.31), 27, .0065, true)
        var body = Node3D.new()
        stand.add_child(body)
        body.position = centre
        meshes.append(body)
    add_child(camera)
    camera.current = true
    camera.fov = 44
    _hud()
    get_window().focus_exited.connect(end_stroke)
    reset_example(0, false)
    update_camera()

func _material(colour: Color, shine: bool = false) -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    mat.albedo_color = colour
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mat.roughness = .38 if shine else .73
    mat.metallic = .22 if shine else .0
    return mat

func _box(parent: Node3D, size: Vector3, pos: Vector3, colour: Color) -> void:
    var instance = MeshInstance3D.new()
    var mesh = BoxMesh.new()
    mesh.size = size
    instance.mesh = mesh
    instance.material_override = _material(colour)
    instance.position = pos
    parent.add_child(instance)

func _label(parent: Node3D, text: String, pos: Vector3, size: int, pixel: float, on_plinth: bool = false) -> void:
    var label = Label3D.new()
    label.text = text
    label.font = font
    label.font_size = size
    label.pixel_size = pixel
    label.outline_size = 0
    label.modulate = Color("42434a") if on_plinth else Color("d8d0ca")
    if on_plinth:
        label.rotation_degrees.x = -90
    label.position = pos
    parent.add_child(label)

func _room() -> void:
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("171822")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("bac9e7")
    environment.ambient_light_energy = .5
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.tonemap_white = 5.0
    var world = WorldEnvironment.new()
    world.environment = environment
    add_child(world)
    var key = DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-43, -27, 0)
    key.light_color = Color("ffe5d7")
    key.light_energy = 1.5
    key.shadow_enabled = true
    add_child(key)
    var fill = DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(24, 152, 0)
    fill.light_color = Color("b1c6ff")
    fill.light_energy = .65
    add_child(fill)
    _box(self, Vector3(25, .14, 24), Vector3(0, -.09, 0), Color("272935"))
    add_child(backdrop)
    _box(backdrop, Vector3(25, 7, .14), Vector3(0, 3.5, -9), Color("20222d"))
    _label(backdrop, "A   L I N E   A C Q U I R E S   A   B O D Y", Vector3(0, 5.55, -8.8), 58, .012)
    _label(backdrop, "One gesture. Six constructions. Walk around the difference.", Vector3(0, 4.55, -8.8), 28, .012)

func _hud() -> void:
    add_child(canvas)
    for label in [title, info, status]:
        label.add_theme_font_override("font", font)
        label.add_theme_color_override("font_color", Color("eee5de"))
        label.add_theme_color_override("font_shadow_color", Color("171822"))
        label.add_theme_constant_override("shadow_offset_x", 1)
        label.add_theme_constant_override("shadow_offset_y", 2)
        canvas.add_child(label)
    title.position = Vector2(36, 27)
    title.add_theme_font_size_override("font_size", 27)
    info.position = Vector2(36, 78)
    info.add_theme_font_size_override("font_size", 16)
    status.position = Vector2(36, 917)
    status.add_theme_font_size_override("font_size", 16)
    _update_hud()

func _update_hud() -> void:
    title.text = "A LINE ACQUIRES A BODY" if selected < 0 else "%02d  %s" % [selected + 1, NAMES[selected]]
    info.text = "1–6 inspect  ·  0 gallery  ·  P gesture / crossing / portrait\nLeft-drag orbit  ·  Shift + left-drag draw  ·  Wheel zoom  ·  Shift + wheel draw depth\n[ ] width  ·  , . twist  ·  - = wash opacity  ·  S coarse / fine sampling\nX next colour  ·  C clear  ·  Z undo stroke  ·  R restore  ·  F5 / F9 save / load"
    var count = 0
    for stroke in strokes:
        count += stroke.points.size()
    status.text = "%s\n%d strokes / %d positions  |  width %.2f m  |  sampling %.3f m  |  turn %.0f°  |  opacity %.2f\n%s%s" % [NOTES[selected] if selected >= 0 else "Every stand holds the same stored gesture.", strokes.size(), count, width, spacing, rad_to_deg(twist), opacity, notice, "  Detail capped; stored path retained." if adaptive_sampling else ""]

func reset_example(which: int, remember: bool = true) -> void:
    end_stroke()
    if remember:
        _remember()
    preset = which % 3
    strokes.clear()
    depth_offset = 0.0
    if preset == 0:
        var path = PackedVector3Array()
        for i in 181:
            var t = i / 180.0
            path.append(Vector3(1.75 * sin(TAU * t) + .5 * t, 1.35 * cos(TAU * t) + .32 * sin(TAU * t * 2.0), .52 * sin(TAU * t * 2.0)))
        strokes.append({"points": path, "colour": COLOURS[0]})
    elif preset == 1:
        for k in 3:
            var path = PackedVector3Array()
            for i in 101:
                var t = i / 100.0
                var a = (t - .5) * 4.0
                path.append(Vector3(a, sin(t * TAU + k * TAU / 3) * .9, (k - 1) * .25 + sin(t * PI) * .22))
            strokes.append({"points": path, "colour": COLOURS[k]})
    else:
        # Authored paths: a repeatable spatial drawing, not a reconstructed painting.
        _path_from_2d([[0,1.65],[-.65,1.53],[-1.0,1.04],[-1.13,.4],[-1.0,-.28],[-.68,-.82],[0,-1.05],[.65,-.83],[.98,-.25],[1.1,.5],[.94,1.15],[.5,1.53],[0,1.65]], -.15, 0)
        _path_from_2d([[-.91,.47],[-.69,.62],[-.44,.62],[-.25,.45],[-.5,.36],[-.76,.37],[-.91,.47]], .18, 1)
        _path_from_2d([[.25,.45],[.49,.64],[.75,.6],[.92,.42],[.65,.34],[.41,.35],[.25,.45]], .18, 1)
        _path_from_2d([[.02,.43],[-.10,.05],[-.18,-.3],[.06,-.4],[.24,-.29]], .51, 2)
        _path_from_2d([[-.51,-.65],[-.24,-.72],[.05,-.74],[.31,-.69],[.56,-.57]], .3, 2)
        _path_from_2d([[-1.04,-.36],[-1.35,.14],[-1.37,.81],[-1.04,1.54],[-.34,1.92],[.51,1.84],[1.19,1.37],[1.41,.55],[1.23,-.32]], -.4, 3)
        _path_from_2d([[-.68,-.83],[-.76,-1.4],[-1.35,-1.58],[-1.76,-1.92]], -.28, 3)
        _path_from_2d([[.63,-.88],[.79,-1.4],[1.41,-1.63],[1.78,-1.93]], -.28, 3)
    notice = ["A spatial loop; only its section and surface change.", "Three coloured strokes overlap at separate depths.", "An authored portrait; its depth is deliberately composed."][preset]
    rebuild()

func _path_from_2d(coords: Array, z: float, colour: int) -> void:
    var path = PackedVector3Array()
    for p in coords:
        path.append(Vector3(p[0], p[1], z))
    strokes.append({"points": path, "colour": COLOURS[colour]})

func options_for(index: int) -> Dictionary:
    return {"shape": "tube" if index == 0 else "ribbon", "width": width * .12 if index == 0 else width, "taper": .94 if index in [2, 3, 4, 5] else 0.0, "twist": twist if index == 3 else 0.0, "sides": 8}

func rebuild() -> void:
    pending_rebuild = false
    adaptive_sampling = false
    var sampled: Array = []
    for stroke in strokes:
        sampled.append(render_points(stroke.points))
    for i in 6:
        for old in meshes[i].get_children():
            meshes[i].remove_child(old)
            old.queue_free()
        for j in strokes.size():
            var stroke = strokes[j]
            var points = sampled[j]
            var mesh = Geometry.build_mesh(points, options_for(i))
            if mesh.get_surface_count() == 0:
                continue
            var instance = MeshInstance3D.new()
            instance.mesh = mesh
            var colour: Color = stroke.colour
            if i in [4, 5]:
                var mat = ShaderMaterial.new()
                mat.shader = load("res://wash.gdshader" if i == 4 else "res://dry.gdshader")
                mat.set_shader_parameter("ink", colour)
                if i == 4:
                    mat.set_shader_parameter("opacity", opacity)
                instance.material_override = mat
                instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            else:
                instance.material_override = _material(colour, true)
            meshes[i].add_child(instance)
    _update_hud()

func render_points(path: PackedVector3Array) -> PackedVector3Array:
    var clean = Geometry.clean_points(path)
    var length = 0.0
    for i in range(1, clean.size()):
        length += clean[i - 1].distance_to(clean[i])
    var allowance = mini(MAX_SAMPLES_PER_STROKE, maxi(8, MAX_RENDER_SAMPLES / maxi(1, strokes.size())))
    var actual_spacing = maxf(spacing, length / float(allowance - 1) + .000001)
    adaptive_sampling = adaptive_sampling or actual_spacing > spacing
    return Geometry.resample(clean, actual_spacing)

func inspect(index: int) -> void:
    end_stroke()
    selected = index
    depth_offset = 0.0
    for i in 6:
        roots[i].visible = index < 0 or index == i
    backdrop.visible = index < 0
    focus = Vector3(0, 1.3, 0) if index < 0 else centres[index]
    yaw = .28 if index < 0 else .12
    pitch = .47 if index < 0 else .12
    distance = 29.0 if index < 0 else 9.0
    update_camera()
    _update_hud()

func update_camera() -> void:
    camera.position = focus + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
    camera.look_at(focus, Vector3.UP)

func clear_drawing() -> void:
    end_stroke()
    _remember()
    strokes.clear()
    notice = "Shift + drag to draw. Release to start another stroke."
    rebuild()

func _remember() -> void:
    undo_stack.append(strokes.duplicate(true))
    if undo_stack.size() > 12:
        undo_stack.pop_front()

func undo() -> void:
    end_stroke()
    if not undo_stack.is_empty():
        strokes = undo_stack.pop_back()
        rebuild()

func begin_stroke(at: Vector2) -> void:
    if selected < 0:
        notice = "Choose a stand with 1–6 before drawing."
        _update_hud()
        return
    if strokes.size() >= MAX_STROKES or point_count() >= MAX_POINTS:
        notice = "Drawing limit reached; undo, clear or save this study."
        _update_hud()
        return
    _remember()
    draw_normal = camera.global_basis.z
    draw_origin = centres[selected] + draw_normal * depth_offset
    strokes.append({"points": PackedVector3Array(), "colour": COLOURS[ink_index]})
    drawing = true
    sample_pointer(at)

func point_count() -> int:
    var count = 0
    for stroke in strokes:
        count += stroke.points.size()
    return count

func sample_pointer(at: Vector2) -> void:
    if not drawing or point_count() >= MAX_POINTS:
        return
    var origin = camera.project_ray_origin(at)
    var ray = camera.project_ray_normal(at)
    var den = ray.dot(draw_normal)
    if absf(den) < .0001:
        return
    var depth = (draw_origin - origin).dot(draw_normal) / den
    if depth <= .1:
        return
    var p = origin + ray * depth - centres[selected]
    var path: PackedVector3Array = strokes.back().points
    if path.is_empty() or path[-1].distance_to(p) >= .022:
        path.append(p)
        strokes[-1].points = path
        pending_rebuild = true

func minimum_stroke_points() -> int:
    return 2

func end_stroke() -> void:
    if drawing and not strokes.is_empty() and strokes.back().points.size() < minimum_stroke_points():
        strokes.pop_back()
        pending_rebuild = true
    drawing = false

func set_depth(value: float) -> void:
    depth_offset = clampf(value, -2.0, 2.0)
    if drawing:
        draw_origin = centres[selected] + draw_normal * depth_offset
        sample_pointer(pointer)
    notice = "Drawing plane offset: %.2f m" % depth_offset
    _update_hud()

func save_drawing(path: String = SAVE) -> bool:
    var records = []
    for stroke in strokes:
        var coords = []
        for p in stroke.points:
            coords.append([p.x, p.y, p.z])
        records.append({"points": coords, "colour": stroke.colour.to_html(true)})
    var file = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify({"version": 1, "strokes": records}))
    return true

func load_drawing(path: String = SAVE) -> bool:
    if not FileAccess.file_exists(path):
        return false
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null or file.get_length() > 500000:
        return false
    var data = JSON.parse_string(file.get_as_text())
    if not data is Dictionary or data.get("version") != 1 or not data.get("strokes") is Array or data.strokes.size() > MAX_STROKES:
        return false
    var next = []
    var total = 0
    for entry in data.strokes:
        if not entry is Dictionary or not entry.get("points") is Array or not entry.get("colour") is String or not Color.html_is_valid(entry.colour):
            return false
        var points = PackedVector3Array()
        for coord in entry.points:
            if not coord is Array or coord.size() != 3:
                return false
            for value in coord:
                if not (value is float or value is int) or not is_finite(float(value)) or absf(float(value)) > 100.0:
                    return false
            points.append(Vector3(coord[0], coord[1], coord[2]))
        total += points.size()
        if points.size() < minimum_stroke_points() or total > MAX_POINTS:
            return false
        next.append({"points": points, "colour": Color(entry.colour)})
    end_stroke()
    _remember()
    strokes = next
    rebuild()
    return true

func _process(_delta: float) -> void:
    if pending_rebuild:
        rebuild()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode >= KEY_1 and event.keycode <= KEY_6:
            inspect(event.keycode - KEY_1)
        elif event.keycode == KEY_0: inspect(-1)
        elif event.keycode == KEY_P: reset_example(preset + 1)
        elif event.keycode == KEY_R: reset_example(preset)
        elif event.keycode == KEY_C: clear_drawing()
        elif event.keycode == KEY_Z: undo()
        elif event.keycode == KEY_X:
            ink_index = (ink_index + 1) % COLOURS.size()
            notice = "Next stroke colour: " + ["pink", "mint", "amber", "lilac"][ink_index]
            _update_hud()
        elif event.keycode in [KEY_BRACKETLEFT, KEY_BRACKETRIGHT]:
            width = clampf(width + (-.07 if event.keycode == KEY_BRACKETLEFT else .07), .07, 1.2)
            rebuild()
        elif event.keycode in [KEY_COMMA, KEY_PERIOD]:
            twist += -PI / 4 if event.keycode == KEY_COMMA else PI / 4
            rebuild()
        elif event.keycode in [KEY_MINUS, KEY_EQUAL]:
            opacity = clampf(opacity + (-.1 if event.keycode == KEY_MINUS else .1), .05, .95)
            rebuild()
        elif event.keycode == KEY_S:
            spacing = .4 if spacing < .1 else .055
            rebuild()
        elif event.keycode == KEY_F5:
            end_stroke()
            notice = "Drawing saved locally." if save_drawing() else "Could not save drawing."
            _update_hud()
        elif event.keycode == KEY_F9:
            notice = "Drawing loaded." if load_drawing() else "No valid drawing found."
            _update_hud()
    elif event is InputEventMouseButton:
        pointer = event.position
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed and event.shift_pressed: begin_stroke(pointer)
            elif not event.pressed: end_stroke()
        elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
            var direction = 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
            if event.shift_pressed:
                set_depth(depth_offset + direction * .15)
            else:
                distance = clampf(distance - direction * .55, 3.0, 38.0)
                update_camera()
    elif event is InputEventMouseMotion:
        pointer = event.position
        if drawing:
            sample_pointer(pointer)
        elif event.button_mask & MOUSE_BUTTON_MASK_LEFT:
            yaw -= event.relative.x * .007
            pitch = clampf(pitch + event.relative.y * .006, -.5, 1.35)
            update_camera()
