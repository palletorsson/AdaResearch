extends SceneTree
const BASE="res://doc/book/iterations/2026-10-11-foundations-reconstruction/learner/"
const OUT="res://doc/book/iterations/2026-10-11-foundations-reconstruction/"
var checks:Array=[]
var failures:Array=[]
const JOURNAL=OUT+"synthetic-trials.json"

func _initialize() -> void: run.call_deferred()
func check(name:String,ok:bool) -> void:
    checks.append({"name":name,"passed":ok})
    if not ok:failures.append(name)
    print("FOUNDATIONS ","PASS " if ok else "FAIL ",name)

func frames(n:int=4) -> void:
    for i in n:await physics_frame;await process_frame

func run() -> void:
    await journal_checks()
    var membership=load(BASE+"membership.gd").new()
    check("Russell: two unrestricted cases both contradict",not membership.test(false,false).agrees and not membership.test(true,false).agrees)
    for n in range(7):
        var result=membership.test(false,true,n)
        check("Russell: ordinal %d separation and outside result"%n,result.members==range(n) and result.agrees and not result.domain_contains_result and not membership.test(true,true,n).agrees)
    check("Russell: invalid domain refused",not membership.test(false,true,-1).valid and not membership.test(false,true,7).valid)
    var proof=load(BASE+"derivation.gd").new()
    check("Godel: axiom examined at zero budget",proof.search("0",0).status=="CHECKED DERIVATION" and proof.search("S0",0).examined==1)
    check("Godel: five steps miss, six produce checkable witness",proof.search("SSSSSS0",5).status=="NOT FOUND WITHIN BUDGET" and proof.verify(proof.search("SSSSSS0",6).proof,"SSSSSS0"))
    check("Godel: missing intermediate inference refused",not proof.verify(["0","SS0","SSS0"],"SSS0"))
    check("Godel: wrong axiom and wrong endpoint refused",not proof.verify(["S0","SS0"],"SS0") and not proof.verify(["0","S0"],"SS0"))
    check("Godel: malformed input is not a search miss",proof.search("00",5).status=="INVALID INPUT" and proof.search("X",5).status=="INVALID INPUT" and proof.search("S0",-1).status=="INVALID INPUT")
    var family_ok:=true
    for n in range(12):
        var target="S".repeat(n)+"0"
        family_ok=family_ok and proof.verify(proof.search(target,n).proof,target)
        if n>0:family_ok=family_ok and proof.search(target,n-1).status=="NOT FOUND WITHIN BUDGET"
    check("Godel: all twelve boundary budgets match predicted chain lengths",family_ok)
    var route=load(BASE+"height_route.gd").new()
    for i in 3:route.step()
    check("Escher: first three gains total 0.6m",absf(route.up-0.6)<0.00001 and route.down==0)
    route.step()
    check("Escher: closing drop is negative0.6 and returns to zero",absf(route.last+0.6)<0.00001 and route.index==0 and absf(route.up-route.down)<0.00001)
    route.closed=false;route.reset()
    for i in 3:route.step()
    check("Escher: open run refuses wrapping",not route.step() and route.index==3)
    route.closed=true
    var changed:=Transform3D(Basis(Vector3.RIGHT,PI/2).scaled(Vector3(1,2,3)),Vector3(7,9,-4))
    route.reset()
    for i in 4:route.step(changed)
    check("Escher: rotated scaled translated closed route cancels",absf(route.up-route.down)<0.00001 and absf(route.closure(changed))<0.00001)
    check("Escher: changing world up changes individual gains",absf(route.up-0.6)>0.1)
    var witness=load(BASE+"witness.gd").new()
    for i in 8:witness.append_bit(0)
    check("Brouwer: finite absence and open continuation separated",not witness.inspect_prefix().finite_contains_one and witness.inspect_prefix().future_claim=="NO WITNESS YET")
    var kept=witness.terms.duplicate()
    check("Brouwer: full or invalid writes leave record unchanged",not witness.append_bit(1) and not witness.append_bit(2) and witness.terms==kept)
    witness.terms.clear()
    for bit in [0,0,0,1]:witness.append_bit(bit)
    check("Brouwer: fourth bit gives index3 witness",witness.inspect_prefix().witness_index==3 and witness.inspect_prefix().future_claim=="WITNESSED")
    var rows:Array=[[0,0,1,1],[1,0,1,0],[0,1,1,0],[1,1,0,1]]
    var original=rows.duplicate(true)
    var diagonal=witness.diagonal(rows)
    check("Brouwer: exact diagonal1100 without changing rows",diagonal.valid and diagonal.bits==[1,1,0,0] and rows==original)
    var differs:=true
    for i in 4:differs=differs and diagonal.bits[i]!=rows[i][i]
    check("Brouwer: witness differs at named position in every row",differs)
    for i in 4:rows[i][i]=1-rows[i][i]
    check("Brouwer: reversing diagonal reverses witness",witness.diagonal(rows).bits==[0,0,1,1])
    check("Brouwer: empty ragged and nonbinary tables refused",not witness.diagonal([]).valid and not witness.diagonal([[1],[0,1]]).valid and not witness.diagonal([[2]]).valid)
    var reports=load(BASE+"reports.gd").new()
    var values=[Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(0,1)]
    # Rows/columns T,B,N,F. Independent finite truth-table oracle.
    var and_table=[[0,1,2,3],[1,1,3,3],[2,3,2,3],[3,3,3,3]]
    var or_table=[[0,0,0,0],[0,1,0,1],[0,0,2,2],[0,1,2,3]]
    var tables:=true
    var laws:=true
    for i in 4:
        var a:Vector2i=values[i]
        laws=laws and reports.neg(reports.neg(a))==a
        for j in 4:
            var b:Vector2i=values[j]
            tables=tables and reports.both(a,b)==values[and_table[i][j]] and reports.either(a,b)==values[or_table[i][j]]
            laws=laws and reports.neg(reports.both(a,b))==reports.either(reports.neg(a),reports.neg(b))
            laws=laws and reports.neg(reports.either(a,b))==reports.both(reports.neg(a),reports.neg(b))
            if reports.supported(reports.both(a,b)):laws=laws and reports.supported(a) and reports.supported(b)
    check("Florensky: all32 connective entries match independent tables",tables)
    check("Florensky: negation DeMorgan conjunction elimination",laws)
    var counter=reports.explosion_counterexample()
    check("Florensky: concrete nonexplosion countermodel",counter.found and counter.p==Vector2i(1,1) and counter.q==Vector2i(0,0))
    var record=load(BASE+"claim_record.gd").new()
    var cards=record.cards.duplicate(true)
    record.large=true;record.advance(0.6)
    check("Synthesis: one word interval advances one word",record.word()=="ANSWER")
    record.paused=true;var time=record.elapsed;record.advance(12)
    check("Synthesis: held rhythm retains its word",record.elapsed==time)
    record.pace();record.paused=false;record.advance(120);record.next()
    var copy=record.current();copy.evidence.proof.clear()
    check("Synthesis: display and returned copy cannot mutate evidence",record.cards==cards)
    check("Synthesis: bounded miss never renamed unprovable",record.current().sentence=="NO PROOF WAS FOUND WITHIN TWO STEPS" and record.current().evidence.status=="NOT FOUND WITHIN BUDGET")
    check("Synthesis: AI proposal explicitly lacks verifier",record.cards[-1].evidence=="No verification procedure attached")
    for key in ["russell","godel","escher","brouwer","florensky","synthesis"]:
        var scene=load(BASE+key+"_study.gd").new()
        if key in ["godel","synthesis"]:scene.journal_path=OUT+"synthetic-controls.json"
        scene.position=Vector3(3,2,-4);scene.rotation.y=0.8
        root.add_child(scene);await frames()
        check(key+": complete printed scene initializes its own nodes",scene.buttons.size()==(7 if key=="godel" else 4) and scene.readout!=null and scene.point!=null)
        var id=scene.point.get_instance_id()
        for button in scene.buttons:button.pressed.emit()
        await frames()
        check(key+": real button signals retain carried sphere",scene.point.get_instance_id()==id and scene.point.position.distance_to(scene.point_home)<0.001)
        if key=="russell":
            var pointer:=Node3D.new();root.add_child(pointer)
            scene.point.on_desktop_grab(pointer)
            scene.point.global_position=scene.to_global(Vector3(0.8,1.3,0))
            scene._process(0.01)
            scene.point.on_desktop_drop(pointer)
            # Even an intervening physics update must not lose the held-side record.
            scene._physics_process(0.02);scene._process(0.01);await frames()
            check("Russell: transformed hand choice survives intervening physics",scene.assumed and scene.point.get_instance_id()==id)
            pointer.free()
        if key=="escher":
            scene.model.closed=true;scene.reset()
            for i in 4:scene.buttons[0].pressed.emit()
            await frames()
            check("Escher: displayed sphere returns with measured route",scene.model.index==0 and absf(scene.model.up-scene.model.down)<0.0001 and scene.point.position.distance_to(scene.point_home)<0.001)
        if key=="brouwer":
            scene.reset();scene.buttons[1].pressed.emit()
            check("Brouwer: actual1 signal supplies first witness",scene.model.first_one()==0)
        if key=="florensky":
            scene.reset();scene.buttons[0].pressed.emit();scene.buttons[1].pressed.emit()
            check("Florensky: adding opposed reports leaves Q untouched",scene.model.p==Vector2i(1,1) and scene.model.q==Vector2i.ZERO)
        scene.free();await frames(1)
    FileAccess.open(OUT+"ghost-results.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Author-operated exact-print reconstruction; synthetic hand adapter; no blind reader or human headset test."},"  "))
    quit(0 if failures.is_empty() else 1)

func journal_checks() -> void:
    for path in [JOURNAL,OUT+"synthetic-controls.json",OUT+"synthetic-missing.json"]:
        if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    var archive=load(BASE+"trial_archive.gd").new()
    var proof=load(BASE+"derivation.gd").new()
    var missed=archive.capture(proof,"SSS0",3,false,false)
    var predicted=archive.capture(proof,"SSS0",3,false,true)
    check("Journal: opposite predictions cannot affect computation",missed.candidate==predicted.candidate and missed.search_result==predicted.search_result and missed.accepted==predicted.accepted and not missed.prediction_matched and predicted.prediction_matched)
    check("Journal: complete source identity and explicit model version",missed.model_sha256==FileAccess.get_sha256(BASE+"derivation.gd") and missed.model_id=="unary-derivation-v1")
    check("Journal: missing file has no invented entries",archive.read(JOURNAL).ok and archive.read(JOURNAL).entries.is_empty())
    check("Journal: first write retains a failed prediction",archive.append(missed,JOURNAL).ok and not archive.read(JOURNAL).entries[0].prediction_matched)
    var damaged=archive.capture(proof,"SSS0",3,true,false)
    check("Journal: search result and damaged candidate are distinct",damaged.search_result.status=="CHECKED DERIVATION" and damaged.search_result.proof==["0","S0","SS0","SSS0"] and damaged.candidate==["0","SS0","SSS0"] and not damaged.accepted)
    check("Journal: second append preserves the earlier record",archive.append(damaged,JOURNAL).ok and archive.read(JOURNAL).entries.size()==2 and archive.read(JOURNAL).entries[0]==missed)
    var new_reader=load(BASE+"trial_archive.gd").new()
    check("Journal: fresh reader restores both original records",new_reader.read(JOURNAL).entries==[missed,damaged])
    var invalid=missed.duplicate(true);invalid.erase("prediction")
    var bytes=FileAccess.get_file_as_string(JOURNAL)
    check("Journal: invalid append leaves prior bytes intact",not archive.append(invalid,JOURNAL).ok and FileAccess.get_file_as_string(JOURNAL)==bytes)
    var corrupt=OUT+"synthetic-corrupt.json"
    var file=FileAccess.open(corrupt,FileAccess.WRITE);file.store_string("{broken");file.close()
    check("Journal: malformed JSON refused without overwrite",not archive.read(corrupt).ok and not archive.append(missed,corrupt).ok and FileAccess.get_file_as_string(corrupt)=="{broken")
    file=FileAccess.open(corrupt,FileAccess.WRITE);file.store_string('{"schema":2,"entries":[]}');file.close()
    check("Journal: unknown schema refused",not archive.read(corrupt).ok)
    var malformed=missed.duplicate(true);malformed.candidate=7
    file=FileAccess.open(corrupt,FileAccess.WRITE);file.store_string(JSON.stringify({"schema":1,"entries":[malformed]}));file.close()
    check("Journal: malformed entry refused",not archive.read(corrupt).ok)
    check("Journal: inaccessible destination reports failure",not archive.append(missed,OUT+"directory-that-does-not-exist/trial.json").ok)
    var record=load(BASE+"claim_record.gd").new()
    record.load_journal(JOURNAL)
    check("Synthesis: actual saved records selected after six reference cards",record.cards.size()==8 and record.index==6 and record.current().student_record and record.current().evidence==missed)
    var copy=record.current();copy.evidence.candidate.clear()
    record.large=true;record.pace();record.advance(3);record.next();record.next()
    check("Synthesis: display changes do not rewrite saved journal",record.cards[6].evidence==missed and FileAccess.get_file_as_string(JOURNAL)==bytes)
    record.load_journal(OUT+"synthetic-missing.json")
    check("Synthesis: missing journal leaves six clearly supplied cards",record.cards.size()==6 and record.journal_message.begins_with("No saved"))
    record.load_journal(corrupt)
    check("Synthesis: damaged journal yields a notice not personal cards",record.cards.size()==6 and record.journal_message.begins_with("Invalid"))
    var old=missed.duplicate(true);old.model_sha256="0".repeat(64)
    archive.append(old,JOURNAL);record.load_journal(JOURNAL)
    check("Synthesis: earlier source version stays visible without recomputation",not record.cards[-1].same_model_source and record.cards[-1].evidence==old)
    # Real UI flow, then destroy the source host before opening the destination.
    var host=load(BASE+"godel_study.gd").new();host.journal_path=OUT+"synthetic-controls.json"
    root.add_child(host);await frames()
    host.buttons[6].pressed.emit()
    check("Godel: TRY before prediction creates no file",not FileAccess.file_exists(host.journal_path))
    host.buttons[5].pressed.emit()
    check("Godel: prediction fixes next inputs before computation",host.pending.budget==3 and not host.pending.prediction and host.budget==2 and host.result.status=="NOT FOUND WITHIN BUDGET" and not FileAccess.file_exists(host.journal_path))
    host.buttons[6].pressed.emit()
    var saved=archive.read(host.journal_path).entries[0]
    check("Godel: button run keeps wrong prediction and accepted candidate",not saved.prediction and saved.accepted and not saved.prediction_matched and saved.budget==3)
    host.buttons[3].pressed.emit()
    check("Godel: reset retains recorded experiment",archive.read(host.journal_path).entries==[saved])
    host.buttons[4].pressed.emit();host.buttons[1].pressed.emit()
    check("Godel: setup edit invalidates pending prediction",host.pending.is_empty())
    host.buttons[6].pressed.emit()
    check("Godel: invalidated prediction cannot create another record",archive.read(host.journal_path).entries.size()==1)
    host.free();await frames(1)
    var destination=load(BASE+"synthesis_study.gd").new();destination.journal_path=OUT+"synthetic-controls.json"
    root.add_child(destination);await frames()
    check("Synthesis: new scene loads source scene's exact saved experiment",destination.model.current().evidence==saved and destination.wall.text=="MY PREDICTION FAILED IN THIS RUN" and destination.readout.text.contains("budget 3"))
    var kept_bytes=FileAccess.get_file_as_string(destination.journal_path)
    for button in destination.buttons:button.pressed.emit()
    check("Synthesis: native label controls preserve journal bytes",FileAccess.get_file_as_string(destination.journal_path)==kept_bytes)
    destination.free();await frames(1)
