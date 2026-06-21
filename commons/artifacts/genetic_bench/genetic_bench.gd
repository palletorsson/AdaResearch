extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GeneticBench

## @identity
## name: "Genetic & evolutionary"
## tier: medium
## lineage: one generation of a genetic algorithm laid out as a population — variation, then selection,
##   made spatial. The fitness function picks; the picked one is lit.
## essence: a row of ~7 creatures, each decoded from its own random gene vector by the same reader. A
##   fitness function scores them — tall and symmetric wins — and the single fittest is set glowing while
##   the rest stay matte. Nobody designed the winner; it was selected out of a spread of bodies.
## truth: variation, selection — forms you never drew; the population is the search and fitness is the judge.

@export var bench_seed: int = 9
@export var population: int = 7
@export var gene_count: int = 6
@export var base_col: Color = Color(0.55, 0.6, 0.72)
@export var win_col: Color = Color(1.0, 0.85, 0.35)
@export var label_col: Color = Color(0.78, 0.92, 0.85)

const BASE_Y: float = 0.85

var _t: float = 0.0
var _winner: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("bench_seed"):
		bench_seed = int(config["bench_seed"])
	if config.has("population"):
		population = clampi(int(config["population"]), 3, 11)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_winner = null
	_build()


# Decode a 6-gene vector into a stacked body. Returns [Node3D, height, symmetry] for scoring.
func _decode(genome: Array[float], col_base: Color, glow: bool) -> Dictionary:
	var holder := Node3D.new()
	var segments: int = 3 + int(round(genome[0] * 4.0))
	var base_w: float = lerpf(0.05, 0.10, genome[1])
	var taper: float = lerpf(0.6, 0.95, genome[2])
	var hue_drift: float = lerpf(-0.15, 0.15, genome[3])
	var lean: float = lerpf(-0.08, 0.08, genome[4])
	var crown: float = lerpf(0.015, 0.05, genome[5])

	var y: float = 0.0
	var w: float = base_w
	for s in range(segments):
		var seg_h: float = w * 0.95
		var col: Color = col_base
		col.h = wrapf(col_base.h + hue_drift * float(s), 0.0, 1.0)
		var x: float = lean * float(s) * 0.4
		var mat: StandardMaterial3D = _glow_mat(col, 0.9) if glow else _matte_mat(col, 0.7)
		holder.add_child(_box(Vector3(x, y + seg_h * 0.5, 0.0), Vector3(w, seg_h, w * 0.8), mat))
		y += seg_h
		w *= taper
	var head_col: Color = col_base.lightened(0.1)
	var head_mat: StandardMaterial3D = _glow_mat(win_col, 1.1) if glow else _matte_mat(head_col, 0.7)
	holder.add_child(_sphere(Vector3(lean * float(segments) * 0.4, y + crown, 0.0), crown, head_mat))

	# symmetry score: less lean = more symmetric (1.0 at zero lean)
	var symmetry: float = 1.0 - clampf(absf(lean) / 0.08, 0.0, 1.0)
	return {"node": holder, "height": y + crown, "symmetry": symmetry}


func _build() -> void:
	# bench
	add_child(_box(Vector3(0.0, BASE_Y - 0.09, 0.0), Vector3(1.5, 0.18, 0.6), _matte_mat(Color(0.16, 0.17, 0.2), 0.85)))
	add_child(_cylinder(Vector3(0.0, (BASE_Y - 0.18) * 0.5, 0.0), 0.07, BASE_Y - 0.18, _steel_mat(Color(0.32, 0.34, 0.4))))
	add_child(_billboard_label("GENETIC BENCH\nvariation, selection — forms you never drew", Vector3(0.0, BASE_Y + 0.95, 0.0), 17, label_col))

	var rng := RandomNumberGenerator.new()
	rng.seed = bench_seed

	# build the whole population, decode each, score by tall + symmetric
	var bodies: Array = []
	var best_i: int = 0
	var best_score: float = -1.0
	for i in range(population):
		var genome: Array[float] = []
		for _g in range(gene_count):
			genome.append(rng.randf())
		var info := _decode(genome, base_col, false)
		var score: float = float(info["height"]) * 1.6 + float(info["symmetry"]) * 0.18
		bodies.append({"genome": genome, "score": score})
		if score > best_score:
			best_score = score
			best_i = i

	# place them in a row; the winner is re-decoded with glow
	var spacing: float = 1.36 / float(maxi(population - 1, 1))
	for i in range(population):
		var x: float = (float(i) - float(population - 1) * 0.5) * spacing
		var is_win: bool = (i == best_i)
		var info := _decode(bodies[i]["genome"], base_col, is_win)
		var node: Node3D = info["node"]
		node.position = Vector3(x, BASE_Y, 0.0)
		add_child(node)
		if is_win:
			_winner = node
			# a glowing pedestal ring + "FITTEST" tag under the chosen one
			add_child(_cylinder(Vector3(x, BASE_Y - 0.005, 0.0), 0.075, 0.01, _glow_mat(win_col, 0.8)))
			add_child(_billboard_label("FITTEST", Vector3(x, BASE_Y - 0.06, 0.18), 11, win_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# the winner pulses gently to draw the eye
	_t += delta
	if _winner != null:
		var s: float = 1.0 + sin(_t * 2.2) * 0.04
		_winner.scale = Vector3(s, s, s)
