# @identity
# essence: P(spawn) = P(remove) — steady-state random replacement
# desire: watch cubes appear and disappear at random intervals, hear the wood knock of each arrival
# critical_parameter: capacity — the carrying capacity; once reached, each spawn requires a death
# triggers: spawn_timer exceeding next_spawn_time (randomized 0.3–1.3s) triggers spawn or replace
# emerges: a column of cubes that never grows beyond capacity but is never the same column twice
# needs: AudioStreamGenerator for wood knock synthesis [has]; template cube [has]
# relationships: feeds Random_Cubes map; contrasts with remove_random (pure subtraction vs replacement); shares the randomness bench with random_cubes and pixel_cloud
# truth: Replacement is the metabolism of randomness — the system lives by forgetting what it was.

extends Node3D

# --- STAGE-2 DNA (promoted 2026-08-05, by hand) -------------------------------
# TWO HARD-CODED DECISIONS THAT WERE ALREADY A PARAMETER SPACE.
#
# 1. `dispersal` — THE LIE IN THE NAME. The registry calls this "a spawning
#    algorithm that randomly generates and places objects in the environment",
#    and it does not place them randomly at all: every cube in the artifact's
#    life enters the world at exactly `spawn_position`, one fixed spigot, and
#    whatever spread you see afterwards was made by collision, not by the
#    spawner. The randomness here is entirely in the CLOCK (next_spawn_time) and
#    in the KILL (randi() % size); the PLACE was never left to chance for one
#    frame. That is a real position — a point process with zero variance is
#    still a point process — but it was never declared, so nobody could tell
#    whether it was a claim or an oversight.
#
#    The values are ecology's three textbook dispersion patterns — random,
#    clumped, even (uniform/over-dispersed) — plus `spigot`, which names the
#    shipped degenerate case honestly. Ecology is the right vocabulary because
#    it is already this file's own: carrying capacity, metabolism, "each spawn
#    requires a death". The word was NOT borrowed from random_cubes, whose
#    `macrostate` (uniform | corner | layered | spilled) asks a different
#    question — WHICH REGION a fixed pile occupies, for the sake of counting the
#    ways it could have been. Same substrate, different question, and none of
#    its four values can name a single point, so taking the word would have
#    meant taking it without its answers.
#
# 2. `capacity` — was `const MAX_CUBES: int = 20`, and the @identity block above
#    already named it the critical parameter: "once reached, each spawn requires
#    a death". A constant that the file's own documentation calls the critical
#    parameter is a declared axis that nobody declared.
#
# NOT PROMOTED: next_spawn_time's 0.3–1.3 s window, the wood-knock synthesis
# (amplitude / decay_rate / main_freq / second_freq / noise_factor), and the
# choice of victim in remove_random_cube_and_spawn. The first two are a rate and
# a sound; the evidence for a DNA axis is one still PNG, and neither survives it.
# The third is real and interesting — uniform mortality is a memoryless
# assumption, and oldest-first or newest-first would be genuine rivals — but a
# wooden cube carries no visible age, so four mortality rules photograph as the
# same heap. It would need an age readout before it could be evidence, and that
# is a different artifact.
#
# THE BENCH KNOBS ARE NOT AXES AND ARE NOT DEFAULTS. initial_population,
# spawn_seed and freeze_arrivals all ship OFF, and dna.fixture turns them on for
# the sweep only. Without them this artifact is unphotographable by
# construction: the first cube arrives at t = 1.0 s and the shutter opens at
# 1.1 s, so every variant of every axis would render the same single cube, and
# a live RigidBody3D dropped at t = 0 has fallen six metres by then — out of a
# frame that was measured at 0.35 s.
# ------------------------------------------------------------------------------

## The shipped carrying capacity. Kept as the source of `capacity`'s default so
## the default is provably the constant it replaced.
const MAX_CUBES: int = 20

## Allow-lists. A typo in a map token falls back to the shipped behaviour rather
## than stranding a placement with an empty or nonsensical rule.
const DISPERSALS: PackedStringArray = ["spigot", "random", "clumped", "even"]

## Clump seeds for `clumped`, in units of `spread`. Fixed, so the clusters are a
## property of the rule and not of the draw; only membership is left to chance.
const CLUMP_CENTRES = [
	Vector3(-0.62, 0.0, -0.38),
	Vector3(0.55, 0.0, -0.58),
	Vector3(0.12, 0.0, 0.66),
]

## What law places an arriving cube. `spigot` is the shipped build: every cube at
## spawn_position, no draw taken, exactly as before.
@export_enum("spigot", "random", "clumped", "even") var dispersal: String = "spigot"

## Carrying capacity — how many cubes may live at once. Was const MAX_CUBES.
@export var capacity: int = MAX_CUBES

## Half-extent of the arrival field, in metres. Unused by `spigot`.
@export var spread: float = 0.5

## 0 keeps the shipped behaviour exactly — the global RNG, a different column
## every launch. Any other value pins the draws so one value of an axis is ONE
## arrangement rather than a fresh object per boot. dna.fixture sets it for the
## sweep only.
@export var spawn_seed: int = 0

## 0 is shipped: nothing is pre-placed and cubes arrive on the clock. A negative
## value fills to `capacity` during _ready; a positive one places that many.
@export var initial_population: int = 0

## Bench flag. Untyped on purpose: a typed bool rejects the string "true" that a
## map token would deliver, before _ready can convert it.
@export var freeze_arrivals = false

@export var cube_size: float = 1.0
@export var gutter: float = 0.0
@export var spawn_position: Vector3 = Vector3(0, 1, 0)  # Default position on table (y=1)
@onready var base_cube = $woodCube  # Template cube
var spawned_cubes: Array = []  # Track spawned cubes
var spawn_timer: float = 0.0  # Timer for spawning
var next_spawn_time: float = 1.0  # Initial spawn time target (1 second)

# Sound related variables
@onready var wood_sound: AudioStreamPlayer3D = $AudioStreamPlayer3D
var wood_stream: AudioStreamGeneratorPlayback
var wood_generator: AudioStreamGenerator
var sound_ready = false

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _built: bool = false

func _ready() -> void:
	_read_dna_meta()

	if not base_cube:
		push_error("Base cube not found!")
		return

	print("Starting cube spawner initialization")
	base_cube.visible = false  # Hide the template

	# The hidden template is still a physics body, and on the capture bench there
	# is no floor to catch it. Freezing it keeps the measured box the same at
	# 0.35 s (framing pass) and 1.1 s (shutter). Off in every shipped placement.
	if _truthy(freeze_arrivals) and base_cube is RigidBody3D:
		(base_cube as RigidBody3D).freeze = true

	if spawn_seed != 0:
		_rng.seed = spawn_seed

	# Create and synthesize the wood sound
	create_wood_sound()

	# Bench only: initial_population ships at 0, so this returns immediately.
	_prefill()
	_built = true

## GridInteractablesComponent stamps `config_*` metadata on the ROOT before
## add_child, so this runs ahead of the build. An unknown word keeps the default:
## an axis must never be able to blank an artifact by typo.
func _read_dna_meta() -> void:
	if has_meta("config_dispersal"):
		var d_in: String = str(get_meta("config_dispersal")).strip_edges().to_lower()
		dispersal = d_in if DISPERSALS.has(d_in) else dispersal
	if has_meta("config_capacity"):
		capacity = maxi(1, int(str(get_meta("config_capacity"))))
	if has_meta("config_spread"):
		spread = maxf(0.0, float(str(get_meta("config_spread"))))
	if has_meta("config_spawn_seed"):
		spawn_seed = int(str(get_meta("config_spawn_seed")))
	if has_meta("config_initial_population"):
		initial_population = int(str(get_meta("config_initial_population")))
	if has_meta("config_freeze_arrivals"):
		freeze_arrivals = get_meta("config_freeze_arrivals")

func _truthy(v) -> bool:
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	return str(v).strip_edges().to_lower() in ["1", "true", "yes", "on"]

## One draw. spawn_seed = 0 is the shipped path: the global RNG, over the same
## ranges, in the same order. randf_range(0.0, 1.0) consumes the stream exactly
## as the shipped randf() did, so no existing placement can tell the difference.
func _rf(a: float, b: float) -> float:
	if spawn_seed != 0:
		return _rng.randf_range(a, b)
	return randf_range(a, b)

func _ri(n: int) -> int:
	if n <= 0:
		return 0
	if spawn_seed != 0:
		return _rng.randi() % n
	return randi() % n

## Where an arriving cube enters. `spigot` returns spawn_position without taking
## a single draw, which is the shipped build to the byte.
func _arrival_position(slot: int) -> Vector3:
	match dispersal:
		"random":
			# Complete spatial randomness: independent uniform draws in the plane.
			return spawn_position + Vector3(_rf(-spread, spread), 0.0, _rf(-spread, spread))
		"clumped":
			# A Poisson cluster: fixed centres, random membership, tight jitter.
			var centre: Vector3 = CLUMP_CENTRES[_ri(CLUMP_CENTRES.size())]
			centre *= spread
			var jitter: float = spread * 0.16
			return spawn_position + centre + Vector3(_rf(-jitter, jitter), 0.0, _rf(-jitter, jitter))
		"even":
			# Over-dispersed: a lattice slot per arrival, no draw at all. Every
			# cube is as far from its neighbours as the field allows — the
			# opposite claim to `random`, and the one a territorial population
			# makes.
			var side: int = int(ceil(sqrt(float(maxi(1, capacity)))))
			if side < 2:
				return spawn_position
			var step: float = (2.0 * spread) / float(side - 1)
			var col: int = slot % side
			var row: int = int(slot / side) % side
			return spawn_position + Vector3(
				-spread + float(col) * step,
				0.0,
				-spread + float(row) * step)
		_:
			# spigot — the shipped single point.
			return spawn_position

## Bench helper. Idempotent: tops the population up to what initial_population
## asks for and never removes anything.
func _prefill() -> void:
	if initial_population == 0:
		return
	var want: int = capacity if initial_population < 0 else mini(initial_population, capacity)
	while spawned_cubes.size() < want:
		spawn_cube()

func create_wood_sound() -> void:
	# Create the generator stream
	wood_generator = AudioStreamGenerator.new()
	wood_generator.mix_rate = 44100  # CD quality
	wood_generator.buffer_length = 0.2  # 200ms buffer

	# Set the stream on the existing AudioStreamPlayer3D
	wood_sound.stream = wood_generator
	wood_sound.unit_size = 3.0
	wood_sound.max_distance = 10.0

	# Play the sound first to initialize the playback system
	wood_sound.play()

	# Wait a frame to ensure the playback is initialized
	await get_tree().process_frame

	# Now get the playback to fill with data
	wood_stream = wood_sound.get_stream_playback()

	# Check if we successfully got a playback
	if wood_stream:
		# Generate a wooden knock sound
		synthesize_wood_knock()
	else:
		push_error("Failed to get stream playback")

func synthesize_wood_knock() -> void:
	# Fill the buffer with a synthesized wooden knock sound
	var buffer_size = wood_stream.get_frames_available()

	# Parameters for wood knock sound
	var amplitude = 0.5
	var decay_rate = 15.0  # Higher value means faster decay
	var main_freq = 800.0  # Main resonant frequency
	var second_freq = 1200.0  # Secondary resonant frequency
	var noise_factor = 0.15  # Amount of noise to add

	# Fill the buffer with the synthesized sound
	for i in range(buffer_size):
		var time = float(i) / wood_generator.mix_rate

		# Exponential decay envelope
		var envelope = amplitude * exp(-decay_rate * time)

		# Main resonant frequency
		var main_wave = sin(TAU * main_freq * time)

		# Secondary frequency
		var second_wave = sin(TAU * second_freq * time)

		# Noise component (simulates wood texture)
		var noise = randf_range(-1.0, 1.0) * noise_factor

		# Combine components
		var sample = envelope * (main_wave * 0.6 + second_wave * 0.3 + noise)

		# Apply sample to both channels
		wood_stream.push_frame(Vector2(sample, sample))
	sound_ready = true

func play_wood_sound(at_position: Vector3) -> void:
	if sound_ready:
		# Instead of creating a new AudioStreamPlayer, let's reuse the existing one
		# This avoids potential initialization issues with the audio stream playback

		# Position the sound
		wood_sound.global_position = at_position

		# Random variations for more natural sound
		wood_sound.pitch_scale = randf_range(0.85, 1.15)

		# Generate a new wood knock sound
		if wood_stream:
			# Parameters with slight random variations
			var amplitude = randf_range(0.4, 0.6)
			var decay_rate = randf_range(14.0, 16.0)
			var main_freq = randf_range(750.0, 850.0)
			var second_freq = randf_range(1150.0, 1250.0)
			var noise_factor = randf_range(0.1, 0.2)

			# Fill the buffer with a synthesized wooden knock sound
			var buffer_size = wood_stream.get_frames_available()

			# Fill the buffer with the synthesized sound
			for i in range(buffer_size):
				var time = float(i) / wood_generator.mix_rate
				var envelope = amplitude * exp(-decay_rate * time)
				var main_wave = sin(TAU * main_freq * time)
				var second_wave = sin(TAU * second_freq * time)
				var noise = randf_range(-1.0, 1.0) * noise_factor
				var sample = envelope * (main_wave * 0.6 + second_wave * 0.3 + noise)
				wood_stream.push_frame(Vector2(sample, sample))

			# Play the sound
			if not wood_sound.playing:
				wood_sound.play()
		else:
			push_warning("Wood stream not available")

			# Try to reinitialize the sound
			create_wood_sound()

func _process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= next_spawn_time:  # Spawn at randomized intervals
		spawn_timer = 0.0  # Reset timer

		# Set the next spawn time to be 1-2 seconds
		next_spawn_time = 0.3 + _rf(0.0, 1.0)  # 0.3 + random(0,1)

		if spawned_cubes.size() < capacity:
			spawn_cube()  # Spawn a new cube
		else:
			remove_random_cube_and_spawn()  # Remove random cube, then spawn new one

func spawn_cube() -> void:
	var total_size = cube_size + gutter
	var new_cube = base_cube.duplicate()
	new_cube.position = _arrival_position(spawned_cubes.size())
	new_cube.visible = true
	add_child(new_cube)
	# Bench only. Off in every shipped placement, where the arrivals fall and
	# pile exactly as they always did.
	if _truthy(freeze_arrivals) and new_cube is RigidBody3D:
		(new_cube as RigidBody3D).freeze = true
	if get_tree() and get_tree().edited_scene_root:
		new_cube.owner = get_tree().edited_scene_root
	spawned_cubes.append(new_cube)
	#print("Spawned cube at:", new_cube.position)

	# Play wood sound at the spawned cube position
	play_wood_sound(new_cube.position)

func remove_random_cube_and_spawn() -> void:
	if spawned_cubes.size() > 0:
		# Remove a random cube
		var random_index = _ri(spawned_cubes.size())
		var cube_to_remove = spawned_cubes[random_index]
		var removed_position = cube_to_remove.position
		cube_to_remove.queue_free()
		spawned_cubes.remove_at(random_index)
		#print("Removed cube at index ", random_index)

		# Spawn a new cube in the same spot
		spawn_cube()

## Only ever called when `capacity` is LOWERED through a config. The shipped
## capacity is never exceeded, so this cannot fire on an untouched placement.
func _enforce_capacity() -> void:
	while spawned_cubes.size() > capacity:
		var idx: int = _ri(spawned_cubes.size())
		var doomed = spawned_cubes[idx]
		if is_instance_valid(doomed):
			doomed.queue_free()
		spawned_cubes.remove_at(idx)

func exit_tree() -> void:
	# Clean up all spawned cubes when the node is removed
	for cube in spawned_cubes:
		if is_instance_valid(cube):
			cube.queue_free()
	spawned_cubes.clear()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Grid hook. The body was `pass`, so nothing this artifact knows was reachable
## from a map token.
##
## GATED BY DATA, AND IT NEVER TEARS ANYTHING DOWN. A config carrying none of
## these keys returns having touched nothing. A dispersal change is deliberately
## NOT retroactive — the cubes already standing keep the places the old law gave
## them and only later arrivals follow the new one — so no config call can blank
## or re-roll a live placement. The one destructive path, _enforce_capacity, runs
## only when capacity was actually lowered.
func apply_grid_config(config: Dictionary) -> void:
	var before_capacity: int = capacity
	var before_population: int = initial_population

	if config.has("dispersal"):
		var d_in: String = str(config["dispersal"]).strip_edges().to_lower()
		if DISPERSALS.has(d_in):
			dispersal = d_in
	if config.has("capacity"):
		capacity = maxi(1, int(str(config["capacity"])))
	if config.has("spread"):
		spread = maxf(0.0, float(str(config["spread"])))
	if config.has("spawn_seed"):
		spawn_seed = int(str(config["spawn_seed"]))
		if spawn_seed != 0:
			_rng.seed = spawn_seed
	if config.has("initial_population"):
		initial_population = int(str(config["initial_population"]))
	if config.has("freeze_arrivals"):
		freeze_arrivals = config["freeze_arrivals"]

	if not _built:
		return
	if capacity < before_capacity:
		_enforce_capacity()
	if initial_population != before_population:
		_prefill()
