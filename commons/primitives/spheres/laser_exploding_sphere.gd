@tool
extends StaticBody3D

# @identity
# essence: StaticBody3D sphere on collision layer 21 — when a laser pointer ray hits it, the sphere disappears and fires 30 particle instances outward with procedurally-synthesized explosion audio (noise burst + 60Hz rumble, 0.3s)
# desire: to give the learner a small violent feedback loop — point the laser, make the sphere vanish; it rewards precision with a little chaos and teaches that the laser is a tool that transforms things
# critical_parameter: explosion_particle_count (30) — more particles feel more satisfying but are heavier; the audio synthesis uses randf() noise with exponential decay, so every explosion sounds slightly different
# triggers: StaticBody3D collision layer 21 catches the laser raycast; trigger_explosion() spawns particles in random outward directions, plays audio, then hides the sphere; particles queue_free after explosion_lifetime
# emerges: the sphere resets after the explosion (it is a static teaching object, not a consumable) — the reset reveals that destruction here is a demonstration, not a consequence
# needs: VR laser pointer interaction [has via StaticBody3D layer 21]; explosion particles [has]; explosion audio [has]; respawn delay for reset [missing — appears to hide permanently after explosion]
# relationships: placed in Point_Lines alongside laser_measure — both are objects that the laser interacts with, but one measures and one destroys; the contrast makes the laser feel like a tool with different modes
# truth: a laser pointer is not a cursor — it is a ray that either measures distance or triggers a reaction; the sphere teaches the second possibility

## Laser Exploding Sphere
## A simple sphere that explodes and disappears when hit by a laser pointer

@export var explosion_particle_count: int = 30
@export var explosion_speed: float = 2.0
@export var explosion_lifetime: float = 1.0
@export var explosion_color: Color = Color(1.0, 0.6, 0.2, 1.0)

# Audio
var _explosion_player: AudioStreamPlayer3D

# Explosion state
var _is_exploding: bool = false
var _explosion_particles: Array[Node3D] = []

func _ready() -> void:
	# Debug: Print collision layer
	print("LaserExplodingSphere _ready:")
	print("  collision_layer = ", collision_layer)
	print("  collision_mask = ", collision_mask)
	print("  Layer 21 bit value = ", pow(2, 20))
	print("  Has layer 21? ", (collision_layer & int(pow(2, 20))) != 0)

	# Setup explosion audio
	_setup_explosion_audio()


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
