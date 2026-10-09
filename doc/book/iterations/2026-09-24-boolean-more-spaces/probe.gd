extends Node
var checks: Array = []
var stage
var out: String
func check(test: bool, message: String) -> void:
 checks.append({"pass":test,"check":message})
 print("PASS " if test else "FAIL ",message)
func settle(n: int=8) -> void:
 for i in n: await get_tree().physics_frame
func shot(name: String, at: Vector3, target: Vector3) -> void:
 stage.camera.global_position = at
 stage.camera.look_at(target,Vector3.UP)
 await settle(6)
 await RenderingServer.frame_post_draw
 var img = get_viewport().get_texture().get_image()
 check(img.save_png(out+"/"+name+".png")==OK,"capture "+name)
func run(s) -> void:
 stage = s
 out = OS.get_environment("ADA_BOOLEAN_OUT")
 await settle(90)
 for i in 3:
  var room = stage.rooms[i]
  var origin: Vector3 = room.position
  var tag: String = room.mode
  check(room.stock.get_meshes().size()==2,tag+" CSG generated mesh")
  var triangles: int = room.stock.get_meshes()[1].get_faces().size()/3
  check(triangles>100,tag+" nonempty carved boundary")
  checks.append({"pass":true,"check":tag+" triangle count","triangles":triangles})
  if tag == "ring":
   for direction in [1,-1]:
    var route: Array[Vector3] = []
    var start_angle := 0.0 if direction == 1 else PI
    for k in 13:
     var a := start_angle + float(k)*PI/12.0
     route.append(Vector3(sin(a)*3.5,0,cos(a)*3.5))
    route.append(Vector3(0,0,-7.8*direction))
    await walk_route(tag+" half-loop "+str(direction),origin,Vector3(0,0,7.8*direction),route)
   var qcore = PhysicsRayQueryParameters3D.create(origin+Vector3(0,1.2,3.5),origin+Vector3(0,1.2,0),1)
   check(not stage.get_world_3d().direct_space_state.intersect_ray(qcore).is_empty(),"ring core prevents a straight shortcut")
  else:
   for direction in [-1,1]:
    await walk_route(tag+" through route "+str(direction),origin,Vector3(0,0,-7.8*direction),[Vector3(0,0,0),Vector3(0,0,7.8*direction)])
   if tag == "cross":
    for side in [-1,1]:
     await walk_route("cross side branch "+str(side),origin,Vector3(0,0,7.8),[Vector3(0,0,0),Vector3(9.0*side,0,0),Vector3(0,0,0),Vector3(0,0,7.8)])
  # Ray through a solid flank, away from designed entry and pores.
  var q=PhysicsRayQueryParameters3D.create(origin+Vector3(-9,1,5.3),origin+Vector3(0,1,5.3),1)
  var flank=stage.get_world_3d().direct_space_state.intersect_ray(q)
  check(not flank.is_empty(),tag+" solid side blocks ray")
  # Actual ray hit and XR pointer event on the four surface buttons.
  var oldmesh=room.stock.get_meshes()[1].get_faces()
  for k in 4:
   var button=room.get_node("MaterialPlinth/Button_"+["PEARL","AMBER","CHROME","CHALK"][k])
   var target: Vector3=button.global_position
   var hit=stage.pointer_hit(target+Vector3(0,0,1),target-Vector3(0,0,.1))
   check(not hit.is_empty() and hit.collider==button,tag+" ray reaches surface button "+str(k))
   if not hit.is_empty():
    stage.PointerEvent.pressed(stage.camera,hit.collider,hit.position)
    stage.PointerEvent.released(stage.camera,hit.collider,hit.position)
   check(room.finish==k,tag+" pointer selected finish "+str(k))
  check(oldmesh==room.stock.get_meshes()[1].get_faces(),tag+" surface changes preserve geometry")
  room.set_finish(stage.study_finishes[i])
  var b=room.get_node("MaterialPlinth/Button_DRIFT")
  var bhit=stage.pointer_hit(b.global_position+Vector3(0,0,1),b.global_position-Vector3(0,0,.1))
  if not bhit.is_empty(): stage.PointerEvent.pressed(stage.camera,bhit.collider,bhit.position)
  await settle(10)
  check(room.breathing and room.elapsed>0,tag+" drift advances only surface phase")
  if not bhit.is_empty(): stage.PointerEvent.pressed(stage.camera,bhit.collider,bhit.position)
  check(not room.breathing,tag+" drift can stop")
  var stopped_phase: float = room.elapsed
  await settle(8)
  check(room.elapsed == stopped_phase,tag+" stopped phase holds")
  var eye := Vector3(.2,1.7,3.6)
  var target := Vector3(-1.8,2.8,-.4)
  if tag == "ring":
   eye=Vector3(.1,1.7,4.0)
   target=Vector3(3.6,2.0,.8)
  elif tag == "fold":
   eye=Vector3(0,1.7,4.8)
   target=Vector3(.2,3.0,-3)
  await shot(tag+"-inside",origin+eye,origin+target)
  await shot(tag+"-entry",origin+Vector3(3.8,2.0,9.2),origin+Vector3(0,2.4,0))
  if tag == "ring":
   await shot(tag+"-ceiling",origin+Vector3(3.5,1.7,.2),origin+Vector3(3.5,5.5,0))
   await shot("ring-return",origin+Vector3(-3.5,1.7,-.5),origin+Vector3(-2.0,2.0,3.5))
  else:
   await shot(tag+"-ceiling",origin+Vector3(.4,2.0,1.0),origin+Vector3(-.3,5.2,-1.8))
  if tag=="cross":
   for k in 4:
    room.set_finish(k)
    await shot("surface-"+str(k),origin+eye,origin+target)
   room.set_finish(stage.study_finishes[i])
 var f=FileAccess.open(out+"/runtime.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"checks":checks,"scope":"Isolated production artifact with a 1.8m x 0.30m CharacterBody capsule. Native renders and pointer-event tests; not a headset or museum-loader test."},"  "))
 f.close()
 var failed=checks.filter(func(c):return not c["pass"]).size()
 print("COMPLETE checks=",checks.size()," failures=",failed)
 get_tree().quit(1 if failed else 0)

func walk_route(label: String, origin: Vector3, start: Vector3, points: Array) -> void:
 stage.player.position=origin+start+Vector3(0,.02,0)
 stage.player.velocity=Vector3.ZERO
 stage.camera.position=Vector3(0,1.7,0)
 await settle()
 var all_reached := true
 var supported := true
 for local_point in points:
  var target: Vector3=origin+local_point
  var reached := false
  for tick in 180:
   await get_tree().physics_frame
   var offset: Vector3=target-stage.player.position
   offset.y=0
   if offset.length()<.12:
    reached=true
    break
   var v: Vector3=offset.normalized()*4.0
   stage.player.velocity=Vector3(v.x,-.6,v.z)
   stage.player.move_and_slide()
   supported=supported and absf(stage.player.position.y)<.1
  all_reached=all_reached and reached
  if not reached: break
 check(all_reached,label+" reached every waypoint")
 check(supported,label+" level support throughout")
