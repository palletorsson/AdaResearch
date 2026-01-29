@tool
extends Node3D
class_name GeneticProgramming

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

func _ready():
    initialize_population()

func _process(delta):
    if auto_evolve:
        evolution_timer += delta * evolution_speed
        if evolution_timer >= 1.0:
            evolution_timer = 0.0
            evolve_generation()

func initialize_population():
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

func create_primitive_genome(genome: Genome):
    var num_genes = randi() % genome_complexity + 3
    for i in range(num_genes):
        genome.genes.append(genome.create_random_gene())

func create_csg_genome(genome: Genome):
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

func create_parametric_genome(genome: Genome):
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

func create_voxel_genome(genome: Genome):
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

func create_lsystem_genome(genome: Genome):
    # L-System grammar for generative forms
    var rules = {
        "axiom": "F",
        "F": ["F[+F]F[-F]F", "FF+[+F-F-F]-[-F+F+F]"][randi() % 2],
        "angle": randf_range(15, 45),
        "length": randf_range(0.5, 1.5),
        "iterations": randi() % 3 + 2
    }
    genome.genes.append(Gene.new("lsystem", rules))

func evaluate_population():
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

func evolve_generation():
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

func build_primitive_phenotype(genome: Genome, phenotype: Node3D):
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

func build_csg_phenotype(genome: Genome, phenotype: Node3D):
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

func add_primitive_to_surface(surface_tool: SurfaceTool, gene: Gene):
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

func build_parametric_phenotype(genome: Genome, phenotype: Node3D):
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

func build_voxel_phenotype(genome: Genome, phenotype: Node3D):
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

func build_lsystem_phenotype(genome: Genome, phenotype: Node3D):
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

func interpret_lsystem(lstring: String, rules: Dictionary, parent: Node3D):
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

func create_branch_segment(parent: Node3D, start: Vector3, end: Vector3):
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

func visualize_population():
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

func clear_population():
    for genome in population:
        if genome.phenotype:
            genome.phenotype.queue_free()
    clear_visualization()

func clear_visualization():
    for child in get_children():
        child.queue_free()
