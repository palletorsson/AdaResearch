class_name TessellatingPortal
extends Node3D

enum PortalType {
    CUBE,
    TRUNCATED_OCTAHEDRON,
    RHOMBIC_DODECAHEDRON,
    TRIANGULAR_PRISM,
    HEXAGONAL_PRISM,
    GYROBIFASTIGIUM
}

@export_group("Portal Configuration")
@export var portal_type: PortalType = PortalType.CUBE
@export var portal_radius: float = 3.0
@export var portal_thickness: float = 1.5
@export var block_size: float = 0.5
@export var auto_generate: bool = true

@export_group("Visual")
@export var portal_color: Color = Color(0.3, 0.6, 1.0)
@export var emission_strength: float = 1.5
@export var animate_rotation: bool = true
@export var rotation_speed: float = 0.5

var transforms: Array[Transform3D] = []
var current_mesh: Mesh

func _ready():
    if auto_generate:
        generate_portal()

func _process(delta):
    if animate_rotation:
        rotate_y(rotation_speed * delta)

func generate_portal():
    """Generate the portal structure"""
    transforms.clear()
    
    # Clear existing
    for child in get_children():
        child.queue_free()
    
    # Create mesh for selected type
    current_mesh = create_mesh_for_type(portal_type)
    
    # Build portal ring
    match portal_type:
        PortalType.CUBE:
            build_cube_portal()
        PortalType.TRUNCATED_OCTAHEDRON:
            build_truncated_octahedron_portal()
        PortalType.RHOMBIC_DODECAHEDRON:
            build_rhombic_dodecahedron_portal()
        PortalType.TRIANGULAR_PRISM:
            build_triangular_prism_portal()
        PortalType.HEXAGONAL_PRISM:
            build_hexagonal_prism_portal()
        PortalType.GYROBIFASTIGIUM:
            build_gyrobifastigium_portal()
    
    create_multimesh()

func build_cube_portal():
    """Classic brick arch portal"""
    var angle_step = deg_to_rad(15)
    var total_angle = PI  # Semi-circle arch
    
    # Build arch
    var angle = 0.0
    while angle <= total_angle:
        var x = cos(angle) * portal_radius
        var y = sin(angle) * portal_radius
        
        # Multiple layers for thickness
        for layer in range(int(portal_thickness / block_size)):
            var z = (layer - portal_thickness / block_size / 2) * block_size
            var pos = Vector3(x, y, z)
            
            var t = Transform3D.IDENTITY
            t.origin = pos
            t = t.scaled(Vector3.ONE * block_size)
            transforms.append(t)
        
        angle += angle_step
    
    # Pillars on both sides
    for side in [-1, 1]:
        for h in range(int(portal_radius / block_size)):
            for layer in range(int(portal_thickness / block_size)):
                var z = (layer - portal_thickness / block_size / 2) * block_size
                var pos = Vector3(side * portal_radius, h * block_size, z)
                
                var t = Transform3D.IDENTITY
                t.origin = pos
                t = t.scaled(Vector3.ONE * block_size)
                transforms.append(t)

func build_truncated_octahedron_portal():
    """Sci-fi honeycomb portal"""
    var positions = []
    
    # Create ring pattern
    var num_around = 12
    var num_layers = 2
    
    for i in range(num_around):
        var angle = (float(i) / num_around) * TAU
        var x = cos(angle) * portal_radius
        var z = sin(angle) * portal_radius
        
        for layer in range(num_layers):
            var y = layer * block_size * 1.5
            positions.append(Vector3(x, y, z))
    
    # Add top arch
    var arch_points = 8
    for i in range(arch_points):
        var angle = (float(i) / arch_points) * PI
        var x = cos(angle) * portal_radius
        var y = sin(angle) * portal_radius + num_layers * block_size * 1.5
        positions.append(Vector3(x, y, 0))
    
    for pos in positions:
        var t = Transform3D.IDENTITY
        t.origin = pos
        t = t.scaled(Vector3.ONE * block_size)
        transforms.append(t)

func build_rhombic_dodecahedron_portal():
    """Organic crystal portal"""
    # Hexagonal ring pattern (rhombic dodecahedrons pack like this)
    var num_segments = 10
    var height_segments = 3
    
    for i in range(num_segments):
        var angle = (float(i) / num_segments) * TAU
        var x = cos(angle) * portal_radius
        var z = sin(angle) * portal_radius
        
        # Stack vertically
        for h in range(height_segments):
            var y = h * block_size * 1.2
            var pos = Vector3(x, y, z)
            
            var t = Transform3D.IDENTITY
            t.origin = pos
            t = t.rotated(Vector3.UP, angle)
            t = t.scaled(Vector3.ONE * block_size)
            transforms.append(t)
    
    # Top dome
    var dome_rings = 3
    for ring in range(dome_rings):
        var ring_radius = portal_radius * (1.0 - float(ring) / dome_rings)
        var num_in_ring = max(6, int(10 * (1.0 - float(ring) / dome_rings)))
        
        for i in range(num_in_ring):
            var angle = (float(i) / num_in_ring) * TAU
            var x = cos(angle) * ring_radius
            var z = sin(angle) * ring_radius
            var y = height_segments * block_size * 1.2 + ring * block_size * 0.8
            
            var t = Transform3D.IDENTITY
            t.origin = Vector3(x, y, z)
            t = t.scaled(Vector3.ONE * block_size)
            transforms.append(t)

func build_triangular_prism_portal():
    """Angular geometric portal"""
    # Triangular pattern
    var num_prisms = 18
    
    for i in range(num_prisms):
        var angle = (float(i) / num_prisms) * TAU
        var x = cos(angle) * portal_radius
        var z = sin(angle) * portal_radius
        
        # Point prisms outward
        var t = Transform3D.IDENTITY
        t.origin = Vector3(x, portal_radius * 0.3, z)
        t = t.rotated(Vector3.UP, angle)
        t = t.rotated(Vector3.RIGHT, PI / 2)
        t = t.scaled(Vector3.ONE * block_size)
        transforms.append(t)

func build_hexagonal_prism_portal():
    """Honeycomb portal"""
    # Hexagonal grid wrapped into circle
    var num_around = 12
    
    for ring in range(3):
        var ring_radius = portal_radius - ring * block_size
        var items = num_around - ring * 2
        
        for i in range(items):
            var angle = (float(i) / items) * TAU
            var x = cos(angle) * ring_radius
            var z = sin(angle) * ring_radius
            
            var t = Transform3D.IDENTITY
            t.origin = Vector3(x, portal_radius * 0.5, z)
            t = t.rotated(Vector3.UP, angle)
            t = t.rotated(Vector3.RIGHT, PI / 2)
            t = t.scaled(Vector3.ONE * block_size * 0.8)
            transforms.append(t)

func build_gyrobifastigium_portal():
    """Twisted dual-prism portal"""
    var num_pairs = 10
    
    for i in range(num_pairs):
        var angle = (float(i) / num_pairs) * TAU
        var x = cos(angle) * portal_radius
        var z = sin(angle) * portal_radius
        
        for offset in [0, 1]:
            var y = portal_radius * 0.3 + offset * block_size
            var twist = PI / 4 if offset == 1 else 0
            
            var t = Transform3D.IDENTITY
            t.origin = Vector3(x, y, z)
            t = t.rotated(Vector3.UP, angle + twist)
            t = t.scaled(Vector3.ONE * block_size)
            transforms.append(t)

func create_mesh_for_type(type: PortalType) -> Mesh:
    """Create appropriate mesh for portal type"""
    match type:
        PortalType.CUBE:
            return create_cube_mesh()
        PortalType.TRUNCATED_OCTAHEDRON:
            return create_truncated_octahedron_mesh()
        PortalType.RHOMBIC_DODECAHEDRON:
            return create_rhombic_dodecahedron_mesh()
        PortalType.TRIANGULAR_PRISM:
            return create_triangular_prism_mesh()
        PortalType.HEXAGONAL_PRISM:
            return create_hexagonal_prism_mesh()
        PortalType.GYROBIFASTIGIUM:
            return create_gyrobifastigium_mesh()
    
    return create_cube_mesh()

func create_cube_mesh() -> Mesh:
    """Simple cube"""
    var box_mesh = BoxMesh.new()
    box_mesh.size = Vector3.ONE
    return box_mesh

func create_triangular_prism_mesh() -> Mesh:
    """Triangular prism"""
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    var h = 1.0
    var r = 0.5
    
    # Triangle vertices
    var top = [
        Vector3(0, h/2, r),
        Vector3(r * 0.866, h/2, -r * 0.5),
        Vector3(-r * 0.866, h/2, -r * 0.5)
    ]
    var bottom = [
        Vector3(0, -h/2, r),
        Vector3(r * 0.866, -h/2, -r * 0.5),
        Vector3(-r * 0.866, -h/2, -r * 0.5)
    ]
    
    # Top face
    st.add_vertex(top[0])
    st.add_vertex(top[2])
    st.add_vertex(top[1])
    
    # Bottom face
    st.add_vertex(bottom[0])
    st.add_vertex(bottom[1])
    st.add_vertex(bottom[2])
    
    # Sides
    for i in range(3):
        var next_i = (i + 1) % 3
        st.add_vertex(top[i])
        st.add_vertex(bottom[i])
        st.add_vertex(top[next_i])
        
        st.add_vertex(top[next_i])
        st.add_vertex(bottom[i])
        st.add_vertex(bottom[next_i])
    
    return st.commit()

func create_hexagonal_prism_mesh() -> Mesh:
    """Hexagonal prism"""
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    var h = 1.0
    var r = 0.5
    var sides = 6
    
    # Top and bottom hexagons
    for face in [h/2, -h/2]:
        for i in range(sides):
            var angle1 = (float(i) / sides) * TAU
            var angle2 = (float((i + 1) % sides) / sides) * TAU
            
            st.add_vertex(Vector3(0, face, 0))
            if face > 0:
                st.add_vertex(Vector3(cos(angle2) * r, face, sin(angle2) * r))
                st.add_vertex(Vector3(cos(angle1) * r, face, sin(angle1) * r))
            else:
                st.add_vertex(Vector3(cos(angle1) * r, face, sin(angle1) * r))
                st.add_vertex(Vector3(cos(angle2) * r, face, sin(angle2) * r))
    
    # Sides
    for i in range(sides):
        var angle1 = (float(i) / sides) * TAU
        var angle2 = (float((i + 1) % sides) / sides) * TAU
        
        var t1 = Vector3(cos(angle1) * r, h/2, sin(angle1) * r)
        var t2 = Vector3(cos(angle2) * r, h/2, sin(angle2) * r)
        var b1 = Vector3(cos(angle1) * r, -h/2, sin(angle1) * r)
        var b2 = Vector3(cos(angle2) * r, -h/2, sin(angle2) * r)
        
        st.add_vertex(t1)
        st.add_vertex(b1)
        st.add_vertex(t2)
        
        st.add_vertex(t2)
        st.add_vertex(b1)
        st.add_vertex(b2)
    
    return st.commit()

func create_truncated_octahedron_mesh() -> Mesh:
    """Simplified truncated octahedron"""
    # Using a rounded cube as approximation for simplicity
    var sphere = SphereMesh.new()
    sphere.radial_segments = 6
    sphere.rings = 6
    sphere.radius = 0.5
    sphere.height = 1.0
    return sphere

func create_rhombic_dodecahedron_mesh() -> Mesh:
    """Simplified rhombic dodecahedron"""
    var sphere = SphereMesh.new()
    sphere.radial_segments = 8
    sphere.rings = 6
    sphere.radius = 0.5
    sphere.height = 1.0
    return sphere

func create_gyrobifastigium_mesh() -> Mesh:
    """Two triangular prisms joined with twist"""
    return create_triangular_prism_mesh()

func create_multimesh():
    """Create MultiMeshInstance3D"""
    var mmi = MultiMeshInstance3D.new()
    var mm = MultiMesh.new()
    
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = current_mesh
    mm.instance_count = transforms.size()
    
    for i in transforms.size():
        mm.set_instance_transform(i, transforms[i])
    
    mmi.multimesh = mm
    
    # Create glowing material
    var material = StandardMaterial3D.new()
    material.albedo_color = portal_color
    material.emission_enabled = true
    material.emission = portal_color
    material.emission_energy_multiplier = emission_strength
    material.metallic = 0.3
    material.roughness = 0.7
    
    mmi.material_override = material
    
    add_child(mmi)
    print("Portal generated with ", transforms.size(), " blocks")

func regenerate():
    """Regenerate portal"""
    generate_portal()

func set_portal_type(type: PortalType):
    """Change portal type and regenerate"""
    portal_type = type
    generate_portal()

func get_portal_stats() -> Dictionary:
    """Get statistics about the generated portal"""
    return {
        "total_blocks": transforms.size(),
        "portal_type": PortalType.keys()[portal_type],
        "portal_radius": portal_radius,
        "block_size": block_size,
        "portal_thickness": portal_thickness
    }

