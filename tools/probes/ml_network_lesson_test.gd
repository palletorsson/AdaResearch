extends SceneTree
const FOLDER="res://doc/book/iterations/2026-10-11-networks-what-a-weight-keeps/"
var checks:Array=[]
var failures:Array=[]
var evidence:Dictionary={}
func _initialize() -> void: run.call_deferred()
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok})
    if not ok: failures.append(label)
    print("NETWORK ","PASS " if ok else "FAIL ",label)
func near(a:float,b:float,tol:float=0.00001) -> bool: return absf(a-b)<tol
func press(host,index:int) -> void:
    var button=host.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
    button.button_pressed.emit(button)
func numeric(m,index:int,x:Vector2,target:int) -> float:
    var old:float=m.weights[index];var h:=0.00001
    m.weights[index]=old+h;var high:float=m.example_loss(x,target)
    m.weights[index]=old-h;var low:float=m.example_loss(x,target)
    m.weights[index]=old
    return (high-low)/(2*h)
func run() -> void:
    var Model=load(FOLDER+"learner/printed/tiny_network.gd")
    var m=Model.new();var start:PackedFloat64Array=m.weights.duplicate()
    var data:PackedVector2Array=m.data.duplicate();var labels:PackedInt32Array=m.labels.duplicate()
    var f:Dictionary=m.forward(Vector2(-0.8,-0.8))
    check("thirteen parameters and two input coordinates only",start.size()==13 and m.data.size()==4 and f.hidden.size()==3)
    check("independent forward oracle hidden activations",near(f.hidden[0],0.552519009259) and near(f.hidden[1],-0.579692864984) and near(f.hidden[2],-0.314922032938))
    check("independent forward oracle output",near(f.z,-0.138341128452) and near(f.p,0.465469771060))
    check("independent starting mean cross entropy",near(m.loss(),0.685269095589))
    m.labels=PackedInt32Array([1,0,0,1]);var alternate:Dictionary=m.forward(Vector2(-0.8,-0.8))
    check("forward does not receive or consult target labels",alternate==f and m.weights==start)
    m.labels=labels.duplicate()
    var largest_error:=0.0
    for state in 3:
        if state>0:
            for epoch in 30: m.train_epoch()
        for x in [Vector2(-0.8,-0.8),Vector2(0.3,-0.6),Vector2(0.8,0.8)]:
            for target in 2:
                var g:PackedFloat64Array=m.gradient(x,target)
                for p in 13:largest_error=maxf(largest_error,absf(g[p]-numeric(m,p,x,target)))
    check("all thirteen derivatives match central differences at eighteen cases",largest_error<0.000001)
    evidence["max_gradient_error"]=largest_error
    m.reset();var expected:=PackedFloat64Array();expected.resize(13)
    for p in 13:
        var g:=0.0
        for i in 4:g+=numeric(m,p,m.data[i],m.labels[i])/4
        expected[p]=start[p]-0.5*g
    m.train_epoch();var epoch_error:=0.0
    for p in 13:epoch_error=maxf(epoch_error,absf(m.weights[p]-expected[p]))
    check("one batch uses old weights for all rows before one update",epoch_error<0.000001 and m.epoch==1)
    check("readout change equals actual first parameter difference",near(m.last_change,m.weights[0]-start[0]))
    var retained:PackedFloat64Array=m.weights.duplicate();var previous_epoch:int=m.epoch
    m.check_fresh();m.forward(Vector2(0.2,-0.4))
    check("inference and fresh checks leave model and training data intact",m.weights==retained and m.epoch==previous_epoch and m.data==data and m.labels==labels)
    m.reset()
    var descending:=true;var old:float=m.loss()
    for i in 1000:
        m.train_epoch();var loss:float=m.loss();descending=descending and loss<=old+0.0000001;old=loss
    check("fixed fixture loss decreases over all thousand epochs",descending)
    check("independent fitted loss oracle",near(m.loss(),0.00503878768188))
    var result:Dictionary=m.check_fresh()
    check("four distinct check inputs stay outside training",m.fresh.size()==4 and not data.has(m.fresh[0]) and not data.has(m.fresh[1]) and not data.has(m.fresh[2]) and not data.has(m.fresh[3]))
    check("independent fresh loss and four correct predictions",near(result.loss,0.00740483920100) and result.correct==4)
    evidence["fitted"]={"training_loss":m.loss(),"check":result,"centre_score":m.forward(Vector2.ZERO).p}
    retained=m.weights.duplicate()
    check("epoch cap refuses further fitting",not m.train_epoch() and m.weights==retained and m.epoch==1000)
    m.flip_labels()
    check("FLIP resets weights and reverses labels without editing inputs",m.flipped and m.weights==start and m.labels==PackedInt32Array([1,0,0,1]) and m.epoch==0 and m.data==data)
    for i in 1000:m.train_epoch()
    result=m.check_fresh()
    check("changed target convention is actually learned",result.correct==4 and result.loss<0.03)
    m.reset();check("RESET keeps changed labels",m.flipped and m.labels==PackedInt32Array([1,0,0,1]) and m.weights==start)
    m.flip_labels();check("second FLIP restores original convention",not m.flipped and m.labels==labels)
    m.labels[0]=1
    for i in 1000:m.train_epoch()
    var fits:=true
    for i in 4:fits=fits and int(m.forward(data[i]).p>=0.5)==m.labels[i]
    check("independent exercise changing one label fits the changed data",fits and m.loss()<0.03)
    m.reset();m.weights[12]=1000
    check("stable positive logit does not overflow",is_finite(m.example_loss(Vector2.ZERO,0)) and m.forward(Vector2.ZERO).p==1)
    m.weights[12]=-1000
    check("stable negative logit does not overflow",is_finite(m.example_loss(Vector2.ZERO,1)) and m.forward(Vector2.ZERO).p==0)
    var host=load(FOLDER+"learner/printed/network_study.gd").new();root.add_child(host)
    await process_frame;host.set_process(false)
    var point=host.point;var identity:int=point.get_instance_id()
    check("host starts paused with one inherited PointBody",not host.running and host.model.epoch==0 and not point.held())
    press(host,0);check("actual STEP signal fits one full epoch",host.model.epoch==1 and host.model.weights!=start)
    retained=host.model.weights.duplicate();press(host,3)
    check("EXAMPLE changes input while keeping fitted parameters",host.probe==data[1] and host.model.weights==retained)
    for i in 5:await physics_frame;await process_frame
    check("unheld sphere remains at selected input across physics frames",point.position.distance_to(host.place(host.probe))<0.0001)
    press(host,4);check("CHECK signal measures without fitting",not host.check_result.is_empty() and host.model.epoch==1 and host.model.weights==retained)
    press(host,1);host._process(0.1)
    check("TRAIN adds ten epochs and clears stale check",host.running and host.model.epoch==11 and host.check_result.is_empty())
    press(host,1);check("second TRAIN pauses",not host.running)
    host.position=Vector3(4,0,8);host.rotation.y=PI/2
    var pointer:=Node3D.new();root.add_child(pointer);point.on_desktop_grab(pointer)
    retained=host.model.weights.duplicate();host.running=true
    point.global_position=host.to_global(Vector3(-0.816,2,-0.312));host._process(0.1)
    check("hand samples local coordinates under rotated translated hall",host.probe.distance_to(Vector2(0.3,-0.4))<0.0001)
    check("holding pauses training without editing weights or data",not host.running and host.model.weights==retained and host.model.data==data)
    var selected:Vector2=host.probe
    for i in 6:press(host,i)
    check("every control is ignored while held",host.probe==selected and host.model.weights==retained and host.model.epoch==11 and not host.model.flipped)
    point.on_desktop_drop(pointer);host._process(0.1)
    for i in 5:await physics_frame;await process_frame
    check("release retains input and restores display height",host.probe==selected and point.position.distance_to(host.place(selected))<0.0001)
    point.on_desktop_grab(pointer);point.global_position=host.to_global(Vector3(99,8,-99));host._process(0.1)
    point.on_desktop_drop(pointer);host._process(0.1)
    check("out of range hand coordinates explicitly clamp",host.probe==Vector2(1,-1))
    press(host,5);check("FLIP button changes targets and resets",host.model.flipped and host.model.epoch==0 and host.model.weights==start)
    press(host,0);press(host,2)
    check("RESET button keeps labels input and same sphere",host.model.flipped and host.model.weights==start and host.probe==Vector2(1,-1) and host.point.get_instance_id()==identity)
    host.queue_free();pointer.queue_free();await process_frame
    # Production audit is separate from the printed reconstruction.
    var exhibit=load("res://algorithms/machinelearning/neuralnetworkvisualization/neural_network_visualization.tscn").instantiate()
    root.add_child(exhibit);exhibit._stop_training()
    var leaked:=true
    for i in exhibit.training_data.size():
        leaked=leaked and exhibit.training_data[i][2]==exhibit.target_data[i][1] and exhibit.training_data[i][3]==exhibit.target_data[i][0]
    check("source audit confirms legacy extra inputs encode targets reversed",leaked)
    var legacy=exhibit.weights.duplicate(true);var biases=exhibit.biases.duplicate(true)
    exhibit.test_network([0.2,0.3,0.4,0.5])
    check("legacy input probe changes activations without fitting weights",exhibit.weights==legacy and exhibit.biases==biases)
    exhibit.queue_free();await process_frame
    FileAccess.open(FOLDER+"tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Author-informed exact-print reconstruction; numerical oracles, synthetic data, actual button signals and desktop hand adapter. Human VR untested."},"  "))
    quit(0 if failures.is_empty() else 1)
