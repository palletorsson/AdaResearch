extends SceneTree

## Capture the composition_platform with a mock stack of colored primitives
## resting on it — demonstrates the capture-the-stack idea visually.

const PLATFORM := "res://commons/artifacts/composition_platform/composition_platform.tscn"

var _out := "user://composition_platform_demo.png"
var _wait := 4.0

func _initialize() -> void:
    for raw in OS.get_cmdline_user_args():
        var s := String(raw).strip_edges()
        if s.begins_with("--out="): _out = s.substr(6)
    call_deferred("_run")

func _run() -> void:
    var root := get_root()

    # Environment
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.10, 0.11, 0.16)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_color = Color(0.55, 0.55, 0.65)
    e.ambient_light_energy = 0.7
    env.environment = e
    root.add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(35), 0)
    sun.light_energy = 1.5
    root.add_child(sun)

    # Platform
    var pscene := load(PLATFORM) as PackedScene
    if pscene == null:
        push_error("platform missing"); quit(1); return
    var pf := pscene.instantiate()
    root.add_child(pf)

    # Mock stack: render colored cubes/sphere/wedge sitting on the platform
    # to simulate what a player composition looks like before capture.
    var stack := [
        {"shape": "cube",   "color": Color("#a02020"), "scale": 1.4},
        {"shape": "cube",   "color": Color("#0a0a0a"), "scale": 0.20},
        {"shape": "cube",   "color": Color("#1f4ecc"), "scale": 1.1},
        {"shape": "cube",   "color": Color("#0a0a0a"), "scale": 0.18},
        {"shape": "sphere", "color": Color("#f0c020"), "scale": 1.0},
        {"shape": "wedge",  "color": Color("#1a8848"), "scale": 0.9},
    ]
    var base_size := 0.10
    var y := 0.05  # platform top
    for prim in stack:
        var mi := MeshInstance3D.new()
        var sc: float = float(prim["scale"])
        var col: Color = prim["color"]
        match str(prim["shape"]):
            "cube":
                var bm := BoxMesh.new()
                bm.size = Vector3(base_size * sc, base_size * sc, base_size * sc)
                mi.mesh = bm
                y += base_size * sc * 0.5
            "sphere":
                var sm := SphereMesh.new()
                sm.radius = base_size * sc * 0.5
                sm.height = base_size * sc
                mi.mesh = sm
                y += base_size * sc * 0.5
            "wedge":
                var pm := PrismMesh.new()
                pm.size = Vector3(base_size * sc, base_size * sc * 0.8, base_size * sc)
                mi.mesh = pm
                y += base_size * sc * 0.4
        var mat := StandardMaterial3D.new()
        mat.albedo_color = col
        mat.roughness = 0.55
        mi.material_override = mat
        mi.position = Vector3(0, y, 0)
        root.add_child(mi)
        # advance cursor for next layer
        var next_h: float = base_size * float(prim["scale"]) * 0.5
        y += next_h * 1.05

    # Camera framing the whole pedestal + stack + label
    var cam := Camera3D.new()
    cam.position = Vector3(0.85, 1.05, 0.95)
    cam.look_at(Vector3(0.0, 0.55, 0.0), Vector3.UP)
    cam.fov = 38
    root.add_child(cam)
    cam.make_current()

    # Same pattern as capture_conveyor_composition.gd: poll create_timer
    # in 50ms ticks until the wait elapses. This lets the engine run a
    # full render cycle for the new objects/camera.
    var t := 0.0
    while t < _wait:
        await create_timer(0.05).timeout
        t += 0.05
    var img := root.get_texture().get_image()
    if img == null:
        push_error("no image"); quit(1); return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out.get_base_dir()))
    img.save_png(_out)
    print("composition_platform demo: ", _out)
    quit(0)
