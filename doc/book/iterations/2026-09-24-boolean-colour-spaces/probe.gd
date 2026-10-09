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
  stage.player.position = origin+Vector3(0,.015,7.8)
  stage.player.velocity = Vector3.ZERO
  stage.camera.position = Vector3(0,1.70,0)
  await settle()
  for direction in [-1,1]:
   for step in 330:
    await get_tree().physics_frame
    stage.player.velocity=Vector3(0,-.6,direction*3.0)
    stage.player.move_and_slide()
    if (direction<0 and stage.player.position.z< -7.7) or (direction>0 and stage.player.position.z>7.7):break
   check(absf(stage.player.position.z-direction*7.7)<.20,tag+" capsule traversal direction "+str(direction))
   check(absf(stage.player.position.y)<.10,tag+" maintained level support")
  # Ray through a solid flank, away from designed entry and pores.
  var q=PhysicsRayQueryParameters3D.create(origin+Vector3(-9,1,0),origin+Vector3(0,1,0),1)
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
  room.set_finish(i)
  var b=room.get_node("MaterialPlinth/Button_DRIFT")
  var bhit=stage.pointer_hit(b.global_position+Vector3(0,0,1),b.global_position-Vector3(0,0,.1))
  if not bhit.is_empty(): stage.PointerEvent.pressed(stage.camera,bhit.collider,bhit.position)
  await settle(10)
  check(room.breathing and room.elapsed>0,tag+" drift advances only surface phase")
  if not bhit.is_empty(): stage.PointerEvent.pressed(stage.camera,bhit.collider,bhit.position)
  check(not room.breathing,tag+" drift can stop")
  await shot(tag+"-inside",origin+Vector3(.2,1.70,3.2),origin+Vector3(-.3,3.0,-2.4))
  await shot(tag+"-entry",origin+Vector3(3.8,2.0,9.2),origin+Vector3(0,2.4,0))
  await shot(tag+"-ceiling",origin+Vector3(.4,2.2,1.0),origin+Vector3(-.3,5.2,-1.8))
  if i==0:
   for k in 4:
    room.set_finish(k)
    await shot("surface-"+str(k),origin+Vector3(.2,1.70,3.2),origin+Vector3(-.3,3.0,-2.4))
   room.set_finish(0)
 var f=FileAccess.open(out+"/runtime.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"checks":checks,"scope":"Isolated production artifact with a 1.8m x 0.30m CharacterBody capsule. Native renders and pointer-event tests; not a headset or museum-loader test."},"  "))
 f.close()
 var failed=checks.filter(func(c):return not c["pass"]).size()
 print("COMPLETE checks=",checks.size()," failures=",failed)
 get_tree().quit(1 if failed else 0)
