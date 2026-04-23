# Replace 'branch' with 'corridor' and a tree becomes a dungeon — the turtle interpreter is a pluggable layer

Grammar Lab established the pipeline: axiom, rules, string, turtle, geometry. Growth added time and context. Grammars_And_Curves formalized the grammar and proved it could fill space. Every map so far interpreted the turtle's output as natural form — trees, plants, curves, fractals. The turtle read F as "move forward and draw a branch." The brackets pushed and popped positions on a stack, creating branching topology.

This map changes nothing about the grammar. It changes the interpreter. F stops meaning "draw a branch segment" and starts meaning "place a corridor tile." The brackets stop meaning "save position for a sub-branch" and start meaning "open a doorway into a side room." The production rules are identical to the ones that grew trees. The output is architecture.

## The Dungeon Grammar

The `lsystem_dungeon` artifact generates floor plans from two production rules operating at 90-degree turns.

```gdscript
var axiom := "F"
var rules := {
    "F": "F+RF-FF-FR+F",
    "R": "RFRFRF"
}
var angle := 90.0
var iterations := 3
```

Two symbols rewrite. F is the corridor — the drawing command that moves the turtle forward and places a floor tile. R is the room marker — when the turtle encounters it, it expands a room footprint at the current position instead of drawing a single tile. The `+` and `-` symbols turn 90 degrees, producing the orthogonal grid that architectural floor plans require.

At iteration 1, the axiom F expands to `F+RF-FF-FR+F`. The turtle walks forward, turns left, places a room, turns right, walks two corridor segments, turns right, places another room, turns left, walks forward. The result: an L-shaped corridor with two rooms branching off it.

At iteration 2, every F and R in that string expands again. The L-shape subdivides. Corridors sprout sub-corridors. Rooms bud off intersections. The topology is tree-like — branching without cycles — because the grammar is context-free and the turtle uses a stack.

At iteration 3, the dungeon becomes a labyrinth. Hundreds of corridor tiles, dozens of rooms, a navigable floor plan that no designer placed by hand.

```gdscript
func generate_dungeon(iter: int) -> Array[Dictionary]:
    var instruction_str := derive(axiom, rules, iter)
    return interpret_as_architecture(instruction_str)

func interpret_as_architecture(s: String) -> Array[Dictionary]:
    var tiles: Array[Dictionary] = []
    var pos := Vector2i.ZERO
    var dir := Vector2i.UP
    var stack: Array[Dictionary] = []

    for i in range(s.length()):
        var ch := s[i]
        match ch:
            "F":
                pos += dir
                tiles.append({"pos": pos, "type": "corridor"})
            "R":
                for dx in range(-1, 2):
                    for dz in range(-1, 2):
                        tiles.append({
                            "pos": pos + Vector2i(dx, dz),
                            "type": "room"
                        })
            "+":
                dir = Vector2i(-dir.y, dir.x)  # rotate left
            "-":
                dir = Vector2i(dir.y, -dir.x)  # rotate right
            "[":
                stack.push_back({"pos": pos, "dir": dir})
            "]":
                var saved: Dictionary = stack.pop_back()
                pos = saved["pos"]
                dir = saved["dir"]

    return tiles
```

The critical difference from the tree interpreter: F produces a floor tile on the XZ plane instead of a line segment in 3D space. The direction vector is 2D integer — up, down, left, right — because the floor plan is grid-aligned. Room markers expand a 3x3 footprint centered on the current position. The stack still handles branching — a side corridor can push its state, extend, and pop back to the main hall.

## Architectural Interpretation: Tiles to Geometry

The tile array is not yet geometry. It is a set of grid positions tagged as corridor or room. The rendering pass converts tiles to 3D architecture.

```gdscript
func render_tiles(tiles: Array[Dictionary]) -> void:
    var occupied: Dictionary = {}
    for tile in tiles:
        occupied[tile["pos"]] = tile["type"]

    for tile in tiles:
        var pos: Vector2i = tile["pos"]
        var world_pos := Vector3(pos.x * tile_size, 0.0, pos.y * tile_size)

        # Floor
        _place_floor(world_pos, tile["type"])

        # Walls on unoccupied neighbors
        for neighbor_dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
            var neighbor: Vector2i = pos + neighbor_dir
            if not occupied.has(neighbor):
                _place_wall(world_pos, neighbor_dir)
```

Walls emerge from absence. A corridor tile with no neighbor to its north gets a north wall. The grammar does not specify walls — it specifies walkable space. Walls are the boundary between occupied and void, computed after generation. This is the architectural analog of the corridor constraint in Growth: the grammar defines positive space, and the negative space defines itself.

Room tiles get different floor materials — wider, perhaps lit differently — distinguishing them visually from corridors. The 3x3 room footprint creates recognizable chambers. Corridors are one tile wide. The contrast between narrow passage and open room is the fundamental rhythm of dungeon design, and it falls out of the grammar naturally: F produces one tile, R produces nine.

## The City Generator

The `CityGenerator` artifact applies the same principle at urban scale. Where the dungeon grammar uses orthogonal turns to produce corridors and rooms, the city grammar uses branching rules to produce streets and blocks.

```gdscript
var city_axiom := "X"
var city_rules := {
    "X": "F[-X][+X]FX",
    "F": "FF"
}
var city_angle := 25.7  # degrees — organic street angles
```

The non-terminal X serves as the growth tip — a meristem that branches into two sub-streets (the `[-X][+X]` bracketed expressions) and extends the main road (`FX`). The terminal F doubles with each generation, lengthening existing streets. The angle is not 90 degrees. Urban grids are a special case. Most historical cities grew organically — streets branching at irregular angles, following terrain, waterways, property lines.

```gdscript
func interpret_as_city(s: String, angle_deg: float) -> Dictionary:
    var streets: Array[Dictionary] = []
    var blocks: Array[Dictionary] = []
    var pos := Vector3.ZERO
    var heading := Vector3.FORWARD
    var stack: Array[Dictionary] = []

    for i in range(s.length()):
        var ch := s[i]
        match ch:
            "F":
                var next_pos := pos + heading * block_size
                streets.append({"from": pos, "to": next_pos})
                pos = next_pos
            "+":
                heading = heading.rotated(Vector3.UP, deg_to_rad(angle_deg))
            "-":
                heading = heading.rotated(Vector3.UP, -deg_to_rad(angle_deg))
            "[":
                stack.push_back({"pos": pos, "heading": heading})
            "]":
                var saved: Dictionary = stack.pop_back()
                pos = saved["pos"]
                heading = saved["heading"]

    # Derive blocks from the regions between streets
    blocks = _extract_blocks_from_street_network(streets)
    return {"streets": streets, "blocks": blocks}
```

The interpreter is almost identical to the tree turtle. The difference is semantic: the line segments are streets, not branches. The regions enclosed by streets are city blocks, not empty space. Block extraction — identifying the polygonal regions between street segments — is a computational geometry problem solved after the grammar has finished generating.

Streets are rendered as ground-level surfaces. Blocks are extruded upward to varying heights, creating the building mass. The height can be uniform, random, or grammar-derived (deeper branches produce shorter buildings, mimicking the density gradient from downtown to suburbs). The city is a tree — a branching hierarchy of streets — viewed from the side instead of from below.

## The Pluggable Interpreter Pattern

The key technical insight is that the grammar layer and the interpretation layer are independent. The same derivation function runs for trees, curves, dungeons, and cities. Only the turtle changes.

```gdscript
# Tree interpreter
func interpret_as_tree(s: String, angle: float, step: float) -> Array[Dictionary]:
    # F = draw branch segment, [/] = push/pop, +/- = rotate in 3D

# Dungeon interpreter
func interpret_as_architecture(s: String) -> Array[Dictionary]:
    # F = place corridor tile, R = expand room, +/- = rotate 90° on grid

# City interpreter
func interpret_as_city(s: String, angle: float) -> Dictionary:
    # F = place street segment, [/] = push/pop, +/- = rotate by angle on XZ
```

Three functions. Three interpretations. The same string — the same sequence of characters produced by the same rewriting engine — becomes a tree, a dungeon, or a city depending on which function reads it. The grammar computes topology. The interpreter assigns meaning.

This separation is the L-system's deepest architectural feature. It means that any new domain — music, circuit layout, narrative structure — can be reached by writing a new interpreter. The grammar is domain-agnostic. It produces strings. Strings become whatever the reader decides they are.

## The Map Layout as Urban Grid

The 8x10 map itself is structured as an urban grid. The structure layer uses heights 1 through 4, with street-level paths at height 1-2 and building blocks at height 3-4. The learner walks the street network — a physical traversal of a grammar-generated layout. The `CityGenerator` artifact sits at (2,3), producing a miniature city the learner can observe from the elevated path. The `lsystem_dungeon` at (5,6) generates its top-down floor plan on the XZ plane.

The two artifacts demonstrate the same mechanism at different scales. The dungeon is intimate — corridors you could walk through if they were life-size. The city is panoramic — streets and blocks visible from above. Both are grammar products. Both are interpretations of string rewriting. The learner's path between them is the conceptual journey from room to metropolis, mediated by nothing more than a change in what F means.

## From Architecture to Ecology

Grammar Lab showed that a sentence becomes a tree. Growth showed that the tree depends on its environment. Grammars_And_Curves showed that the grammar's formal class determines its expressive power. This map shows that the grammar's interpretation determines its domain.

The grammar has escaped biology. It was never biological — it was always formal. The tree was one reading. The dungeon is another. The city is a third.

The next map — LSystems_Competition — brings the grammar back to biology, but with a difference. Multiple grammars will share a single world. The single-grammar demonstrations are over. Architecture prepared the ground: if one grammar can build a city, what happens when several grammars build in the same space? The answer is ecology — not designed, but emerged from the intersection of competing rule systems.
