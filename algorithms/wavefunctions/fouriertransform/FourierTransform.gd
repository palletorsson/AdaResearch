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
## SignalTypeSlider runs 0-3 and cannot reach impulse or noise; those two are reachable only
## from the map token. The order here matches signal_types, not the axis declaration.
const SLIDER_WAVEFORMS := ["sine", "square", "triangle", "sawtooth"]

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

# =============================================================================
# DEEPENED 2026-08-03 — the third axis: waveform
# =============================================================================
# The first pass got the transform onstage and left it transforming ONE signal. Every
# placement of this bench shows a sine at 1.1 Hz, because SignalTypeSlider — the only thing
# that could ever have changed it — is a Control node map placements suppress as demo chrome,
# and generate_signal_at_time's match already had square, triangle and sawtooth waiting
# behind it. A Fourier bench that can only ever transform a sine cannot say why anyone
# bothers: the whole interest of the transform is that DIFFERENT signals have different
# spectra, and one signal is not a comparison.
#
#   sine     — the shipped signal, byte for byte. One frequency in, one bar out.
#   square   — the classic: odd harmonics, 1/h. The spectrum grows a whole family of bars
#              the time-domain picture gives no hint of.
#   impulse  — a narrow pulse train. Localised in time, spread across every bin: the
#              uncertainty argument, which is the reason the pair of domains is a pair.
#   triangle — odd harmonics again but falling much faster; near-sine to the eye, plainly
#              not to the transform. The value that separates looking from measuring.
#   sawtooth — all harmonics, the densest spectrum a periodic signal here produces.
#   noise    — no period at all. Deterministic hash, not randf(): a sweep must be able to
#              render the same variant twice and get the same picture.
#
# Measured on the shipped sampling before it was written: the frequency bars peak at 3.4
# (sine), 5.0 (square), 15.0 (impulse), 26.8 (triangle), 1.2 (sawtooth) and 9.6 (noise)
# world units, and the time-domain sample heights are distinct patterns at every phase.
@export_enum("sine", "square", "impulse", "triangle", "sawtooth", "noise") var waveform: String = "sine"

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
	var idx: int = clampi(int(value), 0, signal_types.size() - 1)
	signal_type_label.text = "Signal Type: " + str(signal_types[idx])
	# The slider now moves the DNA value rather than signal_type directly, so the two cannot
	# disagree. Index 0 is "sine", which is the slider's own default, so the demo starts
	# exactly where it always did.
	if signal_generator:
		signal_generator.set_waveform_mode(str(SLIDER_WAVEFORMS[idx]))
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
		# signal_type is NOT written here any more — it belongs to `waveform`, and writing it
		# from the slider on every parameter change would silently undo a placement's DNA the
		# first time anything else moved. The slider feeds waveform in its own handler; at
		# startup both say sine, so the value this line used to write is the value that stands.
		signal_generator.frequency = frequency_slider.value
		signal_generator.amplitude = amplitude_slider.value
		signal_generator.harmonics = int(harmonics_slider.value)
		signal_generator.update_signal()

func _apply_dna() -> void:
	if signal_generator == null:
		return
	# All three setters are no-ops when the value already matches, so a default placement
	# never touches the display the child built in its own _ready().
	# waveform FIRST: the other two only decide what is shown, this decides what it is.
	signal_generator.set_waveform_mode(waveform)
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
	if config.has("waveform"):
		var wanted_wave: String = str(config["waveform"]).strip_edges()
		if wanted_wave != "" and wanted_wave != waveform:
			waveform = wanted_wave
			dirty = true
	# Only rebuild when a value actually changed AND _ready has already built once.
	# Called before _ready (the usual case from GridInteractablesComponent), the vars
	# are simply set and _ready's own _apply_dna() picks them up.
	if dirty and is_node_ready():
		_apply_dna()
