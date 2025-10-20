@tool
extends Node3D
class_name PoissonDiskSampling3D

@export_group("Sampling Settings")
@export var sample_region: Vector3 = Vector3(10, 10, 10)
@export var min_distance: float = 1.0
@export var max_attempts: int = 30
@export var seed_value: int = 0

@export_group("Visualization")
@export_enum("Points", "Spheres", "Cubes", "Cylinders", "Custom") var display_mode: int = 1
@export var point_size: float = 0.2
@export var point_color: Color = Color(0.2, 0.8, 1.0)
@export var show_radius: bool = false
@export var show_grid: bool = false

@export_group("Advanced")
@export var use_boundary: bool = true
@export_enum("Uniform", "Spherical", "Cylindrical", "Layered") var distribution_type: int = 0
@export var boundary_falloff: float = 0.5

@export_group("Actions")
@export var regenerate: bool = false:
    set(value):
        if value:
            generate_samples()
            regenerate = false
@export var export_points: bool = false:
    set(value):
        if value:
            print_sample_points()
            export_points = false

var sample_points: Array[Vector3] = []
var grid: Dictionary = {}
var cell_size: float
var grid_dimensions: Vector3i

func _ready():
    generate_samples()

func generate_samples():
    clear_samples()
    
    if seed_value != 0:
        seed(seed_value)
    
    # Initialize grid
    cell_size = min_distance / sqrt(3.0)
    grid_dimensions = Vector3i(
        ceil(sample_region.x / cell_size),
        ceil(sample_region.y / cell_size),
        ceil(sample_region.z / cell_size)
    )
    grid.clear()
    
    # Bridson's algorithm for Poisson Disk Sampling
    var active_list: Array[Vector3] = []
    
    # Start with initial sample
    var initial_point = get_initial_point()
    sample_points.append(initial_point)
    active_list.append(initial_point)
    add_to_grid(initial_point)
    
    # Process active list
    while active_list.size() > 0:
        var random_index = randi() % active_list.size()
        var point = active_list[random_index]
        var found = false
        
        for _attempt in range(max_attempts):
            var new_point = generate_point_around(point)
            
            if is_valid_point(new_point):
                sample_points.append(new_point)
                active_list.append(new_point)
                add_to_grid(new_point)
                found = true
                break
        
        if not found:
            active_list.remove_at(random_index)
    
    print("Generated ", sample_points.size(), " sample points")
    visualize_samples()

func get_initial_point() -> Vector3:
    match distribution_type:
        0: # Uniform
            return Vector3(
                randf() * sample_region.x - sample_region.x / 2,
                randf() * sample_region.y - sample_region.y / 2,
                randf() * sample_region.z - sample_region.z / 2
            )
        1: # Spherical (start from center)
            return Vector3.ZERO
        2: # Cylindrical (start on axis)
            return Vector3(0, randf() * sample_region.y - sample_region.y / 2, 0)
        3: # Layered (start at bottom)
            return Vector3(
                randf() * sample_region.x - sample_region.x / 2,
                -sample_region.y / 2,
                randf() * sample_region.z - sample_region.z / 2
            )
    return Vector3.ZERO

func generate_point_around(center: Vector3) -> Vector3:
    # Generate random point in spherical annulus between min_distance and 2*min_distance
    var radius = min_distance * (1.0 + randf())
    var theta = randf() * TAU
    var phi = acos(2.0 * randf() - 1.0)
    
    var offset = Vector3(
        radius * sin(phi) * cos(theta),
        radius * sin(phi) * sin(theta),
        radius * cos(phi)
    )
    
    return center + offset

func is_valid_point(point: Vector3) -> bool:
    # Check boundaries
    if use_boundary:
        match distribution_type:
            0: # Uniform box
                if abs(point.x) > sample_region.x / 2 or \
                   abs(point.y) > sample_region.y / 2 or \
                   abs(point.z) > sample_region.z / 2:
                    return false
            1: # Spherical
                var radius = min(sample_region.x, min(sample_region.y, sample_region.z)) / 2
                if point.length() > radius:
                    return false
            2: # Cylindrical
                var radius = min(sample_region.x, sample_region.z) / 2
                var xz_dist = Vector2(point.x, point.z).length()
                if xz_dist > radius or abs(point.y) > sample_region.y / 2:
                    return false
            3: # Layered (box with density variation)
                if abs(point.x) > sample_region.x / 2 or \
                   abs(point.y) > sample_region.y / 2 or \
                   abs(point.z) > sample_region.z / 2:
                    return false
    
    # Check minimum distance to other points using grid
    var grid_pos = world_to_grid(point)
    
    # Check neighboring cells
    for x in range(-2, 3):
        for y in range(-2, 3):
            for z in range(-2, 3):
                var neighbor_pos = Vector3i(
                    grid_pos.x + x,
                    grid_pos.y + y,
                    grid_pos.z + z
                )
                
                var key = grid_key(neighbor_pos)
                if grid.has(key):
                    for neighbor in grid[key]:
                        if point.distance_to(neighbor) < min_distance:
                            return false
    
    return true

func world_to_grid(point: Vector3) -> Vector3i:
    var offset = sample_region / 2
    return Vector3i(
        int((point.x + offset.x) / cell_size),
        int((point.y + offset.y) / cell_size),
        int((point.z + offset.z) / cell_size)
    )

func grid_key(grid_pos: Vector3i) -> String:
    return "%d,%d,%d" % [grid_pos.x, grid_pos.y, grid_pos.z]

func add_to_grid(point: Vector3):
    var grid_pos = world_to_grid(point)
    var key = grid_key(grid_pos)
    
    if not grid.has(key):
        grid[key] = []
    
    grid[key].append(point)

func visualize_samples():
    clear_visualization()
    
    # Draw sample points
    for point in sample_points:
        create_sample_visual(point)
    
    # Draw grid if enabled
    if show_grid:
        create_grid_visual()
    
    # Draw radius spheres if enabled
    if show_radius:
        create_radius_visual()

func create_sample_visual(point: Vector3):
    var instance = MeshInstance3D.new()
    add_child(instance)
    instance.position = point
    
    var mesh: Mesh
    match display_mode:
        0: # Points (small spheres)
            var sphere = SphereMesh.new()
            sphere.radius = point_size * 0.5
            sphere.height = sphere.radius
            mesh = sphere
        1: # Spheres
            var sphere = SphereMesh.new()
            sphere.radius = point_size
            sphere.height = sphere.radius
            mesh = sphere
        2: # Cubes
            var box = BoxMesh.new()
            box.size = Vector3.ONE * point_size
            mesh = box
        3: # Cylinders
            var cylinder = CylinderMesh.new()
            cylinder.top_radius = point_size * 0.5
            cylinder.bottom_radius = point_size * 0.5
            cylinder.height = point_size * 2
            mesh = cylinder
    
    instance.mesh = mesh
    
    var material = StandardMaterial3D.new()
    material.albedo_color = point_color
    material.metallic = 0.3
    material.roughness = 0.7
    instance.material_override = material

func create_radius_visual():
    # Create wireframe spheres showing min_distance radius
    for i in range(min(sample_points.size(), 50)): # Limit for performance
        var point = sample_points[i]
        var sphere = create_wireframe_sphere(point, min_distance / 2)
        add_child(sphere)

func create_wireframe_sphere(center: Vector3, radius: float) -> MeshInstance3D:
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.position = center
    
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_LINES)
    
    var segments = 16
    
    # Create three perpendicular circles
    for circle in range(3):
        for i in range(segments):
            var angle1 = float(i) / segments * TAU
            var angle2 = float(i + 1) / segments * TAU
            
            var p1: Vector3
            var p2: Vector3
            
            match circle:
                0: # XY plane
                    p1 = Vector3(cos(angle1), sin(angle1), 0) * radius
                    p2 = Vector3(cos(angle2), sin(angle2), 0) * radius
                1: # XZ plane
                    p1 = Vector3(cos(angle1), 0, sin(angle1)) * radius
                    p2 = Vector3(cos(angle2), 0, sin(angle2)) * radius
                2: # YZ plane
                    p1 = Vector3(0, cos(angle1), sin(angle1)) * radius
                    p2 = Vector3(0, cos(angle2), sin(angle2)) * radius
            
            surface_tool.add_vertex(p1)
            surface_tool.add_vertex(p2)
    
    mesh_instance.mesh = surface_tool.commit()
    
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(point_color.r, point_color.g, point_color.b, 0.2)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mesh_instance.material_override = material
    
    return mesh_instance

func create_grid_visual():
    var grid_mesh = MeshInstance3D.new()
    add_child(grid_mesh)
    
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_LINES)
    
    var half_region = sample_region / 2
    
    # Draw bounding box
    var corners = [
        Vector3(-half_region.x, -half_region.y, -half_region.z),
        Vector3(half_region.x, -half_region.y, -half_region.z),
        Vector3(half_region.x, half_region.y, -half_region.z),
        Vector3(-half_region.x, half_region.y, -half_region.z),
        Vector3(-half_region.x, -half_region.y, half_region.z),
        Vector3(half_region.x, -half_region.y, half_region.z),
        Vector3(half_region.x, half_region.y, half_region.z),
        Vector3(-half_region.x, half_region.y, half_region.z)
    ]
    
    var edges = [
        [0,1], [1,2], [2,3], [3,0],
        [4,5], [5,6], [6,7], [7,4],
        [0,4], [1,5], [2,6], [3,7]
    ]
    
    for edge in edges:
        surface_tool.add_vertex(corners[edge[0]])
        surface_tool.add_vertex(corners[edge[1]])
    
    grid_mesh.mesh = surface_tool.commit()
    
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(1, 1, 1, 0.3)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    grid_mesh.material_override = material

func print_sample_points():
    print("\n=== Poisson Disk Sample Points ===")
    print("Total points: ", sample_points.size())
    print("Density: ", sample_points.size() / (sample_region.x * sample_region.y * sample_region.z), " points per cubic unit")
    print("\nPoints array:")
    for i in range(min(sample_points.size(), 20)):
        print("  [", i, "]: ", sample_points[i])
    if sample_points.size() > 20:
        print("  ... (", sample_points.size() - 20, " more points)")

func get_sample_points() -> Array[Vector3]:
    return sample_points

func clear_samples():
    sample_points.clear()
    grid.clear()
    clear_visualization()

func clear_visualization():
    for child in get_children():
        child.queue_free()
