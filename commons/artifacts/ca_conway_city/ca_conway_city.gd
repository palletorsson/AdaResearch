# ca_conway_city.gd — Walkable Conway Life emergent city.
# Cellular automaton simulated once at _ready(), alive cells become blocks,
# live-neighbor count at the final step drives building height.
# Clusters become towers; isolated cells stay squat. The Life pattern IS
# the city layout — no urban planner, only a rule.
#
# Uses the same CAPruneOp._simulate_ca helper that seeds the CA-family
# gallery artifacts (ps_ca01_conway_city, sb_ca02_life_without_death_cloth,
# gg_quad01_ca_tapestry_chandelier).
#
# @identity
# essence: Conway's Game of Life as a walkable emergent skyline — B3/S23 becomes modernism
# desire: To walk inside the pattern. Between the cubes, under the towers, through the gaps that the rule left.
# critical_parameter: rule — Conway/HighLife/Seeds/Day-and-Night/Life-without-Death each produce a different city
# triggers: Change rule → pastoral sparse city, continental density, explosive patches, or geological accumulation
# emerges: Urban form without urban planning. The rule is the architect.
# needs: Enough walkable area (~8 cells) to stand in. Label3D for pedagogy.
# relationships: Sibling to rd_coral_garden — both take a 2D substrate pattern and make it walkable terrain.
# truth: Change two digits in the rule string and the city becomes a different kind of thing.

extends Node3D

class_name CAConwayCity

const CAPruneOpScript = preload("res://commons/graph_grammar/operations/ca_prune_op.gd")

## CA parameters
@export var rule: String = "conway"             # conway / highlife / seeds / life_without_death / day_and_night
@export var grid_size: int = 22                 # N×N grid cells
@export var iterations: int = 10
@export var density: float = 0.45               # initial live-cell density
@export var ca_seed: int = 3

## Walkable scale
@export var city_radius: float = 3.6            # meters — footprint half-width
@export var building_base: float = 0.1          # meters — minimum tower height
@export var building_scale: float = 0.35        # extra meters per live neighbor
@export var building_width: float = 0.22        # meters — cube side

## Palette
@export var color_lo: Color = Color(0.12, 0.12, 0.15)
@export var color_hi: Color = Color(0.92, 0.92, 0.94)

## Label
@export var show_label: bool = true
@export var label_height: float = 1.65

var _mmi: MultiMeshInstance3D
var _label: Label3D


const CA_RULES := {
	"conway":             {"B": [3],       "S": [2, 3]},
	"highlife":           {"B": [3, 6],    "S": [2, 3]},
	"seeds":              {"B": [2],       "S": []},
	"life_without_death": {"B": [3],       "S": [0, 1, 2, 3, 4, 5, 6, 7, 8]},
	"day_and_night":      {"B": [3, 6, 7, 8], "S": [3, 4, 6, 7, 8]},
}


func _ready() -> void:
	_build_city()
	if show_label:
		_build_label()


func _build_city() -> void:
	var r_def: Dictionary = CA_RULES.get(rule, CA_RULES["conway"])
	var grid: PackedInt32Array = CAPruneOpScript._simulate_ca(
		grid_size, r_def["B"], r_def["S"], iterations, density, ca_seed)

	# Collect alive cells with their live-neighbor count at final step
	var alive: Array = []
	for iy in grid_size:
		for ix in grid_size:
			if grid[iy * grid_size + ix] == 0: continue
			var n: int = 0
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					if dx == 0 and dy == 0: continue
					var rr: int = iy + dy; var cc: int = ix + dx
					if rr < 0 or rr >= grid_size or cc < 0 or cc >= grid_size: continue
					if grid[rr * grid_size + cc] == 1: n += 1
			alive.append([ix, iy, n])

	# MultiMesh of cubes
	_mmi = MultiMeshInstance3D.new()
	_mmi.name = "Buildings"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bx := BoxMesh.new()
	bx.size = Vector3(1, 1, 1)
	mm.mesh = bx
	mm.instance_count = alive.size()

	var cell_world: float = city_radius * 2.0 / float(grid_size - 1)

	for i in alive.size():
		var c = alive[i]
		var ix: int = c[0]
		var iy: int = c[1]
		var n: int = c[2]
		var x: float = -city_radius + float(ix) * cell_world
		var z: float = -city_radius + float(iy) * cell_world
		var h: float = building_base + float(n) * building_scale * building_base * 2.0
		var t := Transform3D(
			Basis().scaled(Vector3(building_width, h, building_width)),
			Vector3(x, h * 0.5, z))
		mm.set_instance_transform(i, t)
		var tt: float = clampf(float(n) / 8.0, 0.0, 1.0)
		mm.set_instance_color(i, color_lo.lerp(color_hi, tt))

	_mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.55
	mat.metallic = 0.0
	_mmi.material_override = mat
	add_child(_mmi)

	print("CAConwayCity: %d buildings from %s (B=%s, S=%s)" % [
		alive.size(), rule, r_def["B"], r_def["S"]])


func _build_label() -> void:
	var r_def: Dictionary = CA_RULES.get(rule, CA_RULES["conway"])
	_label = Label3D.new()
	_label.name = "Label"
	_label.text = "%s\nB=%s  S=%s\n%d buildings from one rule" % [
		rule.capitalize(), r_def["B"], r_def["S"],
		_mmi.multimesh.instance_count if _mmi else 0
	]
	_label.pixel_size = 0.003
	_label.font_size = 28
	_label.modulate = Color(0.88, 0.87, 0.83)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, label_height, 0)
	add_child(_label)


## Grid-system integration
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("rule"):
		rule = str(config_data["rule"])
	if config_data.has("grid_size"):
		grid_size = clampi(int(config_data["grid_size"]), 12, 48)
	if config_data.has("iterations"):
		iterations = clampi(int(config_data["iterations"]), 2, 30)
	if config_data.has("density"):
		density = clampf(float(config_data["density"]), 0.1, 0.9)
	if config_data.has("ca_seed"):
		ca_seed = int(config_data["ca_seed"])
	if config_data.has("city_radius"):
		city_radius = clampf(float(config_data["city_radius"]), 1.5, 8.0)
	# Rebuild
	if _mmi and _mmi.get_parent() == self:
		_mmi.queue_free(); _mmi = null
	if _label and _label.get_parent() == self:
		_label.queue_free(); _label = null
	_build_city()
	if show_label: _build_label()
