# chromatic_form_artifact.gd
# Map-placeable wrapper for the chromatic-form gallery. Reads a JSON
# config (same format the offline renderer consumes) and builds the
# requested form as the artifact's own subtree — so the bake pipeline
# can snapshot it to a PackedScene, and prebaked_loader can place it
# instantly in any map.
#
# Currently carries the four Turrell Boolean-space builders. The other
# chromatic forms (fin_wall, gradient_corridor, etc.) live in
# render_chromatic_form.gd and could be ported here in the same pattern.
#
# @identity
# essence: bring Turrell rooms into walkable maps via the same bake → place loop
# desire: a player walks the spine and passes through an Aten Reign overhead
# critical_parameter: config_path — the JSON config baked from the gallery
# triggers: apply_grid_config swaps the config, rebuilds the subtree
# emerges: the federation absorbs phenomenological color spaces alongside totems
# needs: render_chromatic_form.gd-compatible JSON configs in best_of/
# relationships: sibling to composition_artifact for primitive_stack;
#   shares the prebaked_loader downstream pipeline
# truth: the room IS the artifact when the artifact IS a room

extends Node3D
class_name ChromaticFormArtifact

@export var config_path: String = ""


func _ready() -> void:
    if config_path.strip_edges().is_empty():
        return
    _build_from_config()


func apply_grid_config(cfg: Dictionary) -> void:
    if cfg.has("config_path"):
        config_path = str(cfg["config_path"])
    for child in get_children():
        child.queue_free()
    _build_from_config()


func _build_from_config() -> void:
    if config_path.is_empty():
        return
    var f := FileAccess.open(config_path, FileAccess.READ)
    if f == null:
        push_warning("[chromatic_form_artifact] config not found: %s" % config_path)
        return
    var json := JSON.new()
    if json.parse(f.get_as_text()) != OK:
        push_warning("[chromatic_form_artifact] JSON parse error in %s" % config_path)
        return
    var cfg = json.data
    if not (cfg is Dictionary):
        push_warning("[chromatic_form_artifact] config is not a dict: %s" % config_path)
        return

    var form := str(cfg.get("form", ""))
    var colors: Array = cfg.get("colors", [])
    var params: Dictionary = cfg.get("params", {})

    match form:
        "turrell_skyspace":
            _build_turrell_skyspace(colors, params)
        "turrell_afrum_corner":
            _build_turrell_afrum_corner(colors, params)
        "turrell_chromatic_chamber":
            _build_turrell_chromatic_chamber(colors, params)
        "turrell_aten_reign":
            _build_turrell_aten_reign(colors, params)
        _:
            push_warning("[chromatic_form_artifact] unsupported form: %s" % form)


# ── Shared utilities ─────────────────────────────────────────────

func _emissive(c: Color, energy: float = 2.4) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.emission_enabled = true
    m.emission = c
    m.emission_energy_multiplier = energy
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m


# ── Form: turrell_skyspace ───────────────────────────────────────

func _build_turrell_skyspace(colors: Array, params: Dictionary) -> void:
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

    var floor_mi := MeshInstance3D.new()
    var fb := BoxMesh.new(); fb.size = Vector3(room_w, 0.05, room_w)
    floor_mi.mesh = fb
    floor_mi.position = Vector3(0, -0.025, 0)
    var fmat := StandardMaterial3D.new()
    fmat.albedo_color = Color(0.32, 0.22, 0.14)
    fmat.roughness = 0.85
    floor_mi.material_override = fmat
    add_child(floor_mi)

    var wall_specs := [
        Vector3( 0, room_h * 0.5, -hr),
        Vector3( 0, room_h * 0.5,  hr),
        Vector3(-hr, room_h * 0.5, 0),
        Vector3( hr, room_h * 0.5, 0),
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
        add_child(w)

    var north_d: float = (hr - ha_d)
    var south_d: float = (hr - ha_d)
    var ceil_y: float = room_h
    var n := MeshInstance3D.new()
    var nb := BoxMesh.new(); nb.size = Vector3(room_w, 0.05, north_d)
    n.mesh = nb
    n.position = Vector3(0, ceil_y, ha_d + north_d * 0.5)
    n.material_override = _emissive(room_col, 1.6)
    add_child(n)
    var s := MeshInstance3D.new()
    var sb := BoxMesh.new(); sb.size = Vector3(room_w, 0.05, south_d)
    s.mesh = sb
    s.position = Vector3(0, ceil_y, -ha_d - south_d * 0.5)
    s.material_override = _emissive(room_col, 1.6)
    add_child(s)
    var w_d: float = ap_d
    var west_w: float = (hr - ha_w)
    var ws := MeshInstance3D.new()
    var wsb := BoxMesh.new(); wsb.size = Vector3(west_w, 0.05, w_d)
    ws.mesh = wsb
    ws.position = Vector3(-ha_w - west_w * 0.5, ceil_y, 0)
    ws.material_override = _emissive(room_col, 1.6)
    add_child(ws)
    var es := MeshInstance3D.new()
    var esb := BoxMesh.new(); esb.size = Vector3(west_w, 0.05, w_d)
    es.mesh = esb
    es.position = Vector3(ha_w + west_w * 0.5, ceil_y, 0)
    es.material_override = _emissive(room_col, 1.6)
    add_child(es)

    var sky := MeshInstance3D.new()
    var sky_mesh := BoxMesh.new()
    sky_mesh.size = Vector3(ap_w, 0.02, ap_d)
    sky.mesh = sky_mesh
    sky.position = Vector3(0, ceil_y + 0.06, 0)
    sky.material_override = _emissive(sky_col, 3.5)
    add_child(sky)

    var fill := OmniLight3D.new()
    fill.position = Vector3(0, ceil_y - 0.4, 0)
    fill.light_color = sky_col
    fill.light_energy = 1.6
    fill.omni_range = room_w * 0.9
    add_child(fill)


# ── Form: turrell_afrum_corner ───────────────────────────────────

func _build_turrell_afrum_corner(colors: Array, params: Dictionary) -> void:
    if colors.size() < 2:
        colors = ["#0a0816", "#28a8ff"]
    var dark_col := Color(colors[0])
    var afrum_col := Color(colors[1])
    var room_w: float = float(params.get("room_size", 5.0))
    var room_h: float = float(params.get("room_height", 3.0))
    var hr := room_w * 0.5

    for w_specs in [
        [Vector3(0, room_h*0.5, -hr), Vector3(room_w, room_h, 0.05)],
        [Vector3(-hr, room_h*0.5, 0), Vector3(0.05, room_h, room_w)],
        [Vector3(hr,  room_h*0.5, 0), Vector3(0.05, room_h, room_w)],
        [Vector3(0,   room_h, 0),     Vector3(room_w, 0.05, room_w)],
    ]:
        var w := MeshInstance3D.new()
        var b := BoxMesh.new(); b.size = w_specs[1]
        w.mesh = b
        w.position = w_specs[0]
        w.material_override = _emissive(dark_col, 0.6)
        add_child(w)

    var floor_mi := MeshInstance3D.new()
    var fb := BoxMesh.new(); fb.size = Vector3(room_w, 0.05, room_w)
    floor_mi.mesh = fb
    floor_mi.position = Vector3(0, -0.025, 0)
    floor_mi.material_override = _emissive(dark_col.lightened(0.04), 0.4)
    add_child(floor_mi)

    var cube := MeshInstance3D.new()
    var cb := BoxMesh.new()
    cb.size = Vector3(1.1, 1.1, 1.1)
    cube.mesh = cb
    cube.position = Vector3(-0.55, 0.85, -0.55)
    cube.material_override = _emissive(afrum_col, 4.5)
    add_child(cube)

    var spill := OmniLight3D.new()
    spill.position = Vector3(-0.4, 1.0, -0.4)
    spill.light_color = afrum_col
    spill.light_energy = 3.0
    spill.omni_range = 4.5
    add_child(spill)


# ── Form: turrell_chromatic_chamber ──────────────────────────────

func _build_turrell_chromatic_chamber(colors: Array, params: Dictionary) -> void:
    if colors.size() < 2:
        colors = ["#c83838", "#f0c020"]
    var room_col := Color(colors[0])
    var aperture_col := Color(colors[1])
    var room_w: float = float(params.get("room_size", 4.0))
    var room_h: float = float(params.get("room_height", 2.6))
    var hr := room_w * 0.5

    for w_specs in [
        [Vector3(-hr, room_h*0.5, 0), Vector3(0.05, room_h, room_w), 1.4],
        [Vector3(hr,  room_h*0.5, 0), Vector3(0.05, room_h, room_w), 1.4],
        [Vector3(0,   room_h,     0), Vector3(room_w, 0.05, room_w), 1.4],
        [Vector3(0,   room_h*0.5, hr), Vector3(room_w, room_h, 0.05), 1.4],
    ]:
        var w := MeshInstance3D.new()
        var b := BoxMesh.new(); b.size = w_specs[1]
        w.mesh = b
        w.position = w_specs[0]
        w.material_override = _emissive(room_col, w_specs[2])
        add_child(w)

    var floor_mi := MeshInstance3D.new()
    var fb := BoxMesh.new(); fb.size = Vector3(room_w, 0.05, room_w)
    floor_mi.mesh = fb
    floor_mi.position = Vector3(0, -0.025, 0)
    var fmat := StandardMaterial3D.new()
    fmat.albedo_color = Color(0.10, 0.07, 0.04)
    fmat.roughness = 0.85
    floor_mi.material_override = fmat
    add_child(floor_mi)

    var ap_w: float = room_w * 0.35
    var ap_h: float = room_h * 0.55
    var ap_y: float = room_h * 0.55
    var back_z: float = -hr
    var top_h: float = room_h - ap_y - ap_h * 0.5
    var top := MeshInstance3D.new()
    var tb := BoxMesh.new(); tb.size = Vector3(room_w, top_h, 0.05)
    top.mesh = tb
    top.position = Vector3(0, ap_y + ap_h * 0.5 + top_h * 0.5, back_z)
    top.material_override = _emissive(room_col, 1.4)
    add_child(top)
    var bot_h: float = ap_y - ap_h * 0.5
    var bot := MeshInstance3D.new()
    var bb := BoxMesh.new(); bb.size = Vector3(room_w, bot_h, 0.05)
    bot.mesh = bb
    bot.position = Vector3(0, bot_h * 0.5, back_z)
    bot.material_override = _emissive(room_col, 1.4)
    add_child(bot)
    var side_w: float = (room_w - ap_w) * 0.5
    var lf := MeshInstance3D.new()
    var lb := BoxMesh.new(); lb.size = Vector3(side_w, ap_h, 0.05)
    lf.mesh = lb
    lf.position = Vector3(-ap_w * 0.5 - side_w * 0.5, ap_y, back_z)
    lf.material_override = _emissive(room_col, 1.4)
    add_child(lf)
    var rt := MeshInstance3D.new()
    rt.mesh = lb
    rt.position = Vector3(ap_w * 0.5 + side_w * 0.5, ap_y, back_z)
    rt.material_override = _emissive(room_col, 1.4)
    add_child(rt)
    var ap := MeshInstance3D.new()
    var apm := BoxMesh.new(); apm.size = Vector3(ap_w, ap_h, 0.02)
    ap.mesh = apm
    ap.position = Vector3(0, ap_y, back_z - 0.04)
    ap.material_override = _emissive(aperture_col, 4.0)
    add_child(ap)

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
        add_child(step)

    var spill := OmniLight3D.new()
    spill.position = Vector3(0, ap_y, back_z + 0.4)
    spill.light_color = aperture_col
    spill.light_energy = 2.4
    spill.omni_range = room_w * 1.1
    add_child(spill)


# ── Form: turrell_aten_reign ─────────────────────────────────────

func _build_turrell_aten_reign(colors: Array, params: Dictionary) -> void:
    if colors.size() < 4:
        colors = ["#ff66d8", "#b34de8", "#6666f0", "#3399ff"]
    var n_rings: int = int(params.get("rings", 6))
    var base_r: float = float(params.get("base_radius", 0.18))
    var step_r: float = float(params.get("step_radius", 0.16))
    var ring_h: float = float(params.get("ring_height", 0.45))
    var ring_w: float = float(params.get("ring_width", 0.10))
    var y_start: float = float(params.get("y_start", 2.5))

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
    add_child(floor_mi)

    for i in range(n_rings):
        var col := Color(colors[i % colors.size()])
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
        add_child(ring)

    var oculus := MeshInstance3D.new()
    var om := CylinderMesh.new()
    om.top_radius = base_r * 0.55
    om.bottom_radius = base_r * 0.55
    om.height = 0.05
    oculus.mesh = om
    oculus.position = Vector3(0, y_start + n_rings * ring_h + 0.1, 0)
    oculus.material_override = _emissive(Color(colors[(n_rings - 1) % colors.size()]).lightened(0.35), 4.5)
    add_child(oculus)

    var bottom_glow := OmniLight3D.new()
    bottom_glow.position = Vector3(0, y_start - 0.3, 0)
    bottom_glow.light_color = Color(colors[0])
    bottom_glow.light_energy = 1.8
    bottom_glow.omni_range = base_r + n_rings * step_r + 1.0
    add_child(bottom_glow)
