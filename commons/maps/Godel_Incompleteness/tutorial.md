# Gödel Incompleteness

**Revision status — legacy code sketch.** The fragments below are retained for inspection, not supplied as a complete runnable lesson. Required scene objects and helpers are missing. They have not passed the ghost-student reconstruction test. The current hall separates statements about proof from bounded searches and visual representations. The sketch below does not implement Gödel numbering, a proof calculus or an incompleteness proof. Its verdict strings must not be treated as test results.

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Proof checking
- Bounded search
- Unprovability claims

Inspect why a label about unprovability is not an incompleteness proof. A reconstruction must distinguish a checked proof from an unsuccessful bounded search.

Inspect the proposed numeric encoding.

```gdscript
func godel_encode(statement: String) -> int:
    var primes := [2, 3, 5, 7, 11, 13, 17, 19, 23]
    var code := 1
    for i in statement.length():
        var ord_c: int = statement.unicode_at(i)
        code *= int(pow(primes[i % primes.size()], ord_c % 10))
    return code
```

This encoding loses information: characters with the same remainder modulo 10 collide, primes are reused, and the integer can overflow. It cannot serve as the required recoverable encoding of syntax.

Make a truncated display key.

```gdscript
func godel_key(code: int) -> String:
    return "stmt_%d" % (code % 100000)
```

Modulo 100000 discards more information. This function formats a key; it does not decode a statement or supply a lookup table.

Declare the self-referential statement.

```gdscript
const GODEL_STATEMENT := "This statement is not provable in this system."
var godel_code: int = 0

func prepare_godel() -> void:
    godel_code = godel_encode(GODEL_STATEMENT)
```

The snippet stores a sentence and computes a number. It supplies neither an arithmetic representation of provability nor the diagonal construction needed for the theorem.

Run the proof search.

```gdscript
func search_proof(code: int, depth: int) -> String:
    var axioms := ["PA1", "PA2", "PA3", "PA4"]
    for step in depth:
        if _derives(axioms, code):
            return "proved"
    return "not found"
```

The helper _derives is undefined. The loop repeats the same call without advancing a search state. Even a working bounded search returning not found would not establish unprovability.

Inspect the unsupported verdict strings.

```gdscript
func evaluate_godel() -> String:
    var result := search_proof(godel_code, 1000)
    if result == "proved":
        return "contradiction: system proved its own unprovability claim"
    else:
        return "incomplete: a true statement no proof can reach"
```

Neither verdict follows from the supplied program. In particular, not found does not mean true or unprovable. These strings are claims to replace, not successful assertions about a tested proof system.

Render the verdict on the plaque.

```gdscript
func show_verdict(label: Label3D) -> void:
    label.text = evaluate_godel()
    label.modulate = Color(0.85, 0.85, 0.6)
```

This formats the returned string. Colour and persistence give it no additional warrant.

Dim the lights on the verdict.

```gdscript
func dim_for_verdict() -> void:
    world_environment.environment.ambient_light_energy = 0.35
    spotlight_on_plaque.light_energy = 2.5
```

The ambient drops; a spot focuses on the plaque. The statement is a monument. Incompleteness is what the room is for.

Keep the distinction between a statement and its warrant. Escher Impossible next tests a different matter: height differences around a model, not a spatial proof of Gödel’s theorem.
<<</MAP>>>
