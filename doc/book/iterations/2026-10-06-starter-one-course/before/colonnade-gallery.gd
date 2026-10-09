extends Node3D
## Walkable study: five profiles and staggered heights over a resolution matrix.
## Artwork inspired by Pompeian colour, not an archaeological reconstruction.

const Totem = preload("resolution_totem.gd")
const COUNTS: Array[int] = [4,6,8,12,16]
const HEIGHTS = [
    [3.30,4.70,2.65,5.35,3.95],
    [5.65,3.55,4.95,3.05,5.05],
    [4.15,5.90,3.75,5.10,2.85],
    [5.25,3.15,5.65,4.25,5.85],
    [3.65,5.45,4.40,5.95,4.85],
]
## Disable to restore the controlled, equal-height Vessel comparison.
@export var varied_forms := true
@export var own_environment := true
var columns: Array[Node3D] = []
var spawn := Vector3(1.7,0,3.2)
var architecture := Node3D.new()

func _ready() -> void:
    architecture.name = "Architecture"
    add_child(architecture)
    _architecture()
    for row in COUNTS.size():
        for col in COUNTS.size():
            var at := Vector3(-6.8+3.4*col,0,-2.8-4.0*row)
            var column := Totem.new()
            column.name = "Column_%d_%d" % [COUNTS[col],COUNTS[row]]
            column.radial_segments = COUNTS[col]
            column.profile_rings = COUNTS[row]
            if varied_forms:
                column.profile_kind = (row+col)%Totem.PROFILE_NAMES.size()
                column.column_height = HEIGHTS[row][col]
                column.width_factor = [1.0,0.92,1.02,0.96,1.0][(row*2+col)%5]
            column.position = at+Vector3.UP*0.22
            add_child(column)
            columns.append(column)
            _box(Vector3(1.86,0.22,1.86),at+Vector3.UP*0.11,_mat("ded4c0",0.8))
            _label("%s  /  %.2f M\n%02d SIDES  /  %02d RINGS" % [Totem.PROFILE_NAMES[column.profile_kind].to_upper(),column.height,COUNTS[col],COUNTS[row]],at+Vector3(0,0.39,0.95),0.0024,Color("e5c8a0"),22)
    _label("R I N G S   O F   A S H",Vector3(0,5.95,-21.9),0.012,Color("ead5ae"),38)
    _label("4     6     8     12     16",Vector3(0,5.3,-21.9),0.009,Color("cca588"),25)
    _label("SIDES ACROSS\nPROFILE DIVISIONS AHEAD",Vector3(-6.8,1.0,1.1),0.003,Color("d6c5a5"),26)
    _label("FIVE PROFILES / TWENTY-FIVE BODIES" if varied_forms else "ONE FORM / TWENTY-FIVE BODIES",Vector3(-6.8,0.69,1.1),0.002,Color("a99485"),22)
    _lighting()

func _architecture() -> void:
    var red := _mat("843930",0.93)
    var ash := _mat("c7bda8",0.87)
    var black := _mat("181c23",0.29)
    var stone := _mat("c6b694",0.64)
    var inlay := _mat("554951",0.7)
    _box(Vector3(20,0.3,28),Vector3(0,-0.15,-9),black)
    for side in [-1,1]:
        _box(Vector3(0.4,7.5,28),Vector3(side*10.0,3.75,-9),red)
        _box(Vector3(0.12,0.9,28),Vector3(side*9.74,0.45,-9),_mat("242027",0.7))
        _box(Vector3(0.17,0.10,28),Vector3(side*9.72,1.0,-9),stone)
        _box(Vector3(0.22,0.15,28),Vector3(side*9.7,5.35,-9),stone)
        _box(Vector3(0.38,1.85,28),Vector3(side*9.77,6.45,-9),ash)
        for row in 6:
            var z := -0.8-4.0*row
            _box(Vector3(0.16,3.65,0.12),Vector3(side*9.68,3.18,z),stone,false)
        # Two roof strips leave a continuous open nave of sky above the columns.
        _box(Vector3(3.1,0.25,28),Vector3(side*8.45,7.3,-9),ash)
    _box(Vector3(20,7.5,0.4),Vector3(0,3.75,-23),red)
    # Entrance has an actual open centre rather than a blocking wall.
    _box(Vector3(6.5,7.5,0.4),Vector3(-6.75,3.75,5),red)
    _box(Vector3(6.5,7.5,0.4),Vector3(6.75,3.75,5),red)
    _box(Vector3(7,2,0.4),Vector3(0,6.5,5),ash)
    for row in 6:
        var z := -0.8-4.0*row
        _box(Vector3(20,0.28,0.25),Vector3(0,6.7,z),ash,false)
        _box(Vector3(19.5,0.005,0.012),Vector3(0,0.004,z),inlay,false)
    for col in 6:
        _box(Vector3(0.012,0.005,27),Vector3(-8.5+3.4*col,0.004,-9),inlay,false)
    # A luminous rose disc faces the returning visitor; the sun remains above.
    var disc := MeshInstance3D.new()
    var circle := CylinderMesh.new()
    circle.top_radius = 1.45
    circle.bottom_radius = 1.45
    circle.height = 0.06
    circle.radial_segments = 64
    disc.mesh = circle
    disc.rotation_degrees.x = 90
    disc.position = Vector3(1.7,3.0,-22.72)
    var glow := _mat("d5a4ad",0.55)
    glow.emission_enabled = true
    glow.emission = Color("bd6d86")
    glow.emission_energy_multiplier = 1.25
    disc.material_override = glow
    architecture.add_child(disc)
    # Thin reveal around the disc gives the far wall a physical depth cue.
    var rim := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 1.49
    torus.outer_radius = 1.54
    torus.rings = 64
    torus.ring_segments = 8
    rim.mesh = torus
    rim.rotation_degrees.x = 90
    rim.position = Vector3(1.7,3.0,-22.64)
    rim.material_override = stone
    architecture.add_child(rim)

func _lighting() -> void:
    if not own_environment:
        return
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("b9b6c9")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("c1b7cf")
    env.ambient_light_energy = 0.26
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.glow_enabled = true
    env.glow_intensity = 0.5
    env.fog_enabled = true
    env.fog_light_color = Color("a18d9f")
    env.fog_light_energy = 0.6
    env.fog_density = 0.003
    var xr := XRServer.find_interface("OpenXR")
    env.ssao_enabled = RenderingServer.get_current_rendering_method()=="forward_plus" and not (xr != null and xr.is_initialized())
    env.ssao_radius = 0.3
    env.ssao_intensity = 1.3
    # Desktop light shafts; the headset keeps the less expensive depth haze.
    env.volumetric_fog_enabled = env.ssao_enabled
    env.volumetric_fog_density = 0.008
    env.volumetric_fog_length = 40.0
    env.volumetric_fog_albedo = Color("d5c2c0")
    env.volumetric_fog_ambient_inject = 0.25
    world.environment = env
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-46,-35,0)
    sun.light_color = Color("ffe5b3")
    sun.light_energy = 1.25
    sun.light_volumetric_fog_energy = 2.0
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 50
    sun.light_angular_distance = 0.45
    add_child(sun)
    for z in [-3.0,-11.0,-19.0]:
        var fill := OmniLight3D.new()
        fill.position = Vector3(0,5.8,z)
        fill.light_color = Color("a8accb")
        fill.light_energy = 0.6
        fill.omni_range = 9.0
        add_child(fill)

func _mat(hex: String, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(hex)
    material.roughness = roughness
    return material

func _box(size: Vector3, at: Vector3, material: Material, solid: bool = true) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.material_override = material
    mesh.position = at
    architecture.add_child(mesh)
    if solid:
        var body := StaticBody3D.new()
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
        mesh.add_child(body)
    return mesh

func _label(words: String, at: Vector3, pixel: float, colour: Color, size: int) -> void:
    var label := Label3D.new()
    label.text = words
    label.position = at
    label.pixel_size = pixel
    label.font_size = size
    label.outline_size = 0
    label.modulate = colour
    architecture.add_child(label)
