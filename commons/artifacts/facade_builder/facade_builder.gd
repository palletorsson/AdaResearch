## FacadeBuilder — Interactive architectural facade composer artifact.
## Builds 3D facades from v2 plan JSON or from preset-based zone/element config.
## Uses FacadeComposer (part-based system) when a plan file is available,
## falls back to built-in SurfaceTool geometry for preset-based builds.
##
## Config keys:
##   preset          - "classical", "gothic", "palazzo", "arcade", "minimal"
##   plan_path       - path to v2 facade plan JSON (overrides preset if set)
##   bay_count       - number of vertical bay divisions (1-20)
##   story_count     - number of horizontal story divisions (1-10)
##   facade_width    - total width in meters
##   facade_height   - total height in meters
##   symmetry        - 0=None, 1=Bilateral, 2=Axial, 3=Hierarchical
##   primary_color   - hex color string for primary surfaces
##   secondary_color - hex color string for accent/trim surfaces

extends Node3D
class_name FacadeBuilder

# @identity
# essence: Preset-driven or plan-driven facade composer — zones, bays, symmetry, and classical orders as architectural grammar
# desire: To let players compose their own facades from learned vocabulary: base, columns, openings, cornice, crown
# critical_parameter: preset — which architectural grammar (classical, gothic, palazzo, arcade, minimal) governs zone proportions
# triggers: Switching presets transforms the entire facade; changing bay_count alters rhythm; symmetry mode reshapes hierarchy
# emerges: Complete architectural facades from zone-based grammar rules
# needs: apply_grid_config [has], plan JSON support [has], FacadeComposer integration [has], VR interaction [missing]
# relationships: Synthesis artifact for facades sequence alongside facade_grammar_demo. Uses FacadeComposer part library.
# truth: Every facade is a sentence in an architectural grammar — the preset is the dialect, the parameters are the words.

const SC := preload("res://commons/composition/spatial_composition.gd")
const FacadeComposerScript := preload("res://commons/facade_parts/facade_composer.gd")

@export var preset: String = "classical"
@export var plan_path: String = ""
@export var bay_count: int = 5
@export var story_count: int = 3
@export var facade_width: float = 15.0
@export var facade_height: float = 10.0
@export_enum("None", "Bilateral", "Axial Rhythm", "Hierarchical")
var symmetry: int = 1
@export var primary_color: Color = Color(0.82, 0.78, 0.70)
@export var secondary_color: Color = Color(0.65, 0.60, 0.52)

# ── DNA ───────────────────────────────────────────────────────────────
## AXIS — WHAT OF THE MAKING IS STILL STANDING on the finished face. This artifact is a
## composer: it reads a plan of bays and stories and snaps parts into it, and then hands
## back an elevation that has swallowed every trace of the rule it obeyed. A facade that
## hides its setting-out claims to have been FOUND; one that shows it admits to having been
## SET OUT, by someone, to a measure. Both are arguments, and the second is the one this
## sequence is actually teaching.
##
##   none      the legacy lineage, byte for byte — the elevation alone, no apparatus
##   datum     the setting-out lines left on the face: a batten on every story line and
##             every bay line, the drawing's construction grid built instead of erased
##   scaffold  the working platform still up — standards, ledgers, board decks and toe
##             boards across the whole face, the building caught mid-sentence
##   gantry    the lifting frame: two towers past the ends, a beam over the parapet and a
##             cradle hanging off it — the machinery that PUT the parts there, not the
##             surface they landed on
##
## Appearance only, and the last thing built in either path (plan-composed or preset
## geometry), so bays, zones, parts, colours and the facade light are untouched.
@export_enum("none", "datum", "scaffold", "gantry") var armature: String = "none"
const ARMATURES: PackedStringArray = ["none", "datum", "scaffold", "gantry"]

# Internal state
var _composition = null
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
	if config_data.has("plan_path"):
		plan_path = str(config_data["plan_path"])
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
	if config_data.has("armature"):
		var arm_tok: String = str(config_data["armature"]).strip_edges().to_lower()
		armature = arm_tok if ARMATURES.has(arm_tok) else armature

	# Rebuild
	_clear_children()
	build_facade()


# ═══════════════════════════════════════════════════════════════════
# MAIN BUILD
# ═══════════════════════════════════════════════════════════════════

func build_facade() -> void:
	_clear_children()

	# If a plan_path is set, try the new FacadeComposer system first
	if plan_path != "":
		var facade_node := FacadeComposerScript.build_from_file(plan_path)
		if facade_node and facade_node.get_child_count() > 0:
			add_child(facade_node)
			_add_facade_lights()
			_build_armature()
			print("[FacadeBuilder] Built from plan: %s" % plan_path)
			return

	# Also check ada_run/facade_plan.json for web editor sync
	var sync_path := "user://facade_plan.json"
	if FileAccess.file_exists(sync_path):
		var facade_node := FacadeComposerScript.build_from_file(sync_path)
		if facade_node and facade_node.get_child_count() > 0:
			add_child(facade_node)
			_add_facade_lights()
			_build_armature()
			print("[FacadeBuilder] Built from synced plan")
			return

	# Fallback: built-in preset-based geometry
	_setup_materials()
	_composition = _build_composition()

	var preset_def: Dictionary = PRESET_DEFS.get(preset, PRESET_DEFS["classical"])
	var zone_defs: Array = preset_def.get("zones", [])
	_build_zone_geometry(zone_defs)
	_add_facade_lights()
	_build_armature()

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


# ═══════════════════════════════════════════════════════════════════
# ARMATURE — one axis, four answers to "what of the making is still standing"
# ═══════════════════════════════════════════════════════════════════
# Built LAST in both paths (plan-composed and preset geometry) and measured off what is
# already there, so no zone, part, colour or light above it moves. "none" returns before
# anything is added. Nothing here carries a collider: this is a reading of the facade, not
# a change to what the player can walk into.

var _ext_acc: AABB = AABB()
var _ext_have: bool = false


func _build_armature() -> void:
	if armature == "none":
		return
	_ext_acc = AABB()
	_ext_have = false
	_extent_walk(self, Transform3D.IDENTITY)
	if not _ext_have:
		return

	var box: AABB = _ext_acc
	var w: float = maxf(box.size.x, 0.5)
	var h: float = maxf(box.size.y, 0.5)
	var x0: float = box.position.x
	var y0: float = box.position.y
	var zf: float = box.position.z + box.size.z          # the front face
	var facade_def: Dictionary = _plan_facade()
	var bays: int = maxi(int(facade_def.get("bays", bay_count)), 1)
	var stories: int = maxi(int(facade_def.get("stories", story_count)), 1)

	var root := Node3D.new()
	root.name = "Armature"
	add_child(root)

	match armature:
		"datum":
			_armature_datum(root, x0, y0, w, h, zf, bays, stories)
		"scaffold":
			_armature_scaffold(root, x0, y0, w, h, zf, bays, stories)
		"gantry":
			_armature_gantry(root, x0, y0, w, h, zf)
		_:
			pass


## The extent of everything built so far, in THIS node's own space. Walked by hand rather
## than read off global_transform, because build_facade also runs from apply_grid_config
## and a composed plan nests parts several levels deep.
func _extent_walk(node: Node, xform: Transform3D) -> void:
	for child in node.get_children():
		# _clear_children() queue_frees, which does not take effect until the end of the
		# frame, so on a rebuild the OLD armature is still a child while the new one is
		# being sized. Measuring it would make the facade grow a little every config.
		if child.is_queued_for_deletion():
			continue
		var t: Transform3D = xform
		if child is Node3D:
			t = xform * (child as Node3D).transform
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			if mi.mesh != null:
				var b: AABB = t * mi.mesh.get_aabb()
				_ext_acc = b if not _ext_have else _ext_acc.merge(b)
				_ext_have = true
		_extent_walk(child, t)


## bays/stories as the PLAN states them — the preset exports (5 x 3) are not what a
## composed facade was set out on, and a setting-out grid that disagrees with the parts it
## claims to explain would be a drawing of a different building.
func _plan_facade() -> Dictionary:
	var p: String = plan_path
	if p == "" and FileAccess.file_exists("user://facade_plan.json"):
		p = "user://facade_plan.json"
	if p == "" or not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		var plan: Dictionary = parsed
		if plan.get("facade", null) is Dictionary:
			var fd: Dictionary = plan["facade"]
			return fd
	return {}


## DATUM — the setting-out left on the face. A batten on every story line and every bay
## line, dark against pale stone, standing a hand's breadth proud so it casts its own line.
func _armature_datum(root: Node3D, x0: float, y0: float, w: float, h: float, zf: float,
		bays: int, stories: int) -> void:
	var mark := StandardMaterial3D.new()
	mark.albedo_color = Color(0.20, 0.17, 0.15)
	mark.roughness = 0.9
	var t: float = clampf(w * 0.013, 0.06, 0.30)
	var d: float = t * 0.5
	var z: float = zf + d * 0.5 + 0.01
	var cx: float = x0 + w * 0.5
	var cy: float = y0 + h * 0.5

	for i in range(bays + 1):
		var x: float = x0 + w * (float(i) / float(bays))
		root.add_child(_arm_box(Vector3(x, cy, z), Vector3(t, h, d), mark))
	for j in range(stories + 1):
		var y: float = y0 + h * (float(j) / float(stories))
		root.add_child(_arm_box(Vector3(cx, y, z), Vector3(w, t, d), mark))

	# The origin corner gets a cross and a stub, the way a set-out point is marked on site.
	var ink := StandardMaterial3D.new()
	ink.albedo_color = Color(0.78, 0.22, 0.10)
	ink.roughness = 0.8
	var m: float = t * 3.0
	root.add_child(_arm_box(Vector3(x0 + m * 0.5, y0 + t * 0.5, z + d), Vector3(m, t, d), ink))
	root.add_child(_arm_box(Vector3(x0 + t * 0.5, y0 + m * 0.5, z + d), Vector3(t, m, d), ink))


## SCAFFOLD — the working platform still up. Standards on every bay line, ledgers and a
## boarded deck with a toe board at every story line, braces across the end bays. The face
## is legible through it; that is the point of a scaffold.
func _armature_scaffold(root: Node3D, x0: float, y0: float, w: float, h: float, zf: float,
		bays: int, stories: int) -> void:
	var tube := StandardMaterial3D.new()
	tube.albedo_color = Color(0.62, 0.63, 0.66)
	tube.metallic = 0.75
	tube.roughness = 0.35
	var board := StandardMaterial3D.new()
	board.albedo_color = Color(0.56, 0.44, 0.27)
	board.roughness = 0.9

	var stand: float = clampf(w * 0.006, 0.04, 0.12)      # tube diameter
	var reach: float = clampf(h * 0.05, 0.35, 0.9)        # how far the lift stands off
	var deck: float = reach * 0.85
	var toe: float = clampf(h * 0.02, 0.12, 0.3)
	var zc: float = zf + reach * 0.5 + 0.02
	var cx: float = x0 + w * 0.5

	# Standards: one vertical tube on every bay line, plus an outer file at the deck edge.
	for i in range(bays + 1):
		var x: float = x0 + w * (float(i) / float(bays))
		root.add_child(_arm_box(Vector3(x, y0 + h * 0.5, zf + reach), Vector3(stand, h + toe, stand), tube))
		root.add_child(_arm_box(Vector3(x, y0 + h * 0.5, zf + stand), Vector3(stand, h + toe, stand), tube))

	# Lifts: a ledger, a boarded deck and a toe board at every story line.
	for j in range(stories + 1):
		var y: float = y0 + h * (float(j) / float(stories))
		root.add_child(_arm_box(Vector3(cx, y, zf + reach), Vector3(w, stand, stand), tube))
		root.add_child(_arm_box(Vector3(cx, y + stand, zc), Vector3(w, stand * 0.9, deck), board))
		root.add_child(_arm_box(Vector3(cx, y + toe * 0.5 + stand, zf + reach), Vector3(w, toe, stand * 0.6), board))

	# Braces across the end bays — the diagonal that makes a frame a structure.
	var lift: float = h / float(stories)
	var bay_w: float = w / float(bays)
	for j in range(stories):
		var y: float = y0 + h * (float(j) / float(stories))
		for raw_x in [x0 + bay_w * 0.5, x0 + w - bay_w * 0.5]:
			var sx: float = float(raw_x)
			var brace: MeshInstance3D = _arm_box(Vector3(sx, y + lift * 0.5, zf + reach),
				Vector3(sqrt(bay_w * bay_w + lift * lift), stand * 0.8, stand * 0.8), tube)
			brace.rotation.z = atan2(lift, bay_w)
			root.add_child(brace)


## GANTRY — the machinery that put the parts there. Two towers standing clear of the ends,
## a beam over the parapet, and a cradle hung off it at working height. The elevation is
## untouched; what changes is the silhouette above and beside it.
func _armature_gantry(root: Node3D, x0: float, y0: float, w: float, h: float, zf: float) -> void:
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.55, 0.56, 0.60)
	steel.metallic = 0.8
	steel.roughness = 0.3
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.86, 0.55, 0.10)
	paint.roughness = 0.7

	var leg: float = clampf(w * 0.035, 0.18, 0.7)
	var stand_off: float = clampf(h * 0.09, 0.6, 1.6)
	var top: float = y0 + h + clampf(h * 0.12, 0.5, 1.8)
	var zc: float = zf + stand_off
	var lx0: float = x0 - leg
	var lx1: float = x0 + w + leg

	# Towers: a boxed leg each side, braced back to the face at two levels.
	for raw_x in [lx0, lx1]:
		var x: float = float(raw_x)
		root.add_child(_arm_box(Vector3(x, y0 + (top - y0) * 0.5, zc), Vector3(leg, top - y0, leg), steel))
		for f in [0.35, 0.8]:
			var y: float = y0 + h * float(f)
			root.add_child(_arm_box(Vector3(x, y, zf + stand_off * 0.5),
				Vector3(leg * 0.45, leg * 0.45, stand_off), steel))

	# The beam over the parapet, and the rail it runs on.
	root.add_child(_arm_box(Vector3((lx0 + lx1) * 0.5, top, zc), Vector3(lx1 - lx0 + leg, leg * 1.1, leg * 1.1), paint))
	root.add_child(_arm_box(Vector3((lx0 + lx1) * 0.5, top - leg, zc), Vector3(lx1 - lx0, leg * 0.4, leg * 0.4), steel))

	# The cradle: a hung platform at working height, on two drop lines.
	var cw: float = clampf(w * 0.28, 1.0, 4.0)
	var cy: float = y0 + h * 0.42
	var cxp: float = x0 + w * 0.5
	for raw_s in [-1.0, 1.0]:
		var sx: float = float(raw_s)
		root.add_child(_arm_box(Vector3(cxp + sx * cw * 0.45, (cy + top) * 0.5, zc),
			Vector3(leg * 0.16, top - cy, leg * 0.16), steel))
	root.add_child(_arm_box(Vector3(cxp, cy, zc), Vector3(cw, leg * 0.4, stand_off * 0.7), paint))
	root.add_child(_arm_box(Vector3(cxp, cy + leg * 0.9, zc + stand_off * 0.3),
		Vector3(cw, leg * 0.22, leg * 0.22), steel))


func _arm_box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi
