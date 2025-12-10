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

# Colors based on the Progress Pride Flag + Traditional Rainbow
var palette: Array[Color] = [
	Color("#E40303"), # Life (Red) - Outer
	Color("#FF8C00"), # Healing (Orange)
	Color("#FFED00"), # Sunlight (Yellow)
	Color("#008026"), # Nature (Green)
	Color("#004DFF"), # Harmony (Blue)
	Color("#750787"), # Spirit (Purple)
	Color("#FFFFFF"), # Magic/Nonbinary (White)
	Color("#F5A9B8"), # Trans Pink
	Color("#5BCEFA"), # Trans Blue
	Color("#613915"), # POC Inclusion (Brown)
	Color("#000000"), # HIV/AIDS Awareness (Black) - Inner
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
		# Rotate container 90 degrees on Z so the stack lies horizontally
		container.rotation_degrees.z = 90.0
	
	# Create a "Totem" stack of cylinders (Horizontal Bar)
	# Stripe sequence: Red -> Purple -> White -> Black
	
	var num_segments = palette.size()
	var segment_height = 0.15 # Length of each stripe
	var total_length = segment_height * num_segments
	var radius = 0.3 # Thickness of the bar
	
	# Center the stack
	var start_y = -total_length * 0.5
	
	for i in range(num_segments):
		var y_pos = start_y + (i * segment_height) + (segment_height * 0.5)
		var color = palette[i]
		
		_create_segment(radius, segment_height, color, y_pos)

func _create_segment(radius: float, height: float, color: Color, y_offset: float) -> void:
	var mesh_inst = MeshInstance3D.new()
	
	var cyl = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 32
	
	mesh_inst.mesh = cyl
	mesh_inst.material_override = _create_material(color)
	mesh_inst.position.y = y_offset
	
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

func damage(amount: float) -> void:
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
