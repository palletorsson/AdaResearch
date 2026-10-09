shader_type spatial;
render_mode unshaded;
varying vec4 ink;
void vertex() { ink = COLOR; }
void fragment() {
    ALBEDO = ink.rgb;
    EMISSION = ink.rgb * 2.0;
}
