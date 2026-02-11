# Checkpoint.gd
# Save point that activates when player enters
# Visual: Green translucent sphere with "S" label (like utility sub style)

extends Area3D
class_name Checkpoint

@export var checkpoint_id: String = ""  ## Unique identifier for this checkpoint
@export var auto_activate: bool = true  ## Activate on player touch
@export var sphere_radius: float = 0.5  ## Visual sphere size

var is_activated: bool = false

# Colors
const INACTIVE_COLOR = Color(0.2, 0.6, 0.2, 0.4)  # Dim green, transparent
const ACTIVE_COLOR = Color(0.3, 1.0, 0.3, 0.6)    # Bright green
const GLOW_COLOR = Color(0.4, 1.0, 0.4)           # Emission color

# Node references
var sphere_mesh: MeshInstance3D
var label_3d: Label3D
var ground_glow: MeshInstance3D
var collision_shape: CollisionShape3D
var audio_player: AudioStreamPlayer3D
var activation_particles: GPUParticles3D

signal activated(checkpoint: Checkpoint)

func _ready() -> void:
	print("[Checkpoint] _ready() called at position: ", global_position)
	_setup_visuals()
	_setup_collision()
	_setup_audio()
	body_entered.connect(_on_body_entered)
	
	# Register with CheckpointManager if available
	var manager = get_node_or_null("/root/CheckpointManager")
	if manager and manager.has_method("register_checkpoint"):
		manager.register_checkpoint(self)
		print("[Checkpoint] Registered with CheckpointManager")

func _setup_visuals() -> void:
	# Main sphere
	sphere_mesh = MeshInstance3D.new()
	sphere_mesh.name = "SphereMesh"
	var sphere = SphereMesh.new()
	sphere.radius = sphere_radius
	sphere.height = sphere_radius * 2
	sphere.radial_segments = 24
	sphere.rings = 12
	sphere_mesh.mesh = sphere
	
	# Material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = INACTIVE_COLOR
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sphere_mesh.set_surface_override_material(0, mat)
	add_child(sphere_mesh)
	
	# "S" Label
	label_3d = Label3D.new()
	label_3d.name = "Label3D"
	label_3d.text = "S"
	label_3d.font_size = 128
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.no_depth_test = true
	label_3d.modulate = Color(1.0, 1.0, 1.0, 0.9)
	label_3d.outline_size = 8
	label_3d.outline_modulate = Color(0.1, 0.4, 0.1)
	add_child(label_3d)
	
	# Ground glow disc
	ground_glow = MeshInstance3D.new()
	ground_glow.name = "GroundGlow"
	var disc = CylinderMesh.new()
	disc.top_radius = sphere_radius * 1.2
	disc.bottom_radius = sphere_radius * 1.2
	disc.height = 0.02
	ground_glow.mesh = disc
	ground_glow.position.y = -sphere_radius + 0.01
	
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.2, 0.5, 0.2, 0.3)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground_glow.set_surface_override_material(0, glow_mat)
	add_child(ground_glow)

func _setup_collision() -> void:
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var shape = SphereShape3D.new()
	shape.radius = sphere_radius * 1.5  # Slightly larger for easier activation
	collision_shape.shape = shape
	collision_shape.position.y = 1.0  # Player body height
	add_child(collision_shape)
	
	# Configure as trigger area - match subtitle_trigger settings
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 524288  # Layer 20 - player body (same as subtitle_trigger)

func _setup_audio() -> void:
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "AudioPlayer"
	audio_player.max_distance = 10.0
	audio_player.unit_size = 2.0
	add_child(audio_player)

func _on_body_entered(body: Node3D) -> void:
	if not auto_activate:
		return
	if _is_player(body):
		if not is_activated:
			activate()

func _is_player(body: Node3D) -> bool:
	if body.is_in_group("player"):
		return true
	if body.is_in_group("player_body"):
		return true
	if body.name.contains("Player") or body.name.contains("XR"):
		return true
	return false

func activate() -> void:
	if is_activated:
		return
	
	is_activated = true
	
	# Save to CheckpointManager
	var manager = get_node_or_null("/root/CheckpointManager")
	if manager and manager.has_method("save_checkpoint"):
		manager.save_checkpoint(self)
	
	# Visual feedback
	_set_visual_state(true)
	_play_activation_particles()
	_play_activation_sound()
	
	activated.emit(self)
	print("[Checkpoint] Activated: %s" % checkpoint_id)

func _set_visual_state(active: bool) -> void:
	if not sphere_mesh:
		return
	
	var mat = sphere_mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.albedo_color = ACTIVE_COLOR if active else INACTIVE_COLOR
		mat.emission_enabled = active
		if active:
			mat.emission = GLOW_COLOR
			mat.emission_energy_multiplier = 0.5

func _play_activation_particles() -> void:
	# Simple particle burst - green sparkles rising
	if activation_particles:
		activation_particles.emitting = true
		return
	
	activation_particles = GPUParticles3D.new()
	activation_particles.name = "ActivationParticles"
	activation_particles.amount = 20
	activation_particles.lifetime = 1.0
	activation_particles.one_shot = true
	activation_particles.explosiveness = 0.8
	
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 2.0
	mat.gravity = Vector3(0, -2, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.1
	mat.color = GLOW_COLOR
	activation_particles.process_material = mat
	
	var mesh = SphereMesh.new()
	mesh.radius = 0.03
	mesh.height = 0.06
	activation_particles.draw_pass_1 = mesh
	
	add_child(activation_particles)
	activation_particles.emitting = true

func _play_activation_sound() -> void:
	# Generate a simple confirmation tone if no audio file
	# In production, load an actual sound file
	if audio_player.stream:
		audio_player.play()
	else:
		# Could procedurally generate a chime here
		pass

func reset() -> void:
	"""Reset checkpoint to inactive state"""
	is_activated = false
	_set_visual_state(false)
