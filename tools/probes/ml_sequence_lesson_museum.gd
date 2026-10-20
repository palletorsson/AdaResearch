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
    var cell:=find_scene("/LSTMs_VR.gd")
    check("existing recurrent-cell artifact remains",cell!=null)
    var printed=load("res://doc/book/iterations/2026-10-11-memory-both-hands/learner/printed/sequence_study.gd")
    var launcher=load("res://doc/book/studies/ml-lineage/sequence_museum.gd")
    var study:Node3D=launcher.mount(hall,printed)
    await tick();study.set_process(false)
    check("printed extension mounted in actual Sequence Memory hall",study.get_parent()==hall and study.position.is_equal_approx(Vector3(4,0,17)))
    check("point, own panel and empty models present",study.sphere!=null and study.panel!=null and study.one.examples.is_empty() and not study.library.trained)
    var floor_ok:=true;var clear:=true
    for x:float in [-0.6,0.0,0.6]:
        for z:float in [1.3,1.8,2.3]:
            var p:=study.to_global(Vector3(x,0,z))
            floor_ok=floor_ok and not floor_at(p).is_empty()
            clear=clear and body_clear(p)
    check("teaching stance supported by native museum floor",floor_ok)
    check("teaching stance clears standing player capsule",clear)
    await snapshot("empty",study.to_global(Vector3(0.4,1.8,3.3)),study.to_global(Vector3(0,1.65,-0.2)),62)
    await snapshot("hall",hall.to_global(Vector3(9,21,28)),hall.to_global(Vector3(9,0,13)),64)
    var sphere_id:int=study.sphere.get_instance_id()
    for v in 3:study.one.add_example(Fixture.take(v))
    study.command("TRAIN")
    check("printed prototype fitted from complete synthetic takes",study.one.trained and study.mode=="TEST")
    study.command("REPLAY");study.replay_time=1.5;study.draw_phrase()
    study.message="SYNTHETIC PREVIEW / left + right paths";study.refresh()
    check("two airborne paths and same sphere shown",study.rods[0].visible and study.rods[40].visible and study.sphere.get_instance_id()==sphere_id)
    var first:Vector3=study.sphere.position
    await snapshot("replay",study.to_global(Vector3(0.4,1.8,3.3)),study.to_global(Vector3(0,1.7,-0.2)),62)
    study.replay_time=3;study.draw_phrase()
    check("sphere follows a changing two-hand midpoint",first.distance_to(study.sphere.position)>0.01)
    # Exercise comparison through the printed host, deliberately leaving B selected.
    study.command("A")
    for v in 3:study.library.add_example("A",Fixture.take(v))
    study.command("B")
    for v in 3:study.library.add_example("B",Fixture.take(v,true))
    study.command("TRAIN");study.command("TEST")
    var before:Dictionary=study.library.snapshot()
    study.capturing=true;study.phrase_time=-0.05;study.pending.clear();study.sample_time=0
    for row:Dictionary in Fixture.take(11):study.advance_phrase(0.05,row.x,true)
    study.draw_phrase();study.refresh()
    check("museum TEST identifies A without target selection or action",study.result.label=="A" and study.selected=="B" and study.replay_time<0 and study.library.snapshot()==before)
    await snapshot("test",study.to_global(Vector3(0.4,1.8,3.3)),study.to_global(Vector3(0,1.65,-0.2)),62)
    observations["scope"]="Printed extension of Perception code in native Sequence Memory room; synthetic fixture takes after empty capture. No human/headset performance claim."

func finish() -> void:
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "))
    print("SEQUENCE MUSEUM ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
