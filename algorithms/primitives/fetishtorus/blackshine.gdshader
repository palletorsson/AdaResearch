shader_type spatial;

void fragment() {
    // Set the base color to black
    ALBEDO = vec3(0.0, 0.0, 0.0);
    
    // Set the roughness to a very low value for a shiny, reflective look
    ROUGHNESS = 0.01;
}