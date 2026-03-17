class_name FacadePlanImporter
extends RefCounted

## Imports a facade plan JSON (exported from the web-based ada_facade_editor)
## and builds a complete 3D facade using CSG nodes.
##
## This complements the MeshData-based FacadeGrammar system:
## - FacadePlanImporter uses CSG nodes for real-time interactive editing
## - FacadeGrammar uses MeshData for the procedural grammar pipeline
##
## Usage:
##   var facade := FacadePlanImporter.import_plan("res://path/to/facade_plan.json")
##   add_child(facade)


## Zone height multipliers matching the web editor.
const ZONE_HEIGHT_MULTIPLIERS := {
	"Cornice": 0.5,
	"Upper": 1.0,
	"Piano Nobile": 1.4,
	"Base": 0.9,
	"Plinth": 0.45,
}


## Import a facade plan JSON file and build the 3D scene.
## Returns a Node3D containing the complete CSG facade.
static func import_plan(json_path: String) -> Node3D:
	var data := _load_json(json_path)
	if data.is_empty():
		push_error("FacadePlanImporter: Failed to load plan from '%s'" % json_path)
		return Node3D.new()

	return build_from_dict(data)


## Build a facade from an already-parsed Dictionary.
## Useful when the JSON is loaded externally or constructed programmatically.
static func build_from_dict(data: Dictionary) -> Node3D:
	# Validate version
	var version: int = data.get("version", 0) as int
	if version != 1:
		push_warning("FacadePlanImporter: Unexpected version %d (expected 1)" % version)

	var facade_data: Dictionary = data.get("facade", {})
	var zones_data: Array = data.get("zones", [])
	var placements_data: Array = data.get("placements", [])
	var zone_colors: Dictionary = data.get("zone_colors", {})

	# Extract facade dimensions
	var bays: int = facade_data.get("bays", 5) as int
	var stories: int = facade_data.get("stories", 5) as int
	var total_width: float = facade_data.get("total_width", 15.0) as float
	var total_height: float = facade_data.get("total_height", 10.0) as float
	var primary_color: String = str(facade_data.get("primary_color", "#d4c5a9"))
	var secondary_color: String = str(facade_data.get("secondary_color", "#8d8d8d"))

	# Build the scene
	var root := Node3D.new()
	root.name = "FacadePlan"

	# ── Compute row heights ──
	var zone_for_row := _build_zone_map(zones_data)
	var row_heights: Array[float] = []
	var raw_total := 0.0

	for r in range(stories):
		var zone_name: String = zone_for_row.get(r, "")
		var mult: float = ZONE_HEIGHT_MULTIPLIERS.get(zone_name, 1.0) as float
		row_heights.append(mult)
		raw_total += mult

	# Normalize row heights so they sum to total_height
	if raw_total > 0:
		for i in range(row_heights.size()):
			row_heights[i] = (row_heights[i] / raw_total) * total_height

	# Cumulative Y offsets (row 0 = top of facade, so we go top-down)
	# In 3D: row 0 is at the TOP, row stories-1 is at the BOTTOM
	var row_y_bottoms: Array[float] = []
	var cum_y := 0.0
	for r in range(stories):
		# Row 0 starts at the top
		row_y_bottoms.append(0.0)  # placeholder
	# Compute from bottom up: row (stories-1) starts at y=0
	cum_y = 0.0
	for r in range(stories - 1, -1, -1):
		row_y_bottoms[r] = cum_y
		cum_y += row_heights[r]

	var cell_width := total_width / float(bays)

	# ── Base wall ──
	var wall := _create_base_wall(total_width, total_height, 0.25, primary_color)
	root.add_child(wall)

	# ── Zone backgrounds ──
	var zone_container := Node3D.new()
	zone_container.name = "Zones"
	root.add_child(zone_container)

	for zone_entry in zones_data:
		if not zone_entry is Dictionary:
			continue
		var row: int = zone_entry.get("row", 0) as int
		if row < 0 or row >= stories:
			continue
		var zone_name: String = str(zone_entry.get("name", ""))
		var zone_color_hex: String = str(zone_colors.get(zone_name, zone_entry.get("color", "")))

		if zone_color_hex != "" and zone_color_hex.begins_with("#"):
			var zone_bg := CSGBox3D.new()
			zone_bg.name = "ZoneBg_%s_%d" % [zone_name, row]
			zone_bg.size = Vector3(total_width, row_heights[row], 0.01)
			zone_bg.position = Vector3(
				total_width * 0.5,
				row_y_bottoms[row] + row_heights[row] * 0.5,
				0.126  # Slightly in front of wall
			)
			zone_bg.material = FacadeMaterials.stone_material(
				Color.html(zone_color_hex), 0.8
			)
			zone_container.add_child(zone_bg)

	# ── Element placements ──
	var elements_container := Node3D.new()
	elements_container.name = "Elements"
	root.add_child(elements_container)

	for placement in placements_data:
		if not placement is Dictionary:
			continue

		var col: int = placement.get("col", 0) as int
		var row: int = placement.get("row", 0) as int
		var element_type: String = str(placement.get("element_type", ""))

		if col < 0 or col >= bays or row < 0 or row >= stories:
			continue
		if element_type == "" or element_type == "plain_wall":
			continue

		var ch := row_heights[row] if row < row_heights.size() else (total_height / float(stories))

		# Build element params
		var elem_params := {
			"col": col,
			"row": row,
			"wall_depth": 0.25,
		}

		# Pass zone color as element color hint
		var zone_name: String = zone_for_row.get(row, "")
		if zone_colors.has(zone_name):
			elem_params["color"] = str(zone_colors[zone_name])
		elif secondary_color != "":
			elem_params["color"] = secondary_color

		# Generate the CSG element
		var element_node := CsgFacadeElements.create_element(element_type, cell_width, ch, elem_params)

		# Position: cell origin at bottom-left of the cell
		var cell_x := float(col) * cell_width + cell_width * 0.5
		var cell_y := row_y_bottoms[row]
		element_node.position = Vector3(cell_x, cell_y, 0.125)
		element_node.name = "%s_c%d_r%d" % [element_type, col, row]
		elements_container.add_child(element_node)

	print("FacadePlanImporter: Built facade with %d elements (%d bays × %d stories)" % [
		placements_data.size(), bays, stories
	])

	return root


# ─── INTERNAL HELPERS ──────────────────────────────────────────────────────

## Load and parse a JSON file.
static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("FacadePlanImporter: File not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("FacadePlanImporter: Cannot open file: %s" % path)
		return {}

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("FacadePlanImporter: JSON parse error at line %d: %s" % [
			json.get_error_line(), json.get_error_message()
		])
		return {}

	if json.data is Dictionary:
		return json.data
	return {}


## Build a map from row index → zone name.
static func _build_zone_map(zones_data: Array) -> Dictionary:
	var result := {}
	for entry in zones_data:
		if entry is Dictionary:
			var row: int = entry.get("row", -1) as int
			var name: String = str(entry.get("name", ""))
			if row >= 0 and name != "":
				result[row] = name
	return result


## Create the base wall as a CSGBox3D.
static func _create_base_wall(width: float, height: float, depth: float, color_hex: String) -> CSGBox3D:
	var wall := CSGBox3D.new()
	wall.name = "BaseWall"
	wall.size = Vector3(width, height, depth)
	wall.position = Vector3(width * 0.5, height * 0.5, 0)

	var color := Color(0.83, 0.77, 0.66)
	if color_hex.begins_with("#"):
		color = Color.html(color_hex)

	wall.material = FacadeMaterials.stone_material(color)
	return wall
