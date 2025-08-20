shader_type spatial;
render_mode unshaded;

// Metaball parameters - can be controlled from GDScript
uniform vec4 metaball_positions[5]; // xyz = position, w = radius
uniform float metaball_strengths[5];
uniform float blend_factor = 0.4;
uniform vec3 metaball_color = vec3(0.2, 0.6, 1.0);

// Lighting parameters
uniform vec3 light_direction = vec3(1.0, 0.0, 1.0);

void vertex() {
    UV = UV;
    NORMAL = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

// Smoothing version Boolean (same as your smin function)
float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * h * k * (1.0 / 6.0);
}

// Sphere SDF (signed distance function)
float sdSphere(vec3 p, vec3 center, float radius) {
    return length(p - center) - radius;
}

// Map function to calculate distance to the scene
float map(vec3 p) {
    // Start with a large value
    float dist = 100.0;
    
    // Blend all metaballs together
    for (int i = 0; i < 5; i++) {
        vec3 center = metaball_positions[i].xyz;
        float radius = metaball_positions[i].w;
        float strength = metaball_strengths[i];
        
        // Scale radius by strength
        radius *= strength;
        
        // Get distance to this metaball
        float sphere_dist = sdSphere(p, center, radius);
        
        // Blend with the current distance
        dist = smin(dist, sphere_dist, blend_factor);
    }
    
    return dist;
}

// Calculate normal using gradient of the distance field
vec3 calcNormal(vec3 p) {
    float epsilon = 0.001;
    vec3 n;
    
    // Sample the distance function in each axis direction
    n.x = map(p + vec3(epsilon, 0.0, 0.0)) - map(p - vec3(epsilon, 0.0, 0.0));
    n.y = map(p + vec3(0.0, epsilon, 0.0)) - map(p - vec3(0.0, epsilon, 0.0));
    n.z = map(p + vec3(0.0, 0.0, epsilon)) - map(p - vec3(0.0, 0.0, epsilon));
    
    return normalize(n);
}

void fragment() {
    vec2 uv = UV;
    uv = (uv - 0.5) * 2.0; // Set UV Origin 0,0 to center
    
    // Fragment World Position
    vec3 world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    // Initial Ray Marching Setup
    vec3 ro = CAMERA_POSITION_WORLD; // Ray Origin (using built-in variable)
    vec3 rd = normalize(world_position - ro);
    vec3 col = vec3(0);
    
    float t = 0.0; // Total distance travelled
    
    // Ray Marching
    float alpha = 1.0;
    vec3 p;
    bool hit = false;
    
    for (int i = 0; i < 80; i++) {
        p = ro + (rd * t); // Position along the ray
        
        float d = map(p); // current distance to the scene
        t += d;
        
        // Check for hit or max distance
        if (d < 0.001) {
            hit = true;
            break;
        }
        if (t > 20.0) {
            alpha = 0.0;
            break;
        }
    }
    
    if (hit) {
        // Calculate lighting for hit point
        vec3 normal = calcNormal(p);
        vec3 light_dir = normalize(light_direction);
        
        // Calculate diffuse lighting
        float diff = max(dot(normal, light_dir), 0.0);
        vec3 diffuse = diff * metaball_color;
        
        // Add ambient lighting
        vec3 ambient = metaball_color * 0.2;
        
        // Calculate specular highlight
        vec3 reflect_dir = reflect(-light_dir, normal);
        vec3 view_dir = normalize(ro - p);
        float spec = pow(max(dot(view_dir, reflect_dir), 0.0), 32.0);
        vec3 specular = vec3(0.5) * spec;
        
        // Combine lighting components
        col = ambient + diffuse + specular;
        
        // Add depth-based shading for more visual interest
        col = mix(col, col * 0.6, clamp(t * 0.05, 0.0, 0.4));
    } else {
        // No hit, make transparent
        alpha = 0.0;
        discard;
    }
    
    ALBEDO = col;
    ALPHA = alpha;
}