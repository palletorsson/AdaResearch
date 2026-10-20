extends "../probe_base.gd"

func silhouette_delta(a: Image,b: Image) -> int:
    var changes := 0
    var bg := a.get_pixel(0,0)
    for y in range(0,512,2):
        for x in range(0,512,2):
            var ca := a.get_pixel(x,y); var cb := b.get_pixel(x,y)
            var ia := absf(ca.r-bg.r)+absf(ca.g-bg.g)+absf(ca.b-bg.b)>0.15
            var ib := absf(cb.r-bg.r)+absf(cb.g-bg.g)+absf(cb.b-bg.b)>0.15
            if ia != ib: changes += 1
    return changes

func _run() -> void:
    setup("water")
    for child in space.get_children():
        if child is WorldEnvironment: child.environment.background_color = Color(0.8,0,0.8)
    probe_quad = MeshInstance3D.new()
    probe_quad.mesh = study.surface.mesh
    probe_quad.material_override = study.material
    probe_quad.position = Vector3(5,0,0)
    probe_quad.custom_aabb = study.surface.custom_aabb
    space.add_child(probe_quad)
    camera.size = 3.6
    camera.position = Vector3(5,1.6,4)
    camera.look_at(Vector3(5,0,0))
    var colour := await capture("colour")
    study.next_mode(study.control)
    var normal := await capture("normal")
    check(difference(colour,normal)>0.001,"normal mode changes surface light",difference(colour,normal))
    check(silhouette_delta(colour,normal)==0,"normal mode preserves silhouette",silhouette_delta(colour,normal))
    study.next_mode(study.control)
    var height := await capture("height")
    check(silhouette_delta(normal,height)>20,"height mode changes silhouette",silhouette_delta(normal,height))
    await move_control(Vector3(0.9,1.2,1.2))
    var quarter := await capture("quarter-phase")
    await move_control(Vector3(1.4,1.2,1.2))
    var three_quarters := await capture("three-quarter-phase")
    var path_difference := difference(quarter,three_quarters)
    check(path_difference>0.005 if mode == "original" else path_difference<0.001,"circular versus retraced path prediction",path_difference)
    await move_control(Vector3(1.65,1.2,1.2))
    var returned := await capture("full-phase")
    check(difference(height,returned)<0.001,"full phase turn returns field",difference(height,returned))
    await frame(20)
    var held := await capture("held")
    check(difference(returned,held)==0.0,"waiting preserves manually held field",difference(returned,held))
    await physics_frame
    var ray := PhysicsRayQueryParameters3D.create(Vector3(0,2,0),Vector3(0,0,0))
    var hit := study.get_world_3d().direct_space_state.intersect_ray(ray)
    check(not hit.is_empty() and hit.collider == study.bridge,"physics ray meets separate fixed bridge")
    if not hit.is_empty(): note("bridge_hit_height",hit.position.y)
    finish()
