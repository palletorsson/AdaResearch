# SplitQuad.gd - Creates a quad split into two triangles with different colors
extends Node3D

var vertex_color: Color = Color(1.0, 0.8, 0.2)  # Golden spheres
@export var sphere_size_multiplier: float = 1.2
@export var sphere_y_offset: float = 0.0

## Freeze behavior options
@export var alter_freeze : bool = false  # Keep quad fixed; points move freely

# Two triangle mesh instances - one pink, one black
var triangle_mesh_pink: MeshInstance3D
var triangle_mesh_black: MeshInstance3D
var drag_points: DragPointSet

# Quad has 4 corner points that define 2 triangles
var vertex_positions: Array[Vector3] = [
    Vector3(-1.0, sphere_y_offset - 1.0, 0.0),  # Bottom-left (0)
    Vector3(1.0, sphere_y_offset - 1.0, 0.0),   # Bottom-right (1)
    Vector3(1.0, sphere_y_offset + 1.0, 0.0),   # Top-right (2)
    Vector3(-1.0, sphere_y_offset + 1.0, 0.0)   # Top-left (3)
]

# Define the two triangles from the quad
# Triangle 1: Bottom-left, Bottom-right, Top-right (indices 0,1,2)
# Triangle 2: Bottom-left, Top-right, Top-left (indices 0,2,3)
var triangle1_indices: Array[int] = [0, 1, 2]  # Pink triangle
var triangle2_indices: Array[int] = [0, 2, 3]  # Black triangle

func _ready():
    drag_points = DragPointSet.new()
    drag_points.name = "DragPoints"
    add_child(drag_points)

    drag_points.point_picked_up.connect(_on_point_picked_up)
    drag_points.point_dropped.connect(_on_point_dropped)
    drag_points.point_moved.connect(_on_point_moved)

    create_triangle_meshes()
    _setup_drag_points()
    update_triangle_meshes()
    print_help()

func create_triangle_meshes():
    # Create pink triangle mesh
    triangle_mesh_pink = MeshInstance3D.new()
    triangle_mesh_pink.name = "TriangleMesh_Pink"
    apply_triangle_material(triangle_mesh_pink, Color.DEEP_PINK)
    add_child(triangle_mesh_pink)

    # Create black triangle mesh
    triangle_mesh_black = MeshInstance3D.new()
    triangle_mesh_black.name = "TriangleMesh_Black"
    apply_triangle_material(triangle_mesh_black, Color.BLACK)
    add_child(triangle_mesh_black)

func _setup_drag_points():
    var point_configs: Array = []
    for i in range(vertex_positions.size()):
        point_configs.append({
            "id": i,
            "name": "GrabSphere_%d" % i,
            "position": vertex_positions[i],
            "meta": {"vertex_index": i},
            "scale": sphere_size_multiplier,
            "color": vertex_color
        })

    drag_points.setup(point_configs, {
        "freeze_on_drop": true,
        "unfreeze_on_pickup": true,
        "alter_freeze": alter_freeze
    })

func update_triangle_meshes():
    # Update both triangle meshes
    update_single_triangle_mesh(triangle_mesh_pink, triangle1_indices)
    update_single_triangle_mesh(triangle_mesh_black, triangle2_indices)

func update_single_triangle_mesh(mesh_instance: MeshInstance3D, indices: Array[int]):
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    # Get the three vertices for this triangle
    var triangle_vertices = [
        vertex_positions[indices[0]],
        vertex_positions[indices[1]],
        vertex_positions[indices[2]]
    ]

    # Create the triangle face
    add_triangle_with_normal(st, triangle_vertices, [0, 1, 2])

    # Commit the mesh
    mesh_instance.mesh = st.commit()

func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
    var v0 = vertices[face[0]]
    var v1 = vertices[face[1]]
    var v2 = vertices[face[2]]

    # Calculate face normal
    var edge1 = v1 - v0
    var edge2 = v2 - v0
    var normal = edge1.cross(edge2).normalized()

    # Add vertices with normal and UV coordinates (front face)
    st.set_normal(normal)
    st.set_uv(Vector2(0.0, 0.0))
    st.add_vertex(v0)

    st.set_normal(normal)
    st.set_uv(Vector2(1.0, 0.0))
    st.add_vertex(v1)

    st.set_normal(normal)
    st.set_uv(Vector2(0.5, 1.0))
    st.add_vertex(v2)

    # Add the back face for double-sided rendering
    st.set_normal(-normal)
    st.set_uv(Vector2(0.0, 0.0))
    st.add_vertex(v0)

    st.set_normal(-normal)
    st.set_uv(Vector2(0.5, 1.0))
    st.add_vertex(v2)

    st.set_normal(-normal)
    st.set_uv(Vector2(1.0, 0.0))
    st.add_vertex(v1)

func _on_point_picked_up(index: int, _pickable, _meta: Dictionary) -> void:
    print("DEBUG PICKUP")

func _on_point_dropped(index: int, _pickable, _meta: Dictionary) -> void:
    print("quad sphere dropped ")
    var quad_context := {
        "vertex": index,
        "pink_area": "%.2f" % get_triangle_area(triangle1_indices),
        "black_area": "%.2f" % get_triangle_area(triangle2_indices),
        "total_area": "%.2f" % (get_triangle_area(triangle1_indices) + get_triangle_area(triangle2_indices))
    }

    var handled := false
    if typeof(TextManager) != TYPE_NIL and TextManager.has_method("trigger_event"):
        handled = TextManager.trigger_event("quad_drop", quad_context)

    if handled and typeof(GameManager) != TYPE_NIL and GameManager.has_method("add_console_message"):
        var status := "Quad vertex %d dropped. Pink area %s, black area %s, total area %s" % [
            quad_context["vertex"],
            quad_context["pink_area"],
            quad_context["black_area"],
            quad_context["total_area"]
        ]
        GameManager.add_console_message(status, "info", "interactive_quad")
    elif not handled:
        push_warning("SplitQuad: Missing quad_drop text entry for current map")

func _on_point_moved(index: int, position: Vector3, _meta: Dictionary) -> void:
    if index < 0 or index >= vertex_positions.size():
        return
    if vertex_positions[index] == position:
        return
    vertex_positions[index] = position
    update_triangle_meshes()

func update_sphere_positions():
    if drag_points:
        drag_points.set_points_positions(vertex_positions)
    update_triangle_meshes()

func set_vertex_color(color: Color):
    vertex_color = color
    if not drag_points:
        return
    drag_points.for_each_sphere(func(sphere):
        var mesh_instance = sphere.get_node("MeshInstance3D")
        if mesh_instance:
            var material = mesh_instance.material_override as StandardMaterial3D
            if material:
                material.albedo_color = vertex_color
                material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
                material.emission = Color(0.1, 0.4, 0.2) * 0.3
                material.roughness = 0.1
                material.metallic = 0.0
                material.refraction = 0.05
    ))

func apply_triangle_material(mesh_instance: MeshInstance3D, color: Color):
    var material = ShaderMaterial.new()
    var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
    if shader:
        material.shader = shader

        # Use the input color parameter to determine which triangle gets which color
        var chosen_color: Color
        if color == Color.DEEP_PINK:
            chosen_color = Color.DEEP_PINK
        elif color == Color.BLACK:
            chosen_color = Color.BLACK
        else:
            # Fallback to random selection for other colors
            var rand = randi() % 3
            if rand == 0:
                chosen_color = Color.BLACK
            elif rand == 1:
                chosen_color = Color.DEEP_PINK
            else:  # rand == 2
                chosen_color = Color.RED

        material.set_shader_parameter("wireframe_color", chosen_color)
        material.set_shader_parameter("fill_color", chosen_color)
        mesh_instance.material_override = material
    else:
        # Fallback to standard material if shader fails to load
        var standard_material = StandardMaterial3D.new()
        standard_material.albedo_color = color
        standard_material.emission_enabled = true
        standard_material.emission = color * 0.3
        standard_material.cull_mode = BaseMaterial3D.CULL_DISABLED
        mesh_instance.material_override = standard_material

func _input(event):
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_R:
                reset_to_square()
            KEY_Q:
                reset_to_quad()
            KEY_D:
                reset_to_diamond()
            KEY_T:
                reset_to_trapezoid()

func reset_to_square():
    # Reset to perfect square
    vertex_positions = [
        Vector3(-1.0, sphere_y_offset - 1.0, 0.0),  # Bottom-left
        Vector3(1.0, sphere_y_offset - 1.0, 0.0),   # Bottom-right
        Vector3(1.0, sphere_y_offset + 1.0, 0.0),   # Top-right
        Vector3(-1.0, sphere_y_offset + 1.0, 0.0)   # Top-left
    ]
    update_sphere_positions()
    print("Reset to square shape")

func reset_to_quad():
    # Reset to rectangular quad
    vertex_positions = [
        Vector3(-1.5, sphere_y_offset - 0.8, 0.0),  # Bottom-left
        Vector3(1.5, sphere_y_offset - 0.8, 0.0),   # Bottom-right
        Vector3(1.5, sphere_y_offset + 0.8, 0.0),   # Top-right
        Vector3(-1.5, sphere_y_offset + 0.8, 0.0)   # Top-left
    ]
    update_sphere_positions()
    print("Reset to rectangular quad")

func reset_to_diamond():
    # Reset to diamond shape
    vertex_positions = [
        Vector3(0.0, sphere_y_offset - 1.2, 0.0),   # Bottom
        Vector3(1.2, sphere_y_offset, 0.0),        # Right
        Vector3(0.0, sphere_y_offset + 1.2, 0.0),  # Top
        Vector3(-1.2, sphere_y_offset, 0.0)        # Left
    ]
    update_sphere_positions()
    print("Reset to diamond shape")

func reset_to_trapezoid():
    # Reset to trapezoid shape
    vertex_positions = [
        Vector3(-1.2, sphere_y_offset - 1.0, 0.0),  # Bottom-left
        Vector3(1.2, sphere_y_offset - 1.0, 0.0),   # Bottom-right
        Vector3(0.8, sphere_y_offset + 1.0, 0.0),   # Top-right
        Vector3(-0.8, sphere_y_offset + 1.0, 0.0)   # Top-left
    ]
    update_sphere_positions()
    print("Reset to trapezoid shape")

func print_help():
    print("=== Split Quad Controls ===")
    print("Mouse: Drag the corner spheres to reshape the quad")
    print("R: Reset to square")
    print("Q: Reset to rectangular quad")
    print("D: Reset to diamond")
    print("T: Reset to trapezoid")
    print("Pink Triangle: Bottom-left -> Bottom-right -> Top-right")
    print("Black Triangle: Bottom-left -> Top-right -> Top-left")
    print("============================")

func get_quad_info() -> Dictionary:
    return {
        "vertices": vertex_positions,
        "pink_triangle_area": get_triangle_area(triangle1_indices),
        "black_triangle_area": get_triangle_area(triangle2_indices),
        "total_area": get_triangle_area(triangle1_indices) + get_triangle_area(triangle2_indices)
    }

func get_triangle_area(indices: Array[int]) -> float:
    var v0 = vertex_positions[indices[0]]
    var v1 = vertex_positions[indices[1]]
    var v2 = vertex_positions[indices[2]]

    var edge1 = v1 - v0
    var edge2 = v2 - v0
    var cross = edge1.cross(edge2)
    return cross.length() * 0.5
