# reactive_particle_field.gd
# A field of particles that demonstrates QFEP visually
# Low lambda: ordered grid, High lambda: chaotic swarm

extends Node3D
class_name ReactiveParticleField

# Configuration
@export var particle_count := 100
@export var field_size := Vector3(2.0, 1.5, 2.0)

## AXIS — FORMATION: what this field treats as ORDER.
##
## λ decides how much order the system buys. It never decides what order LOOKS like —
## and this artifact answers that second question silently, in one line of geometry.
## `_calculate_grid_positions()` lays a cubic lattice, so when λ falls the swarm falls
## into a crystal, and every player who ever watched it learned that ordered means
## regular, isotropic, close-packed. That is one physics tradition's answer, not the
## world's. A cell membrane is order and it is a SURFACE. An orbit is order and it is
## a CIRCLE. Sediment is order and it is LAYERS. None of them are crystals, and none of
## them are less ordered for it.
##
## So the axis is the attractor: the target set the field falls toward while λ is low
## enough to pull. The lesson is untouched — λ still runs order ↔ chaos, the colour
## ramp and every force branch are byte for byte what they were — but the picture of
## "ordered" stops being a fact about nature and becomes a choice with a name on it.
##
##   lattice   the legacy lineage, byte for byte: a 5×5×5 cubic grid filling the box.
##   shell     a Fibonacci sphere on the field's boundary — order as a MEMBRANE, hollow,
##             all structure at the edge and nothing in the middle.
##   ring      one horizontal annulus at mid height — order as an ORBIT: a bright
##             ellipse from the camera's angle, the box otherwise empty.
##   column    five stacked plates of twenty — order as STRATA, sedimentary, layered
##             in the one axis gravity would have picked if this field had any.
##   drift     no attractor at all: each unit's target is where it already is, so the
##             gas stays a gas and only the swirl moves it. Order as nothing.
##
## ONE SCENE, FOUR REGISTRY NAMES. reactive_particle_field, reactive_particles,
## edge_particles and emergence_zone are the same file under four tokens, so this axis
## is shared vocabulary across all four by construction — and if the sweep is honest
## they will measure alike, which is the confirmation.
@export_enum("lattice", "shell", "ring", "column", "drift") var formation: String = "lattice"
const FORMATIONS: PackedStringArray = ["lattice", "shell", "ring", "column", "drift"]

## Seed for the units' scattered starting positions. −1 keeps today's behaviour
## (a fresh random gas on every spawn); any value ≥ 0 makes the start reproducible.
## A sweep NEEDS that: this is a damped physics field photographed 1.1 s after birth,
## so without a seed five variants of an axis are also five different gases, and the
## noise gets measured as the axis.
@export var field_seed: int = -1

# State
var current_lambda := 0.4
var current_phi := 0.0
var particles: Array[RigidBody3D] = []
var particle_targets: Array[Vector3] = []
var _rng := RandomNumberGenerator.new()

# Animation
var time := 0.0

# Colors
const COLOR_ORDER := Color(0.3, 0.5, 1.0)
const COLOR_EDGE := Color(0.3, 1.0, 0.5)
const COLOR_CHAOS := Color(1.0, 0.4, 0.3)

func _ready():
	_read_dna_meta()
	if field_seed < 0:
		_rng.randomize()
	else:
		_rng.seed = field_seed
	_create_particles()
	_calculate_grid_positions()

	add_to_group("qfep_reactive")
	add_to_group("interactable")

	_connect_to_sliders()


# The grid sets `config_*` metadata BEFORE add_child, so this runs ahead of the build.
# Unknown words keep the default — an axis must never be able to blank an artifact by
# typo, and four registry tokens ride on this one file.
func _read_dna_meta() -> void:
	if has_meta("config_formation"):
		var f_in: String = str(get_meta("config_formation")).strip_edges().to_lower()
		formation = f_in if FORMATIONS.has(f_in) else formation
	if has_meta("config_field_seed"):
		field_seed = int(str(get_meta("config_field_seed")))


# There was no config hook here at all, so the axis would have been unreachable from a
# map token: GridInteractablesComponent calls this on the ROOT and fell through to
# "no configuration method found". GATED BY DATA — a config without one of these two
# keys returns before touching anything, so the 15 existing placements cannot move.
func apply_grid_config(config: Dictionary) -> void:
	var touched: bool = false
	if config.has("formation"):
		var f_in: String = str(config["formation"]).strip_edges().to_lower()
		if FORMATIONS.has(f_in):
			formation = f_in
			touched = true
	if config.has("field_seed"):
		field_seed = int(str(config["field_seed"]))
		touched = true
	if not touched:
		return
	for p in particles:
		if is_instance_valid(p):
			p.queue_free()
	particles.clear()
	particle_targets.clear()
	if field_seed < 0:
		_rng.randomize()
	else:
		_rng.seed = field_seed
	_create_particles()
	_calculate_grid_positions()

func _create_particles():
	for i in range(particle_count):
		var particle := _create_single_particle(i)
		particles.append(particle)
		add_child(particle)

func _create_single_particle(index: int) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = "Particle_%d" % index
	body.gravity_scale = 0.0  # No gravity
	body.linear_damp = 3.0    # Damping for smooth movement
	body.angular_damp = 2.0
	
	# Visual
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.03
	sphere.height = 0.06
	mesh_instance.mesh = sphere
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR_EDGE
	mat.emission_enabled = true
	mat.emission = COLOR_EDGE
	mat.emission_energy_multiplier = 0.5
	mesh_instance.material_override = mat
	
	body.add_child(mesh_instance)
	
	# Collision (small)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.03
	collision.shape = shape
	body.add_child(collision)
	
	# Random starting position. Drawn from the artifact's OWN generator rather than the
	# global one so `field_seed` can hold it still; at field_seed = -1 the generator is
	# randomize()d, which is the same gas from a different stream.
	body.position = Vector3(
		_rng.randf_range(-field_size.x/2, field_size.x/2),
		_rng.randf_range(-field_size.y/2, field_size.y/2),
		_rng.randf_range(-field_size.z/2, field_size.z/2)
	)

	return body

func _calculate_grid_positions():
	# Calculate ordered grid positions for when lambda is low
	particle_targets.clear()

	# FORMATION — which ordered set the field falls toward. Branch FIRST and return, so
	# "lattice" drops through to the original cubic-grid body below with nothing above it
	# touched. Every other value fills particle_targets itself and nothing else changes:
	# the force branches, the colour ramp and the λ thresholds are all downstream of this
	# list and never look at what shape it is.
	match formation:
		"shell":
			_targets_shell()
			return
		"ring":
			_targets_ring()
			return
		"column":
			_targets_column()
			return
		"drift":
			_targets_drift()
			return
		_:
			pass

	var grid_size: int = ceili(pow(particle_count, 1.0/3.0))
	var spacing := Vector3(
		field_size.x / float(grid_size),
		field_size.y / float(grid_size),
		field_size.z / float(grid_size)
	)
	
	var index: int = 0
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				if index >= particle_count:
					break
				
				var pos := Vector3(
					(float(x) - grid_size/2.0 + 0.5) * spacing.x,
					(float(y) - grid_size/2.0 + 0.5) * spacing.y,
					(float(z) - grid_size/2.0 + 0.5) * spacing.z
				)
				particle_targets.append(pos)
				index += 1

func _physics_process(delta):
	time += delta
	
	_update_particles(delta)

func _update_particles(_delta):
	var color := _get_current_color()
	
	for i in range(particles.size()):
		var particle := particles[i]
		var target := particle_targets[i] if i < particle_targets.size() else Vector3.ZERO
		
		# Calculate force based on lambda
		var force := Vector3.ZERO
		
		if current_lambda < 0.3:
			# Strong attraction to grid position (order)
			var to_target := target - particle.position
			force = to_target * 5.0 * (1.0 - current_lambda * 2)
			
		elif current_lambda < 0.55:
			# Weak attraction + some wandering (edge of chaos)
			var to_target := target - particle.position
			force = to_target * 2.0
			
			# Add some swirling motion
			var swirl := Vector3(
				sin(time * 2 + i * 0.5) * 0.3,
				cos(time * 1.5 + i * 0.3) * 0.2,
				sin(time * 1.8 + i * 0.7) * 0.3
			)
			force += swirl
			
		else:
			# Random motion (chaos)
			var chaos_strength: float = (current_lambda - 0.55) / 0.45
			force = Vector3(
				randf_range(-1, 1),
				randf_range(-1, 1),
				randf_range(-1, 1)
			) * chaos_strength * 2.0
			
			# Weak containment
			if particle.position.length() > field_size.length() / 2:
				force -= particle.position.normalized() * 0.5
		
		# Apply phi (embrace or resist change)
		if current_phi > 0:
			force *= 1.0 + current_phi * 0.5  # More dynamic
		else:
			force *= 1.0 + current_phi * 0.3  # More damped (phi is negative)
		
		particle.apply_central_force(force)
		
		# Update color
		var mesh := particle.get_child(0) as MeshInstance3D
		if mesh:
			var mat := mesh.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color = color
				mat.emission = color

func _get_current_color() -> Color:
	if current_lambda < 0.3:
		return COLOR_ORDER.lerp(COLOR_EDGE, current_lambda / 0.3)
	elif current_lambda < 0.55:
		return COLOR_EDGE
	else:
		return COLOR_EDGE.lerp(COLOR_CHAOS, (current_lambda - 0.55) / 0.45)

func on_lambda_changed(lambda: float):
	current_lambda = lambda

func on_phi_changed(phi: float):
	current_phi = phi

func _connect_to_sliders():
	await get_tree().process_frame

	var sliders = get_tree().get_nodes_in_group("qfep_slider")
	for slider in sliders:
		if slider.has_signal("lambda_changed"):
			slider.lambda_changed.connect(on_lambda_changed)
		if slider.has_signal("phi_changed"):
			slider.phi_changed.connect(on_phi_changed)
	print("ReactiveParticleField: Connected to sliders")


# ── FORMATION ────────────────────────────────────────────────────────────────
# Four alternative attractors, each filling particle_targets with exactly
# particle_count entries in the field's own local space — the same contract the
# cubic lattice keeps. Nothing downstream knows the difference.

## SHELL — order as a membrane. A Fibonacci sphere on the field boundary: evenly spaced
## on the surface, hollow at the centre. The silhouette is a ball outline, not a block.
func _targets_shell() -> void:
	var rx: float = field_size.x * 0.5
	var ry: float = field_size.y * 0.5
	var rz: float = field_size.z * 0.5
	var ga: float = PI * (3.0 - sqrt(5.0))
	for i in range(particle_count):
		var t: float = (float(i) + 0.5) / float(particle_count)
		var yy: float = 1.0 - 2.0 * t
		var rad: float = sqrt(maxf(0.0, 1.0 - yy * yy))
		var th: float = ga * float(i)
		particle_targets.append(Vector3(cos(th) * rad * rx, yy * ry, sin(th) * rad * rz))


## RING — order as an orbit. One horizontal annulus at mid height; from any camera above
## the horizon it reads as an ellipse of light with an empty box around it.
func _targets_ring() -> void:
	var rx: float = field_size.x * 0.45
	var rz: float = field_size.z * 0.45
	for i in range(particle_count):
		var a: float = TAU * float(i) / float(particle_count)
		particle_targets.append(Vector3(cos(a) * rx, 0.0, sin(a) * rz))


## COLUMN — order as strata. Five stacked plates of twenty: the same count as the lattice,
## organised in the one axis a field with no gravity has no reason to prefer.
func _targets_column() -> void:
	var layers: int = 5
	var per: int = ceili(float(particle_count) / float(layers))
	var side: int = ceili(sqrt(float(per)))
	var span: int = maxi(side - 1, 1)
	var sx: float = field_size.x * 0.72
	var sz: float = field_size.z * 0.72
	for i in range(particle_count):
		var li: int = i / per
		var k: int = i % per
		var fx: float = (float(k % side) / float(span) - 0.5) * sx
		var fz: float = (float(k / side) / float(span) - 0.5) * sz
		var fy: float = -field_size.y * 0.5 + (float(li) + 0.5) * (field_size.y / float(layers))
		particle_targets.append(Vector3(fx, fy, fz))


## DRIFT — order as nothing. Each unit's target is where it was born, so the attraction
## term is ~zero and only the swirl moves it. The gas never condenses into anything.
func _targets_drift() -> void:
	for i in range(particles.size()):
		particle_targets.append(particles[i].position)
