# RandomWalk128.gd
# Random walk algorithm for 128x128 fine-grained grid using cube_scene.tscn
# Creates an 8x8 meter area with tiny cubes
#
# @identity
# essence: p_{n+1} = p_n + uniform(N,E,S,W) — a lattice walk that raises the floor wherever it lands, so height is a visit count
# desire: stand on a plain and watch a mountain range assemble itself out of nothing but four equally likely choices
# critical_parameter: residue — what the field KEEPS of the walk (head | tail | path | envelope | ensemble); walk_seed pins which walk you get
# triggers: step_timer fires ~60x a second, _step_walk runs steps_per_frame lattice steps and raises a cube at each landing
# emerges: the mound is a diffusion profile — tall at the origin, thinning outward, its edge growing like sqrt(N) and never like N
# needs: cube_scene.tscn [has], a 10x10 m clear floor [has]
# relationships: shares the `residue` ladder word for word with [[random_walk_leash]] — the same walk, one you stand on and one you hold
# truth: A random walk has no memory, but the ground it walked on does. Everything you can see of chance is something that was kept.

class_name RandomWalk128Algorithm
extends Node3D

# Grid configuration
const GRID_SIZE = 32  # 128x128 grid
const GRID_AREA_SIZE = 10.0  # 8x8 meters
const CUBE_SIZE = GRID_AREA_SIZE / GRID_SIZE  # 0.0625m = 6.25cm per cube
const CUBE_SCALE = CUBE_SIZE  # Scale factor for cube_scene.tscn
const RAISE_AMOUNT = CUBE_SIZE * 0.1  # Half cube height

# Cube scene reference
const CUBE_SCENE_PATH = "res://commons/primitives/cubes/cube_scene.tscn"
var cube_scene_resource: PackedScene

# Grid storage
var grid: Array[Array] = []  # 2D array to track cube heights
var cube_instances: Array[Array] = []  # Store actual cube nodes
var walker_position: Vector2i = Vector2i(GRID_SIZE / 2, GRID_SIZE / 2)  # Start at center

# Algorithm settings
@export var steps_per_frame: int = 10
@export var total_steps: int = 10000
@export var auto_start: bool = true
@export var show_walker: bool = true

# Audio settings
@export var enable_audio: bool = true
@export var base_pitch: float = 1.0
@export var pitch_height_scale: float = 0.1

# ─────────────────────────────────────────────────────────────────────────────
# DNA PROMOTION (2026-08-02). THE RANDOM-WALK GROUP: this artifact and
# random_walk_leash, the same process at two scales — one walk you stand on, one
# walk you hold. They take the same axis word, the way prng_crank_machine and
# coin_toss share `disclosure`.
#
# Randomness is the one subject on this curriculum you cannot photograph. A
# distribution has no picture; only its LEAVINGS do. So the axis is not what the
# walk is made of but what the field KEEPS of it:
#
#   residue   how much of the walk's own history the ground leaves standing
#
#     head  <  tail  <  path  <  envelope  <  ensemble
#
#   head      the walker, over a dead flat carpet. Every cell it has touched
#             still has its cube — the walk has been HERE — but not one of them
#             is raised, so nothing tells you how often or how long ago. One
#             marker floats over a plain. The claim: a random process is a
#             LOCATION, and this is what every rand() call in every program
#             actually looks like from outside.
#   tail      + a window. The last TAIL_WINDOW landings are raised, in rank
#             order, so the field carries a single wandering ridge that climbs
#             to a peak under the walker and sinks to nothing behind it. You can
#             see the walk MOVING and you cannot see where it started.
#   path      + the archive. Every landing raises its cell and nothing ever
#             sinks, so height is a visit count and the field is a diffusion
#             profile: a mound at the origin thinning outward. Now the walk is
#             an OBJECT with a shape, and the shape is the distribution.
#             THIS IS THE LEGACY LINEAGE, byte for byte.
#   envelope  + the bound. A rail around the smallest rectangle the walk has
#             stayed inside. The mound alone says "it spread"; the rail says
#             HOW FAR, and that the far edge is creeping outward like sqrt(N)
#             and not like N is the whole content of the lesson.
#   ensemble  + the counterfactual. Four more walks from the same origin under
#             the same law, laid flat and pale around the bright one. This mound
#             stops being THE walk and becomes ONE walk; the halo is the rest of
#             the distribution. Nothing in it happened — that is the point.
#
# WHAT IS DELIBERATELY NOT THE AXIS. steps_per_frame is the obvious knob and it
# is a RATE — invisible to a still, and info_board already burned a whole sweep
# on five duration exports and published six identical tiles. total_steps is
# invisible for a different reason: the sweep photographs at a fixed wall-clock
# moment, so a walk allowed 10000 steps and a walk allowed 40000 both render at
# whatever step the clock caught, and the axis would be measuring frame timing.
# Both stay plain exports.
#
# WHAT IS FORECLOSED. There is no rung showing nothing: `head` still shows the
# walker and still shows which cells were touched, because a field that reports
# nothing is not a quieter field, it is an empty one — and an empty frame would
# also collapse the capture's bounding box and fake a bite out of pure zoom. So
# this axis has no `none`, on purpose.
#
# NOT TOUCHED, AND NOT NEGOTIABLE: the walk itself. Four directions, uniformly
# chosen, clamped at the boundary; grid[x][z] accumulates RAISE_AMOUNT on every
# landing at every rung, and walk_step_complete still reports that accumulated
# number. grid[][] is the MATHEMATICS and it is curriculum. This axis changes
# only the y a cube is DRAWN at, which is staging.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — how much of the walk's history this field leaves standing. One
## ordered ladder, monotone: each rung shows everything the rung below shows,
## plus one more kind of leaving. `path` is the legacy default.
@export_enum("head", "tail", "path", "envelope", "ensemble") var residue: String = "path"

## The allow-list, in ladder order — the same five words the @export_enum above
## declares, same spelling, same sequence.
const RESIDUES: PackedStringArray = ["head", "tail", "path", "envelope", "ensemble"]

## The ladder, as rank. ADOPTED WORD FOR WORD from random_walk_leash, which is
## the group's canonical table (see its residue_name()). It is duplicated rather
## than preloaded because that file preloads two godot-xr-tools scenes, and a
## parse-time dependency from here would drag the whole XR addon into an artifact
## with no grabbable in it. Both copies say so; if one changes, change both.
const RESIDUE_RUNGS := {
	"head": 0,      # the walker
	"tail": 1,      # + a window
	"path": 2,      # + the whole record   ← legacy default
	"envelope": 3,  # + the bound it obeyed
	"ensemble": 4,  # + the walks it did not take
}

# ── Determinism: the seed, and the bench-only prebuild ───────────────────────
# NO RNG IN THE RENDER PATH. A random walk is nothing but accumulated draws, so
# an evidence sweep of an UNSEEDED walk renders five different walks and reports
# the difference between them as the axis — a confident, entirely false bite
# that nothing downstream can catch. Worse here than anywhere: this walk also
# grows with wall-clock time, so even a seeded walk photographed at t=1.1 s is
# at whatever step the frame rate happened to reach. Both holes need closing,
# and both exports default to "behave exactly as before".

## Pins the global stream this artifact draws from. -1 = do not touch it, i.e.
## today: a fresh unpredictable landscape every launch, which is correct in a
## room and useless on a bench. Any value >= 0 calls seed() once at the very top
## of _ready(), before the audio burst and before the first step.
@export var walk_seed: int = -1

## Bench-only. Runs this many steps INSTANTLY during _ready, before the live
## timer starts, so the field a still photographs is a fixed number of steps
## rather than however many the frame rate managed. Pair it with auto_start
## false and the picture is fully determined by walk_seed. 0 = today, and 0 is
## what every room ships.
@export var preroll_steps: int = 0

# State tracking
var current_step: int = 0
var is_running: bool = false
var walker_cube: Node3D
var step_timer: Timer
var audio_player: AudioStreamPlayer3D

# ── residue bookkeeping ──────────────────────────────────────────────────────
# All of it is recorded at EVERY rung. It costs one array append and four
# integer compares per step, it changes no output, and recording unconditionally
# is what lets a late apply_grid_config move to `tail` or `envelope` and have a
# history to draw instead of a blank one.

## residue:tail — the landing window, oldest first. A cell may appear more than
## once; _refresh_tail walks forward so the most recent rank wins.
var _recent: Array[Vector2i] = []
## Cells that dropped out of the window this batch and must be put back down.
var _tail_faded: Array[Vector2i] = []
## residue:tail — how many landings the ridge remembers.
const TAIL_WINDOW: int = 140
## residue:tail — the height of the ridge under the walker. RAISE_AMOUNT x 16 so
## the crest reads at the same order as the legacy mound rather than as a scuff.
const TAIL_PEAK: float = RAISE_AMOUNT * 16.0

## residue:envelope — the smallest grid rectangle the walk has stayed inside.
var _ex_min: Vector2i = Vector2i(GRID_SIZE, GRID_SIZE)
var _ex_max: Vector2i = Vector2i(-1, -1)
var _ex_drawn: Rect2i = Rect2i(0, 0, -1, -1)   # what the rail currently shows

## residue:envelope — rail dimensions, in metres.
const RAIL_HEIGHT: float = 0.5
const RAIL_THICK: float = 0.10
## residue:ensemble — how many counterfactual walks lie around the real one.
const GHOST_WALKS: int = 4

## Everything the residue rungs build, freed as a set when the rung moves. Kept
## apart from the cubes and the walker, which no rung may destroy.
var _residue_nodes: Array[Node] = []
## True once _ready has finished. apply_grid_config arriving before this is a
## value change with no geometry to answer it — _ready will use it.
var _built: bool = false

# Signals
signal walk_step_complete(position: Vector2i, height: float)
signal walk_finished(total_steps: int)

func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child, so the meta
	# read must happen here, before any geometry exists — apply_grid_config()
	# arrives call_deferred, i.e. after this, and is a re-read rather than the read.
	_read_meta_overrides()
	# THE SEED, BEFORE ANY OTHER LINE. Nothing above this point draws. Pinning
	# here pins the audio burst's 100 randf() calls AND every step that follows,
	# in that order, which is the order they already ran in. At the default of -1
	# the branch is not taken and not one draw is consumed, so the legacy stream
	# is untouched to the bit.
	if walk_seed >= 0:
		seed(walk_seed)
	print("RandomWalk128: Initializing 128x128 random walk system")
	print("Grid size: %dx%d cubes" % [GRID_SIZE, GRID_SIZE])
	print("Area size: %.1fx%.1f meters" % [GRID_AREA_SIZE, GRID_AREA_SIZE])
	print("Cube size: %.4f meters (%.1f cm)" % [CUBE_SIZE, CUBE_SIZE * 100])
	
	# Load cube scene
	cube_scene_resource = load(CUBE_SCENE_PATH)
	if not cube_scene_resource:
		push_error("RandomWalk128: Could not load cube scene from: " + CUBE_SCENE_PATH)
		return
	else:
		print("RandomWalk128: Successfully loaded cube scene")
	
	# Initialize grid
	_initialize_grid()
	
	# Setup audio
	if enable_audio:
		_setup_audio()
	
	# Setup timer for smooth animation
	step_timer = Timer.new()
	step_timer.wait_time = 0.016  # ~60 FPS
	step_timer.timeout.connect(_step_walk)
	add_child(step_timer)
	
	# Create walker indicator
	if show_walker:
		_create_walker_indicator()
	
	if auto_start:
		print("RandomWalk128: Auto-start enabled, starting walk...")
		call_deferred("start_walk")
	else:
		print("RandomWalk128: Auto-start disabled. Use Space to start manually.")

	# APPENDED LAST, all three, so every line above runs in its legacy order and
	# consumes its legacy draws. At the shipped defaults (preroll_steps 0,
	# residue "path") the first call does nothing, the second finds nothing to
	# refresh and the third builds nothing.
	if preroll_steps > 0:
		_preroll(preroll_steps)
	_refresh_residue()
	_build_residue()
	_built = true

func _setup_audio() -> void:
	"""Setup procedural audio for steps"""
	audio_player = AudioStreamPlayer3D.new()
	audio_player.unit_size = 5.0
	audio_player.max_distance = 20.0
	audio_player.stream = _generate_step_sound()
	add_child(audio_player)

func _generate_step_sound() -> AudioStreamWAV:
	"""Generate a short 'tick' sound"""
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	
	var duration = 0.05 # Very short tick
	var sample_count = int(44100 * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in sample_count:
		var t = float(i) / 44100.0
		var envelope = exp(-200.0 * t) # Sharp decay
		var wave = sin(TAU * 880.0 * t) * envelope
		if i < 100: wave = (randf() * 2.0 - 1.0) * envelope # Initial noise burst
		
		var sample_int = int(clamp(wave, -1.0, 1.0) * 32767.0)
		data.encode_s16(i*2, sample_int)
		
	stream.data = data
	return stream

func _initialize_grid() -> void:
	"""Initialize the 128x128 grid arrays"""
	print("RandomWalk128: Initializing grid arrays...")
	
	grid.resize(GRID_SIZE)
	cube_instances.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		grid[x] = []
		grid[x].resize(GRID_SIZE)
		cube_instances[x] = []
		cube_instances[x].resize(GRID_SIZE)
		
		for z in range(GRID_SIZE):
			grid[x][z] = 0.0  # Initial height
			cube_instances[x][z] = null  # No cube initially
	
	print("RandomWalk128: Grid initialized (%d x %d)" % [GRID_SIZE, GRID_SIZE])

func _create_walker_indicator() -> void:
	"""Create a visual indicator for the walker position"""
	walker_cube = cube_scene_resource.instantiate()
	walker_cube.name = "Walker"
	walker_cube.scale = Vector3.ONE * CUBE_SCALE * 2.0  # Bigger for visibility
	
	add_child(walker_cube)
	_update_walker_position()

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	"""Find MeshInstance3D in node hierarchy"""
	if node is MeshInstance3D:
		return node as MeshInstance3D
	
	for child in node.get_children():
		var mesh = _find_mesh_instance(child)
		if mesh:
			return mesh
	
	return null

func start_walk() -> void:
	"""Start the random walk algorithm"""
	if is_running:
		return
	
	print("RandomWalk128: Starting random walk from center position")
	print("Target steps: %d" % total_steps)
	
	is_running = true
	current_step = 0
	walker_position = Vector2i(GRID_SIZE / 2, GRID_SIZE / 2)  # Center
	_update_walker_position()
	
	step_timer.start()

func stop_walk() -> void:
	"""Stop the random walk"""
	is_running = false
	step_timer.stop()
	print("RandomWalk128: Walk stopped at step %d" % current_step)

func _step_walk() -> void:
	"""Execute multiple walk steps per frame for performance"""
	if not is_running:
		return
	
	var last_height = 0.0
	
	for i in range(steps_per_frame):
		if current_step >= total_steps:
			_finish_walk()
			return
		
		last_height = _execute_single_step()
		current_step += 1
	
	# Update walker position after batch
	_update_walker_position()

	# ONCE PER BATCH, not once per step. residue:tail restages up to TAIL_WINDOW
	# cubes and residue:envelope may redraw four rails — a few hundred transform
	# writes a frame, against the tens of thousands doing it per step would cost.
	# At residue:path (the default) this returns on its first line.
	_refresh_residue()

	# Play audio once per frame, pitch modulated by height
	if enable_audio and audio_player and not audio_player.playing:
		var pitch = base_pitch + (last_height * pitch_height_scale)
		audio_player.pitch_scale = clamp(pitch, 0.5, 3.0)
		audio_player.play()

func _execute_single_step() -> float:
	"""Execute a single random walk step. Returns new height."""
	# Choose random direction (4-directional: N, E, S, W)
	var directions = [
		Vector2i(0, 1),   # North
		Vector2i(1, 0),   # East
		Vector2i(0, -1),  # South
		Vector2i(-1, 0)   # West
	]
	
	var random_direction = directions[randi() % directions.size()]
	var new_position = walker_position + random_direction
	
	# Clamp to grid boundaries
	new_position.x = clamp(new_position.x, 0, GRID_SIZE - 1)
	new_position.y = clamp(new_position.y, 0, GRID_SIZE - 1)
	
	walker_position = new_position
	
	# Raise cube at walker position
	_raise_cube_at(walker_position.x, walker_position.y)
	
	# Emit step signal
	var height = grid[walker_position.x][walker_position.y]
	walk_step_complete.emit(walker_position, height)
	
	return height

func _raise_cube_at(x: int, z: int) -> void:
	"""Raise the cube at the specified grid position"""
	# Increase height in grid. THE MATHEMATICS, at every rung — grid[][] is the
	# visit count the curriculum is about and no residue value touches it. Only
	# the y a cube is DRAWN at is staged (see _cube_y).
	grid[x][z] += RAISE_AMOUNT

	# Create or update physical cube
	if cube_instances[x][z] == null:
		_create_cube_at(x, z)
	else:
		_update_cube_height(x, z)

	# residue bookkeeping, recorded at EVERY rung so a late rung change has a
	# history to draw. No RNG here and no geometry: an append and four compares.
	_recent.append(Vector2i(x, z))
	if _recent.size() > TAIL_WINDOW:
		# Only residue:tail ever consumes the faded list, and it is the only rung
		# that has to put a cell back DOWN. Collecting it at the other rungs would
		# grow an array to total_steps for nothing — and a late switch to tail
		# flattens every cube through apply_grid_config anyway, so nothing is lost.
		var tail_rung: bool = _rung() == 1
		while _recent.size() > TAIL_WINDOW:
			var gone: Vector2i = _recent.pop_front()
			if tail_rung:
				_tail_faded.append(gone)
	if x < _ex_min.x: _ex_min.x = x
	if z < _ex_min.y: _ex_min.y = z
	if x > _ex_max.x: _ex_max.x = x
	if z > _ex_max.y: _ex_max.y = z

func _create_cube_at(x: int, z: int) -> void:
	"""Create a new cube at the specified grid position"""
	var cube = cube_scene_resource.instantiate()
	cube.name = "Cube_%d_%d" % [x, z]
	
	# Scale down the cube
	cube.scale = Vector3.ONE * CUBE_SCALE
	
	# Position the cube
	var world_pos = _grid_to_world_position(x, z)
	cube.position = Vector3(world_pos.x, _cube_y(x, z), world_pos.y)

	# Store reference
	cube_instances[x][z] = cube
	add_child(cube)

func _update_cube_height(x: int, z: int) -> void:
	"""Update the height of an existing cube"""
	var cube = cube_instances[x][z]
	if cube:
		var world_pos = _grid_to_world_position(x, z)
		cube.position = Vector3(world_pos.x, _cube_y(x, z), world_pos.y)

func _grid_to_world_position(grid_x: int, grid_z: int) -> Vector2:
	"""Convert grid coordinates to world position"""
	var offset = -GRID_AREA_SIZE / 2.0 + CUBE_SIZE / 2.0
	var world_x = offset + grid_x * CUBE_SIZE
	var world_z = offset + grid_z * CUBE_SIZE
	return Vector2(world_x, world_z)

func _update_walker_position() -> void:
	"""Update the visual walker indicator position"""
	if walker_cube:
		var world_pos = _grid_to_world_position(walker_position.x, walker_position.y)
		# At residue:path and above this is grid[x][z] + CUBE_SIZE * 2.0, byte for
		# byte the legacy line. Below it the walker rides the STAGED ground rather
		# than the accumulated one, so it does not float over a flat carpet.
		var walker_height = _walker_y()
		walker_cube.position = Vector3(world_pos.x, walker_height, world_pos.y)
		# Move audio source to walker
		if audio_player:
			audio_player.position = walker_cube.position

func _finish_walk() -> void:
	"""Complete the random walk"""
	is_running = false
	step_timer.stop()
	
	print("RandomWalk128: Walk completed!")
	print("Total steps: %d" % current_step)
	print("Final position: %s" % walker_position)
	print("Total cubes created: %d" % _count_created_cubes())
	
	walk_finished.emit(current_step)

func _count_created_cubes() -> int:
	"""Count how many cubes were actually created"""
	var count = 0
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			if cube_instances[x][z] != null:
				count += 1
	return count

# === PUBLIC API ===

func restart_walk() -> void:
	"""Restart the walk from the beginning"""
	stop_walk()
	_clear_all_cubes()
	# _clear_all_cubes takes the residue nodes down with the record they describe;
	# the counterfactuals are rebuilt from their own private seed, so they come
	# back identical. Returns immediately below residue:envelope.
	_build_residue()
	current_step = 0
	walker_position = Vector2i(GRID_SIZE / 2, GRID_SIZE / 2)
	start_walk()

func _clear_all_cubes() -> void:
	"""Clear all created cubes"""
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			if cube_instances[x][z] != null:
				cube_instances[x][z].queue_free()
				cube_instances[x][z] = null
			grid[x][z] = 0.0
	# The residue record is a record of those cubes; it dies with them, or the
	# next _refresh_tail would restage cells whose nodes are gone.
	_recent.clear()
	_tail_faded.clear()
	_ex_min = Vector2i(GRID_SIZE, GRID_SIZE)
	_ex_max = Vector2i(-1, -1)
	_ex_drawn = Rect2i(0, 0, -1, -1)
	_clear_residue()

func set_walk_speed(new_steps_per_frame: int) -> void:
	"""Change the walking speed"""
	steps_per_frame = clamp(new_steps_per_frame, 1, 100)
	print("RandomWalk128: Speed set to %d steps per frame" % steps_per_frame)

func get_walk_info() -> Dictionary:
	"""Get current walk information"""
	return {
		"grid_size": GRID_SIZE,
		"cube_size": CUBE_SIZE,
		"current_step": current_step,
		"total_steps": total_steps,
		"walker_position": walker_position,
		"cubes_created": _count_created_cubes(),
		"is_running": is_running,
		"grid_area_meters": GRID_AREA_SIZE
	}

func print_walk_status() -> void:
	"""Print current walk status"""
	var info = get_walk_info()
	print("=== RANDOM WALK 128x128 STATUS ===")
	print("Grid: %dx%d (%.1fm x %.1fm)" % [info.grid_size, info.grid_size, info.grid_area_meters, info.grid_area_meters])
	print("Cube size: %.4fm (%.1fcm)" % [info.cube_size, info.cube_size * 100])
	print("Progress: %d / %d steps" % [info.current_step, info.total_steps])
	print("Walker at: %s" % info.walker_position)
	print("Cubes created: %d" % info.cubes_created)
	print("Running: %s" % info.is_running)
	print("=================================")

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═════════════════════════════════════════════════════════════════════════════
# THE RESIDUE LADDER
# ═════════════════════════════════════════════════════════════════════════════

## The house-pattern reader, generic over an allow-list. Same rule as
## random_walk_leash.residue_name(): lower, strip, keep the fallback on anything
## unrecognised. An unreadable word resolves to the LEGACY rung rather than to
## silence — a typo must not quietly flatten a field rooms expect to be a mound.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	if allowed.has(v):
		return v
	if v != "":
		push_warning("random_walk_128: unknown value '%s' — keeping '%s'" % [v, fallback])
	return fallback


## Rank of the current rung, 0..4. Every gate in this file is `_rung() >= n`.
func _rung() -> int:
	return int(RESIDUE_RUNGS.get(residue, 2))


## The CENTRE y a cube is drawn at. The only place the axis touches geometry, and
## the reason grid[][] never has to lie about the visit count.
##
##   residue:path and above  grid[x][z] / 2.0 — the legacy expression, byte for
##                           byte, so the default field is the default field.
##   residue:tail            0.0 here; _refresh_tail sets the window's real
##                           heights once per batch, in rank order, because a
##                           cell's height at this rung depends on how RECENT it
##                           is and that is not knowable one cell at a time.
##   residue:head            0.0, always. The carpet lies flat.
func _cube_y(x: int, z: int) -> float:
	if _rung() >= 2:
		return float(grid[x][z]) / 2.0
	return 0.0


## The walker's y. Legacy expression at residue:path and above; at head/tail the
## walker rides the STAGED ground, so it sits on the ridge instead of floating
## over a flat carpet at the height of a mound that is not being drawn.
func _walker_y() -> float:
	var gx: int = walker_position.x
	var gz: int = walker_position.y
	if _rung() >= 2:
		return float(grid[gx][gz]) + CUBE_SIZE * 2.0
	return _cube_y(gx, gz) * 2.0 + CUBE_SIZE * 2.0


## BENCH ONLY (preroll_steps == 0 in every room, so this returns having done
## nothing). Runs the walk forward instantly before the first frame is drawn.
##
## This exists because the sweep photographs at a fixed WALL-CLOCK moment and
## this walk grows with time: without it, five variants are five different step
## counts and the sheet measures the frame rate. It calls the same
## _execute_single_step the timer calls — same law, same draws, same order —
## so a preroll of N followed by nothing is exactly the walk the timer would
## have produced after N steps.
func _preroll(steps: int) -> void:
	for _i in range(steps):
		if current_step >= total_steps:
			break
		_execute_single_step()
		current_step += 1
	_update_walker_position()


## Restage whatever the current rung has to restage. Called once per batch and
## once at the end of the preroll. Returns on its first line at head, path,
## ensemble's own ghosts being built elsewhere — only tail and the rail move.
func _refresh_residue() -> void:
	var r: int = _rung()
	if r == 1:
		_refresh_tail()
	if r >= 3:
		_refresh_rail()


## residue:tail — put the cells that fell out of the window back down, then raise
## the window in rank order so the ridge climbs to a crest under the walker. A
## cell can appear twice in _recent; iterating forward means its most recent rank
## wins, which is the correct read (a cell revisited is recent).
func _refresh_tail() -> void:
	for cell in _tail_faded:
		_place_cube_at_height(cell.x, cell.y, 0.0)
	_tail_faded.clear()
	var n: int = _recent.size()
	if n <= 0:
		return
	for i in range(n):
		var c: Vector2i = _recent[i]
		var h: float = TAIL_PEAK * float(i + 1) / float(n)
		_place_cube_at_height(c.x, c.y, h)


## Move one already-created cube to a staged height. Never creates, never touches
## grid[][] — the visit count is not this function's business.
func _place_cube_at_height(x: int, z: int, height: float) -> void:
	var cube = cube_instances[x][z]
	if cube == null:
		return
	var world_pos = _grid_to_world_position(x, z)
	cube.position = Vector3(world_pos.x, height / 2.0, world_pos.y)


## residue:envelope — the rail around the smallest rectangle the walk has stayed
## inside. Rebuilt only when the rectangle actually grows, which after the first
## few hundred steps is rarely: the extent creeps like sqrt(N), and that it does
## is the reason this rung exists.
func _refresh_rail() -> void:
	if _ex_max.x < 0:
		return
	var want := Rect2i(_ex_min, _ex_max - _ex_min)
	if want == _ex_drawn:
		return
	_ex_drawn = want
	_drop_node_named("WalkEnvelope")

	var lo: Vector2 = _grid_to_world_position(_ex_min.x, _ex_min.y)
	var hi: Vector2 = _grid_to_world_position(_ex_max.x, _ex_max.y)
	var x0: float = lo.x - CUBE_SIZE * 0.5
	var x1: float = hi.x + CUBE_SIZE * 0.5
	var z0: float = lo.y - CUBE_SIZE * 0.5
	var z1: float = hi.y + CUBE_SIZE * 0.5

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.55, 0.18)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.45, 0.12)
	mat.emission_energy_multiplier = 1.8
	mat.roughness = 0.45

	var rail := Node3D.new()
	rail.name = "WalkEnvelope"
	add_child(rail)
	_residue_nodes.append(rail)

	var span_x: float = x1 - x0
	var span_z: float = z1 - z0
	var sides: Array = [
		[Vector3((x0 + x1) * 0.5, RAIL_HEIGHT * 0.5, z0), Vector3(span_x, RAIL_HEIGHT, RAIL_THICK)],
		[Vector3((x0 + x1) * 0.5, RAIL_HEIGHT * 0.5, z1), Vector3(span_x, RAIL_HEIGHT, RAIL_THICK)],
		[Vector3(x0, RAIL_HEIGHT * 0.5, (z0 + z1) * 0.5), Vector3(RAIL_THICK, RAIL_HEIGHT, span_z)],
		[Vector3(x1, RAIL_HEIGHT * 0.5, (z0 + z1) * 0.5), Vector3(RAIL_THICK, RAIL_HEIGHT, span_z)],
	]
	for si in range(sides.size()):
		var s: Array = sides[si]
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = s[1]
		mi.mesh = bm
		mi.material_override = mat
		mi.position = s[0]
		rail.add_child(mi)


## residue:envelope and up, built once. The rail is handled by _refresh_rail
## because it moves; the ghosts never move, so they are laid down here.
func _build_residue() -> void:
	var r: int = _rung()
	if r < 3:
		return
	_ex_drawn = Rect2i(0, 0, -1, -1)   # force the rail to draw on the next refresh
	_refresh_rail()
	if r >= 4:
		_build_ghosts()


## residue:ensemble — THE COUNTERFACTUAL. Four more lattice walks from the same
## origin under the same law, laid flat and pale as a MultiMesh of thin plates.
## Where the real walk has raised a cube the plate is buried under it; where it
## has not, the plate shows — so what you see is precisely the ground the OTHER
## walks covered and this one missed. The bright mound stops being the walk.
##
## THESE DRAW FROM THEIR OWN RandomNumberGenerator, NOT THE GLOBAL STREAM, and
## that is not tidiness. Every global draw taken here would shift every later
## global draw, so the REAL walk would differ between `ensemble` and every other
## rung and the sweep would be comparing two different walks while calling the
## difference the axis. A private generator makes the ghosts free.
func _build_ghosts() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(walk_seed) * 7919 + 104729     # deterministic, disjoint from global
	var steps: int = maxi(preroll_steps, 3000)
	var dirs: Array = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]

	var holder := Node3D.new()
	holder.name = "WalkEnsemble"
	add_child(holder)
	_residue_nodes.append(holder)

	var plate := BoxMesh.new()
	plate.size = Vector3(CUBE_SIZE * 0.88, 0.02, CUBE_SIZE * 0.88)

	for g in range(GHOST_WALKS):
		var seen: Dictionary = {}
		var p: Vector2i = Vector2i(GRID_SIZE / 2, GRID_SIZE / 2)
		for _i in range(steps):
			p += dirs[rng.randi() % 4]
			p.x = clampi(p.x, 0, GRID_SIZE - 1)
			p.y = clampi(p.y, 0, GRID_SIZE - 1)
			seen[p] = true
		var cells: Array = seen.keys()
		if cells.is_empty():
			continue
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.42, 0.52, 0.72, 0.5)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.22, 0.30, 0.48)
		mat.emission_energy_multiplier = 0.7
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = plate
		mm.instance_count = cells.size()
		for ci in range(cells.size()):
			var c: Vector2i = cells[ci]
			var w: Vector2 = _grid_to_world_position(c.x, c.y)
			mm.set_instance_transform(ci, Transform3D(
				Basis.IDENTITY, Vector3(w.x, 0.010 + 0.004 * float(g), w.y)))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Ghost_%d" % g
		mmi.multimesh = mm
		mmi.material_override = mat
		holder.add_child(mmi)


func _drop_node_named(node_name: String) -> void:
	var keep: Array[Node] = []
	for n in _residue_nodes:
		if is_instance_valid(n) and n.name == node_name:
			remove_child(n)          # leaves the tree synchronously — no double render
			n.queue_free()
		elif is_instance_valid(n):
			keep.append(n)
	_residue_nodes = keep


func _clear_residue() -> void:
	for n in _residue_nodes:
		if is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_residue_nodes.clear()


# ═════════════════════════════════════════════════════════════════════════════
# CONFIG
# ═════════════════════════════════════════════════════════════════════════════

## LATENT BUG PAID (2026-08-02): this was `pass`. Every `#token: value` a map put
## on a random_walk_128 placement was parsed, logged by
## GridInteractablesComponent and stashed as metadata — then silently discarded,
## because nothing on this artifact ever read the metadata back. A registry that
## derives its DNA block from this file would have been declaring a knob that did
## nothing. It reads its metadata now.
##
## THE EARLY RETURNS ARE LOAD-BEARING. curation_station calls
## apply_grid_config({"emissive": false}) on every artifact it curates; that dict
## carries no residue key, and an unconditional restage there would move a
## thousand cubes for nothing. Unchanged rung means touch nothing.
func apply_grid_config(config: Dictionary) -> void:
	var before_residue: String = residue

	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()

	if not _built:
		return                        # nothing built yet; _ready will use these values
	if residue == before_residue:
		return                        # curation_station's {"emissive": false} lands here

	# The staged height of every cube that already exists follows the new rung.
	# grid[][] is not consulted for anything but its own legacy expression inside
	# _cube_y, so no visit count is lost by moving up or down the ladder.
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			if cube_instances[x][z] != null:
				_update_cube_height(x, z)
	_update_walker_position()
	_clear_residue()
	_refresh_residue()
	_build_residue()
	print("[RandomWalk128] Config applied — residue=%s" % residue)


func _read_meta_overrides() -> void:
	if has_meta("config_residue"):
		residue = _pick_axis(str(get_meta("config_residue")), RESIDUES, "path")
	if has_meta("config_walk_seed"):
		walk_seed = int(str(get_meta("config_walk_seed")))
	if has_meta("config_preroll_steps"):
		preroll_steps = int(str(get_meta("config_preroll_steps")))
