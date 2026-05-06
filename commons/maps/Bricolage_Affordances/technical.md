# Bricolage_Affordances - Technical

## Core Concept in Code

Affordances emerge from the relationship between part properties and context requirements:

```gdscript
# Affordance as function, not category
class Affordance:
    var part: Primitive
    var context: AssemblyContext
    var action: String  # "support", "span", "rotate", "contain", etc.

    func is_satisfied() -> bool:
        return context.requirements_met_by(part, action)

# Example: cylinder affordances depend on orientation and neighbors
func discover_cylinder_affordances(cyl: Cylinder, context: AssemblyContext) -> Array[Affordance]:
    var affordances = []

    # Column affordance: vertical, has load above
    if cyl.orientation == Vector3.UP and context.has_load_above(cyl):
        affordances.append(Affordance.new(cyl, context, "column"))

    # Beam affordance: horizontal, spans between supports
    if cyl.orientation.dot(Vector3.UP) < 0.1 and context.has_supports_at_ends(cyl):
        affordances.append(Affordance.new(cyl, context, "beam"))

    # Axle affordance: horizontal, has rotating parts
    if context.has_rotating_attachment(cyl):
        affordances.append(Affordance.new(cyl, context, "axle"))

    return affordances
```

## Implementation: Affordance Demonstration Stations

Each station shows the same primitive in different contexts:

```gdscript
# Affordance demonstration station
class AffordanceStation:
    var primitive: Primitive
    var context_a: AssemblyContext  # e.g., column context
    var context_b: AssemblyContext  # e.g., axle context

    func setup_demonstration():
        # Left side: context A
        var part_a = primitive.duplicate()
        part_a.position = station_pos + Vector3(-1.5, 0, 0)
        context_a.apply_to(part_a)
        context_a.add_visual_indicators()  # show load arrows, rotation arrows, etc.

        # Right side: context B
        var part_b = primitive.duplicate()
        part_b.position = station_pos + Vector3(1.5, 0, 0)
        context_b.apply_to(part_b)
        context_b.add_visual_indicators()
```

## Affordance Catalog Data Structure

The affordance_catalog_axioms file provides structured affordance data:

```gdscript
# Affordance catalog as structured data
var AFFORDANCE_CATALOG = {
    "cylinder": {
        "structural": ["column", "beam", "strut", "pillar"],
        "functional": ["axle", "roller", "tube", "pipe"],
        "spatial": ["shaft", "tunnel", "bore"],
        "relational": ["connector", "spacer", "extension"]
    },
    "plane": {
        "structural": ["platform", "floor", "ceiling", "shelf"],
        "functional": ["seat", "tabletop", "work_surface"],
        "spatial": ["wall", "partition", "barrier", "divider"],
        "relational": ["bridge", "ramp", "lid", "cover"]
    },
    "sphere": {
        "structural": ["dome", "cap", "hull"],
        "functional": ["joint", "bearing", "roller", "ball"],
        "spatial": ["node", "hub", "center"],
        "relational": ["connector", "terminator", "transition"]
    }
}

# Query affordances by capability
func can_perform(primitive_type: String, action: String) -> bool:
    for category in AFFORDANCE_CATALOG[primitive_type].values():
        if action in category:
            return true
    return false
```

## Contextual Activation

Affordances are latent until activated by context:

```gdscript
# Context activates specific affordances
class AssemblyContext:
    var gravity: Vector3
    var loads: Array[LoadVector]
    var neighbors: Array[Part]
    var intended_use: String

    func activate_affordances(part: Part) -> Array[String]:
        var active = []

        # Gravity + vertical orientation + load = column
        if part.type == "cylinder":
            if part.up_aligned() and self.has_load_above(part):
                active.append("column")
            if part.horizontal() and self.spans_gap(part):
                active.append("beam")

        return active
```

## Why These Design Choices

1. **Paired demonstrations**: Same shape, different context—makes the point undeniable
2. **Pedestal positioning (height 2)**: Elevates demonstrations for examination
3. **Three primitive types**: Cylinder, plane, sphere—cover the essential shape categories
4. **Two affordances per type**: Manageable cognitive load, clear contrast
5. **Systematic layout**: North/south progression creates a tour

## Key Takeaway

A part's category (cylinder, plane, sphere) is less important than its affordance profile—what it can DO in context. The bricoleur thinks in affordances, not categories.
