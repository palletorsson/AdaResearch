extends SceneTree

## Render a single pattern-generation specimen by instantiating the
## existing algorithm scene, letting it animate for `wait` seconds, then
## snapshotting from a top-down or oblique camera with AABB-fit framing.
##
## Config JSON shape:
##   { "id": ..., "scene": "res://path/to/scene.tscn",
##     "camera": "top" | "oblique" | "front",
##     "auto_fit": true (default — compute AABB and fit camera),
##     "distance": 8.0 (used only if auto_fit=false),
##     "wait": 6.0 (optional) }

var _config_path: String = ""
var _out_path: String = "user://pattern_render.png"
var _wait := 6.0
var _size := 800

func _initialize() -> void:
    for raw in OS.get_cmdline_user_args():
        var s := String(raw).strip_edges()
        if s.begins_with("--config="): _config_path = s.substr(9)
        elif s.begins_with("--out="):    _out_path = s.substr(6)
        elif s.begins_with("--wait="):   _wait = float(s.substr(7))
        elif s.begins_with("--size="):   _size = int(s.substr(7))
    call_deferred("_run")

func _run() -> void:
    if _config_path.is_empty():
        push_error("--config required"); quit(1); return
    var f := FileAccess.open(_config_path, FileAccess.READ)
    if f == null: push_error("config not found"); quit(1); return
    var json := JSON.new()
    if json.parse(f.get_as_text()) != OK:
        push_error("bad json"); quit(1); return
    var cfg = json.data
    if not (cfg is Dictionary):
        push_error("config is not dict"); quit(1); return

    var scene_path: String = String(cfg.get("scene", ""))
    if scene_path.is_empty():
        push_error("config missing 'scene'"); quit(1); return

    var root := get_root()

    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.93, 0.93, 0.92)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_color = Color(0.85, 0.85, 0.88)
    e.ambient_light_energy = 0.7
    e.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.environment = e
    root.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(40), 0)
    sun.light_energy = 1.4
    root.add_child(sun)

    var ps := load(scene_path) as PackedScene
    if ps == null:
        push_error("scene load failed: %s" % scene_path); quit(1); return
    var rig := ps.instantiate()
    root.add_child(rig)

    if cfg.has("scene_props") and cfg["scene_props"] is Dictionary:
        for k in cfg["scene_props"].keys():
            rig.set(k, cfg["scene_props"][k])

    var existing_cam := rig.find_child("Camera*", true, false)
    if existing_cam and existing_cam is Camera3D:
        (existing_cam as Camera3D).current = false

    # Let scene spawn its meshes for one frame, then compute AABB.
    await create_timer(0.4).timeout
    var bounds: AABB = _scene_aabb(rig)
    var center: Vector3 = bounds.position + bounds.size * 0.5
    var diag: float = bounds.size.length()

    var cam_mode: String = String(cfg.get("camera", "oblique"))
    var auto_fit: bool = bool(cfg.get("auto_fit", true))
    var dist: float
    if auto_fit and diag > 0.001:
        dist = max(diag * 0.85 + 0.5, 2.0)
    else:
        dist = float(cfg.get("distance", 8.0))

    var look_at: Vector3 = center
    if cfg.has("look_at") and cfg["look_at"] is Array:
        var la = cfg["look_at"]
        look_at = Vector3(float(la[0]), float(la[1]), float(la[2]))

    var fov: float = float(cfg.get("fov", 42.0))
    var cam := Camera3D.new()
    root.add_child(cam)
    match cam_mode:
        "top":
            cam.global_position = look_at + Vector3(0.001, dist, 0.001)
        "front":
            cam.global_position = look_at + Vector3(0, 0, dist)
        _:  # oblique
            cam.global_position = look_at + Vector3(dist * 0.5, dist * 0.6, dist * 0.7)
    cam.look_at(look_at, Vector3.UP)
    cam.fov = fov
    cam.make_current()

    if cfg.has("wait"):
        _wait = float(cfg["wait"])
    var t := 0.0
    while t < _wait:
        await create_timer(0.05).timeout
        t += 0.05

    var img := root.get_texture().get_image()
    if img == null: push_error("no image"); quit(1); return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_path.get_base_dir()))
    img.save_png(_out_path)
    print("pattern: ", _out_path)
    quit(0)


## Walk visual descendants, union their world-space AABBs.
func _scene_aabb(node: Node) -> AABB:
    var out := AABB()
    var first := true
    for n in _flatten_visual(node):
        var box: AABB
        if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
            box = (n as MeshInstance3D).get_aabb()
        elif n is CSGShape3D:
            box = (n as CSGShape3D).get_aabb()
        else:
            continue
        var t: Transform3D = (n as Node3D).global_transform
        var corners := [
            box.position,
            box.position + Vector3(box.size.x, 0, 0),
            box.position + Vector3(0, box.size.y, 0),
            box.position + Vector3(0, 0, box.size.z),
            box.position + Vector3(box.size.x, box.size.y, 0),
            box.position + Vector3(box.size.x, 0, box.size.z),
            box.position + Vector3(0, box.size.y, box.size.z),
            box.position + box.size,
        ]
        for c in corners:
            var p: Vector3 = t * (c as Vector3)
            if first:
                out = AABB(p, Vector3.ZERO)
                first = false
            else:
                out = out.expand(p)
    if first or out.size.length_squared() < 0.001:
        return AABB(Vector3.ZERO, Vector3.ONE * 2.0)
    return out


func _flatten_visual(n: Node) -> Array:
    var out: Array = [n]
    for c in n.get_children():
        out.append_array(_flatten_visual(c))
    return out
