# ML Gradient Landscape

Gradient descent. Compute the slope; step downhill.

Define a loss function.

```gdscript
func loss(p: Vector2) -> float:
    return (p.x * p.x + p.y - 11) ** 2 + (p.x + p.y * p.y - 7) ** 2  # Himmelblau
```

Himmelblau's function. Four global minima at comparable values.

Compute the gradient numerically.

```gdscript
func gradient(p: Vector2, h: float = 0.001) -> Vector2:
    var dx: float = (loss(Vector2(p.x + h, p.y)) - loss(Vector2(p.x - h, p.y))) / (2 * h)
    var dy: float = (loss(Vector2(p.x, p.y + h)) - loss(Vector2(p.x, p.y - h))) / (2 * h)
    return Vector2(dx, dy)
```

Central-difference approximation. Two function evaluations per axis.

Vanilla gradient descent step.

```gdscript
func gd_step(p: Vector2, lr: float = 0.05) -> Vector2:
    return p - gradient(p) * lr
```

Move opposite to the gradient, scaled by the learning rate.

Momentum gradient descent.

```gdscript
var velocity: Vector2 = Vector2.ZERO

func momentum_step(p: Vector2, lr: float = 0.05, momentum: float = 0.9) -> Vector2:
    velocity = velocity * momentum - gradient(p) * lr
    return p + velocity
```

Accumulate velocity across steps. Escapes shallow local minima.

Adam optimiser.

```gdscript
var m: Vector2 = Vector2.ZERO  # first moment
var v: Vector2 = Vector2.ZERO  # second moment
var t: int = 0
@export var beta1: float = 0.9
@export var beta2: float = 0.999
@export var eps: float = 1e-8

func adam_step(p: Vector2, lr: float = 0.05) -> Vector2:
    t += 1
    var g := gradient(p)
    m = m * beta1 + g * (1 - beta1)
    v = Vector2(v.x * beta2 + g.x * g.x * (1 - beta2), v.y * beta2 + g.y * g.y * (1 - beta2))
    var m_hat: Vector2 = m / (1 - pow(beta1, t))
    var v_hat: Vector2 = v / (1 - pow(beta2, t))
    return p - Vector2(lr * m_hat.x / (sqrt(v_hat.x) + eps), lr * m_hat.y / (sqrt(v_hat.y) + eps))
```

Per-parameter adaptive learning rates. Adam is the default optimiser in modern deep learning.

Render the loss surface.

```gdscript
func render_surface(bounds: Vector2, resolution: int = 64) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for y in resolution:
        for x in resolution:
            var p := Vector2(x, y) / resolution * bounds - bounds / 2
            var height: float = loss(p)
            st.add_vertex(Vector3(p.x, height, p.y))
    # ... triangulation
    return st.commit()
```

A grid of vertices at computed heights. The mesh shows the terrain gradient descent walks.

Animate the descent.

```gdscript
func animate_descent(p_start: Vector2, steps: int) -> void:
    var p := p_start
    for _i in steps:
        p = adam_step(p)
        mark_position(p)
        await get_tree().create_timer(0.1).timeout
```

Each step drops a marker. The trail shows the optimiser's trajectory.

You can now compute gradients numerically, step via vanilla/momentum/Adam, render a loss surface, and animate the descent. ML_Classification extends into decision boundaries.
