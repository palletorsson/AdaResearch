extends SceneTree
var checks:Array=[]
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
    checks.append({"name":title,"passed":ok})
    if not ok:failures.append(title)
    print("[glide learner] ","PASS " if ok else "FAIL ",title)
func values(s:Node3D)->Array:
    var a:Array=[]
    for z in 5:
        for x in 5:a.append(s.value_at(Vector2i(x,z)))
    return a
func rendered(s:Node3D,expected:Array)->bool:
    for z in 5:
        for x in 5:
            var a:Color=s.grid.read(Vector2i(x,z));var b:Color=s.palette.colours[expected[z*5+x]]
            for i in 4:
                if absf(a[i]-b[i])>.005:return false
    return true
func hand(s:Node3D,p:Vector3)->void:
    s.control.global_position=s.to_global(p);s._process(0)
func run()->void:
    await process_frame
    var path:="";var report:="";var changed:=false
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):path=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
        if arg=="--changed":changed=true
    var script=load(path)
    if script==null or not script.can_instantiate():quit(2);return
    var s=script.new();s.position=Vector3(4,0,7);s.rotation.y=PI/3;root.add_child(s);s.set_process(false)
    await create_timer(.2).timeout;s._process(0)
    check("subclass builds one grid and one inherited point",s.grid.cells.size()==25 and s.find_children("*","RigidBody3D",true,false).size()==1 and s.find_children("*","MultiMeshInstance3D",true,false).size()==1)
    check("initial point remains frozen",s.control.freeze and s.control.position.is_equal_approx(Vector3(0,1.15,2.5)))
    var original:Array=s.source.duplicate(true);var id:int=s.grid.instances.get_instance_id();var pose:Transform3D=s.grid.transform
    var p1:Array=[0,1,0,0,1,0,0,1,0,0,0,1,0,0,1,0,0,1,0,0,0,1,0,0,1]
    var pm:Array=[0,1,0,0,1,0,0,1,1,0,0,1,0,0,1,0,0,1,1,0,0,1,0,0,1]
    var pg:Array=[0,1,0,1,0,0,0,1,0,1,0,1,0,1,0,0,0,1,0,1,0,1,0,1,0]
    if changed:
        p1=[0,1,0,0,1,0,0,1,0,0,2,0,0,2,0,0,2,0,0,2,0,1,0,0,1]
        pm=[0,1,0,0,1,0,0,1,1,0,2,0,0,0,0,0,2,0,0,2,0,1,0,0,1]
        pg=[0,1,0,0,0,0,0,1,0,2,2,0,0,0,1,0,2,0,1,0,0,1,0,0,0]
    for rule in 3:
        var expected:Array=[p1,pm,pg][rule]
        check("rule "+str(rule)+" has explicit expected twenty-five values",s.rule==rule and values(s)==expected)
        check("rule "+str(rule)+" renders expected colours",rendered(s,expected))
        check("rule "+str(rule)+" keeps source, receiver and MultiMesh",s.source==original and s.grid.transform==pose and s.grid.instances.get_instance_id()==id)
        check("rule "+str(rule)+" preserves reflection state",s.reflected==(rule!=0))
        hand(s,Vector3(0,1.15,2.5))
        check("local RULE label selects on rotated host",s.operation()=="RULE" and s.rule==rule and s.label.text.contains(s.RULE_NAMES[rule]))
        s.control.action();s._process(0)
    check("three triggers return to P1 with original source",s.rule==0 and not s.reflected and s.source==original and rendered(s,p1))
    s.cycle_rule();s.cycle_rule();s._process(0)
    check("PG odd block uses half-height shifted source row",s.source_address(Vector2i(3,0))==Vector2i(2,2 if changed else 1))
    check("PG even block never shifts",s.source_address(Vector2i(1,0))==Vector2i(1,0))
    check("negative odd block uses floor and positive wrapping",s.source_address(Vector2i(-1,-1))==Vector2i(0,1 if changed else 0))
    var period_ok:=true;var differs_three:=false;var differs_half:=false;var glide_ok:=true
    var height:int=4 if changed else 2
    for y in range(-4,8):
        for x in range(-7,12):
            var a:=Vector2i(x,y)
            period_ok=period_ok and s.value_at(a)==s.value_at(a+Vector2i(6,0)) and s.value_at(a)==s.value_at(a+Vector2i(0,height))
            differs_three=differs_three or s.value_at(a)!=s.value_at(a+Vector2i(3,0))
            differs_half=differs_half or s.value_at(a)!=s.value_at(a+Vector2i(0,height/2))
            # Reflect about x=2.5 and shift along the axis: G^2(x,y)=(x,y+h).
            var g:=Vector2i(5-x,y+height/2)
            var gg:=Vector2i(5-g.x,g.y+height/2)
            glide_ok=glide_ok and s.value_at(a)==s.value_at(g) and gg==a+Vector2i(0,height)
    check("PG has six-column and full-height translation periods",period_ok and differs_three and differs_half)
    check("field admits glide and two glides give full-height translation",glide_ok)
    hand(s,Vector3(.32,1.12,0))
    check("point finds surface row zero column three",s.selected_address()==Vector2i(3,0) and s.label.text.contains("source row %d, column 2"%(2 if changed else 1)))
    s.control.action();s._process(0)
    var edited:Array=original.duplicate(true);edited[2 if changed else 1][2]=1 if changed else 2
    check("painting through glide changes only the true source entry",s.source==edited)
    var changed_cells:Array=[]
    var after:Array=values(s)
    for i in 25:
        if after[i]!=pg[i]:changed_cells.append(i)
    check("painting reaches exact predicted copies",changed_cells==([3,12,23] if changed else [3,7,13,17,23]))
    check("painted values reach renderer",rendered(s,after))
    hand(s,Vector3(-.6,1.15,2.5));s.control.action()
    hand(s,Vector3(.6,1.15,2.5));s.control.action()
    check("inherited FACE and WIDTH still work without changing rule",s.wall and s.width_index==1 and s.rule==2 and s.source==edited)
    hand(s,Vector3(.6,2.2,1.44))
    check("glide lookup composes with resized wall frame",s.selected_address()==Vector2i(3,0) and s.label.text.contains("source row %d, column 2"%(2 if changed else 1)))
    hand(s,Vector3(0,1.6,2.5));s.control.action()
    check("out-of-reach trigger performs no edit",s.operation().is_empty() and s.source==edited and s.rule==2)
    for row in s.source:row.fill(0)
    s.repaint()
    var zeroes:Array=[];zeroes.resize(25);zeroes.fill(0)
    for i in 3:
        s.cycle_rule()
        check("uniform source conceals rule "+str(s.rule),rendered(s,zeroes))
    s.source=original.duplicate(true);s.repaint()
    var restored:Array=values(s);s.cycle_rule()
    check("restored asymmetric source makes rule change visible",values(s)!=restored)
    var other=script.new();root.add_child(other);other.set_process(false)
    s.source[0][0]=2
    check("new instance owns independent source and rule",other.source==original and other.rule==0)
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":path,"changed":changed,"engine":Engine.get_version_info(),"scope":"Exact printed five-file reconstruction and independent four-row source. Sampled field invariants and explicit fixtures; not a classification proof or headset/human-learning test."},"  "))
    s.free();other.free();quit(0 if failures.is_empty() else 1)
