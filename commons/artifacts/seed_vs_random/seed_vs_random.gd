extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SeedVsRandom

## @identity
## lineage: the payoff of the seed -> form ladder, and the project's thesis made walkable — the random
##   vs the deep, side by side. Closes the loop from the randomness ladder to the DNA galleries.
## essence: two beds of plants. LEFT grows from fresh randomness every few seconds — never the same,
##   nothing worth storing. RIGHT grows from fixed CritterDNA seeds — store the seed, regrow it exactly.
##   Flat randomness is shallow; a seed that grows is deep. Same machine, opposite epistemics.
## truth: the random forgets itself the instant it lands; the seed can be kept, and kept is a kind of alive.
##
## PERF: the RIGHT (seeded) bed is reproducible, so it is built ONCE and never touched again. Only the
## LEFT (random) bed rebuilds, and only on a timer (every shuffle_interval s) — never per frame. Plants
## are trees (tube + MultiMesh leaves), capped at 3 per bed at LOD 1. The whole room stays a handful of
## rebuilds every few seconds, not a per-frame storm.

@export var shuffle_interval: float = 4.0
@export var per_bed: int = 3
const FIXED_SEEDS := [11, 27, 43, 58, 71]   # the stored genomes — reproducible forever
var _mapper
var _left: Node3D
var _t: float = 0.0


func _ready() -> void:
	_mapper = CritterTraitMapper.new()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("per_bed"): per_bed = clampi(int(config["per_bed"]), 1, 5)
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	# floor + the dividing line between the two epistemics
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(8.0, 0.1, 5.0), _matte_mat(Color(0.15, 0.16, 0.19), 0.9)))
	add_child(_box(Vector3(0.0, 0.02, 0.0), Vector3(0.06, 0.04, 5.0), _glow_mat(Color(0.5, 0.55, 0.62), 0.4)))
	# soil beds
	add_child(_box(Vector3(-2.2, 0.0, 0.0), Vector3(3.0, 0.12, 4.0), _matte_mat(Color(0.2, 0.16, 0.14), 0.95)))
	add_child(_box(Vector3(2.2, 0.0, 0.0), Vector3(3.0, 0.12, 4.0), _matte_mat(Color(0.14, 0.18, 0.15), 0.95)))
	# titles
	add_child(_billboard_label("the random  vs  the deep", Vector3(0.0, 3.5, 0.0), 30, Color(0.85, 0.9, 1.0)))
	add_child(_billboard_label("RANDOM\nnever the same\nnothing to store", Vector3(-2.2, 2.4, 0.0), 22, Color(1.0, 0.6, 0.5)))
	add_child(_billboard_label("DNA-SEEDED\nstore the seed\nregrow it exactly", Vector3(2.2, 2.4, 0.0), 22, Color(0.55, 0.95, 0.7)))
	# RIGHT bed — fixed seeds, built ONCE, reproducible and static
	var right := Node3D.new()
	add_child(right)
	for i in range(per_bed):
		var dna: CritterDNA = CritterDNA.random_kingdom(0, FIXED_SEEDS[i % FIXED_SEEDS.size()])
		var h := Node3D.new()
		h.position = Vector3(2.2 + (float(i) - (per_bed - 1) * 0.5) * 0.85, 0.06, (float(i) - (per_bed - 1) * 0.5) * 1.0)
		right.add_child(h)
		MorphologyRouter.build(dna, h, _mapper, 1)
	# LEFT bed — fresh randomness, rebuilt on the timer
	_left = Node3D.new()
	add_child(_left)
	_grow_random()


# Rebuild ONLY the random bed — fresh genomes each time, so it never looks the same twice.
func _grow_random() -> void:
	for c in _left.get_children():
		_left.remove_child(c); c.queue_free()
	for i in range(per_bed):
		var dna: CritterDNA = CritterDNA.random_kingdom(0, -1)   # -1 = unseeded, fresh every call
		var h := Node3D.new()
		h.position = Vector3(-2.2 + (float(i) - (per_bed - 1) * 0.5) * 0.9, 0.06, (float(i) - (per_bed - 1) * 0.5) * 1.1)
		_left.add_child(h)
		MorphologyRouter.build(dna, h, _mapper, 1)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _left == null:
		return
	_t += delta
	if _t >= shuffle_interval:
		_t = 0.0
		_grow_random()   # only the random side churns; the seeded side is permanent
