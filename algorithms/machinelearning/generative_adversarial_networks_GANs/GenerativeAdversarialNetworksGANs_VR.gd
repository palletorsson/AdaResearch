extends Node3D

# VR-Reimagined GAN Visualization
# Spatially separated Generator and Discriminator with central competition arena
# Interactive adversarial training experience

@export_group("VR Scale")
@export var room_separation: float = 8.0  # Distance between generator and discriminator
@export var arena_size: float = 4.0  # Central competition arena size
@export var noise_particle_size: float = 0.12  # Throwable noise particles

@export_group("Training Simulation")
@export var auto_train: bool = true
@export var training_speed: float = 0.1
@export var particle_count: int = 20

@export_group("Interactive Elements")
@export var enable_noise_throwing: bool = true
@export var enable_data_judging: bool = true
@export var show_feedback_loop: bool = true
@export var competition_visualization: bool = true

# Training state
var time: float = 0.0
var training_progress: float = 0.0
var generator_loss: float = 1.0
var discriminator_loss: float = 1.0
var competition_level: float = 0.0

# Generated data quality
var generation_quality: float = 0.0

# Particle arrays
var noise_particles: Array = []
var real_data_particles: Array = []
var fake_data_particles: Array = []
var feedback_particles: Array = []

# Zone nodes
var generator_zone: Node3D
var discriminator_zone: Node3D
var competition_arena: Node3D

func _ready():
	print("[GANs_VR] Initializing adversarial training arena")
	_create_generator_zone()
	_create_discriminator_zone()
	_create_competition_arena()
	_create_feedback_loop()
	_create_training_controls()
	_create_info_panels()

func _process(delta):
	time += delta

	if auto_train:
		training_progress = min(1.0, training_progress + delta * training_speed)

		# Simulate adversarial dynamics
		generator_loss = max(0.1, 1.0 - training_progress * 0.7)
		discriminator_loss = max(0.1, 0.5 + sin(time) * 0.2)
		competition_level = training_progress * 0.8
		generation_quality = training_progress * 0.9

	_animate_generator(delta)
	_animate_discriminator(delta)
	_animate_competition(delta)
	_animate_data_flow(delta)
	_animate_feedback_loop(delta)

func _create_generator_zone():
	"""Create the Generator zone (left side)"""
	generator_zone = Node3D.new()
	generator_zone.name = "GeneratorZone"
	generator_zone.position = Vector3(-room_separation, 0, 0)
	add_child(generator_zone)

	# Generator core (rotating structure)
	var core = MeshInstance3D.new()
	core.name = "GeneratorCore"
	var box = BoxMesh.new()
	box.size = Vector3(2.0, 2.0, 2.0)
	core.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.9, 0.3, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.9, 0.3)
	mat.emission_energy_multiplier = 1.0
	mat.metallic = 0.0
	mat.roughness = 1.0
	core.material_override = mat

	core.position = Vector3(0, 2.0, 0)
	generator_zone.add_child(core)

	# Zone label
	var label = Label3D.new()
	label.text = "GENERATOR\nCreates Fake Data"
	label.font_size = 64
	label.outline_size = 12
	label.outline_modulate = Color.BLACK
	label.modulate = Color(0.3, 0.9, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 4.0, 0)
	generator_zone.add_child(label)

	# Noise input area (platform at foot level)
	_create_noise_input_platform()

	# Output fake data area
	_create_fake_data_spawn()

func _create_noise_input_platform():
	"""Create a platform where users can place/throw noise"""
	var platform = MeshInstance3D.new()
	platform.name = "NoiseInputPlatform"
	var box = BoxMesh.new()
	box.size = Vector3(2.0, 0.2, 2.0)
	platform.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.3, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 0.3)
	mat.emission_energy_multiplier = 0.8
	mat.metallic = 0.0
	mat.roughness = 1.0
	platform.material_override = mat

	platform.position = Vector3(-room_separation, 0.5, 0)
	add_child(platform)

	# Create throwable noise particles
	for i in range(particle_count):
		var noise = _create_noise_particle(
			Vector3(
				-room_separation + randf_range(-0.8, 0.8),
				0.7 + i * 0.3,
				randf_range(-0.8, 0.8)
			)
		)
		add_child(noise)
		noise_particles.append(noise)

func _create_noise_particle(pos: Vector3) -> RigidBody3D:
	"""Create a throwable noise particle"""
	var body = RigidBody3D.new()
	body.position = pos
	body.mass = 0.1

	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = noise_particle_size
	sphere.height = noise_particle_size * 2.0
	mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 0.3)
	mat.emission_energy_multiplier = 1.2
	mat.metallic = 0.0
	mat.roughness = 1.0
	mesh.material_override = mat
	body.add_child(mesh)

	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = noise_particle_size
	collision.shape = shape
	body.add_child(collision)

	# Make grabbable and throwable
	body.collision_layer = 1 | (1 << 20)
	body.collision_mask = 1

	return body

func _create_fake_data_spawn():
	"""Area where generated fake data appears"""
	var spawn_zone = Node3D.new()
	spawn_zone.name = "FakeDataSpawn"
	spawn_zone.position = Vector3(-room_separation, 2.0, 2.0)
	add_child(spawn_zone)

	# Create fake data particles (purple)
	for i in range(particle_count, 2):
		var fake = _create_data_particle(
			Vector3(0, 0, 0),
			Color(0.9, 0.3, 0.9),
			"FAKE"
		)
		spawn_zone.add_child(fake)
		fake_data_particles.append({
			"node": fake,
			"spawn_zone": spawn_zone
		})

func _create_discriminator_zone():
	"""Create the Discriminator zone (right side)"""
	discriminator_zone = Node3D.new()
	discriminator_zone.name = "DiscriminatorZone"
	discriminator_zone.position = Vector3(room_separation, 0, 0)
	add_child(discriminator_zone)

	# Discriminator core (rotating structure)
	var core = MeshInstance3D.new()
	core.name = "DiscriminatorCore"
	var box = BoxMesh.new()
	box.size = Vector3(2.0, 2.0, 2.0)
	core.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.3, 0.3, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.3, 0.3)
	mat.emission_energy_multiplier = 1.0
	mat.metallic = 0.0
	mat.roughness = 1.0
	core.material_override = mat

	core.position = Vector3(0, 2.0, 0)
	discriminator_zone.add_child(core)

	# Zone label
	var label = Label3D.new()
	label.text = "DISCRIMINATOR\nJudges Real vs Fake"
	label.font_size = 64
	label.outline_size = 12
	label.outline_modulate = Color.BLACK
	label.modulate = Color(0.9, 0.3, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 4.0, 0)
	discriminator_zone.add_child(label)

	# Real data area (green particles)
	_create_real_data_area()

func _create_real_data_area():
	"""Area showing real training data"""
	var real_zone = Node3D.new()
	real_zone.name = "RealDataZone"
	real_zone.position = Vector3(room_separation, 2.0, -2.0)
	add_child(real_zone)

	# Platform
	var platform = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2.0, 0.2, 2.0)
	platform.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.9, 0.3, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.9, 0.3)
	mat.emission_energy_multiplier = 0.8
	mat.metallic = 0.0
	mat.roughness = 1.0
	platform.material_override = mat

	platform.position = Vector3(0, -1.5, 0)
	real_zone.add_child(platform)

	# Create real data particles (green)
	for i in range(particle_count, 2):
		var real = _create_data_particle(
			Vector3(
				randf_range(-0.8, 0.8),
				0,
				randf_range(-0.8, 0.8)
			),
			Color(0.3, 0.9, 0.3),
			"REAL"
		)
		real_zone.add_child(real)
		real_data_particles.append({
			"node": real,
			"zone": real_zone
		})

func _create_data_particle(pos: Vector3, color: Color, label_text: String) -> MeshInstance3D:
	"""Create a data particle (real or fake)"""
	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.0
	mat.metallic = 0.0
	mat.roughness = 1.0
	mesh.material_override = mat

	mesh.position = pos

	# Small label
	var label = Label3D.new()
	label.text = label_text
	label.font_size = 24
	label.outline_size = 6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.3, 0)
	mesh.add_child(label)

	return mesh

func _create_competition_arena():
	"""Create central competition arena"""
	competition_arena = Node3D.new()
	competition_arena.name = "CompetitionArena"
	competition_arena.position = Vector3(0, 1.0, 0)
	add_child(competition_arena)

	# Arena floor (circular)
	var floor_mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = arena_size
	cylinder.bottom_radius = arena_size
	cylinder.height = 0.2
	floor_mesh.mesh = cylinder

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.5, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.5, 0.9)
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.0
	mat.roughness = 1.0
	floor_mesh.material_override = mat

	competition_arena.add_child(floor_mesh)

	# Central pillar showing competition level
	var pillar = MeshInstance3D.new()
	pillar.name = "CompetitionPillar"
	var pillar_mesh = CylinderMesh.new()
	pillar_mesh.top_radius = 0.3
	pillar_mesh.bottom_radius = 0.3
	pillar_mesh.height = 2.0
	pillar.mesh = pillar_mesh

	var pillar_mat = StandardMaterial3D.new()
	pillar_mat.albedo_color = Color(0.9, 0.5, 0.2)
	pillar_mat.emission_enabled = true
	pillar_mat.emission = Color(0.9, 0.5, 0.2)
	pillar_mat.emission_energy_multiplier = 1.5
	pillar_mat.metallic = 0.0
	pillar_mat.roughness = 1.0
	pillar.material_override = pillar_mat

	pillar.position = Vector3(0, 1.0, 0)
	competition_arena.add_child(pillar)

	# Label
	var label = Label3D.new()
	label.text = "ADVERSARIAL\nCOMPETITION"
	label.font_size = 72
	label.outline_size = 14
	label.modulate = Color(0.9, 0.5, 0.2)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 3.5, 0)
	competition_arena.add_child(label)

func _create_feedback_loop():
	"""Create visible feedback path connecting all components"""
	if not show_feedback_loop:
		return

	var loop_container = Node3D.new()
	loop_container.name = "FeedbackLoop"
	add_child(loop_container)

	# Create particles that move in a circle through the system
	for i in range(particle_count):
		var particle = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.06
		sphere.height = 0.12
		particle.mesh = sphere

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.9, 0.9, 0.7)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.9, 0.9)
		mat.emission_energy_multiplier = 1.0
		mat.metallic = 0.0
		mat.roughness = 1.0
		particle.material_override = mat

		loop_container.add_child(particle)
		feedback_particles.append({
			"node": particle,
			"progress": float(i) / particle_count
		})

func _create_training_controls():
	"""Create VR-accessible control panel"""
	var controls = Node3D.new()
	controls.name = "TrainingControls"
	controls.position = Vector3(0, 2.5, -arena_size - 2.0)
	add_child(controls)

	# Control panel
	var panel = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(4.0, 2.0, 0.1)
	panel.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.3, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.0
	mat.roughness = 1.0
	panel.material_override = mat
	controls.add_child(panel)

	# Title
	var title = Label3D.new()
	title.text = "GAN TRAINING ARENA"
	title.font_size = 72
	title.outline_size = 14
	title.position = Vector3(0, 0.7, 0.1)
	controls.add_child(title)

	# Metrics
	var metrics = Label3D.new()
	metrics.name = "MetricsLabel"
	metrics.text = "Gen Loss: 1.00\nDisc Loss: 1.00"
	metrics.font_size = 48
	metrics.outline_size = 10
	metrics.position = Vector3(0, -0.3, 0.1)
	controls.add_child(metrics)

func _create_info_panels():
	"""Create educational info panels"""
	# Generator explanation
	_create_info_panel(
		Vector3(-room_separation, 5.0, 0),
		"Generator learns to\ncreate realistic data\nfrom random noise",
		Color(0.3, 0.9, 0.3)
	)

	# Discriminator explanation
	_create_info_panel(
		Vector3(room_separation, 5.0, 0),
		"Discriminator learns to\ndistinguish real data\nfrom fake data",
		Color(0.9, 0.3, 0.3)
	)

	# Arena explanation
	_create_info_panel(
		Vector3(0, 5.0, 0),
		"Both networks compete\nand improve together\nthrough adversarial training",
		Color(0.9, 0.5, 0.2)
	)

func _create_info_panel(pos: Vector3, text: String, color: Color):
	"""Create floating info panel"""
	var label = Label3D.new()
	label.text = text
	label.font_size = 40
	label.outline_size = 10
	label.outline_modulate = Color.BLACK
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	add_child(label)

func _animate_generator(delta):
	"""Animate generator core"""
	var core = generator_zone.get_node_or_null("GeneratorCore")
	if core:
		core.rotation.y += delta * 0.6
		var pulse = 1.0 + sin(time * 2.0) * 0.2 * training_progress
		core.scale = Vector3.ONE * pulse

func _animate_discriminator(delta):
	"""Animate discriminator core"""
	var core = discriminator_zone.get_node_or_null("DiscriminatorCore")
	if core:
		core.rotation.y -= delta * 0.8
		var pulse = 1.0 + cos(time * 2.2) * 0.2 * training_progress
		core.scale = Vector3.ONE * pulse

func _animate_competition(delta):
	"""Animate competition arena pillar"""
	var pillar = competition_arena.get_node_or_null("CompetitionPillar")
	if pillar:
		# Scale based on competition level
		var target_height = 2.0 + competition_level * 3.0
		var current_height = pillar.mesh.height
		pillar.mesh.height = lerp(current_height, target_height, delta * 2.0)
		pillar.position.y = pillar.mesh.height / 2.0

		# Rotate
		pillar.rotation.y += delta * competition_level * 2.0

func _animate_data_flow(delta):
	"""Animate fake data flowing from generator to discriminator"""
	for fake_data in fake_data_particles:
		var node = fake_data.node
		# Move toward discriminator
		var target_pos = Vector3(room_separation * 0.5, 2.0, 0)
		node.position = node.position.lerp(target_pos, delta * 0.3 * generation_quality)

func _animate_feedback_loop(delta):
	"""Animate feedback particles circling the system"""
	for particle_data in feedback_particles:
		var particle = particle_data.node
		var progress = particle_data.progress

		# Update progress
		progress = fmod(progress + delta * 0.2, 1.0)
		particle_data.progress = progress

		# Circular path connecting all three zones
		var angle = progress * TAU
		var radius = room_separation * 0.7
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		var y = 1.5 + sin(progress * PI * 4) * 0.5

		particle.position = Vector3(x, y, z)

# Public API
func set_training_progress(progress: float):
	training_progress = clamp(progress, 0.0, 1.0)

func reset_training():
	training_progress = 0.0
	generator_loss = 1.0
	discriminator_loss = 1.0
	competition_level = 0.0
	time = 0.0

func get_metrics() -> Dictionary:
	return {
		"generator_loss": generator_loss,
		"discriminator_loss": discriminator_loss,
		"competition": competition_level,
		"quality": generation_quality
	}
