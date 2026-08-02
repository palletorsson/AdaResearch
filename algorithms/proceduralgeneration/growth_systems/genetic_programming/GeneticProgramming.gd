@tool
extends Node3D
class_name GeneticProgramming

# @identity
# essence: population[i].fitness = f(genome) -> select, crossover, mutate, repeat — evolution without a designer
# desire: to watch 3D creatures evolve in front of you, generation by generation, toward a fitness goal no individual understands
# critical_parameter: mutation_rate — too low and evolution stagnates, too high and good solutions dissolve; 0.3 is the edge of chaos (and INVISIBLE at auto_evolve:false, which is the default, because a still shows generation zero); alphabet — what the genome may say, which decides what evolution can ever reach (primitives | csg_tree | parametric | voxel); muster — how much of the population you are allowed to see (parade | champion | scatter)
# triggers: auto_evolve ticks generations on a timer; evolve_one_generation allows manual stepping; fitness_function selects the selection pressure
# emerges: creatures converge on similar body plans despite random initialization — convergent evolution from pure math
# needs: population grid display [has]; fitness labels [has]; auto-evolve timer [has]; VR selection pressure picker [missing]
# relationships: opener for proceduralgeneration sequence; contrasts with space_colonization_algorithm (evolution vs growth); genome_type spans primitives to L-systems
# truth: evolution does not design — it accumulates accidents that happen to survive

@export_group("Evolution Settings")
@export var population_size: int = 20
@export var max_generations: int = 50
@export var mutation_rate: float = 0.3
@export var crossover_rate: float = 0.7
@export var elitism_count: int = 2

@export_group("Genome Type")
@export_enum("Primitives", "CSG_Tree", "Parametric", "Voxel", "L_System") var genome_type: int = 0
@export var genome_complexity: int = 8
@export var max_depth: int = 4

@export_group("Fitness Goals")
@export var target_volume: float = 10.0
@export var target_height: float = 5.0
@export var symmetry_weight: float = 0.5
@export var smoothness_weight: float = 0.3
@export var complexity_weight: float = 0.2
@export_enum("Volume", "Height", "Symmetry", "Sphere", "Custom") var fitness_function: int = 0

@export_group("Visualization")
@export var show_population: bool = true
@export var show_best_only: bool = false
@export var arrange_in_grid: bool = true
@export var spacing: float = 6.0

@export_group("Evolution Control")
@export var auto_evolve: bool = false
@export var evolution_speed: float = 1.0
@export var evolve_one_generation: bool = false:
    set(value):
        if value:
            evolve_generation()
            evolve_one_generation = false
@export var reset_evolution: bool = false:
    set(value):
        if value:
            initialize_population()
            reset_evolution = false

# ─────────────────────────────────────────────────────────────────────────────
# DNA PROMOTION (2026-08-02). SELECTION, NOT INVENTION.
#
# This file carries 27 exports, the largest knob surface in this pass, and 25 of
# them are dials rather than claims. The job was to find which ones were already
# an unnamed axis and give it a name. Two were.
#
# TWENTY-FIVE REJECTED, AND WHY:
#   population_size, max_generations, mutation_rate, crossover_rate,
#   elitism_count — the whole Evolution Settings group is INVISIBLE here, and not
#     because it is subtle. auto_evolve defaults to FALSE, so what a still frame
#     of this artifact shows is generation ZERO: twenty random genomes that have
#     never been selected, crossed or mutated. mutation_rate is declared the
#     critical_parameter in the identity block above and it does not touch a
#     single pixel of the default frame. That is worth knowing and it is not an
#     axis.
#   fitness_function, target_volume, target_height, symmetry_weight,
#   complexity_weight — these only sort the population, so at generation zero
#     they reshuffle the same twenty creatures between the same twenty grid
#     slots and rewrite the labels. A permutation is not a claim.
#   smoothness_weight — declared and never read anywhere in this file. See the
#     latent-bug note; it is dead, not swept.
#   genome_complexity, max_depth, spacing, evolution_speed, auto_evolve,
#   evolve_one_generation, reset_evolution — quantities, timers and buttons.
#
# TWO PROMOTED:
#
#   alphabet   what the genome is allowed to SAY
#
#     primitives | csg_tree | parametric | voxel
#
#   This is genome_type, which has been sitting here as an unnamed @export_enum
#   of CamelCase ints since the file was written, and it is the deepest claim in
#   genetic programming: evolution cannot find what its representation cannot
#   express. Change the alphabet and you change the reachable universe, not the
#   search. Twenty creatures built of loose primitives and twenty built from an
#   L-system grammar are not the same population rendered differently — they are
#   two different spaces of possible bodies, and no amount of fitness pressure
#   moves one into the other.
#     primitives  loose spheres, boxes, cylinders and tori scattered in a cloud —
#                 body plans as heaps of parts. The legacy lineage.
#     csg_tree    union/subtract/intersect operations. SEE THE LATENT BUG NOTE:
#                 the phenotype builder for this branch is a stub and emits ONE
#                 triangle per gene, so its tiles are a few floating shards, not
#                 CSG solids. It is kept in the family because the branch exists
#                 and a truthful tile of a stub is better than a hidden one.
#     parametric  one continuous trigonometric surface per creature — ribboned
#                 sheets, where the genome is nine frequencies and phases.
#     voxel       a dense occupancy cloud, roughly 150 small cubes per creature
#                 on an 8x8x8 grid: bodies as matter rather than as parts.
#
#   THE FIFTH BRANCH IS NOT IN THE FAMILY, ON PURPOSE. genome_type 4 (L-System)
#   is the one I most wanted — a genome that is a SENTENCE rather than a bag of
#   parts is the sharpest possible contrast to `primitives` — and it cannot ship
#   until interpret_lsystem is repaired. It rotates the heading with
#   `direction.rotated(Vector3.UP, angle)` while the heading IS Vector3.UP
#   (lines 779 and 782), which is a no-op, so the turtle never turns: every
#   segment goes straight up through the last one, and create_branch_segment's
#   `look_at(end, Vector3.UP)` (line 804) then errors on a look direction
#   parallel to its up vector, once per segment. With rule "FF+[+F-F-F]-[-F+F+F]"
#   at up to 4 iterations that is 8^4 = 4096 cylinders per genome, built forty
#   times over (once per fitness evaluation, once per visualisation): ~160,000
#   MeshInstance3D and ~160,000 pushed errors for one tile. Adding it would have
#   published a stack of overlapping cylinders as evidence and quite possibly
#   stalled the capture. Declared as four values; the fifth is a repair, not a
#   value. See the latent-bug note.
#
#   muster     how much of the population you are allowed to look at
#
#     parade | champion | scatter
#
#   This is the Visualization group's three booleans, which are only ever set as
#   a group and have three meaningful combinations. The claim is epistemic and it
#   is the one the truth line is about — "evolution does not design, it
#   accumulates accidents that happen to survive". Nearly every published picture
#   of an evolutionary run shows the winner. The accidents that did not survive
#   are the actual mechanism and they are almost never in the frame.
#     parade    all twenty ranked into a lattice, fittest first, each wearing its
#               score. The legacy lineage. You can see the failures.
#     champion  the single best genome alone at the origin with one large label.
#               The standard scientific illustration, and the one that hides the
#               nineteen bodies the result was selected out of.
#     scatter   all twenty, unranked, strewn at random over the plot. The same
#               population as `parade` with the league table taken away.
#
# STRICTLY ADDITIVE. Both appliers are match blocks whose default arm is `pass`,
# so at alphabet="primitives" and muster="parade" not one property is written and
# _ready runs exactly the sequence it ran before. The RNG is discussed on
# population_seed below.
# ─────────────────────────────────────────────────────────────────────────────
@export_group("DNA")

## THE AXIS — what the genome is allowed to say. Selects genome_type, which is
## kept as the legacy int knob so nothing that already sets it breaks.
@export_enum("primitives", "csg_tree", "parametric", "voxel") var alphabet: String = "primitives"

## THE AXIS — how much of the population is shown. Selects the three
## Visualization booleans, which are only ever meaningful as a group.
@export_enum("parade", "champion", "scatter") var muster: String = "parade"

## The allow-lists a map token is checked against — the same words the two
## @export_enums declare, same spelling, same order.
const ALPHABETS: PackedStringArray = ["primitives", "csg_tree", "parametric", "voxel"]
const MUSTERS: PackedStringArray = ["parade", "champion", "scatter"]

## Determinism, and the precondition for this artifact being measurable at all.
## EVERY body in the initial population is rolled from the global RNG — gene
## counts, gene types, positions, rotations, scales, voxel occupancy, L-system
## rules — and Godot randomises that RNG at startup. So two boots of the same map
## produced twenty entirely different creatures, and any two frames of this
## artifact differed by 100% no matter what was or was not changed between them.
## An axis swept against that measures the dice and reports a confident result.
## -1 keeps the old behaviour EXACTLY (no seed call is made, so the stream is
## untouched); any value >= 0 pins the population. Note this seeds the GLOBAL
## stream, which is the only reach that covers the inner Gene/Genome classes too;
## the capture harness sets it through the registry's dna.fixture.
@export var population_seed: int = -1

# Genome classes
class Gene:
    var gene_type: String
    var parameters: Dictionary
    
    func _init(type: String = "sphere", params: Dictionary = {}):
        gene_type = type
        parameters = params
    
    func duplicate_gene() -> Gene:
        var new_gene = Gene.new(gene_type, parameters.duplicate())
        return new_gene
    
    func mutate(mutation_strength: float):
        match gene_type:
            "sphere", "box", "cylinder":
                if randf() < mutation_strength:
                    parameters.scale = Vector3(
                        parameters.scale.x * randf_range(0.5, 1.5),
                        parameters.scale.y * randf_range(0.5, 1.5),
                        parameters.scale.z * randf_range(0.5, 1.5)
                    )
                if randf() < mutation_strength:
                    parameters.position += Vector3(
                        randf_range(-1, 1),
                        randf_range(-1, 1),
                        randf_range(-1, 1)
                    )
                if randf() < mutation_strength:
                    parameters.rotation.y += randf_range(-PI/4, PI/4)

class Genome:
    var genes: Array[Gene] = []
    var fitness: float = 0.0
    var phenotype: Node3D = null
    var id: int = 0
    
    func _init():
        pass
    
    func duplicate_genome() -> Genome:
        var new_genome = Genome.new()
        for gene in genes:
            new_genome.genes.append(gene.duplicate_gene())
        return new_genome
    
    func mutate(rate: float, strength: float):
        for gene in genes:
            if randf() < rate:
                gene.mutate(strength)
        
        # Structural mutation: add or remove gene
        if randf() < rate * 0.3:
            if randf() < 0.5 and genes.size() > 1:
                genes.remove_at(randi() % genes.size())
            else:
                genes.append(create_random_gene())
    
    func create_random_gene() -> Gene:
        var types = ["sphere", "box", "cylinder", "torus"]
        var type = types[randi() % types.size()]
        
        var params = {
            "position": Vector3(
                randf_range(-2, 2),
                randf_range(0, 4),
                randf_range(-2, 2)
            ),
            "rotation": Vector3(
                randf_range(0, TAU),
                randf_range(0, TAU),
                randf_range(0, TAU)
            ),
            "scale": Vector3(
                randf_range(0.5, 2),
                randf_range(0.5, 2),
                randf_range(0.5, 2)
            )
        }
        
        return Gene.new(type, params)

var population: Array[Genome] = []
var current_generation: int = 0
var best_genome: Genome = null
var evolution_timer: float = 0.0
var fitness_history: Array[float] = []

func _ready() -> void:
    # DNA first: a map token or a sweep fixture must be in hand before the first
    # genome is rolled. All four calls are no-ops at the defaults.
    _read_dna_meta()
    if population_seed >= 0:
        seed(population_seed)
    _apply_alphabet()
    _apply_muster()
    initialize_population()

func _process(delta: float) -> void:
    if auto_evolve:
        evolution_timer += delta * evolution_speed
        if evolution_timer >= 1.0:
            evolution_timer = 0.0
            evolve_generation()

func initialize_population() -> void:
    clear_population()
    population.clear()
    current_generation = 0
    fitness_history.clear()
    
    for i in range(population_size):
        var genome = create_random_genome()
        genome.id = i
        population.append(genome)
    
    evaluate_population()
    visualize_population()
    
    print("Initialized population of ", population_size, " individuals")

func create_random_genome() -> Genome:
    var genome = Genome.new()
    
    match genome_type:
        0: # Primitives
            create_primitive_genome(genome)
        1: # CSG Tree
            create_csg_genome(genome)
        2: # Parametric
            create_parametric_genome(genome)
        3: # Voxel
            create_voxel_genome(genome)
        4: # L-System
            create_lsystem_genome(genome)
    
    return genome

func create_primitive_genome(genome: Genome) -> void:
    var num_genes = randi() % genome_complexity + 3
    for i in range(num_genes):
        genome.genes.append(genome.create_random_gene())

func create_csg_genome(genome: Genome) -> void:
    # Create CSG operations (union, subtract, intersect)
    var num_operations = randi() % (genome_complexity / 2) + 2
    
    for i in range(num_operations):
        var operation = ["union", "subtract", "intersect"][randi() % 3]
        var params = {
            "operation": operation,
            "primitive": ["sphere", "box", "cylinder"][randi() % 3],
            "position": Vector3(
                randf_range(-2, 2),
                randf_range(0, 4),
                randf_range(-2, 2)
            ),
            "scale": Vector3(
                randf_range(0.5, 2),
                randf_range(0.5, 2),
                randf_range(0.5, 2)
            )
        }
        genome.genes.append(Gene.new(operation, params))

func create_parametric_genome(genome: Genome) -> void:
    # Parametric equations for generating forms
    var params = {
        "freq_x": randf_range(0.5, 3.0),
        "freq_y": randf_range(0.5, 3.0),
        "freq_z": randf_range(0.5, 3.0),
        "amp_x": randf_range(0.5, 2.0),
        "amp_y": randf_range(0.5, 2.0),
        "amp_z": randf_range(0.5, 2.0),
        "phase_x": randf_range(0, TAU),
        "phase_y": randf_range(0, TAU),
        "phase_z": randf_range(0, TAU)
    }
    genome.genes.append(Gene.new("parametric", params))

func create_voxel_genome(genome: Genome) -> void:
    # 3D voxel grid representation
    var grid_size = 8
    var params = {
        "grid_size": grid_size,
        "voxels": []
    }
    
    # Random voxel pattern
    for x in range(grid_size):
        for y in range(grid_size):
            for z in range(grid_size):
                if randf() < 0.3:
                    params.voxels.append(Vector3i(x, y, z))
    
    genome.genes.append(Gene.new("voxel", params))

func create_lsystem_genome(genome: Genome) -> void:
    # L-System grammar for generative forms
    var rules = {
        "axiom": "F",
        "F": ["F[+F]F[-F]F", "FF+[+F-F-F]-[-F+F+F]"][randi() % 2],
        "angle": randf_range(15, 45),
        "length": randf_range(0.5, 1.5),
        "iterations": randi() % 3 + 2
    }
    genome.genes.append(Gene.new("lsystem", rules))

func evaluate_population() -> void:
    for genome in population:
        genome.fitness = calculate_fitness(genome)
    
    # Sort by fitness (descending)
    population.sort_custom(func(a, b): return a.fitness > b.fitness)
    
    best_genome = population[0]
    fitness_history.append(best_genome.fitness)
    
    print("Generation ", current_generation, " - Best fitness: ", best_genome.fitness)

func calculate_fitness(genome: Genome) -> float:
    var fitness = 0.0
    
    # Build phenotype to measure properties
    var phenotype = build_phenotype(genome)
    
    match fitness_function:
        0: # Volume target
            var volume = estimate_volume(genome)
            fitness = 100.0 / (1.0 + abs(volume - target_volume))
        
        1: # Height target
            var height = estimate_height(genome)
            fitness = 100.0 / (1.0 + abs(height - target_height))
        
        2: # Symmetry
            fitness = calculate_symmetry(genome) * 100.0
        
        3: # Sphere-like
            fitness = calculate_sphericity(genome) * 100.0
        
        4: # Custom (combination)
            var volume = estimate_volume(genome)
            var height = estimate_height(genome)
            var symmetry = calculate_symmetry(genome)
            var complexity = float(genome.genes.size()) / genome_complexity
            
            fitness = 0.0
            fitness += (100.0 / (1.0 + abs(volume - target_volume))) * (1.0 - complexity_weight)
            fitness += symmetry * 100.0 * symmetry_weight
            fitness += (1.0 - complexity) * 100.0 * complexity_weight
    
    phenotype.queue_free()
    return fitness

func estimate_volume(genome: Genome) -> float:
    var total_volume = 0.0
    
    for gene in genome.genes:
        var scale = gene.parameters.get("scale", Vector3.ONE)
        match gene.gene_type:
            "sphere":
                total_volume += (4.0 / 3.0) * PI * scale.x * scale.y * scale.z
            "box":
                total_volume += scale.x * scale.y * scale.z * 8.0
            "cylinder":
                total_volume += PI * scale.x * scale.z * scale.y * 2.0
    
    return total_volume

func estimate_height(genome: Genome) -> float:
    var max_height = 0.0
    
    for gene in genome.genes:
        var pos = gene.parameters.get("position", Vector3.ZERO)
        var scale = gene.parameters.get("scale", Vector3.ONE)
        var height = pos.y + scale.y
        max_height = max(max_height, height)
    
    return max_height

func calculate_symmetry(genome: Genome) -> float:
    # Calculate bilateral symmetry (X-axis)
    var symmetry_score = 0.0
    var comparisons = 0
    
    for i in range(genome.genes.size()):
        var gene1 = genome.genes[i]
        var pos1 = gene1.parameters.get("position", Vector3.ZERO)
        
        for j in range(i + 1, genome.genes.size()):
            var gene2 = genome.genes[j]
            var pos2 = gene2.parameters.get("position", Vector3.ZERO)
            
            # Check if mirrored across X axis
            if abs(pos1.x + pos2.x) < 0.5 and abs(pos1.y - pos2.y) < 0.5 and abs(pos1.z - pos2.z) < 0.5:
                symmetry_score += 1.0
            comparisons += 1
    
    return symmetry_score / max(comparisons, 1.0)

func calculate_sphericity(genome: Genome) -> float:
    # Measure how sphere-like the form is
    var center = Vector3.ZERO
    var count = 0
    
    for gene in genome.genes:
        center += gene.parameters.get("position", Vector3.ZERO)
        count += 1
    
    if count > 0:
        center /= count
    
    # Calculate variance from center
    var variance = 0.0
    for gene in genome.genes:
        var pos = gene.parameters.get("position", Vector3.ZERO)
        variance += center.distance_to(pos)
    
    variance /= max(count, 1.0)
    
    # Lower variance = more spherical
    return 1.0 / (1.0 + variance)

func evolve_generation() -> void:
    if current_generation >= max_generations:
        print("Maximum generations reached")
        return
    
    var new_population: Array[Genome] = []
    
    # Elitism: keep best individuals
    for i in range(elitism_count):
        new_population.append(population[i].duplicate_genome())
    
    # Generate rest of population
    while new_population.size() < population_size:
        var parent1 = tournament_selection()
        var parent2 = tournament_selection()
        
        var child: Genome
        
        if randf() < crossover_rate:
            child = crossover(parent1, parent2)
        else:
            child = parent1.duplicate_genome()
        
        child.mutate(mutation_rate, 0.5)
        new_population.append(child)
    
    population = new_population
    current_generation += 1
    
    # Assign new IDs
    for i in range(population.size()):
        population[i].id = i
    
    evaluate_population()
    visualize_population()

func tournament_selection() -> Genome:
    var tournament_size = 3
    var best: Genome = null
    
    for i in range(tournament_size):
        var contestant = population[randi() % population.size()]
        if best == null or contestant.fitness > best.fitness:
            best = contestant
    
    return best

func crossover(parent1: Genome, parent2: Genome) -> Genome:
    var child = Genome.new()
    
    # Single-point crossover
    var crossover_point = randi() % min(parent1.genes.size(), parent2.genes.size())
    
    for i in range(crossover_point):
        if i < parent1.genes.size():
            child.genes.append(parent1.genes[i].duplicate_gene())
    
    for i in range(crossover_point, parent2.genes.size()):
        child.genes.append(parent2.genes[i].duplicate_gene())
    
    return child

func build_phenotype(genome: Genome) -> Node3D:
    var phenotype = Node3D.new()
    
    match genome_type:
        0: # Primitives
            build_primitive_phenotype(genome, phenotype)
        1: # CSG
            build_csg_phenotype(genome, phenotype)
        2: # Parametric
            build_parametric_phenotype(genome, phenotype)
        3: # Voxel
            build_voxel_phenotype(genome, phenotype)
        4: # L-System
            build_lsystem_phenotype(genome, phenotype)
    
    return phenotype

func build_primitive_phenotype(genome: Genome, phenotype: Node3D) -> void:
    for gene in genome.genes:
        var mesh_instance = MeshInstance3D.new()
        phenotype.add_child(mesh_instance)
        
        var mesh: Mesh
        match gene.gene_type:
            "sphere":
                var sphere = SphereMesh.new()
                sphere.radius = 0.5
                sphere.height = sphere.radius
                mesh = sphere
            "box":
                var box = BoxMesh.new()
                box.size = Vector3.ONE
                mesh = box
            "cylinder":
                var cylinder = CylinderMesh.new()
                cylinder.top_radius = 0.5
                cylinder.bottom_radius = 0.5
                cylinder.height = 1.0
                mesh = cylinder
            "torus":
                var torus = TorusMesh.new()
                torus.inner_radius = 0.3
                torus.outer_radius = 0.7
                mesh = torus
        
        mesh_instance.mesh = mesh
        mesh_instance.position = gene.parameters.get("position", Vector3.ZERO)
        mesh_instance.rotation = gene.parameters.get("rotation", Vector3.ZERO)
        mesh_instance.scale = gene.parameters.get("scale", Vector3.ONE)
        
        # Material
        var material = StandardMaterial3D.new()
        material.albedo_color = Color(0.6, 0.7, 0.9)
        material.metallic = 0.3
        material.roughness = 0.7
        mesh_instance.material_override = material

func build_csg_phenotype(genome: Genome, phenotype: Node3D) -> void:
    if genome.genes.size() == 0:
        return
    
    var base_mesh = MeshInstance3D.new()
    phenotype.add_child(base_mesh)
    
    # Create combined mesh (simplified CSG simulation)
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    for gene in genome.genes:
        var operation = gene.parameters.get("operation", "union")
        # In a full implementation, you'd use CSG nodes or libraries
        # For now, just add primitives
        add_primitive_to_surface(surface_tool, gene)
    
    surface_tool.generate_normals()
    base_mesh.mesh = surface_tool.commit()
    
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.8, 0.6, 0.4)
    base_mesh.material_override = material

func add_primitive_to_surface(surface_tool: SurfaceTool, gene: Gene) -> void:
    # Simplified - just add a cube
    var pos = gene.parameters.get("position", Vector3.ZERO)
    var scale = gene.parameters.get("scale", Vector3.ONE)
    
    var vertices = [
        pos + Vector3(-0.5, -0.5, -0.5) * scale,
        pos + Vector3(0.5, -0.5, -0.5) * scale,
        pos + Vector3(0.5, 0.5, -0.5) * scale,
        pos + Vector3(-0.5, 0.5, -0.5) * scale,
        pos + Vector3(-0.5, -0.5, 0.5) * scale,
        pos + Vector3(0.5, -0.5, 0.5) * scale,
        pos + Vector3(0.5, 0.5, 0.5) * scale,
        pos + Vector3(-0.5, 0.5, 0.5) * scale
    ]
    
    # Add one face
    surface_tool.add_vertex(vertices[0])
    surface_tool.add_vertex(vertices[1])
    surface_tool.add_vertex(vertices[2])

func build_parametric_phenotype(genome: Genome, phenotype: Node3D) -> void:
    if genome.genes.size() == 0:
        return
    
    var gene = genome.genes[0]
    var params = gene.parameters
    
    var mesh_instance = MeshInstance3D.new()
    phenotype.add_child(mesh_instance)
    
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    var resolution = 20
    
    for u in range(resolution):
        for v in range(resolution):
            var u_norm = float(u) / resolution * TAU
            var v_norm = float(v) / resolution * TAU
            
            # Parametric surface equation
            var x = params.amp_x * cos(u_norm * params.freq_x + params.phase_x)
            var y = params.amp_y * sin(v_norm * params.freq_y + params.phase_y)
            var z = params.amp_z * cos(v_norm * params.freq_z + params.phase_z)
            
            var p1 = Vector3(x, y, z)
            
            var u_next = float(u + 1) / resolution * TAU
            var v_next = float(v + 1) / resolution * TAU
            
            var x2 = params.amp_x * cos(u_next * params.freq_x + params.phase_x)
            var y2 = params.amp_y * sin(v_norm * params.freq_y + params.phase_y)
            var z2 = params.amp_z * cos(v_norm * params.freq_z + params.phase_z)
            var p2 = Vector3(x2, y2, z2)
            
            var x3 = params.amp_x * cos(u_norm * params.freq_x + params.phase_x)
            var y3 = params.amp_y * sin(v_next * params.freq_y + params.phase_y)
            var z3 = params.amp_z * cos(v_next * params.freq_z + params.phase_z)
            var p3 = Vector3(x3, y3, z3)
            
            surface_tool.add_vertex(p1)
            surface_tool.add_vertex(p2)
            surface_tool.add_vertex(p3)
    
    surface_tool.generate_normals()
    mesh_instance.mesh = surface_tool.commit()
    
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.9, 0.5, 0.7)
    mesh_instance.material_override = material

func build_voxel_phenotype(genome: Genome, phenotype: Node3D) -> void:
    if genome.genes.size() == 0:
        return
    
    var gene = genome.genes[0]
    var voxels = gene.parameters.get("voxels", [])
    var grid_size = gene.parameters.get("grid_size", 8)
    
    for voxel_pos in voxels:
        var cube = MeshInstance3D.new()
        phenotype.add_child(cube)
        
        var mesh = BoxMesh.new()
        mesh.size = Vector3.ONE * 0.4
        cube.mesh = mesh
        
        cube.position = Vector3(
            voxel_pos.x - grid_size / 2.0,
            voxel_pos.y,
            voxel_pos.z - grid_size / 2.0
        ) * 0.5
        
        var material = StandardMaterial3D.new()
        material.albedo_color = Color(0.5, 0.8, 0.6)
        cube.material_override = material

func build_lsystem_phenotype(genome: Genome, phenotype: Node3D) -> void:
    if genome.genes.size() == 0:
        return
    
    var gene = genome.genes[0]
    var rules = gene.parameters
    
    # Generate L-system string
    var lstring = rules.axiom
    for i in range(rules.iterations):
        lstring = expand_lsystem(lstring, rules)
    
    # Interpret L-system as 3D structure
    interpret_lsystem(lstring, rules, phenotype)

func expand_lsystem(lstring: String, rules: Dictionary) -> String:
    var result = ""
    for c in lstring:
        if rules.has(c):
            result += rules[c]
        else:
            result += c
    return result

func interpret_lsystem(lstring: String, rules: Dictionary, parent: Node3D) -> void:
    var position = Vector3.ZERO
    var direction = Vector3.UP
    var angle = deg_to_rad(rules.angle)
    var length = rules.length
    
    var stack: Array = []
    
    for c in lstring:
        match c:
            'F':
                # Draw forward
                var end_pos = position + direction * length
                create_branch_segment(parent, position, end_pos)
                position = end_pos
            '+':
                # Rotate right
                direction = direction.rotated(Vector3.UP, angle)
            '-':
                # Rotate left
                direction = direction.rotated(Vector3.UP, -angle)
            '[':
                # Push state
                stack.append([position, direction])
            ']':
                # Pop state
                if stack.size() > 0:
                    var state = stack.pop_back()
                    position = state[0]
                    direction = state[1]

func create_branch_segment(parent: Node3D, start: Vector3, end: Vector3) -> void:
    var mesh_instance = MeshInstance3D.new()
    parent.add_child(mesh_instance)
    
    var cylinder = CylinderMesh.new()
    cylinder.top_radius = 0.1
    cylinder.bottom_radius = 0.1
    cylinder.height = start.distance_to(end)
    mesh_instance.mesh = cylinder
    
    mesh_instance.position = (start + end) / 2
    mesh_instance.look_at(end, Vector3.UP)
    mesh_instance.rotate_object_local(Vector3.RIGHT, PI / 2)
    
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.6, 0.4, 0.2)
    mesh_instance.material_override = material

func visualize_population() -> void:
    clear_visualization()
    
    if show_best_only:
        var phenotype = build_phenotype(best_genome)
        add_child(phenotype)
        phenotype.position = Vector3.ZERO
        
        # Add label
        var label = Label3D.new()
        add_child(label)
        label.text = "Best: %.2f" % best_genome.fitness
        label.position = Vector3(0, 6, 0)
        label.font_size = 32
    
    elif show_population:
        var display_count = min(population.size(), 20)
        var grid_size = ceili(sqrt(display_count))
        
        for i in range(display_count):
            var genome = population[i]
            var phenotype = build_phenotype(genome)
            add_child(phenotype)
            
            if arrange_in_grid:
                var x = (i % grid_size) * spacing
                var z = (i / grid_size) * spacing
                phenotype.position = Vector3(x, 0, z)
            else:
                phenotype.position = Vector3(
                    randf_range(-spacing * 2, spacing * 2),
                    0,
                    randf_range(-spacing * 2, spacing * 2)
                )
            
            genome.phenotype = phenotype
            
            # Add fitness label
            var label = Label3D.new()
            add_child(label)
            label.text = "%.1f" % genome.fitness
            label.position = phenotype.position + Vector3(0, 4, 0)
            label.font_size = 16

func clear_population() -> void:
    for genome in population:
        if genome.phenotype:
            genome.phenotype.queue_free()
    clear_visualization()

func clear_visualization() -> void:
    for child in get_children():
        child.queue_free()

func _exit_tree() -> void:
    for child in get_children():
        if not child.owner:
            child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
    pass


# ── DNA: ALPHABET AND MUSTER ─────────────────────────────────────────────────

## Read map tokens / grid config values if the placer left any. Unknown words
## keep the default — a typo must not quietly hand a room a different species.
func _read_dna_meta() -> void:
    if has_meta("config_alphabet"):
        var raw_a: String = str(get_meta("config_alphabet")).strip_edges().to_lower()
        if ALPHABETS.has(raw_a):
            alphabet = raw_a
        else:
            push_warning("GeneticProgramming: unknown alphabet '%s' — keeping '%s'" % [raw_a, alphabet])
    if has_meta("config_muster"):
        var raw_m: String = str(get_meta("config_muster")).strip_edges().to_lower()
        if MUSTERS.has(raw_m):
            muster = raw_m
        else:
            push_warning("GeneticProgramming: unknown muster '%s' — keeping '%s'" % [raw_m, muster])
    if has_meta("config_population_seed"):
        population_seed = int(str(get_meta("config_population_seed")))


## alphabet -> genome_type. "primitives" is genome_type 0, which is what the
## export already holds, so the default arm writes nothing at all.
func _apply_alphabet() -> void:
    match alphabet:
        "csg_tree":
            genome_type = 1
        "parametric":
            genome_type = 2
        "voxel":
            genome_type = 3
        _:
            pass                            # "primitives" — the legacy lineage


## muster -> the three Visualization booleans. "parade" is the combination the
## exports already hold, so the default arm leaves every one of them alone —
## including any a scene or a placer set deliberately.
func _apply_muster() -> void:
    match muster:
        "champion":
            show_best_only = true
            show_population = false
        "scatter":
            show_best_only = false
            show_population = true
            arrange_in_grid = false
        _:
            pass                            # "parade" — the legacy lineage
