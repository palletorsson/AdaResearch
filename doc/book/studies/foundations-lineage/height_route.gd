extends RefCounted
var points: Array[Vector3] = [Vector3(-0.7,0,-0.5), Vector3(0.7,0.2,-0.5),
    Vector3(0.7,0.4,0.5), Vector3(-0.7,0.6,0.5)]
var closed := true
var index := 0
var up := 0.0
var down := 0.0
var last := 0.0

func reset() -> void:
    index=0
    up=0
    down=0
    last=0

func step(frame: Transform3D = Transform3D.IDENTITY) -> bool:
    if points.is_empty() or (not closed and index==points.size()-1): return false
    var next := (index+1)%points.size()
    last = (frame*points[next]).y - (frame*points[index]).y
    up += maxf(last,0)
    down += maxf(-last,0)
    index=next
    return true

func closure(frame: Transform3D = Transform3D.IDENTITY) -> float:
    var total := 0.0
    for i in points.size():
        total += (frame*points[(i+1)%points.size()]).y - (frame*points[i]).y
    return total
