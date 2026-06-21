extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GenomeToy

## @identity
## name: "Genetic & evolutionary"
## tier: small
## lineage: genotype -> phenotype, the smallest possible case. A handful of numbers read aloud as a body.
## essence: a held creature, ~0.4m, decoded from a 6-float gene vector. The genes set the number of body
##   segments, their taper, their colour drift, their side-to-side lean, and a crown size. Change the
##   string, get a different animal. There is no model — only the reading of the genes.
## truth: a body is a short string read aloud — the form is downstream of a few numbers you could write on a hand.

@export var genome_seed: int = 3
@export var gene_count: int = 6
@export var base_col: Color = Color(0.7, 0.45, 0.55)
@export var label_col: Color = Color(0.85, 0.9, 1.0)

var _root: Node3D = null
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("genome_seed"):
		genome_seed = int(config["genome_seed"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_root = null
	_build()


# Make the gene vector — gene_count floats in 0..1, deterministic from the seed.
func _make_genome() -> Array[float]:
	var rng := RandomNumberGenerator.new()
	rng.seed = genome_seed
	var g: Array[float] = []
	for _i in range(gene_count):
		g.append(rng.randf())
	return g


# Decode a gene vector into a stacked little body. Pure read — no randomness here.
func _decode(genome: Array[float], holder: Node3D) -> void:
	# gene 0 -> segment count, 1 -> base width, 2 -> taper, 3 -> hue drift, 4 -> lean, 5 -> crown
	var segments: int = 3 + int(round(genome[0] * 4.0))            # 3..7
	var base_w: float = lerpf(0.06, 0.12, genome[1])
	var taper: float = lerpf(0.6, 0.95, genome[2])
	var hue_drift: float = lerpf(-0.18, 0.18, genome[3])
	var lean: float = lerpf(-0.05, 0.05, genome[4])
	var crown: float = lerpf(0.02, 0.07, genome[5])

	var y: float = 0.0
	var w: float = base_w
	for s in range(segments):
		var seg_h: float = w * 0.9
		var col: Color = base_col
		col.h = wrapf(base_col.h + hue_drift * float(s), 0.0, 1.0)
		col = col.lerp(Color.WHITE, 0.06 * float(s))
		var x: float = lean * float(s) * 0.4
		holder.add_child(_box(Vector3(x, y + seg_h * 0.5, 0.0), Vector3(w, seg_h, w * 0.8), _glow_mat(col, 0.4)))
		# little side limbs on the middle segments, sized by the same width gene
		if s > 0 and s < segments - 1:
			var limb := w * 0.55
			holder.add_child(_box(Vector3(x + w * 0.5 + limb * 0.4, y + seg_h * 0.5, 0.0), Vector3(limb, seg_h * 0.35, w * 0.4), _matte_mat(col.darkened(0.15), 0.7)))
			holder.add_child(_box(Vector3(x - w * 0.5 - limb * 0.4, y + seg_h * 0.5, 0.0), Vector3(limb, seg_h * 0.35, w * 0.4), _matte_mat(col.darkened(0.15), 0.7)))
		y += seg_h
		w *= taper
	# crown — a head sphere whose size is its own gene
	var head_col: Color = base_col
	head_col.h = wrapf(base_col.h + hue_drift * float(segments), 0.0, 1.0)
	holder.add_child(_sphere(Vector3(lean * float(segments) * 0.4, y + crown, 0.0), crown, _glow_mat(head_col.lightened(0.1), 0.6)))


func _build() -> void:
	var genome := _make_genome()
	_root = Node3D.new()
	add_child(_root)
	_decode(genome, _root)

	# the gene string itself, shown as a tiny readable label — the "short string"
	var txt := "GENOME  "
	for v in genome:
		txt += "%0.2f " % v
	add_child(_billboard_label("a body is a short string\nread aloud", Vector3(0.0, 0.42, 0.0), 13, label_col))
	add_child(_billboard_label(txt, Vector3(0.0, 0.34, 0.0), 9, Color(0.6, 0.85, 0.95)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _root == null:
		return
	# gentle sway so the little creature feels alive in the hand
	_t += delta
	_root.rotation.y = sin(_t * 0.8) * 0.25
