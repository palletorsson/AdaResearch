# Topology Entropy Morphogenesis

Form from flow. Turing patterns, reaction-diffusion, metaballs.

Run Gray-Scott reaction-diffusion.

```gdscript
class_name GrayScott extends Node3D

@export var grid_size: Vector2i = Vector2i(128, 128)
@export var feed: float = 0.055
@export var kill: float = 0.062
@export var du: float = 1.0
@export var dv: float = 0.5

var U: Array = []  # activator
var V: Array = []  # inhibitor

func initialise() -> void:
    U.clear(); V.clear()
    for y in grid_size.y:
        var u_row: Array = []
        var v_row: Array = []
        for x in grid_size.x:
            u_row.append(1.0)
            v_row.append(0.0)
        U.append(u_row); V.append(v_row)
    # Seed a small region
    for dy in 5:
        for dx in 5:
            V[grid_size.y / 2 + dy][grid_size.x / 2 + dx] = 1.0
```

Two coupled concentrations. U is high everywhere; V is seeded in a small region.

Compute the Laplacian.

```gdscript
func laplacian(grid: Array, x: int, y: int) -> float:
    var w := grid_size.x; var h := grid_size.y
    return (
        grid[(y - 1 + h) % h][x] +
        grid[(y + 1) % h][x] +
        grid[y][(x - 1 + w) % w] +
        grid[y][(x + 1) % w] -
        4.0 * grid[y][x]
    )
```

Five-point stencil with periodic boundaries. Wrapping prevents edge artifacts.

Step once.

```gdscript
@export var dt: float = 1.0

func step() -> void:
    var new_U: Array = []
    var new_V: Array = []
    for y in grid_size.y:
        new_U.append([]); new_V.append([])
        for x in grid_size.x:
            var u := U[y][x]; var v := V[y][x]
            var uvv := u * v * v
            new_U[y].append(u + dt * (du * laplacian(U, x, y) - uvv + feed * (1.0 - u)))
            new_V[y].append(v + dt * (dv * laplacian(V, x, y) + uvv - (feed + kill) * v))
    U = new_U; V = new_V
```

Gray-Scott update. Different feed/kill combinations produce spots, stripes, labyrinths.

Render as a texture.

```gdscript
func render_to_texture() -> ImageTexture:
    var image := Image.create(grid_size.x, grid_size.y, false, Image.FORMAT_RGBA8)
    for y in grid_size.y:
        for x in grid_size.x:
            var intensity: float = V[y][x]
            image.set_pixel(x, y, Color(intensity, intensity * 0.5, intensity * 0.8, 1.0))
    return ImageTexture.create_from_image(image)
```

Purple intensity tracks V. Patterns emerge over thousands of steps.

Metaball rendering.

```gdscript
func metaball_value_at(p: Vector3, centres: Array, radii: Array) -> float:
    var total: float = 0.0
    for i in centres.size():
        var distance: float = p.distance_to(centres[i])
        if distance > radii[i] * 2: continue
        total += radii[i] * radii[i] / (distance * distance + 0.001)
    return total
```

Sum of inverse-square contributions from all metaballs. Surface at a threshold level.

Extract iso-surface via marching cubes.

```gdscript
func marching_cubes_surface(field_func: Callable, threshold: float, resolution: int) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # ... full MC lookup tables, omitted for brevity
    # For each 2x2x2 voxel, determine which vertices/edges produce the surface
    return st.commit()
```

Standard marching cubes. Voxel grid samples the scalar field; the 256-case lookup determines triangles.

You can now run Gray-Scott reaction-diffusion, render it as a texture, sample a metaball field, and extract the iso-surface via marching cubes. Chamber_SoftBodies closes the sequence with push-as-interaction.
