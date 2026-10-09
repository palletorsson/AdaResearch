extends "res://gallery.gd"
## A focused drawing view. The same retained strokes become lines or light dots.
var draw_mode = 0
var shape_instances: Array = []
const DRAW_SAVE = "user://line-dot-drawing.json"

func _ready() -> void:
    super._ready()
    for i in roots.size():
        roots[i].visible = i == 0
        for child in roots[i].get_children():
            child.visible = i == 0 and child == meshes[0]
    selected = 0
    centres[0] = Vector3.ZERO
    meshes[0].position = Vector3.ZERO
    focus = Vector3.ZERO
    width = .25
    spacing = .085
    yaw = 0.0
    pitch = 0.0
    distance = 7.3
    reset_example(2, false)
    update_camera()
    _update_hud()

func _room() -> void:
    add_child(backdrop)
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("10121b")
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.tonemap_white = 5.0
    environment.glow_enabled = true
    environment.glow_intensity = 1.4
    environment.glow_hdr_threshold = .9
    environment.glow_bloom = 0.0
    var world = WorldEnvironment.new()
    world.environment = environment
    add_child(world)

func _update_hud() -> void:
    title.text = "COLOURED LINES" if draw_mode == 0 else "LIGHT DOTS"
    info.text = "Left-drag draw  ·  Click a point  ·  Right-drag orbit  ·  Wheel zoom\nShift + wheel changes drawing depth  ·  X colour  ·  [ ] size\nB or 1 / 2 lines / dots  ·  G glow  ·  S dot spacing\nC clear  ·  Z undo  ·  P examples  ·  R restore  ·  F5 / F9 save / load"
    status.text = "%d strokes / %d recorded positions  |  spacing %.3f m  |  depth %+.2f m\n%s%s" % [strokes.size(), point_count(), spacing, depth_offset, notice, "  Render detail capped; recorded path retained." if adaptive_sampling else ""]

func set_mode(mode: int) -> void:
    end_stroke()
    draw_mode = clampi(mode, 0, 1)
    rebuild()

func minimum_stroke_points() -> int:
    return 1

func _ink(colour: Color, luminous: bool) -> Material:
    if luminous:
        var glow_material = ShaderMaterial.new()
        glow_material.shader = preload("res://light_dot.gdshader")
        glow_material.set_shader_parameter("ink", colour)
        return glow_material
    var mat = StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = colour
    return mat

func rebuild() -> void:
    pending_rebuild = false
    adaptive_sampling = false
    shape_instances.clear()
    if meshes.is_empty():
        return
    for old in meshes[0].get_children():
        meshes[0].remove_child(old)
        old.queue_free()
    for stroke in strokes:
        var points = render_points(stroke.points)
        if points.is_empty():
            continue
        if draw_mode == 0 and points.size() > 1:
            var instance = MeshInstance3D.new()
            instance.mesh = Geometry.build_mesh(points, {"shape":"tube", "width":width * .12, "sides":8, "taper":0.0})
            instance.material_override = _ink(stroke.colour, false)
            instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            meshes[0].add_child(instance)
            shape_instances.append(instance)
        else:
            var sphere = SphereMesh.new()
            sphere.radius = width * .075
            sphere.height = sphere.radius * 2.0
            sphere.radial_segments = 8
            sphere.rings = 4
            var mm = MultiMesh.new()
            mm.transform_format = MultiMesh.TRANSFORM_3D
            mm.mesh = sphere
            mm.instance_count = points.size()
            for i in points.size():
                mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, points[i]))
            var instance = MultiMeshInstance3D.new()
            instance.multimesh = mm
            instance.material_override = _ink(stroke.colour, draw_mode == 1)
            instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            meshes[0].add_child(instance)
            shape_instances.append(instance)
    _update_hud()

func clear_drawing() -> void:
    super.clear_drawing()
    notice = "Left-drag to draw. Click to leave one point."
    _update_hud()

func save_drawing(path: String = DRAW_SAVE) -> bool:
    return super.save_drawing(path)

func load_drawing(path: String = DRAW_SAVE) -> bool:
    return super.load_drawing(path)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_B: set_mode(1 - draw_mode)
            KEY_1: set_mode(0)
            KEY_2: set_mode(1)
            KEY_G:
                environment.glow_enabled = not environment.glow_enabled
                notice = "Screen glow on." if environment.glow_enabled else "Screen glow off; the dot geometry remains."
            KEY_C: clear_drawing()
            KEY_Z: undo()
            KEY_P: reset_example(preset + 1)
            KEY_R: reset_example(preset)
            KEY_X:
                ink_index = (ink_index + 1) % COLOURS.size()
                notice = "Next stroke: " + ["pink", "mint", "amber", "lilac"][ink_index]
            KEY_BRACKETLEFT, KEY_BRACKETRIGHT:
                width = clampf(width + (-.035 if event.keycode == KEY_BRACKETLEFT else .035), .07, .8)
                rebuild()
            KEY_S:
                spacing = .16 if spacing < .1 else .085
                rebuild()
            KEY_F5:
                end_stroke()
                notice = "Drawing saved locally." if save_drawing() else "Could not save drawing."
            KEY_F9:
                notice = "Drawing loaded." if load_drawing() else "No valid drawing saved yet."
        _update_hud()
    elif event is InputEventMouseButton:
        pointer = event.position
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed: begin_stroke(pointer)
            else: end_stroke()
        elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
            end_stroke()
        elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
            var direction = 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
            if event.shift_pressed:
                set_depth(depth_offset + direction * .15)
            else:
                end_stroke()
                distance = clampf(distance - direction * .4, 3.0, 30.0)
                update_camera()
    elif event is InputEventMouseMotion:
        pointer = event.position
        if drawing:
            sample_pointer(pointer)
        elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
            yaw -= event.relative.x * .007
            pitch = clampf(pitch + event.relative.y * .006, -.7, 1.35)
            update_camera()
