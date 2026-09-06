# museum_wall_architectural_spans.gd
# Additive, family-specific architectural detail pass for MuseumWallPiece.
# Owns no run layout: every visible part stays inside the caller's exact 1 m span.
# All work happens at build time; there is no per-frame processing.

extends RefCounted
class_name MuseumWallArchitecturalSpans

const API_VERSION := "museum_wall_architectural_spans_v1"
const MATERIAL_ROOT := "res://commons/materials/museum/"
const SUPPORTED_FAMILIES := [&"solid", &"feature", &"service", &"endcap"]
const WEAR_STATES := [&"pristine", &"lived_in", &"worn", &"damaged"]
const FACE_Z := 0.075
const UV_VARIANT_POOL := 8
const MICRO_LOD_END_M := 18.0
const MEDIUM_LOD_END_M := 42.0
const NEAR_DRAW_CALL_BUDGET := 32

const PBR_SHADER_CODE := """
shader_type spatial;
render_mode depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ao_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D height_tex : hint_default_black, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D metallic_tex : hint_default_black, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 uv_scale = vec2(1.0);
uniform float normal_strength = 0.5;
uniform float roughness_bias = 0.0;
uniform float metallic_strength = 0.0;
uniform vec4 surface_tint : source_color = vec4(1.0);
// x = age response, y = chamfer polish, z = macro breakup, w = micro breakup.
uniform vec4 surface_story = vec4(0.45, 0.25, 0.12, 0.08);
// xy = phase, z = scale jitter, w = quarter turns.
uniform vec4 uv_variant_data = vec4(0.0, 0.0, 1.0, 0.0);

varying float local_edge_factor;
varying vec3 local_position;

float story_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float story_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(story_hash(i), story_hash(i + vec2(1.0, 0.0)), f.x),
		mix(story_hash(i + vec2(0.0, 1.0)), story_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	local_position = VERTEX;
	vec3 authored_normal = abs(normalize(NORMAL));
	float planar = max(authored_normal.x, max(authored_normal.y, authored_normal.z));
	local_edge_factor = smoothstep(0.08, 0.38, 1.0 - planar);
}

vec2 authored_uv(vec2 source_uv) {
	vec2 p = source_uv * uv_scale * uv_variant_data.z;
	int quarter_turns = int(uv_variant_data.w + 0.5);
	if (quarter_turns == 1) p = vec2(p.y, -p.x);
	else if (quarter_turns == 2) p = -p;
	else if (quarter_turns == 3) p = vec2(-p.y, p.x);
	return p + uv_variant_data.xy;
}

void fragment() {
	vec2 mapped_uv = authored_uv(UV);
	vec3 authored_albedo = texture(albedo_tex, mapped_uv).rgb;
	float authored_height = texture(height_tex, mapped_uv).r;
	float relief_breakup = mix(0.94, 1.055, authored_height);
	float macro_story = story_noise(mapped_uv * 0.42 + uv_variant_data.xy * 7.0);
	float medium_story = story_noise(mapped_uv * 3.1 + uv_variant_data.yx * 19.0);
	float micro_story = story_hash(floor(mapped_uv * 72.0) + uv_variant_data.xy * 101.0);
	float cavity = clamp(1.0 - authored_height, 0.0, 1.0);
	float settled_age = smoothstep(0.48, 0.92, macro_story * 0.62 + medium_story * 0.24 + cavity * 0.24);
	float tiny_chip = smoothstep(0.975, 0.998, micro_story) * smoothstep(0.28, 0.8, cavity);
	float bedding = 0.5 + 0.5 * sin(local_position.y * 7.4 + local_position.x * 1.35 + macro_story * 1.8);
	float value_breakup = 1.0 + (macro_story - 0.5) * surface_story.z + (medium_story - 0.5) * surface_story.w;
	value_breakup *= 1.0 + (bedding - 0.5) * surface_story.z * 0.12;
	vec3 story_albedo = authored_albedo * surface_tint.rgb * relief_breakup * value_breakup;
	// The authored bronze scan is deliberately dark. Preserve its patina while
	// lifting reflected metal colour enough to separate it from brown paint.
	story_albedo *= mix(1.0, 1.52, smoothstep(0.35, 0.95, metallic_strength));
	story_albedo *= mix(vec3(1.0), vec3(0.68, 0.61, 0.52), settled_age * surface_story.x * 0.22);
	story_albedo *= mix(vec3(1.0), vec3(0.48, 0.43, 0.38), tiny_chip * surface_story.x * 0.34);
	story_albedo = mix(story_albedo, story_albedo * 1.14 + vec3(0.018, 0.012, 0.006), local_edge_factor * surface_story.y);
	ALBEDO = story_albedo;
	NORMAL_MAP = texture(normal_tex, mapped_uv).rgb;
	NORMAL_MAP_DEPTH = normal_strength;
	ROUGHNESS = clamp(texture(roughness_tex, mapped_uv).r + roughness_bias + (0.5 - authored_height) * 0.06 + settled_age * 0.055 - local_edge_factor * surface_story.y * 0.22, 0.08, 1.0);
	AO = texture(ao_tex, mapped_uv).r * mix(1.0, 0.82, settled_age * surface_story.x);
	METALLIC = texture(metallic_tex, mapped_uv).r * metallic_strength;
}
"""

const FLAT_SHADER_CODE := """
shader_type spatial;
render_mode depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
uniform vec4 flat_color : source_color = vec4(1.0);
// x = roughness, y = metallic, z = emission energy.
uniform vec4 flat_surface = vec4(0.8, 0.0, 0.0, 0.0);
// x = macro variation, y = chamfer polish, z = contact-darkening response.
uniform vec3 flat_story = vec3(0.04, 0.12, 0.0);
varying float local_edge_factor;
varying vec3 local_position;

float flat_hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.7, 289.3))) * 9124.173);
}

void vertex() {
	local_position = VERTEX;
	vec3 authored_normal = abs(normalize(NORMAL));
	float planar = max(authored_normal.x, max(authored_normal.y, authored_normal.z));
	local_edge_factor = smoothstep(0.08, 0.38, 1.0 - planar);
}

void fragment() {
	float macro_story = flat_hash(floor(local_position.xy * 7.0 + local_position.z * 3.0));
	float fine_story = flat_hash(floor(local_position.xy * 57.0 + local_position.z * 31.0));
	float brushed = 0.5 + 0.5 * sin(local_position.y * 173.0 + local_position.x * 29.0);
	float value_breakup = 1.0 + (macro_story - 0.5) * flat_story.x + (fine_story - 0.5) * flat_story.x * 0.24;
	float contact = smoothstep(-0.01, 0.08, -local_position.y) * flat_story.z;
	vec3 story_color = flat_color.rgb * value_breakup * mix(1.0, 0.72, contact);
	story_color = mix(story_color, story_color * 1.18 + vec3(0.01), local_edge_factor * flat_story.y);
	ALBEDO = story_color;
	ROUGHNESS = clamp(flat_surface.x + contact * 0.08 + (brushed - 0.5) * flat_story.x * 0.12 - local_edge_factor * flat_story.y * 0.2, 0.08, 1.0);
	METALLIC = flat_surface.y;
	EMISSION = flat_color.rgb * flat_surface.z;
}
"""

static var _texture_cache: Dictionary = {}
static var _material_cache: Dictionary = {}
static var _box_mesh_cache: Dictionary = {}
static var _cylinder_mesh_cache: Dictionary = {}
static var _pbr_shader: Shader
static var _flat_shader: Shader
static var _physics_material_cache: Dictionary = {}


## Adds one bounded detail pass below `parent`. Unsupported families are a no-op.
## Required config: family. Optional: width_cells, height, finish, flip, seed,
## wear_state, quality_tier (0..2), enable_collision, replace_existing.
## `canonical_collision_owner` is reserved for MuseumWallPiece: it maps the few
## physically represented detail meshes to that piece's canonical surface bodies.
static func decorate(parent: Node3D, config: Dictionary) -> Dictionary:
	var family := StringName(str(config.get("family", "solid")).to_lower())
	if not SUPPORTED_FAMILIES.has(family):
		return {"supported": false, "family": str(family), "api_version": API_VERSION}
	var width_cells := clampi(int(config.get("width_cells", 1)), 1, 4)
	var wall_height := clampf(float(config.get("height", 4.0)), 3.0, 6.0)
	var finish := str(config.get("finish", "uffizi_stone"))
	var flip := bool(config.get("flip", false))
	var quality_tier := clampi(int(config.get("quality_tier", 2)), 0, 2)
	var enable_collision := bool(config.get("enable_collision", true))
	var wear_state := StringName(str(config.get("wear_state", "lived_in")).to_lower())
	if not WEAR_STATES.has(wear_state):
		wear_state = &"lived_in"
	var seed := int(config.get("seed", hash("%s:%d:%s:%s" % [family, width_cells, finish, flip])))

	var old := parent.get_node_or_null("ArchitecturalSpanDetail")
	if old != null:
		if not bool(config.get("replace_existing", false)):
			return old.get_meta("build_report", {"supported": true, "reused": true})
		old.free()

	var detail_root := Node3D.new()
	detail_root.name = "ArchitecturalSpanDetail"
	parent.add_child(detail_root)
	var groups := _make_groups(detail_root)
	var ctx := {
		"family": str(family), "width": float(width_cells), "height": wall_height,
		"finish": finish, "flip": flip, "seed": seed, "wear": str(wear_state),
		"quality": quality_tier, "collision": enable_collision, "groups": groups,
		"canonical_collision_owner": bool(config.get("canonical_collision_owner", false)),
		"meshes": 0, "multimeshes": 0, "triangles": 0, "colliders": 0,
		"story_elements": 0,
		"construction_systems": [],
		"draw_macro": 0, "draw_medium": 0, "draw_micro": 0,
		"bounds_min_x": INF, "bounds_max_x": -INF, "material_keys": {},
	}

	match family:
		&"solid": _build_solid(ctx)
		&"feature": _build_feature(ctx)
		&"service": _build_service(ctx)
		&"endcap": _build_endcap(ctx)

	var near_calls := int(ctx["draw_macro"]) + int(ctx["draw_medium"]) + int(ctx["draw_micro"])
	var report := {
		"supported": true, "api_version": API_VERSION, "family": str(family),
		"width_cells": width_cells, "owned_width_m": float(width_cells), "height_m": wall_height,
		"detail_bounds_x_m": Vector2(float(ctx["bounds_min_x"]), float(ctx["bounds_max_x"])),
		"exact_width_preserved": float(ctx["bounds_min_x"]) >= -float(width_cells) * 0.5 - 0.001 and float(ctx["bounds_max_x"]) <= float(width_cells) * 0.5 + 0.001,
		"wear_state": str(wear_state), "quality_tier": quality_tier,
		"mesh_instances": int(ctx["meshes"]), "multimesh_instances": int(ctx["multimeshes"]),
		"estimated_triangles_near": int(ctx["triangles"]),
		"estimated_draw_calls": {"near": near_calls, "medium": int(ctx["draw_macro"]) + int(ctx["draw_medium"]), "far": int(ctx["draw_macro"])},
		"unique_materials_used": (ctx["material_keys"] as Dictionary).size(),
		"collision_shapes": int(ctx["colliders"]),
		"collision_scope": "helper_protrusions_only" if enable_collision else "disabled",
		"base_wall_collision_owner": "MuseumWallPiece",
		"surface_story_elements": int(ctx["story_elements"]),
		"authored_construction_systems": (ctx["construction_systems"] as Array).duplicate(),
		"lod_ranges_m": {"micro_end": MICRO_LOD_END_M, "medium_end": MEDIUM_LOD_END_M},
		"budget": {"near_draw_call_limit": NEAR_DRAW_CALL_BUDGET, "passes": near_calls <= NEAR_DRAW_CALL_BUDGET},
		"physics_profile": "museum_surface_zones_v2", "allocations_in_process": 0,
		"pbr_surfaces": ["aaa_wall_stone", "aaa_trim_bronze"],
		"uv_strategy": "bounded_%d_variant_phase_and_quarter_turn_pool" % UV_VARIANT_POOL,
	}
	detail_root.set_meta("build_report", report)
	detail_root.set_meta("family_contract", _family_contract(str(family), flip))
	detail_root.set_meta("no_process_allocations", true)
	return report


## Shared PBR factory. `surface` is `stone` or `bronze`. Requested tint and UV
## phase are folded into four deterministic slots per surface. This keeps atlas
## scale below Godot's shader-instance buffer ceiling without visible repetition.
static func create_pbr_material(surface: String, tint: Color, _uv_scale: Vector2 = Vector2.ONE, variant: int = 0) -> Material:
	var surface_name := "bronze" if surface.to_lower() == "bronze" else "stone"
	var slot := _pbr_variant_slot(surface_name, tint, variant)
	var key := "pooled_pbr:%s:%d" % [surface_name, slot]
	if _material_cache.has(key):
		return _material_cache[key]
	var maps := _surface_maps(surface_name)
	if maps["albedo"] == null:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = _pbr_slot_tint(surface_name, slot)
		fallback.roughness = 0.84 if surface_name == "stone" else 0.44
		fallback.metallic = 0.0 if surface_name == "stone" else 0.9
		fallback.resource_name = "Museum %s PBR fallback slot %d" % [surface_name.capitalize(), slot]
		fallback.set_meta("museum_surface_id", surface_name)
		fallback.set_meta("museum_material_pool_key", key)
		fallback.set_meta("museum_uv_variant_slot", slot)
		_material_cache[key] = fallback
		return fallback
	if _pbr_shader == null:
		_pbr_shader = Shader.new()
		_pbr_shader.code = PBR_SHADER_CODE
	var material := ShaderMaterial.new()
	material.shader = _pbr_shader
	material.set_shader_parameter("albedo_tex", maps["albedo"])
	material.set_shader_parameter("normal_tex", maps["normal"])
	material.set_shader_parameter("roughness_tex", maps["roughness"])
	material.set_shader_parameter("ao_tex", maps["ao"])
	material.set_shader_parameter("height_tex", maps["height"])
	material.set_shader_parameter("metallic_tex", maps["metallic"])
	material.set_shader_parameter("uv_scale", Vector2(2.4, 2.4) if surface_name == "bronze" else Vector2(1.65, 2.35))
	var uv := uv_variant(slot)
	var offset: Vector2 = uv["offset"]
	material.set_shader_parameter("surface_tint", _pbr_slot_tint(surface_name, slot))
	material.set_shader_parameter("uv_variant_data", Vector4(offset.x, offset.y, float(uv["scale_jitter"]), float(uv["quarter_turns"])))
	material.set_shader_parameter("normal_strength", 0.52 if surface_name == "stone" else 0.38)
	material.set_shader_parameter("roughness_bias", 0.04 if surface_name == "stone" else -0.04)
	material.set_shader_parameter("metallic_strength", 0.0 if surface_name == "stone" else 1.0)
	material.set_shader_parameter("surface_story", Vector4(0.58, 0.18, 0.17, 0.09) if surface_name == "stone" else Vector4(0.42, 0.48, 0.1, 0.07))
	material.resource_name = "Museum %s PBR slot %d" % [surface_name.capitalize(), slot]
	material.set_meta("museum_surface_id", surface_name)
	material.set_meta("museum_material_pool_key", key)
	material.set_meta("museum_uv_variant_slot", slot)
	_material_cache[key] = material
	return material


## Compatibility no-op retained for callers from the earlier instance-uniform API.
## Variation is now selected by create_pbr_material() and never consumes the
## RenderingServer's finite per-instance shader-variable buffer.
static func apply_surface_instance(_instance: GeometryInstance3D, _tint: Color, _seed_or_variant: int, _cell_index: int = 0) -> void:
	pass


static func instance_uniforms_supported() -> bool:
	return false


## Stable UV transform for both helper geometry and the base wall-cell integration.
static func uv_variant(seed_or_index: int, cell_index: int = 0) -> Dictionary:
	var index := posmod(seed_or_index * 5 + cell_index * 3, UV_VARIANT_POOL)
	var offsets := [
		Vector2(0.07, 0.19), Vector2(0.43, 0.73), Vector2(0.81, 0.31), Vector2(0.22, 0.91),
		Vector2(0.66, 0.11), Vector2(0.37, 0.52), Vector2(0.94, 0.64), Vector2(0.14, 0.42),
	]
	return {"index": index, "offset": offsets[index], "quarter_turns": index % 4, "scale_jitter": 0.94 + float(index % 3) * 0.045}


static func _pbr_variant_slot(surface: String, tint: Color, variant: int) -> int:
	var luminance := tint.get_luminance()
	var tone := 0 if luminance >= (0.34 if surface == "bronze" else 0.7) else 1
	return tone * 2 + posmod(variant, 2)


static func _pbr_slot_tint(surface: String, slot: int) -> Color:
	if surface == "bronze":
		var bronze_base := Color(0.72, 0.5, 0.235) if slot < 2 else Color(0.4, 0.275, 0.14)
		var bronze_jitter := 0.975 if slot % 2 == 0 else 1.025
		return Color(bronze_base.r * bronze_jitter, bronze_base.g * bronze_jitter, bronze_base.b * bronze_jitter, 1.0)
	var stone_palette := [
		Color(0.62, 0.585, 0.52), Color(0.44, 0.405, 0.355),
	]
	var stone_base: Color = stone_palette[clampi(int(slot / 2), 0, stone_palette.size() - 1)]
	var stone_jitter := 0.975 if slot % 2 == 0 else 1.025
	return Color(stone_base.r * stone_jitter, stone_base.g * stone_jitter, stone_base.b * stone_jitter, 1.0)


static func cache_report() -> Dictionary:
	return {"textures": _texture_cache.size(), "materials": _material_cache.size(), "profile_meshes": _box_mesh_cache.size(), "cylinder_meshes": _cylinder_mesh_cache.size(), "physics_materials": _physics_material_cache.size(), "uv_variant_limit": UV_VARIANT_POOL}


static func _build_solid(ctx: Dictionary) -> void:
	var w: float = ctx["width"]
	var h: float = ctx["height"]
	var macro: Node3D = ctx["groups"]["macro"]
	var medium: Node3D = ctx["groups"]["medium"]
	var micro: Node3D = ctx["groups"]["micro"]
	for cell in range(int(w)):
		var x := -w * 0.5 + float(cell) + 0.5
		_add_box(ctx, macro, "SolidStoneField_%02d" % cell, Vector3(x, h * 0.5, FACE_Z + 0.018), Vector3(0.986, h - 0.4, 0.034), _stone(ctx, cell, Color(0.82, 0.77, 0.67)), "macro")
		if cell > 0:
			_add_box(ctx, micro, "SolidShadowJoint_%02d" % cell, Vector3(x - 0.5, h * 0.51, FACE_Z + 0.039), Vector3(0.007, h - 0.62, 0.014), _plain(ctx, "shadow", Color(0.035, 0.03, 0.025), 0.9, 0.0), "micro")
	_add_profile_courses(ctx, medium, w, h, true)
	_add_box(ctx, medium, "SolidDadoShadow", Vector3(0, 0.88, FACE_Z + 0.071), Vector3(w - 0.08, 0.026, 0.075), _plain(ctx, "shadow", Color(0.028, 0.025, 0.022), 0.92, 0.0), "medium")
	_add_box(ctx, medium, "SolidDadoCap", Vector3(0, 0.925, FACE_Z + 0.09), Vector3(w - 0.1, 0.07, 0.12), _bronze(ctx, 2, Color(0.42, 0.29, 0.15)), "medium")
	_add_anchor_array(ctx, micro, w, h, "SolidBedAnchors", 0.021)
	_add_solid_story(ctx, medium, micro, w, h)
	_add_solid_joinery(ctx, medium, micro, w, h)
	_add_contact_breakup(ctx, micro, w, "solid")
	_add_family_wear(ctx, micro, "solid")


static func _build_feature(ctx: Dictionary) -> void:
	var w: float = ctx["width"]
	var h: float = ctx["height"]
	var macro: Node3D = ctx["groups"]["macro"]
	var medium: Node3D = ctx["groups"]["medium"]
	var micro: Node3D = ctx["groups"]["micro"]
	var field_w := maxf(0.48, w - 0.52)
	var field_h := minf(2.72, h - 1.05)
	var cy := minf(2.05, 1.02 + field_h * 0.5)
	_add_box(ctx, macro, "FeatureDeepReveal", Vector3(0, cy, FACE_Z + 0.034), Vector3(field_w + 0.2, field_h + 0.2, 0.07), _plain(ctx, "shadow", Color(0.018, 0.019, 0.02), 0.78, 0.05), "macro")
	_add_box(ctx, macro, "FeatureDisplayBack", Vector3(0, cy, FACE_Z + 0.074), Vector3(field_w, field_h, 0.035), _stone(ctx, 3, Color(0.62, 0.59, 0.54)), "macro")
	_add_frame(ctx, medium, "FeatureOuterProfile", field_w + 0.28, field_h + 0.28, cy, 0.075, _stone(ctx, 5, Color(0.76, 0.7, 0.6)), FACE_Z + 0.11)
	_add_frame(ctx, medium, "FeatureBronzeReveal", field_w + 0.1, field_h + 0.1, cy, 0.028, _bronze(ctx, 1, Color(0.54, 0.38, 0.2)), FACE_Z + 0.146)
	_add_box(ctx, medium, "FeatureHangingBus", Vector3(0, minf(h - 0.58, cy + field_h * 0.5 + 0.22), FACE_Z + 0.13), Vector3(field_w * 0.84, 0.075, 0.105), _bronze(ctx, 4, Color(0.34, 0.23, 0.13)), "medium")
	_add_box(ctx, micro, "FeatureWallWashBaffle", Vector3(0, cy + field_h * 0.5 - 0.035, FACE_Z + 0.2), Vector3(field_w * 0.88, 0.075, 0.19), _plain(ctx, "blackened_steel", Color(0.055, 0.06, 0.065), 0.36, 0.42), "micro")
	_add_box(ctx, micro, "FeatureWallWashEmitter", Vector3(0, cy + field_h * 0.5 - 0.075, FACE_Z + 0.302), Vector3(field_w * 0.78, 0.026, 0.018), _emissive(ctx, "warm_emitter", Color(1.0, 0.68, 0.35), 1.8), "micro")
	for side in [-1.0, 1.0]:
		var x: float = float(side) * (field_w * 0.5 + 0.125)
		_add_box(ctx, micro, "FeatureCableHatch", Vector3(x, 0.47, FACE_Z + 0.13), Vector3(0.12, 0.22, 0.08), _bronze(ctx, 6, Color(0.31, 0.22, 0.13)), "micro")
		_add_marker(micro, "FeatureAnchor_%s" % ("Left" if side < 0 else "Right"), Vector3(side * field_w * 0.38, cy + field_h * 0.44, FACE_Z + 0.19), {"socket": "museum_feature_hanger_v1", "safe_working_load_kg": 80.0})
	_add_feature_story(ctx, medium, micro, field_w, field_h, cy)
	_add_feature_hardware(ctx, medium, micro, field_w, field_h, cy)
	_add_contact_breakup(ctx, micro, w, "feature")
	_add_family_wear(ctx, micro, "feature")
	ctx["groups"]["contracts"].set_meta("reserved_feature_field_m", Vector2(field_w, field_h))


static func _build_service(ctx: Dictionary) -> void:
	var w: float = ctx["width"]
	var h: float = ctx["height"]
	var side := 1.0 if bool(ctx["flip"]) else -1.0
	var macro: Node3D = ctx["groups"]["macro"]
	var medium: Node3D = ctx["groups"]["medium"]
	var micro: Node3D = ctx["groups"]["micro"]
	var cabinet_w := minf(0.72, w * 0.46)
	var cabinet_x := side * (w * 0.5 - cabinet_w * 0.5 - 0.11)
	_add_box(ctx, macro, "ServiceRecess", Vector3(cabinet_x, 1.15, FACE_Z + 0.07), Vector3(cabinet_w + 0.12, 1.52, 0.12), _plain(ctx, "shadow", Color(0.025, 0.029, 0.033), 0.58, 0.2), "macro")
	_add_box(ctx, macro, "ServiceCabinetShell", Vector3(cabinet_x, 1.15, FACE_Z + 0.155), Vector3(cabinet_w, 1.4, 0.12), _plain(ctx, "service_steel", Color(0.14, 0.17, 0.18), 0.48, 0.62), "macro")
	_add_frame(ctx, medium, "ServiceDoorBevel", cabinet_w - 0.08, 1.29, 1.15, 0.035, _bronze(ctx, 3, Color(0.34, 0.24, 0.14)), FACE_Z + 0.226)
	_add_box(ctx, medium, "ServiceHeaderRaceway", Vector3(0, h - 0.54, FACE_Z + 0.12), Vector3(w - 0.12, 0.18, 0.14), _plain(ctx, "service_steel", Color(0.105, 0.125, 0.135), 0.4, 0.66), "medium")
	var pipe_x := -side * (w * 0.5 - 0.22)
	_add_cylinder(ctx, medium, "ServiceCopperRiser", Vector3(pipe_x, h * 0.53, FACE_Z + 0.18), 0.027, h - 0.66, _bronze(ctx, 2, Color(0.46, 0.28, 0.13)), Vector3.ZERO, 10, "medium")
	_add_cylinder(ctx, medium, "ServiceBlackRiser", Vector3(pipe_x - side * 0.09, h * 0.46, FACE_Z + 0.155), 0.022, h - 1.2, _plain(ctx, "blackened_steel", Color(0.045, 0.052, 0.057), 0.34, 0.78), Vector3.ZERO, 10, "medium")
	_add_cylinder(ctx, micro, "ServiceLatch", Vector3(cabinet_x - side * cabinet_w * 0.31, 1.12, FACE_Z + 0.25), 0.035, 0.075, _bronze(ctx, 7, Color(0.48, 0.34, 0.18)), Vector3(90, 0, 0), 10, "micro")
	for index in range(3):
		_add_box(ctx, micro, "ServiceIndicator_%02d" % index, Vector3(cabinet_x + side * (0.12 - float(index) * 0.09), 1.62, FACE_Z + 0.244), Vector3(0.045, 0.045, 0.018), _emissive(ctx, "service_indicator_%d" % index, [Color(0.16, 0.85, 0.48), Color(1.0, 0.56, 0.12), Color(0.18, 0.54, 1.0)][index], 1.25), "micro")
	_add_pipe_clamps(ctx, micro, pipe_x, h)
	_add_service_story(ctx, medium, micro, cabinet_x, cabinet_w, pipe_x, side, h)
	_add_service_hardware(ctx, medium, micro, cabinet_x, cabinet_w, pipe_x, side)
	_add_contact_breakup(ctx, micro, w, "service")
	_add_family_wear(ctx, micro, "service")
	if bool(ctx["collision"]):
		_add_collision(ctx, "ServiceFixtureCollision", Vector3(cabinet_x, 1.15, FACE_Z + 0.14), Vector3(cabinet_w + 0.08, 1.48, 0.28), {"surface_id": "painted_metal", "contact": "hard", "impact": "metal_hollow", "decal": "paint_chip"})
	ctx["groups"]["contracts"].set_meta("prop_zone", "edge")
	ctx["groups"]["contracts"].set_meta("service_side", "right" if side > 0 else "left")


static func _build_endcap(ctx: Dictionary) -> void:
	var w: float = ctx["width"]
	var h: float = ctx["height"]
	var side := 1.0 if bool(ctx["flip"]) else -1.0
	var macro: Node3D = ctx["groups"]["macro"]
	var medium: Node3D = ctx["groups"]["medium"]
	var micro: Node3D = ctx["groups"]["micro"]
	var edge_x := side * (w * 0.5 - 0.105)
	var infill_w := maxf(0.3, w - 0.46)
	var infill_x := -side * 0.23
	_add_box(ctx, macro, "EndcapInfillStoneField", Vector3(infill_x, h * 0.5, FACE_Z + 0.018), Vector3(infill_w, h - 0.4, 0.034), _stone(ctx, 3, Color(0.72, 0.66, 0.56)), "macro")
	_add_box(ctx, macro, "EndcapStoneReturn", Vector3(edge_x, h * 0.5, -0.17), Vector3(0.21, h - 0.08, 0.5), _stone(ctx, 6, Color(0.72, 0.66, 0.56)), "macro")
	_add_box(ctx, macro, "EndcapWeightPier", Vector3(side * (w * 0.5 - 0.2), h * 0.5, FACE_Z + 0.07), Vector3(0.4, h, 0.16), _stone(ctx, 2, Color(0.66, 0.59, 0.49)), "macro")
	_add_box(ctx, medium, "EndcapShadowReveal", Vector3(side * (w * 0.5 - 0.405), h * 0.5, FACE_Z + 0.155), Vector3(0.026, h - 0.42, 0.13), _plain(ctx, "shadow", Color(0.025, 0.022, 0.02), 0.92, 0.0), "medium")
	_add_box(ctx, medium, "EndcapBronzeNosing", Vector3(side * (w * 0.5 - 0.025), h * 0.5, FACE_Z + 0.105), Vector3(0.05, h - 0.22, 0.12), _bronze(ctx, 0, Color(0.48, 0.32, 0.16)), "medium")
	_add_box(ctx, medium, "EndcapArmouredShoe", Vector3(edge_x, 0.24, FACE_Z + 0.12), Vector3(0.2, 0.48, 0.17), _bronze(ctx, 5, Color(0.29, 0.22, 0.16)), "medium")
	_add_box(ctx, medium, "EndcapCrownBlock", Vector3(edge_x, h - 0.16, FACE_Z + 0.1), Vector3(0.21, 0.32, 0.18), _stone(ctx, 1, Color(0.8, 0.73, 0.62)), "medium")
	_add_endcap_studs(ctx, micro, edge_x, h)
	_add_endcap_story(ctx, medium, micro, infill_x, infill_w, edge_x, side, h)
	_add_endcap_hardware(ctx, medium, micro, edge_x, side, h)
	_add_contact_breakup(ctx, micro, w, "endcap")
	_add_family_wear(ctx, micro, "endcap")
	if bool(ctx["collision"]):
		_add_collision(ctx, "EndcapReturnCollision", Vector3(edge_x, h * 0.5, -0.17), Vector3(0.21, h - 0.08, 0.5), {"surface_id": "stone", "contact": "hard", "impact": "stone_dense", "decal": "mineral_chip"})
	ctx["groups"]["contracts"].set_meta("termination_side", "right" if side > 0 else "left")
	ctx["groups"]["contracts"].set_meta("return_depth_m", 0.5)


static func _add_profile_courses(ctx: Dictionary, parent: Node3D, w: float, h: float, include_cornice: bool) -> void:
	_add_box(ctx, parent, "ProfileSkirtingShadow", Vector3(0, 0.14, FACE_Z + 0.07), Vector3(w - 0.04, 0.28, 0.11), _plain(ctx, "shadow", Color(0.028, 0.026, 0.024), 0.9, 0.0), "medium")
	_add_box(ctx, parent, "ProfileSkirtingFace", Vector3(0, 0.19, FACE_Z + 0.13), Vector3(w - 0.08, 0.3, 0.09), _stone(ctx, 1, Color(0.63, 0.57, 0.48)), "medium")
	_add_box(ctx, parent, "ProfileSkirtingBevel", Vector3(0, 0.37, FACE_Z + 0.11), Vector3(w - 0.1, 0.065, 0.12), _bronze(ctx, 3, Color(0.36, 0.25, 0.14)), "medium")
	if include_cornice:
		_add_box(ctx, parent, "ProfileCorniceBed", Vector3(0, h - 0.27, FACE_Z + 0.08), Vector3(w - 0.05, 0.18, 0.11), _stone(ctx, 4, Color(0.7, 0.64, 0.54)), "medium")
		_add_box(ctx, parent, "ProfileCorniceLip", Vector3(0, h - 0.12, FACE_Z + 0.14), Vector3(w - 0.09, 0.12, 0.13), _bronze(ctx, 5, Color(0.4, 0.28, 0.15)), "medium")


# Restrained age cues are tied to believable construction: bed joints and one
# fitted stone repair. Their location is deterministic and never crosses a cell edge.
static func _add_solid_story(ctx: Dictionary, medium: Node3D, micro: Node3D, w: float, h: float) -> void:
	if int(ctx["quality"]) < 1:
		return
	var seed := posmod(int(ctx["seed"]), 11)
	for index in range(2):
		var y := minf(h - 0.62, 1.28 + float(index) * 1.27 + float(seed % 3) * 0.035)
		_add_box(ctx, micro, "SolidBedJoint_%02d" % index, Vector3(0, y, FACE_Z + 0.044), Vector3(w - 0.12, 0.008, 0.015), _plain(ctx, "shadow", Color(0.035, 0.03, 0.025), 0.92, 0.0), "micro")
		ctx["story_elements"] = int(ctx["story_elements"]) + 1
	if int(ctx["quality"]) < 2:
		return
	var side := -1.0 if seed % 2 == 0 else 1.0
	var repair_w := 0.3 + float(seed % 3) * 0.05
	var repair_h := 0.18 + float(seed % 2) * 0.04
	var repair_x := side * (w * 0.5 - repair_w * 0.5 - 0.11)
	var repair_y := 0.7 + float(seed % 4) * 0.11
	_add_box(ctx, medium, "SolidDutchmanRepairShadow", Vector3(repair_x, repair_y, FACE_Z + 0.051), Vector3(repair_w + 0.025, repair_h + 0.022, 0.02), _plain(ctx, "shadow", Color(0.03, 0.027, 0.024), 0.94, 0.0), "medium")
	_add_box(ctx, medium, "SolidDutchmanRepair", Vector3(repair_x, repair_y, FACE_Z + 0.067), Vector3(repair_w, repair_h, 0.025), _stone(ctx, seed + 1, Color(0.82, 0.76, 0.66)), "medium")
	ctx["story_elements"] = int(ctx["story_elements"]) + 2


# Staggered perp joints make the dressed-stone field read as assembled masonry,
# not a tiled skin. The batch shares one profile and one material at every width.
static func _add_solid_joinery(ctx: Dictionary, _medium: Node3D, micro: Node3D, w: float, h: float) -> void:
	if int(ctx["quality"]) < 1:
		return
	var transforms: Array[Transform3D] = []
	var course_ys := [minf(1.55, h - 0.9), minf(2.35, h - 0.72), minf(3.15, h - 0.54)]
	for course_index in range(course_ys.size()):
		var inset := 0.34 if course_index % 2 == 0 else 0.66
		for cell in range(int(w)):
			var x := -w * 0.5 + float(cell) + inset
			if x > -w * 0.5 + 0.08 and x < w * 0.5 - 0.08:
				transforms.append(Transform3D(Basis.IDENTITY, Vector3(x, float(course_ys[course_index]), FACE_Z + 0.047)))
	_add_multibox(ctx, micro, "SolidStaggeredPerpJoints", transforms, Vector3(0.009, 0.34, 0.017), _plain(ctx, "shadow", Color(0.026, 0.024, 0.022), 0.94, 0.0), "micro")
	ctx["story_elements"] = int(ctx["story_elements"]) + 1
	(ctx["construction_systems"] as Array).append("ashlar_staggered_jointing")


# The exhibition center stays empty. A museum inventory plaque and keyed frame
# corners live only on the service margins and explain how the feature is mounted.
static func _add_feature_story(ctx: Dictionary, medium: Node3D, micro: Node3D, field_w: float, field_h: float, cy: float) -> void:
	if int(ctx["quality"]) < 1:
		return
	var seed := posmod(int(ctx["seed"]), 17)
	var side := -1.0 if seed % 2 == 0 else 1.0
	var plaque_x := side * (field_w * 0.5 + 0.115)
	var plaque_y := minf(cy + field_h * 0.5 - 0.17, float(ctx["height"]) - 0.48)
	_add_box(ctx, medium, "FeatureInventoryPlaque", Vector3(plaque_x, plaque_y, FACE_Z + 0.205), Vector3(0.17, 0.1, 0.024), _bronze(ctx, seed, Color(0.72, 0.5, 0.24)), "medium")
	var corner_transforms: Array[Transform3D] = []
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			corner_transforms.append(Transform3D(Basis.IDENTITY, Vector3(float(sx) * (field_w * 0.5 + 0.105), cy + float(sy) * (field_h * 0.5 + 0.105), FACE_Z + 0.181)))
	_add_multibox(ctx, micro, "FeatureFrameCornerKeys", corner_transforms, Vector3(0.046, 0.046, 0.025), _bronze(ctx, seed + 2, Color(0.38, 0.27, 0.14)), "micro")
	var pin_transforms: Array[Transform3D] = []
	for dx in [-0.038, 0.038]:
		pin_transforms.append(Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)), Vector3(plaque_x + float(dx), plaque_y, FACE_Z + 0.225)))
	_add_multicylinder(ctx, micro, "FeatureInventoryPlaquePins", pin_transforms, 0.007, 0.012, _bronze(ctx, seed + 4, Color(0.58, 0.42, 0.22)), 8, "micro")
	ctx["story_elements"] = int(ctx["story_elements"]) + 3


# Conservation hardware is layered outside the reserved picture field: a soft
# gasket line, load-rated top carriages, leveling shoes, and cable grommets.
static func _add_feature_hardware(ctx: Dictionary, medium: Node3D, micro: Node3D, field_w: float, field_h: float, cy: float) -> void:
	if int(ctx["quality"]) < 1:
		return
	_add_frame(ctx, medium, "FeatureConservationGasket", field_w + 0.045, field_h + 0.045, cy, 0.012, _plain(ctx, "shadow", Color(0.018, 0.019, 0.02), 0.86, 0.0), FACE_Z + 0.177)
	var carriage_x := minf(0.38, field_w * 0.27)
	var carriage_y := cy + field_h * 0.5 + 0.215
	var carriage_transforms: Array[Transform3D] = []
	var shoe_transforms: Array[Transform3D] = []
	var grommet_transforms: Array[Transform3D] = []
	for side_value in [-1.0, 1.0]:
		var side := float(side_value)
		carriage_transforms.append(Transform3D(Basis.IDENTITY, Vector3(side * carriage_x, carriage_y, FACE_Z + 0.197)))
		shoe_transforms.append(Transform3D(Basis.IDENTITY, Vector3(side * field_w * 0.34, cy - field_h * 0.5 + 0.04, FACE_Z + 0.207)))
		grommet_transforms.append(Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)), Vector3(side * field_w * 0.42, cy - field_h * 0.5 + 0.13, FACE_Z + 0.202)))
	_add_multibox(ctx, micro, "FeatureHangerCarriages", carriage_transforms, Vector3(0.085, 0.055, 0.07), _plain(ctx, "blackened_steel", Color(0.08, 0.09, 0.095), 0.34, 0.7), "micro")
	_add_multibox(ctx, micro, "FeatureLevelingShoes", shoe_transforms, Vector3(0.075, 0.035, 0.06), _bronze(ctx, 4, Color(0.44, 0.31, 0.16)), "micro")
	_add_multicylinder(ctx, micro, "FeatureCableGrommets", grommet_transforms, 0.018, 0.018, _plain(ctx, "blackened_steel", Color(0.055, 0.06, 0.065), 0.4, 0.58), 10, "micro")
	ctx["story_elements"] = int(ctx["story_elements"]) + 4
	(ctx["construction_systems"] as Array).append("conservation_gasket_carriage_and_leveling")


# Service details follow maintenance logic rather than decorative greebling:
# hinges, ventilation, an ID carrier, and unions where the riser can be replaced.
static func _add_service_story(ctx: Dictionary, medium: Node3D, micro: Node3D, cabinet_x: float, cabinet_w: float, pipe_x: float, side: float, h: float) -> void:
	if int(ctx["quality"]) < 1:
		return
	var hinge_transforms: Array[Transform3D] = []
	var hinge_x := cabinet_x + side * (cabinet_w * 0.5 - 0.03)
	for y in [0.78, 1.15, 1.52]:
		hinge_transforms.append(Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)), Vector3(hinge_x, y, FACE_Z + 0.267)))
	_add_multicylinder(ctx, micro, "ServiceCabinetHinges", hinge_transforms, 0.014, 0.052, _bronze(ctx, 5, Color(0.4, 0.29, 0.16)), 8, "micro")
	var vent_transforms: Array[Transform3D] = []
	for index in range(4):
		vent_transforms.append(Transform3D(Basis.IDENTITY, Vector3(cabinet_x, 0.7 + float(index) * 0.045, FACE_Z + 0.259)))
	_add_multibox(ctx, micro, "ServiceCabinetVentSlots", vent_transforms, Vector3(cabinet_w * 0.42, 0.012, 0.018), _plain(ctx, "shadow", Color(0.03, 0.033, 0.035), 0.9, 0.1), "micro")
	_add_box(ctx, medium, "ServiceAssetLabelCarrier", Vector3(cabinet_x - side * cabinet_w * 0.16, 1.46, FACE_Z + 0.268), Vector3(cabinet_w * 0.34, 0.075, 0.024), _bronze(ctx, 6, Color(0.5, 0.36, 0.18)), "medium")
	var coupling_transforms: Array[Transform3D] = []
	for y in [0.92, minf(2.18, h - 1.05), h - 0.72]:
		coupling_transforms.append(Transform3D(Basis.IDENTITY, Vector3(pipe_x, y, FACE_Z + 0.18)))
	_add_multicylinder(ctx, micro, "ServiceRiserUnions", coupling_transforms, 0.037, 0.04, _bronze(ctx, 3, Color(0.52, 0.35, 0.16)), 10, "micro")
	ctx["story_elements"] = int(ctx["story_elements"]) + 4


# Hardware explains how a technician opens, bonds, and identifies the assembly.
# All repeated index marks share one MultiMesh and disappear with the micro LOD.
static func _add_service_hardware(ctx: Dictionary, medium: Node3D, micro: Node3D, cabinet_x: float, cabinet_w: float, pipe_x: float, side: float) -> void:
	if int(ctx["quality"]) < 1:
		return
	var pull_x := cabinet_x - side * (cabinet_w * 0.5 - 0.085)
	_add_box(ctx, medium, "ServiceFlushPullRecess", Vector3(pull_x, 1.17, FACE_Z + 0.269), Vector3(0.075, 0.22, 0.024), _plain(ctx, "shadow", Color(0.022, 0.025, 0.027), 0.88, 0.08), "medium")
	_add_box(ctx, micro, "ServiceFlushPull", Vector3(pull_x - side * 0.008, 1.17, FACE_Z + 0.287), Vector3(0.028, 0.15, 0.026), _bronze(ctx, 2, Color(0.5, 0.35, 0.17)), "micro")
	var bond_center := (cabinet_x + pipe_x) * 0.5
	var bond_width := absf(cabinet_x - pipe_x) + 0.04
	_add_box(ctx, medium, "ServiceEquipotentialBond", Vector3(bond_center, 0.47, FACE_Z + 0.205), Vector3(bond_width, 0.026, 0.028), _bronze(ctx, 1, Color(0.54, 0.36, 0.15)), "medium")
	var index_transforms: Array[Transform3D] = []
	for index in range(5):
		index_transforms.append(Transform3D(Basis.IDENTITY, Vector3(cabinet_x + side * (-0.12 + float(index) * 0.055), 1.43, FACE_Z + 0.288)))
	_add_multibox(ctx, micro, "ServiceCircuitIndexTicks", index_transforms, Vector3(0.028, 0.011, 0.012), _bronze(ctx, 6, Color(0.62, 0.44, 0.21)), "micro")
	ctx["story_elements"] = int(ctx["story_elements"]) + 4
	(ctx["construction_systems"] as Array).append("maintainable_bonded_service_hardware")


# The terminal becomes spatially legible through a dressed infill, return bed
# joints, and one pinned sacrificial corner plate at hand/cart impact height.
static func _add_endcap_story(ctx: Dictionary, medium: Node3D, micro: Node3D, infill_x: float, infill_w: float, edge_x: float, side: float, h: float) -> void:
	if int(ctx["quality"]) < 1:
		return
	var joint_transforms: Array[Transform3D] = []
	for y in [1.24, minf(2.52, h - 0.7)]:
		joint_transforms.append(Transform3D(Basis.IDENTITY, Vector3(infill_x, y, FACE_Z + 0.044)))
	_add_multibox(ctx, micro, "EndcapInfillBedJoints", joint_transforms, Vector3(infill_w - 0.06, 0.008, 0.015), _plain(ctx, "shadow", Color(0.03, 0.027, 0.024), 0.93, 0.0), "micro")
	var return_joints: Array[Transform3D] = []
	for y in [1.02, 2.06, h - 0.72]:
		return_joints.append(Transform3D(Basis.IDENTITY, Vector3(edge_x, y, -0.17)))
	_add_multibox(ctx, micro, "EndcapReturnBedJoints", return_joints, Vector3(0.21, 0.012, 0.505), _plain(ctx, "shadow", Color(0.03, 0.027, 0.024), 0.93, 0.0), "micro")
	var repair_y := 0.88 + float(posmod(int(ctx["seed"]), 4)) * 0.06
	_add_box(ctx, medium, "EndcapCornerRepairPlate", Vector3(edge_x, repair_y, FACE_Z + 0.222), Vector3(0.15, 0.2, 0.025), _bronze(ctx, 5, Color(0.68, 0.48, 0.23)), "medium")
	var pin_transforms: Array[Transform3D] = []
	for sy in [-1.0, 1.0]:
		pin_transforms.append(Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)), Vector3(edge_x, repair_y + float(sy) * 0.052, FACE_Z + 0.24)))
	_add_multicylinder(ctx, micro, "EndcapCornerRepairPins", pin_transforms, 0.008, 0.012, _bronze(ctx, 7, Color(0.58, 0.42, 0.22)), 8, "micro")
	ctx["story_elements"] = int(ctx["story_elements"]) + 4


# A compressed return seal and sacrificial trolley guard make the terminal read
# as the end of a buildable run from front and grazing views.
static func _add_endcap_hardware(ctx: Dictionary, medium: Node3D, micro: Node3D, edge_x: float, side: float, h: float) -> void:
	if int(ctx["quality"]) < 1:
		return
	_add_box(ctx, medium, "EndcapReturnSeal", Vector3(edge_x, h * 0.5, -0.426), Vector3(0.15, h - 0.54, 0.018), _plain(ctx, "shadow", Color(0.02, 0.022, 0.022), 0.86, 0.02), "medium")
	_add_cylinder(ctx, medium, "EndcapTrolleyGuard", Vector3(edge_x - side * 0.07, 0.92, FACE_Z + 0.225), 0.026, 0.82, _bronze(ctx, 3, Color(0.42, 0.3, 0.16)), Vector3.ZERO, 10, "medium")
	_add_box(ctx, medium, "EndcapDatumKey", Vector3(edge_x - side * 0.025, 1.48, FACE_Z + 0.225), Vector3(0.13, 0.075, 0.035), _plain(ctx, "blackened_steel", Color(0.075, 0.085, 0.09), 0.38, 0.68), "medium")
	var pin_transforms: Array[Transform3D] = []
	for side_y in [-1.0, 1.0]:
		pin_transforms.append(Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)), Vector3(edge_x - side * 0.025, 1.48 + float(side_y) * 0.018, FACE_Z + 0.247)))
	_add_multicylinder(ctx, micro, "EndcapDatumKeyPins", pin_transforms, 0.006, 0.01, _bronze(ctx, 7, Color(0.56, 0.4, 0.2)), 8, "micro")
	ctx["story_elements"] = int(ctx["story_elements"]) + 4
	(ctx["construction_systems"] as Array).append("terminal_return_seal_and_trolley_guard")


static func _add_frame(ctx: Dictionary, parent: Node3D, prefix: String, frame_w: float, frame_h: float, cy: float, rail: float, surface: Variant, z: float) -> void:
	_add_box(ctx, parent, prefix + "_Left", Vector3(-frame_w * 0.5 + rail * 0.5, cy, z), Vector3(rail, frame_h, 0.055), surface, "medium")
	_add_box(ctx, parent, prefix + "_Right", Vector3(frame_w * 0.5 - rail * 0.5, cy, z), Vector3(rail, frame_h, 0.055), surface, "medium")
	_add_box(ctx, parent, prefix + "_Top", Vector3(0, cy + frame_h * 0.5 - rail * 0.5, z), Vector3(frame_w - rail * 2.0, rail, 0.055), surface, "medium")
	_add_box(ctx, parent, prefix + "_Bottom", Vector3(0, cy - frame_h * 0.5 + rail * 0.5, z), Vector3(frame_w - rail * 2.0, rail, 0.055), surface, "medium")


static func _add_anchor_array(ctx: Dictionary, parent: Node3D, w: float, h: float, prefix: String, radius: float) -> void:
	if int(ctx["quality"]) < 2:
		return
	var transforms: Array[Transform3D] = []
	for cell in range(int(w)):
		var x := -w * 0.5 + float(cell) + 0.5
		for y in [0.56, h - 0.56]:
			transforms.append(Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)), Vector3(x, y, FACE_Z + 0.115)))
	_add_multicylinder(ctx, parent, prefix, transforms, radius, 0.025, _bronze(ctx, 7, Color(0.34, 0.25, 0.16)), 8, "micro")


static func _add_pipe_clamps(ctx: Dictionary, parent: Node3D, pipe_x: float, h: float) -> void:
	if int(ctx["quality"]) < 1:
		return
	var transforms: Array[Transform3D] = []
	for y in [0.72, minf(1.66, h - 1.0), h - 0.72]:
		transforms.append(Transform3D(Basis.IDENTITY, Vector3(pipe_x, y, FACE_Z + 0.21)))
	_add_multibox(ctx, parent, "ServicePipeClamps", transforms, Vector3(0.12, 0.045, 0.055), _bronze(ctx, 4, Color(0.31, 0.23, 0.15)), "micro")


static func _add_endcap_studs(ctx: Dictionary, parent: Node3D, edge_x: float, h: float) -> void:
	if int(ctx["quality"]) < 2:
		return
	var transforms: Array[Transform3D] = []
	for y in [0.62, 1.25, h - 1.18, h - 0.58]:
		transforms.append(Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)), Vector3(edge_x, y, FACE_Z + 0.225)))
	_add_multicylinder(ctx, parent, "EndcapAnchorStuds", transforms, 0.032, 0.026, _bronze(ctx, 6, Color(0.46, 0.33, 0.18)), 8, "micro")


static func _add_contact_breakup(ctx: Dictionary, parent: Node3D, w: float, family: String) -> void:
	if int(ctx["quality"]) < 1:
		return
	var variant := posmod(int(ctx["seed"]), 7)
	var side := -1.0 if variant % 2 == 0 else 1.0
	var patch_w := minf(0.22, w * 0.18)
	var x := side * (w * 0.5 - patch_w * 0.62 - 0.025)
	var tint := Color(0.105, 0.075, 0.045, 1.0) if family != "service" else Color(0.035, 0.045, 0.05, 1.0)
	var main_patch := _add_box(ctx, parent, "%sAsymmetricContactPatina" % family.capitalize(), Vector3(x, 0.29, FACE_Z + 0.174), Vector3(patch_w, 0.05 + float(variant % 3) * 0.009, 0.012), _plain(ctx, "contact_patina", tint, 0.94, 0.0), "micro")
	main_patch.rotation.z = side * (0.018 + float(variant % 2) * 0.012)
	var feather_w := patch_w * 0.43
	var feather := _add_box(ctx, parent, "%sContactPatinaFeather" % family.capitalize(), Vector3(x - side * patch_w * 0.24, 0.345, FACE_Z + 0.169), Vector3(feather_w, 0.016, 0.009), _plain(ctx, "contact_patina", tint, 0.94, 0.0), "micro")
	feather.rotation.z = -side * 0.045
	ctx["story_elements"] = int(ctx["story_elements"]) + 2


static func _add_family_wear(ctx: Dictionary, parent: Node3D, family: String) -> void:
	var wear := str(ctx["wear"])
	if wear == "pristine" or int(ctx["quality"]) < 2:
		return
	var w: float = ctx["width"]
	var seed := posmod(int(ctx["seed"]), 13)
	var side := -1.0 if seed % 2 == 0 else 1.0
	var x := side * (w * 0.5 - 0.16 - float(seed % 3) * 0.04)
	var y := 0.38 + float(seed % 5) * 0.13
	var size := Vector3(0.12, 0.024, 0.014) if family != "service" else Vector3(0.08, 0.035, 0.014)
	var scar := _add_box(ctx, parent, "%sUseScar" % family.capitalize(), Vector3(x, y, FACE_Z + 0.2), size, _plain(ctx, "wear_scar", Color(0.12, 0.09, 0.06), 0.82, 0.05), "micro")
	scar.rotation.z = side * (0.16 + float(seed % 4) * 0.07)
	ctx["story_elements"] = int(ctx["story_elements"]) + 1
	if wear == "damaged":
		var chip := _add_box(ctx, parent, "%sImpactChip" % family.capitalize(), Vector3(x - side * 0.1, y + 0.1, FACE_Z + 0.195), Vector3(0.075, 0.06, 0.018), _plain(ctx, "damage_core", Color(0.045, 0.04, 0.035), 0.96, 0.0), "micro")
		chip.rotation.z = -side * 0.38
		ctx["story_elements"] = int(ctx["story_elements"]) + 1


static func _make_groups(root: Node3D) -> Dictionary:
	var groups := {}
	for group_name in ["Macro", "Medium", "Micro", "Physics", "Contracts"]:
		var node := Node3D.new()
		node.name = group_name
		root.add_child(node)
		groups[group_name.to_lower()] = node
	return groups


static func _add_box(ctx: Dictionary, parent: Node3D, node_name: String, at: Vector3, size: Vector3, surface: Variant, lod: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.mesh = _box_mesh(size)
	_apply_surface_style(instance, surface)
	_apply_lod(instance, lod)
	_apply_collision_role(ctx, instance, node_name)
	parent.add_child(instance)
	_count_draw(ctx, lod, 44)
	_track_x(ctx, at.x - size.x * 0.5, at.x + size.x * 0.5)
	return instance


static func _add_cylinder(ctx: Dictionary, parent: Node3D, node_name: String, at: Vector3, radius: float, length: float, surface: Variant, rotation_degrees: Vector3, sides: int, lod: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.rotation_degrees = rotation_degrees
	instance.mesh = _cylinder_mesh(radius, length, sides)
	_apply_surface_style(instance, surface)
	_apply_lod(instance, lod)
	_apply_collision_role(ctx, instance, node_name)
	parent.add_child(instance)
	_count_draw(ctx, lod, sides * 4)
	var along_x := absf(rotation_degrees.z) > 45.0
	var x_extent := length * 0.5 if along_x else radius
	_track_x(ctx, at.x - x_extent, at.x + x_extent)
	return instance


static func _add_multibox(ctx: Dictionary, parent: Node3D, node_name: String, transforms: Array[Transform3D], size: Vector3, surface: Variant, lod: String) -> void:
	if transforms.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _box_mesh(size)
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
		_track_x(ctx, transforms[index].origin.x - size.x * 0.5, transforms[index].origin.x + size.x * 0.5)
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	_apply_surface_style(instance, surface)
	_apply_lod(instance, lod)
	parent.add_child(instance)
	ctx["multimeshes"] = int(ctx["multimeshes"]) + 1
	_count_draw(ctx, lod, 44 * transforms.size(), false)


static func _add_multicylinder(ctx: Dictionary, parent: Node3D, node_name: String, transforms: Array[Transform3D], radius: float, length: float, surface: Variant, sides: int, lod: String) -> void:
	if transforms.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _cylinder_mesh(radius, length, sides)
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
		_track_x(ctx, transforms[index].origin.x - radius, transforms[index].origin.x + radius)
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	_apply_surface_style(instance, surface)
	_apply_lod(instance, lod)
	parent.add_child(instance)
	ctx["multimeshes"] = int(ctx["multimeshes"]) + 1
	_count_draw(ctx, lod, sides * 4 * transforms.size(), false)


static func _apply_surface_style(instance: GeometryInstance3D, surface: Variant) -> void:
	if surface is Dictionary:
		var style: Dictionary = surface
		instance.material_override = style.get("material") as Material
	else:
		instance.material_override = surface as Material


## Every detail mesh declares its collision intent. Most authored joinery and wear
## is visual-only; the small set with a simple primitive counterpart is promoted
## only when MuseumWallPiece owns the named canonical body.
static func _apply_collision_role(ctx: Dictionary, instance: MeshInstance3D, node_name: String) -> void:
	instance.set_meta("collision_role", "visual_only")
	instance.set_meta("physics_surface_id", "")
	instance.set_meta("collision_target", "")
	instance.set_meta("collision_shape_targets", PackedStringArray())
	if not bool(ctx.get("canonical_collision_owner", false)):
		return
	var family := str(ctx.get("family", ""))
	var surface_id := ""
	var shape_target := ""
	if family == "solid" and node_name.begins_with("SolidStoneField_"):
		surface_id = "stone"
		shape_target = "StoneShape03"
	elif family == "feature" and node_name == "FeatureHangingBus":
		surface_id = "bronze"
		shape_target = "BronzeShape01"
	elif family == "service" and node_name == "ServiceHeaderRaceway":
		surface_id = "painted_metal"
		shape_target = "PaintedMetalShape02"
	elif family == "endcap" and node_name == "EndcapStoneReturn":
		surface_id = "stone"
		shape_target = "StoneShape04"
	elif family == "endcap" and node_name == "EndcapArmouredShoe":
		surface_id = "bronze"
		shape_target = "BronzeShape01"
	elif family == "endcap" and node_name == "EndcapTrolleyGuard":
		surface_id = "bronze"
		shape_target = "BronzeShape02"
	if surface_id.is_empty():
		return
	instance.set_meta("collision_role", "solid")
	instance.set_meta("physics_surface_id", surface_id)
	var target := "CollisionStone"
	if surface_id == "bronze":
		target = "CollisionBronze"
	elif surface_id == "painted_metal":
		target = "CollisionPaintedMetal"
	instance.set_meta("collision_target", target)
	instance.set_meta("collision_shape_targets", PackedStringArray([shape_target]))


static func _add_collision(ctx: Dictionary, node_name: String, at: Vector3, size: Vector3, metadata: Dictionary) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	var surface_id := str(metadata.get("surface_id", metadata.get("surface_audio", "stone")))
	var physics_spec := _physics_surface_spec(surface_id)
	body.physics_material_override = _get_physics_material(surface_id)
	body.set_meta("museum_physics_profile", "museum_surface_zones_v2")
	body.set_meta("physics_surface_id", surface_id)
	body.set_meta("surface_id", surface_id)
	body.set_meta("surface_audio", surface_id)
	body.set_meta("friction", float(physics_spec["friction"]))
	body.set_meta("bounce", float(physics_spec["bounce"]))
	body.set_meta("collision_scope", "helper_protrusion")
	for key in metadata:
		body.set_meta(str(key), metadata[key])
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	ctx["groups"]["physics"].add_child(body)
	ctx["colliders"] = int(ctx["colliders"]) + 1
	_track_x(ctx, at.x - size.x * 0.5, at.x + size.x * 0.5)


static func _add_marker(parent: Node3D, node_name: String, at: Vector3, metadata: Dictionary) -> void:
	var marker := Marker3D.new()
	marker.name = node_name
	marker.position = at
	for key in metadata:
		marker.set_meta(str(key), metadata[key])
	parent.add_child(marker)


static func _apply_lod(instance: GeometryInstance3D, lod: String) -> void:
	if lod == "micro":
		instance.visibility_range_end = MICRO_LOD_END_M
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elif lod == "medium":
		instance.visibility_range_end = MEDIUM_LOD_END_M
	instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED


static func _count_draw(ctx: Dictionary, lod: String, triangles: int, count_mesh: bool = true) -> void:
	if count_mesh:
		ctx["meshes"] = int(ctx["meshes"]) + 1
	ctx["triangles"] = int(ctx["triangles"]) + triangles
	var key := "draw_%s" % lod
	ctx[key] = int(ctx[key]) + 1


static func _track_x(ctx: Dictionary, min_x: float, max_x: float) -> void:
	ctx["bounds_min_x"] = minf(float(ctx["bounds_min_x"]), min_x)
	ctx["bounds_max_x"] = maxf(float(ctx["bounds_max_x"]), max_x)


static func _box_mesh(size: Vector3) -> Mesh:
	var smallest_half := minf(size.x, minf(size.y, size.z)) * 0.5
	var bevel := minf(0.018, maxf(0.0015, smallest_half * 0.34))
	var key := "chamfer:%.4f:%.4f:%.4f:%.4f" % [size.x, size.y, size.z, bevel]
	if _box_mesh_cache.has(key):
		return _box_mesh_cache[key]
	var mesh := _build_chamfered_box(size, bevel)
	_box_mesh_cache[key] = mesh
	return mesh


# Convex 26-face architectural profile: six planes, twelve bevels, eight corners.
# Bounds remain exactly +/- size/2; flat, authored normals give stable highlights.
static func _build_chamfered_box(size: Vector3, bevel: float) -> ArrayMesh:
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5
	var ix := hx - bevel
	var iy := hy - bevel
	var iz := hz - bevel
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	_emit_profile_quad(st, Vector3(-ix, -iy, hz), Vector3(ix, -iy, hz), Vector3(ix, iy, hz), Vector3(-ix, iy, hz), Vector3.BACK)
	_emit_profile_quad(st, Vector3(-ix, -iy, -hz), Vector3(-ix, iy, -hz), Vector3(ix, iy, -hz), Vector3(ix, -iy, -hz), Vector3.FORWARD)
	_emit_profile_quad(st, Vector3(hx, -iy, -iz), Vector3(hx, iy, -iz), Vector3(hx, iy, iz), Vector3(hx, -iy, iz), Vector3.RIGHT)
	_emit_profile_quad(st, Vector3(-hx, -iy, -iz), Vector3(-hx, -iy, iz), Vector3(-hx, iy, iz), Vector3(-hx, iy, -iz), Vector3.LEFT)
	_emit_profile_quad(st, Vector3(-ix, hy, -iz), Vector3(-ix, hy, iz), Vector3(ix, hy, iz), Vector3(ix, hy, -iz), Vector3.UP)
	_emit_profile_quad(st, Vector3(-ix, -hy, -iz), Vector3(ix, -hy, -iz), Vector3(ix, -hy, iz), Vector3(-ix, -hy, iz), Vector3.DOWN)

	for sy_value in [-1.0, 1.0]:
		var sy := float(sy_value)
		for sz_value in [-1.0, 1.0]:
			var sz := float(sz_value)
			_emit_profile_quad(st, Vector3(-ix, sy * hy, sz * iz), Vector3(ix, sy * hy, sz * iz), Vector3(ix, sy * iy, sz * hz), Vector3(-ix, sy * iy, sz * hz), Vector3(0, sy, sz).normalized())
	for sx_value in [-1.0, 1.0]:
		var sx := float(sx_value)
		for sz_value in [-1.0, 1.0]:
			var sz := float(sz_value)
			_emit_profile_quad(st, Vector3(sx * hx, -iy, sz * iz), Vector3(sx * hx, iy, sz * iz), Vector3(sx * ix, iy, sz * hz), Vector3(sx * ix, -iy, sz * hz), Vector3(sx, 0, sz).normalized())
	for sx_value in [-1.0, 1.0]:
		var sx := float(sx_value)
		for sy_value in [-1.0, 1.0]:
			var sy := float(sy_value)
			_emit_profile_quad(st, Vector3(sx * hx, sy * iy, -iz), Vector3(sx * hx, sy * iy, iz), Vector3(sx * ix, sy * hy, iz), Vector3(sx * ix, sy * hy, -iz), Vector3(sx, sy, 0).normalized())

	for sx_value in [-1.0, 1.0]:
		var sx := float(sx_value)
		for sy_value in [-1.0, 1.0]:
			var sy := float(sy_value)
			for sz_value in [-1.0, 1.0]:
				var sz := float(sz_value)
				_emit_profile_triangle(st, Vector3(sx * hx, sy * iy, sz * iz), Vector3(sx * ix, sy * hy, sz * iz), Vector3(sx * ix, sy * iy, sz * hz), Vector3(sx, sy, sz).normalized())

	st.index()
	st.generate_tangents()
	return st.commit()


static func _emit_profile_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	_emit_profile_triangle(st, a, b, c, normal)
	_emit_profile_triangle(st, a, c, d, normal)


static func _emit_profile_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	var second := b
	var third := c
	if (second - a).cross(third - a).dot(normal) < 0.0:
		second = c
		third = b
	for vertex in [a, second, third]:
		st.set_normal(normal)
		st.set_uv(_profile_uv(vertex, normal))
		st.add_vertex(vertex)


static func _profile_uv(vertex: Vector3, normal: Vector3) -> Vector2:
	var absolute := normal.abs()
	if absolute.x >= absolute.y and absolute.x >= absolute.z:
		return Vector2(vertex.z, vertex.y)
	if absolute.y >= absolute.z:
		return Vector2(vertex.x, vertex.z)
	return Vector2(vertex.x, vertex.y)


static func _cylinder_mesh(radius: float, length: float, sides: int) -> CylinderMesh:
	var key := "%.4f:%.4f:%d" % [radius, length, sides]
	if _cylinder_mesh_cache.has(key):
		return _cylinder_mesh_cache[key]
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = sides
	mesh.rings = 1
	_cylinder_mesh_cache[key] = mesh
	return mesh


static func _stone(ctx: Dictionary, cell_index: int, tint: Color) -> Dictionary:
	var variant := int(uv_variant(int(ctx["seed"]), cell_index)["index"])
	(ctx["material_keys"] as Dictionary)["canonical_pbr:stone"] = true
	return {"material": create_pbr_material("stone", tint, Vector2(1.65, 2.35), variant), "tint": tint, "variant": variant}


static func _bronze(ctx: Dictionary, cell_index: int, tint: Color) -> Dictionary:
	var variant := int(uv_variant(int(ctx["seed"]) + 11, cell_index)["index"])
	(ctx["material_keys"] as Dictionary)["canonical_pbr:bronze"] = true
	return {"material": create_pbr_material("bronze", tint, Vector2(2.4, 2.4), variant), "tint": tint, "variant": variant}


static func _plain(ctx: Dictionary, role: String, color: Color, roughness: float, metallic: float) -> Material:
	var spec := _flat_style_spec(role, color, roughness, metallic, 0.0)
	(ctx["material_keys"] as Dictionary)["pooled_flat:%s" % spec["key"]] = true
	return _flat_material(spec)


static func _emissive(ctx: Dictionary, role: String, color: Color, energy: float) -> Material:
	var spec := _flat_style_spec(role, color, 0.32, 0.0, energy)
	(ctx["material_keys"] as Dictionary)["pooled_flat:%s" % spec["key"]] = true
	return _flat_material(spec)


static func _flat_material(spec: Dictionary) -> Material:
	var key := "pooled_flat:%s" % spec["key"]
	if _material_cache.has(key):
		return _material_cache[key]
	if _flat_shader == null:
		_flat_shader = Shader.new()
		_flat_shader.code = FLAT_SHADER_CODE
	var material := ShaderMaterial.new()
	material.shader = _flat_shader
	material.set_shader_parameter("flat_color", spec["color"])
	material.set_shader_parameter("flat_surface", Vector4(float(spec["roughness"]), float(spec["metallic"]), float(spec["emission"]), 0.0))
	var story := Vector3(0.035, 0.1, 0.0)
	if spec["key"] == "dark_metal":
		story = Vector3(0.14, 0.34, 0.04)
	elif spec["key"] == "wear":
		story = Vector3(0.16, 0.06, 0.12)
	elif spec["key"] == "shadow":
		story = Vector3.ZERO
	elif str(spec["key"]).begins_with("emissive") or str(spec["key"]).begins_with("signal"):
		story = Vector3.ZERO
	material.set_shader_parameter("flat_story", story)
	material.resource_name = "Museum pooled %s" % str(spec["key"])
	material.set_meta("museum_material_pool_key", key)
	material.set_meta("museum_surface_role", str(spec["key"]))
	_material_cache[key] = material
	return material


static func _flat_style_spec(role: String, requested_color: Color, roughness: float, metallic: float, emission: float) -> Dictionary:
	if emission > 0.0:
		if role.contains("warm"):
			return {"key": "emissive_warm", "color": Color(1.0, 0.68, 0.35), "roughness": 0.32, "metallic": 0.0, "emission": 1.8}
		if role.ends_with("_1"):
			return {"key": "signal_warm", "color": Color(1.0, 0.56, 0.12), "roughness": 0.32, "metallic": 0.0, "emission": 1.25}
		return {"key": "signal_cool", "color": Color(0.14, 0.72, 0.8), "roughness": 0.32, "metallic": 0.0, "emission": 1.25}
	if role in ["shadow", "damage_core"]:
		return {"key": "shadow", "color": Color(0.025, 0.024, 0.023), "roughness": 0.9, "metallic": 0.0, "emission": 0.0}
	if role in ["blackened_steel", "service_steel"]:
		return {"key": "dark_metal", "color": Color(0.12, 0.138, 0.148), "roughness": 0.38, "metallic": 0.68, "emission": 0.0}
	if role in ["contact_patina", "wear_scar"]:
		return {"key": "wear", "color": Color(0.42, 0.3, 0.17), "roughness": 0.9, "metallic": 0.02, "emission": 0.0}
	return {"key": "neutral", "color": requested_color, "roughness": roughness, "metallic": metallic, "emission": 0.0}


static func _surface_maps(surface: String) -> Dictionary:
	var prefix := "aaa_trim_bronze_" if surface == "bronze" else "aaa_wall_stone_"
	var maps := {}
	for channel in ["albedo", "normal", "roughness", "ao", "height"]:
		maps[channel] = _load_texture(MATERIAL_ROOT + prefix + channel + ".png")
	maps["metallic"] = _load_texture(MATERIAL_ROOT + "aaa_trim_bronze_metallic.png") if surface == "bronze" else maps["roughness"]
	return maps


static func _load_texture(resource_path: String) -> Texture2D:
	if _texture_cache.has(resource_path):
		return _texture_cache[resource_path]
	var texture: Texture2D
	if ResourceLoader.exists(resource_path):
		texture = ResourceLoader.load(resource_path) as Texture2D
	if texture == null:
		var image := Image.load_from_file(ProjectSettings.globalize_path(resource_path))
		if image != null and not image.is_empty():
			if not image.has_mipmaps():
				image.generate_mipmaps()
			texture = ImageTexture.create_from_image(image)
	if texture == null:
		push_error("MuseumWallArchitecturalSpans: failed to load %s" % resource_path)
	_texture_cache[resource_path] = texture
	return texture


static func _physics_surface_spec(surface_id: String) -> Dictionary:
	match surface_id:
		"painted_metal": return {"friction": 0.55, "bounce": 0.03}
		"bronze": return {"friction": 0.48, "bounce": 0.04}
	return {"friction": 0.82, "bounce": 0.02}


static func _get_physics_material(surface_id: String) -> PhysicsMaterial:
	if _physics_material_cache.has(surface_id):
		return _physics_material_cache[surface_id]
	var spec := _physics_surface_spec(surface_id)
	var material := PhysicsMaterial.new()
	material.resource_name = "Museum collision %s" % surface_id
	material.friction = float(spec["friction"])
	material.rough = true
	material.bounce = float(spec["bounce"])
	material.set_meta("surface_id", surface_id)
	_physics_material_cache[surface_id] = material
	return material


static func _family_contract(family: String, flip: bool) -> Dictionary:
	match family:
		"solid": return {"role": "load_bearing_infill", "attachment": "masonry_bed_and_datum_rail", "construction": "staggered_ashlar_with_fitted_repair", "feature_safe": true}
		"feature": return {"role": "protected_exhibition_field", "attachment": "rated_picture_bus", "construction": "gasketed_frame_with_carriages_and_leveling_shoes", "feature_safe": true}
		"service": return {"role": "peripheral_building_services", "attachment": "recessed_backplane", "construction": "hinged_bonded_service_cabinet_and_replaceable_risers", "prop_zone": "edge", "side": "right" if flip else "left"}
		"endcap": return {"role": "run_termination_and_return", "attachment": "terminal_pier", "construction": "sealed_return_with_sacrificial_trolley_guard", "side": "right" if flip else "left"}
	return {}
