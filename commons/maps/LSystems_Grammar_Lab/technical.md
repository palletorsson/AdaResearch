# A single character rewrites itself into a forest — axiom, rules, string, turtle, tree

Fractals generated complexity through geometric recursion — subdivide, repeat. The cube split into eight cubes. The chair became chairs made of chairs. The rule was always spatial: take a shape, produce smaller shapes, place them. L-Systems generate complexity through symbolic recursion — rewrite, interpret. The rule operates on characters, not geometry. A string becomes a longer string becomes an even longer string. Only at the end does anything draw.

This separation — generation from interpretation — is the core insight. The grammar does not know about angles or lines. The renderer does not know about rules. Between them sits a string that grows exponentially with each generation.

## Axiom and Production Rules

An L-System starts with an axiom — a string of characters — and a set of production rules. Each rule maps a single character to a replacement string. One generation rewrites every character simultaneously.

```gdscript
var axiom := "F"
var rules := { "F": "F[+F]F[-F]F" }
```

The axiom is `"F"`. The single rule says: wherever you see `F`, replace it with `F[+F]F[-F]F`. One character becomes nine. Apply the rule again and each of those F's expands. The string grows by substitution — every symbol that matches a rule is replaced in parallel.

Characters without production rules survive unchanged — constants. The brackets `[` and `]`, the `+` and `-` pass through rewriting untouched. Only `F` transforms. The constants are scaffolding that the grammar preserves while the variables multiply.

```gdscript
# Generation 0: F
# Generation 1: F[+F]F[-F]F
# Generation 2: F[+F]F[-F]F[+F[+F]F[-F]F]F[+F]F[-F]F[-F[+F]F[-F]F]F[+F]F[-F]F
```

Generation 0 is one character. Generation 1 is nine. Generation 2 is forty-one. The string roughly quintuples each generation. By generation 5, thousands of characters. By generation 7, tens of thousands. The rule is five characters mapping to nine. The output is unbounded.

## The Rewriting Algorithm

String rewriting is a single loop. Walk through the current string character by character. If the character has a production rule, append the replacement. If not, append the character itself. The result is the next generation.

```gdscript
func rewrite(input: String, rules: Dictionary, generations: int) -> String:
    var current := input

    for gen in range(generations):
        var next := ""
        for i in range(current.length()):
            var ch := current[i]
            if rules.has(ch):
                next += rules[ch]
            else:
                next += ch
        current = next

    return current
```

The outer loop counts generations. The inner loop processes every character. The key detail — every character is rewritten simultaneously. This is not sequential replacement where early substitutions affect later ones. The entire string is read, then the entire next string is built. Aristid Lindenmayer designed this parallel rewriting to model simultaneous cell division in biological organisms — every cell divides at the same time.

The `fractal_lsystem_string` artifact implements this function and displays the raw string at each generation. The learner watches `"F"` expand into a wall of characters. The string is the program. It has not been executed yet.

## Turtle Graphics: Interpreting the String

The string means nothing until a turtle reads it. Turtle graphics is the interpreter — a cursor with a position and a heading. It walks the string one character at a time, executing movement commands.

The alphabet:

- `F` — move forward by `step_length`, drawing a line
- `+` — rotate left by `angle` degrees
- `-` — rotate right by `angle` degrees
- `[` — push current state (position and heading) onto a stack
- `]` — pop the most recent state from the stack

That is the entire language. Five symbols. The push and pop create branching — the turtle saves its place, explores a side path, then returns to where it was. Without the stack, the turtle can only draw continuous curves. With it, the turtle can draw trees.

Consider the string `F[+F][-F]`. The turtle draws forward. Hits `[` — saves position and heading. Turns left, draws forward. Hits `]` — snaps back to the saved state. Turns right, draws forward. Hits `]` — snaps back again. The result is a Y-shape: one trunk, two branches. The brackets mean "explore, then return." Every tree, every fern in an L-System is built from nested instances of this push-pop pattern.

```gdscript
func interpret(lstring: String, angle_deg: float, step_length: float) -> Array[Dictionary]:
    var segments: Array[Dictionary] = []
    var pos := Vector3.ZERO
    var heading := Vector3.UP
    var angle_rad := deg_to_rad(angle_deg)
    var stack: Array[Dictionary] = []

    for i in range(lstring.length()):
        var ch := lstring[i]
        match ch:
            "F":
                var new_pos := pos + heading * step_length
                segments.append({"from": pos, "to": new_pos})
                pos = new_pos
            "+":
                heading = heading.rotated(Vector3.FORWARD, angle_rad)
            "-":
                heading = heading.rotated(Vector3.FORWARD, -angle_rad)
            "[":
                stack.append({"pos": pos, "heading": heading})
            "]":
                var state: Dictionary = stack.pop_back()
                pos = state["pos"]
                heading = state["heading"]

    return segments
```

The function returns an array of line segments — `from` and `to` positions. The rendering layer consumes this array without any knowledge of L-Systems. The grammar produces the string. The turtle produces the geometry. The renderer draws it. Three stages, fully decoupled.

The `lsystem_tree` artifact implements this interpreter and draws the result in 3D space. The angle parameter determines the spread. The step length determines the scale. The same string rendered with different angles produces wildly different shapes — the interpretation is as important as the grammar.

## Koch, Sierpinski, Dragon: Classic Presets

Different axioms, rules, and angles produce entirely different fractals. The L-System framework is general — the specific fractal emerges from the specific rule table.

```gdscript
# Koch snowflake
var koch_axiom := "F--F--F"
var koch_rules := { "F": "F+F--F+F" }
var koch_angle := 60.0

# Sierpinski triangle
var sierpinski_axiom := "F-G-G"
var sierpinski_rules := { "F": "F-G+F+G-F", "G": "GG" }
var sierpinski_angle := 120.0

# Dragon curve
var dragon_axiom := "FX"
var dragon_rules := { "X": "X+YF+", "Y": "-FX-Y" }
var dragon_angle := 90.0

# Plant
var plant_axiom := "X"
var plant_rules := { "X": "F+[[X]-X]-F[-FX]+X", "F": "FF" }
var plant_angle := 25.0
```

The Koch snowflake starts with a triangle (`F--F--F` at 60 degrees draws three sides) and replaces each straight segment with a kinked version. After four generations, the boundary is a continuous curve of intricate detail. This is the same Koch curve from the fractals map, generated symbolically instead of geometrically. Same shape, different engine.

The Sierpinski triangle uses two symbols — `F` and `G` — that both draw forward but follow different replacement rules. `G` simply doubles (`GG`), while `F` follows a more complex path. After six generations at 120 degrees, the familiar triangle-of-triangles appears. The fractal dimension of 1.585 has not changed — only the method of construction.

The dragon curve uses `X` and `Y` as control symbols that never draw anything directly. They organize the rewriting. The turtle ignores them — only `F`, `+`, and `-` produce geometry. Non-drawing symbols are the grammar's internal bookkeeping, invisible in the final shape but essential to its structure.

The plant is the payoff. The `X` symbol drives branching through push/pop brackets. Each `X` expands into a structure that pushes state, explores two sub-branches, and returns. The `F` doubles each generation, lengthening the trunk segments. At angle 25 degrees and five generations, the result is an organic branching structure — not a geometric fractal but a convincing plant silhouette. This is what Lindenmayer was after. Not snowflakes. Plants.

All four presets share the same rewriting engine and the same turtle interpreter. The only differences are the axiom, the rules, and the angle. The framework does not know which fractal it is generating. The identity of the shape lives entirely in the rule table — a few characters of configuration that produce thousands of characters of structure.

## The L-System Editor

The `lsystem_editor` artifact exposes the rule table for direct manipulation. The learner types axioms, edits production rules, adjusts the angle and generation count, and watches the result update.

```gdscript
@export var axiom: String = "F"
@export var rules: Dictionary = { "F": "FF+[+F-F-F]-[-F+F+F]" }
@export var angle: float = 22.5
@export var generations: int = 4
@export var step_length: float = 1.0

func generate() -> void:
    var lstring := rewrite(axiom, rules, generations)
    var segments := interpret(lstring, angle, step_length)
    _draw_segments(segments)

func _draw_segments(segments: Array[Dictionary]) -> void:
    var im := ImmediateMesh.new()
    im.surface_begin(Mesh.PRIMITIVE_LINES)
    for seg in segments:
        im.surface_add_vertex(seg["from"])
        im.surface_add_vertex(seg["to"])
    im.surface_end()
    _mesh_instance.mesh = im
```

`ImmediateMesh` draws line segments directly — each segment is two vertices. The `surface_begin` / `surface_add_vertex` / `surface_end` pattern is Godot's immediate-mode geometry API. Not efficient for thousands of segments, but legible. For production, a `PackedVector3Array` fed to an `ArrayMesh` performs better. For learning, `ImmediateMesh` shows the pipeline without abstraction.

The editor's power is in the feedback loop. Change the angle from 22.5 to 30 and the branching opens. Change it to 15 and the plant compresses. Replace `F` with a different rule and the shape transforms entirely. Remove the brackets and branching vanishes — the turtle can no longer save state, so the tree collapses into a single continuous curve. Every parameter is a lever. The editor makes the levers visible.

## Exponential Growth and the Generation Limit

Each generation multiplies string length by approximately the length of the longest production rule. If `F` maps to a 9-character replacement, each `F` produces 9 characters in the next generation. Growth is exponential — O(k^n), where k is the expansion factor and n is the generation count.

```gdscript
func estimate_string_length(axiom_length: int, expansion_factor: int, generations: int) -> int:
    var length := axiom_length
    for gen in range(generations):
        length *= expansion_factor
    return length

# Plant rule: F -> FF (expansion ~2), X -> F+[[X]-X]-F[-FX]+X (expansion ~15 for X)
# Generation 1: ~15 characters
# Generation 5: ~200,000 characters
# Generation 8: ~25,000,000 characters
```

By generation 8, the string alone consumes tens of megabytes. The turtle must then walk every character. Memory and compute both hit walls. The `lsystem_editor` caps generation count — the learner can crank the slider up and feel the framerate drop, a direct encounter with exponential cost.

This is the same exponential wall from the fractals map — 8^n cubes, k^n characters. The shape of the problem is identical. The mitigation differs. Fractal cubes used LOD — reduce depth at distance. L-System strings have no spatial LOD because the string must be fully generated before interpretation begins. The alternatives are generation capping, lazy evaluation, or caching geometry across frames.

A practical safeguard:

```gdscript
const MAX_STRING_LENGTH := 500_000

func rewrite_safe(input: String, rules: Dictionary, generations: int) -> String:
    var current := input
    for gen in range(generations):
        var next := ""
        for i in range(current.length()):
            var ch := current[i]
            if rules.has(ch):
                next += rules[ch]
            else:
                next += ch
        current = next
        if current.length() > MAX_STRING_LENGTH:
            push_warning("String exceeded limit at generation %d" % gen)
            return current
    return current
```

The guard checks string length after each generation. If it exceeds half a million characters, the function bails early. The geometry will be incomplete — the shape cuts off mid-branch — but the application survives.

## Stochastic L-Systems

Deterministic rules produce the same output every time. Stochastic L-Systems introduce probability — a symbol can have multiple replacement rules, each with a weight.

```gdscript
var stochastic_rules := {
    "F": [
        {"rule": "F[+F]F[-F]F", "weight": 0.5},
        {"rule": "F[+F][-F]", "weight": 0.3},
        {"rule": "FF", "weight": 0.2}
    ]
}

func stochastic_rewrite(input: String, rules: Dictionary) -> String:
    var next := ""
    for i in range(input.length()):
        var ch := input[i]
        if rules.has(ch) and rules[ch] is Array:
            next += _weighted_pick(rules[ch])
        elif rules.has(ch):
            next += rules[ch]
        else:
            next += ch
    return next

func _weighted_pick(options: Array) -> String:
    var total := 0.0
    for opt in options:
        total += opt["weight"]
    var roll := randf() * total
    var cumulative := 0.0
    for opt in options:
        cumulative += opt["weight"]
        if roll <= cumulative:
            return opt["rule"]
    return options[-1]["rule"]
```

Each `F` independently selects from its replacement options by weight. The result is a different string every generation — and therefore a different shape. Run the plant preset with stochastic rules and each execution produces a unique plant. The family resemblance persists — the rules define a distribution of shapes, not a single shape.

A deterministic L-System is a description — it produces one object. A stochastic L-System is a species — it produces a population. The axiom and rules define not a shape but a possibility space. The lambda_edge principle surfaces here — the balance between the deterministic skeleton and the stochastic variation at each rewriting step. Too little randomness and every tree is identical. Too much and the structure dissolves into noise. The weight distribution is the dial.

## From String to Shape

The pipeline is clean. Axiom enters the rewriter. The rewriter iterates for n generations, producing a string. The string enters the turtle. The turtle walks character by character, accumulating segments. The segments enter the renderer.

At no point does the grammar reference geometry. At no point does the turtle reference rules. The string is the interface — a symbolic program written by the rewriter and executed by the turtle. Change the rewriter and the same turtle draws different shapes. Change the angle and the same string produces different geometry. The decoupling is total.

This is what distinguishes L-Systems from the recursive fractals of the previous map. The `subdivide_cube` function was both grammar and geometry — the rule and its spatial consequence lived in the same function. L-Systems split them apart. The grammar is pure symbol manipulation. The interpretation is pure spatial execution.

The `dark_sphere` anchors the environment — a visual center of gravity while string visualizations and tree renderings orbit the concept. The sphere's slow pulse is the room's resting state. The L-System artifacts are the room's active exploration.

The next map — LSystems_Growth — adds time. Instead of generating all generations at once, growth applies them incrementally. The plant develops. Branches extend. New branches emerge from existing ones. The static grammar becomes a dynamic process — but the grammar itself does not change. The axiom and rules defined here carry forward unchanged. What changes is the relationship between generation and frame. The grammar is the seed. Growth is the unfolding.

## Possible Artifacts

**string_shape_comparator** — A side-by-side display showing the raw L-System string on the left and the corresponding turtle-graphics rendering on the right. Highlight a substring in the string and the corresponding line segments illuminate in the shape. Highlight a branch in the shape and the corresponding `[...]` block highlights in the string. This is the gap artifact — the map needs it to make the string-to-shape mapping tangible rather than abstract. The learner sees that `[+F]` is a specific branch, that nested brackets are nested branches, that the string is a spatial program.

**generation_slider** — An animated artifact that steps through generations, showing the string expanding and the shape gaining detail in sync. Generation 0: a single line. Generation 1: a kinked line. Generation 2: a kinked kinked line. A counter shows character count and segment count, making exponential growth visible as number and geometry simultaneously.

**rule_mutator** — An interactive artifact where the learner modifies one character in a production rule and immediately sees how the shape changes. Replacing `+` with `-` mirrors the entire plant. Removing a bracket pair collapses a branch. Adding an `F` lengthens every segment. The artifact annotates the shape diff: "changed 847 segments, added 212, removed 193." Connects microscopic rule changes to macroscopic shape consequences.

**stochastic_forest** — A grid of sixteen plants generated from the same stochastic rule set with different random seeds. Same grammar, different rolls. The family resemblance is visible — all are recognizably the same species. No two are identical. A seed slider regenerates the grid. Makes the species-versus-individual distinction physical.
