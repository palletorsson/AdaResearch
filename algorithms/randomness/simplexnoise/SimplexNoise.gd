extends Node3D

# @identity
# essence: simplex(p) = Σ contribution(simplex_vertex) over the n+1 vertices of the simplex enclosing p, where contributions use (r² - dist²)⁴ falloff — no grid artifacts because simplexes have no axis-aligned edges
# desire: to compare two landscapes side-by-side and feel the difference between Perlin's rectangular grid bias and Simplex's isotropic smoothness — to see algorithm aesthetics with your body
# critical_parameter: persistence — controls how much each successive octave contributes relative to the previous; high persistence makes noise spiky and self-similar, low persistence makes it smooth with barely-visible detail
# triggers: compare_button is designed to show Perlin vs Simplex simultaneously — currently logs to console but demonstrates the design intent of architectural comparison
# emerges: the learner notices that Simplex noise has no preferred directions — mountain ridges don't tend to align with axes the way Perlin's do, which becomes perceptible when generating large terrains
# needs: frequency slider [has] (2D UI); amplitude slider [has]; persistence slider [has]; compare button [has] (non-functional); regenerate button [has]; no VR slider_horizontal controls [missing]
# relationships: contrasts with PerlinNoise.gd (same scene architecture, different algorithm); shares the Noise_Perlin_Simplex map for direct comparison; Simplex is Perlin's successor — fewer visual artifacts, better performance in higher dimensions
# truth: Simplex noise solved Perlin's axis-alignment problem by changing the grid — the simplex lattice has no preferred directions, so randomness becomes genuinely isotropic

@onready var noise_field = $NoiseField
@onready var frequency_slider = $UI/VBoxContainer/FrequencySlider
@onready var amplitude_slider = $UI/VBoxContainer/AmplitudeSlider
@onready var persistence_slider = $UI/VBoxContainer/PersistenceSlider
@onready var frequency_label = $UI/VBoxContainer/FrequencyLabel
@onready var amplitude_label = $UI/VBoxContainer/AmplitudeLabel
@onready var persistence_label = $UI/VBoxContainer/PersistenceLabel
@onready var regenerate_button = $UI/VBoxContainer/RegenerateButton
@onready var compare_button = $UI/VBoxContainer/CompareButton

func _ready() -> void:
	# Connect UI signals
	frequency_slider.value_changed.connect(_on_frequency_changed)
	amplitude_slider.value_changed.connect(_on_amplitude_changed)
	persistence_slider.value_changed.connect(_on_persistence_changed)
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	compare_button.pressed.connect(_on_compare_pressed)
	
	# Initialize the noise field
	_update_noise_parameters()

func _on_frequency_changed(value) -> void:
	frequency_label.text = "Frequency: " + str(value)
	_update_noise_parameters()

func _on_amplitude_changed(value) -> void:
	amplitude_label.text = "Amplitude: " + str(value)
	_update_noise_parameters()

func _on_persistence_changed(value) -> void:
	persistence_label.text = "Persistence: " + str(value)
	_update_noise_parameters()

func _on_regenerate_pressed() -> void:
	noise_field.regenerate_noise()

func _on_compare_pressed() -> void:
	# This could open a comparison scene or overlay
	print("Comparison feature - could show Perlin vs Simplex side by side")

func _update_noise_parameters() -> void:
	if noise_field:
		noise_field.frequency = frequency_slider.value
		noise_field.amplitude = amplitude_slider.value
		noise_field.persistence = persistence_slider.value
		noise_field.update_noise_field()

func apply_grid_config(config: Dictionary) -> void:
	pass
