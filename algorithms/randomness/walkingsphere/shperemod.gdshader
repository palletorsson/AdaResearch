shader_type spatial;
render_mode cull_disabled;

uniform int mode;
uniform float intensity;
uniform float smoothing;
uniform float iteration;
uniform float iterations;
uniform vec4 albedo_color = vec4(0.3, 0.7, 0.9, 1.0);

// Spike parameters
uniform float spike_count;
uniform float spike_length;
uniform float spike_taper;

// Random Walk parameters
uniform float walk_step_size;
uniform float walk_expansion_rate;
uniform float walk_direction_chaos;

// Hill Seeking parameters
uniform float hill_count;
uniform float hill_attraction_strength;
uniform float hill_influence_radius;

// Gaussian parameters
uniform float gaussian_count;
uniform float gaussian_amplitude;
uniform float gaussian_width;

// Noise parameters
uniform float noise_frequency;
uniform float noise_octaves;
uniform float noise_amplitude;

// CA parameters
uniform float ca_neighbor_threshold;
uniform float ca_growth_rate;

// Hash-based random functions for the GPU
vec2 hash22(vec2 p) {
    p = fract(p * vec2(5.315, 6.745));
    p += dot(p.xy, p.yx + 2.135);
    return fract(vec2(p.x * p.y, p.x + p.y));
}

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

// Simple noise function (based on position)
float snoise(vec3 p) {
	vec3 p1 = fract(p);
	vec3 p2 = p1 * p1 * (3.0 - 2.0 * p1);
	vec2 p3 = floor(p.xy) + floor(p.z) * 17.0;
	return mix(mix(mix(hash11(p3.x + p3.y), hash11(p3.x + p3.y + 1.0), p2.x),
	            mix(hash11(p3.x + p3.y + 17.0), hash11(p3.x + p3.y + 18.0), p2.x), p2.y),
	        mix(mix(hash11(p3.x + p3.y + 1.0), hash11(p3.x + p3.y + 2.0), p2.x),
	            mix(hash11(p3.x + p3.y + 18.0), hash11(p3.x + p3.y + 19.0), p2.x), p2.y), p2.z) * 2.0 - 1.0;
}

void vertex() {
	vec3 original_pos = VERTEX;
	vec3 new_pos = original_pos;
	
	// Debug: Add a simple test displacement to verify shader is working
	new_pos += original_pos * 0.5 * intensity;
	
	switch(mode) {
		case 0: { // Ordered Spikes
			// This mode cannot be easily translated to a vertex shader because
			// it requires knowing the location of a discrete number of "spikes"
			// and their influence on each vertex, which is a global calculation.
			// A reasonable approximation is to use a hash-based spike system.
			// For a more performant alternative, Ordered Spikes is better
			// implemented as an O(1) procedural algorithm on the CPU per vertex.
			// Reverting to the original GDScript functionality for this mode.
			new_pos = original_pos;
		} break;
		
		case 1: { // Random Spikes
			float random_factor = hash11(dot(original_pos, vec3(12.9898, 78.233, 37.797)) + iteration * 12345.0);
			if (random_factor > (1.0 - intensity)) {
				float spike_strength = pow((random_factor - (1.0 - intensity)) / intensity, spike_taper);
				float spike_extension = spike_strength * spike_length;
				new_pos += original_pos * spike_extension;
			}
		} break;
		
		case 2: { // Random Walk
			// Random walk is inherently a CPU-based, iterative process
			// that depends on the previous state. Simulating it in a shader
			// would require passing the state of each vertex from the previous frame.
			// For this demo, we'll use a noise-based displacement to create a similar feel.
			float noise_val = snoise(original_pos * 2.0 + vec3(iteration * 0.1)) * 0.5 + 0.5;
			float evolution_factor = iteration / iterations;
			new_pos += original_pos * noise_val * walk_step_size * evolution_factor * intensity;
			new_pos = mix(new_pos, original_pos, smoothing);
		} break;
		
		case 3: { // Hill Seeking
			// Hill seeking is also a CPU-based simulation, but we can fake it.
			// Pass the hill positions to the shader as uniforms.
			// For this demo, we will use a single hill at the top.
			vec3 peak = vec3(0.0, 1.5, 0.0);
			vec3 to_peak = peak - new_pos;
			float distance = length(to_peak);
			if (distance < hill_influence_radius) {
				float attraction = hill_attraction_strength / (distance * distance);
				float evolution_factor = iteration / iterations;
				new_pos += normalize(to_peak) * attraction * evolution_factor * intensity;
			}
		} break;
		
		case 4: { // Gaussian Bumps
			vec3 direction = normalize(original_pos);
			float total_displacement = 0.0;
			// For a GPU approach, we would need to pass multiple gaussian centers
			// as an array of uniforms, but for simplicity, we use one fixed one.
			vec3 center = vec3(1.0, 0.0, 0.0);
			float distance = distance(direction, center);
			float gaussian_value = exp(-distance * distance / (2.0 * gaussian_width * gaussian_width));
			total_displacement = gaussian_value * gaussian_amplitude;
			float evolution_factor = iteration / iterations;
			new_pos += direction * total_displacement * evolution_factor * intensity;
		} break;
		
		case 5: { // Noise Deformation
			vec3 direction = normalize(original_pos);
			float noise_value = 0.0;
			float amp = noise_amplitude;
			float freq = noise_frequency;
			for (int i = 0; i < int(noise_octaves); i++) {
				vec3 sample_pos = original_pos * freq + vec3(iteration * 0.1);
				noise_value += snoise(sample_pos) * amp;
				amp *= 0.5;
				freq *= 2.0;
			}
			float evolution_factor = iteration / iterations;
			new_pos += direction * noise_value * evolution_factor * intensity;
		} break;
		
		case 6: { // Cellular Automata
			// Cellular Automata is an iterative neighbor-based system and is
			// difficult to implement in a single-pass vertex shader.
			// It would require a compute shader to update states.
			// For a simplified effect, we use a noise-based pattern that evolves.
			float noise_val = snoise(original_pos * ca_growth_rate + vec3(iteration * 0.1));
			float evolution_factor = iteration / iterations;
			if (noise_val > ca_neighbor_threshold / 10.0) {
				new_pos += original_pos * (noise_val * evolution_factor * intensity * 0.1);
			} else {
				new_pos -= original_pos * (noise_val * evolution_factor * intensity * 0.1);
			}
		} break;
	}
	
	// Apply smoothing. A simple shader-based smoothing
	// is to blend back towards the original position.
	new_pos = mix(new_pos, original_pos, smoothing);
	
	VERTEX = new_pos;
	NORMAL = normalize(new_pos);
}

void fragment() {
	ALBEDO = albedo_color.rgb;
	EMISSION = albedo_color.rgb * 0.2;
}
