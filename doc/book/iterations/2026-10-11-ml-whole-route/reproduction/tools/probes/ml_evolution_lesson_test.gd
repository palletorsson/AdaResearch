extends SceneTree
const FOLDER="res://doc/book/iterations/2026-10-11-evolution-what-keeps-a-body/"
var Model:Script
var checks:Array=[]
var failures:Array=[]
var evidence:Dictionary={}

func _initialize() -> void: run.call_deferred()
func check(name:String,okay:bool) -> void:
    checks.append({"name":name,"passed":okay})
    if not okay: failures.append(name)
    print("EVOLUTION ","PASS " if okay else "FAIL ",name)

func fixture(renew:bool=false):
    var m=Model.new();m.reset(17,renew)
    m.bodies.clear();m.born=0;m.died=0;m.meals=0;m.ready_at.fill(INF)
    return m

func add(m,p:Vector2,energy:float=2.0,speed:float=0.2) -> Dictionary:
    var b:Dictionary=m.make_body(p,speed,energy,-1,0,m.born)
    b.direction=Vector2.ZERO;m.bodies.append(b);return b

func press(host,index:int) -> void:
    var button=host.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
    button.button_pressed.emit(button)

func run() -> void:
    await process_frame
    Model=load(FOLDER+"learner/printed/population.gd")
    var a=Model.new();a.reset(17,false)
    var b=Model.new();b.reset(17,true)
    check("twelve seeded bodies and sixty-four available cells",a.bodies.size()==12 and a.born==12 and a.died==0 and a.ready_at.size()==64)
    check("renewal changes no opening bodies or RNG state",a.bodies==b.bodies and a.rng.state==b.rng.state)
    check("initial energy budget is eighteen",is_equal_approx(a.total_energy(),18))
    check("cell mapping includes edges and row-major interior",Model.cell(Vector2(-1,-1))==0 and Model.cell(Vector2(1,1))==63 and Model.cell(Vector2(0,0))==36)
    var m=fixture();add(m,Vector2(-0.875,-0.875));add(m,Vector2(-0.875,-0.875));m.ready_at[0]=0
    m.step()
    check("one shared cell supplies exactly one meal",m.meals==1 and not m.available(0))
    check("first occupant receives reward and both pay time cost",is_equal_approx(m.bodies[0].energy,2.795) and is_equal_approx(m.bodies[1].energy,1.995))
    m=fixture();var first=add(m,Vector2(-0.875,-0.875));var second=add(m,Vector2(-0.875,-0.875));m.bodies.reverse();m.ready_at[0]=0;m.step()
    check("swapping record order changes the recipient",is_equal_approx(second.energy,2.795) and is_equal_approx(first.energy,1.995))
    var before:float=m.total_energy();m.step()
    check("depleted cell pays no second finite meal",m.meals==1 and is_equal_approx(m.total_energy(),before-0.01))
    m=fixture(true);add(m,Vector2(-0.875,-0.875),1.0);m.ready_at[0]=0;m.step()
    var due:float=m.ready_at[0]
    for i in 119:m.step()
    check("regrowth does not happen before four elapsed seconds",m.meals==1 and not m.available(0))
    m.step()
    check("stationary occupant can eat when the cell regrows",m.meals==2 and is_equal_approx(due,4.0+Model.DT))
    m=fixture();var parent=add(m,Vector2.ZERO,3.2);m.step()
    check("above threshold creates one child",m.bodies.size()==2 and m.born==2)
    check("split conserves energy after per-body drain",is_equal_approx(m.total_energy(),3.2-0.15*Model.DT) and is_equal_approx(parent.energy,m.bodies[1].energy))
    check("child retains parent and family but increments ancestry depth",m.bodies[1].parent==parent.id and m.bodies[1].family==parent.family and m.bodies[1].generation==1 and m.bodies[1].id!=parent.id)
    check("child speed is inherited with bounded variation",absf(m.bodies[1].speed-parent.speed)<=0.050001 and m.bodies[1].speed>=0.05 and m.bodies[1].speed<=0.6)
    check("new child has not moved during its birth step",m.bodies[1].p==parent.p)
    var child:Dictionary=m.bodies[1];var kept:float=parent.energy;child.energy+=1
    check("child is not a dictionary alias of parent",is_equal_approx(parent.energy,kept))
    m=fixture();add(m,Vector2.ZERO,0.004);m.step()
    check("zero energy removes body exactly once",m.bodies.is_empty() and m.died==1 and m.born==1)
    m.step();check("empty population does not resurrect",m.bodies.is_empty() and m.died==1)
    m=fixture()
    for i in Model.LIMIT:add(m,Vector2.ZERO,4.0)
    m.step();check("full population defers births and splitting",m.bodies.size()==Model.LIMIT and is_equal_approx(m.bodies[0].energy,3.995))
    m=fixture();var edge=add(m,Vector2(0.999,0),1.0,0.6);edge.direction=Vector2.RIGHT;m.step()
    check("crossing the right boundary wraps into the field",edge.p.x<0 and edge.p.x>=-1)
    a.reset(17,false);b.reset(17,false)
    for i in 900:a.step();b.step()
    check("same seed repeats bodies food and RNG through births",a.bodies==b.bodies and a.ready_at==b.ready_at and a.rng.state==b.rng.state and a.born==b.born)
    b.reset(18,false);a.reset(17,false)
    check("different seed changes the opening",a.bodies!=b.bodies)
    var finite=Model.new();var returning=Model.new();finite.reset(17,false);returning.reset(17,true)
    var rows:Array=[];var valid:=true
    for i in 3600:
        finite.step();returning.step()
        for world in [finite,returning]:
            valid=valid and world.bodies.size()<=Model.LIMIT and world.bodies.size()==world.born-world.died
            for body:Dictionary in world.bodies:
                valid=valid and body.speed>=0.05 and body.speed<=0.6 and body.p.x>=-1 and body.p.x<1 and body.p.y>=-1 and body.p.y<1
        if (i+1)%300==0:rows.append({"seconds":(i+1)*Model.DT,"finite_alive":finite.bodies.size(),"return_alive":returning.bodies.size(),"finite_meals":finite.meals,"return_meals":returning.meals})
    evidence["seed_17_comparison"]=rows
    check("long run retains accounting bounds and valid positions",valid)
    check("finite run never collects more than sixty-four meals",finite.meals<=64)
    check("finite seed seventeen is extinct by 120 simulated seconds",finite.bodies.is_empty())
    check("return seed seventeen retains bodies at the same time",not returning.bodies.is_empty() and returning.meals>64)
    var host=load(FOLDER+"learner/printed/environment_study.gd").new()
    root.add_child(host);await process_frame;host.set_process(false)
    var point=host.point
    check("study starts paused with one view per living body",not host.playing and host.views.size()==12 and host.tiles.size()==64)
    var ids:Dictionary={}
    for id in host.views:ids[id]=host.views[id].get_instance_id()
    press(host,1)
    var same:=true
    for id in ids:same=same and host.views.has(id) and host.views[id].get_instance_id()==ids[id]
    check("STEP signal advances exactly one step while retaining nodes",host.world.ticks==1 and not host.playing and same)
    press(host,0);host._process(Model.DT/2);host._process(Model.DT/2)
    check("frame accumulator consumes a whole fixed step",host.world.ticks==2 and host.playing)
    point.action_pressed.emit(point)
    check("carried point trigger pauses the same study",not host.playing and host.point==point)
    var original:Array=Model.new().bodies
    press(host,2);original=host.world.bodies.duplicate(true)
    press(host,4)
    check("RETURN signal resets same opening and preserves handheld point",host.world.renewal and host.world.bodies==original and host.point==point and host.world.ticks==0)
    press(host,5)
    check("NEXT SEED changes opening and keeps chosen condition",host.seed_value==18 and host.world.renewal and host.world.bodies!=original)
    press(host,3)
    check("FINITE signal selects finite resource with current seed",not host.world.renewal and host.seed_value==18 and not host.playing)
    host.world.bodies.clear();host.redraw()
    check("absent identities remove visual nodes without removing the point",host.views.is_empty() and is_instance_valid(point))
    host.reset(false);host.world.bodies.clear();host.playing=true;host._process(Model.DT)
    check("empty study stops instead of silently restarting",not host.playing)
    host.queue_free();await process_frame
    # Inspect actual exhibit modes as a separate comparison, not as the learner model.
    var exhibit=load("res://algorithms/machinelearning/non_teleological_evolution/non_teleological_evolution.tscn").instantiate()
    root.add_child(exhibit);exhibit.set_process(false)
    check("actual drift opening has thirty bodies and four hundred cells",exhibit._creatures.size()==30 and exhibit.grid_resolution==20)
    exhibit.apply_grid_config({"selection":"uniform"})
    check("authored uniform arrangement does not run evolution",not exhibit.is_processing() and exhibit._creatures.size()==30)
    exhibit.apply_grid_config({"selection":"drift"})
    check("drift selection re-enables the actual simulation",exhibit.is_processing())
    exhibit.queue_free();await process_frame
    FileAccess.open(FOLDER+"tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Author-informed printed reconstruction, synthetic runs, real Godot control signals. Human VR untested."},"  "))
    quit(0 if failures.is_empty() else 1)
