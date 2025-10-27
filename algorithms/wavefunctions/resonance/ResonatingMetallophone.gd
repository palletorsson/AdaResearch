extends Node3D

## Resonating Metallophone
## A complete musical instrument with multiple resonating bars
## Hit with the stick to create harmonious resonances!

const RESONATING_BAR = preload("res://algorithms/wavefunctions/resonance/resonating_bar.tscn")

# Musical scale: C major pentatonic (C, D, E, G, A)
# These frequencies sound harmonious together
const PENTATONIC_SCALE = [
	261.63,  # C4
	293.66,  # D4
	329.63,  # E4
	392.00,  # G4
	440.00,  # A4
	523.25,  # C5
	587.33,  # D5
	659.25,  # E5
]

# Rainbow colors for the bars
const BAR_COLORS = [
	Color(1.0, 0.3, 0.3),  # Red
	Color(1.0, 0.7, 0.2),  # Orange
	Color(1.0, 1.0, 0.2),  # Yellow
	Color(0.3, 1.0, 0.3),  # Green
	Color(0.3, 0.7, 1.0),  # Blue
	Color(0.6, 0.3, 1.0),  # Indigo
	Color(1.0, 0.3, 0.9),  # Violet
	Color(1.0, 0.6, 0.8),  # Pink
]

@export var bar_spacing: float = 0.12
@export var decay_time: float = 3.0
@export var visualizer_height: float = 1.0

var bars: Array[ResonatingBar] = []
var visualizer: Node3D

func _ready() -> void:
	_create_bars()
	_create_visualizer()
	_create_stick()
	_create_instructions()

func _create_bars() -> void:
	"""Create all the resonating bars in a row"""
	var bar_container = Node3D.new()
	bar_container.name = "Bars"
	add_child(bar_container)

	for i in range(PENTATONIC_SCALE.size()):
		var bar = _create_single_bar(i)
		bars.append(bar)
		bar_container.add_child(bar)

		# Position in a row
		var x_pos = (i - PENTATONIC_SCALE.size() * 0.5) * bar_spacing
		bar.position = Vector3(x_pos, 0, 0)

	print("ResonatingMetallophone: Created %d bars" % bars.size())

func _create_single_bar(index: int) -> ResonatingBar:
	"""Create a single resonating bar"""
	# Load the resonating bar scene
	var bar_scene = load("res://algorithms/wavefunctions/resonance/resonating_bar.tscn")
	var bar: ResonatingBar

	if bar_scene:
		bar = bar_scene.instantiate()
	else:
		# Fallback: create manually if scene doesn't exist
		bar = ResonatingBar.new()
		bar.name = "Bar_%d" % index

		# Add mesh
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(0.08, 0.04, 0.3)
		mesh_instance.mesh = box_mesh
		bar.add_child(mesh_instance)

		# Add collision
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(0.08, 0.04, 0.3)
		collision_shape.shape = box_shape
		bar.add_child(collision_shape)

	# Set properties
	bar.frequency = PENTATONIC_SCALE[index]
	bar.bar_color = BAR_COLORS[index % BAR_COLORS.size()]
	bar.decay_time = decay_time
	bar.contact_monitor = true
	bar.max_contacts_reported = 4

	return bar

func _create_visualizer() -> void:
	"""Create the combined wave visualizer"""
	visualizer = Node3D.new()
	visualizer.name = "CombinedWaveVisualizer"
	visualizer.position.y = visualizer_height

	# Load and set script
	var visualizer_script = load("res://algorithms/wavefunctions/resonance/CombinedWaveVisualizer.gd")
	if visualizer_script:
		visualizer.set_script(visualizer_script)

	add_child(visualizer)

func _create_stick() -> void:
	"""Create a grab stick for hitting the bars"""
	var stick_scene = load("res://commons/primitives/cubes/grab_long_stick.tscn")
	if stick_scene:
		var stick = stick_scene.instantiate()
		stick.name = "GrabStick"
		stick.position = Vector3(-0.5, 0.5, -0.3)
		stick.add_to_group("stick")  # Add to group so bars recognize it
		add_child(stick)
		print("ResonatingMetallophone: Stick created")

func _create_instructions() -> void:
	"""Create instruction label"""
	var label = Label3D.new()
	label.text = "HIT THE BARS WITH THE STICK!"
	label.position = Vector3(0, -0.3, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	label.modulate = Color(1, 1, 0.5, 1)
	label.outline_size = 5
	label.outline_modulate = Color(0, 0, 0, 1)
	label.scale = Vector3.ONE * 0.07
	add_child(label)

	# Add frequency labels
	for i in range(bars.size()):
		var freq_label = Label3D.new()
		freq_label.text = "%.0f Hz" % PENTATONIC_SCALE[i]
		var x_pos = (i - PENTATONIC_SCALE.size() * 0.5) * bar_spacing
		freq_label.position = Vector3(x_pos, -0.15, 0)
		freq_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		freq_label.font_size = 16
		freq_label.modulate = BAR_COLORS[i % BAR_COLORS.size()]
		freq_label.outline_size = 3
		freq_label.outline_modulate = Color(0, 0, 0, 1)
		freq_label.scale = Vector3.ONE * 0.06
		add_child(freq_label)

# Public API
func stop_all_resonances() -> void:
	"""Stop all bars from resonating"""
	for bar in bars:
		bar.force_stop()

func get_active_frequencies() -> Array[float]:
	"""Get all currently resonating frequencies"""
	var active_freqs: Array[float] = []
	for bar in bars:
		if bar.is_resonating:
			active_freqs.append(bar.frequency)
	return active_freqs
