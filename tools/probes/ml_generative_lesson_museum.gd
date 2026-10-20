extends "res://tools/probes/transformation_encounters.gd"
const Fixture=preload("res://tools/probes/movement_fixture.gd")

func body_clear(p: Vector3) -> bool:
    var shape:=CapsuleShape3D.new();shape.radius=0.25;shape.height=1.75
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=shape;query.transform.origin=p+Vector3.UP*0.94;query.collision_mask=1
    var walker:=museum.get_node_or_null("Walker") as CollisionObject3D
    if walker!=null:query.exclude=[walker.get_rid()]
    return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func landing_checks() -> void:
    var diagram:=find_scene("/GenerativeAdversarialNetworksGANs_VR.gd")
    check("existing adversarial diagram remains",diagram!=null)
    var printed=load("res://doc/book/iterations/2026-10-11-generative-a-phrase-varied/learner/printed/generative_study.gd")
    var launcher=load("res://doc/book/studies/ml-lineage/generative_museum.gd")
    var study:Node3D=launcher.mount(hall,printed)
    await tick();study.set_process(false)
    check("printed extension mounted in actual Generative hall",study.get_parent()==hall)
    check("arrival has no invented teaching or generated paths",study.one.examples.is_empty() and not study.generator.trained and study.replay_time<0)
    var floor_ok:=true;var clear:=true
    for x:float in [-0.6,0.0,0.6]:
        for z:float in [1.3,1.8,2.3]:
            var p:=study.to_global(Vector3(x,0,z))
            floor_ok=floor_ok and not floor_at(p).is_empty()
            clear=clear and body_clear(p)
    check("teaching stance supported by actual floor",floor_ok)
    check("standing player capsule clears teaching stance",clear)
    await snapshot("empty",study.to_global(Vector3(0.4,1.8,3.3)),study.to_global(Vector3(0,1.65,-0.2)),62)
    await snapshot("hall",hall.to_global(Vector3(9,23,30)),hall.to_global(Vector3(9,0,13)),65)
    var point_id:int=study.sphere.get_instance_id()
    for v in 3:
        var take:=Fixture.take(0)
        for row:Dictionary in take:
            var d:float=(v-1)*0.12*(0.6+sin(PI*float(row.t)/4))
            row.x[1]+=d;row.x[4]+=2*d
        study.one.add_example(take)
    var before:Dictionary=study.one.snapshot()
    study.command("FIT")
    check("model fitted from explicit synthetic complete performances",study.generator.trained)
    study.command("MEAN");study.replay_time=1.5;study.draw_phrase();study.refresh()
    await snapshot("mean",study.to_global(Vector3(0.4,1.8,3.3)),study.to_global(Vector3(0,1.7,-0.2)),62)
    study.sample_seed=72;study.amount=1;study.command("DRAW")
    study.replay_time=1.5;study.draw_phrase();study.refresh()
    check("two airborne paths retain same PointBody",study.rods[0].visible and study.rods[40].visible and study.sphere.get_instance_id()==point_id)
    check("generated result does not overwrite teaching",study.one.snapshot()==before)
    var initial:Vector3=study.sphere.position
    await snapshot("generated",study.to_global(Vector3(0.4,1.8,3.3)),study.to_global(Vector3(0,1.7,-0.2)),62)
    study.replay_time=3;study.draw_phrase()
    check("sphere moves along paired generated path",initial.distance_to(study.sphere.position)>0.01)
    study.command("STOP")
    check("STOP returns point and hides paths",study.replay_time<0 and not study.rods[0].visible)
    observations["scope"]="Actual Generative hall with exact-print student code. Empty arrival followed by synthetic teaching for captures. No human/headset trial."


func finish() -> void:
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "))
    print("GENERATIVE MUSEUM ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
