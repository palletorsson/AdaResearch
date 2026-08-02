# dice_throw.gd
# VR Dice Throw — grab a physical dice, throw it, see the result
# Roll a 6 → 100 balls rain from the sky. Roll a 1 → 1 ball.
# Demonstrates discrete uniform distribution and expected value.
#
# QFEP: Equiprobability — each face equally likely. Fairness as symmetry.
#
# @identity
# essence: P(X=k) = 1/6 for k ∈ {1,...,6} — discrete uniform distribution
# desire: grab a die, throw it physically, and be showered with reward balls proportional to the result
# critical_parameter: balls_per_pip — multiplier that makes a 6 spectacular (96 balls) and a 1 humbling (16 balls)
# triggers: _on_dice_dropped() starts settle detection; velocity < 0.02 for 0.8s triggers _read_dice_result()
# emerges: the histogram converges to E[X]=3.5 — fairness is not felt in one throw but in the accumulation
# needs: XRToolsPickable grab + throw [has]; pip rendering on 6 faces [has]; ball rain physics [has]
# relationships: contrasts with coin_toss (6 outcomes vs 2); feeds slot_machine (compound dice)
# truth: Fairness is not a single outcome — it is the symmetry of the generating process.

extends Node3D

class_name DiceThrow

# ── Dice ─────────────────────────────────────────────────────────────────────
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

## Housing finish — "rams" (light Braun default) or "terminal" (dark console).
## Every colour derives from HangarKit.finish_palette(), so one word re-skins
## the whole body instead of a dozen hand-typed constants.
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "DT-05"


@export var dice_size: float = 0.08
@export var dice_mass: float = 0.15
@export var dice_bounce: float = 0.4
@export var dice_color: Color = Color(0.95, 0.95, 0.98)
@export var pip_color: Color = Color(0.08, 0.08, 0.12)

# ── Reward Balls ─────────────────────────────────────────────────────────────
@export var ball_radius: float = 0.025
@export var ball_drop_height: float = 3.0
@export var ball_color: Color = Color(1.0, 0.5, 0.15)
@export var balls_per_pip: int = 16  # 6 × 16 = 96 ≈ 100

# ── Table ────────────────────────────────────────────────────────────────────
@export var table_width: float = 0.8
@export var table_depth: float = 0.6
@export var table_height: float = 0.85
@export var table_color: Color = Color(0.70, 0.68, 0.64)  # family panel grey (was dark brown, off-family)
@export var felt_color: Color = Color(0.08, 0.35, 0.12)

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-02). THE KIN OF prng_crank_machine.
#
# The crank machine's axis is `disclosure`: how much a DETERMINISTIC source will
# admit about where its numbers came from. A die is the other pole of the same
# argument — the canonical FAIR source, trusted not because it explains itself
# but because of two properties you can check with your eyes before it is
# thrown: it is a CUBE (symmetric under 24 rotations, so no face is privileged)
# and it CARRIES ITS OWN SAMPLE SPACE ON ITS SKIN (six faces, 1..6, all present).
#
# But this table does not actually show you either of those things. It shows you
# a bar chart. That is a third, quite different argument — the empirical one, the
# law of large numbers, "trust it because the frequencies converged" — and it is
# the only warrant this artifact has ever offered in 19 rooms. The identity block
# says the truth is "fairness is the symmetry of the generating process", and the
# table has been arguing frequency at it the whole time.
#
#   warrant   what the table puts forward as the reason to trust the die
#
#     tally  the RECORD. Bare felt; the far-rail glass carries rolls, the running
#            mean against the theoretical 3.50, and a six-row bar chart. Trust it
#            because it came out even. THIS IS THE LEGACY LINEAGE, byte for byte.
#     word   the ASSERTION. The felt is stamped with a house legend the way a
#            casino layout is printed — FAIR / EACH FACE 1 IN 6 / NO RECORD KEPT —
#            between routed rules, and the glass keeps the answer but drops every
#            statistic. Nothing on the table lets you check anything. This is the
#            loot box, the "provably fair" badge, the certified-RNG line in a EULA.
#     net    the GEOMETRY. The die's own unfolded net printed across the play
#            field: the 1-4-1 cross, six squares, twenty-one pips, laid out so you
#            can count every face and see they are the same square six times, with
#            OPPOSITE FACES SUM TO 7 under it. The cube stands on the flat map of
#            itself. This is the warrant the identity block actually names.
#     assay  the STAMP. A gauge cradle on the felt holding a reference die between
#            two jaws under a dial, an inlaid inspection plate (SERIAL / TOLERANCE
#            / EDGE), and the certificate in the glass. Somebody with authority
#            measured this cube. You are trusting the stamp, not the die.
#
# WHAT IS DELIBERATELY NOT THE AXIS. balls_per_pip is the identity block's own
# named critical_parameter and it is NOT promoted: the reward rain only exists
# after a settled physical throw, so it is invisible to a still, and sweeping it
# would publish six identical photographs of an empty table. Same for the
# physics knobs (dice_mass, dice_bounce, ball_drop_height) — all of them are
# tempo, none of them is an argument.
#
# WHAT IS FORECLOSED. There is no `none`. A table that offers no warrant at all
# is not a quieter table, it is an unmarked one, and the die must still answer —
# `_result_label` survives at every value, exactly as the crank machine still
# emits its number at `oracle`. The absence case is `word`: a warrant made
# entirely of a claim.
#
# NOT TOUCHED, AND NOT NEGOTIABLE: the throw. The die is the same cube with the
# same pips, the same mass, the same felt friction and the same face-normal
# read at every value. `_read_dice_result` is byte for byte what it was, the
# counts still accumulate internally at every rung, and P(X=k) is still 1/6.
# This axis changes what the TABLE SAYS about the die, never the die.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — what this table offers as the reason to trust the die. Not a
## ladder: four different kinds of warrant, not four amounts of one.
## `tally` is the legacy default and the only value 19 live placements will see
## unless a map asks for another by name.
@export_enum("tally", "word", "net", "assay") var warrant: String = "tally"

## The allow-list, same spelling and same order as the @export_enum above. This
## is what `_pick_warrant` checks a map token against; an unreadable word falls
## back to the legacy default rather than to a blank table.
const WARRANTS: PackedStringArray = ["tally", "word", "net", "assay"]

## Printing on the cloth. Casino felt is marked in chalk-white, not in the body
## palette — the legend is ink on cloth, not another painted panel, so it stays
## outside HangarKit.finish_palette on purpose and reads at maximum contrast
## against felt_color at any finish.
const CHALK := Color(0.88, 0.90, 0.86)

# ── Internal ─────────────────────────────────────────────────────────────────
var _dice_body: RigidBody3D
var _dice_spawn_pos: Vector3
var _result_label: Label3D
var _stats_label: Label3D
var _total_rolls: int = 0
var _roll_counts: Array[int] = [0, 0, 0, 0, 0, 0]
var _reward_balls: Array[RigidBody3D] = []
var _is_rolling: bool = false
var _settle_timer: float = 0.0
var _last_result: int = 0
## True once _ready has built the table. apply_grid_config arriving BEFORE this
## is a value change with no geometry to answer it — _ready will use the new value.
var _built: bool = false

const PICKABLE_SCENE = preload("res://addons/godot-xr-tools/objects/pickable.tscn")
const HIGHLIGHT_RING_SCENE = preload("res://addons/godot-xr-tools/objects/highlight/highlight_ring.tscn")

# Face normal vectors for a standard die (opposing faces sum to 7)
# Face 1 = -Y, Face 2 = -X, Face 3 = +Z, Face 4 = -Z, Face 5 = +X, Face 6 = +Y
const FACE_NORMALS := [
	Vector3(0, -1, 0),  # Face 1
	Vector3(-1, 0, 0),  # Face 2
	Vector3(0, 0, 1),   # Face 3
	Vector3(0, 0, -1),  # Face 4
	Vector3(1, 0, 0),   # Face 5
	Vector3(0, 1, 0),   # Face 6
]


# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child (see
	# GridInteractablesComponent._apply_artifact_config), so the meta read has to
	# happen here, before any geometry exists. apply_grid_config() arrives
	# call_deferred — after this — and is the re-read, not the read.
	_read_meta_overrides()
	_create_table()
	_create_rim()
	_create_dice()
	_create_labels()
	_create_vr_controls()
	_create_console()

	_dice_spawn_pos = Vector3(0, table_height + dice_size, 0)
	# APPENDED LAST, and it must stay last: it prints onto a felt the table has
	# already built and it repaints a stats label the console has already seated.
	# At warrant:tally it creates no node and rewrites the stats text to the same
	# string _create_labels set, so the default scene is untouched.
	_create_warrant()
	_built = true


func _process(delta: float) -> void:
	if not _dice_body:
		return

	# Detect when dice has been thrown and settled
	if _is_rolling:
		var vel := _dice_body.linear_velocity.length()
		var ang_vel := _dice_body.angular_velocity.length()

		if vel < 0.02 and ang_vel < 0.1:
			_settle_timer += delta
			if _settle_timer > 0.8:  # Settled for 0.8 seconds
				_is_rolling = false
				_settle_timer = 0.0
				_read_dice_result()
		else:
			_settle_timer = 0.0

	# Clean up old reward balls that fell too far
	for ball in _reward_balls.duplicate():
		if ball.global_position.y < global_position.y - 5.0:
			ball.queue_free()
			_reward_balls.erase(ball)


# ═════════════════════════════════════════════════════════════════════════════
# TABLE
# ═════════════════════════════════════════════════════════════════════════════

func _create_table() -> void:
	# Table surface
	var surface := StaticBody3D.new()
	surface.name = "TableSurface"

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(table_width, 0.03, table_depth)
	col.shape = shape
	surface.add_child(col)

	# Felt top
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(table_width - 0.02, 0.005, table_depth - 0.02)
	mesh.mesh = box
	var felt_mat := StandardMaterial3D.new()
	felt_mat.albedo_color = felt_color
	felt_mat.roughness = 0.95
	mesh.material_override = felt_mat
	mesh.position.y = 0.016
	surface.add_child(mesh)

	# Table body
	var body_mesh := MeshInstance3D.new()
	var body_box := BoxMesh.new()
	body_box.size = Vector3(table_width, 0.03, table_depth)
	body_mesh.mesh = body_box
	var table_mat := StandardMaterial3D.new()
	table_mat.albedo_color = table_color
	table_mat.metallic = 0.1
	table_mat.roughness = 0.7
	body_mesh.material_override = table_mat
	surface.add_child(body_mesh)

	# Legs — near-black, the horizontal-family standard (not the body colour)
	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.09, 0.09, 0.105)
	leg_mat.metallic = 0.3
	leg_mat.roughness = 0.6
	for x_sign in [-1, 1]:
		for z_sign in [-1, 1]:
			var leg := MeshInstance3D.new()
			var leg_mesh := CylinderMesh.new()
			leg_mesh.top_radius = 0.02
			leg_mesh.bottom_radius = 0.025
			leg_mesh.height = table_height
			leg.mesh = leg_mesh
			leg.material_override = leg_mat
			leg.position = Vector3(
				x_sign * (table_width / 2.0 - 0.05),
				-table_height / 2.0,
				z_sign * (table_depth / 2.0 - 0.05)
			)
			surface.add_child(leg)

	surface.position = Vector3(0, table_height, 0)

	# Physics material for felt (absorbs bounce)
	var phys := PhysicsMaterial.new()
	phys.bounce = 0.15
	phys.friction = 0.8
	surface.physics_material_override = phys

	add_child(surface)


func _create_rim() -> void:
	# Low rim around the table to catch the dice
	var rim_height := 0.04
	var rim_thickness := 0.015
	var rim_y := table_height + 0.015 + rim_height / 2.0

	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.30, 0.11, 0.09)  # maroon rim (family accent flank), not brown
	rim_mat.metallic = 0.2
	rim_mat.roughness = 0.6

	# Four sides
	var sides := [
		# position, size
		[Vector3(0, rim_y, table_depth / 2.0), Vector3(table_width, rim_height, rim_thickness)],
		[Vector3(0, rim_y, -table_depth / 2.0), Vector3(table_width, rim_height, rim_thickness)],
		[Vector3(table_width / 2.0, rim_y, 0), Vector3(rim_thickness, rim_height, table_depth)],
		[Vector3(-table_width / 2.0, rim_y, 0), Vector3(rim_thickness, rim_height, table_depth)],
	]

	for i in range(sides.size()):
		var body := StaticBody3D.new()
		body.name = "Rim_%d" % i

		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = sides[i][1]
		col.shape = shape
		body.add_child(col)

		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = sides[i][1]
		mesh.mesh = box
		mesh.material_override = rim_mat
		body.add_child(mesh)

		body.position = sides[i][0]
		add_child(body)


# ═════════════════════════════════════════════════════════════════════════════
# DICE
# ═════════════════════════════════════════════════════════════════════════════

func _create_dice() -> void:
	# Build dice from XR Tools pickable base (same principle as grab_cube_wood.tscn)
	var pickable: XRToolsPickable = PICKABLE_SCENE.instantiate() as XRToolsPickable
	if pickable == null:
		push_error("DiceThrow: Failed to instantiate XRTools pickable scene for dice.")
		return

	_dice_body = pickable
	_dice_body.name = "Dice"
	pickable.press_to_hold = true
	pickable.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	pickable.second_hand_grab = XRToolsPickable.SecondHandGrab.SECOND
	_dice_body.mass = dice_mass
	_dice_body.gravity_scale = 1.5  # Slightly heavier feel
	_dice_body.linear_damp = 0.3
	_dice_body.angular_damp = 0.4
	_dice_body.continuous_cd = true

	var phys := PhysicsMaterial.new()
	phys.bounce = dice_bounce
	phys.friction = 0.5
	_dice_body.physics_material_override = phys

	# Collision shape
	var col := _dice_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col == null:
		col = CollisionShape3D.new()
		_dice_body.add_child(col)
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * dice_size
	col.shape = shape

	# Dice body mesh
	var mesh := MeshInstance3D.new()
	mesh.name = "DiceMesh"
	var box := BoxMesh.new()
	box.size = Vector3.ONE * dice_size
	mesh.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = dice_color
	mat.metallic = 0.05
	mat.roughness = 0.3
	mesh.material_override = mat
	_dice_body.add_child(mesh)

	# Highlight ring for hover/selection feedback
	var highlight: Node3D = HIGHLIGHT_RING_SCENE.instantiate() as Node3D
	if highlight:
		highlight.position = Vector3(0, -dice_size * 0.46, 0)
		var ring_scale: float = dice_size / 0.05 if dice_size / 0.05 > 1.0 else 1.0
		highlight.scale = Vector3.ONE * ring_scale
		_dice_body.add_child(highlight)

	# Add pips to each face
	_add_pips_to_dice()

	# Position on table
	_dice_body.position = Vector3(0, table_height + dice_size, 0)

	# Connect dropped signal if XRToolsPickable
	if _dice_body.has_signal("dropped"):
		_dice_body.dropped.connect(_on_dice_dropped)
	if _dice_body.has_signal("picked_up"):
		_dice_body.picked_up.connect(_on_dice_picked_up)

	add_child(_dice_body)


func _add_pips_to_dice() -> void:
	var half := dice_size / 2.0 + 0.001  # Slightly above surface
	var pip_r := dice_size * 0.08
	var pip_offset := dice_size * 0.22
	var pip_mat := StandardMaterial3D.new()
	pip_mat.albedo_color = pip_color
	pip_mat.roughness = 0.6

	# Standard die pip layouts per face
	# Face 1 (+Y top): 1 pip center → but standard die has 1 on top when 6 is on bottom
	# Using standard Western die: 1 opposite 6, 2 opposite 5, 3 opposite 4
	# Face normals: +Y=6, -Y=1, +X=5, -X=2, +Z=3, -Z=4

	var pip_sphere := SphereMesh.new()
	pip_sphere.radius = pip_r
	pip_sphere.height = pip_r * 2.0
	pip_sphere.radial_segments = 8
	pip_sphere.rings = 4

	# Helper: create pip at local position
	var create_pip := func(local_pos: Vector3) -> MeshInstance3D:
		var m := MeshInstance3D.new()
		m.mesh = pip_sphere
		m.material_override = pip_mat
		m.position = local_pos
		return m

	# Face 1 (-Y): 1 center pip
	_dice_body.add_child(create_pip.call(Vector3(0, -half, 0)))

	# Face 6 (+Y): 6 pips (two columns of 3)
	for col_sign in [-1, 1]:
		for row in [-1, 0, 1]:
			_dice_body.add_child(create_pip.call(Vector3(col_sign * pip_offset, half, row * pip_offset)))

	# Face 2 (-X): 2 pips (diagonal)
	_dice_body.add_child(create_pip.call(Vector3(-half, pip_offset, pip_offset)))
	_dice_body.add_child(create_pip.call(Vector3(-half, -pip_offset, -pip_offset)))

	# Face 5 (+X): 5 pips (X pattern)
	_dice_body.add_child(create_pip.call(Vector3(half, 0, 0)))
	for x_sign in [-1, 1]:
		for z_sign in [-1, 1]:
			_dice_body.add_child(create_pip.call(Vector3(half, x_sign * pip_offset, z_sign * pip_offset)))

	# Face 3 (+Z): 3 pips (diagonal)
	_dice_body.add_child(create_pip.call(Vector3(0, 0, half)))
	_dice_body.add_child(create_pip.call(Vector3(-pip_offset, pip_offset, half)))
	_dice_body.add_child(create_pip.call(Vector3(pip_offset, -pip_offset, half)))

	# Face 4 (-Z): 4 pips (square)
	for x_sign in [-1, 1]:
		for y_sign in [-1, 1]:
			_dice_body.add_child(create_pip.call(Vector3(x_sign * pip_offset, y_sign * pip_offset, -half)))


func _on_dice_dropped(_pickable) -> void:
	_is_rolling = true
	_settle_timer = 0.0


func _on_dice_picked_up(_pickable) -> void:
	# Stop any settle sampling while the player is holding the die
	_is_rolling = false
	_settle_timer = 0.0


# ═════════════════════════════════════════════════════════════════════════════
# RESULT DETECTION
# ═════════════════════════════════════════════════════════════════════════════

func _read_dice_result() -> void:
	# Determine which face is pointing UP by checking which face normal
	# is most aligned with world UP after the dice's rotation
	var dice_basis := _dice_body.global_transform.basis
	var best_face := 0
	var best_dot := -2.0

	for i in range(6):
		var world_normal: Vector3 = dice_basis * FACE_NORMALS[i]
		var dot: float = world_normal.dot(Vector3.UP)
		if dot > best_dot:
			best_dot = dot
			best_face = i

	var result := best_face + 1  # Faces are 1-indexed
	_last_result = result
	_total_rolls += 1
	_roll_counts[result - 1] += 1

	# Update display
	_result_label.text = str(result)
	_update_stats()

	# Spawn reward balls!
	var num_balls := result * balls_per_pip
	_spawn_reward_balls(num_balls)


func _spawn_reward_balls(count: int) -> void:
	var spawn_center := global_position + Vector3(0, ball_drop_height, 0)

	for i in range(count):
		var ball := RigidBody3D.new()
		ball.mass = 0.02
		ball.gravity_scale = 1.0
		ball.linear_damp = 0.1

		var phys := PhysicsMaterial.new()
		phys.bounce = 0.6
		phys.friction = 0.3
		ball.physics_material_override = phys

		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = ball_radius
		col.shape = shape
		ball.add_child(col)

		var mesh := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = ball_radius
		sphere.height = ball_radius * 2.0
		sphere.radial_segments = 12
		sphere.rings = 6
		mesh.mesh = sphere

		# Color varies slightly per ball
		var hue_shift := randf_range(-0.05, 0.05)
		var c := ball_color
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(
			clamp(c.r + hue_shift, 0, 1),
			clamp(c.g + hue_shift * 0.5, 0, 1),
			clamp(c.b - hue_shift, 0, 1)
		)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 0.3
		mat.metallic = 0.1
		mat.roughness = 0.5
		mesh.material_override = mat
		ball.add_child(mesh)

		# Random position in a cloud above
		ball.position = spawn_center + Vector3(
			randf_range(-0.4, 0.4),
			randf_range(0, 1.0),
			randf_range(-0.3, 0.3)
		)

		# Slight initial spread velocity
		ball.linear_velocity = Vector3(
			randf_range(-0.3, 0.3),
			randf_range(-0.5, 0),
			randf_range(-0.3, 0.3)
		)

		add_child(ball)
		_reward_balls.append(ball)

	# Schedule cleanup of reward balls
	var timer := get_tree().create_timer(8.0)
	timer.timeout.connect(_clean_reward_balls)


func _clean_reward_balls() -> void:
	for ball in _reward_balls.duplicate():
		if is_instance_valid(ball):
			ball.queue_free()
	_reward_balls.clear()


# ═════════════════════════════════════════════════════════════════════════════
# LABELS
# ═════════════════════════════════════════════════════════════════════════════

func _create_labels() -> void:
	# Title
	var title := Label3D.new()
	title.name = "TitleLabel"
	title.text = "DICE THROW"
	title.pixel_size = 0.002
	title.font_size = 18
	title.modulate = Color(0.9, 0.9, 0.95)
	title.position = Vector3(0, table_height + 0.35, -table_depth / 2.0 - 0.05)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Subtitle
	var sub := Label3D.new()
	sub.name = "SubLabel"
	sub.text = "Discrete Uniform Distribution"
	sub.pixel_size = 0.0014
	sub.font_size = 11
	sub.modulate = Color(0.6, 0.6, 0.7)
	sub.position = Vector3(0, table_height + 0.31, -table_depth / 2.0 - 0.05)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	# Big result number
	_result_label = Label3D.new()
	_result_label.name = "ResultLabel"
	_result_label.text = "?"
	_result_label.pixel_size = 0.005
	_result_label.font_size = 48
	_result_label.modulate = Color(1.0, 0.9, 0.3)
	_result_label.position = Vector3(table_width / 2.0 + 0.15, table_height + 0.18, 0)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_result_label)

	# Stats
	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.text = _idle_stats_text()
	_stats_label.pixel_size = 0.0012
	_stats_label.font_size = 11
	_stats_label.modulate = Color(0.8, 0.8, 0.85)
	_stats_label.position = Vector3(table_width / 2.0 + 0.15, table_height + 0.06, 0)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_stats_label)


## THE TABLE CONSOLE — the HORIZONTAL dialect of the interface ruling.
##
## The kiosk grammar (back slab, standing window, sign band overhead) answers
## a VERTICAL question: an artifact you face. A table is a horizontal
## instrument — you look DOWN at it — so its interface has to be integrated in
## that thinking: everything inset into the rail and the deck, nothing rising
## above the table silhouette. The parts translate, they do not transfer:
##
##   vertical               horizontal
##   ─────────────────────  ────────────────────────────────────────
##   back slab              broad working RAIL around the play field
##   inset window/screen    readout sunk in the FAR rail, tilted up to
##                          the player (22 deg from the deck plane)
##   sign band overhead     name INLAID FLAT in the near rail, read
##                          by looking down as you approach
##   keypad on a wedge      keypad recessed FLUSH in the near rail,
##                          face-up, pressed downward
##   maroon flank           maroon EDGE BANDING on the rail's outer lip
##   vent slats on the back vents in the APRON, seen from below
##
## Nothing here breaks the plane of a table. It reads as one piece of casino
## furniture, not as a machine standing behind a table.
func _create_console() -> void:
	var th: float = table_height
	var rail_far: float = 0.18                    # far rail — carries the readout
	var rail_near: float = 0.24                   # near rail — deeper: the player leans here
	var rail_side: float = 0.10
	var rail_th: float = 0.055
	var rail_top: float = th + 0.048
	var rail_y: float = rail_top - rail_th / 2.0
	var outer_w: float = table_width + 2.0 * rail_side
	var far_z: float = -(table_depth / 2.0 + rail_far / 2.0)
	var near_z: float = table_depth / 2.0 + rail_near / 2.0
	var z_out_far: float = -(table_depth / 2.0 + rail_far)
	var z_out_near: float = table_depth / 2.0 + rail_near
	var ring_cz: float = (z_out_far + z_out_near) / 2.0
	var ring_d: float = z_out_near - z_out_far

	var con := Node3D.new()
	con.name = "TableConsole"
	add_child(con)

	var rail_mat := StandardMaterial3D.new()
	rail_mat.albedo_color = table_color.lightened(0.18)   # kin to the table's own wood
	rail_mat.roughness = 0.6
	rail_mat.metallic = 0.15
	# ── Kit finish system (horizontal dialect keeps its own host woods) ──
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_panel: Color = pal["panel"]
	var col_accent: Color = pal["accent"]
	var ew: float = float(pal["wear"]) if finish.to_lower() == "terminal" else wear
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), ew, 0.4, 0.5)
	var maroon: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.11, 0.09), ew)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_panel)
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.04, 0.05, 0.08)
	glass_mat.roughness = 0.15
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.05, 0.08, 0.12)
	glass_mat.emission_energy_multiplier = 0.6
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	# ── the working RAIL ring — the horizontal answer to the back slab ──
	var rails := [
		[Vector3(0, rail_y, far_z), Vector3(outer_w, rail_th, rail_far)],
		[Vector3(0, rail_y, near_z), Vector3(outer_w, rail_th, rail_near)],
		[Vector3(-(table_width / 2.0 + rail_side / 2.0), rail_y, 0),
			Vector3(rail_side, rail_th, table_depth)],
		[Vector3(table_width / 2.0 + rail_side / 2.0, rail_y, 0),
			Vector3(rail_side, rail_th, table_depth)],
	]
	for r in rails:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = r[1]
		mi.mesh = bm
		mi.material_override = rail_mat
		mi.position = r[0]
		con.add_child(mi)

	# Maroon edge INLAY — a routed line just under the rail's top edge,
	# following the whole perimeter. The vertical dialect's flank is a mass
	# (a whole painted side); laid flat on furniture the same mass becomes a
	# stripe of paint, which is what it read as at 0.030 on a 0.055 rail —
	# over half the visible edge face. Banding on a table is a LINE: it
	# states the colour without claiming the surface, and it pairs with the
	# ember inlay running the rail's inner edge.
	var band_y: float = rail_top - 0.015
	var band_h: float = 0.009
	var bands := [
		[Vector3(0, band_y, z_out_far + 0.004), Vector3(outer_w, band_h, 0.008)],
		[Vector3(0, band_y, z_out_near - 0.004), Vector3(outer_w, band_h, 0.008)],
		[Vector3(-(outer_w / 2.0) + 0.004, band_y, ring_cz), Vector3(0.008, band_h, ring_d)],
		[Vector3((outer_w / 2.0) - 0.004, band_y, ring_cz), Vector3(0.008, band_h, ring_d)],
	]
	for b in bands:
		var mi2 := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		bm2.size = b[1]
		mi2.mesh = bm2
		mi2.material_override = maroon
		mi2.position = b[0]
		con.add_child(mi2)

	# ember inlay routed along the rail's inner edge
	for sz in [-1.0, 1.0]:
		var inlay := MeshInstance3D.new()
		var inlay_mesh := BoxMesh.new()
		inlay_mesh.size = Vector3(table_width + 2.0 * rail_side, 0.003, 0.006)
		inlay.mesh = inlay_mesh
		inlay.material_override = accent
		inlay.position = Vector3(0, rail_top + 0.001, sz * (table_depth / 2.0 + 0.014))
		con.add_child(inlay)

	# ── READOUT sunk into the FAR rail, 14 deg off the deck ──
	# Nearly flat: an inlaid dealer's screen, read by looking down. Steeper
	# than this and it stands up like a monitor — which is the vertical
	# dialect wearing a table.
	var tilt: float = -76.0
	var norm := Vector3(0.0, 0.970, 0.242)        # glass face normal
	var loc_up := Vector3(0.0, 0.242, -0.970)     # glass local up, in world
	var scr_w: float = 0.56
	var scr_h: float = 0.15
	var scr_c := Vector3(0.0, rail_top + 0.016, far_z + 0.004)

	var pocket := MeshInstance3D.new()
	var pocket_mesh := BoxMesh.new()
	pocket_mesh.size = Vector3(scr_w + 0.030, scr_h + 0.025, 0.014)
	pocket.mesh = pocket_mesh
	pocket.material_override = dark
	pocket.position = scr_c - Vector3(0, 0.005, 0.003)
	pocket.rotation_degrees = Vector3(tilt, 0, 0)
	con.add_child(pocket)

	var glass := MeshInstance3D.new()
	var glass_mesh := BoxMesh.new()
	glass_mesh.size = Vector3(scr_w, scr_h, 0.006)
	glass.mesh = glass_mesh
	glass.material_override = glass_mat
	glass.position = scr_c
	glass.rotation_degrees = Vector3(tilt, 0, 0)
	con.add_child(glass)

	var scr_stripe := MeshInstance3D.new()
	var scr_stripe_mesh := BoxMesh.new()
	scr_stripe_mesh.size = Vector3(scr_w + 0.030, 0.004, 0.005)
	scr_stripe.mesh = scr_stripe_mesh
	scr_stripe.material_override = accent
	scr_stripe.position = scr_c + loc_up * (scr_h / 2.0 + 0.005) + norm * 0.003
	scr_stripe.rotation_degrees = Vector3(tilt, 0, 0)
	con.add_child(scr_stripe)

	# the live figures ride the inlaid glass (housing changes, text tech stays)
	if _result_label != null and is_instance_valid(_result_label):
		_result_label.pixel_size = 0.0018
		_result_label.position = scr_c + Vector3(-0.21, 0, 0) + norm * 0.006
		_result_label.rotation_degrees = Vector3(tilt, 0, 0)
	if _stats_label != null and is_instance_valid(_stats_label):
		_stats_label.pixel_size = 0.0010
		_stats_label.position = scr_c + Vector3(-0.13, 0, 0) + loc_up * 0.060 + norm * 0.006
		_stats_label.rotation_degrees = Vector3(tilt, 0, 0)

	# ── NEAR rail: keypad recessed flush (left) + name INLAID FLAT (right) ──
	var pad_pocket := MeshInstance3D.new()
	var pad_pocket_mesh := BoxMesh.new()
	pad_pocket_mesh.size = Vector3(0.28, 0.200, 0.012)
	pad_pocket.mesh = pad_pocket_mesh
	pad_pocket.material_override = dark
	pad_pocket.position = Vector3(-0.22, rail_top + 0.008, table_depth / 2.0 + 0.120)
	pad_pocket.rotation_degrees = Vector3(-80, 0, 0)
	con.add_child(pad_pocket)

	# retire the floating title/sub — the rail inlay owns the name now
	var t: Node = get_node_or_null("TitleLabel")
	if t != null:
		t.queue_free()
	var sub: Node = get_node_or_null("SubLabel")
	if sub != null:
		sub.queue_free()

	# the name is read by looking down, the way a table is read
	var name_tag: Node3D = BakedText.make_tag(
		"DICE THROW", Color(0.93, 0.94, 0.97), 0.030,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if name_tag:
		name_tag.position = Vector3(0.20, rail_top + 0.002, near_z - 0.030)
		name_tag.rotation_degrees = Vector3(-90, 0, 0)
		con.add_child(name_tag)
	var name_sub: Node3D = BakedText.make_tag(
		"DISCRETE UNIFORM DISTRIBUTION", Color(0.58, 0.50, 0.44), 0.013,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if name_sub:
		name_sub.position = Vector3(0.20, rail_top + 0.002, near_z + 0.010)
		name_sub.rotation_degrees = Vector3(-90, 0, 0)
		con.add_child(name_sub)

	# ── APRON under the rail, vents where a table hides them ──
	var apron := MeshInstance3D.new()
	var apron_mesh := BoxMesh.new()
	apron_mesh.size = Vector3(outer_w - 0.08, 0.08, ring_d - 0.08)
	apron.mesh = apron_mesh
	apron.material_override = dark
	apron.position = Vector3(0, th - 0.045, ring_cz)
	con.add_child(apron)
	for gi in range(5):
		var slat := MeshInstance3D.new()
		var slat_mesh := BoxMesh.new()
		slat_mesh.size = Vector3(0.30, 0.007, 0.008)
		slat.mesh = slat_mesh
		slat.material_override = rail_mat
		slat.position = Vector3(0.0, th - 0.072 + float(gi) * 0.013,
			ring_cz + (ring_d - 0.08) / 2.0 + 0.002)
		con.add_child(slat)

	# ── Kit details, HORIZONTAL dialect: nothing climbs off the deck ────
	con.add_child(HangarKit.bolts(
		Vector3(-outer_w / 2.0 + 0.10, rail_y, z_out_near - 0.006),
		Vector3(outer_w / 2.0 - 0.10, rail_y, z_out_near - 0.006),
		9, 0.008, steel))
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.11, 0.028),
		col_accent.lightened(0.25))
	if code:
		code.position = Vector3(-0.40, rail_top + 0.002, near_z + 0.055)
		code.rotation_degrees = Vector3(-90, 0, 0)   # read by looking down
		con.add_child(code)
	# (no grime band here: the apron is already near-black, so an opaque
	#  dirt shadow on it reads as a slab hanging under the table.)


func _update_stats() -> void:
	# warrant != tally — the record is precisely what this table is not offering,
	# so the bar chart never comes back over the rung's own evidence. The counts
	# in _roll_counts still accumulate; they are simply not published here.
	if warrant != "tally":
		_stats_label.text = _idle_stats_text()
		return
	if _total_rolls == 0:
		return

	var mean := 0.0
	for i in range(6):
		mean += float(i + 1) * float(_roll_counts[i])
	mean /= float(_total_rolls)

	var lines := "Rolls: %d\nmean: %.2f\n(theory: 3.50)\n\n" % [_total_rolls, mean]
	for i in range(6):
		var bar := ""
		var pct := float(_roll_counts[i]) / float(_total_rolls) * 100.0
		var bar_len := int(pct / 5.0)
		for j in range(bar_len):
			bar += "|"
		lines += "%d: %s %.0f%%\n" % [i + 1, bar, pct]

	_stats_label.text = lines


# ═════════════════════════════════════════════════════════════════════════════
# VR CONTROLS
# ═════════════════════════════════════════════════════════════════════════════

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("", [
		[
			{"type": "button", "label": "RESET"},
			{"type": "button", "label": "CLEAR"},
		],
	], true)  # frameless — the rail pocket is the faceplate
	# recessed flush into the near rail, face-up — a table's controls are
	# pressed downward, not faced (see _create_console for the ruling)
	panel.position = Vector3(-0.22, table_height + 0.068, table_depth / 2.0 + 0.122)
	panel.rotation_degrees = Vector3(-80, 0, 0)
	panel.scale = Vector3(0.78, 0.78, 0.78)
	add_child(panel)

	# RESET (Btn_0)
	var reset_btn: Node = panel.find_child("Btn_0", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _reset_dice())

	# CLEAR (Btn_1)
	var clear_btn: Node = panel.find_child("Btn_1", true, false)
	if clear_btn:
		var area = clear_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _reset_stats())


func _reset_dice() -> void:
	if not _dice_body:
		return

	_dice_body.freeze = true
	_dice_body.linear_velocity = Vector3.ZERO
	_dice_body.angular_velocity = Vector3.ZERO
	_dice_body.global_position = global_position + _dice_spawn_pos
	_dice_body.global_rotation = Vector3.ZERO
	_dice_body.set_deferred("freeze", false)

	_is_rolling = false
	_settle_timer = 0.0
	_result_label.text = "?"
	_clean_reward_balls()


func _reset_stats() -> void:
	_total_rolls = 0
	_roll_counts.fill(0)
	_result_label.text = "?"
	_stats_label.text = _idle_stats_text()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## LATENT BUG PAID (2026-08-02): this was `pass`, exactly as
## prng_crank_machine's was before its promotion. Every `#token: value` a map put
## on a dice_throw placement was parsed, printed to the log by
## GridInteractablesComponent and stashed as metadata — then silently discarded,
## because nothing on this artifact ever read the metadata back. The registry now
## derives its DNA block from this file, so a token that does nothing would be a
## declaration that lies. It reads its metadata now.
##
## Ordering: the grid sets config_* metadata BEFORE add_child and calls this
## method call_deferred, i.e. after _ready has already built the table. So _ready
## does the real read; this is the re-read for direct callers (packaging, tools,
## tests) and the path that makes a late value actually move the printing.
##
## THE SECOND EARLY RETURN IS LOAD-BEARING. curation_station.gd calls
## apply_grid_config({"emissive": false}) on every artifact it curates, one line
## after _hide_labels() has darkened the modulate and hidden the back-plates.
## That dict carries no warrant key. An unconditional rebuild there would repaint
## the stats label and re-add printing over framing that is never re-applied.
## Unchanged warrant means touch nothing and say nothing.
func apply_grid_config(config: Dictionary) -> void:
	var before: String = warrant

	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()

	if _built:
		if warrant == before:
			return                  # curation_station's {"emissive": false} lands here
		_rebuild_warrant()
		print("[DiceThrow] Config applied — warrant=%s" % [warrant])


func _read_meta_overrides() -> void:
	if has_meta("config_warrant"):
		# Fallback is the LEGACY value, not the current one: an unreadable word
		# must not quietly strip the record from a table 19 rooms expect to keep it.
		warrant = _pick_warrant(str(get_meta("config_warrant")))


## The reader for a warrant token — lower, strip, and fall back on anything
## unrecognised. Same rule and same shape as PrngCrankMachine._pick_axis; the two
## machines are the family's pair on this subject and must not drift into two
## habits for reading one map token.
func _pick_warrant(raw: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	if WARRANTS.has(v):
		return v
	if v != "":
		push_warning("dice_throw: unknown warrant '%s' — keeping 'tally'" % v)
	return "tally"


# ═════════════════════════════════════════════════════════════════════════════
# WARRANT — what the table offers as the reason to trust the die
#
# Everything below is MESH ONLY. Not one node here carries a CollisionShape3D,
# so the die falls through the same empty air onto the same felt at every value
# and the physics the identity block is about is untouched (R5). The printing
# sits 2-5 mm proud of the felt top and nothing stands higher than the die
# already does, so the artifact's AABB is identical at all four values — the
# sweep frames every tile the same way and no crop shift does the work.
# ═════════════════════════════════════════════════════════════════════════════

## Felt top in artifact-local Y. The table body is a StaticBody3D at
## y = table_height carrying the felt mesh at local y = 0.016, 0.005 thick — so
## the cloth surface is here, and every printed layer stacks upward from it.
func _felt_y() -> float:
	return table_height + 0.016 + 0.0025


## The line the far-rail glass carries under the numeral. At `tally` this returns
## the legacy string CHARACTER FOR CHARACTER, which is what keeps _create_labels
## and _reset_stats byte-identical on the default path.
func _idle_stats_text() -> String:
	match warrant:
		"word":
			return "FAIR\n\nthe house\nsays so"
		"net":
			return "6 FACES\n1 CUBE\n24 ROTATIONS\n\nopposite faces\nsum to 7"
		"assay":
			return "SERIAL DT-05-1148\nTOL +/-0.0005 IN\nEDGE 0.750 IN\n\nINSPECTED\nAND STAMPED"
		_:
			return "Rolls: 0\n\nGrab & throw\nthe dice!"


## THE MATCH BLOCK. Appended last in the file and called last in _ready, so
## nothing above it moves. `tally` builds nothing: the bare felt and the running
## bar chart ARE the shipped table.
func _create_warrant() -> void:
	match warrant:
		"word":
			_warrant_word(_warrant_root())
		"net":
			_warrant_net(_warrant_root())
		"assay":
			_warrant_assay(_warrant_root())
		_:
			pass
	if _stats_label != null and is_instance_valid(_stats_label):
		if _total_rolls > 0:
			_update_stats()
		else:
			_stats_label.text = _idle_stats_text()


## Frees only the printing and lays it down again. A full teardown is wrong here:
## the die is an XRToolsPickable a hand may be holding and the console has already
## re-seated the labels, so a rebuild that freed everything would drop a held
## object on the floor to change a legend on the cloth.
func _rebuild_warrant() -> void:
	var old: Node = get_node_or_null("Warrant")
	if old != null:
		remove_child(old)           # leaves the tree synchronously — no double-render
		old.queue_free()
	_create_warrant()


func _warrant_root() -> Node3D:
	var n := Node3D.new()
	n.name = "Warrant"
	add_child(n)
	return n


## Chalk printing laid flat on the cloth, face up. Rotated -90 about X for the
## same reason the console's name tag is: this is read by looking DOWN, the way a
## table is read, not by facing it.
func _print_on_felt(host: Node3D, text: String, size: Vector2,
		x: float, z: float, lift: float = 0.003) -> void:
	var q: MeshInstance3D = HangarKit.stencil(text, size, CHALK)
	if q == null:
		return
	q.position = Vector3(x, _felt_y() + lift, z)
	q.rotation_degrees = Vector3(-90, 0, 0)
	host.add_child(q)


## A routed rule in the cloth — a thin chalk line, the printed layout's own ruling.
func _rule_on_felt(host: Node3D, width: float, x: float, z: float) -> void:
	var mat: StandardMaterial3D = HangarKit.painted_metal(CHALK, 0.0, 0.0, 0.85)
	host.add_child(HangarKit.box(
		Vector3(x, _felt_y() + 0.0015, z), Vector3(width, 0.002, 0.005), mat))


# ── word ─────────────────────────────────────────────────────────────────────
## The assertion. House legend printed on the cloth between two rules, the way a
## casino layout states its own terms, and nothing anywhere that lets you audit
## it. The largest word on the table is the claim.
func _warrant_word(host: Node3D) -> void:
	_rule_on_felt(host, 0.62, 0.0, -0.205)
	_print_on_felt(host, "EACH FACE 1 IN 6", Vector2(0.56, 0.062), 0.0, -0.145)
	_rule_on_felt(host, 0.62, 0.0, -0.085)
	# the claim itself, large, in the half of the cloth nearest the player
	_print_on_felt(host, "FAIR", Vector2(0.30, 0.130), 0.0, 0.150, 0.004)
	_print_on_felt(host, "NO RECORD KEPT", Vector2(0.34, 0.030), 0.0, 0.248)


# ── net ──────────────────────────────────────────────────────────────────────
## The geometry. The 1-4-1 cross: the band 2-3-5-4 across the cloth with 1 folded
## up off face 3 and 6 folded down off it. Opposite faces land two apart in the
## band (2/5, 3/4) and above/below (1/6), so the printing is a REAL net of this
## die and not a decorative row of squares — you can fold it in your head and get
## the cube that is standing on it.
const NET_PITCH := 0.128
const NET_FACE := 0.118

func _warrant_net(host: Node3D) -> void:
	var face_mat: StandardMaterial3D = HangarKit.painted_metal(CHALK, 0.0, 0.0, 0.80)
	var y: float = _felt_y()
	# band of four, left to right
	var band := [2, 3, 5, 4]
	for i in range(4):
		var cx: float = (float(i) - 1.5) * NET_PITCH
		_net_face(host, face_mat, int(band[i]), cx, 0.0, y)
	# the two that fold off face 3 (band index 1)
	var fold_x: float = -0.5 * NET_PITCH
	_net_face(host, face_mat, 1, fold_x, -NET_PITCH, y)
	_net_face(host, face_mat, 6, fold_x, NET_PITCH, y)
	_print_on_felt(host, "OPPOSITE FACES SUM TO 7", Vector2(0.44, 0.036), 0.0, 0.240)


## One printed face: a chalk square with its true pip pattern in the die's own
## pip colour. Pip layout is the standard Western die — corners, edge midpoints,
## centre — at 0.30 of the face from its middle.
func _net_face(host: Node3D, face_mat: StandardMaterial3D, pips: int,
		cx: float, cz: float, y: float) -> void:
	host.add_child(HangarKit.box(
		Vector3(cx, y + 0.002, cz), Vector3(NET_FACE, 0.002, NET_FACE), face_mat))
	var o: float = NET_FACE * 0.30
	var spots: Array = []
	match pips:
		1:
			spots = [Vector2(0, 0)]
		2:
			spots = [Vector2(-o, o), Vector2(o, -o)]
		3:
			spots = [Vector2(-o, o), Vector2(0, 0), Vector2(o, -o)]
		4:
			spots = [Vector2(-o, -o), Vector2(-o, o), Vector2(o, -o), Vector2(o, o)]
		5:
			spots = [Vector2(-o, -o), Vector2(-o, o), Vector2(0, 0),
				Vector2(o, -o), Vector2(o, o)]
		6:
			spots = [Vector2(-o, -o), Vector2(-o, 0), Vector2(-o, o),
				Vector2(o, -o), Vector2(o, 0), Vector2(o, o)]
	var ink: StandardMaterial3D = HangarKit.painted_metal(pip_color, 0.0, 0.0, 0.70)
	for s in spots:
		var p: Vector2 = s
		host.add_child(HangarKit.box(
			Vector3(cx + p.x, y + 0.0035, cz + p.y),
			Vector3(NET_FACE * 0.15, 0.002, NET_FACE * 0.15), ink))


# ── assay ────────────────────────────────────────────────────────────────────
## The stamp. A gauge cradle standing on the cloth with a reference die clamped
## between its jaws under a dial, and the inspection record inlaid flat beside
## it. The warrant here is institutional: this cube was measured by someone whose
## measurement you are agreeing to accept.
func _warrant_assay(host: Node3D) -> void:
	var y: float = _felt_y()
	var steel: StandardMaterial3D = HangarKit.worn_metal(Color(0.62, 0.63, 0.66))
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), wear, 0.4, 0.5)
	var gx: float = 0.215
	var gz: float = -0.145

	# bed
	host.add_child(HangarKit.box(
		Vector3(gx, y + 0.009, gz), Vector3(0.170, 0.018, 0.062), dark))
	# the two jaws the reference cube is held between — the caliper read
	for sx in [-1.0, 1.0]:
		host.add_child(HangarKit.box(
			Vector3(gx + float(sx) * 0.052, y + 0.040, gz),
			Vector3(0.011, 0.044, 0.062), steel))
	# the reference die, clamped and pipped so it reads as a die and not a block
	var ivory: StandardMaterial3D = HangarKit.painted_metal(Color(0.93, 0.93, 0.95), 0.0, 0.0, 0.35)
	host.add_child(HangarKit.box(
		Vector3(gx, y + 0.042, gz), Vector3(0.052, 0.052, 0.052), ivory))
	var ink: StandardMaterial3D = HangarKit.painted_metal(pip_color, 0.0, 0.0, 0.70)
	for s in [Vector2(-0.014, -0.014), Vector2(-0.014, 0.014), Vector2(0, 0),
			Vector2(0.014, -0.014), Vector2(0.014, 0.014)]:
		var p: Vector2 = s
		host.add_child(HangarKit.box(
			Vector3(gx + p.x, y + 0.0685, gz + p.y),
			Vector3(0.009, 0.002, 0.009), ink))
	# the dial, lit — the only emissive thing the gauge has, and the piece that
	# says a reading was TAKEN rather than merely that a cube was held
	host.add_child(HangarKit.box(
		Vector3(gx, y + 0.030, gz - 0.042), Vector3(0.040, 0.040, 0.008),
		HangarKit.emissive(Color(0.90, 0.92, 0.88), 1.4)))
	host.add_child(HangarKit.box(
		Vector3(gx, y + 0.030, gz - 0.047), Vector3(0.046, 0.046, 0.004), steel))

	# the record, inlaid flat in the cloth — an opaque printed patch, not chalk:
	# a plate screwed to the table, which is a different kind of statement from
	# something painted on the cloth by the house
	var plate: MeshInstance3D = HangarKit.brand_patch(
		"SERIAL DT-05-1148   TOL +/-0.0005 IN",
		Vector2(0.360, 0.052), Color(0.14, 0.15, 0.17), CHALK)
	if plate:
		plate.position = Vector3(-0.150, y + 0.003, -0.185)
		plate.rotation_degrees = Vector3(-90, 0, 0)
		host.add_child(plate)
	_print_on_felt(host, "INSPECTED AND STAMPED 1148", Vector2(0.40, 0.032), 0.0, 0.240)
