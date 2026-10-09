extends Node
var checks: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var scene: Node3D

func check(label: String, passes: bool, detail: Variant = null) -> void:
 checks.append({"check":label,"pass":passes,"detail":detail})
 if not passes: push_error("CHECK FAILED: " + label)

func run(study: Node3D) -> void:
 scene = study
 for i in range(8): await get_tree().physics_frame
 var counts := [12,24,36,84,84,444]
 check("six independent specimens",scene.encounter.records.size() == 6)
 for i in range(6):
  var record: Dictionary = scene.encounter.records[i]
  var body: MeshInstance3D = scene.encounter.meshes[record.id]
  check(record.id + " triangle count",record.faces == counts[i],record.faces)
  check(record.id + " retained tips",record.growing == (12 if i==5 else 2),record.growing)
  var finite := true
  var verts: PackedVector3Array = body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
  for v in verts: finite = finite and v.is_finite()
  check(record.id + " finite rendered geometry",finite)
  check(record.id + " mesh collision",body.get_child_count() >= 2)
  var ray := PhysicsRayQueryParameters3D.create(body.global_position+Vector3(0.1,7,0.13),body.global_position-Vector3(0,3,0),1)
  var hit: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(ray)
  check(record.id + " surface ray reaches specimen",not hit.is_empty() and body.is_ancestor_of(hit.get("collider")),str(hit.get("position")))
 # Continuous capsule travel through both rows, the narrow aisle and the exit.
 var route := [Vector3(-5,0,6),Vector3(5,0,6),Vector3(8,0,6),Vector3(8,0,0),Vector3(-8,0,0),Vector3(-8,0,-7),Vector3(2.5,0,-7),Vector3(2.5,0,0),Vector3(2.5,0,-9),Vector3(0,0,-10)]
 for target in route:
  var frames := 0
  while Vector2(scene.player.position.x-target.x,scene.player.position.z-target.z).length() > 0.12 and frames < 400:
   await get_tree().physics_frame
   var move := Vector3(target.x-scene.player.position.x,0,target.z-scene.player.position.z).normalized()
   scene.player.velocity = Vector3(move.x*4,scene.player.velocity.y-9.8/60.0,move.z*4)
   scene.player.move_and_slide()
   frames += 1
  check("walk to " + str(target),frames<400 and absf(scene.player.position.y)<0.08,str(scene.player.position))
 scene.player.position = Vector3(-5,0.02,6)
 for i in range(90):
  await get_tree().physics_frame
  scene.player.velocity = Vector3(0,scene.player.velocity.y-9.8/60.0,-4)
  scene.player.move_and_slide()
 check("plinth stops walking body",scene.player.position.z > 4.7 and scene.player.position.z < 4.9,str(scene.player.position))
 var cam := Camera3D.new()
 cam.fov = 58
 add_child(cam)
 cam.make_current()
 await shot(cam,"hall",Vector3(8.4,4.8,9),Vector3(0,1.5,-0.5))
 await shot(cam,"first-three",Vector3(6.7,3.3,10),Vector3(0,0.95,3.2))
 await shot(cam,"three-families",Vector3(7.2,5,5.5),Vector3(0,1.6,-3.2))
 await shot(cam,"inside",Vector3(2.5,1.7,0),Vector3(5,2.1,-3.2))
 await shot(cam,"diagonal",Vector3(-2.8,2.8,6.2),Vector3(-5,1.25,3.2))
 var file := FileAccess.open(OS.get_environment("ADA_GRAMMAR_OUT").path_join("native-checks.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"specimens":scene.encounter.records,"shots":shots},"  "))
 file.close()
 var ok := true
 for record in checks: ok = ok and record["pass"]
 get_tree().quit(0 if ok else 1)

func shot(camera: Camera3D, title: String, at: Vector3, target: Vector3) -> void:
 camera.position = at
 camera.look_at(target)
 for i in range(8): await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var error := get_viewport().get_texture().get_image().save_png(OS.get_environment("ADA_GRAMMAR_OUT").path_join(title + ".png"))
 check("capture " + title,error == OK)
 shots.append({"name":title,"camera":str(at),"target":str(target),"saved":error == OK})
