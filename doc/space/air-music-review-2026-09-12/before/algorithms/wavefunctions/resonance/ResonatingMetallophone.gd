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

## THE STAGING AXIS (2026-09-11, WaveFunctions_AirMusic, Astra's W3 thread). `none` is the
## shipped rig: bars at the origin's height, the stick dropped beside them, the captions hung
## below the origin. `table` builds the deck AT the origin (the museum's map-authored lane does
## not ground a body built in _ready): the row of bars on a table at hand height, a cradle on
## the table's front edge that the striker starts in and returns to when left elsewhere, the Hz
## labels and the instruction on the table's front face, the bars locked in place so a strike
## rings without displacing them, the combined wave and its voices readout above the row.
## Nothing about the tuning or the sound changes with the stand.
@export var stand: String = "none"

const TABLE_H: float = 0.85
const TABLE_W: float = 1.50
const TABLE_SPACING: float = 0.16   # the striker's tip is a 10 cm ball: at the shipped 0.12 m it rang two bars at once
const TABLE_D: float = 0.56
const STICK_AWAY_M: float = 0.5        # the striker counts as "left elsewhere" beyond this
const STICK_RETURN_S: float = 3.0       # ...for this long

var _lift: float = 0.0
var _staging_root: Node3D
var _stick: Node3D
var _stick_rest: Transform3D
var _stick_away_time: float = 0.0
var _stick_returning: bool = false
var _stick_last_pos: Vector3
var _stick_speed: float = 0.0
var stick_returns: int = 0

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
	if has_meta("config_stand"):
		stand = _stand_name(str(get_meta("config_stand")))
	_lift = (TABLE_H + BAR_THICK * 0.5 + 0.005) if stand == "table" else 0.0
	if stand == "table":
		bar_spacing = TABLE_SPACING
	_create_bars()
	_create_visualizer()
	_create_stick()
	_create_instructions()
	if stand == "table":
		_build_staging()
	_built = true

static func _stand_name(raw: String) -> String:
	var w: String = raw.strip_edges().to_lower()
	return "table" if w in ["table", "desk", "stand", "bench"] else "none"

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

	bar_container.position.y = _lift
	for i in range(scale_hz.size()):
		var bar = _create_single_bar(i, scale_hz, root)
		bars.append(bar)
		bar_container.add_child(bar)

		# Position in a row
		var x_pos = (i - scale_hz.size() * 0.5) * bar_spacing
		bar.position = Vector3(x_pos, 0, 0)
		if stand == "table":
			# a strike rings the bar; it does not push it off the table (gravity 0, mass 0.5,
			# nothing else held it). Locked, the body still reports the striker's contact.
			bar.axis_lock_linear_x = true; bar.axis_lock_linear_y = true; bar.axis_lock_linear_z = true
			bar.axis_lock_angular_x = true; bar.axis_lock_angular_y = true; bar.axis_lock_angular_z = true
			# a locked bar that never moves falls asleep, and a sleeping body reports no contact
			# from a striker moved by its transform: keep it awake so the strike registers
			bar.can_sleep = false

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
	if stand == "table":
		# the sum and its readout above the row, below a standing eye: wave at 1.35 m
		visualizer.position.y = 0.40
		visualizer.set("display_height", 0.95)

	add_child(visualizer)

func _create_stick() -> void:
	"""Create a grab stick for hitting the bars"""
	var stick_scene = load("res://commons/primitives/cubes/grab_long_stick.tscn")
	if stick_scene:
		var stick = stick_scene.instantiate()
		stick.name = "GrabStick"
		stick.position = Vector3(-0.5, 0.5, -0.3)
		if stand == "table":
			# in the cradle at the table's LEFT end, lying front-to-back beside the first bar,
			# so the row of bars is free (12 September; it had lain along the front edge across
			# the row, and Astra's review read it as lying across the playable row)
			stick.position = Vector3(-0.70, TABLE_H + 0.13, 0.0)
			stick.rotation_degrees = Vector3(0.0, 90.0, 0.0)
		stick.add_to_group("stick")  # Add to group so bars recognize it
		add_child(stick)
		_stick = stick
		# THE HELD STRIKER NEVER REACHED A BAR (2026-09-11). XR Tools freezes a held pickable
		# (kinematic), clears its collision_mask and moves it to `picked_up_layer`; the bars'
		# mask is the default layer 1, so a strike with the stick in hand formed no contact
		# pair — only a thrown or dropped stick ever rang a bar. The bars listen on the
		# pick-up layer as well now, in every placement: a repair, not a variant.
		var pick_layer: int = int(stick.get("picked_up_layer")) if "picked_up_layer" in stick else 0
		if pick_layer > 0:
			for b in bars:
				(b as RigidBody3D).collision_mask |= pick_layer
		_stick_rest = stick.transform
		_stick_last_pos = stick.global_position
		print("ResonatingMetallophone: Stick created")

func _create_instructions() -> void:
	"""Create instruction label"""
	var label = Label3D.new()
	label.name = "Instruction"
	label.text = "HIT THE BARS WITH THE STICK!"
	label.position = Vector3(0, -0.3, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	label.modulate = Color(1, 1, 0.5, 1)
	label.outline_size = 5
	label.outline_modulate = Color(0, 0, 0, 1)
	label.scale = Vector3.ONE * 0.07
	if stand == "table":
		# on the table's front face, read from where a visitor stands; not through the bars
		label.text = "strike a bar · listen after the stick has left · then a second bar"
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.font_size = 22
		label.pixel_size = 0.0022      # 5 cm letters, read from the strip; the shipped label is 6 mm
		label.scale = Vector3.ONE
		label.outline_size = 2
		label.position = Vector3(0, TABLE_H - 0.30, TABLE_D * 0.5 + 0.012)
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
		if stand == "table":
			freq_label.position = Vector3(x_pos, TABLE_H - 0.10, TABLE_D * 0.5 + 0.012)
			freq_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			freq_label.pixel_size = 0.0022   # 4 cm figures under each bar, on the front face
		freq_label.font_size = 16
		freq_label.modulate = BAR_COLORS[i % BAR_COLORS.size()]
		freq_label.outline_size = 3
		freq_label.outline_modulate = Color(0, 0, 0, 1)
		freq_label.scale = Vector3.ONE * 0.06 if stand != "table" else Vector3.ONE
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

## The voices as a probe or a readout reads them: which bars ring, how loud now, how long
## since their strike, and whether their sound is still playing.
func get_active_voices() -> Array:
	var out: Array = []
	for i in bars.size():
		var bar: ResonatingBar = bars[i]
		if bar.is_resonating:
			out.append({"index": i, "frequency": bar.frequency, "amplitude": bar.current_amplitude,
				"seconds": bar.resonance_time, "playing": bar.audio_player != null and bar.audio_player.playing})
	return out

## A strike from code, for a probe or a fixture — NOT the striker's collision path.
func strike_bar(index: int, strength: float = 1.0) -> void:
	if index < 0 or index >= bars.size():
		return
	bars[index].hit_velocity = clampf(strength, 0.1, 1.0)
	bars[index]._trigger_resonance(bars[index].hit_velocity)

func get_stick() -> Node3D:
	return _stick

func stick_rest_position() -> Vector3:
	return to_global(_stick_rest.origin)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

## The striker's speed reaches the bar. An XR Tools pickable is frozen while held and moved
## by its transform, so its linear_velocity is zero at the moment of contact and every strike
## used to land at the minimum strength (0.1). The stick carries its measured speed as meta;
## ResonatingBar._on_body_hit reads it when present.
func _physics_process(delta: float) -> void:
	if _stick == null or not is_instance_valid(_stick):
		return
	var p: Vector3 = _stick.global_position
	_stick_speed = p.distance_to(_stick_last_pos) / maxf(delta, 0.0001)
	_stick_last_pos = p
	_stick.set_meta("speed", _stick_speed)
	if stand != "table" or _stick_returning:
		return
	# the return rest: left more than STICK_AWAY_M from its cradle and not held, the striker
	# comes back after STICK_RETURN_S
	var held: bool = _stick.has_method("is_picked_up") and bool(_stick.call("is_picked_up"))
	var away: float = p.distance_to(stick_rest_position())
	if held or away < STICK_AWAY_M:
		_stick_away_time = 0.0
		return
	_stick_away_time += delta
	if _stick_away_time >= STICK_RETURN_S:
		_return_stick()

func _return_stick() -> void:
	_stick_returning = true
	_stick_away_time = 0.0
	# on its way home the tip sweeps across the row: a returning striker rings nothing
	_stick.set_meta("returning", true)
	if _stick is RigidBody3D:
		(_stick as RigidBody3D).freeze = true
		(_stick as RigidBody3D).linear_velocity = Vector3.ZERO
		(_stick as RigidBody3D).angular_velocity = Vector3.ZERO
	# in two legs since 12 September: straight up first, then to the rest — a straight line
	# from a struck bar to a rest at the row's end swept the tip through the bars between
	# and rang them (the Hz readout named a third voice at 0.3 s in the first rerun)
	var lifted: Transform3D = _stick.transform
	lifted.origin.y += 0.30
	var tw := create_tween()
	tw.tween_property(_stick, "transform", lifted, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var high_rest: Transform3D = _stick_rest
	high_rest.origin.y += 0.30
	tw.tween_property(_stick, "transform", high_rest, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_stick, "transform", _stick_rest, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.finished.connect(func():
		_stick_returning = false
		_stick.set_meta("returning", false)
		stick_returns += 1)

## The table, its cradle, and the readout's place: built at the origin.
func _build_staging() -> void:
	_staging_root = Node3D.new()
	_staging_root.name = "Staging"
	add_child(_staging_root)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.19, 0.18)
	mat.roughness = 0.8
	var table := StaticBody3D.new()
	table.name = "Table"
	table.position = Vector3(0.0, TABLE_H * 0.5, 0.0)
	var mi := MeshInstance3D.new()
	mi.name = "Top"
	var box := BoxMesh.new()
	box.size = Vector3(TABLE_W, TABLE_H, TABLE_D)
	mi.mesh = box
	mi.material_override = mat
	table.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(TABLE_W, TABLE_H, TABLE_D)
	col.shape = shape
	table.add_child(col)
	_staging_root.add_child(table)
	# the front edge, marked: a pale rail along the playable edge and a low dark kerb along
	# the back, so the edge a hand reaches over is told from the drop behind (12 September)
	var HangarKit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	var rail: MeshInstance3D = HangarKit.box(Vector3(0.0, TABLE_H + 0.006, TABLE_D * 0.5 - 0.012), Vector3(TABLE_W, 0.012, 0.024), HangarKit.emissive(Color(0.95, 0.80, 0.45), 1.4))
	rail.name = "FrontRail"
	_staging_root.add_child(rail)
	var kerb: MeshInstance3D = HangarKit.box(Vector3(0.0, TABLE_H + 0.03, -TABLE_D * 0.5 + 0.012), Vector3(TABLE_W, 0.06, 0.024), mat)
	kerb.name = "BackKerb"
	_staging_root.add_child(kerb)
	# the cradle: two blocks at the table's left end the striker lies across, front to back
	for sz in [-0.18, 0.18]:
		var blk := StaticBody3D.new()
		blk.name = "Cradle%s" % ("L" if sz < 0.0 else "R")
		blk.position = Vector3(-0.70, TABLE_H + 0.05, sz)
		var bm := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = Vector3(0.05, 0.10, 0.06)
		bm.mesh = bb
		bm.material_override = mat
		blk.add_child(bm)
		var bc := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(0.05, 0.10, 0.06)
		bc.shape = bs
		blk.add_child(bc)
		_staging_root.add_child(blk)
	_house_readout()
	_quiet_striker()

## The voices readout as a cased plate a visitor can read from the strip, and a dark plate
## behind the sum: the visualiser's own label is a centimetre-high billboard (font 20 at
## scale 0.08) that no capture from the strip could resolve.
func _house_readout() -> void:
	if visualizer == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.13, 0.13, 0.14)
	mat.roughness = 0.75
	var wave_plate := MeshInstance3D.new()
	wave_plate.name = "WavePlate"
	var wb := BoxMesh.new()
	wb.size = Vector3(1.10, 0.34, 0.02)
	wave_plate.mesh = wb
	wave_plate.material_override = mat
	wave_plate.position = Vector3(0.0, 0.40 + 0.95, -0.02)   # behind the ribbon (visualizer y + display_height)
	_staging_root.add_child(wave_plate)
	var plate := MeshInstance3D.new()
	plate.name = "ReadoutPlate"
	var pb := BoxMesh.new()
	pb.size = Vector3(1.10, 0.14, 0.02)
	plate.mesh = pb
	plate.material_override = mat
	plate.position = Vector3(0.0, 0.40 + 0.95 + 0.26, -0.02)
	_staging_root.add_child(plate)
	var lbl: Label3D = visualizer.get("_status_label")
	if lbl != null:
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.scale = Vector3.ONE
		lbl.pixel_size = 0.0016
		lbl.font_size = 22
		lbl.outline_size = 0
		lbl.modulate = Color(0.85, 0.95, 1.0)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector3(0.0, 0.95 + 0.26, 0.0)   # in the visualiser's frame: on the plate

## The shared striker is also a position-reading rod elsewhere: a floating X/Y/Z display, a
## text node and a cloth trail come with it. On the table they are clutter across the
## visitor's view of the bars; hidden here, left alone in the stick's other placements.
func _quiet_striker() -> void:
	if _stick == null:
		return
	for n in _stick.find_children("*", "", true, false):
		var scene: String = str(n.get("scene_file_path")) if n is Node else ""
		var script_path: String = str(n.get_script().resource_path) if n.get_script() != null else ""
		var noisy: bool = scene.contains("displayobjectposition") or script_path.contains("mesmerizing_trail") or script_path.contains("text_node")
		if noisy and n is Node3D:
			(n as Node3D).visible = false
			n.set_process(false)
			n.set_physics_process(false)


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
	if visualizer != null and visualizer.has_method("_find_resonating_bars"):
		visualizer.call("_find_resonating_bars")
