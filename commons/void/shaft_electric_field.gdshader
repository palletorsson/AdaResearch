shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
uniform vec4 field_colour : source_color = vec4(1.0,0.25,0.62,0.48);
void fragment() {
    vec2 p=UV*vec2(10.0,12.0);
    vec2 g=abs(fract(p)-0.5);
    float grid=1.0-smoothstep(0.025,0.065,min(g.x,g.y));
    float edge=1.0-smoothstep(0.01,0.04,min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y)));
    float pulse=0.7+0.3*sin(TIME*3.0-p.x*1.7-p.y*1.1);
    float arc=pow(max(0.0,sin((UV.x+UV.y)*42.0-TIME*4.0)),18.0);
    ALBEDO=field_colour.rgb;
    EMISSION=field_colour.rgb*(0.3+grid*1.3+edge*2.0+arc*0.4);
    ALPHA=field_colour.a*(0.10+grid*0.65*pulse+edge*0.8+arc*0.12);
}
