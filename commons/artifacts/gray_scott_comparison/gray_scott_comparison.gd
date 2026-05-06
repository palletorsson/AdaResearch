# gray_scott_comparison.gd — Walkable Gray-Scott parameter comparison garden.
# Nine mini-gardens arranged 3×3, each running the same reaction-diffusion
# equations with a different (F, K) preset. Walking between them teaches
# the thesis directly: same equations, different constants, different ecology.
#
# Each mini-garden is a small pillar forest (like rd_coral_garden but scaled
# down), with a Label3D naming its (F, K) values and the emergent pattern name.
#
# @identity
# essence: Turing's 1952 claim made walkable — two chemicals, two constants, nine ecologies
# desire: To make the argument of blog post #2 into something a person can stand inside
# critical_parameter: (F, K) — the entire content of each garden is encoded in two numbers
# triggers: The player walks between gardens and sees that identical math produces spots, stripes, mazes, coral, mitosis — nothing else changes
# emerges: The pedagogical punchline of reaction-diffusion. Pattern formation from local rules.
# needs: Enough space for 3×3 gardens. Labels at reading height. Walk paths between.
# relationships: Rd-family sibling of rd_coral_garden — this is the "all nine presets" teacher, that's the "one preset at full scale" artwork.
# truth: Everything here is (F, K). Nothing else changes. The rule is the thing.

extends Node3D

class_name GrayScottComparison

const RDSimScript = preload("res://commons/rd_grammar/rd_sim.gd")

## Nine presets arranged 3×3 — the canonical pattern zoo
const PRESETS: Array = [
	["spots",    "F=0.037 K=0.06"],
	["stripes",  "F=0.022 K=0.051"],
	["mazes",    "F=0.029 K=0.057"],
	["coral",    "F=0.062 K=0.061"],
	["mitosis",  "F=0.0367 K=0.0649"],
	["chaos",    "F=0.026 K=0.051"],
	["bacteria", "F=0.014 K=0.054"],
	["holes",    "F=0.039 K=0.058"],
	["coral",    "F=0.062 K=0.061"],  # repeat for 9th cell so grid is full
]

## Simulation per garden (smaller for performance)
@export var per_garden_grid: int = 48
@export var iterations: int = 3000
@export var base_seed: int = 7

## Layout
@export var garden_size: float = 1.6            # meters — per-garden footprint half-width
@export var garden_spacing: float = 3.8         # meters between garden centers
@export var threshold: float = 0.22
@export var pillar_radius: float = 0.025
@export var pillar_base_height: float = 0.03
@export var pillar_max_height: float = 0.35

## Palette per preset — each garden gets its own color family
const PALETTES: Dictionary = {
	"spots":    [Color(0.2, 0.15, 0.25), Color(0.95, 0.75, 0.3)],
	"stripes":  [Color(0.15, 0.25, 0.35), Color(0.85, 0.9, 0.4)],
	"mazes":    [Color(0.2, 0.2, 0.35),   Color(0.4, 0.85, 0.7)],
	"coral":    [Color(0.25, 0.15, 0.15), Color(0.95, 0.5, 0.35)],
	"mitosis":  [Color(0.1, 0.2, 0.25),   Color(0.7, 0.95, 0.9)],
	"chaos":    [Color(0.15, 0.1, 0.2),   Color(1.0, 0.65, 0.3)],
	"bacteria": [Color(0.2, 0.2, 0.1),    Color(0.7, 0.85, 0.3)],
	"holes":    [Color(0.1, 0.2, 0.25),   Color(0.6, 0.8, 0.95)],
}


func _ready() -> void:
	_build_comparison()


func _build_comparison() -> void:
	for i in PRESETS.size():
		var col: int = i % 3
		var row: int = i / 3
		var gx: float = (float(col) - 1.0) * garden_spacing
		var gz: float = (float(row) - 1.0) * garden_spacing
		var origin := Vector3(gx, 0, gz)
		var preset_name: String = PRESETS[i][0]
		var fk_label: String = PRESETS[i][1]
		_build_one_garden(preset_name, fk_label, origin, base_seed + i * 13)


func _build_one_garden(preset_name: String, fk_label: String,
		origin: Vector3, seed_val: int) -> void:
	var cfg: Dictionary = {
		"preset": preset_name,
		"grid_size": per_garden_grid,
		"iterations": iterations,
		"seed": seed_val,
	}
	var field: PackedFloat32Array = RDSimScript.simulate(cfg)
	var pal: Array = PALETTES.get(preset_name, [Color(0.3, 0.25, 0.2), Color(0.9, 0.8, 0.5)])
	var color_lo: Color = pal[0]
	var color_hi: Color = pal[1]

	var alive: Array = []
	for iy in per_garden_grid:
		for ix in per_garden_grid:
			var v: float = field[iy * per_garden_grid + ix]
			if v > threshold:
				alive.append([ix, iy, v])

	if alive.is_empty(): return

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Garden_" + preset_name
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cyl := CylinderMesh.new()
	cyl.top_radius = pillar_radius
	cyl.bottom_radius = pillar_radius
	cyl.height = 1.0
	cyl.radial_segments = 6
	mm.mesh = cyl
	mm.instance_count = alive.size()

	var cell_world: float = garden_size * 2.0 / float(per_garden_grid - 1)
	for i in alive.size():
		var c = alive[i]
		var ix: int = c[0]; var iy: int = c[1]; var v: float = c[2]
		var x: float = -garden_size + float(ix) * cell_world
		var z: float = -garden_size + float(iy) * cell_world
		var h: float = pillar_base_height + v * (pillar_max_height - pillar_base_height)
		var t := Transform3D(
			Basis().scaled(Vector3(1, h, 1)),
			Vector3(x, h * 0.5, z))
		mm.set_instance_transform(i, t)
		var tt: float = clampf(v * 2.0, 0.0, 1.0)
		mm.set_instance_color(i, color_lo.lerp(color_hi, tt))

	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.58
	mmi.material_override = mat
	mmi.position = origin
	add_child(mmi)

	# Label at each garden
	var lbl := Label3D.new()
	lbl.name = "Label_" + preset_name
	lbl.text = "%s\n%s" % [preset_name.capitalize(), fk_label]
	lbl.pixel_size = 0.0024
	lbl.font_size = 28
	lbl.modulate = Color(0.92, 0.88, 0.82)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = origin + Vector3(0, 0.9, 0)
	add_child(lbl)


## Grid-system integration
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("per_garden_grid"):
		per_garden_grid = clampi(int(config_data["per_garden_grid"]), 24, 96)
	if config_data.has("iterations"):
		iterations = clampi(int(config_data["iterations"]), 500, 6000)
	if config_data.has("garden_spacing"):
		garden_spacing = clampf(float(config_data["garden_spacing"]), 2.0, 6.0)
	for child in get_children():
		child.queue_free()
	_build_comparison()
