# Bricolage_Constraints - Technical

## Core Concept in Code

Constraints as validation functions that assemblies must satisfy:

```gdscript
# Constraint interface
class Constraint:
    var name: String
    var description: String

    func is_satisfied(assembly: Assembly) -> bool:
        pass  # Override in subclass

    func get_violations(assembly: Assembly) -> Array[Violation]:
        pass  # Returns specific failures

# Core constraints
class GravityConstraint extends Constraint:
    func is_satisfied(assembly: Assembly) -> bool:
        for part in assembly.parts:
            if not has_path_to_ground(part, assembly):
                return false
        return true

    func has_path_to_ground(part: Part, assembly: Assembly) -> bool:
        if part.position.y <= 0:
            return true  # On ground
        for bond in assembly.get_bonds_from(part):
            var neighbor = bond.other_end(part)
            if neighbor.position.y < part.position.y:
                if has_path_to_ground(neighbor, assembly):
                    return true
        return false  # Floating

class BalanceConstraint extends Constraint:
    func is_satisfied(assembly: Assembly) -> bool:
        var com = assembly.center_of_mass()
        var base = assembly.support_polygon()
        return base.contains_point_2d(Vector2(com.x, com.z))

class TriangulationConstraint extends Constraint:
    func is_satisfied(assembly: Assembly) -> bool:
        # All closed loops must be triangular
        for loop in assembly.get_closed_loops():
            if loop.edge_count() > 3 and not loop.is_braced():
                return false
        return true
```

## Implementation: Fail/Pass Demonstrations

Each demonstration shows identical parts in different configurations:

```gdscript
# Gravity demonstration
func create_gravity_demo():
    var parts = [
        Cube.new(position=Vector3(0, 0, 0)),  # Base
        Cube.new(position=Vector3(0, 1, 0)),  # Middle
        Cube.new(position=Vector3(0, 2, 0))   # Top
    ]

    # Fail version: remove middle support
    var fail = Assembly.new()
    fail.add_part(parts[0].duplicate())
    fail.add_part(parts[2].duplicate())  # Top with gap
    fail.position = fail_station_pos
    # Visual: top cube shown with "falling" indicator

    # Pass version: complete stack
    var pass = Assembly.new()
    for p in parts:
        pass.add_part(p.duplicate())
    pass.position = pass_station_pos
    # Visual: stable stack

# Balance demonstration
func create_balance_demo():
    var beam = Plane.new(width=3, depth=0.5)
    var weight = Cube.new(scale=Vector3(0.5, 0.5, 0.5))
    var support = Cylinder.new(radius=0.1, height=1)

    # Fail version: weight cantilevered past support
    var fail = Assembly.new()
    fail.add_part(support.duplicate())
    fail.add_part(beam.duplicate())
    fail.add_part(weight.duplicate())
    weight.position = Vector3(1.5, 0, 0)  # Past edge
    # Visual: tipping indicator

    # Pass version: weight over support, or counterweighted
    var pass = Assembly.new()
    pass.add_part(support.duplicate())
    pass.add_part(beam.duplicate())
    pass.add_part(weight.duplicate())
    weight.position = Vector3(0, 0, 0)  # Centered
    # Or add counterweight on opposite side
```

## Constraint Checking System

```gdscript
# Constraint system for assembly validation
class ConstraintSystem:
    var constraints: Array[Constraint] = [
        GravityConstraint.new(),
        BalanceConstraint.new(),
        ConnectivityConstraint.new(),
        TriangulationConstraint.new()
    ]

    func validate(assembly: Assembly) -> ValidationResult:
        var result = ValidationResult.new()
        result.passed = true

        for constraint in constraints:
            if not constraint.is_satisfied(assembly):
                result.passed = false
                result.violations.append_array(constraint.get_violations(assembly))

        return result

    func get_feedback(assembly: Assembly) -> String:
        var result = validate(assembly)
        if result.passed:
            return "All constraints satisfied - structure stable"
        else:
            var feedback = "Constraint violations:\n"
            for v in result.violations:
                feedback += "- %s: %s\n" % [v.constraint_name, v.description]
            return feedback
```

## Triangulation Specifics

```gdscript
# Triangulation analysis
class TriangulationAnalyzer:
    func analyze_frame(assembly: Assembly) -> TriangulationReport:
        var report = TriangulationReport.new()

        for face in assembly.get_faces():
            if face.edge_count() == 3:
                report.triangles.append(face)
            elif face.edge_count() == 4:
                if face.has_diagonal_brace():
                    report.braced_quads.append(face)
                else:
                    report.unbraced_quads.append(face)  # Racking risk

        report.is_rigid = report.unbraced_quads.is_empty()
        return report

    func suggest_bracing(assembly: Assembly) -> Array[BraceSuggestion]:
        var suggestions = []
        for quad in assembly.get_unbraced_quads():
            suggestions.append(BraceSuggestion.new(
                from=quad.corners[0],
                to=quad.corners[2],  # Diagonal
                reason="Prevents racking under lateral load"
            ))
        return suggestions
```

## Why These Design Choices

1. **Fail/pass pairing**: Identical parts in different configurations—isolates the constraint
2. **Three constraint types**: Gravity (universal), balance (common), triangulation (structural)
3. **Pedestal placement (height 3)**: Demonstrations need vertical space
4. **Cooler lighting**: Shifts from workshop warmth to analytical clarity

## Key Takeaway

Constraints are not enemies—they are teachers. Each failure mode carries information about what physical reality demands. The bricoleur learns to read this feedback and adjust.
