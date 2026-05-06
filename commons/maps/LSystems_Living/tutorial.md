# Living

The L-system becomes the world. Terrain itself follows grammar.

Generate a terrain patch via L-system.

```gdscript
func generate_terrain(lstring: String, grid_size: Vector2i) -> Array:
    var heightmap: Array = []
    var cursor_x: int = 0; var cursor_y: int = 0
    for y in grid_size.y:
        heightmap.append([])
        for x in grid_size.x:
            heightmap[y].append(0.0)
    for c in lstring:
        match c:
            "F":
                if cursor_x >= 0 and cursor_x < grid_size.x and cursor_y >= 0 and cursor_y < grid_size.y:
                    heightmap[cursor_y][cursor_x] += 1.0
                cursor_x += 1
            "+": cursor_y += 1
            "-": cursor_y -= 1
    return heightmap
```

F raises a cell by one; +/- advance the cursor. The string becomes a terrain.

Render the terrain as a mesh.

```gdscript
func heightmap_to_mesh(heightmap: Array) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for y in heightmap.size() - 1:
        for x in heightmap[0].size() - 1:
            add_quad(st, heightmap, x, y)
    st.generate_normals()
    return st.commit()
```

Each grid cell becomes two triangles. The heightmap drives the vertex Y coordinates.

Plant trees following grammar.

```gdscript
func plant_trees_from_grammar(lstring: String) -> void:
    var position := Vector3.ZERO
    for c in lstring:
        match c:
            "T":
                spawn_tree(position)
            "F":
                position += Vector3.FORWARD * 2
            "+":
                position = position.rotated(Vector3.UP, PI / 8)
```

T spawns a tree; F moves forward; + rotates. The tree-placement pattern follows the L-system's rhythm.

Use the sculpted artifact.

```gdscript
class_name GeneticTreeSculptor extends Node3D

@export var depth: int = 5
@export var branch_forks: int = 2
@export var branch_angle: float = 25.0
@export var length_taper: float = 0.75

func regenerate() -> void:
    var system := LSystem.new()
    system.axiom = "F"
    system.rules = {"F": generate_rule_from_params()}
    system.angle_deg = branch_angle
    interpret_and_display(system.expand(depth))
```

Exposed parameters drive a parameterised rule. The learner adjusts sliders; the tree regenerates.

Generate the rule.

```gdscript
func generate_rule_from_params() -> String:
    var rule: String = "F["
    for _i in branch_forks:
        rule += "+F]["
    for _i in branch_forks:
        rule += "-F]"
    rule += "F"
    return rule
```

More forks means more branching; higher angle means wider spread. The rule's structure reflects the learner's choices.

Plant into the ecosystem.

```gdscript
func plant_authored_tree() -> void:
    var tree := spawn_tree_from_rule(current_rule)
    tree.global_position = spawn_point.global_position
    tree.add_to_group("ecosystem_trees")
    light_field.register_tree(tree)
```

The planted tree joins the ecosystem. It competes for light with existing plants.

You can now generate terrain from an L-system, render it as a mesh, plant trees following grammar, configure a parametric tree sculptor, and plant into the live ecosystem. Chamber_LSystems closes the sequence with grammars in contact.

Test an empty string.

```gdscript
func is_terminal(lstring: String, rules: Dictionary) -> bool:
    for c in lstring:
        if c in rules: return false
    return true
```

Fully expanded when no symbol matches a rule. Useful for detecting when further generations won't change anything.
