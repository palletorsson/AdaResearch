# A checkerboard of platforms traces a single path that visits every point in three-dimensional space

Growth added time. The tree unfolded generation by generation, branches forking from branches, the string lengthening under context-sensitive rules that let neighbors shape each other's fate. But the mechanism — axiom, rules, parallel substitution — was presented as a biological tool. Trees, plants, branching morphology. The formalism was implicit. The rewriting engine did exactly what a context-free grammar does, but nobody called it a grammar. Nobody placed it in a hierarchy. Nobody asked: what else can this mechanism produce beyond biology?

This map answers. The same rewriting system that grows trees can fill space. Not "fill" in the loose sense of scattering points. Fill in the mathematical sense: a single continuous path that passes through every point in a region, missing none, revisiting none. A one-dimensional line that saturates two dimensions. A grammar that exhausts three. The production rules fit in a sentence. The space they cover is, in the limit, total.

## Production Rules as Context-Free Grammar

A context-free grammar consists of four components: a set of non-terminal symbols (variables that get rewritten), a set of terminal symbols (characters that persist), a set of production rules (substitution instructions), and a start symbol (the axiom). Every L-System encountered so far is a context-free grammar — or more precisely, a parallel context-free grammar, because all substitutions fire simultaneously.

```gdscript
# L-System as explicit CFG
var non_terminals := ["A", "B"]
var terminals := ["F", "+", "-"]
var axiom := "A"

var productions := {
    "A": "-BF+AFA+FB-",
    "B": "+AF-BFB-FA+"
}
```

The distinction between non-terminals and terminals was always present but never named. In Grammar Lab, `F` was both a drawing command (terminal behavior) and a rewritable symbol (non-terminal behavior). The Koch curve rule `F -> F+F--F+F` uses `F` as both. This conflation works for simple cases but obscures the grammar's structure. Separating `A` and `B` as pure non-terminals — symbols that exist only to be rewritten, never drawn — clarifies what the grammar computes versus what it renders.

```gdscript
func derive(axiom_str: String, rules: Dictionary, generations: int) -> String:
    var current := axiom_str
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

The `derive` function is identical to every rewriter in the previous two maps. Character by character, parallel substitution, terminals passing through unchanged. The function does not know it is implementing a formal grammar. It does not need to. The formalism is a lens applied to the same mechanism — a way of classifying what the rewriter can and cannot express.

Context-free means each production depends only on the single symbol being rewritten, never on its neighbors. The rule `A -> -BF+AFA+FB-` fires for every `A` regardless of surrounding characters. The Growth map introduced context-sensitive rules where neighbors mattered. That distinction — whether productions examine surrounding symbols — is the boundary between two classes in the Chomsky hierarchy. Context-free grammars sit at Type 2. Context-sensitive grammars sit at Type 1. The L-Systems from Grammar Lab and most of Growth are Type 2. The neighbor-dependent rules from Growth's constrained trees are Type 1.

## The Chomsky Hierarchy and L-System Variants

Formal language theory classifies grammars by the restrictions placed on their production rules. Four types, nested like Russian dolls.

Type 3 (regular) — the most restricted. Productions can only append a terminal and optionally a single non-terminal. Sufficient for simple patterns. Cannot express nesting or recursion.

Type 2 (context-free) — a single non-terminal on the left side produces an arbitrary string of terminals and non-terminals. Nesting and recursion are expressible. Brackets in L-Systems (`[` and `]`) are context-free constructs — they nest, and the stack-based turtle tracks that nesting.

Type 1 (context-sensitive) — the left side of a production can include surrounding context. `aAb -> aXYZb` means "replace A with XYZ, but only when A is flanked by `a` on the left and `b` on the right." The context-sensitive tree from the Growth map operates here.

Type 0 (unrestricted) — no constraints on production form. Turing-complete. Any computation expressible.

```gdscript
# Type 2 (context-free): standard L-System
var cfg_rules := {"F": "F[+F]F[-F]F"}

# Type 1 (context-sensitive): neighbor-dependent
var csg_rules := {
    "F": {
        "default": "F[+F][-F]",
        "F<F": "FF",
        "F<F>F": "F[-F]F"
    }
}
```

Standard L-Systems are context-free grammars with parallel application — all symbols rewrite simultaneously rather than sequentially. This parallelism mirrors biological development, where all cells divide in the same time step. Sequential rewriting (standard CFGs in compiler theory) processes one symbol at a time. The distinction matters for the resulting strings: parallel rewriting can produce different derivations than sequential rewriting from the same rules.

The grammar class determines expressive power. Context-free L-Systems produce strict self-similarity — every branch is a scaled copy of the whole tree. Context-sensitive L-Systems produce differentiation — branches vary based on position. Parametric extensions, adding continuous variables to symbols, do not change the grammar class but increase the morphological vocabulary within it. A parametric context-free grammar is still context-free. The parameters ride atop the grammar, not inside it.

## Turtle Interpretation: From String to Geometry

The grammar generates a string. The turtle interprets it as geometry. These are separate phases, and the separation matters.

```gdscript
func turtle_interpret(instruction_string: String, angle_deg: float,
                      step_length: float) -> Array[Dictionary]:
    var segments: Array[Dictionary] = []
    var pos := Vector3.ZERO
    var heading := Vector3.UP
    var stack: Array[Dictionary] = []

    for i in range(instruction_string.length()):
        var ch := instruction_string[i]
        match ch:
            "F":
                var next_pos := pos + heading * step_length
                segments.append({"from": pos, "to": next_pos})
                pos = next_pos
            "+":
                heading = heading.rotated(Vector3.FORWARD, deg_to_rad(angle_deg))
            "-":
                heading = heading.rotated(Vector3.FORWARD, -deg_to_rad(angle_deg))
            "[":
                stack.push_back({"pos": pos, "heading": heading})
            "]":
                var saved: Dictionary = stack.pop_back()
                pos = saved["pos"]
                heading = saved["heading"]

    return segments
```

`F` means "move forward and draw." `+` and `-` mean "turn." `[` means "save position and heading." `]` means "restore." Non-terminals like `A` and `B` are invisible to the turtle — they exist only during derivation and vanish from the final string (or persist as no-ops that the turtle skips). The grammar computes topology. The turtle computes geometry. Different grammars can share a turtle. Different turtles can interpret the same grammar. The two layers are independent.

This independence is what enables space-filling curves. The grammar that produces the Hilbert curve uses the same turtle alphabet — `F`, `+`, `-` — as the grammar that produces a branching tree. The symbols mean the same thing. The production rules differ.

The resulting strings differ. The resulting geometry is unrecognizably different. Trees branch. Curves fold. Same interpreter, different instructions.

## The Hilbert Curve: A Grammar That Fills a Plane

The Hilbert curve is defined by two non-terminals, `A` and `B`, a turn angle of 90 degrees, and two production rules.

```gdscript
var hilbert_axiom := "A"
var hilbert_rules := {
    "A": "-BF+AFA+FB-",
    "B": "+AF-BFB-FA+"
}
var hilbert_angle := 90.0
```

At generation 0, the string is `A` — a single non-terminal. The turtle sees no drawing commands. Nothing renders. At generation 1, `A` becomes `-BF+AFA+FB-`. The turtle encounters one `F` among the turns and non-terminals.

A single line segment. At generation 2, every `A` and `B` in the string expand further. The path bends into a U-shape. At generation 3, the U subdivides. At generation 4, the path weaves through a 16-cell grid, visiting each cell exactly once.

```gdscript
func generate_hilbert(generations: int) -> Array[Dictionary]:
    var instruction_str := derive(hilbert_axiom, hilbert_rules, generations)
    return turtle_interpret(instruction_str, hilbert_angle, 1.0)
```

The generation count controls resolution. Each additional generation quadruples the number of cells visited. Generation n fills a 2^n x 2^n grid. Generation 4 fills 16 x 16 = 256 cells. Generation 6 fills 64 x 64 = 4096 cells. In the limit — infinite generations — the curve passes through every point in the unit square. A one-dimensional path that fills a two-dimensional region. The curve's Hausdorff dimension approaches 2.

The `space_filling_curve_gallery` artifact renders this progression on the floor. Three curves side by side, each at the same generation depth, each tracing a different grammar through the same grid.

## Peano and Moore: Different Grammars, Same Saturation

The Hilbert curve is not the only space-filling curve. Peano's curve predates it by a year (1890 vs. 1891). Moore's curve is a closed variant of Hilbert's — it returns to its starting point.

```gdscript
var peano_axiom := "X"
var peano_rules := {
    "X": "XFYFX+F+YFXFY-F-XFYFX",
    "Y": "YFXFY-F-XFYFX+F+YFXFY"
}
var peano_angle := 90.0

var moore_axiom := "LFL+F+LFL"
var moore_rules := {
    "L": "-RF+LFL+FR-",
    "R": "+LF-RFR-FL+"
}
var moore_angle := 90.0
```

Three grammars. Three sets of production rules. Three different paths through the same region. The Hilbert curve traces a U-shaped recursion. The Peano curve traces an S-shaped recursion at higher density — each generation nines the cell count instead of quadrupling it. The Moore curve closes into a loop, its endpoints meeting where they began.

```gdscript
func build_curve_gallery(generations: int) -> Dictionary:
    var hilbert_segs := generate_curve(hilbert_axiom, hilbert_rules, hilbert_angle, generations)
    var peano_segs := generate_curve(peano_axiom, peano_rules, peano_angle, generations)
    var moore_segs := generate_curve(moore_axiom, moore_rules, moore_angle, generations)
    return {
        "hilbert": hilbert_segs,
        "peano": peano_segs,
        "moore": moore_segs
    }
```

The gallery artifact positions each curve in its own floor panel. Same generation depth, same cell size, same rendering style. The visual comparison is immediate: Hilbert serpentines, Peano zigzags tighter, Moore forms a closed loop. Different topologies, different aesthetics, identical coverage.

The grammar determines the path's shape — how it folds, where it turns, which cells it visits in what order. The grammar does not determine whether the path fills the plane. All three do. Coverage is a property of the curve family, not the individual grammar. Any space-filling curve grammar, iterated sufficiently, saturates its region.

## Hilbert3D: The Curve Enters Volume

The checkerboard layout of this map — platforms at alternating heights 1 and 3 — mirrors the Hilbert curve's recursive subdivision of a plane. The learner's walking path approximates a Hilbert traversal. But the `Hilbert3D` artifact overhead extends the concept into three dimensions.

A 3D Hilbert curve fills a cube the way its 2D counterpart fills a square. The production rules grow more complex — the 2D curve requires two non-terminals, the 3D curve requires twelve — but the mechanism is unchanged. Parallel substitution. Turtle interpretation. Recursive subdivision.

```gdscript
var hilbert3d_rules := {
    "A": "B-F+CFC+F-D&F^D-F+&&CFC+F+B//",
    "B": "A&F^CFB^F^D^^-F-D^|F^B|FC^F^A//",
    "C": "|D^|F^B-F+C^F^A&&FA&F^C+F+B^F^D//",
    "D": "|CFB-F+B|FA&F^A&&FB-F+B|FC//"
}
var hilbert3d_axiom := "A"
```

The 3D turtle needs additional commands beyond `+` and `-`. The `&` and `^` symbols pitch the heading down and up. The `|` and `//` symbols roll. Six degrees of rotational freedom — yaw, pitch, roll — each with its own symbol. The turtle walks in three dimensions, and the grammar's production rules exploit all three axes.

```gdscript
func turtle_interpret_3d(instruction_string: String, angle_deg: float,
                         step_length: float) -> Array[Dictionary]:
    var segments: Array[Dictionary] = []
    var pos := Vector3.ZERO
    var heading := Vector3.UP
    var left := Vector3.LEFT
    var up := Vector3.FORWARD

    for i in range(instruction_string.length()):
        var ch := instruction_string[i]
        match ch:
            "F":
                var next_pos := pos + heading * step_length
                segments.append({"from": pos, "to": next_pos})
                pos = next_pos
            "+":
                var rot := heading.rotated(up, deg_to_rad(angle_deg))
                left = left.rotated(up, deg_to_rad(angle_deg))
                heading = rot
            "-":
                var rot := heading.rotated(up, -deg_to_rad(angle_deg))
                left = left.rotated(up, -deg_to_rad(angle_deg))
                heading = rot
            "&":
                var rot := heading.rotated(left, deg_to_rad(angle_deg))
                up = up.rotated(left, deg_to_rad(angle_deg))
                heading = rot
            "^":
                var rot := heading.rotated(left, -deg_to_rad(angle_deg))
                up = up.rotated(left, -deg_to_rad(angle_deg))
                heading = rot
            "/":
                left = left.rotated(heading, deg_to_rad(angle_deg))
                up = up.rotated(heading, deg_to_rad(angle_deg))

    return segments
```

The 3D turtle maintains a full orientation frame — heading, left, and up — rather than a single heading vector. Each rotation command modifies two of the three vectors, preserving orthogonality. This is the Frenet frame of differential geometry applied to discrete turtle steps. The heading says "which way to walk." The left and up vectors say "which way to turn when told to turn." All three must stay perpendicular, or the geometry warps.

The `Hilbert3D` artifact floats at position (3,3) in the map grid, rendering generation 2 or 3 of the volumetric curve. At generation 2, the curve visits 64 cells in a 4x4x4 cube. At generation 3, it visits 512 cells in an 8x8x8 cube. The line snakes through the volume, visiting every sub-cube exactly once, never crossing itself. A one-dimensional thread woven through three-dimensional space with zero waste — no cell unvisited, no cell revisited.

## Dimension as Consequence, Not Container

The space-filling curve dissolves intuition about dimension. A line is one-dimensional. A square is two-dimensional. These categories feel like physical law. But the Hilbert curve is a continuous, one-dimensional object that completely fills a two-dimensional region. Its topological dimension is 1. Its Hausdorff dimension is 2. The curve exists between categories — or rather, it reveals that categories are human labels applied to a continuum.

The grammar does not "know" it is producing a space-filling curve. The production rules `A -> -BF+AFA+FB-` and `B -> +AF-BFB-FA+` are local substitutions. No rule references global coverage. No rule checks whether the path has visited a cell. The global property — total saturation of the plane — emerges from local rules iterated to depth.

This is the same principle the Growth map demonstrated with trees: global form from local grammar. But trees merely suggest complexity. Space-filling curves prove it. The emergence is mathematically exact. In the limit, coverage is not approximate. It is complete.

This matters for computation. Space-filling curves provide a way to linearize multi-dimensional data — to impose a one-dimensional ordering on a two- or three-dimensional grid such that spatially nearby cells tend to be nearby in the linear sequence. Database indexing, texture mapping, cache-coherent memory access — all exploit this property. The grammar is not an abstraction. It is a data structure.

## String Growth and Computational Cost

Each generation of derivation multiplies the string length. For the Hilbert curve, generation n produces a string of length proportional to 4^n. Generation 6 yields roughly 4,096 `F` symbols and many more turn symbols. Generation 10 yields over a million. The exponential growth that made tree rendering require frame budgets applies here with equal force.

```gdscript
func estimate_string_length(rules: Dictionary, axiom_str: String,
                            generations: int) -> int:
    var lengths := {}
    for key in rules:
        lengths[key] = rules[key].length()

    var current_length := axiom_str.length()
    for gen in range(generations):
        var next_length := 0
        # Each non-terminal expands to its rule length
        # Each terminal stays at length 1
        # Approximation: count non-terminals, multiply by expansion factor
        next_length = current_length * lengths.values().max()
        current_length = next_length
    return current_length
```

Rendering cost scales with segment count, not string length — most characters in the string are turns or non-terminals, not `F` commands. But segment count still grows exponentially. The `space_filling_curve_gallery` artifact caps generation depth at a visually informative level — deep enough that the space-filling property is apparent, shallow enough that the renderer does not choke. The right generation depth varies by curve family. Hilbert at generation 5 fills a 32x32 grid legibly. Peano at generation 3 fills a 27x27 grid with comparable density, because each Peano generation triples rather than doubles the grid dimension.

## From Growth to Grammar to Architecture

Growth demonstrated that environment shapes form. This map demonstrates that form — specifically, the form of production rules — determines a grammar's expressive class and its geometric consequences. A context-free grammar with the right rules fills space. A context-sensitive grammar with the right rules differentiates branches. The rules are local. The consequences are global. The grammar class constrains which global consequences are reachable.

The checkerboard layout encodes this lesson spatially. Platforms at height 1 and height 3 alternate in a pattern that mirrors the Hilbert curve's recursive subdivision. Walking the map means traversing a space-filling path. The body traces what the grammar computes. Overhead, the `Hilbert3D` artifact extends the same principle into the third dimension the learner inhabits. Below, the `space_filling_curve_gallery` compares three grammars that achieve the same saturation by different paths.

The next map — LSystems_Architecture — applies grammar to built environments. If a grammar can grow a tree and fill a volume, it can also generate a corridor, a room, a building. The production rules change. The turtle interpretation changes. The mechanism does not. Architecture is grammar with walls.

## Possible Artifacts

**grammar_type_comparator** — Places a single branching tree under three grammar treatments side by side: context-free, context-sensitive, and stochastic. The same axiom and base rule set, with context and randomness toggled independently. The context-free tree is perfectly self-similar. The context-sensitive tree differentiates by position. The stochastic tree varies on each generation. The learner sees how grammar class reshapes morphology from one plant body, confirming that expressive power is not an abstraction but a visible structural property.

**derivation_stepper** — An interactive panel that shows the Hilbert curve's string at each generation alongside the corresponding geometric path. The learner steps forward and backward through generations, watching the string expand and the curve fold in lockstep. Highlighted substrings correspond to highlighted curve segments — the `A` non-terminal maps to a specific recursive U-shape, the `B` to its mirror. Makes the grammar-to-geometry correspondence explicit at every derivation depth rather than only at the final rendering.

**curve_dimension_meter** — A visualization that computes and displays the approximate fractal dimension of each space-filling curve at each generation depth. As generations increase, the dimension readout climbs toward 2.0 (for 2D curves) or 3.0 (for the Hilbert3D). The meter makes the dimension-dissolving property quantitative — the learner watches a one-dimensional object's measured dimension increase toward the dimension of the region it fills.

**parallel_vs_sequential_rewriter** — Applies the same production rules to the same axiom using parallel substitution (L-System style, all symbols rewritten simultaneously) and sequential substitution (compiler-theory style, leftmost non-terminal rewritten first). The two resulting strings diverge after generation 1. Side-by-side rendering shows how the same grammar, under different application strategies, produces different geometry — demonstrating that parallelism is not incidental to L-Systems but constitutive of their behavior.