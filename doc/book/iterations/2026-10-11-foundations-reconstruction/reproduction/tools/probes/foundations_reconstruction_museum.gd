extends "res://tools/probes/transformation_encounters.gd"
const BASE="res://doc/book/iterations/2026-10-11-foundations-reconstruction/learner/"
const KEYS={"Russell_Paradox":"russell","Godel_Incompleteness":"godel","Escher_Impossible":"escher","Brouwer_Intuitionism":"brouwer","Florensky_Paraconsistent":"florensky","Crisis_Synthesis":"synthesis"}
const ORIGINAL={"russell":"/russell_paradox_workbench.gd","godel":"/godel_sentence_machine.gd","escher":"/escher_staircase.gd","brouwer":"/brouwer_choice_sequence.gd","florensky":"/both_true_gate.gd","synthesis":"/sentence_authority.gd"}
const JOURNAL="res://doc/book/iterations/2026-10-11-foundations-reconstruction/native-synthetic-trials.json"

func placeable(at:Transform3D, exclude:Array[RID]=[]) -> bool:
    for dx:float in [-0.5,0,0.5]:
        for dz:float in [1.25,1.55,1.85]:
            var p:=hall.to_global(at*Vector3(dx,0,dz))
            var hit:=floor_at(p)
            if hit.is_empty() or absf(hit.position.y-p.y)>0.04:return false
    var shape:=BoxShape3D.new();shape.size=Vector3(2.96,2.25,3.1)
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape
    query.transform=hall.global_transform*at*Transform3D(Basis.IDENTITY,Vector3(0,1.175,0.55))
    query.collision_mask=1
    var player:=museum.get_node_or_null("Walker") as CollisionObject3D
    if player!=null:exclude.append(player.get_rid())
    query.exclude=exclude
    var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
    if not observations.has("supported_bays"):observations["supported_bays"]=[]
    if observations.supported_bays.size()<12:
        var bodies:Array=[]
        for hit in hits:bodies.append(str(hit.collider.get_path()))
        observations.supported_bays.append({"at":xyz(at.origin),"yaw":at.basis.get_euler().y,"bodies":bodies})
    return hits.is_empty()

func landing_checks() -> void:
    var start:=Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-start<30000:
        museum.call("_drain_stamps");museum.call("_drain_cartridge_nodes");await tick()
    check("hall artifacts finished loading",museum.get("_stamp_queue").is_empty() and museum.get("_cartridge_pending_nodes").is_empty())
    var key:String=KEYS[map_id]
    var original:=find_scene(ORIGINAL[key])
    check("existing teaching artifact retained",original!=null)
    if original==null:return
    observations["original_local"] = xyz(hall.to_local(original.global_position))
    observations["floor_samples"] = []
    for at:Vector3 in [Vector3(5,0,10),Vector3(5,1,10),Vector3(5,2,10)]:
        var ray:=PhysicsRayQueryParameters3D.create(hall.to_global(at+Vector3.UP*5),hall.to_global(at+Vector3.DOWN*5),1)
        var hit:=hall.get_world_3d().direct_space_state.intersect_ray(ray)
        observations.floor_samples.append({"at":xyz(at),"hit":xyz(hall.to_local(hit.position)) if not hit.is_empty() else [],"body":str(hit.collider.get_path()) if not hit.is_empty() else ""})
    await snapshot("existing",original.global_position+Vector3(3,5,6),original.global_position+Vector3.UP,65)
    var launcher=load("res://doc/book/studies/foundations-lineage/"+key+"_museum.gd")
    if key=="godel" and FileAccess.file_exists(JOURNAL):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(JOURNAL))
    var study=launcher.mount(hall,load(BASE+key+"_study.gd"),{"journal_path":JOURNAL}) if key in ["godel","synthesis"] else launcher.mount(hall,load(BASE+key+"_study.gd"))
    var t:Transform3D=study.transform
    var bodies:Array[RID]=[]
    for body in study.find_children("*","CollisionObject3D",true,false):bodies.append(body.get_rid())
    check("supplied placement has supported clear approach",placeable(t,bodies))
    observations["mount"]={"position":xyz(t.origin),"yaw":study.rotation.y}
    var packed=load("res://doc/book/studies/foundations-lineage/"+key+".tscn").instantiate()
    check("F6 scene references supplied launcher",packed.get_script()==launcher)
    packed.free()
    await tick()
    check("printed working copy uses actual hall",study.get_parent()==hall and study.buttons.size()==(7 if key=="godel" else 4))
    await snapshot("opening",study.to_global(Vector3(0,2.25,3.3)),study.to_global(Vector3(0,1.45,0)),60)
    await snapshot("hall",hall.to_global(t.origin+Vector3(0,14,12)),hall.to_global(t.origin),68)
    var id=study.point.get_instance_id()
    match key:
        "russell":
            study.buttons[1].pressed.emit()
            check("unrestricted IN visibly fails",not study.result.agrees and study.assumed)
            study.buttons[2].pressed.emit();study.buttons[0].pressed.emit()
            check("restricted OUT visibly agrees",study.result.agrees and study.result.members==[0,1,2,3])
            check("student cases match installed workbench",original.evaluate_membership(false,true).agrees==study.result.agrees and not original.evaluate_membership(true,false).agrees)
        "godel":
            check("opening miss is labelled bounded",study.result.status=="NOT FOUND WITHIN BUDGET")
            study.buttons[5].pressed.emit()
            check("native prediction precedes next search",study.pending.budget==3 and not study.pending.prediction and study.budget==2)
            study.buttons[6].pressed.emit()
            check("larger budget finds actual checked derivation",study.model.verify(study.result.proof,study.target))
            var saved=study.archive.read(JOURNAL)
            check("native trial preserves mistaken prediction on disk",saved.ok and saved.entries.size()==1 and saved.entries[0].accepted and not saved.entries[0].prediction_matched)
            observations["saved_synthetic_experiment"]=saved.entries[0]
        "escher":
            for i in 4:study.buttons[0].pressed.emit()
            check("closed route returns sphere and measured height",study.model.index==0 and absf(study.model.up-study.model.down)<0.00001)
            study.buttons[1].pressed.emit()
            for i in 4:study.buttons[0].pressed.emit()
            check("open route stops at cut end",study.model.index==3)
        "brouwer":
            study.buttons[0].pressed.emit();study.buttons[1].pressed.emit()
            check("choice signals create actual witness",study.model.first_one()==1)
            study.buttons[2].pressed.emit()
            check("diagonal view retains chosen prefix",study.show_diagonal and study.model.terms==[0,1])
        "florensky":
            study.buttons[0].pressed.emit();study.buttons[1].pressed.emit()
            check("native controls retain conflict without Q",study.model.p==Vector2i(1,1) and study.model.q==Vector2i.ZERO)
            original.clear_reports();original.toggle_report(true);original.toggle_report(false)
            check("installed gate likewise keeps Q unsupported",original.report_state().P and original.report_state().not_P and not original.report_state().Q)
        "synthesis":
            check("separate hall reads actual earlier native experiment",study.model.cards.size()==7 and study.model.current().get("student_record",false))
            var card=study.model.current()
            check("saved target budget and failed prediction reach final display",card.get("student_record",false) and card.evidence.target=="SSS0" and card.evidence.budget==3 and not card.evidence.prediction and card.evidence.accepted)
            var journal_bytes=FileAccess.get_file_as_string(JOURNAL)
            var kept=study.model.cards.duplicate(true)
            for i in [1,2,3]:study.buttons[i].pressed.emit()
            check("native presentation changes keep evidence",study.model.cards==kept)
            check("Synthesis never rewrites source journal",FileAccess.get_file_as_string(JOURNAL)==journal_bytes)
            check("three labels share one selected sentence",study.small.text==study.wall.text and study.model.current().sentence==study.wall.text)
    for i in 5:await tick()
    check("sphere retains identity and placement across physics",study.point.get_instance_id()==id and study.point.position.distance_to(study.point_home)<0.001)
    await snapshot("result",study.to_global(Vector3(0,2.25,3.3)),study.to_global(Vector3(0,1.45,0)),60)
    observations["scope"]="Actual isolated museum; printed working copy and synthetic control signals; measured placement candidate. No permanent artifact replacement, human reach or full walking route claim."

func finish() -> void:
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
    print("FOUNDATIONS MUSEUM ",map_id," ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
