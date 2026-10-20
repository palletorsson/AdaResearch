extends RefCounted
# Six equal seats: this working comparison varies positions only.
func layout(circle: bool) -> Array[Vector3]:
    var points: Array[Vector3] = []
    for i in 6:
        if circle:
            var angle := TAU*float(i)/6.0
            points.append(Vector3(cos(angle)*0.7,1.1,sin(angle)*0.7))
        else:
            points.append(Vector3(-0.75+float(i%3)*0.75,1.1,-0.45 if i<3 else 0.45))
    return points

func gaps(points: Array[Vector3]) -> Array[float]:
    var result: Array[float] = []
    for i in points.size(): result.append(points[i].distance_to(points[(i+1)%points.size()]))
    return result

# An authored centre-distance rule, not an accessibility or fairness standard.
func accepts(points: Array[Vector3], minimum_gap: float) -> bool:
    if points.size()<2 or not is_finite(minimum_gap) or minimum_gap<=0: return false
    for i in points.size():
        for j in range(i+1,points.size()):
            if points[i].distance_to(points[j])+0.00001<minimum_gap: return false
    return true
