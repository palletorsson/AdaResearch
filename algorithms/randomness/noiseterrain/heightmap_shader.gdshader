shader_type spatial;
render_mode unshaded;

varying float height;

uniform float height_scale : hint_range(0.1, 2.0) = 1.0;
uniform float contour_frequency : hint_range(5.0, 50.0) = 20.0;
uniform float contour_strength : hint_range(0.0, 1.0) = 0.3;
uniform bool enable_contours  = true;

void vertex() {
	// Use the Y coordinate directly (Y is up in Godot)
	height = VERTEX.y;
}

void fragment() {
	// Height-based color mapping using Y coordinate
	// Apply height scale for fine-tuning
	float scaled_height = height * height_scale;

	// Normalize height range - adjust these values based on your terrain's height range
	// Assuming terrain heights typically range from -10 to +10 units
	float normalized_height = (scaled_height + 10.0) / 20.0;
	normalized_height = clamp(normalized_height, 0.0, 1.0);

	// Define height-based color bands (topographical style) - made brighter
	vec3 deep_water = vec3(0.1, 0.3, 0.6);      // Brighter dark blue
	vec3 shallow_water = vec3(0.3, 0.6, 0.9);   // Brighter light blue
	vec3 beach = vec3(1.0, 0.9, 0.7);           // Brighter sand color
	vec3 grass = vec3(0.4, 0.8, 0.3);           // Brighter green
	vec3 forest = vec3(0.3, 0.6, 0.2);          // Brighter dark green
	vec3 mountain = vec3(0.7, 0.6, 0.5);        // Brighter brown
	vec3 snow = vec3(1.0, 1.0, 1.0);            // Pure white

	vec3 final_color;

	// Height-based color interpolation
	if (normalized_height < 0.2) {
		// Deep to shallow water
		final_color = mix(deep_water, shallow_water, normalized_height / 0.2);
	} else if (normalized_height < 0.3) {
		// Shallow water to beach
		final_color = mix(shallow_water, beach, (normalized_height - 0.2) / 0.1);
	} else if (normalized_height < 0.5) {
		// Beach to grass
		final_color = mix(beach, grass, (normalized_height - 0.3) / 0.2);
	} else if (normalized_height < 0.7) {
		// Grass to forest
		final_color = mix(grass, forest, (normalized_height - 0.5) / 0.2);
	} else if (normalized_height < 0.85) {
		// Forest to mountain
		final_color = mix(forest, mountain, (normalized_height - 0.7) / 0.15);
	} else {
		// Mountain to snow
		final_color = mix(mountain, snow, (normalized_height - 0.85) / 0.15);
	}

	// Add contour lines for topographical effect using Y height
	if (enable_contours) {
		float contour_line = abs(fract(scaled_height * contour_frequency * 0.1) - 0.5) * 2.0;
		contour_line = smoothstep(0.8, 1.0, contour_line);
		final_color = mix(final_color * (1.0 - contour_strength), final_color, contour_line);
	}

	// Make it very bright and unshaded
	ALBEDO = final_color;
}
