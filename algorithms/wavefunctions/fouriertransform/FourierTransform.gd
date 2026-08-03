extends Node3D

@onready var signal_generator = $SignalGenerator
@onready var signal_type_slider = $UI/VBoxContainer/SignalTypeSlider
@onready var frequency_slider = $UI/VBoxContainer/FrequencySlider
@onready var amplitude_slider = $UI/VBoxContainer/AmplitudeSlider
@onready var harmonics_slider = $UI/VBoxContainer/HarmonicsSlider
@onready var signal_type_label = $UI/VBoxContainer/SignalTypeLabel
@onready var frequency_label = $UI/VBoxContainer/FrequencyLabel
@onready var amplitude_label = $UI/VBoxContainer/AmplitudeLabel
@onready var harmonics_label = $UI/VBoxContainer/HarmonicsLabel
@onready var transform_button = $UI/VBoxContainer/TransformButton
@onready var reset_button = $UI/VBoxContainer/ResetButton

var signal_types = ["Sine Wave", "Square Wave", "Triangle Wave", "Sawtooth Wave"]

# =============================================================================
# DNA — stage 2, promoted 2026-07-29
# =============================================================================
# Two hard-coded facts in this artifact were secretly a parameter space.
#
# domain: create_frequency_domain_display() ended with set_frequency_domain_visible(false)
#   and the only way back was the "Compute FFT" button — a Control node that map
#   placements suppress as demo chrome. So the artifact named after a transform showed
#   only one side of it, everywhere it has ever been placed. The axis makes that a
#   choice: which domain is standing in the room, and whether the pair is shown at once.
#
# trace: the time-domain signal is 20 CSG spheres on a 0.5 grid — already a claim that a
#   signal is a finite set of samples, made without saying so. samples leaves the claim
#   implicit, stems draws each measurement down to the zero line and makes the sampling
#   the subject, ribbon fills the gaps and hides it behind a continuum. The same question
#   additive_wave_demo asks from the other direction: how much of the arithmetic is shown.
@export_enum("time", "frequency", "both") var domain: String = "time"
@export_enum("samples", "stems", "ribbon") var trace: String = "samples"

func _ready() -> void:
	# Connect UI signals
	signal_type_slider.value_changed.connect(_on_signal_type_changed)
	frequency_slider.value_changed.connect(_on_frequency_changed)
	amplitude_slider.value_changed.connect(_on_amplitude_changed)
	harmonics_slider.value_changed.connect(_on_harmonics_changed)
	transform_button.pressed.connect(_on_transform_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	
	# Initialize the signal generator
	_update_signal_parameters()
	_apply_dna()

func _on_signal_type_changed(value) -> void:
	var signal_type = signal_types[int(value)]
	signal_type_label.text = "Signal Type: " + signal_type
	_update_signal_parameters()

func _on_frequency_changed(value) -> void:
	frequency_label.text = "Frequency: " + str(value) + " Hz"
	_update_signal_parameters()

func _on_amplitude_changed(value) -> void:
	amplitude_label.text = "Amplitude: " + str(value)
	_update_signal_parameters()

func _on_harmonics_changed(value) -> void:
	harmonics_label.text = "Harmonics: " + str(int(value))
	_update_signal_parameters()

func _on_transform_pressed() -> void:
	signal_generator.compute_fft()

func _on_reset_pressed() -> void:
	signal_generator.reset_signal()
	_update_signal_parameters()

func _update_signal_parameters() -> void:
	if signal_generator:
		signal_generator.signal_type = int(signal_type_slider.value)
		signal_generator.frequency = frequency_slider.value
		signal_generator.amplitude = amplitude_slider.value
		signal_generator.harmonics = int(harmonics_slider.value)
		signal_generator.update_signal()

func _apply_dna() -> void:
	if signal_generator == null:
		return
	# Both setters are no-ops when the value already matches, so a default placement
	# never touches the display the child built in its own _ready().
	signal_generator.set_domain_mode(domain)
	signal_generator.set_trace_mode(trace)

func apply_grid_config(config: Dictionary) -> void:
	var dirty: bool = false
	if config.has("domain"):
		var wanted_domain: String = str(config["domain"]).strip_edges()
		if wanted_domain != "" and wanted_domain != domain:
			domain = wanted_domain
			dirty = true
	if config.has("trace"):
		var wanted_trace: String = str(config["trace"]).strip_edges()
		if wanted_trace != "" and wanted_trace != trace:
			trace = wanted_trace
			dirty = true
	# Only rebuild when a value actually changed AND _ready has already built once.
	# Called before _ready (the usual case from GridInteractablesComponent), the vars
	# are simply set and _ready's own _apply_dna() picks them up.
	if dirty and is_node_ready():
		_apply_dna()
