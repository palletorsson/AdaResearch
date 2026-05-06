extends SceneTree

## Bestiary capture — 4 CSG walkers in a row, mixed body forms × leg counts.

const FOUR_LEG := "res://commons/hazards/octapod_crawler/csg_four_leg_walker.tscn"
const SIX_LEG  := "res://commons/hazards/octapod_crawler/csg_six_leg_walker.tscn"

var _out := "user://csg_bestiary_demo.png"
var _wait := 5.0

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
    e.background_color = Color(0.92, 0.92, 0.90)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_color = Color(0.88, 0.88, 0.92)
    e.ambient_light_energy = 0.65
    env.environment = e
    root.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(40), 0)
    sun.light_energy = 1.6
    root.add_child(sun)

    # Floor
    var floor_mi := MeshInstance3D.new()
    var fb := BoxMesh.new(); fb.size = Vector3(60, 0.05, 60)
    floor_mi.mesh = fb
    floor_mi.position = Vector3(0, -0.025, 0)
    var fmat := StandardMaterial3D.new()
    fmat.albedo_color = Color(0.74, 0.72, 0.68)
    fmat.roughness = 0.95
    floor_mi.material_override = fmat
    root.add_child(floor_mi)

    # Specimens — { scene, x, form, palette_base, palette_accent, seed, atom_r, body_legs, joint_style, lift }
    var specimens := [
        {"scene": FOUR_LEG, "x": -9.0,
         "form": "headcrab", "base": "#d8a878", "accent": "#5a1810", "seed": 1, "atom_r": 0.40,
         "joint_style": "cylinder", "lift": 1.4},
        {"scene": FOUR_LEG, "x": -3.0,
         "form": "headcrab", "base": "#88b0c8", "accent": "#0a1860", "seed": 7, "atom_r": 0.42,
         "joint_style": "pill", "lift": 1.6},
        {"scene": SIX_LEG,  "x":  3.0,
         "form": "headcrab", "base": "#a83820", "accent": "#1a0a08", "seed": 11, "atom_r": 0.38,
         "joint_style": "cylinder", "lift": 1.8},
        {"scene": SIX_LEG,  "x":  9.0,
         "form": "headcrab", "base": "#88a058", "accent": "#1a3818", "seed": 23, "atom_r": 0.40,
         "joint_style": "pill", "lift": 2.0},
    ]

    for spec in specimens:
        var ps := load(spec["scene"]) as PackedScene
        if ps == null:
            push_error("missing scene: %s" % spec["scene"])
            continue
        var rig := ps.instantiate()
        rig.position = Vector3(float(spec["x"]), 0, 0)
        var body_node: Node3D = rig.get_node_or_null("Body")
        if body_node == null:
            push_error("no Body child in %s" % spec["scene"])
            continue
        body_node.set("creature_form", spec["form"])
        body_node.set("creature_base_color", Color(String(spec["base"])))
        body_node.set("creature_accent_color", Color(String(spec["accent"])))
        body_node.set("creature_seed", int(spec["seed"]))
        body_node.set("creature_atom_radius", float(spec["atom_r"]))
        # Lift the CSG body up so it doesn't intersect the leg shoulders.
        body_node.set("creature_body_y_offset", float(spec["lift"]))
        # Pick the joint construction style.
        body_node.set("leg_joint_style", String(spec["joint_style"]))
        # Tune leg geometry — thinner shafts, larger joint hubs for visibility.
        body_node.set("leg_shaft_radius", 0.20)
        body_node.set("leg_hub_radius", 0.36)
        body_node.set("leg_foot_radius", 0.46)
        body_node.set("leg_taper", 0.40)
        body_node.set("leg_accent_period", 3)
        root.add_child(rig)

    var cam := Camera3D.new()
    root.add_child(cam)
    cam.global_position = Vector3(0.0, 5.0, 22.0)
    cam.look_at(Vector3(0, 2.0, 0), Vector3.UP)
    cam.fov = 50
    cam.make_current()

    var t := 0.0
    while t < _wait:
        await create_timer(0.05).timeout
        t += 0.05

    var img := root.get_texture().get_image()
    if img == null:
        push_error("no image"); quit(1); return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out.get_base_dir()))
    img.save_png(_out)
    print("bestiary: ", _out)
    quit(0)
