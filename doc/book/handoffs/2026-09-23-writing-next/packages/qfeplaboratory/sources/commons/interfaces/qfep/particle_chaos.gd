# particle_chaos.gd
# QFEP E(S) Term Visualization - Chaotic Particle System
# High entropy: maximum spread, random velocities, no coherence
# λ = 1 dissolution zone

extends Node3D

class_name QFEPParticleChaos

# @identity
# essence: GPU_particles(spread=180, gravity=0, angular_velocity=+-360) -> pure entropy cloud
# desire: be surrounded by particles that obey no pattern — feel the freedom of maximum entropy
# critical_parameter: spread (180 = full sphere) — the absence of preferred direction that defines chaos
# triggers: set_intensity() scales velocity and count; pulse() creates momentary burst
# emerges: transient clusters and voids in the noise — the eye finds patterns even where none exist
# needs: VR intensity control [missing], pulse trigger [missing]
# relationships: represents E(S) term; contrasts ordered_grid (F term); paired with random_cubes; feeds into lambda spectrum
# truth: entropy is not disorder but possibility — maximum spread means maximum freedom from constraint

## --- DNA (stage 2, promoted 2026-08-03) ---
##
## AXIS — CONSTRAINT: which law the free cloud is made to obey.
##
## This artifact's whole claim is in its own truth line: "entropy is not disorder but
## possibility — maximum spread means maximum freedom from constraint." And it argues that
## claim by DELETION. Four lines of _build_particles() are the argument, and every one of
## them is a removal: direction = (0,0,0) — no preferred heading; spread = 180 — the full
## sphere; gravity = (0,0,0) — no field; attractor_interaction_enabled = false — nothing
## pulling. The freedom is real, but it is invisible, because a player who has only ever
## met the unconstrained ball has no second term to read it against. Freedom from what?
##
## So the axis puts the constraints BACK, one at a time, and names each one. Nothing here
## is a parameter of the noise — the count, the speeds, the lifetime and the colour are
## untouched by every value, and a finer or coarser cloud would be exactly the
## reaction_diffusion failure: five frames that differ only in texture, which a still
## cannot tell apart from five frames of nothing. What changes is the SILHOUETTE, because
## what changes is the law:
##
##   none      the shipped lineage, byte for byte. Isotropic sphere. No field, no channel,
##             no circulation, no dissipation. Entropy with nothing to push against.
##   gravity   a field. One direction is now cheaper than the others, so the ball becomes
##             a plume that falls — chaos is still total in x and z and broken in y.
##   jet       a channel. The heading is dictated at birth (spread 12°), so the same
##             random speeds make a narrow column. Freedom of magnitude, not of direction.
##   vortex    a circulation. Emission on a thin horizontal annulus with a tangential
##             acceleration: motion is bound to a circle, and the cloud reads as a disc.
##   drag      dissipation. Damping bleeds the velocity away before the lifetime is out,
##             so the cloud collapses toward its own emitter — the thermodynamic opposite
##             of spread, and the one value where the particles are not free at all.
##
## `none` is the default and the default alone is what the three existing placements
## (QFEP_E_Term, Corridor_QFEP_E_Term, Curation_Bay_qfeplaboratory_3) get.
const CONSTRAINTS: PackedStringArray = ["none", "gravity", "jet", "vortex", "drag"]
@export_enum("none", "gravity", "jet", "vortex", "drag") var constraint: String = "none"

## Particle count
@export var particle_count: int = 200

## Emission radius
@export var emission_radius: float = 0.5

## Particle speed range
@export var speed_min: float = 0.5
@export var speed_max: float = 2.0

## Particle lifetime
@export var lifetime: float = 3.0

## Chaos color (red = entropy)
@export var chaos_color: Color = Color(0.9, 0.2, 0.2, 1.0)

# Internal
var _particles: GPUParticles3D
var _material: ParticleProcessMaterial

func _ready() -> void:
	_build_particles()

func _build_particles() -> void:
	_particles = GPUParticles3D.new()
	_particles.amount = particle_count
	_particles.lifetime = lifetime
	_particles.explosiveness = 0.0  # Continuous emission
	_particles.randomness = 1.0  # Maximum randomness
	
	# Process material - CHAOS settings
	_material = ParticleProcessMaterial.new()
	
	# Emission from sphere
	_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	_material.emission_sphere_radius = emission_radius
	
	# Random directions - full sphere spread
	_material.direction = Vector3(0, 0, 0)  # No preferred direction
	_material.spread = 180.0  # Full sphere
	
	# Velocity - chaotic range
	_material.initial_velocity_min = speed_min
	_material.initial_velocity_max = speed_max
	
	# No gravity - pure chaos
	_material.gravity = Vector3(0, 0, 0)
	
	# Random acceleration for turbulence
	_material.attractor_interaction_enabled = false
	
	# Scale variation
	_material.scale_min = 0.5
	_material.scale_max = 2.0
	
	# Color - red chaos with fade
	_material.color = chaos_color
	
	# Angular velocity - spinning particles
	_material.angular_velocity_min = -360.0
	_material.angular_velocity_max = 360.0
	
	# THE AXIS, which until now was declared, exported, documented to the value —
	# and never read. The corpus audit found it: an @export_enum and thirty lines
	# of comment specifying five silhouettes, with _build_particles() constructing
	# the unconstrained cloud regardless. A sweep would have rendered five
	# identical frames and reported the axis inert, which would have been a fact
	# about a missing function.
	#
	# Applied AFTER the free build above and never instead of it, so `none` is the
	# shipped material byte for byte: every branch below is additive and `none`
	# has no branch at all.
	_apply_constraint()

	_particles.process_material = _material

	# Particle mesh - small spheres
	var particle_mesh = SphereMesh.new()
	particle_mesh.radius = 0.02
	particle_mesh.height = 0.04
	particle_mesh.radial_segments = 8
	particle_mesh.rings = 4
	_particles.draw_pass_1 = particle_mesh
	
	# Particle material with glow
	var mesh_mat = StandardMaterial3D.new()
	mesh_mat.albedo_color = chaos_color
	mesh_mat.emission_enabled = true
	mesh_mat.emission = chaos_color
	mesh_mat.emission_energy_multiplier = 1.5
	mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	particle_mesh.material = mesh_mat
	
	add_child(_particles)

## Set chaos intensity (0-1)
func set_intensity(value: float) -> void:
	if _material:
		_material.initial_velocity_max = lerp(speed_min, speed_max * 2, value)
		_material.spread = lerp(90.0, 180.0, value)
	if _particles:
		_particles.amount = int(lerp(50, particle_count * 2, value))

## Pulse the chaos
func pulse() -> void:
	if _particles:
		_particles.explosiveness = 0.8
		await get_tree().create_timer(0.1).timeout
		_particles.explosiveness = 0.0


## Put a law back into the free cloud, one at a time, exactly as the DNA block
## above specifies. Each branch changes the SILHOUETTE — never the count, the
## speeds, the lifetime or the colour, because a finer or coarser cloud is the
## reaction_diffusion failure: five frames differing only in texture, which a
## still cannot tell from five frames of nothing.
func _apply_constraint() -> void:
	match constraint:
		"gravity":
			# A field. One direction is cheaper than the others, so the ball
			# becomes a plume: chaos still total in x and z, broken in y.
			_material.gravity = Vector3(0.0, -4.0, 0.0)
		"jet":
			# A channel. The heading is dictated at birth, so the same random
			# speeds make a narrow column — freedom of magnitude, not direction.
			_material.direction = Vector3(0.0, 1.0, 0.0)
			_material.spread = 12.0
			_material.emission_sphere_radius = emission_radius * 0.25
		"vortex":
			# A circulation. Emission on a thin horizontal annulus with tangential
			# acceleration: motion is bound to a circle and the cloud reads as a disc.
			_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			_material.emission_ring_radius = emission_radius * 1.6
			_material.emission_ring_inner_radius = emission_radius * 1.2
			_material.emission_ring_height = emission_radius * 0.12
			_material.emission_ring_axis = Vector3(0.0, 1.0, 0.0)
			_material.tangential_accel_min = 6.0
			_material.tangential_accel_max = 9.0
			_material.direction = Vector3(0.0, 0.0, 0.0)
			_material.spread = 15.0
		"drag":
			# Dissipation. Damping bleeds the velocity away before the lifetime is
			# out, so the cloud collapses toward its own emitter — the
			# thermodynamic opposite of spread, and the one value where the
			# particles are not free at all.
			_material.damping_min = 6.0
			_material.damping_max = 9.0
		_:
			pass    # "none" — the shipped lineage, untouched


## Config from a map token. Guarded twice: a word must be in the artifact's own
## allow-list AND differ from what is in play, and the rebuild only runs once
## _ready has built, because the grid calls this deferred.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("constraint"):
		return
	var want: String = str(config_data["constraint"]).strip_edges().to_lower()
	if not CONSTRAINTS.has(want) or want == constraint:
		return
	constraint = want
	if _particles == null:
		return          # _ready has not built yet; it will read the new value
	_particles.queue_free()
	_particles = null
	_build_particles()
