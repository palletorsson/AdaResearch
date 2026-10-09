extends "res://doc/book/iterations/2026-09-24-arrays-review-comments/floor-probe.gd"
func landing_checks() -> void:
 museum.call("flush_stamps")
 await super.landing_checks()
 await snapshot("museum-approach",hall.to_global(Vector3(10,1.7,1)),hall.to_global(Vector3(10,1.7,18)),74)
 await snapshot("museum-hall",hall.to_global(Vector3(10,1.7,7)),hall.to_global(Vector3(11,1.7,22)),74)
func snapshot(label:String,eye:Vector3,target:Vector3,fov:float=55.0) -> void:
 if label=="the-written-floor" or label=="floor-restored":
  eye=writer.grid.parent_node.to_global(Vector3(18,2.2,13))
  target=writer.grid.parent_node.to_global(Vector3(14.5,0.8,17.5))
  fov=76
 await super.snapshot(label,eye,target,fov)
