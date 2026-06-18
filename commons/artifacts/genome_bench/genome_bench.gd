extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GenomeBench

## @identity
## lineage: the bench rung of the seed -> form ladder — the genotype->phenotype map made watchable.
##   Scrub the genome and the organism re-grows; the form is downstream of a few dozen numbers.
## essence: a CritterDNA genome drifts by small mutations; each change re-grows the plant via the same
##   L-system. A row of gene-bars on the panel IS the seed — store those numbers and the form returns.
## truth: the body is the long way of saying the genome; mutate one gene and the whole sentence rewrites.
##
## PERF: the plant is rebuilt ONLY when the genome changes (every drift_interval s), never per frame —
## TreeMorphology MultiMesh-batches the leaves and we hold LOD low (1). _process is a cheap timer.

@export var seed_value: int = 7
@export var drift_interval: float = 2.6
@export var mutate_strength: float = 0.14
const BASE_Y := 0.86
var _dna: CritterDNA
var _mapper
var _holder: Node3D
var _panel: Node3D
var _t: float = 0.0


func _ready() -> void:
	_mapper = CritterTraitMapper.new()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("seed_value"): seed_value = int(config["seed_value"])
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	# bench
	add_child(_box(Vector3(0.0, BASE_Y - 0.1, 0.0), Vector3(1.2, 0.18, 0.7), _matte_mat(Color(0.16, 0.17, 0.2), 0.85)))
	add_child(_cylinder(Vector3(0.0, (BASE_Y - 0.2) * 0.5, 0.0), 0.07, BASE_Y - 0.2, _steel_mat(Color(0.32, 0.34, 0.4))))
	add_child(_billboard_label("GENOME BENCH\nscrub the genome -> the form re-grows", Vector3(0.0, BASE_Y + 0.95, 0.0), 17, Color(0.72, 0.95, 0.82)))
	# the genome — deterministic seed, then it will drift; nudge it toward a fuller, readable tree
	_dna = CritterDNA.random_kingdom(0, seed_value)
	_dna.scale = 2.2   # the scale gene drives morphology size — a taller tree that reads on the bench
	_dna.segments = maxf(_dna.segments, 7.0)
	_dna.leaf_density = maxf(_dna.leaf_density, 0.6)
	_holder = Node3D.new()
	_holder.position = Vector3(-0.12, BASE_Y, -0.02)
	_holder.scale = Vector3.ONE * 0.42   # transform-only; trims the now-tall tree to bench proportion
	add_child(_holder)
	_panel = Node3D.new()
	_panel.position = Vector3(0.42, BASE_Y + 0.34, -0.2)
	add_child(_panel)
	_regrow()


# Rebuild the plant + the gene-bar panel from the current genome. Called on change only.
func _regrow() -> void:
	for c in _holder.get_children():
		_holder.remove_child(c); c.queue_free()
	MorphologyRouter.build(_dna, _holder, _mapper, 2)   # LOD 2 reads far fuller; only rebuilt on drift, not per frame
	# gene-bar readout — a handful of genes drawn as bars; this row of numbers IS the seed
	for c in _panel.get_children():
		_panel.remove_child(c); c.queue_free()
	var genes := [
		[_dna.segments / 12.0, _dna.primary_color],
		[_dna.branch_angle / 90.0, _dna.secondary_color],
		[_dna.leaf_density, _dna.tertiary_color],
		[_dna.part_curve, _dna.primary_color.lerp(Color.WHITE, 0.3)],
		[_dna.symmetry / 8.0, _dna.secondary_color.lerp(Color.WHITE, 0.3)],
	]
	for i in range(genes.size()):
		var h: float = clampf(float(genes[i][0]), 0.05, 1.0) * 0.26
		_panel.add_child(_box(Vector3(float(i) * 0.07 - 0.14, h * 0.5 - 0.13, 0.0), Vector3(0.05, h, 0.02), _glow_mat(genes[i][1], 0.7)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _dna == null:
		return
	_t += delta
	if _t >= drift_interval:
		_t = 0.0
		CritterDNA.mutate(_dna, 0.5, mutate_strength)   # small drift, then re-grow ONCE
		_regrow()
