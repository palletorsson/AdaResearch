extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Constraint Catalog[/b][/font_size][/center]
[center][i]What Pushes Back[/i][/center]

In bricolage, structure emerges when constraints are satisfied.

Constraints are not limitations—they are **discovery mechanisms**. When you feel pushback, you are learning what the assembly wants to become.

[hr]

[b]Physical Constraints[/b]

These are non-negotiable laws of the physical world.

[color=yellow][b]Gravity[/b][/color]
[code]
# Everything falls unless supported
constraint gravity:
    condition: object.position.y > ground_level
    unless: object.has_support() or object.is_anchored()
    consequence: object falls

# Test: Does your structure reach the ground?
func test_gravity(structure):
    for part in structure.parts:
        if not has_load_path_to_ground(part):
            return "FAIL: " + part.name + " floats"
    return "PASS: All parts supported"
[/code]
**Gravity teaches**: load paths, support, foundation.

[color=yellow][b]Collision[/b][/color]
[code]
# Two objects cannot occupy the same space
constraint collision:
    condition: object_a.volume.intersects(object_b.volume)
    consequence: invalid configuration

# Test: Do any parts overlap?
func test_collision(structure):
    for i in range(structure.parts.size()):
        for j in range(i + 1, structure.parts.size()):
            if parts_intersect(structure.parts[i], structure.parts[j]):
                return "FAIL: Collision between parts"
    return "PASS: No overlaps"
[/code]
**Collision teaches**: spatial planning, clearance, fit.

[color=yellow][b]Material Limits[/b][/color]
[code]
# Every material has maximum stress before failure
constraint material_strength:
    condition: stress > material.yield_strength
    consequence: deformation or fracture

# Simplified test
func test_load(part, applied_force):
    var stress = applied_force / part.cross_section_area
    if stress > part.material.strength:
        return "FAIL: Part exceeds load capacity"
    return "PASS: Within material limits"
[/code]
**Material limits teach**: load distribution, sizing, reinforcement.

[hr]

[b]Topological Constraints[/b]

These concern how parts connect and relate.

[color=yellow][b]Connectivity[/b][/color]
[code]
# Parts must touch to bond
constraint connectivity:
    condition: wants_bond(part_a, part_b)
    unless: parts_touch(part_a, part_b)
    consequence: bond cannot form

# Test: Is the structure connected?
func test_connectivity(structure):
    var visited = {}
    var to_visit = [structure.parts[0]]

    while not to_visit.is_empty():
        var current = to_visit.pop_front()
        visited[current] = true
        for neighbor in current.bonded_parts:
            if neighbor not in visited:
                to_visit.append(neighbor)

    if visited.size() < structure.parts.size():
        return "FAIL: Structure has disconnected parts"
    return "PASS: All parts connected"
[/code]
**Connectivity teaches**: bonding, joints, assembly sequence.

[color=yellow][b]Closure[/b][/color]
[code]
# Enclosure requires complete boundary
constraint closure:
    condition: structure.intends_enclosure
    unless: boundary_is_complete(structure)
    consequence: enclosure fails (leaks, gaps)

# Test: Does the boundary close?
func test_closure(structure):
    for edge in structure.boundary_edges:
        if edge.faces.size() != 2:
            return "FAIL: Open edge at " + str(edge.position)
    return "PASS: Boundary complete"
[/code]
**Closure teaches**: manifold geometry, sealing, weather-tightness.

[color=yellow][b]Continuity[/b][/color]
[code]
# Paths must not break
constraint continuity:
    condition: path.requires_traversability
    unless: path_is_continuous(path)
    consequence: path fails, blockage

# Test: Can you traverse from A to B?
func test_path(structure, start, end):
    var path = find_path(structure, start, end)
    if path.is_empty():
        return "FAIL: No continuous path"
    return "PASS: Path exists"
[/code]
**Continuity teaches**: circulation, flow, accessibility.

[hr]

[b]Structural Constraints[/b]

These concern stability and load-bearing.

[color=yellow][b]Balance[/b][/color]
[code]
# Center of mass must be over base of support
constraint balance:
    condition: structure.is_freestanding
    unless: center_of_mass_over_base(structure)
    consequence: structure tips over

# Calculate center of mass
func get_center_of_mass(structure) -> Vector3:
    var total_mass = 0.0
    var weighted_pos = Vector3.ZERO

    for part in structure.parts:
        weighted_pos += part.position * part.mass
        total_mass += part.mass

    return weighted_pos / total_mass

# Test balance
func test_balance(structure):
    var com = get_center_of_mass(structure)
    var base = get_support_polygon(structure)

    if not point_in_polygon_2d(Vector2(com.x, com.z), base):
        return "FAIL: Will tip (COM outside base)"
    return "PASS: Balanced"
[/code]
**Balance teaches**: weight distribution, counterweight, base sizing.

[color=yellow][b]Triangulation[/b][/color]
[code]
# Triangles resist deformation; quads do not
constraint triangulation:
    condition: structure.requires_rigidity
    unless: all_faces_triangulated(structure)
    consequence: structure can rack/deform

# A square can become a rhombus
# A triangle cannot deform without changing edge lengths

func test_rigidity(frame):
    for face in frame.faces:
        if face.vertex_count > 3:
            if not face.has_diagonal_brace:
                return "WARN: Quad face can rack"
    return "PASS: Structure is rigid"
[/code]
**Triangulation teaches**: why trusses work, bracing, rigidity.

[color=yellow][b]Redundancy[/b][/color]
[code]
# Multiple load paths increase stability
constraint redundancy:
    condition: structure.critical_to_safety
    unless: has_multiple_load_paths(structure)
    consequence: single point of failure

# Three-legged stool: one leg fails → collapse
# Four-legged table: one leg fails → might survive

func test_redundancy(structure):
    for part in structure.load_bearing_parts:
        var remaining = structure.duplicate()
        remaining.remove(part)
        if not remaining.is_stable():
            return "WARN: Single point of failure at " + part.name
    return "PASS: Redundant load paths"
[/code]
**Redundancy teaches**: safety margins, backup systems, robustness.

[hr]

[b]Geometric Constraints[/b]

These concern form and proportion.

[color=yellow][b]Symmetry[/b][/color]
[code]
# Optional but often discovered
constraint symmetry:
    condition: structure.exhibits_symmetry_intent
    unless: symmetry_is_maintained(structure)
    consequence: visual imbalance (not failure, but dissonance)

# Symmetry types
enum SymmetryType {
    BILATERAL,    # Mirror across plane
    RADIAL,       # Rotation around axis
    TRANSLATIONAL # Repeat along vector
}

func test_symmetry(structure, type: SymmetryType):
    match type:
        BILATERAL:
            return check_mirror_symmetry(structure)
        RADIAL:
            return check_rotational_symmetry(structure)
        TRANSLATIONAL:
            return check_repetition_consistency(structure)
[/code]
**Symmetry teaches**: visual balance, pattern, rhythm.

[color=yellow][b]Proportion[/b][/color]
[code]
# Parts must relate in scale
constraint proportion:
    condition: parts_should_relate_visually
    unless: proportions_are_harmonious(parts)
    consequence: visual awkwardness

# Chair seat too small for human → fails ergonomically
# Legs too thin for load → fails structurally
# Head too large for body → fails aesthetically

func test_human_scale(furniture):
    var seat_height = furniture.seat.position.y
    if seat_height < 0.4 or seat_height > 0.55:
        return "WARN: Seat height outside ergonomic range"
    return "PASS: Human-scaled"
[/code]
**Proportion teaches**: scale, ergonomics, visual harmony.

[hr]

[b]Discovered Constraints[/b]

These emerge during assembly—you learn them by encountering failure.

[color=yellow][b]Wobble[/b][/color]
[code]
# Insufficient support causes instability
discovered constraint wobble:
    symptom: structure rocks when pushed
    cause: support points coplanar or insufficient
    solution: add support, triangulate base, widen stance

# Three legs define a plane → stable but tippy
# Four legs may wobble if floor uneven
# Triangulated base → rigid
[/code]

[color=yellow][b]Sag[/b][/color]
[code]
# Unsupported spans deflect under load
discovered constraint sag:
    symptom: horizontal member bends downward
    cause: span too long for member section
    solution: add support, increase section, add tension

# Shelf sags in middle → add center support
# Beam deflects → use deeper section or add cable
[/code]

[color=yellow][b]Racking[/b][/color]
[code]
# Rectangular frames deform parallelogram
discovered constraint racking:
    symptom: frame leans when pushed sideways
    cause: joints not rigid, no triangulation
    solution: add diagonal brace, rigidify joints

# Bookshelf without back → racks
# Add diagonal or back panel → rigid
[/code]

[color=yellow][b]Resonance[/b][/color]
[code]
# Structure vibrates at natural frequency
discovered constraint resonance:
    symptom: oscillation amplifies with rhythmic input
    cause: input frequency matches natural frequency
    solution: change stiffness, add damping, change mass

# Footbridge bounces when walked on
# Floor vibrates when machine runs
[/code]

[hr]

[b]Constraint Satisfaction as Design[/b]

The bricoleur does not design, then check constraints.
The bricoleur assembles until constraints stop complaining.

[color=yellow][b]Code: Assembly Loop[/b][/color]
[code]
func bricolage_assembly(inventory, intent):
    var structure = Structure.new()

    while not intent_satisfied(structure, intent):
        # Try adding or repositioning parts
        var action = choose_action(inventory, structure)
        structure.apply(action)

        # Check what pushes back
        var feedback = test_all_constraints(structure)

        if feedback.has_failures():
            # Learn from constraint
            var lesson = interpret_failure(feedback)
            inventory.update_affordances(lesson)
            structure.undo(action)
        else:
            # Constraint satisfied, continue
            pass

    return structure

func test_all_constraints(structure) -> Feedback:
    var feedback = Feedback.new()

    feedback.add(test_gravity(structure))
    feedback.add(test_collision(structure))
    feedback.add(test_connectivity(structure))
    feedback.add(test_balance(structure))
    feedback.add(test_rigidity(structure))

    return feedback
[/code]

Structure emerges when all constraints return PASS.

[i]Constraints are not obstacles—they are teachers.[/i]

[hr]

[color=cyan][b]Summary:[/b][/color]
Constraints tell you what pushes back. Physical: gravity, collision, material limits. Topological: connectivity, closure, continuity. Structural: balance, triangulation, redundancy. Geometric: symmetry, proportion. Discovered: wobble, sag, racking, resonance. The bricoleur learns by encountering constraint failure. Structure emerges when constraints are satisfied. Constraints are not obstacles but teachers.

'''
