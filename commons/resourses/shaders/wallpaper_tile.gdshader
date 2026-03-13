shader_type spatial;

// Wallpaper Tile Shader -- GPU implementation of all 17 wallpaper groups
//
// Tiles a fundamental domain texture across a surface using mathematically
// correct plane symmetry operations. Direct port of WallpaperGroups.gd
// to GLSL for real-time GPU rendering.
//
// The domain_texture is the small pattern tile. The shader repeats and
// transforms it according to the selected wallpaper group.

render_mode blend_mix, cull_back;

// Domain texture -- the fundamental tile to repeat
uniform sampler2D domain_texture : source_color, filter_linear, repeat_disable;

// Which wallpaper group (0-16): P1,P2,PM,PG,CM,PMM,PMG,PGG,CMM,P4,P4M,P4G,P3,P3M1,P31M,P6,P6M
uniform int wallpaper_group : hint_range(0, 16, 1) = 0;

// How many times the tile repeats across the UV space
uniform float tile_scale : hint_range(1.0, 32.0, 1.0) = 4.0;

// Grout / gap between tiles
uniform float grout_width : hint_range(0.0, 0.1) = 0.0;
uniform vec3 grout_color : source_color = vec3(0.1, 0.1, 0.1);
uniform float grout_softness : hint_range(0.0, 0.02) = 0.005;

// Material properties
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.0;

// Noise distortion for organic feel (opus vermiculatum style)
uniform float noise_distort : hint_range(0.0, 0.1) = 0.0;

// ── Aging & Weathering ──────────────────────────────────────────────
// Simulates centuries of wear on Roman/Italian mosaics and textiles.
// Each effect uses procedural noise to create natural-looking variation.

uniform float wear_amount : hint_range(0.0, 1.0) = 0.0;       // Edge erosion + surface scuffing
uniform float dust_amount : hint_range(0.0, 1.0) = 0.0;       // Accumulated dust/dirt in crevices
uniform vec3 dust_color : source_color = vec3(0.35, 0.30, 0.22); // Warm earth tone dust
uniform float fade_amount : hint_range(0.0, 1.0) = 0.0;       // UV/sun color fading (desaturation)
uniform float crack_density : hint_range(0.0, 1.0) = 0.0;     // Micro-fractures and crazing
uniform float stain_amount : hint_range(0.0, 1.0) = 0.0;      // Water/mineral staining
uniform vec3 stain_color : source_color = vec3(0.45, 0.38, 0.25); // Warm patina stain
uniform float chip_amount : hint_range(0.0, 1.0) = 0.0;       // Missing tesserae / chipped areas
uniform vec3 chip_color : source_color = vec3(0.25, 0.22, 0.18); // Exposed substrate

// -- Helpers --

// Integer modulo that always returns non-negative (like GDScript posmod)
int imod(int x, int m) {
	return ((x % m) + m) % m;
}

// Float modulo, always non-negative
float fmod_pos(float x, float m) {
	return mod(mod(x, m) + m, m);
}

// Simple hash for noise
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// Value noise for subtle distortion
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // smoothstep
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion -- layered noise for natural-looking variation
float fbm(vec2 p, int octaves) {
	float sum = 0.0;
	float amp = 0.5;
	float freq = 1.0;
	for (int i = 0; i < 6; i++) {
		if (i >= octaves) break;
		sum += value_noise(p * freq) * amp;
		freq *= 2.0;
		amp *= 0.5;
	}
	return sum;
}

// Voronoi distance -- for crack patterns
float voronoi_cracks(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float min_dist = 1.0;
	float second_dist = 1.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 point = vec2(hash21(i + neighbor), hash21(i + neighbor + vec2(37.0, 17.0)));
			float d = length(neighbor + point - f);
			if (d < min_dist) {
				second_dist = min_dist;
				min_dist = d;
			} else if (d < second_dist) {
				second_dist = d;
			}
		}
	}
	// Edge distance (thin lines where cells meet)
	return second_dist - min_dist;
}

// -- Core: apply wallpaper group symmetry to get domain UV --
// Returns the UV coordinate within the fundamental domain [0,1]x[0,1]

vec2 get_symmetric_uv(vec2 uv, int group) {
	// Scale to tile space
	vec2 st = uv * tile_scale;

	// Tile indices (which tile are we in?)
	int tile_x = int(floor(st.x));
	int tile_y = int(floor(st.y));

	// Local coordinates within tile [0,1)
	vec2 local = fract(st);

	// Apply symmetry based on group
	// Groups 0-16: P1,P2,PM,PG,CM,PMM,PMG,PGG,CMM,P4,P4M,P4G,P3,P3M1,P31M,P6,P6M

	if (group == 0) {
		// P1: Translation only -- no transform needed
		// local stays as-is

	} else if (group == 1) {
		// P2: 180 degree rotation at alternating tiles
		if (imod(tile_x + tile_y, 2) == 1) {
			local = vec2(1.0 - local.x, 1.0 - local.y);
		}

	} else if (group == 2) {
		// PM: Mirror in X direction
		if (imod(tile_x, 2) == 1) {
			local.x = 1.0 - local.x;
		}

	} else if (group == 3) {
		// PG: Glide reflection (mirror + half shift)
		if (imod(tile_x, 2) == 1) {
			local.x = 1.0 - local.x;
			local.y = fract(local.y + 0.5);
		}

	} else if (group == 4) {
		// CM: Centered mirror + glide
		if (imod(tile_x, 2) == 1) {
			local.x = 1.0 - local.x;
		}
		if (imod(tile_x + tile_y, 2) == 1) {
			local.y = fract(local.y + 0.5);
		}

	} else if (group == 5) {
		// PMM: Double mirror (perpendicular)
		if (imod(tile_x, 2) == 1) {
			local.x = 1.0 - local.x;
		}
		if (imod(tile_y, 2) == 1) {
			local.y = 1.0 - local.y;
		}

	} else if (group == 6) {
		// PMG: Mirror X + Glide Y + 180 degree rotation
		if (imod(tile_x, 2) == 1) {
			local.x = 1.0 - local.x;
		}
		if (imod(tile_y, 2) == 1) {
			local.x = 1.0 - local.x;
			local.y = 1.0 - local.y;
			local.y = fract(local.y + 0.5);
		}

	} else if (group == 7) {
		// PGG: Double glide + 180 degree rotation
		if (imod(tile_x, 2) == 1) {
			local.x = 1.0 - local.x;
			local.y = fract(local.y + 0.5);
		}
		if (imod(tile_y, 2) == 1) {
			local.y = 1.0 - local.y;
			local.x = fract(local.x + 0.5);
		}

	} else if (group == 8) {
		// CMM: Centered double mirror
		if (imod(tile_x, 2) == 1) {
			local.x = 1.0 - local.x;
		}
		if (imod(tile_y, 2) == 1) {
			local.y = 1.0 - local.y;
		}
		if (imod(tile_x + tile_y, 2) == 1) {
			local = fract(local + vec2(0.5));
		}

	} else if (group == 9) {
		// P4: 90 degree rotation
		int rotation = imod(tile_x + tile_y * 2, 4);
		for (int i = 0; i < 4; i++) {
			if (i >= rotation) break;
			float new_x = 1.0 - local.y;
			float new_y = local.x;
			local = vec2(new_x, new_y);
		}

	} else if (group == 10) {
		// P4M: 90 degree rotation + diagonal mirrors
		int rotation = imod(tile_x + tile_y, 4);
		for (int i = 0; i < 4; i++) {
			if (i >= rotation) break;
			float new_x = 1.0 - local.y;
			float new_y = local.x;
			local = vec2(new_x, new_y);
		}
		// Diagonal mirror
		if (imod(tile_x, 2) == 1) {
			float temp = local.x;
			local.x = local.y;
			local.y = temp;
		}

	} else if (group == 11) {
		// P4G: 90 degree rotation + off-center mirrors
		int rotation = imod(tile_x + tile_y, 4);
		for (int i = 0; i < 4; i++) {
			if (i >= rotation) break;
			float new_x = 1.0 - local.y;
			float new_y = local.x;
			local = vec2(new_x, new_y);
		}
		if (imod(tile_x + tile_y, 2) == 1) {
			local = vec2(1.0 - local.x, 1.0 - local.y);
		}

	} else if (group == 12) {
		// P3: 120 degree rotation (triangular lattice)
		int region = imod(tile_x + tile_y * 2, 3);
		if (region > 0) {
			float angle = float(region) * 2.0943951; // 2*PI/3
			vec2 centered = local - vec2(0.5);
			float ca = cos(angle);
			float sa = sin(angle);
			centered = vec2(centered.x * ca - centered.y * sa,
							centered.x * sa + centered.y * ca);
			local = centered + vec2(0.5);
		}

	} else if (group == 13 || group == 14) {
		// P3M1 (13) / P31M (14): 120 degree rotation + mirrors
		int region = imod(tile_x + tile_y, 6);
		float angle = float(region) * 1.0471976; // PI/3
		if (angle > 0.001) {
			vec2 centered = local - vec2(0.5);
			float ca = cos(angle);
			float sa = sin(angle);
			centered = vec2(centered.x * ca - centered.y * sa,
							centered.x * sa + centered.y * ca);
			local = centered + vec2(0.5);
		}
		// Mirror for P3M1
		if (group == 13 && imod(region, 2) == 1) {
			local.x = 1.0 - local.x;
		}

	} else if (group == 15) {
		// P6: 60 degree rotation (hexagonal)
		int region = imod(tile_x * 2 + tile_y, 6);
		float angle = float(region) * 1.0471976; // PI/3
		if (angle > 0.001) {
			vec2 centered = local - vec2(0.5);
			float ca = cos(angle);
			float sa = sin(angle);
			centered = vec2(centered.x * ca - centered.y * sa,
							centered.x * sa + centered.y * ca);
			local = centered + vec2(0.5);
		}

	} else if (group == 16) {
		// P6M: 60 degree rotation + all mirrors (highest symmetry)
		int region = imod(tile_x + tile_y * 3, 12);
		int rot = region % 6;
		bool do_mirror = region >= 6;

		if (rot > 0) {
			float angle = float(rot) * 1.0471976; // PI/3
			vec2 centered = local - vec2(0.5);
			float ca = cos(angle);
			float sa = sin(angle);
			centered = vec2(centered.x * ca - centered.y * sa,
							centered.x * sa + centered.y * ca);
			local = centered + vec2(0.5);
		}
		if (do_mirror) {
			float temp = local.x;
			local.x = local.y;
			local.y = temp;
		}
	}

	// Clamp to valid UV range using fract (handles negative from rotation)
	local = fract(abs(local));

	return local;
}

void fragment() {
	vec2 uv = UV;

	// Optional noise distortion for organic feel
	if (noise_distort > 0.001) {
		float nx = value_noise(uv * tile_scale * 8.0) * 2.0 - 1.0;
		float ny = value_noise(uv * tile_scale * 8.0 + vec2(100.0)) * 2.0 - 1.0;
		uv += vec2(nx, ny) * noise_distort;
	}

	// Get the symmetry-transformed UV within the domain
	vec2 domain_uv = get_symmetric_uv(uv, wallpaper_group);

	// Sample the domain texture
	vec3 color = texture(domain_texture, domain_uv).rgb;

	// Grout lines at tile boundaries
	float edge_dist = 1.0;
	if (grout_width > 0.001) {
		vec2 st = uv * tile_scale;
		vec2 f = fract(st);
		vec2 d = min(f, 1.0 - f);
		edge_dist = min(d.x, d.y);
		float grout_mask = 1.0 - smoothstep(grout_width - grout_softness, grout_width, edge_dist);
		color = mix(color, grout_color, grout_mask);
	}

	float final_roughness = roughness;

	// ── Aging & Weathering Effects ──────────────────────────────────

	// 1. WEAR -- edges erode first, high-traffic center wears smooth
	if (wear_amount > 0.001) {
		// Edge wear: tiles lose color near grout lines (mortar exposure)
		float edge_wear = smoothstep(0.08, 0.0, edge_dist) * wear_amount * 0.6;
		// Surface scuffing: broad random patches of lightening
		float scuff = fbm(uv * 12.0 + vec2(7.3, 2.1), 4);
		float scuff_mask = smoothstep(0.4, 0.7, scuff) * wear_amount * 0.4;
		// Combined wear lightens and desaturates
		float wear_total = clamp(edge_wear + scuff_mask, 0.0, 1.0);
		vec3 worn_color = mix(color, vec3(dot(color, vec3(0.3, 0.5, 0.2))) * 1.15, wear_total * 0.5);
		color = mix(color, worn_color, wear_total);
		// Worn areas are smoother (polished by traffic)
		final_roughness = mix(final_roughness, final_roughness * 0.6, wear_total);
	}

	// 2. DUST -- accumulates in grout lines and low spots
	if (dust_amount > 0.001) {
		// Dust in grout crevices
		float grout_dust = smoothstep(0.06, 0.0, edge_dist) * 0.7;
		// Scattered dust patches on surface
		float surface_dust = fbm(uv * 6.0 + vec2(42.0, 13.0), 3);
		surface_dust = smoothstep(0.35, 0.65, surface_dust) * 0.4;
		// Corner accumulation (dust gathers at edges of the overall surface)
		float corner_dust = (1.0 - smoothstep(0.0, 0.3, uv.x)) * (1.0 - smoothstep(0.0, 0.3, uv.y));
		corner_dust += (1.0 - smoothstep(0.7, 1.0, uv.x)) * (1.0 - smoothstep(0.7, 1.0, uv.y));
		corner_dust *= 0.3;

		float dust_total = clamp((grout_dust + surface_dust + corner_dust) * dust_amount, 0.0, 1.0);
		color = mix(color, dust_color, dust_total);
		// Dusty areas are matte
		final_roughness = mix(final_roughness, 1.0, dust_total * 0.5);
	}

	// 3. FADE -- sun/UV exposure desaturates and shifts warm
	if (fade_amount > 0.001) {
		// Non-uniform fading (some areas more exposed than others)
		float exposure = fbm(uv * 3.0 + vec2(99.0, 55.0), 3);
		exposure = smoothstep(0.3, 0.8, exposure);
		float fade = exposure * fade_amount;
		// Desaturate
		float lum = dot(color, vec3(0.299, 0.587, 0.114));
		vec3 faded = mix(color, vec3(lum), fade * 0.7);
		// Warm shift (sun-bleached yellowing)
		faded = mix(faded, faded * vec3(1.08, 1.02, 0.88), fade * 0.4);
		color = faded;
	}

	// 4. STAINS -- water/mineral deposits in organic blob shapes
	if (stain_amount > 0.001) {
		// Large organic blobs
		float stain_noise = fbm(uv * 4.0 + vec2(200.0, 77.0), 5);
		float stain_mask = smoothstep(0.55, 0.7, stain_noise) * stain_amount;
		// Ring patterns (water rings)
		float ring = sin(length(uv - vec2(0.3, 0.6)) * 30.0) * 0.5 + 0.5;
		ring *= smoothstep(0.3, 0.15, length(uv - vec2(0.3, 0.6)));
		stain_mask += ring * stain_amount * 0.3;
		stain_mask = clamp(stain_mask, 0.0, 1.0);
		color = mix(color, color * stain_color / max(stain_color, vec3(0.01)) * 0.7, stain_mask * 0.5);
		color = mix(color, stain_color, stain_mask * 0.3);
	}

	// 5. CRACKS -- voronoi-based micro-fractures
	if (crack_density > 0.001) {
		// Fine crack network
		float cracks = voronoi_cracks(uv * tile_scale * 4.0);
		float crack_line = 1.0 - smoothstep(0.0, 0.04 * (1.0 - crack_density * 0.8), cracks);
		// Larger structural cracks
		float big_cracks = voronoi_cracks(uv * 3.0 + vec2(55.0, 33.0));
		float big_line = 1.0 - smoothstep(0.0, 0.02, big_cracks);
		big_line *= smoothstep(0.3, 0.7, fbm(uv * 5.0, 3)); // Only in some areas
		float crack_total = clamp((crack_line * 0.6 + big_line * 0.8) * crack_density, 0.0, 1.0);
		// Cracks are dark lines
		color = mix(color, color * 0.2, crack_total);
		// Cracks increase roughness
		final_roughness = mix(final_roughness, 1.0, crack_total * 0.3);
	}

	// 6. CHIPS -- missing tesserae / chipped areas (expose substrate)
	if (chip_amount > 0.001) {
		float chip_noise = fbm(uv * tile_scale * 2.0 + vec2(300.0, 150.0), 4);
		// Chips happen near edges more often
		float edge_bias = smoothstep(0.06, 0.0, edge_dist) * 0.3;
		float chip_mask = smoothstep(0.7 - chip_amount * 0.3, 0.75, chip_noise + edge_bias);
		chip_mask *= chip_amount;
		color = mix(color, chip_color, chip_mask);
		// Chipped areas are rough
		final_roughness = mix(final_roughness, 0.95, chip_mask);
	}

	// ── Output ──────────────────────────────────────────────────────

	ALBEDO = color;
	ROUGHNESS = final_roughness;
	METALLIC = metallic;

	if (emission_strength > 0.001) {
		EMISSION = color * emission_strength;
	}
}
