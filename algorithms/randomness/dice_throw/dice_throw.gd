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
@export var table_color: Color = Color(0.15, 0.12, 0.1)
@export var felt_color: Color = Color(0.08, 0.35, 0.12)

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
	_create_table()
	_create_rim()
	_create_dice()
	_create_labels()
	_create_vr_controls()
	_create_cabinet()

	_dice_spawn_pos = Vector3(0, table_height + dice_size, 0)


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

	# Legs
	for x_sign in [-1, 1]:
		for z_sign in [-1, 1]:
			var leg := MeshInstance3D.new()
			var leg_mesh := CylinderMesh.new()
			leg_mesh.top_radius = 0.02
			leg_mesh.bottom_radius = 0.025
			leg_mesh.height = table_height
			leg.mesh = leg_mesh
			leg.material_override = table_mat
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
	rim_mat.albedo_color = Color(0.25, 0.18, 0.12)
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
	_stats_label.text = "Rolls: 0\n\nGrab & throw\nthe dice!"
	_stats_label.pixel_size = 0.0012
	_stats_label.font_size = 11
	_stats_label.modulate = Color(0.8, 0.8, 0.85)
	_stats_label.position = Vector3(table_width / 2.0 + 0.15, table_height + 0.06, 0)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_stats_label)


## THE CABINET — propagation no. 5: the croupier table. The felt keeps its
## table; a BACKBOARD rises at the rear edge carrying the sign band and an
## inset TALLY screen (the live result "?" and stats Label3Ds re-home onto
## the glass — Label3D stays, the housing changes); RESET/CLEAR seats on an
## apron wedge at the front edge; maroon trims, vents, apron skirt. One body.
func _create_cabinet() -> void:
	var th: float = table_height
	var bb_w: float = table_width + 0.10
	var bb_z: float = -table_depth / 2.0 - 0.065
	var bb_bot: float = th - 0.10
	var bb_top: float = th + 0.72
	var cap_h: float = 0.10
	var face_z: float = bb_z + 0.042

	var cab := Node3D.new()
	cab.name = "Cabinet"
	add_child(cab)

	var shell := StandardMaterial3D.new()
	shell.albedo_color = Color(0.58, 0.60, 0.63)
	shell.roughness = 0.5
	shell.metallic = 0.25
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.07, 0.075, 0.09)
	dark.roughness = 0.45
	dark.metallic = 0.4
	var maroon := StandardMaterial3D.new()
	maroon.albedo_color = Color(0.30, 0.11, 0.09)
	maroon.roughness = 0.55
	maroon.metallic = 0.2
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.04, 0.05, 0.08)
	glass_mat.roughness = 0.15
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.05, 0.08, 0.12)
	glass_mat.emission_energy_multiplier = 0.6
	var accent := StandardMaterial3D.new()
	accent.albedo_color = Color(0.86, 0.30, 0.10)
	accent.emission_enabled = true
	accent.emission = Color(0.86, 0.30, 0.10)
	accent.emission_energy_multiplier = 2.2

	# backboard
	var bb := MeshInstance3D.new()
	var bb_mesh := BoxMesh.new()
	bb_mesh.size = Vector3(bb_w, bb_top - bb_bot, 0.07)
	bb.mesh = bb_mesh
	bb.material_override = shell
	bb.position = Vector3(0.0, (bb_bot + bb_top) / 2.0, bb_z)
	cab.add_child(bb)
	for sx in [-1.0, 1.0]:
		var trim := MeshInstance3D.new()
		var trim_mesh := BoxMesh.new()
		trim_mesh.size = Vector3(0.05, bb_top - bb_bot, 0.09)
		trim.mesh = trim_mesh
		trim.material_override = maroon
		trim.position = Vector3(sx * (bb_w / 2.0 + 0.025), (bb_bot + bb_top) / 2.0, bb_z)
		cab.add_child(trim)

	# inset TALLY screen — result + stats re-home here
	var scr_w: float = bb_w - 0.22
	var scr_h: float = 0.42
	var scr_y: float = th + 0.30
	var pocket := MeshInstance3D.new()
	var pocket_mesh := BoxMesh.new()
	pocket_mesh.size = Vector3(scr_w + 0.02, scr_h + 0.04, 0.014)
	pocket.mesh = pocket_mesh
	pocket.material_override = dark
	pocket.position = Vector3(0.0, scr_y, face_z + 0.002)
	cab.add_child(pocket)
	var glass := MeshInstance3D.new()
	var glass_mesh := BoxMesh.new()
	glass_mesh.size = Vector3(scr_w, scr_h, 0.006)
	glass.mesh = glass_mesh
	glass.material_override = glass_mat
	glass.position = Vector3(0.0, scr_y - 0.006, face_z + 0.010)
	cab.add_child(glass)
	var head_tag: Node3D = BakedText.make_tag(
		"TALLY", Color(0.92, 0.93, 0.97), 0.020,
		Color(0.055, 0.06, 0.075), true, Color(0.86, 0.30, 0.10))
	if head_tag:
		head_tag.position = Vector3(0.0, scr_y + scr_h / 2.0 + 0.012, face_z + 0.014)
		cab.add_child(head_tag)
	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(scr_w + 0.02, 0.005, 0.004)
	stripe.mesh = stripe_mesh
	stripe.material_override = accent
	stripe.position = Vector3(0.0, scr_y + scr_h / 2.0 - 0.002, face_z + 0.012)
	cab.add_child(stripe)

	# retire floating title/sub (cap sign owns the name); re-home live labels
	var t: Node = get_node_or_null("TitleLabel")
	if t != null:
		t.queue_free()
	var sub: Node = get_node_or_null("SubLabel")
	if sub != null:
		sub.queue_free()
	if _result_label != null and is_instance_valid(_result_label):
		_result_label.position = Vector3(-scr_w / 2.0 + 0.11, scr_y + 0.10, face_z + 0.016)
	if _stats_label != null and is_instance_valid(_stats_label):
		_stats_label.position = Vector3(-scr_w / 2.0 + 0.20, scr_y + 0.06, face_z + 0.016)

	# apron wedge for the pad (front edge)
	var wedge := _make_wedge(0.22, 0.12, 0.058, 0.016, dark)
	wedge.position = Vector3(0.0, th + 0.035, table_depth / 2.0 + 0.030)
	wedge.rotation_degrees = Vector3(0, 180, 0)
	cab.add_child(wedge)

	# vent slats at backboard base
	for gi in range(5):
		var slat := MeshInstance3D.new()
		var slat_mesh := BoxMesh.new()
		slat_mesh.size = Vector3(0.34, 0.008, 0.010)
		slat.mesh = slat_mesh
		slat.material_override = dark
		slat.position = Vector3(0.0, bb_bot + 0.03 + float(gi) * 0.020, face_z + 0.002)
		cab.add_child(slat)

	# sign cap
	var cap := MeshInstance3D.new()
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(bb_w + 0.10, cap_h, 0.11)
	cap.mesh = cap_mesh
	cap.material_override = shell
	cap.position = Vector3(0.0, bb_top + cap_h / 2.0, bb_z)
	cab.add_child(cap)
	var cap_stripe := MeshInstance3D.new()
	var cap_stripe_mesh := BoxMesh.new()
	cap_stripe_mesh.size = Vector3(bb_w + 0.10, 0.006, 0.004)
	cap_stripe.mesh = cap_stripe_mesh
	cap_stripe.material_override = accent
	cap_stripe.position = Vector3(0.0, bb_top + 0.004, bb_z + 0.058)
	cab.add_child(cap_stripe)
	var sign := MeshInstance3D.new()
	var sign_mesh := BoxMesh.new()
	sign_mesh.size = Vector3(bb_w - 0.02, 0.066, 0.012)
	sign.mesh = sign_mesh
	sign.material_override = dark
	sign.position = Vector3(0.0, bb_top + cap_h / 2.0, bb_z + 0.056)
	cab.add_child(sign)
	var sign_title: Node3D = BakedText.make_tag(
		"DICE THROW", Color(0.93, 0.94, 0.97), 0.030,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_title:
		sign_title.position = Vector3(0.0, bb_top + cap_h / 2.0 + 0.012, bb_z + 0.064)
		cab.add_child(sign_title)
	var sign_sub: Node3D = BakedText.make_tag(
		"DISCRETE UNIFORM DISTRIBUTION", Color(0.55, 0.58, 0.66), 0.014,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_sub:
		sign_sub.position = Vector3(0.0, bb_top + cap_h / 2.0 - 0.018, bb_z + 0.064)
		cab.add_child(sign_sub)

	# apron skirt under the table lip
	var skirt := MeshInstance3D.new()
	var skirt_mesh := BoxMesh.new()
	skirt_mesh.size = Vector3(table_width + 0.06, 0.09, table_depth + 0.06)
	skirt.mesh = skirt_mesh
	skirt.material_override = dark
	skirt.position = Vector3(0.0, th - 0.075, 0.0)
	cab.add_child(skirt)


## Right-triangle prism shoulder (shared cabinet grammar — see galton_board).
func _make_wedge(w: float, h: float, d_bottom: float, d_top: float, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0: float = -w / 2.0
	var x1: float = w / 2.0
	var y0: float = -h / 2.0
	var y1: float = h / 2.0
	var bbl := Vector3(x0, y0, 0.0)
	var bbr := Vector3(x1, y0, 0.0)
	var btl := Vector3(x0, y1, 0.0)
	var btr := Vector3(x1, y1, 0.0)
	var fbl := Vector3(x0, y0, d_bottom)
	var fbr := Vector3(x1, y0, d_bottom)
	var ftl := Vector3(x0, y1, d_top)
	var ftr := Vector3(x1, y1, d_top)
	var faces := [
		[fbl, fbr, ftr, ftl],
		[bbr, bbl, btl, btr],
		[bbl, fbl, ftl, btl],
		[fbr, bbr, btr, ftr],
		[btl, ftl, ftr, btr],
		[bbl, bbr, fbr, fbl],
	]
	for f in faces:
		st.add_vertex(f[0]); st.add_vertex(f[1]); st.add_vertex(f[2])
		st.add_vertex(f[0]); st.add_vertex(f[2]); st.add_vertex(f[3])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


func _update_stats() -> void:
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
	])
	# seated on the table-apron wedge (all-in-one body)
	panel.position = Vector3(0, table_height + 0.035, table_depth / 2.0 + 0.085)
	panel.rotation_degrees = Vector3(-18, 0, 0)
	panel.scale = Vector3(0.8, 0.8, 0.8)
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
	_stats_label.text = "Rolls: 0\n\nGrab & throw\nthe dice!"

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
