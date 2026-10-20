extends RefCounted
# Pair (support-for, support-against); each component is independently 0 or 1.
var p := Vector2i.ZERO
var q := Vector2i.ZERO

func neg(a: Vector2i) -> Vector2i:
    return Vector2i(a.y,a.x)

func both(a: Vector2i,b: Vector2i) -> Vector2i:
    return Vector2i(mini(a.x,b.x),maxi(a.y,b.y))

func either(a: Vector2i,b: Vector2i) -> Vector2i:
    return Vector2i(maxi(a.x,b.x),mini(a.y,b.y))

func supported(a: Vector2i) -> bool:
    return a.x==1

func describe(a: Vector2i) -> String:
    if a==Vector2i(1,1): return "BOTH REPORTS"
    if a==Vector2i(1,0): return "FOR ONLY"
    if a==Vector2i(0,1): return "AGAINST ONLY"
    return "NO SUPPORT"

func explosion_counterexample() -> Dictionary:
    for positive in [0,1]:
        for negative in [0,1]:
            var premise := Vector2i(positive,negative)
            for q_positive in [0,1]:
                for q_negative in [0,1]:
                    var conclusion := Vector2i(q_positive,q_negative)
                    if supported(premise) and supported(neg(premise)) and not supported(conclusion):
                        return {"found":true,"p":premise,"q":conclusion}
    return {"found":false}
