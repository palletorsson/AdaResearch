# Vector-Joint Playground

A human-scale VR arena with six interactive stations arranged in a semicircle, each pairing one or two draggable vector arrows with a large physics-joint mechanism. Manipulating the vectors in real time drives the joints, making abstract vector operations physically visible and tangible. The artifact teaches **core vector math operations** -- magnitude, addition, subtraction, dot product, cross product, and net force -- through embodied physics interaction.

## Concept Taught

**Vector operations** are the mathematical backbone of physics, graphics, and engineering. Each station isolates a single operation and maps it to a physical mechanism:

| Station | Operation | Mechanism | Joint Type |
|---------|-----------|-----------|------------|
| The Crane | Magnitude `|v|` | Boom arm angle | HingeJoint3D |
| The Pistons | Addition `A + B` | Two orthogonal sliders | SliderJoint3D x2 |
| The Door | Dot product `A . B` | Double door opening angle | HingeJoint3D x2 |
| The Seesaw | Subtraction `A - B` | Beam tilt via weight difference | HingeJoint3D + gravity |
| The Waterwheel | Cross product `A x B` | Wheel spin speed and direction | HingeJoint3D |
| The Spring Tower | Net force `sum(F)` | Platform compression/extension | Generic6DOFJoint3D |

## How It Works

1. Six stations are placed along a 180-degree arc at radius 6 meters. Each station faces the arena center.
2. Each station instantiates a `GadgetBase` helper that provides factory methods for rigid bodies, static bodies, and joints.
3. Draggable vector arrows use the shared `line.tscn` scene with two grab spheres. The user moves the endpoint in VR to change the vector.
4. Every frame, `_process` reads each vector's start/end positions, computes the relevant operation, and feeds the result into the physics joint (motor velocity, applied force, or mass adjustment).
5. Live data labels update at 10 Hz, displaying the current vector values, computed result, and physical output.
6. An info panel at each station shows the operation name, formula, and a plain-language description.

## Parameters

This script uses constants rather than exports:

| Constant | Value | Description |
|----------|-------|-------------|
| `STATION_RADIUS` | `6.0` | Distance from center to each station |
| `STATION_COUNT` | `6` | Number of stations |
| `STATION_ARC_DEG` | `180.0` | Angular spread of the semicircle |
| `TEXT_INTERVAL` | `0.1` s | Throttle interval for label updates |

## Features

- Six physics stations covering magnitude, addition, subtraction, dot product, cross product, and net force.
- Real-time vector-to-physics mapping: dragging arrows drives joints and bodies.
- VR-ready grabbable vector endpoints via the shared `line.tscn` primitive.
- GadgetBase helper for consistent rigid body, static body, and joint creation.
- Live info panels with operation formulas and computed values.
- Shared material cache for efficient rendering.
- Arena floor with center marker for spatial orientation.

## Files

- `vector_joint_playground.gd` -- Main script: arena layout, six station builders, per-frame vector-to-joint updates, info panels.
- `vector_joint_playground.tscn` -- Scene file.
