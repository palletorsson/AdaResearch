shader_type sky;

// A directional cloud sea far below the playable floors. Sky only: no false
// platforms, transparent layers or per-eye volumetric raymarching.
uniform sampler2D cloud_noise : repeat_enable, filter_linear_mipmap;
// Driven at 1 Hz by atmosphere.gd; a whole cycle takes twelve minutes.
// No TIME/POSITION dependency, so head movement never triggers a sky rebuild.
uniform float cycle_phase = 0.0;
uniform vec3 sun_direction = vec3(-0.484, 0.407, 0.775);
uniform float sun_strength = 1.0;
uniform vec3 rose_zenith : source_color = vec3(0.557, 0.345, 0.706);
uniform vec3 violet_zenith : source_color = vec3(0.365, 0.275, 0.643);
uniform vec3 rose_horizon : source_color = vec3(0.957, 0.722, 0.839);
uniform vec3 violet_horizon : source_color = vec3(0.769, 0.604, 0.902);
uniform vec3 rose_shadow : source_color = vec3(0.616, 0.471, 0.686);
uniform vec3 violet_shadow : source_color = vec3(0.435, 0.412, 0.667);
uniform vec3 rose_light : source_color = vec3(1.0, 0.941, 0.937);
uniform vec3 violet_light : source_color = vec3(0.918, 0.875, 0.984);

void sky() {
	vec3 direction = normalize(EYEDIR);
	float violet = 0.5 - 0.5 * cos(cycle_phase);
	vec3 zenith = mix(rose_zenith, violet_zenith, violet);
	vec3 horizon = mix(rose_horizon, violet_horizon, violet);
	vec3 cloud_shadow = mix(rose_shadow, violet_shadow, violet);
	vec3 cloud_light = mix(rose_light, violet_light, violet);
	// A small circular translation closes without a jump at the cycle boundary.
	vec2 drift = vec2(sin(cycle_phase), cos(cycle_phase) - 1.0) * 0.065;
	float elevation = max(direction.y, 0.0);
	vec3 colour = mix(horizon, zenith, pow(elevation, 0.55));
	float sun_facing = max(dot(direction, normalize(sun_direction)), 0.0);
	colour += vec3(0.32, 0.15, 0.20) * pow(sun_facing, 18.0) * sun_strength;
	colour += vec3(1.8, 1.35, 1.20) * smoothstep(0.9995, 0.9998, sun_facing) * sun_strength;
	if (direction.y < 0.0) {
		// Perspective compression makes the clouds recede towards the horizon.
		vec2 plane = direction.xz / max(-direction.y, 0.025) * 0.09 + drift;
		float broad = texture(cloud_noise, plane).r;
		float detail = texture(cloud_noise, plane * 3.1 - drift * 0.6 + vec2(0.36, 0.71)).r;
		float fine = texture(cloud_noise, plane * 8.3 + vec2(0.81, 0.23)).r;
		float billow = broad * 0.65 + detail * 0.23 + fine * 0.12;
		float lit_side = texture(cloud_noise, plane + vec2(-0.012, 0.018)).r;
		float volume = clamp(0.2 + smoothstep(0.27, 0.73, billow) * 0.65 + (broad - lit_side) * 1.2, 0.1, 0.95);
		vec3 clouds = mix(cloud_shadow, cloud_light, volume);
		colour = mix(colour, clouds, smoothstep(0.015, 0.18, -direction.y));
	} else {
		// A few thin high clouds; the larger cloud mass remains beneath us.
		vec2 upper = direction.xz / max(direction.y, 0.12) * 0.1;
		float wisp = smoothstep(0.54, 0.78, texture(cloud_noise, upper * vec2(0.4, 1.8) + drift * 0.35).r);
		colour = mix(colour, cloud_light, wisp * 0.24 * smoothstep(0.03, 0.2, direction.y));
	}
	COLOR = colour;
}
