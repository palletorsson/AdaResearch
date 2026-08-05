# gravity_gun_test_scene.gd
# Test scene with 10 shootable spheres for gravity gun testing
#
# @identity
# essence: An arrangement of shootable spheres — grid, ramp, ring or stack — providing physics targets for the gravity gun
# desire: To give the player something to push, throw, knock — to make the abstract gravity gun palpable through impact and rearrangement
# critical_parameter: arrangement and spawn_count — arrangement decides whether the collection reads as wall, rank, ring or stack; count decides intensity
# triggers: Grid produces brick wall feel; ramp grades the targets by height; ring gives a ring-toss-like target; stack piles for cascade physics
# emerges: A simple arrangement of physics objects becomes a stage for vector practice — every shot is a vector being applied at a point
# needs: configurable spawn patterns [has], physics-active spheres [has], reset on map enter [has]
# relationships: Stage for gravity_gun in forces/Combat_Arena. Companion to queer_cylinder_target (the named goal among the spheres)
# truth: A test scene is not a placeholder — it is the rehearsal where physics learns its part before the player arrives.
extends Node3D

const SHOOTABLE_SPHERE = preload("res://algorithms/vectors/08_vector_throwing/destructibles/shootable_sphere.tscn")

@export_group("Sphere Spawning")
@export var spawn_count: int = 10

## AXIS — WHAT SHAPE THE COLLECTION IS FILED IN, and therefore what it claims a rehearsal
## space IS. Ten or thirty spheres are the same spheres whichever way they lie; the layout
## is the only place this artifact makes an argument, which its own identity block already
## says: "pattern decides whether the arrangement reads as wall, ring, or stack".
##
## The word and its four values are taken from [[grabcolorcollection]] — which asks the
## identical question of ten colour swatches — and the word alone from [[particle_systems]]
## and [[scale_lines]]. Three of the four values ARE this file's shipped three under the
## family's spelling: circle was a ring and pyramid was a stack. `ramp` is the one value
## the collection did not have, and it is the one that completes the argument.
##
##   grid      the shipped 2 x 5 wall, byte for byte: two rows of five at spawn_spacing,
##             flat in the XY plane, every sphere equally available. The claim is that a
##             target field is a MASS — undifferentiated, breachable anywhere
##   ramp      the same ten unstacked into one rank, each sphere higher than the last, so
##             the row climbs away from the shooter. The claim is that targets are ORDERED
##             — a graded ladder where position means difficulty, not a wall
##   ring      the count stood evenly around a circle at 2 x spawn_spacing, the shooter
##             inside it rather than facing it. The claim is that a target field
##             SURROUNDS — there is no front, and every shot has a back
##   stack     the shipped pyramid: 4 + 3 + 2 + 1 in rings of falling radius, each level
##             bearing the one above. The claim is that a target field is a STRUCTURE, and
##             that what you knock out matters more than how many
##
## STRICTLY ADDITIVE at the default. `grid` runs the same spawn_grid_pattern() body it
## always did, so all four existing placements stand exactly as before. Nothing here reads
## or writes spawn_count, spawn_spacing, spawn_height, the palette or the gravity gun.
@export_enum("grid", "ramp", "ring", "stack") var arrangement: String = "grid"

## Allow-list. An unknown word in a map token keeps the shipped wall.
const ARRANGEMENTS: PackedStringArray = ["grid", "ramp", "ring", "stack"]

## The words this export answered to before it joined the family vocabulary. set_pattern()
## still takes them, so any caller written against the old README keeps working.
const LEGACY_PATTERN_WORDS: Dictionary = {"circle": "ring", "pyramid": "stack"}

## `ramp` re-files the GRID's ten, not spawn_count's thirty: a rank of thirty at
## spawn_spacing would be fourteen metres wide, which is not a variant of a two-metre wall
## — it is a different object, and in a sweep it would shrink every other value to specks.
const RAMP_COUNT: int = 10

@export var spawn_spacing: float = 0.3
@export var spawn_height: float = 0.0

## Multiplies each spawned sphere's gravity_scale. 1.0 is the shipped behaviour exactly.
## THIS IS A FIXTURE KNOB, not an axis. These spheres are RigidBody3D with gravity, and
## shootable_sphere.setup_physics() re-asserts gravity_scale = 1.0 in its own _ready — so
## on a capture bench with no floor under them, all four arrangements dissolve into the
## same falling cloud within a second and the axis photographs as nothing. At 0.0 the
## collection holds the pose it was filed in, which is the thing the axis is about.
@export var spawn_gravity_scale: float = 1.0

@export_group("Sphere Colors")
@export var randomize_colors: bool = true
## 0 keeps the shipped rng.randomize() — a fresh colouring every launch. Any positive
## value seeds the generator instead, which is what a sweep needs: unseeded colour means
## four variants differ before the axis has been turned at all, and the critic reads that
## noise as bite.
@export var color_seed: int = 0
@export var color_palette: Array[Color] = [
	Color(1.0, 0.3, 0.3),  # Red
	Color(1.0, 0.7, 0.3),  # Orange
	Color(1.0, 1.0, 0.3),  # Yellow
	Color(0.3, 1.0, 0.3),  # Green
	Color(0.3, 0.7, 1.0),  # Blue
	Color(0.7, 0.3, 1.0),  # Purple
]

var spawned_spheres: Array[RigidBody3D] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _built: bool = false

func _ready() -> void:
	_settle_arrangement()
	if color_seed > 0:
		rng.seed = color_seed
	else:
		rng.randomize()
	spawn_spheres()
	_built = true


## Reads the map token's `#arrangement:<value>` metadata, then normalises whatever is set.
func _settle_arrangement() -> void:
	if has_meta("config_arrangement"):
		var m: String = str(get_meta("config_arrangement")).strip_edges().to_lower()
		if ARRANGEMENTS.has(m):
			arrangement = m
	var v: String = String(arrangement).strip_edges().to_lower()
	arrangement = v if ARRANGEMENTS.has(v) else "grid"

func spawn_spheres() -> void:
	"""Spawn spheres in selected pattern"""
	clear_spheres()

	match arrangement:
		"grid":
			spawn_grid_pattern()
		"ramp":
			spawn_ramp_pattern()
		"ring":
			spawn_ring_pattern()
		"stack":
			spawn_stack_pattern()
		_:
			spawn_grid_pattern()

	print("[GravityGunTest] Spawned ", spawned_spheres.size(), " spheres in ", arrangement, " arrangement")

func spawn_grid_pattern() -> void:
	"""Spawn spheres in a grid (2x5)"""
	var rows = 2
	var cols = 5

	for row in range(rows):
		for col in range(cols):
			var pos = Vector3(
				(col - cols / 2.0 + 0.5) * spawn_spacing,
				spawn_height + row * spawn_spacing,
				0
			)
			spawn_sphere_at(pos)

func spawn_ramp_pattern() -> void:
	"""Spawn the grid's ten as one climbing rank — a graded ladder, not a wall.

	The pitch is half spawn_spacing so the rank spans the same ~2 m the 2 x 5 wall does;
	the rise is 2 x spawn_spacing over the whole run. Both are read from the same knob the
	other three arrangements use, so a map that widens the spacing widens all four alike."""
	for i in range(RAMP_COUNT):
		var f: float = float(i) / float(RAMP_COUNT - 1)
		var pos: Vector3 = Vector3(
			(float(i) - float(RAMP_COUNT - 1) * 0.5) * spawn_spacing * 0.5,
			spawn_height + f * spawn_spacing * 2.0,
			0.0
		)
		spawn_sphere_at(pos)

func spawn_ring_pattern() -> void:
	"""Spawn spheres in a ring"""
	for i in range(spawn_count):
		var angle = (float(i) / float(spawn_count)) * TAU
		var radius = spawn_spacing * 2.0
		var pos = Vector3(
			cos(angle) * radius,
			spawn_height,
			sin(angle) * radius
		)
		spawn_sphere_at(pos)

func spawn_stack_pattern() -> void:
	"""Spawn spheres in a pyramid (4+3+2+1 = 10)"""
	var levels = [
		{"count": 4, "radius": spawn_spacing * 1.5},
		{"count": 3, "radius": spawn_spacing * 1.0},
		{"count": 2, "radius": spawn_spacing * 0.5},
		{"count": 1, "radius": 0.0}
	]

	var sphere_index = 0
	for level_idx in range(levels.size()):
		var level = levels[level_idx]
		var count = level["count"]
		var radius = level["radius"]
		var height = spawn_height + level_idx * spawn_spacing * 0.8

		if count == 1:
			# Single sphere at top
			spawn_sphere_at(Vector3(0, height, 0))
		else:
			# Ring of spheres
			for i in range(count):
				var angle = (float(i) / float(count)) * TAU
				var pos = Vector3(
					cos(angle) * radius,
					height,
					sin(angle) * radius
				)
				spawn_sphere_at(pos)

		sphere_index += count
		if sphere_index >= spawn_count:
			break

func spawn_sphere_at(position: Vector3) -> void:
	"""Spawn a single sphere at the given position"""
	var sphere = SHOOTABLE_SPHERE.instantiate()
	sphere.position = position

	# Randomize color if enabled
	if randomize_colors and not color_palette.is_empty():
		var color = color_palette[rng.randi() % color_palette.size()]
		# Set color before adding to tree
		sphere.sphere_color = color

	add_child(sphere)
	# AFTER add_child, and only when asked. shootable_sphere.setup_physics() re-asserts
	# gravity_scale = 1.0 from its own _ready, which runs on add_child — so a value set
	# before this line is erased. The `!= 1.0` guard means the shipped path never touches
	# the body at all.
	if spawn_gravity_scale != 1.0:
		sphere.gravity_scale = spawn_gravity_scale
	spawned_spheres.append(sphere)

func clear_spheres() -> void:
	"""Remove all spawned spheres"""
	for sphere in spawned_spheres:
		if is_instance_valid(sphere):
			sphere.queue_free()
	spawned_spheres.clear()

func reset_spheres() -> void:
	"""Respawn all spheres"""
	spawn_spheres()

# Public API for testing
func set_pattern(pattern: String) -> void:
	"""Change arrangement and respawn. Still answers to the pre-promotion words
	"circle" and "pyramid", so a caller written against the old README keeps working."""
	var p: String = String(pattern).strip_edges().to_lower()
	if LEGACY_PATTERN_WORDS.has(p):
		p = String(LEGACY_PATTERN_WORDS[p])
	if not ARRANGEMENTS.has(p):
		push_warning("GravityGunTestScene: unknown arrangement '%s' — keeping '%s'"
			% [pattern, arrangement])
		return
	arrangement = p
	spawn_spheres()

func get_sphere_count() -> int:
	return spawned_spheres.size()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## GATED ON THE KEY AND ON A CHANGE. This was `pass`, so nothing a map said ever reached
## the artifact. It still returns on the first line for a config that says nothing about
## arrangement — a token carrying only other keys cannot cause a respawn — and it never
## respawns before _ready has spawned once, or for a word that repeats the current value
## or misspells one.
func apply_grid_config(config: Dictionary) -> void:
	if not config.has("arrangement"):
		return
	var a: String = str(config["arrangement"]).strip_edges().to_lower()
	if not ARRANGEMENTS.has(a) or a == arrangement:
		return
	arrangement = a
	if _built:
		spawn_spheres()
