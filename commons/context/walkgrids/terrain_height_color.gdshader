shader_type spatial;

// Height-based terrain coloring for walkable mathematical spaces
// Assign this shader to any TopologySpace mesh for gradient coloring
// that reveals the mathematical structure of the surface.

uniform vec3 color_low : source_color = vec3(0.15, 0.12, 0.2);     // Valley color
uniform vec3 color_mid : source_color = vec3(0.4, 0.45, 0.5);      // Mid-height
uniform vec3 color_high : source_color = vec3(0.9, 0.85, 0.75);    // Peak color
uniform float height_min : hint_range(-10.0, 0.0) = -2.0;
uniform float height_max : hint_range(0.0, 20.0) = 4.0;

uniform float roughness_base : hint_range(0.0, 1.0) = 0.7;
uniform float metallic_base : hint_range(0.0, 1.0) = 0.15;

// Contour lines
uniform bool show_contours = false;
uniform float contour_spacing : hint_range(0.1, 2.0) = 0.5;
uniform float contour_width : hint_range(0.001, 0.05) = 0.015;
uniform vec3 contour_color : source_color = vec3(0.0, 0.0, 0.0);

// Slope shading
uniform bool shade_by_slope = true;
uniform float slope_darkening : hint_range(0.0, 1.0) = 0.3;

// Emission
uniform float emission_strength : hint_range(0.0, 2.0) = 0.2;

// Fresnel rim
uniform bool enable_rim = true;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform vec3 rim_color : source_color = vec3(0.5, 0.6, 0.8);

varying float v_height;
varying vec3 v_world_normal;

void vertex() {
	v_height = VERTEX.y;
	v_world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	// Height-based color gradient
	float t = clamp((v_height - height_min) / (height_max - height_min), 0.0, 1.0);

	vec3 color;
	if (t < 0.5) {
		color = mix(color_low, color_mid, t * 2.0);
	} else {
		color = mix(color_mid, color_high, (t - 0.5) * 2.0);
	}

	// Slope darkening — steeper = darker
	if (shade_by_slope) {
		float slope = 1.0 - abs(normalize(v_world_normal).y);
		color *= 1.0 - slope * slope_darkening;
	}

	// Contour lines
	if (show_contours) {
		float contour = abs(fract(v_height / contour_spacing + 0.5) - 0.5);
		if (contour < contour_width) {
			color = mix(contour_color, color, contour / contour_width);
		}
	}

	ALBEDO = color;
	ROUGHNESS = roughness_base;
	METALLIC = metallic_base;

	// Emission from height
	EMISSION = color * emission_strength * t;

	// Fresnel rim
	if (enable_rim) {
		float fresnel = pow(1.0 - abs(dot(NORMAL, VIEW)), rim_power);
		EMISSION += rim_color * fresnel * 0.3;
	}
}
