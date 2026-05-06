extends SceneTree

## Capture the upgraded conveyor belt loaded with a specific composition.
## Usage:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_conveyor_composition.gd -- \
##     --product=mondrian --out=user://conveyor_shots/mondrian.png --wait=4.0

const SCENE := "res://commons/primitives/assembly/assembly_line_puzzle.tscn"

var _product: String = "mondrian"
var _out_path: String = "user://conveyor_shots/conveyor.png"
var _wait_seconds: float = 4.0
var _img_size: int = 800

func _initialize() -> void:
    _parse_args()
    call_deferred("_run")

func _parse_args() -> void:
    for raw in OS.get_cmdline_user_args():
        var s := String(raw).strip_edges()
        if not s.begins_with("--"): continue
        var eq := s.find("=")
        if eq < 3: continue
        var k := s.substr(2, eq - 2)
        var v := s.substr(eq + 1).strip_edges()
        match k:
            "product": _product = v
            "out":     _out_path = v
            "wait":    _wait_seconds = float(v)
            "size":    _img_size = int(v)

func _run() -> void:
    var root := get_root()

    # World env — soft sky so colors read
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.10, 0.11, 0.16)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_color = Color(0.5, 0.5, 0.6)
    e.ambient_light_energy = 0.6
    env.environment = e
    root.add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(35), 0)
    sun.light_energy = 1.4
    root.add_child(sun)

    # Instantiate conveyor + apply composition
    var ps := load(SCENE) as PackedScene
    if ps == null:
        push_error("scene missing: %s" % SCENE); quit(1); return
    var rig := ps.instantiate()
    root.add_child(rig)
    if rig.has_method("apply_grid_config"):
        if _product == "sandbox":
            rig.apply_grid_config({"sandbox": true, "palette": "compositions"})
        elif _product == "rainbow":
            rig.apply_grid_config({"sandbox": true, "palette": "rainbow"})
        else:
            rig.apply_grid_config({"category": "compositions", "product": _product})

    # Camera framing the station + belts. Conveyor pieces are tiny
    # (shape_scale=0.07), input belt spans x≈[-0.8,1.0], output runs
    # to z=-1.4 — pull back, look at the station midway down.
    # Conveyor belts span x≈[-0.8,1.0] × z≈[0,-1.4] at y=0.5; pieces are
    # tiny (shape_scale=0.07). Frame from front-right to show input belt
    # left→right and the output running away.
    var cam := Camera3D.new()
    cam.position = Vector3(0.40, 0.85, 0.55)
    cam.look_at(Vector3(0.05, 0.50, -0.55), Vector3.UP)
    cam.fov = 60
    root.add_child(cam)
    cam.make_current()

    # Wait for spawns
    var t := 0.0
    while t < _wait_seconds:
        await create_timer(0.05).timeout
        t += 0.05

    # Snap viewport
    var vp := root
    var img := vp.get_texture().get_image()
    if img == null:
        push_error("could not get viewport image"); quit(1); return
    var dir := _out_path.get_base_dir()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
    img.save_png(_out_path)
    print("conveyor capture: ", _out_path, " (", img.get_width(), "x", img.get_height(), ")")
    quit(0)
