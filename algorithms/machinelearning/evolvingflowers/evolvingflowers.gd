extends Node3D

# @identity
# essence: genome = {petals, color_hue, symmetry, L-system_rules, branch_angle}; fitness = symmetry + vibrancy + complexity
# desire: watch a garden of flowers evolve toward beauty — petals deepen in color, branching patterns elaborate
# critical_parameter: mutation_rate — shapes how quickly the aesthetic drifts; too high and beauty dissolves
# triggers: generation_time timer breeds new population; elite flowers survive; growth animation springs flowers up
# emerges: L-system branching patterns, color preferences, symmetry — an aesthetic nobody programmed
# needs: VR controls [missing] — generation_time and mutation_rate exported but no spatial sliders
# relationships: depends on 9_3_smart_rockets_vr (shared GA pattern); unlocks evolved_creatures (from flowers to creatures)
# truth: beauty is what survives selection — aesthetics can be an emergent property of optimization

## Evolving Flowers — a genetic algorithm that breeds flowers via L-System branching,
## petal geometry, and colour genes. Each generation is evaluated for aesthetic fitness
## (symmetry, colour vibrancy, branching complexity) and the best survive to breed.
#
# ── STAGE-2 DNA — ONE AXIS: `selection` ──────────────────────────────────────
#
# calculate_fitness() below is one of the most explicit statements of taste in the
# project: more petals better, longer petals better, symmetry better, hue near 0.8
# better, vivid better, more L-system iterations better — with explicit penalties
# past petal_count 10 and branch_count 50. That taste is authored, unattributed, and
# until now unfalsifiable in a still, because the still was always of the generation
# BEFORE selection had happened: a random gen-0 bed, every placement, forever.
#
# `selection` states in geometry what a pressure DID to this population — and
# whether any pressure was applied at all.
#
#   drift    the shipped gen-0 bed: 16 randomised genomes, 4 x 4 at 3.0 m pitch on
#            the 20 m plane. No pressure applied yet. The default and the
#            pre-promotion look — now drawn from a SEEDED generator, so two builds
#            are the same bed rather than two samples of a distribution.
#   uniform  16 copies of the fitness function's own stated optimum. A regimented
#            purple bed 9 m across in which the aesthetic the code rewards has
#            already won and nothing else remains.
#   culled   three of that optimum standing on the 4 x 4 pattern with 13 plots bare,
#            so the 20 m plane reads as an abandoned trial rather than a garden.
#   runaway  16 flowers pushed PAST the code's own penalty thresholds — petal_count
#            11, petal_length 1.5, 2.5 m stems, 4 L-system iterations (256 branch
#            segments, well over the 50 the fitness function punishes). Beauty
#            carried until the fitness function starts subtracting from it.
#   split    eight 3-petal yellow flowers on 1.0 m stems filling the -x half, eight
#            10-petal purple flowers on 2.4 m stems filling the +x half, the 3.0 m
#            pitch gap empty between two incompatible tastes.
#
# NOT AN AXIS: generation_time. It is a 3-to-30-second clock. A rate cannot be
# photographed, and sweeping it produces sixteen random flowers every time.
#
# The four non-drift values are PAST-TENSE claims, so they hold still: only `drift`
# runs the generational loop in _process. A live GA would overwrite a stated outcome
# eight seconds after spawn and turn the map token into a lie.

const POPULATION_SIZE = 16
@export_range(3.0, 30.0) var generation_time: float = 8.0
@export_range(0.01, 0.5) var mutation_rate_export: float = 0.15:
	set(v):
		mutation_rate_export = v
const MUTATION_RATE = 0.15  # Still used by FlowerGenome.mutate()
const ELITE_COUNT = 2

## What a selection pressure did to this population — and whether any pressure was
## applied at all. Read in _ready() before the bed is planted.
@export_enum("drift", "uniform", "culled", "runaway", "split") var selection: String = "drift"

const SELECTIONS: PackedStringArray = ["drift", "uniform", "culled", "runaway", "split"]

## Every random draw in the build path comes from this seed. Fixed, so two builds of
## one value are the same bed down to the petal — an unseeded draw here would make
## the pixel critic read noise as signal.
const BUILD_SEED: int = 20260730

## The three plots left standing under `culled`. Scattered on the diagonal, not a
## tidy row, so what is left reads as survivors on an abandoned plot grid rather
## than as a smaller, neater garden.
const CULLED_PLOTS: PackedInt32Array = [0, 6, 11]

## The rule the three authored tableaux use. It is one of the five options
## randomize_genome() already draws from, not a new grammar — four F per iteration,
## so `runaway` at 4 iterations is 256 branch segments and the branch_count > 50
## penalty genuinely bites.
const TABLEAU_RULE: String = "F[+F][-F]F"

## The five rule options, lifted to script scope so the seeded drift builder draws
## from exactly the list FlowerGenome.randomize_genome() uses.
const RULE_OPTIONS: PackedStringArray = [
	"F[+F]F[-F]F",
	"F[+F][-F]F",
	"FF[+F][-F]",
	"F[++F][--F]F",
	"F[+F][F][-F]",
]

var generation := 0
var timer := 0.0
var current_population := []
var fitness_scores := []
var _info_label: Label3D  # Floating generation display
var _best_fitness_ever: float = 0.0

## Build state. `_env_built` keeps ground, sky, light and the readout label out of
## the rebuild path: by the time a config key arrives, LabelFramer has already
## plated that label, and rebuilding it would throw the plate away and leave naked
## glyphs hanging over the bed.
var _built: bool = false
var _env_built: bool = false
var _rng := RandomNumberGenerator.new()

## `emissive` is not an axis — curation_station hands every artifact it curates
## {"emissive": false}. Petals, flower centres and the L-system's mini petals all
## glow; these are the materials that carry it, so the key can be honoured in place.
var _emissive: bool = true
var _emissive_mats: Array = []

class FlowerGenome:
	var petal_count: int = 5
	var petal_length: float = 1.0
	var petal_width: float = 0.5
	var petal_curve: float = 0.0
	var center_size: float = 0.3
	var color_hue: float = 0.0
	var color_saturation: float = 0.8
	var color_value: float = 1.0
	var stem_height: float = 1.5
	var leaf_size: float = 0.5
	var symmetry: float = 1.0
	var fitness: float = 0.0

	# L-System parameters for branching
	var lsystem_axiom: String = "F"
	var lsystem_rules: Dictionary = {"F": "F[+F]F[-F]F"}
	var lsystem_iterations: int = 2
	var branch_angle: float = 25.0
	var branch_length_decay: float = 0.7
	
	func _init() -> void:
		randomize_genome()
	
	func randomize_genome() -> void:
		petal_count = randi() % 8 + 3  # 3-10 petals
		petal_length = randf_range(0.5, 1.5)
		petal_width = randf_range(0.2, 0.8)
		petal_curve = randf_range(-0.3, 0.3)
		center_size = randf_range(0.2, 0.5)
		color_hue = randf()
		color_saturation = randf_range(0.6, 1.0)
		color_value = randf_range(0.7, 1.0)
		stem_height = randf_range(1.0, 2.5)
		leaf_size = randf_range(0.3, 0.8)
		symmetry = randf_range(0.8, 1.0)

		# Randomize L-System parameters
		lsystem_iterations = randi() % 3 + 1  # 1-3 iterations
		branch_angle = randf_range(15.0, 45.0)
		branch_length_decay = randf_range(0.5, 0.8)

		# Random L-System rule selection
		var rule_options = [
			"F[+F]F[-F]F",
			"F[+F][-F]F",
			"FF[+F][-F]",
			"F[++F][--F]F",
			"F[+F][F][-F]"
		]
		lsystem_rules = {"F": rule_options[randi() % rule_options.size()]}
	
	func crossover(other: FlowerGenome) -> FlowerGenome:
		var child = FlowerGenome.new()
		# Uniform crossover
		child.petal_count = self.petal_count if randf() < 0.5 else other.petal_count
		child.petal_length = lerp(self.petal_length, other.petal_length, randf())
		child.petal_width = lerp(self.petal_width, other.petal_width, randf())
		child.petal_curve = lerp(self.petal_curve, other.petal_curve, randf())
		child.center_size = lerp(self.center_size, other.center_size, randf())
		child.color_hue = lerp(self.color_hue, other.color_hue, randf())
		child.color_saturation = lerp(self.color_saturation, other.color_saturation, randf())
		child.color_value = lerp(self.color_value, other.color_value, randf())
		child.stem_height = lerp(self.stem_height, other.stem_height, randf())
		child.leaf_size = lerp(self.leaf_size, other.leaf_size, randf())
		child.symmetry = lerp(self.symmetry, other.symmetry, randf())

		# L-System crossover
		child.lsystem_iterations = self.lsystem_iterations if randf() < 0.5 else other.lsystem_iterations
		child.branch_angle = lerp(self.branch_angle, other.branch_angle, randf())
		child.branch_length_decay = lerp(self.branch_length_decay, other.branch_length_decay, randf())
		child.lsystem_rules = self.lsystem_rules if randf() < 0.5 else other.lsystem_rules

		return child
	
	func mutate() -> void:
		if randf() < MUTATION_RATE:
			petal_count = clampi(petal_count + (randi() % 3 - 1), 3, 12)
		if randf() < MUTATION_RATE:
			petal_length = clamp(petal_length + randf_range(-0.2, 0.2), 0.3, 2.0)
		if randf() < MUTATION_RATE:
			petal_width = clamp(petal_width + randf_range(-0.1, 0.1), 0.1, 1.0)
		if randf() < MUTATION_RATE:
			petal_curve = clamp(petal_curve + randf_range(-0.1, 0.1), -0.5, 0.5)
		if randf() < MUTATION_RATE:
			center_size = clamp(center_size + randf_range(-0.05, 0.05), 0.1, 0.7)
		if randf() < MUTATION_RATE:
			color_hue = fmod(color_hue + randf_range(-0.1, 0.1), 1.0)
		if randf() < MUTATION_RATE:
			color_saturation = clamp(color_saturation + randf_range(-0.1, 0.1), 0.3, 1.0)
		if randf() < MUTATION_RATE:
			color_value = clamp(color_value + randf_range(-0.1, 0.1), 0.5, 1.0)
		if randf() < MUTATION_RATE:
			stem_height = clamp(stem_height + randf_range(-0.2, 0.2), 0.5, 3.0)
		if randf() < MUTATION_RATE:
			leaf_size = clamp(leaf_size + randf_range(-0.1, 0.1), 0.2, 1.0)
		if randf() < MUTATION_RATE:
			symmetry = clamp(symmetry + randf_range(-0.05, 0.05), 0.7, 1.0)

		# L-System mutations
		if randf() < MUTATION_RATE:
			lsystem_iterations = clampi(lsystem_iterations + (randi() % 3 - 1), 1, 4)
		if randf() < MUTATION_RATE:
			branch_angle = clamp(branch_angle + randf_range(-5.0, 5.0), 10.0, 60.0)
		if randf() < MUTATION_RATE:
			branch_length_decay = clamp(branch_length_decay + randf_range(-0.1, 0.1), 0.4, 0.9)
		if randf() < MUTATION_RATE * 0.5:  # Rarer mutation
			var rule_options = [
				"F[+F]F[-F]F",
				"F[+F][-F]F",
				"FF[+F][-F]",
				"F[++F][--F]F",
				"F[+F][F][-F]"
			]
			lsystem_rules = {"F": rule_options[randi() % rule_options.size()]}

class Flower:
	var genome: FlowerGenome
	var root_node: Node3D
	var flower_head: Node3D
	var petals: Array = []
	var position: Vector3
	var age: float = 0.0
	
	func _init(g: FlowerGenome, pos: Vector3) -> void:
		genome = g
		position = pos

func _ready() -> void:
	_build_all()
	_built = true


## SYNCHRONOUS, from @export values alone. The sweep sets `selection` before the node
## enters the tree and never calls apply_grid_config, so the whole bed has to be
## standing by the time _ready() returns.
func _build_all() -> void:
	if not _env_built:
		setup_environment()
		_env_built = true
	initialize_population()

func setup_environment() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.0
	light.shadow_enabled = true
	add_child(light)
	
	var ambient := WorldEnvironment.new()
	ambient.environment = Environment.new()
	ambient.environment.background_mode = Environment.BG_SKY
	ambient.environment.sky = Sky.new()
	ambient.environment.sky.sky_material = ProceduralSkyMaterial.new()
	(ambient.environment.sky.sky_material as ProceduralSkyMaterial).sky_top_color = Color(0.4, 0.6, 1.0)
	(ambient.environment.sky.sky_material as ProceduralSkyMaterial).sky_horizon_color = Color(0.7, 0.8, 1.0)
	(ambient.environment.sky.sky_material as ProceduralSkyMaterial).ground_bottom_color = Color(0.2, 0.3, 0.2)
	ambient.environment.sky.sky_material.ground_horizon_color = Color(0.4, 0.5, 0.3)
	ambient.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	ambient.environment.ambient_light_energy = 0.5
	add_child(ambient)
	
	# Ground plane
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	ground.mesh = plane
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.3, 0.5, 0.2)
	ground.material_override = ground_mat
	ground.position.y = -0.01
	add_child(ground)
	
	var camera := Camera3D.new()
	camera.position = Vector3(0, 8, 12)
	camera.look_at_from_position(camera.position, Vector3(0, 1, 0), Vector3.UP)
	add_child(camera)
	
	# Floating stats label
	_info_label = Label3D.new()
	_info_label.text = "Evolving Flowers — Generation 0"
	_info_label.font_size = 36
	_info_label.position = Vector3(0, 5, -5)
	_info_label.modulate = Color(1.0, 0.85, 0.2)
	_info_label.outline_modulate = Color(0, 0, 0, 0.5)
	_info_label.outline_size = 4
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_info_label)

func initialize_population() -> void:
	# One seed for the whole bed, reset at the top of every build: the drift genomes
	# and the per-petal symmetry jitter both draw from here, in this order.
	_rng.seed = BUILD_SEED
	for entry in _population_plan():
		var genome: FlowerGenome = entry["genome"]
		var plot: int = entry["plot"]
		current_population.append(spawn_flower(genome, _plot_position(plot)))
	# Say what the taste makes of this bed, now, in the readout. Before this the label
	# carried its title until the first generation eight seconds later, so no still
	# ever showed a fitness number — the artifact's whole claim, unphotographed.
	calculate_fitness()
	update_generation_label()


## The shipped 4 x 4 bed: 3.0 m pitch, 9 m across, centred on the 20 m plane.
func _plot_position(index: int) -> Vector3:
	var col: int = index % 4
	var row: int = int(index / 4.0)
	return Vector3((col - 1.5) * 3.0, 0.0, (row - 1.5) * 3.0)


## Which genome stands in which plot, per axis value. Every value returns a different
## population — nothing here falls through to a shared builder.
func _population_plan() -> Array:
	var plan: Array = []
	match selection:
		"uniform":
			# The aesthetic the code rewards has already won: sixteen of its winner.
			for i in range(POPULATION_SIZE):
				plan.append({"genome": _optimum_genome(), "plot": i})
		"culled":
			# Same winner, three of it, thirteen plots bare.
			for i in CULLED_PLOTS:
				plan.append({"genome": _optimum_genome(), "plot": int(i)})
		"runaway":
			# The same taste carried past the point where its own author flinched
			# and started subtracting.
			for i in range(POPULATION_SIZE):
				plan.append({"genome": _runaway_genome(), "plot": i})
		"split":
			# Columns 0 and 1 are the -x half, columns 2 and 3 the +x half; the 3.0 m
			# pitch between x = -1.5 and x = 1.5 is the empty centre.
			for i in range(POPULATION_SIZE):
				plan.append({"genome": _split_genome((i % 4) < 2), "plot": i})
		_:
			# drift — no pressure has been applied yet.
			for i in range(POPULATION_SIZE):
				plan.append({"genome": _drift_genome(), "plot": i})
	return plan


## The shipped gen-0 genome: exactly randomize_genome()'s ranges — 3 to 10 petals,
## hues around the whole wheel, 1.0 to 2.5 m stems — drawn from the seeded generator
## instead of the global one, so the bed is one fixed bed instead of a new sample
## every boot.
func _drift_genome() -> FlowerGenome:
	var g := FlowerGenome.new()
	g.petal_count = _rng.randi_range(3, 10)
	g.petal_length = _rng.randf_range(0.5, 1.5)
	g.petal_width = _rng.randf_range(0.2, 0.8)
	g.petal_curve = _rng.randf_range(-0.3, 0.3)
	g.center_size = _rng.randf_range(0.2, 0.5)
	g.color_hue = _rng.randf()
	g.color_saturation = _rng.randf_range(0.6, 1.0)
	g.color_value = _rng.randf_range(0.7, 1.0)
	g.stem_height = _rng.randf_range(1.0, 2.5)
	g.leaf_size = _rng.randf_range(0.3, 0.8)
	g.symmetry = _rng.randf_range(0.8, 1.0)
	g.lsystem_iterations = _rng.randi_range(1, 3)
	g.branch_angle = _rng.randf_range(15.0, 45.0)
	g.branch_length_decay = _rng.randf_range(0.5, 0.8)
	g.lsystem_rules = {"F": RULE_OPTIONS[_rng.randi_range(0, RULE_OPTIONS.size() - 1)]}
	return g


## What calculate_fitness() says it wants, read straight off its own arithmetic:
## 8 petals (the most it does not punish, minus a margin), hue 0.8, saturation 1.0,
## symmetry 1.0, 2.0 m stems, 3 L-system iterations, ~30 degree branch angles,
## gradual decay. Note that 3 iterations of a four-F rule is already 64 branches, so
## the code's stated optimum trips the code's own branch_count > 50 penalty — the
## taste contradicts itself, and the readout now prints the number that says so.
func _optimum_genome() -> FlowerGenome:
	var g := FlowerGenome.new()
	g.petal_count = 8
	g.petal_length = 1.0
	g.petal_width = 0.5
	g.petal_curve = 0.0
	g.center_size = 0.3
	g.color_hue = 0.8
	g.color_saturation = 1.0
	g.color_value = 1.0
	g.stem_height = 2.0
	g.leaf_size = 0.5
	g.symmetry = 1.0
	g.lsystem_iterations = 3
	g.branch_angle = 30.0
	g.branch_length_decay = 0.8
	g.lsystem_rules = {"F": TABLEAU_RULE}
	return g


## The optimum carried past every threshold the fitness function penalises: 11 petals
## (over the 10 it punishes), 1.5 m petals on 2.5 m stems, fat petals well clear of
## the thin-petal penalty, and 4 iterations for 256 branch segments against a ceiling
## of 50. Heads overlap their 3.0 m plots — beauty pushed until it costs.
func _runaway_genome() -> FlowerGenome:
	var g := FlowerGenome.new()
	g.petal_count = 11
	g.petal_length = 1.5
	g.petal_width = 0.8
	g.petal_curve = 0.25
	g.center_size = 0.4
	g.color_hue = 0.8
	g.color_saturation = 1.0
	g.color_value = 1.0
	g.stem_height = 2.5
	g.leaf_size = 0.8
	g.symmetry = 1.0
	g.lsystem_iterations = 4
	g.branch_angle = 30.0
	g.branch_length_decay = 0.75
	g.lsystem_rules = {"F": TABLEAU_RULE}
	return g


## Two tastes that could not be reconciled, one per half of the bed. West: small,
## three-petalled, yellow, short-stemmed, barely branched. East: ten-petalled,
## purple, tall, elaborate — the fitness function's own preference. Nothing in
## between, because nothing in between survived.
func _split_genome(west: bool) -> FlowerGenome:
	var g := FlowerGenome.new()
	if west:
		g.petal_count = 3
		g.petal_length = 0.7
		g.petal_width = 0.35
		g.petal_curve = 0.0
		g.center_size = 0.25
		g.color_hue = 0.15
		g.color_saturation = 1.0
		g.color_value = 1.0
		g.stem_height = 1.0
		g.leaf_size = 0.4
		g.symmetry = 1.0
		g.lsystem_iterations = 1
		g.branch_angle = 20.0
		g.branch_length_decay = 0.6
	else:
		g.petal_count = 10
		g.petal_length = 1.3
		g.petal_width = 0.7
		g.petal_curve = 0.15
		g.center_size = 0.35
		g.color_hue = 0.8
		g.color_saturation = 1.0
		g.color_value = 1.0
		g.stem_height = 2.4
		g.leaf_size = 0.7
		g.symmetry = 1.0
		g.lsystem_iterations = 3
		g.branch_angle = 30.0
		g.branch_length_decay = 0.8
	g.lsystem_rules = {"F": TABLEAU_RULE}
	return g

func spawn_flower(genome: FlowerGenome, pos: Vector3) -> Flower:
	var flower = Flower.new(genome, pos)
	
	flower.root_node = Node3D.new()
	flower.root_node.position = pos
	add_child(flower.root_node)
	
	# Stem
	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.05
	stem_mesh.bottom_radius = 0.08
	stem_mesh.height = genome.stem_height
	stem.mesh = stem_mesh
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.2, 0.5, 0.1)
	stem_mat.roughness = 0.9
	stem_mat.metallic = 0.0
	stem.material_override = stem_mat
	stem.position.y = genome.stem_height / 2
	flower.root_node.add_child(stem)
	
	# Leaves
	for i in range(2):
		var leaf := MeshInstance3D.new()
		var leaf_mesh := create_leaf_mesh(genome.leaf_size)
		leaf.mesh = leaf_mesh
		var leaf_mat := StandardMaterial3D.new()
		leaf_mat.albedo_color = Color(0.3, 0.6, 0.2)
		leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		leaf.material_override = leaf_mat
		var leaf_height = genome.stem_height * (0.3 + i * 0.3)
		leaf.position = Vector3(0, leaf_height, 0)
		leaf.rotation_degrees.y = i * 180
		leaf.rotation_degrees.z = 45
		flower.root_node.add_child(leaf)
	
	# Flower head container
	flower.flower_head = Node3D.new()
	flower.flower_head.position.y = genome.stem_height
	flower.root_node.add_child(flower.flower_head)
	
	# Center
	var center := MeshInstance3D.new()
	var center_mesh := SphereMesh.new()
	center_mesh.radius = genome.center_size
	center_mesh.height = genome.center_size * 2
	center_mesh.radial_segments = 16
	center_mesh.rings = 8
	center.mesh = center_mesh
	var center_mat := StandardMaterial3D.new()
	center_mat.albedo_color = Color(0.9, 0.7, 0.2)
	center_mat.emission_enabled = _emissive
	center_mat.emission = Color(0.9, 0.7, 0.2) * 0.3
	center.material_override = center_mat
	_emissive_mats.append(center_mat)
	flower.flower_head.add_child(center)

	# Petals — ONE mesh and ONE material for the whole head. Every petal used to build
	# its own identical ArrayMesh and its own identical material; sharing them is
	# pixel-identical and is what keeps `runaway` (256 branch segments x 16 flowers)
	# inside a single synchronous _ready() instead of stalling a capture.
	var petal_color = Color.from_hsv(genome.color_hue, genome.color_saturation, genome.color_value)
	var petal_mesh: ArrayMesh = create_petal_mesh(genome)
	var petal_mat := StandardMaterial3D.new()
	petal_mat.albedo_color = petal_color
	petal_mat.emission_enabled = _emissive
	petal_mat.emission = petal_color * 0.2
	petal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_emissive_mats.append(petal_mat)
	for i in range(genome.petal_count):
		var angle = (float(i) / genome.petal_count) * TAU
		var petal := MeshInstance3D.new()
		petal.mesh = petal_mesh
		petal.material_override = petal_mat

		# Position with symmetry variation — from the SEEDED generator, so a flower
		# that is imperfect is imperfect the same way in every build.
		var symmetry_offset = _rng.randf_range(-1.0 + genome.symmetry, 1.0 - genome.symmetry) * 0.1
		petal.rotation.y = angle + symmetry_offset
		petal.position = Vector3(0, 0, 0)

		flower.flower_head.add_child(petal)
		flower.petals.append(petal)

	# L-System branching structure
	var lsystem_container = Node3D.new()
	lsystem_container.rotation_degrees.x = 90  # Point branches outward
	flower.flower_head.add_child(lsystem_container)
	create_lsystem_branches(genome, lsystem_container, petal_color)

	# Growth animation — flowers spring up from the ground
	flower.root_node.scale = Vector3(0.01, 0.01, 0.01)
	var grow_tween = create_tween()
	grow_tween.tween_property(flower.root_node, "scale", Vector3.ONE, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	return flower

func create_petal_mesh(genome: FlowerGenome) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	
	# Create petal shape
	var segments = 8
	for i in range(segments + 1):
		var t = float(i) / segments
		var width = sin(t * PI) * genome.petal_width
		var length = t * genome.petal_length
		var curve = sin(t * PI) * genome.petal_curve
		
		vertices.append(Vector3(-width, curve, length + genome.center_size))
		vertices.append(Vector3(width, curve, length + genome.center_size))
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
	
	for i in range(segments):
		var base = i * 2
		indices.append(base)
		indices.append(base + 2)
		indices.append(base + 1)
		indices.append(base + 1)
		indices.append(base + 2)
		indices.append(base + 3)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_leaf_mesh(size: float) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	# Simple leaf shape
	vertices.append(Vector3(0, 0, 0))
	vertices.append(Vector3(-size * 0.3, 0, size * 0.5))
	vertices.append(Vector3(0, 0, size))
	vertices.append(Vector3(size * 0.3, 0, size * 0.5))

	for i in range(4):
		normals.append(Vector3.UP)

	indices.append(0)
	indices.append(1)
	indices.append(2)
	indices.append(0)
	indices.append(2)
	indices.append(3)

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

# L-System Generation
func generate_lsystem_string(genome: FlowerGenome) -> String:
	var result = genome.lsystem_axiom
	for i in range(genome.lsystem_iterations):
		var next_result = ""
		for c in result:
			if genome.lsystem_rules.has(c):
				next_result += genome.lsystem_rules[c]
			else:
				next_result += c
		result = next_result
	return result

func create_lsystem_branches(genome: FlowerGenome, parent: Node3D, petal_color: Color) -> void:
	var lstring = generate_lsystem_string(genome)
	var position = Vector3.ZERO
	var direction = Vector3.UP
	var length = genome.petal_length * 0.3

	var stack = []  # Stack for push/pop operations

	# One mini-petal mesh and one mini-petal material for the whole branching
	# structure. Both were being rebuilt per F: identical every time, and at 256 F
	# (the `runaway` value) that was 256 ArrayMeshes and 256 materials per flower.
	var mini_mesh: ArrayMesh = create_petal_mesh(genome)
	var mini_mat := StandardMaterial3D.new()
	mini_mat.albedo_color = petal_color
	mini_mat.emission_enabled = _emissive
	mini_mat.emission = petal_color * 0.3
	mini_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_emissive_mats.append(mini_mat)

	for c in lstring:
		match c:
			"F":  # Draw forward
				var end_pos = position + direction * length
				var branch = create_branch_segment(position, end_pos, length * 0.05, petal_color)
				parent.add_child(branch)

				# Add small petal at end
				var mini_petal = MeshInstance3D.new()
				mini_petal.mesh = mini_mesh
				mini_petal.scale = Vector3.ONE * 0.3
				mini_petal.position = end_pos
				mini_petal.material_override = mini_mat
				parent.add_child(mini_petal)

				position = end_pos
				length *= genome.branch_length_decay

			"+":  # Rotate right
				direction = direction.rotated(Vector3.FORWARD, deg_to_rad(genome.branch_angle))

			"-":  # Rotate left
				direction = direction.rotated(Vector3.FORWARD, deg_to_rad(-genome.branch_angle))

			"[":  # Push state
				stack.append({"pos": position, "dir": direction, "len": length})

			"]":  # Pop state
				if stack.size() > 0:
					var state = stack.pop_back()
					position = state.pos
					direction = state.dir
					length = state.len

func create_branch_segment(start: Vector3, end: Vector3, thickness: float, color: Color) -> MeshInstance3D:
	var branch = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = thickness
	mesh.bottom_radius = thickness * 1.2
	mesh.height = start.distance_to(end)
	branch.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color.darkened(0.3)
	branch.material_override = mat

	branch.position = (start + end) / 2.0
	# Only orient if positions are different (with tolerance)
	var distance = start.distance_to(end)
	if distance > 0.001:  # Use distance check instead of is_equal_approx
		branch.look_at_from_position(branch.position, end, Vector3.RIGHT)
		branch.rotate_object_local(Vector3.RIGHT, PI / 2)

	return branch

func _process(delta: float) -> void:
	timer += delta
	
	# Animate flowers
	for flower in current_population:
		flower.age += delta
		if flower.flower_head:
			flower.flower_head.rotation.y += delta * 0.2
			var bob = sin(flower.age * 2.0) * 0.05
			flower.flower_head.position.y = flower.genome.stem_height + bob
	
	# Only the shipped `drift` bed runs the generational loop. The other four values
	# are past-tense claims about a pressure that has already been applied; a live GA
	# would overwrite the stated outcome eight seconds after spawn and make the map
	# token a lie about the room it is standing in.
	if selection == "drift" and timer >= generation_time:
		evolve_population()
		timer = 0.0

func evolve_population() -> void:
	generation += 1
	print("\n=== Generation ", generation, " ===")
	
	# Calculate fitness
	calculate_fitness()
	
	# Sort by fitness
	var genomes_with_fitness = []
	for i in range(current_population.size()):
		genomes_with_fitness.append({
			"genome": current_population[i].genome,
			"fitness": fitness_scores[i]
		})
	genomes_with_fitness.sort_custom(func(a, b): return a.fitness > b.fitness)
	
	print("Best fitness: ", genomes_with_fitness[0].fitness)
	print("Average fitness: ", fitness_scores.reduce(func(a, b): return a + b, 0.0) / fitness_scores.size())
	
	# Clear old flowers
	for flower in current_population:
		if flower.root_node:
			flower.root_node.queue_free()
	current_population.clear()
	fitness_scores.clear()
	
	# Create new generation
	var new_genomes = []
	
	# Elitism - keep best
	for i in range(ELITE_COUNT):
		new_genomes.append(genomes_with_fitness[i].genome)
	
	# Breed the rest
	while new_genomes.size() < POPULATION_SIZE:
		var parent1 = select_parent(genomes_with_fitness)
		var parent2 = select_parent(genomes_with_fitness)
		var child = parent1.crossover(parent2)
		child.mutate()
		new_genomes.append(child)
	
	# Spawn new generation
	for i in range(POPULATION_SIZE):
		var flower = spawn_flower(new_genomes[i], _plot_position(i))
		current_population.append(flower)
	
	update_generation_label()

func calculate_fitness() -> void:
	fitness_scores.clear()
	for flower in current_population:
		var genome = flower.genome
		var fitness = 0.0

		# Reward specific traits
		fitness += genome.petal_count * 2.0  # More petals = better
		fitness += genome.petal_length * 10.0  # Longer petals = better
		fitness += genome.symmetry * 15.0  # Symmetry = better
		fitness += (1.0 - abs(genome.color_hue - 0.8)) * 20.0  # Prefer purple/pink hues
		fitness += genome.color_saturation * 10.0  # Vivid colors = better

		# L-System fitness rewards
		fitness += genome.lsystem_iterations * 8.0  # More complex = better
		fitness += (1.0 - abs(genome.branch_angle - 30.0) / 30.0) * 10.0  # Prefer ~30 degree angles
		fitness += genome.branch_length_decay * 5.0  # Reward gradual decay

		# Calculate L-System complexity
		var lstring = generate_lsystem_string(genome)
		var branch_count = lstring.count("F")
		fitness += min(branch_count, 20) * 0.5  # Reward branching up to a limit

		# Penalty for extreme values
		if genome.petal_count > 10:
			fitness -= 10.0
		if genome.petal_width < 0.3:
			fitness -= 5.0
		if branch_count > 50:  # Too many branches
			fitness -= 15.0

		flower.genome.fitness = fitness
		fitness_scores.append(fitness)

func select_parent(genomes_with_fitness: Array) -> FlowerGenome:
	# Tournament selection
	var tournament_size = 3
	var best = null
	var best_fitness = -INF
	
	for i in range(tournament_size):
		var candidate = genomes_with_fitness[randi() % genomes_with_fitness.size()]
		if candidate.fitness > best_fitness:
			best_fitness = candidate.fitness
			best = candidate.genome
	
	return best

func update_generation_label() -> void:
	if _info_label:
		var best = fitness_scores.max() if fitness_scores.size() > 0 else 0.0
		var avg = (fitness_scores.reduce(func(a, b): return a + b, 0.0) / fitness_scores.size()) if fitness_scores.size() > 0 else 0.0
		_best_fitness_ever = max(_best_fitness_ever, best)
		_info_label.text = "Generation %d | Best %.1f | Avg %.1f | Record %.1f" % [generation, best, avg, _best_fitness_ever]
		# Pulse the label on new generation
		var pulse_tw = create_tween()
		pulse_tw.tween_property(_info_label, "modulate:a", 1.0, 0.0)
		pulse_tw.tween_property(_info_label, "modulate:a", 0.5, 0.15)
		pulse_tw.tween_property(_info_label, "modulate:a", 1.0, 0.15)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Map tokens: #selection:uniform, #selection:runaway, ...
##
## GridInteractablesComponent calls this via call_deferred, AFTER _ready() has already
## planted the default bed, so this is a change-detected REBUILD and never the first
## build. curation_station hands every artifact it curates {"emissive": false} one line
## after framing its labels: that dict carries no axis key, so it must leave the
## geometry exactly as it stands — hence the snapshot and the early return.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_selection: String = selection
	if config_data.has("selection"):
		selection = _pick_axis(str(config_data["selection"]), SELECTIONS, selection)

	# Non-geometry, applied IN PLACE and before the returns — an accepted key that
	# does nothing is worse than a key that was never accepted.
	if config_data.has("emissive"):
		_emissive = _to_bool(config_data["emissive"], _emissive)
		_apply_emissive()

	if not _built:
		return
	if selection == before_selection:
		return
	_rebuild_now()
	print("[EvolvingFlowers] Config applied — selection=%s" % [selection])


## Accept an axis value only if it names a population this artifact actually plants.
## A typo has to land on the shipped look rather than on an empty plot grid.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _to_bool(raw: Variant, fallback: bool) -> bool:
	if raw is bool:
		return bool(raw)
	if raw is int or raw is float:
		return float(raw) != 0.0
	var s: String = str(raw).to_lower().strip_edges()
	if s in ["true", "1", "on", "yes"]:
		return true
	if s in ["false", "0", "off", "no"]:
		return false
	return fallback


## Petals, flower centres and the L-system's mini petals glow by default. Turning that
## off is a material change, not a geometry change, so it happens on the standing bed.
func _apply_emissive() -> void:
	for m in _emissive_mats:
		if m is StandardMaterial3D:
			(m as StandardMaterial3D).emission_enabled = _emissive


## SYNCHRONOUS. No call_deferred anywhere in the build path: a deferred rebuild that
## removes children first makes the grid's auto-grounding measure a zero AABB and bail.
##
## Frees ONLY the flower roots this script planted. The ground plane, sky, light and
## the readout label stay — they are not part of the axis, and the label already
## carries the plate LabelFramer gave it at spawn.
func _rebuild_now() -> void:
	for flower in current_population:
		if flower.root_node != null and is_instance_valid(flower.root_node):
			remove_child(flower.root_node)
			flower.root_node.queue_free()
	current_population.clear()
	fitness_scores.clear()
	_emissive_mats.clear()
	generation = 0
	timer = 0.0
	_best_fitness_ever = 0.0
	initialize_population()
