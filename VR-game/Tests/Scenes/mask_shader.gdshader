shader_type canvas_item;

uniform sampler2D mask_texture;

void fragment() {
	vec4 mask_color = texture(mask_texture, UV);
     
     if (mask_color.a < 0.5) {
        COLOR.a = 0.0;
    }
}