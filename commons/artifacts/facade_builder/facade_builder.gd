## FacadeBuilder — Interactive architectural facade composer artifact.
## Combines SpatialComposition zone layout with SurfaceTool geometry
## to build 3D facades from presets (classical, gothic, palazzo, arcade, minimal).
##
## Each preset defines horizontal zones with distinct architectural elements.
## FacadeGrammar integration loads study packs for region-specific detailing.
##
## Config keys:
##   preset          - "classical", "gothic", "palazzo", "arcade", "minimal"
##   bay_count       - number of vertical bay divisions (1-20)
##   story_count     - number of horizontal story divisions (1-10)
##   facade_width    - total width in meters
##   facade_height   - total height in meters
##   study_pack      - FacadeGrammar study pack name (e.g., "italy")
##   symmetry        - 0=None, 1=Bilateral, 2=Axial, 3=Hierarchical
##   primary_color   - hex color string for primary surfaces
##   secondary_color - hex color string for accent/trim surfaces

extends Node3D
class_name FacadeBuilder

const SC := preload("res://commons/composition/spatial_composition.gd")

@export var preset: String = "classical"
@export var bay_count: int = 5
@export var story_count: int = 3
@export var facade_width: float = 15.0
@export var facade_height: float = 10.0
@export var study_pack: String = "italy"
@export_enum("None", "Bilateral", "Axial Rhythm", "Hierarchical")
var symmetry: int = 1
@export var primary_color: Color = Color(0.82, 0.78, 0.70)
@export var secondary_color: Color = Color(0.65, 0.60, 0.52)

# Internal state
var _composition = null
var _facade_grammar: FacadeGrammar = null
var _mesh_instance: MeshInstance3D = null
var _primary_material: StandardMaterial3D = null
var _secondary_material: StandardMaterial3D = null

# Preset definitions: each maps zone_id -> element config
const PRESET_DEFS: Dictionary = {
	"classical": {
		"description": "Columns and pediment, classical order proportions",
		"zones": [
			{"id": "base", "height_frac": 0.15, "depth": 0.06, "elements": ["rustication"]},
			{"id": "main", "height_frac": 0.50, "depth": 0.0, "elements": ["columns", "windows_rect"]},
			{"id": "entablature", "height_frac": 0.10, "depth": 0.04, "elements": ["cornice_band"]},
			{"id": "pediment", "height_frac": 0.15, "depth": 0.0, "elements": ["pediment_tri"]},
			{"id": "attic", "height_frac": 0.10, "depth": 0.0, "elements": ["balustrade"]},
		],
	},
	"gothic": {
		"description": "Pointed arches, vertical emphasis, tracery",
		"zones": [
			{"id": "base", "height_frac": 0.10, "depth": 0.04, "elements": ["rustication"]},
			{"id": "arcade", "height_frac": 0.40, "depth": -0.08, "elements": ["pointed_arches"]},
			{"id": "gallery", "height_frac": 0.25, "depth": 0.0, "elements": ["tracery_windows"]},
			{"id": "clerestory", "height_frac": 0.15, "depth": 0.02, "elements": ["rose_window"]},
			{"id": "parapet", "height_frac": 0.10, "depth": 0.0, "elements": ["crenellation"]},
		],
	},
	"palazzo": {
		"description": "Rusticated base, piano nobile, classical Italian palazzo",
		"zones": [
			{"id": "plinth", "height_frac": 0.05, "depth": 0.08, "elements": ["plinth_band"]},
			{"id": "base", "height_frac": 0.25, "depth": 0.05, "elements": ["rustication", "small_windows"]},
			{"id": "piano_nobile", "height_frac": 0.35, "depth": 0.0, "elements": ["arched_windows", "pilasters"]},
			{"id": "upper", "height_frac": 0.25, "depth": 0.0, "elements": ["windows_rect"]},
			{"id": "cornice", "height_frac": 0.10, "depth": 0.06, "elements": ["heavy_cornice"]},
		],
	},
	"arcade": {
		"description": "Repeated arches, open colonnade or loggia",
		"zones": [
			{"id": "plinth", "height_frac": 0.08, "depth": 0.04, "elements": ["plinth_band"]},
			{"id": "arcade_lower", "height_frac": 0.42, "depth": -0.10, "elements": ["round_arches", "columns"]},
			{"id": "string_course", "height_frac": 0.05, "depth": 0.03, "elements": ["string_band"]},
			{"id": "arcade_upper", "height_frac": 0.35, "depth": -0.06, "elements": ["round_arches", "columns"]},
			{"id": "balustrade", "height_frac": 0.10, "depth": 0.0, "elements": ["balustrade"]},
		],
	},
	"minimal": {
		"description": "Clean modern facade, flat planes, minimal ornamentation",
		"zones": [
			{"id": "ground", "height_frac": 0.30, "depth": 0.0, "elements": ["glass_panels"]},
			{"id": "upper", "height_frac": 0.55, "depth": 0.0, "elements": ["grid_windows"]},
			{"id": "parapet", "height_frac": 0.15, "depth": 0.02, "elements": ["flat_cap"]},
		],
	},
}


func _ready() -> void:
	build_facade()


func apply_grid_config(config_data: Dictionary) -> void:
	print("FacadeBuilder: Applying config: %s" % str(config_data))

	if config_data.has("preset"):
		preset = str(config_data["preset"])
	if config_data.has("bay_count"):
		bay_count = clampi(int(config_data["bay_count"]), 1, 20)
	if config_data.has("story_count"):
		story_count = clampi(int(config_data["story_count"]), 1, 10)
	if config_data.has("facade_width"):
		facade_width = clampf(float(config_data["facade_width"]), 2.0, 100.0)
	if config_data.has("facade_height"):
		facade_height = clampf(float(config_data["facade_height"]), 2.0, 60.0)
	if config_data.has("study_pack"):
		study_pack = str(config_data["study_pack"])
	if config_data.has("symmetry"):
		var sym_val = config_data["symmetry"]
		if sym_val is int or sym_val is float:
			symmetry = clampi(int(sym_val), 0, 3)
		else:
			var sym_str := str(sym_val).to_lower()
			match sym_str:
				"none": symmetry = 0
				"bilateral": symmetry = 1
				"axial_rhythm", "axial": symmetry = 2
				"hierarchical": symmetry = 3
	if config_data.has("primary_color"):
		var c := str(config_data["primary_color"])
		if c.begins_with("#"):
			primary_color = Color.html(c)
	if config_data.has("secondary_color"):
		var c := str(config_data["secondary_color"])
		if c.begins_with("#"):
			secondary_color = Color.html(c)

	# Rebuild
	_clear_children()
	build_facade()


# ═══════════════════════════════════════════════════════════════════
# MAIN BUILD
# ═══════════════════════════════════════════════════════════════════

func build_facade() -> void:
	_clear_children()
	_setup_materials()

	# Build spatial composition for zone layout
	_composition = _build_composition()

	# Attempt to load FacadeGrammar study pack for element details
	_facade_grammar = FacadeGrammar.new()
	if study_pack != "":
		_facade_grammar.load_study_pack(study_pack)

	# Get preset definition
	var preset_def: Dictionary = PRESET_DEFS.get(preset, PRESET_DEFS["classical"])
	var zone_defs: Array = preset_def.get("zones", [])

	# Build geometry for each zone
	_build_zone_geometry(zone_defs)

	# Add subtle lighting
	_add_facade_lights()

	print("[FacadeBuilder] Built '%s' facade: %d bays x %d stories, %.1f x %.1f m" % [
		preset, bay_count, story_count, facade_width, facade_height
	])


func _build_composition():
	# Create composition sized to bay_count x story_count
	var comp = SC._make(bay_count, story_count)

	var preset_def: Dictionary = PRESET_DEFS.get(preset, PRESET_DEFS["classical"])
	var zone_defs: Array = preset_def.get("zones", [])

	# Map zone defs onto composition regions (horizontal bands)
	var y_cursor: int = 0
	for i in range(zone_defs.size()):
		var zd: Dictionary = zone_defs[i]
		var zone_id: String = zd.get("id", "zone_%d" % i)
		var height_frac: float = zd.get("height_frac", 0.2)
		var zone_rows: int = maxi(1, roundi(float(story_count) * height_frac))

		# Clamp to remaining rows
		if y_cursor + zone_rows > story_count:
			zone_rows = story_count - y_cursor
		if zone_rows <= 0:
			continue

		var region = SC.Region.make_rect(0, y_cursor, bay_count, zone_rows)
		comp.add_zone(zone_id, region, {
			"depth": zd.get("depth", 0.0),
			"elements": zd.get("elements", []),
			"zone_index": i,
		}, i + 1)

		y_cursor += zone_rows

	# Apply bilateral symmetry modifier if requested
	if symmetry == 1:
		comp.add_modifier("mirror_x")

	return comp


# ═══════════════════════════════════════════════════════════════════
# GEOMETRY BUILDING
# ═══════════════════════════════════════════════════════════════════

func _build_zone_geometry(zone_defs: Array) -> void:
	var bay_width: float = facade_width / float(bay_count)

	# Calculate zone vertical extents
	var zone_extents: Array = _compute_zone_extents(zone_defs)

	for zi in range(zone_defs.size()):
		if zi >= zone_extents.size():
			break
		var zd: Dictionary = zone_defs[zi]
		var zone_id: String = zd.get("id", "zone_%d" % zi)
		var z_bottom: float = zone_extents[zi][0]
		var z_top: float = zone_extents[zi][1]
		var z_height: float = z_top - z_bottom
		var depth_offset: float = zd.get("depth", 0.0)
		var elements: Array = zd.get("elements", [])

		# Build wall plane for the zone
		_add_zone_wall(zone_id, z_bottom, z_top, depth_offset, zi)

		# Build elements within bays
		for bay_idx in range(bay_count):
			var bay_left: float = float(bay_idx) * bay_width - facade_width / 2.0
			var bay_right: float = bay_left + bay_width
			var bay_center_x: float = (bay_left + bay_right) / 2.0

			for element_name in elements:
				_build_element(str(element_name), bay_center_x, bay_width, z_bottom, z_top, z_height, depth_offset, bay_idx, zi)


func _compute_zone_extents(zone_defs: Array) -> Array:
	# Normalize height fractions and compute world-space extents (bottom-up)
	var total_frac: float = 0.0
	for zd in zone_defs:
		total_frac += zd.get("height_frac", 0.2)

	var extents: Array = []
	var y_cursor: float = 0.0
	for zd in zone_defs:
		var frac: float = zd.get("height_frac", 0.2) / total_frac
		var zone_h: float = frac * facade_height
		extents.append([y_cursor, y_cursor + zone_h])
		y_cursor += zone_h

	return extents


func _add_zone_wall(zone_id: String, bottom: float, top: float, depth: float, zone_idx: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_w: float = facade_width / 2.0
	var z_pos: float = depth

	# Use secondary color for base/plinth zones, primary for the rest
	var color: Color = secondary_color if zone_id in ["base", "plinth", "ground"] else primary_color
	st.set_color(color)
	st.set_normal(Vector3(0, 0, 1))

	# Quad: two triangles
	st.set_uv(Vector2(0, 0))
	st.add_vertex(Vector3(-half_w, bottom, z_pos))
	st.set_uv(Vector2(1, 0))
	st.add_vertex(Vector3(half_w, bottom, z_pos))
	st.set_uv(Vector2(1, 1))
	st.add_vertex(Vector3(half_w, top, z_pos))

	st.set_uv(Vector2(0, 0))
	st.add_vertex(Vector3(-half_w, bottom, z_pos))
	st.set_uv(Vector2(1, 1))
	st.add_vertex(Vector3(half_w, top, z_pos))
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(-half_w, top, z_pos))

	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "Wall_%s" % zone_id

	# Apply material based on zone type
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat

	add_child(mi)


func _build_element(element_name: String, cx: float, bay_w: float, z_bottom: float, z_top: float, z_height: float, depth: float, bay_idx: int, zone_idx: int) -> void:
	match element_name:
		"columns", "pilasters":
			_build_column(cx - bay_w * 0.45, z_bottom, z_top, depth, bay_idx, zone_idx)
			if bay_idx == bay_count - 1:
				_build_column(cx + bay_w * 0.45, z_bottom, z_top, depth, bay_idx, zone_idx)
		"rustication":
			_build_rustication(cx, bay_w, z_bottom, z_top, depth, bay_idx, zone_idx)
		"windows_rect", "small_windows", "grid_windows":
			_build_window_rect(cx, bay_w * 0.5, z_bottom + z_height * 0.25, z_height * 0.5, depth, bay_idx, zone_idx)
		"arched_windows":
			_build_arched_opening(cx, bay_w * 0.45, z_bottom + z_height * 0.1, z_height * 0.8, depth, bay_idx, zone_idx, false)
		"pointed_arches":
			_build_pointed_arch(cx, bay_w * 0.45, z_bottom, z_top, depth, bay_idx, zone_idx)
		"round_arches":
			_build_arched_opening(cx, bay_w * 0.40, z_bottom, z_top - z_bottom, depth, bay_idx, zone_idx, true)
		"cornice_band", "string_band", "heavy_cornice":
			_build_horizontal_band(cx, bay_w, z_bottom, z_top, depth, bay_idx, zone_idx)
		"pediment_tri":
			_build_pediment(z_bottom, z_top, depth)
		"balustrade", "crenellation":
			_build_balustrade(cx, bay_w, z_bottom, z_top, depth, bay_idx, zone_idx)
		"tracery_windows":
			_build_tracery_window(cx, bay_w * 0.45, z_bottom + z_height * 0.1, z_height * 0.8, depth, bay_idx, zone_idx)
		"rose_window":
			if bay_idx == bay_count / 2:
				_build_rose_window(cx, z_bottom + z_height * 0.5, z_height * 0.4, depth, zone_idx)
		"glass_panels":
			_build_glass_panel(cx, bay_w * 0.8, z_bottom + z_height * 0.05, z_height * 0.9, depth, bay_idx, zone_idx)
		"plinth_band":
			_build_horizontal_band(cx, bay_w, z_bottom, z_top, depth, bay_idx, zone_idx)
		"flat_cap":
			_build_horizontal_band(cx, bay_w, z_bottom, z_top, depth + 0.02, bay_idx, zone_idx)


# ═══════════════════════════════════════════════════════════════════
# ELEMENT BUILDERS — SurfaceTool geometry
# ═══════════════════════════════════════════════════════════════════

func _build_column(x: float, bottom: float, top: float, depth: float, bay_idx: int, zone_idx: int) -> void:
	var radius: float = facade_width / float(bay_count) * 0.04
	var segments: int = 8
	var col_depth: float = depth + radius * 2.0

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(secondary_color)

	# Column shaft as a cylinder approximation
	for i in range(segments):
		var angle0: float = float(i) / float(segments) * TAU
		var angle1: float = float(i + 1) / float(segments) * TAU
		var x0: float = x + cos(angle0) * radius
		var z0: float = col_depth + sin(angle0) * radius
		var x1: float = x + cos(angle1) * radius
		var z1: float = col_depth + sin(angle1) * radius
		var n0 := Vector3(cos(angle0), 0, sin(angle0))
		var n1 := Vector3(cos(angle1), 0, sin(angle1))

		# Two triangles per segment
		st.set_normal(n0)
		st.add_vertex(Vector3(x0, bottom, z0))
		st.set_normal(n1)
		st.add_vertex(Vector3(x1, bottom, z1))
		st.set_normal(n1)
		st.add_vertex(Vector3(x1, top, z1))

		st.set_normal(n0)
		st.add_vertex(Vector3(x0, bottom, z0))
		st.set_normal(n1)
		st.add_vertex(Vector3(x1, top, z1))
		st.set_normal(n0)
		st.add_vertex(Vector3(x0, top, z0))

	# Capital — wider disc at top
	var cap_h: float = (top - bottom) * 0.04
	var cap_r: float = radius * 1.6
	for i in range(segments):
		var angle0: float = float(i) / float(segments) * TAU
		var angle1: float = float(i + 1) / float(segments) * TAU
		st.set_normal(Vector3(0, 1, 0))
		st.add_vertex(Vector3(x, top + cap_h, col_depth))
		st.add_vertex(Vector3(x + cos(angle1) * cap_r, top, col_depth + sin(angle1) * cap_r))
		st.add_vertex(Vector3(x + cos(angle0) * cap_r, top, col_depth + sin(angle0) * cap_r))

	# Base — wider disc at bottom
	var base_h: float = (top - bottom) * 0.03
	for i in range(segments):
		var angle0: float = float(i) / float(segments) * TAU
		var angle1: float = float(i + 1) / float(segments) * TAU
		st.set_normal(Vector3(0, -1, 0))
		st.add_vertex(Vector3(x, bottom - base_h * 0.5, col_depth))
		st.add_vertex(Vector3(x + cos(angle0) * cap_r, bottom, col_depth + sin(angle0) * cap_r))
		st.add_vertex(Vector3(x + cos(angle1) * cap_r, bottom, col_depth + sin(angle1) * cap_r))

	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "Col_%d_%d" % [zone_idx, bay_idx]
	mi.material_override = _secondary_material
	add_child(mi)


func _build_rustication(cx: float, bay_w: float, bottom: float, top: float, depth: float, bay_idx: int, zone_idx: int) -> void:
	# Horizontal groove lines to simulate rusticated stonework
	var groove_count: int = clampi(int((top - bottom) / 0.3), 2, 12)
	var groove_h: float = 0.02
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(secondary_color.darkened(0.2))

	var left: float = cx - bay_w * 0.5
	var right: float = cx + bay_w * 0.5

	for gi in range(groove_count):
		var gy: float = bottom + float(gi + 1) / float(groove_count + 1) * (top - bottom)
		var gz: float = depth + 0.07  # Slightly proud of wall

		# Groove strip
		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(Vector3(left, gy - groove_h, gz))
		st.add_vertex(Vector3(right, gy - groove_h, gz))
		st.add_vertex(Vector3(right, gy + groove_h, gz))

		st.add_vertex(Vector3(left, gy - groove_h, gz))
		st.add_vertex(Vector3(right, gy + groove_h, gz))
		st.add_vertex(Vector3(left, gy + groove_h, gz))

	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "Rust_%d_%d" % [zone_idx, bay_idx]
	add_child(mi)


func _build_window_rect(cx: float, win_w: float, win_bottom: float, win_h: float, depth: float, bay_idx: int, zone_idx: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var left: float = cx - win_w * 0.5
	var right: float = cx + win_w * 0.5
	var top: float = win_bottom + win_h
	var z_pos: float = depth - 0.04  # Recessed

	# Dark glass pane
	st.set_color(Color(0.1, 0.12, 0.18, 0.9))
	st.set_normal(Vector3(0, 0, 1))
	st.add_vertex(Vector3(left, win_bottom, z_pos))
	st.add_vertex(Vector3(right, win_bottom, z_pos))
	st.add_vertex(Vector3(right, top, z_pos))

	st.add_vertex(Vector3(left, win_bottom, z_pos))
	st.add_vertex(Vector3(right, top, z_pos))
	st.add_vertex(Vector3(left, top, z_pos))

	# Frame (surround)
	var frame_w: float = 0.04
	var fz: float = depth + 0.02
	st.set_color(secondary_color)

	# Top frame
	_add_quad_to_st(st, left - frame_w, top, right + frame_w, top + frame_w, fz)
	# Bottom frame (sill)
	_add_quad_to_st(st, left - frame_w, win_bottom - frame_w, right + frame_w, win_bottom, fz)
	# Left frame
	_add_quad_to_st(st, left - frame_w, win_bottom, left, top, fz)
	# Right frame
	_add_quad_to_st(st, right, win_bottom, right + frame_w, top, fz)

	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "Win_%d_%d" % [zone_idx, bay_idx]
	add_child(mi)


func _build_arched_opening(cx: float, arch_w: float, bottom: float, height: float, depth: float, bay_idx: int, zone_idx: int, full_arch: bool) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var spring_line: float = bottom + height * 0.55
	var arch_top: float = bottom + height
	var left: float = cx - arch_w * 0.5
	var right: float = cx + arch_w * 0.5
	var z_pos: float = depth - 0.05
	var arch_radius: float = arch_w * 0.5

	# Rectangular lower portion
	st.set_color(Color(0.08, 0.1, 0.15, 0.85))
	st.set_normal(Vector3(0, 0, 1))
	st.add_vertex(Vector3(left, bottom, z_pos))
	st.add_vertex(Vector3(right, bottom, z_pos))
	st.add_vertex(Vector3(right, spring_line, z_pos))

	st.add_vertex(Vector3(left, bottom, z_pos))
	st.add_vertex(Vector3(right, spring_line, z_pos))
	st.add_vertex(Vector3(left, spring_line, z_pos))

	# Semicircular arch portion (fan triangles)
	var arch_segments: int = 12
	var arch_center := Vector3(cx, spring_line, z_pos)
	for i in range(arch_segments):
		var a0: float = float(i) / float(arch_segments) * PI
		var a1: float = float(i + 1) / float(arch_segments) * PI
		var p0 := arch_center + Vector3(cos(PI - a0) * arch_radius, sin(a0) * arch_radius, 0)
		var p1 := arch_center + Vector3(cos(PI - a1) * arch_radius, sin(a1) * arch_radius, 0)
		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(arch_center)
		st.add_vertex(p0)
		st.add_vertex(p1)

	# Archivolt (arch frame ring)
	var frame_thick: float = 0.05
	var fz: float = depth + 0.02
	st.set_color(secondary_color)
	for i in range(arch_segments):
		var a0: float = float(i) / float(arch_segments) * PI
		var a1: float = float(i + 1) / float(arch_segments) * PI
		var inner0 := arch_center + Vector3(cos(PI - a0) * arch_radius, sin(a0) * arch_radius, fz - z_pos)
		var inner1 := arch_center + Vector3(cos(PI - a1) * arch_radius, sin(a1) * arch_radius, fz - z_pos)
		var outer0 := arch_center + Vector3(cos(PI - a0) * (arch_radius + frame_thick), sin(a0) * (arch_radius + frame_thick), fz - z_pos)
		var outer1 := arch_center + Vector3(cos(PI - a1) * (arch_radius + frame_thick), sin(a1) * (arch_radius + frame_thick), fz - z_pos)

		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(inner0)
		st.add_vertex(inner1)
		st.add_vertex(outer1)

		st.add_vertex(inner0)
		st.add_vertex(outer1)
		st.add_vertex(outer0)

	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "Arch_%d_%d" % [zone_idx, bay_idx]
	add_child(mi)


func _build_pointed_arch(cx: float, arch_w: float, bottom: float, top: float, depth: float, bay_idx: int, zone_idx: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var height: float = top - bottom
	var spring_line: float = bottom + height * 0.4
	var left: float = cx - arch_w * 0.5
	var right: float = cx + arch_w * 0.5
	var z_pos: float = depth - 0.05
	var radius: float = arch_w * 0.8  # Larger than half-width for pointed effect

	# Lower rectangle
	st.set_color(Color(0.08, 0.1, 0.15, 0.85))
	st.set_normal(Vector3(0, 0, 1))
	st.add_vertex(Vector3(left, bottom, z_pos))
	st.add_vertex(Vector3(right, bottom, z_pos))
	st.add_vertex(Vector3(right, spring_line, z_pos))

	st.add_vertex(Vector3(left, bottom, z_pos))
	st.add_vertex(Vector3(right, spring_line, z_pos))
	st.add_vertex(Vector3(left, spring_line, z_pos))

	# Pointed arch: two arcs meeting at apex
	var segments: int = 8
	var apex := Vector3(cx, top, z_pos)
	# Left arc center at right side of opening, right arc center at left side
	var left_center := Vector3(right, spring_line, z_pos)
	var right_center := Vector3(left, spring_line, z_pos)

	# Build pointed arch as fan from apex and springers
	var prev_left := Vector3(left, spring_line, z_pos)
	var prev_right := Vector3(right, spring_line, z_pos)
	for i in range(1, segments + 1):
		var t: float = float(i) / float(segments)
		# Left side: interpolate from left springer to apex
		var pl := prev_left.lerp(apex, t)
		pl.x = left + (cx - left) * t  # Curve inward
		pl.y = spring_line + (top - spring_line) * sin(t * PI * 0.5)
		# Right side: mirror
		var pr := Vector3(cx + (cx - pl.x), pl.y, z_pos)

		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(prev_left)
		st.add_vertex(prev_right)
		st.add_vertex(pr)

		st.add_vertex(prev_left)
		st.add_vertex(pr)
		st.add_vertex(pl)

		prev_left = pl
		prev_right = pr

	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "PArch_%d_%d" % [zone_idx, bay_idx]
	add_child(mi)


func _build_horizontal_band(cx: float, bay_w: float, bottom: float, top: float, depth: float, bay_idx: int, zone_idx: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var left: float = cx - bay_w * 0.5
	var right: float = cx + bay_w * 0.5
	var z_pos: float = depth + 0.03

	st.set_color(secondary_color)
	st.set_normal(Vector3(0, 0, 1))
	st.add_vertex(Vector3(left, bottom, z_pos))
	st.add_vertex(Vector3(right, bottom, z_pos))
	st.add_vertex(Vector3(right, top, z_pos))

	st.add_vertex(Vector3(left, bottom, z_pos))
	st.add_vertex(Vector3(right, top, z_pos))
	st.add_vertex(Vector3(left, top, z_pos))

	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "Band_%d_%d" % [zone_idx, bay_idx]
	mi.material_override = _secondary_material
	add_child(mi)


func _build_pediment(bottom: float, top: float, depth: float) -> void:
	# Single triangular pediment spanning full width (only built once)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_w: float = facade_width / 2.0
	var z_pos: float = depth + 0.04
	var apex_y: float = top

	st.set_color(secondary_color)
	st.set_normal(Vector3(0, 0, 1))
	st.add_vertex(Vector3(-half_w, bottom, z_pos))
	st.add_vertex(Vector3(half_w, bottom, z_pos))
	st.add_vertex(Vector3(0.0, apex_y, z_pos))

	# Tympanum fill (slightly recessed)
	st.set_color(primary_color.lightened(0.1))
	var inset: float = 0.15
	st.add_vertex(Vector3(-half_w + inset, bottom + 0.03, z_pos - 0.02))
	st.add_vertex(Vector3(half_w - inset, bottom + 0.03, z_pos - 0.02))
	st.add_vertex(Vector3(0.0, apex_y - inset, z_pos - 0.02))

	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "Pediment"
	add_child(mi)


func _build_balustrade(cx: float, bay_w: float, bottom: float, top: float, depth: float, bay_idx: int, zone_idx: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var left: float = cx - bay_w * 0.5
	var right: float = cx + bay_w * 0.5
	var rail_h: float = 0.04
	var z_pos: float = depth + 0.03

	# Top rail
	st.set_color(secondary_color)
	st.set_normal(Vector3(0, 0, 1))
	_add_quad_to_st(st, left, top - rail_h, right, top, z_pos)

	# Bottom rail
	_add_quad_to_st(st, left, bottom, right, bottom + rail_h, z_pos)

	# Balusters (small verticals)
	var baluster_count: int = clampi(int(bay_w / 0.15), 2, 20)
	var baluster_w: float = 0.02
	for bi in range(baluster_count):
		var bx: float = left + float(bi + 1) / float(baluster_count + 1) * bay_w
		_add_quad_to_st(st, bx - baluster_w, bottom + rail_h, bx + baluster_w, top - rail_h, z_pos + 0.01)

	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "Balust_%d_%d" % [zone_idx, bay_idx]
	mi.material_override = _secondary_material
	add_child(mi)


func _build_tracery_window(cx: float, win_w: float, bottom: float, win_h: float, depth: float, bay_idx: int, zone_idx: int) -> void:
	# Simplified lancet window with mullion
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_w: float = win_w * 0.5
	var top: float = bottom + win_h
	var z_pos: float = depth - 0.04

	# Glass pane
	st.set_color(Color(0.15, 0.2, 0.4, 0.8))
	st.set_normal(Vector3(0, 0, 1))
	_add_quad_to_st(st, cx - half_w, bottom, cx + half_w, top - win_h * 0.2, z_pos)

	# Pointed top (simplified)
	st.add_vertex(Vector3(cx - half_w, top - win_h * 0.2, z_pos))
	st.add_vertex(Vector3(cx + half_w, top - win_h * 0.2, z_pos))
	st.add_vertex(Vector3(cx, top, z_pos))

	# Central mullion
	var mullion_w: float = 0.02
	var fz: float = depth + 0.01
	st.set_color(secondary_color)
	_add_quad_to_st(st, cx - mullion_w, bottom, cx + mullion_w, top - win_h * 0.1, fz)

	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "Tracery_%d_%d" % [zone_idx, bay_idx]
	add_child(mi)


func _build_rose_window(cx: float, cy: float, radius: float, depth: float, zone_idx: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var z_pos: float = depth - 0.04
	var segments: int = 16

	# Circular glass pane
	st.set_color(Color(0.3, 0.15, 0.5, 0.7))
	for i in range(segments):
		var a0: float = float(i) / float(segments) * TAU
		var a1: float = float(i + 1) / float(segments) * TAU
		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(Vector3(cx, cy, z_pos))
		st.add_vertex(Vector3(cx + cos(a0) * radius, cy + sin(a0) * radius, z_pos))
		st.add_vertex(Vector3(cx + cos(a1) * radius, cy + sin(a1) * radius, z_pos))

	# Stone tracery spokes
	var spoke_w: float = 0.025
	var fz: float = depth + 0.01
	st.set_color(secondary_color)
	for i in range(8):
		var angle: float = float(i) / 8.0 * TAU
		var dx := cos(angle)
		var dy := sin(angle)
		var perp_x := -dy * spoke_w
		var perp_y := dx * spoke_w
		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(Vector3(cx + perp_x, cy + perp_y, fz))
		st.add_vertex(Vector3(cx - perp_x, cy - perp_y, fz))
		st.add_vertex(Vector3(cx + dx * radius + perp_x, cy + dy * radius + perp_y, fz))

		st.add_vertex(Vector3(cx - perp_x, cy - perp_y, fz))
		st.add_vertex(Vector3(cx + dx * radius - perp_x, cy + dy * radius - perp_y, fz))
		st.add_vertex(Vector3(cx + dx * radius + perp_x, cy + dy * radius + perp_y, fz))

	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "Rose_%d" % zone_idx
	add_child(mi)


func _build_glass_panel(cx: float, panel_w: float, bottom: float, panel_h: float, depth: float, bay_idx: int, zone_idx: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var left: float = cx - panel_w * 0.5
	var right: float = cx + panel_w * 0.5
	var top: float = bottom + panel_h
	var z_pos: float = depth - 0.02

	# Glass pane
	st.set_color(Color(0.2, 0.25, 0.35, 0.6))
	st.set_normal(Vector3(0, 0, 1))
	_add_quad_to_st(st, left, bottom, right, top, z_pos)

	# Thin frame
	var frame_w: float = 0.02
	var fz: float = depth + 0.01
	st.set_color(Color(0.3, 0.3, 0.3))
	_add_quad_to_st(st, left - frame_w, bottom - frame_w, right + frame_w, bottom, fz)
	_add_quad_to_st(st, left - frame_w, top, right + frame_w, top + frame_w, fz)
	_add_quad_to_st(st, left - frame_w, bottom, left, top, fz)
	_add_quad_to_st(st, right, bottom, right + frame_w, top, fz)

	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "Glass_%d_%d" % [zone_idx, bay_idx]
	add_child(mi)


# ═══════════════════════════════════════════════════════════════════
# UTILITY
# ═══════════════════════════════════════════════════════════════════

func _add_quad_to_st(st: SurfaceTool, left: float, bottom: float, right: float, top: float, z: float) -> void:
	st.set_normal(Vector3(0, 0, 1))
	st.add_vertex(Vector3(left, bottom, z))
	st.add_vertex(Vector3(right, bottom, z))
	st.add_vertex(Vector3(right, top, z))

	st.add_vertex(Vector3(left, bottom, z))
	st.add_vertex(Vector3(right, top, z))
	st.add_vertex(Vector3(left, top, z))


func _setup_materials() -> void:
	_primary_material = StandardMaterial3D.new()
	_primary_material.albedo_color = primary_color
	_primary_material.roughness = 0.8
	_primary_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	_secondary_material = StandardMaterial3D.new()
	_secondary_material.albedo_color = secondary_color
	_secondary_material.roughness = 0.85
	_secondary_material.cull_mode = BaseMaterial3D.CULL_DISABLED


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()


func _add_facade_lights() -> void:
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, facade_height * 0.6, facade_width * 0.4)
	light.light_energy = 3.0
	light.omni_range = facade_width * 1.2
	light.light_color = Color(0.98, 0.95, 0.88)
	light.shadow_enabled = false
	light.name = "FacadeLight"
	add_child(light)
