extends RefCounted
var amount := 0.0
const WORDS = ["queer", "disabled", "refugee", "normal", "professional", "objective"]

func layout(value: float) -> Array[Vector3]:
    amount = clampf(value, 0, 1)
    var result: Array[Vector3] = []
    for i in 6:
        var warm := i < 3
        var column := i % 3
        var start := Vector3((column-1)*0.52, 1.4, -0.3 if warm else 0.3)
        var finish := Vector3((column-1)*(0.12 if warm else 0.8), 1.4, -0.45 if warm else 0.45)
        result.append(start.lerp(finish, amount))
    return result
