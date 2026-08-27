extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TwoCakes

## @identity
## lineage: the Composition hero — the registry promised a carousel_cake and never baked
##   it, so here are TWO: the same three tiers assembled by the same two instructions in
##   opposite orders. Left cake: rotate each tier, THEN slide it onto the stand — a neat
##   spiral staircase of a cake. Right cake: slide first, THEN rotate the lot — the
##   tiers sweep out sideways like a dancer caught mid-turn, candles leaning into the
##   consequence. Same ingredients. Different order. Different cake.
## essence: transforms compose, and composition does not commute: R·T ≠ T·R. The pair
##   is the proof by patisserie — every difference between the two cakes is owed
##   entirely to the order of the same two words.
## truth: order is the meaning. Ask any recipe, any sentence, any life.
##
## The 2026-08-27 category-heroes pass, transformation.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const TIER_COLORS := [Color(0.92, 0.86, 0.80), Color(0.88, 0.62, 0.66), Color(0.55, 0.30, 0.16)]

@export var seed: int = 15
@export var tier_r: float = 0.34       # base tier radius; upper tiers shrink by 0.72
@export var slide: float = 0.22        # the T of the demonstration, metres in x
@export var turn_deg: float = 40.0     # the R of the demonstration, per tier
@export var stands_apart: float = 2.1

func _ready() -> void:
	_rng.seed = seed
	_build_stand(Vector3(-stands_apart * 0.5, 0.0, 0.0), true)
	_build_stand(Vector3(stands_apart * 0.5, 0.0, 0.0), false)
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "tier_r", "slide", "turn_deg", "stands_apart"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_stand(at: Vector3, rotate_first: bool) -> void:
	var table := MeshInstance3D.new()
	var table_mesh := CylinderMesh.new()
	table_mesh.top_radius = tier_r + 0.28
	table_mesh.bottom_radius = tier_r + 0.34
	table_mesh.height = 0.85
	table.mesh = table_mesh
	table.position = at + Vector3(0.0, 0.425, 0.0)
	table.material_override = _matte_mat(Color(0.88, 0.86, 0.82), 0.9)
	add_child(table)
	var cloth := MeshInstance3D.new()
	var cloth_mesh := CylinderMesh.new()
	cloth_mesh.top_radius = tier_r + 0.32
	cloth_mesh.bottom_radius = tier_r + 0.32
	cloth_mesh.height = 0.02
	cloth.mesh = cloth_mesh
	cloth.position = at + Vector3(0.0, 0.86, 0.0)
	cloth.material_override = _matte_mat(Color(0.75, 0.65, 0.42), 0.9)
	add_child(cloth)

	var base_y := 0.87
	var tier_h := 0.16
	for i in range(3):
		var r := tier_r * pow(0.72, float(i))
		var theta := deg_to_rad(turn_deg) * float(i)
		var t_vec := Vector3(slide, 0.0, 0.0) * float(i)
		# THE WHOLE ARTIFACT IS THESE FOUR LINES. Left: rotate the tier's own slide
		# vector before applying it (R first, then T lands rotated). Right: slide in
		# world x, then the rotation only turns the tier in place.
		var offset: Vector3
		if rotate_first:
			offset = t_vec.rotated(Vector3.UP, theta)
		else:
			offset = t_vec
		var tier := MeshInstance3D.new()
		var tier_mesh := CylinderMesh.new()
		tier_mesh.top_radius = r
		tier_mesh.bottom_radius = r * 1.04
		tier_mesh.height = tier_h
		tier.mesh = tier_mesh
		tier.position = at + offset + Vector3(0.0, base_y + (tier_h + 0.012) * float(i) + tier_h * 0.5, 0.0)
		tier.rotation.y = theta
		tier.material_override = _matte_mat(TIER_COLORS[i], 0.9)
		add_child(tier)
		# piping: a ring of icing beads so the rotation is VISIBLE on a round tier
		for b in range(8):
			var bead := MeshInstance3D.new()
			var bead_mesh := SphereMesh.new()
			bead_mesh.radius = 0.022
			bead_mesh.height = 0.044
			bead.mesh = bead_mesh
			var ang := TAU * float(b) / 8.0 + theta
			bead.position = tier.position + Vector3(cos(ang) * (r - 0.03), tier_h * 0.5, sin(ang) * (r - 0.03))
			bead.material_override = _matte_mat(Color(0.95, 0.95, 0.92), 0.95)
			add_child(bead)
	# the candle rides the top tier and leans nowhere — it reports the top tier's
	# final ADDRESS, which is the two cakes' whole disagreement
	var top_theta := deg_to_rad(turn_deg) * 2.0
	var top_offset := (Vector3(slide, 0.0, 0.0) * 2.0)
	if rotate_first:
		top_offset = top_offset.rotated(Vector3.UP, top_theta)
	var candle := MeshInstance3D.new()
	var candle_mesh := CylinderMesh.new()
	candle_mesh.top_radius = 0.014
	candle_mesh.bottom_radius = 0.014
	candle_mesh.height = 0.16
	candle.mesh = candle_mesh
	candle.position = at + top_offset + Vector3(0.0, 0.87 + 3.0 * 0.172 + 0.08, 0.0)
	candle.material_override = _matte_mat(Color(0.13, 0.30, 0.62), 0.8)
	add_child(candle)
	var flame := MeshInstance3D.new()
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.025
	flame_mesh.height = 0.06
	flame.mesh = flame_mesh
	flame.position = candle.position + Vector3(0.0, 0.11, 0.0)
	flame.material_override = _glow_mat(Color(0.98, 0.75, 0.25), 2.0)
	add_child(flame)
	# the order, written under each cake
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.3
	tag.position = at + Vector3(0.0, 0.16, tier_r + 0.5)
	add_child(tag)
	if tag.has_method("set_text"):
		if rotate_first:
			tag.set_text("ROTATE, then SLIDE", "the slide happens in the tier's own turned frame")
		else:
			tag.set_text("SLIDE, then ROTATE", "the slide happens in the room's frame; the turn stays home")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "CakesPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(0.0, 0.24, tier_r + 0.95)
	ts.rotation.y = 0.0
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("TWO CAKES - R*T != T*R",
			"The same three tiers, the same two instructions, opposite orders -\nand two different cakes, candles at two different addresses.\nComposition does not commute. Order is the meaning. Ask any recipe.")
