extends Node3D
## Isolated geometry study. No museum dependencies, scene lookups or XR setup.
const Sweep = preload("profile_sweep.gd")
const GLYPHS = ["O", "O", "B", "C", "I", ":"]
const TITLES = ["01  /  A PASSAGE", "02  /  A FLARED VESSEL", "03  /  TWO WELLS", "04  /  A CURLED CHANNEL", "05  /  A NEW HOLE", "06  /  TWO BODIES"]
const OPERATIONS = ["O  +  depth", "O  +  changing width", "B  +  rising turn", "C  +  curved path", "I  +  closed path", ":  +  one shared path"]
var font := FontFile.new()
var specimens: Array[MeshInstance3D] = []
var sections: Array[Dictionary] = []
var section_frames: Array = []
var camera := Camera3D.new()
var focus := Vector3(0,2,0)
var yaw := .40
var pitch := .55
var distance := 32.0
var selected := -1
var canvas := CanvasLayer.new()

func _ready() -> void:
    assert(font.load_dynamic_font("res://JetBrainsMono-Medium.ttf") == OK)
    _environment()
    _box(Vector3(33,.2,27), Vector3(0,-.12,0), Color("32343b"))
    _box(Vector3(33,9,.2), Vector3(0,4.5,-12), Color("443d49"))
    _label("B O R R O W E D   O U T L I N E S", Vector3(0,7.5,-11.85), .014, 44)
    _label("A letter carries a boundary. What else can that boundary hold?", Vector3(0,6.4,-11.85), .010, 28)
    for i in 6:
        var place := Vector3((i%3-1)*10, .24, -5.0 if i<3 else 6.0)
        _box(Vector3(8.6,.24,8.8), place-Vector3(0,.12,0), Color("bab6b0"))
        var section := Sweep.profile(font, GLYPHS[i])
        var frames := _frames(i)
        sections.append(section)
        section_frames.append(frames)
        var object := MeshInstance3D.new()
        object.mesh = Sweep.make(section, frames, i==4)
        object.position = place
        object.material_override = _material(Color(["edcad7","dcafa8","bfc9bd","a9b9d5","d0bedf","ded5b7"][i]), .28 if i==4 else .48, .50 if i==4 else .08)
        add_child(object)
        specimens.append(object)
        _label(TITLES[i], place+Vector3(0,.18,4.25), .005, 30)
        _label(OPERATIONS[i], place+Vector3(0,-.01,4.25), .0045, 23)
        # A flat specimen keeps the borrowed section visible beside its new use.
        var small := MeshInstance3D.new()
        var slab_frames: Array[Transform3D] = [Transform3D(Basis.IDENTITY,Vector3.ZERO),Transform3D(Basis.IDENTITY,Vector3(0,0,.06))]
        small.mesh = Sweep.make(section, slab_frames)
        small.position = place+Vector3(-3.25,1.0,2.8)
        small.material_override = _material(Color("eadcd1"), .72, 0)
        add_child(small)
        _box(Vector3(1.3,1.45,.14),place+Vector3(-3.25,.78,2.69), Color("36333e"))
    _scale_figure(specimens[0].position+Vector3(0,0,1.4))
    add_child(camera)
    camera.current = true
    camera.fov = 52
    update_camera()
    var hud := Label.new()
    hud.text = "BORROWED OUTLINES     1–6: inspect a body   ·   0: gallery   ·   drag: orbit   ·   wheel: approach   ·   hold right mouse + WASD/QE: fly"
    hud.position = Vector2(24,20)
    hud.add_theme_font_size_override("font_size",16)
    hud.add_theme_color_override("font_color",Color("f4e7da"))
    canvas.add_child(hud)
    add_child(canvas)

func _frames(kind: int) -> Array[Transform3D]:
    var frames: Array[Transform3D] = []
    var upright := Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP)
    var steps := 96 if kind==4 else (1 if kind==0 else 48)
    for i in range(steps if kind==4 else steps+1):
        var t := float(i)/float(steps)
        var basis := Basis.IDENTITY
        var centre := Vector3.ZERO
        var width := 1.0
        match kind:
            0: # O is an upright doorway, extrusion front to back.
                width = 5.4
                centre = Vector3(0,2.7,lerpf(-1.1,1.1,t))
            1: # The annulus stays open at BOTH ends: vessel, not a sealed cup.
                width = 2.3-.65*sin(PI*t)+2.5*pow(t,3)
                basis = upright * Basis(Vector3.BACK,.22*PI*t)
                centre = Vector3(0,4.6*t,0)
            2: # Both B holes remain channels while the profile turns.
                width = 3.5
                basis = upright * Basis(Vector3.BACK,PI*.38*t)
                centre = Vector3(0,5.2*t,0)
            3: # Section frame follows the tangent of an open circular path.
                var angle := lerpf(-PI*.69,PI*.69,t)
                var radial := Vector3(cos(angle),0,sin(angle))
                basis = Basis(radial,Vector3.UP,Vector3(-sin(angle),0,cos(angle)))
                width = 2.2
                centre = radial*2.6+Vector3(0,1.1,0)
            4: # The I has no hole; joining the sweep creates one.
                var angle := TAU*t
                var radial := Vector3(cos(angle),0,sin(angle))
                basis = Basis(radial,Vector3.UP,Vector3(-sin(angle),0,cos(angle)))
                width = 1.4
                centre = radial*2.25+Vector3(0,.7,0)
            5: # Separate dots remain separate along the same bending frames.
                width = 3.8
                basis = upright * Basis(Vector3.BACK,-.35*PI*t)
                centre = Vector3(.9*sin(PI*t),4.8*t,0)
        frames.append(Transform3D(basis.scaled_local(Vector3(width,width,1)),centre))
    return frames

func _environment() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color("34445e")
    sky_material.sky_horizon_color = Color("d2b8bd")
    sky_material.ground_bottom_color = Color("282632")
    sky_material.ground_horizon_color = Color("897c91")
    sky.sky_material = sky_material
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = .50
    env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.ssao_enabled = true
    world.environment = env
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-47,-27,0)
    sun.light_color = Color("fff0d7")
    sun.light_energy = 1.7
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 65
    sun.shadow_bias = .4
    sun.shadow_normal_bias = 3.0
    sun.light_angular_distance = 2.0
    add_child(sun)
    var fill := OmniLight3D.new()
    fill.position = Vector3(8,7,8)
    fill.light_color = Color("c4c9ff")
    fill.light_energy = 2.0
    fill.omni_range = 28
    add_child(fill)

func _material(colour: Color, rough: float, metal: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = colour
    mat.roughness = rough
    mat.metallic = metal
    return mat

func _box(size: Vector3, at: Vector3, colour: Color) -> void:
    var object := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    object.mesh = box
    object.position = at
    object.material_override = _material(colour,.8,0)
    add_child(object)

func _label(words: String, at: Vector3, pixel: float, size: int) -> void:
    var label := Label3D.new()
    label.text = words
    label.position = at
    label.font_size = size
    label.pixel_size = pixel
    label.outline_size = 0
    label.modulate = Color("f3e8e0") if at.y>6 else Color("322c3c")
    add_child(label)

func _scale_figure(at: Vector3) -> void:
    # Schematic 1.7m reference, not an embodied player or a collision claim.
    var person := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = .17
    capsule.height = 1.7
    person.mesh = capsule
    person.material_override = _material(Color("302b39"),.9,0)
    person.position = at+Vector3(0,.85,0)
    add_child(person)
    _label("1.7 m",at+Vector3(.7,.85,0),.006,22)

func inspect(index: int) -> void:
    selected = index
    focus = specimens[index].position+Vector3(0,2.2,0) if index>=0 else Vector3(0,2,0)
    distance = 11.5 if index>=0 else 32
    yaw = .5 if index>=0 else .4
    pitch = .4 if index>=0 else .55
    update_camera()

func update_camera() -> void:
    camera.position = focus+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
    camera.look_at(focus)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode>=KEY_0 and event.keycode<=KEY_6:
            inspect(event.keycode-KEY_1)
    if event is InputEventMouseMotion:
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
            camera.rotation.y -= event.relative.x*.004
            camera.rotation.x = clampf(camera.rotation.x-event.relative.y*.004,-1.5,1.5)
        elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            yaw -= event.relative.x*.006
            pitch = clampf(pitch+event.relative.y*.006,-.10,1.4)
            update_camera()
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            distance = maxf(2,distance-.6)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            distance = minf(48,distance+.6)
        else:
            return
        update_camera()

func _process(delta: float) -> void:
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        var movement := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),
            float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q)),
            float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
        camera.position += camera.basis*movement.normalized()*delta*5
