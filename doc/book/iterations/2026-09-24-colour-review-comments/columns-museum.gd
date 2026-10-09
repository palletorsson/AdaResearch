extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
 museum.call("flush_stamps")
 var grid:Node3D=hall.get_node_or_null("SimGrid_Color_Context_Placed")
 check("colour hall embedded exhibits present",grid!=null)
 if grid==null:return
 for i in 1800:
  if grid.has_meta("stage_grid_ready"):break
  await process_frame
 check("museum exhibit build finished",grid.has_meta("stage_grid_ready"))
 for node in root.find_children("*","Node",true,false):
  if node.get_script()!=null and str(node.get_script().resource_path).ends_with("/MushroomHand.gd"):
   var hud:CanvasLayer=node.get("_hud")
   if hud!=null:hud.visible=false
 var dna:Array=[];var chroma:Array=[];var striped:Node3D
 for node in grid.find_children("*","Node3D",true,false):
  if node.get_script()==null:continue
  var path:String=node.get_script().resource_path
  if path.ends_with("/chroma_stack.gd"):chroma.append(node)
  if path.ends_with("/color_dna_stack.gd"):
   dna.append(node)
   if node.study=="kras_rainbow":striped=node
 check("all fifteen earlier stacks remain",chroma.size()==15)
 check("all eight DNA studies remain",dna.size()==8)
 check("striped column still placed",striped!=null)
 if striped!=null:
  var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/color_dna_stack/studies.json"))
  check("plate names the scale change",data.kras_rainbow.body.begins_with("A table-sized study, 72 centimetres tall"))
  check("stripe construction source retained",data.kras_rainbow.parts[0].source=="ps07_kras_rainbow")
  check("column remains 6.2 metres",is_equal_approx(float(data.kras_rainbow.parts[0].height),6.2))
  observations["striped_position_in_grid"]=xyz(grid.to_local(striped.global_position))
 await snapshot("colour-hall",grid.to_global(Vector3(11,2.2,3)),grid.to_global(Vector3(11,2.6,24)),74)
 await snapshot("among-the-columns",grid.to_global(Vector3(11,2.2,37)),grid.to_global(Vector3(11,3.6,52)),74)
 if striped!=null:
  await snapshot("rainbow-column",grid.to_global(Vector3(11,2.2,43)),striped.global_position+Vector3.UP*3.1,70)
 observations["capture_scope"]="Standing viewpoints in the loaded production museum, original materials and surrounding hall retained. No grid editor, isolated object stage or headset pose."
