# Bricolage_Inventory - Technical

## Core Concept in Code

The bricoleur works with what's at hand. In code, this means treating primitives as a typed inventory rather than raw geometry:

```gdscript
# Engineer's approach: design from abstract type
var seat = Plane.new(width=0.5, depth=0.5)
var legs = [Cylinder.new(radius=0.02, height=0.4) for i in range(4)]

# Bricoleur's approach: work with inventory at hand
var inventory = {
    "planes": [plane1, plane2, plane3],  # whatever's available
    "cylinders": [cyl1, cyl2, cyl3, cyl4, cyl5],
    "spheres": [sphere1, sphere2]
}

# Ask: what can these BECOME?
func probe_inventory(parts: Dictionary) -> Array[Affordance]:
    var possibilities = []
    for part_type in parts:
        for part in parts[part_type]:
            possibilities.append_array(discover_affordances(part))
    return possibilities
```

## Implementation: Specimen Display

Each primitive specimen in the map uses elevated pedestals to create museum-like presentation:

```gdscript
# Pedestal structure layer uses height 2 blocks
# Specimens placed on top with vertical offset

func create_specimen_display(primitive: Node3D, position: Vector3) -> void:
    var pedestal = create_block(position, height=2)
    primitive.position = position + Vector3(0, 2.5, 0)  # Above pedestal
    primitive.add_to_group("inventory_specimen")

    # Specimens can be examined but not moved (yet)
    primitive.set_meta("affordances", get_primitive_affordances(primitive))
```

## Inventory as Data Structure

The assemblies.json catalog pattern applies here—inventory is structured data:

```gdscript
# From assemblies.json pattern
var inventory_catalog = {
    "parts": {
        "point": {"count": 1, "affordances": ["mark", "anchor", "vertex"]},
        "line": {"count": 1, "affordances": ["span", "edge", "direction"]},
        "triangle": {"count": 1, "affordances": ["face", "rigid_element", "bracket"]},
        "plane": {"count": 1, "affordances": ["seat", "wall", "shelf", "platform"]},
        "cube": {"count": 1, "affordances": ["volume", "container", "anchor", "mass"]},
        "sphere": {"count": 1, "affordances": ["joint", "hub", "roller", "cap"]},
        "cylinder": {"count": 1, "affordances": ["column", "beam", "axle", "tube"]},
        "torus": {"count": 1, "affordances": ["ring", "gasket", "rim", "handle"]}
    }
}
```

## Why These Design Choices

1. **Pedestals (height 2)**: Elevates specimens to eye level, creates museum/workshop feel
2. **Grid arrangement**: Systematic layout invites systematic examination
3. **Warm lighting**: Workshop atmosphere, not cold laboratory
4. **Two clipboards**: Primary for concept, secondary for preview of next concept
5. **Workbench**: Transition from passive viewing to active engagement

## Interactable Implementation

```gdscript
# Specimen interactable pattern
class InventorySpecimen extends InteractableBase:
    var primitive_type: String
    var affordances: Array[String]

    func _on_interact():
        # Show affordance popup
        var popup = AffordancePopup.new()
        popup.title = "This %s can be..." % primitive_type
        popup.items = affordances
        popup.show()

    func _on_examine():
        # Highlight in inventory workbench
        inventory_workbench.highlight_part(primitive_type)
```

## Key Takeaway

The inventory is not just "stuff"—it's structured possibility. Each part carries metadata about what it can become. The bricoleur's skill is reading this potential.
