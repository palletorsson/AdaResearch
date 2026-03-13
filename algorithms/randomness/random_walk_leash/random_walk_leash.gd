# random_walk_leash.gd
# Random Walk Leash — hold a glowing orb on a string.
# The orb tugs in random directions, pulling against your grip.
# Feel the random walk through your VR hand.
#
# QFEP: Embodied randomness — the random walk isn't watched, it's felt.
# Your arm becomes the accumulator of stochastic impulses.

extends Node3D

class_name RandomWalkLeash

# ── Orb ─────────────────────────────────────────────────────────────────────
@export var orb_radius: float = 0.05
@export var orb_mass: float = 0.15
@export var orb_color: Color = Color(0.3, 0.8, 1.0)
@export var orb_emission_energy: float = 1.5

# ── Leash ───────────────────────────────────────────────────────────────────
@export var leash_length: float = 0.4
@export var leash_segments: int = 8
@export var leash_color: Color = Color(0.6, 0.7, 0.9, 0.7)

# ── Random Walk ─────────────────────────────────────────────────────────────
@export var impulse_interval: float = 0.3   ## seconds between tugs
@export var impulse_strength: float = 0.04  ## force per tug
@export var walk_bias: float = 0.0          ## 0 = unbiased, >0 biases upward

# ── Pedestal ────────────────────────────────────────────────────────────────
@export var pedestal_height: float = 0.9
@export var pedestal_color: Color = Color(0.1, 0.1, 0.12)

# ── Internal ────────────────────────────────────────────────────────────────
var _orb_body: RigidBody3D
var _orb_spawn_pos: Vector3
var _leash_line: MeshInstance3D
var _leash_material: StandardMaterial3D
var _impulse_timer: float = 0.0
var _total_tugs: int = 0
var _displacement_sum: Vector3 = Vector3.ZERO
var _is_held: bool = false

var _trail_points: Array[Vector3] = []
var _trail_mesh: MeshInstance3D
var _trail_material: StandardMaterial3D
const MAX_TRAIL: int = 200

var _stats_label: Label3D
var _direction_label: Label3D

const PICKABLE_SCENE = preload("res://addons/godot-xr-tools/objects/pickable.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const HIGHLIGHT_RING_SCENE = preload("res://addons/godot-xr-tools/objects/highlight/highlight_ring.tscn")


# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_create_pedestal()
	_create_orb()
	_create_leash_visual()
	_create_trail()
	_create_labels()
	_create_vr_controls()
	_orb_spawn_pos = Vector3(0, pedestal_height + 0.15, 0)


func _physics_process(delta: float) -> void:
	if not _orb_body:
		return

	# Apply random impulses
	_impulse_timer += delta
	if _impulse_timer >= impulse_interval:
		_impulse_timer = 0.0
		_apply_random_impulse()

	# Enforce leash constraint when held
	if _is_held:
		_enforce_leash()

	# Update visuals
	_update_leash_visual()
	_update_trail()
	_update_display()


# ═════════════════════════════════════════════════════════════════════════════
# PEDESTAL
# ═════════════════════════════════════════════════════════════════════════════

func _create_pedestal() -> void:
	var body := StaticBody3D.new()
	body.name = "Pedestal"

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.12
	shape.height = pedestal_height
	col.shape = shape
	body.add_child(col)

	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.14
	cyl.height = pedestal_height
	cyl.radial_segments = 16
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pedestal_color
	mat.metallic = 0.3
	mat.roughness = 0.6
	mesh.material_override = mat
	body.add_child(mesh)

	body.position = Vector3(0, pedestal_height / 2.0, 0)
	add_child(body)

	# Rest cradle on top
	var cradle := MeshInstance3D.new()
	var cradle_mesh := TorusMesh.new()
	cradle_mesh.inner_radius = orb_radius * 0.7
	cradle_mesh.outer_radius = orb_radius * 1.1
	cradle_mesh.rings = 16
	cradle_mesh.ring_segments = 12
	cradle.mesh = cradle_mesh
	var cradle_mat := StandardMaterial3D.new()
	cradle_mat.albedo_color = Color(0.25, 0.25, 0.3)
	cradle_mat.metallic = 0.6
	cradle_mat.roughness = 0.4
	cradle.material_override = cradle_mat
	cradle.position = Vector3(0, pedestal_height + 0.01, 0)
	cradle.rotation.x = PI / 2.0
	add_child(cradle)


# ═════════════════════════════════════════════════════════════════════════════
# ORB (VR grabbable)
# ═════════════════════════════════════════════════════════════════════════════

func _create_orb() -> void:
	var pickable: XRToolsPickable = PICKABLE_SCENE.instantiate() as XRToolsPickable
	if pickable == null:
		push_error("RandomWalkLeash: Failed to instantiate XRTools pickable.")
		return

	_orb_body = pickable
	_orb_body.name = "Orb"
	pickable.press_to_hold = true
	pickable.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	_orb_body.mass = orb_mass
	_orb_body.gravity_scale = 0.3  # Light feel — mostly driven by random impulses
	_orb_body.linear_damp = 1.5
	_orb_body.angular_damp = 2.0
	_orb_body.continuous_cd = true

	# Collision
	var col := _orb_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col == null:
		col = CollisionShape3D.new()
		_orb_body.add_child(col)
	var shape := SphereShape3D.new()
	shape.radius = orb_radius
	col.shape = shape

	# Glowing orb mesh
	var mesh := MeshInstance3D.new()
	mesh.name = "OrbMesh"
	var sphere := SphereMesh.new()
	sphere.radius = orb_radius
	sphere.height = orb_radius * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = orb_color
	mat.emission_enabled = true
	mat.emission = orb_color
	mat.emission_energy_multiplier = orb_emission_energy
	mat.metallic = 0.2
	mat.roughness = 0.1
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.85
	mesh.material_override = mat
	_orb_body.add_child(mesh)

	# Inner glow core
	var core := MeshInstance3D.new()
	var core_sphere := SphereMesh.new()
	core_sphere.radius = orb_radius * 0.5
	core_sphere.height = orb_radius
	core.mesh = core_sphere
	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.6)
	core_mat.emission_enabled = true
	core_mat.emission = Color(0.8, 0.95, 1.0)
	core_mat.emission_energy_multiplier = 3.0
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core.material_override = core_mat
	_orb_body.add_child(core)

	# Highlight ring
	var highlight: Node3D = HIGHLIGHT_RING_SCENE.instantiate() as Node3D
	if highlight:
		highlight.position = Vector3(0, -orb_radius * 0.9, 0)
		highlight.scale = Vector3.ONE * (orb_radius / 0.03)
		_orb_body.add_child(highlight)

	_orb_body.position = Vector3(0, pedestal_height + 0.15, 0)

	if _orb_body.has_signal("dropped"):
		_orb_body.dropped.connect(_on_orb_dropped)
	if _orb_body.has_signal("picked_up"):
		_orb_body.picked_up.connect(_on_orb_picked_up)

	add_child(_orb_body)


func _on_orb_picked_up(_pickable) -> void:
	_is_held = true
	_trail_points.clear()


func _on_orb_dropped(_pickable) -> void:
	_is_held = false


# ═════════════════════════════════════════════════════════════════════════════
# RANDOM WALK
# ═════════════════════════════════════════════════════════════════════════════

func _apply_random_impulse() -> void:
	var direction := Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0) + walk_bias,
		randf_range(-1.0, 1.0)
	).normalized()

	_orb_body.apply_impulse(direction * impulse_strength)
	_displacement_sum += direction
	_total_tugs += 1

	# Pulse the orb color on each tug
	var orb_mesh := _orb_body.get_node_or_null("OrbMesh") as MeshInstance3D
	if orb_mesh and orb_mesh.material_override:
		var m: StandardMaterial3D = orb_mesh.material_override
		var pulse_color := Color(1.0, 1.0, 1.0)
		m.emission_energy_multiplier = orb_emission_energy * 2.5
		var tw := create_tween()
		tw.tween_property(m, "emission_energy_multiplier", orb_emission_energy, 0.2)


func _enforce_leash() -> void:
	# Keep orb within leash_length of its grab point
	# The pickable system handles the grip — we just add a soft constraint
	# by damping velocity when the orb moves far from its rest position
	var dist := _orb_body.global_position.distance_to(global_position + _orb_spawn_pos)
	if dist > leash_length:
		var pull_dir := (global_position + _orb_spawn_pos - _orb_body.global_position).normalized()
		_orb_body.apply_force(pull_dir * (dist - leash_length) * 2.0)


# ═════════════════════════════════════════════════════════════════════════════
# LEASH VISUAL (line from orb to pedestal top)
# ═════════════════════════════════════════════════════════════════════════════

func _create_leash_visual() -> void:
	_leash_line = MeshInstance3D.new()
	_leash_line.name = "LeashLine"
	_leash_material = StandardMaterial3D.new()
	_leash_material.albedo_color = leash_color
	_leash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_leash_material.emission_enabled = true
	_leash_material.emission = Color(0.4, 0.5, 0.8)
	_leash_material.emission_energy_multiplier = 0.3
	_leash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	add_child(_leash_line)


func _update_leash_visual() -> void:
	if not _orb_body or not _leash_line:
		return

	var start := Vector3(0, pedestal_height + 0.02, 0)
	var end := _orb_body.global_position - global_position

	# Simple cylinder between two points
	var dir := end - start
	var length := dir.length()
	if length < 0.001:
		return

	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(start)
	im.surface_add_vertex(end)
	im.surface_end()
	_leash_line.mesh = im
	_leash_line.material_override = _leash_material


# ═════════════════════════════════════════════════════════════════════════════
# TRAIL
# ═════════════════════════════════════════════════════════════════════════════

func _create_trail() -> void:
	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.name = "Trail"
	_trail_material = StandardMaterial3D.new()
	_trail_material.albedo_color = Color(0.3, 0.6, 1.0, 0.3)
	_trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_material.emission_enabled = true
	_trail_material.emission = orb_color * 0.5
	_trail_material.emission_energy_multiplier = 0.3
	_trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	add_child(_trail_mesh)


func _update_trail() -> void:
	if not _orb_body or not _trail_mesh:
		return

	var orb_local := _orb_body.global_position - global_position
	_trail_points.append(orb_local)
	if _trail_points.size() > MAX_TRAIL:
		_trail_points.pop_front()

	if _trail_points.size() < 2:
		return

	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for pt in _trail_points:
		im.surface_add_vertex(pt)
	im.surface_end()
	_trail_mesh.mesh = im
	_trail_mesh.material_override = _trail_material


# ═════════════════════════════════════════════════════════════════════════════
# LABELS
# ═════════════════════════════════════════════════════════════════════════════

func _create_labels() -> void:
	# Title
	var title := Label3D.new()
	title.name = "TitleLabel"
	title.text = "RANDOM WALK LEASH"
	title.pixel_size = 0.002
	title.font_size = 14
	title.modulate = Color(0.9, 0.9, 0.95)
	title.position = Vector3(0, pedestal_height + 0.35, -0.15)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var sub := Label3D.new()
	sub.text = "Feel the Random Walk"
	sub.pixel_size = 0.0014
	sub.font_size = 10
	sub.modulate = Color(0.6, 0.7, 0.8)
	sub.position = Vector3(0, pedestal_height + 0.31, -0.15)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	# Direction indicator
	_direction_label = Label3D.new()
	_direction_label.name = "DirectionLabel"
	_direction_label.text = ""
	_direction_label.pixel_size = 0.004
	_direction_label.font_size = 20
	_direction_label.modulate = orb_color
	_direction_label.position = Vector3(0.18, pedestal_height + 0.25, 0)
	_direction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_direction_label)

	# Stats
	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.text = "Tugs: 0\n\nGrab the orb!"
	_stats_label.pixel_size = 0.0012
	_stats_label.font_size = 10
	_stats_label.modulate = Color(0.8, 0.8, 0.85)
	_stats_label.position = Vector3(0.18, pedestal_height + 0.1, 0)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_stats_label)


func _update_display() -> void:
	if _total_tugs == 0:
		return

	# RMS displacement
	var rms := _displacement_sum.length() / sqrt(float(_total_tugs)) if _total_tugs > 0 else 0.0

	var lines := "Tugs: %d\n" % _total_tugs
	lines += "Drift: %.2f\n" % _displacement_sum.length()
	lines += "RMS: %.2f\n" % rms
	lines += "\nTheory: drift ~ sqrt(N)"
	_stats_label.text = lines


# ═════════════════════════════════════════════════════════════════════════════
# VR CONTROLS
# ═════════════════════════════════════════════════════════════════════════════

func _create_vr_controls() -> void:
	var panel := Node3D.new()
	panel.name = "ControlPanel"
	panel.position = Vector3(-0.18, pedestal_height * 0.5, 0)
	panel.rotation_degrees = Vector3(-15, 90, 0)
	add_child(panel)

	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(0.12, 0.06, 0.006)
	back.mesh = back_mesh
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.06, 0.06, 0.08)
	back.material_override = back_mat
	back.position.z = -0.006
	panel.add_child(back)

	var reset_btn := PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetBtn"
	reset_btn.position = Vector3(0, 0, 0)
	reset_btn.scale = Vector3(0.65, 0.65, 0.65)
	panel.add_child(reset_btn)
	_add_button_label(reset_btn, "RESET")

	var reset_area := reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(func(_b): _reset())


func _add_button_label(btn: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 8
	lbl.position = Vector3(0, -0.02, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_child(lbl)


func _reset() -> void:
	if _orb_body:
		_orb_body.freeze = true
		_orb_body.linear_velocity = Vector3.ZERO
		_orb_body.angular_velocity = Vector3.ZERO
		_orb_body.global_position = global_position + _orb_spawn_pos
		_orb_body.set_deferred("freeze", false)

	_total_tugs = 0
	_displacement_sum = Vector3.ZERO
	_impulse_timer = 0.0
	_trail_points.clear()
	_is_held = false
	_stats_label.text = "Tugs: 0\n\nGrab the orb!"

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

