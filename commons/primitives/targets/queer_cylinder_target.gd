extends StaticBody3D

# Queer Cylinder Target
# A dynamic, responsive target practice object celebrating queer aesthetics
# Features concentric rings in Pride colors arranged like a traditional target face

class_name QueerCylinderTarget

@export_group("Settings")
@export var points_per_hit: int = 10
@export var breathing_speed: float = 2.0
@export var breathing_amount: float = 0.02
@export var target_radius: float = 0.6
@export var target_thickness: float = 0.05

@onready var container = $RingsContainer
@onready var audio_player = $AudioStreamPlayer3D
@onready var hit_particles = $GPUParticles3D

# Colors based on the Progress Pride Flag (removed outer yellow/orange/red)
var palette: Array[Color] = [
	Color("#008026"), # Nature (Green) - Outer
	Color("#004DFF"), # Harmony (Blue)
	Color("#750787"), # Spirit (Purple)
	Color("#FFFFFF"), # Magic/Nonbinary (White)
	Color("#F5A9B8"), # Trans Pink
	Color("#5BCEFA"), # Trans Blue
	Color("#613915"), # POC Inclusion (Brown)
	Color("#000000"), # HIV/AIDS Awareness (Black) - Inner (bullseye)
]

var rings: Array[MeshInstance3D] = []
var time_accum: float = 0.0

func _ready() -> void:
	_generate_rings()
	time_accum = randf() * 100.0

func _process(delta: float) -> void:
	time_accum += delta
	
	# Gentle breathing animation
	for i in range(rings.size()):
		var ring = rings[i]
		var breathe = 1.0 + sin(time_accum * breathing_speed + (i * 0.2)) * breathing_amount
		ring.scale = Vector3(breathe, 1.0, breathe)

func _generate_rings() -> void:
	if not container:
		container = Node3D.new()
		container.name = "RingsContainer"
		add_child(container)

	# Create concentric rings like a traditional target (bullseye)
	# Rings are horizontal flat disks stacked with slight z-offset
	# Outer rings are larger, inner rings are smaller

	var num_rings = palette.size()
	var ring_thickness = 0.1  # Height of each cylinder (thin disks)
	var max_radius = target_radius
	var radius_step = max_radius / num_rings

	for i in range(num_rings):
		# Outer rings first (palette[0] is outermost)
		var ring_radius = max_radius - (i * radius_step)
		var color = palette[i]
		# Small z-offset so inner rings appear on top
		var z_offset = i * 0.001

		_create_ring(ring_radius, ring_thickness, color, z_offset)

func _create_ring(radius: float, thickness: float, color: Color, z_offset: float) -> void:
	var mesh_inst = MeshInstance3D.new()

	var cyl = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = thickness
	cyl.radial_segments = 32

	mesh_inst.mesh = cyl
	mesh_inst.material_override = _create_material(color)
	# Rotate 90 degrees on X axis so the disk is horizontal (facing forward)
	mesh_inst.rotation_degrees.x = 90.0
	mesh_inst.position.z = z_offset

	container.add_child(mesh_inst)
	rings.append(mesh_inst)

func _create_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	mat.roughness = 0.2
	mat.metallic = 0.1
	return mat

func damage(_amount: float) -> void:
	_on_hit()

func hit() -> void:
	_on_hit()

func _on_hit() -> void:
	# Feedback
	_flash()
	if audio_player and audio_player.stream:
		# Random pitch to make it musical
		audio_player.pitch_scale = randf_range(0.8, 1.2)
		audio_player.play()
	
	if hit_particles:
		hit_particles.emitting = true
	
	# Score
	GameManager.add_points(points_per_hit)

func _flash() -> void:
	# Flash all materials white
	var tween = create_tween()
	for ring in rings:
		var initial_mat = ring.material_override as StandardMaterial3D
		var initial_emission = initial_mat.emission
		
		# Flash emission bright
		tween.parallel().tween_property(initial_mat, "emission", Color.WHITE * 3.0, 0.05)
		tween.parallel().tween_property(initial_mat, "emission", initial_emission, 0.2).set_delay(0.05)
