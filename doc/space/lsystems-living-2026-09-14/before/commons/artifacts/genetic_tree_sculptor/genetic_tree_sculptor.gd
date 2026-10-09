extends Node3D
class_name GeneticTreeSculptor

# @identity
# essence: 8 sliders → CritterDNA → TreeMorphology.build() — design a tree's genome, watch it grow live
# desire: To sculpt a tree by tweaking its DNA — depth, forks, angle, taper, leaves, tropism, twist, arrangement
# critical_parameter: branch_angle (15-90°) — the single gene that most visibly transforms the tree's character
# triggers: Any slider move → debounced rebuild in 0.3s; Randomize → new genome; Plant → exports DNA for world placement
# emerges: The player becomes a breeder — intuition about which genes produce which forms develops through play
# needs: VR sliders [has, 8 sliders], push buttons [has, Random + Plant], Label3D [has via slider labels]
# relationships: Central to LSystems_Living. Uses CritterDNA and TreeMorphology systems. Bridges to evolution concepts.
# truth: A tree is eight numbers — change them and you are doing what evolution does, but with intention.

## Interactive DNA-to-tree workbench. Eight sliders control tree genes,
## live preview regenerates via TreeMorphology. The designed DNA is stored
## globally so the branching catalyst can plant copies in the world.

# ── STAGE-2 DNA — ONE AXIS: `pressure` ───────────────────────────────────────
#
# This artifact is called a GENETIC tree sculptor and its registry entry claims
# "genetic algorithm selection". There was no selection in it. _ready drew ONE
# unseeded random genome and built it, so the picture in every room was always
# generation 0 — the thing evolution starts from, standing in for the thing
# evolution produces. The eight sliders are a designer's hand, not a fitness
# function, and a still cannot photograph a hand moving.
#
# `pressure` runs the search the name promises, and states in the geometry WHAT
# the genome was selected FOR. That is the argument: selection is never for
# "better", it is always for something, and the same ancestor under four tastes
# grows four incompatible trees.
#
#   none      no selection. The shipped generation-0 genome, built exactly as
#             before. The default.
#   reach     selected for height — deep recursion, narrow forks, no droop.
#   spread    selected for canopy width — wide forks, many branches, tropism.
#   thicket   selected for mass — deep, many-forked and heavily leaved.
#   spare     selected for economy — shallow, two-forked, bare, fast taper.
#
# Each non-`none` value is a seeded greedy hill-climb over the eight slider
# genes: mutate, score, keep if better, `generations` times. Deterministic given
# dna_seed, so one value is one tree rather than a fresh sample each boot.
#
# NOT AN AXIS: `generations`. It is a count, and convergence is asymptotic — a
# gen-20 and a gen-40 climb under the same taste land on the same tree, so the
# upper rungs of a generation ladder would be identical frames dressed as an
# experiment. Its bottom rung is `pressure = none` already.
# NOT AN AXIS: REBUILD_COOLDOWN. A debounce is time-domain; a still cannot see it.
# NOT AN AXIS: `bench`. Staging, not argument — it hides the control rack so the
# sweep can photograph the tree instead of a slider panel. It is dna.fixture.

# --- slider definitions: [gene_name, label, default_normalized] ---
const GENE_SLIDERS: Array[Array] = [
	["segments",    "Depth",      0.4],   # generations 2-5
	["symmetry",    "Forks",      0.33],  # fork count 2-5
	["branch_angle","Angle",      0.2],   # 15-90°
	["branch_decay","Taper",      0.55],  # 0.3-0.9
	["leaf_density","Leaves",     0.5],   # 0-1
	["part_curve",  "Tropism",    0.35],  # gravity droop 0-1
	["part_twist",  "Twist",      0.5],   # -45 to 45 (0.5 = 0)
	["phyllotaxis", "Arrange",    0.0],   # spiral/opposite/whorled
]

## The genome the search may touch, with the same bounds the sliders map onto —
## so an evolved tree is always a tree a player could also have dialled by hand.
const GENE_RANGE: Dictionary = {
	"segments": [2.0, 10.0],
	"symmetry": [1.0, 8.0],
	"branch_angle": [15.0, 90.0],
	"branch_decay": [0.3, 0.9],
	"leaf_density": [0.0, 1.0],
	"part_curve": [0.0, 1.0],
	"part_twist": [-45.0, 45.0],
	"phyllotaxis": [0.0, 1.0],
}

## What this genome was selected for. Read in _ready(), before the tree is built.
@export_enum("none", "reach", "spread", "thicket", "spare") var pressure: String = "none"

const PRESSURES: PackedStringArray = ["none", "reach", "spread", "thicket", "spare"]

## Ancestor seed. -1 is the shipped behaviour: CritterDNA.random_kingdom(0)
## randomizes, so every boot is a different tree. Pin it to make a variant
## reproducible — the sweep does, via dna.fixture.
@export var dna_seed: int = -1

## Rounds of mutate-score-keep. A count, not an axis; see the header.
@export_range(0, 120) var generations: int = 24

## Staging only: "bare" omits the eight-slider control rack. dna.fixture, not an axis.
@export_enum("panel", "bare") var bench: String = "panel"

const MUTATION_RATE: float = 0.5     # per gene, per round
const MUTATION_STEP: float = 0.25    # fraction of the gene's own range
const PRESSURE_SALT: int = 90210     # keeps the search rng off the genome's rng

var _dna: CritterDNA
var _mapper: CritterTraitMapper
var _tree_root: Node3D
var _sliders: Dictionary = {}   # gene_name → slider_instance
var _control_panel: Node3D
var _rebuild_queued := false
var _rebuild_timer := 0.0
var _ready_done := false
const REBUILD_COOLDOWN := 0.3   # debounce slider scrubbing

func _ready() -> void:
	_dna = CritterDNA.random_kingdom(0, dna_seed)  # kingdom 0 = tree
	_evolve()
	_mapper = CritterTraitMapper.new()
	_build_ui()
	_sync_sliders_from_dna()
	_rebuild_tree()
	_ready_done = true

func _process(delta: float) -> void:
	if _rebuild_queued:
		_rebuild_timer -= delta
		if _rebuild_timer <= 0.0:
			_rebuild_queued = false
			_rebuild_tree()

# ── Selection ────────────────────────────────────────────────────────────────

## Greedy hill-climb from the current genome. A pure no-op at pressure="none",
## which is why every shipped placement is untouched.
func _evolve() -> void:
	if pressure == "none" or generations <= 0 or _dna == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = (dna_seed if dna_seed >= 0 else 0) + PRESSURE_SALT
	var best: float = _fitness(_dna)
	for _gen in generations:
		var challenger: CritterDNA = _mutated(_dna, rng)
		var score: float = _fitness(challenger)
		if score > best:
			best = score
			_dna = challenger
		else:
			_dna.generation += 1

func _mutated(src: CritterDNA, rng: RandomNumberGenerator) -> CritterDNA:
	var child: CritterDNA = src.duplicate(true) as CritterDNA
	for gene_name in GENE_RANGE:
		if rng.randf() > MUTATION_RATE:
			continue
		var span: Array = GENE_RANGE[gene_name]
		var lo: float = float(span[0])
		var hi: float = float(span[1])
		var cur: float = float(child.get(gene_name))
		var nudge: float = rng.randf_range(-MUTATION_STEP, MUTATION_STEP) * (hi - lo)
		child.set(gene_name, clampf(cur + nudge, lo, hi))
	child.generation = src.generation + 1
	return child

func _norm(v: float, lo: float, hi: float) -> float:
	if absf(hi - lo) < 0.0001:
		return 0.0
	return clampf((v - lo) / (hi - lo), 0.0, 1.0)

## The taste. Each value weights the SAME six readings differently — nothing here
## reads a gene the sliders do not already expose.
func _fitness(d: CritterDNA) -> float:
	var depth: float = _norm(d.segments, 2.0, 10.0)
	var forks: float = _norm(d.symmetry, 1.0, 8.0)
	var angle: float = _norm(d.branch_angle, 15.0, 90.0)
	var taper: float = _norm(d.branch_decay, 0.3, 0.9)
	var leaves: float = d.leaf_density
	var droop: float = d.part_curve
	match pressure:
		"reach":
			return depth * 2.0 + (1.0 - angle) * 2.0 + (1.0 - droop) + taper * 0.5
		"spread":
			return angle * 2.0 + forks * 1.5 + droop + depth * 0.5
		"thicket":
			return depth * 2.0 + forks * 1.5 + leaves * 1.5 + taper * 0.5
		"spare":
			return (1.0 - depth) * 1.5 + (1.0 - forks) * 1.5 \
				+ (1.0 - leaves) * 1.5 + (1.0 - taper)
	return 0.0

# ── UI construction ──────────────────────────────────────────────

func _build_ui() -> void:
	if bench != "bare":
		var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")

		# Build rows: 2 columns of 4 sliders each, then a button row
		var row1 := []
		var row2 := []
		for i in GENE_SLIDERS.size():
			var def: Array = GENE_SLIDERS[i]
			var entry := {"type": "slider_h", "label": def[1], "default": def[2]}
			if i < 4:
				row1.append(entry)
			else:
				row2.append(entry)

		_control_panel = RackTpl.create_panel("GENETIC TREE", [
			row1,
			row2,
			[
				{"type": "button", "label": "RANDOM"},
				{"type": "button", "label": "PLANT"},
			],
		])
		_control_panel.position = Vector3(0, 0.85, 1.2)
		_control_panel.rotation_degrees = Vector3(-25, 0, 0)
		add_child(_control_panel)

		# Wire up sliders
		for i in GENE_SLIDERS.size():
			var gene_name: String = GENE_SLIDERS[i][0]
			var slider = _control_panel.find_child("Param_%d" % i, true, false)
			if slider:
				_sliders[gene_name] = slider
				slider.slider_moved.connect(_on_slider_moved.bind(gene_name))

		# Wire up buttons
		var rand_btn = _control_panel.find_child("Btn_0", true, false)
		if rand_btn:
			var area = rand_btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(func(_b): _on_randomize())

		var export_btn = _control_panel.find_child("Btn_1", true, false)
		if export_btn:
			var area2 = export_btn.get_node_or_null("InteractableAreaButton")
			if area2:
				area2.button_pressed.connect(func(_b): _on_export_dna())

	# Pedestal for tree preview
	var pedestal := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.6
	cyl.height = 0.05
	pedestal.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.35)
	mat.roughness = 0.8
	pedestal.material_override = mat
	add_child(pedestal)
	pedestal.position = Vector3(0.0, 0.0, 0.0)

# ── Slider → DNA ─────────────────────────────────────────────────

func _on_slider_moved(_value: float, gene_name: String) -> void:
	_apply_slider_to_dna(gene_name)
	_rebuild_queued = true
	_rebuild_timer = REBUILD_COOLDOWN

func _apply_slider_to_dna(gene_name: String) -> void:
	var slider: Node3D = _sliders[gene_name]
	var n: float = slider.get_normalized_value()
	match gene_name:
		"segments":
			_dna.segments = lerpf(2.0, 10.0, n)
		"symmetry":
			_dna.symmetry = lerpf(1.0, 8.0, n)
		"branch_angle":
			_dna.branch_angle = lerpf(15.0, 90.0, n)
		"branch_decay":
			_dna.branch_decay = lerpf(0.3, 0.9, n)
		"leaf_density":
			_dna.leaf_density = n
		"part_curve":
			_dna.part_curve = n
		"part_twist":
			_dna.part_twist = lerpf(-45.0, 45.0, n)
		"phyllotaxis":
			_dna.phyllotaxis = n

func _sync_sliders_from_dna() -> void:
	for gene_name in _sliders:
		var slider: Node3D = _sliders[gene_name]
		var n: float = 0.5
		match gene_name:
			"segments":
				n = inverse_lerp(2.0, 10.0, _dna.segments)
			"symmetry":
				n = inverse_lerp(1.0, 8.0, _dna.symmetry)
			"branch_angle":
				n = inverse_lerp(15.0, 90.0, _dna.branch_angle)
			"branch_decay":
				n = inverse_lerp(0.3, 0.9, _dna.branch_decay)
			"leaf_density":
				n = _dna.leaf_density
			"part_curve":
				n = _dna.part_curve
			"part_twist":
				n = inverse_lerp(-45.0, 45.0, _dna.part_twist)
			"phyllotaxis":
				n = _dna.phyllotaxis
		slider.set_normalized_value(clampf(n, 0.0, 1.0))

# ── Tree building ────────────────────────────────────────────────

func _rebuild_tree() -> void:
	if _tree_root:
		_tree_root.queue_free()
		_tree_root = null

	_tree_root = Node3D.new()
	add_child(_tree_root)
	_tree_root.position = Vector3(0.0, 0.05, 0.0)

	TreeMorphology.build(_dna, _tree_root, _mapper, 2)

# ── Actions ──────────────────────────────────────────────────────

func _on_randomize() -> void:
	_dna = CritterDNA.random_kingdom(0)
	_evolve()
	_sync_sliders_from_dna()
	_rebuild_tree()

func _on_export_dna() -> void:
	# Store designed DNA globally so the branching catalyst can read it
	Engine.set_meta("sculptor_tree_dna", _dna)
	# Visual feedback: brief flash
	if _tree_root:
		var tween := create_tween()
		tween.tween_property(_tree_root, "scale", Vector3(1.1, 1.1, 1.1), 0.15)
		tween.tween_property(_tree_root, "scale", Vector3.ONE, 0.15)

# ── Grid system integration ──────────────────────────────────────
#
# GUARDED. A key only counts when its value actually differs from the one held,
# and the regrow only fires after _ready has built once — the shipped version
# regrew the whole tree on the mere PRESENCE of dna_seed. All five placements
# (LSystems_Living, Corridor_LSystems_Living, Curation_Bay_lsystems_2 and the two
# AutoGenTest maps) are bare tokens that pass none of these keys.
func apply_grid_config(config_data: Dictionary) -> void:
	var regrow: bool = false

	if config_data.has("dna_seed"):
		var s: int = int(config_data["dna_seed"])
		if s != dna_seed:
			dna_seed = s
			regrow = true

	if config_data.has("pressure"):
		var w: String = str(config_data["pressure"]).to_lower()
		if PRESSURES.has(w) and w != pressure:
			pressure = w
			regrow = true

	if config_data.has("generations"):
		var g: int = clampi(int(config_data["generations"]), 0, 120)
		if g != generations:
			generations = g
			# A round count is inert while no pressure is applied, but it must not
			# cancel a regrow another key already earned.
			if pressure != "none":
				regrow = true

	if not regrow or not _ready_done:
		return

	_dna = CritterDNA.random_kingdom(0, dna_seed)
	_evolve()
	_sync_sliders_from_dna()
	_rebuild_tree()
