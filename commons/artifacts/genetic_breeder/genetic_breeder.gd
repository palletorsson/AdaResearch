extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GeneticBreeder

## @identity
## name: "Genetic & evolutionary"
## tier: applied
## lineage: a full genetic algorithm running live — select, crossover, mutate, repeat — the loop a single
##   generation of GeneticBench only froze. Hill-climbing through body-space toward a fitness target.
## essence: a ~1m breeder. A hidden population of gene vectors evolves: each tick the top genomes are kept,
##   bred (crossover) and mutated into a new generation, and the current BEST body is decoded onto the
##   platform. A readout climbs — GEN n, FIT x.xx — as selection ratchets fitness upward toward tall and
##   symmetric. When it plateaus or hits the cap it reseeds and climbs again. Evolution you can watch.
## truth: keep the best, breed it, nudge it — and fitness climbs a body at a time, with no designer in the loop.

@export var breeder_seed: int = 17
@export var pop_size: int = 16
@export var elite: int = 4
@export var gene_count: int = 6
@export var mutate_rate: float = 0.16
@export var tick_interval: float = 0.5
@export var max_generations: int = 40
@export var base_col: Color = Color(0.5, 0.7, 0.85)
@export var glow_col: Color = Color(0.45, 0.95, 0.6)
@export var label_col: Color = Color(0.82, 0.95, 0.88)

const BASE_Y: float = 0.85

var _platform: Node3D = null
var _readout: Label3D = null
var _rng_run := RandomNumberGenerator.new()
var _population: Array = []      # Array of Array[float]
var _generation: int = 0
var _best_fit: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(true)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("breeder_seed"):
		breeder_seed = int(config["breeder_seed"])
	if config.has("pop_size"):
		pop_size = clampi(int(config["pop_size"]), 6, 40)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_platform = null
	_readout = null
	_build()


func _build() -> void:
	# device — a platform on a column
	add_child(_cylinder(Vector3(0.0, BASE_Y - 0.02, 0.0), 0.34, 0.05, _steel_mat(Color(0.3, 0.32, 0.38))))
	add_child(_cylinder(Vector3(0.0, (BASE_Y - 0.06) * 0.5, 0.0), 0.06, BASE_Y - 0.06, _steel_mat(Color(0.26, 0.28, 0.33))))
	add_child(_box(Vector3(0.0, 0.03, 0.0), Vector3(0.46, 0.06, 0.46), _matte_mat(Color(0.14, 0.15, 0.18), 0.9)))
	add_child(_billboard_label("GENETIC BREEDER\nkeep the best, breed it, climb", Vector3(0.0, BASE_Y + 1.1, 0.0), 16, label_col))

	_platform = Node3D.new()
	_platform.position = Vector3(0.0, BASE_Y, 0.0)
	add_child(_platform)

	_readout = _billboard_label("GEN 0   FIT 0.00", Vector3(0.0, BASE_Y + 0.82, 0.0), 19, Color(0.6, 0.95, 0.7))
	add_child(_readout)

	_seed_population()


# Fresh random population.
func _seed_population() -> void:
	_rng_run.seed = breeder_seed + _generation * 0
	_rng_run.randomize()
	_population.clear()
	for _i in range(pop_size):
		var g: Array[float] = []
		for _j in range(gene_count):
			g.append(_rng_run.randf())
		_population.append(g)
	_generation = 0
	_best_fit = 0.0
	_advance(true)


# Fitness: tall (more, taller segments) + symmetric (low lean). Pure function of the genes.
func _fitness(genome: Array[float]) -> float:
	var segments: int = 3 + int(round(genome[0] * 4.0))
	var base_w: float = lerpf(0.05, 0.10, genome[1])
	var taper: float = lerpf(0.6, 0.95, genome[2])
	var lean: float = lerpf(-0.08, 0.08, genome[4])
	# total stacked height
	var h: float = 0.0
	var w: float = base_w
	for _s in range(segments):
		h += w * 0.95
		w *= taper
	var symmetry: float = 1.0 - clampf(absf(lean) / 0.08, 0.0, 1.0)
	return h * 4.0 + symmetry * 0.6


# Decode a genome into a body on the platform. glow lights the current best.
func _decode(genome: Array[float], glow: bool) -> Node3D:
	var holder := Node3D.new()
	var segments: int = 3 + int(round(genome[0] * 4.0))
	var base_w: float = lerpf(0.05, 0.10, genome[1])
	var taper: float = lerpf(0.6, 0.95, genome[2])
	var hue_drift: float = lerpf(-0.15, 0.15, genome[3])
	var lean: float = lerpf(-0.08, 0.08, genome[4])
	var crown: float = lerpf(0.02, 0.06, genome[5])
	var y: float = 0.0
	var w: float = base_w
	for s in range(segments):
		var seg_h: float = w * 0.95
		var col: Color = base_col
		col.h = wrapf(base_col.h + hue_drift * float(s), 0.0, 1.0)
		var x: float = lean * float(s) * 0.4
		var mat: StandardMaterial3D = _glow_mat(glow_col.lerp(col, 0.4), 0.9) if glow else _matte_mat(col, 0.7)
		holder.add_child(_box(Vector3(x, y + seg_h * 0.5, 0.0), Vector3(w, seg_h, w * 0.8), mat))
		y += seg_h
		w *= taper
	var head_mat: StandardMaterial3D = _glow_mat(glow_col, 1.1) if glow else _matte_mat(base_col.lightened(0.1), 0.7)
	holder.add_child(_sphere(Vector3(lean * float(segments) * 0.4, y + crown, 0.0), crown, head_mat))
	return holder


func _clear(n: Node3D) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


# Score the population, sort, show the best. If breed, also produce the next generation.
func _advance(initial: bool) -> void:
	# score + sort descending by fitness
	var scored: Array = []
	for g in _population:
		scored.append({"g": g, "f": _fitness(g)})
	scored.sort_custom(func(a, b): return a["f"] > b["f"])

	var best_genome: Array[float] = scored[0]["g"]
	var best: float = scored[0]["f"]
	_best_fit = maxf(_best_fit, best)

	# show the best body
	_clear(_platform)
	var body := _decode(best_genome, true)
	_platform.add_child(body)
	if _readout != null:
		_readout.text = "GEN %d   FIT %0.2f" % [_generation, _best_fit]

	if initial:
		return

	# breed the next generation: keep elite, fill with crossover + mutation of the top half
	var next_pop: Array = []
	var keep: int = clampi(elite, 1, _population.size())
	for i in range(keep):
		next_pop.append((scored[i]["g"] as Array[float]).duplicate())
	var pool: int = maxi(_population.size() / 2, 2)
	while next_pop.size() < pop_size:
		var pa: Array[float] = scored[_rng_run.randi() % pool]["g"]
		var pb: Array[float] = scored[_rng_run.randi() % pool]["g"]
		var child: Array[float] = []
		for j in range(gene_count):
			# uniform crossover
			var v: float = pa[j] if _rng_run.randf() < 0.5 else pb[j]
			# mutation — a small nudge, clamped to the gene range
			if _rng_run.randf() < mutate_rate:
				v += _rng_run.randfn(0.0, 0.12)
			child.append(clampf(v, 0.0, 1.0))
		next_pop.append(child)
	_population = next_pop


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _platform == null:
		return
	_t += delta
	# gentle spin of the showcased best so it reads from all sides
	_platform.rotation.y += delta * 0.5
	if _t < tick_interval:
		return
	_t = 0.0
	if _generation >= max_generations:
		# plateau reached — reseed and climb again
		_generation = 0
		_seed_population()
		return
	_generation += 1
	_advance(false)
