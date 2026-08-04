@tool
extends StaticBody3D

# @identity
# essence: StaticBody3D sphere on collision layer 21 — when a laser pointer ray hits it, the sphere disappears and fires 30 particle instances outward with procedurally-synthesized explosion audio (noise burst + 60Hz rumble, 0.3s)
# desire: to give the learner a small violent feedback loop — point the laser, make the sphere vanish; it rewards precision with a little chaos and teaches that the laser is a tool that transforms things
# critical_parameter: moment — which instant of the demonstration is standing in the room (intact / fissured / burst / scattered); explosion_particle_count still sets how many pieces there are, but only `moment` decides whether a viewer ever sees them
# triggers: StaticBody3D collision layer 21 catches the laser raycast; trigger_explosion() spawns particles in random outward directions, plays audio, then hides the sphere; particles queue_free after explosion_lifetime
# emerges: the sphere resets after the explosion (it is a static teaching object, not a consumable) — the reset reveals that destruction here is a demonstration, not a consequence
# needs: VR laser pointer interaction [has via StaticBody3D layer 21]; explosion particles [has]; explosion audio [has]; respawn delay for reset [missing — appears to hide permanently after explosion]
# relationships: placed in Point_Lines alongside laser_measure — both are objects that the laser interacts with, but one measures and one destroys; the contrast makes the laser feel like a tool with different modes
# truth: a laser pointer is not a cursor — it is a ray that either measures distance or triggers a reaction; the sphere teaches the second possibility

## Laser Exploding Sphere
## A simple sphere that explodes and disappears when hit by a laser pointer

# ── Stage-2 DNA: moment ───────────────────────────────────────────────
#
# THE PROBLEM THIS ARTIFACT SETS. Everything it owns happens in a tenth of a
# second, once, and only after a laser ray touches it — which never happens
# during a capture. Its four exports are a count, a speed, a duration and a
# colour, and three of those are invisible to a still frame by construction:
# the particles they describe do not exist while the shutter is open. Sweeping
# any of them would have produced N identical photographs of an intact sphere
# and a confident INERT verdict about a design that was never in the picture.
#
# So the axis is not a parameter of the event. It is WHICH MOMENT OF THE EVENT
# IS STANDING IN THE ROOM. The explosion's own constants — the particle count,
# the fragment size, the outward throw — are lifted out of the tween that
# nobody sees and set down as geometry that holds still:
#
#   intact     the shipped target. One emissive ball, live, waiting to be hit.
#              Nothing added, nothing hidden — the thirteen rooms as they are.
#   fissured   the same live target, with the flaw already in it: three dark
#              seams girdling the ball. It still explodes; it has simply
#              stopped pretending it is whole.
#   burst      the shell hidden and the fragment field frozen at full throw —
#              explosion_particle_count pieces on a deterministic sphere. The
#              event, held.
#   scattered  the same pieces come to rest: a dimmed disc of debris on the
#              floor. The residue, long after.
#
# The last two are aftermath, so they set _is_exploding — the flag the artifact
# already had — and the existing guard at the top of hit_by_laser() makes them
# inert to the pointer. A thing that has already gone off does not go off.
#
# WHY IT IS WORTH ASKING. The @identity's own emerges line says the reset
# "reveals that destruction here is a demonstration, not a consequence", and
# then the code queue_free()s the sphere so that in a live map the aftermath
# exists for one second and never again. A map could show the promise or
# nothing. Now it can show the promise, the flaw, the event or what is left,
# and that choice is a claim about which tense a teaching room is in.
#
# DETERMINISM. The live explosion keeps its randf() directions, untouched. The
# frozen fields do NOT use it: fragments sit on a Fibonacci sphere and a
# golden-angle disc, so two captures of the same value are two photographs of
# one object rather than two objects.

@export var explosion_particle_count: int = 30
@export var explosion_speed: float = 2.0
@export var explosion_lifetime: float = 1.0
@export var explosion_color: Color = Color(1.0, 0.6, 0.2, 1.0)

@export_group("Moment")
## Which moment of the demonstration is standing in the room. `intact` is the
## shipped target exactly — no node added, nothing hidden, nothing disabled.
@export_enum("intact", "fissured", "burst", "scattered") var moment: String = "intact"

## Allow-list for the axis. Anything outside it is a typo in a map token and
## keeps the value already held — for a fresh instance, the shipped target.
const MOMENTS: PackedStringArray = ["intact", "fissured", "burst", "scattered"]

## Fallback only. The real radius is read off the shipped SphereMesh at build
## time so this constant cannot drift away from laser_exploding_sphere.tscn.
const SPHERE_RADIUS: float = 0.1

const SEAM_RINGS: int = 3                  ## great circles drawn as cracks
const SEAM_THICKNESS: float = 0.004        ## tube diameter of a seam
const FRAGMENT_RADIUS: float = 0.02        ## same 0.02 the live particles use
const BURST_RADIUS: float = 0.28           ## the frozen field's throw
const SCATTER_RADIUS: float = 0.40         ## how wide the debris settles
const SCATTER_DROP: float = 0.075          ## how far under the origin it lies
const SCATTER_RELIEF: float = 0.012        ## deterministic unevenness of the pile

# Audio
var _explosion_player: AudioStreamPlayer3D

# Explosion state
var _is_exploding: bool = false
var _explosion_particles: Array[Node3D] = []

# Everything the axis added, and nothing else. Teardown walks this and never
# touches the shipped mesh, the collider or the audio player.
var _built: bool = false
var _moment_root: Node3D = null

func _ready() -> void:
	# Debug: Print collision layer
	print("LaserExplodingSphere _ready:")
	print("  collision_layer = ", collision_layer)
	print("  collision_mask = ", collision_mask)
	print("  Layer 21 bit value = ", pow(2, 20))
	print("  Has layer 21? ", (collision_layer & int(pow(2, 20))) != 0)

	# Setup explosion audio
	_setup_explosion_audio()

	# The grid writes config_* metadata BEFORE add_child and only calls
	# apply_grid_config deferred, so reading it here builds the right moment
	# first time and leaves the deferred call with nothing to tear down.
	_read_metadata_overrides()
	_build_moment()
	_built = true


# ── Moment ───────────────────────────────────────────────────────────
#
# `intact` returns on the first line: no node added, no property written, no
# node hidden, and _is_exploding stays false. The thirteen existing placements
# cannot tell this section exists.

func _build_moment() -> void:
	if moment == "intact":
		return

	_moment_root = Node3D.new()
	_moment_root.name = "Moment"
	add_child(_moment_root)

	match moment:
		"fissured":
			_build_seams()
		"burst":
			_build_fragment_shell()
		"scattered":
			_build_fragment_field()

	if moment == "burst" or moment == "scattered":
		# Aftermath. The guard at the top of hit_by_laser() already says a thing
		# that has gone off does not go off again; this is that same flag, set
		# at build time instead of by the ray.
		_is_exploding = true
		var shipped: MeshInstance3D = _shipped_mesh()
		if shipped != null:
			shipped.visible = false


## The shipped ball, resolved by name so the script survives being dropped on a
## bare StaticBody3D.
func _shipped_mesh() -> MeshInstance3D:
	return get_node_or_null("MeshInstance3D") as MeshInstance3D


## Derived, never transcribed: the .tscn's SphereMesh is the truth about how
## big this thing is, and a hand-copied constant is how a declaration and its
## code drift apart.
func _shipped_radius() -> float:
	var shipped: MeshInstance3D = _shipped_mesh()
	if shipped != null and shipped.mesh is SphereMesh:
		return (shipped.mesh as SphereMesh).radius
	return SPHERE_RADIUS


## RUNG 1 — the flaw already in it. Three dark great circles half-sunk in the
## surface, so the silhouette is the shipped ball and the skin is not.
func _build_seams() -> void:
	var r: float = _shipped_radius()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.03, 0.03, 1.0)
	mat.roughness = 0.9
	mat.metallic = 0.0

	# A TorusMesh lies in the XZ plane, so the three rungs of rotation put one
	# seam on each of the three great circles: the equator, then the two
	# meridians at right angles to it. Whatever angle the camera takes, at least
	# two of them cross the disc it sees.
	var turns: Array[Vector3] = [
		Vector3(0.0, 0.0, 0.0),
		Vector3(90.0, 0.0, 0.0),
		Vector3(0.0, 0.0, 90.0),
	]
	for i in range(SEAM_RINGS):
		var ring := MeshInstance3D.new()
		ring.name = "Seam%d" % i
		var torus := TorusMesh.new()
		torus.inner_radius = r - SEAM_THICKNESS * 0.5
		torus.outer_radius = r + SEAM_THICKNESS * 0.5
		torus.rings = 48
		torus.ring_segments = 6
		ring.mesh = torus
		ring.material_override = mat
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.rotation_degrees = turns[i]
		_moment_root.add_child(ring)


## RUNG 2 — the event, held. explosion_particle_count fragments on a Fibonacci
## sphere at full throw: the same count and the same 0.02 m pieces the live
## burst spawns, at rest instead of tweening.
func _build_fragment_shell() -> void:
	var mat: StandardMaterial3D = _fragment_material(explosion_color, 2.0)
	var count: int = maxi(1, explosion_particle_count)
	for i in range(count):
		var frag: MeshInstance3D = _fragment(mat, i)
		frag.position = _fibonacci_direction(i, count) * BURST_RADIUS
		_moment_root.add_child(frag)


## RUNG 3 — the residue. The same pieces come to rest on a golden-angle disc
## near the floor, dimmed, with a deterministic unevenness so the pile reads as
## a pile and not as a printed pattern.
func _build_fragment_field() -> void:
	var dim: Color = Color(explosion_color.r * 0.55, explosion_color.g * 0.45, explosion_color.b * 0.45, 1.0)
	var mat: StandardMaterial3D = _fragment_material(dim, 0.35)
	var count: int = maxi(1, explosion_particle_count)
	for i in range(count):
		var frag: MeshInstance3D = _fragment(mat, i)
		var k: float = float(i) + 0.5
		var spread: float = sqrt(k / float(count)) * SCATTER_RADIUS
		var theta: float = PI * (1.0 + sqrt(5.0)) * k
		var relief: float = fmod(k * 0.6180339887, 1.0) * SCATTER_RELIEF
		frag.position = Vector3(cos(theta) * spread, -SCATTER_DROP + relief, sin(theta) * spread)
		_moment_root.add_child(frag)


func _fragment(mat: StandardMaterial3D, index: int) -> MeshInstance3D:
	var frag := MeshInstance3D.new()
	frag.name = "Fragment%d" % index
	var mesh := SphereMesh.new()
	mesh.radius = FRAGMENT_RADIUS
	mesh.height = FRAGMENT_RADIUS * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	frag.mesh = mesh
	frag.material_override = mat
	frag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return frag


func _fragment_material(tint: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = energy
	return mat


## An even spread with no randf() in it, so two captures of one value are two
## photographs of the same object.
func _fibonacci_direction(index: int, count: int) -> Vector3:
	var k: float = float(index) + 0.5
	var y: float = 1.0 - 2.0 * k / float(count)
	var ring: float = sqrt(maxf(0.0, 1.0 - y * y))
	var theta: float = PI * (1.0 + sqrt(5.0)) * k
	return Vector3(cos(theta) * ring, y, sin(theta) * ring)


## Grid config entry point. Called via call_deferred after _ready, and by
## cluster_resolver / curation_station with dicts that carry no axis key at all,
## so it returns without touching anything unless the word actually moved.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_moment: String = moment

	if config_data.has("moment"):
		moment = _pick_moment(str(config_data["moment"]))

	if not _built:
		# Nothing exists yet; _ready() will build with the value just resolved.
		return
	if moment == before_moment:
		return
	_rebuild_moment()


func _read_metadata_overrides() -> void:
	if has_meta("config_moment"):
		moment = _pick_moment(str(get_meta("config_moment")))


func _pick_moment(raw: String) -> String:
	var want: String = raw.to_lower().strip_edges()
	return want if MOMENTS.has(want) else moment


## Synchronous teardown so the old moment leaves the tree in THIS frame — a
## deferred free would let the grid's auto-grounding measure a stale AABB.
func _rebuild_moment() -> void:
	if is_instance_valid(_moment_root):
		if _moment_root.get_parent() == self:
			remove_child(_moment_root)
		_moment_root.queue_free()
	_moment_root = null

	# Un-hide the shipped ball and hand the target back its life before the new
	# moment decides what to do with them.
	var shipped: MeshInstance3D = _shipped_mesh()
	if shipped != null:
		shipped.visible = true
	_is_exploding = false

	_build_moment()


func _setup_explosion_audio() -> void:
	var explosion_stream = _build_explosion_stream()
	_explosion_player = AudioStreamPlayer3D.new()
	_explosion_player.name = "ExplosionPlayer"
	_explosion_player.stream = explosion_stream
	_explosion_player.autoplay = false
	_explosion_player.volume_db = -6.0
	_explosion_player.unit_size = 1.5
	_explosion_player.attenuation_filter_cutoff_hz = 8000
	add_child(_explosion_player)

func _build_explosion_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var duration := 0.3
	var length := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(length * 2)

	for i in length:
		var t: float = float(i) / stream.mix_rate
		var envelope: float = exp(-8.0 * t)

		# Noise burst with low frequency rumble
		var noise: float = randf() * 2.0 - 1.0
		var rumble: float = sin(TAU * 60.0 * t) * 0.3
		var sample: float = (noise * 0.7 + rumble * 0.3) * envelope * 0.5

		var int_sample: int = int(sample * 32767.0)
		data[2 * i] = int_sample & 0xFF
		data[2 * i + 1] = (int_sample >> 8) & 0xFF

	stream.data = data
	return stream

## Called when the sphere is hit (by laser or other area)
## This can be called directly by the laser pointer's raycast
func hit_by_laser() -> void:
	if _is_exploding:
		return

	print("LaserExplodingSphere: Hit by laser, exploding!")
	_explode()

## Alternative: Called when pointer action is triggered while pointing at this object
func pointer_pressed(_at_position: Vector3) -> void:
	print("LaserExplodingSphere: Pointer pressed, exploding!")
	hit_by_laser()

## Alternative: Called by function pointer on click
func action() -> void:
	print("LaserExplodingSphere: Action triggered, exploding!")
	hit_by_laser()

## Called by XR Tools pointer system when pointer events occur
func pointer_event(event) -> void:
	var event_type = event.event_type
	print("LaserExplodingSphere: pointer_event called! event_type = ", event_type, " (type: ", typeof(event_type), ")")
	print("  Checking if event_type == 0: ", (event_type == 0))

	# Explode when laser enters (touches) the sphere
	if event_type == 0:  # XRToolsPointerEvent.Type.ENTERED = 0
		print(">>> LaserExplodingSphere: Laser touched sphere, EXPLODING NOW!")
		hit_by_laser()
	# Also support trigger click if it works
	elif event_type == 2:  # XRToolsPointerEvent.Type.PRESSED = 2
		print(">>> LaserExplodingSphere: Pointer event (PRESSED), EXPLODING NOW!")
		hit_by_laser()
	else:
		print("  Not exploding - event type is: ", event_type)


## Trigger explosion effect
func _explode() -> void:
	_is_exploding = true

	# Play explosion sound
	if _explosion_player:
		_explosion_player.play()

	# Hide the main mesh
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.visible = false

	# ...and the seams with it, if this one was standing at `fissured`. A crack
	# outliving the thing it cracked would be a lie in furniture form.
	if is_instance_valid(_moment_root):
		_moment_root.visible = false

	# Disable collision
	collision_layer = 0
	collision_mask = 0

	# Create particle burst
	_create_explosion_particles()

	# Queue free after particles fade
	await get_tree().create_timer(explosion_lifetime + 0.5).timeout
	queue_free()

func _create_explosion_particles() -> void:
	# Create small sphere particles that burst outward
	for i in range(explosion_particle_count):
		var particle = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.02
		sphere_mesh.height = 0.04
		particle.mesh = sphere_mesh

		# Create material
		var material = StandardMaterial3D.new()
		material.albedo_color = explosion_color
		material.emission_enabled = true
		material.emission = explosion_color
		material.emission_energy_multiplier = 2.0
		particle.material_override = material

		# Add to scene
		get_parent().add_child(particle)
		particle.global_position = global_position

		# Random velocity direction
		var direction = Vector3(
			randf() * 2.0 - 1.0,
			randf() * 2.0 - 1.0,
			randf() * 2.0 - 1.0
		).normalized()

		_explosion_particles.append(particle)
		_animate_particle(particle, direction)

func _animate_particle(particle: Node3D, direction: Vector3) -> void:
	var tween = create_tween()
	tween.set_parallel(true)

	# Move outward
	var end_pos = particle.global_position + direction * explosion_speed
	tween.tween_property(particle, "global_position", end_pos, explosion_lifetime)

	# Fade out
	var material = particle.material_override as StandardMaterial3D
	if material:
		tween.tween_property(material, "albedo_color:a", 0.0, explosion_lifetime)

	# Scale down
	tween.tween_property(particle, "scale", Vector3.ZERO, explosion_lifetime)

	# Clean up
	tween.finished.connect(func(): particle.queue_free())
