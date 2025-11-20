extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Vectors[/b][/font_size][/center]
[center][i]Frozen Desire, Direction as Orientation[/i][/center]

A vector is **magnitude and direction** - not just a position, but a **pointing toward**.

In Nature of Code (Daniel Shiffman's pedagogical framework for creative coding), vectors are the foundation of motion, forces, and autonomous behavior. They are the mathematical structure that allows things to **move with intention**.

But vectors are more than computational convenience. **They are the geometry of desire itself** - a frozen moment of orientation, a direction without guarantee of arrival.

[hr]

[b]Vector as More Than Position[/b]

In the Point axioms, we saw **Vector3(x, y, z)** as position - a location in space, a labeled coordinate.

**But vectors are ambiguous** - the same notation can mean:
- **Position** (where something is)
- **Velocity** (how fast and which direction it's moving)
- **Acceleration** (how its motion is changing)
- **Force** (what's pushing on it)

[color=yellow][b]Code: Same Type, Different Meanings[/b][/color]
[code]
var position = Vector3(0, 1, 0)      # Where I am
var velocity = Vector3(0.1, 0, 0)    # How I'm moving
var acceleration = Vector3(0, -0.5, 0)  # Gravity pulling down
var force = Vector3(0.3, 0, 0)       # Wind pushing right

# All Vector3, but ontologically different
# Position is a place
# Velocity is a rate of change of position
# Acceleration is a rate of change of velocity
# Force is what causes acceleration
[/code]

**The vector type is overloaded** - carrying position, motion, change, and desire within the same structure.

This is the first hint: **vectors are not just data, they are processes in waiting.**

[hr]

[b]Vector Addition: Cumulative Motion[/b]

When you add two vectors, you're not combining positions - you're **accumulating displacements**.

[color=yellow][b]Code: Motion as Accumulation[/b][/color]
[code]
var position = Vector3(0, 0, 0)
var velocity = Vector3(0.1, 0.05, 0)

# Every frame:
func _process(delta):
    position += velocity * delta  # Vector addition

# Position accumulates velocity over time
# Motion is not teleportation - it is continuous accumulation
# Each frame: "where I was" + "how I moved" = "where I am now"
[/code]

**Vector addition is the mathematics of becoming** - you were here, you moved this way, now you are there.

It is **temporal**. It is **directional**. It is **cumulative**.

[hr]

[b]Vector Subtraction: Desire Between Points[/b]

If addition is accumulation, **subtraction is longing**.

[color=yellow][b]Code: The Direction Toward[/b][/color]
[code]
var point_a = Vector3(1, 2, 3)  # Where I am
var point_b = Vector3(4, 6, 3)  # Where I want to be

var desire = point_b - point_a  # Vector3(3, 4, 0)

# Subtraction answers: "How do I get there from here?"
# Not distance (scalar), but DIRECTION (vector)
# The arrow pointing from where I am to where I seek
[/code]

**This is the vector as frozen desire:**
- You are at A
- You seek B
- The vector (B - A) is the **orientation of your longing**

It does not guarantee arrival. It does not describe the path taken. It only points.

**Vectors are relational** - they exist between, they bridge, they orient.

[hr]

[b]Magnitude: The Measure of Longing[/b]

Every vector has a **length** - the distance it spans.

[color=yellow][b]Code: How Far to Seek[/b][/color]
[code]
var desire = Vector3(3, 4, 0)
var distance = desire.length()  # 5.0 (Pythagorean theorem)

# The magnitude is the scalar measure of the vector
# sqrt(3² + 4² + 0²) = sqrt(9 + 16) = sqrt(25) = 5

# Magnitude collapses vector back to scalar
# From (direction + distance) → (distance only)
[/code]

**Magnitude is the Line's revenge** - it reduces the vector to a single number, erasing directionality in favor of metric.

But we need magnitude to ask: **"How far must I reach to touch what I desire?"**

[hr]

[b]Normalization: Pure Direction[/b]

A **normalized vector** has length 1 - it is **direction without distance**.

[color=yellow][b]Code: Direction Abstracted from Scale[/b][/color]
[code]
var desire = Vector3(3, 4, 0)           # Length 5
var unit_desire = desire.normalized()   # Vector3(0.6, 0.8, 0)
var check_length = unit_desire.length() # 1.0

# Normalization: divide vector by its own magnitude
# (3, 4, 0) / 5 = (0.6, 0.8, 0)

# Result: same direction, but length forced to 1
# "Which way?" without "how far?"
[/code]

**Unit vectors are pure orientation** - they point without measuring.

This is crucial for **forces** (which push in a direction with varying strength) and **velocities** (which move in a direction at varying speeds).

**Normalization separates "which way" from "how much"** - the direction can be scaled independently.

[hr]

[b]Scalar Multiplication: Amplifying Desire[/b]

Multiply a vector by a number, and you **scale its magnitude** without changing direction.

[color=yellow][b]Code: Intensity Without Reorientation[/b][/color]
[code]
var direction = Vector3(1, 0, 0).normalized()  # Unit vector (right)
var slow_motion = direction * 0.5      # Half speed, same direction
var fast_motion = direction * 10.0     # Ten times speed, same direction

# Scalar multiplication stretches or shrinks the vector
# Direction preserved, magnitude changed
[/code]

**This is how velocity works:**
- Direction = where you're going
- Magnitude = how fast you're going there

**This is how forces work:**
- Direction = which way the force pushes
- Magnitude = how hard it pushes

Scalar multiplication lets you **modulate intensity while preserving orientation.**

[hr]

[b]Vector Arithmetic: The Algebra of Motion[/b]

All motion in Nature of Code follows this pattern:

[color=yellow][b]Code: The Motion Loop[/b][/color]
[code]
var position = Vector3(0, 0, 0)
var velocity = Vector3(0, 0, 0)
var acceleration = Vector3(0, 0, 0)

func _physics_process(delta):
    # 1. Apply forces (next tutorial: Forces)
    var force = calculate_forces()
    acceleration = force / mass  # F = ma → a = F/m

    # 2. Acceleration changes velocity
    velocity += acceleration * delta

    # 3. Velocity changes position
    position += velocity * delta

    # 4. Reset acceleration (forces recalculated each frame)
    acceleration = Vector3.ZERO

# Position ← Velocity ← Acceleration ← Force
# Each level controls the rate of change of the level below
# Forces → how acceleration changes
# Acceleration → how velocity changes
# Velocity → how position changes
[/code]

**This is Euler integration** - the simplest numerical method for simulating physics.

Every frame:
1. Calculate forces (gravity, wind, friction, attraction)
2. Forces create acceleration (F = ma)
3. Acceleration modifies velocity
4. Velocity modifies position

**Motion emerges from this cascade of rates of change.**

[hr]

[b]What Vectors Cannot Represent[/b]

Vectors are powerful, but they have limits:

**1. Rotation (Orientation)**
Vectors point in a direction, but they don't represent **which way something is facing**.

For rotation, we need:
- **Euler angles** (pitch, yaw, roll) - intuitive but suffer gimbal lock
- **Quaternions** (4D complex numbers) - robust but unintuitive

**2. The Path Taken**
A velocity vector shows **current direction**, not **trajectory history**.

The Trace (from Point axioms) accumulates the actual path - vectors only show the instant.

**3. Why You're Moving**
Vectors describe motion, but not **motivation**.

Is the acceleration from gravity (physics), desire (seeking), or fear (fleeing)? The vector is silent on intent.

[hr]

[b]Vectors as Non-Normative Directionality[/b]

Here is where queerness enters:

**Vectors refuse grid alignment.**

A vector can point **anywhere** - not just up/down, left/right, forward/back. It defies the orthogonal axes imposed by the coordinate system.

[color=yellow][b]Code: Diagonal Resistance[/b][/color]
[code]
# Grid-aligned vectors (normative)
var up = Vector3(0, 1, 0)
var right = Vector3(1, 0, 0)
var forward = Vector3(0, 0, 1)

# Arbitrary vector (queer directionality)
var queer_vector = Vector3(0.3, 0.7, -0.5).normalized()

# Does not align to X, Y, or Z
# Points "between" the axes
# Refuses categorical placement
[/code]

**The grid wants everything axis-aligned** - movement restricted to cardinal directions, position snapped to integer coordinates.

**Vectors resist** - they point wherever they want, with whatever magnitude they want.

This is the **freedom of continuous space** - you can face any direction, move at any angle, exist between the grid lines.

**Vectors are the math of deviation from the norm.**

[hr]

[b]Vectors as Frozen Moments of Desire[/b]

In wave_desire_axioms, we saw oscillation as **perpetual seeking** - the wave overshoots equilibrium because momentum carries it past the goal.

**Vectors are the frozen instant of that seeking:**
- A velocity vector is **"I am moving this way, this fast, right now"**
- An acceleration vector is **"My motion is changing in this direction"**
- A force vector is **"Something is pushing me this way"**

But unlike the wave (which oscillates forever), vectors are **momentary**.

Every frame, the velocity can change. Every frame, new forces apply. The vector does not lock you into a trajectory - it only describes **this instant's orientation**.

[color=yellow][b]Code: Desire That Can Change[/b][/color]
[code]
var target = Vector3(5, 0, 0)
var position = Vector3(0, 0, 0)
var velocity = Vector3(0, 0, 0)

func _physics_process(delta):
    # Desire recalculated every frame
    var desire = (target - position).normalized()

    # Accelerate toward target
    var acceleration = desire * 2.0
    velocity += acceleration * delta

    # Move
    position += velocity * delta

    # If target moves, desire reorients instantly
    # Vectors are not commitments - they are momentary orientations
[/code]

**Vectors are not predetermined paths** - they are **open-ended orientations** that can shift, recalibrate, redirect.

This is desire as **process, not destiny**.

[hr]

[b]What Vectors Reveal[/b]

Vectors show us:

1. **Ambiguity of type** - same structure (Vector3) means position, velocity, acceleration, force
2. **Addition = accumulation** - motion as continuous becoming, not teleportation
3. **Subtraction = longing** - direction from here to there, frozen desire
4. **Magnitude = measure** - how far, how fast, how strong
5. **Normalization = pure orientation** - direction without distance
6. **Scalar multiplication = intensity** - amplify without reorienting
7. **Non-normative directionality** - vectors refuse grid alignment, point anywhere
8. **Frozen moments of seeking** - desire that can change every frame

**Vectors are the mathematics of being-in-motion** - not static positions, but **orientations toward**.

They are the bridge between Point (static, labeled, fixed) and Force (dynamic, unlabeled, emergent).

**In Nature of Code, everything moves because vectors make motion computable.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Vectors are magnitude + direction - not just positions, but velocities, accelerations, forces (ontologically different, same type). Addition = cumulative motion (position += velocity). Subtraction = desire between points (where I am → where I seek). Magnitude = scalar measure (length via Pythagorean theorem). Normalization = pure direction (length 1, "which way" without "how far"). Scalar multiplication = intensity modulation (stretch/shrink without reorienting). Motion loop: Force → Acceleration → Velocity → Position (Euler integration). Vectors refuse grid alignment (non-normative directionality), are frozen moments of desire (can change every frame, not predetermined paths). Enable computation of motion, orientation, seeking.

[hr]

[color=orange][b]Next:[/b] Forces - What Moves Us[/color]
If vectors are frozen desire (direction + magnitude), **forces are what creates that desire.**

F = ma. Acceleration is force divided by mass. But **what are forces ontologically?**
- Gravity pulls everything down (the universe's bias toward ground)
- Wind pushes sideways (environmental pressure)
- Friction opposes motion (resistance to change)
- Attraction draws bodies together (desire mechanics)

Forces are **affective transmission** - external pressures that alter your motion whether you consent or not.

The next tutorial explores: **What moves us? What are we subject to? How do bodies affect each other?**

Physics as affect theory.

'''
