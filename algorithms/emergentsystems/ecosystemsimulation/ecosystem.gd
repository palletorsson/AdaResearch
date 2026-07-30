extends Node2D

# @identity
# essence: population(t+1) = reproduce(survive(eat(move(population(t))))) with DNA crossover and mutation at each birth — evolution in a closed box
# desire: to watch a predator-prey cycle spike and crash and recover — to feel the ecosystem breathe and realize no agent understands the cycle, only you can see it
# critical_parameter: mutation_rate — at 0 the ecosystem either freezes in its starting configuration or collapses; at 0.1 adaptation keeps prey one step ahead of predators indefinitely
# triggers: balance_ecosystem() acts as a hidden stabilizer that respawns prey below 10 and weakens predators when they outnumber prey by 2:1 — remove it and the system collapses in minutes
# emerges: prey develop faster flee_weight and higher perception_radius over generations without explicit selection pressure — predation IS the selection pressure
# needs: [partial] no VR controls at all; the quota axis now exposes the three population allotments as an @export, but mutation_rate and the stabiliser's own thresholds are still hardcoded
# relationships: synthesis artifact for the swarmintelligence sequence; combines local movement rules from boids with genetic memory from neuroevolution; previews machinelearning sequence's evolutionary algorithms
# truth: evolution has no goal — only the dead are wrong, and only the living get to try again

## Ecosystem simulation — 3D VR version.
## Prey, predators, and food rendered via MultiMeshInstance3D.

# ── Stage-2 DNA axis ───────────────────────────────────
## quota — who is allotted a place in the closed box, in what proportion, and
## whether the hidden stabiliser is topping anyone up.
##
##   tended  50 prey / 5 predators / 100 food — the shipped mix, exactly the one
##           balance_ecosystem() was tuned to hold. 155 bodies.
##   barren  50 / 5 / 4 — the same creatures with the green gone. 59 bodies,
##           prey with nothing to converge on.
##   hunted  50 / 24 / 60 — 134 bodies, red a fifth of the population instead of
##           a thirtieth. 24 sits one under the stabiliser's own prey/2 ceiling
##           so the referee does not fire during the capture window.
##   fallow  110 / 0 / 100 — 210 bodies, not one of them red. The predator-restock
##           clause is skipped here (see balance_ecosystem) or the value undoes
##           itself on the first _process frame.
##
## The registry declaration is generated from the @export_enum line below; the
## spelling and order there are the contract.
@export_enum("tended", "barren", "hunted", "fallow") var quota: String = "tended"

const QUOTAS: PackedStringArray = ["tended", "barren", "hunted", "fallow"]

## prey / predators / food, and whether the stabiliser is allowed to restock
## predators. Populations only — nothing here is a rate, because a still cannot
## hold a rate and everything else this artifact does is one.
const QUOTA_TABLE: Dictionary = {
	"tended": {"prey": 50, "pred": 5, "food": 100, "restock": true},
	"barren": {"prey": 50, "pred": 5, "food": 4, "restock": true},
	"hunted": {"prey": 50, "pred": 24, "food": 60, "restock": true},
	"fallow": {"prey": 110, "pred": 0, "food": 100, "restock": false},
}

## Every draw in this artifact comes off this stream, seeded from one constant.
## Never seed()/randomize() — that would reseed the whole process from inside one
## artifact. Creature._init only rolls its own random DNA when handed an empty
## dictionary, so the build path always hands it _make_dna() instead.
const BUILD_SEED: int = 20260730

# Ecosystem parameters — set from QUOTA_TABLE by _apply_quota()
var prey_population: int = 50
var predator_population: int = 5
var food_amount: int = 100
var mutation_rate: float = 0.1
var proximity_for_mating: float = 0.03

# Bounds (half-extents on X/Z, full height on Y)
const HALF_X: float = 0.4
const HALF_Z: float = 0.4
const HEIGHT: float = 0.4

# ── Caption ────────────────────────────────────────────
## Constant width, 28 characters at every quota value, so the framer's plate is
## the same size in all four tiles instead of growing when fallow's counts reach
## three digits. One label. Never one per creature — at 210 bodies per-agent
## plates would be an opaque wall where an ecosystem used to be.
const LABEL_FORMAT: String = "Prey %3d  Pred %3d  Food %3d"

## font_size 32 x pixel_size 0.001 = 0.032 m of text -> plate 0.59 x 0.102,
## bezel 0.65 x 0.162. Centred at y 0.54 the bezel spans 0.459..0.621, clear of
## the 0.40 m box ceiling (0.408 with the sphere radius) by 0.051 m. The old
## 0.45 put the bezel bottom at 0.369 — inside the body, a real crossing.
const LABEL_Y: float = 0.54

# Entity lists
var prey_list: Array = []
var predator_list: Array = []
var food_list: Array = []

# MultiMesh rendering
var prey_mm_instance: MultiMeshInstance3D
var predator_mm_instance: MultiMeshInstance3D
var food_mm_instance: MultiMeshInstance3D
var info_label: Label3D

# ── Build state ────────────────────────────────────────
var _built: bool = false
var _emissive: bool = false
var _restock_predators: bool = true
## Only nodes THIS script created. Freeing get_children() would destroy the
## grid-added label plates.
var _owned: Array = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Inner classes ────────────────────────────────────────

class EcoPrey extends Creature:
	func _init(pos: Vector3, dna_values: Dictionary = {}) -> void:
		super(pos, dna_values)

	func eat_food(nutrition: float) -> void:
		health += nutrition

class EcoPredator extends Creature:
	func _init(pos: Vector3, dna_values: Dictionary = {}) -> void:
		super(pos, dna_values)
		if dna.size() > 0:
			dna["max_speed"] = max(dna["max_speed"], 0.08)

	func eat_prey(_prey) -> void:
		health += 0.5

# Lifecycle ────────────────────────────────────────────

func _ready() -> void:
	# The sweep sets swept @exports and adds to the tree; it never sets meta and
	# never calls apply_grid_config. So the axis has to be read here.
	quota = _pick_axis(quota, QUOTAS, "tended")
	_build_all()
	_built = true

## Synchronous, from @export values alone, and it RETURNS. No await, no
## call_deferred, no while loop, no waiting for convergence: this sequence has a
## known headless hang class and a capture that never returns stalls the pipeline.
func _build_all() -> void:
	_apply_quota()
	# Assigning `seed` resets the stream. Do NOT also assign `state` — that would
	# overwrite the seeded state and make BUILD_SEED decorative.
	_rng.seed = BUILD_SEED

	_setup_multimeshes()
	_setup_label()

	# Prey first, then predators, then food — one stream, one order. tended,
	# barren and hunted therefore share the same 50 prey and the same first 5
	# predators, so barren really is "the shipped box with the green taken away"
	# rather than a different box that happens to have less food in it.
	for i in range(prey_population):
		spawn_prey(_random_pos(), _make_dna())

	for i in range(predator_population):
		spawn_predator(_random_pos(), _make_dna())

	spawn_food(food_amount)

	# The picture at the 1.1 s shot is the standing composition, not a settled
	# state we ran for — so push it into the multimeshes and the plate now.
	_sync_multimeshes()
	_apply_emissive()
	_update_label()

func _process(delta: float) -> void:
	if not _built:
		return

	update_prey(delta)
	update_predators(delta)

	# Periodically spawn food
	if _rng.randf() < 0.01:
		spawn_food(1)

	balance_ecosystem()
	_sync_multimeshes()
	_update_label()

func _exit_tree() -> void:
	for p in prey_list:
		if is_instance_valid(p):
			p.queue_free()
	for p in predator_list:
		if is_instance_valid(p):
			p.queue_free()
	for f in food_list:
		if is_instance_valid(f):
			f.queue_free()

# Setup ────────────────────────────────────────────────

func _setup_multimeshes() -> void:
	# Prey — blue spheres
	prey_mm_instance = MultiMeshInstance3D.new()
	var prey_mm = MultiMesh.new()
	prey_mm.transform_format = MultiMesh.TRANSFORM_3D
	prey_mm.use_colors = true
	var prey_mesh = SphereMesh.new()
	prey_mesh.radius = 0.008
	prey_mesh.height = 0.016
	prey_mm.mesh = prey_mesh
	prey_mm.instance_count = 0
	prey_mm_instance.multimesh = prey_mm
	add_child(prey_mm_instance)
	_owned.append(prey_mm_instance)

	# Predators — red boxes
	predator_mm_instance = MultiMeshInstance3D.new()
	var pred_mm = MultiMesh.new()
	pred_mm.transform_format = MultiMesh.TRANSFORM_3D
	pred_mm.use_colors = true
	var pred_mesh = BoxMesh.new()
	pred_mesh.size = Vector3(0.012, 0.012, 0.012)
	pred_mm.mesh = pred_mesh
	pred_mm.instance_count = 0
	predator_mm_instance.multimesh = pred_mm
	add_child(predator_mm_instance)
	_owned.append(predator_mm_instance)

	# Food — green spheres
	food_mm_instance = MultiMeshInstance3D.new()
	var food_mm = MultiMesh.new()
	food_mm.transform_format = MultiMesh.TRANSFORM_3D
	food_mm.use_colors = true
	var food_mesh = SphereMesh.new()
	food_mesh.radius = 0.004
	food_mesh.height = 0.008
	food_mm.mesh = food_mesh
	food_mm.instance_count = 0
	food_mm_instance.multimesh = food_mm
	add_child(food_mm_instance)
	_owned.append(food_mm_instance)

## One Label3D, billboard ENABLED, so LabelFramer plates it — which is correct
## here: the text floats in front of nothing, it does not lie on a surface of the
## artifact, so claiming the BILLBOARD_DISABLED exemption would be the dodge.
## It is placed ABOVE the box, not across it, and there is no second label to
## merge with.
func _setup_label() -> void:
	info_label = Label3D.new()
	info_label.position = Vector3(0.0, LABEL_Y, 0.0)
	info_label.font_size = 32
	info_label.pixel_size = 0.001
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(info_label)
	_owned.append(info_label)

# MultiMesh sync ───────────────────────────────────────

func _sync_multimeshes() -> void:
	# Prey
	var pmm = prey_mm_instance.multimesh
	pmm.instance_count = prey_list.size()
	for i in range(prey_list.size()):
		var p = prey_list[i]
		pmm.set_instance_transform(i, Transform3D(Basis(), p.position))
		pmm.set_instance_color(i, Color(0.2, 0.5, 0.8))

	# Predators
	var rmm = predator_mm_instance.multimesh
	rmm.instance_count = predator_list.size()
	for i in range(predator_list.size()):
		var p = predator_list[i]
		rmm.set_instance_transform(i, Transform3D(Basis(), p.position))
		rmm.set_instance_color(i, Color(0.8, 0.2, 0.2))

	# Food
	var fmm = food_mm_instance.multimesh
	fmm.instance_count = food_list.size()
	for i in range(food_list.size()):
		var f = food_list[i]
		fmm.set_instance_transform(i, Transform3D(Basis(), f.position))
		fmm.set_instance_color(i, Color(0.2, 0.8, 0.2))

func _update_label() -> void:
	if info_label == null:
		return
	info_label.text = LABEL_FORMAT % [
		prey_list.size(), predator_list.size(), food_list.size()]

# Simulation ───────────────────────────────────────────

func update_prey(delta: float) -> void:
	var prey_to_remove: Array = []

	for prey in prey_list:
		prey.update(delta)

		# Check for nearby food
		var food_eaten = null
		for food in food_list:
			var distance = prey.position.distance_to(food.position)
			if distance < prey.size + 0.005:
				prey.eat_food(food.nutrition)
				food_eaten = food
				break

		if food_eaten:
			food_list.erase(food_eaten)
			_owned.erase(food_eaten)
			food_eaten.queue_free()

		# Flee from predators
		var flee_force := Vector3.ZERO
		for predator in predator_list:
			var distance = prey.position.distance_to(predator.position)
			if distance < prey.dna["perception_radius"]:
				var flee = prey.flee(predator.position)
				flee_force += flee * prey.dna["flee_weight"]

		prey.apply_force(flee_force)

		if prey.can_reproduce() and _rng.randf() < prey.dna["reproduction_rate"] * delta:
			check_for_mate(prey)

		if prey.is_dead():
			prey_to_remove.append(prey)

	for prey in prey_to_remove:
		prey_list.erase(prey)
		_owned.erase(prey)
		prey.queue_free()

func update_predators(delta: float) -> void:
	var predators_to_remove: Array = []

	for predator in predator_list:
		predator.update(delta)

		var nearest_prey = null
		var min_distance: float = predator.dna["perception_radius"]

		for prey in prey_list:
			var distance = predator.position.distance_to(prey.position)
			if distance < min_distance:
				min_distance = distance
				nearest_prey = prey

		if nearest_prey:
			var seek_force = predator.seek(nearest_prey.position) * predator.dna["seek_weight"]
			predator.apply_force(seek_force)

			if min_distance < predator.size + nearest_prey.size:
				predator.eat_prey(nearest_prey)
				prey_list.erase(nearest_prey)
				_owned.erase(nearest_prey)
				nearest_prey.queue_free()

		if predator.can_reproduce() and _rng.randf() < predator.dna["reproduction_rate"] * delta:
			check_for_mate(predator, true)

		if predator.is_dead():
			predators_to_remove.append(predator)

	for predator in predators_to_remove:
		predator_list.erase(predator)
		_owned.erase(predator)
		predator.queue_free()

func check_for_mate(creature, is_predator: bool = false) -> void:
	var creature_list = predator_list if is_predator else prey_list

	for potential_mate in creature_list:
		if potential_mate == creature:
			continue

		var distance = creature.position.distance_to(potential_mate.position)
		if distance < proximity_for_mating and potential_mate.can_reproduce():
			var child_dna = crossover_dna(creature.dna, potential_mate.dna)
			child_dna = mutate_dna(child_dna)

			var spawn_pos = (creature.position + potential_mate.position) / 2.0
			if is_predator:
				spawn_predator(spawn_pos, child_dna)
			else:
				spawn_prey(spawn_pos, child_dna)

			creature.health -= 0.2
			potential_mate.health -= 0.2
			break

func crossover_dna(dna1: Dictionary, dna2: Dictionary) -> Dictionary:
	var child_dna := {}
	for key in dna1.keys():
		if _rng.randf() < 0.5:
			child_dna[key] = dna1[key]
		else:
			child_dna[key] = dna2[key]
	return child_dna

func mutate_dna(dna: Dictionary) -> Dictionary:
	var mutated_dna = dna.duplicate()
	for key in mutated_dna.keys():
		if _rng.randf() < mutation_rate:
			var mutation_amount = _rng.randf_range(-0.2, 0.2)
			mutated_dna[key] = max(0.001, mutated_dna[key] * (1.0 + mutation_amount))
	return mutated_dna

# Spawning ─────────────────────────────────────────────

func spawn_prey(pos: Vector3, dna_values: Dictionary = {}) -> EcoPrey:
	var prey = EcoPrey.new(pos, dna_values)
	prey_list.append(prey)
	add_child(prey)
	_owned.append(prey)
	return prey

func spawn_predator(pos: Vector3, dna_values: Dictionary = {}) -> EcoPredator:
	var predator = EcoPredator.new(pos, dna_values)
	predator_list.append(predator)
	add_child(predator)
	_owned.append(predator)
	return predator

func spawn_food(amount: int) -> void:
	for i in range(amount):
		var pos = _random_pos()
		var food = Food.new(pos)
		food_list.append(food)
		add_child(food)
		_owned.append(food)

## The referee. The blurb says predator and prey with no referee; this is the
## referee, and quota is what makes it visible as one.
func balance_ecosystem() -> void:
	if prey_list.size() < 10:
		for i in range(5):
			spawn_prey(_random_pos(), _make_dna())

	if predator_list.size() > prey_list.size() * 0.5:
		for predator in predator_list:
			predator.health -= 0.05

	# fallow allots nobody a predator place, so the stabiliser has no predator
	# quota to top up. Without this guard it spawns two predators on the very
	# first _process frame and the value no-ops inside 17 milliseconds.
	if _restock_predators and predator_list.size() < 2 and prey_list.size() > 20:
		for i in range(2):
			spawn_predator(_random_pos(), _make_dna())

# Helpers ──────────────────────────────────────────────

func _random_pos() -> Vector3:
	return Vector3(
		_rng.randf_range(-HALF_X, HALF_X),
		_rng.randf_range(0.0, HEIGHT),
		_rng.randf_range(-HALF_Z, HALF_Z))

## Creature._init rolls its own DNA off the GLOBAL stream when handed an empty
## dictionary. Handing it a full one instead is how this artifact stays
## pixel-identical between two builds of the same axis value: same ranges, same
## keys, seeded stream.
func _make_dna() -> Dictionary:
	return {
		"max_speed": _rng.randf_range(0.05, 0.15),
		"max_force": _rng.randf_range(0.005, 0.02),
		"size": _rng.randf_range(0.005, 0.015),
		"perception_radius": _rng.randf_range(0.05, 0.15),
		"lifespan": _rng.randf_range(10.0, 30.0),
		"reproduction_rate": _rng.randf_range(0.001, 0.005),
		"separation_weight": _rng.randf_range(1.0, 2.0),
		"alignment_weight": _rng.randf_range(1.0, 2.0),
		"cohesion_weight": _rng.randf_range(1.0, 2.0),
		"flee_weight": _rng.randf_range(1.0, 3.0),
		"seek_weight": _rng.randf_range(1.0, 3.0),
	}

func _apply_quota() -> void:
	var row: Dictionary = QUOTA_TABLE.get(quota, QUOTA_TABLE["tended"])
	prey_population = int(row["prey"])
	predator_population = int(row["pred"])
	food_amount = int(row["food"])
	_restock_predators = bool(row["restock"])

## Accept an axis value only if it names something this artifact actually builds.
## A typo in a map token falls back to the legacy look rather than stranding a
## placement on a population nobody declared.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback

## bool("false") is TRUE, which inverts the meaning of every JSON-authored flag.
func _as_bool(raw, fallback: bool) -> bool:
	match typeof(raw):
		TYPE_BOOL:
			return bool(raw)
		TYPE_INT, TYPE_FLOAT:
			return float(raw) != 0.0
		TYPE_STRING, TYPE_STRING_NAME:
			var v: String = str(raw).to_lower().strip_edges()
			if v == "true" or v == "1" or v == "yes" or v == "on":
				return true
			if v == "false" or v == "0" or v == "no" or v == "off" or v == "":
				return false
	return fallback

## emissive is applied IN PLACE — no rebuild, so it still bites after the
## early-return. Default false means no material_override at all, which is the
## shipped look byte for byte: the meshes carry no material today.
func _apply_emissive() -> void:
	var targets: Array = [prey_mm_instance, predator_mm_instance, food_mm_instance]
	for i in range(targets.size()):
		var mmi: MultiMeshInstance3D = targets[i]
		if mmi == null:
			continue
		if _emissive:
			var mat: StandardMaterial3D = StandardMaterial3D.new()
			mat.vertex_color_use_as_albedo = true
			mat.emission_enabled = true
			mat.emission = Color(1.0, 1.0, 1.0)
			mat.emission_energy_multiplier = 0.6
			mmi.material_override = mat
		else:
			mmi.material_override = null

# Grid config ──────────────────────────────────────────

## Called by GridInteractablesComponent via call_deferred, AFTER _ready().
## curation_station hands every curated artifact {"emissive": false} one line
## after framing its labels — no axis key, so that call must change nothing.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_quota: String = quota

	if config_data.has("quota"):
		quota = _pick_axis(str(config_data["quota"]), QUOTAS, quota)

	if config_data.has("emissive"):
		_emissive = _as_bool(config_data["emissive"], _emissive)
		_apply_emissive()

	if not _built:
		return
	if quota == before_quota:
		return

	_rebuild_now()
	print("[Ecosystem] Config applied — quota=%s (prey %d / pred %d / food %d)" % [
		quota, prey_population, predator_population, food_amount])

## Synchronous and inline. A deferred rebuild that removes children first makes
## auto-grounding measure a ZERO AABB and bail.
func _rebuild_now() -> void:
	for i in range(_owned.size()):
		var c: Node = _owned[i]
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()

	prey_list.clear()
	predator_list.clear()
	food_list.clear()
	prey_mm_instance = null
	predator_mm_instance = null
	food_mm_instance = null
	info_label = null

	_build_all()
