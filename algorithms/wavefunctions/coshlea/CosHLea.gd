extends Node3D

@export var u_min: float = -PI
@export var u_max: float = PI
@export var v_min: float = 0.0
@export var v_max: float = 4.0
@export var u_steps: int = 64
@export var v_steps: int = 128
@export var scale_factor: float = 1.0

var mesh_instance: MeshInstance3D

func _ready():
    mesh_instance = MeshInstance3D.new()
    add_child(mesh_instance)
    mesh_instance.mesh = _build_surface()

func _build_surface() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    var du := (u_max - u_min) / float(u_steps)
    var dv := (v_max - v_min) / float(v_steps)

    var grid := []
    for i in range(u_steps + 1):
        var row := []
        var u := u_min + i * du
        for j in range(v_steps + 1):
            var v := v_min + j * dv
            # Helicoid-like surface using hyperbolic cosine shaping
            # x = sinh(v) * sin(u)
            # y = 3*u
            # z = -sinh(v) * cos(u)
            var x := sinh(v) * sin(u)
            var y := 3.0 * u
            var z := -sinh(v) * cos(u)
            row.append(Vector3(x, y, z) * scale_factor)
        grid.append(row)

    for i in range(u_steps):
        for j in range(v_steps):
            var v0: Vector3 = grid[i][j]
            var v1: Vector3 = grid[i + 1][j]
            var v2: Vector3 = grid[i + 1][j + 1]
            var v3: Vector3 = grid[i][j + 1]

            var n1 := (v1 - v0).cross(v3 - v0).normalized()
            st.set_normal(n1)
            st.add_vertex(v0)
            st.set_normal(n1)
            st.add_vertex(v1)
            st.set_normal(n1)
            st.add_vertex(v2)

            var n2 := (v2 - v0).cross(v3 - v0).normalized()
            st.set_normal(n2)
            st.add_vertex(v0)
            st.set_normal(n2)
            st.add_vertex(v2)
            st.set_normal(n2)
            st.add_vertex(v3)

    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.7, 0.9, 1.0, 1.0)
    mat.roughness = 0.2
    mat.metallic = 0.0
    st.set_material(mat)

    var mesh := st.commit()
    return mesh


