extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Scale[/b][/font_size][/center]
[center][i]Alice and the Relativity of Magnitude[/i][/center]

"Curiouser and curiouser!" cried Alice (she was so much surprised, that for the moment she quite forgot how to speak good English). "Now I'm opening out like the largest telescope that ever was! Good-bye, feet!"

In Lewis Carroll's *Alice's Adventures in Wonderland* (1865), Alice drinks potions and eats cakes that make her grow to nine feet tall or shrink to three inches. The world around her stays the same size - but her relationship to it transforms completely.

Scale is the transformation that changes magnitude. The object grows or shrinks. Position and orientation remain fixed - but size mutates.

[hr]

[b]Magnitude as Mutable Property[/b]

If translation changed where and rotation changed which way, scale changes how big. The object occupies more or less space - expands or contracts.

[color=yellow][b]Code: The Scale Operation[/b][/color]
[code]
var cube = MeshInstance3D.new()
cube.position = Vector3(0, 0, 0)  # Stays here
cube.rotation = Vector3(0, 0, 0)  # No rotation
cube.scale = Vector3(1, 1, 1)     # Original size

# Scale to twice the size
cube.scale = Vector3(2, 2, 2)

# Position unchanged, orientation unchanged
# But cube now occupies 8x the volume
[/code]

A unit cube (1x1x1) scaled by 2 becomes a 2x2x2 cube. It has doubled in each dimension - but volume has increased 8-fold.

Scale is not linear in its effects.

[hr]

[b]Uniform vs Non-Uniform Scaling[/b]

Scale can be uniform (same factor in all directions) or non-uniform (different factors for X, Y, Z).

[color=yellow][b]Code: Uniform Scaling[/b][/color]
[code]
# Uniform scale: same in all dimensions
cube.scale = Vector3(2, 2, 2)

# Shape preserved: still a cube
# Just bigger
[/code]

[color=yellow][b]Code: Non-Uniform Scaling[/b][/color]
[code]
# Non-uniform scale: different per axis
cube.scale = Vector3(3, 1, 0.5)

# No longer a cube
# Now a rectangular box (stretched and compressed)
# Shape has changed
[/code]

Non-uniform scaling is deformation - it warps the object. A sphere becomes an ellipsoid. A cube becomes a rectangular prism. Only uniform scaling preserves shape.

[hr]

[b]The Exponential Nature of Volume[/b]

When you double the scale, you do not double the volume - you multiply it by 8 (2³). This is the cube law.

[color=yellow][b]Code: Volume Under Scaling[/b][/color]
[code]
# Original cube: 1x1x1
var volume_before = 1.0

# Scale by factor of 3
var scale_factor = 3.0
cube.scale = Vector3(scale_factor, scale_factor, scale_factor)

# New volume: 3x3x3 = 27
var volume_after = scale_factor * scale_factor * scale_factor
# Volume increased 27-fold from 3x linear scale
[/code]

This is why large objects are qualitatively different from scaled-up small objects. A giant ant (scaled 100x) would have:
- 100x the height
- 10,000x the surface area (100²)
- 1,000,000x the volume and mass (100³)

Its legs (cross-sectional area increased 10,000x) must support a mass increased 1,000,000x. It would collapse under its own weight.

Scale reveals: size is not neutral. Physical laws change with magnitude.

[hr]

[b]Alice's Problem: The Relativity of Size[/b]

When Alice shrinks, the world does not change - only her scale relative to it. A normal doorway becomes impossibly tall. A small key becomes a heavy weight.

[color=yellow][b]Code: Relative Scale[/b][/color]
[code]
# Alice's scale
var alice_scale = 1.0  # Normal size

# Doorway height (constant)
var doorway_height = 2.0

# Alice can pass through
if alice_scale < doorway_height:
    print("Alice fits through the door")

# Alice drinks shrinking potion
alice_scale = 0.1  # 1/10 size

# Doorway now seems 20x taller (relative to Alice)
var relative_height = doorway_height / alice_scale  # 20.0

# The world has not changed
# Alice's relationship to it has transformed
[/code]

"Big" and "small" are not absolute properties - they are relations between object scale and context scale. Alice is not small in herself - she is small *compared to the door*.

Scale reveals: magnitude is relative.

[hr]

[b]Invariance: What Scale Preserves (Uniform Only)[/b]

Uniform scaling preserves:

**Preserved Properties:**
- Position - Center stays fixed
- Orientation - No rotation occurs
- Shape - Proportions maintained
- Angles - All angles between edges unchanged

**Changed Properties:**
- Size - Linear dimensions multiplied
- Area - Surface area scales by factor²
- Volume - Occupied space scales by factor³
- Distances - All lengths multiplied by scale factor

[color=yellow][b]Code: Preservation of Angles[/b][/color]
[code]
# Two edges of a cube form a 90-degree angle
var edge1 = Vector3(1, 0, 0)
var edge2 = Vector3(0, 1, 0)
var angle_before = edge1.angle_to(edge2)  # 90 degrees

# Scale both edges
var scale_factor = 5.0
edge1 *= scale_factor
edge2 *= scale_factor
var angle_after = edge1.angle_to(edge2)  # Still 90 degrees

# Angles preserved, lengths changed
[/code]

Uniform scale is shape-preserving enlargement or reduction. Non-uniform scale is deformation.

[hr]

[b]Negative Scale: Reflection and Inversion[/b]

Scale can be negative - which inverts the object through the origin, mirroring it.

[color=yellow][b]Code: Negative Scaling[/b][/color]
[code]
# Mirror across YZ plane (flip X axis)
cube.scale.x = -1.0

# The cube is now reflected
# Right becomes left, left becomes right
# This is chirality inversion
[/code]

Negative scale does what rotation cannot: it mirrors the object, changing its handedness. A left glove becomes a right glove (in 3D terms).

This reveals: scale is more powerful than rotation. It can transform between enantiomers (mirror-image forms).

[hr]

[b]Zero Scale: Dimensional Collapse[/b]

What happens when scale reaches zero?

[color=yellow][b]Code: Collapsing Dimensions[/b][/color]
[code]
# Scale Z axis to zero
cube.scale.z = 0.0

# Cube has no depth
# 3D object becomes 2D plane
# Dimension lost
[/code]

Scaling to zero collapses a dimension. The object becomes infinitely thin in that axis - effectively losing that dimension. A cube becomes a square, a sphere becomes a circle.

Scale to zero in all dimensions: the object disappears - occupies zero volume, becomes a point.

[hr]

[b]What Scale Cannot Do[/b]

Scale changes size but cannot:

- **Translate** - Position stays fixed (unless pivot offset)
- **Rotate** - Orientation unchanged
- **Change topology** - A cube stays a cube (unless non-uniform)
- **Preserve physical behavior** - Mass, strength, surface area scale differently
- **Make physics-defying giants** - Square-cube law limits biological scaling

Scale multiplies magnitude but does not alter fundamental structure (in uniform case).

[hr]

[b]The Pivot Point: Scale Relative to What?[/b]

Scale occurs around a pivot point - usually the object's origin. Moving the pivot changes how scaling appears.

[color=yellow][b]Code: Pivot Offset[/b][/color]
[code]
# Default: scale around object center
cube.scale = Vector3(2, 2, 2)
# Center stays at same position, edges expand outward

# If pivot at corner instead:
# That corner stays fixed, rest of object grows away from it
[/code]

This is another relativity: scale is not just a multiplier, but a multiplier around a reference point. Different pivots produce different results.

[hr]

[b]Alice's Revelation: Context Defines Magnitude[/b]

After growing and shrinking repeatedly, Alice realizes: her size has no intrinsic meaning. She is only big or small in relation to her surroundings.

When she is ten feet tall in a tiny room, she feels enormous. When she is ten feet tall next to a giant mushroom, she feels small. The same absolute size - different experiential magnitude.

[color=yellow][b]Code: Contextual Size[/b][/color]
[code]
var alice_height = 10.0

# Context 1: Room with 8-foot ceiling
var room_height = 8.0
if alice_height > room_height:
    print("Alice is too big for the room")

# Context 2: Room with 20-foot ceiling
room_height = 20.0
if alice_height < room_height:
    print("Alice is small in this room")

# Same Alice, different context, different meaning
[/code]

Scale reveals: magnitude is not an intrinsic property but a relation to environment.

[hr]

[b]The Square-Cube Law: Why Giants Cannot Exist[/b]

In physical reality, you cannot simply scale organisms up arbitrarily. As size increases:
- Volume (and mass) increases by scale³
- Cross-sectional area (and strength) increases by scale²

[color=yellow][b]Code: Structural Failure Under Scaling[/b][/color]
[code]
var scale_factor = 10.0

# Leg cross-section (strength)
var strength = scale_factor * scale_factor  # 100x stronger

# Body mass (weight to support)
var mass = scale_factor * scale_factor * scale_factor  # 1000x heavier

# Strength-to-weight ratio
var ratio = strength / mass  # 100/1000 = 0.1
# Only 1/10 as strong relative to weight

# Giant collapses under its own mass
[/code]

This is why elephants have thick legs and why insects can lift many times their body weight. Scale is not neutral - physical laws impose limits.

Virtual worlds ignore this. You can scale anything arbitrarily - because there are no real physical constraints, only rendered appearances.

[hr]

[b]Ontological Nature: Size as Relational[/b]

Scale reveals that **magnitude is not intrinsic but relational**.

An object is not "big" in itself - it is big *compared to something*. Size is a property that only exists in context.

**But:** In virtual space, scale is absolute - stored as a numeric multiplier:
[code]
cube.scale = Vector3(2.5, 2.5, 2.5)
# This number exists independently of context
# Absolute scale in a world of relative magnitude
[/code]

The algorithm stores absolute values, but meaning is relational. A contradiction between representation and experience.

[hr]

[b]What Scale Reveals About the World[/b]

Scale shows us:

1. **Size is relative** - Big/small only meaningful in context
2. **Volume scales exponentially** - Not linear with dimension
3. **Shape is preserved only by uniform scaling** - Non-uniform deforms
4. **Physical laws change with magnitude** - Square-cube law limits scaling
5. **Negative scale mirrors** - Reflection, chirality inversion
6. **Zero scale collapses dimensions** - 3D becomes 2D becomes point
7. **Pivot point matters** - Scale is relative to chosen origin
8. **Virtual worlds ignore physics** - Arbitrary scaling possible without consequence

Scale asserts that magnitude has no privileged value - that an object's size is contingent on context, that "normal" is merely conventional.

Alice learns this through transformation. We learn it through the scale parameter.

[hr]

[color=cyan][b]Summary:[/b][/color]
Scale is magnitude change without position or orientation change - growing or shrinking by multiplying dimensions. Volume scales cubically (factor³), not linearly. Uniform scaling preserves shape; non-uniform scaling deforms. Size is relative to context (Alice's revelation), not intrinsic. Physical reality imposes square-cube law limits, but virtual worlds allow arbitrary scaling. Negative scale mirrors objects; zero scale collapses dimensions.

[hr]

[color=orange][b]Question:[/b][/color]
Is size a property of objects, or a relation between objects?
When Alice shrinks, has she changed, or has her relationship to the world changed?
Why can virtual worlds ignore the square-cube law that governs physical reality?

The transformations are complete. You can now move objects (translation), turn them (rotation), and resize them (scale). Each reveals something about the contingency of spatial properties - that position, orientation, and magnitude are not essential to identity, but contextual parameters that can be freely manipulated in computational space.

'''
