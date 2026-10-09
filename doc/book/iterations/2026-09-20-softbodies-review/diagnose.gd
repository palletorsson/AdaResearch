extends SceneTree
func _initialize():call_deferred("run")
func run():
 var m=load("res://algorithms/softbodies/rounded_softbody.tscn").instantiate()
 m.position=Vector3(4,1,4);root.add_child(m)
 var a=m._soft_body.mesh.surface_get_arrays(0)
 var inward=0
 for i in a[Mesh.ARRAY_NORMAL].size():
  if a[Mesh.ARRAY_NORMAL][i].dot(a[Mesh.ARRAY_VERTEX][i])<0:inward+=1
 print("INITIAL NORMALS inward ",inward," of ",a[Mesh.ARRAY_NORMAL].size())
 var c=Camera3D.new();root.add_child(c);c.position=Vector3(4,2,0);c.look_at(Vector3(4,1,4));c.current=true
 for step in 8:
  await create_timer(0.15).timeout
  var b=AABB(PhysicsServer3D.soft_body_get_point_global_position(m._sb_rid,0),Vector3.ZERO)
  for i in m._vertex_count:b=b.expand(PhysicsServer3D.soft_body_get_point_global_position(m._sb_rid,i))
  print("DIAG ",step," bounds ",b," rest ",m._rest_volume," transform ",m._soft_body.global_transform)
 var q=PhysicsRayQueryParameters3D.create(Vector3(4,2,4),Vector3(4,0,4),1)
 print("RAY ",m.get_world_3d().direct_space_state.intersect_ray(q))
 quit()
