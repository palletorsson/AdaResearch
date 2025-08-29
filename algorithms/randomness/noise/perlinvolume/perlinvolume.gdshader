shader_type spatial;
// Render back-faces first, then front-faces, with alpha pre-pass for transparency.
render_mode cull_front, depth_draw_opaque;

uniform float time_scale = 0.2;
uniform float noise_scale = 1.5;
uniform float density = 1.2;
uniform int march_steps = 48;
uniform vec4 color1 : source_color = vec4(0.0, 0.4, 1.0, 1.0);
uniform vec4 color2 : source_color = vec4(0.4, 1.0, 1.0, 1.0);
uniform vec4 color3 : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Varyings to pass ray information from vertex to fragment shader
varying vec3 v_ray_origin;
varying vec3 v_ray_direction;

// --- 3D Simplex Noise Function ---
// A standard, high-quality noise function for 3D procedural textures.
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
	float n_ = 0.142857142857; // 1.0/7.0
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
// --- End Noise Function ---

// Function to calculate the intersection points of a ray with an AABB (the cube).
// The cube is centered at (0,0,0) with a size of 1.
vec2 ray_box_intersect(vec3 ray_origin, vec3 ray_dir) {
	vec3 box_min = vec3(-0.5);
	vec3 box_max = vec3(0.5);
	vec3 inv_dir = 1.0 / ray_dir;
	vec3 t_min_v = (box_min - ray_origin) * inv_dir;
	vec3 t_max_v = (box_max - ray_origin) * inv_dir;
	vec3 t1 = min(t_min_v, t_max_v);
	vec3 t2 = max(t_min_v, t_max_v);
	float t_min = max(max(t1.x, t1.y), t1.z);
	float t_max = min(min(t2.x, t2.y), t2.z);
	return vec2(t_min, t_max);
}

// Maps a noise value (0 to 1) to a color gradient.
vec4 colormap(float value) {
	vec3 col = mix(color1.rgb, color2.rgb, smoothstep(0.0, 0.6, value));
	col = mix(col, color3.rgb, smoothstep(0.6, 1.0, value));
	return vec4(col, value);
}

void vertex() {
	// Transform camera position and ray direction into the cube's local space.
	// This simplifies the intersection math in the fragment shader.
	v_ray_origin = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_ray_dir = normalize(world_vertex - CAMERA_POSITION_WORLD);
	v_ray_direction = (inverse(MODEL_MATRIX) * vec4(world_ray_dir, 0.0)).xyz;
}

void fragment() {
	// Find where the ray enters and exits the cube.
	vec2 intersection = ray_box_intersect(v_ray_origin, v_ray_direction);
	float t_min = intersection.x;
	float t_max = intersection.y;

	// If the ray doesn't hit the box, discard the pixel.
	if (t_min >= t_max) {
		discard;
	}
	
	// Clamp the start of the ray march to be inside the box and not behind the camera.
	t_min = max(t_min, 0.0);

	vec4 accumulated_color = vec4(0.0);
	float step_size = (t_max - t_min) / float(march_steps);

	// --- Ray Marching Loop ---
	// Step along the ray inside the cube.
	for (int i = 0; i < march_steps; i++) {
		float t = t_min + float(i) * step_size;
		
		// Get the current position along the ray.
		vec3 pos = v_ray_origin + v_ray_direction * t;
		
		// Sample the 3D noise at this position, animating it with time.
		vec3 noise_coord = pos * noise_scale + vec3(0.0, 0.0, TIME * time_scale);
		float noise_value = (snoise(noise_coord) + 1.0) * 0.5; // Remap noise to 0-1 range.
		
		// Map the noise value to a color and apply density.
		vec4 sample_color = colormap(noise_value);
		sample_color.a *= density * step_size;
		
		// Blend this sample with the accumulated color. This is "front-to-back" alpha blending.
		accumulated_color.rgb += sample_color.rgb * sample_color.a * (1.0 - accumulated_color.a);
		accumulated_color.a += sample_color.a * (1.0 - accumulated_color.a);
		
		// Early exit if the color is fully opaque.
		if (accumulated_color.a >= 0.99) {
			break;
		}
	}
	
	// Set the final pixel color and alpha.
	ALBEDO = accumulated_color.rgb;
	ALPHA = accumulated_color.a;
	
	// Add emission for better visibility
	EMISSION = accumulated_color.rgb * 0.3;
}
