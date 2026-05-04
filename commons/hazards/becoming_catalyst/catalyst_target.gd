# @identity
# essence: a destructible practice target for catalyst projectiles — 7 configurable shapes (cube, fireball, apple, banana, barrel, crystal, ring) that explode on hit and respawn after a delay
# desire: to give the player something to hit — practice targets make the catalyst bracelet legible by providing immediate feedback: you fire, the target breaks, it returns, you try again
# critical_parameter: shape (via apply_grid_config) — changes mesh, collision, and color palette at runtime; hits_to_destroy controls difficulty; moving/orbit enable patrol patterns
# triggers: _ready() builds visual + collision + explosion particles; hit_by_projectile() drives flash→explode→respawn cycle; _rebuild_after_config() called deferred after shape change
# emerges: the return — targets respawn with an elastic bounce animation that reads as resilience, not reset; the player learns that the system is cyclical, not final
# needs: apply_grid_config [has]; projectile collision [has via collision_layer 2]; shape variants [has — 7 shapes]; moving patrol [has]; orbit mode [has]
# relationships: placed in Chamber_* maps (one per sequence end); receives projectiles from becoming_catalyst; groups under "catalyst_target" for GameManager collision routing
# truth: a target is not an enemy — it is a question; catalyst_target asks whether you can place a projectile in space, and answers with color, destruction, and return

# catalyst_target.gd
# Destructible practice target for catalyst projectiles.
# Supports multiple shapes via grid config: cube, fireball, apple, banana, default.
# Explodes on hit with particle burst, respawns after delay.
extends StaticBody3D

# ── Shape Definitions ─────────────────────────────────────────────────
const SHAPES := {
	"default": { "color": Color(0.85, 0.35, 0.1), "emission": Color(0.9, 0.4, 0.15), "scale": 1.0 },
	"cube":    { "color": Color(0.6, 0.45, 0.3),  "emission": Color(0.7, 0.5, 0.25),  "scale": 1.0 },
	"fireball":{ "color": Color(1.0, 0.3, 0.05),  "emission": Color(1.0, 0.5, 0.1),   "scale": 0.5 },
	"apple":   { "color": Color(0.8, 0.1, 0.1),   "emission": Color(0.9, 0.15, 0.1),  "scale": 0.3 },
	"banana":  { "color": Color(0.95, 0.85, 0.2),  "emission": Color(0.9, 0.8, 0.1),  "scale": 0.3 },
	"barrel":  { "color": Color(0.5, 0.35, 0.2),  "emission": Color(0.6, 0.3, 0.1),   "scale": 0.8 },
	"crystal": { "color": Color(0.3, 0.7, 0.9),   "emission": Color(0.4, 0.8, 1.0),   "scale": 0.4 },
}

# ── State ─────────────────────────────────────────────────────────────
var _shape_id: String = "default"
var _visual: Node3D  # Container for all visuals
var _col_shape: CollisionShape3D
var _particles: GPUParticles3D

# Movement
var _moving: bool = false
var _orbit: bool = false
var _patrol_speed: float = 1.5
var _patrol_range: float = 2.5
var _time: float = 0.0
var _start_pos: Vector3

# Hit / destruction
var _hits_to_destroy: int = 1
var _hit_count: int = 0
var _flash_timer: float = 0.0
var _destroyed: bool = false
var _respawn_timer: float = 0.0
const RESPAWN_DELAY := 4.0

# Ring spin (default shape only)
var _ring: MeshInstance3D
var _inner_ring: MeshInstance3D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	_start_pos = position
	_build_visual()
	_build_collision()
	_build_explosion_particles()
	add_to_group("catalyst_target")


func _process(delta: float) -> void:
	_time += delta

	# Respawn countdown
	if _destroyed:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_respawn()
		return

	# Movement
	if _moving:
		position.x = _start_pos.x + sin(_time * _patrol_speed) * _patrol_range
	elif _orbit:
		position.x = _start_pos.x + cos(_time * _patrol_speed) * _patrol_range
		position.z = _start_pos.z + sin(_time * _patrol_speed) * _patrol_range

	# Ring spin (default shape)
	if _ring:
		_ring.rotate_y(delta * 0.8)
	if _inner_ring:
		_inner_ring.rotate_x(delta * 1.2)

	# Flash decay
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_set_emission_boost(0.0)


# ═══════════════════════════════════════════════════════════════════════
# HIT / DESTRUCTION
# ═══════════════════════════════════════════════════════════════════════

func hit_by_projectile(_projectile_color: Color = Color.WHITE) -> void:
	if _destroyed:
		return

	# Hit logging silenced — fires too often during normal play. Re-enable
	# locally if diagnosing why a mode doesn't visibly land on the target.
	_hit_count += 1
	_flash_timer = 0.3
	_set_emission_boost(4.0)
	# Tint the body to the projectile's color so the user can SEE which
	# mode landed (transformation = purple, primitives = white, etc.).
	var visual_root: Node3D = _visual if is_instance_valid(_visual) else null
	if visual_root:
		for child in visual_root.get_children():
			if child is MeshInstance3D and (child as MeshInstance3D).material_override is StandardMaterial3D:
				var m: StandardMaterial3D = (child as MeshInstance3D).material_override
				m.albedo_color = _projectile_color
				m.emission = _projectile_color

	if _hit_count >= _hits_to_destroy:
		_explode()
	else:
		# Shake
		var base := position
		var tween := create_tween()
		for i in 4:
			var offset := Vector3(
				randf_range(-0.03, 0.03),
				randf_range(-0.02, 0.02),
				randf_range(-0.03, 0.03)
			)
			tween.tween_property(self, "position", base + offset, 0.04)
		tween.tween_property(self, "position", base, 0.06)


func _explode() -> void:
	_destroyed = true
	_respawn_timer = RESPAWN_DELAY

	# Fire explosion particles
	if _particles:
		_particles.emitting = true

	# Scale down + fade visual
	if _visual:
		var tween := create_tween()
		tween.tween_property(_visual, "scale", Vector3.ZERO, 0.25) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)

	# Disable collision
	if _col_shape:
		_col_shape.disabled = true


func _respawn() -> void:
	_destroyed = false
	_hit_count = 0
	_flash_timer = 0.0

	# Restore visual
	if _visual:
		_visual.scale = Vector3.ONE
		var tween := create_tween()
		_visual.scale = Vector3(0.01, 0.01, 0.01)
		tween.tween_property(_visual, "scale", Vector3.ONE, 0.4) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	# Re-enable collision
	if _col_shape:
		_col_shape.disabled = false

	_set_emission_boost(0.0)


func _set_emission_boost(boost: float) -> void:
	if not _visual:
		return
	for child in _visual.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = child.material_override
			var base: float = mat.get_meta("base_emission", 1.2)
			mat.emission_energy_multiplier = base + boost


# ═══════════════════════════════════════════════════════════════════════
# VISUAL BUILDERS
# ═══════════════════════════════════════════════════════════════════════

func _build_visual() -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)

	match _shape_id:
		"cube":     _build_cube()
		"fireball": _build_fireball()
		"apple":    _build_apple()
		"banana":   _build_banana()
		"barrel":   _build_barrel()
		"crystal":  _build_crystal()
		_:          _build_default_target()


func _make_mat(color: Color, emission: Color, base_emission: float = 1.2) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = base_emission
	mat.metallic = 0.3
	mat.roughness = 0.4
	mat.set_meta("base_emission", base_emission)
	return mat


func _add_mesh(mesh: Mesh, mat: StandardMaterial3D, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	_visual.add_child(mi)
	return mi


# ── Cube (1m crate) ──────────────────────────────────────────────────
func _build_cube() -> void:
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 1.0, 1.0)
	var mat := _make_mat(Color(0.6, 0.45, 0.3), Color(0.4, 0.3, 0.15), 0.4)
	mat.roughness = 0.7
	mat.metallic = 0.1
	_add_mesh(box, mat)

	# Cross-brace detail
	var plank := BoxMesh.new()
	plank.size = Vector3(1.02, 0.06, 0.06)
	var plank_mat := _make_mat(Color(0.5, 0.35, 0.2), Color(0.3, 0.2, 0.1), 0.2)
	plank_mat.roughness = 0.8
	for y in [-0.35, 0.0, 0.35]:
		_add_mesh(plank, plank_mat, Vector3(0, y, 0.5))
		_add_mesh(plank, plank_mat, Vector3(0, y, -0.5))


# ── Fireball ──────────────────────────────────────────────────────────
func _build_fireball() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 12
	sphere.rings = 8
	var mat := _make_mat(Color(1.0, 0.3, 0.05), Color(1.0, 0.5, 0.1), 3.0)
	_add_mesh(sphere, mat)

	# Inner glow core
	var core := SphereMesh.new()
	core.radius = 0.3
	core.height = 0.6
	var core_mat := _make_mat(Color(1.0, 0.9, 0.3), Color(1.0, 1.0, 0.5), 5.0)
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_mat.albedo_color.a = 0.6
	_add_mesh(core, core_mat)

	# Fire particles
	var fire := GPUParticles3D.new()
	fire.name = "FireEffect"
	fire.amount = 30
	fire.lifetime = 0.8
	var fire_mat := ParticleProcessMaterial.new()
	fire_mat.direction = Vector3(0, 1, 0)
	fire_mat.spread = 45.0
	fire_mat.initial_velocity_min = 0.3
	fire_mat.initial_velocity_max = 0.8
	fire_mat.gravity = Vector3(0, 1, 0)
	fire_mat.scale_min = 0.05
	fire_mat.scale_max = 0.15
	fire_mat.color = Color(1.0, 0.4, 0.1)
	fire.process_material = fire_mat
	var quad := QuadMesh.new()
	quad.size = Vector2(0.1, 0.1)
	fire.draw_pass_1 = quad
	_visual.add_child(fire)


# ── Apple ─────────────────────────────────────────────────────────────
func _build_apple() -> void:
	# Body — slightly squashed sphere
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.28
	sphere.radial_segments = 12
	sphere.rings = 8
	var mat := _make_mat(Color(0.8, 0.1, 0.05), Color(0.9, 0.15, 0.1), 0.8)
	mat.roughness = 0.6
	_add_mesh(sphere, mat, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.9, 1.0))

	# Stem
	var stem := CylinderMesh.new()
	stem.top_radius = 0.008
	stem.bottom_radius = 0.012
	stem.height = 0.06
	stem.radial_segments = 6
	var stem_mat := _make_mat(Color(0.35, 0.25, 0.1), Color(0.2, 0.15, 0.05), 0.3)
	_add_mesh(stem, stem_mat, Vector3(0, 0.16, 0))

	# Leaf
	var leaf := BoxMesh.new()
	leaf.size = Vector3(0.04, 0.005, 0.02)
	var leaf_mat := _make_mat(Color(0.2, 0.6, 0.15), Color(0.1, 0.4, 0.05), 0.5)
	_add_mesh(leaf, leaf_mat, Vector3(0.02, 0.17, 0), Vector3(0, 0, 0.3))


# ── Banana ────────────────────────────────────────────────────────────
func _build_banana() -> void:
	# Curved banana body — 5 segments along an arc
	var seg := CylinderMesh.new()
	seg.top_radius = 0.035
	seg.bottom_radius = 0.04
	seg.height = 0.08
	seg.radial_segments = 8
	var mat := _make_mat(Color(0.95, 0.85, 0.2), Color(0.9, 0.8, 0.1), 0.6)
	mat.roughness = 0.5

	var arc_radius := 0.15
	for i in 5:
		var angle := deg_to_rad(-40 + i * 20)
		var pos := Vector3(sin(angle) * arc_radius, cos(angle) * arc_radius - arc_radius, 0)
		var rot := Vector3(0, 0, angle)
		var s: float = 1.0 - abs(i - 2) * 0.15  # Taper at ends
		_add_mesh(seg, mat, pos, rot, Vector3(s, 1.0, s))

	# Brown tip
	var tip := SphereMesh.new()
	tip.radius = 0.02
	tip.height = 0.04
	var tip_mat := _make_mat(Color(0.3, 0.2, 0.1), Color(0.2, 0.1, 0.05), 0.3)
	var end_angle := deg_to_rad(40)
	_add_mesh(tip, tip_mat, Vector3(sin(end_angle) * arc_radius, cos(end_angle) * arc_radius - arc_radius, 0))


# ── Barrel ────────────────────────────────────────────────────────────
func _build_barrel() -> void:
	# Main body — bulging cylinder
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.3
	cyl.height = 0.8
	cyl.radial_segments = 12
	var mat := _make_mat(Color(0.5, 0.35, 0.2), Color(0.3, 0.2, 0.1), 0.3)
	mat.roughness = 0.8
	_add_mesh(cyl, mat)

	# Metal bands
	var band := TorusMesh.new()
	band.inner_radius = 0.01
	band.outer_radius = 0.32
	band.rings = 16
	band.ring_segments = 6
	var band_mat := _make_mat(Color(0.4, 0.4, 0.45), Color(0.3, 0.3, 0.35), 0.5)
	band_mat.metallic = 0.7
	for y in [-0.3, 0.0, 0.3]:
		_add_mesh(band, band_mat, Vector3(0, y, 0), Vector3(PI / 2, 0, 0))


# ── Crystal target ────────────────────────────────────────────────────
func _build_crystal() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	sphere.radial_segments = 6  # Faceted
	sphere.rings = 4
	var mat := _make_mat(Color(0.3, 0.7, 0.9), Color(0.4, 0.8, 1.0), 2.0)
	mat.metallic = 0.6
	mat.roughness = 0.1
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.8
	_add_mesh(sphere, mat)

	# Spikes
	var spike := CylinderMesh.new()
	spike.top_radius = 0.0
	spike.bottom_radius = 0.04
	spike.height = 0.15
	spike.radial_segments = 5
	var spike_mat := _make_mat(Color(0.5, 0.85, 1.0), Color(0.6, 0.9, 1.0), 2.5)
	for dir in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var pos: Vector3 = dir * 0.18
		var rot := Vector3.ZERO
		if dir == Vector3.UP:
			rot = Vector3.ZERO
		elif dir == Vector3.DOWN:
			rot = Vector3(PI, 0, 0)
		elif dir == Vector3.RIGHT:
			rot = Vector3(0, 0, -PI/2)
		elif dir == Vector3.LEFT:
			rot = Vector3(0, 0, PI/2)
		elif dir == Vector3.FORWARD:
			rot = Vector3(PI/2, 0, 0)
		elif dir == Vector3.BACK:
			rot = Vector3(-PI/2, 0, 0)
		_add_mesh(spike, spike_mat, pos, rot)


# ── Default (ring target) ────────────────────────────────────────────
func _build_default_target() -> void:
	# Core sphere
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	sphere.radial_segments = 16
	sphere.rings = 8
	var mat := _make_mat(Color(0.85, 0.35, 0.1), Color(0.9, 0.4, 0.15), 1.2)
	mat.metallic = 0.5
	mat.roughness = 0.3
	_add_mesh(sphere, mat)

	# Outer ring
	var torus := TorusMesh.new()
	torus.inner_radius = 0.015
	torus.outer_radius = 0.2
	torus.rings = 24
	torus.ring_segments = 8
	var ring_mat := _make_mat(Color(1.0, 0.7, 0.2), Color(1.0, 0.8, 0.3), 0.8)
	ring_mat.metallic = 0.6
	ring_mat.roughness = 0.2
	_ring = _add_mesh(torus, ring_mat)

	# Inner ring — perpendicular
	var torus2 := TorusMesh.new()
	torus2.inner_radius = 0.01
	torus2.outer_radius = 0.15
	torus2.rings = 20
	torus2.ring_segments = 6
	var inner_mat := _make_mat(Color(0.9, 0.5, 0.15), Color(0.95, 0.6, 0.2), 0.6)
	inner_mat.metallic = 0.5
	inner_mat.roughness = 0.25
	_inner_ring = _add_mesh(torus2, inner_mat, Vector3.ZERO, Vector3(PI / 2, 0, 0))


# ═══════════════════════════════════════════════════════════════════════
# COLLISION
# ═══════════════════════════════════════════════════════════════════════

func _build_collision() -> void:
	_col_shape = CollisionShape3D.new()
	var shape_def: Dictionary = SHAPES.get(_shape_id, SHAPES["default"])
	var s: float = shape_def.get("scale", 1.0)

	if _shape_id == "cube":
		var box := BoxShape3D.new()
		box.size = Vector3(1.0, 1.0, 1.0)
		_col_shape.shape = box
	elif _shape_id == "barrel":
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.32
		cyl.height = 0.8
		_col_shape.shape = cyl
	elif _shape_id == "banana":
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.05
		capsule.height = 0.3
		_col_shape.shape = capsule
	else:
		var sphere := SphereShape3D.new()
		sphere.radius = 0.2 * s if s > 0.5 else 0.15
		_col_shape.shape = sphere

	add_child(_col_shape)


# ═══════════════════════════════════════════════════════════════════════
# EXPLOSION PARTICLES
# ═══════════════════════════════════════════════════════════════════════

func _build_explosion_particles() -> void:
	_particles = GPUParticles3D.new()
	_particles.name = "Explosion"
	_particles.emitting = false
	_particles.one_shot = true
	_particles.explosiveness = 1.0
	_particles.amount = 24
	_particles.lifetime = 1.2

	var shape_def: Dictionary = SHAPES.get(_shape_id, SHAPES["default"])
	var color: Color = shape_def.get("color", Color.WHITE)

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 1.5
	mat.initial_velocity_max = 4.0
	mat.gravity = Vector3(0, -4, 0)
	mat.damping_min = 1.0
	mat.damping_max = 3.0
	mat.scale_min = 0.03
	mat.scale_max = 0.12
	mat.color = color

	# Color ramp: shape color → dark
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 1.0))
	gradient.set_color(1, Color(color.r * 0.3, color.g * 0.3, color.b * 0.3, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	mat.color_ramp = ramp

	_particles.process_material = mat

	# Draw pass — small box chunk
	var chunk := BoxMesh.new()
	chunk.size = Vector3(0.08, 0.08, 0.08)
	_particles.draw_pass_1 = chunk

	add_child(_particles)


# ═══════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═══════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	# Shape must be set before _ready builds visuals, but grid config runs after.
	# So if shape changes, rebuild.
	if config_data.has("shape"):
		var new_shape := str(config_data["shape"])
		if new_shape != _shape_id:
			_shape_id = new_shape
			# Rebuild everything
			if _visual:
				_visual.queue_free()
				_visual = null
			_ring = null
			_inner_ring = null
			if _col_shape:
				_col_shape.queue_free()
				_col_shape = null
			if _particles:
				_particles.queue_free()
				_particles = null
			call_deferred("_rebuild_after_config")

	if config_data.has("hits"):
		_hits_to_destroy = int(config_data["hits"])
	if config_data.has("moving"):
		_moving = true
	if config_data.has("orbit"):
		_orbit = true
	if config_data.has("speed"):
		_patrol_speed = float(config_data["speed"])
	if config_data.has("range"):
		_patrol_range = float(config_data["range"])


func _rebuild_after_config() -> void:
	_build_visual()
	_build_collision()
	_build_explosion_particles()
