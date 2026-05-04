extends SceneTree

## Capture the CSG-bodied four-leg walker as a still PNG. The walker
## IK initializes lazily during _process; we wait a few frames then grab
## the viewport.

const SCENE := "res://commons/hazards/octapod_crawler/csg_four_leg_walker.tscn"

var _out := "user://csg_walker_demo.png"
var _wait := 4.0

func _initialize() -> void:
    for raw in OS.get_cmdline_user_args():
        var s := String(raw).strip_edges()
        if s.begins_with("--out="): _out = s.substr(6)
        elif s.begins_with("--wait="): _wait = float(s.substr(7))
    call_deferred("_run")

func _run() -> void:
    var root := get_root()

    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.95, 0.95, 0.93)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_color = Color(0.85, 0.85, 0.88)
    e.ambient_light_energy = 0.7
    env.environment = e
    root.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(40), 0)
    sun.light_energy = 1.5
    root.add_child(sun)

    # Floor.
    var floor_mi := MeshInstance3D.new()
    var fb := BoxMesh.new(); fb.size = Vector3(20, 0.05, 20)
    floor_mi.mesh = fb
    floor_mi.position = Vector3(0, -0.025, 0)
    var fmat := StandardMaterial3D.new()
    fmat.albedo_color = Color(0.78, 0.76, 0.72)
    fmat.roughness = 0.95
    floor_mi.material_override = fmat
    root.add_child(floor_mi)

    var ps := load(SCENE) as PackedScene
    if ps == null:
        push_error("scene missing: %s" % SCENE); quit(1); return
    var rig := ps.instantiate()
    root.add_child(rig)

    # Camera angled at the walker.
    var cam := Camera3D.new()
    root.add_child(cam)
    cam.global_position = Vector3(6.0, 4.0, 6.0)
    cam.look_at(Vector3(0, 1.5, 0), Vector3.UP)
    cam.fov = 38
    cam.make_current()

    var t := 0.0
    while t < _wait:
        await create_timer(0.05).timeout
        t += 0.05

    var img := root.get_texture().get_image()
    if img == null:
        push_error("no viewport image"); quit(1); return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out.get_base_dir()))
    img.save_png(_out)
    print("csg walker capture: ", _out)
    quit(0)
