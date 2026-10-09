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

## STAGE-2 DNA PROMOTION (2026-07-29). Before this the root exposed no exports at
## all: the whole parameter space lived in a 2D Control panel that the grid strips
## out of every map placement (the demo-as-artifact UI suppression). So all 8
## placements were the same 20x20 field of half-metre cubes, displaced in y, tinted
## pink-to-teal — and nothing in map_data could say otherwise.
##
## Two axes, both lifted from constants already in this scene:
##
##   readout  WHAT the field is claimed to BE    relief · plate · column
##            (the cube.position.y = value line in SimplexVisualizer)
##   octaves  HOW MANY scales are summed         1 · 2 · 4 · 6
##            (noise_generator.fractal_octaves = 4, hard-coded in _ready)
##
## readout is the argument. relief reads the noise as TERRAIN — a landscape you
## could walk, which is how noise is usually sold. plate flattens every cube to the
## ground and leaves only the colour, so the field is an IMAGE of a scalar function
## and the mountains are revealed as our reading of it, not a property of it.
## column grows each cube from the floor to its value, so each sample is a MEASURED
## QUANTITY standing in a bar chart — noise as data, before it is scenery.
##
## octaves is the honest twin of the @identity's critical_parameter. persistence
## says how much each successive octave contributes; with the octave count nailed
## at 4 you can never see the term it is weighting. At 1 the field is pure simplex
## and its isotropy is legible; at 6 it is fractal brownian terrain and the lattice
## disappears under detail.
##
## readout=relief, octaves=4 is exactly the pre-promotion behaviour and is the
## default, so all 8 existing placements are untouched.
##
## Usage in map_data.json:
##   "simplex_noise"
##   "simplex_noise#readout:plate"
##   "simplex_noise#readout:column#octaves:1"

## What the field is claimed to be: terrain, image, or measured quantities.
@export_enum("relief", "plate", "column") var readout: String = "relief"
## How many scales of noise are summed. 1 = pure simplex, 6 = fractal terrain.
@export_range(1, 8, 1) var octaves: int = 4

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
		# DNA axes travel with the sliders. octaves=4 and readout="relief" are what
		# the visualizer already did, so the default path changes nothing.
		noise_field.octaves = octaves
		noise_field.readout = readout
		noise_field.update_noise_field()

## Grid system integration.
## Guarded: the field is only re-read when a value actually changed, and never
## before _ready has built the cubes (noise_field is @onready, so it is null until
## then — the values simply wait and are picked up by _ready's own update).
func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = false
	if config.has("readout"):
		var r: String = str(config["readout"])
		if r != readout:
			readout = r
			changed = true
	if config.has("octaves"):
		var o: int = int(config["octaves"])
		if o != octaves:
			octaves = o
			changed = true
	if changed and noise_field != null:
		_update_noise_parameters()
