// lab_wall_bands.gdshader
//
// Spatial shader for the lab room's wall surfaces. Paints up to three
// horizontal colour bands (header / footer / mid-band) onto the wall
// based on world-space Y position, on top of a base wall colour.
//
// Used by lab_room.gd's wall material when any band is enabled. With
// this shader the bands are TEXTURED ONTO the wall instead of being
// separate mesh strips — they automatically follow whatever wall
// geometry exists (window cutouts, door openings, side strips) without
// needing per-strip mesh segmentation.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.94, 0.94, 0.97);
uniform float wall_roughness : hint_range(0.0, 1.0) = 0.6;
uniform float wall_metallic  : hint_range(0.0, 1.0) = 0.0;

// The lab_room's world-space Y position. World-Y of a fragment minus
// this gives the fragment's lab-local Y, which is what the band
// thresholds below are expressed in. Set by lab_room.gd in _ready
// (deferred so global_position is valid) and updated whenever the
// lab moves. Defaults to 0 — correct for GLB export where the lab
// sits at world origin.
uniform float lab_world_y = 0.0;

// HEADER — runs from header_y_min to header_y_max (in world Y).
uniform bool header_on = false;
uniform vec3 header_color : source_color = vec3(0.32, 0.36, 0.34);
uniform float header_y_min = 0.0;
uniform float header_y_max = 0.0;

// FOOTER
uniform bool footer_on = false;
uniform vec3 footer_color : source_color = vec3(0.20, 0.22, 0.24);
uniform float footer_y_min = 0.0;
uniform float footer_y_max = 0.0;

// MID-BAND
uniform bool band_on = false;
uniform vec3 band_color : source_color = vec3(0.12, 0.36, 0.95);
uniform float band_y_min = 0.0;
uniform float band_y_max = 0.0;

varying vec3 world_pos;

void vertex() {
	// Capture world-space position so the fragment shader can pick
	// the right colour by absolute Y, regardless of which wall this
	// fragment belongs to.
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 col = base_color;
	// Lab-local Y: subtract the lab_room's world-Y so the band
	// thresholds (which are authored in lab-local terms) match.
	float y = world_pos.y - lab_world_y;
	// Order matters when ranges overlap — paint footer last so a
	// header/band overlap reads as the header. In practice the three
	// ranges shouldn't overlap.
	if (band_on   && y >= band_y_min   && y <= band_y_max)   col = band_color;
	if (header_on && y >= header_y_min && y <= header_y_max) col = header_color;
	if (footer_on && y >= footer_y_min && y <= footer_y_max) col = footer_color;
	ALBEDO = col;
	ROUGHNESS = wall_roughness;
	METALLIC = wall_metallic;
}
