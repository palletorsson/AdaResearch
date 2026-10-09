shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
varying vec4 ink;
void vertex() {
    ink = COLOR;
    // Camera-facing stamps keep their world size. They imply a volume by accumulation.
    vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
    MODELVIEW_MATRIX[0] *= scale.x;
    MODELVIEW_MATRIX[1] *= scale.y;
    MODELVIEW_MATRIX[2] *= scale.z;
}
void fragment() {
    float r = length(UV * 2.0 - 1.0);
    float falloff = exp(-4.0 * r * r) * (1.0 - smoothstep(0.65, 1.0, r));
    ALBEDO = ink.rgb;
    ALPHA = 0.105 * falloff * ink.a;
}
