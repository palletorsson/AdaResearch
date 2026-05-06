# LSystems Architecture

L-systems build buildings. Rules become floor plans.

Encode a skyscraper grammar.

```gdscript
var skyscraper := LSystem.new()
skyscraper.axiom = "B"
skyscraper.rules = {
    "B": "F[B]F[B]B",  # base branches into tiers
    "F": "F",
}
skyscraper.angle_deg = 0.0  # vertical only
```

Base B expands into stacked tiers. Each tier branches vertically; the F represents a floor.

Interpret in 3D.

```gdscript
func interpret_building(lstring: String, floor_height: float) -> Node3D:
    var building := Node3D.new()
    var current_y: float = 0.0
    for c in lstring:
        match c:
            "F":
                spawn_floor(building, current_y, floor_height)
                current_y += floor_height
            "[", "]":
                pass  # branches handled separately
    return building
```

F commands stack floors vertically. The building's height grows with the string length.

Spawn a floor slab.

```gdscript
func spawn_floor(parent: Node3D, y: float, height: float) -> void:
    var mesh := MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    mesh.scale = Vector3(2, height, 2)
    mesh.position = Vector3(0, y + height / 2, 0)
    parent.add_child(mesh)
```

One slab per floor. Scale matches the floor's footprint.

Encode a temple grammar.

```gdscript
var temple := LSystem.new()
temple.axiom = "T"
temple.rules = {
    "T": "CR[+C][-C]P",  # temple: columns, roof, steps
    "C": "F",            # column as single tall prism
    "R": "F",            # roof as single block
    "P": "F",            # pediment
}
```

Different grammar, different structure. The architectural vocabulary expands with the rule set.

Vary the grammar.

```gdscript
func generate_variant(base_system: LSystem, mutation_rate: float = 0.1) -> LSystem:
    var variant := base_system.duplicate(true)
    for key in variant.rules:
        if randf() < mutation_rate:
            variant.rules[key] = mutate_rule(variant.rules[key])
    return variant
```

Each variant is a small change to the grammar. Many variants together read as a town of related buildings.

Mutate a rule.

```gdscript
func mutate_rule(rule: String) -> String:
    var i: int = randi() % rule.length()
    var mutation_type: int = randi() % 3
    match mutation_type:
        0: return rule.insert(i, "F")  # add a floor
        1: if rule.length() > 1: return rule.erase(i, 1)  # remove
        2: return rule.insert(i, "[F]")  # add a branch
    return rule
```

Three mutation types: insertion, deletion, branch. Each produces a small variation from the parent rule.

Compose a skyline.

```gdscript
func build_skyline(count: int, systems: Array) -> void:
    for i in count:
        var system: LSystem = systems[i % systems.size()]
        var string := system.expand(3 + randi() % 3)
        var building := interpret_building(string, 0.5)
        building.position = Vector3(i * 3, 0, 0)
        add_child(building)
```

A row of buildings, each from a (possibly varied) grammar. The skyline becomes a set of grammars rendered together.

You can now encode architectural grammars, interpret them as 3D structures, vary them via mutation, and compose a skyline from varied buildings. LSystems_Competition extends L-systems into populations.
