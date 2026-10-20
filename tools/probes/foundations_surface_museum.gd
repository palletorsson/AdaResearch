extends "res://tools/probes/noneuclid_lesson_museum.gd"
## The old high camera intersects the adjacent hall canopy after moving the bench.
## Keep the same assertions; capture from its supported visitor approach instead.
func snapshot(name: String, eye: Vector3, target: Vector3, fov: float = 55.0) -> void:
    if name == "above":
        await super.snapshot(name, eye, target, fov)
        return
    var study: Node3D = hall.get_node("StudentSurfaceStudy")
    await super.snapshot(name, study.to_global(Vector3(0,1.8,2.05)),
        study.to_global(Vector3(0,1.3,0)), 78)
