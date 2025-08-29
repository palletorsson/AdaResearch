shader_type spatial;
// Render back-faces first to establish the ray's exit point, then front-faces.
render_mode cull_front, depth_draw_opaque, unshaded;

// --- Cloud Shape & Density ---
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.25;
uniform float noise_scale : hint_range(0.1, 5.0) = 0.6;
uniform float time_scale : hint_range(0.0, 0.5) = 0.15;
uniform float absorption : hint_range(0.0, 2.0) = 0.15;
uniform float density : hint_range(0.1, 3.0) = 3.0;

// --- Lighting & Color ---
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.5, 0.6, 0.8, 1.0);
uniform float light_steps : hint_range(1, 16) = 8.0;
uniform float light_absorption : hint_range(0.0, 2.0) = 0.1;

// --- Ray Marching ---
uniform int march_steps = 64;
uniform vec3 volume_size = vec3(1.0, 1.0, 1.0);

// --- Dynamic Uniforms (set from GDScript) ---
uniform vec3 camera_position;
uniform vec3 sun_direction;

// Varyings to pass ray information from vertex to fragment shader
varying vec3 v_ray_origin;
varying vec3 v_ray_direction;
varying vec3 v_world_position;

// --- 3D Simplex Noise Function (standard implementation) ---
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289(((x*34.0)+1.0)*x); }
vec4 taylor_inv_sqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }
float snoise(vec3 v) {
	const vec2 C = vec2(1.0/6.0, 1.0/3.0);
	const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
	vec3 i  = floor(v + dot(v, C.yyy));
	vec3 x0 = v - i + dot(i, C.xxx);
	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0 - g;
	vec3 i1 = min(g.xyz, l.zxy);
	vec3 i2 = max(g.xyz, l.zxy);
	vec3 x1 = x0 - i1 + C.xxx;
	vec3 x2 = x0 - i2 + C.yyy;
	vec3 x3 = x0 - D.yyy;
	i = mod289(i);
	vec4 p = permute(permute(permute(
			 i.z + vec4(0.0, i1.z, i2.z, 1.0))
		   + i.y + vec4(0.0, i1.y, i2.y, 1.0))
		   + i.x + vec4(0.0, i1.x, i2.x, 1.0));
	float n_ = 0.142857142857;
	vec3  ns = n_ * D.wyz - D.xzx;
	vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
	vec4 x_ = floor(j * ns.z);
	vec4 y_ = floor(j - 7.0 * x_);
	vec4 x = x_ * ns.x + ns.yyyy;
	vec4 y = y_ * ns.x + ns.yyyy;
	vec4 h = 1.0 - abs(x) - abs(y);
	vec4 b0 = vec4(x.xy, y.xy);
	vec4 b1 = vec4(x.zw, y.zw);
	vec4 s0 = floor(b0)*2.0 + 1.0;
	vec4 s1 = floor(b1)*2.0 + 1.0;
	vec4 sh = -step(h, vec4(0.0));
	vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
	vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww;
	vec3 p0 = vec3(a0.xy,h.x);
	vec3 p1 = vec3(a0.zw,h.y);
	vec3 p2 = vec3(a1.xy,h.z);
	vec3 p3 = vec3(a1.zw,h.w);
	vec4 norm = taylor_inv_sqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
	p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;
	vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
	m = m * m;
	return 42.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}

// --- Fractional Brownian Motion (FBM) ---
// Stacks multiple layers of noise (octaves) to create complex, cloud-like patterns.
float fbm(vec3 p) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	for (int i = 0; i < 4; i++) {
		value += amplitude * snoise(p * frequency);
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

// --- Density Function ---
// Defines the shape and density of the cloud at any given point in space.
float sample_density(vec3 pos) {
	vec3 animated_pos = pos + vec3(0.0, 0.0, TIME * time_scale);
	float noise = fbm(animated_pos * noise_scale);
	
	// Remap noise to create more cloud-like shapes
	float density_val = (noise - cloud_cover);
	
	// Add a soft falloff at the edges of the volume
	density_val -= length(pos * 1.5) - 1.0;

	return max(0.0, density_val) * density;
}

// --- Light Marching ---
// Marches a ray from a point inside the cloud towards the sun to see how much light it receives.
float march_light(vec3 pos, vec3 light_dir) {
	float light_step_size = length(volume_size) / light_steps;
	float transmittance = 1.0;
	
	for (float i = 1.0; i < light_steps; i += 1.0) {
		vec3 sample_pos = pos + light_dir * light_step_size * i;
		float density_val = sample_density(sample_pos);
		if (density_val > 0.0) {
			transmittance *= exp(-density_val * light_absorption * light_step_size);
		}
		if (transmittance < 0.01) break;
	}
	return transmittance;
}

void vertex() {
	// Pass the world-space vertex position to the fragment shader
	v_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Calculate the ray origin (camera position) and direction for this fragment
	v_ray_origin = (inverse(MODEL_MATRIX) * vec4(camera_position, 1.0)).xyz;
	v_ray_direction = normalize(VERTEX - v_ray_origin);
}

void fragment() {
	// Since we render the back-faces first, the fragment's world position
	// is the ray's exit point from the cube.
	vec3 ray_exit_point = v_world_position;
	
	// Determine the ray's entry point by intersecting it with the cube.
	// This is simplified; a robust solution would use a full intersection test.
	vec3 inv_dir = 1.0 / v_ray_direction;
	vec3 t_min = (-volume_size * 0.5 - v_ray_origin) * inv_dir;
	vec3 t_max = (volume_size * 0.5 - v_ray_origin) * inv_dir;
	vec3 t1 = min(t_min, t_max);
	vec3 t2 = max(t_min, t_max);
	float t_near = max(max(t1.x, t1.y), t1.z);
	float t_far = min(min(t2.x, t2.y), t2.z);
	
	if (t_near >= t_far) {
		discard;
	}
	
	vec3 ray_entry_point = v_ray_origin + v_ray_direction * t_near;
	
	// Calculate ray length and step size
	float ray_length = distance(ray_entry_point, ray_exit_point);
	float step_size = ray_length / float(march_steps);
	
	vec4 final_color = vec4(0.0);

	// --- Main Ray Marching Loop ---
	for (int i = 0; i < march_steps; i++) {
		vec3 current_pos = ray_entry_point + v_ray_direction * step_size * float(i);
		
		// Get the density at the current position
		float density_val = sample_density(current_pos);
		
		if (density_val > 0.01) {
			// Calculate how much light reaches this point
			float light_transmittance = march_light(current_pos, sun_direction);
			vec3 lit_color = mix(shadow_color.rgb, base_color.rgb, light_transmittance);

			// Accumulate color and alpha based on density
			float alpha = 1.0 - exp(-density_val * absorption * step_size);
			final_color.rgb += lit_color * alpha * (1.0 - final_color.a);
			final_color.a += alpha * (1.0 - final_color.a);
		}
		
		// Early exit if the color is fully opaque
		if (final_color.a > 0.99) {
			break;
		}
	}
	
	if (final_color.a < 0.01) {
		discard;
	}

	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
	
	// Add emission for better visibility
	EMISSION = final_color.rgb * 0.4;
}
