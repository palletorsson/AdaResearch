extends Node3D

## Resonating Metallophone
## A complete musical instrument with multiple resonating bars
## Hit with the stick to create harmonious resonances!


# @identity
# essence: bar[i].frequency = pentatonic_scale[i], amplitude(t) = A * e^(-t/decay)
# desire: Strike metal bars and hear pentatonic tones ring while seeing combined wave visualization
# critical_parameter: decay_time — controls how long each bar resonates after being struck
# triggers: striking a bar initiates a decaying sinusoidal vibration at that frequency
# emerges: music from physics — the pentatonic scale emerges from choosing bar lengths
# needs: VR strike interaction [has], wave visualizer [has]
# relationships: depends on ResonatingBar physics; contrasts with chladni_plate (discrete strikes vs continuous vibration); unlocks resonance and timbre
# truth: Every object has frequencies at which it wants to vibrate — striking reveals its voice.

## --- DNA (stage 2, promoted 2026-08-05) ---
##
## STAGE-2 DNA PROMOTION. The registry says of this artifact: "each bar's length
## determines its pitch, shorter bars vibrate faster". That was not true. Every bar was
## the same box, and the pitch was a NUMBER handed to an audio generator — the physical
## claim the artifact exists to make was the one thing it did not make. (Worse: the box
## was not drawn at all. See ResonatingBar._setup_visual.)
##
## So the axis is the one the instrument is actually about:
##
##   tuning   which scale the row is CUT to
##
## A free-free bar's flexural frequency goes as h/L², so L is proportional to 1/sqrt(f)
## and a scale is a SHAPE — both in how long each bar is and in how many there are.
## Four scales, four visibly different rows: pentatonic steps down in uneven jumps where
## the scale skips its fourth and seventh, eight bars across a fifth of an octave short
## of two; just intonation covers the same ground in ten; equal temperament needs
## seventeen and grades them evenly, every bar the same ratio shorter than the last; and
## the harmonic series — the tuning nature actually uses — is not a division of a range
## at all and collapses away in a hyperbola. See the TUNINGS block for why the count
## carries as much of the argument as the length does.
##
## tuning=pentatonic is the shipped C-major-pentatonic series note for note, so the
## sound of all 7 placements is unchanged. What is NOT unchanged is that the bars are
## now visible; they never were. That is a repair, not a variant, and it is recorded as
## such in the registry's dna.was.
##
## Usage in map_data.json:
##   "resonating_metallophone#tuning:equal"

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

## FOUR WAYS TO FILL THE SAME RANGE, and the count is the argument.
##
## The first cut of this axis kept eight bars for every value and only re-cut their
## lengths. That is not what a tuning is. A tuning is a rule for dividing a range, and
## the first thing the rule decides is HOW MANY notes there are — five to the octave or
## twelve to the octave is the whole difference between the instruments, and a row that
## always has eight bars is always the same instrument slightly re-filed. Measured, and
## this is why it changed: pentatonic against just came back 0.233% apart on a subject
## filling 11.3% of the frame. They differed by a few millimetres on five of eight bars
## because both are just-ish ratios; the picture was correct and the axis was not saying
## anything with it.
##
## So every value now states its scale over the SAME PITCH RANGE — C4 up to E5, which is
## the range the shipped pentatonic row already spans — at its own cardinality:
##
##   pentatonic  5 to the octave   ->  8 bars   (THE SHIPPED ROW, note for note)
##   just        7 to the octave   -> 10 bars
##   equal      12 to the octave   -> 17 bars
##   harmonic   not a division of a range at all
##
## Every one of these lists is a pure APPEND to the list it replaces — no frequency that
## was declared before has moved — and pentatonic is untouched, so the 7 placements ring
## and measure exactly as they did.
##
## harmonic is the value that refuses the frame, and that refusal is its claim. The
## overtone series is not a way of dividing a range; it climbs from the fundamental and
## crosses E5 on its second step. Asked to fill the range it would give TWO bars, so it is
## allowed to keep running instead — twelve partials over three and a half octaves,
## crowding visibly toward nothing, which is precisely why nobody tunes an instrument to
## it. Twelve is also a count no other value here has, so the row still cannot be confused
## with any of them.
const TUNINGS = {
	"pentatonic": PENTATONIC_SCALE,
	# 12-TET semitones C4 -> E5. Every step the same RATIO, so every bar the same
	# fraction shorter than its neighbour: an evenly graded row, and seventeen of them
	# where the pentatonic gets eight.
	"equal": [261.63, 277.18, 293.66, 311.13, 329.63, 349.23, 369.99, 392.00,
		415.30, 440.00, 466.16, 493.88, 523.25, 554.37, 587.33, 622.25, 659.25],
	# 5-limit just major from C4: 1, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8, 2, then 9/4 and 5/2
	# to reach the same E5. The whole temperament argument, in centimetres.
	"just": [261.63, 294.33, 327.04, 348.84, 392.45, 436.05, 490.56, 523.26,
		588.67, 654.08],
	# The overtone series on C4 — what a single vibrating body actually contains.
	# Frequency is linear in the partial, so length falls as 1/sqrt(n): a hyperbola,
	# and by the twelfth partial the bar is 8.7 cm against the fundamental's 30.
	"harmonic": [261.63, 523.26, 784.89, 1046.52, 1308.15, 1569.78, 1831.41, 2093.04,
		2354.67, 2616.30, 2877.93, 3139.56],
}

## The shipped bar, from the CollisionShape3D in resonating_bar.tscn. BAR_LENGTH is
## now the length of the LOWEST bar; the rest are cut from it by the physics.
const BAR_WIDTH = 0.08
const BAR_THICK = 0.04
const BAR_LENGTH = 0.30

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
## DNA gene: which scale the row of bars is CUT to — how many bars there are and how
## long each one is. Pitch on a metallophone is not a number attached to a bar, it is
## the bar's LENGTH; a scale is not a set of pitches, it is a count. "pentatonic" is the
## shipped series and the shipped eight-bar row.
@export_enum("pentatonic", "equal", "just", "harmonic") var tuning: String = "pentatonic"

var bars: Array[ResonatingBar] = []
var visualizer: Node3D

var _bar_container: Node3D
var _freq_labels: Array[Label3D] = []
var _built: bool = false

func _ready() -> void:
	# The grid stamps `config_<key>` metadata before _ready; apply_grid_config only
	# arrives on a deferred frame, after the row is already cut.
	if has_meta("config_tuning"):
		tuning = str(get_meta("config_tuning")).to_lower()
	_create_bars()
	_create_visualizer()
	_create_stick()
	_create_instructions()
	_built = true

## The active scale. An unknown value falls back to the shipped pentatonic rather
## than to an empty row.
func _tuned_scale() -> Array:
	return TUNINGS.get(tuning, PENTATONIC_SCALE)

## A free-free bar vibrates at f = k * h / L^2, so length goes as 1 / sqrt(f). The
## lowest note keeps the shipped BAR_LENGTH and every higher one is cut from it —
## which is what makes a scale something you can SEE rather than only hear.
func _bar_length(freq: float, root: float) -> float:
	return BAR_LENGTH * sqrt(root / maxf(1.0, freq))

func _create_bars() -> void:
	"""Create all the resonating bars in a row"""
	var scale_hz: Array = _tuned_scale()
	var root: float = float(scale_hz[0])
	var bar_container = Node3D.new()
	bar_container.name = "Bars"
	add_child(bar_container)
	_bar_container = bar_container

	for i in range(scale_hz.size()):
		var bar = _create_single_bar(i, scale_hz, root)
		bars.append(bar)
		bar_container.add_child(bar)

		# Position in a row
		var x_pos = (i - scale_hz.size() * 0.5) * bar_spacing
		bar.position = Vector3(x_pos, 0, 0)

	print("ResonatingMetallophone: Created %d bars (tuning=%s)" % [bars.size(), tuning])

func _create_single_bar(index: int, scale_hz: Array, root: float) -> ResonatingBar:
	"""Create a single resonating bar"""
	# Load the resonating bar scene
	var bar_scene = load("res://algorithms/wavefunctions/resonance/resonating_bar.tscn")
	var bar: ResonatingBar
	var freq: float = float(scale_hz[index])
	var size := Vector3(BAR_WIDTH, BAR_THICK, _bar_length(freq, root))

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
		box_mesh.size = size
		mesh_instance.mesh = box_mesh
		bar.add_child(mesh_instance)

		# Add collision
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = size
		collision_shape.shape = box_shape
		bar.add_child(collision_shape)

	# Set properties. bar_size lands before the bar enters the tree, so its own
	# _setup_visual builds the mesh and its private collision shape at this length.
	bar.bar_size = size
	bar.frequency = freq
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

	_create_freq_labels()

func _create_freq_labels() -> void:
	"""One Hz label under each bar, reading the scale the row is currently cut to"""
	var scale_hz: Array = _tuned_scale()
	for i in range(bars.size()):
		var freq_label = Label3D.new()
		freq_label.text = "%.0f Hz" % float(scale_hz[i])
		var x_pos = (i - scale_hz.size() * 0.5) * bar_spacing
		freq_label.position = Vector3(x_pos, -0.15, 0)
		freq_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		freq_label.font_size = 16
		freq_label.modulate = BAR_COLORS[i % BAR_COLORS.size()]
		freq_label.outline_size = 3
		freq_label.outline_modulate = Color(0, 0, 0, 1)
		freq_label.scale = Vector3.ONE * 0.06
		add_child(freq_label)
		_freq_labels.append(freq_label)

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

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## DNA / map config. GUARDED: the row is re-cut only when `tuning` actually names a
## DIFFERENT known scale and only after _ready has built once. An unguarded rebuild
## here would tear down and respawn eight rigid bodies on every call, including the
## calls that name nothing this artifact owns.
func apply_grid_config(config: Dictionary) -> void:
	if not config.has("tuning"):
		return
	var want: String = str(config["tuning"]).to_lower()
	if want == tuning or not TUNINGS.has(want):
		return
	tuning = want
	if _built:
		_recut()

## Re-cut the row: only the bars and their Hz labels. The stick, the title and the
## wave visualizer are untouched — nothing about them is tuned.
func _recut() -> void:
	bars.clear()
	if is_instance_valid(_bar_container):
		_bar_container.queue_free()
	for lbl in _freq_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_freq_labels.clear()
	_create_bars()
	_create_freq_labels()
