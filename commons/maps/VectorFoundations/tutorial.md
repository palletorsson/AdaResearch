# Vector Foundations

Before you can simulate anything that moves — a falling ball, a drifting boid, a planet pulled by gravity — you need a way to talk about *where things are* and *which way they are going*. That way is the vector, and it is the single most important idea in this whole sequence. Everything ahead is built on it.

So what is a vector? The textbook answer is "a quantity with magnitude and direction." True, but cold. Here is the warmer one: **a vector is the trip from one point to another.** Stand where you are. Now think of a spot across the room. The arrow that points from you to that spot — aimed in a particular direction, exactly as long as the distance between you — that arrow is a vector. Walk it, and you arrive. In VR this is not a metaphor you have to imagine. You are standing inside it. Your own position is a vector from the origin. Every step you take adds a small vector to it.

This room teaches six moves with vectors, in the order Nature of Code teaches them: name one, read its parts, add, subtract, scale, and measure. Master these six and you can describe any motion. We will not rush. Each move is a station you can walk to and touch.

## Three arrows to measure everything

Every vector in this room is described against three reference arrows — the *basis*. One points east, one points up, one points north. Each is exactly one unit long, and each is perpendicular to the other two.

```gdscript
const I := Vector3(1, 0, 0)  # east
const J := Vector3(0, 1, 0)  # up
const K := Vector3(0, 0, 1)  # north
```

Why three little arrows? Because once you have them, you never need anything else. Any arrow you can draw in space — long, short, slanted, whatever — is just *so much east, so much up, so much north*, the three basis arrows stretched and added together. The basis is the alphabet; every vector is a word spelled out of it. Grab the rig in front of you and tilt it: notice that the three arrows stay rigid relative to each other. They are a frame, and you measure the world through it.

<!-- bead: basis_vectors_rig -->

## A point is just three numbers

If every vector is *so much east, so much up, so much north*, then writing one down is easy: you list those three amounts. Those three numbers are the vector's **components**, and they are also, simply, its coordinates.

```gdscript
func compose(x: float, y: float, z: float) -> Vector3:
    return x * I + y * J + z * K     # build the vector FROM its components

func decompose(v: Vector3) -> Array:
    return [v.x, v.y, v.z]           # read the components back OUT
```

Composing and decomposing are the same fact seen from two sides. Hand the machine three numbers and it builds the arrow; hand it the arrow and it reads the three numbers back. Here is the part worth pausing on: the arithmetic you do *on the coordinates* — adding them, doubling them — is exactly the arithmetic you do *on the vectors*. That is the whole reason vectors are useful. The geometry of arrows and the algebra of numbers are the same thing wearing two outfits. The artifact in front of you shows it live: move the point, and watch its three component numbers rewrite themselves.

<!-- bead: CoordinateSystem3M -->

## Adding: one trip, then another

Now the moves. The first is addition, and it is the one you already do every time you walk somewhere in two stages. Go to the kitchen, then from the kitchen to the door. Your total trip is the *sum* of those two legs — and you could have walked straight to the door instead and ended up in the same place.

```gdscript
func add_tip_to_tail(a: Vector3, b: Vector3) -> Vector3:
    return a + b
```

That is all addition is: place the tail of the second arrow at the tip of the first, and the sum is the single arrow from the very start to the very end. The `+` operator does it componentwise — east-plus-east, up-plus-up, north-plus-north — but you do not have to think in numbers. Think in trips. This is how every moving thing in the chapters ahead updates its position: *new position = old position + velocity.* One trip, then another.

<!-- bead: adder_board -->

## Subtracting: the arrow between two places

Subtraction answers a question you will ask constantly: *how do I get from here to there?* You have two points — your position and a target — and you want the arrow that connects them.

```gdscript
func between_points(from_p: Vector3, to_p: Vector3) -> Vector3:
    return to_p - from_p
```

The arrow runs from the first point to the second: `to minus from`. This deserves to be underlined, because it is the deepest fact in the room — **a vector is the subtraction of two positions.** Aiming a turret, chasing a target, measuring a distance, pointing a creature toward food: every one of them begins with *target minus self*. When something in this game seems to know where to go, this subtraction is how it knows.

<!-- bead: vector_sub -->

## Scaling: same direction, new length

Sometimes you want to keep an arrow's direction but change how far it reaches — go *twice* as far that way, or half, or flip around and go backward. That is multiplication by a single number, a *scalar*.

```gdscript
func scale_vector(v: Vector3, s: float) -> Vector3:
    return v * s
```

Multiply by 2 and the arrow stretches to double its length, still pointing the same way. Multiply by 0.5 and it shrinks. Multiply by −1 and it whips around to point the opposite direction, same length. Multiply by 0 and it collapses to a single point. Notice what scaling can *never* do: it cannot bend the arrow off its line. Direction survives multiplication — a fact you will lean on the moment forces enter, because a force is a direction you push *harder* or *softer* along.

<!-- bead: stretch_bench -->

## Measuring: how long is this arrow?

Every vector has a length — its **magnitude** — and often the length is the thing you actually care about. How fast is this moving? How far away is that? Those are magnitude questions.

```gdscript
func vector_length(v: Vector3) -> float:
    return v.length()
# Equivalent: sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
```

The formula is the Pythagorean theorem, stretched into three dimensions: square the components, add them, take the root. It is the straight-line distance from the arrow's tail to its tip. The lantern in front of you ties length to brightness — a long vector glows hard, a short one barely flickers — so you can *see* magnitude before you ever compute it. Hold on to the idea that a vector is two things bundled together: a direction, and this number. The last move pulls them apart.

<!-- bead: length_lantern -->

## Normalising: keeping the direction, dropping the length

Constantly you will want a vector's *direction* with its length thrown away — a pure pointer, exactly one unit long. Getting it is simple: divide the vector by its own length.

```gdscript
func safe_normalise(v: Vector3) -> Vector3:
    if v.length() < 0.0001: return Vector3.ZERO
    return v.normalized()
```

Divide an arrow by how long it is, and what remains points the same way but measures exactly 1. That is a *unit vector*, and it is the cleanest way to say "this direction, and nothing about distance." The guard matters: a zero-length vector has no direction to keep, and dividing by zero would hand you nonsense, so you check first. You will normalise constantly in the forces ahead — *give me the direction toward the target, then I will decide separately how hard to push.* Separating **where** from **how far** is what normalising is for.

<!-- bead: vector_normalize_demo -->

## Picking up the catalyst

One last thing before you leave. On its stand is the force catalyst — grab it.

```gdscript
func check_catalyst_pickup() -> void:
    var catalyst := get_tree().get_first_node_in_group("becoming_catalyst")
    if catalyst and catalyst.was_picked_up:
        unlock_force_mode()
```

Lifting it flips the switch the rest of the sequence reads. You arrived able to point; you leave able to push. The arrows you have been measuring are about to start *moving things*.

<!-- bead: catalyst_pickup -->

> Try: at the stretch bench, find by hand the single number that turns the display vector into a unit vector — the one that makes it exactly one unit long. You will have computed, with your own eyes, what `normalized()` does in code.

You can now name a vector, read its components, add two of them, subtract to find the arrow between points, scale a direction longer or shorter, measure a length, and strip a vector down to pure direction. That is the entire vocabulary of motion. **Vector Operations** is next, and it adds two new tools — the dot product and the cross product — that take vectors in and hand back *alignment* and *perpendicularity*: how much two arrows agree, and the direction square to them both.
