// res://materials/ColorCheckerFloor.shader
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque, specular_schlick_ggx;

/* -------- Controls -------- */
uniform float tile_size : hint_range(0.05, 5.0) = 0.60;
uniform float rotation_deg : hint_range(-180.0, 180.0) = 45.0;
uniform float grout : hint_range(0.0, 0.25) = 0.05;
uniform float edge_softness : hint_range(0.0, 0.2) = 0.015;
/* Gutter color is black by default */
uniform vec4 grout_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

/* This uniform is no longer used but left here to avoid breaking the material file */
uniform vec4 light_tile : source_color = vec4(0.90, 0.90, 0.90, 1.0);
/* This uniform is also no longer used */
uniform float inner_fill_mix : hint_range(0.0, 1.0) = 1.0;

/* palette selector */
uniform int preset = 0;

/* PBR */
uniform float metallic : hint_range(0.0, 1.0) = 0.02;
uniform float roughness : hint_range(0.0, 1.0) = 0.45;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.0;

/* -------- Varyings -------- */
varying vec3 v_world_pos;

/* -------- Helpers -------- */
float hash12(vec2 p){
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}
vec2 rot2d(vec2 p, float a){
    float c = cos(a), s = sin(a);
    return mat2(vec2(c,-s), vec2(s, c)) * p;
}
vec3 hsv2rgb(vec3 c){
    vec3 p = abs(fract(c.xxx + vec3(0.0, 1.0/3.0, 2.0/3.0))*6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p-1.0,0.0,1.0), c.y);
}
vec3 palette_color(int idx){
    if (preset == 0){
        const vec3 pal[6] = vec3[](
            vec3(0.95,0.25,0.60), vec3(0.28,0.75,0.95), vec3(0.45,0.90,0.50),
            vec3(0.95,0.60,0.20), vec3(0.55,0.45,0.95), vec3(0.15,0.70,0.80)
        ); return pal[idx % 6];
    } else if (preset == 1){
        const vec3 pal[5] = vec3[](
            vec3(1.00,0.10,0.60), vec3(0.15,0.85,1.00), vec3(0.00,0.95,0.70),
            vec3(1.00,0.80,0.20), vec3(0.55,0.10,0.95)
        ); return pal[idx % 5];
    } else {
        float h = fract(float(idx) * 0.61803398875);
        return hsv2rgb(vec3(h, 0.85, 0.95));
    }
}

/* -------- Stages -------- */
void vertex(){
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment(){
    vec2 p = v_world_pos.xz / max(tile_size, 1e-5);
    p = rot2d(p, radians(rotation_deg));

    vec2 cell = floor(p);
    vec2 uv   = fract(p);

    // This is the grout mask. It creates a value of 0.0 for the grout and 1.0 for the tile interior.
    float e = min(min(uv.x, 1.0-uv.x), min(uv.y, 1.0-uv.y));
    float gmask = smoothstep(grout, grout + edge_softness, e);

    // Get a unique color for each tile from the palette.
    int idx = int(mod(cell.x + cell.y * 7.0, 10000.0));
    vec3 tile_color = palette_color(idx + int(floor(hash12(cell) * 8.0)));
    
    // The old checkerboard logic has been removed.
    // Every tile now uses the palette_color directly.

    // Mix the grout color and the tile color using the mask.
    vec3 final_col = mix(grout_color.rgb, tile_color, gmask);

    ALBEDO    = final_col;
    METALLIC  = metallic;
    ROUGHNESS = roughness;
    EMISSION  = final_col * emission_strength;
}