extends SceneTree

## In-context capture: load a real map, optionally inject one or more
## artifact tokens at named cells (without writing to disk), place camera
## at a world position + lookAt, snapshot.
##
## This is the player's-eye-view counterpart to render_pattern_specimen
## (which renders artifacts in vacuum). The research-loop orchestrator
## drives this for every contextual shot.
##
## Config JSON shape:
##   {
##     "map":      "Study_Room",
##     "inject": [
##       { "layer": "interactables", "at": [8, 8], "token": "radiolaria_specimen:0:0" }
##     ],
##     "spawn_scenes": [
##       { "scene": "res://algorithms/computationalbiology/radiolaria/radiolaria.tscn",
##         "position": [8, 0, 8] }
##     ],
##     "camera":   { "position": [10, 1.7, 5], "look_at": [8, 1.0, 8], "fov": 60 },
##     "wait":     3.0
##   }
##
## Two injection paths:
##   `inject` — token-based, goes through registry. Use for wrapped artifacts.
##   `spawn_scenes` — direct-scene path, instantiated at world position.
##                    Use for algorithm scenes that animate themselves.

const MAP_LOADER := "res://commons/maps/MapLoader.gd"  # if exists; we fall back to direct JSON+GridScene

var _config_path: String = ""
var _out_path: String = "user://in_map_capture.png"
var _wait := 3.0

func _initialize() -> void:
    for raw in OS.get_cmdline_user_args():
        var s := String(raw).strip_edges()
        if s.begins_with("--config="): _config_path = s.substr(9)
        elif s.begins_with("--out="):    _out_path = s.substr(6)
        elif s.begins_with("--wait="):   _wait = float(s.substr(7))
    call_deferred("_run")


func _run() -> void:
    if _config_path.is_empty():
        push_error("--config required"); quit(1); return
    var f := FileAccess.open(_config_path, FileAccess.READ)
    if f == null:
        push_error("config not found: %s" % _config_path); quit(1); return
    var json := JSON.new()
    if json.parse(f.get_as_text()) != OK:
        push_error("bad json"); quit(1); return
    var cfg = json.data
    if not (cfg is Dictionary):
        push_error("config not dict"); quit(1); return

    var map_name: String = String(cfg.get("map", "Study_Room"))
    var injects: Array = cfg.get("inject", [])

    # Load the map JSON. Apply inject patches BEFORE building the grid.
    var map_path := "res://commons/maps/%s/map_data.json" % map_name
    var mf := FileAccess.open(map_path, FileAccess.READ)
    if mf == null:
        push_error("map not found: %s" % map_path); quit(1); return
    var map_json := JSON.new()
    if map_json.parse(mf.get_as_text()) != OK:
        push_error("bad map json"); quit(1); return
    var map_data = map_json.data
    if not (map_data is Dictionary):
        push_error("map_data not dict"); quit(1); return

    for inj in injects:
        var layer_name: String = String(inj.get("layer", "interactables"))
        var at: Array = inj.get("at", [0, 0])
        var token: String = String(inj.get("token", ""))
        if layer_name.is_empty() or token.is_empty():
            continue
        var layers = map_data.get("layers", {})
        var layer = layers.get(layer_name, [])
        if at.size() < 2: continue
        var z: int = int(at[1])
        var x: int = int(at[0])
        if z >= 0 and z < layer.size():
            var row = layer[z]
            if x >= 0 and x < row.size():
                row[x] = token

    var root := get_root()

    # Soft sky environment.
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.94, 0.94, 0.92)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_color = Color(0.85, 0.85, 0.90)
    e.ambient_light_energy = 0.7
    e.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.environment = e
    root.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(40), 0)
    sun.light_energy = 1.5
    root.add_child(sun)

    # Build the grid via the project's GridScene if present, else build a
    # bare interpretation of the map_data layers ourselves.
    var grid_built := await _try_build_via_grid_scene(root, map_data)
    if not grid_built:
        _build_bare_grid(root, map_data)

    # Direct scene injection — bypass registry, instantiate any .tscn
    # at any world position. Used for algorithm scenes that animate
    # themselves (most of algorithms/*/*.tscn).
    var spawn_scenes: Array = cfg.get("spawn_scenes", [])
    for ss in spawn_scenes:
        var scene_path: String = String(ss.get("scene", ""))
        var pos: Array = ss.get("position", [0, 0, 0])
        if scene_path.is_empty(): continue
        var ps := load(scene_path) as PackedScene
        if ps == null:
            push_warning("spawn_scene load failed: %s" % scene_path); continue
        var node := ps.instantiate()
        root.add_child(node)
        if node is Node3D:
            (node as Node3D).global_position = Vector3(
                float(pos[0]), float(pos[1]), float(pos[2]))

    # Camera placement.
    var cam_cfg = cfg.get("camera", {})
    var pos: Array = cam_cfg.get("position", [8, 1.7, 8])
    var la: Array = cam_cfg.get("look_at", [8, 1.0, 5])
    var fov: float = float(cam_cfg.get("fov", 60.0))
    var cam := Camera3D.new()
    root.add_child(cam)
    cam.global_position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
    cam.look_at(Vector3(float(la[0]), float(la[1]), float(la[2])), Vector3.UP)
    cam.fov = fov
    cam.make_current()

    # Wait for grid to settle, artifacts to spawn meshes.
    var t := 0.0
    var wait_total := float(cfg.get("wait", _wait))
    while t < wait_total:
        await create_timer(0.05).timeout
        t += 0.05

    var img := root.get_texture().get_image()
    if img == null: push_error("no image"); quit(1); return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_path.get_base_dir()))
    img.save_png(_out_path)
    print("in_map: ", _out_path)
    quit(0)


## Try to build via the existing GridSystem if accessible. Returns true
## on success. If false, caller should fall back to bare-grid build.
func _try_build_via_grid_scene(root: Node, _map_data: Dictionary) -> bool:
    # Most map captures in this repo use capture_multi_angle.gd which
    # invokes the full GridScene. For now we use the bare fallback —
    # that's enough to capture artifact placement; biome / utilities
    # come along when GridScene is wired in.
    return false


## Bare grid builder — instantiates an artifact for every interactable
## token whose lookup_name is registered. Skips structure heights for
## simplicity in this vertical slice; a future pass will honor them.
func _build_bare_grid(root: Node, map_data: Dictionary) -> void:
    var dims = map_data.get("map_info", {}).get("dimensions", {})
    var width: int = int(dims.get("width", 16))
    var depth: int = int(dims.get("depth", 16))

    var layers = map_data.get("layers", {})
    var structure = layers.get("structure", [])
    var interactables = layers.get("interactables", [])

    # Floor: union of cells where structure[z][x] != "0".
    var floor_mi := MeshInstance3D.new()
    var fb := BoxMesh.new(); fb.size = Vector3(width, 0.05, depth)
    floor_mi.mesh = fb
    floor_mi.position = Vector3(width * 0.5 - 0.5, -0.025, depth * 0.5 - 0.5)
    var fmat := StandardMaterial3D.new()
    fmat.albedo_color = Color(0.85, 0.84, 0.80)
    fmat.roughness = 0.95
    floor_mi.material_override = fmat
    root.add_child(floor_mi)

    # Walk interactables — instantiate any artifact scene whose lookup
    # name we can resolve in the registry.
    var registry := _load_registry()
    for z in min(depth, interactables.size()):
        var row = interactables[z]
        for x in min(width, row.size()):
            var token: String = String(row[x]).strip_edges()
            if token.is_empty(): continue
            var lookup := token.split(":")[0].split("#")[0]
            var entry = registry.get(lookup)
            if entry == null: continue
            var scene_path: String = String(entry.get("scene", ""))
            if scene_path.is_empty(): continue
            var ps := load(scene_path) as PackedScene
            if ps == null: continue
            var node := ps.instantiate()
            node.position = Vector3(x, 0, z)
            # If artifact carries config params after the lookup_name token,
            # parse #key:value pairs and forward to apply_grid_config.
            var params := _parse_token_params(token)
            if params.size() > 0 and node.has_method("apply_grid_config"):
                node.call("apply_grid_config", params)
            root.add_child(node)


func _parse_token_params(token: String) -> Dictionary:
    # Token format: lookup_name:rotation:y_offset#key1:value1#key2:value2
    var out: Dictionary = {}
    var parts := token.split("#")
    if parts.size() <= 1: return out
    for i in range(1, parts.size()):
        var seg = String(parts[i])
        var kv = seg.split(":")
        if kv.size() < 2: continue
        var k = kv[0]
        var v_str = kv[1]
        # Try numeric
        if v_str.is_valid_float():
            out[k] = float(v_str)
        elif v_str == "true":
            out[k] = true
        elif v_str == "false":
            out[k] = false
        else:
            out[k] = v_str
    return out


func _load_registry() -> Dictionary:
    var out: Dictionary = {}
    var dir := DirAccess.open("res://commons/artifacts/registry")
    if dir == null: return out
    dir.list_dir_begin()
    var fname := dir.get_next()
    while fname != "":
        if fname.ends_with(".json") and not fname.ends_with(".bak"):
            var fp := "res://commons/artifacts/registry/" + fname
            var f := FileAccess.open(fp, FileAccess.READ)
            if f != null:
                var j := JSON.new()
                if j.parse(f.get_as_text()) == OK:
                    var data = j.data
                    if data is Dictionary and data.has("artifacts"):
                        for k in data["artifacts"].keys():
                            out[k] = data["artifacts"][k]
        fname = dir.get_next()
    return out
