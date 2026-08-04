# @identity
# essence: hive.spawn(boid) -> flock(separation, alignment, cohesion) -- stationary hive releasing swarms
# desire: a hive spawning boid particles following three flocking rules -- the swarm IS the weapon
# critical_parameter: boid rules (separation, alignment, cohesion) / spawn_timer -- three rules generate all behavior
# triggers: spawn_timer releases boids; boids flock using three rules; player proximity attracts swarm
# emerges: three rules produce flocking -- separation prevents collision, alignment creates direction, cohesion mass
# needs: player tracking [has]; boid array [has]; flocking rules [has]; hive health [has]; VR interaction [missing]
# relationships: embodies swarmintelligence sequence; three rules that generate coordinated group behavior
# truth: separation, alignment, cohesion -- three rules, and the swarm organizes itself.

extends Node3D
class_name SwarmHive
## Swarm Intelligence hazard — a stationary hive that spawns boid particles.
## Boids follow separation/alignment/cohesion + player-seeking.
## Teaches emergent collective behavior from simple local rules.

signal enemy_destroyed(enemy: Node3D)

@export_group("Swarm")
@export var max_boids: int = 20
@export var spawn_interval: float = 0.3
@export var boid_speed: float = 3.0
@export var boid_damage: float = 5.0

@export_group("Boid Rules")
@export var separation_radius: float = 0.5
@export var alignment_radius: float = 1.5
@export var cohesion_radius: float = 2.5
@export var separation_weight: float = 2.0
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0
@export var player_seek_weight: float = 1.5
@export var detection_radius: float = 8.0

@export_group("Appearance")
@export var hive_color: Color = Color(0.6, 0.45, 0.15)
@export var boid_color: Color = Color(0.9, 0.7, 0.1)
@export var emission_color: Color = Color(1.0, 0.8, 0.2)

# ═══════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — accord
# ═══════════════════════════════════════════════════════════════════════
#
# WHICH OF REYNOLDS' THREE RULES THE NEIGHBOURHOOD IS ACTUALLY OBEYING, and
# therefore what standing shape the swarm holds. Same word, same ladder, same
# meaning as boid_manager and boids_aquarium — one family, one vocabulary,
# differing only in scale (a 20 m box there, a 0.5 m hive here). This
# artifact's own critical_parameter is literally "boid rules (separation,
# alignment, cohesion)", and its truth is "three rules, and the swarm
# organizes itself" — accord is that sentence made turnable.
#
#   school   the shipped swarm, untouched: boids released one every
#            spawn_interval on a random outward heading, all three rules at
#            the shipped weights (sep 2.0 / ali 1.0 / coh 1.0) and the
#            shipped 3.0 m/s cap. A loose drifting cloud around the hive.
#   orb      cohesion wins (coh 4.5 / sep 0.4 / ali 0.6). Deposited as a
#            solid 0.6 m-radius ball above the hive with tangential
#            velocities — a bead hanging over the box.
#   lane     alignment wins (ali 4.5 / coh 0.6 / sep 0.9). Deposited as a
#            2.4 x 0.16 x 2.4 m horizontal sheet with every velocity +X —
#            twenty motes lying parallel in one thin plane.
#   lattice  separation wins (sep 4.5 / coh 0.0 / ali 0.0). Deposited on a
#            regular grid spanning 1.8 x 0.6 x 1.8 m, spaced wider than
#            separation_radius so every mote sits in visible air.
#
# NOT A TIME AXIS, and the three deposited values do NOT wait for a flock to
# emerge — each deposits the settled arrangement its rule holds, directly and
# synchronously, and carries a low speed cap so that arrangement STANDS across
# the capture window instead of decaying into the same drifting cloud as
# `school`. The cap is the mechanism by which a standing shape stands, not the
# thing declared. `school` keeps the shipped speeds and the shipped drift,
# because the default must be the pre-promotion look.
@export_group("DNA")
## DNA — which of Reynolds' three rules the neighbourhood is actually obeying,
## and therefore what standing shape the swarm holds around its hive.
@export_enum("school", "orb", "lane", "lattice") var accord: String = "school"

const ACCORDS: PackedStringArray = ["school", "orb", "lane", "lattice"]

# ── Deposit geometry (metres), sized to a 0.5 m hive ────────────────────
const DEPOSIT_Y: float = 0.8             # centre height above the hive origin
const ORB_RADIUS: float = 0.6
const ORB_SPEED: float = 0.03            # tangential; holds r over the capture window
const LANE_SPAN: float = 2.4
const LANE_THICKNESS: float = 0.16
const LANE_SPEED: float = 0.05           # +X, and exactly the cap so alignment nets zero
const LATTICE_SPAN_XZ: float = 1.8
const LATTICE_SPAN_Y: float = 0.6
const LATTICE_SPEED: float = 0.02

# The shipped rule weights and speed cap, restored before every deposit so that
# switching accord twice in one session cannot accumulate. No placement authors
# these — they are reachable only from the .tscn, and the one placed token is a
# bare token — so restoring them can never clobber a value someone chose.
const SHIPPED_SEPARATION: float = 2.0
const SHIPPED_ALIGNMENT: float = 1.0
const SHIPPED_COHESION: float = 1.0
const SHIPPED_BOID_SPEED: float = 3.0

# ── Determinism. Every draw in the build path comes from _rng. The global RNG
# is never touched — seed()/randomize() from inside an artifact reseeds the
# whole process and poisons every other artifact in the same run. Two builds of
# one accord value are identical, which is what lets the critic attribute a
# difference between two frames to the axis rather than to the dice.
const SEED_SCHOOL: int = 810_101
const SEED_ORB: int = 810_102
const SEED_LANE: int = 810_103
const SEED_LATTICE: int = 810_104

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _built: bool = false

# State
var _player_node: Node3D = null
var _boids: Array[Dictionary] = []  # {node, velocity, alive}
var _spawn_timer: float = 0.0
var _hive_health: float = 100.0

# Visual
var _hive_mesh: MeshInstance3D = null
var _hive_mat: StandardMaterial3D
var _boid_mat: StandardMaterial3D
var _boid_mesh: SphereMesh = null


func _ready() -> void:
	_create_materials()
	_build_hive()
	_find_player()
	add_to_group("enemy")

	# Collision for the hive itself
	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.6, 0.6, 0.6)
	col.shape = shape
	col.position.y = 0.4
	area.add_child(col)
	area.collision_layer = 4
	area.collision_mask = 0
	add_child(area)

	# Pre-create boid mesh template
	_boid_mesh = SphereMesh.new()
	_boid_mesh.radius = 0.06
	_boid_mesh.height = 0.12
	_boid_mesh.radial_segments = 8
	_boid_mesh.rings = 4

	# Deposit last: it needs the boid mesh template above. Synchronous, bounded
	# by max_boids, and it RETURNS — no await, no wait-for-convergence.
	_deposit_accord()
	_built = true


# ── Accord deposits ─────────────────────────────────────────────────────

## `school` deposits NOTHING. It seeds the stream that _spawn_boid draws from
## and then leaves the shipped timer to release boids exactly as it always has.
func _deposit_accord() -> void:
	match accord:
		"orb":
			_deposit_orb()
		"lane":
			_deposit_lane()
		"lattice":
			_deposit_lattice()
		_:
			_rng.seed = SEED_SCHOOL


## Restore the shipped rule weights, then let the chosen deposit overwrite the
## ones its rule wins on.
func _reset_rules() -> void:
	separation_weight = SHIPPED_SEPARATION
	alignment_weight = SHIPPED_ALIGNMENT
	cohesion_weight = SHIPPED_COHESION
	boid_speed = SHIPPED_BOID_SPEED


## orb — cohesion wins. A solid ball above the hive, every velocity tangential
## so the bead turns instead of collapsing.
func _deposit_orb() -> void:
	_rng.seed = SEED_ORB
	_reset_rules()
	separation_weight = 0.4
	alignment_weight = 0.6
	cohesion_weight = 4.5
	boid_speed = ORB_SPEED

	var centre: Vector3 = global_position + Vector3(0.0, DEPOSIT_Y, 0.0)
	for _i in range(max_boids):
		var dir: Vector3 = _rand_dir()
		# Cube root of a uniform draw fills the ball evenly rather than piling
		# every boid onto the surface.
		var r: float = ORB_RADIUS * pow(_rng.randf(), 1.0 / 3.0)
		var tangent: Vector3 = Vector3.UP.cross(dir)
		if tangent.length() < 0.001:
			tangent = Vector3.RIGHT.cross(dir)
		_place_boid(centre + dir * r, tangent.normalized() * ORB_SPEED)


## lane — alignment wins. A thin horizontal sheet, every velocity +X at exactly
## the speed cap so the alignment term nets to zero and the heading holds.
func _deposit_lane() -> void:
	_rng.seed = SEED_LANE
	_reset_rules()
	separation_weight = 0.9
	alignment_weight = 4.5
	cohesion_weight = 0.6
	boid_speed = LANE_SPEED

	var origin: Vector3 = global_position + Vector3(0.0, DEPOSIT_Y, 0.0)
	var hx: float = LANE_SPAN * 0.5
	var hy: float = LANE_THICKNESS * 0.5
	for _i in range(max_boids):
		var offset: Vector3 = Vector3(
			_rng.randf_range(-hx, hx),
			_rng.randf_range(-hy, hy),
			_rng.randf_range(-hx, hx)
		)
		_place_boid(origin + offset, Vector3(LANE_SPEED, 0.0, 0.0))


## lattice — separation wins. A regular grid whose spacing is WIDER than
## separation_radius, so the rule is satisfied everywhere and the ranks stand.
##
## The rank count is derived from max_boids rather than hard-coded, so the grid
## is full at any population instead of leaving a half-lattice and a heap.
func _deposit_lattice() -> void:
	_rng.seed = SEED_LATTICE
	_reset_rules()
	separation_weight = 4.5
	alignment_weight = 0.0
	cohesion_weight = 0.0
	boid_speed = LATTICE_SPEED

	var origin: Vector3 = global_position + Vector3(0.0, DEPOSIT_Y, 0.0)
	var n: int = maxi(max_boids, 1)
	var rows: int = clampi(int(round(float(n) / 10.0)), 2, 4)
	var cols: int = maxi(2, int(ceil(sqrt(float(n) / float(rows)))))
	# Bounded widening: at most a handful of steps, never a search.
	for _pad in range(8):
		if cols * rows * cols >= n:
			break
		cols += 1

	var sx: float = LATTICE_SPAN_XZ / float(maxi(cols - 1, 1))
	var sy: float = LATTICE_SPAN_Y / float(maxi(rows - 1, 1))
	var x0: float = -LATTICE_SPAN_XZ * 0.5
	var y0: float = -LATTICE_SPAN_Y * 0.5

	for i in range(n):
		var ix: int = i % cols
		var iz: int = int(i / cols) % cols
		# Clamped so an oversized population can never stack above the block.
		var iy: int = mini(int(i / (cols * cols)), rows - 1)
		var offset: Vector3 = Vector3(
			x0 + float(ix) * sx,
			y0 + float(iy) * sy,
			x0 + float(iz) * sx
		)
		_place_boid(origin + offset, _rand_dir() * LATTICE_SPEED)


## One boid, built the same way _spawn_boid builds one, but placed rather than
## launched.
func _place_boid(pos: Vector3, vel: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _boid_mesh
	mi.set_surface_override_material(0, _boid_mat.duplicate())
	add_child(mi)
	mi.global_position = pos
	_boids.append({
		"node": mi,
		"velocity": vel,
	})


## A unit vector from the seeded stream. Never returns zero.
func _rand_dir() -> Vector3:
	var v: Vector3 = Vector3(
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0)
	)
	if v.length() < 0.0001:
		return Vector3.FORWARD
	return v.normalized()


## Free the current swarm and lay down the one the new accord names.
func _rebuild_swarm() -> void:
	for b in _boids:
		if is_instance_valid(b["node"]):
			b["node"].queue_free()
	_boids.clear()
	_spawn_timer = 0.0
	_reset_rules()
	_deposit_accord()


func _process(delta: float) -> void:
	if not is_instance_valid(_player_node):
		_find_player()

	# Spawn boids
	_spawn_timer += delta
	if _spawn_timer >= spawn_interval and _boids.size() < max_boids:
		_spawn_timer = 0.0
		_spawn_boid()

	# Update boids
	_update_boids(delta)


func _create_materials() -> void:
	_hive_mat = StandardMaterial3D.new()
	_hive_mat.albedo_color = hive_color
	_hive_mat.emission_enabled = true
	_hive_mat.emission = emission_color * 0.3
	_hive_mat.emission_energy_multiplier = 1.0

	_boid_mat = StandardMaterial3D.new()
	_boid_mat.albedo_color = boid_color
	_boid_mat.emission_enabled = true
	_boid_mat.emission = emission_color
	_boid_mat.emission_energy_multiplier = 2.0


func _build_hive() -> void:
	# Hexagonal prism hive body
	var body := BoxMesh.new()
	body.size = Vector3(0.5, 0.5, 0.5)
	_hive_mesh = MeshInstance3D.new()
	_hive_mesh.mesh = body
	_hive_mesh.set_surface_override_material(0, _hive_mat)
	_hive_mesh.position.y = 0.4
	add_child(_hive_mesh)

	# Honeycomb accent — smaller boxes on faces
	var accent_mat: StandardMaterial3D = _hive_mat.duplicate()
	accent_mat.albedo_color = hive_color.lightened(0.2)
	var accent := BoxMesh.new()
	accent.size = Vector3(0.12, 0.12, 0.12)
	for i in range(6):
		var a := MeshInstance3D.new()
		a.mesh = accent
		a.set_surface_override_material(0, accent_mat)
		var angle: float = i * TAU / 6.0
		a.position = Vector3(cos(angle) * 0.22, 0.0, sin(angle) * 0.22)
		_hive_mesh.add_child(a)


func _spawn_boid() -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _boid_mesh
	mi.set_surface_override_material(0, _boid_mat.duplicate())
	add_child(mi)

	# Random direction outward from hive. The draw now comes from the artifact's
	# own seeded stream instead of the process RNG: the same uniform heading on
	# the same circle, from a source that two runs share, so `school` photographs
	# the same cloud twice. The distribution, the ring and the launch speed are
	# untouched.
	var angle: float = _rng.randf() * TAU
	var dir := Vector3(cos(angle), 0.3, sin(angle)).normalized()

	mi.global_position = global_position + Vector3(0.0, 0.4, 0.0) + dir * 0.3

	_boids.append({
		"node": mi,
		"velocity": dir * boid_speed * 0.5,
	})


func _update_boids(delta: float) -> void:
	var player_pos: Vector3 = Vector3.ZERO
	var has_player: bool = false
	if is_instance_valid(_player_node):
		player_pos = _player_node.global_position
		has_player = true

	var positions: Array[Vector3] = []
	var velocities: Array[Vector3] = []

	# Gather positions
	for b in _boids:
		if is_instance_valid(b["node"]):
			positions.append(b["node"].global_position)
			velocities.append(b["velocity"])
		else:
			positions.append(Vector3.ZERO)
			velocities.append(Vector3.ZERO)

	# Update each boid
	var to_remove: Array[int] = []
	for i in range(_boids.size()):
		var boid: Dictionary = _boids[i]
		if not is_instance_valid(boid["node"]):
			to_remove.append(i)
			continue

		var pos: Vector3 = positions[i]
		var vel: Vector3 = velocities[i]

		# Boid rules
		var sep := Vector3.ZERO
		var ali := Vector3.ZERO
		var coh := Vector3.ZERO
		var sep_count: int = 0
		var ali_count: int = 0
		var coh_count: int = 0

		for j in range(_boids.size()):
			if i == j:
				continue
			var diff: Vector3 = pos - positions[j]
			var dist: float = diff.length()

			if dist < separation_radius and dist > 0.01:
				sep += diff.normalized() / dist
				sep_count += 1
			if dist < alignment_radius:
				ali += velocities[j]
				ali_count += 1
			if dist < cohesion_radius:
				coh += positions[j]
				coh_count += 1

		var steering := Vector3.ZERO

		if sep_count > 0:
			steering += (sep / float(sep_count)).normalized() * separation_weight
		if ali_count > 0:
			steering += ((ali / float(ali_count)).normalized() - vel.normalized()) * alignment_weight
		if coh_count > 0:
			var center: Vector3 = coh / float(coh_count)
			steering += (center - pos).normalized() * cohesion_weight

		# Player seeking
		if has_player:
			var to_player: Vector3 = player_pos - pos
			var player_dist: float = to_player.length()
			if player_dist < detection_radius:
				steering += to_player.normalized() * player_seek_weight

				# Contact damage
				if player_dist < 0.3:
					var gm = get_node_or_null("/root/GameManager")
					if gm and gm.has_method("apply_health_damage"):
						gm.apply_health_damage(boid_damage * delta)

		# Hive tethering — don't wander too far
		var to_hive: Vector3 = global_position - pos
		if to_hive.length() > detection_radius * 1.5:
			steering += to_hive.normalized() * 2.0

		# Apply steering
		vel += steering * delta * 5.0
		if vel.length() > boid_speed:
			vel = vel.normalized() * boid_speed

		boid["velocity"] = vel
		boid["node"].global_position += vel * delta

		# Keep above ground
		if boid["node"].global_position.y < 0.1:
			boid["node"].global_position.y = 0.1
			boid["velocity"].y = abs(boid["velocity"].y) * 0.5

	# Clean up dead boids
	for idx in range(to_remove.size() - 1, -1, -1):
		_boids.remove_at(to_remove[idx])


# ── Damage Interface ────────────────────────────────────────────────────

func take_damage(amount: float) -> void:
	_apply_damage(amount)

func apply_damage(amount: float) -> void:
	_apply_damage(amount)

func damage(amount: float) -> void:
	_apply_damage(amount)

func _apply_damage(amount: float) -> void:
	_hive_health -= max(0.0, amount)
	if _hive_health <= 0.0:
		# Disperse all boids
		for b in _boids:
			if is_instance_valid(b["node"]):
				var tween := get_tree().create_tween()
				tween.tween_property(b["node"], "scale", Vector3.ZERO, 0.5)
				tween.tween_callback(b["node"].queue_free)
		_boids.clear()
		enemy_destroyed.emit(self)
		var die_tween := get_tree().create_tween()
		die_tween.tween_property(_hive_mesh, "scale", Vector3.ZERO, 1.0)
		die_tween.tween_callback(queue_free)


func _find_player() -> void:
	var scene: Node = get_tree().current_scene
	if not scene:
		return
	for candidate in [
		get_tree().get_first_node_in_group("player"),
		scene.find_child("XROrigin3D", true, false),
		scene.find_child("Player", true, false),
	]:
		if candidate is Node3D:
			_player_node = candidate
			return


func configure(config: Dictionary) -> void:
	if config.has("boids"):
		max_boids = int(config["boids"])
	if config.has("damage"):
		boid_damage = float(config["damage"])

## Called via call_deferred by GridInteractablesComponent, AFTER _ready().
##
## An UNKNOWN value is IGNORED rather than assigned: a silent fallback to the
## default is how a sweep publishes N identical frames and calls the axis inert.
## The swarm is rebuilt only when accord actually CHANGED and only once _ready
## has already built — the one placed token carries no config at all, and the
## pre-existing boids/damage keys must not tear down a live swarm.
func apply_grid_config(config: Dictionary) -> void:
	configure(config)

	if not config.has("accord"):
		return
	var wanted: String = str(config["accord"]).strip_edges().to_lower()
	if not ACCORDS.has(wanted):
		return
	if wanted == accord:
		return

	accord = wanted
	if not _built:
		return
	_rebuild_swarm()
