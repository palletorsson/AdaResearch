extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Translation[/b][/font_size][/center]
[center][i]Movement Through Indexed Space[/i][/center]

Translation is the simplest transformation: moving an object from one position to another without rotating it, without scaling it, without changing anything about its internal structure.

Translation is pure displacement. The object remains identical to itself - only its address in space changes.

[hr]

[b]Position as Mutable Property[/b]

Before transformation, we had static primitives - forms frozen in space. Translation reveals that position is not intrinsic to an object. The cube is still a cube whether it sits at (0,0,0) or (5,3,2).

[color=yellow][b]Code: The Translation Operation[/b][/color]
[code]
var cube_position = Vector3(0, 0, 0)
var displacement = Vector3(5, 0, 0)

# Translation is vector addition
var new_position = cube_position + displacement
# Result: Vector3(5, 0, 0)

# The cube has moved 5 units along X axis
# But the cube itself is unchanged
[/code]

Translation is addition in vector space. The object's identity is preserved - only its coordinates change.

[hr]

[b]Displacement as Vector[/b]

The displacement is not a position - it is a direction and magnitude. It says: "move this far in this direction."

[color=yellow][b]Code: Displacement vs Position[/b][/color]
[code]
# Position: absolute location in world space
var position = Vector3(10, 5, 3)  # "I am here"

# Displacement: relative movement
var displacement = Vector3(2, 0, -1)  # "Move this way"

# Translation combines them
position += displacement  # Vector3(12, 5, 2)

# Displacement has no absolute location
# It exists only as difference, as change
[/code]

A displacement vector (2, 0, -1) means:
- Move 2 units in X direction
- Move 0 units in Y direction
- Move -1 units in Z direction

It does not care where you started. It only describes the journey.

[hr]

[b]Invariance: What Translation Preserves[/b]

Translation changes position, but preserves everything else:

**Preserved Properties:**
- Shape - The cube remains cubic
- Size - All edges same length
- Orientation - No rotation occurs
- Internal structure - Vertices maintain relative positions
- Volume - Space occupied unchanged

[color=yellow][b]Code: Preservation of Structure[/b][/color]
[code]
# Before translation
var v0 = Vector3(0, 0, 0)
var v1 = Vector3(1, 0, 0)
var distance_before = v0.distance_to(v1)  # 1.0

# After translation
v0 += Vector3(10, 5, 3)
v1 += Vector3(10, 5, 3)
var distance_after = v0.distance_to(v1)  # Still 1.0

# All internal distances preserved
# Shape unchanged
[/code]

Translation is the transformation of position, not of form. The object travels through space while maintaining its identity.

[hr]

[b]Global vs Local: Whose Movement?[/b]

But movement is relative. When the cube translates from (0,0,0) to (5,0,0), what actually moved?

**Two Interpretations:**
1. The cube moved through static space (object-relative)
2. Space moved past a static cube (space-relative)

[color=yellow][b]Code: Reference Frame Ambiguity[/b][/color]
[code]
# Translate the cube
cube.position += Vector3(5, 0, 0)

# Equivalent to translating the camera in opposite direction
camera.position -= Vector3(5, 0, 0)

# Visually identical results
# But ontologically different claims
[/code]

There is no absolute space to measure against. All movement is relative to a chosen reference frame. Translation reveals: space is not a container, but a relation.

[hr]

[b]The Grid as Cadastral System Revisited[/b]

Translation moves objects through the grid we explored in grid_axioms. Every position change is a change of address - a new set of coordinates.

[color=yellow][b]Code: Moving Through Indexed Space[/b][/color]
[code]
# Object's grid coordinates
var grid_x = floor(position.x)
var grid_y = floor(position.y)
var grid_z = floor(position.z)

# After translation, new grid cell
position += displacement
var new_grid_x = floor(position.x)

# The object has crossed a grid boundary
# Its cadastral address has changed
[/code]

Translation is navigation through indexed space. Every coordinate change is tracked, recorded, addressable. To move is to confess your new location.

[hr]

[b]Translation and Continuity[/b]

In the algorithm, translation happens instantly - position jumps from A to B in a single frame. But in rendered space, we interpolate to create the illusion of smooth motion.

[color=yellow][b]Code: Interpolated Translation[/b][/color]
[code]
var start_position = Vector3(0, 0, 0)
var end_position = Vector3(10, 0, 0)
var t = 0.0  # Progress from 0 to 1

func _process(delta):
    t += delta * 0.5  # Speed of transition
    if t > 1.0:
        t = 1.0

    # Linear interpolation
    position = start_position.lerp(end_position, t)

    # Creates smooth motion from discrete jumps
[/code]

The discrete algorithm performs continuous motion through interpolation. Translation reveals the gap between computational state (instant) and rendered experience (smooth).

[hr]

[b]What Translation Cannot Do[/b]

Translation is pure displacement. It cannot:

- **Rotate** - Object maintains orientation
- **Scale** - Object maintains size
- **Deform** - Internal structure rigid
- **Teleport non-locally** - Must specify displacement vector
- **Move without leaving trace** - Grid records all coordinate changes

Translation is the most constrained transformation - it changes position and nothing else.

[hr]

[b]Translation as Freedom and Surveillance[/b]

To translate is to move freely through space - the object can go anywhere, navigate the entire grid, explore all positions.

But every translation is recorded. The grid knows where you were and where you are now. The displacement vector is evidence of your path.

[color=yellow][b]Code: Movement History[/b][/color]
[code]
var movement_history = []

func translate(displacement: Vector3):
    movement_history.append({
        "from": position,
        "to": position + displacement,
        "time": Time.get_ticks_msec()
    })
    position += displacement

# Every translation logged
# The archive of all displacements
# Your path is known
[/code]

Translation offers navigable freedom within surveilled space. You can move anywhere - but your movement is always addressable, always indexed.

[hr]

[b]Ontological Nature: Position as Contingent[/b]

Translation reveals that **position is not essential to identity**.

The cube is a cube regardless of where it sits. Its "cubeness" does not depend on coordinates. Position is contingent - it could be otherwise without changing what the object is.

This is a materialist claim: objects are defined by their internal relations (edges, faces, vertices), not by their location in abstract space.

**But:** In a computational world, position is the first property we assign:
[code]
var cube = MeshInstance3D.new()
cube.position = Vector3(0, 0, 0)  # Must exist somewhere
[/code]

Even if position is contingent philosophically, it is mandatory computationally. The object cannot exist without coordinates.

[hr]

[b]What Translation Reveals About the World[/b]

Translation shows us:

1. **Space is navigable** - Objects can move through it freely
2. **Space is indexed** - Every position has coordinates
3. **Movement is relative** - No absolute reference frame exists
4. **Identity is preserved** - Objects remain themselves through displacement
5. **Position is contingent** - Where something is does not define what it is
6. **Displacement is vectorial** - Movement has direction and magnitude
7. **Motion is interpolated** - Smooth experience from discrete state

Translation is the most fundamental transformation - it asserts that objects are not bound to locations, that space is a field of possible positions rather than a fixed container.

[hr]

[color=cyan][b]Summary:[/b][/color]
Translation is displacement without rotation or scaling - pure position change via vector addition. It preserves shape, size, orientation, and internal structure while changing coordinates. Translation reveals position as contingent rather than essential, space as navigable and indexed, and movement as relative to chosen reference frames. Every translation is recorded by the grid - freedom of movement within surveillance.

[hr]

[color=orange][b]Next:[/b] Rotation[/color]
Where translation changed position, rotation will change orientation.
Where translation preserved "which way is up," rotation will spin that question.
Translation moved through space. Rotation will move space around the object.

'''
