extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name DnaSprout

## @identity
## lineage: the held end of the seed -> form ladder — one genome, one grown plant. The deep seed,
##   bridging the randomness ladder's seed_toy ("same seed -> same glyph") to the DNA galleries.
## essence: a short CritterDNA genome grown by an L-system into a unique plant. The SAME seed always
##   grows the SAME plant — not flat randomness, the deep kind: store the seed, replay the growth.
## truth: a seed is not small because it is simple; it is small because the growing is where the size lives.
##
## PERF: built ONCE from a deterministic genome (no per-frame geometry rebuild); leaves are MultiMesh-
## batched by TreeMorphology; the only per-frame cost is a transform-only sway. apply_grid_config rebuilds.

@export var seed_value: int = 42
@export var kingdom: int = 0          # 0=tree, 2=flower (CritterDNA.body_type)
@export var sprout_scale: float = 0.32
var _holder: Node3D
var _mapper
var _t: float = 0.0


func _ready() -> void:
	_mapper = CritterTraitMapper.new()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("seed_value"): seed_value = int(config["seed_value"])
	if config.has("kingdom"): kingdom = int(config["kingdom"])
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	# the genome — deterministic from the seed (same seed -> same genes -> same plant)
	var dna: CritterDNA = CritterDNA.random_kingdom(kingdom, seed_value)
	dna.scale = 1.0   # keep the held sprout a consistent size; sprout_scale does the shrinking
	# grow it ONCE — L-system tubes + a single MultiMesh of leaves, modest LOD
	_holder = Node3D.new()
	_holder.position = Vector3(0.0, 0.12, 0.0)
	_holder.scale = Vector3.ONE * sprout_scale
	add_child(_holder)
	MorphologyRouter.build(dna, _holder, _mapper, 2)
	# the genome "strand" — a few beads coloured by the genes, so the seed is made visible in the hand
	var cols := [dna.primary_color, dna.secondary_color, dna.tertiary_color]
	var strand := Node3D.new()
	strand.position = Vector3(0.0, 0.02, 0.2)
	add_child(strand)
	for i in range(6):
		strand.add_child(_sphere(Vector3((float(i) - 2.5) * 0.05, 0.0, 0.0), 0.02, _glow_mat(cols[i % 3], 0.9)))
	add_child(_billboard_label("DNA seed %d\nsame seed -> same plant" % seed_value, Vector3(0.0, 0.74, 0.0), 16, Color(0.72, 0.95, 0.82)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _holder == null:
		return
	_t += delta
	_holder.rotation.y = _t * 0.4   # cheap turntable sway — transform only, no geometry rebuild
