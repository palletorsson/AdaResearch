# Bricolage_Arrays_as_Probes - Technical

## Core Concept in Code

Arrays as probes—systematic exploration of what parts can become:

```gdscript
# Array types as exploration strategies
enum ArrayType {
    LINEAR,   # for i in range(n): pos + i*direction
    RADIAL,   # for i in range(n): rotate_around(center, i*angle)
    GRID,     # for i in range(w): for j in range(h): pos + i*x + j*y
    STACK     # for i in range(n): pos + i*Vector3.UP
}

# Probe function: what does this part want to become?
func probe_with_array(part: Primitive, array_type: ArrayType, count: int) -> EmergentStructure:
    var instances = create_array(part, array_type, count)
    var structure = analyze_emergence(instances)
    return structure

# Example: probing cylinder with different array types
func probe_cylinder():
    var cyl = Cylinder.new(radius=0.05, height=1.0)

    # Linear probe → fence, ladder, colonnade
    var linear = probe_with_array(cyl, ArrayType.LINEAR, 10)
    print(linear.suggests)  # ["fence", "ladder", "colonnade", "spine"]

    # Radial probe → wheel, dome_base, turbine
    var radial = probe_with_array(cyl, ArrayType.RADIAL, 12)
    print(radial.suggests)  # ["wheel_spoke", "dome_strut", "star"]

    # Grid probe → forest, column_field
    var grid = probe_with_array(cyl, ArrayType.GRID, 16)
    print(grid.suggests)  # ["column_forest", "support_grid"]

    # Stack probe → tower, chimney
    var stack = probe_with_array(cyl, ArrayType.STACK, 5)
    print(stack.suggests)  # ["tower", "segmented_column"]
```

## Implementation: Array Demonstrations

Each demonstration station shows a part repeated in a specific pattern:

```gdscript
# Linear array demonstration
func create_linear_array_demo(part: Primitive, count: int, spacing: float) -> Node3D:
    var demo = Node3D.new()
    for i in range(count):
        var instance = part.duplicate()
        instance.position = Vector3(i * spacing, 0, 0)
        demo.add_child(instance)

    # Add emergence label
    var label = Label3D.new()
    label.text = "Linear: fence, ladder, spine"
    label.position = Vector3(count * spacing / 2, 1.5, 0)
    demo.add_child(label)

    return demo

# Radial array demonstration
func create_radial_array_demo(part: Primitive, count: int, radius: float) -> Node3D:
    var demo = Node3D.new()
    var angle_step = TAU / count
    for i in range(count):
        var instance = part.duplicate()
        var angle = i * angle_step
        instance.position = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
        instance.look_at(Vector3.ZERO)  # point toward center
        demo.add_child(instance)

    var label = Label3D.new()
    label.text = "Radial: wheel, star, dome"
    label.position = Vector3(0, 1.5, 0)
    demo.add_child(label)

    return demo
```

## Array Emergence Analysis

The probe detects emergent properties:

```gdscript
# Analyze what structure emerges from arrayed parts
class EmergenceAnalyzer:
    func analyze(instances: Array[Primitive]) -> EmergentStructure:
        var structure = EmergentStructure.new()

        # Check for linear alignment
        if is_linear_arrangement(instances):
            structure.suggests.append("fence")
            structure.suggests.append("spine")
            if all_vertical(instances):
                structure.suggests.append("colonnade")

        # Check for radial symmetry
        if has_radial_symmetry(instances):
            structure.suggests.append("wheel")
            structure.suggests.append("star")
            if parts_point_inward(instances):
                structure.suggests.append("dome_base")

        # Check for planar coverage
        if forms_surface(instances):
            structure.suggests.append("floor")
            structure.suggests.append("wall")
            structure.suggests.append("platform")

        # Check for vertical stacking
        if is_vertical_stack(instances):
            structure.suggests.append("tower")
            structure.suggests.append("shelf")

        return structure
```

## The Probe-Discover Pattern

```gdscript
# Bricoleur workflow: probe → discover → assemble
class BricoleurWorkflow:
    var inventory: Array[Primitive]
    var discoveries: Dictionary  # part_type -> Array[EmergentStructure]

    func explore_inventory():
        for part in inventory:
            discoveries[part.type] = []
            for array_type in ArrayType.values():
                var probe_result = probe_with_array(part, array_type, 8)
                if probe_result.has_emergence():
                    discoveries[part.type].append(probe_result)

    func what_can_become(part_type: String) -> Array[String]:
        var possibilities = []
        for discovery in discoveries[part_type]:
            possibilities.append_array(discovery.suggests)
        return possibilities
```

## Why These Design Choices

1. **Four array types**: Covers the fundamental repetition patterns (1D linear, 1D angular, 2D planar, 1D vertical)
2. **Low demonstration height (0.3)**: Player can see patterns from above
3. **Corner positioning**: Clear spatial separation between types
4. **nested_arrays_axioms reference**: Connects to existing axiom file on dimensional ladder

## Key Takeaway

Arrays are not about making "more"—they're about discovering what "more" reveals. The bricoleur uses repetition as a probe, systematically asking parts what they want to become.
