extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Bricolage[/b][/font_size][/center]
[center][i]From Primitives to Structures Without Blueprint[/i][/center]

**Bricolage is construction without a blueprint: structures emerge by recombining existing parts until constraints are satisfied.**

The term comes from Claude Lévi-Strauss, who contrasts two modes of making:

**Engineer**: designs from abstract principles, invents tools for the task, works from blueprint to object.

**Bricoleur**: works with what is at hand, recombines existing elements, discovers structure through constraint.

This distinction matters. We are not engineers here. We are bricoleurs.

[hr]

[b]The Bricoleur's Method[/b]

The engineer asks: "What do I need to build this?"
The bricoleur asks: "What can I build with this?"

The engineer starts with a plan.
The bricoleur starts with an **inventory**.

[color=yellow][b]Code: Two Approaches[/b][/color]
[code]
# Engineer's approach
func build_chair():
    var blueprint = load("chair_blueprint.json")
    var parts = manufacture_parts(blueprint.specifications)
    var chair = assemble_according_to_plan(parts, blueprint)
    return chair

# Bricoleur's approach
func bricolage():
    var inventory = get_what_exists()  # Primitives, transforms, arrays
    var affordances = discover_what_parts_can_do(inventory)
    var attempts = recombine_until_stable(affordances)
    var structure = what_emerges_when_constraints_satisfied(attempts)
    return structure
[/code]

The engineer knows what they're building before they start.
The bricoleur discovers what they've built when constraints stop pushing back.

[i]Structure is not imposed—it crystallizes.[/i]

[hr]

[b]From Primitives to Inventory[/b]

Bricolage does not start with ideal form.
It starts with **what exists**.

You have already built an inventory through the primitives sequence:

[color=yellow][b]The Primitive Inventory[/b][/color]
[code]
# Not "shapes" — potential parts
var inventory = {
    "point": {
        "affordances": ["position", "anchor", "vertex", "origin"]
    },
    "line": {
        "affordances": ["span", "connect", "edge", "direction"]
    },
    "triangle": {
        "affordances": ["surface", "stability", "face", "minimal_plane"]
    },
    "plane": {
        "affordances": ["platform", "wall", "membrane", "division"]
    },
    "cube": {
        "affordances": ["volume", "container", "module", "voxel"]
    },
    "sphere": {
        "affordances": ["joint", "node", "distribution", "enclosure"]
    },
    "cylinder": {
        "affordances": ["strut", "beam", "axle", "column"]
    }
}
[/code]

A primitive is not "a shape"—it is a **potential part**.
The cylinder is not "a cylinder"—it is load-bearing, spanning, rotatable, stackable.

[i]Identity dissolves into affordance.[/i]

[hr]

[b]Affordances: What Can This Part Do?[/b]

In bricolage, parts are defined by **what they afford**, not what they are named.

A stick is not "a leg"—it is:
- load-bearing (can support weight)
- spanning (can bridge gaps)
- lever-like (can pivot)
- stackable (can accumulate)

[color=yellow][b]Code: Affordance Catalog[/b][/color]
[code]
# Cylinder affordances
var cylinder_affordances = {
    "structural": [
        "vertical_support",   # Column, leg
        "horizontal_span",    # Beam, rail
        "diagonal_brace",     # Strut, tension member
    ],
    "mechanical": [
        "axle",               # Rotation axis
        "pivot_point",        # Hinge component
        "connector",          # Bridge between nodes
    ],
    "spatial": [
        "linear_extrusion",   # Path through space
        "boundary_marker",    # Edge definition
        "rhythm_element",     # Repeated pattern
    ]
}

# Plane affordances
var plane_affordances = {
    "structural": [
        "platform",           # Standing, sitting surface
        "wall",               # Vertical division
        "roof",               # Overhead shelter
    ],
    "functional": [
        "seat",               # Support for body
        "table_top",          # Work surface
        "shelf",              # Storage plane
    ],
    "spatial": [
        "divider",            # Space separation
        "reflector",          # Light/sound bounce
        "membrane",           # Tension surface
    ]
}
[/code]

The chair does not pre-exist.
It crystallizes when:
- a plane affords "seat"
- cylinders afford "vertical_support"
- connections afford "stability"

[i]Form follows affordance, not intention.[/i]

[hr]

[b]Arrays as Exhaustion of Possibility[/b]

In classical curriculum: Arrays = repetition.
In bricolage: Arrays = **systematic probing**.

When you array a primitive, you are asking:
"What does this part want to become if repeated?"

[color=yellow][b]Code: Arrays as Questions[/b][/color]
[code]
# Linear array asks: "What if I keep adding?"
var linear = []
for i in range(10):
    linear.append(cylinder.duplicate())
    linear[i].position.x = i * spacing
# Answer: fence, ladder, spine, rail

# Radial array asks: "What if I distribute around center?"
var radial = []
for i in range(8):
    var angle = i * (TAU / 8)
    radial.append(strut.duplicate())
    radial[i].rotation.y = angle
# Answer: wheel, dome base, star, octopus

# Grid array asks: "What if I fill a plane?"
var grid = []
for x in range(5):
    for z in range(5):
        grid.append(cube.duplicate())
        grid[-1].position = Vector3(x, 0, z)
# Answer: floor, wall, platform, foundation

# Vertical stack asks: "What if height accumulates?"
var stack = []
for y in range(6):
    stack.append(plane.duplicate())
    stack[y].position.y = y * layer_height
# Answer: shelf, tower, layer cake, stratigraphy
[/code]

Arrays are not final forms—they are **probing tools**.
They reveal what inventory wants to become.

[i]Repetition is interrogation.[/i]

[hr]

[b]Constraints: What Pushes Back[/b]

A bricoleur does not assemble freely.
They assemble **until constraints push back**.

[color=yellow][b]The Constraint Catalog[/b][/color]
[code]
# Physical constraints
var gravity = "structures must not float"
var collision = "parts cannot overlap"
var support = "load must reach ground"
var balance = "center of mass over base"

# Topological constraints
var connectivity = "parts must touch to bond"
var closure = "enclosure requires complete boundary"
var continuity = "paths must not break"

# Structural constraints
var triangulation = "triangles resist deformation"
var redundancy = "multiple load paths increase stability"
var distribution = "forces spread through connections"

# Discovered constraints
var wobble = "insufficient support causes instability"
var collapse = "exceeded load capacity fails"
var gap = "missing connection breaks structure"
[/code]

Structure emerges when constraints are satisfied:

[code]
func attempt_assembly(parts, bonds):
    var structure = connect(parts, bonds)

    # Test constraints
    if not touches_ground(structure):
        return "floats — add support"
    if not balanced(structure):
        return "tips — redistribute mass"
    if not connected(structure):
        return "falls apart — add bonds"
    if wobbles(structure):
        return "unstable — triangulate or add redundancy"

    # All constraints satisfied
    return structure  # This is now a stable form
[/code]

A chair becomes a chair when:
- load paths appear (legs to ground)
- redundancy stabilizes (four legs, not three)
- wobble disappears (connections rigid)

Not because "chair" was defined—
but because **constraints were satisfied**.

[i]Stability is the signature of solved constraints.[/i]

[hr]

[b]The Chair as Vernacular Bricolage[/b]

The chair is the perfect bricolage object:
- historically improvised from available materials
- joint logic matters more than form logic
- teaches anchors, stability, redundancy

[color=yellow][b]Code: Chair Emerges from Constraints[/b][/color]
[code]
# Start with inventory
var seat = Plane.new()      # Affords: platform, sitting surface
var back = Plane.new()      # Affords: support, lean-against
var legs = [Cylinder.new(), Cylinder.new(),
            Cylinder.new(), Cylinder.new()]  # Afford: vertical support

# Position by affordance
seat.position = Vector3(0, 0.5, 0)           # Sitting height
back.position = Vector3(0, 0.85, -0.22)      # Behind seat, angled
back.rotation.x = -0.1                        # Slight recline

for i in range(4):
    var x = [-0.18, 0.18, -0.18, 0.18][i]
    var z = [0.18, 0.18, -0.18, -0.18][i]
    legs[i].position = Vector3(x, 0.25, z)    # Under seat corners

# Bonds discovered through constraint
var bonds = [
    [seat, back],   # Back must connect to seat
    [seat, legs[0]], [seat, legs[1]],  # Legs must support seat
    [seat, legs[2]], [seat, legs[3]]
]

# Test: Does it stand? Does it hold weight? Does it wobble?
# If yes to first two, no to third: chair has emerged.
[/code]

The chair was not designed—it was **discovered** through constraint satisfaction.

[i]Vernacular forms are frozen bricolage.[/i]

[hr]

[b]The Sculpture as Balance Discovery[/b]

Abstract sculpture is bricolage without function:
- no sitting requirement
- no load specification
- only: balance, tension, visual weight

[color=yellow][b]Code: Sculpture Through Counterweight[/b][/color]
[code]
# Tatlin's Tower, Calder's mobiles: bricolage, not engineering

var masses = []
var connections = []

# Add element
func add_mass(position: Vector3, weight: float):
    masses.append({"pos": position, "weight": weight})
    recalculate_balance()

# Check balance
func recalculate_balance():
    var center_of_mass = Vector3.ZERO
    var total_weight = 0.0

    for m in masses:
        center_of_mass += m.pos * m.weight
        total_weight += m.weight

    center_of_mass /= total_weight

    # Constraint: center of mass over support
    if not over_base(center_of_mass):
        suggest_counterweight(center_of_mass)

func suggest_counterweight(com: Vector3):
    # Bricoleur response: add mass on opposite side
    var offset = -com.normalized() * compensation_distance
    print("Add counterweight at: ", offset)
[/code]

The sculpture emerges when:
- visual masses balance
- tension members pull taut
- nothing tips, sags, or collapses

Meaning emerges from relations, not from plan.

[i]Sculpture is frozen negotiation with gravity.[/i]

[hr]

[b]The Geodesic Dome as Formalized Bricolage[/b]

The dome appears engineered—calculated struts, precise angles.
But Fuller framed it as **discovery**, not invention.

[color=yellow][b]Code: Dome Emerges from Local Rules[/b][/color]
[code]
# Start with icosahedron (20 triangles)
var vertices = icosahedron_vertices()
var faces = icosahedron_faces()

# Bricolage operation: subdivide each triangle
func subdivide(frequency: int):
    for face in faces:
        var new_vertices = subdivide_triangle(face, frequency)
        for v in new_vertices:
            # Project to sphere surface (local rule)
            v = v.normalized() * radius
            vertices.append(v)

# Constraint: triangles must close
# Constraint: vertices must lie on sphere
# Constraint: struts must have consistent length (approximately)

# What emerges: geodesic dome
# Not designed top-down
# Discovered through repeated local operations + constraint
[/code]

The dome is bricolage **scaled up and formalized**:
- repeated struts (inventory)
- local triangulation (affordance of triangle: stability)
- topological rules (constraints)
- spherical emergence (structure)

Fuller did not invent the dome.
He discovered what triangulated struts want to become when arrayed spherically.

[i]The dome is what triangles dream of.[/i]

[hr]

[b]From Primitives to Worlds[/b]

The bricolage sequence:

[color=cyan][b]1. INVENTORY[/b][/color] — What primitives exist
   Point, line, triangle, plane, cube, sphere, cylinder
   These are not shapes—they are potential parts

[color=cyan][b]2. AFFORDANCE[/b][/color] — What each primitive can do
   Cylinder: support, span, rotate, connect
   Plane: platform, divide, shelter, reflect

[color=cyan][b]3. ARRAYS[/b][/color] — Systematic exhaustion of possibility
   Linear, radial, grid, stack
   "What does this part want to become if repeated?"

[color=cyan][b]4. CONSTRAINTS[/b][/color] — What pushes back
   Gravity, collision, connectivity, balance
   Structure emerges when constraints stop complaining

[color=cyan][b]5. STRUCTURE[/b][/color] — What crystallizes
   Chair, sculpture, dome, building
   Not designed—discovered

[hr]

[b]Why Bricolage Matters[/b]

Bricolage is not a fallback for those who cannot engineer.
It is a **structural epistemology**—a way of knowing through making.

The bricoleur learns:
- **Constraint literacy**: what pushes back, what gives way
- **Relational thinking**: parts defined by connections, not essence
- **Structural intuition**: feeling when something will stand or fall
- **Emergence**: wholes that exceed their parts

This aligns with:
- **Intuitionism**: inner construction over formal derivation
- **QFEP**: structure as free energy minimum, stability as satisfied constraint
- **Queer theory**: identity through relation, not category

[i]Bricolage is the lived practice of moving from primitives to worlds.[/i]

[hr]

[color=cyan][b]Summary:[/b][/color]
Bricolage is construction without blueprint. The bricoleur works with existing inventory (primitives), discovers affordances (what parts can do), uses arrays to probe possibility, and assembles until constraints (gravity, balance, connectivity) are satisfied. Structure emerges—it is not imposed. Chair, sculpture, dome: all are frozen bricolage. This is how we move from primitives to worlds.

[hr]

[color=orange][b]Next:[/b] The Assembly Sequence[/color]
From inventory to chair, from chair to sculpture, from sculpture to dome.
Each step: same method, increasing scale.
Bricolage all the way up.

'''
