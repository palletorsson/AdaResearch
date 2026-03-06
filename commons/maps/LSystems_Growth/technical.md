# The same axiom planted in a walled corridor and an open clearing grows into two different trees

Grammar Lab built the full pipeline — axiom, rules, string, turtle, tree — in a single instant. One click generated all generations. The string exploded, the turtle walked, the shape appeared. Time was absent. A five-generation plant arrived fully formed, as if printed from a blueprint. But organisms do not arrive fully formed. They develop. Generation 1 precedes generation 2. Branches extend before sub-branches fork. Growth has sequence, and sequence has consequences.

This map adds time. The same rewriting engine runs, but now each generation renders as a distinct phase. The string does not explode all at once. It lengthens step by step. The tree does not appear — it grows. And because growth happens inside space, the space shapes what grows. A corridor constrains. A clearing permits. Two trees diverge not because their grammars differ but because their environments do.

## Animated Generation: Making Time Visible

The `AnimatedTree` artifact steps through L-System generations one at a time. Each step rewrites the string, interprets it, and renders the result before proceeding to the next.

```gdscript
var axiom := "F"
var rules := { "F": "F[+F]F[-F]F" }
var current_string := axiom
var current_generation := 0
var max_generations := 5

func step_generation() -> void:
    if current_generation >= max_generations:
        return
    current_string = rewrite(current_string, rules)
    current_generation += 1
    var segments := interpret(current_string, angle, step_length)
    draw_segments(segments)
```

The `step_generation` function does exactly what the batch rewriter did in Grammar Lab — one pass of character substitution — but stops after a single generation. The learner triggers each step manually. Generation 0 is a single line. Generation 1 forks into five segments. Generation 2 branches further. The tree accumulates structure visibly, the way a sapling adds rings.

The critical difference from batch rewriting: intermediate states are observable. In Grammar Lab, generations 1 through 4 existed only as transient string values inside a loop. The learner saw generation 0 and generation 5 — the seed and the tree — with nothing between. The `AnimatedTree` makes the between visible. Every intermediate form is a valid shape, a tree-in-progress, structurally coherent at every step.

```gdscript
func rewrite(input: String, rules: Dictionary) -> String:
    var next := ""
    for i in range(input.length()):
        var ch := input[i]
        if rules.has(ch):
            next += rules[ch]
        else:
            next += ch
    return next
```

The rewriter has not changed. The same function from Grammar Lab runs here, character by character, parallel substitution. The only difference is invocation — called once per user action instead of looped inside a batch. The algorithm is identical. The temporal framing transforms the experience.

This is a pattern worth naming: the same computation, exposed at different temporal resolutions, teaches different things. Batch execution teaches pipeline structure. Stepped execution teaches developmental sequence. The math is unchanged. The pedagogy is not.

## Context-Free Growth: The Baseline

Before introducing context, establish what context-free means. A context-free production rule depends only on the symbol being rewritten. `F` becomes `F[+F]F[-F]F` regardless of what surrounds it — regardless of whether the `F` sits at the trunk, the tip of a branch, or deep inside a nested sub-branch. Every `F` is treated identically.

```gdscript
# Context-free: every F expands the same way
var cf_rules := { "F": "F[+F]F[-F]F" }

# This F at position 0 and this F at position 6
# produce identical replacements
```

Context-free rewriting is the engine Grammar Lab used exclusively. The Koch snowflake, the Sierpinski triangle, the dragon curve — all context-free. The power of context-free grammars lies in their simplicity: one symbol, one replacement, no conditions. The weakness is uniformity. Every branch grows the same way. Every fork opens at the same angle. The result is self-similar — a mathematical fractal, not a biological tree.

Self-similarity is elegant but lifeless. Real trees are not identical at every scale. Lower branches are thicker and longer. Upper branches are thinner and shorter. Branches in shade grow differently from branches in sun. The trunk is not a scaled-up branch. Differentiation requires information about position, about neighbors, about context.

## Context-Sensitive Rules: Neighbors Matter

A context-sensitive production rule conditions on neighboring symbols. The replacement for a character depends not just on what it is but on what flanks it.

```gdscript
# Context-sensitive rule notation:
# Left_context < Symbol > Right_context -> Replacement
#
# In code, a rule table with context keys:

var cs_rules := {
    "F": {
        "default": "F[+F][-F]",
        "F<F": "FF",           # F preceded by F: just lengthen
        "F<F>F": "F[-F]F",    # F flanked by F on both sides: reduce branching
    }
}
```

The `ContextSensitiveTree` artifact implements this lookup. During rewriting, each character checks its left and right neighbors before selecting a production. An `F` at the start of a branch — preceded by a bracket — expands fully. An `F` in a chain of trunk segments — preceded by another `F` — merely doubles. An `F` flanked on both sides suppresses some branching.

```gdscript
func context_rewrite(input: String, rules: Dictionary) -> String:
    var next := ""
    for i in range(input.length()):
        var ch := input[i]
        if not rules.has(ch):
            next += ch
            continue

        var rule_set: Dictionary = rules[ch]
        var left := input[i - 1] if i > 0 else ""
        var right := input[i + 1] if i < input.length() - 1 else ""

        # Try full context match first, then left-only, then default
        var full_key := "%s<%s>%s" % [left, ch, right]
        var left_key := "%s<%s" % [left, ch]

        if rule_set.has(full_key):
            next += rule_set[full_key]
        elif rule_set.has(left_key):
            next += rule_set[left_key]
        else:
            next += rule_set["default"]

    return next
```

The lookup priority matters: full context (both neighbors) overrides partial context (left neighbor only), which overrides the default. This is a cascade — the most specific matching rule wins. The system degrades gracefully to context-free behavior when no context match is found.

Context-sensitivity transforms the L-System from a uniform rewriter into something resembling cellular communication. Each symbol "knows" its neighbors. A branch tip surrounded by empty string (edge of the sequence) behaves differently from a trunk segment surrounded by other trunk segments. Position in the string creates positional identity. The grammar remains local — each rule examines at most one neighbor on each side — but locality is enough to produce differentiation.

Lindenmayer introduced context-sensitivity precisely to model this. Biological cells do not consult a master blueprint. They respond to chemical signals from adjacent cells. A meristem cell at a shoot tip receives different signals than a cambium cell in the trunk. Same genome, different neighborhood, different behavior. Context-sensitive L-Systems are the formal analog: same rule table, different neighbors, different expansion.

## Parametric Decay: Continuous Variables in Discrete Grammar

Context-sensitivity adds conditional logic. Parametric L-Systems add continuous mathematics. Each symbol carries numerical parameters — length, angle, thickness — that the production rules can read and modify.

```gdscript
# Parametric symbol: F(length, angle, thickness)
# Production: F(l, a, t) -> F(l * 0.85, a, t * 0.9)[+F(l * 0.7, a + 5, t * 0.6)]

var parametric_rules := {
    "F": {
        "production": func(params: Dictionary) -> Array:
            var l: float = params["length"]
            var a: float = params["angle"]
            var t: float = params["thickness"]
            return [
                {"symbol": "F", "params": {"length": l * 0.85, "angle": a, "thickness": t * 0.9}},
                {"symbol": "[", "params": {}},
                {"symbol": "+", "params": {}},
                {"symbol": "F", "params": {"length": l * 0.7, "angle": a + 5.0, "thickness": t * 0.6}},
                {"symbol": "]", "params": {}}
            ]
    }
}
```

The `parametric_lsystem` artifact exposes these decay rates as sliders. Length shrinkage controls how quickly branches shorten with each generation. Angle decay controls how branch angles widen or narrow. Thickness scaling controls taper — branches thinning toward the tips.

```gdscript
@export var length_decay: float = 0.85
@export var angle_offset: float = 5.0
@export var thickness_decay: float = 0.9

func parametric_interpret(symbols: Array, base_step: float) -> Array[Dictionary]:
    var segments: Array[Dictionary] = []
    var pos := Vector3.ZERO
    var heading := Vector3.UP
    var stack: Array[Dictionary] = []

    for sym in symbols:
        match sym["symbol"]:
            "F":
                var step: float = sym["params"].get("length", base_step)
                var thick: float = sym["params"].get("thickness", 1.0)
                var new_pos := pos + heading * step
                segments.append({"from": pos, "to": new_pos, "thickness": thick})
                pos = new_pos
            "+":
                var angle_deg: float = sym["params"].get("angle", 25.0)
                heading = heading.rotated(Vector3.FORWARD, deg_to_rad(angle_deg))
            "-":
                var angle_deg: float = sym["params"].get("angle", 25.0)
                heading = heading.rotated(Vector3.FORWARD, -deg_to_rad(angle_deg))
            "[":
                stack.append({"pos": pos, "heading": heading})
            "]":
                var state: Dictionary = stack.pop_back()
                pos = state["pos"]
                heading = state["heading"]

    return segments
```

The turtle now reads parameters from each symbol instead of using global constants. A trunk `F` with `length = 1.0` and `thickness = 0.9` produces a long, thick segment. A tertiary branch `F` with `length = 0.3` and `thickness = 0.15` produces a short, thin one. Same character, different parameters, different geometry. The discrete grammar and the continuous parameters occupy different layers of the same system — the grammar determines topology (what connects to what), while the parameters determine morphology (how long, how thick, at what angle).

Slide length decay from 0.85 to 0.5 and the tree compresses — branches shorten aggressively, the canopy tightens into a dense crown. Slide it to 0.95 and branches barely shorten — the tree becomes lanky, leggy, stretching outward. The decay rate is a single scalar that reshapes the entire organism. This is leverage: one number, propagated through every generation, compounding at every branch point, producing global form from local arithmetic.

## The Corridor and the Clearing

The map is split asymmetrically. The left half is a walled corridor — the `AnimatedTree` grows here, hemmed by geometry. The right half is an open clearing — the `ContextSensitiveTree` grows here, unconstrained. The layout is the argument made spatial.

Environmental constraint in this map takes the form of collision or boundary checking during growth. When a branch segment would extend beyond the corridor walls, the growth rule modifies:

```gdscript
func constrained_grow(pos: Vector3, heading: Vector3, step: float,
                      bounds: AABB) -> Dictionary:
    var target := pos + heading * step
    var clamped := Vector3(
        clampf(target.x, bounds.position.x, bounds.end.x),
        clampf(target.y, bounds.position.y, bounds.end.y),
        clampf(target.z, bounds.position.z, bounds.end.z)
    )
    var actual_step := (clamped - pos).length()
    var pruned := actual_step < step * 0.5
    return {"position": clamped, "pruned": pruned}
```

The `clampf` calls enforce spatial boundaries. A branch reaching beyond the wall gets clipped. If the clipping removes more than half the intended segment, the branch is flagged as pruned — it stops generating sub-branches in subsequent generations. The grammar does not know about walls. The constraint applies at interpretation time, between string and geometry, modifying the turtle's walk without touching the turtle's instructions.

The result: the corridor tree grows tall and narrow, branches bending inward, sub-branches pruned where they hit walls. The clearing tree grows wide and symmetrical, branches extending freely, the full grammar expressed without interference. Same axiom. Same rules. Same parameters. Different shape. The genome has not changed. The environment has.

This is the lambda_edge principle embodied in morphology. The grammar defines a space of possible forms — all the shapes the axiom and rules can produce. The environment selects from that space by constraining which branches survive. The corridor tree is not a different species from the clearing tree. It is the same species in a different habitat. Identity emerges not from instruction alone but from instruction meeting constraint. The axiom is necessary but not sufficient. The environment completes the form.

## Growth as State Accumulation

Each generation of growth is not a fresh computation — it builds on the previous result. The string at generation n is the input for generation n+1. Geometry accumulates. Branches that exist at generation 3 persist at generation 4; new sub-branches fork from their tips. This accumulation creates a temporal identity for each branch: the trunk appeared at generation 1, the primary branches at generation 2, the secondary branches at generation 3.

```gdscript
var generation_history: Array[String] = []

func record_and_step() -> void:
    generation_history.append(current_string)
    current_string = rewrite(current_string, rules)
    current_generation += 1
```

The `generation_history` array preserves every intermediate string. This enables temporal navigation — the learner scrubs a slider backward and forward through generations, watching branches appear and disappear. Forward scrubbing is growth. Backward scrubbing is developmental regression — undoing the last round of cell division.

The slider reveals that early generations establish gross structure (trunk, primary branches) while later generations add fine detail (tertiary branches, leaf-level forking). This is the biological pattern: morphogenesis proceeds from coarse to fine, each generation refining rather than replacing. The L-System captures this naturally because rewriting is additive — new symbols are inserted, but the scaffold of existing symbols persists. The trunk `F` from generation 1 is still present in generation 5; it has not been replaced, only surrounded by descendants.

## Temporal Rendering and Frame Budgets

Animated growth introduces a frame-timing problem. Each generation produces more segments than the last. Generation 5 might contain thousands of segments. Drawing them all in one frame causes a visible stutter. The `AnimatedTree` addresses this with incremental rendering:

```gdscript
var segments_per_frame := 50
var pending_segments: Array[Dictionary] = []
var draw_index := 0

func _process(delta: float) -> void:
    if draw_index >= pending_segments.size():
        return

    var batch_end := mini(draw_index + segments_per_frame, pending_segments.size())
    for i in range(draw_index, batch_end):
        _add_segment_to_mesh(pending_segments[i])
    draw_index = batch_end
```

The segments queue fills when a new generation is computed. The `_process` loop draws a fixed batch each frame — fifty segments, enough to show visible progress without choking the renderer. The tree appears to grow continuously within each generation, segments extending in real time rather than popping into existence.

The batch size is a design constant, not a mathematical one. Fifty segments at sixty frames per second means three thousand segments per second — a generation of a moderately complex plant renders in under a second. More complex grammars need higher batch sizes or lower frame budgets. The tradeoff between visual smoothness and rendering speed is the same budget problem encountered with fractal subdivision depth: finite resources require finite scope.

## From Grammar Lab to Growth

Grammar Lab demonstrated that a sentence can become a forest — that symbolic rewriting produces spatial complexity. Growth demonstrates that the sentence unfolds in time, and the room it unfolds in shapes the result. The pipeline has not changed: axiom, rules, string, turtle, geometry. What changed is the temporal and spatial framing of that pipeline.

Context-free rules produce uniform self-similarity. Context-sensitive rules produce differentiation. Parametric decay produces organic taper. Environmental constraints produce adaptation. Each addition layers onto the previous without replacing it — the context-free rewriter still runs inside the context-sensitive one, the parametric interpreter still reads the same string, the constrained turtle still walks the same commands. The architecture is accretive, not revolutionary. Each mechanism is a refinement, not a replacement.

The next map — LSystems_Grammars_And_Curves — formalizes what this map demonstrates intuitively. Context-sensitive grammars have a precise place in the Chomsky hierarchy. Parametric extensions correspond to specific formal language classes. The biological intuition developed here — neighbors influencing growth, parameters decaying through generations, environments shaping form — finds its mathematical scaffolding in formal grammar theory. The feeling of context precedes the formalism of context. Growth precedes proof.

## Possible Artifacts

**environmental_dashboard** — A control panel exposing light direction, gravity strength, and spatial boundary dimensions as real-time sliders. The `AnimatedTree` and `ContextSensitiveTree` respond as parameters change mid-growth — adjusting light direction bends branches toward the new source, tightening boundaries increases pruning. The coupling between grammar and environment becomes interactive rather than preset. The learner discovers that small environmental shifts produce large morphological consequences, especially when compounded across multiple generations.

**generation_diff_viewer** — A split display showing the L-System string at generation n and generation n+1, with inserted characters highlighted. The corresponding new branch segments illuminate in the tree rendering. The learner sees exactly which symbols the rewriter added and where they appear in the geometry. Makes the relationship between string growth and spatial growth explicit at each step rather than across the whole history.

**context_rule_editor** — An interactive rule table where the learner writes context-sensitive productions using the `left < symbol > right` notation. The editor highlights which symbols in the current string match each context pattern before rewriting occurs, then shows the result after. Failed matches (where the default fires instead of a context rule) are marked differently. Teaches the precedence cascade — full context, partial context, default — through direct manipulation rather than description.

**corridor_width_slider** — A single slider that adjusts the corridor wall spacing from near-zero (maximum constraint) to the full map width (no constraint). The `AnimatedTree` regrows from generation 0 each time the slider moves. At minimum width, the tree is a single vertical trunk with vestigial stubs. At maximum width, it matches the clearing tree exactly. The continuous transition from constrained to unconstrained reveals that adaptation is not binary — it is a gradient, a spectrum of forms between imprisonment and freedom, shaped by the ratio of growth impulse to spatial budget.
