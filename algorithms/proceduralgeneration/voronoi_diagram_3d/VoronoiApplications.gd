@tool
extends Node3D
class_name VoronoiApplications

## Voronoi Applications - Caves, Buildings, Fractured Objects

@export_group("Application")
@export_enum("Cave System", "Building Interior", "Fractured Object", "Coral Reef", "Rock Formation") var application_type: int = 0

@export_group("Cave Settings")
@export var cave_density: int = 30
@export var tunnel_width: float = 1.5
@export var cave_roughness: float = 0.3

@export_group("Building Settings")
@export var num_rooms: int = 15
@export var floor_height: float = 3.0
@export var wall_thickness: float = 0.2

@export var apply: bool = false:
    set(value):
        if value:
            generate_application()
            apply = false

var voronoi_generator: Node3D

func _ready():
    setup_voronoi()

func setup_voronoi():
    voronoi_generator = Node3D.new()
    add_child(voronoi_generator)
    # Attach voronoi script here

func generate_application():
    clear_application()
    
    match application_type:
        0:
            create_cave_system()
        1:
            create_building_interior()
        2:
            create_fractured_object()
        3:
            create_coral_reef()
        4:
            create_rock_formation()

func create_cave_system():
    # Use Voronoi cells to create cave chambers connected by tunnels
    if voronoi_generator:
        voronoi_generator.num_seeds = cave_density
        voronoi_generator.structure_type = 4  # Organic
        voronoi_generator.hollow_cells = true
        voronoi_generator.noise_influence = cave_roughness
        voronoi_generator.region_size = Vector3(20, 10, 20)
        voronoi_generator.generate_voronoi_structure()
    
    print("Cave system generated with ", cave_density, " chambers")

func create_building_interior():
    # Use Voronoi cells as rooms
    if voronoi_generator:
        voronoi_generator.num_seeds = num_rooms
        voronoi_generator.structure_type = 5  # Architectural
        voronoi_generator.seed_distribution = 4  # Layered
        voronoi_generator.region_size = Vector3(15, floor_height * 3, 15)
        voronoi_generator.cell_wall_thickness = wall_thickness
        voronoi_generator.generate_voronoi_structure()
    
    print("Building with ", num_rooms, " rooms generated")

func create_fractured_object():
    # Create shattered/fractured geometry
    if voronoi_generator:
        voronoi_generator.num_seeds = 25
        voronoi_generator.structure_type = 2  # Crystal
        voronoi_generator.seed_distribution = 0  # Random
        voronoi_generator.region_size = Vector3(5, 5, 5)
        voronoi_generator.generate_voronoi_structure()
    
    print("Fractured object generated")

func create_coral_reef():
    if voronoi_generator:
        voronoi_generator.num_seeds = 40
        voronoi_generator.structure_type = 3  # Foam
        voronoi_generator.seed_distribution = 3  # Spherical
        voronoi_generator.region_size = Vector3(12, 8, 12)
        voronoi_generator.generate_voronoi_structure()
    
    print("Coral reef generated")

func create_rock_formation():
    if voronoi_generator:
        voronoi_generator.num_seeds = 20
        voronoi_generator.structure_type = 4  # Organic
        voronoi_generator.noise_influence = 0.5
        voronoi_generator.relaxation_iterations = 2
        voronoi_generator.region_size = Vector3(10, 10, 10)
        voronoi_generator.generate_voronoi_structure()
    
    print("Rock formation generated")

func clear_application():
    for child in get_children():
        if child != voronoi_generator:
            child.queue_free()
