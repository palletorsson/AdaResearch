shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform sampler2D camera_frame : source_color, filter_linear, repeat_disable;
uniform vec3 channel = vec3(1,0,0);
void fragment() { ALBEDO=texture(camera_frame,UV).rgb*channel; ALPHA=1.0; }
