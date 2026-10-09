extends "res://doc/book/iterations/2026-09-23-nails-the-choosing-hand/probe.gd"
func landing_checks() -> void:
 museum.call("flush_stamps")
 for node in root.find_children("*","Node",true,false):
  if node.get_script()!=null and str(node.get_script().resource_path).ends_with("/MushroomHand.gd"):
   var hud:CanvasLayer=node.get("_hud")
   if hud!=null:hud.visible=false
 await super.landing_checks()
func snapshot(label:String,eye:Vector3,target:Vector3,fov:float=55.0) -> void:
 if label.begins_with("salon-"):
  var grid:Node3D=hall.get_node("SimGrid_Color_Nails")
  eye=grid.to_global(Vector3(7,2.2,4))
  target=grid.to_global(Vector3(7,2.6,10))
  fov=76
 await super.snapshot(label,eye,target,fov)
