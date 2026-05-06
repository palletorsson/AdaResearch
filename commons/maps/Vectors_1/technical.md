# Open ground where two arrows meet tip-to-tail and a third closes the triangle

VectorBasics established the vocabulary: components, magnitude, direction, basis vectors. VectorSubtraction introduced the first operation — difference as displacement, the arrow from here to there. VectorCrossProduct manufactured perpendicularity from two inputs. VectorProjectionReflection decomposed vectors into parallel and perpendicular components along arbitrary axes. Four maps. Four operations on individual vectors or pairs. None of them asked the simplest question: what happens when two vectors combine?

Addition is that question. Place one arrow's tail at another's head. The resultant runs from the first tail to the second head. Two influences become one. Two displacements become a single displacement. Two forces become a net force. The operation is component-wise — `(a.x+b.x, a.y+b.y, a.z+b.z)` — but the geometry is richer than the algebra suggests. The parallelogram rule, the tip-to-tail construction, commutativity — these are spatial facts that the formula alone does not convey.

This map sits at the hinge point of the vector sequence. Everything before it dissected individual operations. Everything after it — VectorFieldFlow, VectorForces, motion — depends on combining multiple vectors into resultants. Addition is the bridge. Superposition is the principle. Linearity is the assumption that makes it all work.

## Component-Wise Addition

Two vectors add by summing their components independently. Each axis contributes its own arithmetic. The axes do not interfere.

```gdscript
var a := Vector3(2.0, 1.0, 0.5)
var b := Vector3(-1.0, 3.0, 0.0)
var c := a + b  # Vector3(1.0, 4.0, 0.5)
```

The x-components add: 2 + (-1) = 1. The y-components add: 1 + 3 = 4. The z-components add: 0.5 + 0 = 0.5. Three independent scalar additions packaged into one vector operation. The result `c` is a new vector whose relationship to `a` and `b` is entirely determined by those three sums.

The `vector_addition_demo` artifact makes this concrete. Two exported vectors define the inputs:

```gdscript
@export var vector_a: Vector3 = Vector3(0.8, 0.3, 0.0):
    set(value):
        vector_a = value.limit_length(max_vector_length)
        if is_inside_tree():
            _update_vectors()
```

The setter clamps magnitude via `limit_length()` — a practical constraint that keeps arrows visible within the map's physical bounds. Without it, a vector could extend past the ground plane, past the walls, into geometric nonsense. The clamping is pedagogical: it forces the learner to work within a bounded space where all three arrows remain simultaneously legible.

Inside `_update_vectors()`, the addition happens in one line:

```gdscript
var result = vector_a + vector_b
```

One expression. The engine computes `(a.x+b.x, a.y+b.y, a.z+b.z)` and stores it. Everything else in the function — positioning arrows, updating labels, placing ghost vectors — is visualization. The math is finished. The rendering is just beginning.

## Tip-to-Tail Construction

The geometric interpretation of addition is physical. Take arrow A. Place the tail of arrow B at the head of A. The resultant runs from A's tail to B's head. This is tip-to-tail construction — the method that makes addition spatial rather than numeric.

The demo draws this explicitly. Five arrows occupy the scene: A from the origin, B from the origin, the resultant from the origin, and two ghost arrows that complete the parallelogram.

```gdscript
VectorVisuals.position_arrow(_arrow_a, Vector3.ZERO, vector_a, arrow_thickness)
VectorVisuals.position_arrow(_arrow_b, Vector3.ZERO, vector_b, arrow_thickness)
VectorVisuals.position_arrow(_arrow_result, Vector3.ZERO, result, arrow_thickness)

# Ghost arrows (parallelogram)
VectorVisuals.position_arrow(_arrow_a_ghost, vector_b, vector_b + vector_a, arrow_thickness)
VectorVisuals.position_arrow(_arrow_b_ghost, vector_a, vector_a + vector_b, arrow_thickness)
```

The ghost arrow `_arrow_a_ghost` starts at the tip of B and extends by A. The ghost `_arrow_b_ghost` starts at the tip of A and extends by B. Both ghosts terminate at the same point: `vector_a + vector_b`. The four arrows — A, B, ghost-A, ghost-B — form a parallelogram. The resultant is its diagonal.

Ghost arrows use a reduced-opacity color:

```gdscript
var color_ghost: Color = Color(0.5, 0.5, 0.6, 0.35)
```

Alpha 0.35. Translucent enough to read as secondary construction, solid enough to trace the geometry. The visual hierarchy — solid for primary vectors, ghost for construction lines — separates the operation from its scaffolding. The learner sees three real arrows and two helpers. The helpers can be ignored once the pattern clicks.

The primary arrows use distinct saturated colors — coral for A, cyan for B, neon green for the result:

```gdscript
var color_a: Color = Color(1.0, 0.35, 0.4)      # Coral
var color_b: Color = Color(0.3, 0.85, 0.95)     # Cyan
var color_result: Color = Color(0.4, 1.0, 0.5)  # Neon green
```

Three hues, maximum perceptual separation. The result deliberately avoids blending either input color — it is green, not a mix of coral and cyan. The sum is a new thing, not a blend of its parts. Color encodes the algebra: distinct inputs, distinct output.

## The Parallelogram Rule

Tip-to-tail is the process. The parallelogram is the proof that order does not matter.

Draw A from the origin. Draw B from the origin. Now draw A again, starting from B's tip. Draw B again, starting from A's tip. The four arrows close a parallelogram. Both diagonals — "A then B" and "B then A" — end at the same corner. This is commutativity made geometric.

```gdscript
# Commutativity: a + b == b + a
var a := Vector3(3.0, 1.0, 0.0)
var b := Vector3(1.0, 2.0, 0.0)

var ab := a + b  # Vector3(4.0, 3.0, 0.0)
var ba := b + a  # Vector3(4.0, 3.0, 0.0)
# ab == ba — always
```

The demo's two ghost arrows embody the two orderings. Ghost-A starts at B's tip (the "B then A" path). Ghost-B starts at A's tip (the "A then B" path). They converge. The parallelogram closes. No matter which path the learner traces — along the top edge or the bottom — the destination is the same.

This is not a trivial property. The cross product is anti-commutative: `A x B = -(B x A)`. Matrix multiplication is non-commutative. Rotations composed in different orders produce different results. Addition is the exception — the operation where sequence is irrelevant. That symmetry is why forces combine so cleanly. Gravity pulls down while friction pushes sideways and the net force is the same regardless of which you account for first.

## Superposition and Linearity

Addition encodes a deeper assumption: superposition. Effects combine linearly. Two forces acting simultaneously on a body produce the same result as computing each force independently and summing the vectors. No interference. No saturation. No threshold effects. Each contribution adds to the total without modifying the others.

```gdscript
# Net force on an object
var gravity := Vector3(0, -9.8, 0)
var wind := Vector3(3.0, 0, 0)
var friction := Vector3(-1.5, 0, 0)

var net_force := gravity + wind + friction
# Vector3(1.5, -9.8, 0.0)
```

Three forces. One sum. The gravity component (-9.8 in y) passes through untouched by wind or friction. The horizontal components (wind minus friction = 1.5 in x) resolve independently of the vertical pull. Superposition means the axes are independent channels. Each carries its own sum.

This linearity holds in Newtonian mechanics, in electrostatics, in small-displacement elasticity. It breaks in fluid turbulence, in material plasticity, in relativistic regimes. When two ocean waves meet and the resulting wave is not the sum of the two inputs — that is nonlinearity. When a material bends past its yield point and deformation stops being proportional to force — that is nonlinearity. But at the beginner level, within the scope of this sequence, linearity is the operating assumption. Addition is king because superposition holds. The entire apparatus of vector math works because the world, at human scales and modest speeds, behaves linearly enough to trust the sum.

In QFEP terms, the system state S is a vector. The environment E acts through forces that are themselves vectors. The framework expression QFE = F - lambda * E(S) + phi * Delta-E(S,t) relies on addition to combine the base function F with the environmental correction and the temporal sensitivity term. Each term contributes independently. The sum is the total quality. Without linear addition, the framework collapses into something far more complex.

## The Basis Vectors Rig as Frame

The `basis_vectors_rig` artifact returns in this map as the coordinate anchor. Three colored arrows — red for i-hat (X), green for j-hat (Y), blue for k-hat (Z) — establish the frame within which addition is demonstrated.

```gdscript
@export var target_point: Vector3 = Vector3(0.35, 0.45, 0.25):
    set(value):
        target_point = value
        if is_inside_tree():
            _update_visualization()
```

The rig decomposes `target_point` into basis components and draws the staircase path — along X, then Y, then Z — that reaches the point from the origin. This staircase is itself a three-step vector addition:

```gdscript
func _update_component_lines(coords: Vector3):
    var p0 = Vector3.ZERO
    var p1 = _basis.x * coords.x
    var p2 = p1 + _basis.y * coords.y
    var p3 = p2 + _basis.z * coords.z
```

Start at the origin. Add the X contribution. Add the Y contribution. Add the Z contribution. Three additions. The final point `p3` equals the target. The component lines visualize each addition step as a colored segment — red horizontal, green vertical, blue into depth. The staircase is tip-to-tail construction with basis vectors as the addends.

The rig also supports basis rotation via presets:

```gdscript
var rotation_presets = [
    ["RESET", Basis.IDENTITY],
    ["TILT", Basis(Vector3.RIGHT, deg_to_rad(30))],
    ["SPIN", Basis(Vector3.UP, deg_to_rad(45))],
]
```

Rotating the basis changes the staircase. The same target point decomposes differently in a tilted frame — different component magnitudes, different colored segments, same destination. Addition still works. The components change because the basis changed, but the sum is invariant. The target point does not move when the learner presses TILT. Only the decomposition shifts. This is the same observation VectorBasics introduced from the platform — the vector is independent of the frame. Addition respects that independence.

Addition of vectors is also associative: `(A + B) + C = A + (B + C)`. Grouping does not matter. This extends the pairwise operation to chains of arbitrary length.

```gdscript
# Three forces acting on a body
var f1 := Vector3(2.0, 0, 0)
var f2 := Vector3(0, 3.0, 0)
var f3 := Vector3(-1.0, -1.0, 1.0)

# All groupings yield the same net force
var net_a := (f1 + f2) + f3  # Vector3(1.0, 2.0, 1.0)
var net_b := f1 + (f2 + f3)  # Vector3(1.0, 2.0, 1.0)
```

Associativity means the engine can sum forces in any order — as they arrive, in batches, recursively. No accumulation error from ordering. No sensitivity to which pair combines first. This is critical for physics engines that iterate over contact points, apply gravity, add user input, and accumulate impulses in whatever order the solver dictates.

The `vector_addition_demo` works with two vectors, but the principle extends without modification. Four forces, ten forces, a hundred forces — the operation is the same. Sum all x-components. Sum all y-components. Sum all z-components. The resultant is the total arrow. Tip-to-tail extends to a chain: lay each arrow end to end, and the resultant runs from the first tail to the last head.

```gdscript
# Summing an array of force vectors
func net_force(forces: Array[Vector3]) -> Vector3:
    var total := Vector3.ZERO
    for f in forces:
        total += f
    return total
```

`Vector3.ZERO` is the identity element — the zero vector. Adding it to any vector returns that vector unchanged. It is the arrow of no displacement, no force, no velocity. The additive identity. Every vector space has one. And every vector has an additive inverse — the negated vector from VectorSubtraction. `A + (-A) = Vector3.ZERO`. Addition and subtraction close the loop: one builds up, the other cancels out, and zero is where they meet.

The `dark_sphere` artifact occupies this map as ambient presence. Its implementation does not teach addition explicitly, but its frame-by-frame behavior is additive accumulation.

```gdscript
_sphere_mesh.rotation.y += rotation_speed * delta
```

Each frame adds a small angular increment to the current rotation. The rotation at frame N is the sum of all increments from frame 0 through N-1. This is discrete integration — addition applied over time. The continuous rotation of the sphere is built from hundreds of tiny additions per second, each one a vector added to the running total.

The pulse oscillation uses a different pattern — not accumulation but periodic resetting:

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
_sphere_material.emission_energy_multiplier = lerpf(pulse_min, pulse_max, pulse_t)
```

The `lerpf` function is itself an addition in disguise: `lerpf(a, b, t) = a + t * (b - a)`. Start at `a`. Add `t` times the difference between `b` and `a`. Linear interpolation is addition of a scaled displacement. The same tip-to-tail construction that the demo shows with arrows, `lerpf` performs with scalars. The pattern is fractal — addition at every scale, in every context, wearing different names.

## Magnitude of Sums and the Triangle Inequality

The demo provides preset buttons for VR interaction that expose different geometric cases:

```gdscript
var presets = [
    ["ORTHO", Vector3(0.9, 0, 0), Vector3(0, 0.8, 0)],
    ["ACUTE", Vector3(0.7, 0.3, 0), Vector3(0.3, 0.7, 0)],
    ["3D", Vector3(0.6, 0.3, 0.3), Vector3(0.2, 0.5, 0.4)],
    ["RESET", Vector3(0.8, 0.3, 0), Vector3(0.2, 0.6, 0.3)]
]
```

Each preset configures A and B to demonstrate a different geometric case. ORTHO places them at right angles — the parallelogram becomes a rectangle and the resultant is the diagonal of a box. ACUTE tilts them toward each other — the parallelogram compresses and the resultant grows shorter than the sum of magnitudes. 3D lifts both vectors out of the XY plane — the parallelogram floats in space, demonstrating that addition works identically in all three dimensions.

The formula panel updates live with component values and magnitude:

```gdscript
formula_label.text = "A = (%.2f, %.2f, %.2f)\n" % [vector_a.x, vector_a.y, vector_a.z]
formula_label.text += "B = (%.2f, %.2f, %.2f)\n\n" % [vector_b.x, vector_b.y, vector_b.z]
formula_label.text += "A + B = (%.2f, %.2f, %.2f)\n" % [result.x, result.y, result.z]
formula_label.text += "|A + B| = %.3f" % result.length()
```

The magnitude line matters. `|A + B|` is not `|A| + |B|` unless the vectors are perfectly aligned. For perpendicular vectors, `|A + B| = sqrt(|A|^2 + |B|^2)` — Pythagoras again. For opposing vectors, `|A + B|` can be as small as `||A| - |B||`. The triangle inequality constrains the result: the magnitude of a sum is always less than or equal to the sum of the magnitudes. The formula panel lets the learner watch this inequality tighten and loosen as the vectors pivot.

## From Addition to Fields

Addition of two discrete vectors is a single operation. But what happens when every point in space has its own vector — a velocity, a force, an electric field direction — and the question becomes not "what is A + B" but "what is the vector at position P"?

That is a vector field. And the transition from pairwise addition to field-level thinking is exactly what VectorFieldFlow explores next. The field assigns a vector to every point. An object moving through the field accumulates influence by adding the local vector to its velocity at each timestep. The addition operation from this map becomes the integration rule of the next. One arrow plus one arrow becomes one arrow per point, everywhere, continuously.

The basis_vectors_rig already hints at this transition. Its staircase decomposition walks through space step by step — along X, then Y, then Z. A vector field generalizes that walk: instead of following fixed basis directions, the path follows whatever arrow exists at the current position. The local arrow says "go this way." Addition says "add this displacement to where you are." The result is a streamline — a curve traced by repeated addition of locally varying vectors.

```gdscript
# Euler integration through a vector field
func trace_streamline(start: Vector3, field: Callable, steps: int, dt: float) -> Array[Vector3]:
    var path: Array[Vector3] = [start]
    var pos := start
    for i in steps:
        var v := field.call(pos)  # Vector at current position
        pos += v * dt              # Addition: update position
        path.append(pos)
    return path
```

`pos += v * dt` is vector addition. The field provides direction and magnitude. Delta time scales the step. Addition applies the step. The streamline emerges from repeated application of the same operation this map teaches with two arrows and a parallelogram.

## Possible Artifacts

**vector_addition_playground** — Two draggable arrows anchored at the origin with live parallelogram construction and tip-to-tail tracing shown simultaneously. The resultant updates in real time. Numeric readouts display component sums and magnitude. A toggle switches between parallelogram view and chain view (tip-to-tail only, no parallelogram). Directly addresses the gap identified in the intent — making the two geometric interpretations of addition interactive and side by side.

**force_combiner** — Three or more force vectors applied to a central point, each draggable independently. The net force arrow updates as any input changes. A "balance" mode challenges the learner to add a vector that zeroes the net force — finding the equilibrium condition where all forces cancel. Extends pairwise addition to multi-vector sums and introduces the zero vector as a target rather than a starting point.

**superposition_tester** — Two independent oscillating vectors (configurable frequency and amplitude) whose sum is displayed as a third vector tracing a Lissajous-like path. Demonstrates that addition of time-varying vectors produces emergent motion patterns not visible in either input alone. Bridges from static addition to the dynamic accumulation that VectorFieldFlow requires.
