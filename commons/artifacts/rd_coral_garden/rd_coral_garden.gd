# rd_coral_garden.gd — Walkable Gray-Scott coral polyp forest.
# Gray-Scott reaction-diffusion at (F=0.062, K=0.061) simulated once at
# _ready(), rendered as a MultiMesh forest of small cylinders. Above-threshold
# cells become polyps, V concentration drives height.
#
# Uses the same commons/rd_grammar/rd_sim.gd substrate that powers the
# rd-gallery research configs — so this artifact IS one of the gallery's
# crown jewels made walkable in VR.
#
# @identity
# essence: Gray-Scott (F=0.062, K=0.061) as a walkable coral garden — two constants become a reef
# desire: To stand in the pattern. Not view it on a screen — walk between the polyps.
# critical_parameter: (F, K) — one of the eight named Gray-Scott preset regions, each a different ecology
# triggers: Change preset → spots become columns, stripes become ridges, mitosis becomes self-replicating hills
# emerges: An organic distribution of polyps that the player navigates as terrain. Not designed, grown.
# needs: VR player to walk in it. Label3D for pedagogy.
# relationships: Sibling to rd04_coral_heightmap and rd06_coral_pillars in the rd-gallery. Part of the RD DNA family on /dna.
# truth: No artist placed these pillars. Two numbers did.

extends Node3D

class_name RDCoralGarden

const RDSimScript = preload("res://commons/rd_grammar/rd_sim.gd")

## RD parameters — choose preset or override with (F, K)
@export var preset: String = "coral"           # coral / spots / stripes / mazes / mitosis / chaos
@export var custom_F: float = -1.0             # override preset F (set > 0 to use)
@export var custom_K: float = -1.0             # override preset K

## Grid + simulation
@export var grid_size: int = 64                # NxN cells — larger = more detail, slower
@export var iterations: int = 3500
@export var rd_seed: int = 17

## Rendering
@export var threshold: float = 0.22            # V concentration threshold for "alive"
@export var garden_radius: float = 4.0         # meters — footprint
@export var pillar_base_height: float = 0.04
@export var pillar_max_height: float = 0.45
@export var pillar_radius: float = 0.035
@export var color_lo: Color = Color(0.45, 0.22, 0.15)
@export var color_hi: Color = Color(0.96, 0.58, 0.32)

## Label
@export var show_label: bool = true
@export var label_height: float = 1.6

var _mmi: MultiMeshInstance3D
var _label: Label3D


func _ready() -> void:
	_build_garden()
	if show_label:
		_build_label()


func _build_garden() -> void:
	# Simulate RD once
	var cfg: Dictionary = {
		"preset": preset,
		"grid_size": grid_size,
		"iterations": iterations,
		"seed": rd_seed,
	}
	if custom_F > 0.0: cfg["F"] = custom_F
	if custom_K > 0.0: cfg["K"] = custom_K
	var field: PackedFloat32Array = RDSimScript.simulate(cfg)

	# Count alive cells for MultiMesh sizing
	var alive: Array = []
	for iy in grid_size:
		for ix in grid_size:
			var v: float = field[iy * grid_size + ix]
			if v > threshold:
				alive.append([ix, iy, v])

	# Build MultiMesh of cylinders
	_mmi = MultiMeshInstance3D.new()
	_mmi.name = "Pillars"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cyl := CylinderMesh.new()
	cyl.top_radius = pillar_radius
	cyl.bottom_radius = pillar_radius
	cyl.height = 1.0  # scaled per-instance
	cyl.radial_segments = 6
	mm.mesh = cyl
	mm.instance_count = alive.size()

	var cell_world: float = garden_radius * 2.0 / float(grid_size - 1)

	for i in alive.size():
		var c = alive[i]
		var ix: int = c[0]
		var iy: int = c[1]
		var v: float = c[2]
		var x: float = -garden_radius + float(ix) * cell_world
		var z: float = -garden_radius + float(iy) * cell_world
		var h: float = pillar_base_height + v * (pillar_max_height - pillar_base_height)
		var t := Transform3D(Basis().scaled(Vector3(1, h, 1)), Vector3(x, h * 0.5, z))
		mm.set_instance_transform(i, t)
		var tt: float = clampf(v * 2.0, 0.0, 1.0)
		mm.set_instance_color(i, color_lo.lerp(color_hi, tt))

	_mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.58
	mat.metallic = 0.0
	_mmi.material_override = mat
	add_child(_mmi)

	print("RDCoralGarden: %d polyps from %s (F/K=%s)" % [
		alive.size(), preset,
		"custom" if custom_F > 0 else "preset"
	])


func _build_label() -> void:
	_label = Label3D.new()
	_label.name = "Label"
	_label.text = "Gray-Scott coral\n(F=0.062, K=0.061)\n%d polyps from two constants" % _mmi.multimesh.instance_count
	_label.pixel_size = 0.003
	_label.font_size = 28
	_label.modulate = Color(0.85, 0.82, 0.78)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, label_height, 0)
	add_child(_label)


## Grid-system integration — apply config from map_data.json
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("preset"):
		preset = str(config_data["preset"])
	if config_data.has("grid_size"):
		grid_size = clampi(int(config_data["grid_size"]), 16, 128)
	if config_data.has("iterations"):
		iterations = clampi(int(config_data["iterations"]), 500, 10000)
	if config_data.has("rd_seed"):
		rd_seed = int(config_data["rd_seed"])
	if config_data.has("garden_radius"):
		garden_radius = clampf(float(config_data["garden_radius"]), 1.0, 8.0)
	# Rebuild if already built
	if _mmi and _mmi.get_parent() == self:
		_mmi.queue_free()
		_mmi = null
	if _label and _label.get_parent() == self:
		_label.queue_free()
		_label = null
	_build_garden()
	if show_label:
		_build_label()
