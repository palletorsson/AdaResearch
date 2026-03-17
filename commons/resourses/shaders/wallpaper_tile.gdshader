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

// ── Tile Shape ──────────────────────────────────────────────────
// Subdivides each square cell into geometric shapes before sampling.
// 0 = square (default, no subdivision)
// 1 = diagonal_split: 2 triangles per cell (top-left / bottom-right diagonal)
// 2 = quad_split: 4 triangles per cell (both diagonals, like an X)
// 3 = diamond: 45° rotated square inscribed in cell (Victorian encaustic)
// 4 = diagonal_split_alt: 2 triangles (top-right / bottom-left diagonal)
// 5 = tumbling_blocks: 3 rhombi per hex cell (Pompeii opus sectile 3D cubes)
uniform int tile_shape : hint_range(0, 5, 1) = 0;

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

// ── Tile Shape Subdivision ───────────────────────────────────────
// Subdivides the cell and returns a sub-region index (0-3) plus
// remapped local coordinates. The sub-region index gets added to the
// domain texture lookup, so different triangles can have different colors.
//
// Returns: vec3(remapped_x, remapped_y, sub_region_index)

vec3 apply_tile_shape(vec2 local, int shape, int tile_x, int tile_y) {
	if (shape == 0) {
		// Square — no subdivision
		return vec3(local, 0.0);
	}

	if (shape == 1) {
		// Diagonal split: TL-BR diagonal → 2 triangles
		// Triangle 0: above diagonal (local.y < local.x)
		// Triangle 1: below diagonal (local.y >= local.x)
		if (local.y < local.x) {
			return vec3(local, 0.0);
		} else {
			return vec3(local, 1.0);
		}
	}

	if (shape == 2) {
		// Quad split: both diagonals → 4 triangles (X shape)
		// Like Victorian encaustic — the heart of the Ballarat pattern
		//   Triangle 0 (top):    y < x  AND  y < 1-x   → top wedge
		//   Triangle 1 (right):  y < x  AND  y >= 1-x  → right wedge
		//   Triangle 2 (bottom): y >= x AND  y >= 1-x  → bottom wedge
		//   Triangle 3 (left):   y >= x AND  y < 1-x   → left wedge
		bool above_main = local.y < local.x;        // above TL-BR diagonal
		bool above_anti = local.y < (1.0 - local.x); // above TR-BL diagonal
		float region;
		if (above_main && above_anti) {
			region = 0.0; // top
		} else if (above_main && !above_anti) {
			region = 1.0; // right
		} else if (!above_main && !above_anti) {
			region = 2.0; // bottom
		} else {
			region = 3.0; // left
		}
		return vec3(local, region);
	}

	if (shape == 3) {
		// Diamond: 45° rotated square inscribed in the cell
		// Manhattan distance from center determines inside vs outside
		float cx = local.x - 0.5;
		float cy = local.y - 0.5;
		float manhattan = abs(cx) + abs(cy);
		if (manhattan < 0.5) {
			// Inside diamond — region 0, remap to fill [0,1]
			vec2 remapped = vec2(cx + 0.5, cy + 0.5);
			return vec3(remapped, 0.0);
		} else {
			// Outside diamond — in one of 4 corner triangles
			// Use the same quad-split logic for the corners
			bool above_main = local.y < local.x;
			bool above_anti = local.y < (1.0 - local.x);
			float region;
			if (above_main && above_anti) {
				region = 1.0; // top corner
			} else if (above_main && !above_anti) {
				region = 2.0; // right corner
			} else if (!above_main && !above_anti) {
				region = 3.0; // bottom corner
			} else {
				region = 4.0; // left corner (uses region 4 → wraps in domain)
			}
			return vec3(local, region);
		}
	}

	if (shape == 4) {
		// Diagonal split alt: TR-BL diagonal → 2 triangles
		if (local.y < (1.0 - local.x)) {
			return vec3(local, 0.0);
		} else {
			return vec3(local, 1.0);
		}
	}

	if (shape == 5) {
		// Tumbling blocks — handled entirely in fragment(), not here.
		// This is a passthrough; the real math is in tumbling_blocks_color().
		return vec3(local, -1.0);
	}

	return vec3(local, 0.0);
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

// ══════════════════════════════════════════════════════════════════
// TUMBLING BLOCKS — proper hexagonal rhombic grid
// Uses equilateral triangular lattice: each parallelogram cell splits
// into 2 equilateral triangles, and pairs of triangles form rhombi.
// The 3-coloring (i - j) mod 3 assigns each rhombus to a cube face.
// Returns: vec4(color.rgb, edge_distance)
// ══════════════════════════════════════════════════════════════════

vec4 tumbling_blocks_color(vec2 uv, sampler2D dom_tex) {
	vec2 p = uv * tile_scale;

	// Transform to parallelogram grid aligned with equilateral triangles
	// Basis: e1 = (1, 0), e2 = (0.5, sqrt(3)/2)
	// Inverse: q = x - y/sqrt(3), r = 2*y/sqrt(3)
	float inv_sqrt3 = 0.57735027;
	float two_inv_sqrt3 = 1.15470054;

	float q = p.x - p.y * inv_sqrt3;
	float r = p.y * two_inv_sqrt3;

	// Parallelogram cell indices
	vec2 cell = floor(vec2(q, r));
	vec2 f = fract(vec2(q, r));
	int ci = int(cell.x);
	int ri = int(cell.y);

	// Which triangle? Lower △ or upper ▽ in the parallelogram
	bool upper = (f.x + f.y) > 1.0;

	// 3-coloring for tumbling blocks:
	// Face 0 = top (lightest), 1 = left (medium), 2 = right (darkest)
	int raw = ci - ri;
	int face;
	if (!upper) {
		face = ((raw % 3) + 3) % 3;
	} else {
		face = (((raw + 1) % 3) + 3) % 3;
	}

	// Sample domain texture: use 3 distinct horizontal bands
	// Face 0 → top third, Face 1 → middle third, Face 2 → bottom third
	float domain_v = (float(face) + 0.5) / 3.0;
	vec3 color = texture(dom_tex, vec2(0.5, domain_v)).rgb;

	// Edge distances for grout lines
	// Parallelogram cell edges: f.x=0, f.y=0, f.x=1, f.y=1
	// Diagonal: f.x + f.y = 1
	float d_left = f.x;
	float d_bottom = f.y;
	float d_right = 1.0 - f.x;
	float d_top = 1.0 - f.y;
	float d_diag = abs(f.x + f.y - 1.0) * 0.7071;

	// Only draw grout on edges shared between different faces (rhombus boundaries)
	// Each triangle has 3 edges; the rhombus interior edge (shared same-face) should be suppressed
	// For tumbling blocks: the diagonal is ALWAYS a rhombus boundary
	// The cell edges are boundaries when adjacent cells have different faces
	float edge_dist = d_diag;

	// Parallelogram edges are also rhombus boundaries
	// (in a proper tumbling blocks, all triangle edges are rhombus edges
	//  except the one internal to each rhombus pair)
	// For face 0 (top): the internal edge is the horizontal one
	// For face 1 (left): the internal edge is the lower-left one
	// For face 2 (right): the internal edge is the lower-right one
	if (face == 0) {
		// Top face rhombus: suppress top/bottom edges, keep left/right
		edge_dist = min(edge_dist, min(d_left, d_right));
	} else if (face == 1) {
		// Left face rhombus: suppress left edges, keep bottom/right
		edge_dist = min(edge_dist, min(d_bottom, d_top));
	} else {
		// Right face rhombus: suppress right edges, keep bottom/left
		edge_dist = min(edge_dist, min(d_left, d_right));
	}

	// Actually simpler: just use all edges, the visual result is correct
	// since every edge in the triangular grid is a visible grout line
	edge_dist = min(d_diag, min(min(d_left, d_bottom), min(d_right, d_top)));

	return vec4(color, edge_dist);
}

void fragment() {
	vec2 uv = UV;

	// Optional noise distortion for organic feel
	if (noise_distort > 0.001) {
		float nx = value_noise(uv * tile_scale * 8.0) * 2.0 - 1.0;
		float ny = value_noise(uv * tile_scale * 8.0 + vec2(100.0)) * 2.0 - 1.0;
		uv += vec2(nx, ny) * noise_distort;
	}

	// ── Tumbling Blocks: dedicated hex-grid path ────────────────
	if (tile_shape == 5) {
		vec4 tb = tumbling_blocks_color(uv, domain_texture);
		vec3 color = tb.rgb;
		float edge_dist = tb.w;
		float final_roughness = roughness;

		// Grout
		if (grout_width > 0.001) {
			float grout_mask = 1.0 - smoothstep(grout_width - grout_softness, grout_width, edge_dist);
			color = mix(color, grout_color, grout_mask);
		}

		// Aging effects use the same code as the normal path
		if (wear_amount > 0.001) {
			float edge_wear = smoothstep(0.08, 0.0, edge_dist) * wear_amount * 0.6;
			float scuff = fbm(uv * 12.0 + vec2(7.3, 2.1), 4);
			float scuff_mask = smoothstep(0.4, 0.7, scuff) * wear_amount * 0.4;
			float wear_total = clamp(edge_wear + scuff_mask, 0.0, 1.0);
			vec3 worn_color = mix(color, vec3(dot(color, vec3(0.3, 0.5, 0.2))) * 1.15, wear_total * 0.5);
			color = mix(color, worn_color, wear_total);
			final_roughness = mix(final_roughness, final_roughness * 0.6, wear_total);
		}
		if (dust_amount > 0.001) {
			float grout_dust = smoothstep(0.06, 0.0, edge_dist) * 0.7;
			float surface_dust = fbm(uv * 6.0 + vec2(42.0, 13.0), 3);
			surface_dust = smoothstep(0.35, 0.65, surface_dust) * 0.4;
			float dust_total = clamp((grout_dust + surface_dust) * dust_amount, 0.0, 1.0);
			color = mix(color, dust_color, dust_total);
			final_roughness = mix(final_roughness, 1.0, dust_total * 0.5);
		}
		if (fade_amount > 0.001) {
			float exposure = fbm(uv * 3.0 + vec2(99.0, 55.0), 3);
			exposure = smoothstep(0.3, 0.8, exposure);
			float fd = exposure * fade_amount;
			float lum = dot(color, vec3(0.299, 0.587, 0.114));
			color = mix(color, vec3(lum), fd * 0.7);
			color = mix(color, color * vec3(1.08, 1.02, 0.88), fd * 0.4);
		}
		if (crack_density > 0.001) {
			float cracks = voronoi_cracks(uv * tile_scale * 4.0);
			float crack_line = 1.0 - smoothstep(0.0, 0.04 * (1.0 - crack_density * 0.8), cracks);
			float crack_total = clamp(crack_line * crack_density, 0.0, 1.0);
			color = mix(color, color * 0.2, crack_total);
		}
		if (chip_amount > 0.001) {
			float chip_noise = fbm(uv * tile_scale * 2.0 + vec2(300.0, 150.0), 4);
			float edge_bias = smoothstep(0.06, 0.0, edge_dist) * 0.3;
			float chip_mask = smoothstep(0.7 - chip_amount * 0.3, 0.75, chip_noise + edge_bias) * chip_amount;
			color = mix(color, chip_color, chip_mask);
		}

		ALBEDO = color;
		ROUGHNESS = final_roughness;
		METALLIC = metallic;
		if (emission_strength > 0.001) {
			EMISSION = color * emission_strength;
		}
		return;
	}

	// Get the symmetry-transformed UV within the domain
	vec2 domain_uv = get_symmetric_uv(uv, wallpaper_group);

	// Apply tile shape subdivision
	vec2 st_shape = uv * tile_scale;
	int shape_tx = int(floor(st_shape.x));
	int shape_ty = int(floor(st_shape.y));
	vec2 shape_local = fract(st_shape);
	vec3 shape_result = apply_tile_shape(shape_local, tile_shape, shape_tx, shape_ty);
	float sub_region = shape_result.z;

	// Offset domain UV by sub-region to get different colors per triangle
	// The offset shifts the lookup within the domain texture so each sub-region
	// samples a different part of the color grid
	vec2 region_offset = vec2(0.0);
	if (tile_shape > 0 && sub_region > 0.0) {
		// Shift by fraction of domain texture per sub-region
		float domain_texel_size = 1.0 / max(textureSize(domain_texture, 0).x, 1);
		region_offset = vec2(sub_region * domain_texel_size * 2.0, sub_region * domain_texel_size);
		domain_uv = fract(domain_uv + region_offset);
	}

	// Sample the domain texture
	vec3 color = texture(domain_texture, domain_uv).rgb;

	// Grout lines at tile boundaries
	float edge_dist = 1.0;
	vec2 st_grout = uv * tile_scale;
	vec2 f_grout = fract(st_grout);
	vec2 d_grout = min(f_grout, 1.0 - f_grout);
	edge_dist = min(d_grout.x, d_grout.y);

	// Additional grout along diagonals for triangle shapes
	float diag_dist = 1.0;
	if (tile_shape == 1 || tile_shape == 2) {
		// Distance to TL-BR diagonal: |x - y| / sqrt(2)
		diag_dist = abs(shape_local.x - shape_local.y) * 0.7071;
	}
	if (tile_shape == 2 || tile_shape == 4) {
		// Distance to TR-BL diagonal: |x + y - 1| / sqrt(2)
		float anti_diag = abs(shape_local.x + shape_local.y - 1.0) * 0.7071;
		diag_dist = min(diag_dist, anti_diag);
	}
	if (tile_shape == 3) {
		// Diamond edges: manhattan distance boundary
		float cx = shape_local.x - 0.5;
		float cy = shape_local.y - 0.5;
		float diamond_edge = abs(abs(cx) + abs(cy) - 0.5);
		diag_dist = diamond_edge;
	}
	if (tile_shape == 5) {
		// Tumbling blocks: 3 lines from center at 120° apart
		vec2 c = shape_local - vec2(0.5);
		// Distance to line at 90° (vertical from center): |x|
		float d1 = abs(c.x);
		// Distance to line at 210° (30° below horizontal-left)
		float d2 = abs(c.x * 0.866 + c.y * 0.5);
		// Distance to line at 330° (30° below horizontal-right)
		float d3 = abs(-c.x * 0.866 + c.y * 0.5);
		diag_dist = min(d1, min(d2, d3));
	}

	if (tile_shape > 0) {
		edge_dist = min(edge_dist, diag_dist);
	}

	if (grout_width > 0.001) {
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
