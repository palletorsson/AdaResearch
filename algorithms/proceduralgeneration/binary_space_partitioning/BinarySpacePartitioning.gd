@tool
extends Node3D
class_name BinarySpacePartitioning

@export_group("BSP Settings")
@export var max_depth: int = 7
@export var min_cell_size: float = 0.5
@export var space_size: Vector3 = Vector3(10, 10, 10)

@export_group("Gradient Settings")
@export_enum("Centered", "Compact", "Diagonal", "Scattered") var gradient_type: int = 0
@export_range(0.1, 5.0) var gradient_falloff: float = 1.5
@export_range(0.0, 1.0) var center_bias: float = 0.8

@export_group("Visualization")
@export var show_partitions: bool = true
@export var show_heatmap: bool = true
@export var regenerate: bool = false:
    set(value):
        if value:
            generate_bsp()
            regenerate = false

var root_node: BSPNode
var all_cells: Array[BSPNode] = []

class BSPNode:
    var bounds: AABB
    var depth: int
    var children: Array[BSPNode] = []
    var is_leaf: bool = true
    var split_axis: int = -1
    var split_position: float = 0.0
    var partition_probability: float = 1.0
    
    func _init(aabb: AABB, d: int = 0):
        bounds = aabb
        depth = d

func _ready():
    generate_bsp()

func generate_bsp():
    clear_children()
    all_cells.clear()
    
    # Create root node
    var initial_bounds = AABB(-space_size / 2, space_size)
    root_node = BSPNode.new(initial_bounds, 0)
    
    # Recursively partition space
    partition_node(root_node)
    
    # Collect all leaf cells
    collect_leaves(root_node)
    
    # Visualize
    if show_partitions:
        visualize_partitions()
    if show_heatmap:
        create_heatmap_mesh()

func partition_node(node: BSPNode):
    if node.depth >= max_depth:
        return
    
    var size = node.bounds.size
    if size.x < min_cell_size or size.y < min_cell_size or size.z < min_cell_size:
        return
    
    # Calculate partition probability based on position
    var center = node.bounds.get_center()
    node.partition_probability = calculate_partition_probability(center)
    
    # Decide whether to split based on probability
    if randf() > node.partition_probability:
        return
    
    # Choose split axis (prefer larger dimensions)
    var split_axis = get_best_split_axis(size)
    node.split_axis = split_axis
    
    # Calculate split position with gradient influence
    var split_ratio = get_split_ratio(center, split_axis)
    var axis_size = size[split_axis]
    node.split_position = node.bounds.position[split_axis] + axis_size * split_ratio
    
    # Create child bounds
    var left_bounds = node.bounds
    var right_bounds = node.bounds
    
    var left_size = size
    left_size[split_axis] = axis_size * split_ratio
    left_bounds.size = left_size
    
    var right_pos = node.bounds.position
    right_pos[split_axis] = node.split_position
    right_bounds.position = right_pos
    var right_size = size
    right_size[split_axis] = axis_size * (1.0 - split_ratio)
    right_bounds.size = right_size
    
    # Create child nodes
    node.children.append(BSPNode.new(left_bounds, node.depth + 1))
    node.children.append(BSPNode.new(right_bounds, node.depth + 1))
    node.is_leaf = false
    
    # Recursively partition children
    for child in node.children:
        partition_node(child)

func calculate_partition_probability(position: Vector3) -> float:
    var normalized_pos = position / (space_size / 2)
    var distance_from_center = normalized_pos.length()
    
    match gradient_type:
        0: # Centered - Gaussian
            return exp(-distance_from_center * distance_from_center * gradient_falloff)
        1: # Compact - Sharper falloff
            return exp(-distance_from_center * distance_from_center * gradient_falloff * 3.0)
        2: # Diagonal
            var diagonal_factor = (normalized_pos.x + normalized_pos.z) / 2.0
            return 1.0 - clamp(abs(diagonal_factor) * gradient_falloff, 0.0, 1.0)
        3: # Scattered - Perlin noise based
            var noise_val = abs(sin(position.x * 0.5) * cos(position.z * 0.5))
            return noise_val * (1.0 - distance_from_center * 0.3)
    
    return 1.0

func get_best_split_axis(size: Vector3) -> int:
    # Weight by size
    var weights = [size.x, size.y, size.z]
    var total = weights[0] + weights[1] + weights[2]
    var rand_val = randf() * total
    
    if rand_val < weights[0]:
        return 0
    elif rand_val < weights[0] + weights[1]:
        return 1
    else:
        return 2

func get_split_ratio(position: Vector3, axis: int) -> float:
    # Use gradient to influence split position
    var center_influence = calculate_partition_probability(position)
    var base_ratio = 0.5
    var variation = randf_range(-0.2, 0.2) * (1.0 - center_bias)
    
    return clamp(base_ratio + variation * center_influence, 0.3, 0.7)

func collect_leaves(node: BSPNode):
    if node.is_leaf:
        all_cells.append(node)
    else:
        for child in node.children:
            collect_leaves(child)

func visualize_partitions():
    clear_children()
    
    for cell in all_cells:
        var color_intensity = cell.partition_probability
        var color = Color(1.0 - color_intensity, color_intensity, 0.5, 0.6)
        var node := _create_box_geo_nodes(cell.bounds, color)
        add_child(node)

func _create_box_geo_nodes(bounds: AABB, color: Color) -> Node3D:
    var container := Node3D.new()
    
    var corners := [
        bounds.position,
        bounds.position + Vector3(bounds.size.x, 0, 0),
        bounds.position + Vector3(bounds.size.x, bounds.size.y, 0),
        bounds.position + Vector3(0, bounds.size.y, 0),
        bounds.position + Vector3(0, 0, bounds.size.z),
        bounds.position + Vector3(bounds.size.x, 0, bounds.size.z),
        bounds.position + bounds.size,
        bounds.position + Vector3(0, bounds.size.y, bounds.size.z)
    ]
    
    var edges := [
        [0,1], [1,2], [2,3], [3,0],  # Bottom
        [4,5], [5,6], [6,7], [7,4],  # Top
        [0,4], [1,5], [2,6], [3,7]   # Vertical
    ]
    
    # Materials
    var edge_mat := StandardMaterial3D.new()
    edge_mat.albedo_color = color
    edge_mat.flags_transparent = true
    
    var corner_mat := StandardMaterial3D.new()
    corner_mat.albedo_color = color
    corner_mat.flags_transparent = true
    
    # Edge cylinders
    var edge_radius := 0.03
    for e in edges:
        var a: Vector3 = corners[e[0]]
        var b: Vector3 = corners[e[1]]
        var dir: Vector3 = (b - a)
        var length := dir.length()
        if length <= 0.0001:
            continue
        var mid := a.lerp(b, 0.5)
        dir = dir / length
        var up := Vector3.UP
        if abs(dir.dot(Vector3.UP)) > 0.9:
            up = Vector3.RIGHT
        var x_axis := up.cross(dir).normalized()
        var z_axis := dir.cross(x_axis).normalized()
        var basis := Basis(x_axis, dir, z_axis)  # Y axis along dir
        
        var cyl := MeshInstance3D.new()
        var cyl_mesh := CylinderMesh.new()
        cyl_mesh.top_radius = edge_radius
        cyl_mesh.bottom_radius = edge_radius
        cyl_mesh.height = length
        cyl_mesh.radial_segments = 8
        cyl.mesh = cyl_mesh
        cyl.material_override = edge_mat
        
        var t := Transform3D(basis, mid)
        cyl.transform = t
        container.add_child(cyl)
    
    # Corner spheres
    var corner_radius := 0.06
    for c in corners:
        var s := MeshInstance3D.new()
        var s_mesh := SphereMesh.new()
        s_mesh.radius = corner_radius
        s_mesh.height = s_mesh.radius
        s.mesh = s_mesh
        s.material_override = corner_mat
        s.transform.origin = c
        container.add_child(s)
    
    return container

func create_heatmap_mesh():
    # Create a plane mesh showing the partition probability heatmap
    var heatmap_mesh = MeshInstance3D.new()
    add_child(heatmap_mesh)
    heatmap_mesh.position.y = -space_size.y / 2 - 0.5
    
    var resolution = 50
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    for x in range(resolution):
        for z in range(resolution):
            var x_pos = (float(x) / resolution - 0.5) * space_size.x
            var z_pos = (float(z) / resolution - 0.5) * space_size.z
            
            var pos = Vector3(x_pos, 0, z_pos)
            var prob = calculate_partition_probability(pos)
            
            # Create color gradient (purple to yellow like the reference)
            var color = Color(prob, prob * 0.8, 1.0 - prob * 0.5)
            
            if x < resolution - 1 and z < resolution - 1:
                var p1 = Vector3(x_pos, 0, z_pos)
                var p2 = Vector3(x_pos + space_size.x / resolution, 0, z_pos)
                var p3 = Vector3(x_pos + space_size.x / resolution, 0, z_pos + space_size.z / resolution)
                var p4 = Vector3(x_pos, 0, z_pos + space_size.z / resolution)
                
                surface_tool.set_color(color)
                surface_tool.add_vertex(p1)
                surface_tool.add_vertex(p2)
                surface_tool.add_vertex(p3)
                
                surface_tool.add_vertex(p1)
                surface_tool.add_vertex(p3)
                surface_tool.add_vertex(p4)
    
    heatmap_mesh.mesh = surface_tool.commit()

func clear_children():
    for child in get_children():
        child.queue_free()
