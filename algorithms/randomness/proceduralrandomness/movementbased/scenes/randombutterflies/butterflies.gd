extends Node3D

# Butterfly spawner — spawns entropy-seeking butterflies.
# Butterflies discover entropy_axiom nodes in the scene and are drawn to them.

@export var butterfly_scene: PackedScene
@export var spawn_interval: float = 10.0
@export var max_butterflies: int = 8  # Cap to keep performance reasonable

# ── STAGE-2 DNA (promoted 2026-08-03) ───────────────────────────────────────
## The swarm had three exports and all three were budget: how often, how many,
## which scene. Nothing here was an argument. But the artifact IS an argument —
## it says a random walker in a room with an entropy gradient is not uniformly
## distributed, and that you can see the bias in where the bodies end up.
##
## That claim has three moments, and a still photograph can only ever hold one
## of them. Which one the room shows you is the design decision that was never
## made, because the swarm has only ever been found in the first:
##
##   scatter    Butterflies at uniformly random points across the whole wander
##              volume, wings white. The null hypothesis, standing in the room.
##              Nothing has been sought yet; chance looks like chance.
##   gathering  Caught mid-approach — each one already turned toward its target
##              on the gradient, part-way there, wings half-tinted. The bias is
##              legible as DIRECTION: a field of arrows, not a field of dots.
##   landed     Already sitting on the entropy points, wings carrying the local
##              hue. The distribution has collapsed onto the attractor and the
##              randomness has become a shape. The strongest reading of the
##              artifact's claim, and the one that hides the wandering entirely.
##
## The three are not degrees of the same thing. `scatter` shows the process,
## `landed` shows the result, and only `gathering` shows the two at once —
## which is why it is the interesting middle and not a halfway house.
##
## Deliberately NOT an axis: spawn_interval, entropy_seek_chance, wing tint
## speed. Every one of them is a rate, and a rate cannot be photographed.
@export_enum("scatter", "gathering", "landed") var arrival: String = "scatter"

## Shipped behaviour is exactly one butterfly at _ready and one more every
## spawn_interval seconds up to max_butterflies. 1 keeps that. The DNA bench
## raises it through dna.fixture, because a "distribution" of one sample is not
## a distribution and no arrival value would be distinguishable from another.
@export var initial_count: int = 1

## 0 keeps the shipped behaviour byte for byte: the butterflies draw their spawn
## points from the global RNG, so every swarm in every map is a different swarm.
## Any non-zero value pins the whole swarm, which is what the still needs —
## otherwise three variants are three different swarms and the axis cannot be
## measured at all, only guessed at.
@export var swarm_seed: int = 0

const ARRIVALS := ["scatter", "gathering", "landed"]

var timer: Timer

var _rng: RandomNumberGenerator = null
var _built: bool = false


func _ready() -> void:
	timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.timeout.connect(_on_spawn_timeout)
	add_child(timer)
	timer.start()

	# Spawn the opening population so the scene isn't empty
	_populate()
	_built = true


func _populate() -> void:
	if swarm_seed != 0:
		_rng = RandomNumberGenerator.new()
		_rng.seed = swarm_seed
	else:
		_rng = null

	var n: int = initial_count
	if n < 1:
		n = 1
	for i in range(n):
		_spawn_butterfly(i, n)


func _on_spawn_timeout() -> void:
	# Count current butterflies
	var count: int = get_tree().get_nodes_in_group("entropy_butterfly").size()
	if count < max_butterflies:
		_spawn_butterfly(count, max_butterflies)


func _spawn_butterfly(index: int = 0, total: int = 1) -> void:
	if not butterfly_scene:
		return

	var instance: Node3D = butterfly_scene.instantiate() as Node3D
	if not instance:
		return

	# butterfly.tscn's ROOT is an unscripted container; the behaviour lives on
	# the "butterfly" child. Everything below talks to that node, not the root.
	var brain: Node3D = instance.find_child("butterfly", true, false) as Node3D

	# Seeded BEFORE the child enters the tree: the butterfly draws its own spawn
	# point in _ready, and _ready fires the moment add_child runs.
	if _rng != null and brain:
		brain.set("rng_seed", _rng.randi())

	add_child(instance)
	instance.add_to_group("remove")

	# Start the fly animation on the inner butterfly node
	if brain and arrival != "landed":
		var anim: AnimationPlayer = brain.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim:
			anim.play("fly")

	if arrival != "scatter" and brain and brain.has_method("stage_arrival"):
		# Spread the swarm along the gradient rather than piling it on one point:
		# a heap at one end is a picture of a bug, not of a distribution.
		var t: float = 0.0
		if total > 1:
			t = float(index) / float(total - 1)
		brain.call("stage_arrival", arrival, t)


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	var dirty: bool = false

	if config.has("arrival"):
		var v: String = str(config["arrival"])
		if v in ARRIVALS and v != arrival:
			arrival = v
			dirty = true

	if config.has("initial_count"):
		var n: int = int(config["initial_count"])
		if n > 0 and n != initial_count:
			initial_count = n
			dirty = true

	if config.has("swarm_seed"):
		var s: int = int(config["swarm_seed"])
		if s != swarm_seed:
			swarm_seed = s
			dirty = true

	# THE GUARD THAT MATTERS. An unguarded respawn here would clear and rebuild
	# the swarm in all ten maps that place this artifact with no config at all —
	# a visible change to shipped rooms in exchange for nothing. Rebuild only
	# when a value actually moved, and only once _ready has built a swarm to
	# replace.
	if dirty and _built:
		_repopulate()


func _repopulate() -> void:
	for child in get_children():
		if child.is_in_group("entropy_butterfly") or child.is_in_group("remove"):
			remove_child(child)
			child.queue_free()
	_populate()
