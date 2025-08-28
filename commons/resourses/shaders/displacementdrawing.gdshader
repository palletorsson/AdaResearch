shader_type spatial;

uniform sampler2D displacement_map;  // Displacement map for height
uniform float displacement_strength = 0.1;  // Control how much displacement affects the mesh

void vertex() {
    // Get the UV coordinates of the current vertex
    vec2 uv = UV;

    // Sample the displacement map to get the height value
    float height = texture(displacement_map, uv).r;

    // Modify the Y position of the vertex based on the displacement map
    VERTEX.y += height * displacement_strength;
}
