extends SceneTree
const FOLDER="res://doc/book/iterations/2026-10-11-classification-a-group-without-a-name/"
var checks:Array=[]
var failures:Array=[]
var evidence:Dictionary={}
var Model:Script
func _initialize() -> void: run.call_deferred()
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok})
    if not ok:failures.append(label)
    print("CLASSIFICATION ","PASS " if ok else "FAIL ",label)
func close(a:float,b:float,tol:float=0.0001) -> bool:return absf(a-b)<tol
func press(host,index:int) -> void:
    var button=host.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
    button.button_pressed.emit(button)
func fixture():
    var m=Model.new()
    m.k=2;m.data=PackedVector2Array([Vector2(-0.8,0),Vector2.ZERO,Vector2(0.8,0)])
    m.centres=PackedVector2Array([Vector2(-0.8,0),Vector2(0.8,0)])
    m.invalidate();return m
func run() -> void:
    Model=load(FOLDER+"learner/printed/cluster_model.gd")
    var m=fixture();var data:PackedVector2Array=m.data.duplicate()
    check("no group or scored result exists before assignment",m.groups.is_empty() and m.next_assignment)
    var initial:PackedVector2Array=m.centres.duplicate()
    check("mean before assignment is refused",not m.move_means() and m.centres==initial and m.rounds==0)
    check("first assignment succeeds",m.assign())
    check("independent midpoint fixture assigns tie to lower index",m.groups==PackedInt32Array([0,0,1]))
    check("initial squared-distance score is 0.64",close(m.score(),0.64))
    check("assignment keeps data and centres fixed",m.data==data and m.centres==initial)
    check("duplicate assignment is refused before mean",not m.assign())
    check("first mean update succeeds",m.move_means())
    check("mean matches independently calculated positions",m.centres[0].distance_to(Vector2(-0.4,0))<0.0001 and m.centres[1]==Vector2(0.8,0))
    check("post-mean SSE is 0.32 with old assignments retained",close(m.score(),0.32) and m.groups==PackedInt32Array([0,0,1]) and m.rounds==1)
    var moved:PackedVector2Array=m.centres.duplicate()
    check("duplicate mean is refused before assignment",not m.move_means() and m.centres==moved)
    m=fixture();m.data[1]=Vector2(0.2,0);m.assign();m.move_means()
    check("changed observation changes assignment and mean predictably",m.groups==PackedInt32Array([0,1,1]) and m.centres[0]==Vector2(-0.8,0) and m.centres[1].distance_to(Vector2(0.5,0))<0.0001 and close(m.score(),0.18))
    m=fixture();m.k=3;m.centres.append(Vector2(0,8));m.assign();m.move_means()
    check("empty centre is retained without division by zero",m.centres[2]==Vector2(0,8) and is_finite(m.score()))
    m=fixture();m.assign();m.move_centre(1,Vector2(12,-12))
    check("manual centre edit bounds input and invalidates assignments",m.centres[1]==Vector2(1,-1) and m.groups.is_empty() and m.next_assignment and m.rounds==0 and m.data==data)
    m=Model.new();var base:PackedVector2Array=m.data.duplicate()
    check("default is twelve authored observations and three centres",m.data.size()==12 and m.centres.size()==3 and m.k==3)
    var scores:Dictionary={}
    var descending:=true;var stationary:=true;var indices:=true;var means_valid:=true
    for d in 3:
        for k in range(2,5):
            m.set_data(d);m.reset(k);var observed:PackedVector2Array=m.data.duplicate();var last:=INF;var trail:Array=[]
            for round_index in 20:
                m.assign();descending=descending and m.score()<=last+0.0001;last=m.score();trail.append(last)
                for j in m.groups:indices=indices and j>=0 and j<k
                m.move_means();descending=descending and m.score()<=last+0.0001;last=m.score();trail.append(last)
                for j in k:
                    var sum:=Vector2.ZERO;var count:=0
                    for i in observed.size():
                        if m.groups[i]==j:sum+=observed[i];count+=1
                    if count>0:means_valid=means_valid and m.centres[j].distance_to(sum/count)<0.0001
                stationary=stationary and m.data==observed
            scores["%d/K%d"%[d,k]]=trail
    check("both phases keep SSE nonincreasing for all nine fixed cases",descending)
    check("all observations remain fixed through 180 complete rounds",stationary)
    check("every assigned index refers to a centre",indices)
    check("occupied centres equal group means across all fixtures",means_valid)
    evidence["sse_by_phase"]=scores
    m.set_data(1);check("rings contain twelve inner and twelve outer points",m.data.size()==24 and close(m.data[0].length(),0.35) and close(m.data[12].length(),0.85))
    m.set_data(2);check("grid has 25 regularly placed observations",m.data.size()==25 and m.data[0]==Vector2(-0.8,-0.8) and m.data[24]==Vector2(0.8,0.8))
    m.set_data(0);check("returning to blobs restores the identical data",m.data==base)
    m.reset(3);initial=m.centres.duplicate();m.assign();m.move_means();m.reset(3)
    check("RESET repeats start and clears state without replacing data",m.centres==initial and m.data==base and m.groups.is_empty() and m.rounds==0)
    m.reset(4);check("K changes available centres without changing observations",m.centres.size()==4 and m.data==base)
    var host=load(FOLDER+"learner/printed/cluster_study.gd").new();root.add_child(host)
    await process_frame;host.set_process(false)
    var point=host.point;var identity:int=point.get_instance_id()
    check("study starts with one carried point and an explicit unassigned readout",not point.held() and "unassigned" in host.readout.text and host.selected==0)
    press(host,1);check("MEAN button does not manufacture assignments",host.model.groups.is_empty() and host.model.rounds==0)
    var start:PackedVector2Array=host.model.centres.duplicate();press(host,0)
    check("actual ASSIGN signal sets groups without moving centres",host.model.groups.size()==12 and host.model.centres==start and not host.model.next_assignment)
    var colours:PackedInt32Array=host.model.groups.duplicate();press(host,1)
    check("actual MEAN signal moves centres while retaining shown groups",host.model.centres!=start and host.model.groups==colours and host.model.rounds==1)
    for frame in 5:await physics_frame;await process_frame
    check("unheld PointBody follows the updated centre across physics frames",point.position.distance_to(host.place(host.model.centres[host.selected],1.12))<0.0001)
    press(host,3)
    check("CENTRE changes selection and retains the PointBody instance",host.selected==1 and host.point.get_instance_id()==identity and point.position.distance_to(host.place(host.model.centres[1],1.12))<0.0001)
    host.position=Vector3(4,0,8);host.rotation.y=PI/2
    var pointer:=Node3D.new();root.add_child(pointer);point.on_desktop_grab(pointer)
    var still:PackedVector2Array=host.model.data.duplicate();var untouched:Vector2=host.model.centres[0]
    point.global_position=host.to_global(Vector3(0.375,2,-0.25));host._process(0.1)
    check("grab decodes local x z after hall rotation and translation",host.model.centres[1].distance_to(Vector2(0.3,-0.2))<0.0001)
    check("hand edit keeps observations and other centres but clears grouping",host.model.data==still and host.model.centres[0]==untouched and host.model.groups.is_empty() and host.model.rounds==0)
    var candidate:Vector2=host.model.centres[1];var position:Vector3=point.global_position
    press(host,2);press(host,3);press(host,4);press(host,7)
    check("all controls remain inactive while held",host.model.centres[1]==candidate and host.model.k==3 and host.selected==1 and host.model.dataset==0 and point.global_position==position)
    point.on_desktop_drop(pointer);host._process(0.1)
    check("release returns sphere to display height without moving centre",point.position.distance_to(host.place(candidate,1.12))<0.0001 and host.model.centres[1]==candidate)
    point.on_desktop_grab(pointer);point.global_position=host.to_global(Vector3(99,8,-99));host._process(0.1)
    point.on_desktop_drop(pointer);host._process(0.1)
    check("out of range hand input is explicitly bounded",host.model.centres[1]==Vector2(1,-1))
    press(host,6);press(host,0);press(host,1);press(host,2)
    check("K and RESET buttons retain data and selected count",host.model.k==4 and host.model.data==still and host.model.groups.is_empty() and host.model.rounds==0)
    press(host,7);check("DATA button selects fixed rings and retains chosen K",host.model.dataset==1 and host.model.data.size()==24 and host.model.k==4)
    press(host,7);press(host,7);press(host,4)
    check("return to BLOBS and K2 preserves sphere and original data",host.model.data==still and host.model.k==2 and host.point.get_instance_id()==identity)
    host.queue_free();pointer.queue_free();await process_frame
    # Production comparison is separate from the student's extracted construction.
    var exhibit=load("res://algorithms/machinelearning/kmeansclustering/enhanced_kmeans.tscn").instantiate()
    root.add_child(exhibit);exhibit.set_process(false);exhibit.animate_clustering=false
    exhibit._lesson_reset();var original:Array=[];var old_centres:Array=[]
    for p in exhibit.data_points:original.append(p.position)
    for c in exhibit.centroids:old_centres.append(c.position)
    var expected:=0.0
    for p in original:
        var nearest:=INF
        for c in old_centres:nearest=minf(nearest,p.distance_to(c))
        expected+=nearest
    exhibit.perform_clustering_step()
    check("production Total Distance sums unsquared distances before mean update",close(exhibit.total_distance,expected,0.001))
    var unchanged:=true
    for i in original.size():unchanged=unchanged and exhibit.data_points[i].position==original[i]
    check("production step leaves observations in place",unchanged)
    exhibit._lesson_reset();var repeats:=true
    for i in original.size():repeats=repeats and exhibit.data_points[i].position==original[i]
    for i in old_centres.size():repeats=repeats and exhibit.centroids[i].position==old_centres[i]
    check("production RESET repeats the same sample and centres",repeats)
    evidence["original_readout"]={"expected_pre_update_unsquared":expected,"points":original.size(),"centres":old_centres.size()}
    exhibit.queue_free();await process_frame
    FileAccess.open(FOLDER+"tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Author-informed exact-print reconstruction; synthetic fixtures and desktop hand adapter in Godot. Human VR untested."},"  "))
    quit(0 if failures.is_empty() else 1)
