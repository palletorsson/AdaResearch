@tool
extends XRToolsPickable

## Laser Exploding Sphere
## A grabbable sphere that explodes and disappears when hit by a laser pointer

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
	super()

	# Add to group for laser detection
	add_to_group("laser_destructible")

	# Setup explosion audio
	_setup_explosion_audio()

	# Setup laser detection area
	call_deferred("_setup_laser_detection_area")

func _setup_laser_detection_area() -> void:
	# Create an Area3D to detect laser pointer hits
	var detection_area = Area3D.new()
	detection_area.name = "LaserDetectionArea"
	detection_area.collision_layer = 0
	detection_area.collision_mask = 32  # Layer 6 for laser pointers
	detection_area.monitoring = true
	detection_area.monitorable = true

	# Create collision shape for the area
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.12  # Slightly larger than the sphere for easier hits
	collision_shape.shape = sphere_shape

	detection_area.add_child(collision_shape)
	add_child(detection_area)

	# Connect signals
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.area_entered.connect(_on_detection_area_entered)

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
func hit_by_laser() -> void:
	if _is_exploding:
		return

	print("LaserExplodingSphere: Hit by laser, exploding!")
	_explode()

func _on_detection_area_entered(area: Area3D) -> void:
	# Check if the area is from a laser pointer
	if area.is_in_group("laser_pointer") or area.name.contains("Pointer") or area.name.contains("Ray"):
		hit_by_laser()

func _on_detection_body_entered(body: Node3D) -> void:
	# Alternative detection method via body collision
	if body.is_in_group("laser_pointer") or body.name.contains("Pointer") or body.name.contains("Ray"):
		hit_by_laser()

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

	# Disable physics
	freeze = true
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
