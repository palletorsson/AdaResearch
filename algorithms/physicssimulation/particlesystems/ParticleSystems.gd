## Particle Systems — Uses Godot's GPUParticles3D (runs on GPU, not CPU)
## Shows different particle behaviors: fountain, fire, sparks, snow
##
## @identity
## essence: emit(position, velocity, lifetime). Each particle: born, forced, aged, dead. The system is the population, not the individual.
## desire: To show four archetypal particle behaviors side by side — fountain (ballistic), fire (buoyant), sparks (explosive), snow (gentle) — all from the same GPU machinery.
## critical_parameter: gravity direction and damping per system. Fountain: gravity down, low damp. Fire: gravity UP (buoyancy), high damp. These two parameters create completely different phenomena.
## triggers: Automatic — all four GPUParticles3D emit continuously. No interaction needed; the artifact is a living taxonomy.
## emerges: Fire looking like fire despite being spheres — because upward gravity + high damping + color ramp = buoyant fading embers. The color gradient does most of the work.
## needs: Four GPU particle systems [has]. Missing: VR sliders to morph between behaviors, particle count control, custom emission shapes.
## relationships: GPU counterpart to firework_launcher (CPU particles). Lives in ForcesSystems. Feeds into particle effects throughout the engine.
## truth: A particle system is a statistical object. No single particle matters. The population's distribution is the phenomenon.
##
## STAGE-2 DNA PROMOTION (2026-07-29). This artifact had zero exports and an
## apply_grid_config() whose whole body was `pass` — a map could place it but could
## not say anything to it. Four hard-coded calls at four hard-coded corners: it was
## always the whole taxonomy, always laid out as a 12-metre square of ground, even
## when the map wanted one fire.
##
## Two axes —
##
##   cast          WHO is on show          all · fountain · fire · sparks · snow
##   arrangement   how they are staged     grid · row · ring
##
## cast is the rhetorical mode. all is a COMPARISON — four archetypes side by side,
## and the claim is that one piece of machinery makes all of them. A single member
## is a SPECIMEN — no argument, just a phenomenon standing in the room where the map
## needs a fire rather than a lecture about fire. It also collapses the footprint
## from 12x9x11 to a couple of metres, which is why several maps that wanted an
## effect had to place a demonstration instead.
##
## arrangement is where you stand relative to the claim. grid is the legacy 2x2 —
## you walk between them. row ranks them abreast like specimens on a shelf, read
## left to right. ring puts them around you, so the taxonomy surrounds the viewer
## instead of facing them.
##
## cast=all + arrangement=grid reproduce the four original positions verbatim, and
## they are the defaults, so the 7 existing placements are untouched.
##
## Usage in map_data.json:
##   "particle_systems"                                → the four-up taxonomy, as before
##   "particle_systems#cast:fire"
##   "particle_systems#arrangement:ring"
extends Node3D

## The four archetypes, in the order the pre-promotion _ready() built them.
const MEMBERS: Array[String] = ["fountain", "fire", "sparks", "snow"]

## The pre-promotion corner positions, index-matched to MEMBERS. Kept as literals
## rather than derived, because these exact numbers are what the shipped maps show.
const GRID_POSITIONS: Array[Vector3] = [
	Vector3(-2, 0, -1),  # fountain
	Vector3(2, 0, -1),   # fire
	Vector3(-2, 0, 2),   # sparks
	Vector3(2, 0, 2),    # snow
]

const ROW_SPACING: float = 2.8
const RING_RADIUS: float = 2.4

## Who is on show: "all" for the four-up taxonomy, or one member's name for a
## single specimen.
@export var cast: String = "all"  # all | fountain | fire | sparks | snow
## How the members are staged in the room: grid (2x2), row (abreast), ring (around you).
@export var arrangement: String = "grid"

var _built: bool = false
var _spawned: Array[Node] = []


func _ready() -> void:
	scale = Vector3(0.8, 0.8, 0.8)
	_build()
	_built = true


func _build() -> void:
	_spawned.clear()
	var members: Array[String] = _cast_members()
	var positions: Array[Vector3] = _stage_positions(members.size())
	for i in range(members.size()):
		var pos: Vector3 = positions[i]
		match members[i]:
			"fountain":
				_create_fountain(pos)
			"fire":
				_create_fire(pos)
			"sparks":
				_create_sparks(pos)
			"snow":
				_create_snow(pos)


func _cast_members() -> Array[String]:
	var out: Array[String] = []
	if MEMBERS.has(cast):
		out.append(cast)
		return out
	for m in MEMBERS:
		out.append(str(m))
	return out


## Where each member stands. With four members in the grid this returns the
## original literals untouched; every other combination is a new lineage.
func _stage_positions(count: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if count <= 1:
		# a lone specimen stands where the artifact was placed, not off in a corner
		out.append(Vector3.ZERO)
		return out

	match arrangement:
		"row":
			var half: float = float(count - 1) * 0.5
			for i in range(count):
				out.append(Vector3((float(i) - half) * ROW_SPACING, 0.0, 0.0))
		"ring":
			for i in range(count):
				var a: float = TAU * float(i) / float(count)
				out.append(Vector3(sin(a) * RING_RADIUS, 0.0, cos(a) * RING_RADIUS))
		_:
			for i in range(count):
				if i < GRID_POSITIONS.size():
					out.append(GRID_POSITIONS[i])
				else:
					out.append(Vector3.ZERO)
	return out


func _create_fountain(pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Fountain"
	particles.amount = 200
	particles.lifetime = 2.0
	particles.position = pos

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 15.0
	mat.initial_velocity_min = 4.0
	mat.initial_velocity_max = 6.0
	mat.gravity = Vector3(0, -9.8, 0)
	mat.damping_min = 0.5
	mat.damping_max = 1.0
	mat.scale_min = 0.05
	mat.scale_max = 0.1
	mat.color = Color(0.3, 0.6, 1.0)

	particles.process_material = mat
	particles.draw_pass_1 = SphereMesh.new()
	particles.draw_pass_1.radius = 0.05
	particles.draw_pass_1.height = 0.1

	add_child(particles)
	_spawned.append(particles)

func _create_fire(pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Fire"
	particles.amount = 150
	particles.lifetime = 1.5
	particles.position = pos

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 25.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 3.0
	mat.gravity = Vector3(0, 1.0, 0)  # Upward "buoyancy"
	mat.damping_min = 2.0
	mat.damping_max = 4.0
	mat.scale_min = 0.1
	mat.scale_max = 0.3

	# Fire color gradient
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.9, 0.2))    # Yellow core
	gradient.add_point(0.3, Color(1.0, 0.4, 0.1))   # Orange
	gradient.add_point(0.7, Color(0.8, 0.1, 0.0))   # Red
	gradient.set_color(1, Color(0.2, 0.1, 0.1, 0.0)) # Smoke fade

	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

	particles.process_material = mat
	particles.draw_pass_1 = SphereMesh.new()
	particles.draw_pass_1.radius = 0.08
	particles.draw_pass_1.height = 0.16

	add_child(particles)
	_spawned.append(particles)

func _create_sparks(pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Sparks"
	particles.amount = 80
	particles.lifetime = 0.8
	particles.position = pos

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 8.0
	mat.gravity = Vector3(0, -15.0, 0)
	mat.scale_min = 0.02
	mat.scale_max = 0.04
	mat.color = Color(1.0, 0.8, 0.3)

	particles.process_material = mat
	particles.draw_pass_1 = SphereMesh.new()
	particles.draw_pass_1.radius = 0.02
	particles.draw_pass_1.height = 0.04

	add_child(particles)
	_spawned.append(particles)

func _create_snow(pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Snow"
	particles.amount = 100
	particles.lifetime = 4.0
	particles.position = pos + Vector3(0, 4, 0)
	particles.visibility_aabb = AABB(Vector3(-2, -5, -2), Vector3(4, 6, 4))

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 0.2
	mat.initial_velocity_max = 0.5
	mat.gravity = Vector3(0, -1.0, 0)
	mat.damping_min = 1.0
	mat.damping_max = 3.0
	mat.scale_min = 0.03
	mat.scale_max = 0.06
	mat.color = Color(0.95, 0.95, 1.0, 0.8)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(1.5, 0.1, 1.5)

	particles.process_material = mat
	particles.draw_pass_1 = SphereMesh.new()
	particles.draw_pass_1.radius = 0.03
	particles.draw_pass_1.height = 0.06

	add_child(particles)
	_spawned.append(particles)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Grid config. Reached only when a map token carries #cast: or #arrangement:.
## Anything else leaves the four-up taxonomy exactly as _ready() built it.
func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = false

	if config.has("cast"):
		var c: String = str(config["cast"])
		if (c == "all" or MEMBERS.has(c)) and c != cast:
			cast = c
			changed = true

	if config.has("arrangement"):
		var a: String = str(config["arrangement"])
		if (a == "grid" or a == "row" or a == "ring") and a != arrangement:
			arrangement = a
			changed = true

	if not changed:
		return
	if not _built:
		# _ready has not run yet; it will build with the new values on its own
		return

	for node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	_spawned.clear()
	_build()
