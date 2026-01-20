# Bricolage_Sculpture - Technical

## Core Concept in Code

Sculpture as constraint satisfaction without utility constraints:

```gdscript
# Sculpture validator: only physical constraints, no function
class SculptureValidator:
    func is_stable_sculpture(assembly: Assembly) -> SculptureValidation:
        var result = SculptureValidation.new()

        # Physical constraints only
        if not check_gravity_path(assembly):
            result.add_error("Parts will fall - no path to ground")
        if not check_balance(assembly):
            result.add_error("Assembly will tip - center of mass outside base")
        if not check_connectivity(assembly):
            result.add_error("Parts disconnected - assembly will fall apart")

        # No function constraints - that's the point
        # No seat height, no back angle, no use requirements

        # Optional aesthetic metrics
        result.visual_balance = calculate_visual_balance(assembly)
        result.complexity = calculate_complexity(assembly)
        result.negative_space = calculate_negative_space(assembly)

        return result

# Compare to ChairValidator: sculpture has fewer constraints
# Chair: gravity + balance + connectivity + seat_height + back_angle + ...
# Sculpture: gravity + balance + connectivity (period)
```

## Counterweight Implementation

```gdscript
# Counterweight balance calculation
class BalanceCalculator:
    func calculate_required_counterweight(
        assembly: Assembly,
        cantilever_mass: float,
        cantilever_distance: float,
        counterweight_distance: float
    ) -> float:
        # Torque balance: m1 * d1 = m2 * d2
        return (cantilever_mass * cantilever_distance) / counterweight_distance

    func create_counterweight_demo() -> Assembly:
        var assembly = Assembly.new()

        # Fulcrum (pivot point)
        var pivot = Sphere.new(radius=0.1)
        pivot.position = Vector3(0, 0.5, 0)
        assembly.add_part(pivot)

        # Beam across fulcrum
        var beam = Cylinder.new(radius=0.05, height=2.0)
        beam.rotation_degrees.z = 90  # Horizontal
        beam.position = Vector3(0, 0.6, 0)
        assembly.add_part(beam)
        assembly.add_bond(Bond.new(pivot, beam, BondType.PIVOT))

        # Cantilever mass (far from pivot)
        var cantilever = Cube.new(size=Vector3(0.2, 0.2, 0.2))
        cantilever.position = Vector3(0.8, 0.6, 0)
        assembly.add_part(cantilever)

        # Counterweight (close to pivot but heavier)
        var counter = Cube.new(size=Vector3(0.3, 0.3, 0.3))
        counter.position = Vector3(-0.4, 0.6, 0)
        assembly.add_part(counter)

        # Balance: 0.2^3 * 0.8 = 0.3^3 * 0.4 (roughly)
        return assembly
```

## Tension/Tensegrity Implementation

```gdscript
# Tension structure: compression members held by tension cables
class TensionStructure:
    var compression_members: Array[Part]  # Rigid struts
    var tension_members: Array[Cable]     # Flexible cables

    func validate_tensegrity() -> bool:
        # Each compression member must be held by tension
        for strut in compression_members:
            var tension_count = count_attached_cables(strut)
            if tension_count < 3:
                return false  # Insufficient constraint

        # Cables must be in tension (no slack)
        for cable in tension_members:
            if cable.current_length > cable.rest_length:
                return false  # Slack cable

        return true

    func create_tension_demo() -> Assembly:
        var assembly = Assembly.new()

        # Three compression struts (not touching each other)
        var struts = []
        for i in range(3):
            var strut = Cylinder.new(radius=0.03, height=0.8)
            var angle = i * TAU / 3
            strut.position = Vector3(cos(angle) * 0.3, 0.4, sin(angle) * 0.3)
            strut.rotation_degrees.x = 30  # Tilted
            assembly.add_part(strut)
            struts.append(strut)

        # Tension cables connecting strut ends
        for i in range(3):
            var cable1 = Cable.new(struts[i].top, struts[(i+1)%3].bottom)
            var cable2 = Cable.new(struts[i].bottom, struts[(i+1)%3].top)
            assembly.add_cable(cable1)
            assembly.add_cable(cable2)

        return assembly
```

## Visual Balance Calculation

```gdscript
# Visual mass differs from physical mass
class VisualBalanceCalculator:
    func calculate_visual_mass(part: Part) -> float:
        var physical_mass = part.get_volume() * part.density

        # Visual adjustments
        var visual_mass = physical_mass

        # Dark colors appear heavier
        visual_mass *= lerp(1.0, 1.3, part.color.get_luminance_inverse())

        # Textured surfaces appear heavier
        visual_mass *= lerp(1.0, 1.2, part.texture_density)

        # Lower parts appear heavier (grounded)
        visual_mass *= lerp(0.9, 1.1, inverse_lerp(0, 2, part.position.y))

        # Dense/compact shapes appear heavier than extended shapes
        var compactness = part.get_volume() / part.bounding_box.get_volume()
        visual_mass *= lerp(0.8, 1.2, compactness)

        return visual_mass

    func calculate_visual_center_of_mass(assembly: Assembly) -> Vector3:
        var total_visual_mass = 0.0
        var weighted_pos = Vector3.ZERO

        for part in assembly.parts:
            var vm = calculate_visual_mass(part)
            weighted_pos += part.position * vm
            total_visual_mass += vm

        return weighted_pos / total_visual_mass
```

## Why These Design Choices

1. **Gallery lighting**: Shifts from making to contemplating
2. **Two example sculptures**: Shows variety within constraint satisfaction
3. **Technique demonstrations**: Counterweight and tension are key sculptural methods
4. **No function requirements**: Deliberately contrasts with chair

## Key Takeaway

Sculpture proves that bricolage doesn't require utility. Constraint satisfaction alone—gravity, balance, connectivity—produces form. The sculptor is a bricoleur whose only constraint is standing.
