# @identity
# essence: a destructible practice target for catalyst projectiles — 7 configurable shapes (cube, fireball, apple, banana, barrel, crystal, ring) that explode on hit and respawn after a delay
# desire: to give the player something to hit — practice targets make the catalyst bracelet legible by providing immediate feedback: you fire, the target breaks, it returns, you try again
# critical_parameter: shape (via apply_grid_config) — changes mesh, collision, and color palette at runtime; support is what apparatus HOLDS THE BODY UP (none/cradle/frame/gantry built natively, the whole eight-value vocabulary accepted) and mark is the field it is JUDGED IN (none/bullseye/grid/nimbus); hits_to_destroy controls difficulty; moving/orbit enable patrol patterns
# triggers: _ready() builds visual + fixture + collision + explosion particles; hit_by_projectile() drives flash→explode→respawn cycle; _rebuild_after_config() called deferred after a config change
# emerges: the return — targets respawn with an elastic bounce animation that reads as resilience, not reset; the player learns that the system is cyclical, not final; with a fixture, the support and the mark stay standing while the body is gone, so the empty holder is what you look at during the respawn
# needs: apply_grid_config [has]; projectile collision [has via collision_layer 2]; shape variants [has — 7 shapes]; moving patrol [has]; orbit mode [has]; a frame of reference for the question [has — support + mark]
# relationships: placed in Chamber_* maps (one per sequence end); receives projectiles from becoming_catalyst; groups under "catalyst_target" for GameManager collision routing
# truth: a target is not an enemy — it is a question; catalyst_target asks whether you can place a projectile in space, and answers with color, destruction, and return

# catalyst_target.gd
# Destructible practice target for catalyst projectiles.
# Supports multiple shapes via grid config: cube, fireball, apple, banana, default.
# Explodes on hit with particle burst, respawns after delay.
#
# FAMILY (stage-2 DNA). The body is only half a target. Placing a projectile in space
# is a judgement, and a judgement needs a frame of reference — something that HOLDS the
# object (so you read its height and its facing) and something the miss lands ON (so you
# read how far off you were). Ninety-odd placements had neither: a 40 cm bauble hovering
# in an empty cell, its own size the only clue to the scale of the question. Two axes
# supply the reference frame:
#   support = none | cradle | frame | gantry  — the apparatus that holds it up
#   mark    = none | bullseye | grid | nimbus — the ground it is judged in
# Both default to "nothing", which is exactly today's build, so the existing maps are
# untouched. Both are pure appearance: the fixture carries NO collision shape, so the
# projectile flies straight through it and hit detection is bit-for-bit what it was.
#
# CONVERGENCE (2026-07-27). This axis used to be called `rig`, and three siblings asked
# the same question under three other names — `station` on the fire pieces, `carriage` on
# the info board, `housing` on the science screen. Four private words for one question is
# four vocabularies, and a map author had to learn which artifact they were addressing
# before they could say anything at all. They are now ONE axis, `support`, with ONE
# vocabulary of eight values:
#   none · bracket · stand · cradle · frame · gantry · cabinet · pylon
# `rig` is retired from the GRAMMAR outright — it is neither the token nor a value any
# more, because promoting one member to name the class is how the level confusion started.
# It survives only as a legacy spelling the parser still accepts (SUPPORT_ALIASES and the
# `rig` key in apply_grid_config), so nothing that was writable yesterday reads as empty
# today. An accepted spelling is not vocabulary: neither `rig` nor `free` is offered.
# This artifact builds four of the eight. The other four are not errors and must not be
# silently swallowed: DEGRADE below says which native each of them lands on, declared
# rather than guessed. See _resolve_support().
extends StaticBody3D

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

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

# ── Family axes (stage-2 DNA) ─────────────────────────────────────────
# "none"/"none" reproduce the legacy build exactly: _build_fixture() returns before
# creating a single node, so an untouched map gets the same scene tree it got before.

## What apparatus HOLDS THE BODY UP. none = nothing (legacy, a body alone in the air —
## the reference the other values are read against, not a variant that has to bite);
## cradle = a wide low pad with three struts gripping it, an object PRESENTED;
## frame = an upright rectangle standing around it, an object BRACKETED;
## gantry = tall uprights and an overhead beam with a drop rod, an object SUSPENDED.
## The enum lists what this artifact BUILDS. The token parser accepts all eight canonical
## values (SUPPORTS) and folds the four it cannot build onto these through DEGRADE — the
## enum is the sweepable variant list, so a degraded spelling must never appear in it or
## the critic renders two identical frames and calls the axis inert.
## Note the one place this leaks: `moving`/`orbit` patrol by writing this node's position,
## so a support travels with the body instead of standing still. Counter-translating the
## fixture was the alternative and it is worse — the body drifts clean out of its own
## frame. Two of the hundred placements patrol and neither sets a support; left alone.
@export_enum("none", "cradle", "frame", "gantry") var support: String = "none"

## The field the shot is JUDGED IN — a mark on the floor the body stands at the centre of.
## none = nothing (legacy); bullseye = painted concentric rings, the fairground register;
## grid = a dark calibration pad with pale rules, the range-instrument register;
## nimbus = concentric glowing gold rings, the votive register.
## It lies flat rather than standing behind the body for a mundane reason worth knowing:
## these targets are grounded to the cell surface, so their centre IS the floor line. A
## vertical backboard would have to start at the body's feet and rise, leaving the body
## stranded at the bottom edge of its own bullseye. Flat, the body sits at the centre of
## the mark, which is what a target means. The straight-down capture angle gets it for free.
@export_enum("none", "bullseye", "grid", "nimbus") var mark: String = "none"

## The shared vocabulary, in order of how much building the apparatus is: nothing, wall
## hardware, a slender floor member, a low wide base that grips, an open upright rectangle,
## an overhead span, a body of joinery, a mass of building. Every artifact carrying the
## `support` axis accepts all eight; each builds the subset it has geometry for.
const SUPPORTS := ["none", "bracket", "stand", "cradle", "frame", "gantry", "cabinet", "pylon"]

## The four this artifact builds. Everything else routes through DEGRADE.
const SUPPORT_NATIVE := ["none", "cradle", "frame", "gantry"]

## THE ANTI-SILENCE TABLE. Every canonical value this artifact does not build, and the
## native it lands on. Each of these four is a judgement, not a default:
##   bracket -> none    Placed mid-cell in open air with no wall to fix to. Deliberately
##                      NOT cradle: the cradle claims ~0.76 m of floor and is in no sense
##                      minimal hardware.
##   stand   -> cradle  THE LOAD-BEARING DEGRADE. Rule 2 below forbids any fixture piece
##                      under the body's lowest point, so this artifact structurally
##                      CANNOT lift its object. cradle is its floor-borne-and-below
##                      dialect: it presents rather than elevates. Anyone writing
##                      support:stand here must know they get no lift.
##   cabinet -> frame   It builds no enclosure and no glazing, and a glazed box would
##                      occlude the body the artifact exists to be aimed at. frame keeps
##                      "structure around it" and loses "enclosing it".
##   pylon   -> gantry  Heaviest structure it builds. A slab rising behind the body from
##                      base_y is buildable within rule 2 and is the obvious future native.
const DEGRADE: Dictionary = {
	"bracket": "none",
	"stand": "cradle",
	"cabinet": "frame",
	"pylon": "gantry",
}

## Retired spellings, still accepted so no map that was valid yesterday breaks today.
## `free` was an adjective, and an absence is spelled `none` in this grammar.
const SUPPORT_ALIASES: Dictionary = {"free": "none"}

const MARKS := ["none", "bullseye", "grid", "nimbus"]

# Fixture palette. Deliberately cool and unlit against the body's warm emissive shapes —
# the support is furniture and must not compete with the thing you are aiming at. The one
# exception is nimbus, which is meant to glow.
const SUPPORT_STEEL := Color(0.34, 0.35, 0.38)
const SUPPORT_DARK := Color(0.15, 0.155, 0.17)
const MARK_PALE := Color(0.87, 0.86, 0.82)
const MARK_RED := Color(0.78, 0.15, 0.11)
const MARK_GOLD := Color(1.0, 0.80, 0.42)

# ── State ─────────────────────────────────────────────────────────────
var _shape_id: String = "default"
var _visual: Node3D  # Container for all visuals
var _fixture: Node3D  # Support + mark. Sibling of _visual, NOT a child — see _build_fixture().
# RESOLVED ONCE, in _build_fixture(). `support` holds what the map author asked for; this
# holds what the artifact can actually build. Every consumer reads this one, never the
# raw export — resolving per-site is how one consumer builds a cradle while another still
# thinks it is looking at a stand.
var _support_native: String = "none"
var _col_shape: CollisionShape3D
var _particles: GPUParticles3D
var _rebuild_queued: bool = false
var _rebuild_body_pending: bool = false

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
	_build_fixture()
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
# FIXTURE — support (what holds it up) + mark (the field it is judged in)
# ═══════════════════════════════════════════════════════════════════════
#
# Three rules govern everything below, and each one is a constraint, not a taste:
#
# 1. The fixture is a SIBLING of _visual, parented to self. That is what makes the
#    respawn loop legible: _explode() tweens _visual to zero scale, so a child fixture
#    would vanish with the body and the whole cell would go empty. As a sibling the
#    support and the mark stay put and you spend the four-second respawn looking at an empty
#    holder — the cycle the identity calls "resilience, not reset". It also means the
#    two loops that walk _visual.get_children() (the projectile-colour tint and the
#    emission flash) skip the fixture for free: the body takes the hit colour, the
#    furniture keeps its own, and the contrast is what makes the hit readable.
#
# 2. No fixture piece may sit below the body's own lowest point. The grid auto-grounds
#    artifacts by their local AABB, and that grounding pass and this build are both
#    deferred — the order between them is not something we control. Anchoring every
#    fixture piece to the body's measured base keeps the local AABB floor exactly where
#    it was, so grounding lands identically whichever runs first. The price is that
#    nothing here can be a tall floor pedestal lifting the body to eye height; the
#    supports grow upward and outward from the body's own feet instead. This is also why
#    `stand` degrades to `cradle` rather than being built: a stand LIFTS, and this
#    artifact cannot.
#
# 3. No CollisionShape3D, anywhere. The target is gameplay-critical — projectiles test
#    against collision_layer 2 and the single body shape built in _build_collision().
#    A support that could block or absorb a shot would silently change every map it
#    appears in. Everything below is mesh only; projectiles pass straight through it.

## Mesh-only local AABB of the body. GPUParticles3D are skipped on purpose: the
## fireball's fire emitter reports a huge visibility box and would inflate every support
## built around it by an order of magnitude.
func _body_aabb() -> AABB:
	var fallback: AABB = AABB(Vector3(-0.2, -0.2, -0.2), Vector3(0.4, 0.4, 0.4))
	if not is_instance_valid(_visual):
		return fallback
	var out: AABB = AABB()
	var found: bool = false
	for child in _visual.get_children():
		if not (child is MeshInstance3D):
			continue
		var mi: MeshInstance3D = child
		if mi.mesh == null:
			continue
		var a: AABB = mi.transform * mi.mesh.get_aabb()
		if found:
			out = out.merge(a)
		else:
			out = a
			found = true
	return out if found else fallback


## Fold any value of the shared vocabulary onto one this artifact actually builds.
## THIS IS THE POINT OF THE CONVERGENCE PASS. `support` is one vocabulary spoken by five
## artifacts, and half of it has no geometry here. Resolving an unbuilt value to the
## artifact's default would be silent — `support:pylon` would just look like an untouched
## target and nobody would ever learn the map said something else. DEGRADE names the
## native each foreign value lands on, out loud and in one place.
## Only a value outside all eight falls through to the default, and that case is a typo,
## not a sibling: a typo in a map should look like today, not like a bug.
func _resolve_support(raw: String) -> String:
	var v: String = str(raw).strip_edges().to_lower()
	v = str(SUPPORT_ALIASES.get(v, v))
	if DEGRADE.has(v):
		return str(DEGRADE[v])
	return v if SUPPORT_NATIVE.has(v) else "none"


func _build_fixture() -> void:
	# The legacy build makes no fixture node at all — not an empty one. A visitor
	# diffing the scene tree of an untouched map must find nothing added.
	# Resolved ONCE here and stored, so nothing downstream can disagree about which
	# apparatus this is.
	_support_native = _resolve_support(support)
	var m: String = _support_native
	var k: String = mark if MARKS.has(mark) else "none"
	if m == "none" and k == "none":
		return

	_fixture = Node3D.new()
	_fixture.name = "Fixture"
	add_child(_fixture)

	var body: AABB = _body_aabb()
	var base_y: float = body.position.y          # the body's feet — every piece starts here
	var span: float = maxf(maxf(body.size.x, body.size.z), 0.28)
	var tall: float = maxf(body.size.y, 0.28)

	# Mark first so the support reads as standing ON it.
	match k:
		"bullseye": _mark_bullseye(base_y, span)
		"grid": _mark_grid(base_y, span)
		"nimbus": _mark_nimbus(base_y, span)
	# `m` is already native — every canonical value reached one of these four through
	# DEGRADE, so there is no silent fallthrough left for a real value to land in.
	# "none" builds nothing ON PURPOSE: it is the reference state, the body meeting the
	# room with no apparatus added. Reached here only when a mark is set.
	match m:
		"none": pass
		"cradle": _support_cradle(base_y, span, tall)
		"frame": _support_frame(base_y, span, tall)
		"gantry": _support_gantry(base_y, span, tall)


func _fx(mesh: Mesh, mat: StandardMaterial3D, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	_fixture.add_child(mi)
	return mi


## A cylinder spanning two points. Built by hand rather than with look_at() because the
## fixture is assembled before the node is in a usable global transform.
func _fx_strut(a: Vector3, b: Vector3, radius: float, mat: StandardMaterial3D) -> void:
	var d: Vector3 = b - a
	var seg_len: float = d.length()
	if seg_len < 0.005:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = seg_len
	cyl.radial_segments = 6
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.material_override = mat
	var up: Vector3 = d.normalized()
	var ref: Vector3 = Vector3.RIGHT if absf(up.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var x_axis: Vector3 = ref.cross(up).normalized()
	mi.transform = Transform3D(Basis(x_axis, up, x_axis.cross(up)), (a + b) * 0.5)
	_fixture.add_child(mi)


func _flat_box(size: Vector3, mat: StandardMaterial3D, x: float, base_y: float, z: float, yaw: float = 0.0) -> void:
	# Bottom-anchored: the caller gives the floor line, not the centre, because rule 2
	# above is about floors and doing that arithmetic at every call site invites a slip.
	var mesh := BoxMesh.new()
	mesh.size = size
	_fx(mesh, mat, Vector3(x, base_y + size.y * 0.5, z), Vector3(0, yaw, 0))


func _disc(radius: float, height: float, mat: StandardMaterial3D, base_y: float, segments: int = 24) -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = segments
	_fx(cyl, mat, Vector3(0, base_y + height * 0.5, 0))


# ── support: cradle — the object PRESENTED ──────────────────────────
# A wide two-step pad at the body's feet with three struts leaning in to grip its waist.
# The pad cannot go UNDER the body (rule 2), so it reaches outward instead: roughly twice
# the body's own width of floor claimed, which is what makes a 40 cm bauble read as a
# thing on display rather than a thing dropped. Also where `stand` lands — a stand lifts
# and this artifact may not, so the vocabulary's hold-from-below value takes its traffic.
func _support_cradle(base_y: float, span: float, tall: float) -> void:
	var steel: StandardMaterial3D = HangarKit.painted_metal(SUPPORT_STEEL, 0.2, 0.45, 0.5)
	var dark: StandardMaterial3D = HangarKit.painted_metal(SUPPORT_DARK, 0.15, 0.6, 0.4)
	# Upper clamps everywhere in this section keep a fixture inside roughly a 2-cell
	# footprint (cells are 1 m). The registry already declares range 2 for this artifact;
	# a cube-shaped body scaled by pure ratio would have thrown a 2 m pad across four
	# neighbours' cells and quietly broken their placement.
	var r_out: float = clampf(span * 1.05, 0.38, 0.85)

	_disc(r_out, 0.045, dark, base_y)
	_disc(r_out * 0.74, 0.075, steel, base_y + 0.045)

	var top_y: float = base_y + tall * 0.85
	var r_top: float = span * 0.34
	for i in 3:
		var ang: float = TAU * float(i) / 3.0 + 0.4
		var foot: Vector3 = Vector3(cos(ang) * r_out * 0.88, base_y + 0.06, sin(ang) * r_out * 0.88)
		var grip: Vector3 = Vector3(cos(ang) * r_top, top_y, sin(ang) * r_top)
		_fx_strut(foot, grip, 0.024, steel)


# ── support: frame — the object BRACKETED ───────────────────────────
# An upright rectangle standing around the body: two posts, a head beam, a foot rail,
# and one red bar across the head. Body-height, so it reads as a doorway the target
# happens to be standing in — the silhouette a cradle cannot make. Also where `cabinet`
# lands: this artifact builds no enclosure, and glazing the body would occlude the thing
# you are meant to be aiming at, so the open value keeps "structure around it" and drops
# "enclosing it".
func _support_frame(base_y: float, span: float, tall: float) -> void:
	var steel: StandardMaterial3D = HangarKit.painted_metal(SUPPORT_STEEL, 0.2, 0.45, 0.5)
	var dark: StandardMaterial3D = HangarKit.painted_metal(SUPPORT_DARK, 0.15, 0.6, 0.4)
	var red: StandardMaterial3D = HangarKit.painted_metal(MARK_RED, 0.1, 0.2, 0.55)
	var hw: float = clampf(span * 1.1, 0.36, 0.9)
	var h: float = clampf(tall * 3.2, 1.0, 2.0)
	var t: float = 0.06

	for side in [-1.0, 1.0]:
		var sx: float = side
		_flat_box(Vector3(t, h, t), steel, hw * sx, base_y, 0.0)
		_flat_box(Vector3(0.22, 0.035, 0.22), dark, hw * sx, base_y, 0.0)
	_flat_box(Vector3(hw * 2.0 + t, t, t), steel, 0.0, base_y + h - t, 0.0)
	_flat_box(Vector3(hw * 2.0 - t, t * 0.7, t * 0.7), steel, 0.0, base_y + 0.02, 0.0)
	# One warm bar so the frame is not a grey blank at a distance.
	_flat_box(Vector3(hw * 1.7, 0.03, 0.014), red, 0.0, base_y + h - t * 0.55, t * 0.55)


# ── support: gantry — the object SUSPENDED ──────────────────────────
# Uprights well above head height, a spanning beam, knee braces, and a drop rod down to
# the crown of the body. The tallest of the three by a wide margin, which is the point:
# across a room you read gantry vs frame vs cradle from the silhouette alone. Also where
# `pylon` lands — the heaviest structure this artifact owns. A slab rising behind the body
# from base_y is buildable within rule 2 and is the obvious future native.
func _support_gantry(base_y: float, span: float, tall: float) -> void:
	var steel: StandardMaterial3D = HangarKit.painted_metal(SUPPORT_STEEL, 0.25, 0.5, 0.48)
	var dark: StandardMaterial3D = HangarKit.painted_metal(SUPPORT_DARK, 0.15, 0.6, 0.4)
	var hw: float = clampf(span * 1.3, 0.48, 1.0)
	var h: float = clampf(tall * 5.0, 1.7, 2.5)
	var t: float = 0.075

	for side in [-1.0, 1.0]:
		var sx: float = side
		_flat_box(Vector3(t, h - t, t), steel, hw * sx, base_y, 0.0)
		_flat_box(Vector3(0.26, 0.04, 0.26), dark, hw * sx, base_y, 0.0)
		_fx_strut(
			Vector3(hw * sx, base_y + h * 0.74, 0.0),
			Vector3(hw * sx * 0.42, base_y + h - t, 0.0),
			0.026, steel)
	_flat_box(Vector3(hw * 2.0 + t, t, t), steel, 0.0, base_y + h - t, 0.0)

	# Drop rod to the crown of the body, with a collar where it meets it.
	var crown: float = base_y + tall
	_fx_strut(Vector3(0, base_y + h - t, 0), Vector3(0, crown + 0.02, 0), 0.014, dark)
	_disc(0.055, 0.03, dark, crown + 0.01, 10)


# ── mark: bullseye — the fairground register ──────────────────────────
# Painted concentric rings with a raised kerb. Stacked in Y by 4 mm a ring so the
# coplanar discs cannot z-fight; from any angle that reads as flat paint.
func _mark_bullseye(base_y: float, span: float) -> void:
	var r: float = clampf(span * 1.9, 0.78, 1.05)
	var pale: StandardMaterial3D = HangarKit.painted_metal(MARK_PALE, 0.08, 0.05, 0.72)
	var red: StandardMaterial3D = HangarKit.painted_metal(MARK_RED, 0.08, 0.05, 0.7)
	var dark: StandardMaterial3D = HangarKit.painted_metal(SUPPORT_DARK, 0.1, 0.4, 0.5)

	var radii: Array = [1.0, 0.78, 0.56, 0.34, 0.15]
	for i in radii.size():
		var mat: StandardMaterial3D = red if i % 2 == 1 else pale
		if i == radii.size() - 1:
			mat = dark
		_disc(r * float(radii[i]), 0.012, mat, base_y + float(i) * 0.004, 32)

	# Kerb — segmented rather than a torus so the ring still has height at a grazing
	# camera angle, where a flat mark all but disappears. Yaw turns each segment's long
	# axis tangential: a +Y rotation of θ sends local +X to (cos θ, -sin θ) in the XZ
	# plane, so the tangent at azimuth a wants θ = -(a + π/2).
	for i in 24:
		var ang: float = TAU * float(i) / 24.0
		_flat_box(Vector3(0.075, 0.055, 0.05), dark, cos(ang) * r, base_y, sin(ang) * r, -ang - PI * 0.5)


# ── mark: grid — the range-instrument register ────────────────────────
# A dark square calibration pad, pale rules, corner ticks, and a red centre box around
# the body's feet. Opposite polarity to the bullseye on purpose: dark where that is
# pale, orthogonal where that is radial, so the two never get confused in a still.
func _mark_grid(base_y: float, span: float) -> void:
	var half: float = clampf(span * 1.75, 0.72, 1.05)
	var pad: StandardMaterial3D = HangarKit.painted_metal(SUPPORT_DARK, 0.2, 0.3, 0.62)
	var rule: StandardMaterial3D = HangarKit.painted_metal(MARK_PALE, 0.05, 0.05, 0.7)
	var red: StandardMaterial3D = HangarKit.painted_metal(MARK_RED, 0.08, 0.05, 0.7)

	_flat_box(Vector3(half * 2.0, 0.022, half * 2.0), pad, 0.0, base_y, 0.0)
	var step: float = half * 2.0 / 6.0
	for i in range(1, 6):
		var o: float = -half + step * float(i)
		_flat_box(Vector3(half * 2.0, 0.008, 0.014), rule, 0.0, base_y + 0.022, o)
		_flat_box(Vector3(0.014, 0.008, half * 2.0), rule, o, base_y + 0.022, 0.0)
	for side_x in [-1.0, 1.0]:
		for side_z in [-1.0, 1.0]:
			var sx: float = side_x
			var sz: float = side_z
			_flat_box(Vector3(0.16, 0.012, 0.028), rule, (half - 0.09) * sx, base_y + 0.022, (half - 0.04) * sz)
			_flat_box(Vector3(0.028, 0.012, 0.16), rule, (half - 0.04) * sx, base_y + 0.022, (half - 0.09) * sz)
	# Red centre box around the body's feet — the only warm thing on a cold pad, so the
	# eye lands where the shot is supposed to.
	var c: float = clampf(span * 0.62, 0.2, half - 0.12)
	for side in [-1.0, 1.0]:
		var s: float = side
		_flat_box(Vector3(c * 2.0, 0.014, 0.03), red, 0.0, base_y + 0.022, c * s)
		_flat_box(Vector3(0.03, 0.014, c * 2.0), red, c * s, base_y + 0.022, 0.0)


# ── mark: nimbus — the votive register ────────────────────────────────
# Two concentric glowing gold rings and eight radial pips. No plate at all: this one is
# light rather than paint, which is why it survives a dark room where the other two go
# muddy. Emissive on the floor also throws the body's silhouette, so it changes the
# picture even where the mark itself is out of frame.
func _mark_nimbus(base_y: float, span: float) -> void:
	var r: float = clampf(span * 1.8, 0.74, 1.0)
	var glow: StandardMaterial3D = HangarKit.emissive(MARK_GOLD, 2.6)
	var glow_dim: StandardMaterial3D = HangarKit.emissive(MARK_GOLD.darkened(0.2), 1.5)

	var outer := TorusMesh.new()
	outer.inner_radius = r - 0.05
	outer.outer_radius = r + 0.05
	outer.rings = 40
	outer.ring_segments = 8
	_fx(outer, glow, Vector3(0, base_y + 0.05, 0))

	var inner := TorusMesh.new()
	inner.inner_radius = r * 0.55 - 0.03
	inner.outer_radius = r * 0.55 + 0.03
	inner.rings = 32
	inner.ring_segments = 6
	_fx(inner, glow_dim, Vector3(0, base_y + 0.03, 0))

	# Radial pips. These want their long axis (local +Z) pointing outward, and +Y rotation
	# sends local +Z to (sin θ, cos θ) in XZ — hence θ = π/2 - a, not the tangential yaw
	# the kerb uses. Two different rotations for two different intents.
	for i in 8:
		var ang: float = TAU * float(i) / 8.0 + PI / 8.0
		_flat_box(Vector3(0.05, 0.045, 0.13), glow_dim, cos(ang) * r * 0.78, base_y, sin(ang) * r * 0.78, PI * 0.5 - ang)


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

## Token values arrive as whatever the grid parser made of them, and a token written
## without a value (`#support`) arrives as boolean true. Anything not in the allowed list
## falls back to the current value rather than building a half-formed fixture — a typo in
## a map should look like today, not like a bug.
## Retired spellings are folded FIRST, so a map written against the old grammar still
## lands on the value it meant instead of being read as a typo.
## Note what the allow-list is for `support`: all EIGHT canonical values, not the four
## this artifact builds. Accepting the whole vocabulary here and degrading at build time
## is what keeps a sibling's value from being silently swallowed.
func _axis(config_data: Dictionary, key: String, allowed: Array, current: String, aliases: Dictionary = {}) -> String:
	if not config_data.has(key):
		return current
	var want: String = str(config_data[key]).strip_edges().to_lower()
	want = str(aliases.get(want, want))
	return want if allowed.has(want) else current


func apply_grid_config(config_data: Dictionary) -> void:
	# Shape must be set before _ready builds visuals, but grid config runs after.
	# So if shape changes, rebuild.
	var body_changed: bool = false
	if config_data.has("shape"):
		var new_shape := str(config_data["shape"])
		if new_shape != _shape_id:
			_shape_id = new_shape
			body_changed = true
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

	# The fixture is rebuilt whenever either axis moves OR the body changed under it —
	# every support is dimensioned from the body's measured AABB, so a cube's frame is not
	# an apple's frame and a stale one would hang in the wrong place.
	# `support` is the canonical token; `rig` is the pre-convergence spelling, read ONLY
	# when the canonical one is absent, so a map that somehow says both cannot get the
	# loser. Zero maps in the 2048-map corpus carry either key, so on the default path
	# both branches are skipped and new_support is simply the current value.
	var new_support: String = support
	if config_data.has("support"):
		new_support = _axis(config_data, "support", SUPPORTS, support, SUPPORT_ALIASES)
	var new_mark: String = _axis(config_data, "mark", MARKS, mark)
	var fixture_changed: bool = new_support != support or new_mark != mark
	support = new_support
	mark = new_mark

	if body_changed or fixture_changed:
		if is_instance_valid(_fixture):
			_fixture.queue_free()
		_fixture = null
		# One deferred rebuild however many axes moved — two would double the geometry.
		# The body flag accumulates rather than riding on the deferred call's argument, so
		# a second config pass in the same frame cannot cancel a pending body rebuild.
		_rebuild_body_pending = _rebuild_body_pending or body_changed
		if not _rebuild_queued:
			_rebuild_queued = true
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
	_rebuild_queued = false
	if _rebuild_body_pending:
		_rebuild_body_pending = false
		_build_visual()
		_build_collision()
		_build_explosion_particles()
	_build_fixture()
