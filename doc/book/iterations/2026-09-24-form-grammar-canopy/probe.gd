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
 var route := [Vector3(-5,0,6),Vector3(5,0,6),Vector3(8,0,6),Vector3(8,0,0),Vector3(-8,0,0),Vector3(-8,0,-7),Vector3(2.5,0,-7),Vector3(2.5,0,0),Vector3(2.5,0,-9),Vector3(0,0,-10),Vector3(-7,0,-12),Vector3(-7,0,-20),Vector3(-2,0,-20),Vector3(-2,0,-24),Vector3(-2,0,-26),Vector3(2,0,-26),Vector3(2,0,-24),Vector3(7,0,-24),Vector3(7,0,-29),Vector3(0,0,-30)]
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
 var small: MeshInstance3D = scene.canopy.specimens.petals
 var large: MeshInstance3D = scene.canopy.specimens.canopy
 var sv: PackedVector3Array = small.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
 var lv: PackedVector3Array = large.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
 check("small and canopy use identical local vertices",sv == lv)
 check("same local bounding box",small.mesh.get_aabb() == large.mesh.get_aabb())
 check("canopy is uniformly four times",large.global_basis.get_scale().is_equal_approx(Vector3.ONE*4))
 check("same six-petal parameter set",scene.canopy.records[1].parameters==scene.canopy.records[2].parameters)
 check("surface begins above head",is_equal_approx(large.global_position.y,3.6))
 var finite := true
 for v in lv: finite = finite and v.is_finite()
 check("petal surface finite",finite)
 check("added geometry beyond seed",sv.size()>3)
 # A strip face away from the support, approached from both normal directions.
 var hit_both := true
 var chosen := false
 for i in range(3,lv.size(),3):
  var centre: Vector3 = (lv[i]+lv[i+1]+lv[i+2])/3.0
  if Vector2(centre.x,centre.z).length()<0.5: continue
  var n: Vector3 = (lv[i+1]-lv[i]).cross(lv[i+2]-lv[i]).normalized()
  var pos: Vector3 = large.to_global(centre)
  for sign in [-1,1]:
   var ray := PhysicsRayQueryParameters3D.create(pos+n*0.15*sign,pos-n*0.15*sign,1)
   var hit: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(ray)
   hit_both = hit_both and not hit.is_empty() and large.is_ancestor_of(hit.get("collider"))
  chosen=true
  break
 check("open strip collides from both sides",chosen and hit_both)
 # Check central authored support, while the route above proves walk-under access.
 scene.player.position = Vector3(0,0.02,-28)
 for i in range(100):
  await get_tree().physics_frame
  scene.player.velocity = Vector3(0,scene.player.velocity.y-9.8/60.0,4)
  scene.player.move_and_slide()
 check("canopy support stops body",scene.player.position.z < -25.4 and scene.player.position.z > -25.7,str(scene.player.position))
 var cam := Camera3D.new()
 cam.fov = 58
 add_child(cam)
 cam.make_current()
 await shot(cam,"canopy",Vector3(8,3.6,-15),Vector3(0,3.5,-24))
 await shot(cam,"beneath",Vector3(-2.6,1.7,-27.6),Vector3(0,4.8,-24))
 await shot(cam,"face-and-petals",Vector3(0,3.8,-7.2),Vector3(0,0.9,-16.4))
 await shot(cam,"small",Vector3(5.6,2.5,-13.8),Vector3(4.3,1.25,-16.4))
 await shot(cam,"hall",Vector3(8.4,5.8,9),Vector3(0,2.5,-12))
 var file := FileAccess.open(OS.get_environment("ADA_GRAMMAR_OUT").path_join("native-checks.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"specimens":scene.encounter.records,"canopy":scene.canopy.records,"shots":shots},"  "))
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
