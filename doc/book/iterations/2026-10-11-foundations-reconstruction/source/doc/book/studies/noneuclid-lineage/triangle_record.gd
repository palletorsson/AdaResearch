extends RefCounted
## A flat construction in metres. Positions and measurements are separate records.
const EPS := 0.00001
var points: Array[Vector2] = []

func _init() -> void:
    reset()

func reset() -> void:
    points.assign([Vector2(-0.7, 0.4), Vector2(0.7, 0.4), Vector2(0, -0.6)])

func measure() -> Dictionary:
    var ab := points[1] - points[0]
    var ac := points[2] - points[0]
    var bc := points[2] - points[1]
    var longest := maxf(ab.length(), maxf(ac.length(), bc.length()))
    var twice_area := absf(ab.cross(ac))
    # Refuse coincident or nearly collinear corners at this numerical scale.
    if longest <= EPS or twice_area <= EPS * longest * longest:
        return {"valid": false, "angles": [], "sum": 0.0, "area": twice_area * 0.5}
    var angles: Array[float] = []
    var total := 0.0
    for i in range(3):
        var u := points[(i + 1) % 3] - points[i]
        var v := points[(i + 2) % 3] - points[i]
        var angle := rad_to_deg(atan2(absf(u.cross(v)), u.dot(v)))
        angles.append(angle)
        total += angle
    return {"valid": true, "angles": angles, "sum": total, "area": twice_area * 0.5}

func parallel_ends(half_length: float = 1.25) -> Array[Vector2]:
    var direction := points[1] - points[0]
    if direction.length() <= EPS:
        return []
    direction = direction.normalized() * half_length
    return [points[2] - direction, points[2] + direction]
