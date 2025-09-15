shader_type spatial;
render_mode specular_schlick_ggx, cull_back;

// -------------------- Controls --------------------
uniform int pattern : hint_enum("Leopard,Tiger,Zebra,Dalmatian,Snake") = 0;

// Global look
uniform float scale = 3.0;            // overall tiling
uniform float warp = 0.45;            // noise warp amount for organic feel
uniform float contrast = 1.0;         // post contrast on pattern mask
uniform float normal_amount : hint_range(0.0, 1.0) = 0.35;

// PBR
uniform float rough = 0.75;
uniform float metallic_amt = 0.0;

// Colors (used differently per pattern)
uniform vec4 base_col   : source_color = vec4(0.95, 0.76, 0.35, 1.0); // e.g. tiger/leopard base (orange/sand)
uniform vec4 mark_col   : source_color = vec4(0.09, 0.07, 0.04, 1.0); // dark marks (black/brown)
uniform vec4 accent_col : source_color = vec4(0.10, 0.85, 0.22, 1.0); // e.g. snake alt / funky zebra

// Pattern-specific shaping
uniform float stripe_thickness = 0.55;   // tiger/zebra thickness (0..1)
uniform float stripe_curve = 1.2;        // higher => more sine curvature
uniform float spot_density = 1.25;       // leopard/dalmatian cell density multiplier
uniform float rosette_ring = 0.45;       // leopard ring thickness (0..1)
uniform float snake_scale_round = 0.65;  // scale roundness (0..1)
uniform float snake_checker = 0.25;      // alternating tint amount

// -------------------- Utilities --------------------
float hash21(vec2 p){
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

vec2 rot(vec2 p, float a){
    float c = cos(a), s = sin(a);
    return vec2(c*p.x - s*p.y, s*p.x + c*p.y);
}

// Cheap value noise
float vnoise(vec2 p){
    vec2 i = floor(p); vec2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    vec2 u = f*f*(3.0 - 2.0*f);
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

// FBM for organic warping
float fbm(vec2 p){
    float s = 0.0;
    float a = 0.5;
    for(int i=0;i<5;i++){
        s += a * vnoise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return s;
}

// Bump from a height field
vec3 fake_normal_from_height(float h){
    // screen-space derivatives; keep subtle for VR comfort
    float dX = dFdx(h);
    float dY = dFdy(h);
    vec3 n = normalize(vec3(-dX, 1.0/normal_amount, -dY));
    return n;
}

// Clamp & contrast helper for masks (0..1)
float shape_contrast(float x, float k){
    x = clamp(x, 0.0, 1.0);
    if (k == 1.0) return x;
    // simple power-curve contrast
    return pow(x, k);
}

// -------------------- Patterns --------------------

// 1) ZEBRA / TIGER stripes (share core math, different palettes & thresholds)
float stripes_mask(vec2 uv, float thickness, float bend){
    // Warp & bend
    float w = warp * (fbm(uv*1.2) - 0.5);
    uv.y += w * 0.8;
    uv.x += w * 0.35;

    // Sine field
    float s = 0.5 + 0.5 * sin(uv.y * 3.14159 * bend + fbm(uv*2.7)*2.3);
    // Thickness -> how much stays "dark"
    float m = smoothstep(thickness, thickness-0.15, s);
    return m;
}

// 2) DALMATIAN / LEOPARD via Voronoi-ish cells
// Returns: (edge_dist, center_dist, id_random)
vec3 vor_cells(vec2 uv){
    vec2 g = floor(uv);
    vec2 f = fract(uv);

    float md = 8.0;
    float cd = 8.0;
    float rid = 0.0;
    for(int y=-1;y<=1;y++){
        for(int x=-1;x<=1;x++){
            vec2 o = vec2(float(x), float(y));
            vec2 p = g + o;
            vec2 rnd = vec2(hash21(p), hash21(p+1.23));
            vec2 c = o + rnd*0.8; // jitter
            float d = distance(f, c);
            if(d < md){ md = d; rid = hash21(p+7.77); }
            // closest to true center for ring mask comparison
            if(d < cd){ cd = d; }
        }
    }
    // edge approx (distance to border between cells) by sampling neighbor min
    float edge = md;
    return vec3(edge, cd, rid);
}

vec3 dalmatian_colors(vec2 uv){
    vec2 suv = uv * spot_density;
    vec3 v = vor_cells(suv);

    // Big, irregular black spots on white
    float spot = smoothstep(0.35, 0.25, v.y); // center radius
    // Slight variation in edges
    spot *= smoothstep(0.06, 0.09, v.x);

    float m = shape_contrast(spot, contrast);
    vec3 col = mix(mark_col.rgb, vec3(1.0), 1.0 - m);
    return col;
}

vec3 leopard_colors(vec2 uv){
    vec2 suv = uv * spot_density * 1.35;
    vec3 v = vor_cells(suv);

    // Rosettes: ring where center is light, ring is dark
    float center = smoothstep(0.25, 0.18, v.y);
    float ring    = smoothstep(rosette_ring+0.12, rosette_ring, v.y)
                  * smoothstep(0.06, 0.10, v.x);

    float dark = clamp(ring * (1.0 - center), 0.0, 1.0);
    // Sand base, dark ring, lighter inner
    vec3 col = base_col.rgb;
    col = mix(col, mark_col.rgb, dark);
    col = mix(col, base_col.rgb * 1.02, center*0.5);
    return col;
}

// 3) SNAKE / SCALES (hex/diamond-ish tiling)
vec3 snake_colors(vec2 uv){
    // Skew to a hex grid
    mat2 skew = mat2(vec2(1.0, 0.0),      // first column
                 vec2(0.5, 0.8660254)); // second column
	uv = skew * uv;
    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv);

    // center of each "scale"
    float d = length(gv);
    float r = mix(0.45, 0.62, snake_scale_round);
    float edge = smoothstep(r, r-0.08, d);

    // gentle height for fake normal
    float height = smoothstep(r, r-0.2, d) * 0.6 + fbm(id*0.8)*0.1;

    // alternating tint per cell for natural variation
    float alt = step(0.5, fract(hash21(id*1.73)*2.0));
    vec3 a = mix(base_col.rgb, accent_col.rgb, snake_checker);
    vec3 b = mix(base_col.rgb*0.8, mark_col.rgb*0.6, snake_checker*0.5);
    vec3 col = mix(a, b, alt);

    // darken toward scale edge
    col *= mix(1.0, 0.55, edge);
    // tiny speckle
    col *= 0.95 + 0.05*fbm(uv*2.5);

    

    return col;
}

// -------------------- Main --------------------
void fragment(){
    // Prepare UV with organic warp
    vec2 uv = UV * scale;
    float w = warp * (fbm(uv*1.5) - 0.5);
    uv += vec2(w, w*0.7);

    vec3 albedo;

    if (pattern == 0){ // Leopard
        albedo = leopard_colors(uv);
    } else if (pattern == 1){ // Tiger
        float m = stripes_mask(uv*vec2(1.0, 0.8), stripe_thickness, stripe_curve);
        // Tiger: orange base with dark stripes, a bit of warm noise
        vec3 base = base_col.rgb * (0.95 + 0.05*fbm(uv*2.0));
        albedo = mix(mark_col.rgb, base, 1.0 - shape_contrast(m, contrast));
    } else if (pattern == 2){ // Zebra
        float m = stripes_mask(uv, stripe_thickness, stripe_curve*1.6);
        // Zebra: high-contrast black/white (accent tint optional)
        vec3 whiteish = mix(vec3(1.0), accent_col.rgb, 0.0); // keep white by default
        albedo = mix(mark_col.rgb, whiteish, 1.0 - shape_contrast(m, max(contrast, 1.3)));
    } else if (pattern == 3){ // Dalmatian
        albedo = dalmatian_colors(uv);
    } else { // Snake
        albedo = snake_colors(uv);
    }

    ALBEDO = albedo;
    ROUGHNESS = clamp(rough, 0.02, 1.0);
    METALLIC = clamp(metallic_amt, 0.0, 1.0);
}
