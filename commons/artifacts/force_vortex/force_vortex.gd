extends Node3D
class_name ForceVortex

# @identity
# essence: a rotating force field — a whirlpool that drags you toward its core,
#          spins you around it, then flings you back out. Force as a place.
# desire: to make a vector field bodily — not an arrow you read but a current you
#         are caught in: inward pull + tangential spin = a spiral you ride.
# critical_parameter: pull_strength + spin_strength set the spiral; eject_force +
#         eject_up set the throw. v_in = -r̂*pull + (ŷ×r)*spin; v_out = r̂*eject + ŷ*up.
# triggers: an Area3D on the player_body layer captures the player; each physics
#           frame the field overwrites their velocity with the spiral; crossing the
#           core radius ejects them (the proven XRToolsPlayerBody.velocity path).
# emerges: centripetal vs centrifugal felt in the gut — the field owns you, then
#          releases you faster than you came in.
# truth: a force field is a velocity assigned to every point in space.

const PLAYER_MASK := 524288

@export var field_radius: float = 3.5
@export var pull_strength: float = 4.5      # inward m/s
@export var spin_strength: float = 6.5      # tangential m/s
@export var lift: float = 1.4               # gentle upward while captured
@export var eject_radius: float = 0.9       # cross this → thrown out
@export var eject_force: float = 13.0       # outward m/s
@export var eject_up: float = 8.0           # upward m/s
@export var cooldown_time: float = 1.6
@export var field_color: Color = Color(0.65, 0.35, 1.0)   # violet
@export var core_color: Color = Color(1.0, 0.5, 0.9)

enum S { IDLE, CAPTURED, COOLDOWN }

var _spinner: Node3D
var _core_mat: StandardMaterial3D
var _accent_mats: Array[StandardMaterial3D] = []
var _state: int = S.IDLE
var _player: Node3D = null
var _cooldown: float = 0.0
var _spin_phase: float = 0.0


func _ready() -> void:
	_build_field()
	_build_area()


func apply_grid_config(config: Dictionary) -> void:
	for k in ["field_radius", "pull_strength", "spin_strength", "lift",
			  "eject_radius", "eject_force", "eject_up", "cooldown_time"]:
		if config.has(k):
			set(k, float(config[k]))
	for c in get_children():
		c.queue_free()
	_accent_mats.clear(); _player = null; _state = S.IDLE
	call_deferred("_ready")


# ── Build ───────────────────────────────────────────────────────────────

func _build_field() -> void:
	# Ground ring marking the field boundary.
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = field_radius - 0.08
	torus.outer_radius = field_radius
	torus.rings = 48; torus.ring_segments = 8
	ring.mesh = torus
	ring.position.y = 0.04
	ring.material_override = _emissive(field_color, 2.0)
	add_child(ring)

	# Spinner holds the rotating arms + core (rotated in _physics_process).
	_spinner = Node3D.new()
	_spinner.name = "Spinner"
	add_child(_spinner)

	# Central glowing core column.
	var core := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12; cyl.bottom_radius = 0.22; cyl.height = 3.0
	core.mesh = cyl; core.position.y = 1.5
	_core_mat = _emissive(core_color, 3.0)
	core.material_override = _core_mat
	_spinner.add_child(core)

	# Three logarithmic spiral arms of glowing beads.
	var arms := 3
	var beads := 14
	for a in range(arms):
		var base := float(a) / float(arms) * TAU
		for i in range(beads):
			var t := float(i) / float(beads - 1)
			var rad := lerpf(0.25, field_radius * 0.98, t)
			var ang := base + t * TAU * 1.1          # 1.1 turns of spiral
			var bead := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = lerpf(0.12, 0.04, t); sm.height = sm.radius * 2.0
			bead.mesh = sm
			bead.position = Vector3(cos(ang) * rad, 0.15 + t * 1.2, sin(ang) * rad)
			var col := field_color.lerp(core_color, t)
			bead.material_override = _emissive(col, lerpf(3.2, 1.4, t))
			_spinner.add_child(bead)


func _build_area() -> void:
	var area := Area3D.new()
	area.name = "VortexZone"
	area.collision_layer = 0
	area.collision_mask = PLAYER_MASK
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = field_radius
	cyl.height = 4.0
	col.shape = cyl
	col.position.y = 2.0
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


# ── Capture / spiral / eject ────────────────────────────────────────────

func _on_body_entered(body: Node3D) -> void:
	if _state != S.IDLE:
		return
	if body.is_in_group("player_body") or body is CharacterBody3D:
		_player = body
		_state = S.CAPTURED


func _on_body_exited(body: Node3D) -> void:
	if body == _player and _state == S.CAPTURED:
		_player = null
		_state = S.IDLE


func _physics_process(delta: float) -> void:
	# Visual rotation + core pulse.
	_spin_phase += delta * (spin_strength * 0.25 + 0.6)
	if is_instance_valid(_spinner):
		_spinner.rotation.y = _spin_phase
	if _core_mat:
		_core_mat.emission_energy_multiplier = 2.4 + 1.0 * sin(_spin_phase * 2.0)

	match _state:
		S.CAPTURED:
			_apply_vortex()
		S.COOLDOWN:
			_cooldown -= delta
			if _cooldown <= 0.0:
				_state = S.IDLE


func _apply_vortex() -> void:
	if not is_instance_valid(_player):
		_state = S.IDLE
		return
	var rel := _player.global_position - global_position
	rel.y = 0.0
	var radius := rel.length()
	if radius < eject_radius:
		_eject(rel)
		return
	var to_center := (-rel).normalized()
	var tangent := Vector3.UP.cross(rel).normalized()   # horizontal swirl
	var vel := to_center * pull_strength + tangent * spin_strength + Vector3.UP * lift
	if "velocity" in _player:
		_player.set("velocity", vel)


func _eject(rel: Vector3) -> void:
	var outward := rel.normalized() if rel.length() > 0.1 else Vector3(1, 0, 0)
	if is_instance_valid(_player) and "velocity" in _player:
		_player.set("velocity", outward * eject_force + Vector3.UP * eject_up)
	_player = null
	_state = S.COOLDOWN
	_cooldown = cooldown_time
	for m in _accent_mats:
		m.emission_energy_multiplier = 6.0


# ── Helpers ──────────────────────────────────────────────────────────────

func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_accent_mats.append(m)
	return m
