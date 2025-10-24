class_name SixteenCellNetSpace
extends Node3D

enum NetPattern {
    OCTAHEDRAL_CORE,    # 16 tetrahedra around octahedral core
    DOUBLE_PYRAMID,     # Two square pyramids base-to-base arrangement
    TETRAHEDRAL_STAR,   # Star-like tetrahedral arrangement
    COMPACT_CLUSTER     # Compact close-packed arrangement
}

@export_group("Space Configuration")
@export var net_pattern: NetPattern = NetPattern.OCTAHEDRAL_CORE
@export var space_size: Vector3i = Vector3i(5, 3, 5)
@export var tetrahedron_size: float = 0.8
@export var spacing: float = 0.2
@export var create_hollow_center: bool = true
@export var hollow_radius: float = 2.0

@export_group("Arrangement")
@export var rotation_variety: bool = true
@export var offset_pattern: bool = true
@export var spiral_arrangement: bool = false

@export_group("Visual")
@export var base_color: Color = Color(0.2, 0.8, 0.9)
@export var use_rainbow_gradient: bool = false
@export var emission_strength: float = 0.5
@export var show_edges: bool = true
@export var transparency: float = 0.3

func _ready():
    generate_16cell_space()

func generate_16cell_space():
    """Generate continuous hollow space from 16-cell nets"""
    # Clear existing
    for child in get_children():
        child.queue_free()
    
    var net_bounds = get_net_bounds()
    var net_spacing = net_bounds + Vector3.ONE * spacing
    
    # Generate grid of 16-cell nets
    var net_count = 0
    
    for x in range(space_size.x):
        for y in range(space_size.y):
            for z in range(space_size.z):
                var pos = Vector3(x, y, z) * net_spacing
                
                # Center the structure
                pos -= Vector3(space_size) * net_spacing / 2.0
                
                # Create hollow center
                if create_hollow_center:
                    var center = Vector3.ZERO
                    if spiral_arrangement:
                        # Spiral hollow tunnel
                        var height_offset = Vector3(
                            cos(y * 0.5) * hollow_radius,
                            0,
                            sin(y * 0.5) * hollow_radius
                        )
                        center = height_offset
                    
                    if pos.distance_to(center) < hollow_radius:
                        continue
                
                # Offset pattern for interlocking
                if offset_pattern:
                    var offset_index = (x + y * 2 + z * 3) % 3
                    pos += Vector3(offset_index * 0.3, 0, 0)
                
                # Calculate rotation
                var rotation = Vector3.ZERO
                if rotation_variety:
                    rotation.y = PI / 3.0 * ((x + z) % 6)
                    rotation.x = PI / 4.0 * (y % 4)
                
                # Color variation
                var color = base_color
                if use_rainbow_gradient:
                    var hue = float(x + y + z) / (space_size.x + space_size.y + space_size.z)
                    color = Color.from_hsv(hue, 0.8, 0.9)
                
                create_16cell_net(pos, rotation, color)
                net_count += 1
    
    print("Generated 16-cell net space: ", net_count, " nets, each with 16 tetrahedra")

func get_net_bounds() -> Vector3:
    """Get bounding box of the 16-cell net"""
    match net_pattern:
        NetPattern.OCTAHEDRAL_CORE:
            return Vector3(3, 3, 3) * tetrahedron_size
        NetPattern.DOUBLE_PYRAMID:
            return Vector3(2.5, 4, 2.5) * tetrahedron_size
        NetPattern.TETRAHEDRAL_STAR:
            return Vector3(3.5, 3.5, 3.5) * tetrahedron_size
        NetPattern.COMPACT_CLUSTER:
            return Vector3(2.5, 2.5, 2.5) * tetrahedron_size
    
    return Vector3(3, 3, 3) * tetrahedron_size

func create_16cell_net(pos: Vector3, rotation: Vector3, color: Color):
    """Create a 16-cell net at the given position"""
    var net_node = Node3D.new()
    net_node.position = pos
    net_node.rotation = rotation
    add_child(net_node)
    
    match net_pattern:
        NetPattern.OCTAHEDRAL_CORE:
            create_octahedral_core_net(net_node, color)
        NetPattern.DOUBLE_PYRAMID:
            create_double_pyramid_net(net_node, color)
        NetPattern.TETRAHEDRAL_STAR:
            create_tetrahedral_star_net(net_node, color)
        NetPattern.COMPACT_CLUSTER:
            create_compact_cluster_net(net_node, color)

func create_octahedral_core_net(parent: Node3D, color: Color):
    """16-cell net based on octahedral symmetry"""
    var s = tetrahedron_size
    
    # Create 16 tetrahedra around octahedral vertices
    # Octahedron has 6 vertices at ±1 on each axis
    var octahedron_verts = [
        Vector3(1, 0, 0), Vector3(-1, 0, 0),
        Vector3(0, 1, 0), Vector3(0, -1, 0),
        Vector3(0, 0, 1), Vector3(0, 0, -1)
    ]
    
    # Create tetrahedra at each face of octahedron
    var face_centers = [
        Vector3(0.5, 0.5, 0.5), Vector3(0.5, 0.5, -0.5),
        Vector3(0.5, -0.5, 0.5), Vector3(0.5, -0.5, -0.5),
        Vector3(-0.5, 0.5, 0.5), Vector3(-0.5, 0.5, -0.5),
        Vector3(-0.5, -0.5, 0.5), Vector3(-0.5, -0.5, -0.5),
        # Additional tetrahedra
        Vector3(0.7, 0, 0), Vector3(-0.7, 0, 0),
        Vector3(0, 0.7, 0), Vector3(0, -0.7, 0),
        Vector3(0, 0, 0.7), Vector3(0, 0, -0.7),
        Vector3(0, 0, 0), Vector3(0.3, 0.3, 0.3)
    ]
    
    for i in range(16):
        var tet_color = color
        if use_rainbow_gradient:
            tet_color = Color.from_hsv(float(i) / 16.0, 0.8, 0.9)
        else:
            tet_color = color.lerp(Color.WHITE, float(i) / 24.0)
        
        var tet_pos = face_centers[i] * s * 1.5
        var tet_rot = Vector3(
            randf() * TAU if rotation_variety else 0,
            randf() * TAU if rotation_variety else 0,
            randf() * TAU if rotation_variety else 0
        )
        
        create_tetrahedron(parent, tet_pos, tet_rot, tet_color)

func create_double_pyramid_net(parent: Node3D, color: Color):
    """Double square pyramid arrangement"""
    var s = tetrahedron_size
    
    # Bottom pyramid (4 tetrahedra)
    for i in range(4):
        var angle = i * PI / 2.0
        var pos = Vector3(cos(angle), -1, sin(angle)) * s
        create_tetrahedron(parent, pos, Vector3(0, angle, 0), color)
    
    # Middle ring (8 tetrahedra)
    for i in range(8):
        var angle = i * PI / 4.0
        var pos = Vector3(cos(angle) * 1.2, 0, sin(angle) * 1.2) * s
        create_tetrahedron(parent, pos, Vector3(0, angle, 0), color.lerp(Color.WHITE, 0.3))
    
    # Top pyramid (4 tetrahedra)
    for i in range(4):
        var angle = i * PI / 2.0 + PI / 4.0
        var pos = Vector3(cos(angle), 1, sin(angle)) * s
        create_tetrahedron(parent, pos, Vector3(0, angle, PI), color.lerp(Color.WHITE, 0.6))

func create_tetrahedral_star_net(parent: Node3D, color: Color):
    """Star-like arrangement with tetrahedral symmetry"""
    var s = tetrahedron_size
    
    # 4 main directions (tetrahedral vertices)
    var tet_directions = [
        Vector3(1, 1, 1).normalized(),
        Vector3(1, -1, -1).normalized(),
        Vector3(-1, 1, -1).normalized(),
        Vector3(-1, -1, 1).normalized()
    ]
    
    # Place 4 tetrahedra along each direction
    for dir in tet_directions:
        for dist in range(4):
            var pos = dir * (dist + 0.5) * s * 1.2
            var col = color.lerp(Color.WHITE, dist / 6.0)
            create_tetrahedron(parent, pos, Vector3.ZERO, col)

func create_compact_cluster_net(parent: Node3D, color: Color):
    """Compact close-packed arrangement"""
    var s = tetrahedron_size * 0.8
    
    # Dense packing pattern
    var positions = []
    for i in range(2):
        for j in range(2):
            for k in range(2):
                positions.append(Vector3(i - 0.5, j - 0.5, k - 0.5) * s * 1.5)
    
    # Additional positions for 16 total
    positions.append(Vector3(1.5, 0, 0) * s)
    positions.append(Vector3(-1.5, 0, 0) * s)
    positions.append(Vector3(0, 1.5, 0) * s)
    positions.append(Vector3(0, -1.5, 0) * s)
    positions.append(Vector3(0, 0, 1.5) * s)
    positions.append(Vector3(0, 0, -1.5) * s)
    positions.append(Vector3(1, 1, 0) * s)
    positions.append(Vector3(-1, -1, 0) * s)
    
    for i in range(min(16, positions.size())):
        var col = color.lerp(Color.WHITE, float(i) / 20.0)
        create_tetrahedron(parent, positions[i], Vector3.ZERO, col)

func create_tetrahedron(parent: Node3D, pos: Vector3, rot: Vector3, color: Color):
    """Create a single tetrahedron"""
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.position = pos
    mesh_instance.rotation = rot
    
    # Create tetrahedron mesh
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    var s = tetrahedron_size * 0.9  # Slightly smaller for gaps
    
    # Tetrahedron vertices
    var h = s * sqrt(2.0/3.0)
    var verts = [
        Vector3(0, h/2, 0),                    # Top
        Vector3(-s/2, -h/2, -s/sqrt(3)/2),     # Base 1
        Vector3(s/2, -h/2, -s/sqrt(3)/2),      # Base 2
        Vector3(0, -h/2, s/sqrt(3))            # Base 3
    ]
    
    # 4 triangular faces
    var faces = [
        [0, 2, 1], [0, 3, 2], [0, 1, 3], [1, 2, 3]
    ]
    
    for face in faces:
        var v1 = verts[face[0]]
        var v2 = verts[face[1]]
        var v3 = verts[face[2]]
        
        var normal = (v2 - v1).cross(v3 - v1).normalized()
        
        surface_tool.set_normal(normal)
        surface_tool.add_vertex(v1)
        surface_tool.set_normal(normal)
        surface_tool.add_vertex(v2)
        surface_tool.set_normal(normal)
        surface_tool.add_vertex(v3)
    
    mesh_instance.mesh = surface_tool.commit()
    
    # Material
    var material = StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = emission_strength > 0
    material.emission = color
    material.emission_energy_multiplier = emission_strength
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color.a = 1.0 - transparency
    material.cull_mode = BaseMaterial3D.CULL_DISABLED  # See both sides
    
    mesh_instance.material_override = material
    parent.add_child(mesh_instance)
    
    # Add edge wireframe
    if show_edges:
        var edges = create_tetrahedron_edges(verts, color * 0.5)
        edges.position = pos
        edges.rotation = rot
        parent.add_child(edges)

func create_tetrahedron_edges(verts: Array, color: Color) -> MeshInstance3D:
    """Create edge wireframe for tetrahedron"""
    var immediate_mesh = ImmediateMesh.new()
    var mesh_instance = MeshInstance3D.new()
    
    immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    
    # 6 edges
    var edges = [
        [0, 1], [0, 2], [0, 3],
        [1, 2], [2, 3], [3, 1]
    ]
    
    for edge in edges:
        immediate_mesh.surface_set_color(color)
        immediate_mesh.surface_add_vertex(verts[edge[0]])
        immediate_mesh.surface_set_color(color)
        immediate_mesh.surface_add_vertex(verts[edge[1]])
    
    immediate_mesh.surface_end()
    mesh_instance.mesh = immediate_mesh
    
    var material = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.vertex_color_use_as_albedo = true
    mesh_instance.material_override = material
    
    return mesh_instance

func regenerate():
    generate_16cell_space()

func get_16cell_space_stats() -> Dictionary:
    """Get statistics about the generated 16-cell space"""
    var total_nets = 0
    var total_tetrahedra = 0
    
    for child in get_children():
        if child is Node3D:
            total_nets += 1
            total_tetrahedra += child.get_child_count()
    
    return {
        "total_nets": total_nets,
        "total_tetrahedra": total_tetrahedra,
        "net_pattern": NetPattern.keys()[net_pattern],
        "space_size": space_size,
        "tetrahedron_size": tetrahedron_size,
        "spacing": spacing,
        "hollow_center": create_hollow_center,
        "hollow_radius": hollow_radius,
        "spiral_arrangement": spiral_arrangement,
        "rotation_variety": rotation_variety,
        "offset_pattern": offset_pattern,
        "rainbow_gradient": use_rainbow_gradient,
        "transparency": transparency
    }








