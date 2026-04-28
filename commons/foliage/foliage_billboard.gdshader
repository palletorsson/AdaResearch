// foliage_billboard.gdshader — Camera-facing alpha-tested billboard with
// optional wind sway. Designed for MultiMesh batching: the per-instance
// transform's translation column is the anchor position, and the
// transform's basis column lengths supply the (width, height) scale.
// The basis rotation is IGNORED — the shader computes its own basis to
// face the camera (Y-locked: petals/grass stay vertical).
//
// Per-instance vertex colour drives the tint, so the existing
// CritterDNA primary/secondary/tertiary palette flows through with no
// extra work.

shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform sampler2D albedo_tex : source_color, hint_default_white;
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float wind_amplitude : hint_range(0.0, 0.5) = 0.06;
uniform float wind_frequency : hint_range(0.0, 5.0) = 1.5;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.7;
// 1.0 = fully camera-facing (Y-locked spherical billboard).
// 0.0 = use the basis the collector supplied (static orientation).
uniform float face_camera : hint_range(0.0, 1.0) = 1.0;

void vertex() {
    // Anchor position is the translation column of the per-instance
    // model matrix (set by the collector to the quad centre).
    vec3 anchor_world = MODEL_MATRIX[3].xyz;
    // Pull scale from the basis column magnitudes.
    float sx = length(MODEL_MATRIX[0].xyz);
    float sy = length(MODEL_MATRIX[1].xyz);

    // Camera-facing basis: Y-locked billboard. We keep world Y as up so
    // grass/petals stay vertical, and rotate around Y so the quad's
    // normal points at the camera in the XZ plane.
    vec3 cam_world = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 to_cam = cam_world - anchor_world;
    // Drop Y component for Y-locked: rotate only around the vertical axis.
    vec3 to_cam_flat = vec3(to_cam.x, 0.0, to_cam.z);
    if (length(to_cam_flat) < 1e-4) {
        to_cam_flat = vec3(0.0, 0.0, 1.0);
    }
    vec3 facing_normal = normalize(to_cam_flat);
    vec3 up_world = vec3(0.0, 1.0, 0.0);
    vec3 facing_right = normalize(cross(up_world, facing_normal));

    // Static basis from the collector (used when face_camera < 1.0).
    vec3 static_right = MODEL_MATRIX[0].xyz / max(sx, 1e-6);
    vec3 static_up    = MODEL_MATRIX[1].xyz / max(sy, 1e-6);

    // Mix between the two bases by face_camera weight.
    vec3 right = mix(static_right, facing_right, face_camera);
    vec3 up    = mix(static_up,    up_world,     face_camera);

    // Wind sway: sin curve, only displaces vertices in the upper half of
    // the quad (UV.y > 0.5). Per-instance phase comes from INSTANCE_ID
    // so a meadow ripples instead of swaying in lock-step.
    float phase = float(INSTANCE_ID) * 0.7137;
    float wind  = sin(TIME * wind_frequency + phase) * wind_amplitude;
    // Top half of the quad gets full wind; smooth transition over the
    // middle so the quad bends rather than snapping.
    float wind_mask = smoothstep(0.4, 1.0, UV.y);

    // QuadMesh local vertices are in -0.5..0.5 on X/Y. Build the world
    // position from anchor + right*x*scale + up*y*scale + wind on top.
    vec3 local = vec3(VERTEX.x * sx + wind * wind_mask,
                      VERTEX.y * sy,
                      0.0);
    vec3 world_pos = anchor_world + right * local.x + up * local.y;
    POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(world_pos, 1.0));
    NORMAL = normalize(cross(right, up));
}

void fragment() {
    vec4 c = texture(albedo_tex, UV) * COLOR;
    if (c.a < alpha_threshold) discard;
    ALBEDO = c.rgb;
    ALPHA = c.a;
    ROUGHNESS = roughness_value;
    METALLIC = 0.0;
}
