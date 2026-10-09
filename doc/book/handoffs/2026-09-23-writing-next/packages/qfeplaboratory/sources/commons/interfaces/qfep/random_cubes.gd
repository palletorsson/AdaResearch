# random_cubes.gd
# QFEP E(S) Term Visualization - Chaotic Cube Arrangement
# Represents high entropy: random positions, rotations, scales
# Visual metaphor for possibility space and freedom from pattern

extends Node3D

class_name QFEPRandomCubes

# @identity
# essence: for i in N: cube drawn inside the region `macrostate` fences off, with size/hue/spin left to `chance`, + drift(random velocity)
# desire: be surrounded by cubes that have forgotten how to form a grid — pure possibility space
# critical_parameter: macrostate — WHICH region the same cubes occupy, and therefore how many ways there are to be this pile
# triggers: regenerate() re-rolls every position, velocity, and color; boundary bouncing keeps each cube inside its OWN region
# emerges: temporary alignments and clusters that the eye reads as structure — meaning projected onto noise
# needs: VR regenerate button [missing], drift speed control [missing]
# relationships: represents E(S) entropy term; contrasts ordered_grid (F term); paired with particle_chaos; borrows `macrostate` from microstate_counter and `chance` from john_cage_tech_noir
# truth: randomness is not the absence of information but the presence of all possible configurations simultaneously

# --- STAGE-2 DNA (promoted 2026-08-04, by hand) -------------------------------
# TWO HARD-CODED DECISIONS THAT WERE ALREADY A PARAMETER SPACE, AND BOTH WORDS
# ARE BORROWED RATHER THAN INVENTED.
#
# 1. `macrostate` — the spawn loop drew every position from one region, the whole
#    box (-r..r, 0..r, -r..r), and called that "high entropy". But entropy is not
#    a property of a pile; it is a count of the ways a pile could have been, and
#    that count only exists once you say WHICH macrostate you are counting. The
#    same twenty cubes crowded into one octant are just as randomly placed and
#    have vastly fewer ways to be. The word, and its four values, are
#    microstate_counter's — the artifact three rooms away whose whole job is to
#    print log10(W) for exactly these four arrangements. Character for character:
#    uniform | corner | layered | spilled, `uniform` being the shipped region.
#    Same question, same substrate (small elements loose in a box), so these two
#    can be COMPARED rather than merely juxtaposed.
#
# 2. `chance` — size, hue and spin were all drawn at once and nothing said so.
#    The values are john_cage_tech_noir's none | hue | size | all, the axis that
#    asks what a piece actually surrenders to the dice. Here the shipped answer
#    is `all`, which is the opposite of that artifact's shipped `none` — the two
#    ends of one borrowed question, which is worth more than a private word.
#    ORIENTATION RIDES WITH `all`. The borrowed list has no value for spin, and
#    forking the list to add one would make the shared word a lie; so `none`,
#    `hue` and `size` all stand their cubes axis-aligned and only `all` tumbles
#    them. Stated here rather than hidden, because it is the one place the
#    borrowed vocabulary does not cover this artifact exactly.
#
# THE FRAME IS PART OF THE ARGUMENT, AND ONLY THE NON-DEFAULT VALUES GET IT.
# The spawn volume is invisible in the shipped artifact, so `corner` without it
# is not "the same cubes confined" but simply "fewer, smaller, over there" —
# which is size wearing a name. A thin wire box of the shipped volume is drawn
# for corner / layered / spilled so the constraint is legible, and NOT drawn for
# uniform, which therefore renders exactly what it always rendered.
# (microstate_counter does the same thing with its amber octant cage, and for
# the same stated reason.)
#
# NOT PROMOTED: drift_speed. It is this file's own declared critical_parameter
# and it is real — at zero, chaos is frozen — but the evidence for a DNA axis is
# one still PNG per value, and a rate photographs identically at every setting.
# info_board was swept across five duration exports and published six identical
# tiles. Rates stay exports.
# ------------------------------------------------------------------------------

## Allow-lists. A typo in a map token falls back to the shipped look rather than
## stranding a placement with an empty region or a blank pile.
const MACROSTATES: PackedStringArray = ["uniform", "corner", "layered", "spilled"]
const CHANCES: PackedStringArray = ["none", "hue", "size", "all"]

## Which region of the spawn volume the cubes occupy. `uniform` is the shipped scatter.
@export_enum("uniform", "corner", "layered", "spilled") var macrostate: String = "uniform"

## What is left to chance. `all` is the shipped build: size, hue and spin all drawn.
@export_enum("none", "hue", "size", "all") var chance: String = "all"

## 0 keeps the shipped behaviour exactly — the global RNG, a new pile every launch.
## Any other value pins the draw so one value of an axis is ONE arrangement rather
## than a fresh object per boot. dna.fixture sets it for the sweep only.
@export var chance_seed: int = 0

## Number of cubes to spawn
@export var cube_count: int = 20

## Spawn radius
@export var spawn_radius: float = 1.0

## Cube size range
@export var size_min: float = 0.05
@export var size_max: float = 0.15

## Animation speed (0 = static)
@export var drift_speed: float = 0.1

## Color variation
@export var base_color: Color = Color(0.9, 0.3, 0.3, 0.8)  # Red - entropy color

# Internal
var _cubes: Array[MeshInstance3D] = []
var _velocities: Array[Vector3] = []
var _angular_velocities: Array[Vector3] = []
var _region_lo: Array[Vector3] = []
var _region_hi: Array[Vector3] = []
var _frame_parts: Array[MeshInstance3D] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _time: float = 0.0
var _built: bool = false

func _ready() -> void:
	_read_dna_meta()
	_spawn_cubes()
	_built = true

## GridInteractablesComponent sets `config_*` metadata on the ROOT before add_child,
## so this runs ahead of the build. An unknown word keeps the default: an axis must
## never be able to blank an artifact by typo.
func _read_dna_meta() -> void:
	if has_meta("config_macrostate"):
		var m_in: String = str(get_meta("config_macrostate")).strip_edges().to_lower()
		macrostate = m_in if MACROSTATES.has(m_in) else macrostate
	if has_meta("config_chance"):
		var c_in: String = str(get_meta("config_chance")).strip_edges().to_lower()
		chance = c_in if CHANCES.has(c_in) else chance
	if has_meta("config_chance_seed"):
		chance_seed = int(str(get_meta("config_chance_seed")))
	if has_meta("config_cube_count"):
		cube_count = maxi(1, int(str(get_meta("config_cube_count"))))

## One draw. chance_seed = 0 is the shipped path: the global RNG, over the same
## ranges, in the same order, so no existing placement can tell the difference —
## the pile was never the same twice to begin with.
func _rf(a: float, b: float) -> float:
	if chance_seed != 0:
		return _rng.randf_range(a, b)
	return randf_range(a, b)

func _spawn_cubes() -> void:
	if chance_seed != 0:
		_rng.seed = chance_seed

	var size_random: bool = chance == "all" or chance == "size"
	var hue_random: bool = chance == "all" or chance == "hue"
	var spin_random: bool = chance == "all"
	var size_mid: float = (size_min + size_max) * 0.5

	for region in _region_plan():
		var lo: Vector3 = region["lo"]
		var hi: Vector3 = region["hi"]
		var n: int = int(region["count"])

		for i in range(n):
			var cube: MeshInstance3D = MeshInstance3D.new()

			# Random size
			var size: float = _rf(size_min, size_max) if size_random else size_mid
			var cube_mesh: BoxMesh = BoxMesh.new()
			cube_mesh.size = Vector3(size, size, size)
			cube.mesh = cube_mesh

			# Random position within the region this macrostate fences off.
			# For `uniform` that region is lo=(-r, 0, -r), hi=(r, r, r) — the
			# three shipped randf_range calls, in the shipped order.
			cube.position = Vector3(
				_rf(lo.x, hi.x),
				_rf(lo.y, hi.y),
				_rf(lo.z, hi.z)
			)

			# Random rotation
			if spin_random:
				cube.rotation = Vector3(
					_rf(0.0, TAU),
					_rf(0.0, TAU),
					_rf(0.0, TAU)
				)

			# Random color variation
			var mat: StandardMaterial3D = StandardMaterial3D.new()
			var color_variation: Color = base_color
			if hue_random:
				color_variation.h += _rf(-0.1, 0.1)
				color_variation.s = clamp(color_variation.s + _rf(-0.2, 0.2), 0.3, 1.0)
			mat.albedo_color = color_variation
			mat.emission_enabled = true
			mat.emission = color_variation
			mat.emission_energy_multiplier = 0.3
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			cube.material_override = mat

			add_child(cube)
			_cubes.append(cube)
			_region_lo.append(lo)
			_region_hi.append(hi)

			# Random velocity for drift
			_velocities.append(Vector3(
				_rf(-1, 1),
				_rf(-1, 1),
				_rf(-1, 1)
			).normalized() * drift_speed)

			# Only a tumbling pile keeps tumbling. Under none/hue/size the cubes
			# are axis-aligned, and a random spin would erode that within seconds
			# in a lived room — the value has to survive being stood in, not just
			# photographed.
			if spin_random:
				_angular_velocities.append(Vector3(
					_rf(-1, 1),
					_rf(-1, 1),
					_rf(-1, 1)
				) * 0.5)
			else:
				_angular_velocities.append(Vector3.ZERO)

	if macrostate != "uniform":
		_build_bounds_frame()

## The region each macrostate fences off, and how many cubes live in it.
## `uniform` is the shipped volume, whole and undivided.
func _region_plan() -> Array:
	var r: float = spawn_radius
	var plans: Array = []

	match macrostate:
		"corner":
			# One octant at the low -x / -z corner, about a third of the span each
			# way. The rest of the volume stays visibly empty — that emptiness IS
			# the falling count of ways.
			plans.append({
				"count": cube_count,
				"lo": Vector3(-r, 0.0, -r),
				"hi": Vector3(-r + r * 0.64, r * 0.32, -r + r * 0.64),
			})
		"layered":
			# Sorted into two slabs with a dead band between them. Still random
			# inside each slab; the sorting is the macrostate.
			var top_n: int = cube_count / 2
			plans.append({
				"count": top_n,
				"lo": Vector3(-r, r * 0.78, -r),
				"hi": Vector3(r, r, r),
			})
			plans.append({
				"count": cube_count - top_n,
				"lo": Vector3(-r, 0.0, -r),
				"hi": Vector3(r, r * 0.22, r),
			})
		"spilled":
			# Most of the pile still inside; the rest already over the rim. The
			# boundary is what made the count mean anything, and this value is the
			# pile admitting it. Kept deliberately close so the union AABB the
			# sweep frames on does not shrink the other three values to specks.
			var out_n: int = int(round(float(cube_count) * 0.3))
			plans.append({
				"count": cube_count - out_n,
				"lo": Vector3(-r, 0.0, -r),
				"hi": Vector3(r, r, r),
			})
			plans.append({
				"count": out_n,
				"lo": Vector3(-r * 1.15, r * 1.15, -r * 1.15),
				"hi": Vector3(r * 1.15, r * 1.45, r * 1.15),
			})
		_:
			# uniform — the shipped region, the whole volume.
			plans.append({
				"count": cube_count,
				"lo": Vector3(-r, 0.0, -r),
				"hi": Vector3(r, r, r),
			})

	return plans

## A thin wire box of the SHIPPED spawn volume. Drawn only when the macrostate is
## not `uniform`: without it, `corner` reads as a smaller pile rather than as the
## same pile confined, and `spilled` has nothing to have spilled out of. `uniform`
## renders exactly what it always did — no frame, no extra node.
func _build_bounds_frame() -> void:
	var r: float = spawn_radius
	var t: float = r * 0.012
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	var frame_color: Color = base_color
	frame_color.a = 0.5
	mat.albedo_color = frame_color
	mat.emission_enabled = true
	mat.emission = frame_color
	mat.emission_energy_multiplier = 0.6
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var levels: Array[float] = [0.0, r]
	var sides: Array[float] = [-r, r]
	for y in levels:
		_add_bar(Vector3(0.0, y, -r), Vector3(2.0 * r, t, t), mat)
		_add_bar(Vector3(0.0, y, r), Vector3(2.0 * r, t, t), mat)
		_add_bar(Vector3(-r, y, 0.0), Vector3(t, t, 2.0 * r), mat)
		_add_bar(Vector3(r, y, 0.0), Vector3(t, t, 2.0 * r), mat)
	for x in sides:
		for z in sides:
			_add_bar(Vector3(x, r * 0.5, z), Vector3(t, r, t), mat)

func _add_bar(pos: Vector3, size: Vector3, mat: Material) -> void:
	var bar: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	bar.mesh = box
	bar.position = pos
	bar.material_override = mat
	add_child(bar)
	_frame_parts.append(bar)

func _process(delta: float) -> void:
	if drift_speed <= 0:
		return

	_time += delta

	for i in range(_cubes.size()):
		var cube: MeshInstance3D = _cubes[i]

		# Drift movement
		cube.position += _velocities[i] * delta

		# Rotate
		cube.rotation += _angular_velocities[i] * delta

		# Bounce off the boundaries of THIS cube's region. For `uniform` that is
		# lo=(-r, 0, -r) / hi=(r, r, r), i.e. the three shipped tests exactly;
		# for the other macrostates it is what keeps a sorted pile sorted and a
		# spilled cube outside instead of drifting quietly back in.
		var lo: Vector3 = _region_lo[i]
		var hi: Vector3 = _region_hi[i]
		if cube.position.x < lo.x or cube.position.x > hi.x:
			_velocities[i].x *= -1
		if cube.position.y < lo.y or cube.position.y > hi.y:
			_velocities[i].y *= -1
		if cube.position.z < lo.z or cube.position.z > hi.z:
			_velocities[i].z *= -1

## Regenerate with new random arrangement
func regenerate() -> void:
	for cube in _cubes:
		if is_instance_valid(cube):
			cube.queue_free()
	for part in _frame_parts:
		if is_instance_valid(part):
			part.queue_free()
	_cubes.clear()
	_frame_parts.clear()
	_velocities.clear()
	_angular_velocities.clear()
	_region_lo.clear()
	_region_hi.clear()
	_spawn_cubes()

# --- Grid config --------------------------------------------------------------

## Grid hook. There was none before, so nothing here was reachable from a map token —
## GridInteractablesComponent calls this on the ROOT and fell through to "no
## configuration method found".
##
## GATED BY DATA, TWICE. A config carrying none of these keys returns before touching
## anything, and even one that carries them re-rolls only when a value actually CHANGED
## and only after _ready has built once. An unguarded rebuild here would re-roll the
## shipped placements on their first config call.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_macrostate: String = macrostate
	var before_chance: String = chance
	var before_seed: int = chance_seed
	var before_count: int = cube_count

	if config_data.has("macrostate"):
		var m_in: String = str(config_data["macrostate"]).strip_edges().to_lower()
		if MACROSTATES.has(m_in):
			macrostate = m_in
	if config_data.has("chance"):
		var c_in: String = str(config_data["chance"]).strip_edges().to_lower()
		if CHANCES.has(c_in):
			chance = c_in
	if config_data.has("chance_seed"):
		chance_seed = int(str(config_data["chance_seed"]))
	if config_data.has("cube_count"):
		cube_count = maxi(1, int(str(config_data["cube_count"])))
	if config_data.has("drift_speed"):
		drift_speed = float(str(config_data["drift_speed"]))

	if not _built:
		return
	if macrostate == before_macrostate \
			and chance == before_chance \
			and chance_seed == before_seed \
			and cube_count == before_count:
		return
	regenerate()
