extends Node3D
## Static native proof: click-drag to orbit; wheel to zoom. No museum placement.
const Solid = preload("glyph_solid.gd")
var font := FontFile.new()
var specimens: Array[MeshInstance3D] = []
var camera := Camera3D.new()
var focus := Vector3(0,1.55,0)
var yaw := 0.12
var pitch := 0.17
var distance := 15.5

func _ready() -> void:
    assert(font.load_dynamic_font("res://JetBrainsMono-Medium.ttf")==OK)
    var background := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("22212a")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("abbad0")
    env.ambient_light_energy = 0.45
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    background.environment = env
    add_child(background)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-38,-28,0)
    light.light_color = Color("ffe6ce")
    light.light_energy = 1.25
    light.shadow_enabled = true
    add_child(light)
    var fill := OmniLight3D.new()
    fill.position = Vector3(-5,4,2)
    fill.light_color = Color("b9b7fb")
    fill.light_energy = 0.7
    fill.omni_range = 16
    add_child(fill)
    _box(Vector3(20,.2,10),Vector3(0,-.12,0),Color("323039"))
    _box(Vector3(20,7,.15),Vector3(0,3.5,-3.5),Color("47343a"))
    var chars := ["B","B","O","*","&"]
    var names := ["01 / LETTER","02 / OUTLINE CHANGED","03 / LETTER AS PASSAGE","04 / SYMBOL AS COLUMN","05 / TWIST THROUGH DEPTH"]
    for i in 5:
        var x := (i-2)*3.25
        _box(Vector3(2.65,.25,2.35),Vector3(x,.125,0),Color("cfc5b6"))
        var mesh := MeshInstance3D.new()
        mesh.mesh = Solid.make(font,chars[i],3.2 if i>=3 else (1.65 if i==2 else .42),i==1,PI*.70 if i==4 else 0.0)
        var material := StandardMaterial3D.new()
        material.albedo_color = Color("edc9d2") if i==1 or i==4 else Color("e7ddc8")
        material.roughness = .46
        material.metallic = .12
        mesh.material_override = material
        mesh.position = Vector3(x,1.15,-.15)
        if i>=3:
            mesh.position.y = .25
            mesh.rotation_degrees.x = -90
        add_child(mesh)
        specimens.append(mesh)
        _label(names[i],Vector3(x,.44,1.3),.0035,23)
    _label("A  L E T T E R  B E C O M E S  A  B O D Y",Vector3(0,4.25,-3.35),.011,32)
    _label("Font outline  /  changed points  /  depth  /  another use",Vector3(0,3.65,-3.35),.007,23)
    add_child(camera)
    camera.fov = 48
    camera.current = true
    update_camera()

func _box(size: Vector3, at: Vector3, colour: Color) -> void:
    var object := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    object.mesh = box
    object.position = at
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    material.roughness = .82
    object.material_override = material
    add_child(object)

func _label(words: String, at: Vector3, pixel: float, size: int) -> void:
    var label := Label3D.new()
    label.text = words
    label.position = at
    label.font_size = size
    label.pixel_size = pixel
    label.outline_size = 0
    label.modulate = Color("ead9ca")
    add_child(label)

func update_camera() -> void:
    camera.position = focus+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
    camera.look_at(focus)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        yaw -= event.relative.x*.006
        pitch = clampf(pitch+event.relative.y*.006,-.1,1.3)
        update_camera()
    if event is InputEventMouseButton and event.pressed:
        if event.button_index==MOUSE_BUTTON_WHEEL_UP:
            distance = maxf(4,distance-.7)
        elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
            distance = minf(24,distance+.7)
        update_camera()
