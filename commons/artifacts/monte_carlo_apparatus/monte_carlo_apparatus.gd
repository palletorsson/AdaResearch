extends Node3D
class_name MonteCarloApparatus

# @identity
# essence: a Monte Carlo workshop laid out as physical stations. probability_box
#   (the sampler — 5 dice on a wooden tray) at the front. fishbowl (the random
#   walker — the trail dots showing where the walker has been) on the left.
#   scales (the estimator — beam tilts toward the better hypothesis) on the
#   right. info_screen (the running mean — the live estimate updating in
#   green) on the back wall. Walking the workshop IS executing one MC step:
#   roll, walk, weigh, report.
# desire: Monte Carlo methods are abstract precisely because they don't have
#   a single visual referent — they're "many small samples averaged." The
#   workshop gives the samples a place and the averaging a shape.
# critical_parameter: dice_count (how many samples per step) + estimate_value
#   (the running mean shown on the info screen) + scales tilt (which
#   hypothesis the evidence currently favors) — together they ARE one
#   Monte Carlo iteration.
# triggers: _ready() instantiates 4 props at workshop positions.
# emerges: a chamber that teaches "sample, walk, weigh, report" without
#   anyone writing the algorithm down. The walk through the stations IS
#   the algorithm.
# needs: probability_box (sampler), fishbowl (random walker), scales
#   (estimator), info_screen (reporter), large_table (workbench surface).
# relationships: sibling to turing_apparatus, qfep_phase_apparatus,
#   foundations_crisis_apparatus. Same composer pattern.
# truth: Monte Carlo is not a computation — it is a discipline of asking
#   the world many small questions and averaging the answers.

const SCENE_PROBABILITY_BOX: PackedScene = preload("res://commons/artifacts/probability_box/probability_box.tscn")
const SCENE_FISHBOWL: PackedScene = preload("res://commons/artifacts/fishbowl/fishbowl.tscn")
const SCENE_SCALES: PackedScene = preload("res://commons/artifacts/scales/scales.tscn")
const SCENE_INFO_SCREEN: PackedScene = preload("res://commons/artifacts/info_screen/info_screen.tscn")
const SCENE_LARGE_TABLE: PackedScene = preload("res://commons/artifacts/large_table/large_table.tscn")
const SCENE_WHITEBOARD: PackedScene = preload("res://commons/artifacts/whiteboard/whiteboard.tscn")
const SCENE_LAB_STOOL: PackedScene = preload("res://commons/artifacts/lab_stool/lab_stool.tscn")
const SCENE_SAFETY_SHOWER: PackedScene = preload("res://commons/artifacts/safety_shower/safety_shower.tscn")
const SCENE_CATALYST_PICKUP: PackedScene = preload("res://commons/artifacts/catalyst_pickup/catalyst_pickup.tscn")

@export var current_estimate: float = 0.6427
@export var sample_count_so_far: int = 1024
@export var dice_count: int = 5
@export var scales_left_weight: float = 2.6  # evidence on hypothesis A
@export var scales_right_weight: float = 1.8  # evidence on hypothesis B

var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build_apparatus()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for child in get_children():
			child.queue_free()
		_built = false
		_build_apparatus()


func _read_metadata_overrides() -> void:
	if has_meta("config_current_estimate"):
		current_estimate = float(str(get_meta("config_current_estimate")))
	if has_meta("config_sample_count_so_far"):
		sample_count_so_far = int(str(get_meta("config_sample_count_so_far")))


func _build_apparatus() -> void:
	# ── Front-center: workbench table with the probability_box sampler
	var table_front: Node3D = SCENE_LARGE_TABLE.instantiate()
	table_front.set("length", 1.40)
	table_front.set("depth", 0.80)
	table_front.set("height", 0.85)
	table_front.set("leg_style", "panel")
	table_front.set("top_color", Color(0.88, 0.88, 0.90))
	table_front.set("leg_color", Color(0.20, 0.20, 0.24))
	table_front.set("accent_color", Color(0.20, 0.55, 0.95))
	table_front.set("edge_strip", true)
	table_front.position = Vector3(0.0, 0.0, -0.6)
	add_child(table_front)

	var dice: Node3D = SCENE_PROBABILITY_BOX.instantiate()
	dice.set("dice_count", dice_count)
	dice.set("arrangement", "scattered")
	dice.set("face_values", PackedInt32Array([6, 4, 2, 5, 3, 1, 6, 2]))
	dice.set("tray_color", Color(0.45, 0.30, 0.18))
	dice.set("dice_color", Color(0.95, 0.94, 0.88))
	dice.set("accent_color", Color(0.20, 0.55, 0.95))
	dice.position = Vector3(0.0, 0.95, -0.6)
	add_child(dice)

	# ── Left side: fishbowl on its own small plinth — the random walker
	var plinth_left: Node3D = SCENE_LARGE_TABLE.instantiate()
	plinth_left.set("length", 0.60)
	plinth_left.set("depth", 0.55)
	plinth_left.set("height", 0.75)
	plinth_left.set("leg_style", "post")
	plinth_left.set("top_color", Color(0.88, 0.88, 0.90))
	plinth_left.set("accent_color", Color(0.95, 0.65, 0.20))
	plinth_left.set("edge_strip", true)
	plinth_left.position = Vector3(-2.4, 0.0, -0.4)
	add_child(plinth_left)

	var bowl: Node3D = SCENE_FISHBOWL.instantiate()
	bowl.set("bowl_radius", 0.20)
	bowl.set("bowl_height", 0.26)
	bowl.set("fish_count", 1)  # single random walker, easier to read its path
	bowl.set("fish_trail_visible", true)
	bowl.set("trail_dot_count", 12)
	bowl.set("fish_color", Color(0.95, 0.65, 0.20))
	bowl.set("trail_color", Color(0.95, 0.65, 0.20, 0.45))
	bowl.set("water_color", Color(0.55, 0.78, 0.95, 0.55))
	bowl.set("accent_color", Color(0.95, 0.65, 0.20))
	bowl.position = Vector3(-2.4, 0.78, -0.4)
	add_child(bowl)

	# ── Right side: scales — the running estimator
	var plinth_right: Node3D = SCENE_LARGE_TABLE.instantiate()
	plinth_right.set("length", 0.60)
	plinth_right.set("depth", 0.55)
	plinth_right.set("height", 0.75)
	plinth_right.set("leg_style", "post")
	plinth_right.set("top_color", Color(0.88, 0.88, 0.90))
	plinth_right.set("accent_color", Color(0.85, 0.65, 0.20))
	plinth_right.set("edge_strip", true)
	plinth_right.position = Vector3(2.4, 0.0, -0.4)
	add_child(plinth_right)

	var scales: Node3D = SCENE_SCALES.instantiate()
	scales.set("beam_length", 0.40)
	scales.set("base_radius", 0.10)
	scales.set("pan_radius", 0.08)
	scales.set("left_load", scales_left_weight)
	scales.set("right_load", scales_right_weight)
	scales.set("tilt_from_loads", true)
	scales.set("base_color", Color(0.85, 0.65, 0.20))
	scales.set("accent_color", Color(0.85, 0.65, 0.20))
	scales.position = Vector3(2.4, 0.78, -0.4)
	add_child(scales)

	# ── Back wall: info_screen reporting the running mean ─────────────
	var screen: Node3D = SCENE_INFO_SCREEN.instantiate()
	screen.set("screen_width", 1.50)
	screen.set("screen_height", 0.90)
	screen.set("header_text", "MONTE CARLO")
	screen.set("text_lines", PackedStringArray([
		"samples: %d" % sample_count_so_far,
		"estimate: %.4f" % current_estimate,
		"95%% CI: ±%.4f" % (1.96 / sqrt(float(sample_count_so_far))),
		"hypothesis: %s" % ("A" if scales_left_weight > scales_right_weight else "B"),
	]))
	screen.set("text_color", Color(0.45, 0.95, 0.55))
	screen.set("header_color", Color(0.95, 0.72, 0.30))
	screen.set("text_size", 22)
	screen.position = Vector3(0.0, 2.30, -2.50)
	add_child(screen)

	# ── Whiteboard on left wall: the formal statement ────────────────
	var board: Node3D = SCENE_WHITEBOARD.instantiate()
	board.set("board_width", 1.40)
	board.set("board_height", 0.85)
	board.set("text_lines", PackedStringArray([
		"Monte Carlo estimator",
		"  μ̂ = (1/N) Σᵢ f(Xᵢ),  Xᵢ ~ p",
		"  Var(μ̂) = Var(f)/N",
		"  the walk is the sampling distribution",
	]))
	board.set("text_size", 24)
	board.position = Vector3(-2.85, 1.35, -1.5)
	board.rotation = Vector3(0.0, deg_to_rad(90.0), 0.0)  # face +X from -X wall
	add_child(board)

	# ── A lab stool at the workbench front — the observer position ───
	var stool: Node3D = SCENE_LAB_STOOL.instantiate()
	stool.set("seat_height", 0.65)
	stool.set("base_style", "five_star")
	stool.set("seat_color", Color(0.20, 0.55, 0.95))
	stool.set("accent_color", Color(0.20, 0.55, 0.95))
	stool.position = Vector3(0.6, 0.0, 0.5)
	add_child(stool)

	# ── A safety shower in the back-right corner — the re-seed ──────
	var shower: Node3D = SCENE_SAFETY_SHOWER.instantiate()
	shower.set("shower_height", 2.20)
	shower.set("pipe_orientation", "wall")
	shower.set("chain_visible", true)
	shower.set("signage_text", "RE-SEED")
	shower.set("accent_color", Color(0.15, 0.65, 0.25))
	shower.position = Vector3(2.7, 0.0, -2.6)
	shower.rotation = Vector3(0.0, deg_to_rad(-45.0), 0.0)
	add_child(shower)

	# ── The closing gesture: the catalyst pickup pedestal ────────────
	# Placed on the player's path between the workbench and the exit.
	# Walking up to it grabs the chaos-mode token; LabManager records
	# randomness as completed; the bracelet gains the chaos projectile.
	var pickup: Node3D = SCENE_CATALYST_PICKUP.instantiate()
	pickup.set("sequence_name", "randomness")
	pickup.set("label_text", "CHAOS CATALYST")
	pickup.set("orb_color", Color(0.95, 0.55, 0.20))  # chaos amber
	pickup.set("accent_color", Color(0.95, 0.55, 0.20))
	pickup.set("pedestal_color", Color(0.18, 0.18, 0.22))
	pickup.set("pulsing", true)
	pickup.set("claimed", false)
	# Position on the +Z side of the workbench (between the workbench and
	# the player spawn) so the player encounters it on the way back out.
	pickup.position = Vector3(0.0, 0.0, 1.4)
	add_child(pickup)

	_built = true
