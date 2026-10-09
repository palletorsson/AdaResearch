extends Node
var checks: Array = []
var stage
var out: String
func check(value: bool, label: String) -> void:
 checks.append({"pass":value,"check":label})
 print("PASS " if value else "FAIL ",label)
func settle(n: int=8) -> void:
 for i in n: await get_tree().physics_frame
func shot(key: String, at: Vector3, target: Vector3, fov: float=65) -> void:
 stage.camera.global_position=at
 stage.camera.look_at(target,Vector3.UP)
 stage.camera.fov=fov
 await settle(5)
 await RenderingServer.frame_post_draw
 check(get_viewport().get_texture().get_image().save_png(out+"/"+key+".png")==OK,"capture "+key)
func walk(label: String, start: Vector3, points: Array) -> void:
 stage.player.position=start+Vector3(0,.02,0)
 stage.player.velocity=Vector3.ZERO
 await settle()
 var reached_all := true
 var supported := true
 for target in points:
  var reached := false
  for tick in 190:
   await get_tree().physics_frame
   var offset: Vector3=target-stage.player.position
   offset.y=0
   if offset.length()<.12:
    reached=true
    break
   var velocity: Vector3=offset.normalized()*4.0
   stage.player.velocity=Vector3(velocity.x,-.6,velocity.z)
   stage.player.move_and_slide()
   supported=supported and absf(stage.player.position.y)<.1
  reached_all=reached_all and reached
  if not reached:break
 check(reached_all,label+" reaches every waypoint")
 check(supported,label+" stays supported")
func blocked(label: String, start: Vector3, target: Vector3) -> void:
 stage.player.position=start+Vector3(0,.02,0)
 stage.player.velocity=Vector3.ZERO
 await settle()
 for tick in 120:
  await get_tree().physics_frame
  var d: Vector3=(target-stage.player.position)
  d.y=0
  d=d.normalized()*3
  stage.player.velocity=Vector3(d.x,-.6,d.z)
  stage.player.move_and_slide()
 check(stage.player.position.z>3.65,label)
func occupied(p: Vector3, faces: PackedVector3Array) -> bool:
 var direction:=Vector3(1,.173,.271).normalized()
 var hits: Array[float]=[]
 for i in range(0,faces.size(),3):
  var hit=Geometry3D.ray_intersects_triangle(p,direction,faces[i],faces[i+1],faces[i+2])
  if hit!=null:
   var distance: float=(hit-p).dot(direction)
   if distance>.00001:hits.append(distance)
 hits.sort()
 var unique:=0
 var last:=-1.0
 for distance in hits:
  if absf(distance-last)>.0001:
   unique+=1
   last=distance
 return unique%2==1
func signature(node: Node) -> Array:
 var record: Array=[node.name]
 if node is CSGBox3D: record.append(node.size)
 if node is CSGSphere3D: record.append(node.radius)
 if node is Node3D: record.append(node.transform)
 for child in node.get_children():record.append(signature(child))
 return record
func run(s) -> void:
 stage=s
 out=OS.get_environment("ADA_BOOLEAN_OUT")
 await settle(90)
 var pair=stage.encounter
 check(pair.room.operation==0 and pair.positive.operation==0,"two independently collidable CSG roots")
 check(pair.room_void.operation==2 and pair.cast_void.operation==1,"difference for room; intersection for positive")
 check(signature(pair.room_void)==signature(pair.cast_void),"identical void dimensions, details and transforms")
 var rfaces: PackedVector3Array=pair.room.get_meshes()[1].get_faces()
 var cfaces: PackedVector3Array=pair.positive.get_meshes()[1].get_faces()
 check(rfaces.size()>100 and cfaces.size()>100,"both result meshes generated")
 checks.append({"pass":true,"check":"mesh triangle counts","room":rfaces.size()/3,"positive":cfaces.size()/3})
 var samples:=0
 var overlaps:=0
 var gaps:=0
 for x in [-3.8,-3.0,-2.0,0.0,2.0,3.8]:
  for y in [.5,1.8,3.4,4.6]:
   for z in [-3.3,-2.2,.5,2.6,3.3]:
    var p:=Vector3(x,y,z)
    var r:=occupied(p,rfaces)
    var c:=occupied(p,cfaces)
    samples+=1
    if r and c:overlaps+=1
    if not r and not c:gaps+=1
 check(overlaps==0,"sampled room and positive do not overlap")
 check(gaps==0,"sampled room and positive fill the stock together")
 checks.append({"pass":overlaps==0 and gaps==0,"check":"partition samples","samples":samples,"overlaps":overlaps,"gaps":gaps})
 for spec in [["doorway",Vector3(-2,1.5,3.1)],["window",Vector3(1.6,2.4,3.1)],["inside",Vector3(0,1.5,0)]]:
  check(not occupied(spec[1],rfaces) and occupied(spec[1],cfaces),str(spec[0])+" void corresponds to positive matter")
 check(occupied(Vector3(-3.22,3.35,.45),rfaces) and not occupied(Vector3(-3.22,3.35,.45),cfaces),"wall rail becomes an indentation in the positive")
 check(not occupied(Vector3(-3.22,2,.45),rfaces) and occupied(Vector3(-3.22,2,.45),cfaces),"wall below rail keeps inverse correspondence")
 var bounds: AABB=pair.positive.get_meshes()[1].get_aabb()
 check(bounds.position.x>=-4.001 and bounds.end.x<=4.001 and bounds.position.y>=-.001 and bounds.end.y<=5.001 and bounds.position.z>=-3.501 and bounds.end.z<=3.501,"positive clipped to stock, not the unbounded cutter")
 check(pair.facade.get_node_or_null("WindowFrame/GlassPane")==null,"only this facade window's visual pane removed")
 check(pair.facade.get_node_or_null("DoorFrame/DoorVoid")==null,"only this doorway's visual backing removed")
 await walk("enter, visit alcove and return",Vector3(-8,0,6),[Vector3(-8,0,2.2),Vector3(-6.5,0,.5),Vector3(-4.8,0,-1.2),Vector3(-6.5,0,.5),Vector3(-8,0,2.2),Vector3(-8,0,6)])
 await blocked("room window sill prevents walking through",Vector3(-4.4,0,5),Vector3(-4.4,0,1.8))
 await blocked("positive doorway is solid",Vector3(4,0,5),Vector3(4,0,1.8))
 await walk("walk around positive",Vector3(1.2,0,5),[Vector3(10.5,0,5),Vector3(10.5,0,-4.5),Vector3(1.2,0,-4.5),Vector3(1.2,0,5)])
 var q=PhysicsRayQueryParameters3D.create(Vector3(-4.4,2.4,2),Vector3(-4.4,2.4,5),1)
 check(stage.get_world_3d().direct_space_state.intersect_ray(q).is_empty(),"room window carries an unobstructed sightline")
 await shot("pair",Vector3(0,4,17),Vector3(0,2,0),56)
 await shot("facade",Vector3(-5.8,2.1,11),Vector3(-6,2.3,2.8),58)
 await shot("inside",Vector3(-8,1.7,2.0),Vector3(-4.9,2.5,-1.2),76)
 await shot("inside-return",Vector3(-5.1,1.7,-.6),Vector3(-6,2.0,3.5),74)
 await shot("positive",Vector3(12,3.7,8.5),Vector3(6,2.0,0),62)
 await shot("positive-rail",Vector3(1.1,3.25,1.7),Vector3(3.1,3.25,.2),58)
 await shot("room-rail",Vector3(-7.4,3.25,1.7),Vector3(-9.15,3.25,.2),58)
 await shot("overview",Vector3(0,14,11),Vector3(0,1.5,0),65)
 await shot("window-inside",Vector3(-4.4,2.35,1.0),Vector3(-4.4,2.4,3.5),70)
 await shot("window-positive",Vector3(9.5,2.8,5.8),Vector3(7.6,2.4,3.0),65)
 var file=FileAccess.open(out+"/runtime.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"scope":"Production paired artifact in isolated desktop study; sampled mesh partition, capsule routes and native renders. Not headset or full museum-loader evidence.","checks":checks},"  "))
 file.close()
 var failures=checks.filter(func(c):return not c["pass"]).size()
 print("COMPLETE checks=",checks.size()," failures=",failures)
 get_tree().quit(1 if failures else 0)
