class_name TesseractNetSpace
extends Node3D

enum NetType {
    DALI_CROSS,        # Classic cross: 1 center + 6 around (most common)
    LINEAR_CHAIN,      # 8 cubes in a line
    FOLDED_CHAIN,      # Curved chain of cubes
    DOUBLE_CROSS       # Two crosses perpendicular
}

@export_group("Space Configuration")
@export var net_type: NetType = NetType.DALI_CROSS
@export var space_size: Vector3i = Vector3i(5, 3, 5)  # How many nets in each direction
@export var cube_size: float = 1.0
@export var spacing: float = 0.1  # Gap between nets
@export var create_hollow_center: bool = true

@export_group("Net Arrangement")
@export var rotation_variety: bool = true  # Rotate nets for variety
@export var offset_pattern: bool = true    # Offset nets for interlocking

@export_group("Visual")
@export var base_color: Color = Color(0.8, 0.2, 0.2)
@export var color_variation: bool = true
@export var emission_strength: float = 0.3
@export var show_wireframe: bool = true

func _ready():
    generate_net_space()

func generate_net_space():
    """Generate hollow 3D space from tesseract nets"""
    # Clear existing
    for child in get_children():
        child.queue_free()
    
    # Calculate net dimensions
    var net_bounds = get_net_bounds()
    var net_spacing = net_bounds + Vector3.ONE * spacing
    
    # Generate grid of nets
    for x in range(space_size.x):
        for y in range(space_size.y):
            for z in range(space_size.z):
                # Skip center for hollow space
                if create_hollow_center:
                    var center = Vector3(space_size) / 2.0
                    var dist = Vector3(x, y, z).distance_to(center)
                    if dist < 1.5:  # Hollow radius
                        continue
                
                # Calculate position
                var pos = Vector3(
                    x * net_spacing.x,
                    y * net_spacing.y,
                    z * net_spacing.z
                )
                
                # Center the whole structure
                pos -= Vector3(space_size) * net_spacing / 2.0
                
                # Add offset pattern for interlocking
                if offset_pattern and (x + y + z) % 2 == 1:
                    pos += net_spacing / 3.0
                
                # Create net at position
                var rotation = 0.0
                if rotation_variety:
                    # Rotate based on position for variety
                    rotation = PI / 2.0 * ((x + y * 2 + z * 3) % 4)
                
                var color_mod = 1.0
                if color_variation:
                    color_mod = 0.7 + 0.3 * ((x + y + z) % 3) / 2.0
                
                create_net_at_position(pos, rotation, base_color * color_mod)
    
    print("Generated tesseract net space: ", space_size.x * space_size.y * space_size.z, " nets")

func get_net_bounds() -> Vector3:
    """Get the bounding box size of the selected net type"""
    match net_type:
        NetType.DALI_CROSS:
            # Cross is 4 cubes wide (3 units) in X and Z, 4 cubes tall in Y
            return Vector3(3, 4, 3) * cube_size
        NetType.LINEAR_CHAIN:
            return Vector3(8, 1, 1) * cube_size
        NetType.FOLDED_CHAIN:
            return Vector3(4, 2, 3) * cube_size
        NetType.DOUBLE_CROSS:
            return Vector3(3, 3, 3) * cube_size
    
    return Vector3(3, 4, 3) * cube_size

func create_net_at_position(pos: Vector3, rotation_y: float, color: Color):
    """Create a tesseract net at the given position"""
    var net_node = Node3D.new()
    net_node.position = pos
    net_node.rotation.y = rotation_y
    add_child(net_node)
    
    match net_type:
        NetType.DALI_CROSS:
            create_dali_cross(net_node, color)
        NetType.LINEAR_CHAIN:
            create_linear_chain(net_node, color)
        NetType.FOLDED_CHAIN:
            create_folded_chain(net_node, color)
        NetType.DOUBLE_CROSS:
            create_double_cross(net_node, color)

func create_dali_cross(parent: Node3D, color: Color):
    """Create the classic Dali cross tesseract net"""
    # 8 cubes in cross formation:
    # Center cube at origin
    # 6 cubes attached to each face
    # 1 additional cube extending from one
    
    var cube_positions = [
        Vector3(0, 0, 0),      # Center
        Vector3(1, 0, 0),      # Right
        Vector3(-1, 0, 0),     # Left
        Vector3(0, 1, 0),      # Top
        Vector3(0, -1, 0),     # Bottom
        Vector3(0, 0, 1),      # Front
        Vector3(0, 0, -1),     # Back
        Vector3(0, -2, 0)      # Extended bottom
    ]
    
    for i in range(cube_positions.size()):
        var cube_pos = cube_positions[i] * cube_size
        var cube_color = color
        
        # Vary color slightly per cube
        if color_variation:
            cube_color = cube_color.lerp(Color.WHITE, float(i) / 16.0)
        
        create_cube(parent, cube_pos, cube_color)

func create_linear_chain(parent: Node3D, color: Color):
    """Create a linear chain of 8 cubes"""
    for i in range(8):
        var pos = Vector3((i - 3.5) * cube_size, 0, 0)
        var cube_color = color.lerp(Color.WHITE, float(i) / 12.0)
        create_cube(parent, pos, cube_color)

func create_folded_chain(parent: Node3D, color: Color):
    """Create a folded/zigzag chain"""
    var positions = [
        Vector3(0, 0, 0),
        Vector3(1, 0, 0),
        Vector3(2, 0, 0),
        Vector3(2, 1, 0),
        Vector3(2, 1, 1),
        Vector3(1, 1, 1),
        Vector3(0, 1, 1),
        Vector3(0, 0, 1)
    ]
    
    for i in range(positions.size()):
        var pos = (positions[i] - Vector3(1, 0.5, 0.5)) * cube_size
        var cube_color = color.lerp(Color.WHITE, float(i) / 12.0)
        create_cube(parent, pos, cube_color)

func create_double_cross(parent: Node3D, color: Color):
    """Create two perpendicular crosses"""
    # First cross (XY plane)
    var positions = [
        Vector3(0, 0, 0),
        Vector3(1, 0, 0),
        Vector3(-1, 0, 0),
        Vector3(0, 1, 0),
        Vector3(0, -1, 0),
        # Second cross (YZ plane)
        Vector3(0, 0, 1),
        Vector3(0, 0, -1),
        Vector3(0, 1, 1)  # Extension
    ]
    
    for i in range(positions.size()):
        var pos = positions[i] * cube_size
        var cube_color = color.lerp(Color.WHITE, float(i) / 12.0)
        create_cube(parent, pos, cube_color)

func create_cube(parent: Node3D, pos: Vector3, color: Color):
    """Create a single cube mesh"""
    var mesh_instance = MeshInstance3D.new()
    
    var box_mesh = BoxMesh.new()
    box_mesh.size = Vector3.ONE * cube_size * 0.95  # Slightly smaller for gaps
    
    mesh_instance.mesh = box_mesh
    mesh_instance.position = pos
    
    # Create material
    var material = StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = emission_strength > 0
    material.emission = color
    material.emission_energy_multiplier = emission_strength
    material.metallic = 0.3
    material.roughness = 0.7
    
    mesh_instance.material_override = material
    
    parent.add_child(mesh_instance)
    
    # Add wireframe overlay
    if show_wireframe:
        var wireframe = create_cube_wireframe(pos, color * 0.5)
        parent.add_child(wireframe)

func create_cube_wireframe(pos: Vector3, color: Color) -> MeshInstance3D:
    """Create wireframe edges for a cube"""
    var immediate_mesh = ImmediateMesh.new()
    var mesh_instance = MeshInstance3D.new()
    
    immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    
    var s = cube_size * 0.95 / 2.0
    var vertices = [
        Vector3(-s, -s, -s), Vector3(s, -s, -s),
        Vector3(s, -s, s), Vector3(-s, -s, s),
        Vector3(-s, s, -s), Vector3(s, s, -s),
        Vector3(s, s, s), Vector3(-s, s, s)
    ]
    
    # 12 edges of cube
    var edge_indices = [
        [0,1],[1,2],[2,3],[3,0],  # Bottom
        [4,5],[5,6],[6,7],[7,4],  # Top
        [0,4],[1,5],[2,6],[3,7]   # Vertical
    ]
    
    for edge in edge_indices:
        immediate_mesh.surface_set_color(color)
        immediate_mesh.surface_add_vertex(vertices[edge[0]] + pos)
        immediate_mesh.surface_set_color(color)
        immediate_mesh.surface_add_vertex(vertices[edge[1]] + pos)
    
    immediate_mesh.surface_end()
    
    mesh_instance.mesh = immediate_mesh
    
    var material = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.vertex_color_use_as_albedo = true
    mesh_instance.material_override = material
    
    return mesh_instance

func regenerate():
    """Regenerate the space"""
    generate_net_space()

func get_net_space_stats() -> Dictionary:
    """Get statistics about the generated net space"""
    var total_nets = 0
    var total_cubes = 0
    
    for child in get_children():
        if child is Node3D:
            total_nets += 1
            total_cubes += child.get_child_count()
    
    return {
        "total_nets": total_nets,
        "total_cubes": total_cubes,
        "net_type": NetType.keys()[net_type],
        "space_size": space_size,
        "cube_size": cube_size,
        "spacing": spacing,
        "hollow_center": create_hollow_center,
        "rotation_variety": rotation_variety,
        "offset_pattern": offset_pattern
    }









