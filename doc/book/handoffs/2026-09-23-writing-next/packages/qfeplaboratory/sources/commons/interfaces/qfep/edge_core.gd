# edge_core.gd
# QFEP Edge of Chaos Core - Central Visualization
# The heart of the edge of chaos: λ ≈ 0.4
# Alive, pulsing, dancing - where complexity emerges

extends Node3D

class_name QFEPEdgeCore

# @identity
# essence: pulsing_sphere(frequency=f(lambda)) + ring_particles(orbit) -> living core at lambda~0.4
# desire: stand before the heart of the edge of chaos and feel it breathe
# critical_parameter: lambda distance from 0.4 — the closer to edge, the more alive the pulse
# triggers: set_lambda() shifts pulse speed, color (blue->green->red), and amplitude; pulse() creates burst
# emerges: the core appears to breathe — counter-pulsing inner/outer spheres create an organic heartbeat
# needs: VR lambda connection [missing], touch-to-pulse [missing]
# relationships: central to QFEP_Edge_Of_Chaos map; depends on lambda_slider; contrasts ordered_grid (dead) and chaos_particles (dissolved)
# truth: life does not exist at order or chaos but at the narrow boundary between them — the edge is where complexity breathes

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION — edge_core
#
#   station   WHERE ON THE ORDER↔CHAOS LINE THIS BODY IS STANDING
#             edge · order · chaos
#
# WHAT WAS ALREADY TRUE. This artifact's whole claim is a claim about a
# POSITION: "life does not exist at order or chaos but at the narrow boundary
# between them". It has a set_lambda() that shifts colour blue→green→red and
# amplitude with distance from λ = 0.4 — and NOTHING IN THE REPOSITORY CALLS
# IT. qfep_reactor connects a slider to its own set_lambda, not to this one, so
# in all three placements (QFEP_Edge_Of_Chaos, its corridor twin, and the
# qfeplaboratory curation bay) the core stands green, alive and pulsing, for
# every value of λ there is. An object that can only ever draw the answer is
# the contradiction of the claim it is there to make: you cannot see that the
# edge is NARROW if the two things it is narrow between are never in the room.
#
# So the axis is the position, and it is read out of the artifact's own
# set_lambda(): ORDER_TINT and CHAOS_TINT below are literally the two colours
# that function lerps toward at λ = 0 and λ = 1, and `edge` is the green it
# already ships. Nothing here is invented; what was a runtime response to a
# signal nobody sends becomes a standing state a map can place.
#
#   edge   (DEFAULT, the lineage) translucent green shell, bright counter-
#          pulsing inner core, a ring of particles orbiting it. Alive, and
#          soft-edged: you cannot say where the body stops.
#   order  the same anatomy crystallised. The shell is faceted — seven
#          segments, four rings, so the sphere becomes a solid you can count
#          the faces of — the ring of particles becomes TWELVE FIXED NODES at
#          exact intervals, and _process returns immediately: no pulse, no
#          rotation, no shimmer. Perfect, legible, and dead. What it hides is
#          that anything was ever moving.
#   chaos  the shell is gone — the boundary is the first thing to go — and the
#          core is a dim speck inside ninety scattered points with nothing
#          holding them. There is still something there; there is no longer
#          anything you could point at and call the object. What it hides is
#          the centre.
#
# WHY NOT THE PULSE, which is the tempting knob and the one the identity block
# names. The evidence here is ONE STILL PNG per value, and a rate is invisible
# to a still — info_board was swept across five duration exports and produced
# six identical tiles. pulse_speed and pulse_amount stay exports and stay
# undeclared. Every rung above is FORM: facet count, node count, a shell that
# is there or is not.
#
# KIN, AND WHERE THE FAMILY STOPS. lambda_slider and phi_slider share
# `calibration` (optimum · band · dispute · gap · none), which is about how a
# RAIL marks the right answer. This is not a rail and has no scale to mark, so
# that word would be a false cousin. fluid_form (φ>0) and rigid_sculpture (φ<0)
# are bodies at positions like this one is, and `station` would fit all three —
# but not one value list, because their line is φ (resist ↔ embrace change) and
# this one's is λ (order ↔ chaos). Same question, different axis of the
# formula; a shared word with two vocabularies would claim a kinship the
# geometry does not have.
#
# NOT ROUTED THROUGH station: set_lambda() itself is untouched, so a live λ
# driver still overrides the colour exactly as before — `station` is where the
# core stands when nothing is driving it, which today is everywhere.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS. edge is the legacy lineage. The registry declaration is derived
## from THIS LINE by tools/apply_dna_block.py.
@export_enum("edge", "order", "chaos") var station: String = "edge"

## The allow-list a map token is checked against. An unknown word falls back to
## the shipped look rather than stranding a placement.
const STATIONS: PackedStringArray = ["edge", "order", "chaos"]

## The two ends, copied off set_lambda(): the blue it lerps toward below 0.4 and
## the red it lerps toward above it.
const ORDER_TINT: Color = Color(0.2, 0.4, 0.9, 1.0)
const CHAOS_TINT: Color = Color(0.9, 0.2, 0.2, 1.0)

## Fixed so the scatter is one arrangement and not a new object every boot.
const SCATTER_SEED: int = 40404

## Core size
@export var core_radius: float = 0.4

## Pulse parameters
@export var pulse_speed: float = 1.0
@export var pulse_amount: float = 0.1

## Rotation speed
@export var rotation_speed: float = 0.3

## Particle ring
@export var ring_particles: int = 100

## Edge color (green = life)
@export var edge_color: Color = Color(0.2, 0.9, 0.4, 1.0)

# Internal
var _core_mesh: MeshInstance3D
var _core_material: StandardMaterial3D
var _inner_mesh: MeshInstance3D
var _particles: GPUParticles3D
var _time: float = 0.0
var _frozen: bool = false
var _built: bool = false
var _parts: Array[Node] = []

func _ready() -> void:
	_read_station()
	_frozen = station == "order"
	_build_core()
	_build_inner()
	_build_ring_particles()
	add_to_group("qfep_visualizations")
	_built = true

## A map token reaches here as metadata the grid stamps before add_child; the
## sweep sets the export directly, so the export is the fallback.
func _read_station() -> void:
	var want: String = station
	if has_meta("config_station"):
		want = str(get_meta("config_station"))
	elif has_meta("station"):
		want = str(get_meta("station"))
	station = _normalise_station(want)

func _normalise_station(raw: String) -> String:
	var word: String = raw.strip_edges().to_lower()
	if STATIONS.has(word):
		return word
	return "edge"

## The colour of the position. edge returns the shipped export untouched.
func _station_tint() -> Color:
	match station:
		"order":
			return ORDER_TINT
		"chaos":
			return CHAOS_TINT
		_:
			return edge_color

## Rebuild ONLY when a map actually changed the value and _ready has already
## built once — an unguarded rebuild here would tear down the three shipped
## placements for nothing.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("station"):
		return
	var want: String = _normalise_station(str(config_data["station"]))
	if want == station:
		return
	station = want
	if not _built:
		return
	_rebuild()

func _rebuild() -> void:
	for part in _parts:
		if is_instance_valid(part):
			part.queue_free()
	_parts.clear()
	_core_mesh = null
	_core_material = null
	_inner_mesh = null
	_particles = null
	_frozen = station == "order"
	_build_core()
	_build_inner()
	_build_ring_particles()

func _add_part(node: Node) -> void:
	add_child(node)
	_parts.append(node)

func _build_core() -> void:
	# chaos has no shell: the boundary is the first thing to go
	if station == "chaos":
		return

	# Outer translucent sphere
	_core_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = core_radius
	sphere.height = core_radius * 2
	if station == "order":
		# faceted: a solid whose sides you can count
		sphere.radial_segments = 7
		sphere.rings = 4
	else:
		sphere.radial_segments = 32
		sphere.rings = 16
	_core_mesh.mesh = sphere

	var tint: Color = _station_tint()
	var shell_alpha: float = 0.3
	if station == "order":
		shell_alpha = 0.62
	_core_material = StandardMaterial3D.new()
	_core_material.albedo_color = Color(tint.r, tint.g, tint.b, shell_alpha)
	_core_material.emission_enabled = true
	_core_material.emission = tint
	_core_material.emission_energy_multiplier = 1.0
	_core_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_core_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_core_mesh.material_override = _core_material

	_add_part(_core_mesh)

func _build_inner() -> void:
	# Inner bright core
	_inner_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	var inner_radius: float = core_radius * 0.4
	if station == "chaos":
		inner_radius = core_radius * 0.12
	sphere.radius = inner_radius
	sphere.height = inner_radius * 2.0
	if station == "order":
		sphere.radial_segments = 6
		sphere.rings = 3
	_inner_mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.emission_enabled = true
	mat.emission = _station_tint()
	mat.emission_energy_multiplier = 3.0
	_inner_mesh.material_override = mat

	_add_part(_inner_mesh)

## TWELVE FIXED NODES instead of an orbit: at `order` the population around the
## core is countable and at exact intervals, which is the whole claim.
func _build_lattice_ring() -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = ORDER_TINT
	mat.emission_enabled = true
	mat.emission = ORDER_TINT
	mat.emission_energy_multiplier = 2.0
	var count: int = 12
	var ring_radius: float = core_radius * 1.25
	for i in range(count):
		var node := MeshInstance3D.new()
		var dot := SphereMesh.new()
		dot.radius = core_radius * 0.07
		dot.height = core_radius * 0.14
		dot.radial_segments = 8
		dot.rings = 4
		node.mesh = dot
		node.material_override = mat
		var angle: float = (float(i) / float(count)) * TAU
		node.position = Vector3(cos(angle) * ring_radius, 0.0, sin(angle) * ring_radius)
		_add_part(node)

## NINETY POINTS AND NO CENTRE. Seeded, so the arrangement is one object rather
## than a fresh one per boot — an unseeded scatter would make every capture of
## this value a different artifact.
func _build_scatter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SCATTER_SEED
	var mat = StandardMaterial3D.new()
	mat.albedo_color = CHAOS_TINT
	mat.emission_enabled = true
	mat.emission = CHAOS_TINT
	mat.emission_energy_multiplier = 1.8
	var count: int = 90
	for i in range(count):
		var node := MeshInstance3D.new()
		var dot := SphereMesh.new()
		dot.radius = core_radius * 0.055
		dot.height = core_radius * 0.11
		dot.radial_segments = 6
		dot.rings = 3
		node.mesh = dot
		node.material_override = mat
		var dir: Vector3 = Vector3(rng.randfn(), rng.randfn(), rng.randfn())
		if dir.length() < 0.001:
			dir = Vector3.UP
		var reach: float = core_radius * (0.35 + 0.8 * sqrt(rng.randf()))
		node.position = dir.normalized() * reach
		_add_part(node)

func _build_ring_particles() -> void:
	if station == "order":
		_build_lattice_ring()
		return
	if station == "chaos":
		_build_scatter()
		return

	_particles = GPUParticles3D.new()
	_particles.amount = ring_particles
	_particles.lifetime = 3.0
	
	var mat = ParticleProcessMaterial.new()
	
	# Emit in a ring around the core
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mat.emission_ring_axis = Vector3(0, 1, 0)
	mat.emission_ring_height = 0.1
	mat.emission_ring_inner_radius = core_radius * 0.8
	mat.emission_ring_radius = core_radius * 1.2
	
	# Orbit around (tangential velocity)
	mat.direction = Vector3(1, 0, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 0.2
	mat.initial_velocity_max = 0.4
	
	# Gentle float
	mat.gravity = Vector3(0, 0.1, 0)
	
	# Color
	mat.color = edge_color
	
	# Scale
	mat.scale_min = 0.5
	mat.scale_max = 1.5
	
	_particles.process_material = mat
	
	# Particle mesh
	var particle_mesh = SphereMesh.new()
	particle_mesh.radius = 0.015
	particle_mesh.height = 0.03
	_particles.draw_pass_1 = particle_mesh
	
	# Glow material
	var mesh_mat = StandardMaterial3D.new()
	mesh_mat.albedo_color = edge_color
	mesh_mat.emission_enabled = true
	mesh_mat.emission = edge_color
	mesh_mat.emission_energy_multiplier = 2.0
	particle_mesh.material = mesh_mat

	_add_part(_particles)

func _process(delta: float) -> void:
	# `order` is immune to time — no pulse, no rotation, no shimmer. That
	# absence IS the value; rigid_sculpture makes the same argument by having
	# no _process at all.
	if _frozen:
		return

	_time += delta

	# Pulse the core
	if _core_mesh != null:
		var pulse: float = 1.0 + sin(_time * pulse_speed * TAU) * pulse_amount
		_core_mesh.scale = Vector3.ONE * pulse

	# Counter-pulse inner
	if _inner_mesh != null:
		var inner_pulse: float = 1.0 + sin(_time * pulse_speed * TAU + PI) * pulse_amount * 2
		_inner_mesh.scale = Vector3.ONE * inner_pulse

	# Rotate everything slowly
	rotation.y += delta * rotation_speed

	# Vary emission intensity
	if _core_material != null:
		var emission_pulse: float = 1.0 + sin(_time * pulse_speed * 2 * TAU) * 0.5
		_core_material.emission_energy_multiplier = emission_pulse

## React to lambda value
func set_lambda(value: float) -> void:
	# chaos has no shell and therefore no shell material to tint.
	if _core_material == null:
		return
	# Color shifts based on how close to edge (0.4)
	var distance_from_edge = abs(value - 0.4)
	var edge_factor = 1.0 - clamp(distance_from_edge * 3, 0, 1)
	
	# More alive at the edge
	pulse_speed = lerp(0.3, 2.0, edge_factor)
	pulse_amount = lerp(0.02, 0.2, edge_factor)
	
	# Color: green at edge, blue/red away
	var color: Color
	if value < 0.4:
		color = Color(0.2, 0.4, 0.9).lerp(edge_color, edge_factor)  # Blue → Green
	else:
		color = edge_color.lerp(Color(0.9, 0.2, 0.2), 1.0 - edge_factor)  # Green → Red
	
	_core_material.emission = color
	_core_material.albedo_color = Color(color.r, color.g, color.b, 0.3)

## Pulse effect
func pulse() -> void:
	if _core_mesh == null:
		return
	var tween = create_tween()
	tween.tween_property(_core_mesh, "scale", Vector3.ONE * 1.5, 0.1)
	tween.tween_property(_core_mesh, "scale", Vector3.ONE, 0.3)
