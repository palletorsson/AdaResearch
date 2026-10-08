# museum_wall_c27_occupied_gallery.gd
# Complete C27 museum context for one untouched production MuseumWallPiece.
#
# This is an evidence wrapper, not a replacement wall builder. It places the hero
# inside a continuous one-metre-grid gallery with two production neighbours,
# room-scale floor/ceiling/returns, circulation depth, human scale and restrained
# peripheral museum use. All geometry is created once; there is no per-frame work.

extends Node3D
class_name MuseumWallC27OccupiedGallery

const API_VERSION := "museum_wall_c27_occupied_gallery_v1"
const GRID_M := 1.0
const ROOM_DEPTH_CELLS := 7
const ADJACENT_WIDTH_CELLS := 2
const SUPPORTED_FAMILIES := ["solid", "feature", "window", "vitrine", "service", "portal", "endcap"]
const WALL_PIECE_SCENE := preload("res://commons/artifacts/museum/museum_wall_piece.tscn")
const ARCH := preload("res://commons/artifacts/museum/museum_wall_architectural_spans.gd")

@export_enum("solid", "feature", "window", "vitrine", "service", "portal", "endcap")
var kind: String = "solid"
@export_range(1, 4, 1) var width_cells: int = 4
@export_range(3.0, 6.0, 0.25) var height: float = 4.0
@export var finish: String = "uffizi_stone"
@export var flip: bool = false
@export var enable_collision: bool = true
@export var quality_tier: String = "aaa"
@export var detail_seed: int = 13249
@export_range(0, 2, 1) var lod_level: int = 0
@export var enable_context_lights: bool = true

static var _context_material_cache: Dictionary = {}
static var _cylinder_mesh_cache: Dictionary = {}
static var _sphere_mesh_cache: Dictionary = {}

var _stone: Material
var _stone_dark: Material
var _bronze: Material
var _bronze_dark: Material
var _floor_a: Material
var _floor_b: Material
var _dark: Material
var _ceiling: Material
var _canvas: Material
var _warm_emissive: Material
var _green_emissive: Material
var _safety_red: Material

var _context_draw_nodes := 0
var _context_multimesh_instances := 0
var _context_lights := 0
var _adjacent_bays := 0
var _room_width_cells := 0
var _art_bay_x := 0.0
var _utility_bay_x := 0.0
var _terminal_side := 0.0
var _build_report: Dictionary = {}


func _ready() -> void:
	_build_gallery()


## Returns the immutable report generated with the gallery.
func get_context_report() -> Dictionary:
	return _build_report.duplicate(true)


func _build_gallery() -> void:
	kind = kind.to_lower()
	if not SUPPORTED_FAMILIES.has(kind):
		kind = "solid"
	width_cells = clampi(width_cells, 1, 4)
	height = clampf(height, 3.0, 6.0)
	if kind == "portal":
		width_cells = maxi(width_cells, 2)
	_room_width_cells = width_cells + (8 if kind == "endcap" else 4)
	_terminal_side = (1.0 if flip else -1.0) if kind == "endcap" else 0.0
	_build_materials()

	var gallery := Node3D.new()
	gallery.name = "OccupiedGalleryBay"
	gallery.set_meta("c27_context_api", API_VERSION)
	gallery.set_meta("grid_m", GRID_M)
	gallery.set_meta("room_width_cells", _room_width_cells)
	gallery.set_meta("room_depth_cells", ROOM_DEPTH_CELLS)
	gallery.set_meta("hero_family", kind)
	gallery.set_meta("hero_owned_width_m", float(width_cells))
	gallery.set_meta("central_module_unobscured", true)
	gallery.set_meta("allocations_in_process", 0)
	add_child(gallery)

	_build_floor(gallery)
	_build_ceiling(gallery)
	_build_wall_ensemble(gallery)
	_build_returns(gallery)
	_build_circulation(gallery)
	_build_occupied_story(gallery)
	_build_family_role_context(gallery)
	if enable_context_lights:
		_build_light_and_reflection_cues(gallery)
	if enable_collision:
		_build_shell_collision(gallery)

	_build_report = {
		"api_version": API_VERSION,
		"kind": kind,
		"width_cells": width_cells,
		"height_m": height,
		"grid_m": GRID_M,
		"room_width_cells": _room_width_cells,
		"room_depth_cells": ROOM_DEPTH_CELLS,
		"adjacent_wall_bays": _adjacent_bays,
		"central_module_count": 1,
		"central_module_unobscured": true,
		"continuous_floor": true,
		"continuous_ceiling": true,
		"return_wall_count": 1 if kind == "endcap" else 2,
		"circulation_depth_m": float(ROOM_DEPTH_CELLS),
		"human_scale_witness_m": 1.76,
		"context_draw_nodes": _context_draw_nodes,
		"context_multimesh_instances": _context_multimesh_instances,
		"context_light_count": _context_lights,
		"context_material_limit": 12,
		"context_materials_used": _context_material_count(),
		"reflection_probe_mode": "update_once" if enable_context_lights else "disabled",
		"no_per_frame_logic": true,
		"quest_strategy": "shared_materials_multimesh_floor_and_ceiling_bounded_static_lights",
	}
	gallery.set_meta("build_report", _build_report)
	set_meta("museum_wall_c27_context_report", _build_report)


func _build_materials() -> void:
	_stone = ARCH.create_pbr_material("stone", Color(0.68, 0.64, 0.57), Vector2(1.2, 2.4), detail_seed + 11)
	_stone_dark = ARCH.create_pbr_material("stone", Color(0.48, 0.44, 0.39), Vector2(1.15, 2.55), detail_seed + 17)
	_bronze = ARCH.create_pbr_material("bronze", Color(0.64, 0.44, 0.2), Vector2(1.6, 2.0), detail_seed + 23)
	_bronze_dark = ARCH.create_pbr_material("bronze", Color(0.38, 0.26, 0.13), Vector2(1.7, 2.15), detail_seed + 29)
	_floor_a = _shared_material("floor_a", Color(0.255, 0.275, 0.3), 0.48, 0.08)
	_floor_b = _shared_material("floor_b", Color(0.17, 0.19, 0.22), 0.58, 0.06)
	_dark = _shared_material("dark", Color(0.055, 0.065, 0.08), 0.42, 0.5)
	_ceiling = _shared_material("ceiling", Color(0.33, 0.325, 0.305), 0.78, 0.0)
	_canvas = _shared_material("canvas", Color(0.1, 0.25, 0.3), 0.64, 0.0)
	_warm_emissive = _shared_material("warm_emissive", Color(1.0, 0.67, 0.31), 0.28, 0.05, 2.0)
	_green_emissive = _shared_material("green_emissive", Color(0.18, 0.82, 0.46), 0.25, 0.02, 2.4)
	_safety_red = _shared_material("safety_red", Color(0.53, 0.025, 0.015), 0.36, 0.24)


func _build_floor(parent: Node3D) -> void:
	var floor_root := Node3D.new()
	floor_root.name = "ContinuousFloor_OneMetreGrid"
	floor_root.set_meta("tile_m", 1.0)
	floor_root.set_meta("width_cells", _room_width_cells)
	floor_root.set_meta("depth_cells", ROOM_DEPTH_CELLS)
	parent.add_child(floor_root)
	floor_root.add_child(_box("FloorUnderSlab", Vector3(0, -0.065, float(ROOM_DEPTH_CELLS) * 0.5), Vector3(float(_room_width_cells), 0.1, float(ROOM_DEPTH_CELLS)), _dark, 0.012))

	var even: Array[Transform3D] = []
	var odd: Array[Transform3D] = []
	var first_x := -float(_room_width_cells) * 0.5 + 0.5
	for x_index in range(_room_width_cells):
		for z_index in range(ROOM_DEPTH_CELLS):
			var transform := Transform3D(Basis.IDENTITY, Vector3(first_x + float(x_index), -0.012, float(z_index) + 0.5))
			if (x_index + z_index) % 2 == 0:
				even.append(transform)
			else:
				odd.append(transform)
	_add_multibox(floor_root, "FloorTilesEven", even, Vector3(0.982, 0.045, 0.982), _floor_a)
	_add_multibox(floor_root, "FloorTilesOdd", odd, Vector3(0.982, 0.045, 0.982), _floor_b)


func _build_ceiling(parent: Node3D) -> void:
	var ceiling_root := Node3D.new()
	ceiling_root.name = "ContinuousCeiling_OneMetreGrid"
	ceiling_root.set_meta("tile_m", 1.0)
	parent.add_child(ceiling_root)
	var ceiling_y := height + 0.22
	ceiling_root.add_child(_box("CeilingClosureSlab", Vector3(0, ceiling_y + 0.09, float(ROOM_DEPTH_CELLS) * 0.5), Vector3(float(_room_width_cells), 0.18, float(ROOM_DEPTH_CELLS)), _dark, 0.015))
	var panels: Array[Transform3D] = []
	var first_x := -float(_room_width_cells) * 0.5 + 0.5
	for x_index in range(_room_width_cells):
		for z_index in range(ROOM_DEPTH_CELLS):
			panels.append(Transform3D(Basis.IDENTITY, Vector3(first_x + float(x_index), ceiling_y - 0.015, float(z_index) + 0.5)))
	_add_multibox(ceiling_root, "CeilingCoffers", panels, Vector3(0.968, 0.045, 0.968), _ceiling)
	ceiling_root.add_child(_box("MuseumLightingTrackNear", Vector3(0, ceiling_y - 0.07, 1.18), Vector3(float(_room_width_cells) - 0.7, 0.055, 0.07), _dark, 0.01))
	ceiling_root.add_child(_box("MuseumLightingTrackFar", Vector3(0, ceiling_y - 0.07, 4.82), Vector3(float(_room_width_cells) - 1.1, 0.055, 0.07), _dark, 0.01))
	ceiling_root.add_child(_box("IndirectWarmSlot", Vector3(0, ceiling_y - 0.105, 0.44), Vector3(float(_room_width_cells) - 0.9, 0.026, 0.035), _warm_emissive, 0.005))


func _build_wall_ensemble(parent: Node3D) -> void:
	var wall_root := Node3D.new()
	wall_root.name = "ContinuousProductionWallRun"
	wall_root.set_meta("hero_piece_untouched", true)
	parent.add_child(wall_root)
	var hero_w := float(width_cells)
	if kind == "endcap":
		var non_terminal_side := -_terminal_side
		var first_x := non_terminal_side * (hero_w * 0.5 + 1.0)
		var second_x := non_terminal_side * (hero_w * 0.5 + 3.0)
		_add_production_piece(wall_root, "AdjacentBay_01_Solid", "solid", ADJACENT_WIDTH_CELLS, first_x, detail_seed + 211, false)
		_add_production_piece(wall_root, "AdjacentBay_02_Feature", "feature", ADJACENT_WIDTH_CELLS, second_x, detail_seed + 419, false)
		_art_bay_x = second_x
		_utility_bay_x = first_x
	else:
		var left_x := -(hero_w * 0.5 + 1.0)
		var right_x := hero_w * 0.5 + 1.0
		var left_kind := "solid" if kind == "feature" else "feature"
		var right_kind := "service" if kind == "solid" else "solid"
		_add_production_piece(wall_root, "AdjacentBay_Left_%s" % left_kind.capitalize(), left_kind, ADJACENT_WIDTH_CELLS, left_x, detail_seed + 211, false)
		_add_production_piece(wall_root, "AdjacentBay_Right_%s" % right_kind.capitalize(), right_kind, ADJACENT_WIDTH_CELLS, right_x, detail_seed + 419, false)
		_art_bay_x = left_x
		_utility_bay_x = right_x
	_add_production_piece(wall_root, "Hero_MuseumWallPiece_%s_%dm" % [kind.capitalize(), width_cells], kind, width_cells, 0.0, detail_seed, true)


func _add_production_piece(parent: Node3D, node_name: String, piece_kind: String, piece_width: int, x: float, seed: int, is_hero: bool) -> Node3D:
	var piece := WALL_PIECE_SCENE.instantiate() as Node3D
	piece.name = node_name
	piece.position = Vector3(x, 0, 0)
	piece.set("kind", piece_kind)
	piece.set("width_cells", piece_width)
	piece.set("height", height)
	piece.set("finish", finish)
	piece.set("flip", flip if is_hero else false)
	piece.set("enable_collision", enable_collision)
	piece.set("quality_tier", quality_tier)
	piece.set("detail_seed", seed)
	piece.set("lod_level", lod_level)
	piece.set_meta("c27_hero_subject", is_hero)
	piece.set_meta("context_adjacent_bay", not is_hero)
	piece.set_meta("untouched_production_scene", true)
	parent.add_child(piece)
	if not is_hero:
		_adjacent_bays += 1
	return piece


func _build_returns(parent: Node3D) -> void:
	var returns := Node3D.new()
	returns.name = "RoomScaleReturns"
	parent.add_child(returns)
	var sides := [-1.0, 1.0]
	if kind == "endcap":
		sides = [-_terminal_side]
	for side_variant in sides:
		var side := float(side_variant)
		var side_name := "Left" if side < 0.0 else "Right"
		var x := side * (float(_room_width_cells) * 0.5 + 0.08)
		returns.add_child(_box("%sContinuousReturn" % side_name, Vector3(x, height * 0.5, 1.8), Vector3(0.16, height, 3.6), _stone_dark, 0.014))
		returns.add_child(_box("%sReturnSkirting" % side_name, Vector3(x - side * 0.09, 0.14, 1.8), Vector3(0.045, 0.28, 3.45), _bronze_dark, 0.007))
		returns.add_child(_box("%sReturnCeilingReveal" % side_name, Vector3(x - side * 0.09, height - 0.12, 1.8), Vector3(0.04, 0.16, 3.5), _dark, 0.006))
	if kind == "endcap":
		# A set-back wall bounds the turn without reconnecting the declared terminal.
		var setback_x := _terminal_side * (float(_room_width_cells) * 0.5 + 0.08)
		returns.add_child(_box("TerminalSetbackReturn", Vector3(setback_x, height * 0.5, 5.15), Vector3(0.16, height, 3.7), _stone_dark, 0.014))
		returns.set_meta("terminal_gap_preserved", true)


func _build_circulation(parent: Node3D) -> void:
	var circulation := Node3D.new()
	circulation.name = "PublicCirculation_SevenMetres"
	circulation.set_meta("clear_depth_m", float(ROOM_DEPTH_CELLS))
	circulation.set_meta("minimum_route_width_m", 1.5)
	parent.add_child(circulation)
	var line_x := minf(1.35, float(width_cells) * 0.5 + 0.45)
	for side in [-1.0, 1.0]:
		circulation.add_child(_box("CirculationInlay_%s" % ("Left" if side < 0.0 else "Right"), Vector3(float(side) * line_x, 0.018, 3.55), Vector3(0.028, 0.018, 5.8), _bronze_dark, 0.004))
	for metre in range(1, ROOM_DEPTH_CELLS):
		circulation.add_child(_box("RouteMetreWitness_%02d" % metre, Vector3(0, 0.019, float(metre)), Vector3(0.14, 0.02, 0.022), _bronze, 0.004))


func _build_occupied_story(parent: Node3D) -> void:
	var story := Node3D.new()
	story.name = "RestrainedOccupiedMuseumStory"
	story.set_meta("central_keepout_width_m", float(width_cells) + 0.5)
	story.set_meta("central_keepout_depth_m", 1.15)
	parent.add_child(story)
	_build_adjacent_artwork(story, _art_bay_x)
	_build_bench(story, _utility_bay_x, 2.2)
	var plinth_side := 1.0 if _art_bay_x < 0.0 else -1.0
	_build_small_exhibit(story, plinth_side * (float(_room_width_cells) * 0.5 - 0.72), 1.12)
	var visitor_side := -plinth_side
	_build_human_scale_witness(story, visitor_side * (float(_room_width_cells) * 0.5 - 0.58), 4.25)
	_build_exit_fixture(story, visitor_side)


func _build_adjacent_artwork(parent: Node3D, x: float) -> void:
	var artwork := Node3D.new()
	artwork.name = "AdjacentBay_ConservationArtwork"
	artwork.position = Vector3(x, 0, 0)
	artwork.set_meta("outside_hero_span", true)
	parent.add_child(artwork)
	artwork.add_child(_box("ArtworkShadowReveal", Vector3(0, 2.12, 0.245), Vector3(1.42, 1.46, 0.055), _dark, 0.012))
	artwork.add_child(_box("ArtworkCanvas", Vector3(0, 2.12, 0.287), Vector3(1.12, 1.16, 0.035), _canvas, 0.008))
	artwork.add_child(_box("FrameTop", Vector3(0, 2.82, 0.318), Vector3(1.44, 0.065, 0.075), _bronze, 0.008))
	artwork.add_child(_box("FrameBottom", Vector3(0, 1.42, 0.318), Vector3(1.44, 0.065, 0.075), _bronze_dark, 0.008))
	for side in [-1.0, 1.0]:
		artwork.add_child(_box("FrameSide_%s" % ("Left" if side < 0.0 else "Right"), Vector3(float(side) * 0.69, 2.12, 0.318), Vector3(0.065, 1.34, 0.075), _bronze, 0.008))


func _build_bench(parent: Node3D, x: float, z: float) -> void:
	var bench := Node3D.new()
	bench.name = "PeripheralMuseumBench"
	bench.position = Vector3(x, 0, z)
	bench.set_meta("route_edge_prop", true)
	parent.add_child(bench)
	bench.add_child(_box("BenchSeat", Vector3(0, 0.48, 0), Vector3(1.38, 0.14, 0.46), _stone_dark, 0.025))
	bench.add_child(_box("BenchShadowGap", Vector3(0, 0.39, 0), Vector3(1.18, 0.04, 0.34), _dark, 0.008))
	for side in [-1.0, 1.0]:
		bench.add_child(_box("BenchLeg_%s" % ("Left" if side < 0.0 else "Right"), Vector3(float(side) * 0.48, 0.23, 0), Vector3(0.12, 0.46, 0.34), _bronze_dark, 0.014))


func _build_small_exhibit(parent: Node3D, x: float, z: float) -> void:
	var exhibit := Node3D.new()
	exhibit.name = "PeripheralPlinthExhibit"
	exhibit.position = Vector3(x, 0, z)
	exhibit.set_meta("peripheral_exhibit", true)
	parent.add_child(exhibit)
	exhibit.add_child(_box("PlinthBase", Vector3(0, 0.09, 0), Vector3(0.66, 0.18, 0.66), _stone_dark, 0.025))
	exhibit.add_child(_box("Plinth", Vector3(0, 0.52, 0), Vector3(0.5, 0.72, 0.5), _stone, 0.022))
	exhibit.add_child(_sphere("QuietBronzeStudy", Vector3(0, 1.02, 0), 0.23, _bronze))


func _build_human_scale_witness(parent: Node3D, x: float, z: float) -> void:
	var visitor := Node3D.new()
	visitor.name = "HumanScaleWitness_1_76m"
	visitor.position = Vector3(x, 0, z)
	visitor.set_meta("height_m", 1.76)
	visitor.set_meta("abstract_non_character", true)
	parent.add_child(visitor)
	visitor.add_child(_cylinder("VisitorTorso", Vector3(0, 1.15, 0), 0.18, 0.72, _dark, 18))
	visitor.add_child(_sphere("VisitorHead", Vector3(0, 1.68, 0), 0.14, _dark))
	for side in [-1.0, 1.0]:
		visitor.add_child(_cylinder("VisitorLeg_%s" % ("Left" if side < 0.0 else "Right"), Vector3(float(side) * 0.09, 0.44, 0), 0.055, 0.78, _dark, 12))


func _build_exit_fixture(parent: Node3D, side: float) -> void:
	var x := float(side) * (float(_room_width_cells) * 0.5 - 0.08)
	parent.add_child(_box("PeripheralExitHousing", Vector3(x, 3.35, 2.2), Vector3(0.045, 0.24, 0.52), _dark, 0.008))
	parent.add_child(_box("PeripheralExitFace", Vector3(x - float(side) * 0.028, 3.35, 2.2), Vector3(0.018, 0.14, 0.4), _green_emissive, 0.004))


func _build_family_role_context(parent: Node3D) -> void:
	var role := Node3D.new()
	role.name = "HeroFamilyRole_%s" % kind.capitalize()
	role.set_meta("central_module_unobscured", true)
	parent.add_child(role)
	match kind:
		"feature": _build_feature_display_context(role)
		"vitrine": _build_vitrine_context(role)
		"window": _build_window_depth_context(role)
		"portal": _build_portal_depth_context(role)
		"service": _build_service_role_context(role)
		"endcap": _build_endcap_turn_context(role)
		_: _build_solid_role_context(role)


func _build_viewing_zone(parent: Node3D, prefix: String, depth: float, zone_width: float) -> void:
	parent.add_child(_box("%sViewingLine" % prefix, Vector3(0, 0.026, depth), Vector3(zone_width, 0.022, 0.035), _bronze, 0.005))
	for side in [-1.0, 1.0]:
		parent.add_child(_box("%sViewingReturn_%s" % [prefix, "Left" if side < 0.0 else "Right"], Vector3(float(side) * zone_width * 0.5, 0.026, depth - 0.24), Vector3(0.035, 0.022, 0.5), _bronze_dark, 0.005))
	parent.set_meta("ideal_viewing_depth_m", depth)


func _build_feature_display_context(parent: Node3D) -> void:
	_build_viewing_zone(parent, "Feature", 1.42, maxf(1.1, float(width_cells) - 0.35))
	var display_width := minf(2.25, maxf(0.82, float(width_cells) - 0.9))
	var display := Node3D.new()
	display.name = "FeatureMapMonitor_CurrentExhibition"
	display.set_meta("map_text_monitor", true)
	display.set_meta("removable_exhibition_layer", true)
	parent.add_child(display)
	display.add_child(_box("MonitorShadowReveal", Vector3(0, 2.03, 0.34), Vector3(display_width + 0.16, 1.36, 0.045), _dark, 0.01))
	display.add_child(_box("MonitorField", Vector3(0, 2.03, 0.377), Vector3(display_width, 1.2, 0.025), _canvas, 0.008))
	display.add_child(_box("CurrentMapTitle", Vector3(-display_width * 0.18, 2.36, 0.396), Vector3(display_width * 0.48, 0.07, 0.012), _warm_emissive, 0.003))
	for row in range(4):
		var line_width := display_width * (0.64 - float(row % 2) * 0.12)
		display.add_child(_box("MapTextLine_%02d" % row, Vector3(-display_width * 0.12, 2.15 - float(row) * 0.15, 0.396), Vector3(line_width, 0.025, 0.012), _bronze, 0.003))
	display.add_child(_box("LineageNodeA", Vector3(display_width * 0.29, 1.77, 0.398), Vector3(0.11, 0.11, 0.014), _green_emissive, 0.004))
	display.add_child(_box("LineageNodeB", Vector3(display_width * 0.13, 1.62, 0.398), Vector3(0.08, 0.08, 0.014), _warm_emissive, 0.004))


func _build_vitrine_context(parent: Node3D) -> void:
	_build_viewing_zone(parent, "Vitrine", 1.18, maxf(1.0, float(width_cells) - 0.45))
	# A small label and sight-line witness identify the vitrine as an occupied
	# exhibition condition without replacing its production glass/content system.
	parent.add_child(_box("VitrineObjectLabelPost", Vector3(float(width_cells) * 0.5 - 0.28, 0.41, 0.78), Vector3(0.045, 0.78, 0.045), _bronze_dark, 0.006))
	parent.add_child(_box("VitrineObjectLabel", Vector3(float(width_cells) * 0.5 - 0.28, 0.82, 0.78), Vector3(0.38, 0.22, 0.035), _stone, 0.008))
	parent.add_child(_box("VitrineLabelRule", Vector3(float(width_cells) * 0.5 - 0.28, 0.84, 0.802), Vector3(0.25, 0.018, 0.01), _bronze, 0.002))


func _build_window_depth_context(parent: Node3D) -> void:
	var depth_width := maxf(1.2, float(width_cells) - 0.52)
	parent.add_child(_box("WindowDistantLayer", Vector3(0, 2.0, -1.2), Vector3(depth_width, 3.5, 0.09), _canvas, 0.012))
	for cell in range(width_cells):
		var x := -float(width_cells) * 0.5 + float(cell) + 0.5
		parent.add_child(_box("WindowDepthPier_%02d" % cell, Vector3(x, 1.75, -1.12), Vector3(0.09, 2.8, 0.07), _bronze_dark, 0.009))
	parent.add_child(_box("WindowDistantLight", Vector3(0, 3.28, -1.135), Vector3(depth_width * 0.72, 0.035, 0.025), _warm_emissive, 0.004))
	parent.set_meta("depth_context_m", 1.2)


func _build_portal_depth_context(parent: Node3D) -> void:
	var corridor_width := maxf(1.25, float(width_cells) - 0.72)
	for z_index in range(2):
		parent.add_child(_box("PortalContinuationFloor_%02d" % z_index, Vector3(0, -0.045, -0.5 - float(z_index)), Vector3(corridor_width, 0.09, 0.98), _floor_b if z_index % 2 == 0 else _floor_a, 0.008))
	for side in [-1.0, 1.0]:
		parent.add_child(_box("PortalContinuationReveal_%s" % ("Left" if side < 0.0 else "Right"), Vector3(float(side) * corridor_width * 0.5, 1.6, -1.0), Vector3(0.08, 3.2, 2.0), _stone_dark, 0.01))
	parent.add_child(_box("PortalContinuationBack", Vector3(0, 1.6, -2.04), Vector3(corridor_width, 3.2, 0.08), _canvas, 0.01))
	parent.add_child(_box("PortalDestinationLight", Vector3(0, 2.0, -1.985), Vector3(corridor_width * 0.54, 1.62, 0.025), _stone, 0.008))
	parent.add_child(_box("PortalDestinationDatum", Vector3(0, 1.12, -1.965), Vector3(corridor_width * 0.42, 0.035, 0.012), _bronze, 0.003))
	parent.add_child(_box("PortalWayfinding", Vector3(0, 2.55, -1.99), Vector3(minf(0.72, corridor_width * 0.62), 0.18, 0.025), _green_emissive, 0.005))
	parent.set_meta("corridor_continuation_m", 2.0)


func _build_service_role_context(parent: Node3D) -> void:
	var side := -1.0 if not flip else 1.0
	var x := side * (float(width_cells) * 0.5 + 0.72)
	parent.add_child(_box("MaintenanceCaseLower", Vector3(x, 0.24, 3.3), Vector3(0.72, 0.48, 0.54), _stone_dark, 0.025))
	parent.add_child(_box("MaintenanceCaseUpper", Vector3(x + side * 0.12, 0.68, 3.32), Vector3(0.48, 0.38, 0.48), _dark, 0.02))
	parent.add_child(_box("MaintenanceCaseLatch", Vector3(x - side * 0.37, 0.24, 3.3), Vector3(0.025, 0.12, 0.18), _bronze, 0.005))
	parent.set_meta("maintenance_props_outside_hero_span", true)


func _build_endcap_turn_context(parent: Node3D) -> void:
	var terminal_x := _terminal_side * float(width_cells) * 0.5
	parent.add_child(_box("TerminalRouteTrace", Vector3(terminal_x, 0.028, 2.3), Vector3(0.035, 0.022, 4.55), _bronze, 0.005))
	parent.add_child(_box("TerminalRouteTurn", Vector3(_terminal_side * 2.55, 0.028, 4.55), Vector3(3.1, 0.022, 0.035), _bronze_dark, 0.005))
	parent.add_child(_box("TerminalOpenThreshold", Vector3(_terminal_side * 1.75, 0.022, 0.52), Vector3(1.3, 0.018, 0.035), _warm_emissive, 0.004))
	parent.add_child(_cylinder("TerminalCornerGuard", Vector3(terminal_x + _terminal_side * 0.22, 0.46, 0.48), 0.055, 0.92, _bronze, 16))
	parent.add_child(_box("TerminalCornerGuardFoot", Vector3(terminal_x + _terminal_side * 0.22, 0.055, 0.48), Vector3(0.22, 0.11, 0.22), _stone_dark, 0.012))
	parent.set_meta("declared_terminal_side", "right" if _terminal_side > 0.0 else "left")


func _build_solid_role_context(parent: Node3D) -> void:
	var x := _utility_bay_x
	parent.add_child(_box("ConservationSensorHousing", Vector3(x, 2.72, 0.31), Vector3(0.14, 0.22, 0.08), _dark, 0.01))
	parent.add_child(_sphere("ConservationSensorLens", Vector3(x, 2.72, 0.365), 0.027, _warm_emissive))


func _build_light_and_reflection_cues(parent: Node3D) -> void:
	var rig := Node3D.new()
	rig.name = "BoundedMuseumLightAndReflectionRig"
	rig.set_meta("static_light_count", 2)
	rig.set_meta("reflection_update", "once")
	parent.add_child(rig)
	var ceiling_y := height + 0.06

	var key := SpotLight3D.new()
	key.name = "WarmWallWash"
	key.position = Vector3(-float(width_cells) * 0.5 - 0.8, ceiling_y, 2.15)
	key.light_color = Color(1.0, 0.79, 0.6)
	key.light_energy = 2.6
	key.spot_range = 7.2
	key.spot_angle = 42.0
	key.shadow_enabled = true
	key.shadow_bias = 0.045
	rig.add_child(key)
	key.look_at(Vector3(0, height * 0.52, 0.08), Vector3.UP)
	_context_lights += 1

	var fill := SpotLight3D.new()
	fill.name = "CoolCirculationFill"
	fill.position = Vector3(float(_room_width_cells) * 0.34, ceiling_y - 0.15, 4.8)
	fill.light_color = Color(0.56, 0.69, 0.9)
	fill.light_energy = 1.05
	fill.spot_range = 8.5
	fill.spot_angle = 49.0
	fill.shadow_enabled = false
	rig.add_child(fill)
	fill.look_at(Vector3(0, 0.7, 2.4), Vector3.UP)
	_context_lights += 1

	var probe := ReflectionProbe.new()
	probe.name = "OccupiedBayReflectionProbe"
	probe.position = Vector3(0, height * 0.5, float(ROOM_DEPTH_CELLS) * 0.48)
	probe.size = Vector3(float(_room_width_cells) - 0.3, height + 0.15, float(ROOM_DEPTH_CELLS) - 0.4)
	probe.origin_offset = Vector3(0, 0, -0.65)
	probe.intensity = 0.62
	probe.max_distance = 14.0
	probe.box_projection = true
	probe.interior = true
	probe.enable_shadows = false
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	rig.add_child(probe)


func _build_shell_collision(parent: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "OccupiedGalleryShellCollision"
	body.set_meta("context_collision", true)
	body.set_meta("physics_profile", "museum_static_architecture")
	parent.add_child(body)
	_add_collision_shape(body, "FloorCollision", Vector3(0, -0.08, float(ROOM_DEPTH_CELLS) * 0.5), Vector3(float(_room_width_cells), 0.12, float(ROOM_DEPTH_CELLS)))
	var sides := [-1.0, 1.0]
	if kind == "endcap":
		sides = [-_terminal_side]
	for side_variant in sides:
		var side := float(side_variant)
		_add_collision_shape(body, "ReturnCollision_%s" % ("Left" if side < 0.0 else "Right"), Vector3(side * (float(_room_width_cells) * 0.5 + 0.08), height * 0.5, 1.8), Vector3(0.16, height, 3.6))


func _add_collision_shape(body: StaticBody3D, node_name: String, at: Vector3, size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.name = node_name
	collision.position = at
	collision.shape = shape
	body.add_child(collision)


func _box(node_name: String, at: Vector3, size: Vector3, material: Material, _bevel: float = 0.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	# ArchitecturalSpans owns the exact-bounds chamfer profile cache. Context use
	# shares those resources rather than creating another bevel implementation.
	instance.mesh = ARCH._box_mesh(size)
	instance.material_override = material
	instance.set_meta("c27_context_geometry", true)
	_context_draw_nodes += 1
	return instance


func _add_multibox(parent: Node3D, node_name: String, transforms: Array[Transform3D], size: Vector3, material: Material) -> void:
	if transforms.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = ARCH._box_mesh(size)
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = material
	instance.set_meta("c27_context_geometry", true)
	parent.add_child(instance)
	_context_draw_nodes += 1
	_context_multimesh_instances += transforms.size()


func _cylinder(node_name: String, at: Vector3, radius: float, cylinder_height: float, material: Material, segments: int = 16) -> MeshInstance3D:
	var key := "%.4f:%.4f:%d" % [radius, cylinder_height, segments]
	var mesh: CylinderMesh
	if _cylinder_mesh_cache.has(key):
		mesh = _cylinder_mesh_cache[key]
	else:
		mesh = CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = cylinder_height
		mesh.radial_segments = segments
		mesh.rings = 1
		_cylinder_mesh_cache[key] = mesh
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.mesh = mesh
	instance.material_override = material
	instance.set_meta("c27_context_geometry", true)
	_context_draw_nodes += 1
	return instance


func _sphere(node_name: String, at: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var key := "%.4f" % radius
	var mesh: SphereMesh
	if _sphere_mesh_cache.has(key):
		mesh = _sphere_mesh_cache[key]
	else:
		mesh = SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = 20
		mesh.rings = 10
		_sphere_mesh_cache[key] = mesh
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.mesh = mesh
	instance.material_override = material
	instance.set_meta("c27_context_geometry", true)
	_context_draw_nodes += 1
	return instance


static func _shared_material(key: String, color: Color, roughness: float, metallic: float, emission_energy: float = 0.0) -> StandardMaterial3D:
	if _context_material_cache.has(key):
		return _context_material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	_context_material_cache[key] = material
	return material


func _context_material_count() -> int:
	# Four canonical PBR slots are requested above; the eight context roles are
	# globally cached and reused by every C27 family instantiation.
	return mini(12, _context_material_cache.size() + 4)
