extends "res://tools/probes/transformation_encounters.gd"
const Journey=preload("res://tools/probes/array_entered_address.gd")
var office:Node3D
var actor:CharacterBody3D
var driver:Journey.KeyJourney
var completed:=false
var paths:Array=[]
func press(button:Node3D) -> void:
 var area:Node3D=button.get_node("InteractableAreaButton")
 XRToolsPointerEvent.pressed(camera,area,area.global_position)
 XRToolsPointerEvent.released(camera,area,area.global_position)
 await create_timer(0.15).timeout
func travel(point:Vector3,limit:int=8000) -> bool:
 driver.target=office.to_global(point);driver.arrived=false;driver.moving=true
 var start:=Time.get_ticks_msec()
 while not driver.arrived and Time.get_ticks_msec()-start<limit:await physics_frame
 driver.moving=false;driver.release()
 paths.append({"mode":"glass" if office.glass_visible else "opaque","target":xyz(point),"reached":xyz(office.to_local(actor.global_position)),"arrived":driver.arrived})
 return driver.arrived
func rgba(c:Color) -> Array:return [c.r,c.g,c.b,c.a]
func gradient_values(gradient:Node3D) -> Array:
 var values:Array=[]
 for cube in gradient._cubes:values.append(rgba(cube.material_override.albedo_color))
 return values
func landing_checks() -> void:
 root.size=Vector2i(1440,960)
 var grid:Node3D=hall.get_node_or_null("SimGrid_Color_Walls")
 check("authored grid present",grid!=null)
 if grid==null:return
 for frame in 3600:
  if grid.has_meta("stage_grid_ready"):break
  await process_frame
 check("grid complete",grid.has_meta("stage_grid_ready"))
 office=find_scene("/color_constellation_office.gd")
 var gradient:=find_scene("/gradient_interpolator.gd")
 var navigator:=find_scene("/color_space_navigator.gd")
 check("all three existing primary encounters placed",office!=null and gradient!=null and navigator!=null)
 if office==null or gradient==null or navigator==null:return
 check("floor-level office retains forty orthogonal panes",is_zero_approx(office.global_position.y) and office.office_panes.size()==40 and office.office_panes.all(func(p):return is_zero_approx(fposmod(p.rotation_degrees.y,90))))
 var desks:=0
 for n in office.find_children("*","MeshInstance3D",true,false):
  if n.mesh is BoxMesh and n.mesh.size.is_equal_approx(Vector3(1.7,0.065,0.7)):desks+=1
 check("eight desks remain",desks==8)
 var transforms:Array=[];var bodies:Array=[];var colours:Array=[]
 for pane in office.office_panes:
  transforms.append(pane.global_transform);bodies.append(pane.get_child(0).get_rid());colours.append(pane.material_override.albedo_color)
 await snapshot("office-approach",office.to_global(Vector3(0,1.65,-9.3)),office.to_global(Vector3(0,1.15,-1)),70)
 actor=museum.get("_player");museum.set("_dollhouse",false)
 var support:=floor_at(office.to_global(Vector3(0,0,-4.35)))
 check("comparison approach has floor",not support.is_empty())
 if support.is_empty():return
 actor.global_position=office.to_global(Vector3(0,0.05,-4.35));actor.velocity=Vector3.ZERO
 driver=Journey.KeyJourney.new();driver.world=museum;driver.actor=actor;driver.view=museum.get("_cam");root.add_child(driver)
 for mode in 2:
  var label:String="glass" if mode==0 else "opaque"
  check(label+" material state on every pane",office.office_panes.all(func(p):return is_equal_approx(p.material_override.albedo_color.a,0.26 if mode==0 else 1.0) and p.material_override.transparency==(BaseMaterial3D.TRANSPARENCY_ALPHA if mode==0 else BaseMaterial3D.TRANSPARENCY_DISABLED)))
  await snapshot("office-"+label,office.to_global(Vector3(0.3,1.65,-6.9)),office.to_global(Vector3(3.2,0.75,-5.5)),57)
  var arrived:=await travel(Vector3(2.5,0.05,-4.35),1800)
  var local:=office.to_local(actor.global_position)
  check(label+" pane stops the ordinary controller",not arrived and local.x>0.5 and local.x<1.6 and absf(local.y)<0.15)
  check(label+" walker retreats from pane",await travel(Vector3(0,0.05,-4.35)))
  check(label+" walker finds the same entrance",await travel(Vector3(0,0.05,-5.4)))
  check(label+" walker passes through the doorway",await travel(Vector3(2.5,0.05,-5.4)))
  await snapshot("inside-"+label,actor.global_position+Vector3.UP*1.65,office.to_global(Vector3(-3.2,1.1,-3.0)),72)
  check(label+" walker returns through doorway",await travel(Vector3(0,0.05,-5.4)))
  check(label+" walker returns to comparison",await travel(Vector3(0,0.05,-4.35)))
  await press(office.glass_button)
  check(label+" real pointer changes visibility",office.glass_visible==(mode==1))
 var same:=true
 for i in 40:
  var pane:MeshInstance3D=office.office_panes[i]
  var c:Color=pane.material_override.albedo_color;var original:Color=colours[i]
  same=same and transforms[i].is_equal_approx(pane.global_transform) and bodies[i]==pane.get_child(0).get_rid() and c.is_equal_approx(original)
 check("two toggles preserve geometry bodies and original colours",same and office.glass_visible)
 var rgb:MultiMesh=navigator.get_node("RGBSamples").multimesh
 var hsv:MultiMesh=navigator.get_node("HSLSamples").multimesh
 check("both models keep five hundred samples",rgb.instance_count==500 and hsv.instance_count==500)
 var mapped:=true
 for i in rgb.instance_count:
  var p:Vector3=rgb.get_instance_transform(i).origin/navigator.cube_size+Vector3.ONE*0.5
  var c:Color=rgb.get_instance_color(i)
  mapped=mapped and maxf(absf(p.x-c.r),maxf(absf(p.y-c.g),absf(p.z-c.b)))<0.004
 check("RGB samples keep channel positions",mapped)
 check("black corner explicitly raised for visibility",navigator.get_node("Corner_0").material_override.albedo_color.is_equal_approx(Color(0.08,0.08,0.08)))
 await snapshot("colour-coordinates",navigator.to_global(Vector3(0.45,0.55,1.65)),navigator.to_global(Vector3(0.45,0,0)),60)
 check("gradient starts with sixteen red-to-blue RGB samples",gradient._cubes.size()==16 and not gradient._mode_hsv and gradient._color_a_idx==0 and gradient._color_b_idx==5)
 var gradient_transforms:Array=[]
 for cube in gradient._cubes:gradient_transforms.append(cube.global_transform)
 var first:Color=gradient._cubes[0].material_override.albedo_color
 var last:Color=gradient._cubes[-1].material_override.albedo_color
 var mid:Color=gradient._cubes[7].material_override.albedo_color
 observations["rgb_values"]=gradient_values(gradient)
 await snapshot("gradient-rgb",gradient.to_global(Vector3(0,0.88,1.7)),gradient.to_global(Vector3(0,0.57,0)),42)
 await press(gradient.comparison_controls[2])
 check("real pointer selects HSV",gradient._mode_hsv)
 check("endpoints remain fixed",first.is_equal_approx(gradient._cubes[0].material_override.albedo_color) and last.is_equal_approx(gradient._cubes[-1].material_override.albedo_color))
 var hsv_mid:Color=gradient._cubes[7].material_override.albedo_color
 check("red-blue HSV interior differs and keeps unit value",not hsv_mid.is_equal_approx(mid) and is_equal_approx(hsv_mid.v,1.0) and mid.v<0.6)
 observations["hsv_values"]=gradient_values(gradient)
 await snapshot("gradient-hsv",gradient.to_global(Vector3(0,0.88,1.7)),gradient.to_global(Vector3(0,0.57,0)),42)
 await press(gradient.comparison_controls[0]);await press(gradient.comparison_controls[1])
 check("both endpoint controls select another pair",gradient._color_a_idx==1 and gradient._color_b_idx==6)
 for count in 7:await press(gradient.comparison_controls[0]);await press(gradient.comparison_controls[1])
 await press(gradient.comparison_controls[2])
 check("controls return to original RGB gradient",not gradient._mode_hsv and gradient_values(gradient)==observations.rgb_values)
 var poses_same:=true
 for i in 16:poses_same=poses_same and gradient_transforms[i].is_equal_approx(gradient._cubes[i].global_transform)
 check("all gradient cube transforms unchanged",poses_same)
 observations["walks"]=paths
 observations["office_world"]=xyz(office.global_position)
 completed=true
func finish() -> void:
 if driver!=null:driver.release();driver.set_physics_process(false)
 check("focused encounter completed",completed)
 FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Isolated production museum; supplied pointer events and ordinary-controller key journeys. Selected native camera views. No tracked-hand, headset, colour calibration, learner or performance claim."},"  "))
 print("WALLS VIEW AND PASSAGE ",checks.size()-failures.size(),"/",checks.size())
 quit(0 if failures.is_empty() else 1)
