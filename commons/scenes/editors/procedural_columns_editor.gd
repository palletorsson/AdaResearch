# procedural_columns_editor.gd — Wraps the real ProceduralColumns system at
# commons/mesh_grammar/procedural_columns.gd into a live editor.
# Uses ProceduralColumns.create_column() and ProceduralColumns.profile_column()
# with real column types: solomonic, double_helix, straight, profile,
# fluted_twist, cluster, fluted_straight, twisted_pair, tapered, spiral.
# Profile presets: entasis, baluster, vase, bamboo, bone, solomon_smooth.
extends BaseGeometryEditor

# Column types from ProceduralColumns.get_column_types()
const COLUMN_TYPES: Array[String] = [
	"solomonic", "double_helix", "straight", "profile",
	"fluted_twist", "cluster", "fluted_straight", "twisted_pair",
	"tapered", "spiral",
]
const COLUMN_TYPE_LABELS: Array[String] = [
	"Solomonic", "Double Helix", "Straight", "Profile",
	"Fluted Twist", "Cluster", "Fluted Straight", "Twisted Pair",
	"Tapered", "Spiral",
]

# Profile presets for the "profile" column type
const PROFILE_NAMES: Array[String] = [
	"entasis", "baluster", "vase", "bamboo", "bone", "solomon_smooth",
]


func _get_editor_name() -> String:
	return "Procedural Columns"


func _get_parameter_groups() -> Array:
	return [
		{"name": "Column", "params": [
			{"id": "col_type", "label": "Type (0-9)", "min": 0.0, "max": 9.0, "step": 1.0, "default": 0.0},
			{"id": "profile_idx", "label": "Profile (0-5)", "min": 0.0, "max": 5.0, "step": 1.0, "default": 0.0},
		]},
		{"name": "Dimensions", "params": [
			{"id": "height", "label": "Height", "min": 0.3, "max": 3.0, "step": 0.05, "default": 1.0},
			{"id": "width", "label": "Width", "min": 0.3, "max": 2.0, "step": 0.05, "default": 1.0},
			{"id": "radius", "label": "Radius", "min": 0.05, "max": 0.3, "step": 0.01, "default": 0.1},
		]},
		{"name": "Detail", "params": [
			{"id": "segments", "label": "Segments", "min": 6.0, "max": 32.0, "step": 2.0, "default": 16.0},
			{"id": "flutes", "label": "Flutes", "min": 0.0, "max": 24.0, "step": 1.0, "default": 0.0},
			{"id": "twist_count", "label": "Twist Count", "min": 1.0, "max": 12.0, "step": 1.0, "default": 6.0},
		]},
		{"name": "Shape", "params": [
			{"id": "entasis", "label": "Entasis", "min": 0.0, "max": 0.3, "step": 0.01, "default": 0.05},
			{"id": "twist_radius", "label": "Twist Radius", "min": 0.02, "max": 0.2, "step": 0.01, "default": 0.08},
		]},
	]


func _rebuild() -> void:
	_clear_content()

	var type_idx: int = clampi(int(p("col_type", 0)), 0, COLUMN_TYPES.size() - 1)
	var col_type: String = COLUMN_TYPES[type_idx]

	var height_val: float = p("height", 1.0)
	var width_val: float = p("width", 1.0)
	var radius_val: float = p("radius", 0.1)
	var segments_val: int = clampi(int(p("segments", 16)), 6, 32)
	var flutes_val: int = clampi(int(p("flutes", 0)), 0, 24)
	var twist_count_val: float = p("twist_count", 6.0)
	var entasis_val: float = p("entasis", 0.05)
	var twist_radius_val: float = p("twist_radius", 0.08)
	var profile_idx: int = clampi(int(p("profile_idx", 0)), 0, PROFILE_NAMES.size() - 1)

	# Build params dictionary for ProceduralColumns.create_column()
	var params: Dictionary = {
		"radius": radius_val,
		"shaft_radius": radius_val,
		"segments": segments_val,
		"flute_count": flutes_val,
		"flute_depth": 0.15,
		"twist_count": twist_count_val,
		"twist_radius": twist_radius_val,
		"entasis": entasis_val,
		"helix_radius": radius_val * 1.2,
	}

	# For profile type, set the profile preset
	if col_type == "profile":
		params["profile"] = PROFILE_NAMES[profile_idx]

	# For cluster type, set reasonable satellite params
	if col_type == "cluster":
		params["shaft_count"] = 8
		params["central_radius"] = radius_val
		params["satellite_radius"] = radius_val * 0.5
		params["orbit_radius"] = radius_val * 2.2

	var column: Node3D = ProceduralColumns.create_column(
		col_type, width_val, height_val, params)

	if column:
		# Center the column vertically so it orbits nicely
		column.position.y = -height_val * 0.5
		content_root.add_child(column)

	# Update info label
	var type_label: String = COLUMN_TYPE_LABELS[type_idx]
	var extra := ""
	if col_type == "profile":
		extra = " (%s)" % PROFILE_NAMES[profile_idx]
	info_label.text = "%s%s | h=%.1f r=%.2f seg=%d" % [
		type_label, extra, height_val, radius_val, segments_val]
