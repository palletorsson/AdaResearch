shader_type spatial;

uniform float stripe_width = 0.2;
uniform float speed = 0.02;
uniform vec4 color_red = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 color_white = vec4(1.0, 1.0, 1.0, 1.0);
uniform float stripe_angle_degrees = 4.0;

void fragment(){
    float angle = radians(stripe_angle_degrees);
    mat2 rotation = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle),  cos(angle)));
    // We can pivot around the U component, for example
    vec2 uv_rotated = rotation * UV;
    float scroll = uv_rotated.y + TIME * speed;
    float stripe_phase = fract(scroll / stripe_width);

    vec4 final_color = (stripe_phase < 0.5) ? color_red : color_white;
    ALBEDO = final_color.rgb;
}
