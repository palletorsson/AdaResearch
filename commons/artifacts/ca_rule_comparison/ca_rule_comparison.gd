# ca_rule_comparison.gd — Walkable CA rule comparison garden.
# Five mini-cities arranged in a cross, each running the same initial seed
# through a different CA rule. The cities differ entirely because the rules
# differ by two digits. Mirror structure to gray_scott_comparison for RD.
#
# @identity
# essence: Five CA rules as five emergent ecologies — same density, same seed, different rule, different world
# desire: To walk the contrast. Conway's pastoral → HighLife's sparse gliders → Seeds' explosions → Day-and-Night's continents → Life-without-Death's geology
# critical_parameter: rule string — B3/S23 vs B36/S23 vs B2/S vs B3678/S34678 vs B3/S012345678
# triggers: Walking from city to city — the seed is identical, only the acceptance function changed
# emerges: Five architectures of emergence, laid out for comparison
# needs: Enough space for 5 cities. Labels with rule strings. Walk paths between.
# relationships: CA-family sibling of ca_conway_city (one preset at full scale); RD-family sibling of gray_scott_comparison (nine-garden teacher).
# truth: Two digits in a rule string make the difference between an empty field and a mountain of memory.

extends Node3D

class_name CARuleComparison

const CAPruneOpScript = preload("res://commons/graph_grammar/operations/ca_prune_op.gd")

## Five presets — Conway, HighLife, Seeds, Day-and-Night, Life-without-Death
const PRESETS: Array = [
	{"name": "conway",             "label": "Conway",          "rule_str": "B3/S23"},
	{"name": "highlife",           "label": "HighLife",        "rule_str": "B3,6/S2,3"},
	{"name": "seeds",              "label": "Seeds",           "rule_str": "B2/S∅"},
	{"name": "day_and_night",      "label": "Day & Night",     "rule_str": "B3,6,7,8/S3,4,6,7,8"},
	{"name": "life_without_death", "label": "Life w/o Death",  "rule_str": "B3/S∀"},
]

const CA_RULES := {
	"conway":             {"B": [3],       "S": [2, 3]},
	"highlife":           {"B": [3, 6],    "S": [2, 3]},
	"seeds":              {"B": [2],       "S": []},
	"life_without_death": {"B": [3],       "S": [0, 1, 2, 3, 4, 5, 6, 7, 8]},
	"day_and_night":      {"B": [3, 6, 7, 8], "S": [3, 4, 6, 7, 8]},
}

## Simulation
@export var per_city_grid: int = 22
@export var iterations: int = 10
@export var density: float = 0.45
@export var shared_seed: int = 3                 # same seed for every rule → isolates rule effect

## Layout — cross pattern: center + 4 cardinal
@export var city_footprint: float = 1.4          # meters half-width
@export var city_spacing: float = 4.2            # meters between centers

## Tower scale
@export var building_base: float = 0.08
@export var building_scale: float = 0.25
@export var building_width: float = 0.16

## Palette per rule
const RULE_PALETTES: Dictionary = {
	"conway":             [Color(0.12, 0.12, 0.15), Color(0.92, 0.92, 0.94)],  # monochrome
	"highlife":           [Color(0.18, 0.14, 0.08), Color(0.95, 0.78, 0.35)],  # amber
	"seeds":              [Color(0.2, 0.1, 0.1),    Color(0.95, 0.45, 0.35)],  # red — explosive
	"day_and_night":      [Color(0.1, 0.12, 0.2),   Color(0.55, 0.75, 0.95)],  # blue continents
	"life_without_death": [Color(0.08, 0.18, 0.12), Color(0.5, 0.85, 0.55)],   # green geology
}


func _ready() -> void:
	_build_comparison()


func _build_comparison() -> void:
	# Cross layout: center (0,0), then N, S, E, W
	var positions: Array = [
		Vector3(0, 0, 0),
		Vector3(0, 0, -city_spacing),
		Vector3(0, 0,  city_spacing),
		Vector3( city_spacing, 0, 0),
		Vector3(-city_spacing, 0, 0),
	]
	for i in PRESETS.size():
		var preset: Dictionary = PRESETS[i]
		_build_one_city(preset, positions[i])


func _build_one_city(preset: Dictionary, origin: Vector3) -> void:
	var rule_name: String = preset["name"]
	var r_def: Dictionary = CA_RULES[rule_name]
	var grid: PackedInt32Array = CAPruneOpScript._simulate_ca(
		per_city_grid, r_def["B"], r_def["S"], iterations, density, shared_seed)

	var alive: Array = []
	for iy in per_city_grid:
		for ix in per_city_grid:
			if grid[iy * per_city_grid + ix] == 0: continue
			var n: int = 0
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					if dx == 0 and dy == 0: continue
					var rr: int = iy + dy; var cc: int = ix + dx
					if rr < 0 or rr >= per_city_grid or cc < 0 or cc >= per_city_grid: continue
					if grid[rr * per_city_grid + cc] == 1: n += 1
			alive.append([ix, iy, n])

	var pal: Array = RULE_PALETTES.get(rule_name, [Color(0.2, 0.2, 0.2), Color(0.9, 0.9, 0.9)])
	var color_lo: Color = pal[0]
	var color_hi: Color = pal[1]

	if alive.is_empty():
		# Still build a label for empty cities
		_build_label(preset, origin, 0)
		return

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "City_" + rule_name
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bx := BoxMesh.new(); bx.size = Vector3(1, 1, 1)
	mm.mesh = bx
	mm.instance_count = alive.size()

	var cell_world: float = city_footprint * 2.0 / float(per_city_grid - 1)
	for i in alive.size():
		var c = alive[i]
		var ix: int = c[0]; var iy: int = c[1]; var n: int = c[2]
		var x: float = -city_footprint + float(ix) * cell_world
		var z: float = -city_footprint + float(iy) * cell_world
		var h: float = building_base + float(n) * building_scale * building_base * 2.0
		var t := Transform3D(
			Basis().scaled(Vector3(building_width, h, building_width)),
			Vector3(x, h * 0.5, z))
		mm.set_instance_transform(i, t)
		var tt: float = clampf(float(n) / 8.0, 0.0, 1.0)
		mm.set_instance_color(i, color_lo.lerp(color_hi, tt))
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.55
	mmi.material_override = mat
	mmi.position = origin
	add_child(mmi)

	_build_label(preset, origin, alive.size())


func _build_label(preset: Dictionary, origin: Vector3, count: int) -> void:
	var lbl := Label3D.new()
	lbl.name = "Label_" + preset["name"]
	lbl.text = "%s\n%s\n%d cells" % [preset["label"], preset["rule_str"], count]
	lbl.pixel_size = 0.003
	lbl.font_size = 28
	lbl.modulate = Color(0.92, 0.88, 0.82)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = origin + Vector3(0, 1.1, 0)
	add_child(lbl)


## Grid-system integration
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("per_city_grid"):
		per_city_grid = clampi(int(config_data["per_city_grid"]), 12, 40)
	if config_data.has("iterations"):
		iterations = clampi(int(config_data["iterations"]), 2, 30)
	if config_data.has("density"):
		density = clampf(float(config_data["density"]), 0.2, 0.8)
	if config_data.has("shared_seed"):
		shared_seed = int(config_data["shared_seed"])
	if config_data.has("city_spacing"):
		city_spacing = clampf(float(config_data["city_spacing"]), 3.0, 6.0)
	for child in get_children():
		child.queue_free()
	_build_comparison()
