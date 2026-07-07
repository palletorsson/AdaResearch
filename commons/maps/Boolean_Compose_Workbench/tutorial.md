# Booleans Compose

AND, OR, NOT — stack them. Every complex solid is a sentence built from three words.

An expression is a tree, so represent it as one:

```gdscript
# a node is either a leaf {shape} or an op {op, left, right}
func evaluate(node: Dictionary, p: Vector3) -> float:
    if node.has("shape"):
        return node.shape.call(p)                 # leaf: an SDF
    var a: float = evaluate(node.left, p)
    var b: float = evaluate(node.right, p)
    match node.op:
        "union":     return min(a, b)
        "intersect": return max(a, b)
        "subtract":  return max(a, -b)
    return a
```

The evaluator is the recursion from the fractals chapter pointed at logic instead of geometry: the value of a tree is the op applied to the value of its subtrees. Any depth, same nine lines.

Build a sentence — "a plate with four bolt holes, keep only the round part":

```gdscript
var plate := {"shape": func(p): return sd_box(p, Vector3(2, 0.2, 2))}
var disc  := {"shape": func(p): return sd_cylinder(p, 1.9, 0.3)}
var holes := {"op": "union",
    "left":  {"shape": func(p): return sd_cylinder(p - Vector3( 1.4, 0,  1.4), 0.15, 1.0)},
    "right": {"shape": func(p): return sd_cylinder(p - Vector3(-1.4, 0, -1.4), 0.15, 1.0)}}

var model := {"op": "subtract",
    "left": {"op": "intersect", "left": plate, "right": disc},
    "right": holes}
```

Read it inside-out, like grammar: *(plate AND disc) EXCEPT holes*. Reorder the tree and you machine a different part — `subtract` before `intersect` bores the holes first, and the intersection may then shave their rims. The workbench makes this tangible: the same three volumes, restacked, are a different object.

Two identities to verify at the bench — De Morgan, in solid form:

```gdscript
# NOT (A ∪ B) == (NOT A) ∩ (NOT B)     the outside of a union is where you're outside both
# NOT (A ∩ B) == (NOT A) ∪ (NOT B)
```

Try: build the deepest tree you can and evaluate it at one point in your hand. However baroque the sentence, the answer is still one float — inside or outside, the chapter's only question, asked through arbitrarily many clauses.
