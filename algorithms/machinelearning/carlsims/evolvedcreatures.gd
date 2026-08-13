extends Node3D

## Carl Sims-inspired Evolved Creatures.
## A population of bipedal creatures evolve their gait parameters (hip amplitude,
## frequency, phase) through genetic algorithms. Fitness is measured by forward
## locomotion distance. The best creatures pass their genes to the next generation.
##
## STAGE-2 DNA — `selection`.
## The argument this artifact exists to make is that a fitness function is somebody's
## decision about what a good animal is. That argument used to be unphotographable:
## GENERATION_DURATION is a 20-second constant, the gait is a sine of elapsed time and
## the evolution happens in _physics_process, so a still shows a random gen-0 herd
## standing in a tidy 5 x 4 grid no matter which pressure is applied. The axis converts
## the OUTCOME of a pressure into an ARRANGEMENT plus a body plan, both set at spawn and
## neither dependent on the clock: a comet tail of bodies is a fitness landscape laid on
## the floor, four survivors on a 40 m plate is a cull, two ranks 14 m apart is a
## speciation event. `runaway` earns the axis, because the code already carries the
## clamps (amplitude 0.3-2.5, torso mass 2.0-8.0) that exist to stop the pressure it
## models, and pinning the population at those ceilings shows what the fitness function
## wanted before the clamps stopped it.


const POPULATION_SIZE: int = 20
const GENERATION_DURATION: float = 20.0
const HIP_LIMIT: float = 0.9
const HIP_MAX_TORQUE: float = 50.0
const CREATURE_SPACING: float = 7.0
const ROOT_HEIGHT: float = 2.2
const FLOOR_EXTENT: float = 40.0
const MUTATION_STD: float = 0.25

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA AXIS
# ═══════════════════════════════════════════════════════════════════

## What a selection pressure did to this population — and whether any pressure was
## applied at all.
##   drift    the unselected gen-0 spread: 20 wild bipeds in the shipped 5 x 4 grid
##   uniform  one converged genome copied 20 times; nothing left to tell them apart
##   culled   four survivors of that converged form at the grid's four corners
##   runaway  the population pinned at the genome's own clamp ceilings, strung out
##            along +X in a comet tail spaced by the distance each one earned
##   split    two ranks 14 m apart across z, short-legged and long-legged morphs,
##            the centre of the floor bare
@export_enum("drift", "uniform", "culled", "runaway", "split") var selection: String = "drift"

## The allow-list. A value outside it is a typo in a map token and falls back to the
## legacy look rather than stranding a placement with no population at all.
const SELECTIONS: PackedStringArray = ["drift", "uniform", "culled", "runaway", "split"]

# Body plans. WILD is the shipped hard-coded pair, kept to the millimetre so `drift`
# renders the pre-promotion look exactly. Every other value binds extents to the
# genome, a binding this artifact did not have — torso and leg boxes were literals and
# only the masses ever varied, which is precisely why the axis was invisible in a still.
const TORSO_SIZE_WILD: Vector3 = Vector3(0.70, 0.40, 0.50)
const LEG_SIZE_WILD: Vector3 = Vector3(0.25, 0.80, 0.30)
const TORSO_SIZE_CONVERGED: Vector3 = Vector3(0.62, 0.36, 0.45)
const LEG_SIZE_CONVERGED: Vector3 = Vector3(0.25, 1.15, 0.30)
const TORSO_SIZE_RUNAWAY: Vector3 = Vector3(0.95, 0.55, 0.68)
const LEG_SIZE_RUNAWAY: Vector3 = Vector3(0.25, 2.50, 0.30)
const LEG_SIZE_SPLIT_SHORT: Vector3 = Vector3(0.25, 0.45, 0.30)
const LEG_SIZE_SPLIT_LONG: Vector3 = Vector3(0.25, 1.60, 0.30)

## Metres of air under the feet at spawn. Derived from the shipped numbers, not chosen:
## ROOT_HEIGHT 2.2 - torso half 0.20 - leg 0.80 = 1.20. Holding it constant is what
## keeps a 2.50 m leg from spawning through the floor, and it is why the tallest
## runaway body tops out at 4.25 m instead of hanging below the plate.
const FOOT_CLEARANCE: float = 1.2

## Hip inset. Shipped offset was a literal 0.4 with a 0.70 torso and a 0.25 leg:
## 0.35 + 0.125 - 0.075. Expressed as a rule so wider torsos keep their legs under
## them, and so `drift` reproduces 0.4 exactly.
const HIP_INSET: float = 0.075

## Masses follow volume at the shipped density (4.5 kg over the 0.140 m³ torso,
## 2.0 kg over the 0.060 m³ leg), then meet the same clamps _mutate uses. At runaway
## both clamps bite — 0.3553 m³ x 32 = 11.4 kg lands on the 8.0 ceiling the spec names,
## and the leg lands on 4.0. The ceilings are the point of that value.
const TORSO_DENSITY: float = 32.0
const LEG_DENSITY: float = 33.0
const TORSO_MASS_MIN: float = 2.0
const TORSO_MASS_MAX: float = 8.0
const LEG_MASS_MIN: float = 0.8
const LEG_MASS_MAX: float = 4.0

## Converged gait — deterministic constants, never drawn. A converged population has
## no spread by definition, so there is nothing here for an RNG to do.
const CONVERGED_AMPLITUDE: float = 1.35
const CONVERGED_FREQUENCY: float = 1.05

## The clamp ceilings from _mutate, quoted as constants so `runaway` is visibly sitting
## on them rather than near them.
const CEIL_AMPLITUDE: float = 2.5
const CEIL_FREQUENCY: float = 2.0

## culled: the four corner slots of the shipped 5 x 4 grid — 28.0 m apart in x
## (-14 / +14) and 21.0 m in z (-7 / +14), sixteen plots left empty on a 40 m floor.
const CULLED_SLOTS: PackedInt32Array = [0, 4, 15, 19]

## runaway: a tail from x = -6 to x = +18. The rank exponent makes the gaps grow with
## rank (each body spaced by the distance it earned) and the three lanes fan out at the
## head and converge on the leader, so the herd reads as a tail and not as a queue.
const RUNAWAY_X_START: float = -6.0
const RUNAWAY_X_END: float = 18.0
const RUNAWAY_TAIL_POWER: float = 1.5
const RUNAWAY_FAN: float = 1.7

## split: two ranks of ten, 14.0 m apart across z, at half the grid pitch so 10 bodies
## still land on the 40 m floor (x -15.75 .. +15.75).
const SPLIT_RANK_Z: float = 7.0
const SPLIT_PITCH: float = 3.5
const SPLIT_RANK_SIZE: int = 10

## Hold every body where the axis put it, instead of letting it fall the 1.2 m of
## FOOT_CLEARANCE before the shutter opens. FALSE IS THE SHIPPED BEHAVIOUR and a map that
## does not set this is untouched. Set only by the capture bench, via dna.fixture — see
## the note in _create_body for what it is holding still and what it is NOT fixing.
@export var freeze_bodies: bool = false
@export var random_seed: int = 20241103
@export var enable_random_restart: bool = false
@export var enable_debug_prints: bool = true

@onready var camera: Camera3D = $Camera3D
@onready var light: DirectionalLight3D = $DirectionalLight3D

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _population: Array[CreatureInstance] = []
var _timer: float = 0.0
var _generation: int = 0
var _status_label: Label3D = null
var _best_fitness_ever: float = 0.0

## Lifecycle bookkeeping. `_owned` holds every node THIS script added — freeing
## get_children() would destroy the grid's own added plates and the scene's camera.
var _built: bool = false
var _owned: Array[Node] = []
var _body_materials: Array[StandardMaterial3D] = []
var _emissive: bool = true
var _active_count: int = POPULATION_SIZE

class CreatureGenome:
	var hip_amplitude: PackedFloat32Array = PackedFloat32Array([1.0, 1.0])
	var hip_frequency: PackedFloat32Array = PackedFloat32Array([1.0, 1.0])
	var hip_phase: PackedFloat32Array = PackedFloat32Array([0.0, PI])
	var torso_mass: float = 4.0
	var leg_mass: float = 2.0
	## Body extents now live in the genome. Defaults are the shipped literals, so a
	## genome nobody has applied a pressure to builds the legacy body.
	var torso_size: Vector3 = Vector3(0.70, 0.40, 0.50)
	var leg_size: Vector3 = Vector3(0.25, 0.80, 0.30)
	var fitness: float = 0.0

	func randomize(rng: RandomNumberGenerator) -> void:
		for i in range(2):
			hip_amplitude[i] = rng.randf_range(0.6, 1.8)
			hip_frequency[i] = rng.randf_range(0.6, 1.4)
			hip_phase[i] = rng.randf_range(0.0, TAU)
		torso_mass = rng.randf_range(3.0, 6.0)
		leg_mass = rng.randf_range(1.2, 3.0)
		fitness = 0.0

	func duplicate() -> CreatureGenome:
		var copy := CreatureGenome.new()
		copy.hip_amplitude = hip_amplitude.duplicate()
		copy.hip_frequency = hip_frequency.duplicate()
		copy.hip_phase = hip_phase.duplicate()
		copy.torso_mass = torso_mass
		copy.leg_mass = leg_mass
		copy.torso_size = torso_size
		copy.leg_size = leg_size
		copy.fitness = fitness
		return copy

class CreatureInstance:
	var genome: CreatureGenome
	var bodies: Array[RigidBody3D] = []
	var joints: Array[HingeJoint3D] = []
	var start_position: Vector3 = Vector3.ZERO
	var elapsed: float = 0.0

# ═══════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════

func _ready() -> void:
	_build_all()
	_built = true

## SYNCHRONOUS, from @export values alone — the sweep sets `selection` before the node
## enters the tree and never calls apply_grid_config, so everything must happen here.
func _build_all() -> void:
	selection = _pick_axis(selection, SELECTIONS, "drift")
	# DETERMINISM: a fresh generator seeded from the fixed constant on every build, so
	# two builds of one axis value are pixel-identical.
	_rng = RandomNumberGenerator.new()
	_rng.seed = random_seed
	_active_count = CULLED_SLOTS.size() if selection == "culled" else POPULATION_SIZE
	_generation = 0
	_timer = 0.0
	_best_fitness_ever = 0.0
	_build_ground()
	_create_status_label()
	spawn_initial_population()

func _rebuild_now() -> void:
	var doomed: Array[Node] = _owned.duplicate()
	for c in doomed:
		if is_instance_valid(c):
			if c.get_parent() == self:
				remove_child(c)
			c.queue_free()
	_owned.clear()
	_population.clear()
	_body_materials.clear()
	_status_label = null
	_build_all()

## Track everything this script parents, so a rebuild can free exactly its own work.
func _own(node: Node) -> void:
	add_child(node)
	_owned.append(node)

func _release(node: Node) -> void:
	if not is_instance_valid(node):
		return
	_owned.erase(node)
	if node.get_parent() == self:
		remove_child(node)
	node.queue_free()

# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

## The one caption. Left exactly where it was authored: (0, 6.0, 0), billboard ENABLED,
## font_size 48 at the default pixel_size 0.005. The framer turns it into a ~1.24 x
## 0.31 m plate with a 1.30 x 0.37 m bezel whose underside sits at 5.83 m; the tallest
## body any value builds is the runaway torso top at 4.25 m, so frontal crossing is 0
## at all five values. No value may spawn a body above y = 5.0 m — that is the only way
## this plate could be reached.
func _create_status_label() -> void:
	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 48
	_status_label.modulate = Color(1.0, 0.85, 0.2)
	_status_label.outline_modulate = Color(0, 0, 0, 0.6)
	_status_label.outline_size = 4
	_status_label.position = Vector3(0, 6, 0)
	_status_label.text = "Generation 0 | Evolving…"
	_own(_status_label)

func _build_ground() -> void:
	var floor := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(FLOOR_EXTENT, 0.4, FLOOR_EXTENT)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	floor.add_child(collider)
	var mesh_instance := MeshInstance3D.new()
	var plane_mesh := BoxMesh.new()
	plane_mesh.size = shape.size
	mesh_instance.mesh = plane_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.24, 0.26, 1.0)
	mat.roughness = 0.85
	mat.metallic = 0.05
	mesh_instance.material_override = mat
	floor.add_child(mesh_instance)
	floor.position = Vector3(0, -0.2, 0)
	_own(floor)

func spawn_initial_population() -> void:
	_clear_population()
	for idx in range(_active_count):
		var genome := _genome_for(idx)
		var pos := _layout_position(idx)
		var creature := _spawn_creature(genome, pos)
		_population.append(creature)
	_generation = 0
	_timer = 0.0

# ─── genomes per value ───────────────────────────────────────────────

## The pressure's trait is written into the body. Without that the axis cannot be
## photographed: at frame zero every gait is at rest and all 20 animals look identical.
func _genome_for(index: int) -> CreatureGenome:
	var genome := CreatureGenome.new()
	if selection == "drift":
		# Untouched: the same draws in the same order as the shipped build.
		genome.randomize(_rng)
		return genome
	match selection:
		"runaway":
			genome.hip_amplitude = PackedFloat32Array([CEIL_AMPLITUDE, CEIL_AMPLITUDE])
			genome.hip_frequency = PackedFloat32Array([CEIL_FREQUENCY, CEIL_FREQUENCY])
		_:
			genome.hip_amplitude = PackedFloat32Array([CONVERGED_AMPLITUDE, CONVERGED_AMPLITUDE])
			genome.hip_frequency = PackedFloat32Array([CONVERGED_FREQUENCY, CONVERGED_FREQUENCY])
	genome.hip_phase = PackedFloat32Array([0.0, PI])
	_apply_morph(genome, index)
	return genome

## Re-impose the value's body plan and the masses that follow from it. A selection
## pressure is a standing condition, not a one-off, so this runs on every generation
## reset too — otherwise crossover would blend the two split morphs back into one.
func _apply_morph(genome: CreatureGenome, index: int) -> void:
	if selection == "drift":
		return
	genome.torso_size = _torso_size_for(index)
	genome.leg_size = _leg_size_for(index)
	genome.torso_mass = clampf(
		genome.torso_size.x * genome.torso_size.y * genome.torso_size.z * TORSO_DENSITY,
		TORSO_MASS_MIN, TORSO_MASS_MAX)
	genome.leg_mass = clampf(
		genome.leg_size.x * genome.leg_size.y * genome.leg_size.z * LEG_DENSITY,
		LEG_MASS_MIN, LEG_MASS_MAX)

func _torso_size_for(_index: int) -> Vector3:
	if selection == "runaway":
		return TORSO_SIZE_RUNAWAY
	if selection == "uniform" or selection == "culled" or selection == "split":
		return TORSO_SIZE_CONVERGED
	return TORSO_SIZE_WILD

func _leg_size_for(index: int) -> Vector3:
	if selection == "runaway":
		return LEG_SIZE_RUNAWAY
	if selection == "uniform" or selection == "culled":
		return LEG_SIZE_CONVERGED
	if selection == "split":
		if index < SPLIT_RANK_SIZE:
			return LEG_SIZE_SPLIT_SHORT
		return LEG_SIZE_SPLIT_LONG
	return LEG_SIZE_WILD

# ─── arrangement per value ───────────────────────────────────────────

## Feet at a constant 1.2 m of clearance whatever the leg length. drift resolves to
## exactly ROOT_HEIGHT (1.2 + 0.20 + 0.80 = 2.2).
func _root_height(torso: Vector3, leg: Vector3) -> float:
	return FOOT_CLEARANCE + torso.y * 0.5 + leg.y

func _layout_position(index: int) -> Vector3:
	if selection == "drift":
		return _grid_position(index)
	var y: float = _root_height(_torso_size_for(index), _leg_size_for(index))
	if selection == "culled":
		var slot: int = CULLED_SLOTS[index % CULLED_SLOTS.size()]
		return _grid_position_at(slot, y)
	if selection == "runaway":
		return _runaway_position(index, y)
	if selection == "split":
		return _split_position(index, y)
	# uniform — the shipped 5 x 4 grid at 7.0 m pitch, one genome twenty times over.
	return _grid_position_at(index, y)

func _grid_position(index: int) -> Vector3:
	return _grid_position_at(index, ROOT_HEIGHT)

func _grid_position_at(index: int, y: float) -> Vector3:
	var columns := 5
	var row := index / columns
	var col := index % columns
	var x := (col - (columns - 1) * 0.5) * CREATURE_SPACING
	var z := (row - 1.0) * CREATURE_SPACING
	return Vector3(x, y, z)

## A comet tail, not a grid. Rank 0 is the herd that went nowhere; rank 19 is the one
## the fitness function loved. Gaps grow with rank, and the three lanes fan out at the
## head and converge on the leader.
func _runaway_position(index: int, y: float) -> Vector3:
	var t: float = 0.0
	if _active_count > 1:
		t = float(index) / float(_active_count - 1)
	var span: float = RUNAWAY_X_END - RUNAWAY_X_START
	var x: float = RUNAWAY_X_START + span * pow(t, RUNAWAY_TAIL_POWER)
	var lane: float = float((index % 3) - 1)
	var z: float = lane * RUNAWAY_FAN * (1.0 - t)
	return Vector3(x, y, z)

## Two ranks of ten, 14.0 m apart across z, with the centre of the floor bare.
## One population that stopped being one.
func _split_position(index: int, y: float) -> Vector3:
	var col: int = index % SPLIT_RANK_SIZE
	var x: float = (float(col) - float(SPLIT_RANK_SIZE - 1) * 0.5) * SPLIT_PITCH
	var z: float = -SPLIT_RANK_Z if index < SPLIT_RANK_SIZE else SPLIT_RANK_Z
	return Vector3(x, y, z)

# ─── bodies ──────────────────────────────────────────────────────────

func _spawn_creature(genome: CreatureGenome, start_pos: Vector3) -> CreatureInstance:
	var instance := CreatureInstance.new()
	instance.genome = genome
	instance.start_position = start_pos
	var torso := _create_body(genome.torso_size, genome.torso_mass, Color(0.7, 0.5, 0.9, 1.0))
	torso.position = start_pos
	torso.name = "Torso"
	instance.bodies.append(torso)
	# Hips derived from the extents so legs stay under the torso at any body plan.
	var hip_dx: float = genome.torso_size.x * 0.5 + genome.leg_size.x * 0.5 - HIP_INSET
	var hip_dy: float = -(genome.torso_size.y * 0.5 + genome.leg_size.y * 0.5)
	for leg_idx in [0, 1]:
		var offset := Vector3(hip_dx if leg_idx == 0 else -hip_dx, hip_dy, 0.0)
		var leg := _create_body(genome.leg_size, genome.leg_mass, Color(0.4 + 0.3 * leg_idx, 0.85, 0.6, 1.0))
		leg.position = start_pos + offset
		leg.name = "Leg_%d" % leg_idx
		instance.bodies.append(leg)
		var joint := _create_hip_joint(torso, leg, offset, leg_idx)
		joint.set_meta("index", leg_idx)
		instance.joints.append(joint)
	return instance

func _create_body(size: Vector3, mass: float, colour: Color) -> RigidBody3D:
	## Creates a physics body with emissive, slightly metallic material
	var body := RigidBody3D.new()
	body.mass = mass
	body.linear_damp = 0.2
	body.angular_damp = 0.2
	body.can_sleep = false
	# HOLD THE POSE THE AXIS BUILT. Default false, so a map gets today's behaviour to the
	# byte; only the capture bench ever sets this, through dna.fixture.
	#
	# WHY IT IS NEEDED, measured rather than argued. Every body spawns with FOOT_CLEARANCE
	# = 1.2 m of air beneath it, and capture_config_sweep settles 1.1 s before the shutter.
	# Free fall of 1.2 m takes sqrt(2*1.2/9.8) = 0.495 s, so the herd lands at ~4.85 m/s
	# with the hip motors already driving, roughly 0.6 s before the frame exists. The
	# entire y-ladder this axis builds — root heights 1.83 / 2.20 / 2.53 / 2.98 / 3.98 m
	# across the five values — is gone by then. The artifact's own recorded measurement
	# agrees and nobody read it that way: aabb_size [40.0, 2.21, 40.0] with centre y 0.71
	# puts the top of everything at 1.815 m, BELOW drift's 2.400 m spawn torso top and far
	# below runaway's 4.250 m. That number was taken after the fall.
	#
	# AND THIS DOES NOT MAKE THE ARTIFACT CORRECT, it makes it PHOTOGRAPHABLE. What a
	# player meets is still the fallen herd, and bipeds that topple within a second of
	# spawning are a real defect in a walker demo. Recorded in the registry rather than
	# papered over here; the fix is the artifact's own, not the bench's.
	body.freeze = freeze_bodies
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.5
	mat.metallic = 0.15
	mat.emission_enabled = _emissive
	mat.emission = colour * 0.12
	mesh.material_override = mat
	_body_materials.append(mat)
	body.add_child(mesh)
	_own(body)
	return body

func _create_hip_joint(parent: RigidBody3D, child: RigidBody3D, offset: Vector3, leg_idx: int) -> HingeJoint3D:
	var joint := HingeJoint3D.new()
	joint.node_a = parent.get_path()
	joint.node_b = child.get_path()
	joint.position = parent.position + offset * 0.5
	joint.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0 if leg_idx == 0 else -90.0))
	joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, -HIP_LIMIT)
	joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, HIP_LIMIT)
	joint.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
	joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, HIP_MAX_TORQUE)
	_own(joint)
	return joint

# ═══════════════════════════════════════════════════════════════════
# SIMULATION
# ═══════════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	_timer += delta
	for creature in _population:
		creature.elapsed += delta
		for joint in creature.joints:
			var idx: int = int(joint.get_meta("index"))
			var amp := creature.genome.hip_amplitude[idx]
			var freq := creature.genome.hip_frequency[idx]
			var phase := creature.genome.hip_phase[idx]
			var target := amp * sin(creature.elapsed * freq + phase)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, target)
	if _timer >= GENERATION_DURATION:
		_evaluate_population()
		_evolve_generation()
		_timer = 0.0

func _evaluate_population() -> void:
	var gen_best: float = 0.0
	var gen_avg: float = 0.0
	for creature in _population:
		if creature.bodies.is_empty():
			creature.genome.fitness = 0.0
			continue
		var torso := creature.bodies[0]
		if not is_instance_valid(torso):
			creature.genome.fitness = 0.0
			continue
		var displacement := torso.global_position - creature.start_position
		var forward := displacement.x
		var distance := displacement.length()
		var height_bonus: float = max(0.0, torso.global_position.y - 1.0)
		creature.genome.fitness = forward * 2.0 + distance * 0.5 + height_bonus * 0.3
		gen_best = max(gen_best, creature.genome.fitness)
		gen_avg += creature.genome.fitness
		if enable_debug_prints:
			print("Generation %d fitness: %.2f" % [_generation, creature.genome.fitness])

	gen_avg /= max(1, _population.size())
	_best_fitness_ever = max(_best_fitness_ever, gen_best)

	# Highlight the best creature with a gold flash
	for creature in _population:
		if creature.genome.fitness >= gen_best and creature.bodies.size() > 0:
			var torso = creature.bodies[0]
			if is_instance_valid(torso):
				var mesh_child = torso.get_child(1) if torso.get_child_count() > 1 else null
				if mesh_child is MeshInstance3D and mesh_child.material_override is StandardMaterial3D:
					var mat = mesh_child.material_override as StandardMaterial3D
					var orig_emission = mat.emission
					mat.emission = Color(1.0, 0.85, 0.2) * 0.6
					var tw = create_tween()
					tw.tween_property(mat, "emission", orig_emission, 1.5)
			break

	# Update HUD
	if _status_label:
		_status_label.text = "Gen %d | Best %.1f | Avg %.1f | Record %.1f" % [_generation, gen_best, gen_avg, _best_fitness_ever]

func _evolve_generation() -> void:
	_generation += 1
	var genomes: Array[CreatureGenome] = []
	for creature in _population:
		genomes.append(creature.genome)
	genomes.sort_custom(func(a: CreatureGenome, b: CreatureGenome): return a.fitness > b.fitness)
	var parents: Array[CreatureGenome] = []
	var keep: int = min(2, genomes.size())
	for i in range(keep):
		parents.append(genomes[i].duplicate())
	var offspring: Array[CreatureGenome] = parents.duplicate()
	while offspring.size() < _active_count:
		var mother := genomes[_rng.randi_range(0, min(4, genomes.size() - 1))]
		var father := genomes[_rng.randi_range(0, min(4, genomes.size() - 1))]
		var child := _crossover(mother, father)
		_mutate(child)
		offspring.append(child)
	_reset_population_with_genomes(offspring)

func _crossover(a: CreatureGenome, b: CreatureGenome) -> CreatureGenome:
	var child := CreatureGenome.new()
	for i in range(2):
		var t := _rng.randf_range(0.0, 1.0)
		child.hip_amplitude[i] = lerp(a.hip_amplitude[i], b.hip_amplitude[i], t)
		child.hip_frequency[i] = lerp(a.hip_frequency[i], b.hip_frequency[i], t)
		child.hip_phase[i] = lerp_angle(a.hip_phase[i], b.hip_phase[i], t)
	child.torso_mass = lerp(a.torso_mass, b.torso_mass, 0.5)
	child.leg_mass = lerp(a.leg_mass, b.leg_mass, 0.5)
	child.torso_size = a.torso_size.lerp(b.torso_size, 0.5)
	child.leg_size = a.leg_size.lerp(b.leg_size, 0.5)
	return child

func _mutate(genome: CreatureGenome) -> void:
	for i in range(2):
		if _rng.randf() < 0.5:
			genome.hip_amplitude[i] = clamp(genome.hip_amplitude[i] + _rng.randfn(0.0, MUTATION_STD), 0.3, 2.5)
		if _rng.randf() < 0.5:
			genome.hip_frequency[i] = clamp(genome.hip_frequency[i] + _rng.randfn(0.0, MUTATION_STD), 0.3, 2.0)
		if _rng.randf() < 0.5:
			genome.hip_phase[i] = wrapf(genome.hip_phase[i] + _rng.randfn(0.0, MUTATION_STD), 0.0, TAU)
	if _rng.randf() < 0.3:
		genome.torso_mass = clamp(genome.torso_mass + _rng.randfn(0.0, MUTATION_STD), TORSO_MASS_MIN, TORSO_MASS_MAX)
	if _rng.randf() < 0.3:
		genome.leg_mass = clamp(genome.leg_mass + _rng.randfn(0.0, MUTATION_STD), LEG_MASS_MIN, LEG_MASS_MAX)

func _reset_population_with_genomes(genomes: Array[CreatureGenome]) -> void:
	_clear_population()
	for idx in range(_active_count):
		var genome := genomes[idx % genomes.size()].duplicate()
		if enable_random_restart and idx >= genomes.size():
			genome.randomize(_rng)
		_apply_morph(genome, idx)
		var pos := _layout_position(idx)
		var creature := _spawn_creature(genome, pos)
		_population.append(creature)
	_timer = 0.0

func _clear_population() -> void:
	for creature in _population:
		for joint in creature.joints:
			_release(joint)
		for body in creature.bodies:
			_release(body)
	_population.clear()
	_body_materials.clear()

func _randfn(mean := 0.0, std_dev := 0.1) -> float:
	return _rng.randfn(mean, std_dev)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## Called via call_deferred AFTER _ready(). The build has already happened from the
## @export values, so this only has work to do when a map token actually names a
## different pressure. `emissive` is applied IN PLACE and never triggers a rebuild —
## curation_station hands {"emissive": false} to every artifact it curates and that
## dict carries no axis, so it must not disturb the population.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_selection: String = selection
	if config_data.has("selection"):
		selection = _pick_axis(str(config_data["selection"]), SELECTIONS, selection)
	if config_data.has("emissive"):
		_apply_emissive(bool(config_data["emissive"]))
	if not _built:
		return
	if selection == before_selection:
		return
	_rebuild_now()
	print("[EvolvedCreatures] Config applied — selection=%s, bodies=%d" % [selection, _active_count])

## Accept an axis value only if it names something we actually build. A typo in a map
## token falls back to the legacy look rather than leaving an empty floor.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback

## Non-geometry key, applied to the live materials on the spot. The materials are
## per-body instances built here, so nothing outside this artifact is touched.
func _apply_emissive(on: bool) -> void:
	_emissive = on
	for mat in _body_materials:
		if mat != null:
			mat.emission_enabled = on
