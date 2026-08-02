# CatalystProjectile.gd
# Base projectile for The Becoming Catalyst.
# Each mode extends this behaviour through virtual methods.
# Not damage — transformation. What you hit becomes different.
#
# Follows the FireballProjectile pattern (RigidBody3D, contact_monitor,
# GPUParticles3D, timer-based cleanup).
extends RigidBody3D
class_name CatalystProjectile

# Verbose hit logging. Off by default — matrix lab + smoke tests can flip
# this on if they want to trace dispatch.
const DEBUG_LOG: bool = false

# ── Configuration ─────────────────────────────────────────────────────────
var speed: float = 10.0
var lifetime: float = 5.0
var projectile_scale: float = 1.0
var color_primary: Color = Color(0.9, 0.9, 0.95)
var color_secondary: Color = Color(0.6, 0.6, 0.7)
var emission_energy: float = 1.5

# ── State ─────────────────────────────────────────────────────────────────
var direction: Vector3 = Vector3.FORWARD
var time_alive: float = 0.0
var has_hit: bool = false
var _mesh_instance: MeshInstance3D = null
var _particles: GPUParticles3D = null
var _collision_shape: CollisionShape3D = null

# ── Signals ───────────────────────────────────────────────────────────────
signal projectile_hit(target: Node3D, hit_position: Vector3)
signal projectile_expired()

# ═════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Physics setup
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	collision_layer = 16    # Hazard layer
	# Mask = 2 (hit-receivers only). Layer 1 is the GridStructureComponent
	# MultiMesh world cubes — including layer 1 caused projectiles to hit
	# floor/wall cubes before reaching the foe (which lives in the open
	# air at chest height). Targets + foes are all on layer 2.
	collision_mask = 2
	gravity_scale = 0.0     # Override per-mode

	_build_visual()
	_build_collision()
	_apply_initial_velocity()

func _physics_process(delta: float) -> void:
	time_alive += delta
	if time_alive >= lifetime and not has_hit:
		_expire()
		return
	_update_trajectory(delta)

# ═════════════════════════════════════════════════════════════════════════
# VIRTUAL METHODS — Override per-mode
# ═════════════════════════════════════════════════════════════════════════

## Build the projectile's visual appearance.
func _build_visual() -> void:
	_mesh_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.1 * projectile_scale
	sphere.height = 0.2 * projectile_scale
	_mesh_instance.mesh = sphere
	_mesh_instance.material_override = _make_material(color_primary, emission_energy)
	add_child(_mesh_instance)

## Build the collision shape.
func _build_collision() -> void:
	_collision_shape = CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.12 * projectile_scale
	_collision_shape.shape = shape
	add_child(_collision_shape)

## Set the initial velocity vector.
func _apply_initial_velocity() -> void:
	linear_velocity = direction.normalized() * speed

## Called every physics frame — override for curved/wave trajectories.
func _update_trajectory(_delta: float) -> void:
	pass

## Called when projectile hits something — override for mode-specific effects.
## Subclasses do whatever decorative thing they want here (shrink, fractal-
## split, branch, etc.). They DO NOT need to call hit_by_catalyst_mode —
## the base _on_body_entered already did that BEFORE this method runs, so
## transformation dispatch is guaranteed regardless of subclass behavior.
func _on_hit(body: Node3D) -> void:
	projectile_hit.emit(body, global_position)


## Centralised transformation dispatch. Called from _on_body_entered so it
## ALWAYS fires once per hit, before any subclass _on_hit decoration. This
## guarantees every catalyst mode converts foes/targets, even if the mode's
## subclass overrides _on_hit for visual flair (which most of them do).
func _dispatch_transformation(body: Node3D) -> void:
	if body.has_method("hit_by_catalyst_mode"):
		body.hit_by_catalyst_mode(color_primary, _infer_mode_id())
	elif body.has_method("hit_by_projectile"):
		body.hit_by_projectile(color_primary)

## biome-7: the grid answers the catalyst. The cell under the impact reacts
## with the projectile's typed mode ("catalyst.fractal", "catalyst.swarm", …).
## Only maps that declared layers.biome join the "biome_grid" group, so this
## is a group-miss no-op everywhere else — the additive gate.
func _dispatch_biome_reaction() -> void:
	var biome: Node = get_tree().get_first_node_in_group("biome_grid")
	if biome == null:
		return
	if biome.has_method("react_at_world"):
		biome.react_at_world(global_position, "catalyst." + _infer_mode_id())
	# …and the ground remembers the shot even where no cell was declared:
	# a fading, mode-tinted stain marks the territory this mode has claimed.
	if biome.has_method("mark_impact"):
		biome.mark_impact(global_position, color_primary)


## Returns the projectile's mode id ("transformation", "swarm", …) by
## inspecting the script that was set on it. Each mode's create_projectile
## sets the script to res://.../modes/<mode>_projectile.gd; we extract the
## leading slug. Defaults to "primitives" if inference fails.
func _infer_mode_id() -> String:
	var s: Script = get_script()
	if s == null:
		return "primitives"
	var p: String = s.resource_path
	if p.is_empty():
		return "primitives"
	var fname: String = p.get_file().get_basename()
	# fname looks like "transformation_projectile" or "swarm_projectile".
	if fname.ends_with("_projectile"):
		return fname.substr(0, fname.length() - 11)
	return fname

## Called when projectile expires by lifetime.
func _expire() -> void:
	has_hit = true
	projectile_expired.emit()
	_cleanup()

# ═════════════════════════════════════════════════════════════════════════
# COLLISION HANDLING
# ═════════════════════════════════════════════════════════════════════════

func _on_body_entered(body: Node3D) -> void:
	if DEBUG_LOG:
		print("[Projectile] body_entered fired with body='%s' (class=%s) at pos=%s" % [
			body.name, body.get_class(), global_position])
	if has_hit:
		return
	# Don't hit the catalyst itself
	if body.is_in_group("catalyst"):
		return
	has_hit = true
	# Always dispatch transformation FIRST so subclasses can't accidentally
	# skip it by overriding _on_hit for their own visuals.
	_dispatch_transformation(body)
	_dispatch_biome_reaction()
	_on_hit(body)
	_impact_effect()
	_cleanup()

# ═════════════════════════════════════════════════════════════════════════
# EFFECTS
# ═════════════════════════════════════════════════════════════════════════

const ImpactKit := preload("res://commons/hazards/becoming_catalyst/catalyst_impact_kit.gd")

func _impact_effect() -> void:
	# Stop movement
	var travel: Vector3 = linear_velocity
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true

	# Hide mesh
	if _mesh_instance:
		_mesh_instance.visible = false

	# Shared impact language — flash core, shockwave ring facing back along
	# the flight line, ring spray, light pulse, haptic tick. Parented to the
	# scene so it stays pinned at the contact point after this body frees.
	var fx_parent: Node = get_tree().current_scene
	if fx_parent == null:
		fx_parent = get_parent()
	var normal: Vector3 = -travel.normalized() if travel.length_squared() > 0.01 else -direction.normalized()
	ImpactKit.burst(fx_parent, global_position, normal, color_primary, color_secondary, projectile_scale)

	# Particle burst
	var burst := GPUParticles3D.new()
	burst.emitting = true
	burst.amount = 24
	burst.lifetime = 0.6
	burst.one_shot = true

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0, -3.0, 0)
	mat.scale_min = 0.05 * projectile_scale
	mat.scale_max = 0.15 * projectile_scale

	var gradient := Gradient.new()
	gradient.add_point(0.0, color_primary)
	gradient.add_point(0.5, color_secondary)
	gradient.add_point(1.0, Color(color_secondary, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = gradient
	mat.color_ramp = tex

	burst.process_material = mat
	burst.draw_pass_1 = QuadMesh.new()
	add_child(burst)

func _cleanup(delay: float = 1.0) -> void:
	# Disable further collision
	collision_layer = 0
	collision_mask = 0
	# Stop particles if any
	if _particles:
		_particles.emitting = false
	# Timer to queue_free
	var timer := Timer.new()
	timer.wait_time = delay
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

# ═════════════════════════════════════════════════════════════════════════
# UTILITIES
# ═════════════════════════════════════════════════════════════════════════

func _make_material(color: Color, emission: float = 1.5) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = emission
	mat.metallic = 0.2
	mat.roughness = 0.4
	return mat

## Configure from a dictionary (used by mode factories).
func configure(config: Dictionary) -> void:
	if config.has("speed"): speed = float(config["speed"])
	if config.has("lifetime"): lifetime = float(config["lifetime"])
	if config.has("scale"): projectile_scale = float(config["scale"])
	if config.has("color_primary"): color_primary = config["color_primary"]
	if config.has("color_secondary"): color_secondary = config["color_secondary"]
	if config.has("emission"): emission_energy = float(config["emission"])
	if config.has("gravity_scale"): gravity_scale = float(config["gravity_scale"])
