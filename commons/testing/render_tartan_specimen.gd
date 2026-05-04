extends SceneTree

## Render one tartan-shader cube. Config keys:
##   colors:      ["#hex", ...] up to 4 — passed as color_a..color_d
##   brightness:  float, brightness_boost shader param
##   saturation:  float, saturation_boost shader param
##   uv_scale:    [x, y] for pattern density
##   wait:        float

const SHADER := "res://commons/resourses/shaders/tartanshader.gdshader"

# Inline minimal tartan shader — fixes the [0.5, 1.0] channel clamp bug in
# the production shader so dark palettes (Black Watch, Wallace) render the
# black they actually use, instead of being forced to gray.
const INLINE_TARTAN_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 color_a : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 color_b : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 color_c : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 color_d : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform vec2 uv_scale = vec2(8.0, 8.0);

// Stripe pattern: returns one of 4 colors based on a normalized 1D coord.
// Each color block has different widths to mimic a real tartan sett.
vec3 stripe(float t) {
    // Normalize to [0,1]
    float u = fract(t);
    // Tartan sett: 4 unequal bands.
    if (u < 0.30) return color_a.rgb;
    if (u < 0.45) return color_b.rgb;
    if (u < 0.75) return color_c.rgb;
    return color_d.rgb;
}

void fragment() {
    vec2 uv = UV * uv_scale;
    vec3 h = stripe(uv.x);
    vec3 v = stripe(uv.y);
    // Where horizontal & vertical stripes cross, average them — that's
    // the literal weave: warp shows half the time, weft shows half.
    ALBEDO = mix(h, v, 0.5);
}
"""

var _config_path: String = ""
var _out_path: String = "user://tartan.png"
var _wait := 1.5

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
    var json := JSON.new()
    if json.parse(f.get_as_text()) != OK:
        push_error("bad json"); quit(1); return
    var cfg = json.data
    if not (cfg is Dictionary):
        push_error("not a dict"); quit(1); return

    var root := get_root()

    # Soft neutral environment — tartan shader has its own brightness/
    # saturation, so keep ambient + sun low to avoid washing colors.
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.93, 0.93, 0.91)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.40, 0.40, 0.42)
    e.ambient_light_energy = 1.0
    env.environment = e
    root.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(deg_to_rad(-45), deg_to_rad(30), 0)
    sun.light_energy = 0.65
    root.add_child(sun)

    # Inline tartan shader — production tartanshader.gdshader hardcodes
    # clamp(channel, 0.5, 1.0) which kills dark palettes (Black Watch's
    # black becomes gray; MacLeod's red becomes pink). Use our own
    # honest weave shader instead.
    var shader := Shader.new()
    shader.code = INLINE_TARTAN_SHADER
    var mat := ShaderMaterial.new()
    mat.shader = shader

    var colors: Array = cfg.get("colors", ["#cc1f1f", "#1f4ecc", "#1a8848", "#f0c020"])
    var color_keys := ["color_a", "color_b", "color_c", "color_d"]
    for i in 4:
        var c: Color
        if i < colors.size():
            c = Color(String(colors[i]))
        else:
            c = Color(String(colors[colors.size() - 1]))
        mat.set_shader_parameter(color_keys[i], c)

    var uv_scale: Array = cfg.get("uv_scale", [8.0, 8.0])
    mat.set_shader_parameter("uv_scale", Vector2(float(uv_scale[0]), float(uv_scale[1])))

    # Cube specimen.
    var cube := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(2.0, 2.0, 2.0)
    cube.mesh = bm
    cube.material_override = mat
    root.add_child(cube)

    # Camera 3/4 view.
    var cam := Camera3D.new()
    root.add_child(cam)
    cam.global_position = Vector3(2.6, 2.0, 2.6)
    cam.look_at(Vector3.ZERO, Vector3.UP)
    cam.fov = 38
    cam.make_current()

    var t := 0.0
    while t < _wait:
        await create_timer(0.05).timeout
        t += 0.05

    var img := root.get_texture().get_image()
    if img == null: push_error("no image"); quit(1); return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_path.get_base_dir()))
    img.save_png(_out_path)
    print("tartan: ", _out_path)
    quit(0)
