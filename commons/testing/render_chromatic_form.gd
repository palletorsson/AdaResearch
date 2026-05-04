extends SceneTree

## Render one chromatic-form composition to a PNG. Generic over three forms:
##   fin_wall              — Cruz-Diez vertical fins, one color per fin
##   gradient_corridor     — immersive corridor; floor + 4 walls + ceiling, gradient pull
##   chromatic_panel_field — suspended translucent panels, one gradient per panel
##
## Config JSON shape:
##   {
##     "id": "fins_rgb_red_cyan",
##     "form": "fin_wall" | "gradient_corridor" | "chromatic_panel_field",
##     "colors": ["#hex", ...],           // pre-computed strip from interpolator
##     "params": { ...form-specific... }
##   }
##
## Color strip is computed in Python (mirroring gradient_interpolator's RGB
## and HSV lerp) so the renderer is dumb — it just paints what it's told.

const STAGING := "res://commons/primitive_grammar/_staging/"

var _config_path: String = ""
var _out_path: String = "user://chromatic_form_render.png"
var _wait := 2.5  # CSG forms need a few seconds to compute their meshes
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
    var root := get_root()

    # Environment — neutral interior so the form's color does the work.
    var env := WorldEnvironment.new()
    env.name = "WorldEnvironment"
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
    sun.light_energy = 1.6
    root.add_child(sun)

    if _config_path.is_empty():
        push_error("--config required"); quit(1); return
    var cfg := _load_config(_config_path)
    if cfg.is_empty():
        push_error("could not load config"); quit(1); return

    var form := str(cfg.get("form", "fin_wall"))
    var colors: Array = cfg.get("colors", [])
    var params: Dictionary = cfg.get("params", {})

    var bounds := AABB(Vector3.ZERO, Vector3.ONE)
    match form:
        "fin_wall":
            bounds = _build_fin_wall(root, colors, params)
        "gradient_corridor":
            bounds = _build_gradient_corridor(root, colors, params)
        "chromatic_panel_field":
            bounds = _build_chromatic_panel_field(root, colors, params)
        "panel_grid_3x3":
            bounds = _build_panel_grid_3x3(root, colors, params)
        "truchet_grid":
            bounds = _build_truchet_grid(root, colors, params)
        "wolfram_ca_wall":
            bounds = _build_wolfram_ca_wall(root, colors, params)
        "voronoi_field":
            bounds = _build_voronoi_field(root, colors, params)
        "turrell_skyspace":
            bounds = _build_turrell_skyspace(root, colors, params)
        "turrell_afrum_corner":
            bounds = _build_turrell_afrum_corner(root, colors, params)
        "turrell_chromatic_chamber":
            bounds = _build_turrell_chromatic_chamber(root, colors, params)
        "turrell_aten_reign":
            bounds = _build_turrell_aten_reign(root, colors, params)
        "radiolaria_specimen":
            bounds = _build_radiolaria_specimen(root, colors, params)
        "boolean_corridor":
            bounds = _build_boolean_corridor(root, colors, params)
        "boolean_procedural_space":
            bounds = _build_boolean_procedural_space(root, colors, params)
        "menger_sponge":
            bounds = _build_menger_sponge(root, colors, params)
        "gyroid_pillar":
            bounds = _build_gyroid_pillar(root, colors, params)
        "trabecular_skeleton":
            bounds = _build_trabecular_skeleton(root, colors, params)
        "schwarz_lattice":
            bounds = _build_schwarz_lattice(root, colors, params)
        "hyperbolic_vault":
            bounds = _build_hyperbolic_vault(root, colors, params)
        "sponge_skeleton":
            bounds = _build_sponge_skeleton(root, colors, params)
        "voronoi_meteorite":
            bounds = _build_voronoi_meteorite(root, colors, params)
        "boolean_cathedral":
            bounds = _build_boolean_cathedral(root, colors, params)
        _:
            push_error("unknown form: %s" % form); quit(1); return

    # Hardcoded per-form framing — AABB-based math was missing thin walls.
    var cam := Camera3D.new()
    var center: Vector3 = bounds.position + bounds.size * 0.5
    var cam_pos: Vector3
    var look_at: Vector3 = center
    match form:
        "panel_grid_3x3":
            # Hardcoded for the 3×3 grid scale (~1.1m plan, 1.6m tall).
            # Quarter-front view from above so all 9 panels and the
            # cross-orientation reads.
            cam_pos = Vector3(2.0, 1.6, 2.0)
            look_at = Vector3(0, 0.7, 0)
            cam.fov = 42
        "truchet_grid", "voronoi_field":
            # Plan-on-the-wall: gentle isometric, look down at the field.
            var s3: float = max(bounds.size.x, bounds.size.z, 1.5)
            cam_pos = Vector3(s3 * 0.05, s3 * 1.05, s3 * 0.95)
            look_at = Vector3(0, 0, 0)
            cam.fov = 42
        "wolfram_ca_wall":
            # CA wall: face it head-on, slight elevation.
            var w_w: float = max(bounds.size.x, 1.0)
            cam_pos = Vector3(w_w * 0.10, bounds.size.y * 0.55, w_w * 0.85 + 0.5)
            look_at = Vector3(0, bounds.size.y * 0.50, 0)
            cam.fov = 42
        "turrell_skyspace":
            # Standing inside a room looking up at the ceiling aperture.
            cam_pos = Vector3(0.05, 0.95, 0.05)
            look_at = Vector3(0, 3.0, 0)
            cam.fov = 78
        "turrell_afrum_corner":
            # Standing in a dim room, facing a corner with a glowing cube.
            cam_pos = Vector3(0.0, 1.05, 2.6)
            look_at = Vector3(0.0, 0.85, 0.0)
            cam.fov = 50
        "turrell_chromatic_chamber":
            # Inside the chamber, looking at the lit aperture wall.
            cam_pos = Vector3(0.0, 1.05, 2.0)
            look_at = Vector3(0, 0.95, -1.5)
            cam.fov = 55
        "turrell_aten_reign":
            # Looking up into the rotunda — concentric color rings overhead.
            cam_pos = Vector3(0.0, 1.0, 0.0)
            look_at = Vector3(0, 5.0, 0)
            cam.fov = 75
        "radiolaria_specimen":
            # Specimen on a pedestal-style framing, slight 3/4 elevation.
            # Look slightly DOWN at center so headcrab/tentacle legs that
            # drop toward floor stay in frame.
            cam_pos = Vector3(1.6, 1.4, 1.6)
            look_at = Vector3(0, -0.3, 0)
            cam.fov = 42
        "boolean_corridor":
            # Looking down the corridor's axis with slight elevation.
            cam_pos = Vector3(0.4, 1.5, 4.0)
            look_at = Vector3(0, 1.2, 0)
            cam.fov = 55
        "boolean_procedural_space":
            # CAMERA INSIDE the room — Boolean carvings are interior
            # features. Positioned in one corner looking diagonally at
            # the opposite corner so floor + ceiling + back wall + side
            # wall all show the carved geometry.
            cam_pos = Vector3(1.6, 1.4, 1.6)
            look_at = Vector3(-0.6, 1.5, -0.6)
            cam.fov = 75
        "menger_sponge", "schwarz_lattice", "trabecular_skeleton", "sponge_skeleton", "voronoi_meteorite":
            # Specimen-style 3/4 view of an organic / fractal CSG specimen.
            cam_pos = Vector3(2.0, 1.5, 2.0)
            look_at = Vector3(0, 0, 0)
            cam.fov = 38
        "boolean_cathedral":
            # Camera INSIDE the nave near the entry, looking toward the apse.
            # Must be inside the carved void (not behind the front wall).
            cam_pos = Vector3(0.0, 1.4, 2.6)
            look_at = Vector3(0, 1.8, -3.5)
            cam.fov = 75
        "gyroid_pillar":
            # Tall column — view side-on with slight elevation.
            cam_pos = Vector3(1.8, 1.4, 1.8)
            look_at = Vector3(0, 0.9, 0)
            cam.fov = 40
        "hyperbolic_vault":
            # Looking up into the vault from below.
            cam_pos = Vector3(0.4, 0.8, 0.4)
            look_at = Vector3(0, 4.0, 0)
            cam.fov = 75
        "fin_wall":
            # Frame the wall head-on with a slight rightward angle so
            # parallax/Z-stagger reads. Distance scales with wall width.
            var w: float = bounds.size.x
            cam_pos = Vector3(w * 0.18, bounds.size.y * 0.55, w * 0.55 + 1.4)
            look_at = Vector3(0, bounds.size.y * 0.45, 0)
            cam.fov = 42
        "gradient_corridor":
            cam_pos = center + Vector3(0, bounds.size.y * 0.18, bounds.size.z * 0.62)
            look_at = Vector3(center.x, bounds.size.y * 0.45, bounds.position.z + 0.2)
            cam.fov = 55
        "chromatic_panel_field":
            # Panels are arrayed in a circle of radius ~spread; pull camera
            # back so all of them fit the frame.
            var s: float = max(bounds.size.x, bounds.size.z)
            cam_pos = Vector3(s * 0.20, bounds.size.y * 0.85, s * 0.95)
            look_at = Vector3(0, bounds.size.y * 0.42, 0)
            cam.fov = 50
        _:
            cam_pos = center + Vector3(2.0, 2.0, 3.0)
            cam.fov = 45
    root.add_child(cam)
    cam.global_position = cam_pos
    cam.look_at(look_at, Vector3.UP)
    cam.make_current()

    var t := 0.0
    while t < _wait:
        await create_timer(0.05).timeout
        t += 0.05

    var img := root.get_texture().get_image()
    if img == null:
        push_error("no viewport image"); quit(1); return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_path.get_base_dir()))
    img.save_png(_out_path)
    print("chromatic_form: ", _out_path)
    quit(0)


# ── Form: fin_wall ───────────────────────────────────────────────
# A row of vertical fins (thin tall slabs) like a Cruz-Diez chromatic
# environment. One color per fin, optional translucency.

func _build_fin_wall(root: Node, colors: Array, params: Dictionary) -> AABB:
    var n := colors.size()
    if n == 0: return AABB(Vector3.ZERO, Vector3.ONE)

    var fin_w: float = float(params.get("fin_width", 0.10))
    var fin_h: float = float(params.get("fin_height", 1.5))
    var fin_t: float = float(params.get("fin_thickness", 0.025))
    var gap:   float = float(params.get("gap", 0.055))
    var transparent: bool = bool(params.get("transparent", true))
    var alpha: float = float(params.get("alpha", 0.78))
    var stagger_z: float = float(params.get("stagger_z", 0.10))

    var total_w: float = n * fin_w + (n - 1) * gap
    var x0: float = -total_w * 0.5 + fin_w * 0.5

    # Backing wall — neutral white so the fins read as overlay.
    var wall := MeshInstance3D.new()
    var wb := BoxMesh.new()
    wb.size = Vector3(total_w + 0.4, fin_h + 0.4, 0.04)
    wall.mesh = wb
    wall.position = Vector3(0, fin_h * 0.5, -stagger_z - 0.05)
    var wmat := StandardMaterial3D.new()
    wmat.albedo_color = Color(0.97, 0.97, 0.96)
    wmat.roughness = 0.7
    wall.material_override = wmat
    root.add_child(wall)

    for i in n:
        var mi := MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = Vector3(fin_w, fin_h, fin_t)
        mi.mesh = bm
        # Stagger fins slightly forward in Z for the parallax band Cruz-Diez gets.
        var z := -stagger_z * 0.5 + (float(i) / float(max(n - 1, 1))) * stagger_z
        mi.position = Vector3(x0 + i * (fin_w + gap), fin_h * 0.5, z)
        var mat := StandardMaterial3D.new()
        var c := Color(colors[i])
        if transparent:
            c.a = alpha
            mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
            mat.albedo_color = c
            mat.metallic = 0.05
            mat.roughness = 0.18
            mat.refraction_enabled = false
        else:
            mat.albedo_color = c
        mat.emission_enabled = true
        mat.emission = c
        mat.emission_energy_multiplier = 0.20
        mi.material_override = mat
        root.add_child(mi)

    return AABB(
        Vector3(-total_w * 0.5 - 0.2, 0, -stagger_z - 0.10),
        Vector3(total_w + 0.4, fin_h + 0.4, stagger_z + 0.20),
    )


# ── Form: gradient_corridor ──────────────────────────────────────
# A walk-through corridor; each "ring" along Z is colored from the gradient
# strip. Gives the yellow-tunnel / gradient-interior look (refs 2 & 4).

func _build_gradient_corridor(root: Node, colors: Array, params: Dictionary) -> AABB:
    var n := colors.size()
    if n == 0: return AABB(Vector3.ZERO, Vector3.ONE)

    var ring_depth: float = float(params.get("ring_depth", 0.4))
    var ring_w:     float = float(params.get("ring_width", 1.6))
    var ring_h:     float = float(params.get("ring_height", 1.8))
    var wall_t:     float = float(params.get("wall_thickness", 0.05))

    var total_z: float = n * ring_depth

    for i in n:
        var c := Color(colors[i])
        var z0 := -total_z * 0.5 + i * ring_depth + ring_depth * 0.5

        # Floor strip
        var floor_mi := MeshInstance3D.new()
        var fb := BoxMesh.new()
        fb.size = Vector3(ring_w, wall_t, ring_depth)
        floor_mi.mesh = fb
        floor_mi.position = Vector3(0, 0, z0)
        floor_mi.material_override = _matte_color(c)
        root.add_child(floor_mi)

        # Ceiling strip
        var ceil_mi := MeshInstance3D.new()
        ceil_mi.mesh = fb
        ceil_mi.position = Vector3(0, ring_h, z0)
        ceil_mi.material_override = _matte_color(c.lightened(0.10))
        root.add_child(ceil_mi)

        # Left wall
        var lw := MeshInstance3D.new()
        var lb := BoxMesh.new()
        lb.size = Vector3(wall_t, ring_h, ring_depth)
        lw.mesh = lb
        lw.position = Vector3(-ring_w * 0.5, ring_h * 0.5, z0)
        lw.material_override = _matte_color(c)
        root.add_child(lw)

        # Right wall
        var rw := MeshInstance3D.new()
        rw.mesh = lb
        rw.position = Vector3(ring_w * 0.5, ring_h * 0.5, z0)
        rw.material_override = _matte_color(c.darkened(0.05))
        root.add_child(rw)

    return AABB(
        Vector3(-ring_w * 0.5 - 0.1, -0.1, -total_z * 0.5 - 0.1),
        Vector3(ring_w + 0.2, ring_h + 0.2, total_z + 0.2),
    )


# ── Form: chromatic_panel_field ──────────────────────────────────
# A field of suspended translucent panels (image ref 3). Each panel
# carries one slice of the gradient.

func _build_chromatic_panel_field(root: Node, colors: Array, params: Dictionary) -> AABB:
    var n := colors.size()
    if n == 0: return AABB(Vector3.ZERO, Vector3.ONE)

    var panel_w: float = float(params.get("panel_width", 0.6))
    var panel_h: float = float(params.get("panel_height", 1.6))
    var panel_t: float = float(params.get("panel_thickness", 0.02))
    var spread:  float = float(params.get("spread", 2.4))
    var alpha:   float = float(params.get("alpha", 0.55))
    var rng := RandomNumberGenerator.new()
    rng.seed = int(params.get("seed", 42))

    # Floor disk (wood-toned, as in the warehouse-gallery reference).
    var floor_mi := MeshInstance3D.new()
    var fcm := CylinderMesh.new()
    fcm.top_radius = spread * 0.9
    fcm.bottom_radius = spread * 0.9
    fcm.height = 0.04
    floor_mi.mesh = fcm
    floor_mi.position = Vector3(0, -0.02, 0)
    var fmat := StandardMaterial3D.new()
    fmat.albedo_color = Color(0.55, 0.40, 0.28)
    fmat.roughness = 0.85
    floor_mi.material_override = fmat
    root.add_child(floor_mi)

    for i in n:
        var c := Color(colors[i])
        c.a = alpha
        var mi := MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = Vector3(panel_w, panel_h, panel_t)
        mi.mesh = bm
        var theta := (float(i) / float(n)) * TAU
        var r := spread * (0.45 + 0.35 * rng.randf())
        mi.position = Vector3(cos(theta) * r, panel_h * 0.5 + 0.05, sin(theta) * r)
        mi.rotation.y = -theta + PI * 0.5 + rng.randf_range(-0.4, 0.4)

        var mat := StandardMaterial3D.new()
        mat.albedo_color = c
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.emission_enabled = true
        mat.emission = c
        mat.emission_energy_multiplier = 0.45
        mat.metallic = 0.15
        mat.roughness = 0.20
        mi.material_override = mat
        root.add_child(mi)

    return AABB(
        Vector3(-spread * 1.1, -0.1, -spread * 1.1),
        Vector3(spread * 2.2, panel_h + 0.4, spread * 2.2),
    )


## Form: panel_grid_3x3
## A 3×3 plan grid of vertical translucent panels, each rotated 0° or 90°
## about the Y axis. Colors mix where panels cross — the same logic as
## color_mixing.gd's overlap planes, but as a walkable architecture.
##
## params:
##   spacing       — cell size in plan (default 0.55)
##   panel_w       — panel width along its long axis (default ~spacing)
##   panel_h       — panel height (default 1.6)
##   panel_t       — panel thickness (default 0.025)
##   alpha         — translucency (default 0.62)
##   rotation_mode — "checker" (alternating per cell), "rows" (all parallel
##                   per row), "spiral" (per-row 90° step), "all_x" / "all_z"
func _build_panel_grid_3x3(root: Node, colors: Array, params: Dictionary) -> AABB:
    var spacing: float = float(params.get("spacing", 0.55))
    var panel_w: float = float(params.get("panel_w", spacing * 0.95))
    var panel_h: float = float(params.get("panel_h", 1.6))
    var panel_t: float = float(params.get("panel_t", 0.025))
    var alpha: float   = float(params.get("alpha", 0.62))
    var mode: String   = String(params.get("rotation_mode", "checker"))

    # Floor disk for staging — pale concrete plate.
    var floor_mi := MeshInstance3D.new()
    var fcm := CylinderMesh.new()
    fcm.top_radius = spacing * 2.6
    fcm.bottom_radius = spacing * 2.6
    fcm.height = 0.04
    floor_mi.mesh = fcm
    floor_mi.position = Vector3(0, -0.02, 0)
    var fmat := StandardMaterial3D.new()
    fmat.albedo_color = Color(0.92, 0.91, 0.88)
    fmat.roughness = 0.85
    floor_mi.material_override = fmat
    root.add_child(floor_mi)

    # Place 9 panels on the 3×3 plan, palette index = row*3 + col.
    var n_colors := colors.size()
    for row in range(3):
        for col in range(3):
            var idx := row * 3 + col
            var c := Color(colors[idx % max(n_colors, 1)])
            c.a = alpha

            var rot_y := 0.0
            match mode:
                "checker":
                    rot_y = (PI * 0.5) if ((row + col) % 2 == 0) else 0.0
                "rows":
                    rot_y = (PI * 0.5) if (row % 2 == 0) else 0.0
                "spiral":
                    rot_y = row * (PI * 0.5)  # 0°, 90°, 180° per row
                "all_x":
                    rot_y = 0.0
                "all_z":
                    rot_y = PI * 0.5
                _:
                    rot_y = (PI * 0.5) if ((row + col) % 2 == 0) else 0.0

            var mi := MeshInstance3D.new()
            var bm := BoxMesh.new()
            bm.size = Vector3(panel_w, panel_h, panel_t)
            mi.mesh = bm
            var x := (col - 1) * spacing
            var z := (row - 1) * spacing
            mi.position = Vector3(x, panel_h * 0.5 + 0.02, z)
            mi.rotation = Vector3(0, rot_y, 0)

            var mat := StandardMaterial3D.new()
            mat.albedo_color = c
            mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
            mat.emission_enabled = true
            mat.emission = c
            mat.emission_energy_multiplier = 0.30
            mat.metallic = 0.10
            mat.roughness = 0.18
            mi.material_override = mat
            root.add_child(mi)

    var span: float = spacing * 2.4
    return AABB(
        Vector3(-span, 0, -span),
        Vector3(span * 2, panel_h + 0.4, span * 2),
    )


## Form: truchet_grid
## Smith-Truchet tiles. Each unit cell is a square split along one of the
## two diagonals — opposite triangles share a color. Random rotation per
## cell gives flowing curves through a square grid.
##
## params:
##   grid_n   — N×N tiles (default 16)
##   tile     — tile size in world units (default 0.18)
##   seed     — RNG seed (default 1)
##   variant  — "diagonal" (2-color) | "lshape" (asym L)
##
## colors — only the first 2 are used; rest ignored.
func _build_truchet_grid(root: Node, colors: Array, params: Dictionary) -> AABB:
    var n: int = int(params.get("grid_n", 16))
    var tile: float = float(params.get("tile", 0.18))
    var seed_v: int = int(params.get("seed", 1))
    var variant: String = String(params.get("variant", "diagonal"))
    if colors.size() < 2:
        colors = ["#1a1a1a", "#f4f2ec"]
    var col_a := Color(colors[0])
    var col_b := Color(colors[1])

    var rng := RandomNumberGenerator.new()
    rng.seed = seed_v

    var total: float = n * tile
    var x0: float = -total * 0.5
    var z0: float = -total * 0.5

    # Subtle backing plate so the tiles read against one ground.
    var plate := MeshInstance3D.new()
    var pb := BoxMesh.new()
    pb.size = Vector3(total + 0.04, 0.01, total + 0.04)
    plate.mesh = pb
    plate.position = Vector3(0, -0.005, 0)
    var pmat := StandardMaterial3D.new()
    pmat.albedo_color = col_b
    pmat.roughness = 0.85
    plate.material_override = pmat
    root.add_child(plate)

    for i in range(n):
        for j in range(n):
            var cx := x0 + (j + 0.5) * tile
            var cz := z0 + (i + 0.5) * tile
            var rot: int = rng.randi() % 4
            _spawn_truchet_tile(root, Vector3(cx, 0.005, cz), tile, rot, col_a, variant)

    return AABB(Vector3(x0, 0, z0), Vector3(total, 0.05, total))


func _spawn_truchet_tile(root: Node, center: Vector3, size: float, rot: int, col: Color, variant: String) -> void:
    # Build the colored half of a Smith-Truchet tile: one of two opposing
    # triangular halves split by a diagonal. Rotation by 90° flips which
    # diagonal is active, so curves connect across cell boundaries.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var h := size * 0.5
    var y := 0.001

    # Tile corners (XZ plane) — counterclockwise from bottom-left:
    var bl := Vector3(-h, y, -h)
    var br := Vector3( h, y, -h)
    var tr := Vector3( h, y,  h)
    var tl := Vector3(-h, y,  h)

    if variant == "lshape":
        # Two adjacent quadrants (L-shape: bottom + right). Rotation
        # choreographs four orientations of the L.
        st.add_vertex(bl); st.add_vertex(br); st.add_vertex(Vector3(0, y, 0))
        st.add_vertex(br); st.add_vertex(tr); st.add_vertex(Vector3(0, y, 0))
    else:
        # Single diagonal half: triangle on the / diagonal.
        # Two unrotated states share the / diagonal; the other 90°/270°
        # rotations swap to \ — enabling Smith-Truchet curve flow.
        st.add_vertex(bl); st.add_vertex(br); st.add_vertex(tr)

    st.generate_normals()
    var mesh := st.commit()

    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.position = center
    mi.rotation = Vector3(0, rot * PI * 0.5, 0)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = col
    mat.roughness = 0.55
    mat.emission_enabled = true
    mat.emission = col
    mat.emission_energy_multiplier = 0.10
    mi.material_override = mat
    root.add_child(mi)


## Form: wolfram_ca_wall
## Elementary 1D cellular automaton. Pick rule R (e.g. 30, 90, 110) and
## run for N steps starting from a single live cell in the middle.
## Output is a 2D grid: rows = time, cols = cells. Color = state.
##
## params:
##   rule    — int, 0..255 (default 110)
##   width   — number of cells (default 41, odd → centered seed)
##   steps   — number of generations (default 30)
##   tile    — cell size in world units (default 0.06)
##   wrap    — whether boundary cells wrap (default true)
func _build_wolfram_ca_wall(root: Node, colors: Array, params: Dictionary) -> AABB:
    var rule: int = int(params.get("rule", 110))
    var width: int = int(params.get("width", 41))
    var steps: int = int(params.get("steps", 30))
    var tile: float = float(params.get("tile", 0.06))
    var wrap: bool = bool(params.get("wrap", true))
    if colors.size() < 2:
        colors = ["#101010", "#f0c020"]

    var col0 := Color(colors[0])
    var col1 := Color(colors[1 % colors.size()])

    # Initial row: single 1 in the middle.
    var row: Array = []
    for i in range(width): row.append(0)
    row[width / 2] = 1

    var total_w: float = width * tile
    var total_h: float = steps * tile
    var x0: float = -total_w * 0.5
    var y0: float = total_h  # build downward in Y so step 0 is at top

    # Backing wall.
    var wall := MeshInstance3D.new()
    var wb := BoxMesh.new()
    wb.size = Vector3(total_w + 0.06, total_h + 0.06, 0.02)
    wall.mesh = wb
    wall.position = Vector3(0, total_h * 0.5, -0.012)
    var wmat := StandardMaterial3D.new()
    wmat.albedo_color = col0.darkened(0.4)
    wmat.roughness = 0.85
    wall.material_override = wmat
    root.add_child(wall)

    for s in range(steps):
        for c in range(width):
            var state: int = row[c]
            if state == 0: continue   # only paint live cells (background = wall)
            var mi := MeshInstance3D.new()
            var bm := BoxMesh.new()
            bm.size = Vector3(tile * 0.96, tile * 0.96, 0.02)
            mi.mesh = bm
            mi.position = Vector3(x0 + (c + 0.5) * tile, y0 - (s + 0.5) * tile, 0.0)
            var mat := StandardMaterial3D.new()
            # Color along the gradient strip → row index modulates hue
            var idx: int = int(round(float(s) / float(max(steps - 1, 1)) * float(colors.size() - 1)))
            var c_here := Color(colors[clampi(idx, 0, colors.size() - 1)])
            mat.albedo_color = c_here
            mat.emission_enabled = true
            mat.emission = c_here
            mat.emission_energy_multiplier = 0.20
            mi.material_override = mat
            root.add_child(mi)

        # Evolve: next row from current using rule R.
        var nxt: Array = []
        for c in range(width):
            var l: int = row[(c - 1 + width) % width] if wrap else (row[c - 1] if c > 0 else 0)
            var m: int = row[c]
            var r: int = row[(c + 1) % width] if wrap else (row[c + 1] if c < width - 1 else 0)
            var pat: int = (l << 2) | (m << 1) | r
            nxt.append((rule >> pat) & 1)
        row = nxt

    return AABB(Vector3(x0, 0, -0.05), Vector3(total_w, total_h, 0.10))


## Form: voronoi_field
## A field of K seeds; the unit grid is partitioned by nearest-seed.
## Each seed gets a color from the palette → cellular Mondrian.
##
## params:
##   grid_n  — N×N rasterization (default 32)
##   tile    — cell size (default 0.10)
##   seeds   — number of seeds (default 8)
##   seed_rng — RNG seed (default 7)
func _build_voronoi_field(root: Node, colors: Array, params: Dictionary) -> AABB:
    var n: int = int(params.get("grid_n", 32))
    var tile: float = float(params.get("tile", 0.10))
    var k: int = int(params.get("seeds", 8))
    var seed_rng: int = int(params.get("seed_rng", 7))
    if colors.size() < 2:
        colors = ["#cc1f1f", "#1f4ecc"]

    var rng := RandomNumberGenerator.new()
    rng.seed = seed_rng

    var total: float = n * tile
    var x0: float = -total * 0.5
    var z0: float = -total * 0.5

    # Generate K seed positions in [0, n) and pick a color index for each.
    var seeds: Array = []
    for s in range(k):
        seeds.append({
            "p": Vector2(rng.randf() * n, rng.randf() * n),
            "ci": s % colors.size(),
        })

    for i in range(n):
        for j in range(n):
            var p := Vector2(j + 0.5, i + 0.5)
            var best := 1e30
            var best_idx := 0
            for s in seeds:
                var d: float = p.distance_squared_to(s["p"])
                if d < best:
                    best = d
                    best_idx = s["ci"]
            var col := Color(colors[best_idx])
            var mi := MeshInstance3D.new()
            var bm := BoxMesh.new()
            # Slight per-cell height variation makes the field read as
            # texture; uniform height looks too flat in a 3D capture.
            var h: float = 0.005 + (best_idx % 3) * 0.004
            bm.size = Vector3(tile * 0.97, h, tile * 0.97)
            mi.mesh = bm
            mi.position = Vector3(x0 + (j + 0.5) * tile, h * 0.5, z0 + (i + 0.5) * tile)
            var mat := StandardMaterial3D.new()
            mat.albedo_color = col
            mat.roughness = 0.65
            mat.emission_enabled = true
            mat.emission = col
            mat.emission_energy_multiplier = 0.10
            mi.material_override = mat
            root.add_child(mi)

    return AABB(Vector3(x0, 0, z0), Vector3(total, 0.05, total))


## ── Turrell forms ────────────────────────────────────────────────
## All four below use saturated emission + interior cameras so the
## color BECOMES the space, not a surface IN the space.

## emissive material with strong inner glow — Turrell-style.
## Two-sided so the camera reads inside-of-room walls and underside-of-rings.
func _emissive(c: Color, energy: float = 2.4) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.emission_enabled = true
    m.emission = c
    m.emission_energy_multiplier = energy
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m


## Form: turrell_skyspace
## Closed room with a rectangular cutout in the ceiling that reveals a
## "sky" plane in a contrasting color. Built from 4 ceiling strips
## framing the aperture (Boolean subtract via composition, not CSG).
##
## colors: [room_color, sky_color, ...]  — first two used.
## params: room_size, room_height, aperture_w, aperture_d
func _build_turrell_skyspace(root: Node, colors: Array, params: Dictionary) -> AABB:
    if colors.size() < 2:
        colors = ["#e88828", "#3088c8"]
    var room_col := Color(colors[0])
    var sky_col := Color(colors[1])

    var room_w: float = float(params.get("room_size", 4.0))
    var room_h: float = float(params.get("room_height", 3.2))
    var ap_w: float = float(params.get("aperture_w", 1.4))
    var ap_d: float = float(params.get("aperture_d", 1.4))
    var hr := room_w * 0.5
    var ha_w := ap_w * 0.5
    var ha_d := ap_d * 0.5

    # Inner glow environment override — soft ambient color matches walls.
    var env_node := root.find_child("WorldEnvironment", true, false)
    if env_node and env_node is WorldEnvironment:
        var env := (env_node as WorldEnvironment).environment
        env.background_color = sky_col.darkened(0.5)
        env.ambient_light_color = room_col
        env.ambient_light_energy = 0.85

    # Floor (warm wood, like Turrell's Meeting installation)
    var floor_mi := MeshInstance3D.new()
    var fb := BoxMesh.new()
    fb.size = Vector3(room_w, 0.05, room_w)
    floor_mi.mesh = fb
    floor_mi.position = Vector3(0, -0.025, 0)
    var fmat := StandardMaterial3D.new()
    fmat.albedo_color = Color(0.32, 0.22, 0.14)
    fmat.roughness = 0.85
    floor_mi.material_override = fmat
    root.add_child(floor_mi)

    # Four walls — interior-facing, lit by emissive room_col.
    var wall_specs := [
        Vector3( 0, room_h * 0.5, -hr),  # back
        Vector3( 0, room_h * 0.5,  hr),  # front
        Vector3(-hr, room_h * 0.5, 0),   # left
        Vector3( hr, room_h * 0.5, 0),   # right
    ]
    var wall_sizes := [
        Vector3(room_w, room_h, 0.05),
        Vector3(room_w, room_h, 0.05),
        Vector3(0.05, room_h, room_w),
        Vector3(0.05, room_h, room_w),
    ]
    for i in 4:
        var w := MeshInstance3D.new()
        var b := BoxMesh.new(); b.size = wall_sizes[i]
        w.mesh = b
        w.position = wall_specs[i]
        w.material_override = _emissive(room_col, 1.6)
        root.add_child(w)

    # Ceiling: 4 strips framing the aperture (Boolean cutout via composition).
    # Strip layout (looking down at ceiling):
    #   [    NORTH    ]
    #   [W]  hole  [E]
    #   [    SOUTH    ]
    var north_d: float = (hr - ha_d)
    var south_d: float = (hr - ha_d)
    var ceil_y: float = room_h
    # North strip
    var n := MeshInstance3D.new()
    var nb := BoxMesh.new(); nb.size = Vector3(room_w, 0.05, north_d)
    n.mesh = nb
    n.position = Vector3(0, ceil_y, ha_d + north_d * 0.5)
    n.material_override = _emissive(room_col, 1.6)
    root.add_child(n)
    # South strip
    var s := MeshInstance3D.new()
    var sb := BoxMesh.new(); sb.size = Vector3(room_w, 0.05, south_d)
    s.mesh = sb
    s.position = Vector3(0, ceil_y, -ha_d - south_d * 0.5)
    s.material_override = _emissive(room_col, 1.6)
    root.add_child(s)
    # West strip (between north & south, west of aperture)
    var w_d: float = ap_d
    var west_w: float = (hr - ha_w)
    var ws := MeshInstance3D.new()
    var wsb := BoxMesh.new(); wsb.size = Vector3(west_w, 0.05, w_d)
    ws.mesh = wsb
    ws.position = Vector3(-ha_w - west_w * 0.5, ceil_y, 0)
    ws.material_override = _emissive(room_col, 1.6)
    root.add_child(ws)
    # East strip
    var es := MeshInstance3D.new()
    var esb := BoxMesh.new(); esb.size = Vector3(west_w, 0.05, w_d)
    es.mesh = esb
    es.position = Vector3(ha_w + west_w * 0.5, ceil_y, 0)
    es.material_override = _emissive(room_col, 1.6)
    root.add_child(es)

    # Sky plane just above the aperture — a glowing rectangle of sky_col.
    var sky := MeshInstance3D.new()
    var sky_mesh := BoxMesh.new()
    sky_mesh.size = Vector3(ap_w, 0.02, ap_d)
    sky.mesh = sky_mesh
    sky.position = Vector3(0, ceil_y + 0.06, 0)
    sky.material_override = _emissive(sky_col, 3.5)
    root.add_child(sky)

    # Subtle fill light from the aperture into the room.
    var fill := OmniLight3D.new()
    fill.position = Vector3(0, ceil_y - 0.4, 0)
    fill.light_color = sky_col
    fill.light_energy = 1.6
    fill.omni_range = room_w * 0.9
    root.add_child(fill)

    return AABB(Vector3(-hr, 0, -hr), Vector3(room_w, room_h, room_w))


## Form: turrell_afrum_corner
## A dim room with two walls meeting at a corner; a saturated colored
## cube is "projected" into the corner so it reads as a free-floating
## solid of pure light. (We render an actual emissive cube; the optical
## illusion happens at the camera's eye-line.)
func _build_turrell_afrum_corner(root: Node, colors: Array, params: Dictionary) -> AABB:
    if colors.size() < 2:
        colors = ["#0a0816", "#28a8ff"]
    var dark_col := Color(colors[0])
    var afrum_col := Color(colors[1])

    var room_w: float = float(params.get("room_size", 5.0))
    var room_h: float = float(params.get("room_height", 3.0))
    var hr := room_w * 0.5

    # Dark interior walls
    for w_specs in [
        [Vector3(0, room_h*0.5, -hr), Vector3(room_w, room_h, 0.05)],   # back
        [Vector3(-hr, room_h*0.5, 0), Vector3(0.05, room_h, room_w)],   # left
        [Vector3(hr,  room_h*0.5, 0), Vector3(0.05, room_h, room_w)],   # right
        [Vector3(0,   room_h, 0),     Vector3(room_w, 0.05, room_w)],   # ceiling
    ]:
        var w := MeshInstance3D.new()
        var b := BoxMesh.new(); b.size = w_specs[1]
        w.mesh = b
        w.position = w_specs[0]
        w.material_override = _emissive(dark_col, 0.6)
        root.add_child(w)

    # Floor — slightly less black so we read the floor plane
    var floor_mi := MeshInstance3D.new()
    var fb := BoxMesh.new(); fb.size = Vector3(room_w, 0.05, room_w)
    floor_mi.mesh = fb
    floor_mi.position = Vector3(0, -0.025, 0)
    floor_mi.material_override = _emissive(dark_col.lightened(0.04), 0.4)
    root.add_child(floor_mi)

    # The Afrum cube: a glowing solid in the back-left corner. Sized so
    # its visible faces align toward the camera at (0,1.0,~2.5).
    var cube := MeshInstance3D.new()
    var cb := BoxMesh.new()
    cb.size = Vector3(1.1, 1.1, 1.1)
    cube.mesh = cb
    cube.position = Vector3(-0.55, 0.85, -0.55)
    cube.material_override = _emissive(afrum_col, 4.5)
    root.add_child(cube)

    # Spill light from the cube tinting the corner walls.
    var spill := OmniLight3D.new()
    spill.position = Vector3(-0.4, 1.0, -0.4)
    spill.light_color = afrum_col
    spill.light_energy = 3.0
    spill.omni_range = 4.5
    root.add_child(spill)

    # Override env to deep dark so the glow reads.
    var env_node := root.find_child("WorldEnvironment", true, false)
    if env_node and env_node is WorldEnvironment:
        var env := (env_node as WorldEnvironment).environment
        env.background_color = dark_col
        env.ambient_light_color = afrum_col
        env.ambient_light_energy = 0.25

    return AABB(Vector3(-hr, 0, -hr), Vector3(room_w, room_h, room_w))


## Form: turrell_chromatic_chamber
## A small chamber with a single back wall replaced by a saturated
## colored aperture (a "wedgework"-style colored field). Stepped
## seating — the Houston Live Oak Friends Meeting palette. (Image ref 3.)
func _build_turrell_chromatic_chamber(root: Node, colors: Array, params: Dictionary) -> AABB:
    if colors.size() < 2:
        colors = ["#c83838", "#f0c020"]
    var room_col := Color(colors[0])
    var aperture_col := Color(colors[1])

    var room_w: float = float(params.get("room_size", 4.0))
    var room_h: float = float(params.get("room_height", 2.6))
    var hr := room_w * 0.5

    # Side walls + ceiling (uniform room_col, soft glow)
    for w_specs in [
        [Vector3(-hr, room_h*0.5, 0), Vector3(0.05, room_h, room_w), 1.4],
        [Vector3(hr,  room_h*0.5, 0), Vector3(0.05, room_h, room_w), 1.4],
        [Vector3(0,   room_h,     0), Vector3(room_w, 0.05, room_w), 1.4],
        [Vector3(0,   room_h*0.5, hr), Vector3(room_w, room_h, 0.05), 1.4],   # front (behind cam)
    ]:
        var w := MeshInstance3D.new()
        var b := BoxMesh.new(); b.size = w_specs[1]
        w.mesh = b
        w.position = w_specs[0]
        w.material_override = _emissive(room_col, w_specs[2])
        root.add_child(w)

    # Floor — warm dark
    var floor_mi := MeshInstance3D.new()
    var fb := BoxMesh.new(); fb.size = Vector3(room_w, 0.05, room_w)
    floor_mi.mesh = fb
    floor_mi.position = Vector3(0, -0.025, 0)
    var fmat := StandardMaterial3D.new()
    fmat.albedo_color = Color(0.10, 0.07, 0.04)
    fmat.roughness = 0.85
    floor_mi.material_override = fmat
    root.add_child(floor_mi)

    # Back wall: framed except for an aperture rectangle in the center.
    var ap_w: float = room_w * 0.35
    var ap_h: float = room_h * 0.55
    var ap_y: float = room_h * 0.55
    var back_z: float = -hr
    # Top strip
    var top_h: float = room_h - ap_y - ap_h * 0.5
    var top := MeshInstance3D.new()
    var tb := BoxMesh.new(); tb.size = Vector3(room_w, top_h, 0.05)
    top.mesh = tb
    top.position = Vector3(0, ap_y + ap_h * 0.5 + top_h * 0.5, back_z)
    top.material_override = _emissive(room_col, 1.4)
    root.add_child(top)
    # Bottom strip
    var bot_h: float = ap_y - ap_h * 0.5
    var bot := MeshInstance3D.new()
    var bb := BoxMesh.new(); bb.size = Vector3(room_w, bot_h, 0.05)
    bot.mesh = bb
    bot.position = Vector3(0, bot_h * 0.5, back_z)
    bot.material_override = _emissive(room_col, 1.4)
    root.add_child(bot)
    # Left strip
    var side_w: float = (room_w - ap_w) * 0.5
    var lf := MeshInstance3D.new()
    var lb := BoxMesh.new(); lb.size = Vector3(side_w, ap_h, 0.05)
    lf.mesh = lb
    lf.position = Vector3(-ap_w * 0.5 - side_w * 0.5, ap_y, back_z)
    lf.material_override = _emissive(room_col, 1.4)
    root.add_child(lf)
    # Right strip
    var rt := MeshInstance3D.new()
    rt.mesh = lb
    rt.position = Vector3(ap_w * 0.5 + side_w * 0.5, ap_y, back_z)
    rt.material_override = _emissive(room_col, 1.4)
    root.add_child(rt)
    # Aperture itself — glowing rectangle behind the frame
    var ap := MeshInstance3D.new()
    var apm := BoxMesh.new(); apm.size = Vector3(ap_w, ap_h, 0.02)
    ap.mesh = apm
    ap.position = Vector3(0, ap_y, back_z - 0.04)
    ap.material_override = _emissive(aperture_col, 4.0)
    root.add_child(ap)

    # Stepped seating in front of aperture — three risers.
    for i in range(3):
        var step := MeshInstance3D.new()
        var sm := BoxMesh.new()
        sm.size = Vector3(room_w * 0.7, 0.18, 0.45)
        step.mesh = sm
        var z_off: float = -hr * 0.45 + i * 0.45
        step.position = Vector3(0, 0.09 + i * 0.18, z_off)
        var smat := StandardMaterial3D.new()
        smat.albedo_color = Color(0.06, 0.04, 0.02)
        smat.roughness = 0.85
        step.material_override = smat
        root.add_child(step)

    # Spill light from aperture
    var spill := OmniLight3D.new()
    spill.position = Vector3(0, ap_y, back_z + 0.4)
    spill.light_color = aperture_col
    spill.light_energy = 2.4
    spill.omni_range = room_w * 1.1
    root.add_child(spill)

    var env_node := root.find_child("WorldEnvironment", true, false)
    if env_node and env_node is WorldEnvironment:
        var env := (env_node as WorldEnvironment).environment
        env.background_color = room_col.darkened(0.4)
        env.ambient_light_color = room_col
        env.ambient_light_energy = 0.55

    return AABB(Vector3(-hr, 0, -hr), Vector3(room_w, room_h, room_w))


## Form: turrell_aten_reign
## Concentric oval rings of light stacked overhead — the Guggenheim
## rotunda piece (image ref 5). Looking up into a chromatic vortex.
func _build_turrell_aten_reign(root: Node, colors: Array, params: Dictionary) -> AABB:
    if colors.size() < 4:
        colors = ["#ff66d8", "#b34de8", "#6666f0", "#3399ff"]
    var n_rings: int = int(params.get("rings", 6))
    # Geometry tuned so that from (0, 1.0, 0) at FOV 75° we see concentric
    # nested ovals. Lowest ring at y_start=2.5m, climbs by ring_h_step.
    # Innermost is smallest; rings shrink as they climb.
    var base_r: float = float(params.get("base_radius", 0.18))
    var step_r: float = float(params.get("step_radius", 0.16))
    var ring_h: float = float(params.get("ring_height", 0.45))
    var ring_w: float = float(params.get("ring_width", 0.10))
    var y_start: float = float(params.get("y_start", 2.5))

    # Build a low pedestal (player POV) and a circular floor.
    var floor_mi := MeshInstance3D.new()
    var fcm := CylinderMesh.new()
    fcm.top_radius = base_r + n_rings * step_r + 0.5
    fcm.bottom_radius = fcm.top_radius
    fcm.height = 0.04
    floor_mi.mesh = fcm
    floor_mi.position = Vector3(0, -0.02, 0)
    var fmat := StandardMaterial3D.new()
    fmat.albedo_color = Color(0.05, 0.05, 0.07)
    fmat.roughness = 0.85
    floor_mi.material_override = fmat
    root.add_child(floor_mi)

    # Concentric rings as flat torus annuli, each at a different height,
    # decreasing radius as they go up. From below they read as nested
    # ovals due to perspective — exactly Aten Reign at the Guggenheim.
    # Each ring is rendered as an annulus (a thin torus laid flat).
    for i in range(n_rings):
        var col := Color(colors[i % colors.size()])
        # Outermost ring lowest (largest), innermost highest (smallest).
        var ring_idx_inv: int = n_rings - 1 - i
        var outer_r: float = base_r + ring_idx_inv * step_r + ring_w
        var inner_r_local: float = base_r + ring_idx_inv * step_r
        var y: float = y_start + i * ring_h

        var ring := MeshInstance3D.new()
        var tm := TorusMesh.new()
        tm.inner_radius = inner_r_local
        tm.outer_radius = outer_r
        tm.ring_segments = 64
        tm.rings = 12
        ring.mesh = tm
        ring.position = Vector3(0, y, 0)
        ring.material_override = _emissive(col, 3.2)
        root.add_child(ring)

    # Topmost oculus — bright disc capping the funnel.
    var oculus := MeshInstance3D.new()
    var om := CylinderMesh.new()
    om.top_radius = base_r * 0.55
    om.bottom_radius = base_r * 0.55
    om.height = 0.05
    oculus.mesh = om
    oculus.position = Vector3(0, y_start + n_rings * ring_h + 0.1, 0)
    oculus.material_override = _emissive(Color(colors[(n_rings - 1) % colors.size()]).lightened(0.35), 4.5)
    root.add_child(oculus)

    var env_node := root.find_child("WorldEnvironment", true, false)
    if env_node and env_node is WorldEnvironment:
        var env := (env_node as WorldEnvironment).environment
        env.background_color = Color(0.02, 0.02, 0.04)
        env.ambient_light_color = Color(colors[0])
        env.ambient_light_energy = 0.45

    var max_r: float = base_r + n_rings * step_r + ring_w
    var top_y: float = y_start + n_rings * ring_h + 0.3
    return AABB(Vector3(-max_r, 0, -max_r), Vector3(max_r * 2, top_y, max_r * 2))


## ── CSG / Boolean forms ──────────────────────────────────────────
## All three below use Godot's runtime CSG nodes. Operations:
##   OPERATION_UNION         — child volume added to parent
##   OPERATION_SUBTRACTION   — child volume carved out of parent
##   OPERATION_INTERSECTION  — only the overlap kept
## Trees compose: a CSGSphere parent with a CSGBox child(SUBTRACT) gives
## a sphere with a square chunk removed. The same recipe Ernst Haeckel's
## radiolaria use (mineral skeleton minus the spaces evolution carved
## away), and the same recipe Turrell skyspaces use (room minus aperture).

func _csg_mat(c: Color, metallic: float = 0.1, roughness: float = 0.7, emissive_energy: float = 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.metallic = metallic
    m.roughness = roughness
    if emissive_energy > 0.0:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = emissive_energy
    return m


## Generate the 12 vertices of a unit icosahedron, scaled by `radius`.
## Used to place spikes / ornaments at perfect 5-fold symmetric positions.
func _icosahedron_vertices(radius: float) -> Array:
    var phi: float = (1.0 + sqrt(5.0)) / 2.0
    var v: Array = []
    for vec in [
        Vector3(0,  phi,  1), Vector3(0,  phi, -1),
        Vector3(0, -phi,  1), Vector3(0, -phi, -1),
        Vector3( 1, 0,  phi), Vector3(-1, 0,  phi),
        Vector3( 1, 0, -phi), Vector3(-1, 0, -phi),
        Vector3( phi,  1, 0), Vector3( phi, -1, 0),
        Vector3(-phi,  1, 0), Vector3(-phi, -1, 0),
    ]:
        v.append((vec as Vector3).normalized() * radius)
    return v


## Append a CSG sphere "atom" to a chain root, UNION-merged so the path
## reads as one continuous molecular cluster.
func _add_atom(chain_root: CSGSphere3D, pos: Vector3, radius: float, base_mat: StandardMaterial3D, this_mat: StandardMaterial3D) -> void:
    var atom := CSGSphere3D.new()
    atom.radius = radius
    atom.position = pos
    atom.operation = CSGShape3D.OPERATION_UNION
    atom.material = this_mat if this_mat else base_mat
    chain_root.add_child(atom)


## Add a spike (CSG cylinder) on `parent` pointing in `direction`.
func _csg_spike(parent: Node, direction: Vector3, height: float, base_radius: float, mat: StandardMaterial3D) -> void:
    var spike := CSGCylinder3D.new()
    spike.radius = base_radius
    spike.height = height
    spike.position = direction * (parent.radius if "radius" in parent else 0.0) if parent is CSGSphere3D else direction * 0.4
    var up := Vector3.UP
    if direction.is_equal_approx(up) or direction.is_equal_approx(-up):
        spike.rotation = Vector3(PI if direction.y < 0 else 0, 0, 0)
    else:
        var axis := up.cross(direction).normalized()
        var ang := acos(up.dot(direction))
        spike.transform.basis = Basis(axis, ang)
    spike.operation = CSGShape3D.OPERATION_UNION
    spike.material = mat
    parent.add_child(spike)


## Form: radiolaria_specimen
## A single Haeckel-style biological specimen, built via CSG. Six types
## carried over from algorithms/computationalbiology/radiolaria with a
## `palette`-driven material override.
##
## colors[0] — base, colors[1] — accent (spikes/ornaments)
## params:
##   type — "basic" | "spiky" | "polyhedral" | "lattice" | "ringed" | "pollen"
##   detail, complexity, n_spikes, max_spike_length, seed
func _build_radiolaria_specimen(root: Node, colors: Array, params: Dictionary) -> AABB:
    if colors.size() < 2:
        colors = ["#e0d8c0", "#a83820"]
    var base_mat := _csg_mat(Color(colors[0]), 0.15, 0.6)
    var accent_mat := _csg_mat(Color(colors[1]), 0.25, 0.5)
    var t: String = String(params.get("type", "basic"))
    var seed_v: int = int(params.get("seed", 1))
    var max_spike: float = float(params.get("max_spike_length", 0.9))
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_v

    match t:
        "basic":
            var core := CSGSphere3D.new()
            core.radius = 0.5
            core.material = base_mat
            root.add_child(core)
            var n_bumps: int = 14 + (rng.randi() % 8)
            for i in n_bumps:
                var bump := CSGSphere3D.new()
                bump.radius = rng.randf_range(0.06, 0.18)
                var phi := rng.randf() * TAU
                var theta := rng.randf() * PI
                var r := 0.5 - bump.radius * 0.5
                bump.position = Vector3(
                    r * sin(theta) * cos(phi),
                    r * sin(theta) * sin(phi),
                    r * cos(theta),
                )
                bump.operation = CSGShape3D.OPERATION_UNION
                bump.material = accent_mat if rng.randf() < 0.3 else base_mat
                core.add_child(bump)
        "spiky":
            var core := CSGSphere3D.new()
            core.radius = 0.4
            core.material = base_mat
            root.add_child(core)
            var verts := _icosahedron_vertices(0.4)
            for v in verts:
                _csg_spike(core, (v as Vector3).normalized(),
                    rng.randf_range(0.25, max_spike),
                    rng.randf_range(0.04, 0.07),
                    accent_mat)
        "polyhedral":
            var core := CSGSphere3D.new()
            core.radius = 0.5
            core.material = base_mat
            root.add_child(core)
            # Carve faces by box subtractions placed at icosahedron vertices.
            for v in _icosahedron_vertices(0.62):
                var cutter := CSGBox3D.new()
                cutter.size = Vector3(0.35, 0.35, 0.35)
                cutter.position = v
                cutter.look_at_from_position(cutter.position, Vector3.ZERO, Vector3.UP)
                cutter.operation = CSGShape3D.OPERATION_SUBTRACTION
                core.add_child(cutter)
            # 70% chance: also add ornament spheres at vertices
            if rng.randf() < 0.7:
                for v in _icosahedron_vertices(0.55):
                    var orn := CSGSphere3D.new()
                    orn.radius = rng.randf_range(0.06, 0.10)
                    orn.position = v
                    orn.operation = CSGShape3D.OPERATION_UNION
                    orn.material = accent_mat
                    core.add_child(orn)
        "lattice":
            # Three perpendicular sets of stacked tori — Haeckel "lattice sphere".
            var num_rings: int = 5 + (rng.randi() % 4)
            for axis_idx in 3:
                for i in num_rings:
                    var ring := CSGTorus3D.new()
                    var ring_radius := 0.5 * sin(PI * (i + 1) / float(num_rings + 1))
                    var ring_offset := 0.5 * cos(PI * (i + 1) / float(num_rings + 1))
                    ring.inner_radius = ring_radius - 0.025
                    ring.outer_radius = ring_radius
                    if axis_idx == 0:
                        ring.position = Vector3.UP * ring_offset
                        ring.rotation.x = PI / 2.0
                    elif axis_idx == 1:
                        ring.position = Vector3.RIGHT * ring_offset
                        ring.rotation.z = PI / 2.0
                    else:
                        ring.position = Vector3.FORWARD * ring_offset
                    ring.material = base_mat
                    root.add_child(ring)
            # Surface nodes (small spheres at sphere positions)
            for i in 16:
                var phi := rng.randf() * TAU
                var theta := rng.randf() * PI
                var node := CSGSphere3D.new()
                node.radius = rng.randf_range(0.025, 0.05)
                node.position = Vector3(
                    0.48 * sin(theta) * cos(phi),
                    0.48 * sin(theta) * sin(phi),
                    0.48 * cos(theta),
                )
                node.material = accent_mat if rng.randf() < 0.3 else base_mat
                root.add_child(node)
        "ringed":
            var core := CSGSphere3D.new()
            core.radius = 0.32
            core.material = base_mat
            root.add_child(core)
            var n_rings: int = 1 + (rng.randi() % 3)
            for i in n_rings:
                var ring := CSGTorus3D.new()
                var rr: float = 0.42 + i * 0.16
                var thick: float = rng.randf_range(0.025, 0.055)
                ring.inner_radius = rr - thick
                ring.outer_radius = rr
                ring.material = accent_mat
                ring.rotation = Vector3(rng.randf() * PI, rng.randf() * PI, rng.randf() * PI)
                root.add_child(ring)
        "pollen":
            var core := CSGSphere3D.new()
            core.radius = 0.42
            core.material = base_mat
            root.add_child(core)
            # Bumps
            var n_bumps: int = 28 + (rng.randi() % 18)
            for i in n_bumps:
                var bump := CSGSphere3D.new()
                bump.radius = rng.randf_range(0.05, 0.10)
                var phi := rng.randf() * TAU
                var theta := rng.randf() * PI
                var r := 0.42 - bump.radius * 0.4
                bump.position = Vector3(
                    r * sin(theta) * cos(phi),
                    r * sin(theta) * sin(phi),
                    r * cos(theta),
                )
                bump.operation = CSGShape3D.OPERATION_UNION
                bump.material = accent_mat if rng.randf() < 0.4 else base_mat
                core.add_child(bump)
            # Germ pores (subtractions on the equator)
            var n_pores: int = 1 + (rng.randi() % 3)
            for i in n_pores:
                var ang: float = i * TAU / float(n_pores)
                var pore := CSGSphere3D.new()
                pore.radius = 0.15
                pore.position = Vector3(0.42 * cos(ang), 0.42 * sin(ang), 0)
                pore.operation = CSGShape3D.OPERATION_SUBTRACTION
                core.add_child(pore)
                var rim := CSGTorus3D.new()
                rim.inner_radius = 0.13
                rim.outer_radius = 0.17
                rim.position = pore.position
                rim.rotation.x = PI / 2.0
                rim.rotation.z = ang
                rim.operation = CSGShape3D.OPERATION_UNION
                rim.material = accent_mat
                core.add_child(rim)
        "diatom":
            # Diatom: flat disc body + radial rim spines (like a sand dollar).
            var disc := CSGCylinder3D.new()
            disc.radius = 0.5
            disc.height = 0.12
            disc.material = base_mat
            root.add_child(disc)
            # Radial spines on the rim
            var n_spines: int = 16 + (rng.randi() % 12)
            for i in n_spines:
                var ang: float = i * TAU / float(n_spines)
                var spine := CSGCylinder3D.new()
                spine.radius = 0.018
                spine.height = rng.randf_range(0.18, 0.30)
                spine.position = Vector3(
                    cos(ang) * (0.5 + spine.height * 0.5),
                    0,
                    sin(ang) * (0.5 + spine.height * 0.5),
                )
                spine.transform.basis = Basis(Vector3.FORWARD, PI * 0.5).rotated(Vector3.UP, -ang)
                spine.operation = CSGShape3D.OPERATION_UNION
                spine.material = accent_mat
                disc.add_child(spine)
            # Concentric ring on the top face
            var top_ring := CSGTorus3D.new()
            top_ring.inner_radius = 0.30
            top_ring.outer_radius = 0.34
            top_ring.position = Vector3(0, 0.07, 0)
            top_ring.material = accent_mat
            top_ring.operation = CSGShape3D.OPERATION_UNION
            disc.add_child(top_ring)
            # Central pore (subtraction)
            var center_pore := CSGCylinder3D.new()
            center_pore.radius = 0.08
            center_pore.height = 0.20
            center_pore.position = Vector3(0, 0, 0)
            center_pore.operation = CSGShape3D.OPERATION_SUBTRACTION
            disc.add_child(center_pore)
        "globular_cluster":
            # Molecular chain — atoms walk along a path with mild angular
            # drift, each sphere close-packed against its predecessor
            # (~70% radius overlap). Branches occasionally fork off the
            # main chain like substituents on an organic backbone. Last
            # 1-2 spheres get the accent material to "cap" like methyl
            # groups at chain ends.
            var topology: String = String(params.get("topology", "growth"))
            var n_atoms: int = int(params.get("atoms", 14))
            var atom_r: float = float(params.get("atom_radius", 0.18))
            var pack: float = float(params.get("pack", 0.72))   # overlap factor
            var drift: float = float(params.get("drift", 0.55)) # path drift in radians per step
            var branch_p: float = float(params.get("branch_probability", 0.18))
            # Distance between accent atoms (every Nth atom is accent).
            # Increase to make each colored band stand out more.
            var accent_period: int = int(params.get("accent_period", 5))
            var cluster_root: CSGSphere3D = null
            var bonds: Array = []  # list of {pos, dir, depth}

            # ── Headcrab topology: bulge body + N curved legs + beak ──
            # Each leg starts from the equator angled slightly upward, then
            # bends sharply downward at a "knee" partway along, ending at
            # floor level — the headcrab/spider/octopus posture.
            if topology == "headcrab":
                var bulge_factor_h: float = float(params.get("bulge_factor", 3.5))
                var n_legs: int = int(params.get("legs", 4))
                var leg_atoms: int = int(params.get("leg_atoms", 9))
                var knee_at: float = float(params.get("knee_at", 0.45))   # 0..1 fraction along leg
                var initial_lift: float = float(params.get("initial_lift", 0.5))   # how far up legs start
                var post_knee_drop: float = float(params.get("post_knee_drop", 1.6)) # downward bias after knee
                var beak: bool = bool(params.get("beak", true))
                var bulge_r: float = atom_r * bulge_factor_h

                cluster_root = CSGSphere3D.new()
                cluster_root.radius = bulge_r
                cluster_root.position = Vector3.ZERO
                cluster_root.material = base_mat
                root.add_child(cluster_root)

                # Optional: flatten the body silhouette by carving a
                # spherical bowl out of the BOTTOM of the bulge.
                var bottom_carve := CSGSphere3D.new()
                bottom_carve.radius = bulge_r * 1.05
                bottom_carve.position = Vector3(0, -bulge_r * 1.10, 0)
                bottom_carve.operation = CSGShape3D.OPERATION_SUBTRACTION
                cluster_root.add_child(bottom_carve)

                # Beak — small accent sphere underneath, with a tiny spike.
                if beak:
                    var beak_sphere := CSGSphere3D.new()
                    beak_sphere.radius = atom_r * 0.45
                    beak_sphere.position = Vector3(0, -bulge_r * 0.55, 0)
                    beak_sphere.operation = CSGShape3D.OPERATION_UNION
                    beak_sphere.material = accent_mat
                    cluster_root.add_child(beak_sphere)
                    # tiny tooth-spike below the beak
                    var tooth := CSGSphere3D.new()
                    tooth.radius = atom_r * 0.25
                    tooth.position = Vector3(0, -bulge_r * 0.78, 0)
                    tooth.operation = CSGShape3D.OPERATION_UNION
                    tooth.material = accent_mat
                    cluster_root.add_child(tooth)

                # Legs — equispaced around the equator of the body.
                for leg_idx in n_legs:
                    var phi_l: float = leg_idx * TAU / float(n_legs)
                    # Start direction: outward radially + slight upward lift,
                    # so legs come out of the upper hemisphere.
                    var dir_l := Vector3(cos(phi_l), initial_lift, sin(phi_l)).normalized()
                    var pos_l: Vector3 = dir_l * (bulge_r * 0.9 + atom_r * pack)
                    var cur_dir_l: Vector3 = dir_l

                    for j in leg_atoms:
                        var t_leg: float = float(j) / float(max(leg_atoms - 1, 1))
                        # Taper: thicker near body, thinner toward tip.
                        var taper_l: float = 1.0 - t_leg * 0.55
                        var r_l: float = atom_r * taper_l

                        # Knee bend: at knee_at fraction, drop the direction
                        # sharply downward. Before knee, drift outward
                        # gently with a tiny upward bias for a "shoulder".
                        if t_leg < knee_at:
                            # pre-knee: slight upward arc
                            cur_dir_l.y = lerp(cur_dir_l.y, 0.10, 0.20)
                        elif abs(t_leg - knee_at) < 1.0 / float(leg_atoms):
                            # at knee: rotate sharply downward
                            cur_dir_l = Vector3(cur_dir_l.x, -post_knee_drop, cur_dir_l.z).normalized()
                        else:
                            # post-knee: keep dropping toward floor
                            cur_dir_l.y -= 0.18
                        cur_dir_l = cur_dir_l.normalized()

                        # Color: tip atom + accent_period bands.
                        var is_tip_l: bool = (j == leg_atoms - 1)
                        var is_band: bool = ((j + 1) % accent_period == 0)
                        var atom_mat: StandardMaterial3D = accent_mat if (is_tip_l or is_band) else base_mat
                        _add_atom(cluster_root, pos_l, r_l, base_mat, atom_mat)
                        pos_l += cur_dir_l * (2.0 * atom_r * pack * taper_l)
                # Done — return AABB.
                var span_h: float = bulge_r + atom_r * leg_atoms * 1.4
                return AABB(Vector3(-span_h, -span_h, -span_h), Vector3(span_h * 2, span_h * 2, span_h * 2))

            # ── Tentacles topology: large center bulge + N radiating chains ──
            if topology == "tentacles":
                var bulge_factor: float = float(params.get("bulge_factor", 3.5))
                var n_tentacles: int = int(params.get("tentacles", 4))
                var tentacle_atoms: int = int(params.get("tentacle_atoms", 10))
                var tentacle_drift: float = float(params.get("tentacle_drift", 0.25))
                var bulge_r: float = atom_r * bulge_factor

                cluster_root = CSGSphere3D.new()
                cluster_root.radius = bulge_r
                cluster_root.position = Vector3.ZERO
                cluster_root.material = base_mat
                root.add_child(cluster_root)

                # Equispaced directions for tentacles using golden-ratio
                # spiral on the sphere (Fibonacci) so distribution looks
                # organic for any N.
                var golden: float = (1.0 + sqrt(5.0)) / 2.0
                for t_idx in n_tentacles:
                    var theta_t: float = acos(1.0 - 2.0 * (float(t_idx) + 0.5) / float(n_tentacles))
                    var phi_t: float = TAU * float(t_idx) / golden
                    var dir_t := Vector3(
                        sin(theta_t) * cos(phi_t),
                        sin(theta_t) * sin(phi_t),
                        cos(theta_t),
                    ).normalized()

                    # Step outward from the bulge surface, atom by atom.
                    var pos: Vector3 = dir_t * (bulge_r + atom_r * pack)
                    var cur_dir: Vector3 = dir_t
                    for j in tentacle_atoms:
                        # Tentacle taper: atoms get smaller toward tip.
                        var taper: float = 1.0 - float(j) / float(tentacle_atoms) * 0.45
                        var r_j: float = atom_r * taper
                        # Accent every accent_period along each tentacle, plus the tip.
                        var is_tip: bool = (j == tentacle_atoms - 1)
                        var is_accent_t: bool = is_tip or ((j + 1) % accent_period == 0)
                        _add_atom(cluster_root, pos, r_j, base_mat,
                            accent_mat if is_accent_t else base_mat)
                        # Drift the direction slightly so tentacles curl.
                        var axis_t := Vector3(rng.randf() * 2 - 1, rng.randf() * 2 - 1, rng.randf() * 2 - 1).normalized()
                        cur_dir = cur_dir.rotated(axis_t, rng.randf_range(-tentacle_drift, tentacle_drift)).normalized()
                        pos += cur_dir * (2.0 * atom_r * pack * taper)
                # Skip the rest of the molecular chain logic — tentacles is complete.
                return AABB(Vector3.ONE * (-bulge_r * 4.0), Vector3.ONE * (bulge_r * 8.0))

            # First atom at origin.
            cluster_root = CSGSphere3D.new()
            cluster_root.radius = atom_r
            cluster_root.position = Vector3.ZERO
            cluster_root.material = base_mat
            root.add_child(cluster_root)
            var initial_dir := Vector3(1.0, 0.3, 0.2).normalized()
            bonds.append({"pos": Vector3.ZERO, "dir": initial_dir, "depth": 0})

            # Path-walk: at each step, advance the head of the most recent
            # bond by ~(2 * atom_r * pack) along its direction, perturbing
            # the direction slightly. Occasionally fork.
            for i in range(1, n_atoms):
                var head: Dictionary = bonds[bonds.size() - 1]
                var prev_pos: Vector3 = head["pos"]
                var prev_dir: Vector3 = head["dir"]
                # Drift direction by up to ±drift radians around a random axis.
                var axis := Vector3(
                    rng.randf() * 2.0 - 1.0,
                    rng.randf() * 2.0 - 1.0,
                    rng.randf() * 2.0 - 1.0,
                ).normalized()
                var ang: float = rng.randf_range(-drift, drift)
                var new_dir: Vector3 = prev_dir.rotated(axis, ang).normalized()
                # Topology overrides:
                if topology == "helix":
                    # Force a smooth helical advance: rotate around Y by
                    # 0.55 radians per step, lift slightly per step.
                    var t_h: float = float(i) / float(n_atoms - 1)
                    var helix_ang: float = i * 0.55
                    var hx: float = cos(helix_ang) * (atom_r * 3.5)
                    var hz: float = sin(helix_ang) * (atom_r * 3.5)
                    var hy: float = -atom_r * 4.0 + t_h * atom_r * 8.0
                    var new_pos: Vector3 = Vector3(hx, hy, hz)
                    _add_atom(cluster_root, new_pos, atom_r, base_mat,
                        accent_mat if (i % accent_period == 0) else base_mat)
                    bonds.append({"pos": new_pos, "dir": (new_pos - prev_pos).normalized(), "depth": 0})
                    continue
                elif topology == "ring":
                    # Place atoms equispaced around a circle. Ring radius
                    # is set so neighbors close-pack at the configured
                    # `pack` overlap factor: chord = 2*r*pack means
                    # ring_r = r * pack / sin(PI / n_atoms).
                    var ring_ang: float = i * TAU / float(n_atoms)
                    var ring_r: float = atom_r * pack / max(sin(PI / float(n_atoms)), 0.05)
                    var new_pos: Vector3 = Vector3(cos(ring_ang) * ring_r, 0, sin(ring_ang) * ring_r)
                    _add_atom(cluster_root, new_pos, atom_r, base_mat,
                        accent_mat if (i % 2 == 0) else base_mat)
                    bonds.append({"pos": new_pos, "dir": Vector3.ZERO, "depth": 0})
                    continue
                # Default growth: walk forward, sometimes branch.
                var new_pos: Vector3 = prev_pos + new_dir * (2.0 * atom_r * pack)
                # Atom radius shrinks slightly with depth → reads as energetic chain.
                var r_here: float = atom_r * (0.92 + rng.randf() * 0.18)
                # Color: every Nth atom is accent, plus the last two.
                var is_accent: bool = (i % accent_period == 0) or (i >= n_atoms - 2)
                _add_atom(cluster_root, new_pos, r_here, base_mat,
                    accent_mat if is_accent else base_mat)
                bonds.append({"pos": new_pos, "dir": new_dir, "depth": int(head["depth"])})
                # Branch off this atom?
                if rng.randf() < branch_p and bonds.size() > 2:
                    var branch_axis := Vector3(rng.randf() * 2 - 1, rng.randf() * 2 - 1, rng.randf() * 2 - 1).normalized()
                    var branch_dir: Vector3 = new_dir.rotated(branch_axis, rng.randf_range(0.6, 1.5)).normalized()
                    bonds.append({"pos": new_pos, "dir": branch_dir, "depth": int(head["depth"]) + 1})
        "spiral_horn":
            # Foraminifera-style spiral horn: tapering tube curling around an axis.
            var n_segments: int = 24
            var horn_root: CSGSphere3D = null
            for i in n_segments:
                var u: float = float(i) / float(n_segments - 1)
                var ang: float = u * 4.0 * PI  # 2 full turns
                var radius_arc: float = 0.42 * (1.0 - u * 0.65)
                var bead := CSGSphere3D.new()
                bead.radius = 0.13 * (1.0 - u * 0.78)
                bead.position = Vector3(
                    cos(ang) * radius_arc,
                    -0.18 + u * 0.55,
                    sin(ang) * radius_arc,
                )
                bead.operation = CSGShape3D.OPERATION_UNION
                bead.material = base_mat if (i % 4 != 0) else accent_mat
                if i == 0:
                    horn_root = bead
                    root.add_child(bead)
                else:
                    horn_root.add_child(bead)
        "axopod":
            # Long axial spikes radiating from a small core (Acantharea).
            var core := CSGSphere3D.new()
            core.radius = 0.18
            core.material = base_mat
            root.add_child(core)
            # Use icosahedron vertices for symmetric long spikes.
            for v in _icosahedron_vertices(0.18):
                var spike := CSGCylinder3D.new()
                spike.radius = 0.012
                spike.height = rng.randf_range(0.7, 1.1)
                var direction: Vector3 = (v as Vector3).normalized()
                spike.position = direction * (0.18 + spike.height * 0.5)
                var up := Vector3.UP
                if direction.is_equal_approx(up) or direction.is_equal_approx(-up):
                    spike.rotation = Vector3(PI if direction.y < 0 else 0, 0, 0)
                else:
                    var axis := up.cross(direction).normalized()
                    var ang := acos(up.dot(direction))
                    spike.transform.basis = Basis(axis, ang)
                spike.operation = CSGShape3D.OPERATION_UNION
                spike.material = accent_mat
                core.add_child(spike)
            # Tip beads at end of each spike.
            for v in _icosahedron_vertices(0.18):
                var tip := CSGSphere3D.new()
                tip.radius = 0.025
                var direction: Vector3 = (v as Vector3).normalized()
                tip.position = direction * 0.95
                tip.operation = CSGShape3D.OPERATION_UNION
                tip.material = accent_mat
                core.add_child(tip)
        "comb_jelly":
            # Vertical comb rows: 8 columns of small bumps running pole-to-pole.
            var core := CSGSphere3D.new()
            core.radius = 0.42
            core.material = base_mat
            root.add_child(core)
            var n_combs: int = 8
            var n_rows: int = 12
            for c_idx in n_combs:
                var phi: float = c_idx * TAU / float(n_combs)
                for r_idx in n_rows:
                    var theta: float = (r_idx + 0.5) * PI / float(n_rows)
                    var bump := CSGSphere3D.new()
                    bump.radius = 0.06 * sin(theta)  # smaller near poles
                    var rho: float = 0.40
                    bump.position = Vector3(
                        rho * sin(theta) * cos(phi),
                        rho * cos(theta),
                        rho * sin(theta) * sin(phi),
                    )
                    bump.operation = CSGShape3D.OPERATION_UNION
                    bump.material = accent_mat if (r_idx % 3 == 0) else base_mat
                    core.add_child(bump)
        _:
            push_warning("radiolaria type unknown: %s" % t)

    return AABB(Vector3(-0.9, -0.6, -0.9), Vector3(1.8, 1.5, 1.8))


## Form: boolean_corridor
## A long box corridor with apertures subtracted: arched windows, slot
## skylights, vault hollows, or pillared niches. Walks down a single
## axis; multiple aperture sets compose to give a Boolean architecture.
##
## colors[0] — corridor walls, [1] — sky/aperture color, [2..] — accents
## params:
##   length, width, height
##   aperture: "arches" | "slots" | "vault" | "skylights" | "pillared"
##   n_apertures
func _build_boolean_corridor(root: Node, colors: Array, params: Dictionary) -> AABB:
    if colors.size() < 2:
        colors = ["#e8d8b8", "#3088c8"]
    var wall_col := Color(colors[0])
    var sky_col := Color(colors[1])
    var floor_col := Color(colors[2]) if colors.size() > 2 else wall_col.darkened(0.30)

    var corr_l: float = float(params.get("length", 8.0))
    var corr_w: float = float(params.get("width", 2.4))
    var corr_h: float = float(params.get("height", 2.6))
    var aperture: String = String(params.get("aperture", "arches"))
    var n_ap: int = int(params.get("n_apertures", 4))

    var wall_mat := _csg_mat(wall_col, 0.05, 0.85)
    var sky_mat := _csg_mat(sky_col, 0.0, 0.4, 1.6)
    var floor_mat := _csg_mat(floor_col, 0.05, 0.9)

    # Single CSG combiner — corridor block, then carve everything out.
    var corr := CSGCombiner3D.new()
    corr.use_collision = false
    root.add_child(corr)

    # The corridor solid: an outer box minus an inner box (the void).
    var outer := CSGBox3D.new()
    outer.size = Vector3(corr_w, corr_h, corr_l)
    outer.position = Vector3(0, corr_h * 0.5, 0)
    outer.operation = CSGShape3D.OPERATION_UNION
    outer.material = wall_mat
    corr.add_child(outer)

    var inner := CSGBox3D.new()
    inner.size = Vector3(corr_w - 0.30, corr_h - 0.20, corr_l - 0.20)
    inner.position = Vector3(0, corr_h * 0.5, 0)
    inner.operation = CSGShape3D.OPERATION_SUBTRACTION
    corr.add_child(inner)

    # Floor — laid into the carved void
    var floor_mi := CSGBox3D.new()
    floor_mi.size = Vector3(corr_w - 0.32, 0.04, corr_l - 0.20)
    floor_mi.position = Vector3(0, 0.02, 0)
    floor_mi.operation = CSGShape3D.OPERATION_UNION
    floor_mi.material = floor_mat
    corr.add_child(floor_mi)

    # Aperture pattern: subtract a ring of shapes from each side wall.
    var ap_step: float = corr_l / float(n_ap + 1)
    for i in n_ap:
        var z := -corr_l * 0.5 + (i + 1) * ap_step
        match aperture:
            "arches":
                # Arch = sphere subtracted high on each side wall.
                for side in [-1.0, 1.0]:
                    var arch := CSGSphere3D.new()
                    arch.radius = corr_h * 0.42
                    arch.position = Vector3(side * corr_w * 0.5, corr_h * 0.55, z)
                    arch.operation = CSGShape3D.OPERATION_SUBTRACTION
                    corr.add_child(arch)
            "slots":
                # Vertical rectangular slot windows.
                for side in [-1.0, 1.0]:
                    var slot := CSGBox3D.new()
                    slot.size = Vector3(0.30, corr_h * 0.65, 0.50)
                    slot.position = Vector3(side * corr_w * 0.5, corr_h * 0.50, z)
                    slot.operation = CSGShape3D.OPERATION_SUBTRACTION
                    corr.add_child(slot)
            "vault":
                # Hemispherical vaults bulging through the ceiling.
                var vault := CSGSphere3D.new()
                vault.radius = corr_w * 0.45
                vault.position = Vector3(0, corr_h - 0.10, z)
                vault.operation = CSGShape3D.OPERATION_SUBTRACTION
                corr.add_child(vault)
            "skylights":
                var sky := CSGBox3D.new()
                sky.size = Vector3(corr_w * 0.5, 0.40, ap_step * 0.5)
                sky.position = Vector3(0, corr_h - 0.05, z)
                sky.operation = CSGShape3D.OPERATION_SUBTRACTION
                corr.add_child(sky)
            "pillared":
                # Carve niches into the side walls — body of a pillar remains.
                for side in [-1.0, 1.0]:
                    var niche := CSGBox3D.new()
                    niche.size = Vector3(0.26, corr_h * 0.6, ap_step * 0.55)
                    niche.position = Vector3(side * corr_w * 0.5, corr_h * 0.45, z)
                    niche.operation = CSGShape3D.OPERATION_SUBTRACTION
                    corr.add_child(niche)

    # Sky-color planes outside the apertures so the cuts read as windows.
    var sky_plane := CSGBox3D.new()
    sky_plane.size = Vector3(corr_w + 6.0, corr_h + 4.0, 0.04)
    sky_plane.position = Vector3(0, corr_h * 0.5, -corr_l * 0.5 - 0.5)
    sky_plane.material = sky_mat
    sky_plane.operation = CSGShape3D.OPERATION_UNION
    root.add_child(sky_plane)

    var sky_plane2 := CSGBox3D.new()
    sky_plane2.size = Vector3(corr_w + 6.0, corr_h + 4.0, 0.04)
    sky_plane2.position = Vector3(0, corr_h * 0.5, corr_l * 0.5 + 0.5)
    sky_plane2.material = sky_mat
    sky_plane2.operation = CSGShape3D.OPERATION_UNION
    root.add_child(sky_plane2)

    # Side sky planes for arch/slot views.
    for side in [-1.0, 1.0]:
        var sp := CSGBox3D.new()
        sp.size = Vector3(0.04, corr_h + 4.0, corr_l + 4.0)
        sp.position = Vector3(side * (corr_w * 0.5 + 0.6), corr_h * 0.5, 0)
        sp.material = sky_mat
        sp.operation = CSGShape3D.OPERATION_UNION
        root.add_child(sp)

    # Soft fill light coming through the apertures.
    var fill := DirectionalLight3D.new()
    fill.rotation = Vector3(deg_to_rad(-30), deg_to_rad(45), 0)
    fill.light_color = sky_col
    fill.light_energy = 1.4
    root.add_child(fill)

    return AABB(Vector3(-corr_w * 0.5 - 0.4, 0, -corr_l * 0.5 - 0.4),
                Vector3(corr_w + 0.8, corr_h + 0.4, corr_l + 0.8))


## Form: boolean_procedural_space
## Architectural CSG room with a signature carved feature: domed light
## well, grotto (multiple sphere subtractions), apse (half-sphere niche),
## inverted cube (room with carved alcoves), atrium (central oculus).
##
## colors[0] — walls, [1] — accent / sky, [2] — floor (optional)
## params:
##   space_type: "atrium" | "grotto" | "light_well" | "apse" | "inverse_cube"
##   size
func _build_boolean_procedural_space(root: Node, colors: Array, params: Dictionary) -> AABB:
    if colors.size() < 2:
        colors = ["#f0e8d8", "#3a2810"]
    var wall_col := Color(colors[0])
    var accent_col := Color(colors[1])
    var floor_col := Color(colors[2]) if colors.size() > 2 else wall_col.darkened(0.45)

    var sz: float = float(params.get("size", 4.5))
    var space_type: String = String(params.get("space_type", "atrium"))
    var rng := RandomNumberGenerator.new()
    rng.seed = int(params.get("seed", 1))

    var wall_mat := _csg_mat(wall_col, 0.05, 0.85)
    var accent_mat := _csg_mat(accent_col, 0.10, 0.5, 1.0)
    var floor_mat := _csg_mat(floor_col, 0.05, 0.85)

    var room := CSGCombiner3D.new()
    room.use_collision = false
    root.add_child(room)

    # Outer block (room shell).
    var outer := CSGBox3D.new()
    outer.size = Vector3(sz, sz * 0.85, sz)
    outer.position = Vector3(0, sz * 0.85 * 0.5, 0)
    outer.operation = CSGShape3D.OPERATION_UNION
    outer.material = wall_mat
    room.add_child(outer)

    # Inner void — most of the volume is hollow.
    var void_b := CSGBox3D.new()
    void_b.size = Vector3(sz - 0.30, sz * 0.85 - 0.20, sz - 0.30)
    void_b.position = outer.position
    void_b.operation = CSGShape3D.OPERATION_SUBTRACTION
    room.add_child(void_b)

    # Floor.
    var floor_mi := CSGBox3D.new()
    floor_mi.size = Vector3(sz - 0.32, 0.06, sz - 0.32)
    floor_mi.position = Vector3(0, 0.03, 0)
    floor_mi.operation = CSGShape3D.OPERATION_UNION
    floor_mi.material = floor_mat
    room.add_child(floor_mi)

    match space_type:
        "atrium":
            # Central oculus — circular hole punched in the ceiling.
            var oc := CSGCylinder3D.new()
            oc.radius = sz * 0.20
            oc.height = 0.4
            oc.position = Vector3(0, sz * 0.85, 0)
            oc.operation = CSGShape3D.OPERATION_SUBTRACTION
            room.add_child(oc)
            # Interior column at center under the oculus.
            var col := CSGCylinder3D.new()
            col.radius = sz * 0.05
            col.height = sz * 0.85 - 0.2
            col.position = Vector3(0, sz * 0.85 * 0.5, 0)
            col.operation = CSGShape3D.OPERATION_UNION
            col.material = accent_mat
            room.add_child(col)
        "grotto":
            # Multiple overlapping sphere subtractions form a cave-like void.
            for i in 6:
                var bub := CSGSphere3D.new()
                bub.radius = rng.randf_range(0.6, 1.1)
                bub.position = Vector3(
                    rng.randf_range(-sz * 0.25, sz * 0.25),
                    rng.randf_range(0.4, sz * 0.5),
                    rng.randf_range(-sz * 0.25, sz * 0.25),
                )
                bub.operation = CSGShape3D.OPERATION_SUBTRACTION
                room.add_child(bub)
            # Pool of accent material at floor center.
            var pool := CSGSphere3D.new()
            pool.radius = sz * 0.20
            pool.position = Vector3(0, 0, 0)
            pool.operation = CSGShape3D.OPERATION_UNION
            pool.material = accent_mat
            room.add_child(pool)
        "light_well":
            # Tall vertical cylinder cuts straight through ceiling to floor —
            # column of light at the center of an enclosed space.
            var well := CSGCylinder3D.new()
            well.radius = sz * 0.18
            well.height = sz * 1.2
            well.position = Vector3(0, sz * 0.42, 0)
            well.operation = CSGShape3D.OPERATION_SUBTRACTION
            room.add_child(well)
            # Glowing floor disc visible at the bottom.
            var glow := CSGCylinder3D.new()
            glow.radius = sz * 0.18 - 0.04
            glow.height = 0.06
            glow.position = Vector3(0, 0.03, 0)
            glow.operation = CSGShape3D.OPERATION_UNION
            glow.material = accent_mat
            room.add_child(glow)
            # Spill light from the well.
            var dl := DirectionalLight3D.new()
            dl.rotation = Vector3(deg_to_rad(-85), 0, 0)
            dl.light_color = accent_col
            dl.light_energy = 1.8
            root.add_child(dl)
        "apse":
            # Half-sphere niche carved into the back wall.
            var apse := CSGSphere3D.new()
            apse.radius = sz * 0.32
            apse.position = Vector3(0, sz * 0.40, -sz * 0.5)
            apse.operation = CSGShape3D.OPERATION_SUBTRACTION
            room.add_child(apse)
            # Glowing back-plate inside the apse so the niche reads.
            var back := CSGBox3D.new()
            back.size = Vector3(sz * 0.5, sz * 0.5, 0.05)
            back.position = Vector3(0, sz * 0.40, -sz * 0.5 + 0.10)
            back.operation = CSGShape3D.OPERATION_UNION
            back.material = accent_mat
            room.add_child(back)
        "inverse_cube":
            # 4 alcoves + 1 ceiling oculus + corner column subtractions.
            for s in [Vector3(0, sz * 0.4, -sz * 0.5), Vector3(0, sz * 0.4, sz * 0.5),
                      Vector3(-sz * 0.5, sz * 0.4, 0), Vector3(sz * 0.5, sz * 0.4, 0)]:
                var alc := CSGBox3D.new()
                alc.size = Vector3(sz * 0.30, sz * 0.45, sz * 0.30)
                alc.position = s
                alc.operation = CSGShape3D.OPERATION_SUBTRACTION
                room.add_child(alc)
            var oc := CSGBox3D.new()
            oc.size = Vector3(sz * 0.25, 0.4, sz * 0.25)
            oc.position = Vector3(0, sz * 0.85, 0)
            oc.operation = CSGShape3D.OPERATION_SUBTRACTION
            room.add_child(oc)
        _:
            pass

    return AABB(Vector3(-sz * 0.5 - 0.5, 0, -sz * 0.5 - 0.5),
                Vector3(sz + 1.0, sz * 0.9 + 0.4, sz + 1.0))


## ── Fantastic CSG forms ──────────────────────────────────────────
## More exotic Boolean specimens. Each is the absolute minimal recipe
## for a famously-hard-to-render mathematical / biological form.

## Form: menger_sponge
## The Menger Sponge fractal: cube minus 7 sub-cubes (3×3×3 grid minus
## center + face centers). Iterate twice for a depth-2 sponge.
##
## colors[0] — sponge body, colors[1] — accent
## params: depth (1=27 cubes, 2=400, 3 explosive), size, seed
func _build_menger_sponge(root: Node, colors: Array, params: Dictionary) -> AABB:
    if colors.size() < 2:
        colors = ["#e0c0a0", "#5a3818"]
    var col := Color(colors[0])
    var depth: int = clampi(int(params.get("depth", 2)), 1, 2)
    var size: float = float(params.get("size", 1.6))
    var mat := _csg_mat(col, 0.05, 0.85)

    # Recursive: for each unit cube at depth N, decide if it's "alive"
    # by Menger rule: discard if at least 2 of (i,j,k) are == 1 (centers).
    var unit_cubes: Array = []
    var n: int = int(pow(3, depth))
    var unit: float = size / float(n)

    for i in n:
        for j in n:
            for k in n:
                # Check at every recursive level if this cell is a "hole".
                var alive := true
                var ii: int = i; var jj: int = j; var kk: int = k
                for _l in depth:
                    var ax: int = ii % 3; var ay: int = jj % 3; var az: int = kk % 3
                    var center_count := int(ax == 1) + int(ay == 1) + int(az == 1)
                    if center_count >= 2:
                        alive = false; break
                    ii /= 3; jj /= 3; kk /= 3
                if alive:
                    unit_cubes.append(Vector3i(i, j, k))

    var origin: Vector3 = Vector3.ONE * (-size * 0.5 + unit * 0.5)
    for c in unit_cubes:
        var box := CSGBox3D.new()
        box.size = Vector3.ONE * unit * 0.98  # tiny gap to read facets
        box.position = origin + Vector3(c.x, c.y, c.z) * unit
        box.material = mat
        root.add_child(box)

    return AABB(Vector3.ONE * (-size * 0.5), Vector3.ONE * size)


## Form: gyroid_pillar
## Schoen Gyroid (triply-periodic minimal surface) faked via offset
## torus stack — visually echoes the gyroid's interlinked channels.
## A real gyroid needs SDF rendering; this is the CSG-friendly analog.
##
## colors[0] — pillar body, colors[1] — accent
func _build_gyroid_pillar(root: Node, colors: Array, params: Dictionary) -> AABB:
    if colors.size() < 2:
        colors = ["#a8c8e8", "#1f4ecc"]
    var col := Color(colors[0])
    var accent := Color(colors[1])
    var height: float = float(params.get("height", 2.4))
    var n_layers: int = int(params.get("layers", 12))
    var inner_r: float = float(params.get("inner_r", 0.30))
    var outer_r: float = float(params.get("outer_r", 0.45))
    var twist: float = float(params.get("twist", 0.7))
    var mat := _csg_mat(col, 0.10, 0.6)
    var accent_mat := _csg_mat(accent, 0.20, 0.4, 0.6)

    var combiner := CSGCombiner3D.new()
    root.add_child(combiner)

    var step: float = height / float(n_layers)
    for i in n_layers:
        # Each layer: a torus rotated about Y; alternates orientation per
        # layer to interlock like a gyroid's two oppositely-rotating channels.
        var ring := CSGTorus3D.new()
        ring.inner_radius = inner_r
        ring.outer_radius = outer_r
        ring.position = Vector3(0, step * 0.5 + i * step, 0)
        ring.rotation = Vector3(
            (PI * 0.5) if (i % 2 == 0) else 0.0,
            i * twist,
            (PI * 0.5) if (i % 2 == 1) else 0.0,
        )
        ring.material = mat if (i % 3 != 0) else accent_mat
        ring.operation = CSGShape3D.OPERATION_UNION
        combiner.add_child(ring)

    return AABB(Vector3(-outer_r - 0.1, 0, -outer_r - 0.1),
                Vector3(outer_r * 2 + 0.2, height + 0.1, outer_r * 2 + 0.2))


## Form: trabecular_skeleton
## Bone trabeculae — irregular branching foam carved from a sphere.
## Recipe: start with a sphere, subtract many small overlapping spheres
## at random positions to leave only the connecting struts.
func _build_trabecular_skeleton(root: Node, colors: Array, params: Dictionary) -> AABB:
    if colors.size() < 2:
        colors = ["#f0e0c8", "#a86028"]
    var col := Color(colors[0])
    var accent := Color(colors[1])
    var radius: float = float(params.get("radius", 0.7))
    var n_voids: int = int(params.get("voids", 60))
    var min_void_r: float = float(params.get("min_void_r", 0.12))
    var max_void_r: float = float(params.get("max_void_r", 0.22))
    var seed_v: int = int(params.get("seed", 1))
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_v
    var mat := _csg_mat(col, 0.10, 0.6)
    var accent_mat := _csg_mat(accent, 0.15, 0.5, 0.4)

    var core := CSGSphere3D.new()
    core.radius = radius
    core.material = mat
    root.add_child(core)

    for i in n_voids:
        var theta: float = rng.randf() * PI
        var phi: float = rng.randf() * TAU
        # Distribute voids both inside and at the surface to carve struts.
        var r: float = rng.randf_range(0.0, radius * 1.05)
        var void_r: float = rng.randf_range(min_void_r, max_void_r)
        var s := CSGSphere3D.new()
        s.radius = void_r
        s.position = Vector3(
            r * sin(theta) * cos(phi),
            r * sin(theta) * sin(phi),
            r * cos(theta),
        )
        s.operation = CSGShape3D.OPERATION_SUBTRACTION
        core.add_child(s)

    # A few accent UNION nodes — small spheres at struts representing
    # mineralization seeds.
    for i in 6:
        var seed_sphere := CSGSphere3D.new()
        seed_sphere.radius = 0.04
        var th: float = rng.randf() * PI
        var ph: float = rng.randf() * TAU
        var rr: float = rng.randf_range(0.5, 0.9) * radius
        seed_sphere.position = Vector3(
            rr * sin(th) * cos(ph),
            rr * sin(th) * sin(ph),
            rr * cos(th),
        )
        seed_sphere.operation = CSGShape3D.OPERATION_UNION
        seed_sphere.material = accent_mat
        core.add_child(seed_sphere)

    return AABB(Vector3.ONE * (-radius - 0.2), Vector3.ONE * (radius * 2 + 0.4))


## Form: schwarz_lattice
## Schwarz P-surface analog: a cubic lattice with spherical voids at
## each vertex of a 3×3×3 grid, leaving a connected strut network.
func _build_schwarz_lattice(root: Node, colors: Array, params: Dictionary) -> AABB:
    if colors.size() < 2:
        colors = ["#d8d8e0", "#3a3a4a"]
    var col := Color(colors[0])
    var size: float = float(params.get("size", 1.5))
    var n: int = int(params.get("grid", 3))
    var void_r: float = float(params.get("void_r", 0.35))
    var mat := _csg_mat(col, 0.20, 0.4)

    var core := CSGBox3D.new()
    core.size = Vector3.ONE * size
    core.material = mat
    root.add_child(core)

    var step: float = size / float(n - 1)
    var origin: float = -size * 0.5
    for i in n:
        for j in n:
            for k in n:
                # Subtract spheres at every vertex of the inner grid.
                var s := CSGSphere3D.new()
                s.radius = void_r
                s.position = Vector3(
                    origin + i * step,
                    origin + j * step,
                    origin + k * step,
                )
                s.operation = CSGShape3D.OPERATION_SUBTRACTION
                core.add_child(s)

    return AABB(Vector3.ONE * (-size * 0.5 - 0.1), Vector3.ONE * (size + 0.2))


## Form: hyperbolic_vault
## Catalan / Antoni Gaudí-style vault: ceiling carved by hyperbolic
## paraboloid analog (twisted cylinder lattice carved upward through a
## flat ceiling). Looking up gives a dazzling rib pattern.
func _build_hyperbolic_vault(root: Node, colors: Array, params: Dictionary) -> AABB:
    if colors.size() < 2:
        colors = ["#e8d8b8", "#c87038"]
    var wall_col := Color(colors[0])
    var rib_col := Color(colors[1])
    var room_w: float = float(params.get("room_size", 5.0))
    var room_h: float = float(params.get("room_height", 4.5))
    var n_ribs: int = int(params.get("ribs", 12))
    var rib_thick: float = float(params.get("rib_thickness", 0.10))
    var hr := room_w * 0.5
    var wall_mat := _csg_mat(wall_col, 0.05, 0.85)
    var rib_mat := _csg_mat(rib_col, 0.10, 0.5, 0.4)

    # Floor (deep brown)
    var floor_mi := MeshInstance3D.new()
    var fb := BoxMesh.new(); fb.size = Vector3(room_w, 0.05, room_w)
    floor_mi.mesh = fb
    floor_mi.position = Vector3(0, -0.025, 0)
    var fmat := StandardMaterial3D.new()
    fmat.albedo_color = Color(0.15, 0.10, 0.06)
    fmat.roughness = 0.9
    floor_mi.material_override = fmat
    root.add_child(floor_mi)

    # Tall walls — interior emissive
    for w_specs in [
        [Vector3(0, room_h*0.5, -hr), Vector3(room_w, room_h, 0.05)],
        [Vector3(0, room_h*0.5,  hr), Vector3(room_w, room_h, 0.05)],
        [Vector3(-hr, room_h*0.5, 0), Vector3(0.05, room_h, room_w)],
        [Vector3(hr,  room_h*0.5, 0), Vector3(0.05, room_h, room_w)],
    ]:
        var w := MeshInstance3D.new()
        var b := BoxMesh.new(); b.size = w_specs[1]
        w.mesh = b
        w.position = w_specs[0]
        w.material_override = _emissive(wall_col, 0.9)
        root.add_child(w)

    # Vault ceiling = solid CSG box minus a central dome + N twisting ribs.
    var ceil_h := 1.2
    var combiner := CSGCombiner3D.new()
    combiner.use_collision = false
    root.add_child(combiner)
    var ceil_box := CSGBox3D.new()
    ceil_box.size = Vector3(room_w, ceil_h, room_w)
    ceil_box.position = Vector3(0, room_h - ceil_h * 0.5, 0)
    ceil_box.material = wall_mat
    ceil_box.operation = CSGShape3D.OPERATION_UNION
    combiner.add_child(ceil_box)
    # Dome subtraction
    var dome := CSGSphere3D.new()
    dome.radius = room_w * 0.45
    dome.position = Vector3(0, room_h - ceil_h * 0.4, 0)
    dome.operation = CSGShape3D.OPERATION_SUBTRACTION
    combiner.add_child(dome)
    # Twisting rib subtractions (cylinders rotated radially)
    for i in n_ribs:
        var ang: float = i * TAU / float(n_ribs)
        var rib := CSGCylinder3D.new()
        rib.radius = rib_thick
        rib.height = room_w * 1.3
        # Tilt cylinder inward to converge at the dome center.
        rib.transform = Transform3D(Basis().rotated(Vector3.UP, ang).rotated(Vector3.RIGHT, deg_to_rad(60)), Vector3.ZERO)
        rib.position = Vector3(cos(ang) * room_w * 0.35, room_h - 0.4, sin(ang) * room_w * 0.35)
        rib.operation = CSGShape3D.OPERATION_SUBTRACTION
        combiner.add_child(rib)

    # Skylight at the dome apex — emissive plane behind the carved-out hole.
    var sky := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = room_w * 0.10
    sm.height = room_w * 0.20
    sky.mesh = sm
    sky.position = Vector3(0, room_h + 0.05, 0)
    sky.material_override = _emissive(rib_col.lightened(0.30), 3.0)
    root.add_child(sky)

    # Spill light from the apex
    var fill := OmniLight3D.new()
    fill.position = Vector3(0, room_h - 0.5, 0)
    fill.light_color = rib_col
    fill.light_energy = 2.4
    fill.omni_range = room_w * 1.4
    root.add_child(fill)

    var env_node := root.find_child("WorldEnvironment", true, false)
    if env_node and env_node is WorldEnvironment:
        var env := (env_node as WorldEnvironment).environment
        env.background_color = wall_col.darkened(0.4)
        env.ambient_light_color = wall_col
        env.ambient_light_energy = 0.6

    return AABB(Vector3(-hr - 0.1, 0, -hr - 0.1),
                Vector3(room_w + 0.2, room_h + 0.4, room_w + 0.2))


## Form: sponge_skeleton
## Sea-sponge / Latticework cube: a cube minus a recursive cross of
## smaller cylinders along each axis, leaving an open frame structure.
func _build_sponge_skeleton(root: Node, colors: Array, params: Dictionary) -> AABB:
    if colors.size() < 2:
        colors = ["#f0e8d0", "#a83820"]
    var col := Color(colors[0])
    var size: float = float(params.get("size", 1.5))
    var n: int = int(params.get("grid", 4))
    var hole_r: float = float(params.get("hole_radius", 0.18))
    var mat := _csg_mat(col, 0.05, 0.7)

    var core := CSGBox3D.new()
    core.size = Vector3.ONE * size
    core.material = mat
    root.add_child(core)

    var step: float = size / float(n)
    var origin: float = -size * 0.5 + step * 0.5

    # Punch cylindrical channels along each axis at every grid point.
    for axis in 3:
        for i in n:
            for j in n:
                var c := CSGCylinder3D.new()
                c.radius = hole_r
                c.height = size + 0.2
                var rotation_axis: Vector3
                var pos: Vector3
                match axis:
                    0:  # holes along X
                        c.transform.basis = Basis(Vector3.FORWARD, PI * 0.5)
                        pos = Vector3(0, origin + i * step, origin + j * step)
                    1:  # holes along Y
                        pos = Vector3(origin + i * step, 0, origin + j * step)
                    _:  # holes along Z
                        c.transform.basis = Basis(Vector3.RIGHT, PI * 0.5)
                        pos = Vector3(origin + i * step, origin + j * step, 0)
                c.position = pos
                c.operation = CSGShape3D.OPERATION_SUBTRACTION
                core.add_child(c)

    return AABB(Vector3.ONE * (-size * 0.5 - 0.1), Vector3.ONE * (size + 0.2))


## Form: voronoi_meteorite
## Sphere with K spherical voids placed at 3D Voronoi seed positions.
## Where seed-spheres overlap on the sphere's surface, voids cluster
## and create cratered facets — the meteorite/asteroid texture.
func _build_voronoi_meteorite(root: Node, colors: Array, params: Dictionary) -> AABB:
    if colors.size() < 2:
        colors = ["#a89878", "#3a2818"]
    var col := Color(colors[0])
    var radius: float = float(params.get("radius", 0.7))
    var n_seeds: int = int(params.get("seeds", 24))
    var seed_v: int = int(params.get("seed", 1))
    var crater_min: float = float(params.get("crater_min", 0.10))
    var crater_max: float = float(params.get("crater_max", 0.30))
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_v
    var mat := _csg_mat(col, 0.10, 0.65)

    var core := CSGSphere3D.new()
    core.radius = radius
    core.material = mat
    root.add_child(core)

    # Generate K seed positions on the surface of a slightly-larger sphere,
    # then carve a spherical crater there. Sizes vary so some craters are
    # tiny and others overlap to form polygonal facets.
    for i in n_seeds:
        var theta: float = rng.randf() * PI
        var phi: float = rng.randf() * TAU
        var crater_r: float = rng.randf_range(crater_min, crater_max)
        # Place crater center just past the surface so it cuts INTO the sphere.
        var place_r: float = radius + crater_r * 0.45
        var crater := CSGSphere3D.new()
        crater.radius = crater_r
        crater.position = Vector3(
            place_r * sin(theta) * cos(phi),
            place_r * sin(theta) * sin(phi),
            place_r * cos(theta),
        )
        crater.operation = CSGShape3D.OPERATION_SUBTRACTION
        core.add_child(crater)

    return AABB(Vector3.ONE * (-radius - 0.2), Vector3.ONE * (radius * 2 + 0.4))


## Form: boolean_cathedral
## Recursive nested CSG: nave corridor + apse hemisphere at far end +
## smaller niches carved into the apse + tiny ornament spheres in the
## niches. Each level is a Boolean of the previous.
func _build_boolean_cathedral(root: Node, colors: Array, params: Dictionary) -> AABB:
    if colors.size() < 3:
        colors = ["#e8d8b8", "#f0c020", "#3a2818"]
    var wall_col := Color(colors[0])
    var sky_col := Color(colors[1])
    var floor_col := Color(colors[2])

    var nave_l: float = float(params.get("nave_length", 7.0))
    var nave_w: float = float(params.get("nave_width", 3.6))
    var nave_h: float = float(params.get("nave_height", 4.0))
    var n_arches: int = int(params.get("arches", 4))
    var n_niches: int = int(params.get("niches", 5))

    var wall_mat := _csg_mat(wall_col, 0.05, 0.85)
    var sky_mat := _csg_mat(sky_col, 0.05, 0.4, 1.6)
    var floor_mat := _csg_mat(floor_col, 0.05, 0.9)

    # ── Level 1: nave (a corridor with arched windows) ────────────
    var combiner := CSGCombiner3D.new()
    combiner.use_collision = false
    root.add_child(combiner)

    var outer_nave := CSGBox3D.new()
    outer_nave.size = Vector3(nave_w, nave_h, nave_l)
    outer_nave.position = Vector3(0, nave_h * 0.5, 0)
    outer_nave.operation = CSGShape3D.OPERATION_UNION
    outer_nave.material = wall_mat
    combiner.add_child(outer_nave)

    var inner_nave := CSGBox3D.new()
    inner_nave.size = Vector3(nave_w - 0.30, nave_h - 0.20, nave_l - 0.20)
    inner_nave.position = outer_nave.position
    inner_nave.operation = CSGShape3D.OPERATION_SUBTRACTION
    combiner.add_child(inner_nave)

    # Arched side windows (sphere SUBTRACTIONS) — the corridor recipe.
    var ap_step: float = nave_l / float(n_arches + 1)
    for i in n_arches:
        var z := -nave_l * 0.5 + (i + 1) * ap_step
        for side in [-1.0, 1.0]:
            var arch := CSGSphere3D.new()
            arch.radius = nave_h * 0.40
            arch.position = Vector3(side * nave_w * 0.5, nave_h * 0.55, z)
            arch.operation = CSGShape3D.OPERATION_SUBTRACTION
            combiner.add_child(arch)

    # Floor.
    var floor_mi := CSGBox3D.new()
    floor_mi.size = Vector3(nave_w - 0.32, 0.06, nave_l - 0.20)
    floor_mi.position = Vector3(0, 0.03, 0)
    floor_mi.operation = CSGShape3D.OPERATION_UNION
    floor_mi.material = floor_mat
    combiner.add_child(floor_mi)

    # ── Level 2: apse — hemispherical recess at the far end ───────
    var apse_combiner := CSGCombiner3D.new()
    apse_combiner.use_collision = false
    root.add_child(apse_combiner)

    var apse_r: float = nave_w * 0.50
    # The apse "shell" (bigger hemisphere) UNION'd into the back wall.
    var apse_shell := CSGSphere3D.new()
    apse_shell.radius = apse_r * 1.30
    apse_shell.position = Vector3(0, nave_h * 0.55, -nave_l * 0.5 - apse_r * 0.10)
    apse_shell.material = wall_mat
    apse_shell.operation = CSGShape3D.OPERATION_UNION
    apse_combiner.add_child(apse_shell)

    # Hollow out the apse interior.
    var apse_void := CSGSphere3D.new()
    apse_void.radius = apse_r
    apse_void.position = Vector3(0, nave_h * 0.55, -nave_l * 0.5 - apse_r * 0.10)
    apse_void.operation = CSGShape3D.OPERATION_SUBTRACTION
    apse_combiner.add_child(apse_void)

    # ── Level 3: N niches carved into the apse interior ───────────
    for i in n_niches:
        var ang: float = lerpf(-PI * 0.5, PI * 0.5, float(i) / float(max(n_niches - 1, 1)))
        var nx: float = cos(ang) * apse_r * 0.85
        var ny: float = nave_h * 0.55 + sin(ang) * 0.20
        var nz: float = -nave_l * 0.5 - apse_r * 0.10 + cos(ang) * apse_r * 0.85 * sin(ang) * 0.10
        # Niche carve.
        var niche := CSGSphere3D.new()
        niche.radius = apse_r * 0.18
        niche.position = Vector3(nx, ny, -nave_l * 0.5 - apse_r * 0.10 + cos(ang) * 0.30)
        niche.operation = CSGShape3D.OPERATION_SUBTRACTION
        apse_combiner.add_child(niche)
        # ── Level 4: ornament — tiny accent sphere inside each niche
        var ornament := CSGSphere3D.new()
        ornament.radius = apse_r * 0.06
        ornament.position = niche.position
        ornament.operation = CSGShape3D.OPERATION_UNION
        ornament.material = sky_mat
        apse_combiner.add_child(ornament)

    # Glowing aperture behind the apse (sky color visible through niches)
    var apse_back := MeshInstance3D.new()
    var ab := SphereMesh.new()
    ab.radius = apse_r * 0.6
    ab.height = apse_r * 1.2
    apse_back.mesh = ab
    apse_back.position = Vector3(0, nave_h * 0.55, -nave_l * 0.5 - apse_r * 0.5)
    apse_back.material_override = _emissive(sky_col, 2.5)
    root.add_child(apse_back)

    # Nave fill light.
    var fill := DirectionalLight3D.new()
    fill.rotation = Vector3(deg_to_rad(-30), deg_to_rad(50), 0)
    fill.light_color = sky_col
    fill.light_energy = 1.0
    root.add_child(fill)

    # Apse spill.
    var apse_spill := OmniLight3D.new()
    apse_spill.position = Vector3(0, nave_h * 0.55, -nave_l * 0.5 - apse_r * 0.10)
    apse_spill.light_color = sky_col
    apse_spill.light_energy = 2.0
    apse_spill.omni_range = nave_w * 1.5
    root.add_child(apse_spill)

    return AABB(Vector3(-nave_w * 0.5 - 0.5, 0, -nave_l * 0.5 - apse_r * 1.5),
                Vector3(nave_w + 1.0, nave_h + 0.4, nave_l + apse_r * 2 + 0.5))


func _matte_color(c: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 0.85
    m.metallic = 0.0
    m.emission_enabled = true
    m.emission = c
    m.emission_energy_multiplier = 0.18
    return m


func _load_config(path: String) -> Dictionary:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null: return {}
    var json := JSON.new()
    if json.parse(f.get_as_text()) != OK: return {}
    return json.data if json.data is Dictionary else {}
