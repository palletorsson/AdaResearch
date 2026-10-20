shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float amount : hint_range(0.0,1.0) = 0.0;
void fragment() {
    vec3 sharp=textureLod(screen_texture,SCREEN_UV,0.0).rgb;
    vec3 soft=textureLod(screen_texture,SCREEN_UV,amount*5.0).rgb;
    COLOR=vec4(mix(sharp,soft,min(amount*8.0,1.0)),1.0);
}
