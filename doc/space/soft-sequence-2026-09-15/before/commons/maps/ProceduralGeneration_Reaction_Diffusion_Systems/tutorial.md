# Reaction Diffusion Systems

Two chemicals. Four parameters. Infinite patterns.

Set up concentration grids.

```gdscript
@export var size: Vector2i = Vector2i(128, 128)
var U: Array = []
var V: Array = []

func initialise() -> void:
    U.clear(); V.clear()
    for y in size.y:
        var u_row: Array = []
        var v_row: Array = []
        for x in size.x:
            u_row.append(1.0)
            v_row.append(0.0)
        U.append(u_row); V.append(v_row)
```

U starts at 1.0 everywhere. V starts at 0.0. Seed a small V region to start the dynamics.

Seed the initial perturbation.

```gdscript
func seed() -> void:
    for dy in 10:
        for dx in 10:
            var x: int = size.x / 2 + dx - 5
            var y: int = size.y / 2 + dy - 5
            V[y][x] = 1.0
            U[y][x] = 0.5
```

Central seed. Patterns grow outward from it.

Compute the Laplacian.

```gdscript
func laplacian(grid: Array, x: int, y: int) -> float:
    var w := size.x; var h := size.y
    return (
        grid[(y + h - 1) % h][x] +
        grid[(y + 1) % h][x] +
        grid[y][(x + w - 1) % w] +
        grid[y][(x + 1) % w] -
        4.0 * grid[y][x]
    )
```

Discrete Laplacian with periodic boundaries. Wrap-around prevents boundary artifacts.

Gray-Scott update step.

```gdscript
@export var feed: float = 0.055
@export var kill: float = 0.062
@export var du: float = 1.0
@export var dv: float = 0.5

func step() -> void:
    var new_U: Array = []
    var new_V: Array = []
    for y in size.y:
        new_U.append([]); new_V.append([])
        for x in size.x:
            var u: float = U[y][x]; var v: float = V[y][x]
            var uvv: float = u * v * v
            new_U[y].append(u + du * laplacian(U, x, y) - uvv + feed * (1.0 - u))
            new_V[y].append(v + dv * laplacian(V, x, y) + uvv - (feed + kill) * v)
    U = new_U; V = new_V
```

Two coupled PDEs. feed adds U; kill removes V; the uvv term converts U into V where both are present.

Render as texture.

```gdscript
func to_texture() -> ImageTexture:
    var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
    for y in size.y:
        for x in size.x:
            var intensity: float = clamp(V[y][x], 0.0, 1.0)
            image.set_pixel(x, y, Color(intensity, intensity * 0.4, intensity * 0.7, 1.0))
    return ImageTexture.create_from_image(image)
```

Colour intensity tracks V. Reddish-purple when V is high.

Pattern types by parameter.

```gdscript
enum PatternType { SPOTS, STRIPES, LABYRINTHS, MITOSIS }

func set_pattern(type: PatternType) -> void:
    match type:
        PatternType.SPOTS: feed = 0.040; kill = 0.065
        PatternType.STRIPES: feed = 0.030; kill = 0.057
        PatternType.LABYRINTHS: feed = 0.050; kill = 0.065
        PatternType.MITOSIS: feed = 0.028; kill = 0.062
```

Four regions of the (feed, kill) plane produce distinct visual patterns. Each is a different self-organising regime.

Step continuously.

```gdscript
func _process(_delta: float) -> void:
    for _i in 5:  # multiple steps per frame
        step()
    texture_rect.texture = to_texture()
```

Five updates per frame. The pattern evolves visibly over seconds.

Reset via button.

```gdscript
func _on_reset_pressed() -> void:
    initialise()
    seed()
```

Back to initial conditions. Useful when exploring different parameter regions.

You can now set up Gray-Scott reaction-diffusion, compute the Laplacian, step the update rule, render as texture, and switch between spots/stripes/labyrinths/mitosis pattern regimes. The sequence continues with other morphogenesis techniques.
