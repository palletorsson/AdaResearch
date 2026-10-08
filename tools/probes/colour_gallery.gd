extends "res://tools/probes/transformation_encounters.gd"
## Visitor-height views of the installed Colour rooms, not isolated studies.
const VIEWS := {
 "Color_Context_Placed": [[10,1.7,1.8],[10,2.6,7],82],
 "Color_Flashlight": [[9,1.7,4.5],[9,1.7,9],78],
 "Color_Nails": [[7,1.7,2],[7,2.3,9],78],
 "Color_Rainbow": [[7,1.7,4],[7,2.1,13],78],
 "Color_Pillar": [[21,1.7,4.5],[27,3.4,15],78],
 "Color_Grid_Pallet": [[7.2,1.7,17.5],[10,0.5,10],80],
 "Color_Paint": [[12,1.7,18.8],[12,1.7,15],80],
 "Color_Walls": [[19,1.7,11.5],[26,1.7,22],78]
}
func v(a: Array) -> Vector3: return Vector3(a[0],a[1],a[2])
func snapshot(name: String, eye: Vector3, target: Vector3, fov: float = 55.0) -> void:
 camera.global_position=eye;camera.look_at(target);camera.fov=fov;camera.current=true
 await create_timer(0.4).timeout
 # Minimized native runs still advance real GPU feedback surfaces.
 for i in 4:
  RenderingServer.force_draw(false)
  await process_frame
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+name+".png"))
func landing_checks() -> void:
 root.size=Vector2i(1600,1000)
 root.mode=Window.MODE_MINIMIZED
 var grid: Node3D=hall.get_node_or_null("SimGrid_"+map_id)
 check("actual museum grid exists",grid!=null)
 if grid==null:return
 for i in 3600:
  if grid.has_meta("stage_grid_ready"):break
  await process_frame
 check("actual grid finished building",grid.has_meta("stage_grid_ready"))
 museum.flush_stamps()
 await create_timer(1.0).timeout
 for node in root.find_children("*","CanvasLayer",true,false):node.visible=false
 var previous: Camera3D=museum.get("_cam")
 if previous!=null:
  for n in previous.get_children():
   if n is Control:n.hide()
 if museum.get("_moon")!=null:museum.call("_aim_moon",0.0)
 if grid.has_node("ColourGallery"):await gallery_checks(grid)
 var view: Array=VIEWS[map_id]
 await tick()
 var foot:=grid.to_global(Vector3(view[0][0],.5,view[0][2]))
 check("visitor photograph has a supporting floor",not floor_at(foot).is_empty())
 var capsule:=CapsuleShape3D.new();capsule.radius=.25;capsule.height=1.6
 var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1
 query.transform=Transform3D(Basis.IDENTITY,foot+Vector3.UP*.85)
 var contacts:=hall.get_world_3d().direct_space_state.intersect_shape(query)
 check("visitor photograph is outside solid furniture",contacts.is_empty())
 observations["visitor_clearance_contacts"]=contacts.map(func(hit):return str(hit.collider.get_path()))
 await snapshot("room",grid.to_global(v(view[0])+Vector3.UP*.5),grid.to_global(v(view[1])+Vector3.UP*.5),view[2])
 var installed: Array=[]
 for n in hall.find_children("*","Node3D",true,false):
  if n.get_script()!=null:
   var path: String=n.get_script().resource_path
   if path.contains("/artifacts/") or path.contains("/algorithms/") or path.contains("drawingboard"):
    installed.append({"name":n.name,"source":path,"local_to_grid":xyz(grid.to_local(n.global_position))})
 observations["installed"]=installed

func gallery_checks(grid: Node3D) -> void:
 var gallery: Node3D=grid.get_node("ColourGallery")
 var mm: MultiMeshInstance3D=grid.get_node("GridMultiMesh")
 var count:=mm.multimesh.instance_count
 var nodes:=gallery.get_child_count()
 gallery.install(grid)
 check("finish installs only once",grid.find_children("ColourGallery","Node3D",false,false).size()==1 and gallery.get_child_count()==nodes)
 check("original floor and wall instances retained",count==grid.structure_component.cube_positions.size())
 check("gallery shader replaces triangular wire overlay",mm.material_override.shader.resource_path.ends_with("colour_gallery.gdshader"))
 check("only the address hall uses instance colour on its floor",mm.material_override.get_shader_parameter("addressed_floor")== (map_id=="Color_Grid_Pallet"))
 check("wall columns have been built",gallery.pier_count>0)
 var wall_width: int=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/%s/map_data.json"%map_id)).map_info.dimensions.width
 var at_walls:=true
 for collider: CollisionShape3D in gallery.find_children("*","CollisionShape3D",true,false):
  var x:=grid.to_local(collider.global_position).x
  at_walls=at_walls and (x<.75 or x>wall_width-1.75)
 check("new architectural collision stays at perimeter walls",at_walls)
 check("museum lettering installed",grid.has_node("MuseumIdentity/Tagline") and grid.get_node("MuseumIdentity/Tagline").text=="always another room")
 match map_id:
  "Color_Context_Placed":
   check("all twenty-three stacks have a low white plinth",grid.find_children("StackPlinth*","MeshInstance3D",false,false).size()==23)
  "Color_Flashlight":
   var lamp:=find_scene("/flashlight_demo.gd")
   check("four existing lamps and faceted receiver retained",lamp!=null and lamp.has_node("FacetedReceiver") and lamp.has_node("WhiteFlashlight"))
   check("gallery adds no light to the illumination lesson",gallery.find_children("*","Light3D",true,false).is_empty())
  "Color_Nails":
   var salon:=find_scene("/nail_salon.gd")
   check("both hand scales retain their materials",salon.hands.size()==2 and salon.nail_materials.size()==2)
   var old: Color=salon.nail_materials[0].albedo_color
   salon._nail_colour(Color("be143d"))
   check("nail colour still reaches both receivers",salon.nail_materials.all(func(m):return m.albedo_color.is_equal_approx(Color("be143d"))))
   salon._nail_colour(old)
  "Color_Rainbow":
   check("rainbow installation retained",find_scene("/rainbow.gd")!=null)
  "Color_Pillar":
   var field:=find_scene("/pillarcolorcollection.gd")
   check("thirty-five field samples retained",field.find_children("Pillar_*","Node3D",false,false).size()==35)
   check("dark floor and matching ceiling retained",field.has_node("DarkFloor") and field.get_node("ColourCeiling").material_override.get_shader_parameter("field_mode")==2)
   check("gallery adds no wash over the fog-like field",gallery.find_children("*","Light3D",true,false).is_empty())
  "Color_Grid_Pallet":
   var lesson:=find_scene("/address_lesson.gd")
   check("address console ready",lesson!=null and lesson.ready_for_input)
   if lesson!=null and lesson.ready_for_input:
    var chosen: Vector2i=lesson.selected
    var original: Color=lesson.colorizer.multimesh.get_instance_color(lesson.cells[chosen])
    lesson.buttons[2].pressed.emit()
    var ink: Color=lesson.colorizer.multimesh.get_instance_color(lesson.cells[chosen])
    lesson.buttons[0].pressed.emit()
    check("colour remains when selection moves",lesson.selected!=chosen and lesson.colorizer.multimesh.get_instance_color(lesson.cells[chosen]).is_equal_approx(ink))
    lesson.buttons[3].pressed.emit()
    check("RULE restores the addressed cell",lesson.colorizer.multimesh.get_instance_color(lesson.cells[chosen]).is_equal_approx(original))
    check("colour writes keep the new museum finish",mm.material_override.shader.resource_path.ends_with("colour_gallery.gdshader"))
    lesson.selected=chosen;lesson._refresh()
  "Color_Paint":
   var painter:=find_scene("/ball_painting_automation.gd")
   check("thirty original spray cans remain",painter.get_node("PaintBalls").get_child_count()==30)
   check("same wet canvas and automatic painter",painter.surface.wet_paint and painter.strokes>0 and painter.has_node("AutomatedSprayCan"))
   # Advance the real feedback viewport while this capture window is minimized.
   for i in 100:
    RenderingServer.force_draw(false)
    await process_frame
  "Color_Walls":
   var office:=find_scene("/color_constellation_office.gd")
   if office==null:
    for n in grid.find_children("*","Node3D",true,false):
     if n.get("office_panes")!=null:office=n;break
   check("twelve coloured partitions retained",office!=null and office.office_panes.size()==12)
   if office!=null:
    var poses: Array=[]
    for pane in office.office_panes:poses.append(pane.global_transform)
    office.toggle_office_glass()
    var kept:=true
    for i in office.office_panes.size():kept=kept and office.office_panes[i].global_transform.is_equal_approx(poses[i]) and office.office_panes[i].has_node("PaneBody")
    check("opacity toggle preserves pane placement and collision",kept)
    office.toggle_office_glass()
