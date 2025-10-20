@tool
extends Node3D
class_name PoissonDiskSamplingApplications

## Poisson Disk Sampling - Practical Applications

@export_group("Application Type")
@export_enum("Forest", "Particle Cloud", "Star Field", "Cell Distribution") var application: int = 0

@export_group("Forest Settings")
@export var tree_scene: PackedScene
@export var tree_scale_min: float = 0.8
@export var tree_scale_max: float = 1.5

@export_group("Particle Settings")
@export var particle_colors: Array[Color] = [
    Color(1, 0.3, 0.3),
    Color(0.3, 1, 0.3),
    Color(0.3, 0.3, 1),
    Color(1, 1, 0.3)
]

@export_group("Sampling")
@export var area_size: Vector3 = Vector3(20, 20, 20)
@export var min_separation: float = 2.0
@export var apply_samples: bool = false:
    set(value):
        if value:
            generate_application()
            apply_samples = false

var poisson_sampler: Node3D

func _ready():
    setup_sampler()

func setup_sampler():
    # Create poisson sampler if not exists
    if not poisson_sampler:
        poisson_sampler = Node3D.new()
        add_child(poisson_sampler)
        
        # Add the PoissonDiskSampling3D script
        var script_path = "res://algorithms/proceduralgeneration/poisson_disk_sampling_3d/PoissonDiskSampling3D.gd"
        if ResourceLoader.exists(script_path):
            poisson_sampler.set_script(load(script_path))

func generate_application():
    clear_application()
    
    # Configure sampler
    if poisson_sampler and poisson_sampler.has_method("generate_samples"):
        poisson_sampler.sample_region = area_size
        poisson_sampler.min_distance = min_separation
        poisson_sampler.display_mode = 0  # Don't show default visualization
        
        match application:
            0:
                poisson_sampler.distribution_type = 3  # Layered for forest floor
                poisson_sampler.generate_samples()
                create_forest()
            1:
                poisson_sampler.distribution_type = 0  # Uniform
                poisson_sampler.generate_samples()
                create_particles()
            2:
                poisson_sampler.distribution_type = 1  # Spherical
                poisson_sampler.generate_samples()
                create_star_field()
            3:
                poisson_sampler.distribution_type = 1  # Spherical
                poisson_sampler.generate_samples()
                create_cell_distribution()

func create_forest():
    if not poisson_sampler.has_method("get_sample_points"):
        return
    
    var points = poisson_sampler.get_sample_points()
    
    for point in points:
        var tree: Node3D
        
        if tree_scene:
            tree = tree_scene.instantiate()
        else:
            # Create simple tree
            tree = create_simple_tree()
        
        add_child(tree)
        tree.position = point
        tree.rotation.y = randf() * TAU
        
        var scale_factor = randf_range(tree_scale_min, tree_scale_max)
        tree.scale = Vector3.ONE * scale_factor
    
    print("Created forest with ", points.size(), " trees")

func create_simple_tree() -> Node3D:
    var tree = Node3D.new()
    
    # Trunk
    var trunk = MeshInstance3D.new()
    var trunk_mesh = CylinderMesh.new()
    trunk_mesh.top_radius = 0.1
    trunk_mesh.bottom_radius = 0.15
    trunk_mesh.height = 2.0
    trunk.mesh = trunk_mesh
    
    var trunk_mat = StandardMaterial3D.new()
    trunk_mat.albedo_color = Color(0.4, 0.25, 0.15)
    trunk.material_override = trunk_mat
    trunk.position.y = 1.0
    
    # Foliage
    var foliage = MeshInstance3D.new()
    var foliage_mesh = SphereMesh.new()
    foliage_mesh.radius = 0.8
    foliage_mesh.height = foliage_mesh.radius
    foliage.mesh = foliage_mesh
    
    var foliage_mat = StandardMaterial3D.new()
    foliage_mat.albedo_color = Color(0.2, 0.6, 0.2)
    foliage.material_override = foliage_mat
    foliage.position.y = 2.5
    
    tree.add_child(trunk)
    tree.add_child(foliage)
    
    return tree

func create_particles():
    if not poisson_sampler.has_method("get_sample_points"):
        return
    
    var points = poisson_sampler.get_sample_points()
    
    for point in points:
        var particle = MeshInstance3D.new()
        add_child(particle)
        
        var sphere = SphereMesh.new()
        sphere.radius = 0.15
        sphere.height = sphere.radius
        particle.mesh = sphere
        particle.position = point
        
        var material = StandardMaterial3D.new()
        material.albedo_color = particle_colors[randi() % particle_colors.size()]
        material.emission_enabled = true
        material.emission = material.albedo_color
        material.emission_energy_multiplier = 2.0
        particle.material_override = material
    
    print("Created particle cloud with ", points.size(), " particles")

func create_star_field():
    if not poisson_sampler.has_method("get_sample_points"):
        return
    
    var points = poisson_sampler.get_sample_points()
    
    for point in points:
        var star = MeshInstance3D.new()
        add_child(star)
        
        var sphere = SphereMesh.new()
        var size = randf_range(0.05, 0.2)
        sphere.radius = size
        sphere.height = sphere.radius
        star.mesh = sphere
        star.position = point
        
        var material = StandardMaterial3D.new()
        var brightness = randf_range(0.7, 1.0)
        material.albedo_color = Color(brightness, brightness, brightness * 0.9)
        material.emission_enabled = true
        material.emission = material.albedo_color
        material.emission_energy_multiplier = randf_range(1.0, 4.0)
        star.material_override = material
    
    print("Created star field with ", points.size(), " stars")

func create_cell_distribution():
    if not poisson_sampler.has_method("get_sample_points"):
        return
    
    var points = poisson_sampler.get_sample_points()
    
    for point in points:
        var cell = MeshInstance3D.new()
        add_child(cell)
        
        var sphere = SphereMesh.new()
        sphere.radius = min_separation * 0.4
        sphere.height = sphere.radius
        cell.mesh = sphere
        cell.position = point
        
        var material = StandardMaterial3D.new()
        var color_variation = randf_range(0.8, 1.0)
        material.albedo_color = Color(1.0, color_variation * 0.6, color_variation * 0.8, 0.7)
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material.metallic = 0.4
        material.roughness = 0.3
        cell.material_override = material
    
    print("Created cell distribution with ", points.size(), " cells")

func clear_application():
    for child in get_children():
        if child != poisson_sampler:
            child.queue_free()
