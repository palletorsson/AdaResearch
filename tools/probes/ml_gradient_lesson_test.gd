extends SceneTree
const FOLDER="res://doc/book/iterations/2026-10-11-gradient-a-line-and-a-loss/"
var checks:Array=[]
var failures:Array=[]
var evidence:Dictionary={}
var Model:Script
func _initialize() -> void: run.call_deferred()
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok})
    if not ok:failures.append(label)
    print("GRADIENT ","PASS " if ok else "FAIL ",label)
func close(a:float,b:float,tol:float=0.001) -> bool:return absf(a-b)<tol
func press(host,index:int) -> void:
    var button=host.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
    button.button_pressed.emit(button)
func converge(model,count:int=1500) -> void:
    for i in count:
        if not model.step():break
func run() -> void:
    Model=load(FOLDER+"learner/printed/line_fit.gd")
    var m=Model.new()
    check("five clean observations fit the declared line",m.data.size()==5 and m.loss(Vector2(0.5,0.2))<0.00000001)
    check("independent initial mean squared error is 1.765",close(m.loss(Model.START),1.765))
    var g:Vector2=m.gradient(Model.START)
    check("central differences match analytical gradient",g.distance_to(Vector2(-1.5,1.6))<0.001)
    var coarse:Vector2=m.gradient(Vector2(0.2,-0.3),0.01)
    check("gradient at another candidate and step size matches oracle",coarse.distance_to(Vector2(-0.3,-1))<0.001)
    m.step()
    check("first slow update has predicted parameters",m.p.distance_to(Vector2(-0.85,0.84))<0.001 and m.steps==1)
    check("first slow update reduces the declared loss",m.loss(m.p)<1.765)
    converge(m)
    check("clean MSE converges to slope and intercept",m.p.distance_to(Vector2(0.5,0.2))<0.003)
    var held_p:Vector2=m.p;var held_steps:int=m.steps
    m.p=Vector2(0.5,0.2)
    check("zero gradient stops without adding a step",not m.step() and m.steps==held_steps and m.status=="SMALL GRADIENT")
    m=Model.new();var same:Vector2=m.p;var square:float=m.loss(same);m.robust=true
    check("switching score does not change parameters or data",m.p==same and m.data[4]==Vector2(1,0.7) and not close(m.loss(same),square))
    m.p=Vector2(0.5,0.7)
    check("Huber quadratic region has half-square scale",close(m.loss(m.p),0.125))
    m.p=Vector2(0.5,2.2)
    check("Huber linear region has unit residual slope",close(m.loss(m.p),1.5))
    m.reset();converge(m)
    check("clean Huber approaches the same fit",m.p.distance_to(Vector2(0.5,0.2))<0.003)
    var original:PackedVector2Array=m.data.duplicate()
    m.set_outlier(true)
    var unchanged:=true
    for i in 4:unchanged=unchanged and m.data[i]==original[i]
    check("outlier changes only the final observation and resets parameters",unchanged and m.data[4]==Vector2(1,4.7) and m.p==Model.START and m.steps==0)
    converge(m);var huber_p:Vector2=m.p
    check("outlier Huber fit matches piecewise analytic solution",huber_p.distance_to(Vector2(1.5,0.7))<0.008)
    m.robust=false;m.reset();converge(m);var mse_p:Vector2=m.p
    check("outlier MSE fit matches least squares solution",mse_p.distance_to(Vector2(2.1,1))<0.005)
    check("same observations yield distinct fitted parameters",mse_p.distance_to(huber_p)>0.5)
    evidence["outlier_fits"]={"mse":[mse_p.x,mse_p.y],"huber":[huber_p.x,huber_p.y]}
    m.set_outlier(false)
    check("removing the outlier restores exact original observations",m.data==original)
    m.rate=1.5;m.reset();var before:float=m.loss(m.p);m.step();var after:float=m.loss(m.p)
    check("large step stays in window but increases loss",m.steps==1 and after>before and absf(m.p.x)<=3 and absf(m.p.y)<=3)
    var p_before:Vector2=m.p
    check("next out-of-window step is refused without clamping",not m.step() and m.p==p_before and m.steps==1 and m.status=="STEP OUTSIDE WINDOW")
    evidence["large_step"]={"before":before,"after":after,"last_accepted":[m.p.x,m.p.y],"status":m.status}
    m.robust=true;m.rate=0.1;m.reset()
    check("reset retains chosen loss rate and data",m.robust and m.rate==0.1 and m.data==original and m.steps==0)
    var a=Model.new();var b=Model.new();a.set_outlier(true);b.set_outlier(true)
    for i in 100:a.step();b.step()
    check("unchanged problem and start repeat exactly",a.p==b.p and a.steps==b.steps)
    var host=load(FOLDER+"learner/printed/gradient_study.gd").new()
    root.add_child(host);await process_frame;host.set_process(false)
    var point=host.point;var point_id:int=point.get_instance_id()
    check("study starts paused with the carried point",not host.running and host.fit.p==Model.START and point.held()==false)
    var arrays:Array=host.terrain.mesh.surface_get_arrays(0)
    var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var valid:=true
    for v in vertices:
        var q:=Vector2((v.x-0.95)/0.26,v.z/0.26)
        valid=valid and absf(v.y-(0.9+host.fit.loss(q)*0.025))<0.0001
    check("complete mesh has 24 by 24 quads in triangles",vertices.size()==24*24*6)
    check("every sampled vertex uses the declared loss height",valid)
    check("point height uses same formula plus radius",point.position.distance_to(host.surface_position(host.fit.p)+Vector3.UP*0.085)<0.0001)
    press(host,0)
    check("real STEP signal changes parameters once",host.fit.steps==1 and not host.running)
    for frame in 5:await physics_frame;await process_frame
    check("paused point keeps updated parameters across physics frames",point.position.distance_to(host.surface_position(host.fit.p)+Vector3.UP*0.085)<0.0001)
    var model_p:Vector2=host.fit.p;var old_mesh=host.terrain.mesh
    press(host,4)
    check("HUBER signal keeps candidate and rebuilds surface",host.fit.robust and host.fit.p==model_p and host.terrain.mesh!=old_mesh)
    press(host,5);var contaminated:PackedVector2Array=host.fit.data.duplicate();press(host,2)
    check("RESET retains data and loss",host.fit.robust and host.fit.data==contaminated and host.fit.p==Model.START)
    press(host,3);press(host,6);press(host,1)
    host._process(0.075);check("half display interval makes no descent step",host.fit.steps==0)
    host._process(0.075);check("whole display interval makes one descent step",host.fit.steps==1 and host.running)
    press(host,1);check("RUN toggles to pause",not host.running)
    host.position=Vector3(5,0,7);host.rotation.y=PI/2
    var pointer:=Node3D.new();root.add_child(pointer)
    point.on_desktop_grab(pointer)
    point.global_position=host.to_global(Vector3(0.95+0.26*0.4,3,0.26*(-0.6)))
    host._process(0.2)
    check("held point decodes museum-local slope and intercept",host.fit.p.distance_to(Vector2(0.4,-0.6))<0.001 and not host.running)
    var hand_height:float=point.global_position.y
    press(host,2)
    check("controls do not move parameters while held",host.fit.p.distance_to(Vector2(0.4,-0.6))<0.001 and close(point.global_position.y,hand_height))
    point.on_desktop_drop(pointer);host._process(0.1)
    check("released point returns to scored height",point.global_position.distance_to(host.to_global(host.surface_position(host.fit.p)+Vector3.UP*0.085))<0.001)
    for frame in 5:await physics_frame;await process_frame
    check("released point stays at scored height after native physics",point.global_position.distance_to(host.to_global(host.surface_position(host.fit.p)+Vector3.UP*0.085))<0.001)
    point.on_desktop_grab(pointer);point.global_position=host.to_global(Vector3(20,1,-20));host._process(0.1)
    check("hand input is bounded explicitly",host.fit.p==Vector2(3,-3))
    point.on_desktop_drop(pointer);host._process(0.1)
    press(host,7);check("LARGE signal changes step size without replacing point",host.fit.rate==1.5 and host.point.get_instance_id()==point_id)
    host.queue_free();pointer.queue_free();await process_frame
    var original_exhibit=load("res://algorithms/machinelearning/loss_function_comparator/loss_function_comparator.tscn").instantiate()
    root.add_child(original_exhibit);original_exhibit.set_process(false)
    original_exhibit._on_outlier_changed(0.0);var clean=original_exhibit._data_y.duplicate()
    original_exhibit._on_outlier_changed(0.7);var changed=original_exhibit._data_y.duplicate()
    original_exhibit._on_outlier_changed(0.0)
    check("original comparator slider restores its fixed observations",original_exhibit._data_y==clean and clean!=changed)
    check("original comparator retains three separate surfaces",original_exhibit._terrains.size()==3 and original_exhibit._balls.size()==3)
    original_exhibit.queue_free();await process_frame
    FileAccess.open(FOLDER+"tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Author-informed exact-print reconstruction; synthetic data and desktop hand adapter in Godot. Human VR untested."},"  "))
    quit(0 if failures.is_empty() else 1)
