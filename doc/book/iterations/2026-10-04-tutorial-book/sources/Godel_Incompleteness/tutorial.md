# Gödel Incompleteness

Encode statements as numbers. Build a statement that refers to its own unprovability and watch the system refuse to prove or disprove it.

Declare a Gödel encoding.

```gdscript
func godel_encode(statement: String) -> int:
    var primes := [2, 3, 5, 7, 11, 13, 17, 19, 23]
    var code := 1
    for i in statement.length():
        var ord_c: int = statement.unicode_at(i)
        code *= int(pow(primes[i % primes.size()], ord_c % 10))
    return code
```

A toy encoding using primes. Real Gödel numbering is more careful; the principle is the same. Statements become integers, and integers become arguments inside arithmetic.

Decode a code back to a key.

```gdscript
func godel_key(code: int) -> String:
    return "stmt_%d" % (code % 100000)
```

The decoded key is what the system uses to look up a statement. Lookup on integers is the trick that lets the system talk about itself.

Declare the self-referential statement.

```gdscript
const GODEL_STATEMENT := "This statement is not provable in this system."
var godel_code: int = 0

func prepare_godel() -> void:
    godel_code = godel_encode(GODEL_STATEMENT)
```

The statement is stored as text and as a code. The system can hold both representations and reason about the code numerically.

Run the proof search.

```gdscript
func search_proof(code: int, depth: int) -> String:
    var axioms := ["PA1", "PA2", "PA3", "PA4"]
    for step in depth:
        if _derives(axioms, code):
            return "proved"
    return "not found"
```

A finite search. The function returns either a proof or the absence of one within the depth budget. Gödel's theorem says the absence is permanent, not a budget issue.

Detect the impossibility.

```gdscript
func evaluate_godel() -> String:
    var result := search_proof(godel_code, 1000)
    if result == "proved":
        return "contradiction: system proved its own unprovability claim"
    else:
        return "incomplete: a true statement no proof can reach"
```

Either outcome is an incompleteness. The text says so. The formal system is closed; the question is not.

Render the verdict on the plaque.

```gdscript
func show_verdict(label: Label3D) -> void:
    label.text = evaluate_godel()
    label.modulate = Color(0.85, 0.85, 0.6)
```

Cream-yellow on a stone plaque. The verdict is not rewritten on each visit; the result is stable and inescapable.

Dim the lights on the verdict.

```gdscript
func dim_for_verdict() -> void:
    world_environment.environment.ambient_light_energy = 0.35
    spotlight_on_plaque.light_energy = 2.5
```

The ambient drops; a spot focuses on the plaque. The statement is a monument. Incompleteness is what the room is for.

You have encountered the hardest limit on formal systems. The next map, Escher Impossible, translates the limit into architecture the body can walk.
<<</MAP>>>
