# ML Gradient Landscape — Technical

The map displays a terrain whose height at each point is a loss value — a hypothetical model's error at those parameter values. A marker is dropped onto the terrain, and gradient descent moves the marker downhill one step per frame.

```gdscript
class_name GradientDescentRig extends Node3D

@export var learning_rate: float = 0.05
@export var momentum: float = 0.9

var position_2d: Vector2
var velocity: Vector2

func step() -> void:
    var grad: Vector2 = compute_gradient(position_2d)
    velocity = momentum * velocity - learning_rate * grad
    position_2d += velocity
    update_marker_height()

func compute_gradient(p: Vector2) -> Vector2:
    var h: float = 0.001
    var dx := (loss(Vector2(p.x + h, p.y)) - loss(Vector2(p.x - h, p.y))) / (2 * h)
    var dy := (loss(Vector2(p.x, p.y + h)) - loss(Vector2(p.x, p.y - h))) / (2 * h)
    return Vector2(dx, dy)

func loss(p: Vector2) -> float:
    # Example: Himmelblau function (four minima)
    return pow(p.x * p.x + p.y - 11, 2) + pow(p.x + p.y * p.y - 7, 2)
```

## Learning Rate and Momentum

The learning rate decides step size. Too small, and the marker creeps across the terrain; too large, and it overshoots valleys and oscillates. The stable range is bounded by the Lipschitz constant of the gradient — the maximum rate at which the gradient itself changes — but this is rarely known in practice. The map exposes the learning rate as a slider so the learner can feel the stability boundary.

Momentum accumulates velocity across steps. A momentum term of 0.9 means each step carries 90% of the previous step's velocity plus the current gradient contribution. Momentum helps the marker escape shallow local minima (it keeps moving even when the gradient is briefly weak) and dampens oscillation in narrow valleys.

## Loss Surfaces

The map cycles through several classic loss functions. Himmelblau's function has four minima at comparable values — useful for showing that different starting points reach different optima. The Rastrigin function has many local minima overlaid on a single global minimum — useful for showing how gradient descent gets trapped. The Rosenbrock function has a narrow curved valley — useful for showing how momentum accelerates convergence.

## In Practice

Real neural networks operate in loss landscapes with millions of dimensions. The map's two-dimensional terrain is a pedagogical metaphor, not a realistic model. Saddle points dominate high-dimensional landscapes, and the 3D terrain's legible valleys and ridges do not generalise. A side panel notes this explicitly so the learner knows the metaphor's limits.

Within the sequence, Gradient_Landscape is where optimisation becomes cheap and directed. ML_Classification will next put the machinery to work on a concrete task.

## Adaptive Methods

Modern optimisers adapt per-parameter learning rates based on gradient history. Adagrad scales each parameter's learning rate by the inverse square root of accumulated squared gradients, which dampens updates for parameters that have already moved a lot. RMSProp adds an exponential moving average. Adam combines both with a bias correction.

```gdscript
class_name Adam

var m: Array  # first moment estimate
var v: Array  # second moment estimate
var t: int = 0
@export var beta1: float = 0.9
@export var beta2: float = 0.999
@export var eps: float = 1e-8

func update(params: Array, grads: Array, lr: float) -> Array:
    t += 1
    var new_params: Array = []
    for i in range(params.size()):
        m[i] = beta1 * m[i] + (1.0 - beta1) * grads[i]
        v[i] = beta2 * v[i] + (1.0 - beta2) * grads[i] * grads[i]
        var m_hat = m[i] / (1.0 - pow(beta1, t))
        var v_hat = v[i] / (1.0 - pow(beta2, t))
        new_params.append(params[i] - lr * m_hat / (sqrt(v_hat) + eps))
    return new_params
```

## Second-Order Methods

Newton's method uses the Hessian (the matrix of second derivatives) to take better steps. The update is Δθ = −H⁻¹·∇, which jumps directly to the minimum for quadratic functions. The Hessian costs O(N²) to store and O(N³) to invert, so second-order methods are impractical for large networks. Quasi-Newton methods (BFGS, L-BFGS) approximate the inverse Hessian incrementally and are practical for medium-scale problems.

## Stochastic Gradient Descent

Real neural networks train with stochastic gradients — gradients computed on a randomly-sampled mini-batch rather than on the full dataset. The noise in the stochastic gradient can help escape local minima (the noise perturbs the trajectory enough to jump out of shallow basins), but it also prevents the optimiser from ever settling at a precise minimum. The tradeoff is the subject of an active literature.
