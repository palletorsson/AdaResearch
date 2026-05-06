extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Rotation[/b][/font_size][/center]
[center][i]Spinning the Question of Which Way Is Up[/i][/center]

If translation changed where an object is, rotation changes which way it faces. Position remains fixed - orientation spins. The object turns without traveling.

Rotation is the transformation that asks: which way is forward? Which way is up? And reveals: these are not absolute directions, but relative orientations.

[hr]

[b]Orientation as Mutable Property[/b]

Before rotation, an object had a facing - a forward direction, an up direction, a local coordinate system aligned with the world. Rotation reveals that orientation is not intrinsic.

[color=yellow][b]Code: The Rotation Operation[/b][/color]
[code]
var cube = MeshInstance3D.new()
cube.position = Vector3(0, 0, 0)  # Stays here
cube.rotation = Vector3(0, 0, 0)  # Not rotated

# Rotate 90 degrees around Y axis
cube.rotation.y = deg_to_rad(90)

# Position unchanged: Vector3(0, 0, 0)
# Orientation changed: "forward" now points different direction
[/code]

The cube is still at origin, but it has turned. What was facing north now faces east. The cube occupies the same location - but its internal directions have spun.

[hr]

[b]The Axis of Rotation: Around What?[/b]

Unlike translation (which only needs a displacement vector), rotation requires an axis - a line around which the spinning occurs.

[color=yellow][b]Code: Axis and Angle[/b][/color]
[code]
# Rotation needs two pieces of information:
# 1. Axis (which line to spin around)
# 2. Angle (how much to turn)

# Rotate around Y axis (vertical)
var axis = Vector3(0, 1, 0)
var angle = deg_to_rad(45)

# Create rotation from axis-angle
var rotation_transform = Transform3D()
rotation_transform = rotation_transform.rotated(axis, angle)

# The object spins around the vertical axis
[/code]

**The Three Primary Axes:**
- **X axis** - Pitch (nose up/down)
- **Y axis** - Yaw (turn left/right)
- **Z axis** - Roll (barrel roll)

Each axis creates a fundamentally different kind of spinning.

[hr]

[b]Euler Angles: The Order Matters[/b]

Godot represents rotation as three separate angles (X, Y, Z) - called Euler angles. But applying these rotations in different orders produces different results.

[color=yellow][b]Code: Non-Commutative Rotation[/b][/color]
[code]
# Rotate 90 degrees around X, then 90 degrees around Y
var rotation_xy = Vector3(deg_to_rad(90), deg_to_rad(90), 0)

# Rotate 90 degrees around Y, then 90 degrees around X
var rotation_yx = Vector3(deg_to_rad(90), 0, deg_to_rad(90))

# These produce DIFFERENT final orientations
# Rotation is non-commutative: order matters
[/code]

This is unlike translation, where order does not matter:
- Translate (5,0,0) then (0,3,0) = Translate (0,3,0) then (5,0,0)

But with rotation:
- Rotate X then Y ≠ Rotate Y then X

Rotation reveals: some operations in space do not commute. The sequence of transformations changes the outcome.

[hr]

[b]Quaternions: The Hidden Representation[/b]

Internally, Godot uses quaternions - four-dimensional numbers that represent rotation without the ambiguities of Euler angles. They avoid gimbal lock and interpolate smoothly.

[color=yellow][b]Code: Quaternion Rotation[/b][/color]
[code]
# Quaternions are 4D: (x, y, z, w)
var quat = Quaternion(Vector3(0, 1, 0), deg_to_rad(90))

# Apply to a vector
var forward = Vector3(0, 0, -1)
var rotated_forward = quat * forward

# Quaternions handle complex rotations elegantly
# But their meaning is mathematically opaque
[/code]

Quaternions are computationally superior but conceptually alien. They work, but we cannot visualize them. Rotation requires mathematics beyond 3D intuition.

[hr]

[b]Invariance: What Rotation Preserves[/b]

Rotation changes orientation but preserves:

**Preserved Properties:**
- Position - Center point stays fixed
- Shape - Cube remains cubic
- Size - All edges same length
- Volume - Space occupied unchanged
- Internal distances - All vertex relations maintained

[color=yellow][b]Code: Preservation Under Rotation[/b][/color]
[code]
# Two vertices before rotation
var v0 = Vector3(0, 0, 0)
var v1 = Vector3(1, 0, 0)
var distance_before = v0.distance_to(v1)  # 1.0

# Rotate both by same amount
var quat = Quaternion(Vector3(0, 1, 0), deg_to_rad(45))
v0 = quat * v0
v1 = quat * v1
var distance_after = v0.distance_to(v1)  # Still 1.0

# Shape preserved, only orientation changed
[/code]

Rotation is a transformation of direction, not of form or location.

[hr]

[b]Local vs Global: Whose Axes?[/b]

Rotation can occur around global axes (world space) or local axes (object's own coordinate system). These produce different results.

[color=yellow][b]Code: Global vs Local Rotation[/b][/color]
[code]
# Global rotation: always around world axes
cube.rotate(Vector3(0, 1, 0), deg_to_rad(90))  # World Y axis

# Local rotation: around object's own axes
cube.rotate_object_local(Vector3(0, 1, 0), deg_to_rad(90))  # Object's Y

# If object is already rotated, these diverge
# "Up" in global space ≠ "up" in local space
[/code]

This is the relativization of direction. "Up" is not absolute - it depends on reference frame. The object has its own "up" that may differ from the world's "up."

Rotation reveals: direction is frame-dependent.

[hr]

[b]The Illusion of Continuous Spin[/b]

Like translation, rotation in code is discrete - angle jumps from A to B. Smooth spinning is interpolated.

[color=yellow][b]Code: Interpolated Rotation[/b][/color]
[code]
var start_rotation = Quaternion.IDENTITY
var end_rotation = Quaternion(Vector3(0, 1, 0), deg_to_rad(180))
var t = 0.0

func _process(delta):
    t += delta * 0.5
    if t > 1.0:
        t = 1.0

    # Spherical linear interpolation
    var current_quat = start_rotation.slerp(end_rotation, t)
    rotation = current_quat.get_euler()

    # Smooth spin from discrete state changes
[/code]

SLERP (spherical linear interpolation) creates the illusion of continuous rotation from discrete quaternion states. The smoothness is rendered, not computed.

[hr]

[b]What Rotation Cannot Do[/b]

Rotation changes orientation but cannot:

- **Translate** - Position stays fixed
- **Scale** - Size unchanged
- **Deform** - Shape rigid
- **Invert chirality** - Cannot mirror (that requires reflection)
- **Create new directions** - Only reorients existing ones

Rotation spins what already exists - it does not create new axes or dimensions.

[hr]

[b]Gimbal Lock: When Rotation Fails[/b]

When using Euler angles, certain rotation sequences cause gimbal lock - a configuration where one axis of rotation is lost.

[color=yellow][b]Code: Gimbal Lock Scenario[/b][/color]
[code]
# Rotate 90 degrees around X axis
cube.rotation.x = deg_to_rad(90)

# Now Y and Z rotations produce similar effects
# One degree of freedom is lost
# This is gimbal lock
[/code]

Gimbal lock reveals the limitation of representing 3D rotation with three independent angles. Rotation is not three separate 1D spins - it is a unified 3D phenomenon that Euler angles approximate imperfectly.

Quaternions avoid gimbal lock, but remain conceptually opaque.

[hr]

[b]Rotation as Disorientation[/b]

To rotate an object is to disorient it - to change which way it considers "forward" and "up." The object's internal coordinate system no longer aligns with the world's.

[color=yellow][b]Code: Local Directions After Rotation[/b][/color]
[code]
# Before rotation: forward = -Z axis
var forward_before = Vector3(0, 0, -1)

# Rotate 90 degrees around Y
var quat = Quaternion(Vector3(0, 1, 0), deg_to_rad(90))
var forward_after = quat * forward_before

# Now forward points in -X direction
# "Forward" is no longer aligned with world
[/code]

Rotation reveals: "forward," "up," "right" are not absolute directions but object-relative orientations. The world does not have a canonical forward - only objects do.

[hr]

[b]Ontological Nature: Orientation as Contingent[/b]

Like position with translation, rotation reveals that **orientation is not essential to identity**.

A cube facing north is the same cube as when facing east. Its "cubeness" does not depend on which way it points. Orientation is contingent - could be otherwise.

**But:** In virtual worlds with directed objects (characters, vehicles, cameras), orientation defines behavior:
[code]
# Character's forward direction determines movement
var velocity = transform.basis.z * speed

# Orientation is functionally essential
# even if ontologically contingent
[/code]

Orientation may not define what an object is, but it defines what the object can do.

[hr]

[b]What Rotation Reveals About the World[/b]

Rotation shows us:

1. **Direction is relative** - No absolute "up" or "forward" exists
2. **Rotation is non-commutative** - Order of operations matters
3. **3D rotation is complex** - Requires 4D math (quaternions) to handle fully
4. **Orientation is frame-dependent** - Local vs global axes diverge
5. **Some operations lose degrees of freedom** - Gimbal lock traps rotation
6. **Smooth spinning is interpolated** - Continuous from discrete
7. **Orientation defines capability** - What object can do depends on which way it faces

Rotation asserts that space has no privileged directions - that "up" is a local convention, not a universal constant.

[hr]

[color=cyan][b>Summary:[/b][/color]
Rotation is orientation change without position change - spinning around an axis by an angle. Unlike translation, rotation is non-commutative (order matters) and requires complex mathematics (quaternions) to represent fully. Rotation preserves position, shape, and size while changing which way the object faces. It reveals direction as relative, frame-dependent, and contingent rather than absolute.

[hr]

[color=orange][b]Next:[/b] Scale[/color]
Where translation changed position and rotation changed orientation, scale will change size.
Where translation and rotation preserved the object's magnitude, scale will grow and shrink it.
This is where Alice falls down the rabbit hole - and nothing is the size it should be.

'''
