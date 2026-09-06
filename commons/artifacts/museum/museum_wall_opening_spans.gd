# museum_wall_opening_spans.gd
# High-detail, allocation-stable construction helper for museum window, vitrine,
# and portal spans. The caller owns the one-metre wall contract and supplies a
# shared material palette; this helper owns only geometry inside that span.
#
# Public API:
#   MuseumWallOpeningSpans.build(parent, kind, width_cells, height, palette, options)
#   MuseumWallOpeningSpans.contract_for(kind, width_cells, height, detail_tier)
#
# No process callback is used. Repeated boxes share one unit mesh, hardware is
# batched in MultiMeshInstance3D nodes, and fallback PBR materials are cached.

extends RefCounted
class_name MuseumWallOpeningSpans

const SUPPORTED_KINDS: Array[StringName] = [&"window", &"vitrine", &"portal"]
const GRID_M := 1.0
const WALL_DEPTH_M := 0.15
const HERO_DETAIL_END_M := 12.0
const SECONDARY_DETAIL_END_M := 28.0
const MATERIAL_ROOT := "res://commons/materials/museum/"

const DETAIL_HERO := 0
const DETAIL_STANDARD := 1
const DETAIL_MOBILE := 2

const SURFACE_CONTRACTS := {
	"stone": {"friction": 0.82, "bounce": 0.02, "impact": "stone_dense", "decal": "mineral_chip", "breakability": "none"},
	"bronze": {"friction": 0.48, "bounce": 0.04, "impact": "metal_resonant", "decal": "metal_scuff", "breakability": "none"},
	"painted_metal": {"friction": 0.55, "bounce": 0.03, "impact": "metal_hollow", "decal": "paint_chip", "breakability": "service_only"},
	"glass_laminated": {"friction": 0.22, "bounce": 0.06, "impact": "glass_laminated", "decal": "glass_mark", "breakability": "authored_only"},
	"rubber": {"friction": 0.9, "bounce": 0.12, "impact": "rubber_soft", "decal": "none", "breakability": "none"},
}

const GLASS_SHADER_CODE := """
shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_tint : source_color = vec4(0.97, 0.985, 1.0, 0.018);
uniform vec4 edge_tint : source_color = vec4(0.18, 0.43, 0.45, 0.34);
uniform float surface_roughness : hint_range(0.01, 0.5) = 0.04;
uniform float pane_thickness : hint_range(0.001, 0.1) = 0.016;

void fragment() {
	float ndv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fresnel = 0.04 + 0.96 * pow(1.0 - ndv, 5.0);
	float uv_edge_distance = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float edge_band = 1.0 - smoothstep(0.003, 0.04, uv_edge_distance);
	float optical_path = pane_thickness / max(ndv, 0.22);
	vec3 absorption = exp(-vec3(0.32, 0.12, 0.085) * optical_path * 8.0);
	float edge_weight = clamp(edge_band * 0.78 + fresnel * 0.42, 0.0, 1.0);
	ALBEDO = mix(base_tint.rgb, edge_tint.rgb, edge_weight * 0.5) * absorption;
	ROUGHNESS = mix(surface_roughness, 0.018, fresnel);
	METALLIC = 0.0;
	SPECULAR = 0.9;
	ALPHA = clamp(base_tint.a + fresnel * 0.13 + edge_band * edge_tint.a * 0.5 + optical_path * 0.012, 0.012, 0.46);
}
"""

const GLASS_RESIDUE_SHADER_CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 residue_tint : source_color = vec4(0.72, 0.69, 0.61, 0.085);

void fragment() {
	vec2 p = (UV - vec2(0.5)) * vec2(2.0, 2.18);
	float radius = length(p);
	float rings = 0.5 + 0.5 * sin(radius * 76.0 + p.x * 8.0);
	float ridge = smoothstep(0.68, 0.94, rings);
	float broken = smoothstep(0.2, 0.82, 0.5 + 0.5 * sin(p.x * 31.0 + p.y * 19.0));
	float mask = smoothstep(0.98, 0.2, radius) * ridge * mix(0.45, 1.0, broken);
	ALBEDO = residue_tint.rgb;
	ROUGHNESS = 0.86;
	SPECULAR = 0.25;
	ALPHA = clamp(mask * residue_tint.a, 0.0, 0.105);
}
"""


class GlassImpactHook:
	extends Area3D
	signal impact(energy_j: float)

	func apply_impact(energy_j: float) -> void:
		impact.emit(maxf(0.0, energy_j))

static var _unit_box_mesh: BoxMesh
static var _fastener_mesh: CylinderMesh
static var _vitrine_artifact_torus: TorusMesh
static var _vitrine_artifact_pin: CylinderMesh
static var _vitrine_hinge_mesh: CylinderMesh
static var _glass_wear_quad: QuadMesh
static var _glass_physics_material: PhysicsMaterial
static var _stone_physics_material: PhysicsMaterial
static var _bronze_physics_material: PhysicsMaterial
static var _painted_metal_physics_material: PhysicsMaterial
static var _rubber_physics_material: PhysicsMaterial
static var _glass_shader: Shader
static var _glass_residue_shader: Shader
static var _glass_residue_material: ShaderMaterial
static var _chamfer_mesh_cache: Dictionary = {}
static var _shape_cache: Dictionary = {}
static var _palette_cache: Dictionary = {}
static var _texture_cache: Dictionary = {}


## Builds one complete opening span under `parent` and returns its live assembly,
## immutable dimensional contract, and measured build budget. Palette resources
## are never duplicated. Supported palette slots are: stone, stone_alt, trim,
## bronze, glass, glass_inner, gasket, dark, backing, emissive, safety, and wear.
## Options: enable_collision, enable_interaction_hooks, enable_local_lights,
## detail_tier (0..2), seed, flip, interaction_layer, break_threshold_j, shelves.
static func build(
		parent: Node3D,
		kind_value: Variant,
		width_cells_value: int,
		height_value: float,
		palette: Dictionary = {},
		options: Dictionary = {}
	) -> Dictionary:
	var kind := StringName(str(kind_value).to_lower())
	if not SUPPORTED_KINDS.has(kind):
		return {"ok": false, "error": "unsupported_kind", "kind": str(kind)}
	var cells := clampi(width_cells_value, 2, 4)
	var height := clampf(height_value, 3.0, 6.0)
	var detail_tier := clampi(int(options.get("detail_tier", DETAIL_HERO)), DETAIL_HERO, DETAIL_MOBILE)
	var resolved_palette := palette if not palette.is_empty() else default_palette(str(options.get("finish", "uffizi_stone")))
	var contract := contract_for(kind, cells, height, detail_tier)
	var stats := {
		"mesh_instances": 0,
		"profile_mesh_instances": 0,
		"multimesh_draws": 0,
		"multimesh_instances": 0,
		"estimated_triangles_lod0": 0,
		"collision_shapes": 0,
		"collision_bodies": 0,
		"collision_shapes_by_surface": {},
		"interaction_areas": 0,
		"local_lights": 0,
		"glass_residue_instances": 0,
		"tertiary_elements": 0,
	}
	var assembly := Node3D.new()
	assembly.name = "%sOpeningSpan_%dm" % [str(kind).capitalize(), cells]
	assembly.set_meta("schema", "ada-museum-opening-span-v2")
	assembly.set_meta("kind", str(kind))
	assembly.set_meta("width_m", float(cells))
	assembly.set_meta("height_m", height)
	assembly.set_meta("grid_m", GRID_M)
	assembly.set_meta("construction_depth_m", contract["construction_depth_m"])
	assembly.set_meta("clear_opening_m", contract["clear_opening_m"])
	assembly.set_meta("collision_truth", contract["collision_truth"])
	assembly.set_meta("lod_policy", contract["lod_policy"])
	assembly.set_meta("surface_slots", PackedStringArray(["stone", "stone_alt", "trim", "bronze", "glass", "glass_edge", "glass_residue", "gasket", "backing"]))
	assembly.set_meta("uv_contract", "world_triplanar_stone; linear_trim; deterministic_detail_phase")
	assembly.set_meta("detail_seed", _resolved_seed(kind, cells, height, options))
	parent.add_child(assembly)

	match kind:
		&"window":
			_build_window(assembly, cells, height, resolved_palette, options, contract, stats)
		&"vitrine":
			_build_vitrine(assembly, cells, height, resolved_palette, options, contract, stats)
		&"portal":
			_build_portal(assembly, cells, height, resolved_palette, options, contract, stats)
	_author_collision_visual_roles(assembly, kind)

	contract["budget"] = stats.duplicate(true)
	assembly.set_meta("budget", stats.duplicate(true))
	assembly.set_meta("physics_surface_zones", (stats["collision_shapes_by_surface"] as Dictionary).duplicate(true))
	assembly.set_meta("shared_unit_mesh", true)
	assembly.set_meta("no_process_allocation", true)
	assembly.set_meta("instance_uniforms_used", false)
	assembly.set_meta("material_pool_contract", "cached_palette_and_one_shared_glass_residue_shader; no_instance_uniforms")
	return {"ok": true, "assembly": assembly, "contract": contract, "metrics": stats}


## Returns the exact authored dimensions without creating scene nodes.
static func contract_for(kind_value: Variant, width_cells_value: int, height_value: float, detail_tier: int = DETAIL_HERO) -> Dictionary:
	var kind := StringName(str(kind_value).to_lower())
	var cells := clampi(width_cells_value, 2, 4)
	var height := clampf(height_value, 3.0, 6.0)
	var opening := _opening_rect(kind, cells, height)
	var depth := WALL_DEPTH_M
	var collision_truth := "solid_wall_envelope"
	match kind:
		&"window":
			depth = 0.40
			collision_truth = "four_part_structural_surround_plus_distinct_laminated_glass_surface"
		&"vitrine":
			depth = 0.66
			collision_truth = "four_part_structural_surround_plus_distinct_projecting_glass_surface"
		&"portal":
			depth = 0.52
			collision_truth = "three_shapes_leave_clear_traversable_opening"
	return {
		"schema": "ada-museum-opening-span-v2",
		"kind": str(kind),
		"grid_m": GRID_M,
		"width_cells": cells,
		"width_m": float(cells),
		"height_m": height,
		"construction_depth_m": depth,
		"clear_opening_m": Vector2(opening.size.x, opening.size.y),
		"opening_center_m": Vector2(opening.position.x, opening.position.y),
		"collision_truth": collision_truth,
		"lod_policy": {
			"detail_tier": clampi(detail_tier, DETAIL_HERO, DETAIL_MOBILE),
			"hero_detail_end_m": HERO_DETAIL_END_M,
			"secondary_detail_end_m": SECONDARY_DETAIL_END_M,
			"coarse_shell_persistent": true,
		},
		"physics_policy": "static_by_default; areas_only_when_armed; fragments_spawn_external",
		"surface_policy": "caller_shared_materials; cached_PBR_fallback; bounded_glass_residue_pool; no_per_piece_material_duplicates; no_instance_uniforms",
	}


## Read-only resource-pool telemetry for isolated validators and performance HUDs.
## Counts describe shared resources, never per-frame allocations.
static func cache_report() -> Dictionary:
	return {
		"palette_count": _palette_cache.size(),
		"texture_count": _texture_cache.size(),
		"chamfer_mesh_count": _chamfer_mesh_cache.size(),
		"collision_shape_count": _shape_cache.size(),
		"unit_box_ready": _unit_box_mesh != null,
		"glass_shader_ready": _glass_shader != null,
		"residue_shader_ready": _glass_residue_shader != null,
		"surface_physics_ready": {
			"stone": _stone_physics_material != null,
			"bronze": _bronze_physics_material != null,
			"painted_metal": _painted_metal_physics_material != null,
			"glass_laminated": _glass_physics_material != null,
			"rubber": _rubber_physics_material != null,
		},
	}


## Cached fallback palette. Caller-provided materials are preferred. The stone
## and bronze fallbacks use the museum PBR sets when imported, with direct Image
## fallback for clean headless boots.
static func default_palette(finish: String = "uffizi_stone") -> Dictionary:
	var key := finish.to_lower()
	if _palette_cache.has(key):
		return _palette_cache[key]
	var stone_tint := Color(0.78, 0.72, 0.63) if key != "white_gallery" else Color(0.9, 0.89, 0.85)
	var stone := _pbr_material(stone_tint, 0.82, 0.0, "aaa_wall_stone", Vector3(0.72, 0.72, 0.72))
	var stone_alt := _pbr_material(stone_tint.darkened(0.09), 0.88, 0.0, "aaa_wall_stone", Vector3(0.86, 0.86, 0.86))
	var bronze := _pbr_material(Color(0.62, 0.49, 0.3), 0.38, 0.86, "aaa_trim_bronze", Vector3(1.65, 1.65, 1.65))
	var painted_trim := _pbr_material(Color(0.085, 0.09, 0.095), 0.3, 0.78, "aaa_trim_bronze", Vector3(2.3, 2.3, 2.3))
	var glass := _glass_material(Color(0.97, 0.985, 1.0, 0.018), Color(0.2, 0.46, 0.47, 0.34), 0.038, 0.016)
	var glass_inner := _glass_material(Color(0.985, 0.99, 1.0, 0.01), Color(0.2, 0.42, 0.44, 0.24), 0.055, 0.01)
	var glass_edge := _glass_material(Color(0.36, 0.55, 0.54, 0.09), Color(0.1, 0.45, 0.43, 0.52), 0.075, 0.045)
	var result := {
		"stone": stone,
		"stone_alt": stone_alt,
		"trim": painted_trim,
		"bronze": bronze,
		"glass": glass,
		"glass_inner": glass_inner,
		"glass_edge": glass_edge,
		"glass_wear": _shared_glass_residue_material(),
		"gasket": _material(Color(0.008, 0.01, 0.012), 0.96, 0.0),
		"dark": _material(Color(0.018, 0.022, 0.026), 0.72, 0.08),
		"backing": _material(Color(0.075, 0.069, 0.058), 0.9, 0.0),
		"emissive": _emissive_material(Color(1.0, 0.76, 0.43), 1.8),
		"safety": _emissive_material(Color(0.28, 0.9, 0.55), 1.35),
		"wear": _transparent_material(Color(0.12, 0.095, 0.07, 0.075), 0.93),
	}
	_palette_cache[key] = result
	return result


static func _build_window(parent: Node3D, cells: int, height: float, palette: Dictionary, options: Dictionary, contract: Dictionary, stats: Dictionary) -> void:
	var rect := _opening_rect(&"window", cells, height)
	_build_opening_surround(parent, "Window", cells, height, rect, palette, stats)
	var front_z := 0.19
	# Deep stepped casing: stone architrave, metal subframe, compressed gasket.
	_add_profile_rect_frame(parent, "WindowStoneReveal", rect, 0.115, 0.04, _slot(palette, "stone_alt"), stats, false, 0.014)
	_add_profile_rect_frame(parent, "WindowSubframe", _resized_rect(rect, -0.105), 0.07, front_z - 0.04, _slot(palette, "trim"), stats, false, 0.009)
	_add_rect_frame(parent, "WindowGasket", _resized_rect(rect, -0.16), 0.026, front_z + 0.012, _slot(palette, "gasket"), stats, true)
	var glass_rect := _resized_rect(rect, -0.19)
	# The exterior pressure plate and snap cap are separate manufacturable layers.
	# Their chamfers catch a controlled highlight while the black thermal break stays
	# visible between metal and glass instead of reading as a painted outline.
	_add_profile_rect_frame(parent, "WindowPressurePlate", _resized_rect(glass_rect, 0.012), 0.034, front_z + 0.046, _slot(palette, "trim"), stats, false, 0.006)
	_add_profile_rect_frame(parent, "WindowSnapCap", _resized_rect(glass_rect, 0.035), 0.014, front_z + 0.073, _slot(palette, "bronze"), stats, true, 0.003)
	_add_rect_frame(parent, "WindowThermalBreak", _resized_rect(glass_rect, 0.004), 0.012, front_z - 0.035, _slot(palette, "gasket"), stats, true)
	_box(parent, "WindowOuterLamination", Vector3(glass_rect.position.x, glass_rect.position.y, front_z + 0.018), Vector3(glass_rect.size.x, glass_rect.size.y, 0.012), _slot(palette, "glass"), stats, false, "glass")
	_box(parent, "WindowInnerLamination", Vector3(glass_rect.position.x, glass_rect.position.y, front_z - 0.048), Vector3(glass_rect.size.x, glass_rect.size.y, 0.01), _slot(palette, "glass_inner", _slot(palette, "glass")), stats, false, "glass")
	_add_glass_edge_frame(parent, "WindowLaminatedEdge", glass_rect, front_z - 0.015, 0.086, _slot(palette, "glass_edge", _slot(palette, "glass")), stats)
	_box(parent, "WindowWarmEdgeSpacer", Vector3(0, glass_rect.position.y - glass_rect.size.y * 0.5 + 0.028, front_z - 0.016), Vector3(glass_rect.size.x, 0.018, 0.045), _slot(palette, "bronze"), stats, true, "bronze")
	# Mullions are structural T-sections, not lines painted on glass.
	for seam in range(1, cells):
		var x := -float(cells) * 0.5 + float(seam)
		if absf(x) < glass_rect.size.x * 0.5 - 0.08:
			_box(parent, "WindowMullionWeb_%02d" % seam, Vector3(x, glass_rect.position.y, front_z - 0.004), Vector3(0.052, glass_rect.size.y, 0.11), _slot(palette, "trim"), stats, false, "trim")
			_box(parent, "WindowMullionCap_%02d" % seam, Vector3(x, glass_rect.position.y, front_z + 0.061), Vector3(0.022, glass_rect.size.y - 0.045, 0.02), _slot(palette, "bronze"), stats, true, "bronze")
	var transom_y := glass_rect.position.y + glass_rect.size.y * 0.23
	_box(parent, "WindowTransomWeb", Vector3(0, transom_y, front_z - 0.002), Vector3(glass_rect.size.x, 0.06, 0.105), _slot(palette, "trim"), stats, false, "trim")
	_box(parent, "WindowTransomCap", Vector3(0, transom_y, front_z + 0.06), Vector3(glass_rect.size.x - 0.04, 0.022, 0.02), _slot(palette, "bronze"), stats, true, "bronze")
	# Projecting sill with a capillary break and batched drainage slots.
	var sill_y := rect.position.y - rect.size.y * 0.5 - 0.055
	_chamfer_box(parent, "WindowSill", Vector3(0, sill_y, 0.14), Vector3(rect.size.x + 0.24, 0.11, 0.31), 0.016, _slot(palette, "stone_alt"), stats, false, "stone_alt")
	_chamfer_box(parent, "WindowDripEdge", Vector3(0, sill_y - 0.04, 0.305), Vector3(rect.size.x + 0.16, 0.025, 0.025), 0.004, _slot(palette, "bronze"), stats, true, "bronze")
	_chamfer_box(parent, "WindowHeadFlashing", Vector3(0, rect.position.y + rect.size.y * 0.5 + 0.075, 0.205), Vector3(rect.size.x + 0.2, 0.045, 0.27), 0.006, _slot(palette, "bronze"), stats, false, "bronze")
	_box(parent, "WindowInspectionLatch", Vector3(glass_rect.size.x * 0.5 - 0.105, glass_rect.position.y - glass_rect.size.y * 0.28, front_z + 0.09), Vector3(0.055, 0.17, 0.035), _slot(palette, "trim"), stats, true, "trim")
	var drain_transforms: Array[Transform3D] = []
	var drains := maxi(3, cells * 3)
	for index in range(drains):
		var x := lerpf(-rect.size.x * 0.42, rect.size.x * 0.42, float(index) / float(maxi(1, drains - 1)))
		drain_transforms.append(_scaled_transform(Vector3(x, sill_y + 0.057, 0.21), Vector3(0.018, 0.012, 0.13)))
	_multibox(parent, "WindowDrainSlots", drain_transforms, _slot(palette, "dark"), stats, HERO_DETAIL_END_M, "trim")
	# Two load-bearing setting blocks interrupt the warm-edge spacer. These are
	# deliberately larger than the maintenance residue so they read at human scale.
	var setting_blocks: Array[Transform3D] = []
	for sx in [-1.0, 1.0]:
		setting_blocks.append(_scaled_transform(Vector3(sx * glass_rect.size.x * 0.27, glass_rect.position.y - glass_rect.size.y * 0.5 + 0.029, front_z + 0.032), Vector3(0.13, 0.035, 0.04)))
	_multibox(parent, "WindowGlazingSettingBlocks", setting_blocks, _slot(palette, "bronze"), stats, SECONDARY_DETAIL_END_M, "bronze")
	_add_frame_fasteners(parent, "WindowFrameFasteners", _resized_rect(rect, -0.095), front_z + 0.075, palette, cells + 2, stats)
	_add_glass_imperfection(parent, "WindowWeathering", glass_rect, front_z + 0.027, palette, _resolved_seed(&"window", cells, height, options), stats)
	if _opt_bool(options, "enable_collision", true):
		_add_collision_body(parent, "WindowStructureCollision", _opening_surround_collision_boxes(cells, height, rect, WALL_DEPTH_M), "structural_surround_excludes_glass", stats, options)
		_add_surface_collision_body(parent, "WindowPaintedMetalCollision", _window_metal_collision_boxes(cells, glass_rect, transom_y, front_z), "pressure_frame_mullions_and_transom", &"painted_metal", stats, options)
		_add_surface_collision_body(parent, "WindowRubberCollision", _rect_frame_collision_boxes(_resized_rect(rect, -0.16), 0.026, front_z + 0.012, 0.022), "four_part_compression_gasket", &"rubber", stats, options)
		_add_glass_collision(parent, "WindowGlassCollision", glass_rect, front_z + 0.018, 0.012, &"window_laminated_insulated", stats, options)
	if _opt_bool(options, "enable_interaction_hooks", false):
		_add_glass_hook(parent, "WindowGlassPhysicsHook", glass_rect, front_z + 0.02, &"window", options, stats)
	parent.set_meta("glazing_makeup_m", PackedFloat32Array([0.012, 0.054, 0.01]))
	parent.set_meta("glass_surface_id", "window_laminated_insulated")
	stats["tertiary_elements"] = int(stats["tertiary_elements"]) + 17
	parent.set_meta("glass_optics", "neutral_front_transmission; restrained_fresnel; UV_edge_absorption; bounded_residue_pool")
	parent.set_meta("frame_makeup", "stone_reveal; thermally_broken_metal_subframe; compression_gasket; pressure_plate; bronze_snap_cap")
	parent.set_meta("drainage", "projecting_sill_capillary_break_and_slots")


static func _build_vitrine(parent: Node3D, cells: int, height: float, palette: Dictionary, options: Dictionary, contract: Dictionary, stats: Dictionary) -> void:
	var rect := _opening_rect(&"vitrine", cells, height)
	_build_opening_surround(parent, "Vitrine", cells, height, rect, palette, stats)
	var cavity_back_z := -0.26
	var glass_z := 0.285
	# Recess has physically legible liner depth, a removable backing, and a front door.
	_box(parent, "VitrineBacking", Vector3(rect.position.x, rect.position.y, cavity_back_z), Vector3(rect.size.x, rect.size.y, 0.045), _slot(palette, "backing"), stats, false, "backing")
	for sx in [-1.0, 1.0]:
		_chamfer_box(parent, "VitrineSideLiner", Vector3(sx * rect.size.x * 0.5, rect.position.y, 0.005), Vector3(0.07, rect.size.y, 0.57), 0.009, _slot(palette, "stone_alt"), stats, false, "stone_alt")
	for sy in [-1.0, 1.0]:
		_chamfer_box(parent, "VitrineHeadSillLiner", Vector3(0, rect.position.y + sy * rect.size.y * 0.5, 0.005), Vector3(rect.size.x, 0.07, 0.57), 0.009, _slot(palette, "stone_alt"), stats, false, "stone_alt")
	_add_profile_rect_frame(parent, "VitrineOuterFrame", _resized_rect(rect, 0.075), 0.075, 0.16, _slot(palette, "bronze"), stats, false, 0.009)
	_add_rect_frame(parent, "VitrineDoorGasket", _resized_rect(rect, -0.055), 0.026, glass_z - 0.016, _slot(palette, "gasket"), stats, true)
	var glass_rect := _resized_rect(rect, -0.085)
	_add_profile_rect_frame(parent, "VitrinePressureCap", _resized_rect(glass_rect, 0.012), 0.032, glass_z + 0.034, _slot(palette, "trim"), stats, false, 0.005)
	_add_rect_frame(parent, "VitrineInnerSeal", _resized_rect(glass_rect, -0.018), 0.012, glass_z - 0.027, _slot(palette, "gasket"), stats, true)
	_box(parent, "VitrineLaminatedDoor", Vector3(0, rect.position.y, glass_z), Vector3(glass_rect.size.x, glass_rect.size.y, 0.024), _slot(palette, "glass"), stats, false, "glass")
	_add_glass_edge_frame(parent, "VitrineLaminatedEdge", glass_rect, glass_z, 0.04, _slot(palette, "glass_edge", _slot(palette, "glass")), stats)
	var base_shelf_y := rect.position.y - rect.size.y * 0.5 + 0.13
	_box(parent, "VitrineBaseGlassShelf", Vector3(0, base_shelf_y, 0.005), Vector3(rect.size.x - 0.18, 0.026, 0.31), _slot(palette, "glass_inner", _slot(palette, "glass")), stats, false, "glass")
	# Three shared hinge knuckles, a proper pull bar and two stand-offs make the
	# projecting glass read as a serviceable door rather than a transparent plate.
	var hinge_transforms: Array[Transform3D] = []
	for hinge_index in range(3):
		var t := float(hinge_index + 1) / 4.0
		var hinge_y := rect.position.y - rect.size.y * 0.5 + rect.size.y * t
		hinge_transforms.append(Transform3D(Basis.IDENTITY, Vector3(-glass_rect.size.x * 0.5 - 0.032, hinge_y, glass_z + 0.052)))
	_multimesh(parent, "VitrineHingeKnuckles", _shared_vitrine_hinge(), hinge_transforms, _slot(palette, "bronze"), stats, SECONDARY_DETAIL_END_M, 48, "bronze")
	var pull_x := glass_rect.size.x * 0.5 - 0.105
	_chamfer_box(parent, "VitrineDoorPullBar", Vector3(pull_x, rect.position.y, glass_z + 0.078), Vector3(0.032, 0.38, 0.035), 0.005, _slot(palette, "bronze"), stats, false, "bronze")
	for sy in [-1.0, 1.0]:
		_chamfer_box(parent, "VitrineDoorPullStandOff", Vector3(pull_x, rect.position.y + sy * 0.17, glass_z + 0.052), Vector3(0.075, 0.035, 0.065), 0.006, _slot(palette, "trim"), stats, true, "trim")
	# Adjustable shelves and paired brackets. Shelf count is deterministic by width.
	var shelf_count := clampi(int(options.get("shelves", 1 if cells == 2 else 2)), 0, 3)
	for shelf_index in range(shelf_count):
		var t := float(shelf_index + 1) / float(shelf_count + 1)
		var y := rect.position.y - rect.size.y * 0.5 + rect.size.y * t
		_box(parent, "VitrineShelf_%02d" % shelf_index, Vector3(0, y, 0.005), Vector3(rect.size.x - 0.18, 0.026, 0.31), _slot(palette, "glass_inner", _slot(palette, "glass")), stats, false, "glass")
		for sx in [-1.0, 1.0]:
			_box(parent, "VitrineShelfBracket", Vector3(sx * (rect.size.x * 0.5 - 0.12), y - 0.035, -0.02), Vector3(0.055, 0.09, 0.24), _slot(palette, "bronze"), stats, true, "bronze")
	if str(options.get("vitrine_content", "instrument")).to_lower() != "empty":
		_build_vitrine_content(parent, rect, cavity_back_z, palette, options, stats)
	# Concealed warm LED channel, diffuser, ventilation, lock, and door seam.
	var top_y := rect.position.y + rect.size.y * 0.5 - 0.08
	_box(parent, "VitrineLightChannel", Vector3(0, top_y, -0.06), Vector3(rect.size.x - 0.16, 0.055, 0.09), _slot(palette, "trim"), stats, false, "trim")
	_box(parent, "VitrineLightDiffuser", Vector3(0, top_y - 0.035, -0.005), Vector3(rect.size.x - 0.22, 0.025, 0.04), _slot(palette, "emissive"), stats, false, "emissive")
	_chamfer_box(parent, "VitrineHumidityTray", Vector3(-rect.size.x * 0.26, rect.position.y - rect.size.y * 0.5 + 0.11, -0.17), Vector3(minf(0.42, rect.size.x * 0.24), 0.075, 0.18), 0.008, _slot(palette, "trim"), stats, true, "trim")
	_box(parent, "VitrineHumidityWitness", Vector3(-rect.size.x * 0.26, rect.position.y - rect.size.y * 0.5 + 0.12, -0.068), Vector3(minf(0.24, rect.size.x * 0.14), 0.022, 0.012), _slot(palette, "safety"), stats, true, "emissive")
	# Every width uses a paired service leaf, so the centre ray has a real bronze
	# meeting stile instead of falling through to the glass collider.
	_chamfer_box(parent, "VitrineDoorMeetingStile", Vector3(0, rect.position.y, glass_z + 0.021), Vector3(0.035, glass_rect.size.y - 0.06, 0.026), 0.004, _slot(palette, "bronze"), stats, true, "bronze")
	_box(parent, "VitrineServiceLock", Vector3(rect.size.x * 0.5 - 0.13, rect.position.y - 0.18, glass_z + 0.035), Vector3(0.055, 0.13, 0.035), _slot(palette, "trim"), stats, true, "trim")
	var vent_transforms: Array[Transform3D] = []
	for index in range(cells * 4):
		var x := lerpf(-rect.size.x * 0.4, rect.size.x * 0.4, float(index) / float(maxi(1, cells * 4 - 1)))
		vent_transforms.append(_scaled_transform(Vector3(x, rect.position.y - rect.size.y * 0.5 + 0.075, -0.14), Vector3(0.035, 0.018, 0.02)))
	_multibox(parent, "VitrineVentSlots", vent_transforms, _slot(palette, "dark"), stats, HERO_DETAIL_END_M, "trim")
	_add_frame_fasteners(parent, "VitrineFrameFasteners", _resized_rect(rect, 0.03), glass_z + 0.032, palette, cells + 2, stats)
	_add_glass_imperfection(parent, "VitrineGlassMicroWear", glass_rect, glass_z + 0.015, palette, _resolved_seed(&"vitrine", cells, height, options), stats)
	if _opt_bool(options, "enable_local_lights", false):
		var light := OmniLight3D.new()
		light.name = "VitrineLocalLight"
		light.position = Vector3(0, top_y - 0.1, 0.02)
		light.light_color = Color(1.0, 0.78, 0.52)
		light.light_energy = 0.45
		light.omni_range = minf(2.5, rect.size.x * 0.7)
		light.shadow_enabled = false
		parent.add_child(light)
		stats["local_lights"] = int(stats["local_lights"]) + 1
	if _opt_bool(options, "enable_collision", true):
		var stone_boxes := _opening_surround_collision_boxes(cells, height, rect, WALL_DEPTH_M)
		stone_boxes.append({"name": "CavityBacking", "at": Vector3(rect.position.x, rect.position.y, cavity_back_z), "size": Vector3(rect.size.x, rect.size.y, 0.045)})
		_add_collision_body(parent, "VitrineStructureCollision", stone_boxes, "structural_surround_and_rear_backing_exclude_vitrine_door", stats, options)
		# This proxy follows the visible pressure-cap envelope exactly. The deeper
		# outer frame remains visual construction rather than a hidden blocker.
		var bronze_boxes := _rect_frame_collision_boxes(_resized_rect(glass_rect, 0.012), 0.032, glass_z + 0.034, maxf(0.025, 0.032 * 0.78))
		bronze_boxes.append({"name": "DoorMeetingStile", "at": Vector3(0, rect.position.y, glass_z + 0.021), "size": Vector3(0.035, glass_rect.size.y - 0.06, 0.026)})
		_add_surface_collision_body(parent, "VitrineBronzeCollision", bronze_boxes, "perimeter_clamp_and_meeting_stile", &"bronze", stats, options)
		_add_surface_collision_body(parent, "VitrineRubberCollision", _rect_frame_collision_boxes(_resized_rect(rect, -0.055), 0.026, glass_z - 0.016, 0.022), "four_part_door_compression_gasket", &"rubber", stats, options)
		_add_glass_collision(parent, "VitrineGlassCollision", glass_rect, glass_z, 0.024, &"vitrine_laminated_security", stats, options, [
			{"name": "BaseGlassShelf", "at": Vector3(0, base_shelf_y, 0.005), "size": Vector3(rect.size.x - 0.18, 0.026, 0.31)},
		])
	if _opt_bool(options, "enable_interaction_hooks", false):
		_add_glass_hook(parent, "VitrineGlassPhysicsHook", glass_rect, glass_z, &"vitrine", options, stats)
	var shelf_socket := Marker3D.new()
	shelf_socket.name = "VitrineArtifactSocket"
	shelf_socket.position = Vector3(0, rect.position.y - rect.size.y * 0.18, 0.0)
	shelf_socket.set_meta("clear_volume_m", Vector3(rect.size.x - 0.25, rect.size.y * 0.45, 0.3))
	parent.add_child(shelf_socket)
	parent.set_meta("cavity_depth_m", 0.545)
	parent.set_meta("glass_surface_id", "vitrine_laminated_security")
	stats["tertiary_elements"] = int(stats["tertiary_elements"]) + 16
	parent.set_meta("glass_optics", "neutral_front_transmission; restrained_fresnel; UV_edge_absorption; bounded_residue_pool")
	parent.set_meta("door_makeup", "projecting_laminated_leaf; pressure_cap; dual_gasket; three_knuckle_hinge; pull_bar; service_lock")
	parent.set_meta("default_content", "mounted_archival_instrument")
	parent.set_meta("lighting", "emissive_diffuser; optional_one_unshadowed_local_light")


static func _build_portal(parent: Node3D, cells: int, height: float, palette: Dictionary, options: Dictionary, contract: Dictionary, stats: Dictionary) -> void:
	var rect := _opening_rect(&"portal", cells, height)
	var w := float(cells)
	var pier_w := (w - rect.size.x) * 0.5
	var side_sign := 1.0 if _opt_bool(options, "flip", false) else -1.0
	# The shell is deep enough to read as construction, with a continuous reveal.
	for sx in [-1.0, 1.0]:
		_box(parent, "PortalStructuralPier", Vector3(sx * (rect.size.x * 0.5 + pier_w * 0.5), height * 0.5, 0), Vector3(pier_w, height, 0.26), _slot(palette, "stone_alt"), stats, false, "stone_alt")
	var lintel_h := height - rect.size.y
	_box(parent, "PortalStructuralLintel", Vector3(0, rect.size.y + lintel_h * 0.5, 0), Vector3(rect.size.x, lintel_h, 0.26), _slot(palette, "stone_alt"), stats, false, "stone_alt")
	for sx in [-1.0, 1.0]:
		_chamfer_box(parent, "PortalDeepJamb", Vector3(sx * (rect.size.x * 0.5 + 0.035), rect.size.y * 0.5, 0), Vector3(0.07, rect.size.y, 0.52), 0.01, _slot(palette, "stone"), stats, false, "stone")
		_box(parent, "PortalCompressionGasket", Vector3(sx * (rect.size.x * 0.5 - 0.018), rect.size.y * 0.5, 0.175), Vector3(0.025, rect.size.y - 0.12, 0.075), _slot(palette, "gasket"), stats, true, "gasket")
		# Rear stop and second gasket show that a future leaf has a manufactured
		# landing surface while the zero-leaf default remains fully traversable.
		_chamfer_box(parent, "PortalRearStop", Vector3(sx * (rect.size.x * 0.5 - 0.025), rect.size.y * 0.5, -0.218), Vector3(0.05, rect.size.y - 0.08, 0.075), 0.007, _slot(palette, "trim"), stats, false, "trim")
		_box(parent, "PortalRearGasket", Vector3(sx * (rect.size.x * 0.5 - 0.052), rect.size.y * 0.5, -0.25), Vector3(0.014, rect.size.y - 0.15, 0.018), _slot(palette, "gasket"), stats, true, "gasket")
		# Lower sacrificial corner guards catch cart and case strikes.
		_chamfer_box(parent, "PortalCornerGuard", Vector3(sx * (rect.size.x * 0.5 - 0.035), 0.62, 0.285), Vector3(0.075, 1.18, 0.055), 0.008, _slot(palette, "bronze"), stats, false, "bronze")
		_chamfer_box(parent, "PortalCornerGuardReturn", Vector3(sx * (rect.size.x * 0.5 + 0.013), 0.62, 0.225), Vector3(0.025, 1.18, 0.16), 0.004, _slot(palette, "bronze"), stats, false, "bronze")
	_chamfer_box(parent, "PortalHeadReveal", Vector3(0, rect.size.y + 0.035, 0), Vector3(rect.size.x, 0.07, 0.52), 0.01, _slot(palette, "stone"), stats, false, "stone")
	_box(parent, "PortalHeadSeal", Vector3(0, rect.size.y - 0.018, 0.175), Vector3(rect.size.x - 0.08, 0.025, 0.075), _slot(palette, "gasket"), stats, true, "gasket")
	_chamfer_box(parent, "PortalRearHeadStop", Vector3(0, rect.size.y + 0.012, -0.218), Vector3(rect.size.x - 0.08, 0.05, 0.075), 0.007, _slot(palette, "trim"), stats, false, "trim")
	_box(parent, "PortalRearHeadGasket", Vector3(0, rect.size.y - 0.018, -0.25), Vector3(rect.size.x - 0.14, 0.014, 0.018), _slot(palette, "gasket"), stats, true, "gasket")
	# A recessed rear light and route rails make the open default read as a
	# continuation through wall depth, never as a black cut-out or a hidden leaf.
	_box(parent, "PortalContinuationLightHousing", Vector3(0, rect.size.y - 0.055, -0.235), Vector3(rect.size.x - 0.24, 0.045, 0.045), _slot(palette, "trim"), stats, false, "trim")
	_box(parent, "PortalContinuationLight", Vector3(0, rect.size.y - 0.057, -0.257), Vector3(rect.size.x - 0.36, 0.02, 0.006), _slot(palette, "safety"), stats, true, "emissive")
	var route_transforms: Array[Transform3D] = []
	for sx in [-1.0, 1.0]:
		route_transforms.append(_scaled_transform(Vector3(sx * minf(0.28, rect.size.x * 0.2), 0.007, -0.13), Vector3(0.024, 0.008, 0.25)))
	_multibox(parent, "PortalRouteRails", route_transforms, _slot(palette, "bronze"), stats, SECONDARY_DETAIL_END_M, "bronze")
	# Flush threshold preserves accessibility; the dark line is a recessed floor seal.
	_chamfer_box(parent, "PortalFlushThreshold", Vector3(0, 0.004, 0), Vector3(rect.size.x, 0.008, 0.52), 0.002, _slot(palette, "bronze"), stats, false, "bronze")
	_box(parent, "PortalThresholdSeal", Vector3(0, 0.009, 0.17), Vector3(rect.size.x - 0.1, 0.006, 0.045), _slot(palette, "gasket"), stats, true, "gasket")
	# Sign, sensor and future door hardware are sockets rather than always-on systems.
	var sign_x := side_sign * minf(rect.size.x * 0.27, 0.7)
	var sign_y := rect.size.y + 0.23
	var sign_w := minf(0.82, rect.size.x * 0.36)
	_chamfer_box(parent, "PortalSignCarrier", Vector3(sign_x, sign_y, 0.205), Vector3(sign_w, 0.16, 0.065), 0.008, _slot(palette, "trim"), stats, false, "trim")
	_box(parent, "PortalSignFace", Vector3(sign_x, sign_y, 0.241), Vector3(sign_w - 0.08, 0.095, 0.012), _slot(palette, "dark"), stats, true, "trim")
	var arrow_dir := -side_sign
	var sign_glyph: Array[Transform3D] = [
		_scaled_transform(Vector3(sign_x, sign_y, 0.249), Vector3(0.18, 0.024, 0.008)),
		_scaled_rotated_transform(Vector3(sign_x + arrow_dir * 0.095, sign_y + 0.026, 0.249), Vector3(0.075, 0.018, 0.008), arrow_dir * 0.62),
		_scaled_rotated_transform(Vector3(sign_x + arrow_dir * 0.095, sign_y - 0.026, 0.249), Vector3(0.075, 0.018, 0.008), -arrow_dir * 0.62),
		_scaled_transform(Vector3(sign_x - arrow_dir * 0.125, sign_y, 0.249), Vector3(0.018, 0.064, 0.008)),
	]
	_multibox(parent, "PortalExitDirectionGlyph", sign_glyph, _slot(palette, "safety"), stats, SECONDARY_DETAIL_END_M, "emissive")
	for sx in [-1.0, 1.0]:
		_box(parent, "PortalPresenceSensor", Vector3(sx * (rect.size.x * 0.5 - 0.16), rect.size.y - 0.1, 0.255), Vector3(0.11, 0.075, 0.08), _slot(palette, "trim"), stats, true, "trim")
	_add_frame_fasteners(parent, "PortalRevealFasteners", _resized_rect(rect, -0.055), 0.318, palette, cells + 2, stats)
	var wear_transforms: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = _resolved_seed(&"portal", cells, height, options)
	for index in range(cells + 2):
		var x := rng.randf_range(-rect.size.x * 0.42, rect.size.x * 0.42)
		wear_transforms.append(_scaled_transform(Vector3(x, 0.02, 0.285 + rng.randf_range(-0.02, 0.02)), Vector3(rng.randf_range(0.12, 0.32), 0.008, 0.018)))
	_multibox(parent, "PortalThresholdWear", wear_transforms, _slot(palette, "wear"), stats, HERO_DETAIL_END_M, "wear")
	for socket_data in [
		["PortalSignSocket", Vector3(side_sign * minf(rect.size.x * 0.27, 0.7), rect.size.y + 0.23, 0.29), "sign"],
		["DoorLeafSocketLeft", Vector3(-rect.size.x * 0.5, 0, 0), "hinge_left"],
		["DoorLeafSocketRight", Vector3(rect.size.x * 0.5, 0, 0), "hinge_right"],
		["DoorTrackSocket", Vector3(0, rect.size.y + 0.08, -0.15), "track"],
	]:
		var marker := Marker3D.new()
		marker.name = str(socket_data[0])
		marker.position = socket_data[1]
		marker.set_meta("hardware_role", socket_data[2])
		marker.set_meta("opening_m", Vector2(rect.size.x, rect.size.y))
		parent.add_child(marker)
	if _opt_bool(options, "enable_collision", true):
		_add_collision_body(parent, "PortalCollision", [
			{"name": "LeftPier", "at": Vector3(-rect.size.x * 0.5 - pier_w * 0.5, height * 0.5, 0), "size": Vector3(pier_w, height, 0.26)},
			{"name": "RightPier", "at": Vector3(rect.size.x * 0.5 + pier_w * 0.5, height * 0.5, 0), "size": Vector3(pier_w, height, 0.26)},
			{"name": "Lintel", "at": Vector3(0, rect.size.y + lintel_h * 0.5, 0), "size": Vector3(rect.size.x, lintel_h, 0.26)},
		], "three_shapes_leave_clear_traversable_opening", stats, options)
		_add_surface_collision_body(parent, "PortalBronzeCollision", [
			# Navigation collision is inset 1 mm below the finished walking plane. The
			# visible 8 mm transition remains a truthful finish build-up, while the
			# simplified capsule proxy cannot snag on a coplanar cast at y=0.
			{"name": "FlushThreshold", "at": Vector3(0, -0.005, 0), "size": Vector3(rect.size.x, 0.008, 0.52)},
			{"name": "LeftCornerGuard", "at": Vector3(-rect.size.x * 0.5 + 0.035, 0.62, 0.285), "size": Vector3(0.075, 1.18, 0.055)},
			{"name": "RightCornerGuard", "at": Vector3(rect.size.x * 0.5 - 0.035, 0.62, 0.285), "size": Vector3(0.075, 1.18, 0.055)},
		], "flush_threshold_and_cart_strike_guards", &"bronze", stats, options)
		_add_surface_collision_body(parent, "PortalRubberCollision", [
			{"name": "LeftCompressionGasket", "at": Vector3(-rect.size.x * 0.5 + 0.018, rect.size.y * 0.5, 0.175), "size": Vector3(0.025, rect.size.y - 0.12, 0.075)},
			{"name": "RightCompressionGasket", "at": Vector3(rect.size.x * 0.5 - 0.018, rect.size.y * 0.5, 0.175), "size": Vector3(0.025, rect.size.y - 0.12, 0.075)},
			{"name": "HeadCompressionGasket", "at": Vector3(0, rect.size.y - 0.018, 0.175), "size": Vector3(rect.size.x - 0.08, 0.025, 0.075)},
		], "three_part_future_leaf_compression_gasket", &"rubber", stats, options)
	if _opt_bool(options, "enable_interaction_hooks", false):
		_add_portal_trigger(parent, rect, options, stats)
	stats["tertiary_elements"] = int(stats["tertiary_elements"]) + 16
	parent.set_meta("accessible_threshold_m", 0.008)
	parent.set_meta("interaction", "walkthrough")
	parent.set_meta("continuation_read", "rear_stop_depth; recessed_route_light; paired_floor_rails; zero_leaf")
	parent.set_meta("door_infrastructure", "left/right hinge sockets; head track; sign carrier; presence sensors")


static func _build_opening_surround(parent: Node3D, prefix: String, cells: int, height: float, rect: Rect2, palette: Dictionary, stats: Dictionary) -> void:
	var w := float(cells)
	var left_edge := rect.position.x - rect.size.x * 0.5
	var right_edge := rect.position.x + rect.size.x * 0.5
	var bottom := rect.position.y - rect.size.y * 0.5
	var top := rect.position.y + rect.size.y * 0.5
	_box(parent, prefix + "Apron", Vector3(0, bottom * 0.5, 0), Vector3(w, bottom, WALL_DEPTH_M), _slot(palette, "stone"), stats, false, "stone")
	_box(parent, prefix + "Head", Vector3(0, top + (height - top) * 0.5, 0), Vector3(w, height - top, WALL_DEPTH_M), _slot(palette, "stone_alt"), stats, false, "stone_alt")
	_box(parent, prefix + "LeftPier", Vector3((-w * 0.5 + left_edge) * 0.5, rect.position.y, 0), Vector3(left_edge + w * 0.5, rect.size.y, WALL_DEPTH_M), _slot(palette, "stone_alt"), stats, false, "stone_alt")
	_box(parent, prefix + "RightPier", Vector3((w * 0.5 + right_edge) * 0.5, rect.position.y, 0), Vector3(w * 0.5 - right_edge, rect.size.y, WALL_DEPTH_M), _slot(palette, "stone_alt"), stats, false, "stone_alt")
	_box(parent, prefix + "Skirting", Vector3(0, 0.13, 0.115), Vector3(w, 0.26, 0.09), _slot(palette, "stone_alt"), stats, false, "stone_alt")
	_box(parent, prefix + "Cornice", Vector3(0, height - 0.16, 0.12), Vector3(w, 0.32, 0.1), _slot(palette, "stone_alt"), stats, false, "stone_alt")
	# The seams expose a deterministic one-metre material phase contract.
	for seam in range(1, cells):
		var x := -w * 0.5 + float(seam)
		var groove_h := bottom - 0.3
		if groove_h > 0.08:
			var groove := _box(parent, prefix + "ApronJoint_%02d" % seam, Vector3(x, 0.3 + groove_h * 0.5, 0.078), Vector3(0.008, groove_h, 0.006), _slot(palette, "dark"), stats, true, "stone_joint")
			groove.set_meta("detail_phase", seam & 3)


# Every visible mesh declares whether it owns a solid collision proxy. This is
# intentionally explicit: finish layers, fixings, wear and inner laminations are
# legitimate visual construction, but must never be inferred as hidden blockers.
static func _author_collision_visual_roles(assembly: Node3D, kind: StringName) -> void:
	for node in _all_descendants(assembly):
		if node is MeshInstance3D:
			_set_visual_only(node as MeshInstance3D)
	match kind:
		&"window":
			_mark_solid_exact(assembly, "WindowApron", &"stone", "WindowStructureCollision", PackedStringArray(["Apron"]))
			_mark_solid_exact(assembly, "WindowHead", &"stone", "WindowStructureCollision", PackedStringArray(["Head"]))
			_mark_solid_exact(assembly, "WindowLeftPier", &"stone", "WindowStructureCollision", PackedStringArray(["LeftPier"]))
			_mark_solid_exact(assembly, "WindowRightPier", &"stone", "WindowStructureCollision", PackedStringArray(["RightPier"]))
			_mark_solid_frame(assembly, "WindowSnapCap", &"painted_metal", "WindowPaintedMetalCollision")
			_mark_window_mullions(assembly, int(assembly.get_meta("width_m", 2.0)))
			_mark_solid_exact(assembly, "WindowTransomCap", &"painted_metal", "WindowPaintedMetalCollision", PackedStringArray(["Transom"]))
			_mark_solid_frame(assembly, "WindowGasket", &"rubber", "WindowRubberCollision")
			_mark_solid_exact(assembly, "WindowOuterLamination", &"glass_laminated", "WindowGlassCollision", PackedStringArray(["GlassSurfaceShape"]))
		&"vitrine":
			_mark_solid_exact(assembly, "VitrineApron", &"stone", "VitrineStructureCollision", PackedStringArray(["Apron"]))
			_mark_solid_exact(assembly, "VitrineHead", &"stone", "VitrineStructureCollision", PackedStringArray(["Head"]))
			_mark_solid_exact(assembly, "VitrineLeftPier", &"stone", "VitrineStructureCollision", PackedStringArray(["LeftPier"]))
			_mark_solid_exact(assembly, "VitrineRightPier", &"stone", "VitrineStructureCollision", PackedStringArray(["RightPier"]))
			_mark_solid_exact(assembly, "VitrineBacking", &"stone", "VitrineStructureCollision", PackedStringArray(["CavityBacking"]))
			_mark_solid_frame(assembly, "VitrinePressureCap", &"bronze", "VitrineBronzeCollision")
			_mark_solid_exact(assembly, "VitrineDoorMeetingStile", &"bronze", "VitrineBronzeCollision", PackedStringArray(["DoorMeetingStile"]))
			_mark_solid_frame(assembly, "VitrineDoorGasket", &"rubber", "VitrineRubberCollision")
			_mark_solid_exact(assembly, "VitrineLaminatedDoor", &"glass_laminated", "VitrineGlassCollision", PackedStringArray(["GlassSurfaceShape"]))
			_mark_solid_exact(assembly, "VitrineBaseGlassShelf", &"glass_laminated", "VitrineGlassCollision", PackedStringArray(["BaseGlassShelf"]))
		&"portal":
			for node in _all_descendants(assembly):
				if node is MeshInstance3D and str(node.name) == "PortalStructuralPier":
					_set_solid_visual(node as MeshInstance3D, &"stone", "PortalCollision", PackedStringArray(["LeftPier" if (node as MeshInstance3D).position.x < 0.0 else "RightPier"]))
				elif node is MeshInstance3D and str(node.name) == "PortalCompressionGasket":
					_set_solid_visual(node as MeshInstance3D, &"rubber", "PortalRubberCollision", PackedStringArray(["LeftCompressionGasket" if (node as MeshInstance3D).position.x < 0.0 else "RightCompressionGasket"]))
				elif node is MeshInstance3D and str(node.name) == "PortalCornerGuard":
					_set_solid_visual(node as MeshInstance3D, &"bronze", "PortalBronzeCollision", PackedStringArray(["LeftCornerGuard" if (node as MeshInstance3D).position.x < 0.0 else "RightCornerGuard"]))
			_mark_solid_exact(assembly, "PortalStructuralLintel", &"stone", "PortalCollision", PackedStringArray(["Lintel"]))
			_mark_solid_exact(assembly, "PortalFlushThreshold", &"bronze", "PortalBronzeCollision", PackedStringArray(["FlushThreshold"]))
			_mark_solid_exact(assembly, "PortalHeadSeal", &"rubber", "PortalRubberCollision", PackedStringArray(["HeadCompressionGasket"]))
	assembly.set_meta("visual_collision_roles", "explicit_fail_closed_v1")


static func _set_visual_only(mesh_instance: MeshInstance3D) -> void:
	mesh_instance.set_meta("collision_role", "visual_only")
	mesh_instance.remove_meta("physics_surface_id")
	mesh_instance.remove_meta("collision_target")
	mesh_instance.remove_meta("collision_shape_targets")


static func _mark_solid_exact(assembly: Node3D, node_name: String, surface_id: StringName, target: String, shape_targets: PackedStringArray) -> void:
	for node in _all_descendants(assembly):
		if node is MeshInstance3D and str(node.name) == node_name:
			_set_solid_visual(node as MeshInstance3D, surface_id, target, shape_targets)


static func _mark_solid_frame(assembly: Node3D, prefix: String, surface_id: StringName, target: String) -> void:
	for suffix in ["Left", "Right", "Head", "Sill"]:
		var shape_name: String = {"Left": "LeftRail", "Right": "RightRail", "Head": "HeadRail", "Sill": "SillRail"}[suffix]
		_mark_solid_exact(assembly, prefix + suffix, surface_id, target, PackedStringArray([shape_name]))


static func _mark_window_mullions(assembly: Node3D, cells: int) -> void:
	var mullions: Array[MeshInstance3D] = []
	for node in _all_descendants(assembly):
		if node is MeshInstance3D and str(node.name).begins_with("WindowMullionCap_"):
			mullions.append(node as MeshInstance3D)
	mullions.sort_custom(func(a: MeshInstance3D, b: MeshInstance3D) -> bool: return a.position.x < b.position.x)
	for index in range(mullions.size()):
		var targets := PackedStringArray(["Mullion_%02d" % index])
		if cells == 2:
			targets = PackedStringArray(["Mullion_00", "Mullion_01", "Mullion_02"])
		elif cells == 3 and index == 0:
			targets = PackedStringArray(["Mullion_00", "Mullion_02"])
		_set_solid_visual(mullions[index], &"painted_metal", "WindowPaintedMetalCollision", targets)


static func _set_solid_visual(mesh_instance: MeshInstance3D, surface_id: StringName, target: String, shape_targets: PackedStringArray) -> void:
	mesh_instance.set_meta("collision_role", "solid")
	mesh_instance.set_meta("physics_surface_id", str(surface_id))
	mesh_instance.set_meta("collision_target", target)
	mesh_instance.set_meta("collision_shape_targets", shape_targets)


static func _all_descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_all_descendants(child))
	return result


static func _opening_rect(kind: StringName, cells: int, height: float) -> Rect2:
	var w := float(clampi(cells, 2, 4))
	match kind:
		&"window":
			var bottom := 0.78
			var top := height - 0.43
			return Rect2(Vector2(0, (bottom + top) * 0.5), Vector2(w - 0.46, top - bottom))
		&"vitrine":
			var bottom := 0.64
			var top := minf(3.05, height - 0.7)
			return Rect2(Vector2(0, (bottom + top) * 0.5), Vector2(w - 0.5, top - bottom))
		&"portal":
			var opening_h := minf(3.08, height - 0.5)
			return Rect2(Vector2(0, opening_h * 0.5), Vector2(w - 0.68, opening_h))
	return Rect2(Vector2(0, height * 0.5), Vector2(w, height))


# Rect2.position is deliberately used as an opening centre throughout this
# helper. This preserves that centre while growing/shrinking the clear size.
static func _resized_rect(rect: Rect2, margin: float) -> Rect2:
	return Rect2(rect.position, Vector2(maxf(0.05, rect.size.x + margin * 2.0), maxf(0.05, rect.size.y + margin * 2.0)))


static func _add_rect_frame(parent: Node3D, prefix: String, rect: Rect2, thickness: float, z: float, material: Material, stats: Dictionary, fine: bool) -> void:
	var outer_w := rect.size.x + thickness * 2.0
	var outer_h := rect.size.y + thickness * 2.0
	_box(parent, prefix + "Left", Vector3(rect.position.x - rect.size.x * 0.5 - thickness * 0.5, rect.position.y, z), Vector3(thickness, outer_h, maxf(0.018, thickness * 0.78)), material, stats, fine, "frame")
	_box(parent, prefix + "Right", Vector3(rect.position.x + rect.size.x * 0.5 + thickness * 0.5, rect.position.y, z), Vector3(thickness, outer_h, maxf(0.018, thickness * 0.78)), material, stats, fine, "frame")
	_box(parent, prefix + "Head", Vector3(rect.position.x, rect.position.y + rect.size.y * 0.5 + thickness * 0.5, z), Vector3(outer_w, thickness, maxf(0.018, thickness * 0.78)), material, stats, fine, "frame")
	_box(parent, prefix + "Sill", Vector3(rect.position.x, rect.position.y - rect.size.y * 0.5 - thickness * 0.5, z), Vector3(outer_w, thickness, maxf(0.018, thickness * 0.78)), material, stats, fine, "frame")


# Four cached, chamfered rails give the primary casing a stable highlight roll.
static func _add_profile_rect_frame(parent: Node3D, prefix: String, rect: Rect2, thickness: float, z: float, material: Material, stats: Dictionary, fine: bool, bevel: float) -> void:
	var outer_w := rect.size.x + thickness * 2.0
	var outer_h := rect.size.y + thickness * 2.0
	var depth := maxf(0.025, thickness * 0.78)
	_chamfer_box(parent, prefix + "Left", Vector3(rect.position.x - rect.size.x * 0.5 - thickness * 0.5, rect.position.y, z), Vector3(thickness, outer_h, depth), bevel, material, stats, fine, "frame")
	_chamfer_box(parent, prefix + "Right", Vector3(rect.position.x + rect.size.x * 0.5 + thickness * 0.5, rect.position.y, z), Vector3(thickness, outer_h, depth), bevel, material, stats, fine, "frame")
	_chamfer_box(parent, prefix + "Head", Vector3(rect.position.x, rect.position.y + rect.size.y * 0.5 + thickness * 0.5, z), Vector3(outer_w, thickness, depth), bevel, material, stats, fine, "frame")
	_chamfer_box(parent, prefix + "Sill", Vector3(rect.position.x, rect.position.y - rect.size.y * 0.5 - thickness * 0.5, z), Vector3(outer_w, thickness, depth), bevel, material, stats, fine, "frame")


# The edge band is deliberately visible in front view. It communicates pane
# thickness even when the transmission surface is nearly colorless.
static func _add_glass_edge_frame(parent: Node3D, prefix: String, rect: Rect2, z: float, depth: float, material: Material, stats: Dictionary) -> void:
	var edge := 0.018
	_box(parent, prefix + "Left", Vector3(rect.position.x - rect.size.x * 0.5 + edge * 0.5, rect.position.y, z), Vector3(edge, rect.size.y, depth), material, stats, true, "glass_edge")
	_box(parent, prefix + "Right", Vector3(rect.position.x + rect.size.x * 0.5 - edge * 0.5, rect.position.y, z), Vector3(edge, rect.size.y, depth), material, stats, true, "glass_edge")
	_box(parent, prefix + "Head", Vector3(rect.position.x, rect.position.y + rect.size.y * 0.5 - edge * 0.5, z), Vector3(rect.size.x, edge, depth), material, stats, true, "glass_edge")
	_box(parent, prefix + "Sill", Vector3(rect.position.x, rect.position.y - rect.size.y * 0.5 + edge * 0.5, z), Vector3(rect.size.x, edge, depth), material, stats, true, "glass_edge")


static func _build_vitrine_content(parent: Node3D, rect: Rect2, cavity_back_z: float, palette: Dictionary, options: Dictionary, stats: Dictionary) -> void:
	var content := Node3D.new()
	content.name = "VitrineMountedArchivalInstrument"
	content.set_meta("content_role", "default_scale_and_depth_witness")
	content.set_meta("replaceable_via", "VitrineArtifactSocket")
	parent.add_child(content)
	var bottom := rect.position.y - rect.size.y * 0.5
	var base_y := bottom + 0.16
	var artifact_z := cavity_back_z + 0.22
	_chamfer_box(content, "ArtifactMountBase", Vector3(0, base_y, artifact_z), Vector3(minf(0.72, rect.size.x * 0.42), 0.12, 0.3), 0.015, _slot(palette, "dark"), stats, false, "trim")
	_chamfer_box(content, "ArtifactMountStem", Vector3(0, base_y + 0.28, artifact_z - 0.03), Vector3(0.075, 0.5, 0.075), 0.008, _slot(palette, "bronze"), stats, false, "bronze")
	var torus := _mesh_instance(content, "ArchivalInstrumentRing", _shared_vitrine_torus(), Vector3(0, base_y + 0.56, artifact_z + 0.02), Vector3.ONE, Vector3(PI * 0.5, 0, 0), _slot(palette, "bronze"), stats, 576, SECONDARY_DETAIL_END_M, "bronze")
	torus.set_meta("artifact_content", true)
	_mesh_instance(content, "ArchivalInstrumentAxis", _shared_vitrine_pin(), Vector3(0, base_y + 0.56, artifact_z + 0.025), Vector3(1.0, 0.9, 1.0), Vector3(PI * 0.5, 0, 0), _slot(palette, "trim"), stats, 48, SECONDARY_DETAIL_END_M, "trim")
	_chamfer_box(content, "ArtifactCaptionPlate", Vector3(0, bottom + 0.09, 0.13), Vector3(minf(0.54, rect.size.x * 0.32), 0.055, 0.025), 0.005, _slot(palette, "bronze"), stats, true, "bronze")


static func _mesh_instance(parent: Node3D, node_name: String, mesh: Mesh, at: Vector3, scale_value: Vector3, rotation_value: Vector3, material: Material, stats: Dictionary, triangle_estimate: int, range_end: float, surface_slot: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.rotation = rotation_value
	instance.scale = scale_value
	instance.mesh = mesh
	instance.material_override = material
	instance.visibility_range_end = range_end
	instance.set_meta("surface_slot", surface_slot)
	parent.add_child(instance)
	stats["mesh_instances"] = int(stats["mesh_instances"]) + 1
	stats["estimated_triangles_lod0"] = int(stats["estimated_triangles_lod0"]) + triangle_estimate
	return instance


static func _add_frame_fasteners(parent: Node3D, node_name: String, rect: Rect2, z: float, palette: Dictionary, per_edge: int, stats: Dictionary) -> void:
	var transforms: Array[Transform3D] = []
	var count := maxi(2, per_edge)
	for index in range(count):
		var t := float(index) / float(count - 1)
		var x := lerpf(rect.position.x - rect.size.x * 0.5, rect.position.x + rect.size.x * 0.5, t)
		transforms.append(_fastener_transform(Vector3(x, rect.position.y - rect.size.y * 0.5, z)))
		transforms.append(_fastener_transform(Vector3(x, rect.position.y + rect.size.y * 0.5, z)))
	for index in range(1, count - 1):
		var t := float(index) / float(count - 1)
		var y := lerpf(rect.position.y - rect.size.y * 0.5, rect.position.y + rect.size.y * 0.5, t)
		transforms.append(_fastener_transform(Vector3(rect.position.x - rect.size.x * 0.5, y, z)))
		transforms.append(_fastener_transform(Vector3(rect.position.x + rect.size.x * 0.5, y, z)))
	_multimesh(parent, node_name, _shared_fastener_mesh(), transforms, _slot(palette, "bronze"), stats, HERO_DETAIL_END_M, 32, "fastener")


static func _add_glass_imperfection(parent: Node3D, node_name: String, rect: Rect2, z: float, palette: Dictionary, seed: int, stats: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	# Two faint maintenance streaks live close to the gasket instead of crossing the
	# whole pane. Their transforms carry seed variation; the material stays pooled.
	var edge_dust: Array[Transform3D] = []
	for index in range(2):
		var side := -1.0 if index == 0 else 1.0
		var x := rect.position.x + side * (rect.size.x * 0.5 - rng.randf_range(0.025, 0.055))
		var y := rect.position.y - rect.size.y * 0.5 + rng.randf_range(0.12, rect.size.y * 0.3)
		edge_dust.append(_scaled_transform(Vector3(x, y, z), Vector3(rng.randf_range(0.005, 0.009), rng.randf_range(0.09, 0.24), 0.003)))
	_multibox(parent, node_name + "EdgeDust", edge_dust, _slot(palette, "wear"), stats, HERO_DETAIL_END_M, "glass_residue")

	# At most three fingerprint cards per pane. A single cached QuadMesh and shader
	# are shared by every width and seed; only the MultiMesh transforms differ.
	var fingerprints: Array[Transform3D] = []
	var fingerprint_count := 2 if rect.size.x < 2.2 else 3
	for index in range(fingerprint_count):
		var x := rng.randf_range(rect.position.x - rect.size.x * 0.34, rect.position.x + rect.size.x * 0.34)
		var y := rect.position.y - rect.size.y * 0.5 + rng.randf_range(rect.size.y * 0.18, rect.size.y * 0.5)
		var size := rng.randf_range(0.075, 0.12)
		fingerprints.append(_scaled_rotated_transform(Vector3(x, y, z + 0.0015), Vector3(size, size * rng.randf_range(0.82, 1.16), 1.0), rng.randf_range(-0.42, 0.42)))
	_multimesh(parent, node_name + "FingerprintResidue", _shared_glass_wear_quad(), fingerprints, _slot(palette, "glass_wear", _shared_glass_residue_material()), stats, HERO_DETAIL_END_M, 2, "glass_residue")
	stats["glass_residue_instances"] = int(stats["glass_residue_instances"]) + edge_dust.size() + fingerprints.size()


static func _rect_frame_collision_boxes(rect: Rect2, thickness: float, z: float, depth: float) -> Array:
	var outer_w := rect.size.x + thickness * 2.0
	var outer_h := rect.size.y + thickness * 2.0
	return [
		{"name": "LeftRail", "at": Vector3(rect.position.x - rect.size.x * 0.5 - thickness * 0.5, rect.position.y, z), "size": Vector3(thickness, outer_h, depth)},
		{"name": "RightRail", "at": Vector3(rect.position.x + rect.size.x * 0.5 + thickness * 0.5, rect.position.y, z), "size": Vector3(thickness, outer_h, depth)},
		{"name": "HeadRail", "at": Vector3(rect.position.x, rect.position.y + rect.size.y * 0.5 + thickness * 0.5, z), "size": Vector3(outer_w, thickness, depth)},
		{"name": "SillRail", "at": Vector3(rect.position.x, rect.position.y - rect.size.y * 0.5 - thickness * 0.5, z), "size": Vector3(outer_w, thickness, depth)},
	]


# The painted-metal manifest remains constant across widths: three mullion
# shapes are always authored, with surplus shapes coincident on a real mullion
# for narrower spans. This preserves exact collision coverage without phantom
# blockers or width-dependent physics allocations.
static func _window_metal_collision_boxes(cells: int, glass_rect: Rect2, transom_y: float, front_z: float) -> Array:
	var boxes := _rect_frame_collision_boxes(_resized_rect(glass_rect, 0.035), 0.014, front_z + 0.073, maxf(0.025, 0.014 * 0.78))
	var mullion_x: Array[float] = []
	for seam in range(1, cells):
		var x := -float(cells) * 0.5 + float(seam)
		if absf(x) < glass_rect.size.x * 0.5 - 0.08:
			mullion_x.append(x)
	while mullion_x.size() < 3:
		mullion_x.append(mullion_x[0] if not mullion_x.is_empty() else 0.0)
	for index in range(3):
		boxes.append({"name": "Mullion_%02d" % index, "at": Vector3(mullion_x[index], glass_rect.position.y, front_z + 0.061), "size": Vector3(0.022, glass_rect.size.y - 0.045, 0.02)})
	boxes.append({"name": "Transom", "at": Vector3(0, transom_y, front_z + 0.06), "size": Vector3(glass_rect.size.x - 0.04, 0.022, 0.02)})
	return boxes


static func _opening_surround_collision_boxes(cells: int, height: float, rect: Rect2, depth: float) -> Array:
	var w := float(cells)
	var left_edge := rect.position.x - rect.size.x * 0.5
	var right_edge := rect.position.x + rect.size.x * 0.5
	var bottom := rect.position.y - rect.size.y * 0.5
	var top := rect.position.y + rect.size.y * 0.5
	return [
		{"name": "Apron", "at": Vector3(0, bottom * 0.5, 0), "size": Vector3(w, bottom, depth)},
		{"name": "Head", "at": Vector3(0, top + (height - top) * 0.5, 0), "size": Vector3(w, height - top, depth)},
		{"name": "LeftPier", "at": Vector3((-w * 0.5 + left_edge) * 0.5, rect.position.y, 0), "size": Vector3(left_edge + w * 0.5, rect.size.y, depth)},
		{"name": "RightPier", "at": Vector3((w * 0.5 + right_edge) * 0.5, rect.position.y, 0), "size": Vector3(w * 0.5 - right_edge, rect.size.y, depth)},
	]


static func _add_collision_body(parent: Node3D, node_name: String, boxes: Array, truth: String, stats: Dictionary, options: Dictionary) -> StaticBody3D:
	return _add_surface_collision_body(parent, node_name, boxes, truth, &"stone", stats, options)


static func _add_surface_collision_body(parent: Node3D, node_name: String, boxes: Array, truth: String, surface_id: StringName, stats: Dictionary, options: Dictionary) -> StaticBody3D:
	var contract: Dictionary = SURFACE_CONTRACTS.get(str(surface_id), SURFACE_CONTRACTS["stone"])
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = int(options.get("collision_layer", 1))
	body.collision_mask = int(options.get("collision_mask", 1))
	body.physics_material_override = _shared_surface_physics(surface_id)
	body.set_meta("collision_truth", truth)
	body.set_meta("physics_surface_id", str(surface_id))
	body.set_meta("surface_id", str(surface_id))
	body.set_meta("surface_audio", str(surface_id))
	body.set_meta("friction", float(contract["friction"]))
	body.set_meta("bounce", float(contract["bounce"]))
	body.set_meta("impact", str(contract["impact"]))
	body.set_meta("decal", str(contract["decal"]))
	body.set_meta("breakability", str(contract["breakability"]))
	body.set_meta("blocks_motion", true)
	for box_data in boxes:
		var collision := CollisionShape3D.new()
		collision.name = str(box_data["name"])
		collision.position = box_data["at"]
		collision.shape = _shared_box_shape(box_data["size"])
		body.add_child(collision)
		stats["collision_shapes"] = int(stats["collision_shapes"]) + 1
	parent.add_child(body)
	stats["collision_bodies"] = int(stats["collision_bodies"]) + 1
	var shapes_by_surface: Dictionary = stats["collision_shapes_by_surface"]
	shapes_by_surface[str(surface_id)] = int(shapes_by_surface.get(str(surface_id), 0)) + boxes.size()
	return body


static func _add_glass_collision(parent: Node3D, node_name: String, rect: Rect2, z: float, thickness: float, surface_id: StringName, stats: Dictionary, options: Dictionary, extra_boxes: Array = []) -> void:
	var boxes: Array = [
		{"name": "GlassSurfaceShape", "at": Vector3(rect.position.x, rect.position.y, z), "size": Vector3(rect.size.x, rect.size.y, thickness)},
	]
	boxes.append_array(extra_boxes)
	var body := _add_surface_collision_body(parent, node_name, boxes, "distinct_laminated_glass_surface", &"glass_laminated", stats, options)
	body.set_meta("surface_type", "laminated_glass")
	body.set_meta("assembly_surface_id", str(surface_id))
	body.set_meta("thickness_m", thickness)
	body.set_meta("breakable", _opt_bool(options, "breakable_glass", false))
	body.set_meta("break_threshold_j", float(options.get("break_threshold_j", 42.0)))
	body.set_meta("acoustic_transmission", 0.18)
	body.set_meta("impact_response", "glass_hook_or_rigid_static")


static func _add_glass_hook(parent: Node3D, node_name: String, rect: Rect2, z: float, kind: StringName, options: Dictionary, stats: Dictionary) -> void:
	var area := GlassImpactHook.new()
	area.name = node_name
	area.position = Vector3(rect.position.x, rect.position.y, z)
	area.collision_layer = int(options.get("interaction_layer", 262144))
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("interaction", "glass_impact_hook")
	area.set_meta("kind", str(kind))
	area.set_meta("breakable", _opt_bool(options, "breakable_glass", false))
	area.set_meta("break_threshold_j", float(options.get("break_threshold_j", 42.0)))
	area.set_meta("fragment_budget", int(options.get("fragment_budget", 24)))
	area.set_meta("fragment_policy", "spawn_on_demand_external_pool")
	area.set_meta("impact", "glass_laminated")
	area.set_meta("decal", "glass_mark")
	var shape := CollisionShape3D.new()
	shape.name = "GlassInteractionShape"
	shape.shape = _shared_box_shape(Vector3(rect.size.x, rect.size.y, 0.04))
	area.add_child(shape)
	parent.add_child(area)
	stats["interaction_areas"] = int(stats["interaction_areas"]) + 1


static func _add_portal_trigger(parent: Node3D, rect: Rect2, options: Dictionary, stats: Dictionary) -> void:
	var area := Area3D.new()
	area.name = "PortalTraversalHook"
	area.position = Vector3(0, rect.size.y * 0.5, 0)
	area.collision_layer = 0
	area.collision_mask = int(options.get("portal_trigger_mask", 1))
	area.monitoring = true
	area.monitorable = false
	area.set_meta("interaction", "portal_traversal_hook")
	area.set_meta("portal_mode", "walkthrough")
	area.set_meta("clear_opening_m", Vector2(rect.size.x, rect.size.y))
	var shape := CollisionShape3D.new()
	shape.name = "TraversalVolume"
	shape.shape = _shared_box_shape(Vector3(rect.size.x - 0.08, rect.size.y - 0.08, 0.42))
	area.add_child(shape)
	parent.add_child(area)
	stats["interaction_areas"] = int(stats["interaction_areas"]) + 1


static func _box(parent: Node3D, node_name: String, at: Vector3, size: Vector3, material: Material, stats: Dictionary, fine: bool = false, surface_slot: String = "") -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.scale = size
	instance.mesh = _shared_unit_box()
	instance.material_override = material
	instance.set_meta("surface_slot", surface_slot)
	instance.set_meta("construction_size_m", size)
	instance.set_meta("uv_density_m", 1.0)
	if fine:
		instance.visibility_range_end = HERO_DETAIL_END_M
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stats["mesh_instances"] = int(stats["mesh_instances"]) + 1
	stats["estimated_triangles_lod0"] = int(stats["estimated_triangles_lod0"]) + 12
	parent.add_child(instance)
	return instance


static func _chamfer_box(parent: Node3D, node_name: String, at: Vector3, size: Vector3, bevel: float, material: Material, stats: Dictionary, fine: bool = false, surface_slot: String = "") -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.mesh = _shared_chamfer_mesh(size, bevel)
	instance.material_override = material
	instance.set_meta("surface_slot", surface_slot)
	instance.set_meta("construction_size_m", size)
	instance.set_meta("edge_profile", "cached_chamfer_v1")
	instance.set_meta("stable_authored_normals", true)
	if fine:
		instance.visibility_range_end = HERO_DETAIL_END_M
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stats["mesh_instances"] = int(stats["mesh_instances"]) + 1
	stats["profile_mesh_instances"] = int(stats["profile_mesh_instances"]) + 1
	stats["estimated_triangles_lod0"] = int(stats["estimated_triangles_lod0"]) + 44
	parent.add_child(instance)
	return instance


static func _multibox(parent: Node3D, node_name: String, transforms: Array[Transform3D], material: Material, stats: Dictionary, range_end: float, surface_slot: String) -> void:
	_multimesh(parent, node_name, _shared_unit_box(), transforms, material, stats, range_end, 12, surface_slot)


static func _multimesh(parent: Node3D, node_name: String, mesh: Mesh, transforms: Array[Transform3D], material: Material, stats: Dictionary, range_end: float, triangles_per_instance: int, surface_slot: String) -> void:
	if transforms.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
	multimesh.mesh = mesh
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = material
	instance.visibility_range_end = range_end
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.set_meta("surface_slot", surface_slot)
	parent.add_child(instance)
	stats["multimesh_draws"] = int(stats["multimesh_draws"]) + 1
	stats["multimesh_instances"] = int(stats["multimesh_instances"]) + transforms.size()
	stats["estimated_triangles_lod0"] = int(stats["estimated_triangles_lod0"]) + transforms.size() * triangles_per_instance


static func _shared_unit_box() -> BoxMesh:
	if _unit_box_mesh == null:
		_unit_box_mesh = BoxMesh.new()
		_unit_box_mesh.size = Vector3.ONE
	return _unit_box_mesh


static func _shared_chamfer_mesh(size: Vector3, requested_bevel: float) -> ArrayMesh:
	var bevel := minf(requested_bevel, minf(size.x, minf(size.y, size.z)) * 0.44)
	bevel = maxf(0.0005, bevel)
	var key := "%.4f|%.4f|%.4f|%.4f" % [size.x, size.y, size.z, bevel]
	if _chamfer_mesh_cache.has(key):
		return _chamfer_mesh_cache[key] as ArrayMesh
	var half := size * 0.5
	var inner := Vector3(maxf(0.0001, half.x - bevel), maxf(0.0001, half.y - bevel), maxf(0.0001, half.z - bevel))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Six broad faces retain flat, predictable PBR normals.
	_surface_quad(st, Vector3(half.x, -inner.y, -inner.z), Vector3(half.x, inner.y, -inner.z), Vector3(half.x, inner.y, inner.z), Vector3(half.x, -inner.y, inner.z), Vector3.RIGHT)
	_surface_quad(st, Vector3(-half.x, -inner.y, inner.z), Vector3(-half.x, inner.y, inner.z), Vector3(-half.x, inner.y, -inner.z), Vector3(-half.x, -inner.y, -inner.z), Vector3.LEFT)
	_surface_quad(st, Vector3(-inner.x, half.y, -inner.z), Vector3(-inner.x, half.y, inner.z), Vector3(inner.x, half.y, inner.z), Vector3(inner.x, half.y, -inner.z), Vector3.UP)
	_surface_quad(st, Vector3(-inner.x, -half.y, inner.z), Vector3(-inner.x, -half.y, -inner.z), Vector3(inner.x, -half.y, -inner.z), Vector3(inner.x, -half.y, inner.z), Vector3.DOWN)
	_surface_quad(st, Vector3(-inner.x, -inner.y, half.z), Vector3(inner.x, -inner.y, half.z), Vector3(inner.x, inner.y, half.z), Vector3(-inner.x, inner.y, half.z), Vector3.BACK)
	_surface_quad(st, Vector3(inner.x, -inner.y, -half.z), Vector3(-inner.x, -inner.y, -half.z), Vector3(-inner.x, inner.y, -half.z), Vector3(inner.x, inner.y, -half.z), Vector3.FORWARD)
	# Twelve edge planes catch highlights without unstable smoothing.
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			_surface_quad(st, Vector3(sx * half.x, sy * inner.y, -inner.z), Vector3(sx * inner.x, sy * half.y, -inner.z), Vector3(sx * inner.x, sy * half.y, inner.z), Vector3(sx * half.x, sy * inner.y, inner.z), Vector3(sx, sy, 0).normalized())
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_surface_quad(st, Vector3(sx * half.x, -inner.y, sz * inner.z), Vector3(sx * inner.x, -inner.y, sz * half.z), Vector3(sx * inner.x, inner.y, sz * half.z), Vector3(sx * half.x, inner.y, sz * inner.z), Vector3(sx, 0, sz).normalized())
	for sy in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_surface_quad(st, Vector3(-inner.x, sy * half.y, sz * inner.z), Vector3(-inner.x, sy * inner.y, sz * half.z), Vector3(inner.x, sy * inner.y, sz * half.z), Vector3(inner.x, sy * half.y, sz * inner.z), Vector3(0, sy, sz).normalized())
	# Eight planar corner facets complete the watertight profile.
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_surface_triangle(st, Vector3(sx * half.x, sy * inner.y, sz * inner.z), Vector3(sx * inner.x, sy * half.y, sz * inner.z), Vector3(sx * inner.x, sy * inner.y, sz * half.z), Vector3(sx, sy, sz).normalized())
	st.generate_tangents()
	var mesh := st.commit()
	_chamfer_mesh_cache[key] = mesh
	return mesh


static func _surface_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	var vertices: Array[Vector3] = [a, b, c, d]
	if (b - a).cross(c - a).dot(normal) < 0.0:
		vertices = [a, d, c, b]
	var uvs: Array[Vector2] = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for index in [0, 1, 2, 0, 2, 3]:
		st.set_normal(normal)
		st.set_uv(uvs[index])
		st.add_vertex(vertices[index])


static func _surface_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	var vertices: Array[Vector3] = [a, b, c]
	if (b - a).cross(c - a).dot(normal) < 0.0:
		vertices = [a, c, b]
	for index in range(3):
		st.set_normal(normal)
		st.set_uv([Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 1)][index])
		st.add_vertex(vertices[index])


static func _shared_fastener_mesh() -> CylinderMesh:
	if _fastener_mesh == null:
		_fastener_mesh = CylinderMesh.new()
		_fastener_mesh.top_radius = 0.012
		_fastener_mesh.bottom_radius = 0.012
		_fastener_mesh.height = 0.009
		_fastener_mesh.radial_segments = 8
		_fastener_mesh.rings = 1
	return _fastener_mesh


static func _shared_vitrine_torus() -> TorusMesh:
	if _vitrine_artifact_torus == null:
		_vitrine_artifact_torus = TorusMesh.new()
		_vitrine_artifact_torus.inner_radius = 0.16
		_vitrine_artifact_torus.outer_radius = 0.29
		_vitrine_artifact_torus.rings = 24
		_vitrine_artifact_torus.ring_segments = 12
	return _vitrine_artifact_torus


static func _shared_vitrine_pin() -> CylinderMesh:
	if _vitrine_artifact_pin == null:
		_vitrine_artifact_pin = CylinderMesh.new()
		_vitrine_artifact_pin.top_radius = 0.045
		_vitrine_artifact_pin.bottom_radius = 0.045
		_vitrine_artifact_pin.height = 0.34
		_vitrine_artifact_pin.radial_segments = 12
		_vitrine_artifact_pin.rings = 1
	return _vitrine_artifact_pin


static func _shared_vitrine_hinge() -> CylinderMesh:
	if _vitrine_hinge_mesh == null:
		_vitrine_hinge_mesh = CylinderMesh.new()
		_vitrine_hinge_mesh.top_radius = 0.024
		_vitrine_hinge_mesh.bottom_radius = 0.024
		_vitrine_hinge_mesh.height = 0.12
		_vitrine_hinge_mesh.radial_segments = 12
		_vitrine_hinge_mesh.rings = 1
	return _vitrine_hinge_mesh


static func _shared_glass_wear_quad() -> QuadMesh:
	if _glass_wear_quad == null:
		_glass_wear_quad = QuadMesh.new()
		_glass_wear_quad.size = Vector2.ONE
	return _glass_wear_quad


static func _shared_glass_residue_material() -> ShaderMaterial:
	if _glass_residue_material == null:
		if _glass_residue_shader == null:
			_glass_residue_shader = Shader.new()
			_glass_residue_shader.code = GLASS_RESIDUE_SHADER_CODE
		_glass_residue_material = ShaderMaterial.new()
		_glass_residue_material.shader = _glass_residue_shader
		_glass_residue_material.set_shader_parameter("residue_tint", Color(0.72, 0.69, 0.61, 0.085))
	return _glass_residue_material


static func _shared_glass_physics() -> PhysicsMaterial:
	if _glass_physics_material == null:
		_glass_physics_material = PhysicsMaterial.new()
		_glass_physics_material.friction = 0.22
		_glass_physics_material.rough = false
		_glass_physics_material.bounce = 0.06
		_glass_physics_material.absorbent = true
	return _glass_physics_material


static func _shared_stone_physics() -> PhysicsMaterial:
	if _stone_physics_material == null:
		_stone_physics_material = PhysicsMaterial.new()
		_stone_physics_material.friction = 0.82
		_stone_physics_material.rough = true
		_stone_physics_material.bounce = 0.02
		_stone_physics_material.absorbent = true
	return _stone_physics_material


static func _shared_bronze_physics() -> PhysicsMaterial:
	if _bronze_physics_material == null:
		_bronze_physics_material = _physics_material_for(&"bronze")
	return _bronze_physics_material


static func _shared_painted_metal_physics() -> PhysicsMaterial:
	if _painted_metal_physics_material == null:
		_painted_metal_physics_material = _physics_material_for(&"painted_metal")
	return _painted_metal_physics_material


static func _shared_rubber_physics() -> PhysicsMaterial:
	if _rubber_physics_material == null:
		_rubber_physics_material = _physics_material_for(&"rubber")
	return _rubber_physics_material


static func _shared_surface_physics(surface_id: StringName) -> PhysicsMaterial:
	match surface_id:
		&"glass_laminated": return _shared_glass_physics()
		&"bronze": return _shared_bronze_physics()
		&"painted_metal": return _shared_painted_metal_physics()
		&"rubber": return _shared_rubber_physics()
		_: return _shared_stone_physics()


static func _physics_material_for(surface_id: StringName) -> PhysicsMaterial:
	var contract: Dictionary = SURFACE_CONTRACTS.get(str(surface_id), SURFACE_CONTRACTS["stone"])
	var material := PhysicsMaterial.new()
	material.friction = float(contract["friction"])
	material.bounce = float(contract["bounce"])
	material.rough = surface_id in [&"stone", &"rubber"]
	material.absorbent = true
	return material


static func _shared_box_shape(size: Vector3) -> BoxShape3D:
	var key := "%0.4f|%0.4f|%0.4f" % [size.x, size.y, size.z]
	if not _shape_cache.has(key):
		var shape := BoxShape3D.new()
		shape.size = size
		_shape_cache[key] = shape
	return _shape_cache[key]


static func _scaled_transform(position: Vector3, scale_value: Vector3) -> Transform3D:
	return Transform3D(Basis.IDENTITY.scaled(scale_value), position)


static func _scaled_rotated_transform(position: Vector3, scale_value: Vector3, rotation_z: float) -> Transform3D:
	return Transform3D(Basis(Vector3.FORWARD, rotation_z).scaled(scale_value), position)


static func _fastener_transform(position: Vector3) -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, PI * 0.5), position)


static func _slot(palette: Dictionary, name: String, fallback: Material = null) -> Material:
	var value: Variant = palette.get(name, fallback)
	if value is Material:
		return value as Material
	return fallback


static func _resolved_seed(kind: StringName, cells: int, height: float, options: Dictionary) -> int:
	if options.has("seed"):
		return int(options["seed"])
	return abs(hash("%s|%d|%.2f" % [str(kind), cells, height]))


static func _opt_bool(options: Dictionary, key: String, fallback: bool) -> bool:
	if not options.has(key):
		return fallback
	var value: Variant = options[key]
	if value is bool:
		return value
	return str(value).strip_edges().to_lower() in ["1", "true", "yes", "on"]


static func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


static func _pbr_material(tint: Color, roughness: float, metallic: float, prefix: String, uv_scale: Vector3) -> StandardMaterial3D:
	var material := _material(tint, roughness, metallic)
	material.albedo_texture = _load_texture(MATERIAL_ROOT + prefix + "_albedo.png")
	var normal := _load_texture(MATERIAL_ROOT + prefix + "_normal.png")
	if normal != null:
		material.normal_enabled = true
		material.normal_texture = normal
		material.normal_scale = 0.5
	material.roughness_texture = _load_texture(MATERIAL_ROOT + prefix + "_roughness.png")
	var ao := _load_texture(MATERIAL_ROOT + prefix + "_ao.png")
	if ao != null:
		material.ao_enabled = true
		material.ao_texture = ao
	var metallic_map := _load_texture(MATERIAL_ROOT + prefix + "_metallic.png")
	if metallic_map != null:
		material.metallic_texture = metallic_map
	material.uv1_scale = uv_scale
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	return material


static func _glass_material(base_tint: Color, edge_tint: Color, roughness: float, thickness: float) -> ShaderMaterial:
	if _glass_shader == null:
		_glass_shader = Shader.new()
		_glass_shader.code = GLASS_SHADER_CODE
	var material := ShaderMaterial.new()
	material.shader = _glass_shader
	material.set_shader_parameter("base_tint", base_tint)
	material.set_shader_parameter("edge_tint", edge_tint)
	material.set_shader_parameter("surface_roughness", roughness)
	material.set_shader_parameter("pane_thickness", thickness)
	return material


static func _transparent_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := _material(color, roughness, 0.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


static func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _material(color, 0.38, 0.05)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


static func _load_texture(resource_path: String) -> Texture2D:
	if _texture_cache.has(resource_path):
		return _texture_cache[resource_path]
	var texture: Texture2D = null
	if ResourceLoader.exists(resource_path):
		texture = load(resource_path) as Texture2D
	if texture == null:
		var absolute_path := ProjectSettings.globalize_path(resource_path)
		if FileAccess.file_exists(absolute_path):
			var image := Image.load_from_file(absolute_path)
			if image != null and not image.is_empty():
				if not image.has_mipmaps():
					image.generate_mipmaps()
				texture = ImageTexture.create_from_image(image)
	_texture_cache[resource_path] = texture
	return texture
